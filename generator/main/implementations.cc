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
#include <iostream>

using namespace clang;

enum StorageKind {
  skDefault,
  skCustom,
  skWithArray
};

struct ImplemMethodDef {
  ImplemMethodDef(CXXMethodDecl* method) : method(method) {
    hasSelfParam = false;
  }

  CXXMethodDecl* method;
  bool hasSelfParam;
  FunctionDecl::param_iterator param_begin;
  FunctionDecl::param_iterator param_end;
};

struct ImplementationDef {
  ImplementationDef() {
    name = "";
    copiable = false;
    transient = false;
    storageKind = skDefault;
    storage = "";
    base = "Type";
    autoGCollect = true;
  }

  void makeOutputDeclBefore(llvm::raw_fd_ostream& to);
  void makeOutputDeclAfter(llvm::raw_fd_ostream& to);
  void makeOutput(llvm::raw_fd_ostream& to);

  std::string name;
  bool copiable;
  bool transient;
  StorageKind storageKind;
  std::string storage;
  std::string base;
  bool autoGCollect;
  std::vector<ImplemMethodDef> methods;
private:
  void makeContentsOfAutoGCollect(llvm::raw_fd_ostream& to);
};

void handleImplementation(const SpecDecl* ND) {
  const std::string name = getTypeParamAsString(ND);

  ImplementationDef definition;
  definition.name = name;

  // For every marker, i.e. base class
  for (auto iter = ND->bases_begin(), e = ND->bases_end(); iter != e; ++iter) {
    CXXRecordDecl* marker = iter->getType()->getAsCXXRecordDecl();
    std::string markerLabel = marker->getNameAsString();

    if (markerLabel=="Copiable") {
      definition.copiable = true;
    } else if (markerLabel == "Transient") {
      definition.transient = true;
    } else if (markerLabel == "StoredAs") {
      definition.storageKind = skCustom;
      definition.storage = getTypeParamAsString(marker);
    } else if (markerLabel == "StoredWithArrayOf") {
      definition.storageKind = skWithArray;
      definition.storage = "ImplWithArray<Implementation<" + name + ">, " +
        getTypeParamAsString(marker) + ">";
    } else if (markerLabel == "BasedOn") {
      definition.base = getTypeParamAsString(marker);
    } else if (markerLabel == "NoAutoGCollect") {
      definition.autoGCollect = false;
    } else {}
  }

  // For every method in Implementation<T>
  for (auto iter = ND->method_begin(), e = ND->method_end(); iter != e; ++iter) {
    CXXMethodDecl* m = *iter;
    if (!m->isUserProvided() || !m->isInstance())
      continue;
    if (m->getAccess() != AS_public)
      continue;
    if (isa<CXXConstructorDecl>(m) || (m->getNameAsString() == "build"))
      continue;

    ImplemMethodDef method(m);

    method.hasSelfParam = (m->param_size() > 0) &&
      ((*m->param_begin())->getNameAsString() == "self");

    method.param_begin = m->param_begin() + (method.hasSelfParam ? 1 : 0);
    method.param_end = m->param_end();

    definition.methods.push_back(method);
  }

  {
    std::string err;
    llvm::raw_fd_ostream to((name+"-implem-decl.hh").c_str(), err);
    assert(err == "");
    definition.makeOutputDeclBefore(to);
  }

  {
    std::string err;
    llvm::raw_fd_ostream to((name+"-implem-decl-after.hh").c_str(), err);
    assert(err == "");
    definition.makeOutputDeclAfter(to);
  }

  {
    std::string err;
    llvm::raw_fd_ostream to((name+"-implem.hh").c_str(), err);
    assert(err == "");
    definition.makeOutput(to);
  }
}

void ImplementationDef::makeOutputDeclBefore(llvm::raw_fd_ostream& to) {
  if (storageKind != skDefault) {
    to << "template <>\n";
    to << "class Storage<" << name << "> {\n";
    to << "public:\n";
    to << "  typedef " << storage << " Type;\n";
    to << "};\n\n";
  }

  to << "class " << name << ": public " << base << " {\n";
  to << "private:\n";
  to << "  typedef SelfType<" << name << ">::Self Self;\n";
  to << "  typedef SelfType<" << name
     << ">::SelfReadOnlyView SelfReadOnlyView;\n";
  to << "public:\n";
  to << "  " << name << "() : " << base << "(\"" << name << "\", "
     << b2s(copiable) << ", " << b2s(transient) <<") {}\n";
  to << "\n";
  to << "  static const " << name << "* const type() {\n";
  to << "    return &RawType<" << name << ">::rawType;\n";
  to << "  }\n";

  if (autoGCollect) {
    to << "\n";
    to << "  inline\n";
    to << "  void gCollect(GC gc, Node& from, StableNode& to) const;\n";
    to << "\n";
    to << "  inline\n";
    to << "  void gCollect(GC gc, Node& from, UnstableNode& to) const;\n";
  }

  to << "};\n";
}

void ImplementationDef::makeOutputDeclAfter(llvm::raw_fd_ostream& to) {
  to << "template <>\n";
  to << "class TypedRichNode<" << name << "> "
     << ": BaseTypedRichNode<" << name << "> {\n";
  to << "public:\n";
  to << "  TypedRichNode(Self self) : BaseTypedRichNode(self) {}\n";

  for (auto method = methods.begin(); method != methods.end(); ++method) {
    CXXMethodDecl* m = method->method;

    to << "\n";
    to << "  inline\n";
    to << "  " << m->getResultType().getAsString(context->getPrintingPolicy());
    to << " " << m->getNameAsString() << "(";

    // For every parameter of that method, excluding the self param
    for (auto iter = method->param_begin; iter != method->param_end; ++iter) {
      ParmVarDecl* param = *iter;
      to << typeToString(param->getType()) << " " << param->getNameAsString();
      if (iter+1 != method->param_end)
        to << ", ";
    }

    to << ");\n";
  }

  to << "};\n";
}

void ImplementationDef::makeOutput(llvm::raw_fd_ostream& to) {
  if (autoGCollect) {
    to << "void " << name
       << "::gCollect(GC gc, Node& from, StableNode& to) const {\n";
    makeContentsOfAutoGCollect(to);
    to << "}\n\n";

    to << "void " << name
       << "::gCollect(GC gc, Node& from, UnstableNode& to) const {\n";
    makeContentsOfAutoGCollect(to);
    to << "}\n";
  }

  for (auto method = methods.begin(); method != methods.end(); ++method) {
    CXXMethodDecl* m = method->method;

    to << "\n";
    to << m->getResultType().getAsString(context->getPrintingPolicy());
    to << " TypedRichNode<" << name << ">::" << m->getNameAsString() << "(";

    // For every parameter of that method, excluding the self param
    for (auto iter = method->param_begin; iter != method->param_end; ++iter) {
      ParmVarDecl* param = *iter;
      to << typeToString(param->getType()) << " " << param->getNameAsString();
      if (iter+1 != method->param_end)
        to << ", ";
    }

    to << ") {\n  ";

    if (!m->getResultType().getTypePtr()->isVoidType())
      to << "return ";

    if (storageKind == skCustom)
      to << "_self.get().";
    else
      to << "_self->";
    to << m->getNameAsString() << "(";

    if (method->hasSelfParam)
      to << "_self";

    // For every parameter of that method, excluding the self param
    for (auto iter = method->param_begin; iter != method->param_end; ++iter) {
      if (method->hasSelfParam || iter != method->param_begin)
        to << ", ";

      ParmVarDecl* param = *iter;
      to << param->getNameAsString();
    }

    to << ");\n";

    to << "}\n";
  }
}

void ImplementationDef::makeContentsOfAutoGCollect(llvm::raw_fd_ostream& to) {
  to << "  SelfReadOnlyView fromAsSelf(&from);\n";
  to << "  to.make<" << name << ">(gc->vm, ";
  if (storageKind == skWithArray)
    to << "fromAsSelf.getArraySize(), ";
  to << "gc, fromAsSelf);\n";
}
