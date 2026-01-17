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

clang::ASTContext* context;

enum GenMode {
  gmIntfImpl, gmBuiltins
};

GenMode mode;

bool baseIsNotModule(const CXXRecordDecl* base, void* data) {
  return base->getNameAsString() != "Module";
}

void processDeclContext(const std::string outputDir, const DeclContext* ds,
                        llvm::raw_fd_ostream* builtinHeaderFile,
                        llvm::raw_fd_ostream* builtinCodeFile,
                        llvm::raw_fd_ostream* emulateInlineTo) {
  for (auto iter = ds->decls_begin(), e = ds->decls_end(); iter != e; ++iter) {
    Decl* decl = *iter;

    if (const SpecDecl* ND = dyn_cast<SpecDecl>(decl)) {
      if (mode == gmIntfImpl) {
        /* It's a template specialization decl, might be an
         * Interface<T> that we must process. */
        if (ND->getNameAsString() == "Interface") {
          handleInterface(outputDir, ND);
        }
      }
    } else if (const ClassDecl* CD = dyn_cast<ClassDecl>(decl)) {
      if (mode == gmIntfImpl) {
        if (isImplementationClass(CD)) {
          handleImplementation(outputDir, CD);
        }
      } else if (mode == gmBuiltins) {
        if (isModuleClass(CD)) {
          handleBuiltinModule(outputDir, CD,
                              *builtinHeaderFile, *builtinCodeFile,
                              emulateInlineTo);
        }
      }
    } else if (const NamespaceDecl* nsDecl = dyn_cast<NamespaceDecl>(decl)) {
      /* It's a namespace, recurse in it. */
      processDeclContext(outputDir, nsDecl,
                         builtinHeaderFile, builtinCodeFile,
                         emulateInlineTo);
    }
  }
}

int main(int argc, char* argv[]) {
  CompilerInstance CI;

  std::string modeStr = argv[1];
  std::string astFile = argv[2];
  std::string outputDir = argv[3];
  std::string builtinFileName;

  std::unique_ptr<ostream> builtinHeaderFile = nullptr;
  std::unique_ptr<ostream> builtinCodeFile = nullptr;
  std::unique_ptr<ostream> emulateInlineTo = nullptr;

  // Parse mode
  if (modeStr == "intfimpl") {
    mode = gmIntfImpl;
  } else if (modeStr == "builtins") {
    mode = gmBuiltins;
    builtinFileName = argv[4];
    builtinHeaderFile = openFileOutputStream(outputDir + builtinFileName + ".hh");
    builtinCodeFile = openFileOutputStream(outputDir + builtinFileName + ".cc");
    if (builtinFileName == "mozartbuiltins")
      emulateInlineTo = openFileOutputStream(outputDir + "emulate-inline.cc");
  } else {
    std::cerr << "Unknown generator mode: " << modeStr << std::endl;
    return 1;
  }

  // Parse source file
  CI.createDiagnostics();
  IntrusiveRefCntPtr<DiagnosticsEngine> Diags(&CI.getDiagnostics());
  std::unique_ptr<ASTUnit> unit =
      ASTUnit::LoadFromASTFile(astFile,
                               CI.getPCHContainerReader(),
                               clang::ASTUnit::WhatToLoad::LoadASTOnly,
                               Diags,
                               CI.getFileSystemOpts());

  // Setup printing policy
  // We want the bool type to be printed as "bool"
  context = &(unit->getASTContext());
  PrintingPolicy policy = context->getPrintingPolicy();
  policy.Bool=1;
  context->setPrintingPolicy(policy);

  // Process
  processDeclContext(outputDir, context->getTranslationUnitDecl(),
                     builtinHeaderFile.get(), builtinCodeFile.get(),
                     emulateInlineTo.get());
}
