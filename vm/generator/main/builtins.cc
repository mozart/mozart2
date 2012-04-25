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

struct BuiltinDef {
  BuiltinDef(const ClassDecl* classDecl): classDecl(classDecl) {
    fullCppName = classDecl->getQualifiedNameAsString();
    nameExpr = nullptr;
  }

  void makeOutput(llvm::raw_fd_ostream& to);

  const ClassDecl* classDecl;
  std::string fullCppName;
  const Expr* nameExpr;

  std::vector<BuiltinParam> params;
};

struct ModuleDef {
  ModuleDef(const ClassDecl* classDecl): classDecl(classDecl) {
    fullCppName = classDecl->getQualifiedNameAsString();
    nameExpr = nullptr;
  }

  void makeOutput(llvm::raw_fd_ostream& to);

  const ClassDecl* classDecl;
  std::string fullCppName;
  const Expr* nameExpr;

  std::vector<BuiltinDef> builtins;
};

bool isTheModuleClass(const ClassDecl* decl) {
  if (!isa<SpecDecl>(decl)) {
    if (decl->getQualifiedNameAsString() == "mozart::builtins::Module")
      return true;
  }

  return false;
}

bool isInstantiationOfBuiltin(const ClassDecl* decl) {
  if (const SpecDecl* spec = dyn_cast<SpecDecl>(decl)) {
    auto tpl = spec->getInstantiatedFrom();
    if (tpl.is<ClassTemplateDecl*>()) {
      if (tpl.get<ClassTemplateDecl*>()->getQualifiedNameAsString() ==
          "mozart::builtins::Builtin") {
        return true;
      }
    }
  }

  return false;
}

typedef bool (*ClassDeclPred)(const ClassDecl*);

bool existsBaseClassSuchThat(const ClassDecl* cls,
                             ClassDeclPred testBase) {
  if (!cls || !cls->isCompleteDefinition())
    return false;

  for (auto iter = cls->bases_begin(), e = cls->bases_end();
       iter != e; ++iter) {
    if (const ClassDecl* base = iter->getType()->getAsCXXRecordDecl()) {
      if (testBase(base))
        return true;
    }
  }

  return false;
}

bool isModuleClass(const ClassDecl* cls) {
  return existsBaseClassSuchThat(cls, isTheModuleClass);
}

bool isBuiltinClass(const ClassDecl* cls) {
  return existsBaseClassSuchThat(cls, isInstantiationOfBuiltin);
}

bool extractNameFromDefaultConstructor(const CXXConstructorDecl* constr,
                                       ClassDeclPred testBase,
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

void handleBuiltinModule(const std::string outputDir, const ClassDecl* CD) {
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
        BuiltinDef builtinDef(innerClass);
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

  to << "      \"name\": ";
  nameExpr->printPretty(to, nullptr, context->getPrintingPolicy());
  to << ",\n";

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
