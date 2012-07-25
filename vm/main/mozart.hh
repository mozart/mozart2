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
#include "builtinutils.hh"
#include "coreatoms.hh"
#include "dynbuilders.hh"
#include "exchelpers.hh"
#include "gcollect.hh"
#include "graphreplicator.hh"
#include "lstring.hh"
#include "runnable.hh"
#include "sclone.hh"
#include "space.hh"
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

#include "modules/modboot.hh"
#include "modules/modatom.hh"
#include "modules/modvalue.hh"
#include "modules/modnumber.hh"
#include "modules/modint.hh"
#include "modules/modfloat.hh"
#include "modules/modliteral.hh"
#include "modules/modrecord.hh"
#include "modules/modchunk.hh"
#include "modules/modtuple.hh"
#include "modules/modsystem.hh"
#include "modules/modthread.hh"
#include "modules/modspace.hh"
#include "modules/modcell.hh"
#include "modules/modname.hh"
#include "modules/modarray.hh"
#include "modules/moddictionary.hh"
#include "modules/modexception.hh"
#include "modules/modobject.hh"
#include "modules/modprocedure.hh"
#include "modules/modtime.hh"
#include "modules/modstring.hh"
#include "modules/modvirtualstring.hh"
#include "modules/modbytestring.hh"
#include "modules/modcompilersupport.hh"

#endif // __MOZART_H
