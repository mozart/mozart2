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
  pipe = atomTable.get(vm, u"|");
  sharp = atomTable.get(vm, u"#");

  succeeded = atomTable.get(vm, u"succeeded");
  entailed = atomTable.get(vm, u"entailed");
  stuck = atomTable.get(vm, u"stuck");
  alternatives = atomTable.get(vm, u"alternatives");
  failed = atomTable.get(vm, u"failed");
  merged = atomTable.get(vm, u"merged");

  failure = atomTable.get(vm, u"failure");
  typeError = atomTable.get(vm, u"typeError");
  illegalFieldSelection = atomTable.get(vm, u"illegalFieldSelection");
  illegalArity = atomTable.get(vm, u"illegalArity");
  spaceAdmissible = atomTable.get(vm, u"spaceAdmissible");
  spaceNoChoice = atomTable.get(vm, u"spaceNoChoice");
  spaceAltRange = atomTable.get(vm, u"spaceAltRange");
  spaceMerged = atomTable.get(vm, u"spaceMerged");
}

}

#endif // __COREATOMS_H
