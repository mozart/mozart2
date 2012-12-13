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

enum ParamKind {
  pkIn, pkOut
};

struct BuiltinParam {
  BuiltinParam(): kind(pkIn) {}

  void makeOutput(llvm::raw_fd_ostream& to);

  ParamKind kind;
  std::string name;
};

struct ModuleDef;

struct BuiltinDef {
  BuiltinDef(ModuleDef& module, const ClassDecl* classDecl):
    module(module), classDecl(classDecl) {

    cppName = classDecl->getNameAsString();
    fullCppName = classDecl->getQualifiedNameAsString();
    nameExpr = nullptr;
    inlineable = false;
    inlineOpCode = 0;

    initFullCppGetter();
  }

  inline
  void initFullCppGetter();

  void makeOutput(llvm::raw_fd_ostream& to);
  void makeEmulateInlinesOutput(llvm::raw_fd_ostream& to);
  void makeBuiltinDefsOutput(llvm::raw_fd_ostream& header,
                             llvm::raw_fd_ostream& code);

  ModuleDef& module;

  const ClassDecl* classDecl;
  std::string cppName;
  std::string fullCppName;
  std::string fullCppGetter;
  const Expr* nameExpr;

  std::vector<BuiltinParam> params;

  bool inlineable;
  size_t inlineOpCode;
};

struct ModuleDef {
  ModuleDef(const ClassDecl* classDecl): classDecl(classDecl) {
    cppName = classDecl->getNameAsString();
    fullCppName = classDecl->getQualifiedNameAsString();
    nameExpr = nullptr;
  }

  void makeOutput(llvm::raw_fd_ostream& to);
  void makeEmulateInlinesOutput(llvm::raw_fd_ostream& to);
  void makeBuiltinDefsOutput(llvm::raw_fd_ostream& header,
                             llvm::raw_fd_ostream& code);

  const ClassDecl* classDecl;
  std::string cppName;
  std::string fullCppName;
  const Expr* nameExpr;

  std::vector<BuiltinDef> builtins;
};

void BuiltinDef::initFullCppGetter() {
  fullCppGetter =
    module.fullCppName.substr(0, module.fullCppName.rfind(':')+1) +
    "biref::" + module.cppName + "::" + cppName + "::get";
}

bool isTheModuleClass(const ClassDecl* cls) {
  return isTheClass(cls, "mozart::builtins::Module");
}

bool isModuleClass(const ClassDecl* cls) {
  return existsBaseClassSuchThat(cls, isTheModuleClass);
}

bool isInstantiationOfBuiltin(const ClassDecl* cls) {
  return isAnInstantiationOfTheTemplate(cls, "mozart::builtins::Builtin");
}

bool isBuiltinClass(const ClassDecl* cls) {
  return existsBaseClassSuchThat(cls, isInstantiationOfBuiltin);
}

bool extractNameFromDefaultConstructor(
  const CXXConstructorDecl* constr,
  const std::function<bool(const ClassDecl*)>& testBase,
  const Expr*& nameExpr) {

  for (auto iter = constr->init_begin(), e = constr->init_end();
       iter != e; ++iter) {
    const CXXCtorInitializer* init = *iter;

    if (const Type* base = init->getBaseClass()) {
      if (testBase(base->getAsCXXRecordDecl())) {
        nameExpr = init->getInit();
        return true;
      }
    }
  }

  return false;
}

void processBuiltinCallOperator(BuiltinDef& definition,
                                const CXXMethodDecl* method) {
  for (auto iter = method->param_begin()+1, e = method->param_end();
       iter != e; ++iter) {
    ParmVarDecl* param = *iter;
    BuiltinParam paramDef;

    std::string paramType = param->getType().getAsString();

    if (paramType == "In")
      paramDef.kind = pkIn;
    else if (paramType == "Out")
      paramDef.kind = pkOut;
    else
      assert(false);

    paramDef.name = param->getNameAsString();

    definition.params.push_back(paramDef);
  }
}

void handleBuiltin(BuiltinDef& definition, const ClassDecl* CD) {
  std::string name = CD->getNameAsString();

  // For every marker, i.e. base class
  for (auto iter = CD->bases_begin(), e = CD->bases_end(); iter != e; ++iter) {
    CXXRecordDecl* marker = iter->getType()->getAsCXXRecordDecl();
    std::string markerLabel = marker->getNameAsString();

    if (markerLabel == "InlineAs") {
      definition.inlineable = true;
      definition.inlineOpCode = getValueParamAsIntegral<size_t>(marker);
    }
  }

  for (auto iter = CD->decls_begin(), e = CD->decls_end(); iter != e; ++iter) {
    auto decl = *iter;

    if (const CXXConstructorDecl* constr = dyn_cast<CXXConstructorDecl>(decl)) {
      // Constructor of the module
      if (constr->isDefaultConstructor()) {
        const Expr* nameExpr;
        if (extractNameFromDefaultConstructor(constr, isInstantiationOfBuiltin,
                                              nameExpr))
          definition.nameExpr = nameExpr;
      }
    } else if (const CXXMethodDecl* method = dyn_cast<CXXMethodDecl>(decl)) {
      if (method->getOverloadedOperator() == OO_Call) {
        processBuiltinCallOperator(definition, method);
      }
    }
  }
}

void handleBuiltinModule(const std::string& outputDir, const ClassDecl* CD,
                         llvm::raw_fd_ostream& builtinHeaderFile,
                         llvm::raw_fd_ostream& builtinCodeFile,
                         llvm::raw_fd_ostream* emulateInlinesTo) {
  std::string name = CD->getNameAsString();

  ModuleDef definition(CD);

  for (auto iter = CD->decls_begin(), e = CD->decls_end(); iter != e; ++iter) {
    auto decl = *iter;

    if (const CXXConstructorDecl* constr = dyn_cast<CXXConstructorDecl>(decl)) {
      // Constructor of the module
      if (constr->isDefaultConstructor()) {
        const Expr* nameExpr;
        if (extractNameFromDefaultConstructor(constr, isTheModuleClass,
                                              nameExpr))
          definition.nameExpr = nameExpr;
      }
    } else if (const ClassDecl* innerClass = dyn_cast<ClassDecl>(decl)) {
      // Inner class, maybe it's a builtin
      if (isBuiltinClass(innerClass)) {
        BuiltinDef builtinDef(definition, innerClass);
        handleBuiltin(builtinDef, innerClass);
        definition.builtins.push_back(builtinDef);
      }
    }
  }

  {
    std::string err;
    llvm::raw_fd_ostream to((outputDir+name+"-builtin.json").c_str(), err);
    assert(err == "");
    definition.makeOutput(to);
  }

  definition.makeBuiltinDefsOutput(builtinHeaderFile, builtinCodeFile);

  if (emulateInlinesTo != nullptr)
    definition.makeEmulateInlinesOutput(*emulateInlinesTo);
}

void BuiltinParam::makeOutput(llvm::raw_fd_ostream& to) {
  to << "        {\n";
  to << "          \"name\": \"" << name << "\",\n";

  to << "          \"kind\": \"";
  switch (kind) {
    case pkIn: to << "In"; break;
    case pkOut: to << "Out"; break;
  }
  to << "\"\n";

  to << "        }";
}

void BuiltinDef::makeOutput(llvm::raw_fd_ostream& to) {
  to << "    {\n";
  to << "      \"fullCppName\": \"" << fullCppName << "\",\n";
  to << "      \"fullCppGetter\": \"" << fullCppGetter << "\",\n";

  to << "      \"name\": ";
  nameExpr->printPretty(to, nullptr, context->getPrintingPolicy());
  to << ",\n";

  to << "      \"inlineable\": " << b2s(inlineable) << ",\n";
  if (inlineable)
    to << "      \"inlineOpCode\": " << inlineOpCode << ",\n";

  to << "      \"params\": [\n";
  for (auto iter = params.begin(); iter != params.end(); ++iter) {
    if (iter != params.begin())
      to << ",\n";
    iter->makeOutput(to);
  }
  to << "\n      ]\n";

  to << "    }";
}

void ModuleDef::makeOutput(llvm::raw_fd_ostream& to) {
  to << "{\n";
  to << "  \"fullCppName\": \"" << fullCppName << "\",\n";

  to << "  \"name\": ";
  nameExpr->printPretty(to, nullptr, context->getPrintingPolicy());
  to << ",\n";

  to << "  \"builtins\": [\n";

  for (auto iter = builtins.begin(); iter != builtins.end(); ++iter) {
    if (iter != builtins.begin())
      to << ",\n";
    iter->makeOutput(to);
  }

  to << "\n  ]\n";
  to << "}\n";
}

void BuiltinDef::makeEmulateInlinesOutput(llvm::raw_fd_ostream& to) {
  if (!inlineable)
    return;

  to << "\n";
  to << "case " << inlineOpCode << ": {\n";
  to << "  ::" << fullCppName << "::builtin()(\n";
  to << "    vm";

  for (size_t i = 1; i <= params.size(); i++)
    to << ", XPC(" << i << ")";

  to << ");\n";
  to << "  advancePC(" << params.size() << ");\n";
  to << "  break;\n";
  to << "}\n";
}

void ModuleDef::makeEmulateInlinesOutput(llvm::raw_fd_ostream& to) {
  for (auto iter = builtins.begin(); iter != builtins.end(); ++iter)
    iter->makeEmulateInlinesOutput(to);
}

void BuiltinDef::makeBuiltinDefsOutput(llvm::raw_fd_ostream& header,
                                       llvm::raw_fd_ostream& code) {
  header << "  struct " << cppName << " {\n";
  header << "    static ::mozart::builtins::BaseBuiltin& get(VM vm);\n";
  header << "  };\n";

  code << "\n";
  code << "::mozart::builtins::BaseBuiltin& " << module.cppName << "::"
       << cppName << "::get(VM vm) {\n";
  code << "  return " << fullCppName << "::builtin();\n";
  code << "}\n";
}

void ModuleDef::makeBuiltinDefsOutput(llvm::raw_fd_ostream& header,
                                      llvm::raw_fd_ostream& code) {
  header << "\nnamespace biref {\n\n";
  header << "void registerBuiltin" << cppName << "(::mozart::VM vm);\n";
  header << "\n}\n";

  code << "\nnamespace biref {\n";
  code << "using namespace ::mozart;\n";

  code << "\nclass " << cppName << ": public BuiltinModule {\n";
  code << "public:\n";
  code << "  " << cppName << "(VM vm): BuiltinModule(vm, MOZART_STR(";
  nameExpr->printPretty(code, nullptr, context->getPrintingPolicy());
  code << ")) {\n";

  code << "    UnstableField fields[" << builtins.size() << "];\n";

  size_t i = 0;
  for (auto iter = builtins.begin(); iter != builtins.end(); ++iter, ++i) {
    code << "    fields[" << i << "].feature = build(vm, MOZART_STR(";
    iter->nameExpr->printPretty(code, nullptr, context->getPrintingPolicy());
    code << "));\n";

    code << "    fields[" << i << "].value = build(vm, instance"
         << iter->cppName << ");\n";
  }

  code << "    UnstableNode label = build(vm, MOZART_STR(\"export\"));\n";
  code << "    UnstableNode module = buildRecordDynamic(vm, label, "
       << builtins.size() << ", fields);\n";
  code << "    initModule(vm, std::move(module));\n";
  code << "  }\n";

  code << "private:\n";

  for (auto iter = builtins.begin(); iter != builtins.end(); ++iter) {
    code << "  " << iter->fullCppName << " instance" << iter->cppName << ";\n";
  }

  code << "};\n";

  code << "void registerBuiltin" << cppName << "(VM vm) {\n";
  code << "  auto module = std::make_shared<" << cppName << ">(vm);\n";
  code << "  vm->registerBuiltinModule(module);\n";
  code << "}\n";

  code << "\n}\n";
}
