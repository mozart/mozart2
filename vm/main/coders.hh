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

#ifndef __CODERS_H
#define __CODERS_H

#include "mozartcore.hh"

namespace mozart {

//////////////
// Encoders //
//////////////


FreeableLString<char> encodeLatin1(VM vm, const LString<nchar>& input,
                                   bool isLittleEndian, bool insertBom);


FreeableLString<char> encodeUTF8(VM vm, const LString<nchar>& input,
                                 bool isLittleEndian, bool insertBom);


FreeableLString<char> encodeUTF16(VM vm, const LString<nchar>& input,
                                  bool isLittleEndian, bool insertBom);


FreeableLString<char> encodeUTF32(VM vm, const LString<nchar>& input,
                                  bool isLittleEndian, bool insertBom);

//////////////
// Decoders //
//////////////


FreeableLString<nchar> decodeLatin1(VM vm, const LString<char>& input,
                                    bool isLittleEndian, bool hasBom);

FreeableLString<nchar> decodeUTF8(VM vm, const LString<char>& input,
                                  bool isLittleEndian, bool hasBom);


FreeableLString<nchar> decodeUTF16(VM vm, const LString<char>& input,
                                   bool isLittleEndian, bool hasBom);


FreeableLString<nchar> decodeUTF32(VM vm, const LString<char>& input,
                                   bool isLittleEndian, bool hasBom);

}

#endif
