// Copyright © 2011, Université catholique de Louvain
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

#ifndef MOZART_COREATOMS_H
#define MOZART_COREATOMS_H

#include "mozartcore.hh"

namespace mozart {

void CoreAtoms::initialize(VM vm, AtomTable& atomTable) {
  empty = atomTable.get(vm, "");

  nil = atomTable.get(vm, "nil");
  pipe = atomTable.get(vm, "|");
  sharp = atomTable.get(vm, "#");

  int_ = atomTable.get(vm, "int");
  float_ = atomTable.get(vm, "float");
  bool_ = atomTable.get(vm, "bool");
  unit = atomTable.get(vm, "unit");
  atom = atomTable.get(vm, "atom");
  cons = atomTable.get(vm, "cons");
  tuple = atomTable.get(vm, "tuple");
  arity = atomTable.get(vm, "arity");
  record = atomTable.get(vm, "record");
  builtin = atomTable.get(vm, "builtin");
  codearea = atomTable.get(vm, "codearea");
  patmatwildcard = atomTable.get(vm, "patmatwildcard");
  patmatcapture = atomTable.get(vm, "patmatcapture");
  patmatconjunction = atomTable.get(vm, "patmatconjunction");
  patmatopenrecord = atomTable.get(vm, "patmatopenrecord");
  abstraction = atomTable.get(vm, "abstraction");
  chunk = atomTable.get(vm, "chunk");
  uniquename = atomTable.get(vm, "uniquename");
  name = atomTable.get(vm, "name");
  namedname = atomTable.get(vm, "namedname");
  unicodeString = atomTable.get(vm, "unicodeString");

  succeeded = atomTable.get(vm, "succeeded");
  entailed = atomTable.get(vm, "entailed");
  stuck = atomTable.get(vm, "stuck");
  alternatives = atomTable.get(vm, "alternatives");
  failed = atomTable.get(vm, "failed");
  merged = atomTable.get(vm, "merged");

  ooMeth = atomTable.getUniqueName(vm, "ooMeth");
  ooFastMeth = atomTable.getUniqueName(vm, "ooFastMeth");
  ooDefaults = atomTable.getUniqueName(vm, "ooDefaults");
  ooAttr = atomTable.getUniqueName(vm, "ooAttr");
  ooFeat = atomTable.getUniqueName(vm, "ooFeat");
  ooFreeFeat = atomTable.getUniqueName(vm, "ooFreeFeat");
  ooFreeFlag = atomTable.getUniqueName(vm, "ooFreeFlag");
  ooMethSrc = atomTable.getUniqueName(vm, "ooMethSrc");
  ooAttrSrc = atomTable.getUniqueName(vm, "ooAttrSrc");
  ooFeatSrc = atomTable.getUniqueName(vm, "ooFeatSrc");
  ooPrintName = atomTable.getUniqueName(vm, "ooPrintName");
  ooFallback = atomTable.getUniqueName(vm, "ooFallback");

  outOfRange = atomTable.get(vm, "outOfRange");
  surrogate = atomTable.get(vm, "surrogate");
  invalidUTF8 = atomTable.get(vm, "invalidUTF8");
  invalidUTF16 = atomTable.get(vm, "invalidUTF16");
  truncated = atomTable.get(vm, "truncated");

  debug = atomTable.get(vm, "debug");
  error = atomTable.get(vm, "error");
  system = atomTable.get(vm, "system");
  failure = atomTable.get(vm, "failure");
  kernel = atomTable.get(vm, "kernel");
  illegalFieldSelection = atomTable.get(vm, "illegalFieldSelection");
  unicodeError = atomTable.get(vm, "unicode");
  spaceAdmissible = atomTable.get(vm, "spaceAdmissible");
  spaceNoChoice = atomTable.get(vm, "spaceNoChoice");
  spaceAltRange = atomTable.get(vm, "spaceAltRange");
  spaceMerged = atomTable.get(vm, "spaceMerged");
  indexOutOfBounds = atomTable.get(vm, "indexOutOfBounds");
}

}

#endif // MOZART_COREATOMS_H
