%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%\define DEBUG_EMIT

local
   fun {NextFreeIndex Used I}
      if {Dictionary.member Used I} then {NextFreeIndex Used I + 1}
      else I
      end
   end

   fun {NextFreeIndexWithoutPrintName Used Varnames I}
      if {Dictionary.member Used I} orelse {Dictionary.member Varnames I}
      then {NextFreeIndexWithoutPrintName Used Varnames I + 1}
      else I
      end
   end

   fun {NextFreeIndexWithEmptyPrintName Used Varnames I}
      if {Dictionary.member Used I}
         orelse {Dictionary.condGet Varnames I ''} \= ''
      then {NextFreeIndexWithEmptyPrintName Used Varnames I + 1}
      else I
      end
   end

   fun {LastUsedIndex Used I}
      if {Dictionary.member Used I} then I
      elseif I =< 0 then ~1
      else {LastUsedIndex Used I - 1}
      end
   end

   fun {OccursInVArgs VArgs Reg}
      case VArgs of VArg|VArgr then
         case VArg of value(!Reg) then true
         elseof record(_ _ VArgs) then
            {OccursInVArgs VArgs Reg} orelse {OccursInVArgs VArgr Reg}
         else {OccursInVArgs VArgr Reg}
         end
      [] nil then false
      end
   end
in
   fun {IsStep Coord}
      case {Label Coord} of pos then false
      [] unit then false
      else true
      end
   end

   %%
   %% The Emitter class maintains information about which registers are
   %% currently in use.  The dictionaries UsedX and UsedY map X and Y
   %% register indices respectively to the number of Regs that reference
   %% the corresponding indices.
   %%

   class Emitter
      attr
         Temporaries Permanents
         LastAliveRS ShortLivedTemps
         UsedX LowestFreeX HighestEverX
         UsedY LowestFreeY HighestEverY
         GRegRef HighestUsedG
         LocalEnvSize LocalVarnames
         CodeHd CodeTl
         LocalEnvsInhibited
         continuations contLabels

         %% These are only needed temporarily for call argument initialization:
         AdjDict DelayedInitsDict DoneDict CurrentID Stack Arity
      meth init()
         GRegRef <- {NewDictionary}
         LocalVarnames <- {NewDictionary}
         DelayedInitsDict <- {NewDictionary}
         AdjDict <- {NewDictionary}
         DoneDict <- {NewDictionary}
      end
      meth doEmit(FormalRegs AllRegs StartAddr ?Code ?GRegs ?NLiveRegs)
         RS NewCodeTl
      in
         Temporaries <- {NewDictionary}
         Permanents <- {NewDictionary}
         CodeStore, makeRegSet(?RS)
         LastAliveRS <- RS
         {ForAll FormalRegs proc {$ Reg} {BitArray.set RS Reg} end}
         ShortLivedTemps <- nil
         UsedX <- {NewDictionary}
         LowestFreeX <- 0
         HighestEverX <- ~1
         UsedY <- {NewDictionary}
         LowestFreeY <- 0
         HighestEverY <- ~1
         HighestUsedG <- ~1
         LocalEnvSize <- _
         CodeHd <- allocateL(@LocalEnvSize)|NewCodeTl
         CodeTl <- NewCodeTl
         LocalEnvsInhibited <- false
         continuations <- nil
         contLabels <- nil
         {List.forAllInd FormalRegs
          proc {$ I Reg} Emitter, AllocateThisTemp(I - 1 Reg _) end}
         {ForAll AllRegs
          proc {$ Reg} Emitter, GetPerm(Reg _) end}
         Emitter, EmitAddr(StartAddr)
         GRegs = {ForThread @HighestUsedG 0 ~1
                  fun {$ In I} {Dictionary.get @GRegRef I}|In end nil}
         @LocalEnvSize = @HighestEverY + 1
         @CodeTl = nil
         if self.debugInfoVarnamesSwitch then
            if @HighestEverY == ~1 andthen GRegs == nil then
               %% Emitting at least one `...Varname' instruction
               %% flags this procedure as having been compiled with
               %% the switch +debuginfovarnames:
               Code = @CodeHd#[localVarname('')]
            else
               Code =
               @CodeHd#
               {ForThread @HighestEverY 0 ~1
                fun {$ In I} PrintName in
                   PrintName = {Dictionary.get @LocalVarnames I}
                   localVarname(PrintName)|In
                end
                {Map AllRegs
                 fun {$ GReg} PrintName in
                    PrintName = {Dictionary.condGet @regNames GReg ''}
                    globalVarname(PrintName)
                 end}}
            end
         else
            Code = @CodeHd#nil
         end
         NLiveRegs = @HighestEverX + 1
         %% free for garbage collection:
         {Dictionary.removeAll @Temporaries}
         Temporaries <- unit
         {Dictionary.removeAll @Permanents}
         Permanents <- unit
         LastAliveRS <- unit
         CodeHd <- nil
         {Dictionary.removeAll @UsedX}
         UsedX <- unit
         {Dictionary.removeAll @UsedY}
         UsedY <- unit
         {Dictionary.removeAll @GRegRef}
         {Dictionary.removeAll @LocalVarnames}
      end
      meth newLabel(?Label)
         Label = @nextLabel
         nextLabel <- Label + 1
      end

      meth EmitAddr(Addr)
\ifdef DEBUG_EMIT
         local
            proc {ShowVInstr VInstr}   % for debugging
               L = {Label VInstr}
               N = {Width VInstr}
               NewVInstr = {MakeTuple L N}
            in
               {For 1 N 1
                proc {$ I} X = VInstr.I in
                   if {IsFree X} then X
                   elseif {BitArray.is X} then {BitArray.toList X}
                   elseif {IsRecord X}
                      andthen {HasFeature Continuations {Label X}}
                   then {Label X}
                   else X
                   end = NewVInstr.I
                end}
               {System.show NewVInstr}
            end
         in
            {ShowVInstr Addr}
         end
\endif
         case Addr of nil then
            case @contLabels of ContLabel|_ then
               Emitter, Emit(branch(ContLabel))
            [] nil then
               Emitter, DeallocateAndReturn()
            end
         [] vShared(_ Label Count Addr) then
            case Addr of nil then
               case @contLabels of nil then
                  Emitter, DeallocateAndReturn()
               [] ContLabel|_ then
                  Emitter, Emit(branch(ContLabel))
               end
            else
               if {Dictionary.member @sharedDone Label} then
                  Emitter, Emit(branch(Label))
               else
                  {Dictionary.put @sharedDone Label true}
                  Emitter, Emit(lbl(Label))
                  if {Access Count} > 1 then
                     Emitter, KillAllTemporaries()
                  end
                  Emitter, EmitAddr(Addr)
               end
            end
         elseof VInstr then
            Emitter, FlushShortLivedTemps()
            Emitter, LetDie(VInstr.1)
            case VInstr.(Continuations.{Label VInstr}) of nil then
               Emitter, EmitVInstr(VInstr)
               Emitter, EmitAddr(nil)
            elseof Cont then OldContinuations Aux NewCont in
               OldContinuations = @continuations
               continuations <- Cont|OldContinuations
               Emitter, EmitVInstr(VInstr)
               Aux = @continuations
               Aux = NewCont|_   % may be different from Cont!
               continuations <- OldContinuations
               Emitter, EmitAddr(NewCont)   % may be nil
            end
         end
      end
      meth FlushShortLivedTemps()
         case @ShortLivedTemps of I|Ir then
            Emitter, FreeX(I)
            ShortLivedTemps <- Ir
            Emitter, FlushShortLivedTemps()
         [] nil then skip
         end
      end
      meth LetDie(AliveRS) RS = @LastAliveRS in
         %% Let all registers die that do not occur in AliveRS.
         if RS \= AliveRS then
            LastAliveRS <- AliveRS
            {BitArray.nimpl RS AliveRS}
            Emitter, LetDieSub({BitArray.toList RS})
         end
      end
      meth LetDieSub(Regs)
         case Regs of Reg|Regr then
            case {Dictionary.condGet @Temporaries Reg none} of x(I) then
               Emitter, FreeX(I)
               {Dictionary.remove @Temporaries Reg}
            else skip
            end
            case {Dictionary.condGet @Permanents Reg none} of y(I) then
               Emitter, FreeY(I)
               {Dictionary.remove @Permanents Reg}
            else skip
            end
            Emitter, LetDieSub(Regr)
         [] nil then skip
         end
      end
      meth EmitVInstr(ThisAddr)
         case ThisAddr of vStepPoint(_ Addr Coord Kind Cont) then
            OldContLabels
         in
            Emitter, PushContLabel(Cont ?OldContLabels)
            Emitter, DebugEntry(Coord Kind)
            Emitter, EmitAddr(Addr)
            Emitter, PopContLabel(OldContLabels)
            Emitter, DebugExit(Coord Kind)
         [] vMakePermanent(_ Regs _) then
            {ForAll Regs
             proc {$ Reg}
                if {Dictionary.member @regNames Reg} then
                   case Emitter, GetPerm(Reg $) of none then Y in
                      Emitter, AllocatePerm(Reg ?Y)
                      case Emitter, GetTemp(Reg $) of none then
                         Emitter, Emit(createVariable(Y))
                      elseof X then
                         Emitter, Emit(move(X Y))
                      end
                   else skip
                   end
                end
             end}
         [] vClear(_ Regs _) then
            if @continuations \= nil then
               {ForAll Regs
                proc {$ Reg}
                   case Emitter, GetPerm(Reg $) of none then skip
                   elseof Y=y(I) then Regs in
                      Regs = {Filter {Dictionary.entries @Permanents}
                              fun {$ _#YG}
                                 case YG of y(I2) then I2 == I
                                 else false
                                 end
                              end}
                      if {All Regs fun {$ Reg#_} Emitter, IsLast(Reg $) end}
                      then skip
                      else Y2 in
                         {Dictionary.remove @Permanents Reg}
                         Emitter, FreeY(Reg)
                         Emitter, AllocateUnnamedPerm(Reg ?Y2)
                         {ForAll Regs
                          proc {$ Reg#_}
                             {Dictionary.put @Permanents Reg Y2}
                          end}
                         Emitter, Emit(move(Y Y2))
                         {Dictionary.put @UsedY I {Length Regs}}
                      end
                      Emitter, Emit(clear(Y))
                   end
                end}
            end
         [] vUnify(_ Reg1 Reg2 _) then R1 R2 in
            Emitter, GetReg(Reg1 ?R1)
            Emitter, GetReg(Reg2 ?R2)
            case R1 of none then
               case R2 of none then R1 in
                  Emitter, PredictReg(Reg1 ?R1)
                  Emitter, Emit(createVariable(R1))
               else skip
               end
            elsecase R2 of none then skip
            else Emitter, Emit(unify(R1 R2))
            end
            %% If either register has no temporary, assign to it the other's
            %% temporary:
            case Emitter, GetTemp(Reg1 $) of none then
               case Emitter, GetTemp(Reg2 $) of none then skip
               elseof X2 then Emitter, CopyTemp(X2 Reg1)
               end
            elseof X1 then
               case Emitter, GetTemp(Reg2 $) of none then
                  Emitter, CopyTemp(X1 Reg2)
               else skip
               end
            end
            %% If either register has no permanent, assign to it the other's
            %% permanent:
            case Emitter, GetPerm(Reg1 $) of none then
               case Emitter, GetPerm(Reg2 $) of none then skip
               elseof YG2 then Emitter, CopyPerm(YG2 Reg1)
               end
            elseof YG1 then
               case Emitter, GetPerm(Reg2 $) of none then
                  Emitter, CopyPerm(YG1 Reg2)
               else skip
               end
            end
         [] vFailure(_ _) then
            Emitter, Emit(failure)
         [] vEquateConstant(_ Constant Reg Cont) then
            case Emitter, GetReg(Reg $) of none then
               if self.debugInfoControlSwitch then R in
                  %% This is needed for 'name generation' step points:
                  Emitter, PredictReg(Reg ?R)
                  Emitter, Emit(putConstant(Constant R))
               elseif Emitter, IsLast(Reg $) then skip
               elseif
                  {IsLiteral Constant}
                  andthen Emitter, TryToUseAsSendMsg(ThisAddr Reg Constant 0
                                                     nil Cont $)
               then skip
               else
                  {Dictionary.put @Temporaries Reg ThisAddr}
                  {Dictionary.put @Permanents Reg ThisAddr}
               end
            elseof R then
               if {IsNumber Constant} then
                  Emitter, Emit(getNumber(Constant R))
               elseif {IsLiteral Constant} then
                  Emitter, Emit(getLiteral(Constant R))
               else X in
                  Emitter, AllocateShortLivedTemp(?X)
                  Emitter, Emit(putConstant(Constant X))
                  Emitter, Emit(unify(R X))
               end
            end
         [] vEquateRecord(_ Literal RecordArity Reg VArgs Cont) then
            if Emitter, TryToUseAsSendMsg(ThisAddr Reg Literal RecordArity
                                          VArgs Cont $)
            then skip
            else
               Emitter, CreateNonlinearRegs(VArgs [Reg] _)
               case Emitter, GetReg(Reg $) of none then
                  if Emitter, IsLast(Reg $) then skip
                  else R in
                     Emitter, PredictReg(Reg ?R)
                     Emitter, EmitRecordWrite(Literal RecordArity R VArgs)
                  end
               elseof R then
                  if Emitter, IsLast(Reg $) then
                     if {OccursInVArgs VArgs Reg} then skip
                     else Emitter, FreeReg(Reg)
                     end
                  end
                  Emitter, EmitRecordRead(Literal RecordArity R VArgs)
               end
            end
         [] vGetVariable(_ Reg _) then
            case Emitter, GetReg(Reg $) of none then
               if Emitter, IsLast(Reg $) then
                  Emitter, Emit(getVoid(1))
               else R in
                  Emitter, PredictReg(Reg ?R)
                  Emitter, Emit(getVariable(R))
               end
            elseof R then
               %--** this can never happen!
               Emitter, Emit(unifyValue(R))
            end
         [] vCallBuiltin(OccsRS Builtinname Regs Coord Cont) then
            BIInfo NewCont2
         in
            BIInfo = {Builtins.getInfo Builtinname}
            NewCont2 =
            if {CondSelect BIInfo test false} then NInputs Reg in
               NInputs = {Length BIInfo.imods}
               Reg = {Nth Regs NInputs + 1}
               case Cont
               of vTestBool(_ !Reg Addr1 Addr2 _ Coord NewCont InitsRS) then
                  if {Not self.debugInfoControlSwitch}
                     andthen Emitter, IsFirst(Reg $)
                     andthen Emitter, DoesNotOccurIn(Reg Addr1 $)
                     andthen Emitter, DoesNotOccurIn(Reg Addr2 $)
                     andthen Emitter, DoesNotOccurIn(Reg NewCont $)
                  then
                     TestCont =
                     case Builtinname of 'Value.\'==\'' then
                        [Reg1 Reg2 _] = Regs
                     in
                        case {Dictionary.condGet @Temporaries Reg1 none}
                        of vEquateConstant(_ Constant _ _)
                           andthen ({IsNumber Constant} orelse
                                    {IsLiteral Constant})
                        then
                           vTestConstant(OccsRS Reg2 Constant Addr1 Addr2
                                         Coord NewCont InitsRS)
                        elsecase {Dictionary.condGet @Temporaries Reg2 none}
                        of vEquateConstant(_ Constant _ _)
                           andthen ({IsNumber Constant} orelse
                                    {IsLiteral Constant})
                        then
                           vTestConstant(OccsRS Reg1 Constant Addr1 Addr2
                                         Coord NewCont InitsRS)
                        else ~1
                        end
                     [] 'Value.\'\\=\'' then [Reg1 Reg2 _] = Regs in
                        case {Dictionary.condGet @Temporaries Reg1 none}
                        of vEquateConstant(_ Constant _ _)
                           andthen ({IsNumber Constant} orelse
                                    {IsLiteral Constant})
                        then
                           vTestConstant(OccsRS Reg2 Constant Addr2 Addr1
                                         Coord NewCont InitsRS)
                        elsecase {Dictionary.condGet @Temporaries Reg2 none}
                        of vEquateConstant(_ Constant _ _)
                           andthen ({IsNumber Constant} orelse
                                    {IsLiteral Constant})
                        then
                           vTestConstant(OccsRS Reg1 Constant Addr2 Addr1
                                         Coord NewCont InitsRS)
                        else ~1
                        end
                     else ~1
                     end
                  in
                     if TestCont \= ~1 then TestCont
                     elseif
                        {All {List.drop Regs NInputs}
                         fun {$ Reg} Emitter, IsFirst(Reg $) end}
                     then
                        vTestBuiltin(OccsRS Builtinname Regs Addr1 Addr2
                                     NewCont InitsRS)
                     else ~1
                     end
                  else ~1
                  end
               else ~1
               end
            else ~1
            end
            if NewCont2 \= ~1 then
               continuations <- NewCont2|@continuations.2
            else
               case Builtinname of 'getReturn' then [Reg] = Regs in
                  %--** does this still exist?
                  case Emitter, GetReg(Reg $) of none then R in
                     Emitter, PredictReg(Reg ?R)
                     Emitter, Emit(getReturn(R))
                  elseof R then X in
                     Emitter, AllocateShortLivedTemp(?X)
                     Emitter, Emit(getReturn(X))
                     Emitter, Emit(unify(R X))
                  end
               else XsIn XsOut Unifies in
                  Emitter, AllocateBuiltinArgs(Regs BIInfo.imods ?XsIn
                                               ?XsOut ?Unifies)
                  Emitter, DebugEntry(Coord 'call')
                  Emitter, Emit(callBI(Builtinname XsIn#XsOut))
                  Emitter, EmitUnifies(Unifies)
                  Emitter, DebugExit(Coord 'call')
               end
            end
         [] vGenCall(_ Reg IsMethod Literal RecordArity Regs Coord _) then
            case Emitter, GetReg(Reg $) of g(_) then Instr R in
               Instr = genCall(gci(R IsMethod Literal false RecordArity) 0)
               Emitter, GenericEmitCall(any Reg Regs Instr R _ Coord nil)
            else
               if IsMethod then Instr R Which in
                  Instr = applMeth(ami(Literal RecordArity) R)
                  Which = case @continuations of nil then
                             non_y   % tailApplMeth
                          else any
                          end
                  Emitter, GenericEmitCall(Which Reg Regs Instr R _ Coord nil)
               else Instr R Arity Which in
                  Instr = call(R Arity)
                  Which = case @continuations of nil then non_y   % tailCall
                          else any
                          end
                  Emitter,
                  GenericEmitCall(Which Reg Regs Instr R Arity Coord nil)
               end
            end
         [] vCall(_ Reg Regs Coord _) then Instr R Arity Which in
            Instr = call(R Arity)
            Which = case @continuations of nil then non_y   % tailCall
                    else any
                    end
            Emitter, GenericEmitCall(Which Reg Regs Instr R Arity Coord nil)
         [] vFastCall(_ PredicateRef Regs Coord _) then Instr in
            if {IsProcedure PredicateRef} then
               Instr = marshalledFastCall(PredicateRef {Length Regs} * 2)
            else
               Instr = genFastCall(PredicateRef {Length Regs} * 2)
            end
            Emitter, GenericEmitCall(none ~1 Regs Instr _ _ Coord nil)
         [] vApplMeth(_ Reg Literal RecordArity Regs Coord _) then
            Instr R Which in
            Instr = applMeth(ami(Literal RecordArity) R)
            Which = case @continuations of nil then non_y   % tailApplMeth
                    else any
                    end
            Emitter, GenericEmitCall(Which Reg Regs Instr R _ Coord nil)
         [] vInlineDot(_ Reg1 Feature Reg2 AlwaysSucceeds Coord _) then
            if AlwaysSucceeds then skip
            elseif Emitter, IsFirst(Reg1 $) then
               {self.reporter
                warn(coord: Coord kind: 'code generation warning'
                     msg: ('dot access on undetermined variable suspends '#
                           'forever'))}
            end
            case Emitter, GetReg(Reg2 $) of none then
               if AlwaysSucceeds andthen Emitter, IsLast(Reg2 $) then skip
               else X1 X2 in
                  Emitter, AllocateAndInitializeAnyTemp(Reg1 ?X1)
                  Emitter, PredictBuiltinOutput(Reg2 ?X2)
                  Emitter, Emit(inlineDot(X1 Feature X2 cache))
               end
            elseof R then X1 X2 in
               Emitter, AllocateAndInitializeAnyTemp(Reg1 ?X1)
               Emitter, AllocateShortLivedTemp(?X2)
               Emitter, Emit(inlineDot(X1 Feature X2 cache))
               Emitter, Emit(unify(X2 R))
            end
         [] vInlineAt(_ Literal Reg _) then
            case Emitter, GetReg(Reg $) of none then X in
               Emitter, PredictBuiltinOutput(Reg ?X)
               Emitter, Emit(inlineAt(Literal X cache))
            elseof R then X in
               Emitter, AllocateShortLivedTemp(?X)
               Emitter, Emit(inlineAt(Literal X cache))
               Emitter, Emit(unify(X R))
            end
         [] vInlineAssign(_ Literal Reg _) then X in
            Emitter, AllocateAndInitializeAnyTemp(Reg ?X)
            Emitter, Emit(inlineAssign(Literal X cache))
         [] vGetSelf(_ Reg _) then
            case Emitter, GetReg(Reg $) of none then
               if Emitter, IsLast(Reg $) then skip
               else
                  {Dictionary.put @Temporaries Reg ThisAddr}
                  {Dictionary.put @Permanents Reg ThisAddr}
               end
            elseof R then X in
               Emitter, AllocateShortLivedTemp(?X)
               Emitter, Emit(getSelf(X))
               Emitter, Emit(unify(X R))
            end
         [] vSetSelf(_ Reg _) then X in
            Emitter, AllocateAndInitializeAnyTemp(Reg ?X)
            Emitter, Emit(setSelf(X))
         [] vDefinition(_ Reg PredId PredicateRef GRegs Code _) then
            if Emitter, IsFirst(Reg $) andthen Emitter, IsLast(Reg $)
               andthen PredicateRef == unit
            then skip
            else Rs X DoUnify StartLabel ContLabel Code1 Code2 in
               Rs = {Map GRegs
                     proc {$ Reg ?R}
                        case Emitter, GetReg(Reg $) of none then
                           Emitter, PredictReg(Reg ?R)
                           Emitter, Emit(createVariable(R))
                        elseof XYG then R = XYG
                        end
                     end}
               if Emitter, IsFirst(Reg $) then
                  Emitter, PredictTemp(Reg ?X)
                  DoUnify = false
               else
                  Emitter, AllocateShortLivedTemp(?X)
                  DoUnify = true
               end
               Emitter, newLabel(?StartLabel)
               Emitter, Emit(lbl(StartLabel))
               Emitter, newLabel(?ContLabel)
               Code = Code1#Code2
               Emitter, Emit(definition(X ContLabel PredId
                                        PredicateRef Rs Code1))
               Emitter, Emit(endDefinition(StartLabel))
               {ForAll Code2 proc {$ Instr} Emitter, Emit(Instr) end}
               Emitter, Emit(lbl(ContLabel))
               if DoUnify then
                  Emitter, Emit(unify(X Emitter, GetReg(Reg $)))
               end
            end
         [] vDefinitionCopy(_ Reg1 Reg2 PredId PredicateRef GRegs Code _) then
            if Emitter, IsFirst(Reg2 $) andthen Emitter, IsLast(Reg2 $)
               andthen PredicateRef == unit
            then skip
            else Rs X StartLabel ContLabel Code1 Code2 in
               Rs = {Map GRegs
                     proc {$ Reg ?R}
                        case Emitter, GetReg(Reg $) of none then
                           Emitter, PredictReg(Reg ?R)
                           Emitter, Emit(createVariable(R))
                        elseof XYG then R = XYG
                        end
                     end}
               Emitter, GetTemp(Reg1 ?X=x(_))
               Emitter, newLabel(?StartLabel)
               Emitter, Emit(lbl(StartLabel))
               Emitter, newLabel(?ContLabel)
               Code = Code1#Code2
               Emitter, Emit(definitionCopy(X ContLabel PredId
                                            PredicateRef Rs Code1))
               Emitter, Emit(endDefinition(StartLabel))
               {ForAll Code2 proc {$ Instr} Emitter, Emit(Instr) end}
               Emitter, Emit(lbl(ContLabel))
               Emitter, FreeX(X.1)
               {Dictionary.remove @Temporaries Reg1}
               case Emitter, GetReg(Reg2 $) of none then
                  Emitter, AllocateThisTemp(X.1 Reg2 _)
               elseof R then
                  Emitter, Emit(unify(X R))
               end
            end
         [] vExHandler(_ Addr1 Reg Addr2 Coord Cont InitsRS) then
            OldContLabels Label1 RS RegMap1 OldLocalEnvsInhibited RegMap2
         in
            Emitter, PushContLabel(Cont ?OldContLabels)
            Emitter, newLabel(?Label1)
            case Addr2 of nil then
               case Cont of nil then RS = {BitArray.new 0 0}
               else RS = Cont.1
               end
            else
               case Cont of nil then RS = Addr2.1
               else
                  RS = {BitArray.clone Addr2.1}
                  {BitArray.disj RS Cont.1}
               end
            end
            Emitter, DoInits(InitsRS v(RS))
            Emitter, Emit(exHandler(Label1))
            Emitter, SaveAllRegisterMappings(?RegMap1)
            Emitter, KillAllTemporaries()
            Emitter, AllocateThisTemp(0 Reg _)
            OldLocalEnvsInhibited = @LocalEnvsInhibited
            LocalEnvsInhibited <- true
            Emitter, EmitAddr(Addr2)
            LocalEnvsInhibited <- OldLocalEnvsInhibited
            Emitter, RestoreAllRegisterMappings(RegMap1)
            Emitter, Emit(lbl(Label1))
            Emitter, DebugEntry(Coord 'exception handler')
            Emitter, SaveRegisterMapping(RegMap2)
            Emitter, EmitAddr(Addr1)
            Emitter, RestoreRegisterMapping(RegMap2)
            Emitter, PopContLabel(OldContLabels)
         [] vPopEx(_ Coord _) then
            Emitter, DebugExit(Coord 'exception handler')
            Emitter, Emit(popEx)
         [] vCreateCond(_ VClauses Addr Cont Coord _ InitsRS) then
            OldContLabels Label Dest RegMap
         in
            Emitter, DoInits(InitsRS ThisAddr)
            Emitter, PrepareShared(Addr _)
            Emitter, PushContLabel(Cont ?OldContLabels)
            Emitter, Dereference(Addr ?Label ?Dest)
            Emitter, DebugEntry(Coord 'conditional')
            Emitter, Emit(createCond(Dest))
            Emitter, KillAllTemporaries()
            {FoldLTail VClauses
             proc {$ GuardLabel InitsRS0#Addr1#Addr2|Rest ?NextLabel} RegMap in
                Emitter, Emit(lbl(GuardLabel))
                case Rest of _|_ then
                   Emitter, newLabel(?NextLabel)
                   Emitter, Emit(nextClause(NextLabel))
                [] nil then
                   Emitter, Emit(lastClause)
                end
                Emitter, Emit(clause)
                Emitter, DoInits(InitsRS0 nil)
                Emitter, EmitGuard(Addr1)
                Emitter, SaveRegisterMapping(?RegMap)
                Emitter, EmitAddr(Addr2)
                Emitter, RestoreRegisterMapping(RegMap)
             end Emitter, newLabel($) _}
            Emitter, Emit(lbl(Label))
            Emitter, SaveRegisterMapping(?RegMap)
            Emitter, EmitAddr(Addr)
            Emitter, RestoreRegisterMapping(RegMap)
            Emitter, PopContLabel(OldContLabels)
            Emitter, DebugExit(Coord 'conditional')
         [] vCreateOr(_ VClauses Cont Coord _ InitsRS) then
            Emitter, EmitDisjunction(createOr VClauses Cont Coord InitsRS
                                     ThisAddr)
         [] vCreateEnumOr(_ VClauses Cont Coord _ InitsRS) then
            Emitter, EmitDisjunction(createEnumOr VClauses Cont Coord InitsRS
                                     ThisAddr)
         [] vCreateChoice(_ VClauses Cont Coord _ InitsRS) then
            Emitter, EmitDisjunction(createChoice VClauses Cont Coord InitsRS
                                     ThisAddr)
         [] vAsk(_ Cont) then
            Emitter, DoInits(nil Cont)
            Emitter, Emit(ask)
            Emitter, KillAllTemporaries()
         [] vWait(_ Cont) then
            Emitter, DoInits(nil Cont)
            Emitter, Emit(wait)
            Emitter, KillAllTemporaries()
         [] vWaitTop(_ Cont) then
            Emitter, DoInits(nil Cont)
            Emitter, Emit(waitTop)
            Emitter, KillAllTemporaries()
         [] vTestBool(_ Reg Addr1 Addr2 Addr3 Coord Cont InitsRS) then
            LocalEnv1 LocalEnv2 LocalEnv3
            HasLocalEnv R OldContLabels Label2 Dest2 Label3 Dest3
            RegMap1 RegMap2 RegMap3
         in
            Emitter, DoInits(InitsRS Cont)
            Emitter, PrepareShared(Addr1 ?LocalEnv1)
            Emitter, PrepareShared(Addr2 ?LocalEnv2)
            Emitter, PrepareShared(Addr3 ?LocalEnv3)
            Emitter, MayAllocateEnvLocally(Cont {And {And LocalEnv1 LocalEnv2}
                                                 LocalEnv3} ?HasLocalEnv)
            case Emitter, GetReg(Reg $) of none then
               {self.reporter
                warn(coord: Coord kind: 'code generation warning'
                     msg: 'conditional suspends forever'
                     items: [hint(l: 'Hint'
                                  m: ('undetermined variable used '#
                                      'as `if\' arbiter'))])}
               Emitter, AllocateAndInitializeAnyTemp(Reg ?R)
            elseof XYG then R = XYG
            end
            Emitter, PushContLabel(Cont ?OldContLabels)
            Emitter, Dereference(Addr2 ?Label2 ?Dest2)
            Emitter, Dereference(Addr3 ?Label3 ?Dest3)
            Emitter, DebugEntry(Coord 'conditional')
            Emitter, Emit(testBool(R Dest2 Dest3))
            Emitter, SaveAllRegisterMappings(?RegMap1)
            Emitter, EmitAddrInLocalEnv(Addr1 HasLocalEnv)
            Emitter, RestoreAllRegisterMappings(RegMap1)
            Emitter, Emit(lbl(Label2))
            Emitter, SaveAllRegisterMappings(?RegMap2)
            Emitter, EmitAddrInLocalEnv(Addr2 HasLocalEnv)
            Emitter, RestoreAllRegisterMappings(RegMap2)
            Emitter, Emit(lbl(Label3))
            Emitter, SaveRegisterMapping(?RegMap3)
            Emitter, EmitAddrInLocalEnv(Addr3 HasLocalEnv)
            Emitter, RestoreRegisterMapping(RegMap3)
            Emitter, PopContLabel(OldContLabels)
            Emitter, DebugExit(Coord 'conditional')
         [] vTestBuiltin(_ Builtinname Regs Addr1 Addr2 Cont InitsRS) then
            LocalEnv1 LocalEnv2
            HasLocalEnv OldContLabels Label2 Dest2 BIInfo XsIn
            XsOut RegMap1 RegMap2
         in
            Emitter, DoInits(InitsRS Cont)
            Emitter, PrepareShared(Addr1 ?LocalEnv1)
            Emitter, PrepareShared(Addr2 ?LocalEnv2)
            Emitter, MayAllocateEnvLocally(Cont {And LocalEnv1 LocalEnv2}
                                           ?HasLocalEnv)
            Emitter, PushContLabel(Cont ?OldContLabels)
            Emitter, Dereference(Addr2 ?Label2 ?Dest2)
            BIInfo = {Builtins.getInfo Builtinname}
            Emitter, AllocateBuiltinArgs(Regs BIInfo.imods ?XsIn ?XsOut nil)
            Emitter, Emit(testBI(Builtinname XsIn#XsOut Dest2))
            Emitter, SaveAllRegisterMappings(?RegMap1)
            Emitter, EmitAddrInLocalEnv(Addr1 HasLocalEnv)
            Emitter, RestoreAllRegisterMappings(RegMap1)
            Emitter, Emit(lbl(Label2))
            Emitter, SaveRegisterMapping(?RegMap2)
            Emitter, EmitAddrInLocalEnv(Addr2 HasLocalEnv)
            Emitter, RestoreRegisterMapping(RegMap2)
            Emitter, PopContLabel(OldContLabels)
         [] vTestConstant(_ Reg Constant Addr1 Addr2 Coord Cont InitsRS) then
            LocalEnv1 LocalEnv2
            HasLocalEnv R OldContLabels Label2 Dest2 InstrLabel RegMap1 RegMap2
         in
            Emitter, DoInits(InitsRS Cont)
            Emitter, PrepareShared(Addr1 ?LocalEnv1)
            Emitter, PrepareShared(Addr2 ?LocalEnv2)
            Emitter, MayAllocateEnvLocally(Cont {And LocalEnv1 LocalEnv2}
                                           ?HasLocalEnv)
            case Emitter, GetReg(Reg $) of none then
               {self.reporter
                warn(coord: Coord kind: 'code generation warning'
                     msg: 'conditional suspends forever'
                     items: [hint(l: 'Hint'
                                  m: ('undetermined variable used '#
                                      'as boolean guard'))])}
               Emitter, AllocateAndInitializeAnyTemp(Reg ?R)
            elseof XYG then R = XYG
            end
            Emitter, PushContLabel(Cont ?OldContLabels)
            Emitter, Dereference(Addr2 ?Label2 ?Dest2)
            Emitter, DebugEntry(Coord 'conditional')
            InstrLabel = if {IsLiteral Constant} then testLiteral
                         elseif {IsNumber Constant} then testNumber
                         else
                            {Exception.raiseError
                             compiler(internal testConstant(Constant))} unit
                         end
            Emitter, Emit(InstrLabel(R Constant Dest2))
            Emitter, SaveAllRegisterMappings(?RegMap1)
            Emitter, EmitAddrInLocalEnv(Addr1 HasLocalEnv)
            Emitter, RestoreAllRegisterMappings(RegMap1)
            Emitter, Emit(lbl(Label2))
            Emitter, SaveRegisterMapping(?RegMap2)
            Emitter, EmitAddrInLocalEnv(Addr2 HasLocalEnv)
            Emitter, RestoreRegisterMapping(RegMap2)
            Emitter, PopContLabel(OldContLabels)
            Emitter, DebugExit(Coord 'conditional')
         [] vMatch(_ Reg Addr VHashTableEntries Coord Cont InitsRS) then
            LocalEnv1 HasLocalEnv
            R OldContLabels Label Dest NewVHashTableEntries RegMap
         in
            Emitter, DoInits(InitsRS Cont)
            Emitter, PrepareShared(Addr ?LocalEnv1)
            Emitter, MayAllocateEnvLocally(Cont LocalEnv1 ?HasLocalEnv)
            case Emitter, GetReg(Reg $) of none then
               {self.reporter
                warn(coord: Coord kind: 'code generation warning'
                     msg: 'conditional suspends forever'
                     items: [hint(l: 'Hint'
                                  m: ('undetermined variable used '#
                                      'as pattern case arbiter'))])}
               Emitter, AllocateAndInitializeAnyTemp(Reg ?R)
            elseof XYG then R = XYG
            end
            Emitter, PushContLabel(Cont ?OldContLabels)
            Emitter, Dereference(Addr ?Label ?Dest)
            Emitter, DebugEntry(Coord 'conditional')
            Emitter, Emit(match(R ht(Dest NewVHashTableEntries)))
            NewVHashTableEntries =
            {Map VHashTableEntries
             proc {$ VHashTableEntry ?NewEntry} Addr Label Dest RegMap in
                case VHashTableEntry of onScalar(X A) then
                   Addr = A
                   NewEntry = onScalar(X Dest)
                [] onRecord(X1 X2 A) then
                   Addr = A
                   NewEntry = onRecord(X1 X2 Dest)
                end
                Emitter, Dereference(Addr ?Label ?Dest)
                Emitter, Emit(lbl(Label))
                Emitter, SaveAllRegisterMappings(?RegMap)
                Emitter, EmitAddrInLocalEnv(Addr HasLocalEnv)
                Emitter, RestoreAllRegisterMappings(RegMap)
             end}
            Emitter, Emit(lbl(Label))
            Emitter, SaveRegisterMapping(?RegMap)
            Emitter, EmitAddrInLocalEnv(Addr HasLocalEnv)
            Emitter, RestoreRegisterMapping(RegMap)
            Emitter, PopContLabel(OldContLabels)
            Emitter, DebugExit(Coord 'conditional')
         [] vThread(_ Addr Coord Cont InitsRS) then
            HasLocalEnv ContLabel Dest RegMap OldContLabels
         in
            Emitter, DoInits(InitsRS ThisAddr)
            Emitter, MayAllocateEnvLocally(Cont true ?HasLocalEnv)
            Emitter, Dereference(Cont ?ContLabel ?Dest)
            Emitter, DebugEntry(Coord 'thread')
            Emitter, Emit('thread'(Dest))
            Emitter, SaveAllRegisterMappings(?RegMap)
            Emitter, KillAllTemporaries()
            OldContLabels = @contLabels
            contLabels <- nil
            Emitter, EmitAddrInLocalEnv(Addr HasLocalEnv)
            contLabels <- OldContLabels
            Emitter, RestoreAllRegisterMappings(RegMap)
            Emitter, Emit(lbl(ContLabel))
            Emitter, DebugExit(Coord 'thread')
         [] vLockThread(_ Reg Coord _ Dest) then X in
            if Emitter, IsFirst(Reg $) then
               {self.reporter
                warn(coord: Coord kind: 'code generation warning'
                     msg: 'lock suspends forever'
                     items: [hint(l: 'Hint'
                                  m: 'undetermined variable used as lock')])}
            end
            Emitter, AllocateAndInitializeAnyTemp(Reg ?X)
            Emitter, DebugEntry(Coord 'lock')
            Emitter, Emit(lockThread(Dest X))
         [] vLockEnd(_ Coord Cont Dest) then ContLabel Dest0 in
            Emitter, Dereference(Cont ?ContLabel ?Dest0)
            Dest = if self.debugInfoControlSwitch then ContLabel
                   else Dest0
                   end
            Emitter, DoInits(nil Cont)
            Emitter, KillAllTemporaries()
            Emitter, Emit(return)
            Emitter, Emit(lbl(ContLabel))
            Emitter, DebugExit(Coord 'lock')
         end
      end

      %%
      %% Auxiliary Methods
      %%

      meth DebugEntry(Coord Comment)
         if {IsStep Coord} then FileName Line Column Kind in
            case Coord of fineStep(F L C) then
               FileName = F Line = L Column = C Kind = 'f'
            [] fineStep(F L C _ _ _) then
               FileName = F Line = L Column = C Kind = 'f'
            [] coarseStep(F L C) then
               FileName = F Line = L Column = C Kind = 'c'
            [] coarseStep(F L C _ _ _) then
               FileName = F Line = L Column = C Kind = 'c'
            end
            Emitter,
            Emit(debugEntry(FileName Line Column
                            {VirtualString.toAtom Comment#'/'#Kind}))
         end
      end
      meth DebugExit(Coord Comment)
         if {IsStep Coord} then FileName Line Column Kind in
            case Coord of fineStep(F L C) then
               FileName = F Line = L Column = C Kind = 'f'
            [] fineStep(_ _ _ F L C) then
               FileName = F Line = L Column = C Kind = 'f'
            [] coarseStep(F L C) then
               FileName = F Line = L Column = C Kind = 'c'
            [] coarseStep(_ _ _ F L C) then
               FileName = F Line = L Column = C Kind = 'c'
            end
            Emitter,
            Emit(debugExit(FileName Line Column
                           {VirtualString.toAtom Comment#'/'#Kind}))
         end
      end

      meth TryToUseAsSendMsg(ThisAddr Reg Literal RecordArity VArgs Cont $)
         %% If a vEquate{Constant,Record} instruction is immediately
         %% followed by a unary vCall instruction with the same register as
         %% argument and this register is linear, we emit a sendMsg instruction
         %% for the sequence.
         Arity = if {IsInt RecordArity} then RecordArity
                 else {Length RecordArity}
                 end
      in
         if self.debugInfoControlSwitch then false
         elseif Arity >= {Property.get 'limits.bytecode.xregisters'} then
            false
         elseif Emitter, IsFirst(Reg $) then
            if {OccursInVArgs VArgs Reg} then false
            elsecase Cont of vCall(_ ObjReg [!Reg] Coord Cont2) then
               if Emitter, DoesNotOccurIn(Reg Cont2 $) then
                  Emitter, EmitSendMsg(ObjReg Literal RecordArity
                                       VArgs Coord Cont2)
                  true
               else false
               end
            elseof vGenCall(_ ObjReg false _ _ [!Reg] Coord Cont2) then
               if Emitter, DoesNotOccurIn(Reg Cont2 $) then
                  Emitter, EmitSendMsg(ObjReg Literal RecordArity
                                       VArgs Coord Cont2)
                  true
               else false
               end
            elseof vCallBuiltin(_ 'Object.new' [ClassReg !Reg ObjReg] Coord Cont2)
            then
               if Emitter, DoesNotOccurIn(Reg Cont2 $) then
                  X1 X2
               in
                  Emitter, AllocateAndInitializeAnyTemp(ClassReg ?X1)
                  Emitter, PredictTemp(ObjReg ?X2)
                  Emitter, Emit(callBI('Object.newObject' [X1]#[X2]))
                  %--** maybe X1 may die here?
                  Emitter, EmitSendMsg(ObjReg Literal RecordArity
                                       VArgs Coord Cont2)
                  true
               else false
               end
            else false
            end
         else false
         end
      end
      meth EmitSendMsg(ObjReg Literal RecordArity VArgs Coord Cont)
         Instr Arity R Regs ArgInits OldContinuations
      in
         Instr = sendMsg(Literal R RecordArity cache)
         Arity = if {IsInt RecordArity} then RecordArity
                 else {Length RecordArity}
                 end
         Emitter, ReserveTemps(Arity + 1)
         Regs#ArgInits =
         {List.foldRInd VArgs
          fun {$ I VArg Regs#ArgInits}
             case VArg of constant(Constant) then
                (~I|Regs)#((I - 1)#putConstant(Constant x(I - 1))|ArgInits)
             [] value(Reg) then
                (Reg|Regs)#ArgInits
             [] record(Literal RecordArity VArgs) then
                if {Dictionary.member @UsedX I - 1} then X in
                   Emitter, AllocateShortLivedTemp(?X)
                   Emitter, EmitRecordWrite(Literal RecordArity X VArgs)
                   (~I|Regs)#((I - 1)#move(X x(I - 1))|ArgInits)
                else X in
                   Emitter, AllocateThisShortLivedTemp(I - 1 ?X)
                   Emitter, EmitRecordWrite(Literal RecordArity X VArgs)
                   (~I|Regs)#((I - 1)#'skip'|ArgInits)
                end
             end
          end nil#nil}
         OldContinuations = @continuations.2
         continuations <- case Cont of nil then OldContinuations
                          else Cont|OldContinuations
                          end
         Emitter, GenericEmitCall(any ObjReg Regs Instr R _ Coord ArgInits)
         continuations <- Cont|OldContinuations
      end

      meth GenericEmitCall(WhichReg Reg Regs Instr R Arity Coord ArgInits)
         R0 NLiveRegs
      in
         %%
         %% This method does everything that is required to set up the
         %% registers for a call.  WhichReg indicates whether the call
         %% instruction to use actually needs a register to hold a
         %% reference to the called procedure (else WhichReg is 'none')
         %% and if so, in what kind of register it must reside (in which
         %% case WhichReg is either 'non_y' or 'any' and Reg holds the
         %% abstraction).
         %%
         %% Regs is the list of the argument registers for the call.
         %% These have to be placed in the registers x(0) to x(Arity - 1).
         %%
         %% ArgInits is a list of delayed initializations to be performed
         %% only directly before the call as an optimization (when we
         %% know which argument register they are to be placed in and this
         %% register is free).
         %%
         case @continuations of Cont|_ then
            %% For each register still required after the call, one of the
            %% following holds:
            %% 1) it has no delayed initialization and is unallocated
            %%    => nothing to be done
            %% 2) it has a temporary, but no permanent
            %%    => make it permanent
            %% 3) it already has a permanent
            %%    => nothing to be done
            %% 4) it has a delayed initialization and is an argument
            %%    => emit it into a permanent
            %% 5) it has a delayed initialization and is not an argument
            %%    => delay it until after the call
            {ForAll {BitArray.toList Cont.1}
             proc {$ Reg} Result in
                %% We have to be careful not to emit any delayed initialization
                %% too soon, so we do not use GetTemp here:
                Result = {Dictionary.condGet @Temporaries Reg none}
                case Result of none then skip   % 1)
                [] x(_) then
                   case Emitter, GetPerm(Reg $) of none then Y in   % 2)
                      Emitter, AllocatePerm(Reg ?Y)
                      Emitter, Emit(move(Result Y))
                   else skip   % 3)
                   end
                else
                   if {Member Reg Regs} then   % 4)
                      %% try to emit the delayed initialization into a
                      %% permanent (does not work for vGetSelf!):
                      case Emitter, GetPerm(Reg $) of none then X Y in
                         %% initialization needs a temporary as destination:
                         Emitter, GetTemp(Reg ?X)   % ... emitting it
                         Emitter, AllocatePerm(Reg ?Y)
                         Emitter, Emit(move(X Y))
                      else skip
                      end
                   else skip   % 5)
                   end
                end
             end}
         [] nil then skip
         end
         %%
         %% Since possibly further temporaries will be allocated (for
         %% the reference to the abstraction and for intermediates while
         %% reordering the argument registers), we have to ensure that
         %% these will not interfere with the argument indices:
         %%
         Arity = {Length Regs}
         Emitter, ReserveTemps(Arity)
         %%
         %% Allocate Reg (if necessary) and place it in the kind of register
         %% it is required in; make it permanent if needed:
         %%
         case WhichReg of none then
            % The abstraction is not referenced by a register.
            R0 = none
         else
            case Emitter, GetReg(Reg $) of none then
               %% Reg has not yet been allocated.  Let's check whether
               %% it needs to be permanent.
               {self.reporter
                warn(coord: Coord kind: 'code generation warning'
                     msg: 'application suspends forever'
                     items: [hint(l: 'Hint'
                                  m: ('undetermined variable called '#
                                      'as procedure'))])}
               if Emitter, IsLast(Reg $) orelse WhichReg == non_y then
                  Emitter, AllocateAnyTemp(Reg ?R0)
               else
                  Emitter, AllocatePerm(Reg ?R0)
               end
               Emitter, Emit(createVariable(R0))
            else
               if Emitter, IsLast(Reg $) then
                  %% Here we know: Reg has been allocated and is not needed
                  %% any longer after the call instruction.  Thus, either a
                  %% permanent or a temporary register is fine.
                  %% If it is a temporary however, it must not collide with
                  %% an argument index.
                  case Emitter, GetPerm(Reg $) of none then X in
                     Emitter, GetTemp(Reg ?X)
                     if X.1 < Arity then NewX in
                        Emitter, FreeReg(Reg)
                        Emitter, ReserveTemps(Arity)
                        Emitter, AllocateAnyTemp(Reg ?NewX)
                        Emitter, Emit(move(X NewX))
                     end
                  elsecase WhichReg of non_y then
                     case Emitter, GetTemp(Reg $) of X=x(I) then
                        if I < Arity then NewX in
                           Emitter, FreeReg(Reg)
                           Emitter, ReserveTemps(Arity)
                           Emitter, AllocateAnyTemp(Reg ?NewX)
                           Emitter, Emit(move(X NewX))
                        end
                     else skip
                     end
                  else skip
                  end
               else
                  case Emitter, GetPerm(Reg $) of none then X Y in
                     %% Here we know: Reg has only been allocated as a
                     %% temporary but is still needed after the call
                     %% instruction.  Thus, we have to make it permanent.
                     Emitter, GetTemp(Reg ?X)
                     Emitter, AllocatePerm(Reg ?Y)
                     Emitter, Emit(move(X Y))
                  else
                     %% Reg is already permanent.
                     skip
                  end
               end
            end
            case WhichReg of non_y then
               %% The instruction requires Reg not to reside in a Y register:
               case Emitter, GetReg(Reg $) of Y=y(_) then
                  case Emitter, GetTemp(Reg $) of none then
                     %% move from permanent to temporary:
                     Emitter, AllocateAnyTemp(Reg ?R0)
                     Emitter, Emit(move(Y R0))
                  elseof X then
                     R0 = X
                  end
               elseof XG then
                  R0 = XG
               end
            [] any then
               %% Reg may reside in any register - which it does.
               Emitter, GetReg(Reg ?R0)
            end
         end
         %%
         %% Now we place the arguments in the correct locations and
         %% emit the call instruction.
         %%
         Emitter, SetArguments(Arity ArgInits Regs)
         if self.debugInfoControlSwitch then
            case R0 of x(I) then
               %% this test is needed to ensure correctness, since
               %% the emulator does not save X registers with
               %% indices > Arity:
               if I > Arity then
                  Emitter, Emit(move(R0 R=x(Arity)))
               else
                  R = R0
               end
               NLiveRegs = Arity + 1
            else
               R = R0
               NLiveRegs = Arity
            end
         else
            R = R0
            NLiveRegs = Arity
         end
         Emitter, DebugEntry(Coord 'call')
         Emitter, Emit(Instr)
         Emitter, DebugExit(Coord 'call')
      end
      meth SetArguments(TheArity ArgInits Regs)
         %%
         %% Regs is the list of argument registers to a call instruction.
         %% This method issues move instructions that place these registers
         %% into x(0), ..., x(Arity - 1).
         %%
         %% Each Reg is one of the following sources:
         %% 1) a nonallocated temporary register with delayed initialization
         %%    => write a putConstant/getSelf into DelayedInitsDict
         %% 2) a nonallocated temporary register without delayed initialization
         %%    => write a createVariable instruction into DelayedInitsDict
         %% 3) a nonallocated permanent register without delayed initialization
         %%    => write a createVariableMove instruction into DelayedInitsDict
         %% 4) an allocated temporary register
         %%    => add an edge I->J to the graph represented by AdjDict,
         %%       where I is the source X register index and J the
         %%       destination X register index.
         %% 5) an allocated permanent register
         %%    => write a move instruction into DelayedInitsDict
         %%
         %% The resulting graph is sorted via a depth-first search
         %% and corresponding moves are emitted (for each cycle).
         %%
         Emitter, EnterDelayedInits(ArgInits)
         Arity <- TheArity
         {List.forAllTailInd Regs
          proc {$ Position Reg|Regr} I = Position - 1 in
             if {Dictionary.member @DelayedInitsDict I} then
                if Reg >= 0 then
                   {BitArray.set @LastAliveRS Reg}
                end
             else
                case {Dictionary.condGet @Temporaries Reg none}
                of vEquateConstant(_ Constant _ _) then   % 1)
                   {Dictionary.remove @Temporaries Reg}
                   {Dictionary.remove @Permanents Reg}
                   {Dictionary.put @DelayedInitsDict I
                    putConstant(Constant x(I))}
                [] vGetSelf(_ _ _) then   % 1)
                   {Dictionary.remove @Temporaries Reg}
                   {Dictionary.remove @Permanents Reg}
                   {Dictionary.put @DelayedInitsDict I
                    getSelf(x(I))}
                else X Instr in
                   Emitter, GetTemp(Reg ?X)
                   if X == x(I) then
                      %% Optimize the special case that the register
                      %% already is located in its destination.
                      'skip'
                   else
                      case Emitter, GetPerm(Reg $) of none then
                         case X of none then
                            {BitArray.set @LastAliveRS Reg}
                            if {Member Reg Regr} then NewX in
                               %% special handling for nonlinearities
                               Emitter, Emit(createVariable(NewX))
                               if Emitter, IsLast(Reg $) then skip
                               else Y in
                                  Emitter, AllocatePerm(Reg ?Y)
                                  Emitter, Emit(move(NewX Y))
                               end
                               if {Dictionary.member @UsedX I} then J in
                                  Emitter, AllocateAnyTemp(Reg ?NewX)
                                  NewX = x(J)
                                  {Dictionary.put @AdjDict J
                                   I|{Dictionary.condGet @AdjDict J nil}}
                                  move(NewX x(I))
                               else
                                  Emitter, AllocateThisTemp(I Reg ?NewX)
                                  {Dictionary.put @AdjDict I
                                   I|{Dictionary.condGet @AdjDict I nil}}
                                  'skip'
                               end
                            elseif Emitter, IsLast(Reg $) then   % 2)
                               createVariable(x(I))
                            else   % 3)
                               delayedCreateVariableMove(Reg x(I))
                            end
                         [] x(J) then   % 4)
                            {Dictionary.put @AdjDict J
                             I|{Dictionary.condGet @AdjDict J nil}}
                            move(X x(I))
                         end
                      elseof YG then   % 5)
                         move(YG x(I))
                      end
                   end = Instr
                   {Dictionary.put @DelayedInitsDict I Instr}
                end
             end
          end}
         %%
         %% Perform the depth-first search of the graph:
         %%
         CurrentID <- 0
         Stack <- nil
         {For 0 @Arity - 1 1
          proc {$ I}
             if {Dictionary.member @DoneDict I} then skip
             else Emitter, OrderMoves(I _)
             end
          end}
         Emitter, KillAllTemporaries()
         %--** here we should let unused registers die
         {For 0 @Arity - 1 1
          proc {$ I}
             case {Dictionary.get @DelayedInitsDict I} of move(_ _) then skip
             [] 'skip' then skip
             [] delayedCreateVariableMove(Reg X) then Y in
                Emitter, AllocatePerm(Reg ?Y)
                Emitter, Emit(createVariableMove(Y X))
             elseof Instr then Emitter, Emit(Instr)
             end
          end}
         {Dictionary.removeAll @DelayedInitsDict}
         {Dictionary.removeAll @AdjDict}
         {Dictionary.removeAll @DoneDict}
      end
      meth EnterDelayedInits(ArgInits)
         case ArgInits of (I#Instr)|Rest then
            {Dictionary.put @DelayedInitsDict I Instr}
            Emitter, EnterDelayedInits(Rest)
         [] nil then skip
         end
      end
      meth OrderMoves(I ?MinID) ID = @CurrentID in
         {Dictionary.put @DoneDict I ID}
         CurrentID <- ID + 1
         Stack <- I|@Stack
         MinID = {FoldL {Dictionary.condGet @AdjDict I nil}
                  fun {$ MinID J}
                     {Min MinID
                      case {Dictionary.condGet @DoneDict J ~1} of ~1 then
                         Emitter, OrderMoves(J $)
                      elseof M then M
                      end}
                  end ID}
         if MinID == ID then
            case Emitter, GetCycle(@Stack I $) of [I] then Instr in
               Instr = {Dictionary.get @DelayedInitsDict I}
               case Instr of move(_ _) then
                  Emitter, Emit(Instr)
               else
                  %% we delay all others to allow for the highest possible
                  %% amount of moveMove peephole optimizations.
                  skip
               end
            elseof I1|Ir then I X In in
               Emitter, SpillTemporary(?I)
               X = x(I)
               Emitter, Emit(move(x(I1) X))
               In = {FoldL Ir
                     fun {$ J I} Emitter, Emit(move(x(I) x(J))) I end I1}
               Emitter, Emit(move(X x(In)))
            end
         end
      end
      meth GetCycle(Js I ?Cycle) J|Jr = Js in
         {Dictionary.put @DoneDict I @Arity}
         if J == I then
            Cycle = [I]
            Stack <- Jr
         else
            Cycle = J|Emitter, GetCycle(Jr I $)
         end
      end


      meth CreateNonlinearRegs(VArgs Regs $)
         case VArgs of VArg|VArgr then
            case VArg of value(Reg) then
               case Emitter, GetReg(Reg $) of none then
                  if {Member Reg Regs} then R in
                     Emitter, PredictReg(Reg ?R)
                     Emitter, Emit(createVariable(R))
                     Emitter, CreateNonlinearRegs(VArgr Regs $)
                  else
                     Emitter, CreateNonlinearRegs(VArgr Reg|Regs $)
                  end
               else
                  Emitter, CreateNonlinearRegs(VArgr Reg|Regs $)
               end
            [] record(_ _ VArgs) then Regs2 in
               Emitter, CreateNonlinearRegs(VArgs Regs ?Regs2)
               Emitter, CreateNonlinearRegs(VArgr Regs2 $)
            else
               Emitter, CreateNonlinearRegs(VArgr Regs $)
            end
         [] nil then Regs
         end
      end
      meth EmitRecordWrite(Literal RecordArity R VArgs) IHd ITl in
         %% Emit in write mode, i.e., bottom-up and using `set':
         Emitter, EmitVArgsWrite(VArgs IHd ITl)
         Emitter, Emit(putRecord(Literal RecordArity R))
         Emitter, EmitMultiple(IHd ITl)
      end
      meth EmitVArgsWrite(VArgs IHd ITl)
         case VArgs of VArg|VArgr then IInter in
            case VArg of constant(Constant) then
               IHd = setConstant(Constant)|IInter
            [] predicateRef(PredicateRef) then
               IHd = setPredicateRef(PredicateRef)|IInter
            [] value(Reg) then
               case Emitter, GetReg(Reg $) of none then
                  if Emitter, IsLast(Reg $) then
                     IHd = setVoid(1)|IInter
                  else R in
                     Emitter, PredictReg(Reg ?R)
                     IHd = setVariable(R)|IInter
                  end
               elseof R then
                  IHd = setValue(R)|IInter
               end
            [] record(Literal RecordArity VArgs) then R in
               Emitter, AllocateShortLivedTemp(?R)
               Emitter, EmitRecordWrite(Literal RecordArity R VArgs)
               IHd = setValue(R)|IInter
            end
            Emitter, EmitVArgsWrite(VArgr IInter ITl)
         [] nil then
            IHd = ITl
         end
      end
      meth EmitRecordRead(Literal RecordArity R VArgs) SubRecords in
         %% Emit in read mode, i.e., top-down and using `unify':
         Emitter, Emit(getRecord(Literal RecordArity R))
         Emitter, EmitVArgsRead(VArgs ?SubRecords nil)
         {ForAll SubRecords
          proc {$ R#record(Literal RecordArity VArgs)}
             Emitter, EmitRecordRead(Literal RecordArity R VArgs)
          end}
      end
      meth EmitVArgsRead(VArgs SHd STl)
         case VArgs of VArg|VArgr then SInter in
            case VArg of constant(Constant) then
               SHd = SInter
               if {IsNumber Constant} then
                  Emitter, Emit(unifyNumber(Constant))
               elseif {IsLiteral Constant} then
                  Emitter, Emit(unifyLiteral(Constant))
               else X in
                  Emitter, AllocateShortLivedTemp(?X)
                  Emitter, Emit(putConstant(Constant X))
                  Emitter, Emit(unifyValue(X))
               end
            [] value(Reg) then
               SHd = SInter
               case Emitter, GetReg(Reg $) of none then
                  if Emitter, IsLast(Reg $) then
                     Emitter, Emit(unifyVoid(1))
                  else R in
                     Emitter, PredictReg(Reg ?R)
                     Emitter, Emit(unifyVariable(R))
                  end
               elseof R then
                  Emitter, Emit(unifyValue(R))
               end
            [] record(_ _ _) then R in
               Emitter, AllocateShortLivedTemp(?R)
               Emitter, Emit(unifyVariable(R))
               SHd = R#VArg|SInter
            end
            Emitter, EmitVArgsRead(VArgr SInter STl)
         [] nil then
            SHd = STl
         end
      end
      meth AllocateBuiltinArgs(Regs IMods ?XsIn ?XsOut ?Unifies)
         case IMods#Regs of (IMod|IModr)#(Reg|Regr) then X Xr in
            XsIn = X|Xr
            if IMod then
               Emitter, AllocateShortLivedTemp(?X)
               case Emitter, GetReg(Reg $) of none then R in
                  Emitter, PredictReg(Reg ?R)
                  Emitter, Emit(createVariable(R))
                  Emitter, Emit(move(R X))
               elseof R then
                  Emitter, Emit(move(R X))
               end
            else
               Emitter, AllocateAndInitializeAnyTemp(Reg ?X)
            end
            Emitter, AllocateBuiltinArgs(Regr IModr ?Xr ?XsOut ?Unifies)
         [] nil#_ then
            XsIn = nil
            Emitter, AllocateBuiltinOutputs(Regs ?XsOut ?Unifies)
         end
      end
      meth AllocateBuiltinOutputs(Regs ?XsOut ?Unifies)
         case Regs of Reg|Regr then X Xr Ur in
            XsOut = X|Xr
            case Emitter, GetReg(Reg $) of none then
               %--** here it would be nicer to PredictBuiltinOutput
               Emitter, PredictTemp(Reg ?X)
               Unifies = Ur
            elseof R then
               Emitter, AllocateShortLivedTemp(?X)
               Unifies = X#R|Ur
            end
            Emitter, AllocateBuiltinOutputs(Regr ?Xr ?Ur)
         [] nil then
            XsOut = nil
            Unifies = nil
         end
      end
      meth EmitUnifies(Unifies)
         case Unifies of U|Ur then X#R = U in
            Emitter, Emit(unify(X R))
            Emitter, EmitUnifies(Ur)
         [] nil then skip
         end
      end
      meth EmitGuard(Addr)
         %% Ensure that no temporary dies in the guard:
         OldContinuations = @continuations
         OldContLabels
         Cont = vDummy(case Addr of nil then nil
                       else {BitArray.clone Addr.1}
                       end)
      in
         Emitter, PushContLabel(Cont ?OldContLabels)
         continuations <- Cont|OldContinuations
         Emitter, EmitAddr(Addr)
         continuations <- OldContinuations
         Emitter, PopContLabel(OldContLabels)
      end
      meth EmitDisjunction(Instr VClauses Cont Coord InitsRS ThisAddr)
         OldContLabels
      in
         Emitter, DoInits(InitsRS ThisAddr)
         Emitter, PushContLabel(Cont ?OldContLabels)
         Emitter, DebugEntry(Coord 'conditional')
         Emitter, Emit(Instr)
         Emitter, KillAllTemporaries()
         {FoldLTail VClauses
          proc {$ GuardLabel InitsRS0#Addr1#Addr2|Rest ?NextLabel} RegMap in
             Emitter, Emit(lbl(GuardLabel))
             case Rest of _|_ then
                Emitter, newLabel(?NextLabel)
                Emitter, Emit(nextClause(NextLabel))
             [] nil then
                Emitter, Emit(lastClause)
             end
             Emitter, Emit(clause)
             Emitter, DoInits(InitsRS0 nil)
             Emitter, EmitGuard(Addr1)
             Emitter, SaveRegisterMapping(?RegMap)
             Emitter, EmitAddr(Addr2)
             Emitter, RestoreRegisterMapping(RegMap)
          end Emitter, newLabel($) _}
         Emitter, PopContLabel(OldContLabels)
         Emitter, DebugExit(Coord 'conditional')
      end

      meth DoInits(InitsRS Cont) Regs in
         %% make all already initialized Registers occurring
         %% in the continuation permanent:
         Regs = case Cont of nil then
                   case @continuations of Cont1|_ then
                      {BitArray.toList Cont1.1}
                   [] nil then nil
                   end
                else {BitArray.toList Cont.1}
                end
         {ForAll Regs
          proc {$ Reg}
             case Emitter, GetPerm(Reg $) of none then
                case Emitter, GetTemp(Reg $) of none then skip
                elseof X then Y in
                   Emitter, AllocatePerm(Reg ?Y)
                   Emitter, Emit(move(X Y))
                end
             else skip
             end
          end}
         %% allocate all registers in the InitsRS set as permanents:
         case InitsRS of nil then skip
         else
            {ForAll {BitArray.toList InitsRS}
             proc {$ Reg}
                if Emitter, IsFirst(Reg $) then Y in
                   Emitter, AllocatePerm(Reg ?Y)
                   Emitter, Emit(createVariable(Y))
                end
             end}
         end
      end
      meth PrepareShared(Addr ?LocalEnv)
         case Addr of vShared(_ _ Count Addr2) then
            if {Access Count} > 1 then
               LocalEnv = false
               Emitter, DoInits(nil Addr)
            else
               Emitter, PrepareShared(Addr2 ?LocalEnv)
            end
         else
            LocalEnv = true
         end
      end
      meth PushContLabel(Cont ?OldContLabels)
         OldContLabels = @contLabels
         if Cont \= nil orelse self.debugInfoControlSwitch then
            contLabels <- Emitter, newLabel($)|OldContLabels
         end
      end
      meth PopContLabel(OldContLabels)
         if @contLabels == OldContLabels then skip
         else
            case @contLabels of ContLabel|_ then
               Emitter, Emit(lbl(ContLabel))
            end
         end
         contLabels <- OldContLabels
      end
      meth Dereference(Addr ?DeclLabel ?DestLabel)
         Emitter, newLabel(?DeclLabel)
         Emitter, DereferenceSub(Addr DeclLabel ?DestLabel)
      end
      meth DereferenceSub(Addr DeclLabel ?DestLabel)
         case Addr of nil then
            case @contLabels of ContLabel|_ then
               DestLabel = ContLabel
            [] nil then
               DestLabel = DeclLabel
            end
         [] vShared(_ Label2 _ Addr2) then
            if Addr2 == nil andthen @contLabels == nil then
               DestLabel = DeclLabel
            else
               Emitter, DereferenceSub(Addr2 Label2 ?DestLabel)
            end
         else
            DestLabel = DeclLabel
         end
      end
      meth DeallocateAndReturn()
         Emitter, Emit(deAllocateL(@LocalEnvSize))
         Emitter, Emit(return)
      end
      meth MayAllocateEnvLocally(Cont B $)
         if @LocalEnvsInhibited then false
         elseif self.debugInfoControlSwitch then false
         elseif B andthen Cont == nil andthen @contLabels == nil
            andthen @HighestEverY == ~1
         then
            %% This means that in a conditional, local environments may be
            %% allocated per branch instead of for the procedure as a whole.
            true
         else false
         end
      end
      meth EmitAddrInLocalEnv(Addr HasLocalEnv)
         %% A call to this method must always be followed by a call to
         %% either RestoreRegisterMapping or RestoreAllRegisterMappings;
         %% else the attributes Permanents, UsedY and LowestFreeY do not
         %% contain correct values.
         if HasLocalEnv then
            case Addr of vShared(_ _ _ _) then
               Emitter, EmitAddrInLocalEnvShared(Addr)
            else OldLocalEnvSize in
               OldLocalEnvSize = @LocalEnvSize
               LocalEnvSize <- _
               Emitter, Emit(allocateL(@LocalEnvSize))
               Emitter, EmitAddr(Addr)
               @LocalEnvSize = @HighestEverY + 1
               HighestEverY <- ~1
               LocalEnvSize <- OldLocalEnvSize
            end
         else OldLocalEnvsInhibited in
            OldLocalEnvsInhibited = @LocalEnvsInhibited
            LocalEnvsInhibited <- true
            Emitter, EmitAddr(Addr)
            LocalEnvsInhibited <- OldLocalEnvsInhibited
         end
      end
      meth EmitAddrInLocalEnvShared(Addr)
         case Addr of vShared(_ _ _ nil) then
               case @contLabels of nil then
                  Emitter, DeallocateAndReturn()
               [] ContLabel|_ then
                  Emitter, Emit(branch(ContLabel))
               end
         [] vShared(_ Label _ Addr2) then
            if {Dictionary.member @sharedDone Label} then
               Emitter, Emit(branch(Label))
            else
               {Dictionary.put @sharedDone Label true}
               Emitter, Emit(lbl(Label))
               Emitter, EmitAddrInLocalEnv(Addr2 true)
            end
         end
      end

      %%
      %% Mapping Regs to Real Machine Registers
      %%

      meth IsFirst(Reg $)
         Emitter, GetReg(Reg $) == none
      end
      meth IsLast(Reg $)
         if Reg < @minReg then false
         else
            case @continuations of Cont|_ then
               {Not {BitArray.test Cont.1 Reg}}
            else true
            end
         end
      end
      meth DoesNotOccurIn(Reg Cont $)
         if Reg < @minReg then false
         else
            case Cont of nil then true
            else {Not {BitArray.test Cont.1 Reg}}
            end
         end
      end

      meth EmitInitialization(VInstr R)
         case VInstr of vEquateConstant(_ Constant _ _) then
            Emitter, Emit(putConstant(Constant R))
         [] vGetSelf(_ _ _) then x(_) = R in
            Emitter, Emit(getSelf(R))
         end
      end

      meth GetReg(Reg ?R) Result in
         %% Return Reg's permanent, if it has one; else return Reg's temporary
         %% or 'none'.  If it has a delayed initialization, emit this, deciding
         %% from the continuation which register to allocate it to.
         Result = {Dictionary.condGet @Permanents Reg none}
         case Result of none then
            if Reg < @minReg then I in
               I = @HighestUsedG + 1
               HighestUsedG <- I
               {Dictionary.put @GRegRef I Reg}
               {Dictionary.put @Permanents Reg R=g(I)}
            else
               R = {Dictionary.condGet @Temporaries Reg none}
            end
         [] y(_) then R = Result
         [] g(_) then R = Result
         else
            {Dictionary.remove @Temporaries Reg}
            {Dictionary.remove @Permanents Reg}
            case Result of vGetSelf(_ _ _) then
               Emitter, PredictTemp(Reg ?R)
            else
               Emitter, PredictReg(Reg ?R)
            end
            Emitter, EmitInitialization(Result R)
         end
      end
      meth GetPerm(Reg ?YG) Result in
         %% Return Reg's permanent, if it has one, or 'none'.  If it has a
         %% delayed initialization that can have a permanent as destination,
         %% emit this, allocating a permanent for it.
         Result = {Dictionary.condGet @Permanents Reg none}
         case Result of none then
            if Reg < @minReg then I in
               I = @HighestUsedG + 1
               HighestUsedG <- I
               {Dictionary.put @GRegRef I Reg}
               {Dictionary.put @Permanents Reg YG=g(I)}
            else YG = none
            end
         [] y(_) then YG = Result
         [] g(_) then YG = Result
         elsecase Result of vGetSelf(_ _ _) then YG = none
         else
            {Dictionary.remove @Temporaries Reg}
            {Dictionary.remove @Permanents Reg}
            Emitter, AllocatePerm(Reg ?YG)
            Emitter, EmitInitialization(Result YG)
         end
      end
      meth GetTemp(Reg ?X) Result in
         %% Return Reg's temporary, if it has one, or 'none'.  If it has a
         %% delayed initialization, emit this, allocating a temporary for it.
         Result = {Dictionary.condGet @Temporaries Reg none}
         case Result of none then X = none
         [] x(_) then X = Result
         else
            {Dictionary.remove @Temporaries Reg}
            {Dictionary.remove @Permanents Reg}
            Emitter, PredictTemp(Reg ?X)
            Emitter, EmitInitialization(Result X)
         end
      end
      meth ReserveTemps(Index)
         %% All temporaries lower than Index are reserved; i.e., LowestFreeX
         %% and HighestEverX are set such that AllocateAnyTemp will not
         %% choose any conflicting index.  This is invoked when preparing
         %% calls.
         if @HighestEverX >= Index then
            if @LowestFreeX < Index then
               LowestFreeX <- {NextFreeIndex @UsedX Index}
            end
         else
            HighestEverX <- Index - 1
            LowestFreeX <- Index
         end
      end
      meth AllocateAnyTemp(Reg ?X)
         case Emitter, GetTemp(Reg $) of none then I in
            Emitter, SpillTemporary(?I)
            LowestFreeX <- {NextFreeIndex @UsedX I + 1}
            if I > @HighestEverX then
               HighestEverX <- I
            end
            {Dictionary.put @Temporaries Reg X=x(I)}
            {Dictionary.put @UsedX I 1}
         elseof X0 then X = X0
         end
      end
      meth SpillTemporary($) I in
         I = @LowestFreeX
         if I >= {Property.get 'limits.bytecode.xregisters'} then
            %--** which one should we take?
            {Exception.raiseError compiler(internal spillTemporary)} unit
         else I
         end
      end
      meth AllocateThisTemp(I Reg ?X)
         %% Precondition: X register index I is free
         if @LowestFreeX == I then
            LowestFreeX <- {NextFreeIndex @UsedX I + 1}
         end
         if I > @HighestEverX then
            HighestEverX <- I
         end
         {Dictionary.put @Temporaries Reg X=x(I)}
         {Dictionary.put @UsedX I 1}
      end
      meth AllocateShortLivedTemp(?X) I in
         Emitter, SpillTemporary(?I)
         Emitter, AllocateThisShortLivedTemp(I ?X)
      end
      meth AllocateThisShortLivedTemp(I ?X)
         %% Precondition: X register index I is free
         if @LowestFreeX == I then
            LowestFreeX <- {NextFreeIndex @UsedX I + 1}
         end
         if I > @HighestEverX then
            HighestEverX <- I
         end
         {Dictionary.put @UsedX I 1}
         X = x(I)
         ShortLivedTemps <- I|@ShortLivedTemps
      end
      meth AllocateAndInitializeAnyTemp(Reg ?X)
         case Emitter, GetTemp(Reg $) of none then
            Emitter, AllocateAnyTemp(Reg ?X)
            case Emitter, GetPerm(Reg $) of none then
               Emitter, Emit(createVariable(X))
            elseof YG then
               Emitter, Emit(move(YG X))
            end
         elseof X0 then X = X0
         end
      end
      meth AllocateUnnamedPerm(Reg ?Y)
         case Emitter, GetPerm(Reg $) of none then I in
            I = {NextFreeIndexWithEmptyPrintName @UsedY @LocalVarnames
                 @LowestFreeY}
            {Dictionary.put @LocalVarnames I ''}
            if I > @HighestEverY then
               HighestEverY <- I
            end
            {Dictionary.put @Permanents Reg Y=y(I)}
            {Dictionary.put @UsedY I 1}
         elseof Y0 then Y = Y0
         end
      end
      meth AllocatePerm(Reg ?Y)
         case Emitter, GetPerm(Reg $) of none then I in
            if self.debugInfoVarnamesSwitch then
               case {Dictionary.condGet @regNames Reg ''} of '' then
                  I = {NextFreeIndexWithEmptyPrintName @UsedY @LocalVarnames
                       @LowestFreeY}
                  {Dictionary.put @LocalVarnames I ''}
               elseof PrintName then
                  I = {NextFreeIndexWithoutPrintName @UsedY @LocalVarnames
                       @LowestFreeY}
                  {Dictionary.put @LocalVarnames I PrintName}
               end
               if I == @LowestFreeY then
                  LowestFreeY <- {NextFreeIndex @UsedY I + 1}
               end
            else
               I = @LowestFreeY
               LowestFreeY <- {NextFreeIndex @UsedY I + 1}
            end
            if I > @HighestEverY then
               HighestEverY <- I
            end
            {Dictionary.put @Permanents Reg Y=y(I)}
            {Dictionary.put @UsedY I 1}
         elseof Y0 then Y = Y0
         end
      end
      meth CopyTemp(X Reg) x(I) = X in
         {Dictionary.put @UsedX I {Dictionary.get @UsedX I} + 1}
         {Dictionary.put @Temporaries Reg X}
      end
      meth CopyPerm(YG Reg)
         case YG of y(I) then
            {Dictionary.put @UsedY I {Dictionary.get @UsedY I} + 1}
         [] g(_) then skip
         end
         {Dictionary.put @Permanents Reg YG}
      end
      meth FreeReg(Reg)
         case {Dictionary.condGet @Temporaries Reg none} of x(I) then
            Emitter, FreeX(I)
            {Dictionary.remove @Temporaries Reg}
         else skip
         end
         case {Dictionary.condGet @Permanents Reg none} of y(I) then
            Emitter, FreeY(I)
            {Dictionary.remove @Permanents Reg}
         else skip
         end
      end
      meth FreeX(I)
         case {Dictionary.condGet @UsedX I 0} of 0 then skip
         [] 1 then
            {Dictionary.remove @UsedX I}
            if I < @LowestFreeX then
               LowestFreeX <- I
            end
         elseof N then
            {Dictionary.put @UsedX I N - 1}
         end
      end
      meth FreeY(I)
         case {Dictionary.condGet @UsedY I 0} of 0 then skip
         [] 1 then
            {Dictionary.remove @UsedY I}
            if I < @LowestFreeY then
               LowestFreeY <- I
            end
         elseof N then
            {Dictionary.put @UsedY I N - 1}
         end
      end

      meth PredictBuiltinOutput(Reg ?X)
         %% Here we try to determine whether it would improve
         %% register allocation to reuse one of the argument
         %% registers as the result register, if possible.
         case @continuations of nil then
            Emitter, AllocateShortLivedTemp(?X)
         [] Cont|_ then
            Emitter, LetDie(Cont.1)
            %% This is needed so that LetDie works correctly:
            {BitArray.set Cont.1 Reg}
            Emitter, PredictTemp(Reg ?X)
         end
      end
      meth PredictTemp(Reg ?X)
         case @continuations of nil then
            Emitter, AllocateAnyTemp(Reg ?X)
         [] Cont|_ then
            case Emitter, PredictRegSub(Reg Cont $) of anyperm then
               %% This may be made permanent later.  But for now we
               %% absolutely need it in a temporary register anyway.
               Emitter, AllocateAnyTemp(Reg ?X)
            elseof X2 then
               X = X2
            end
         end
      end
      meth PredictReg(Reg ?R)
         case @continuations of nil then
            Emitter, AllocateAnyTemp(Reg ?R)
         [] Cont|_ then
            case Emitter, PredictRegSub(Reg Cont $) of anyperm then
               Emitter, AllocatePerm(Reg ?R)
            elseof X then
               R = X
            end
         end
      end
      meth PredictRegSub(Reg Cont ?R) VInstr = Cont in
         %% Precondition: Reg has not yet occurred
         case Cont of nil then
            Emitter, AllocateAnyTemp(Reg ?R)
         [] vMakePermanent(_ Regs Cont2) then
            if {Member Reg Regs} then R = anyperm
            else Emitter, PredictRegSub(Reg Cont2 ?R)
            end
         [] vEquateConstant(_ Constant MessageReg Cont2)
            andthen {IsLiteral Constant}
         then
            %% Check whether this will be optimized into a sendMsg instruction.
            case Cont2 of vCall(_ Reg0 [!MessageReg] _ Cont3) then
               Emitter, PredictRegForCall(Reg Reg0 nil Cont3 ?R)
            elseof vGenCall(_ Reg0 false _ _ [!MessageReg] _ Cont3) then
               Emitter, PredictRegForCall(Reg Reg0 nil Cont3 ?R)
            elseof vCallBuiltin(_ 'Object.new' [_ !MessageReg Reg0] _ Cont3) then
               Emitter, PredictRegForCall(Reg Reg0 nil Cont3 ?R)
            else
               Emitter, PredictRegSub(Reg Cont2 ?R)
            end
         [] vEquateRecord(_ _ _ MessageReg VArgs Cont2) then
            %% Check whether this will be optimized into a sendMsg instruction.
            case Cont2 of vCall(_ Reg0 [!MessageReg] _ Cont3) then
               Emitter, PredictRegForCall(Reg Reg0 VArgs Cont3 ?R)
            elseof vGenCall(_ Reg0 false _ _ [!MessageReg] _ Cont3) then
               Emitter, PredictRegForCall(Reg Reg0 VArgs Cont3 ?R)
            elseof vCallBuiltin(_ 'Object.new' [_ !MessageReg Reg0] _ Cont3) then
               Emitter, PredictRegForCall(Reg Reg0 VArgs Cont3 ?R)
            else
               Emitter, PredictRegSub(Reg Cont2 ?R)
            end
         [] vCallBuiltin(_ _ Regs _ Cont) then
            if {Member Reg Regs} then
               Emitter, AllocateAnyTemp(Reg ?R)
            else
               Emitter, PredictRegSub(Reg Cont ?R)
            end
         [] vGenCall(_ _ _ _ _ Regs _ Cont) then
            Emitter, PredictRegForCall(Reg ~1 Regs Cont ?R)
         [] vCall(_ Reg0 Regs _ Cont) then
            Emitter, PredictRegForCall(Reg Reg0 Regs Cont ?R)
         [] vFastCall(_ _ Regs _ Cont) then
            Emitter, PredictRegForCall(Reg ~1 Regs Cont ?R)
         [] vApplMeth(_ _ _ _ Regs _ Cont) then
            Emitter, PredictRegForCall(Reg ~1 Regs Cont ?R)
         [] vShared(_ _ _ _) then
            Emitter, AllocateAnyTemp(Reg ?R)
         [] vExHandler(_ Addr _ _ _ Cont InitsRS) then
            Emitter, PredictRegForInits(Reg InitsRS [Addr Cont] ?R)
         [] vCreateCond(_ _ _ _ _ _ _) then
            Emitter, PredictPermReg(Reg Cont ?R)
         [] vCreateOr(_ _ _ _ _ _) then
            Emitter, PredictPermReg(Reg Cont ?R)
         [] vCreateEnumOr(_ _ _ _ _ _) then
            Emitter, PredictPermReg(Reg Cont ?R)
         [] vCreateChoice(_ _ _ _ _ _) then
            Emitter, PredictPermReg(Reg Cont ?R)
         [] vAsk(_ Cont) then
            Emitter, PredictPermReg(Reg Cont ?R)
         [] vWait(_ Cont) then
            Emitter, PredictPermReg(Reg Cont ?R)
         [] vWaitTop(_ Cont) then
            Emitter, PredictPermReg(Reg Cont ?R)
         [] vTestBool(_ _ Addr1 Addr2 Addr3 _ Cont InitsRS) then Addrs in
            Addrs = [Addr1 Addr2 Addr3 Cont]
            Emitter, PredictRegForInits(Reg InitsRS Addrs ?R)
         [] vTestBuiltin(_ _ Regs Addr1 Addr2 Cont InitsRS) then
            if {Member Reg Regs} then
               Emitter, AllocateAnyTemp(Reg ?R)
            else Addrs in
               Addrs = [Addr1 Addr2 Cont]
               Emitter, PredictRegForInits(Reg InitsRS Addrs ?R)
            end
         [] vTestConstant(_ _ _ Addr1 Addr2 _ Cont InitsRS) then Addrs in
            Addrs = [Addr1 Addr2 Cont]
            Emitter, PredictRegForInits(Reg InitsRS Addrs ?R)
         [] vMatch(_ _ Addr VHashTableEntries _ Cont InitsRS) then
            Addrs = {FoldR VHashTableEntries
                     fun {$ VHashTableEntry In}
                        case VHashTableEntry of onScalar(_ Addr) then Addr|In
                        [] onRecord(_ _ Addr) then Addr|In
                        end
                     end [Addr Cont]}
         in
            Emitter, PredictRegForInits(Reg InitsRS Addrs ?R)
         [] vThread(_ _ _ Cont InitsRS) then
            Emitter, PredictRegForInits(Reg InitsRS [Cont] ?R)
         [] vLockThread(_ Reg0 _ Cont _) then
            if Reg == Reg0 then
               Emitter, AllocateAnyTemp(Reg ?R)
            else
               Emitter, PredictRegSub(Reg Cont ?R)
            end
         [] vLockEnd(_ _ Cont _) then
            Emitter, PredictPermReg(Reg Cont ?R)
         [] vDummy(_) then
            Emitter, AllocateAnyTemp(Reg ?R)
         else NewCont in
            NewCont = VInstr.(Continuations.{Label VInstr})
            Emitter, PredictRegSub(Reg NewCont ?R)
         end
      end
      meth PredictArgReg(Reg Regs I Cont ?R)
         case Regs of RegI|RegRest then
            if RegI == Reg orelse RegI == value(Reg) then
               if {Dictionary.member @UsedX I} then
                  Emitter, PredictArgReg(Reg RegRest I + 1 Cont ?R)
               else
                  Emitter, AllocateThisTemp(I Reg ?R)
               end
            else
               Emitter, PredictArgReg(Reg RegRest I + 1 Cont ?R)
            end
         [] nil then
            if Cont \= nil andthen {BitArray.test Cont.1 Reg} then
               R = anyperm
            else J in
               J = {NextFreeIndex @UsedX I}
               Emitter, AllocateThisTemp(J Reg ?R)
            end
         end
      end
      meth PredictRegForCall(Reg Reg0 Regs Cont ?R)
         if Cont \= nil andthen {BitArray.test Cont.1 Reg} then
            R = anyperm
         elseif Reg == Reg0 then I in
            I = {NextFreeIndex @UsedX {Length Regs}}
            Emitter, AllocateThisTemp(I Reg ?R)
         else
            Emitter, PredictArgReg(Reg Regs 0 Cont ?R)
         end
      end
      meth PredictRegForInits(Reg InitsRS Addrs ?R)
         if {BitArray.test InitsRS Reg} then
            R = anyperm
         else
            Emitter, PredictRegForBranches(Addrs Reg ?R)
         end
      end
      meth PredictRegForBranches(Addrs Reg ?R)
         case Addrs of Addr1|Addrr then
            if Addr1 \= nil andthen {BitArray.test Addr1.1 Reg} then
               Emitter, PredictRegSub(Reg Addr1 ?R)
            else
               Emitter, PredictRegForBranches(Addrr Reg ?R)
            end
         [] nil then
            Emitter, AllocateAnyTemp(Reg ?R)
         end
      end
      meth PredictPermReg(Reg Cont ?R)
         if Cont \= nil andthen {BitArray.test Cont.1 Reg} then
            R = anyperm
         else
            Emitter, AllocateAnyTemp(Reg ?R)
         end
      end

      meth SaveRegisterMapping($)
         Emitter, FlushShortLivedTemps()
         {Dictionary.clone @Permanents}#{Dictionary.clone @UsedY}#@LowestFreeY#
         {BitArray.clone @LastAliveRS}#@HighestUsedG
      end
      meth RestoreRegisterMapping(RegisterMapping)
         OldPermanents#OldUsedY#OldLowestFreeY#
         OldLastAliveRS#OldHighestUsedG = RegisterMapping
      in
         LastAliveRS <- OldLastAliveRS
         Permanents <- OldPermanents
         {For OldHighestUsedG + 1 @HighestUsedG 1
          proc {$ I}
             {Dictionary.put @Permanents {Dictionary.get @GRegRef I} g(I)}
          end}
         UsedY <- OldUsedY
         LowestFreeY <- OldLowestFreeY
         Emitter, KillAllTemporaries()
      end
      meth SaveAllRegisterMappings($)
         Emitter, FlushShortLivedTemps()
         {Dictionary.clone @Temporaries}#{Dictionary.clone @UsedX}#
         {Dictionary.clone @Permanents}#{Dictionary.clone @UsedY}#
         @LowestFreeX#@LowestFreeY#{BitArray.clone @LastAliveRS}#@HighestUsedG
      end
      meth RestoreAllRegisterMappings(RegisterMapping)
         OldTemporaries#OldUsedX#OldPermanents#OldUsedY#
         OldLowestFreeX#OldLowestFreeY#OldLastAliveRS#OldHighestUsedG
         = RegisterMapping
      in
         LastAliveRS <- OldLastAliveRS
         {Dictionary.removeAll @Temporaries}
         Temporaries <- OldTemporaries
         {Dictionary.removeAll @UsedX}
         UsedX <- OldUsedX
         {Dictionary.removeAll @Permanents}
         Permanents <- OldPermanents
         {For OldHighestUsedG + 1 @HighestUsedG 1
          proc {$ I}
             {Dictionary.put @Permanents {Dictionary.get @GRegRef I} g(I)}
          end}
         {Dictionary.removeAll @UsedY}
         UsedY <- OldUsedY
         LowestFreeX <- OldLowestFreeX
         LowestFreeY <- OldLowestFreeY
         ShortLivedTemps <- nil
      end
      meth KillAllTemporaries() D = @Temporaries in
         {ForAll {Dictionary.keys D}
          proc {$ Reg}
             case {Dictionary.get D Reg} of x(_) then {Dictionary.remove D Reg}
             else skip   % do not forget delayed initializations
             end
          end}
         {Dictionary.removeAll @UsedX}
         LowestFreeX <- 0
         ShortLivedTemps <- nil
      end

      %%
      %% Emitting Instructions
      %%

      meth Emit(Instr) NewCodeTl in
\ifdef DEBUG_EMIT
         {System.show Instr}
\endif
         @CodeTl = Instr|NewCodeTl
         CodeTl <- NewCodeTl
      end
      meth EmitMultiple(Instrs NewCodeTl)
\ifdef DEBUG_EMIT
         proc {ShowAll Instrs}
            if {IsDet Instrs} then I|Ir = Instrs in
               {System.show I}
               {ShowAll Ir}
            end
         end
      in
         {ShowAll Instrs}
\endif
         @CodeTl = Instrs
         CodeTl <- NewCodeTl
      end
   end
end
