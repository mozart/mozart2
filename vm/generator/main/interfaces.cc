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

#include <sstream>

using namespace clang;

struct InterfaceDef {
  InterfaceDef() {
    name = "";
    implems = 0;
    autoWait = true;
    autoReflectiveCalls = true;
  }

  void makeOutput(const SpecDecl* ND, llvm::raw_fd_ostream& to);

  std::string name;
  const TemplateSpecializationType* implems;
  bool autoWait;
  bool autoReflectiveCalls;
};

void handleInterface(const std::string& outputDir, const SpecDecl* ND) {
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
    } else if (markerLabel == "NoAutoReflectiveCalls") {
      definition.autoReflectiveCalls = false;
    } else {}
  }

  // Write output
  withFileOutputStream(outputDir + name + "-interf.hh",
    [&] (ostream& to) { definition.makeOutput(ND, to); });
}

void InterfaceDef::makeOutput(const SpecDecl* ND, llvm::raw_fd_ostream& to) {
  to << "class "<< name << " {\n";
  to << "public:\n";
  to << "  " << name << "(RichNode self) : _self(self) {}\n";
  to << "  " << name << "(UnstableNode& self) : _self(self) {}\n";
  to << "  " << name << "(StableNode& self) : _self(self) {}\n";
  to << "\n";
  to << "  template <class T>\n";
  to << "  " << name << "(BaseSelf<T> self) : _self(self) {}\n";

  for (auto iter = ND->decls_begin(), e = ND->decls_end(); iter != e; ++iter) {
    const Decl* decl = *iter;

    if (decl->isImplicit())
      continue;
    if (!decl->isFunctionOrFunctionTemplate())
      continue;
    if (decl->getAccess() != AS_public)
      continue;

    const FunctionDecl* function;

    if ((function = dyn_cast<FunctionDecl>(decl))) {
      // Do nothing
    } else if (const FunctionTemplateDecl* funTemplate =
               dyn_cast<FunctionTemplateDecl>(decl)) {
      function = funTemplate->getTemplatedDecl();
      TemplateParameterList* params = funTemplate->getTemplateParameters();

      to << "\n  ";
      printTemplateParameters(to, params);
    }

    if (!function->isCXXInstanceMember())
      continue;

    std::string funName, resultType, formals, actuals, reflectActuals;
    parseFunction(function, funName, resultType, formals, actuals,
                  reflectActuals, true);

    // Declaration of the procedure
    to << "\n  " << resultType << " " << funName
       << "(" << formals << ") {\n    ";

    // For every implementation that implements this interface (ImplementedBy)
    for (int i = 0; i < (int) implems->getNumArgs(); ++i) {
      std::string imp =
        implems->getArg(i).getAsType()->getAsCXXRecordDecl()->getNameAsString();

      to << "if (_self.is<" << imp << ">()) {\n";
      to << "      return _self.as<" << imp << ">()."
         << funName << "(" << actuals << ");\n";
      to << "    } else ";
    }

    // Auto-wait handling
    if (autoWait) {
      to << "if (_self.isTransient()) {\n";
      to << "      waitFor(vm, _self);\n";
      to << "      throw std::exception(); // not reachable\n";
      to << "    } else ";
    }

    to << "{\n";

    // Auto-reflective calls handling
    if (autoReflectiveCalls) {
      to << "      if (_self.is< ::mozart::ReflectiveEntity>()) {\n";
      if (resultType != "void")
        to << "        " << resultType << " _result;\n";
      to << "        if (_self.as< ::mozart::ReflectiveEntity>()."
         << "reflectiveCall(vm, MOZART_STR(\"$intf$::"
         << name << "::" << funName << "\"), MOZART_STR(\"" << funName << "\")";
      if (!reflectActuals.empty())
        to << ", " << reflectActuals;
      if (resultType != "void")
        to << ", ::mozart::ozcalls::out(_result)";
      to << "))\n";
      if (resultType != "void")
        to << "          return _result;\n";
      else
        to << "          return;\n";
      to << "      }\n";
    }

    // Default behavior
    to << "      return Interface<" << name << ">()." << funName << "(_self";
    if (!actuals.empty())
      to << ", " << actuals;
    to << ");\n";
    to << "    }\n";

    to << "  }\n";
  }

  to << "protected:\n";
  to << "  RichNode _self;\n";
  to << "};\n\n";
}
