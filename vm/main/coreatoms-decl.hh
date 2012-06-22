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

#ifndef __COREATOMS_DECL_H
#define __COREATOMS_DECL_H

#include "core-forward-decl.hh"

#include "atomtable.hh"

namespace mozart {

struct CoreAtoms {
  inline
  void initialize(VM vm, AtomTable& atomTable);

  // nil, '|' and '#'
  AtomImpl* nil;
  AtomImpl* pipe;
  AtomImpl* sharp;

  // Object Orientation
  AtomImpl* ooMeth;
  AtomImpl* ooFastMeth;
  AtomImpl* ooDefaults;
  AtomImpl* ooAttr;
  AtomImpl* ooFeat;
  AtomImpl* ooFreeFeat;
  AtomImpl* ooFreeFlag;
  AtomImpl* ooMethSrc;
  AtomImpl* ooAttrSrc;
  AtomImpl* ooFeatSrc;
  AtomImpl* ooPrintName;
  AtomImpl* ooFallback;

  // Space status
  AtomImpl* succeeded;
  AtomImpl* entailed;
  AtomImpl* stuck;
  AtomImpl* suspended;
  AtomImpl* alternatives;
  AtomImpl* failed;
  AtomImpl* merged;

  // Unicode error types
  AtomImpl* outOfRange;
  AtomImpl* surrogate;
  AtomImpl* invalidUTF8;
  AtomImpl* invalidUTF16;
  AtomImpl* truncated;

  // Exceptions
  AtomImpl* failure;
  AtomImpl* typeError;
  AtomImpl* illegalFieldSelection;
  AtomImpl* illegalArity;
  AtomImpl* unicodeError;
  AtomImpl* spaceAdmissible;
  AtomImpl* spaceNoChoice;
  AtomImpl* spaceAltRange;
  AtomImpl* spaceMerged;
  AtomImpl* indexOutOfBounds;
};

}

#endif // __COREATOMS_DECL_H
