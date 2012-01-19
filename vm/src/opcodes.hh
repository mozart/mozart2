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

#ifndef __OPCODES_H
#define __OPCODES_H

typedef short unsigned int uint16_t;

typedef uint16_t ByteCode;
typedef ByteCode OpCode;

typedef ByteCode* ProgramCounter;

const OpCode OpSkip = 0x00;

const OpCode OpMoveXX = 0x01;
const OpCode OpMoveXY = 0x02;
const OpCode OpMoveYX = 0x03;
const OpCode OpMoveYY = 0x04;
const OpCode OpMoveGX = 0x05;
const OpCode OpMoveGY = 0x06;
const OpCode OpMoveKX = 0x07;
const OpCode OpMoveKY = 0x08;

const OpCode OpAllocateY = 0x0A;
const OpCode OpDeallocateY = 0x0B;
const OpCode OpCreateVar = 0x0C;

const OpCode OpCallBuiltin = 0x10;
const OpCode OpCallX = 0x11;
const OpCode OpCallG = 0x12;
const OpCode OpTailCallX = 0x13;
const OpCode OpTailCallG = 0x14;
const OpCode OpReturn = 0x15;
const OpCode OpBranch = 0x16;
const OpCode OpCondBranch = 0x17;

const OpCode OpUnifyXX = 0x20;
const OpCode OpUnifyXY = 0x21;
const OpCode OpUnifyXK = 0x22;
const OpCode OpUnifyXG = 0x23;

// Hard-coded stuff for bootstrapping the development
const OpCode OpPrint = 0x18;

// Inlines for some builtins
const OpCode OpInlineEqualsInteger = 0x30;
const OpCode OpInlineAdd = 0x31;
const OpCode OpInlineMinus1 = 0x32;

#endif // __OPCODES_H
