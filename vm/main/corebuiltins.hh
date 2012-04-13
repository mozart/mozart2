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

#ifndef __COREBUILTINS_H
#define __COREBUILTINS_H

#include "mozartcore.hh"

namespace mozart {

namespace builtins {

/////////////////////////
// Unification-related //
/////////////////////////

OpResult equals(VM vm, UnstableNode* args[]);
OpResult notEquals(VM vm, UnstableNode* args[]);

//////////////////
// Value status //
//////////////////

OpResult wait(VM vm, UnstableNode* args[]);
OpResult waitOr(VM vm, UnstableNode* args[]);
OpResult isDet(VM vm, UnstableNode* args[]);

////////////////
// Arithmetic //
////////////////

OpResult add(VM vm, UnstableNode* args[]);
OpResult subtract(VM vm, UnstableNode* args[]);
OpResult multiply(VM vm, UnstableNode* args[]);
OpResult divide(VM vm, UnstableNode* args[]);
OpResult div(VM vm, UnstableNode* args[]);
OpResult mod(VM vm, UnstableNode* args[]);

/////////////
// Records //
/////////////

OpResult label(VM vm, UnstableNode* args[]);
OpResult width(VM vm, UnstableNode* args[]);
OpResult dot(VM vm, UnstableNode* args[]);

/////////////
// Threads //
/////////////

OpResult createThread(VM vm, UnstableNode* args[]);

///////////////////
// Miscellaneous //
///////////////////

OpResult show(VM vm, UnstableNode* args[]);

////////////
// Spaces //
////////////

OpResult newSpace(VM vm, UnstableNode* args[]);
OpResult askSpace(VM vm, UnstableNode* args[]);
OpResult askVerboseSpace(VM vm, UnstableNode* args[]);
OpResult mergeSpace(VM vm, UnstableNode* args[]);
OpResult commitSpace(VM vm, UnstableNode* args[]);
OpResult cloneSpace(VM vm, UnstableNode* args[]);
OpResult chooseSpace(VM vm, UnstableNode* args[]);

///////////
// Utils //
///////////

OpResult expectCallable(VM vm, RichNode target, int expectedArity);

void printReprToStream(VM vm, RichNode node,
                       std::ostream& out, int depth = 10);

}

}

#endif // __COREBUILTINS_H
