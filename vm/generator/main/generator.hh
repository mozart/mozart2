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

#include <clang/Frontend/ASTUnit.h>
#include <clang/AST/DeclTemplate.h>

typedef clang::ClassTemplateSpecializationDecl SpecDecl;

std::string typeToString(clang::QualType type);

std::string getTypeParamAsString(const SpecDecl* specDecl);
std::string getTypeParamAsString(clang::CXXRecordDecl* arg);

template <class T>
T getValueParamAsIntegral(const SpecDecl* specDecl) {
  const clang::TemplateArgumentList& templateArgs = specDecl->getTemplateArgs();

  assert(templateArgs.size() == 1);
  assert(templateArgs[0].getKind() == clang::TemplateArgument::Integral);

  auto result = templateArgs[0].getAsIntegral()->getLimitedValue(
    std::numeric_limits<T>::max());

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

void handleInterface(const SpecDecl* ND);
void handleImplementation(const SpecDecl* ND);

extern clang::ASTContext* context;
