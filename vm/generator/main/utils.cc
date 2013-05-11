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

std::string basicTypeToString(QualType type) {
  if (isa<TagType>(type.getTypePtr()))
    return dyn_cast<TagType>(type.getTypePtr())->getDecl()->getNameAsString();
  else
    return type.getAsString(context->getPrintingPolicy());
}

std::string typeToString(QualType type) {
  return type.getAsString(context->getPrintingPolicy());
}

std::string getTypeParamAsString(const SpecDecl* specDecl, bool basicName) {
  const TemplateArgumentList& templateArgs = specDecl->getTemplateArgs();

  assert(templateArgs.size() == 1);
  assert(templateArgs[0].getKind() == TemplateArgument::Type);

  if (basicName)
    return basicTypeToString(templateArgs[0].getAsType());
  else
    return typeToString(templateArgs[0].getAsType());
}

std::string getTypeParamAsString(CXXRecordDecl* arg, bool basicName) {
  return getTypeParamAsString(dyn_cast<SpecDecl>(arg), basicName);
}

bool isTheClass(const ClassDecl* decl,
                const std::string& fullClassName) {
  if (!isa<SpecDecl>(decl)) {
    if (decl->getQualifiedNameAsString() == fullClassName)
      return true;
  }

  return false;
}

bool isAnInstantiationOfTheTemplate(const ClassDecl* decl,
                                    const std::string& fullClassTemplateName) {
  if (const SpecDecl* spec = dyn_cast<SpecDecl>(decl)) {
    auto tpl = spec->getInstantiatedFrom();
    if (auto classTplDecl = tpl.dyn_cast<ClassTemplateDecl*>()) {
      if (classTplDecl->getQualifiedNameAsString() == fullClassTemplateName) {
        return true;
      }
    }
  }

  return false;
}

bool existsBaseClassSuchThat(
  const ClassDecl* cls,
  const std::function<bool(const ClassDecl*)>& testBase) {

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

void printTemplateParameters(llvm::raw_fd_ostream& Out,
  const TemplateParameterList *Params, const TemplateArgumentList *Args) {

  assert(Params);
  assert(!Args || Params->size() == Args->size());

  ASTContext& Context = *context;
  PrintingPolicy Policy = Context.getPrintingPolicy();
  const int Indentation = 0;

  Out << "template <";

  for (unsigned i = 0, e = Params->size(); i != e; ++i) {
    if (i != 0)
      Out << ", ";

    const Decl *Param = Params->getParam(i);
    if (const TemplateTypeParmDecl *TTP =
          dyn_cast<TemplateTypeParmDecl>(Param)) {

      if (TTP->wasDeclaredWithTypename())
        Out << "typename ";
      else
        Out << "class ";

      if (TTP->isParameterPack())
        Out << "... ";

      Out << TTP->getNameAsString();

      if (Args) {
        Out << " = ";
        Args->get(i).print(Policy, Out);
      } else if (TTP->hasDefaultArgument()) {
        Out << " = ";
        Out << TTP->getDefaultArgument().getAsString(Policy);
      };
    } else if (const NonTypeTemplateParmDecl *NTTP =
                 dyn_cast<NonTypeTemplateParmDecl>(Param)) {
      Out << NTTP->getType().getAsString(Policy);

      if (NTTP->isParameterPack() && !isa<PackExpansionType>(NTTP->getType()))
        Out << "...";

      if (IdentifierInfo *Name = NTTP->getIdentifier()) {
        Out << ' ';
        Out << Name->getName();
      }

      if (Args) {
        Out << " = ";
        Args->get(i).print(Policy, Out);
      } else if (NTTP->hasDefaultArgument()) {
        Out << " = ";
        NTTP->getDefaultArgument()->printPretty(Out, 0, Policy,
                                                Indentation);
      }
    } else if (const TemplateTemplateParmDecl *TTPD =
                 dyn_cast<TemplateTemplateParmDecl>(Param)) {
      (void) TTPD;
      assert(false);
    }
  }

  Out << "> ";
}

void printActualTemplateParameters(llvm::raw_fd_ostream& Out,
  const TemplateParameterList *Params, const TemplateArgumentList *Args) {

  assert(Params);
  assert(!Args || Params->size() == Args->size());

  ASTContext& Context = *context;
  PrintingPolicy Policy = Context.getPrintingPolicy();

  Out << "<";

  for (unsigned i = 0, e = Params->size(); i != e; ++i) {
    if (i != 0)
      Out << ", ";

    const Decl *Param = Params->getParam(i);
    if (const TemplateTypeParmDecl *TTP =
          dyn_cast<TemplateTypeParmDecl>(Param)) {

      Out << TTP->getNameAsString();

      if (TTP->isParameterPack())
        Out << "... ";
    } else if (const NonTypeTemplateParmDecl *NTTP =
                 dyn_cast<NonTypeTemplateParmDecl>(Param)) {
      if (IdentifierInfo *Name = NTTP->getIdentifier()) {
        Out << ' ';
        Out << Name->getName();
      }

      if (NTTP->isParameterPack() && !isa<PackExpansionType>(NTTP->getType()))
        Out << "...";
    } else if (const TemplateTemplateParmDecl *TTPD =
                 dyn_cast<TemplateTemplateParmDecl>(Param)) {
      (void) TTPD;
      assert(false);
    }
  }

  Out << ">";
}

void parseFunction(const clang::FunctionDecl* function,
                   std::string& name, std::string& resultType,
                   std::string& formalParams, std::string& actualParams,
                   std::string& reflectActualParams,
                   bool hasSelfParam) {

  name = function->getNameAsString();
  resultType = typeToString(function->getResultType());

  auto param_begin = function->param_begin() + (hasSelfParam ? 1 : 0);
  auto param_end = function->param_end();

  std::stringstream formals;
  std::stringstream actuals;
  std::stringstream reflectActuals;

  for (auto iter = param_begin; iter != param_end; ++iter) {
    if (iter != param_begin) {
      formals << ", ";
      actuals << ", ";
      if (iter != param_begin+1)
        reflectActuals << ", ";
    }

    ParmVarDecl* param = *iter;
    auto paramType = param->getType();
    auto paramName = param->getNameAsString();

    // Formals is easy
    formals << typeToString(paramType) << " " << paramName;

    // Handle pack expansion
    bool isPackExpansion = false;
    if (const PackExpansionType* packType = paramType->getAs<PackExpansionType>()) {
      isPackExpansion = true;
      paramType = packType->getPattern();
    }

    // Handle std::forward
    bool needForward = false;
    std::string forwardArg;
    if (paramType->isRValueReferenceType()) {
      auto nonRefType = paramType.getNonReferenceType();
      if (nonRefType->isTemplateTypeParmType()) {
        needForward = true;
        forwardArg = nonRefType.getAsString();
      }
    }

    // Print it
    if (needForward) {
      actuals << "std::forward<" << forwardArg << ">(" << paramName << ")";
      reflectActuals << "std::forward<" << forwardArg << ">(" << paramName << ")";
    } else {
      actuals << paramName;

      if (iter != param_begin) {
        if (paramType->isLValueReferenceType())
          reflectActuals << "::mozart::ozcalls::out(" << paramName << ")";
        else
          reflectActuals << paramName;
      }
    }

    if (isPackExpansion) {
      actuals << "...";
      reflectActuals << "...";
    }
  }

  formalParams = formals.str();
  actualParams = actuals.str();
  reflectActualParams = reflectActuals.str();
}
