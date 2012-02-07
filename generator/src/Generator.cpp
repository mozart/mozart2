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

#include "clang/Frontend/FrontendPluginRegistry.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/AST.h"
#include "clang/AST/DeclTemplate.h"
#include "clang/Frontend/CompilerInstance.h"
#include "llvm/Support/raw_ostream.h"
using namespace clang;

namespace {
class ExtractInterfacesConsumer : public ASTConsumer {
  ASTContext *context;
  typedef ClassTemplateSpecializationDecl SpecDecl;
public:
  virtual void Initialize(ASTContext& c){
    context=&c;
  }
  virtual void HandleTopLevelDecl(DeclGroupRef DG) {
    for (DeclGroupRef::iterator i = DG.begin(), e = DG.end(); i != e; ++i) {
      const SpecDecl* ND = dyn_cast<SpecDecl>(*i);
      if(!ND) continue;
      if(ND->getNameAsString()!="Interface") continue;
      const TemplateArgumentList& L=ND->getTemplateArgs();
      assert(L.size()==1);
      assert(L[0].getKind()==TemplateArgument::Type);
      const std::string name=
	dyn_cast<TagType>(L[0].getAsType().getTypePtr())
	->getDecl()->getNameAsString();
      const TemplateSpecializationType& implems=
	*dyn_cast<TemplateSpecializationType>(ND->bases_begin()
					      ->getType().getTypePtr());
      std::string err;
      llvm::raw_fd_ostream to((name+"-interf.hh").c_str(),err);
      assert(err=="");
      makeInterface(ND, name, implems, to);
    }
  }
private:
  void makeInterface(const SpecDecl* ND,
		     std::string name,
		     const TemplateSpecializationType& implems,
		     llvm::raw_fd_ostream& to){
    to << "class "<< name << " {\n";
    to << "public:\n";
    to << "  " << name << "(Node& self) : _self(Reference::dereference(self)) {}\n";
    for(CXXRecordDecl::method_iterator i=ND->method_begin(), e=ND->method_end();
	i!=e;
	++i) {
      CXXMethodDecl* m=*i;
      if(!m->isUserProvided())continue;
      to << "\n  " << m->getResultType().getAsString(context->getPrintingPolicy());
      to << " " << m->getNameAsString() << "(";
      for(FunctionDecl::param_iterator j=(m->param_begin())+1, e=m->param_end();
	  (j!=e);
	  ++j,(j!=e)?to<<", ":to) {
	ParmVarDecl* p=*j;
	to << p->getType().getAsString(context->getPrintingPolicy());
	to << " " << p->getNameAsString();
      }
      to << "){\n    ";
      for(int j=0; j<(int)implems.getNumArgs(); ++j) {
	std::string imp=
	  implems.getArg(j).getAsType()->getAsCXXRecordDecl()->getNameAsString();
	to << "if (_self.type == " << imp << "::type) {\n";
	to << "      return IMPL(" 
	   << m->getResultType().getAsString(context->getPrintingPolicy())
	   << ", " << imp << ", " << m->getNameAsString() << ", " << "&_self";
	for(FunctionDecl::param_iterator j=(m->param_begin())+1, e=m->param_end();
	    (j!=e);
	    ++j) {
	  ParmVarDecl* p=*j;
	  to << ", " << p->getNameAsString(); 
	}
	to << ");\n";
	to << "    } else ";
      }
      to << "{\n";
      to << "      return Interface<" << name << ">().";
      to << m->getNameAsString() << "(_self";
      for(FunctionDecl::param_iterator j=(m->param_begin())+1, e=m->param_end();
	  (j!=e);
	  ++j) {
	ParmVarDecl* p=*j;
	to << ", " << p->getNameAsString();
      }
      to << ");\n";
      to << "    }\n";
      to << "  }\n";
    }
    to << "private:\n";
    to << "  Node& _self;\n";
    to << "};\n\n";
  }
};

class ExtractInterfacesAction : public PluginASTAction {
protected:
  ASTConsumer *CreateASTConsumer(CompilerInstance &CI, llvm::StringRef) {
    return new ExtractInterfacesConsumer();
  }
  bool ParseArgs(const CompilerInstance &CI,
                 const std::vector<std::string>& args) {
    return true;
  }
};

}

static FrontendPluginRegistry::Add<ExtractInterfacesAction>
X("ext-inf", "extract Mozart interfaces");
