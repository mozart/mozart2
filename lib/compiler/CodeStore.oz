%%%
%%% Authors:
%%%   Author's name (Author's email address)
%%%
%%% Contributors:
%%%   optional, Contributor's name (Contributor's email address)
%%%
%%% Copyright:
%%%   Organization or Person (Year(s))
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%
%%%  Programming Systems Lab, Universitaet des Saarlandes,
%%%  Postfach 15 11 50, D-66041 Saarbruecken, Phone (+49) 681 302-5609
%%%  Author: Leif Kornstaedt <kornstae@ps.uni-sb.de>

Continuations = c(vMakePermanent: 3
                  vClear: 3
                  vUnify: 4
                  vFailure: 2
                  vEquateNumber: 4
                  vEquateLiteral: 4
                  vEquateRecord: 6
                  vGetVariable: 3
                  vGetNumber: 3
                  vGetLiteral: 3
                  vCallBuiltin: 4
                  vGenCall: 8
                  vCall: 5
                  vFastCall: 5
                  vApplMeth: 7
                  vInlineDot: 7
                  vInlineUparrow: 5
                  vInlineAt: 4
                  vInlineAssign: 4
                  vGetSelf: 3
                  vDefinition: 7
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
                  vShallowGuard: 6
                  vTestBool: 7
                  vShallowTest: 6
                  vTestNumber: 7
                  vTestLiteral: 7
                  vSwitchOnTerm: 6
                  vThread: 4
                  vLockThread: 4
                  vLockEnd: 3)

proc {ShowVInstr VInstr}   % for debugging
   L = {Label VInstr}
   N = {Width VInstr}
   NewVInstr = {MakeTuple L N}
in
   {For 1 N 1
    proc {$ I} X = VInstr.I in
       case {IsFree X} then X
       elsecase {IsChunk X} then {RegSet.toList X}
       elsecase {IsRecord X} andthen {HasFeature Continuations {Label X}}
       then {Label X}
       else X
       end = NewVInstr.I
    end}
   {Show NewVInstr}
end

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
   feat debugInfoControlSwitch debugInfoVarnamesSwitch switches reporter
   meth init(Switches Reporter)
      Emitter, init()
      regNames <- {NewDictionary}
      NextReg <- 0
      Saved <- nil
      nextLabel <- 1
      sharedDone <- {NewDictionary}
      self.debugInfoControlSwitch = {Switches get(debuginfocontrol $)}
      self.debugInfoVarnamesSwitch = {Switches get(debuginfovarnames $)}
      self.switches = Switches
      self.reporter = Reporter
   end

   meth makeRegSet($)
      {RegSet.new @minReg @NextReg - 1}
   end
   meth enterVs(Vs RS)
      case Vs of V|Vr then Reg in
         {V reg(?Reg)}
         case Reg >= @minReg then {RegSet.adjoin RS Reg}
         else skip
         end
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
      case {V getOrigin($)} \= generated then
         {Dictionary.put @regNames Reg {V getPrintName($)}}
      else
         {Dictionary.remove @regNames Reg}
      end
   end
   meth endDefinition(StartAddr FormalRegs ?GRegs ?Code)
      Saved0 = @Saved
      OldMinReg|SavedRest = Saved0
   in
      EmptyRS <- {RegSet.new @minReg @NextReg - 1}
      CodeStore, ComputeOccs(StartAddr _)
      CodeStore, AddRegOccs(StartAddr @EmptyRS)
      {Dictionary.removeAll @sharedDone}
      Emitter, doEmit(FormalRegs StartAddr ?Code ?GRegs)
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
         case {IsDet RS0} then skip
         else CodeStore, ComputeOccs(Addr1 ?RS0)
         end
         RS = RS0
      elseof VInstr then
         RS = VInstr.1
         case VInstr.(Continuations.{Label VInstr}) of nil then
            RS = {RegSet.new @minReg @NextReg - 1}
         elseof Cont then
            RS = {RegSet.copy CodeStore, ComputeOccs(Cont $)}
         end
         case VInstr of vMakePermanent(_ Regs _) then
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
         [] vGetNumber(_ _ _) then
            skip
         [] vGetLiteral(_ _ _) then
            skip
         [] vCallBuiltin(_ _ Regs _) then
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
         [] vInlineUparrow(_ Reg1 Reg2 Reg3 _) then
            CodeStore, RegOcc(Reg1 RS)
            CodeStore, RegOcc(Reg2 RS)
            CodeStore, RegOcc(Reg3 RS)
         [] vInlineAt(_ _ Reg _) then
            CodeStore, RegOcc(Reg RS)
         [] vInlineAssign(_ _ Reg _) then
            CodeStore, RegOcc(Reg RS)
         [] vGetSelf(_ Reg _) then
            CodeStore, RegOcc(Reg RS)
         [] vDefinition(_ Reg _ _ GRegs _ _) then
            CodeStore, RegOcc(Reg RS)
            CodeStore, RegOccs(GRegs RS)
         [] vExHandler(_ Addr1 Reg Addr2 _ _ InitsRS) then
            RS1 RS2 TempRS
         in
            CodeStore, ComputeOccs(Addr1 ?RS1)
            CodeStore, ComputeOccs(Addr2 ?RS2)
            CodeStore, RegOcc(Reg RS2)
            InitsRS = {RegSet.copy RS1}
            {RegSet.union InitsRS RS2}
            {RegSet.intersect InitsRS RS}
            TempRS = {RegSet.copy RS1}
            {RegSet.intersect TempRS RS2}
            {RegSet.union InitsRS TempRS}
            {RegSet.union RS RS1}
            {RegSet.union RS RS2}
         [] vPopEx(_ _ _) then
            skip
         [] vCreateCond(_ VClauses Addr _ _ AllocatesRS InitsRS) then RS0 in
            CodeStore, ComputeOccs(Addr ?RS0)
            InitsRS = {RegSet.copy RS0}
            {ForAll VClauses
             proc {$ InitsRS0#Addr1#Addr2} RS1 RS2 in
                CodeStore, ComputeOccs(Addr1 ?RS1)
                CodeStore, ComputeOccs(Addr2 ?RS2)
                {RegSet.union InitsRS RS1}
                {RegSet.union InitsRS RS2}
                InitsRS0 = {RegSet.copy RS1}
                {RegSet.intersect InitsRS0 RS2}
             end}
            {RegSet.intersect InitsRS RS}
            case AllocatesRS of nil then skip
            else
               {ForAll {RegSet.toList AllocatesRS}
                proc {$ Reg} {RegSet.adjoin InitsRS Reg} end}
            end
            {RegSet.union RS RS0}
            {ForAll VClauses
             proc {$ _#Addr1#Addr2}
                {RegSet.union RS CodeStore, GetOccs(Addr1 $)}
                {RegSet.union RS CodeStore, GetOccs(Addr2 $)}
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
         [] vShallowGuard(_ Addr1 Addr2 Addr3 _ _ AllocatesRS InitsRS) then
            RS1 RS2 RS3 in
            CodeStore, ComputeOccs(Addr1 ?RS1)
            CodeStore, ComputeOccs(Addr2 ?RS2)
            CodeStore, ComputeOccs(Addr3 ?RS3)
            InitsRS = {RegSet.copy RS1}
            {RegSet.union InitsRS RS2}
            {RegSet.union InitsRS RS3}
            {RegSet.intersect InitsRS RS}
            case AllocatesRS of nil then skip
            else
               {ForAll {RegSet.toList AllocatesRS}
                proc {$ Reg} {RegSet.adjoin InitsRS Reg} end}
            end
            {RegSet.union RS RS1}
            {RegSet.union RS RS2}
            {RegSet.union RS RS3}
         [] vTestBool(_ Reg Addr1 Addr2 Addr3 _ _ InitsRS) then
            RS1 RS2 RS3 in
            CodeStore, ComputeOccs(Addr1 ?RS1)
            CodeStore, ComputeOccs(Addr2 ?RS2)
            CodeStore, ComputeOccs(Addr3 ?RS3)
            InitsRS = {RegSet.copy RS1}
            {RegSet.union InitsRS RS2}
            {RegSet.union InitsRS RS3}
            {RegSet.intersect InitsRS RS}
            CodeStore, RegOcc(Reg RS)
            {RegSet.union RS RS1}
            {RegSet.union RS RS2}
            {RegSet.union RS RS3}
         [] vSwitchOnTerm(_ Reg Addr VHashTableEntries _ _ InitsRS) then
            RS0 in
            CodeStore, ComputeOccs(Addr ?RS0)
            InitsRS = {RegSet.copy RS0}
            {ForAll VHashTableEntries
             proc {$ VHashTableEntry} Addr in
                case VHashTableEntry of onVar(A) then Addr = A
                [] onScalar(_ A) then Addr = A
                [] onRecord(_ _ A) then Addr = A
                end
                {RegSet.union InitsRS CodeStore, ComputeOccs(Addr $)}
             end}
            {RegSet.intersect InitsRS RS}
            CodeStore, RegOcc(Reg RS)
            {RegSet.union RS RS0}
            {ForAll VHashTableEntries
             proc {$ VHashTableEntry} Addr in
                case VHashTableEntry of onVar(A) then Addr = A
                [] onScalar(_ A) then Addr = A
                [] onRecord(_ _ A) then Addr = A
                end
                {RegSet.union RS CodeStore, GetOccs(Addr $)}
             end}
         [] vThread(_ Addr _ Cont InitsRS) then RS0 in
            CodeStore, ComputeOccs(Addr ?RS0)
            InitsRS = {RegSet.copy RS0}
            {RegSet.intersect InitsRS RS}
            {RegSet.union RS RS0}
         [] vLockThread(_ Reg _ _ _) then
            CodeStore, RegOcc(Reg RS)
         [] vLockEnd(_ _ _ _) then
            skip
         end
      end
   end
   meth ComputeDisjunctionOccs(VClauses AllocatesRS ?InitsRS RS)
      InitsRS = {RegSet.copy @EmptyRS}
      {ForAll VClauses
       proc {$ InitsRS0#Addr1#Addr2} RS1 RS2 in
          CodeStore, ComputeOccs(Addr1 ?RS1)
          CodeStore, ComputeOccs(Addr2 ?RS2)
          {RegSet.union InitsRS RS1}
          {RegSet.union InitsRS RS2}
          InitsRS0 = {RegSet.copy RS1}
          {RegSet.intersect InitsRS0 RS2}
       end}
      {RegSet.intersect InitsRS RS}
      case AllocatesRS of nil then skip
      else
         {ForAll {RegSet.toList AllocatesRS}
          proc {$ Reg} {RegSet.adjoin InitsRS Reg} end}
      end
      {ForAll VClauses
       proc {$ _#Addr1#Addr2}
          {RegSet.union RS CodeStore, GetOccs(Addr1 $)}
          {RegSet.union RS CodeStore, GetOccs(Addr2 $)}
       end}
   end
   meth RegOcc(Reg RS)
      case Reg < @minReg then skip   % it's a global
      else {RegSet.adjoin RS Reg}
      end
   end
   meth RegOccs(Regs RS)
      case Regs of Reg|Regr then
         case Reg < @minReg then skip   % it's a global
         else {RegSet.adjoin RS Reg}
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
         {RegSet.union Addr.1 AddRS}
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
         case VInstr of vMakePermanent(_ _ _) then skip
         [] vClear(_ _ _) then skip
         [] vUnify(_ _ _ _) then skip
         [] vFailure(_ _) then skip
         [] vEquateNumber(_ _ _ _) then skip
         [] vEquateLiteral(_ _ _ _) then skip
         [] vEquateRecord(_ _ _ _ _ _) then skip
         [] vGetVariable(_ _ _) then skip
         [] vGetNumber(_ _ _) then skip
         [] vGetLiteral(_ _ _) then skip
         [] vCallBuiltin(_ _ _ _) then skip
         [] vGenCall(_ _ _ _ _ _ _ _) then skip
         [] vCall(_ _ _ _ _) then skip
         [] vFastCall(_ _ _ _ _) then skip
         [] vApplMeth(_ _ _ _ _ _ _) then skip
         [] vInlineDot(_ _ _ _ _ _ _) then skip
         [] vInlineUparrow(_ _ _ _ _) then skip
         [] vInlineAt(_ _ _ _) then skip
         [] vInlineAssign(_ _ _ _) then skip
         [] vGetSelf(_ _ _) then skip
         [] vDefinition(_ _ _ _ _ _ _) then skip
         [] vShared(_ Label _ Addr) then
            case {Dictionary.member @sharedDone Label} then skip
            else
               {Dictionary.put @sharedDone Label true}
               CodeStore, AddRegOccs(Addr AddRS2)
            end
         [] vExHandler(_ Addr1 _ Addr2 _ _ _) then AddRS3 in
            AddRS3 = {RegSet.copy AddRS2}
            {RegSet.union AddRS3 CodeStore, GetOccs(Addr2 $)}
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
         [] vShallowGuard(_ Addr1 Addr2 Addr3 _ _ _ _) then AddRS3 in
            AddRS3 = {RegSet.copy AddRS2}
            {RegSet.union AddRS3 CodeStore, GetOccs(Addr2 $)}
            {RegSet.union AddRS3 CodeStore, GetOccs(Addr3 $)}
            CodeStore, AddRegOccs(Addr1 AddRS3)
            CodeStore, AddRegOccs(Addr2 AddRS2)
            CodeStore, AddRegOccs(Addr3 AddRS2)
         [] vTestBool(_ _ Addr1 Addr2 Addr3 _ _ _) then
            CodeStore, AddRegOccs(Addr1 AddRS2)
            CodeStore, AddRegOccs(Addr2 AddRS2)
            CodeStore, AddRegOccs(Addr3 AddRS2)
         [] vSwitchOnTerm(_ _ Addr VHashTableEntries _ _ _) then
            CodeStore, AddRegOccs(Addr AddRS2)
            {ForAll VHashTableEntries
             proc {$ VHashTableEntry} Addr in
                case VHashTableEntry of onVar(A) then Addr = A
                [] onScalar(_ A) then Addr = A
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
      AddRS3 = {RegSet.copy AddRS}
      {ForAll VClauses
       proc {$ _#_#Addr2}
          CodeStore, AddRegOccs(Addr2 AddRS2)
          {RegSet.union AddRS3 CodeStore, GetOccs(Addr2 $)}
       end}
      {FoldR VClauses
       fun {$ _#Addr1#Addr2 AddRS}
          CodeStore, AddRegOccs(Addr1 AddRS)
          CodeStore, GetOccs(Addr1 $)
       end AddRS3 _}
   end
end
