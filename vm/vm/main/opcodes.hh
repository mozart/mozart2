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

namespace mozart {

typedef short unsigned int uint16_t;

typedef uint16_t ByteCode;
typedef ByteCode OpCode;

typedef const ByteCode* ProgramCounter;

const OpCode OpSkip = 0x00;

const OpCode OpMoveXX = 0x01;
const OpCode OpMoveXY = 0x02;
const OpCode OpMoveYX = 0x03;
const OpCode OpMoveYY = 0x04;
const OpCode OpMoveGX = 0x05;
const OpCode OpMoveGY = 0x06;
const OpCode OpMoveKX = 0x07;
const OpCode OpMoveKY = 0x08;

const OpCode OpMoveMoveXYXY = 0x09;
const OpCode OpMoveMoveYXYX = 0x0A;
const OpCode OpMoveMoveYXXY = 0x0B;
const OpCode OpMoveMoveXYYX = 0x0C;

const OpCode OpAllocateY = 0x0D;
const OpCode OpDeallocateY = 0x0E;

const OpCode OpCreateVarX = 0x0F;
const OpCode OpCreateVarY = 0x10;
const OpCode OpCreateVarMoveX = 0x11;
const OpCode OpCreateVarMoveY = 0x12;

const OpCode OpSetupExceptionHandler = 0x18;
const OpCode OpPopExceptionHandler = 0x19;

const OpCode OpCallBuiltin0 = 0x20;
const OpCode OpCallBuiltin1 = 0x21;
const OpCode OpCallBuiltin2 = 0x22;
const OpCode OpCallBuiltin3 = 0x23;
const OpCode OpCallBuiltin4 = 0x24;
const OpCode OpCallBuiltin5 = 0x25;
const OpCode OpCallBuiltinN = 0x26;

const OpCode OpCallX = 0x27;
const OpCode OpCallY = 0x28;
const OpCode OpCallG = 0x29;
const OpCode OpCallK = 0x2A;
const OpCode OpTailCallX = 0x2B;
const OpCode OpTailCallY = 0x2C;
const OpCode OpTailCallG = 0x2D;
const OpCode OpTailCallK = 0x2E;

const OpCode OpSendMsgX = 0x30;
const OpCode OpSendMsgY = 0x31;
const OpCode OpSendMsgG = 0x32;
const OpCode OpSendMsgK = 0x33;
const OpCode OpTailSendMsgX = 0x34;
const OpCode OpTailSendMsgY = 0x35;
const OpCode OpTailSendMsgG = 0x36;
const OpCode OpTailSendMsgK = 0x37;

const OpCode OpReturn = 0x40;
const OpCode OpBranch = 0x41;
const OpCode OpBranchBackward = 0x42;
const OpCode OpCondBranch = 0x43;
const OpCode OpCondBranchFB = 0x44;
const OpCode OpCondBranchBF = 0x45;
const OpCode OpCondBranchBB = 0x46;

const OpCode OpPatternMatchX = 0x47;
const OpCode OpPatternMatchY = 0x48;
const OpCode OpPatternMatchG = 0x49;

const OpCode OpUnifyXX = 0x50;
const OpCode OpUnifyXY = 0x51;
const OpCode OpUnifyXG = 0x52;
const OpCode OpUnifyXK = 0x53;
const OpCode OpUnifyYY = 0x54;
const OpCode OpUnifyYG = 0x55;
const OpCode OpUnifyYK = 0x56;
const OpCode OpUnifyGG = 0x57;
const OpCode OpUnifyGK = 0x58;
const OpCode OpUnifyKK = 0x59;

const OpCode OpCreateStructBase = 0x60;
static_assert((OpCreateStructBase & 0x1F) == 0,
              "OpCreateStructBase must be aligned on 0x20");

const OpCode OpCreateStructWhatMask = 0x03;
const OpCode OpCreateStructAbstraction = 0;
const OpCode OpCreateStructCons = 1;
const OpCode OpCreateStructTuple = 2;
const OpCode OpCreateStructRecord = 3;

const OpCode OpCreateStructWhereMask = 0x07 << 2;
const OpCode OpCreateStructStoreX = 0 << 2;
const OpCode OpCreateStructStoreY = 1 << 2;
const OpCode OpCreateStructUnifyX = 2 << 2;
const OpCode OpCreateStructUnifyY = 3 << 2;
const OpCode OpCreateStructUnifyG = 4 << 2;
const OpCode OpCreateStructUnifyK = 5 << 2;

const OpCode OpCreateAbstractionStoreX =
  OpCreateStructBase | OpCreateStructAbstraction | OpCreateStructStoreX;
const OpCode OpCreateConsStoreX =
  OpCreateStructBase | OpCreateStructCons | OpCreateStructStoreX;
const OpCode OpCreateTupleStoreX =
  OpCreateStructBase | OpCreateStructTuple | OpCreateStructStoreX;
const OpCode OpCreateRecordStoreX =
  OpCreateStructBase | OpCreateStructRecord | OpCreateStructStoreX;

const OpCode OpCreateAbstractionStoreY =
  OpCreateStructBase | OpCreateStructAbstraction | OpCreateStructStoreY;
const OpCode OpCreateConsStoreY =
  OpCreateStructBase | OpCreateStructCons | OpCreateStructStoreY;
const OpCode OpCreateTupleStoreY =
  OpCreateStructBase | OpCreateStructTuple | OpCreateStructStoreY;
const OpCode OpCreateRecordStoreY =
  OpCreateStructBase | OpCreateStructRecord | OpCreateStructStoreY;

const OpCode OpCreateAbstractionUnifyX =
  OpCreateStructBase | OpCreateStructAbstraction | OpCreateStructUnifyX;
const OpCode OpCreateConsUnifyX =
  OpCreateStructBase | OpCreateStructCons | OpCreateStructUnifyX;
const OpCode OpCreateTupleUnifyX =
  OpCreateStructBase | OpCreateStructTuple | OpCreateStructUnifyX;
const OpCode OpCreateRecordUnifyX =
  OpCreateStructBase | OpCreateStructRecord | OpCreateStructUnifyX;

const OpCode OpCreateAbstractionUnifyY =
  OpCreateStructBase | OpCreateStructAbstraction | OpCreateStructUnifyY;
const OpCode OpCreateConsUnifyY =
  OpCreateStructBase | OpCreateStructCons | OpCreateStructUnifyY;
const OpCode OpCreateTupleUnifyY =
  OpCreateStructBase | OpCreateStructTuple | OpCreateStructUnifyY;
const OpCode OpCreateRecordUnifyY =
  OpCreateStructBase | OpCreateStructRecord | OpCreateStructUnifyY;

const OpCode OpCreateAbstractionUnifyG =
  OpCreateStructBase | OpCreateStructAbstraction | OpCreateStructUnifyG;
const OpCode OpCreateConsUnifyG =
  OpCreateStructBase | OpCreateStructCons | OpCreateStructUnifyG;
const OpCode OpCreateTupleUnifyG =
  OpCreateStructBase | OpCreateStructTuple | OpCreateStructUnifyG;
const OpCode OpCreateRecordUnifyG =
  OpCreateStructBase | OpCreateStructRecord | OpCreateStructUnifyG;

const OpCode OpCreateAbstractionUnifyK =
  OpCreateStructBase | OpCreateStructAbstraction | OpCreateStructUnifyK;
const OpCode OpCreateConsUnifyK =
  OpCreateStructBase | OpCreateStructCons | OpCreateStructUnifyK;
const OpCode OpCreateTupleUnifyK =
  OpCreateStructBase | OpCreateStructTuple | OpCreateStructUnifyK;
const OpCode OpCreateRecordUnifyK =
  OpCreateStructBase | OpCreateStructRecord | OpCreateStructUnifyK;

const OpCode SubOpArrayFillX = 0;
const OpCode SubOpArrayFillY = 1;
const OpCode SubOpArrayFillG = 2;
const OpCode SubOpArrayFillK = 3;
const OpCode SubOpArrayFillNewVarX = 4;
const OpCode SubOpArrayFillNewVarY = 5;
const OpCode SubOpArrayFillNewVars = 6;

// Inlines for some builtins
const OpCode OpInlineEqualsInteger = 0x80;
const OpCode OpInlineAdd = 0x81;
const OpCode OpInlineSubtract = 0x82;
const OpCode OpInlinePlus1 = 0x83;
const OpCode OpInlineMinus1 = 0x84;

const OpCode OpInlineGetClass = 0x90;

}

#endif // __OPCODES_H
