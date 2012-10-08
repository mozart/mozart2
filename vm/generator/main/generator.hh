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

#include <cstdlib>
#include <iostream>
#include <functional>
#include <string>

#include <clang/Frontend/ASTUnit.h>
#include <clang/AST/DeclTemplate.h>

typedef clang::ClassTemplateSpecializationDecl SpecDecl;
typedef clang::CXXRecordDecl ClassDecl;

typedef llvm::raw_fd_ostream ostream;

inline
void checkErrString(const std::string& err) {
  if (!err.empty()) {
    llvm::errs() << err << "\n";
    exit(1);
  }
}

inline
std::unique_ptr<ostream> openFileOutputStream(const std::string& fileName) {
  std::string err;
  auto result = std::unique_ptr<ostream>(new ostream(fileName.c_str(), err));
  checkErrString(err);

  return result;
}

inline
void withFileOutputStream(const std::string& fileName,
                          std::function<void (ostream&)> body) {
  std::string err;
  ostream stream(fileName.c_str(), err);
  checkErrString(err);

  body(stream);
}

std::string typeToString(clang::QualType type);

bool isTheClass(const ClassDecl* cls,
                const std::string& fullClassName);

bool isAnInstantiationOfTheTemplate(const ClassDecl* cls,
                                    const std::string& fullClassTemplateName);

bool existsBaseClassSuchThat(
  const ClassDecl* cls,
  const std::function<bool(const ClassDecl*)>& testBase);

std::string getTypeParamAsString(const SpecDecl* specDecl,
                                 bool basicName = true);
std::string getTypeParamAsString(clang::CXXRecordDecl* arg,
                                 bool basicName = true);

void printTemplateParameters(llvm::raw_fd_ostream& Out,
  const clang::TemplateParameterList *Params,
  const clang::TemplateArgumentList *Args = 0);

void parseFunction(const clang::FunctionDecl* function,
                   std::string& name, std::string& resultType,
                   std::string& formalParams, std::string& actualParams,
                   bool hasSelfParam);

namespace internal {
  template <class T>
  struct Dereferencer {
    static T deref(T&& value) {
      return std::forward<T>(value);
    }
  };

  template <class T>
  struct Dereferencer<T*&&> {
    static T& deref(T* value) {
      return *value;
    }
  };

  template <class T>
  inline
  auto dereference(T&& value) ->
      decltype(Dereferencer<decltype(std::forward<T>(value))>::deref(std::forward<T>(value))) {
    return Dereferencer<decltype(std::forward<T>(value))>::deref(std::forward<T>(value));
  }
}

template <class T>
T getValueParamAsIntegral(const SpecDecl* specDecl) {
  const clang::TemplateArgumentList& templateArgs = specDecl->getTemplateArgs();

  assert(templateArgs.size() == 1);
  assert(templateArgs[0].getKind() == clang::TemplateArgument::Integral);

  auto&& integralArg = internal::dereference(templateArgs[0].getAsIntegral());
  auto result = integralArg.getLimitedValue(std::numeric_limits<T>::max());

  return (T) result;
}

template <class T>
T getValueParamAsIntegral(clang::CXXRecordDecl* arg) {
  return getValueParamAsIntegral<T>(clang::dyn_cast<SpecDecl>(arg));
}

inline
std::string b2s(bool value) {
  return value ? "true" : "false";
}

bool isImplementationClass(const ClassDecl* cls);
void handleImplementation(const std::string& outputDir, const ClassDecl* ND);

void handleInterface(const std::string& outputDir, const SpecDecl* ND);

bool isModuleClass(const ClassDecl* cls);
void handleBuiltinModule(const std::string& outputDir, const ClassDecl* CD,
                         llvm::raw_fd_ostream& builtinHeaderFile,
                         llvm::raw_fd_ostream& builtinCodeFile,
                         llvm::raw_fd_ostream* emulateInlinesTo);

extern clang::ASTContext* context;
