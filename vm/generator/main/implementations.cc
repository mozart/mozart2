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
  ImplemMethodDef() {}

  ImplemMethodDef(const FunctionDecl* function,
                  const FunctionTemplateDecl* funTemplate = nullptr) {
    this->function = function;
    this->funTemplate = funTemplate;
    hasSelfParam = false;
  }

  void parseTheFunction() {
    std::string reflectActuals;
    parseFunction(function, name, resultType, formals, actuals,
                  reflectActuals, hasSelfParam);
  }

  bool isRedefinitionOf(const ImplemMethodDef& other) {
    return (hasSelfParam == other.hasSelfParam) &&
      (name == other.name) &&
      (resultType == other.resultType) &&
      (formals == other.formals);
  }

  const FunctionDecl* function;
  const FunctionTemplateDecl* funTemplate;

  bool hasSelfParam;
  std::string name;
  std::string resultType;
  std::string formals;
  std::string actuals;
};

struct ImplementationDef {
  ImplementationDef() {
    name = "";
    transient = false;
    feature = false;
    storageKind = skDefault;
    storage = "";
    storageElement = "";
    structuralBehavior = sbTokenEq;
    bindingPriority = 0;
    withHome = false;
    base = "TypeInfo";
    hasUUID = false;
    hasGetTypeAtom = false;
    hasPrintReprToStream = false;
    hasSerialize = false;
    hasGlobalize = false;
    autoGCollect = true;
    autoSClone = true;
  }

  void computeProperties() {
    if ((storageKind == skCustom) && (structuralBehavior == sbValue)) {
      copyable = "(! ::mozart::MemWord::requiresExternalMemory<" +
        storage + ">())";
    } else {
      copyable = "false";
    }
  }

  void makeOutputDeclBefore(llvm::raw_fd_ostream& to);
  void makeOutputDeclAfter(llvm::raw_fd_ostream& to);
  void makeOutput(llvm::raw_fd_ostream& to);

  std::string name;
  std::string copyable;
  bool transient;
  bool feature;
  StorageKind storageKind;
  std::string storage;
  std::string storageElement;
  StructuralBehavior structuralBehavior;
  unsigned char bindingPriority;
  bool withHome;
  std::string base;
  bool hasUUID;
  bool hasGetTypeAtom;
  bool hasPrintReprToStream;
  bool hasSerialize;
  bool hasGlobalize;
  bool autoGCollect;
  bool autoSClone;
  std::vector<ImplemMethodDef> methods;
private:
  void makeContentsOfAutoGCollect(llvm::raw_fd_ostream& to,
                                  bool toStableNode);
  void makeContentsOfAutoSClone(llvm::raw_fd_ostream& to,
                                bool toStableNode);

  bool requiresStableNodeInGR() {
    return (storageKind == skCustom) &&
      ((storage == "SpaceRef") || (storage == "class mozart::Runnable *") ||
      (storage == "class mozart::StableNode *"));
  }
};

bool isImplementationClass(const ClassDecl* cls) {
  return existsBaseClassSuchThat(cls,
    [] (const ClassDecl* cls) {
      return isAnInstantiationOfTheTemplate(cls, "mozart::DataType");
    }
  );
}

void collectMethods(ImplementationDef& definition, const ClassDecl* CD) {
  // Recurse into base classes
  for (auto iter = CD->bases_begin(), e = CD->bases_end();
       iter != e; ++iter) {
    CXXBaseSpecifier base = *iter;

    if (base.getAccessSpecifier() == AS_public)
      collectMethods(definition, base.getType()->getAsCXXRecordDecl());
  }

  // Process the methods in this class
  for (auto iter = CD->decls_begin(), e = CD->decls_end(); iter != e; ++iter) {
    const Decl* decl = *iter;

    if (decl->isImplicit())
      continue;
    if (!decl->isFunctionOrFunctionTemplate())
      continue;
    if (decl->getAccess() != AS_public)
      continue;

    ImplemMethodDef method;
    const FunctionDecl* function;

    if ((function = dyn_cast<FunctionDecl>(decl))) {
      method = ImplemMethodDef(function);
    } else if (const FunctionTemplateDecl* funTemplate =
               dyn_cast<FunctionTemplateDecl>(decl)) {
      function = funTemplate->getTemplatedDecl();
      method = ImplemMethodDef(function, funTemplate);
    }

    if (!function->isCXXInstanceMember()) {
      if (function->getNameAsString() == "getTypeAtom")
        definition.hasGetTypeAtom = true;
    } else {
      if (isa<CXXConstructorDecl>(function))
        continue;

      if (function->getNameAsString() == "printReprToStream")
        definition.hasPrintReprToStream = true;
      else if (function->getNameAsString() == "serialize")
        definition.hasSerialize = true;
      else if (function->getNameAsString() == "globalize")
        definition.hasGlobalize = true;
      else if (function->getNameAsString() == "compareFeatures")
        definition.feature = true;

      method.hasSelfParam = (function->param_size() > 0) &&
        ((*function->param_begin())->getNameAsString() == "self");

      method.parseTheFunction();

      bool redefinition = false;
      for (auto iter = definition.methods.begin();
           iter != definition.methods.end(); ++iter) {
        if (method.isRedefinitionOf(*iter)) {
          redefinition = true;
          break;
        }
      }

      if (!redefinition)
        definition.methods.push_back(method);
    }
  }
}

void handleImplementation(const std::string& outputDir, const ClassDecl* CD) {
  const std::string name = CD->getNameAsString();

  ImplementationDef definition;
  definition.name = name;

  // For every marker, i.e. base class
  for (auto iter = CD->bases_begin(), e = CD->bases_end(); iter != e; ++iter) {
    CXXRecordDecl* marker = iter->getType()->getAsCXXRecordDecl();
    std::string markerLabel = marker->getNameAsString();

    if (markerLabel == "Transient") {
      definition.transient = true;
    } else if (markerLabel == "StoredAs") {
      definition.storageKind = skCustom;
      definition.storage = getTypeParamAsString(marker, false);
    } else if (markerLabel == "StoredWithArrayOf") {
      definition.storageKind = skWithArray;
      definition.storageElement = getTypeParamAsString(marker, false);
      definition.storage = "ImplWithArray<" + name + ", " +
        definition.storageElement + ">";
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

  // Collect methods
  collectMethods(definition, CD);

  // Look for a UUID
  for (auto iter = CD->decls_begin(), e = CD->decls_end(); iter != e; ++iter) {
    const Decl* decl = *iter;

    if (const NamedDecl* named = dyn_cast<NamedDecl>(decl)) {
      if (named->getNameAsString() == "uuid")
        definition.hasUUID = true;
    }
  }

  // Compute other properties
  definition.computeProperties();

  // Write output
  withFileOutputStream(outputDir + name + "-implem-decl.hh",
    [&] (ostream& to) { definition.makeOutputDeclBefore(to); });

  withFileOutputStream(outputDir + name + "-implem-decl-after.hh",
    [&] (ostream& to) { definition.makeOutputDeclAfter(to); });

  withFileOutputStream(outputDir + name + "-implem.hh",
    [&] (ostream& to) { definition.makeOutput(to); });
}

void ImplementationDef::makeOutputDeclBefore(llvm::raw_fd_ostream& to) {
  to << "class " << name << ";\n";

  if (storageKind != skDefault) {
    to << "\n";
    to << "template <>\n";
    to << "class Storage<" << name << "> {\n";
    to << "public:\n";
    to << "  typedef " << storage << " Type;\n";
    to << "};\n";
  }
}

void ImplementationDef::makeOutputDeclAfter(llvm::raw_fd_ostream& to) {
  to << "template <>\n";
  to << "class TypeInfoOf<" << name << ">: public " << base << " {\n";
  to << "\n";
  to << "  static constexpr UUID uuid() {\n";
  if (hasUUID)
    to << "    return " << name << "::uuid;\n";
  else
    to << "    return UUID();\n";
  to << "  }\n";
  to << "public:\n";
  to << "  TypeInfoOf() : " << base << "(\"" << name << "\", uuid(), "
     << copyable << ", " << b2s(transient) << ", " << b2s(feature) << ", "
     << sb2s(structuralBehavior) << ", " << ((int) bindingPriority)
     << ") {}\n";
  to << "\n";
  to << "  static const TypeInfoOf<" << name << ">* const instance() {\n";
  to << "    return &RawType<" << name << ">::rawType;\n";
  to << "  }\n";
  to << "\n";
  to << "  static Type type() {\n";
  to << "    return Type(instance());\n";
  to << "  }\n";

  if (hasGetTypeAtom) {
    to << "\n";
    to << "  atom_t getTypeAtom(VM vm) const {\n";
    to << "    return " << name << "::getTypeAtom(vm);\n";
    to << "  }\n";
  }

  if (hasPrintReprToStream) {
    to << "\n";
    to << "  inline\n";
    to << "  void printReprToStream(VM vm, RichNode self, std::ostream& out,\n";
    to << "                         int depth, int width) const;\n";
  }

  if (hasSerialize) {
    to << "\n";
    to << "  inline\n";
    to << "  UnstableNode serialize(VM vm, SE s, RichNode from) const;\n";
  }

  if (hasGlobalize) {
    to << "\n";
    to << "  inline\n";
    to << "  GlobalNode* globalize(VM vm, RichNode from) const;\n";
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

  if (feature) {
    to << "\n";
    to << "  inline\n";
    to << "  int compareFeatures(VM vm, RichNode lhs, RichNode rhs) const;\n";
  }

  to << "};\n";

  to << "\n";

  to << "template <>\n";
  to << "class TypedRichNode<" << name << ">: public BaseTypedRichNode {\n";
  to << "public:\n";
  to << "  explicit TypedRichNode(RichNode self) : BaseTypedRichNode(self) {}\n";

  // Hack to include methods in DataTypeStorageHelper
  if (storageKind == skWithArray) {
    to << "\n";
    to << "  inline\n";
    to << "  size_t getArraySize();\n";
    to << "\n";
    to << "  inline\n";
    to << "  StaticArray<" << storageElement << "> getElementsArray();\n";
    to << "\n";
    to << "  inline\n";
    to << "  " << storageElement << "& getElements(size_t i);\n";
  }

  for (auto method = methods.begin(); method != methods.end(); ++method) {
    to << "\n";

    if (method->funTemplate != nullptr) {
      to << "  ";
      printTemplateParameters(to, method->funTemplate->getTemplateParameters());
      to << "\n";
    }

    to << "  inline\n";
    to << "  " << method->resultType << " " << method->name << "("
       << method->formals << ");\n";
  }

  to << "};\n";
}

void ImplementationDef::makeOutput(llvm::raw_fd_ostream& to) {
  std::string className = std::string("TypeInfoOf<") + name + ">";

  std::string access = "_self.access<" + name + ">().";

  if (hasPrintReprToStream) {
    to << "\n";
    to << "void " << className
       << "::printReprToStream(VM vm, RichNode self, std::ostream& out,\n";
    to << "                    int depth, int width) const {\n";
    to << "  assert(self.is<" << name << ">());\n";
    to << "  self.as<" << name
       << ">().printReprToStream(vm, out, depth, width);\n";
    to << "}\n";
  }

  if (hasSerialize) {
    to << "\n";
    to << "UnstableNode " << className
       << "::serialize(VM vm, SE s, RichNode from) const {\n";
    to << "  assert(from.is<" << name << ">());\n";
    to << "  return from.as<" << name << ">().serialize(vm, s);\n";
    to << "}\n";
  }

  if (hasGlobalize) {
    to << "\n";
    to << "GlobalNode* " << className
       << "::globalize(VM vm, RichNode from) const {\n";
    to << "  assert(from.is<" << name << ">());\n";
    to << "  return from.as<" << name << ">().globalize(vm);\n";
    to << "}\n";
  }

  if (autoGCollect) {
    to << "\n";
    to << "void " << className
       << "::gCollect(GC gc, RichNode from, StableNode& to) const {\n";
    makeContentsOfAutoGCollect(to, true);
    to << "}\n\n";

    to << "void " << className
       << "::gCollect(GC gc, RichNode from, UnstableNode& to) const {\n";
    makeContentsOfAutoGCollect(to, false);
    to << "}\n";
  }

  if (autoSClone) {
    to << "\n";
    to << "void " << className
       << "::sClone(SC sc, RichNode from, StableNode& to) const {\n";
    makeContentsOfAutoSClone(to, true);
    to << "}\n\n";

    to << "void " << className
       << "::sClone(SC sc, RichNode from, UnstableNode& to) const {\n";
    makeContentsOfAutoSClone(to, false);
    to << "}\n";
  }

  if (feature) {
    to << "\n";
    to << "int " << className
       << "::compareFeatures(VM vm, RichNode lhs, RichNode rhs) const {\n";
    to << "  return lhs.as<" << name << ">().compareFeatures(vm, rhs);\n";
    to << "}\n\n";
  }

  // Hack to include methods in DataTypeStorageHelper
  if (storageKind == skWithArray) {
    to << "\n";
    to << "size_t TypedRichNode<" << name << ">::getArraySize() {\n";
    to << "  return " << access << "getArraySize();\n";
    to << "}\n";
    to << "\n";
    to << "StaticArray<" << storageElement << "> TypedRichNode<"
       << name << ">::getElementsArray() {\n";
    to << "  return " << access << "getElementsArray();\n";
    to << "}\n";
    to << "\n";
    to << "" << storageElement << "& TypedRichNode<"
       << name << ">::getElements(size_t i) {\n";
    to << "  return " << access << "getElements(i);\n";
    to << "}\n";
  }

  for (auto method = methods.begin(); method != methods.end(); ++method) {
    to << "\n";

    if (method->funTemplate != nullptr) {
      printTemplateParameters(to, method->funTemplate->getTemplateParameters());
      to << "\n";
    }

    to << "inline\n";
    to << method->resultType << " "
       << " TypedRichNode<" << name << ">::" << method->name << "("
       << method->formals << ") {\n";

    to << "  ";
    if (!method->function->getReturnType().getTypePtr()->isVoidType())
      to << "return ";

    to << access << method->name;
    if (method->funTemplate != nullptr)
      printActualTemplateParameters(to, method->funTemplate->getTemplateParameters());
    to << "(";

    if (method->hasSelfParam) {
      to << "_self";
      if (!method->actuals.empty())
        to << ", ";
    }

    to << method->actuals;

    to << ");\n";

    to << "}\n";
  }
}

void ImplementationDef::makeContentsOfAutoGCollect(llvm::raw_fd_ostream& to,
                                                   bool toStableNode) {
  to << "  assert(from.type() == type());\n";

  std::string toPrefix = "to.";

  if (!toStableNode && requiresStableNodeInGR()) {
    to << "  StableNode* stable = new (gc->vm) StableNode;\n";
    to << "  to.make<Reference>(gc->vm, stable);\n";
    toPrefix = "stable->";
  }

  to << "  " << toPrefix << "make<" << name << ">(gc->vm, ";
  if (storageKind == skWithArray)
    to << "from.as<" << name << ">().getArraySize(), ";
  to << "gc, from.access<" << name << ">());\n";
}

void ImplementationDef::makeContentsOfAutoSClone(llvm::raw_fd_ostream& to,
                                                 bool toStableNode) {
  to << "  assert(from.type() == type());\n";

  std::string cloneStatement = std::string("make<") + name + ">(sc->vm, ";
  if (storageKind == skWithArray)
    cloneStatement += "from.as<" + name + ">().getArraySize(), ";
  cloneStatement += "sc, from.access<" + name + ">());";

  if (!toStableNode && requiresStableNodeInGR()) {
    cloneStatement = std::string("stable->") + cloneStatement;
    cloneStatement = std::string(
      "StableNode* stable = new (sc->vm) StableNode;\n"
      "to.make<Reference>(sc->vm, stable);\n") + cloneStatement;
  } else {
    cloneStatement = std::string("to.") + cloneStatement;
  }

  if (withHome) {
    to << "  if (from.as<" << name << ">().home()->shouldBeCloned()) {\n";
    to << "    " << cloneStatement << "\n";
    to << "  } else {\n";
    to << "    to.init(sc->vm, from);\n";
    to << "  }\n";
  } else {
    switch (this->structuralBehavior) {
      case sbValue:
      case sbStructural: {
        to << "  " << cloneStatement << "\n";
        break;
      }

      case sbTokenEq:
      case sbVariable: {
        // Actually, these have a home, but it's always the top-level
        to << "  to.init(sc->vm, from);\n";
        break;
      }
    }
  }
}
