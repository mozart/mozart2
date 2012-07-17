%%% Copyright © 2012, Université catholique de Louvain
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%
%%% *  Redistributions of source code must retain the above copyright notice,
%%%    this list of conditions and the following disclaimer.
%%% *  Redistributions in binary form must reproduce the above copyright notice,
%%%    this list of conditions and the following disclaimer in the documentation
%%%    and/or other materials provided with the distribution.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%%% POSSIBILITY OF SUCH DAMAGE.

functor

import
   CompilerSupport at 'x-oz://boot/CompilerSupport'
   System(show:Show)

export
   InternalAssemble
   Assemble

define

   OpCodeTable = table(
      'skip': 0x00

      moveXX: 0x01
      moveXY: 0x02
      moveYX: 0x03
      moveYY: 0x04
      moveGX: 0x05
      moveGY: 0x06
      moveKX: 0x07
      moveKY: 0x08

      moveMoveXYXY: 0x09
      moveMoveYXYX: 0x0A
      moveMoveYXXY: 0x0B
      moveMoveXYYX: 0x0C

      allocateY: 0x0D
      deallocateY: 0x0E

      createVarX: 0x0F
      createVarY: 0x10
      createVarMoveX: 0x11
      createVarMoveY: 0x12

      setupExceptionHandler: 0x18
      popExceptionHandler: 0x19

      callBuiltin0: 0x20
      callBuiltin1: 0x21
      callBuiltin2: 0x22
      callBuiltin3: 0x23
      callBuiltin4: 0x24
      callBuiltin5: 0x25
      callBuiltinN: 0x26

      callX: 0x27
      callG: 0x28
      tailCallX: 0x29
      tailCallG: 0x2A
      return: 0x2B
      branch: 0x2C
      condBranch: 0x2D
      patternMatch: 0x2E

      unifyXX: 0x30
      unifyXY: 0x31
      unifyXK: 0x32
      unifyXG: 0x33

      arrayInitElementX: 0x40
      arrayInitElementY: 0x41
      arrayInitElementG: 0x42
      arrayInitElementK: 0x43

      createAbstractionX: 0x44
      createAbstractionK: 0x45

      createTupleK: 0x46
      createRecordK: 0x47
      createConsXX: 0x48
   )

   class InternalAssembler
      prop final

      attr
         arity
         xRegCount
         gRegCount
         kRegCount
         kRegs
         byteCode
         byteCodeTail

      meth init(Arity)
         arity := Arity
         xRegCount := Arity
         gRegCount := 0
         kRegCount := 0
         kRegs := nil
         byteCode := _
         byteCodeTail := @byteCode
      end

      meth append(Instr)
         InstrLabel = {Label Instr}
         OpCode Args
      in
         if InstrLabel == custom then
            OpCode|Args = {Record.toList Instr}
         else
            OpCode = OpCodeTable.InstrLabel
            Args = {Record.toList Instr}
         end

         {self AppendElem(OpCode)}
         {self AppendArgs(Args)}
      end

      meth close()
         @byteCodeTail = nil
      end

      meth AppendArgs(Args)
         case Args
         of nil then
            skip
         [] Arg|ArgsTail then
            case Arg
            of x(Idx) then
               if Idx >= @xRegCount then
                  xRegCount := Idx+1
               end
               {self AppendElem(Idx)}
            [] y(Idx) then
               {self AppendElem(Idx)}
            [] g(Idx) then
               if Idx >= @gRegCount then
                  gRegCount := Idx+1
               end
               {self AppendElem(Idx)}
            [] k(Value) then
               {self AppendElem({self GetKRegFor(Value $)})}
            [] Immediate then
               {self AppendElem(Immediate)}
            end

            {self AppendArgs(ArgsTail)}
         end
      end

      meth AppendElem(ByteCodeElem)
         NewTail
      in
         (byteCodeTail := NewTail) = ByteCodeElem | NewTail
      end

      meth GetKRegFor(Value ?Result)
         {self GetKRegForInternal(Value ?Result @kRegCount @kRegs)}
      end

      meth GetKRegForInternal(Value ?Result KRegCount KRegs)
         case KRegs
         of H|_ andthen H == Value then
            Result = KRegCount-1
         [] _|T then
            {self GetKRegForInternal(Value ?Result KRegCount-1 T)}
         [] nil then
            Result = @kRegCount
            kRegCount := Result+1
            kRegs := Value|@kRegs
         end
      end

      meth output($)
         {CompilerSupport.newCodeArea @byteCode @xRegCount {Reverse @kRegs}}
      end
   end

   fun {InternalAssemble Arity Instructions}
      Ass = {New InternalAssembler init(Arity)}
   in
      {ForAll Instructions
       proc {$ Instr}
          {Ass append(Instr)}
       end}
      {Ass close()}
      {Ass output($)}
   end

   Assemble = InternalAssemble

end
