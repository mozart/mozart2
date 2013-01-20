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

#ifndef __COREATOMS_H
#define __COREATOMS_H

#include "mozartcore.hh"

namespace mozart {

void CoreAtoms::initialize(VM vm, AtomTable& atomTable) {
  empty = atomTable.get(vm, MOZART_STR(""));

  nil = atomTable.get(vm, MOZART_STR("nil"));
  pipe = atomTable.get(vm, MOZART_STR("|"));
  sharp = atomTable.get(vm, MOZART_STR("#"));

  succeeded = atomTable.get(vm, MOZART_STR("succeeded"));
  entailed = atomTable.get(vm, MOZART_STR("entailed"));
  stuck = atomTable.get(vm, MOZART_STR("stuck"));
  alternatives = atomTable.get(vm, MOZART_STR("alternatives"));
  failed = atomTable.get(vm, MOZART_STR("failed"));
  merged = atomTable.get(vm, MOZART_STR("merged"));

  ooMeth = atomTable.getUniqueName(vm, MOZART_STR("ooMeth"));
  ooFastMeth = atomTable.getUniqueName(vm, MOZART_STR("ooFastMeth"));
  ooDefaults = atomTable.getUniqueName(vm, MOZART_STR("ooDefaults"));
  ooAttr = atomTable.getUniqueName(vm, MOZART_STR("ooAttr"));
  ooFeat = atomTable.getUniqueName(vm, MOZART_STR("ooFeat"));
  ooFreeFeat = atomTable.getUniqueName(vm, MOZART_STR("ooFreeFeat"));
  ooFreeFlag = atomTable.getUniqueName(vm, MOZART_STR("ooFreeFlag"));
  ooMethSrc = atomTable.getUniqueName(vm, MOZART_STR("ooMethSrc"));
  ooAttrSrc = atomTable.getUniqueName(vm, MOZART_STR("ooAttrSrc"));
  ooFeatSrc = atomTable.getUniqueName(vm, MOZART_STR("ooFeatSrc"));
  ooPrintName = atomTable.getUniqueName(vm, MOZART_STR("ooPrintName"));
  ooFallback = atomTable.getUniqueName(vm, MOZART_STR("ooFallback"));

  outOfRange = atomTable.get(vm, MOZART_STR("outOfRange"));
  surrogate = atomTable.get(vm, MOZART_STR("surrogate"));
  invalidUTF8 = atomTable.get(vm, MOZART_STR("invalidUTF8"));
  invalidUTF16 = atomTable.get(vm, MOZART_STR("invalidUTF16"));
  truncated = atomTable.get(vm, MOZART_STR("truncated"));

  debug = atomTable.get(vm, MOZART_STR("debug"));
  error = atomTable.get(vm, MOZART_STR("error"));
  system = atomTable.get(vm, MOZART_STR("system"));
  failure = atomTable.get(vm, MOZART_STR("failure"));
  kernel = atomTable.get(vm, MOZART_STR("kernel"));
  illegalFieldSelection = atomTable.get(vm, MOZART_STR("illegalFieldSelection"));
  unicodeError = atomTable.get(vm, MOZART_STR("unicode"));
  spaceAdmissible = atomTable.get(vm, MOZART_STR("spaceAdmissible"));
  spaceNoChoice = atomTable.get(vm, MOZART_STR("spaceNoChoice"));
  spaceAltRange = atomTable.get(vm, MOZART_STR("spaceAltRange"));
  spaceMerged = atomTable.get(vm, MOZART_STR("spaceMerged"));
  indexOutOfBounds = atomTable.get(vm, MOZART_STR("indexOutOfBounds"));
}

}

#endif // __COREATOMS_H
