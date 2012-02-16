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

struct ImplementationDef {
  ImplementationDef() {
    name = "";
    copiable = false;
    transient = false;
    storage = "";
    base = "Type";
  }

  void makeOutputDecl(llvm::raw_fd_ostream& to);
  void makeOutput(llvm::raw_fd_ostream& to);

  std::string name;
  bool copiable;
  bool transient;
  std::string storage;
  std::string base;
};

void handleImplementation(const SpecDecl* ND) {
  const std::string name = getTypeParamAsString(ND);

  ImplementationDef definition;
  definition.name = name;

  // For every marker, i.e. base class
  for (auto iter = ND->bases_begin(), e = ND->bases_end(); iter != e; ++iter) {
    CXXRecordDecl* marker = iter->getType()->getAsCXXRecordDecl();
    std::string markerLabel = marker->getNameAsString();

    if (markerLabel=="Copiable") {
      definition.copiable = true;
    } else if (markerLabel == "Transient") {
      definition.transient = true;
    } else if (markerLabel == "StoredAs") {
      definition.storage = getTypeParamAsString(marker);
    } else if (markerLabel == "StoredWithArrayOf") {
      definition.storage = "ImplWithArray<Implementation<" + name + ">, " +
        getTypeParamAsString(marker) + ">";
    } else if (markerLabel == "BasedOn") {
      definition.base = getTypeParamAsString(marker);
    } else {}
  }

  {
    std::string err;
    llvm::raw_fd_ostream to((name+"-implem-decl.hh").c_str(), err);
    assert(err == "");
    definition.makeOutputDecl(to);
  }

  {
    std::string err;
    llvm::raw_fd_ostream to((name+"-implem.hh").c_str(), err);
    assert(err == "");
    definition.makeOutput(to);
  }
}

void ImplementationDef::makeOutputDecl(llvm::raw_fd_ostream& to) {
  if (storage != "") {
    to << "template <>\n";
    to << "class Storage<" << name << "> {\n";
    to << "public:\n";
    to << "  typedef " << storage << " Type;\n";
    to << "};\n\n";
  }

  to << "class " << name << ": public " << base << " {\n";
  to << "public:\n";
  to << "  " << name << "() : " << base << "(\"" << name << "\", "
     << b2s(copiable) << ", " << b2s(transient) <<") {}\n";
  to << "\n";
  to << "  static const " << name << "* const type() {\n";
  to << "    static const " << name << " rawType;\n";
  to << "    return &rawType;\n";
  to << "  }\n";
  to << "};\n";
}

void ImplementationDef::makeOutput(llvm::raw_fd_ostream& to) {
}
