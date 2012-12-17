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

#ifndef __MOZART_H
#define __MOZART_H

#include "mozartcore.hh"

#include "coredatatypes.hh"

#include "builtins.hh"
#include "coreatoms.hh"
#include "datatype.hh"
#include "dynbuilders.hh"
#include "exceptions.hh"
#include "exchelpers.hh"
#include "gcollect.hh"
#include "graphreplicator.hh"
#include "lstring.hh"
#include "ozcalls.hh"
#include "properties.hh"
#include "protect.hh"
#include "runnable.hh"
#include "sclone.hh"
#include "space.hh"
#include "storage.hh"
#include "store.hh"
#include "threadpool.hh"
#include "type.hh"
#include "typeinfo.hh"
#include "unify.hh"
#include "utf.hh"
#include "utils.hh"
#include "vm.hh"
#include "vmallocatedlist.hh"

#include "emulate.hh"

#if !defined(MOZART_GENERATOR) && !defined(MOZART_BUILTIN_GENERATOR)
namespace mozart { namespace builtins {
#include "mozartbuiltins.hh"
} }
#endif

#endif // __MOZART_H
