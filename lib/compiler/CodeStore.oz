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

Continuations = c(vStepPoint: 5
                  vMakePermanent: 3
                  vClear: 3
                  vUnify: 4
                  vFailure: 2
                  vEquateNumber: 4
                  vEquateLiteral: 4
                  vEquateRecord: 6
                  vGetVariable: 3
                  vCallBuiltin: 5
                  vGenCall: 8
                  vCall: 5
                  vFastCall: 5
                  vApplMeth: 7
                  vInlineDot: 7
                  vInlineAt: 4
                  vInlineAssign: 4
                  vGetSelf: 3
                  vSetSelf: 3
                  vDefinition: 7
                  vDefinitionCopy: 8
                  vShared: ~1
                  vBranch: ~1
                  vExHandler: 6
                  vPopEx: 3
                  vCreateCond: 4
                  vCreateOr: 3
                  vCreateEnumOr: 3
                  vCreateChoice: 3
                  vAsk: 2
                  vWait: 2
                  vWaitTop: 2
                  vTestBool: 7
                  vTestBuiltin: 6
                  vTestNumber: 7
                  vTestLiteral: 7
                  vMatch: 6
                  vThread: 4
                  vLockThread: 4
                  vLockEnd: 3)

class CodeStore from Emitter
   prop final
   attr
      EmptyRS
      regNames        % mapping Reg -> PrintName
      NextReg
      minReg          % smallest Reg index local to current def.
      Saved           % saved minReg from enclosing definitions
      nextLabel
      sharedDone
   feat
      debugInfoControlSwitch debugInfoVarnamesSwitch
      state reporter
   meth init(State Reporter)
      Emitter, init()
      regNames <- {NewDictionary}
      NextReg <- 0
      Saved <- nil
      nextLabel <- 1
      sharedDone <- {NewDictionary}
      self.debugInfoControlSwitch =
      {State getSwitch(debuginfocontrol $)}
      self.debugInfoVarnamesSwitch =
      {State getSwitch(debuginfovarnames $)}
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
      Saved <- @minReg|@Saved
      minReg <- @NextReg
   end
   meth newReg(?Reg)
      Reg = @NextReg
      NextReg <- Reg + 1
   end
   meth newSelfReg(?Reg)
      Reg = @NextReg
      NextReg <- Reg + 1
      {Dictionary.put @regNames Reg 'self'}
   end
   meth newVariableReg(V ?Reg)
      Reg = @NextReg
      NextReg <- Reg + 1
      case {V getOrigin($)} of generated then
         {Dictionary.remove @regNames Reg}
      else
         {Dictionary.put @regNames Reg {V getPrintName($)}}
      end
   end
   meth endDefinition(StartAddr FormalRegs AllRegs ?GRegs ?Code ?NLiveRegs)
      Saved0 = @Saved
      OldMinReg|SavedRest = Saved0
   in
      EmptyRS <- CodeStore, makeRegSet($)
      CodeStore, ComputeOccs(StartAddr _)
      CodeStore, AddRegOccs(StartAddr @EmptyRS)
      {Dictionary.removeAll @sharedDone}
      Emitter, doEmit(FormalRegs AllRegs StartAddr ?Code ?GRegs ?NLiveRegs)
      {Dictionary.removeAll @sharedDone}
      % restore enclosing definition's state:
      NextReg <- @minReg
      minReg <- OldMinReg
      Saved <- SavedRest
   end
   meth getRegNames(GRegs ?GPNs)
      GPNs = {Map GRegs fun {$ Reg} {Dictionary.get @regNames Reg} end}
   end

   meth GetOccs(Addr ?RS)
      RS = case Addr of nil then @EmptyRS else Addr.1 end
   end
   meth ComputeOccs(Addr ?RS)
      case Addr of nil then
         RS = @EmptyRS
      [] vShared(RS0 Label Count Addr1) then
         {Assign Count {Access Count} + 1}
         if {IsDet RS0} then skip
         else CodeStore, ComputeOccs(Addr1 ?RS0)
         end
         RS = RS0
      elseof VInstr then
         RS = VInstr.1
         case VInstr.(Continuations.{Label VInstr}) of nil then
            CodeStore, makeRegSet(?RS)
         elseof Cont then
            RS = {BitArray.clone CodeStore, ComputeOccs(Cont $)}
         end
         case VInstr of vStepPoint(_ Addr _ _ _) then RS1 in
            CodeStore, ComputeOccs(Addr ?RS1)
            {BitArray.disj RS RS1}
         [] vMakePermanent(_ Regs _) then
            CodeStore, RegOccs(Regs RS)
         [] vClear(_ Regs _) then
            CodeStore, RegOccs(Regs RS)
         [] vUnify(_ Reg1 Reg2 _) then
            CodeStore, RegOcc(Reg1 RS)
            CodeStore, RegOcc(Reg2 RS)
         [] vFailure(_ _) then
            skip
         [] vEquateNumber(_ _ Reg _) then
            CodeStore, RegOcc(Reg RS)
         [] vEquateLiteral(_ _ Reg _) then
            CodeStore, RegOcc(Reg RS)
         [] vEquateRecord(_ _ _ Reg VArgs _) then
            CodeStore, RegOcc(Reg RS)
            CodeStore, RegOccVArgs(VArgs RS)
         [] vGetVariable(_ Reg _) then
            CodeStore, RegOcc(Reg RS)
         [] vCallBuiltin(_ _ Regs _ _) then
            CodeStore, RegOccs(Regs RS)
         [] vGenCall(_ Reg _ _ _ Regs _ _) then
            CodeStore, RegOcc(Reg RS)
            CodeStore, RegOccs(Regs RS)
         [] vCall(_ Reg Regs _ _) then
            CodeStore, RegOcc(Reg RS)
            CodeStore, RegOccs(Regs RS)
         [] vFastCall(_ _ Regs _ _) then
            CodeStore, RegOccs(Regs RS)
         [] vApplMeth(_ Reg _ _ Regs _ _) then
            CodeStore, RegOcc(Reg RS)
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
         [] vExHandler(_ Addr1 Reg Addr2 _ _ InitsRS) then RS1 RS2 TempRS in
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
         [] vPopEx(_ _ _) then
            skip
         [] vCreateCond(_ VClauses Addr _ _ AllocatesRS InitsRS) then RS0 in
            CodeStore, ComputeOccs(Addr ?RS0)
            InitsRS = {BitArray.clone RS0}
            {ForAll VClauses
             proc {$ InitsRS0#Addr1#Addr2} RS1 RS2 in
                CodeStore, ComputeOccs(Addr1 ?RS1)
                CodeStore, ComputeOccs(Addr2 ?RS2)
                {BitArray.disj InitsRS RS1}
                {BitArray.disj InitsRS RS2}
                InitsRS0 = {BitArray.clone RS1}
                {BitArray.conj InitsRS0 RS2}
             end}
            {BitArray.conj InitsRS RS}
            case AllocatesRS of nil then skip
            else
               % We can't use BitArray.disj here because the bounds of
               % AllocatesRS may be a strict subset of those of InitsRS:
               {ForAll {BitArray.toList AllocatesRS}
                proc {$ Reg} {BitArray.set InitsRS Reg} end}
            end
            {BitArray.disj RS RS0}
            {ForAll VClauses
             proc {$ _#Addr1#Addr2}
                {BitArray.disj RS CodeStore, GetOccs(Addr1 $)}
                {BitArray.disj RS CodeStore, GetOccs(Addr2 $)}
             end}
         [] vCreateOr(_ VClauses _ _ AllocatesRS InitsRS) then
            CodeStore, ComputeDisjunctionOccs(VClauses AllocatesRS
                                              ?InitsRS RS)
         [] vCreateEnumOr(_ VClauses _ _ AllocatesRS InitsRS) then
            CodeStore, ComputeDisjunctionOccs(VClauses AllocatesRS
                                              ?InitsRS RS)
         [] vCreateChoice(_ VClauses _ _ AllocatesRS InitsRS) then
            CodeStore, ComputeDisjunctionOccs(VClauses AllocatesRS
                                              ?InitsRS RS)
         [] vAsk(_ _) then
            skip
         [] vWait(_ _) then
            skip
         [] vWaitTop(_ _) then
            skip
         [] vTestBool(_ Reg Addr1 Addr2 Addr3 _ _ InitsRS) then RS1 RS2 RS3 in
            CodeStore, ComputeOccs(Addr1 ?RS1)
            CodeStore, ComputeOccs(Addr2 ?RS2)
            CodeStore, ComputeOccs(Addr3 ?RS3)
            InitsRS = {BitArray.clone RS1}
            {BitArray.disj InitsRS RS2}
            {BitArray.disj InitsRS RS3}
            {BitArray.conj InitsRS RS}
            CodeStore, RegOcc(Reg RS)
            {BitArray.disj RS RS1}
            {BitArray.disj RS RS2}
            {BitArray.disj RS RS3}
         [] vTestBuiltin(_ _ Regs Addr1 Addr2 _ InitsRS) then RS1 RS2 in
            CodeStore, ComputeOccs(Addr1 ?RS1)
            CodeStore, ComputeOccs(Addr2 ?RS2)
            InitsRS = {BitArray.clone RS1}
            {BitArray.disj InitsRS RS2}
            {BitArray.conj InitsRS RS}
            CodeStore, RegOccs(Regs RS)
            {BitArray.disj RS RS1}
            {BitArray.disj RS RS2}
         [] vMatch(_ Reg Addr VHashTableEntries _ _ InitsRS) then
            RS0 in
            CodeStore, ComputeOccs(Addr ?RS0)
            InitsRS = {BitArray.clone RS0}
            {ForAll VHashTableEntries
             proc {$ VHashTableEntry} Addr in
                case VHashTableEntry of onScalar(_ A) then Addr = A
                [] onRecord(_ _ A) then Addr = A
                end
                {BitArray.disj InitsRS CodeStore, ComputeOccs(Addr $)}
             end}
            {BitArray.conj InitsRS RS}
            CodeStore, RegOcc(Reg RS)
            {BitArray.disj RS RS0}
            {ForAll VHashTableEntries
             proc {$ VHashTableEntry} Addr in
                case VHashTableEntry of onScalar(_ A) then Addr = A
                [] onRecord(_ _ A) then Addr = A
                end
                {BitArray.disj RS CodeStore, GetOccs(Addr $)}
             end}
         [] vThread(_ Addr _ Cont InitsRS) then RS0 in
            CodeStore, ComputeOccs(Addr ?RS0)
            InitsRS = {BitArray.clone RS0}
            {BitArray.conj InitsRS RS}
            {BitArray.disj RS RS0}
         [] vLockThread(_ Reg _ _ _) then
            CodeStore, RegOcc(Reg RS)
         [] vLockEnd(_ _ _ _) then
            skip
         end
      end
   end
   meth ComputeDisjunctionOccs(VClauses AllocatesRS ?InitsRS RS)
      InitsRS = {BitArray.clone @EmptyRS}
      {ForAll VClauses
       proc {$ InitsRS0#Addr1#Addr2} RS1 RS2 in
          CodeStore, ComputeOccs(Addr1 ?RS1)
          CodeStore, ComputeOccs(Addr2 ?RS2)
          {BitArray.disj InitsRS RS1}
          {BitArray.disj InitsRS RS2}
          InitsRS0 = {BitArray.clone RS1}
          {BitArray.conj InitsRS0 RS2}
       end}
      {BitArray.conj InitsRS RS}
      case AllocatesRS of nil then skip
      else
         {ForAll {BitArray.toList AllocatesRS}
          proc {$ Reg} {BitArray.set InitsRS Reg} end}
      end
      {ForAll VClauses
       proc {$ _#Addr1#Addr2}
          {BitArray.disj RS CodeStore, GetOccs(Addr1 $)}
          {BitArray.disj RS CodeStore, GetOccs(Addr2 $)}
       end}
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
         case VInstr of vStepPoint(_ Addr _ _ _) then
            CodeStore, AddRegOccs(Addr AddRS2)
         [] vMakePermanent(_ _ _) then skip
         [] vClear(_ _ _) then skip
         [] vUnify(_ _ _ _) then skip
         [] vFailure(_ _) then skip
         [] vEquateNumber(_ _ _ _) then skip
         [] vEquateLiteral(_ _ _ _) then skip
         [] vEquateRecord(_ _ _ _ _ _) then skip
         [] vGetVariable(_ _ _) then skip
         [] vCallBuiltin(_ _ _ _ _) then skip
         [] vGenCall(_ _ _ _ _ _ _ _) then skip
         [] vCall(_ _ _ _ _) then skip
         [] vFastCall(_ _ _ _ _) then skip
         [] vApplMeth(_ _ _ _ _ _ _) then skip
         [] vInlineDot(_ _ _ _ _ _ _) then skip
         [] vInlineAt(_ _ _ _) then skip
         [] vInlineAssign(_ _ _ _) then skip
         [] vGetSelf(_ _ _) then skip
         [] vSetSelf(_ _ _) then skip
         [] vDefinition(_ _ _ _ _ _ _) then skip
         [] vDefinitionCopy(_ _ _ _ _ _ _ _) then skip
         [] vShared(_ Label _ Addr) then
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
         [] vCreateCond(_ VClauses Addr _ _ _ _) then
            CodeStore, AddRegOccs(Addr AddRS2)
            CodeStore, AddRegOccsClauses(VClauses
                                         CodeStore, GetOccs(Addr $) AddRS2)
         [] vCreateOr(_ VClauses _ _ _ _) then
            CodeStore, AddRegOccsClauses(VClauses AddRS2 AddRS2)
         [] vCreateEnumOr(_ VClauses _ _ _ _) then
            CodeStore, AddRegOccsClauses(VClauses AddRS2 AddRS2)
         [] vCreateChoice(_ VClauses _ _ _ _) then
            CodeStore, AddRegOccsClauses(VClauses AddRS2 AddRS2)
         [] vAsk(_ _) then skip
         [] vWait(_ _) then skip
         [] vWaitTop(_ _) then skip
         [] vTestBool(_ _ Addr1 Addr2 Addr3 _ _ _) then
            CodeStore, AddRegOccs(Addr1 AddRS2)
            CodeStore, AddRegOccs(Addr2 AddRS2)
            CodeStore, AddRegOccs(Addr3 AddRS2)
         [] vTestBuiltin(_ _ _ Addr1 Addr2 _ _) then
            CodeStore, AddRegOccs(Addr1 AddRS2)
            CodeStore, AddRegOccs(Addr2 AddRS2)
         [] vMatch(_ _ Addr VHashTableEntries _ _ _) then
            CodeStore, AddRegOccs(Addr AddRS2)
            {ForAll VHashTableEntries
             proc {$ VHashTableEntry} Addr in
                case VHashTableEntry of onScalar(_ A) then Addr = A
                [] onRecord(_ _ A) then Addr = A
                end
                CodeStore, AddRegOccs(Addr AddRS2)
             end}
         [] vThread(_ Addr _ Cont _) then
            CodeStore, AddRegOccs(Addr AddRS2)
         [] vLockThread(_ _ _ _ _) then
            skip
         [] vLockEnd(_ _ _ _) then
            skip
         end
      end
   end
   meth AddRegOccsClauses(VClauses AddRS AddRS2) AddRS3 in
      AddRS3 = {BitArray.clone AddRS}
      {ForAll VClauses
       proc {$ _#_#Addr2}
          CodeStore, AddRegOccs(Addr2 AddRS2)
          {BitArray.disj AddRS3 CodeStore, GetOccs(Addr2 $)}
       end}
      {FoldR VClauses
       fun {$ _#Addr1#_ AddRS}
          CodeStore, AddRegOccs(Addr1 AddRS)
          CodeStore, GetOccs(Addr1 $)
       end AddRS3 _}
   end
end
