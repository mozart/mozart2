%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997-2001
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
import
   CodeEmitter('class': Emitter continuations: Continuations)
export
   'class': CodeStore
define
   class CodeStore from Emitter
      prop final
      attr
         regNames: unit   % mapping Reg -> PrintName
         NextReg: unit
         minReg: unit     % smallest Reg index local to current definition
         NextYIndex: unit
         Saved: unit      % saved minReg/NextYIndex from enclosing definitions
         nextLabel: unit
         sharedDone: unit
         EmptyRS: unit
      feat
         controlFlowInfoSwitch staticVarnamesSwitch dynamicVarnamesSwitch
         state reporter
      meth init(State Reporter)
         Emitter, init()
         regNames <- {NewDictionary}
         NextReg <- 0
         Saved <- nil
         nextLabel <- 1
         sharedDone <- {NewDictionary}
         self.controlFlowInfoSwitch = {State getSwitch(controlflowinfo $)}
         self.staticVarnamesSwitch = {State getSwitch(staticvarnames $)}
         self.dynamicVarnamesSwitch = {State getSwitch(dynamicvarnames $)}
         self.state = State
         self.reporter = Reporter
      end

      meth makeRegSet($)
         L = @minReg
         H = @NextReg - 1
      in
         if L =< H then
            {BitArray.new L H}
         else
            {BitArray.new L L}
         end
      end
      meth enterVs(Vs RS)
         case Vs of V|Vr then Reg in
            {V reg(?Reg)}
            if Reg >= @minReg then {BitArray.set RS Reg} end
            CodeStore, enterVs(Vr RS)
         [] nil then skip
         end
      end

      meth startDefinition()
         Saved <- @minReg#@NextYIndex|@Saved
         minReg <- @NextReg
         NextYIndex <- 0
      end
      meth newReg(?Reg)
         Reg = @NextReg
         NextReg <- Reg + 1
         {Dictionary.remove @regNames Reg}
      end
      meth newSelfReg(?Reg)
         Reg = @NextReg
         NextReg <- Reg + 1
         {Dictionary.put @regNames Reg 'self'}
      end
      meth newVariableReg(V ?Reg)
         Reg = @NextReg
         NextReg <- Reg + 1
         case {V getPrintName($)} of unit then
            {Dictionary.remove @regNames Reg}
         elseof PrintName then
            {Dictionary.put @regNames Reg PrintName}
         end
      end
      meth nextYIndex(?Index)
         Index = @NextYIndex
         NextYIndex <- Index + 1
      end
      meth endDefinition(StartAddr0 FormalRegs AllRegs ?GRegs ?Code ?NLiveRegs)
         StartAddr N
      in
         EmptyRS <- CodeStore, makeRegSet($)
         CodeStore, Deref(StartAddr0 ?StartAddr)
         {Dictionary.removeAll @sharedDone}
         CodeStore, ComputeOccs(StartAddr _)
         CodeStore, AddRegOccs(StartAddr @EmptyRS)
         {Dictionary.removeAll @sharedDone}
         N = if self.staticVarnamesSwitch then @NextYIndex else 0 end
         Emitter, doEmit(FormalRegs AllRegs StartAddr N
                         ?Code ?GRegs ?NLiveRegs)
         {Dictionary.removeAll @sharedDone}
         %% restore enclosing definition's state:
         NextReg <- @minReg
         case @Saved of OldMinReg#OldNextYIndex|SavedRest then
            minReg <- OldMinReg
            NextYIndex <- OldNextYIndex
            Saved <- SavedRest
         end
      end
      meth getRegNames(GRegs ?GPNs)
         GPNs = {Map GRegs fun {$ Reg} {Dictionary.get @regNames Reg} end}
      end

      meth Deref(Addr $)
         case Addr of nil then nil
         [] vShared(OccsRS InitsRS Label Addr) then
            if {Dictionary.member @sharedDone Label} then
               {Dictionary.get @sharedDone Label}
            else NewVShared in
               {Dictionary.put @sharedDone Label NewVShared}
               NewVShared = case Addr of nil then nil
                            [] vShared(_ _ _ _) then CodeStore, Deref(Addr $)
                            else
                               vShared(OccsRS InitsRS Label
                                       CodeStore, Deref(Addr $))
                            end
               NewVShared
            end
         [] vExHandler(OccsRS Addr1 Reg Addr2 Coord Cont InitsRS) then
            vExHandler(OccsRS CodeStore, Deref(Addr1 $) Reg
                       CodeStore, Deref(Addr2 $) Coord CodeStore, Share(Cont $)
                       InitsRS)
         [] vTestBool(OccsRS Reg Addr1 Addr2 Addr3 Coord Cont) then
            vTestBool(OccsRS Reg CodeStore, Deref(Addr1 $)
                      CodeStore, Deref(Addr2 $) CodeStore, Deref(Addr3 $)
                      Coord CodeStore, Share(Cont $))
         [] vTestConstant(OccsRS Reg NumOrLit Addr1 Addr2 Coord Cont) then
            vTestConstant(OccsRS Reg NumOrLit CodeStore, Deref(Addr1 $)
                          CodeStore, Deref(Addr2 $) Coord
                          CodeStore, Share(Cont $))
         [] vMatch(OccsRS Reg Addr VHashTableEntries Coord Cont) then
            vMatch(OccsRS Reg CodeStore, Deref(Addr $)
                   {Map VHashTableEntries
                    fun {$ VHashTableEntry}
                       case VHashTableEntry of onScalar(NumOrLit Addr) then
                          onScalar(NumOrLit CodeStore, Deref(Addr $))
                       [] onRecord(Atomname RecordArity Addr) then
                          onRecord(Atomname RecordArity
                                   CodeStore, Deref(Addr $))
                       end
                    end} Coord CodeStore, Share(Cont $))
         else I in
            I = Continuations.{Label Addr}
            {AdjoinAt Addr I CodeStore, Deref(Addr.I $)}
         end
      end
      meth Share(Cont $)
         case Cont of vShared(_ _ _ _) then CodeStore, Deref(Cont $)
         [] nil then nil
         else Label in
            CodeStore, newLabel(?Label)
            vShared(_ _ Label CodeStore, Deref(Cont $))
         end
      end

      meth GetOccs(Addr ?RS)
         RS = case Addr of nil then @EmptyRS else Addr.1 end
      end
      meth ComputeOccs(Addr ?RS)
         case Addr of nil then
            RS = @EmptyRS
         [] vShared(RS0 _ _ Addr1) then
            if {IsFree RS0} then
               RS0 = {BitArray.clone CodeStore, ComputeOccs(Addr1 $)}
            end
            RS = RS0
         elseof VInstr then
            RS = VInstr.1
            case VInstr.(Continuations.{Label VInstr}) of nil then
               CodeStore, makeRegSet(?RS)
            elseof Cont then
               RS = {BitArray.clone CodeStore, ComputeOccs(Cont $)}
            end
            case VInstr of vDebugEntry(_ _ _ _) then skip
            [] vDebugExit(_ _ _ _) then skip
            [] vMakePermanent(_ RegIndices _) then
               {ForAll RegIndices
                proc {$ Reg#_#_}
                   CodeStore, RegOcc(Reg RS)
                end}
            [] vClear(_ Regs _) then
               CodeStore, RegOccs(Regs RS)
            [] vUnify(_ Reg1 Reg2 _) then
               CodeStore, RegOcc(Reg1 RS)
               CodeStore, RegOcc(Reg2 RS)
            [] vEquateConstant(_ _ Reg _) then
               CodeStore, RegOcc(Reg RS)
            [] vEquateRecord(_ _ _ Reg VArgs _) then
               CodeStore, RegOcc(Reg RS)
               CodeStore, RegOccVArgs(VArgs RS)
            [] vGetVariable(_ Reg _) then
               CodeStore, RegOcc(Reg RS)
            [] vCallBuiltin(_ _ Regs _ _) then
               CodeStore, RegOccs(Regs RS)
            [] vCallGlobal(_ Reg Regs _ _) then
               CodeStore, RegOcc(Reg RS)
               CodeStore, RegOccs(Regs RS)
            [] vCallMethod(_ Reg _ _ Regs _ _) then
               CodeStore, RegOcc(Reg RS)
               CodeStore, RegOccs(Regs RS)
            [] vCall(_ Reg Regs _ _) then
               CodeStore, RegOcc(Reg RS)
               CodeStore, RegOccs(Regs RS)
            [] vConsCall(_ Reg Regs _ _) then
               CodeStore, RegOcc(Reg RS)
               CodeStore, RegOccs(Regs RS)
            [] vDeconsCall(_ Reg1 Reg2 Reg3 _ _) then
               CodeStore, RegOcc(Reg1 RS)
               CodeStore, RegOcc(Reg2 RS)
               CodeStore, RegOcc(Reg3 RS)
            [] vCallProcedureRef(_ _ Regs _ _) then
               CodeStore, RegOccs(Regs RS)
            [] vCallConstant(_ _ Regs _ _) then
               CodeStore, RegOccs(Regs RS)
            [] vInlineDot(_ Reg1 _ Reg2 _ _ _) then
               CodeStore, RegOcc(Reg1 RS)
               CodeStore, RegOcc(Reg2 RS)
            [] vInlineAt(_ _ Reg _) then
               CodeStore, RegOcc(Reg RS)
            [] vInlineAssign(_ _ Reg _) then
               CodeStore, RegOcc(Reg RS)
            [] vGetSelf(_ Reg _) then
               CodeStore, RegOcc(Reg RS)
            [] vSetSelf(_ Reg _) then
               CodeStore, RegOcc(Reg RS)
            [] vDefinition(_ Reg _ _ GRegs _ _) then
               CodeStore, RegOcc(Reg RS)
               CodeStore, RegOccs(GRegs RS)
            [] vDefinitionCopy(_ Reg1 Reg2 _ _ GRegs _ _) then
               CodeStore, RegOcc(Reg1 RS)
               CodeStore, RegOcc(Reg2 RS)
               CodeStore, RegOccs(GRegs RS)
            [] vExHandler(_ Addr1 Reg Addr2 _ Cont InitsRS) then RS1 RS2 TempRS in
               CodeStore, ComputeOccs(Addr1 ?RS1)
               CodeStore, ComputeOccs(Addr2 ?RS2)
               CodeStore, RegOcc(Reg RS2)
               InitsRS = {BitArray.clone RS1}
               {BitArray.disj InitsRS RS2}
               {BitArray.conj InitsRS RS}
               TempRS = {BitArray.clone RS1}
               {BitArray.conj TempRS RS2}
               {BitArray.disj InitsRS TempRS}
               {BitArray.disj RS RS1}
               {BitArray.disj RS RS2}
               case Cont of vShared(_ InitsRS _ _) then
                  InitsRS = {BitArray.clone RS1}
                  {BitArray.disj InitsRS RS2}
               [] nil then skip
               end
            [] vPopEx(_ _ _) then
               skip
            [] vTestBool(_ Reg Addr1 Addr2 Addr3 _ Cont) then RS1 RS2 RS3 in
               CodeStore, ComputeOccs(Addr1 ?RS1)
               CodeStore, ComputeOccs(Addr2 ?RS2)
               CodeStore, ComputeOccs(Addr3 ?RS3)
               case Cont of vShared(_ InitsRS _ _) then
                  InitsRS = {BitArray.clone RS1}
                  {BitArray.disj InitsRS RS2}
                  {BitArray.disj InitsRS RS3}
               [] nil then skip
               end
               CodeStore, RegOcc(Reg RS)
               {BitArray.disj RS RS1}
               {BitArray.disj RS RS2}
               {BitArray.disj RS RS3}
            [] vTestConstant(_ Reg _ Addr1 Addr2 _ Cont) then RS1 RS2 in
               CodeStore, ComputeOccs(Addr1 ?RS1)
               CodeStore, ComputeOccs(Addr2 ?RS2)
               case Cont of vShared(_ InitsRS _ _) then
                  InitsRS = {BitArray.clone RS1}
                  {BitArray.disj InitsRS RS2}
               [] nil then skip
               end
               CodeStore, RegOcc(Reg RS)
               {BitArray.disj RS RS1}
               {BitArray.disj RS RS2}
            [] vMatch(_ Reg Addr VHashTableEntries _ Cont) then RS0 InitsRS in
               CodeStore, ComputeOccs(Addr ?RS0)
               InitsRS = {BitArray.clone RS0}
               {ForAll VHashTableEntries
                proc {$ VHashTableEntry} Addr in
                   case VHashTableEntry of onScalar(_ A) then Addr = A
                   [] onRecord(_ _ A) then Addr = A
                   end
                   {BitArray.disj InitsRS CodeStore, ComputeOccs(Addr $)}
                end}
               case Cont of vShared(_ InitsRS0 _ _) then
                  InitsRS0 = InitsRS
               [] nil then skip
               end
               CodeStore, RegOcc(Reg RS)
               {BitArray.disj RS RS0}
               {ForAll VHashTableEntries
                proc {$ VHashTableEntry} Addr in
                   case VHashTableEntry of onScalar(_ A) then Addr = A
                   [] onRecord(_ _ A) then Addr = A
                   end
                   {BitArray.disj RS CodeStore, GetOccs(Addr $)}
                end}
            [] vLockThread(_ Reg _ _ _) then
               CodeStore, RegOcc(Reg RS)
            [] vLockEnd(_ _ _ _) then
               skip
            end
         end
      end
      meth RegOcc(Reg RS)
         if Reg < @minReg then skip   % it's a global
         else {BitArray.set RS Reg}
         end
      end
      meth RegOccs(Regs RS)
         case Regs of Reg|Regr then
            if Reg < @minReg then skip   % it's a global
            else {BitArray.set RS Reg}
            end
            CodeStore, RegOccs(Regr RS)
         [] nil then skip
         end
      end
      meth RegOccVArgs(VArgs RS)
         case VArgs of VArg|VArgr then
            case VArg of value(Reg) then CodeStore, RegOcc(Reg RS)
            [] record(_ _ VArgs) then CodeStore, RegOccVArgs(VArgs RS)
            else skip
            end
            CodeStore, RegOccVArgs(VArgr RS)
         [] nil then skip
         end
      end

      meth AddRegOccs(Addr AddRS)
         case Addr of nil then skip
         else VInstr AddRS2 in
            {BitArray.disj Addr.1 AddRS}
            VInstr = Addr
            case Continuations.{Label VInstr} of ~1 then
               AddRS2 = AddRS
            elseof I then
               case VInstr.I of nil then
                  AddRS2 = AddRS
               elseof Cont then
                  CodeStore, AddRegOccs(Cont AddRS)
                  CodeStore, GetOccs(Cont ?AddRS2)
               end
            end
            case VInstr of vDebugEntry(_ _ _ _) then skip
            [] vDebugExit(_ _ _ _) then skip
            [] vMakePermanent(_ _ _) then skip
            [] vClear(_ _ _) then skip
            [] vUnify(_ _ _ _) then skip
            [] vEquateConstant(_ _ _ _) then skip
            [] vEquateRecord(_ _ _ _ _ _) then skip
            [] vGetVariable(_ _ _) then skip
            [] vCallBuiltin(_ _ _ _ _) then skip
            [] vCallGlobal(_ _ _ _ _) then skip
            [] vCallMethod(_ _ _ _ _ _ _) then skip
            [] vCall(_ _ _ _ _) then skip
            [] vConsCall(_ _ _ _ _) then skip
            [] vDeconsCall(_ _ _ _ _ _) then skip
            [] vCallProcedureRef(_ _ _ _ _) then skip
            [] vCallConstant(_ _ _ _ _) then skip
            [] vInlineDot(_ _ _ _ _ _ _) then skip
            [] vInlineAt(_ _ _ _) then skip
            [] vInlineAssign(_ _ _ _) then skip
            [] vGetSelf(_ _ _) then skip
            [] vSetSelf(_ _ _) then skip
            [] vDefinition(_ _ _ _ _ _ _) then skip
            [] vDefinitionCopy(_ _ _ _ _ _ _ _) then skip
            [] vShared(_ _ Label Addr) then
               if {Dictionary.member @sharedDone Label} then skip
               else
                  {Dictionary.put @sharedDone Label true}
                  CodeStore, AddRegOccs(Addr AddRS2)
               end
            [] vExHandler(_ Addr1 _ Addr2 _ _ _) then AddRS3 in
               AddRS3 = {BitArray.clone AddRS2}
               {BitArray.disj AddRS3 CodeStore, GetOccs(Addr2 $)}
               CodeStore, AddRegOccs(Addr1 AddRS3)
               CodeStore, AddRegOccs(Addr2 AddRS2)
            [] vPopEx(_ _ _) then skip
            [] vTestBool(_ _ Addr1 Addr2 Addr3 _ Cont) then
               CodeStore, AddRegOccs(Addr1 AddRS2)
               CodeStore, AddRegOccs(Addr2 AddRS2)
               CodeStore, AddRegOccs(Addr3 AddRS2)
               case Cont of vShared(_ InitsRS _ _) then
                  {BitArray.conj InitsRS AddRS2}
               [] nil then skip
               end
            [] vTestConstant(_ _ _ Addr1 Addr2 _ Cont) then
               CodeStore, AddRegOccs(Addr1 AddRS2)
               CodeStore, AddRegOccs(Addr2 AddRS2)
               case Cont of vShared(_ InitsRS _ _) then
                  {BitArray.conj InitsRS AddRS2}
               [] nil then skip
               end
            [] vMatch(_ _ Addr VHashTableEntries _ Cont) then
               CodeStore, AddRegOccs(Addr AddRS2)
               {ForAll VHashTableEntries
                proc {$ VHashTableEntry} Addr in
                   case VHashTableEntry of onScalar(_ A) then Addr = A
                   [] onRecord(_ _ A) then Addr = A
                   end
                   CodeStore, AddRegOccs(Addr AddRS2)
                end}
               case Cont of vShared(_ InitsRS _ _) then
                  {BitArray.conj InitsRS AddRS2}
               [] nil then skip
               end
            [] vLockThread(_ _ _ _ _) then
               skip
            [] vLockEnd(_ _ _ _) then
               skip
            end
         end
      end
   end
end
