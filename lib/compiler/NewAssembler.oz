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
   CompilerSupport

export
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

      inlineEqualsInteger: 0x50
   )

   fun {GetInstrSize Instr}
      case Instr
      of custom(...) then
         {Width Instr}
      else
         {Width Instr}+1
      end
   end

   fun {ResolveOverload Instr}
      case Instr
      of move(S=x(_) D=x(_)) then moveXX(S D)
      [] move(S=x(_) D=y(_)) then moveXY(S D)
      [] move(S=y(_) D=x(_)) then moveYX(S D)
      [] move(S=y(_) D=y(_)) then moveYY(S D)
      [] move(S=g(_) D=x(_)) then moveGX(S D)
      [] move(S=g(_) D=y(_)) then moveGY(S D)
      [] move(S=k(_) D=x(_)) then moveKX(S D)
      [] move(S=k(_) D=y(_)) then moveKY(S D)

      [] moveMove(S1=x(_) D1=y(_) S2=x(_) D2=y(_)) then moveMoveXYXY(S1 D1 S2 D2)
      [] moveMove(S1=y(_) D1=x(_) S2=y(_) D2=x(_)) then moveMoveYXYX(S1 D1 S2 D2)
      [] moveMove(S1=y(_) D1=x(_) S2=x(_) D2=y(_)) then moveMoveYXXY(S1 D1 S2 D2)
      [] moveMove(S1=x(_) D1=y(_) S2=y(_) D2=x(_)) then moveMoveXYYX(S1 D1 S2 D2)

      [] createVar(D=x(_)) then createVarX(D)
      [] createVar(D=y(_)) then createVarY(D)
      [] createVarMove(D1=x(_) D2) then createVarMoveX(D1 D2)
      [] createVarMove(D1=y(_) D2) then createVarMoveY(D1 D2)

      [] callBuiltin(T nil)              then callBuiltin0(T)
      [] callBuiltin(T [X1])             then callBuiltin1(T X1)
      [] callBuiltin(T [X1 X2])          then callBuiltin2(T X1 X2)
      [] callBuiltin(T [X1 X2 X3])       then callBuiltin3(T X1 X2 X3)
      [] callBuiltin(T [X1 X2 X3 X4])    then callBuiltin4(T X1 X2 X3 X4)
      [] callBuiltin(T [X1 X2 X3 X4 X5]) then callBuiltin5(T X1 X2 X3 X4 X5)

      [] callBuiltin(T Args) then
         N = {Length Args}
      in
         {List.toTuple callBuiltinN T|N|Args}

      [] call(T=x(_) A) then callX(T A)
      [] call(T=g(_) A) then callG(T A)
      [] tailCall(T=x(_) A) then tailCallX(T A)
      [] tailCall(T=g(_) A) then tailCallG(T A)

      [] unify(L R=x(_)) then unifyXX(L R)
      [] unify(L R=y(_)) then unifyXY(L R)
      [] unify(L R=g(_)) then unifyXG(L R)
      [] unify(L R=k(_)) then unifyXK(L R)

      [] arrayInitElement(T I V=x(_)) then arrayInitElementX(T I V)
      [] arrayInitElement(T I V=y(_)) then arrayInitElementY(T I V)
      [] arrayInitElement(T I V=g(_)) then arrayInitElementG(T I V)
      [] arrayInitElement(T I V=k(_)) then arrayInitElementK(T I V)

      [] createAbstraction(A B=x(_) C D) then createAbstractionX(A B C D)
      [] createAbstraction(A B=k(_) C D) then createAbstractionK(A B C D)

      [] createTuple(L=k(_) W D) then createTupleK(L W D)
      [] createRecord(A=k(_) W D) then createRecordK(A W D)
      [] createCons(H=x(_) T=x(_)) then createConsXX(H T)

      [] custom(...) then Instr

      else
         if {Not {HasFeature OpCodeTable {Label Instr}}} then
            {Exception.raiseError compiler(assembler noOverloadFound Instr)}
         end
         Instr
      end
   end

   class InternalAssemblerClass
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

      meth MarkEnd()
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
         {self MarkEnd()}
         {CompilerSupport.newCodeArea @byteCode @xRegCount {Reverse @kRegs}}
      end
   end

   fun {InternalAssemble Arity Instructions}
      Assembler = {New InternalAssemblerClass init(Arity)}
   in
      {ForAll Instructions
       proc {$ Instr}
          {Assembler append(Instr)}
       end}
      {Assembler output($)}
   end

   class AssemblerClass
      prop final

      attr
         InstrsHd
         InstrsTl
         LabelDict
         Size

      meth init()
         InstrsHd <- @InstrsTl
         LabelDict <- {NewDictionary}
         Size <- 0
      end

      meth newLabel(?L)
         L = {NewName}
         {Dictionary.put @LabelDict L _}
      end

      meth declareLabel(L)
         if {Dictionary.member @LabelDict L} then skip
         else {Dictionary.put @LabelDict L _}
         end
      end

      meth isLabelUsed(I $)
         {Dictionary.member @LabelDict I}
      end

      meth setLabel(L)
         if {Dictionary.member @LabelDict L} then
            {Dictionary.get @LabelDict L} = @Size
         else
            {Dictionary.put @LabelDict L @Size}
         end
      end

      meth checkLabels()
         {ForAll {Dictionary.entries @LabelDict}
          proc {$ Entry}
             L#V = Entry
          in
             if {IsFree V} then
                {Exception.raiseError compiler(assembler undeclaredLabel L)}
             end
          end}
      end

      meth append(OverloadedInstr)
         case OverloadedInstr
         of lbl(L) then
            {self setLabel(L)}
         else
            NewTl
            Instr = {ResolveOverload OverloadedInstr}
         in
            {self DeclareLabelsInInstr(Instr)}
            Size <- @Size + {GetInstrSize Instr}
            @InstrsTl = (Instr#@Size) | NewTl
            InstrsTl <- NewTl
         end
      end

      meth output($)
         {self MarkEnd()}

         {Map @InstrsHd fun {$ InstrAndEndAddr}
                           {self TranslateInstrLabels(InstrAndEndAddr $)}
                        end}
      end

      meth MarkEnd()
         @InstrsTl = nil
      end

      meth DeclareLabelsInInstr(Instr)
         case Instr
         of setupExceptionHandler(L) then
            {self declareLabel(L)}

         [] branch(L) then
            {self declareLabel(L)}

         [] condBranch(_ L1 L2 L3) then
            {self declareLabel(L1)}
            {self declareLabel(L2)}
            {self declareLabel(L3)}

         [] patternMatch(_ k(Patterns)) then
            {Record.forAll Patterns
             proc {$ Pattern}
                Pat#L = Pattern
             in
                {self declareLabel(L)}
             end}

         [] inlineEqualsInteger(_ _ L) then
            {self declareLabel(L)}

         else
            skip
         end
      end

      meth TranslateInstrLabels(InstrAndEndAddr $)
         Instr#EndAddr = InstrAndEndAddr
      in
         case Instr
         of setupExceptionHandler(L) then
            A = {self TranslateLabel(L EndAddr $)}
         in
            setupExceptionHandler(A)

         [] branch(L) then
            A = {self TranslateLabel(L EndAddr $)}
         in
            branch(A)

         [] condBranch(X L1 L2 L3) then
            A1 = {self TranslateLabel(L1 EndAddr $)}
            A2 = {self TranslateLabel(L2 EndAddr $)}
            A3 = {self TranslateLabel(L3 EndAddr $)}
         in
            condBranch(X A1 A2 A3)

         [] patternMatch(X k(Patterns)) then
            NewPatterns = {Record.map Patterns
                           fun {$ Pattern}
                              Pat#L = Pattern
                              A = {self TranslateLabel(L EndAddr $)}
                           in
                              Pat#A
                           end}
         in
            patternMatch(X k(NewPatterns))

         [] inlineEqualsInteger(X V L) then
            A = {self TranslateLabel(L EndAddr $)}
         in
            inlineEqualsInteger(X V A)

         else
            Instr
         end
      end

      meth TranslateLabel(L EndAddr $)
         {Dictionary.get @LabelDict L} - EndAddr
      end
   end

   proc {GetClears Instrs ?Clears ?Rest}
      case Instrs of I1|Ir then
         case I1 of clear(_) then Cr in
            Clears = I1|Cr
            {GetClears Ir ?Cr ?Rest}
         else
            Clears = nil
            Rest = Instrs
         end
      [] nil then
         Clears = nil
         Rest = nil
      end
   end

   fun {SkipDeadCode Instrs Assembler}
      case Instrs of I1|Rest then
         case I1 of lbl(I) andthen {Assembler isLabelUsed(I $)} then Instrs
         else {SkipDeadCode Rest Assembler}
         end
      [] nil then nil
      end
   end

   proc {EliminateDeadCode Instrs Assembler}
      {Peephole {SkipDeadCode Instrs Assembler} Assembler}
   end

   proc {Peephole Instrs Assembler}
      case Instrs

      of 'skip'|Rest then
         {Peephole Rest Assembler}

      [] move(X1=x(_) Y1=y(_)) | move(X2=x(_) Y2=y(_)) | Rest then
         {Assembler append(moveMove(X1 Y1 X2 Y2))}
         {Peephole Rest Assembler}

      [] move(Y1=y(_) X1=x(_)) | move(Y2=y(_) X2=x(_)) | Rest then
         {Assembler append(moveMove(Y1 X1 Y2 X2))}
         {Peephole Rest Assembler}

      [] move(Y1=y(_) X1=x(_)) | move(X2=x(_) Y2=y(_)) | Rest then
         {Assembler append(moveMove(Y1 X1 X2 Y2))}
         {Peephole Rest Assembler}

      [] move(X1=x(_) Y1=y(_)) | move(Y2=y(_) X2=x(_)) | Rest then
         {Assembler append(moveMove(X1 Y1 Y2 X2))}
         {Peephole Rest Assembler}

      [] createVar(R) | move(R X=x(_)) | Rest then
         {Peephole createVarMove(R X)|Rest Assembler}

      [] createVar(X=x(_)) | move(X R) | Rest then
         {Peephole createVarMove(R X)|Rest Assembler}

      [] deallocateY | return | (Rest = lbl(_) | deallocateY | return | _) then
         {Peephole Rest Assembler}

      [] return | (Rest = lbl(_) | return | _) then
         {Peephole Rest Assembler}

      [] clear(_) | _ then
         Clears Rest
      in
         {GetClears Instrs ?Clears ?Rest}
         case Rest
         of deallocateY|_ then skip
         else
            {ForAll Clears
             proc {$ Instr}
                {Assembler append(Instr)}
             end}
         end
         {Peephole Rest Assembler}

      [] branch(L) | Rest then
         Rest1
      in
         {Assembler declareLabel(L)}
         Rest1 = {SkipDeadCode Rest Assembler}
         case Rest1 of lbl(L2)|_ andthen L2 == L then skip
         else {Assembler append(branch(L))}
         end
         {Peephole Rest1 Assembler}

      [] return | Rest then
         {Assembler append(return)}
         {EliminateDeadCode Rest Assembler}

      [] (callBuiltin(k(Builtin) Args) = I1) | Rest then
         ActualArity = {Length Args}
         Info = {CompilerSupport.getBuiltinInfo Builtin}
      in
         if ActualArity \= Info.arity then
            {Exception.raiseError compiler(assembler builtinArityMistach Info)}
         end

         case Info.inlineAs
         of some(OpCode) then
            NewInstr = {List.toTuple custom OpCode|Args}
         in
            {Assembler append(NewInstr)}
         [] none then
            {Assembler append(I1)}
         end

         {Peephole Rest Assembler}

      [] call(T Arity) | deallocateY | return | Rest then
         NewT
      in
         case T of y(_) then
            {Assembler append(move(T NewT=x(Arity)))}
         else
            NewT = T
         end
         {Assembler append(deallocateY)}
         {Assembler append(tailCall(NewT Arity))}
         {EliminateDeadCode Rest Assembler}

      [] call(T Arity) | return | Rest then
         {Assembler append(tailCall(T Arity))}
         {EliminateDeadCode Rest Assembler}

      [] I1|Rest then
         {Assembler append(I1)}
         {Peephole Rest Assembler}

      [] nil then
         skip
      end
   end

   fun {Assemble Arity Code Switches}
      Verify = {CondSelect Switches verify true}
      DoPeephole = {CondSelect Switches peephole true}
      Assembler = {New AssemblerClass init()}
   in
      if DoPeephole then
         {Peephole Code Assembler}
      else
         {ForAll Code
          proc {$ Instr}
             {Assembler append(Instr)}
          end}
      end

      if Verify then
         {Assembler checkLabels()}
      end

      {InternalAssemble Arity {Assembler output($)}}
   end

end
