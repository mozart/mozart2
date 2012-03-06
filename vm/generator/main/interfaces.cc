// Copyright © 2012, Université catholique de Louvain
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// *  Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
// *  Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include "generator.hh"

using namespace clang;

struct InterfaceDef {
  InterfaceDef() {
    name = "";
    implems = 0;
    autoWait = true;
  }

  void makeOutput(const SpecDecl* ND, llvm::raw_fd_ostream& to);

  std::string name;
  const TemplateSpecializationType* implems;
  bool autoWait;
};

void handleInterface(const SpecDecl* ND) {
  const std::string name = getTypeParamAsString(ND);

  InterfaceDef definition;
  definition.name = name;

  // For every marker, i.e. base class
  for (auto iter = ND->bases_begin(), e = ND->bases_end(); iter != e; ++iter) {
    CXXRecordDecl* marker = iter->getType()->getAsCXXRecordDecl();
    std::string markerLabel = marker->getNameAsString();

    if (markerLabel == "ImplementedBy") {
      definition.implems =
        dyn_cast<TemplateSpecializationType>(iter->getType().getTypePtr());
    } else if (markerLabel == "NoAutoWait") {
      definition.autoWait = false;
    } else {}
  }

  std::string err;
  llvm::raw_fd_ostream to((name+"-interf.hh").c_str(), err);
  assert(err == "");
  definition.makeOutput(ND, to);
}

void InterfaceDef::makeOutput(const SpecDecl* ND, llvm::raw_fd_ostream& to) {
  to << "class "<< name << " {\n";
  to << "public:\n";
  to << "  " << name << "(Node& self) : _self(Reference::dereference(self)) {}\n";

  // For every method in Interface<T>
  for (auto iter = ND->method_begin(), e = ND->method_end(); iter != e; ++iter) {
    CXXMethodDecl* m = *iter;
    if (!m->isUserProvided())
      continue;

    /* We will iterate several times over all parameters of the method,
     * excluding the self param, which is the first parameter. */
    auto param_begin = m->param_begin() + 1;
    auto param_end = m->param_end();

    // Declaration of the procedure
    to << "\n  " << m->getResultType().getAsString(context->getPrintingPolicy());
    to << " " << m->getNameAsString() << "(";
    // For every parameter of that method, excluding the self param
    for (auto iter = param_begin; iter != param_end; ++iter) {
      ParmVarDecl* param = *iter;
      to << typeToString(param->getType()) << " " << param->getNameAsString();
      if (iter+1 != param_end)
        to << ", ";
    }
    to << ") {\n    ";

    // For every implementation that implements this interface (ImplementedBy)
    for (int i = 0; i < (int) implems->getNumArgs(); ++i) {
      std::string imp =
        implems->getArg(i).getAsType()->getAsCXXRecordDecl()->getNameAsString();

      to << "if (_self.type == " << imp << "::type()) {\n";
      to << "      return IMPL("
         << typeToString(m->getResultType())
         << ", " << imp << ", " << m->getNameAsString() << ", " << "&_self";

      // For every parameter of the method, excluding the self param
      for (auto iter = param_begin; iter != param_end; ++iter) {
        ParmVarDecl* param = *iter;
        to << ", " << param->getNameAsString();
      }

      to << ");\n";
      to << "    } else ";
    }

    // Auto-wait handling
    if (autoWait && (typeToString(m->getResultType()) == "BuiltinResult")) {
      to << "if (_self.type->isTransient()) {\n";
      to << "      return BuiltinResult::waitFor(&_self);\n";
      to << "    } else ";
    }

    // Default behavior
    to << "{\n";
    to << "      return Interface<" << name << ">().";
    to << m->getNameAsString() << "(_self";
    // For every parameter of the method, excluding the self param
    for (auto iter = param_begin; iter != param_end; ++iter) {
      ParmVarDecl* param = *iter;
      to << ", " << param->getNameAsString();
    }
    to << ");\n";
    to << "    }\n";

    to << "  }\n";
  }

  to << "private:\n";
  to << "  Node& _self;\n";
  to << "};\n\n";
}
