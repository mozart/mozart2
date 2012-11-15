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

#ifndef __MODCOMPACTSTRING_H
#define __MODCOMPACTSTRING_H

#include "../mozartcore.hh"

#ifndef MOZART_GENERATOR

namespace mozart {

namespace builtins {

//////////////////////////
// CompactString module //
//////////////////////////

class ModCompactString : public Module {
public:
  ModCompactString() : Module("CompactString") {}

  class IsCompactString : public Builtin<IsCompactString> {
  public:
    IsCompactString() : Builtin("isCompactString") {}

    void operator()(VM vm, In value, Out result) {
      result = build(vm, StringLike(value).isString(vm));
    }
  };

  class IsCompactByteString : public Builtin<IsCompactByteString> {
  public:
    IsCompactByteString() : Builtin("isCompactByteString") {}

    void operator()(VM vm, In value, Out result) {
      result = build(vm, StringLike(value).isByteString(vm));
    }
  };

  class CharAt : public Builtin<CharAt> {
  public:
    CharAt() : Builtin("charAt") {}

    void operator()(VM vm, In value, In index, Out result) {
      result = build(vm, StringLike(value).stringCharAt(vm, index));
    }
  };

  class Append : public Builtin<Append> {
  public:
    Append() : Builtin("append") {}

    void operator()(VM vm, In left, In right, Out result) {
      result = StringLike(left).stringAppend(vm, right);
    }
  };

  class Slice : public Builtin<Slice> {
  public:
    Slice() : Builtin("slice") {}

    void operator()(VM vm, In value, In from, In to, Out result) {
      result = StringLike(value).stringSlice(vm, from, to);
    }
  };

  class Search : public Builtin<Search> {
  public:
    Search() : Builtin("search") {}

    void operator()(VM vm, In value, In from, In needle, Out begin, Out end) {
      return StringLike(value).stringSearch(vm, from, needle, begin, end);
    }
  };

  class HasPrefix : public Builtin<HasPrefix> {
  public:
    HasPrefix() : Builtin("hasPrefix") {}

    void operator()(VM vm, In string, In prefix, Out result) {
      result = build(vm, StringLike(string).stringHasPrefix(vm, prefix));
    }
  };

  class HasSuffix : public Builtin<HasSuffix> {
  public:
    HasSuffix() : Builtin("hasSuffix") {}

    void operator()(VM vm, In string, In suffix, Out result) {
      result = build(vm, StringLike(string).stringHasSuffix(vm, suffix));
    }
  };
};

}

}

#endif

#endif // __MODCOMPACTSTRING_H
