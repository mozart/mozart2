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

require
   BootSerializer at 'x-oz://boot/Serializer'

import
   System
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
      callY: 0x28
      callG: 0x29
      callK: 0x2A
      tailCallX: 0x2B
      tailCallY: 0x2C
      tailCallG: 0x2D
      tailCallK: 0x2E

      sendMsgX: 0x30
      sendMsgY: 0x31
      sendMsgG: 0x32
      sendMsgK: 0x33
      tailSendMsgX: 0x34
      tailSendMsgY: 0x35
      tailSendMsgG: 0x36
      tailSendMsgK: 0x37

      return: 0x40
      branch: 0x41
      branchBackward: 0x42
      condBranch: 0x43
      condBranchFB: 0x44
      condBranchBF: 0x45
      condBranchBB: 0x46

      patternMatchX: 0x47
      patternMatchY: 0x48
      patternMatchG: 0x49

      unifyXX: 0x50
      unifyXY: 0x51
      unifyXG: 0x52
      unifyXK: 0x53
      unifyYY: 0x54
      unifyYG: 0x55
      unifyYK: 0x56
      unifyGG: 0x57
      unifyGK: 0x58
      unifyKK: 0x59

      createAbstractionStoreX: 0x60
      createConsStoreX: 0x61
      createTupleStoreX: 0x62
      createRecordStoreX: 0x63

      createAbstractionStoreY: 0x64
      createConsStoreY: 0x65
      createTupleStoreY: 0x66
      createRecordStoreY: 0x67

      createAbstractionUnifyX: 0x68
      createConsUnifyX: 0x69
      createTupleUnifyX: 0x6A
      createRecordUnifyX: 0x6B

      createAbstractionUnifyY: 0x6C
      createConsUnifyY: 0x6D
      createTupleUnifyY: 0x6E
      createRecordUnifyY: 0x6F

      createAbstractionUnifyG: 0x70
      createConsUnifyG: 0x71
      createTupleUnifyG: 0x72
      createRecordUnifyG: 0x73

      createAbstractionUnifyK: 0x74
      createConsUnifyK: 0x75
      createTupleUnifyK: 0x76
      createRecordUnifyK: 0x77

      arrayFillX: 0
      arrayFillY: 1
      arrayFillG: 2
      arrayFillK: 3
      arrayFillNewVarX: 4
      arrayFillNewVarY: 5
      arrayFillNewVars: 6

      inlineEqualsInteger: 0x80
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
      [] call(T=y(_) A) then callY(T A)
      [] call(T=g(_) A) then callG(T A)
      [] call(T=k(_) A) then callK(T A)

      [] tailCall(T=x(_) A) then tailCallX(T A)
      [] tailCall(T=y(_) A) then tailCallY(T A)
      [] tailCall(T=g(_) A) then tailCallG(T A)
      [] tailCall(T=k(_) A) then tailCallK(T A)

      [] sendMsg(O=x(_) LoA W) then sendMsgX(O LoA W)
      [] sendMsg(O=y(_) LoA W) then sendMsgY(O LoA W)
      [] sendMsg(O=g(_) LoA W) then sendMsgG(O LoA W)
      [] sendMsg(O=k(_) LoA W) then sendMsgK(O LoA W)

      [] tailSendMsg(O=x(_) LoA W) then tailSendMsgX(O LoA W)
      [] tailSendMsg(O=y(_) LoA W) then tailSendMsgY(O LoA W)
      [] tailSendMsg(O=g(_) LoA W) then tailSendMsgG(O LoA W)
      [] tailSendMsg(O=k(_) LoA W) then tailSendMsgK(O LoA W)

      [] patternMatch(R=x(_) T) then patternMatchX(R T)
      [] patternMatch(R=y(_) T) then patternMatchY(R T)
      [] patternMatch(R=g(_) T) then patternMatchG(R T)

      [] unify(L=x(_) R=x(_)) then unifyXX(L R)
      [] unify(L=x(_) R=y(_)) then unifyXY(L R)
      [] unify(L=x(_) R=g(_)) then unifyXG(L R)
      [] unify(L=x(_) R=k(_)) then unifyXK(L R)
      [] unify(L=y(_) R=y(_)) then unifyYY(L R)
      [] unify(L=y(_) R=g(_)) then unifyYG(L R)
      [] unify(L=y(_) R=k(_)) then unifyYK(L R)
      [] unify(L=g(_) R=g(_)) then unifyGG(L R)
      [] unify(L=g(_) R=k(_)) then unifyGK(L R)
      [] unify(L=k(_) R=k(_)) then unifyKK(L R)

      [] unify(L=y(_) R=x(_)) then unifyXY(R L)
      [] unify(L=g(_) R=x(_)) then unifyXG(R L)
      [] unify(L=g(_) R=y(_)) then unifyYG(R L)
      [] unify(L=k(_) R=x(_)) then unifyXK(R L)
      [] unify(L=k(_) R=y(_)) then unifyYK(R L)
      [] unify(L=k(_) R=g(_)) then unifyGK(R L)

      [] createAbstractionStore(B C D=x(_)) then createAbstractionStoreX(B C D)
      [] createAbstractionStore(B C D=y(_)) then createAbstractionStoreY(B C D)

      [] createAbstractionUnify(B C D=x(_)) then createAbstractionUnifyX(B C D)
      [] createAbstractionUnify(B C D=y(_)) then createAbstractionUnifyY(B C D)
      [] createAbstractionUnify(B C D=g(_)) then createAbstractionUnifyG(B C D)
      [] createAbstractionUnify(B C D=k(_)) then createAbstractionUnifyK(B C D)

      [] createConsStore(D) then {ResolveOverload createConsStore(0 2 D)}
      [] createConsUnify(D) then {ResolveOverload createConsUnify(0 2 D)}

      [] createConsStore(B C D=x(_)) then createConsStoreX(B C D)
      [] createConsStore(B C D=y(_)) then createConsStoreY(B C D)

      [] createConsUnify(B C D=x(_)) then createConsUnifyX(B C D)
      [] createConsUnify(B C D=y(_)) then createConsUnifyY(B C D)
      [] createConsUnify(B C D=g(_)) then createConsUnifyG(B C D)
      [] createConsUnify(B C D=k(_)) then createConsUnifyK(B C D)

      [] createTupleStore(B C D=x(_)) then createTupleStoreX(B C D)
      [] createTupleStore(B C D=y(_)) then createTupleStoreY(B C D)

      [] createTupleUnify(B C D=x(_)) then createTupleUnifyX(B C D)
      [] createTupleUnify(B C D=y(_)) then createTupleUnifyY(B C D)
      [] createTupleUnify(B C D=g(_)) then createTupleUnifyG(B C D)
      [] createTupleUnify(B C D=k(_)) then createTupleUnifyK(B C D)

      [] createRecordStore(B C D=x(_)) then createRecordStoreX(B C D)
      [] createRecordStore(B C D=y(_)) then createRecordStoreY(B C D)

      [] createRecordUnify(B C D=x(_)) then createRecordUnifyX(B C D)
      [] createRecordUnify(B C D=y(_)) then createRecordUnifyY(B C D)
      [] createRecordUnify(B C D=g(_)) then createRecordUnifyG(B C D)
      [] createRecordUnify(B C D=k(_)) then createRecordUnifyK(B C D)

      [] arrayFill(S=x(_)) then arrayFillX(S)
      [] arrayFill(S=y(_)) then arrayFillY(S)
      [] arrayFill(S=g(_)) then arrayFillG(S)
      [] arrayFill(S=k(_)) then arrayFillK(S)

      [] arrayFillNewVar(S=x(_)) then arrayFillNewVarX(S)
      [] arrayFillNewVar(S=y(_)) then arrayFillNewVarY(S)

      [] custom(...) then Instr

      else
         if {Not {HasFeature OpCodeTable {Label Instr}}} then
            {Exception.raiseError compiler(assembler noOverloadFound Instr)}
         end
         Instr
      end
   end

   fun {NonBlockingEqEq X Y}
      if {System.eq X Y} then
         true
      elseif {Not {IsDet X} andthen {IsDet Y}} then
         false
      elseif {IsRecord X} andthen {IsRecord Y} then
         Ar = {Arity X}
      in
         {Label X} == {Label Y} andthen Ar == {Arity Y} andthen
         {All Ar fun {$ F} {NonBlockingEqEq X.F Y.F} end}
      else
         X == Y
      end
   end

   class InternalAssemblerClass
      prop final

      attr
         arity
         printName
         debugData
         xRegCount
         gRegCount
         kRegCount
         kRegs
         byteCode
         byteCodeTail

      meth init(Arity PrintName <= '' DebugData <= unit)
         arity := Arity
         printName := PrintName
         debugData := DebugData
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

         case Instr
         of patternMatchX(_ Patterns) then
            {self LookForXRegsInPatterns(Patterns)}
         [] patternMatchY(_ Patterns) then
            {self LookForXRegsInPatterns(Patterns)}
         [] patternMatchG(_ Patterns) then
            {self LookForXRegsInPatterns(Patterns)}
         else
            skip
         end
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
            [] Immediate andthen {IsInt Immediate} then
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
         of H|_ andthen {NonBlockingEqEq H Value} then
            Result = KRegCount-1
         [] _|T then
            {self GetKRegForInternal(Value ?Result KRegCount-1 T)}
         [] nil then
            Result = @kRegCount
            kRegCount := Result+1
            kRegs := Value|@kRegs
         end
      end

      meth LookForXRegsInPatterns(Patterns)
         {Record.forAll Patterns
          proc {$ Pattern}
             {self LookForXRegsInPattern(Pattern)}
          end}
      end

      meth LookForXRegsInPattern(Pattern)
         proc {Loop Qs}
            case Qs
            of nil then
               skip
            [] _#_#patmatcapture(Idx)#Qr then
               if Idx >= @xRegCount then
                  xRegCount := Idx+1
               end
               {Loop Qr}
            [] _#_#_#Qr then
               {Loop Qr}
            end
         end

         Qs = {BootSerializer.serialize {BootSerializer.new} [Pattern#_]}
      in
         {Loop Qs}
      end

      meth output($)
         {self MarkEnd()}
         {CompilerSupport.newCodeArea @byteCode @arity @xRegCount
          {Reverse @kRegs} @printName @debugData}
      end
   end

   fun {InternalAssemble Arity Instructions PrintName DebugData}
      Assembler = {New InternalAssemblerClass init(Arity PrintName DebugData)}
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
         VSInstrsHd
         VSInstrsTl
         InstrsHd
         InstrsTl
         LabelDict
         Size

      meth init()
         VSInstrsHd <- @VSInstrsTl
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
            NewVSTl
            NewTl
            Instr = {ResolveOverload OverloadedInstr}
         in
            @VSInstrsTl = (@Size#OverloadedInstr) | NewVSTl
            VSInstrsTl <- NewVSTl
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
         @VSInstrsTl = nil
         @InstrsTl = nil
      end

      meth DeclareLabelsInInstr(Instr)
         case Instr
         of setupExceptionHandler(L) then
            {self declareLabel(L)}

         [] branch(L) then
            {self declareLabel(L)}

         [] condBranch(_ L1 L2) then
            {self declareLabel(L1)}
            {self declareLabel(L2)}

         [] patternMatchX(_ Patterns) then
            {self DeclareLabelsInPatterns(Patterns)}
         [] patternMatchY(_ Patterns) then
            {self DeclareLabelsInPatterns(Patterns)}
         [] patternMatchG(_ Patterns) then
            {self DeclareLabelsInPatterns(Patterns)}

         [] inlineEqualsInteger(_ _ L) then
            {self declareLabel(L)}

         else
            skip
         end
      end

      meth DeclareLabelsInPatterns(KReg)
         k(Patterns) = KReg
      in
         {Record.forAll Patterns
          proc {$ Pattern}
             L = Pattern.2
          in
             {self declareLabel(L)}
          end}
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
            if A >= 0 then branch(A) else branchBackward(~A) end

         [] condBranch(X L1 L2) then
            A1 = {self TranslateLabel(L1 EndAddr $)}
            A2 = {self TranslateLabel(L2 EndAddr $)}
         in
            case (A1 >= 0)#(A2 >= 0)
            of true#true then condBranch(X A1 A2)
            [] true#false then condBranchFB(X A1 ~A2)
            [] false#true then condBranchBF(X ~A1 A2)
            [] false#false then condBranchBB(X ~A1 ~A2)
            end

         [] patternMatchX(X Patterns) then
            patternMatchX(X {self TranslatePatterns(Patterns EndAddr $)})
         [] patternMatchY(X Patterns) then
            patternMatchY(X {self TranslatePatterns(Patterns EndAddr $)})
         [] patternMatchG(X Patterns) then
            patternMatchG(X {self TranslatePatterns(Patterns EndAddr $)})

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

      meth TranslatePatterns(KReg EndAddr $)
         k(Patterns) = KReg
      in
         k({Record.map Patterns
            fun {$ Pattern}
               Pat#L = Pattern
               A = {self TranslateLabel(L EndAddr $)}
            in
               Pat#A
            end})
      end

      meth outputVS(PrintName DebugData $)
         {self MarkEnd()}

         AddrToLabelDict = {NewDictionary}
      in
         {ForAll {Dictionary.entries @LabelDict}
          proc {$ Label#Addr}
             if {IsDet Addr} then
                {Dictionary.put AddrToLabelDict Addr Label}
             end
          end}

         '%% Code area for '#PrintName#
         case DebugData
         of d(file:F line:L column:C) then
            ' in file "'#F#'", line '#L#', column '#C
         else
            nil
         end#'\n'#
         '%% Code Size:\n'#@Size#' % bytecode elements\n'#
         AssemblerClass, CodeToVS(@VSInstrsHd AddrToLabelDict $)
      end

      meth CodeToVS(Code AddrToLabelDict $)
         case Code
         of (Addr#Instr) | CodeTail then
            Label = {Dictionary.condGet AddrToLabelDict Addr unit}
            LabelS = if Label == unit then nil else
                        {VirtualString.toString
                         'lbl('#{Value.toVirtualString Label 2 2}#')'}
                     end
            PaddingLength = 16 - {Length LabelS}
            Padding = {MakeList PaddingLength}
         in
            {ForAll Padding proc {$ X} X = 32 end}
            LabelS#Padding#{Value.toVirtualString Instr 30 10} # '\n' #
            (AssemblerClass, CodeToVS(CodeTail AddrToLabelDict $))

         [] nil then
            nil
         end
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

      [] createVar(R1) | move(R2 X=x(_)) | Rest andthen R1 == R2 then
         {Peephole createVarMove(R1 X)|Rest Assembler}

      [] createVar(X1=x(_)) | move(X2 R) | Rest andthen X1 == X2 then
         {Peephole createVarMove(R X1)|Rest Assembler}

      [] allocateY(0) | Rest then
         {Peephole Rest Assembler}

      [] return | (Rest = lbl(_) | return | _) then
         {Peephole Rest Assembler}

      [] clear(_) | _ then
         Clears Rest
      in
         {GetClears Instrs ?Clears ?Rest}
         case Rest
         of return|_ then skip
         [] call(_ _)|return|_ then skip
         [] sendMsg(_ _ _)|return|_ then skip
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

      [] call(T Arity) | return | Rest then
         {Assembler append(tailCall(T Arity))}
         {EliminateDeadCode Rest Assembler}

      [] sendMsg(Obj LabelOrArity Width) | return | Rest then
         {Assembler append(tailSendMsg(Obj LabelOrArity Width))}
         {EliminateDeadCode Rest Assembler}

      [] I1|Rest then
         {Assembler append(I1)}
         {Peephole Rest Assembler}

      [] nil then
         skip
      end
   end

   proc {Assemble Arity Code PrintName DebugData Switches ?CodeArea ?VS}
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

      CodeArea = {InternalAssemble Arity {Assembler output($)}
                  PrintName DebugData}
      VS = {ByNeedFuture
            fun {$} {Assembler outputVS(PrintName DebugData $)} end}
   end

end
