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

typedef ClassTemplateSpecializationDecl SpecDecl;

clang::ASTContext* context;

int main(int argc, char* argv[]) {
  llvm::IntrusiveRefCntPtr< DiagnosticsEngine > Diags;
  FileSystemOptions FileSystemOpts;
  ASTUnit *u = ASTUnit::LoadFromASTFile(std::string(argv[1]),
					Diags, FileSystemOpts,
					false, 0, 0, true);
  context = &(u->getASTContext());
  PrintingPolicy p = context->getPrintingPolicy();
  p.Bool=1;
  context->setPrintingPolicy(p);
  DeclContext* ds=context->getTranslationUnitDecl();
  for(DeclContext::decl_iterator i=ds->decls_begin(), e=ds->decls_end();
      i!=e; ++i) {
    Decl* D=*i;
    const SpecDecl* ND = dyn_cast<SpecDecl>(D);
    if(!ND) continue;
    if(ND->getNameAsString()=="Interface"){
      handleInterface(ND);
      continue;
    }
    if(ND->getNameAsString()=="Implementation"){
      handleImplementation(ND);
      continue;
    }
  }
}
