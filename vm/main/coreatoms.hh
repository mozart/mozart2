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
  nil = atomTable.get(vm, u"nil");
  pipe = atomTable.get(vm, u"|");
  sharp = atomTable.get(vm, u"#");

  succeeded = atomTable.get(vm, u"succeeded");
  entailed = atomTable.get(vm, u"entailed");
  stuck = atomTable.get(vm, u"stuck");
  alternatives = atomTable.get(vm, u"alternatives");
  failed = atomTable.get(vm, u"failed");
  merged = atomTable.get(vm, u"merged");

  ooMeth = atomTable.get(vm, u"ooMeth");
  ooFastMeth = atomTable.get(vm, u"ooFastMeth");
  ooDefaults = atomTable.get(vm, u"ooDefaults");
  ooAttr = atomTable.get(vm, u"ooAttr");
  ooFeat = atomTable.get(vm, u"ooFeat");
  ooFreeFeat = atomTable.get(vm, u"ooFreeFeat");
  ooFreeFlag = atomTable.get(vm, u"ooFreeFlag");
  ooMethSrc = atomTable.get(vm, u"ooMethSrc");
  ooAttrSrc = atomTable.get(vm, u"ooAttrSrc");
  ooFeatSrc = atomTable.get(vm, u"ooFeatSrc");
  ooPrintName = atomTable.get(vm, u"ooPrintName");
  ooFallback = atomTable.get(vm, u"ooFallback");

  outOfRange = atomTable.get(vm, MOZART_STR("outOfRange"));
  surrogate = atomTable.get(vm, MOZART_STR("surrogate"));
  invalidUTF8 = atomTable.get(vm, MOZART_STR("invalidUTF8"));
  invalidUTF16 = atomTable.get(vm, MOZART_STR("invalidUTF16"));
  truncated = atomTable.get(vm, MOZART_STR("truncated"));

  failure = atomTable.get(vm, u"failure");
  typeError = atomTable.get(vm, u"typeError");
  illegalFieldSelection = atomTable.get(vm, u"illegalFieldSelection");
  illegalArity = atomTable.get(vm, u"illegalArity");
  unicodeError = atomTable.get(vm, MOZART_STR("unicodeError"));
  spaceAdmissible = atomTable.get(vm, u"spaceAdmissible");
  spaceNoChoice = atomTable.get(vm, u"spaceNoChoice");
  spaceAltRange = atomTable.get(vm, u"spaceAltRange");
  spaceMerged = atomTable.get(vm, u"spaceMerged");
  indexOutOfBounds = atomTable.get(vm, MOZART_STR("indexOutOfBounds"));
}

}

#endif // __COREATOMS_H
