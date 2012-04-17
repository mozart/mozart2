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
#include <cassert>

using namespace clang;

enum StorageKind {
  skDefault,
  skCustom,
  skWithArray
};

// See StructuralBehavior in vm/main/type.hh
enum StructuralBehavior {
  sbValue, sbStructural, sbTokenEq, sbVariable
};

std::string sb2s(StructuralBehavior behavior) {
  switch (behavior) {
    case sbValue: return "sbValue";
    case sbStructural: return "sbStructural";
    case sbTokenEq: return "sbTokenEq";
    case sbVariable: return "sbVariable";

    default:
      assert(false);
      return "";
  }
}

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
    structuralBehavior = sbTokenEq;
    bindingPriority = 0;
    withHome = false;
    base = "Type";
    hasPrintReprToStream = false;
    autoGCollect = true;
    autoSClone = true;
  }

  void makeOutputDeclBefore(llvm::raw_fd_ostream& to);
  void makeOutputDeclAfter(llvm::raw_fd_ostream& to);
  void makeOutput(llvm::raw_fd_ostream& to);

  std::string name;
  bool copiable;
  bool transient;
  StorageKind storageKind;
  std::string storage;
  StructuralBehavior structuralBehavior;
  unsigned char bindingPriority;
  bool withHome;
  std::string base;
  bool hasPrintReprToStream;
  bool autoGCollect;
  bool autoSClone;
  std::vector<ImplemMethodDef> methods;
private:
  void makeContentsOfAutoGCollect(llvm::raw_fd_ostream& to);
  void makeContentsOfAutoSClone(llvm::raw_fd_ostream& to,
                                bool toStableNode);
};

void handleImplementation(const SpecDecl* ND) {
  const std::string name = getTypeParamAsString(ND);

  ImplementationDef definition;
  definition.name = name;

  // For every marker, i.e. base class
  for (auto iter = ND->bases_begin(), e = ND->bases_end(); iter != e; ++iter) {
    CXXRecordDecl* marker = iter->getType()->getAsCXXRecordDecl();
    std::string markerLabel = marker->getNameAsString();

    if (markerLabel == "Copiable") {
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
    } else if (markerLabel == "WithValueBehavior") {
      definition.structuralBehavior = sbValue;
    } else if (markerLabel == "WithStructuralBehavior") {
      definition.structuralBehavior = sbStructural;
    } else if (markerLabel == "WithVariableBehavior") {
      definition.structuralBehavior = sbVariable;
      definition.bindingPriority =
        getValueParamAsIntegral<unsigned char>(marker);
    } else if (markerLabel == "WithHome") {
      definition.withHome = true;
    } else if (markerLabel == "BasedOn") {
      definition.base = getTypeParamAsString(marker);
    } else if (markerLabel == "NoAutoGCollect") {
      definition.autoGCollect = false;
    } else if (markerLabel == "NoAutoSClone") {
      definition.autoSClone = false;
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

    if (m->getNameAsString() == "printReprToStream")
      definition.hasPrintReprToStream = true;

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
  to << "public:\n";
  to << "  " << name << "() : " << base << "(\"" << name << "\", "
     << b2s(copiable) << ", " << b2s(transient) << ", "
     << sb2s(structuralBehavior) << ", " << ((int) bindingPriority)
     << ") {}\n";
  to << "\n";
  to << "  static const " << name << "* const type() {\n";
  to << "    return &RawType<" << name << ">::rawType;\n";
  to << "  }\n";
  to << "\n";
  to << "  template <class... Args>\n";
  to << "  static UnstableNode build(VM vm, Args&&... args) {\n";
  to << "    return UnstableNode::build<" << name
     << ">(vm, std::forward<Args>(args)...);\n";
  to << "  }\n";

  if (hasPrintReprToStream) {
    to << "\n";
    to << "  inline\n";
    to << "  void printReprToStream(VM vm, RichNode self, std::ostream& out,\n";
    to << "                         int depth) const;\n";
  }

  if (autoGCollect) {
    to << "\n";
    to << "  inline\n";
    to << "  void gCollect(GC gc, RichNode from, StableNode& to) const;\n";
    to << "\n";
    to << "  inline\n";
    to << "  void gCollect(GC gc, RichNode from, UnstableNode& to) const;\n";
  }

  if (autoSClone) {
    to << "\n";
    to << "  inline\n";
    to << "  void sClone(SC sc, RichNode from, StableNode& to) const;\n";
    to << "\n";
    to << "  inline\n";
    to << "  void sClone(SC sc, RichNode from, UnstableNode& to) const;\n";
  }

  to << "};\n";
}

void ImplementationDef::makeOutputDeclAfter(llvm::raw_fd_ostream& to) {
  to << "template <>\n";
  to << "class TypedRichNode<" << name << "> "
     << ": public BaseTypedRichNode<" << name << "> {\n";
  to << "public:\n";
  to << "  TypedRichNode(Self self) : BaseTypedRichNode(self) {}\n";

  // Special-casing the method WithHome::home() until we find a better solution
  if (withHome) {
    to << "\n";
    to << "  inline\n";
    to << "  Space* home();\n";
  }

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
  std::string _selfArrow;
  if (storageKind == skCustom)
    _selfArrow = "_self.get().";
  else
    _selfArrow = "_self->";

  if (hasPrintReprToStream) {
    to << "\n";
    to << "void " << name
       << "::printReprToStream(VM vm, RichNode self, std::ostream& out,\n";
    to << "                    int depth) const {\n";
    to << "  assert(self.is<" << name << ">());\n";
    to << "  self.as<" << name << ">().printReprToStream(vm, out, depth);\n";
    to << "}\n";
  }

  if (autoGCollect) {
    to << "\n";
    to << "void " << name
       << "::gCollect(GC gc, RichNode from, StableNode& to) const {\n";
    makeContentsOfAutoGCollect(to);
    to << "}\n\n";

    to << "void " << name
       << "::gCollect(GC gc, RichNode from, UnstableNode& to) const {\n";
    makeContentsOfAutoGCollect(to);
    to << "}\n";
  }

  if (autoSClone) {
    to << "\n";
    to << "void " << name
       << "::sClone(SC sc, RichNode from, StableNode& to) const {\n";
    makeContentsOfAutoSClone(to, true);
    to << "}\n\n";

    to << "void " << name
       << "::sClone(SC sc, RichNode from, UnstableNode& to) const {\n";
    makeContentsOfAutoSClone(to, false);
    to << "}\n";
  }

  // Special-casing the method WithHome::home() until we find a better solution
  if (withHome) {
    to << "\n";
    to << "Space* TypedRichNode<" << name << ">::home() {\n";
    to << "  return " << _selfArrow << "home();\n";
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

    to << _selfArrow << m->getNameAsString() << "(";

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
  to << "  assert(from.type() == type());\n";
  to << "  Self fromAsSelf = from;\n";
  to << "  to.make<" << name << ">(gc->vm, ";
  if (storageKind == skWithArray)
    to << "fromAsSelf.getArraySize(), ";
  to << "gc, fromAsSelf);\n";
}

void ImplementationDef::makeContentsOfAutoSClone(llvm::raw_fd_ostream& to,
                                                 bool toStableNode) {
  to << "  assert(from.type() == type());\n";

  std::string cloneStatement = std::string("to.make<") + name + ">(sc->vm, ";
  if (storageKind == skWithArray)
    cloneStatement += "fromAsSelf.getArraySize(), ";
  cloneStatement += "sc, fromAsSelf);";

  std::string copyStatement =
    std::string("to.") + (toStableNode ? "init" : "copy") + "(sc->vm, from);";

  if (withHome) {
    to << "  Self fromAsSelf = from;\n";
    if (storageKind == skCustom)
      to << "  if (fromAsSelf.get().home()->shouldBeCloned()) {\n";
    else
      to << "  if (fromAsSelf->home()->shouldBeCloned()) {\n";
    to << "    " << cloneStatement << "\n";
    to << "  } else {\n";
    to << "    " << copyStatement << "\n";
    to << "  }\n";
  } else {
    switch (this->structuralBehavior) {
      case sbValue:
      case sbStructural: {
        to << "  Self fromAsSelf = from;\n";
        to << "  " << cloneStatement << "\n";
        break;
      }

      case sbTokenEq:
      case sbVariable: {
        // Actually, these have a home, but it's always the top-level
        to << "  " << copyStatement << "\n";
        break;
      }
    }
  }
}
