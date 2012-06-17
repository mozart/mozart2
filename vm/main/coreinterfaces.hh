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

#ifndef __COREINTERFACES_H
#define __COREINTERFACES_H

#include "mozartcore-decl.hh"

#include "coreinterfaces-decl.hh"
#include "coredatatypes-decl.hh"

namespace mozart {

#ifndef MOZART_GENERATOR

#include "DataflowVariable-interf.hh"
#include "ValueEquatable-interf.hh"
#include "StructuralEquatable-interf.hh"
#include "Comparable-interf.hh"
#include "Wakeable-interf.hh"
#include "Literal-interf.hh"
#include "AtomLike-interf.hh"
#include "NameLike-interf.hh"
#include "PotentialFeature-interf.hh"
#include "BuiltinCallable-interf.hh"
#include "Callable-interf.hh"
#include "CodeAreaProvider-interf.hh"
#include "Numeric-interf.hh"
#include "IntegerValue-interf.hh"
#include "FloatValue-interf.hh"
#include "BooleanValue-interf.hh"
#include "Dottable-interf.hh"
#include "RecordLike-interf.hh"
#include "ArrayLike-interf.hh"
#include "DictionaryLike-interf.hh"
#include "ObjectLike-interf.hh"
#include "ArrayInitializer-interf.hh"
#include "SpaceLike-interf.hh"
#include "ThreadLike-interf.hh"
#include "CellLike-interf.hh"
#include "ChunkLike-interf.hh"
#include "StringLike-interf.hh"
#include "VirtualString-interf.hh"
#include "ByteStringLike-interf.hh"

#endif // MOZART_GENERATOR

}

#endif // __COREINTERFACES_H
