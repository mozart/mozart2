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

%\define DEBUG_EMIT
%\define DEBUG_OPTIMIZER
%\define DEBUG_SHARED

functor
import
   CompilerSupport(isCopyableName) at 'x-oz://boot/CompilerSupport'
   FD(decl int distinct assign)
   Space(new waitStable ask merge)
   Debug(getRaiseOnBlock setRaiseOnBlock) at 'x-oz://boot/Debug'
   Property(get)
   Builtins(getInfo)
   System(show)
export
   'class': Emitter
   Continuations
prepare
   Continuations = c(vDebugEntry: 4
                     vDebugExit: 4
                     vMakePermanent: 3
                     vClear: 3
                     vUnify: 4
                     vEquateConstant: 4
                     vEquateRecord: 6
                     vGetVariable: 3
                     vCallBuiltin: 5
                     vCallGlobal: 5
                     vCallMethod: 7
                     vCall: 5
                     vConsCall: 5
                     vDeconsCall: 6
                     vCallProcedureRef: 5
                     vCallConstant: 5
                     vInlineDot: 7
                     vInlineAt: 4
                     vInlineAssign: 4
                     vGetSelf: 3
                     vSetSelf: 3
                     vDefinition: 7
                     vDefinitionCopy: 8
                     vShared: ~1
                     vExHandler: 6
                     vPopEx: 3
                     vTestBool: 7
                     vTestBuiltin: 6
                     vTestConstant: 7
                     vMatch: 6
                     vLockThread: 4
                     vLockEnd: 3)
define
\ifdef DEBUG_EMIT
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
\endif

   local
      %%
      %% We must not hoist record containing copyable names since
      %% procedure code instantiation would be unable to replace them.
      %%

      fun {IsConstant VArg}
         case VArg of constant(C) then
            {Not {CompilerSupport.isCopyableName C}}
         else false
         end
      end

      fun {GetConstant constant(X)} X end

      fun {HoistVArg VArg}
         case VArg of record(Atomname RecordArity VArgs) then NewVArgs in
            NewVArgs = {Map VArgs HoistVArg}
            if {Not {CompilerSupport.isCopyableName Atomname}} andthen
               {All NewVArgs IsConstant} andthen
               ({IsInt RecordArity} orelse
                {Not {Some RecordArity CompilerSupport.isCopyableName}})
            then Args X in
               Args = {Map NewVArgs GetConstant}
               X = if {IsInt RecordArity} then
                      {List.toTuple Atomname Args}
                   else
                      {List.toRecord Atomname
                       {List.zip RecordArity Args fun {$ F X} F#X end}}
                   end
               constant(X)
            else record(Atomname RecordArity NewVArgs)
            end
         else VArg
         end
      end
   in
      fun {HoistRecord State Atomname RecordArity VArgs}
         if {State getSwitch(recordhoist $)} then
            {HoistVArg record(Atomname RecordArity VArgs)}
         else
            record(Atomname RecordArity VArgs)
         end
      end
   end

   fun {NextFreeIndex Used I}
      if {Dictionary.member Used I} then {NextFreeIndex Used I + 1}
      else I
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

   proc {GetRegs VArgs Hd Tl}
      case VArgs of VArg|VArgr then Inter in
         case VArg of value(Reg) then
            Hd = Reg|Inter
         [] record(_ _ VArgs) then
            {GetRegs VArgs Hd Inter}
         else
            Hd = Inter
         end
         {GetRegs VArgr Inter Tl}
      [] nil then
         Hd = Tl
      end
   end

   fun {FilterNonlinearRegs Regs}
      case Regs of Reg|Regr then
         if {Member Reg Regr} then Reg|{FilterNonlinearRegs Regr}
         else {FilterNonlinearRegs Regr}
         end
      [] nil then nil
      end
   end

   fun {GetNonlinearRegs VArgs}
      {FilterNonlinearRegs {GetRegs VArgs $ nil}}
   end

   local
      local
         proc {DoAssign L H D X N}
            if L=<H then
               if {BitArray.test D L} then
                  X.L=N {DoAssign L+1 H D X N+1}
               else
                  {DoAssign L+1 H D X N}
               end
            end
         end
      in
         proc {AssignFirst _|D X}
            {DoAssign {BitArray.low D} {BitArray.high D} D X 0}
         end
      end

      local
         proc {DoVector L H D X V I}
            if L=<H then
               if {BitArray.test D L} then
                  V.I=X.L {DoVector L+1 H D X V I+1}
               else
                  {DoVector L+1 H D X V I}
               end
            end
         end
      in
         fun {MakeVector C|D X}
            V={MakeTuple v C}
         in
            {DoVector {BitArray.low D} {BitArray.high D} D X V 1}
            V
         end
      end
   in
      class RegisterOptimizer
         attr
            N:      1    % Current Y index
            CDs:    nil  % List of pairs cardinality and bitarrays
                         % representing distinct constraints
            Es:     nil  % List of pairs of equality constraints
            Ns:     nil  % List of pairs of inequality constraints
            Ss:     nil  % List of hard assignments
         feat
            Mapping      % Maps allocation to real registers

         meth init
            %% Assumption: register indices start from 1
            self.Mapping = {Dictionary.new}
         end

         meth Distinct(Ys)
            case Ys of [_] then skip else
               D2={BitArray.fromList Ys}
            in
               case @CDs
               of (_|D1)|CDr then
                  if {BitArray.subsumes D2 D1} then
                     CDs <- ({BitArray.card D2}|D2)|CDr
                  else
                     CDs <- ({BitArray.card D2}|D2)|@CDs
                  end
               else
                  CDs <- [{BitArray.card D2}|D2]
               end
            end
         end

         meth neq(I1 I2)
            Ns <- (I1|I2)|@Ns
         end

         meth decl(Is ?Y ?I)
            J
         in
            I=@N
            N <- I+1
            Y=y(J)
            {Dictionary.put self.Mapping I J}
            {self Distinct(I|Is)}
         end

         meth isEmpty($)
            {Dictionary.isEmpty self.Mapping}
         end

         meth eq(Y1 Y2)
            if Y1\=Y2 then
               Es <- (Y1|Y2)|@Es
            end
         end

         meth set(Y I)
            if I >= @N then
               %% Must accomodate fixed (for debugger) Y registers
               N <- I+1
            end
            Ss <- (Y|I)|@Ss
         end

         meth Optimize(AddNs $)
            LNs = @Ns
            LCDs = {Sort @CDs fun {$ C1|_ C2|_}
                                 C1>C2
                              end}
            LEs = @Es
            LSs = @Ss
            LN  = @N-1
\ifdef DEBUG_OPTIMIZER
            {System.show 'OPTIMISE'}
            local
               ShowDist = {Map LCDs fun {$ _|C}
                                       distinct_regs({BitArray.toList C})
                                    end
                          }
            in
               {ForAll LEs proc {$ R1|R2}
                              {System.show eq_reg(R1 R2)}
                           end}
               {ForAll LSs proc {$ R1|R2}
                              {System.show hard_eq_reg(R1 R2)}
                           end}
               {ForAll ShowDist System.show}
               {ForAll LNs proc {$ R1|R2}
                              {System.show ineq_reg(R1 R2)}
                           end}
            end
\endif
            S = {Space.new proc {$ X}
                              %% Create mapping
                              X = {MakeTuple regs LN}
                              %% Process equality constraints
                              {ForAll LEs
                               proc {$ Y1|Y2}
                                  X.Y1=X.Y2
                               end}
                              if LSs==nil then
                                 %% Take the first distinct and assign directly
                                 if LCDs\=nil then
                                    {AssignFirst LCDs.1 X}
                                 end
                              else
                                 %% Do hard assignments
                                 {ForAll LSs
                                  proc {$ Y|I}
                                     X.Y=I
                                  end}
                              end
                              %% Tell domain constraints
                              X ::: 0#LN
                              if AddNs then
                                 %% inequalities
                                 {ForAll LNs proc {$ I1|I2} X.I1 \=: X.I2 end}
                              end
                              local
                                 Vs={Map if LSs==nil andthen LCDs\=nil then
                                            LCDs.2
                                         else LCDs
                                         end
                                     fun {$ LCD}
                                        {MakeVector LCD X}
                                     end}
                              in
                                 %% Post distincts
                                 {ForAll Vs FD.distinct}
                                 %% Assign following distincts
                                 {ForAll Vs proc {$ V}
                                               {FD.assign min V}
                                            end}
                              end
                              {FD.assign min X}
                           end}
            T = {Thread.this}
            RaiseOnBlock = {Debug.getRaiseOnBlock T}
            Alloc Status
         in
            {Debug.setRaiseOnBlock T false}
            {Space.ask S Status}
            if Status \= succeeded then
               raise ineq_cs_failed end
            end
            {Debug.setRaiseOnBlock T RaiseOnBlock}
            Alloc = {Space.merge S}
            {Record.foldLInd Alloc
             fun {$ I M J}
                %% Because of fixed register assignment (\switch +staticvarname)
                %% some registers may not be in use.
                if {Dictionary.member self.Mapping I} then
                   {Dictionary.get self.Mapping I}=J
                   {Max M J}
                else M
                end
             end ~1}+1
         end
         %% PR#571, PR#931, PR#1244
         %% To fix register allocation bugs we have added inequality
         %% constraints between source/target Y registers involved in
         %% EmitShared's register shuffling. We first try with those
         %% constraints, if it fails we try without those constraints.
         %% (i.e. we fall back on the old behaviour) this is expected
         %% to be a short term fix until further investigations have
         %% made it unnecessary.
         %%
         %% keving: On the main branch we have removed the fallback. If the constraints
         %% are unsolvable the compiler will crash.
         meth optimize(Res)
            Res = {self Optimize(true $)}
            {self reset()}
         end

         meth reset()
            Ns  <- nil
            CDs <- nil
            Es  <- nil
            Ss  <- nil
         end
      end
   end

   fun {IsStep Coord}
      case {Label Coord} of pos then false
      [] unit then false
      else true
      end
   end

   %%
   %% The Emitter class maintains information about which registers are
   %% currently in use.  The dictionary UsedX maps each X register index
   %% to true if and only if it is currently in use.
   %%
   %% Each Y register is represented as y(_); the indices are only bound
   %% at the end of compilation of a procedure.  NamedYs is a dictionary
   %% that maps some Y register indices to their print names (for debug
   %% information).
   %%

   class Emitter
      attr
         Temporaries Permanents
         LastAliveRS ShortLivedTemps ShortLivedPerms
         UsedX LowestFreeX HighestEverX
         NamedYs RegOpt
         GRegRef HighestUsedG
         LocalEnvSize
         CodeHd CodeTl
         LocalEnvsInhibited
         continuations

         %% These are only needed temporarily for call argument initialization
         %% and for fulfilling prerequisites for entering a shared code region:
         AdjDict DelayedInitsDict DoneDict CurrentID Stack Arity
      meth init()
         GRegRef <- {NewDictionary}
         DelayedInitsDict <- {NewDictionary}
         AdjDict <- {NewDictionary}
         DoneDict <- {NewDictionary}
      end
      meth doEmit(FormalRegs AllRegs StartAddr NumberReserved
                  ?Code ?GRegs ?NLiveRegs) RS NewCodeTl NumberOfYs in
         Temporaries <- {NewDictionary}
         Permanents <- {NewDictionary}
         {self makeRegSet(?RS)}
         LastAliveRS <- RS
         {ForAll FormalRegs proc {$ Reg} {BitArray.set RS Reg} end}
         ShortLivedTemps <- nil
         ShortLivedPerms <- nil
         UsedX <- {NewDictionary}
         LowestFreeX <- 0
         HighestEverX <- ~1
         NamedYs <- {NewDictionary}
         RegOpt <- {New RegisterOptimizer init()}
         HighestUsedG <- ~1
         LocalEnvSize <- _
         CodeHd <- allocateL(@LocalEnvSize)|NewCodeTl
         CodeTl <- NewCodeTl
         LocalEnvsInhibited <- false
         continuations <- nil
         {List.forAllInd FormalRegs
          proc {$ I Reg} Emitter, AllocateThisTemp(I - 1 Reg _) end}
         {ForAll AllRegs
          proc {$ Reg} Emitter, GetPerm(Reg _) end}
         Emitter, EmitAddr(StartAddr)
         GRegs = {ForThread @HighestUsedG 0 ~1
                  fun {$ In I} {Dictionary.get @GRegRef I}|In end nil}
         {@RegOpt optimize(?NumberOfYs)}
         if {IsFree @LocalEnvSize} then
            @LocalEnvSize = NumberOfYs
         end
         @CodeTl = nil
         if {self.state getSwitch(staticvarnames $)} then
            if NumberReserved == 0 andthen GRegs == nil then
               %% Emitting at least one `...Varname' instruction
               %% flags this procedure as having been compiled with
               %% the switch +staticvarnames:
               Code = @CodeHd#[localVarname('')]
            else
               Code =
               @CodeHd#
               {ForThread NumberReserved - 1 0 ~1
                fun {$ In I}
                   localVarname({Dictionary.condGet @NamedYs I ''})|In
                end
                {Map AllRegs
                 fun {$ GReg}
                    globalVarname({Dictionary.condGet @regNames GReg ''})
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
         NamedYs <- unit
         {Dictionary.removeAll @GRegRef}
      end
      meth newLabel(?Label)
         Label = @nextLabel
         nextLabel <- Label + 1
      end

      meth EmitAddr(Addr)
\ifdef DEBUG_EMIT
         {System.printInfo 'Debug:\nDebug:Instruction:\nDebug:  '}
         {ShowVInstr Addr}
         {System.printInfo 'Debug:Continuation stack:\n'}
         case @continuations of nil then
            {System.printInfo 'Debug:  nil\n'}
         elseof VInstrs then
            {ForAll VInstrs
             proc {$ VInstr}
                {System.printInfo 'Debug:  '}
                {ShowVInstr VInstr}
             end}
         end
\endif
         case Addr of nil then OldContinuations in
            OldContinuations = @continuations
            case OldContinuations
            of (VInstr=vShared(OccsRS InitsRS Label Addr))|Rest then
               continuations <- Rest
               Emitter, LetDie(VInstr)
               Emitter, EmitShared(OccsRS InitsRS Label Addr 'skip')
               continuations <- OldContinuations
            [] nil then
               Emitter, DeallocateAndReturn()
            end
         elseof VInstr then
            Emitter, FlushShortLivedRegs()
            Emitter, LetDie(VInstr)
            case VInstr of vShared(OccsRS InitsRS Label Addr) then
               Emitter, EmitShared(OccsRS InitsRS Label Addr 'skip')
            elsecase VInstr.(Continuations.{Label VInstr}) of nil then
               Emitter, EmitVInstr(VInstr)
               Emitter, EmitAddr(nil)
            elseof Cont then
               continuations <- Cont|@continuations
               Emitter, EmitVInstr(VInstr)
               case @continuations of NewCont|Rest then
                  %% Note: NewCont may be different from Cont!
                  continuations <- Rest
                  Emitter, EmitAddr(NewCont)   % may be nil
               end
            end
         end
      end
      meth EmitShared(OccsRS InitsRS Label Addr AllocateInstr)
         case {Dictionary.condGet @sharedDone Label unit} of unit then
            OldContinuations
         in
            %% Make sure all registers in InitsRS are allocated:
            OldContinuations = @continuations
            continuations <- Addr|OldContinuations
            {ForAll {Dictionary.keys @Permanents}
             proc {$ Reg} Emitter, GetReg(Reg _) end}
            if {IsDet InitsRS} then
               {ForAll {BitArray.toList InitsRS}
                proc {$ Reg}
                   case Emitter, GetReg(Reg $) of none then R in
                      Emitter, PredictReg(Reg ?R)
                      Emitter, Emit(createVariable(R))
                   else skip
                   end
                end}
            end
            continuations <- OldContinuations
            {Dictionary.put @sharedDone Label
             {Dictionary.clone @Temporaries}#
             {Dictionary.clone @Permanents}}
            Emitter, Emit(lbl(Label))
            Emitter, Emit(AllocateInstr)
            Emitter, EmitAddr(Addr)
         [] Ts#Ps then
\ifdef DEBUG_SHARED
            {System.show {Dictionary.toRecord currentPermanents @Permanents}}
            {System.show {Dictionary.toRecord targetPermanents Ps}}
            {System.show {Dictionary.toRecord currentTemporaries @Temporaries}}
            {System.show {Dictionary.toRecord targetTemporaries Ts}}
\endif
            %% PR#571, PR#931, PR#1244
            %% We move register contents around to be in the right place
            %% for the code block we are about to jump to.
            %% For the X registers this is straightforward,  we know the
            %% physical source/target register numbers.
            %% For the Y registers we don't know the physical numbers until we call
            %% "@RegOpt optimize" at the end of code generation.
            %% We must ensure that we don't overwrite the value in a Y register that
            %% is still required as a source. To ensure this we add inequality
            %% constraints between all source and target Y registers
            %% (and see comment on the register optimizer)
            local
               SourceYs = {NewCell nil}
               TargetYs = {NewCell nil}
            in
               {ForAll {Dictionary.entries Ps}
                proc {$ Reg#YG}
                   case YG of (Y=y(_))#I then
                      case Emitter, GetPerm(Reg $) of none then
                         %% Remember all Indexes, I, that get overwritten
                         local L in {Exchange TargetYs L I|L} end
                         case Emitter, GetTemp(Reg $) of none then
                            Emitter, Emit(createVariable(Y))
                         elseof X then
                            Emitter, Emit(move(X Y))
                         end
                      elsecase {Dictionary.get @Permanents Reg} of _#J then
                         {@RegOpt eq(I J)}
                      end
                   else skip
                   end
                end}
               Arity <- 0
               {ForAll {Dictionary.entries Ts}
                proc {$ Reg#(X=x(I))} Instr in
                   if I >= @Arity then
                      Arity <- I + 1
                   end
                   case {Dictionary.condGet @Permanents Reg none}
                   of vEquateConstant(_ Constant _ _) then
                      {Dictionary.remove @Permanents Reg}
                      putConstant(Constant X)
                   [] vGetSelf(_ _ _) then
                      {Dictionary.remove @Permanents Reg}
                      getSelf(X)
                   elsecase Emitter, GetTemp(Reg $) of none then
                      case Emitter, GetPerm(Reg $) of none then
                         createVariable(X)
                      elseof YG then
                         case {Dictionary.condGet @Permanents Reg none}
                         of y(_)#IndS then
                            %% Remember all Indexes, I, that get read
                            local L in {Exchange SourceYs L IndS|L} end
                         else skip end
                         move(YG X)
                      end
                   [] x(!I) then
                      %% Optimize the special case that the register
                      %% already is located in its destination.
                      'skip'
                   elseof X2=x(J) then
                      {Dictionary.put @AdjDict J
                       I|{Dictionary.condGet @AdjDict J nil}}
                      move(X2 X)
                   end = Instr
                   {Dictionary.put @DelayedInitsDict I Instr}
                end}
               {ForAll {Access SourceYs}
                proc {$ IndS}
                   {ForAll {Access TargetYs}
                    proc {$ IndT}
                       {@RegOpt neq(IndS IndT)} end}
                end}
            end
            %% PR#1329
            %% In ConfigureXBank() when we have cycles we call spillTemporary to
            %% grab a temp X register to break the cycle. This uses
            %% the X register pointed to by LowestFreeX, we must make
            %% sure LowestFreeX is really free in both the current (old) X
            %% registers and the (new) X registers being constructed.
            %% kost@ : 'UsedX' keeps the real registers while
            %% 'Temporaries' keeps the abstract ones!
            LowestFreeX <- {NextFreeIndex @UsedX @Arity}

            Emitter, ConfigureXBank()
            Temporaries <- {Dictionary.clone Ts}
            Permanents <- {Dictionary.clone Ps}
            Emitter, Emit(branch(Label))
         end
      end
      meth FlushShortLivedRegs()
         case @ShortLivedTemps of x(I)|Xr then
            Emitter, FreeX(I)
            ShortLivedTemps <- Xr
            Emitter, FlushShortLivedRegs()
         [] nil then
            ShortLivedPerms <- nil
         end
      end
      meth LetDie(VInstr) RS = @LastAliveRS in
         if RS \= VInstr.1 then AliveRS in
            AliveRS = case VInstr of vShared(RS _ _ _) then {BitArray.clone RS}
                      else VInstr.1
                      end
            %% Let all registers die that do not occur in AliveRS.
            LastAliveRS <- AliveRS
            {BitArray.nimpl RS AliveRS}
            Emitter, LetDieSub({BitArray.toList RS})
         end
      end
      meth LetDieSub(Regs)
         case Regs of Reg|Regr then
            Emitter, FreeReg(Reg)
            Emitter, LetDieSub(Regr)
         [] nil then skip
         end
      end
      meth EmitVInstr(ThisAddr)
         case ThisAddr of vDebugEntry(_ Coord Kind _) then
            Emitter, DebugEntry(Coord Kind)
         [] vDebugExit(_ Coord Kind _) then
            Emitter, DebugExit(Coord Kind)
         [] vMakePermanent(_ RegIndices _) then TempX1 TempX2 S D in
            Emitter, AllocateShortLivedTemp(?TempX2)
            Emitter, AllocateShortLivedTemp(?TempX1)
            S = self.staticVarnamesSwitch
            D = self.dynamicVarnamesSwitch
            {ForAll RegIndices
             proc {$ Reg#Index#PrintName}
                {Dictionary.put @regNames Reg PrintName}
                if S then
                   case Emitter, GetPerm(Reg $) of g(_) then skip
                   elseof Perm then
                      case Perm of none then Y in
                         Emitter, AllocatePerm(Reg ?Y)
                         case Emitter, GetTemp(Reg $) of none then
                            Emitter, Emit(createVariable(Y))
                         elseof X then
                            Emitter, Emit(move(X Y))
                         end
                      elseof OldY then NewY in
                         {Dictionary.remove @Permanents Reg}
                         Emitter, AllocatePerm(Reg ?NewY)
                         Emitter, Emit(move(OldY NewY))
                      end
                      case {Dictionary.get @Permanents Reg} of _#I then
                         {@RegOpt set(I Index)}
                      end
                      {Dictionary.put @NamedYs Index PrintName}
                   end
                end
                if D then X1 X2 in
                   case Emitter, GetTemp(Reg $) of none then
                      case Emitter, GetPerm(Reg $) of none then
                         Emitter, PredictTemp(Reg ?X1)
                         Emitter, Emit(createVariable(X1))
                      elseof Y then
                         X1 = TempX1
                         Emitter, Emit(move(Y X1))
                      end
                   elseof X then
                      X1 = X
                   end
                   X2 = TempX2
                   Emitter, Emit(putConstant(PrintName X2))
                   Emitter, Emit(callBI('Value.nameVariable' [X1 X2]#nil))
                end
             end}
         [] vClear(_ Regs _) then
            if @continuations \= nil then
               {ForAll Regs
                proc {$ Reg}
                   case Emitter, GetPerm(Reg $) of Y=y(_) then
                      if Emitter, IsLast(Reg $) then skip
                      else Y2 in
                         {Dictionary.remove @Permanents Reg}
                         Emitter, AllocatePerm(Reg ?Y2)
                         Emitter, Emit(move(Y Y2))
                      end
                      Emitter, Emit(clear(Y))
                   [] g(_) then skip   % see PR#995
                   end
                end}
            end
         [] vUnify(_ Reg1 Reg2 _) then IsLast1 IsLast2 in
            %% X1 X2 Y1 Y2 L1 L2
            %% -- -- -- -- -- --
            %% 0  0  0  0  0  0  createVariable(R1)
            %% ?  ?  1  1  ?  ?  unify(Y1 Y2)
            %% ?  1  1  0  ?  ?  unify(Y1 X2)
            %% 1  ?  0  1  ?  ?  unify(X1 Y2)
            %% 1  1  0  0  ?  ?  unify(X1 X2)
            %%
            %% 0  0  0  1  0  ?  move(Y2 R1)
            %% 0  0  1  0  ?  0  move(Y1 R2)
            %% 0  1  0  ?  0  0  move(X2 R1)
            %% 1  0  ?  0  0  0  move(X1 R2)
            %%
            %% 0  1  ?  ?  0  1  TransferTemp(Reg2 Reg1)
            %% 1  0  ?  ?  1  0  TransferTemp(Reg1 Reg2)
            Emitter, IsLast(Reg1 ?IsLast1)
            Emitter, IsLast(Reg2 ?IsLast2)
            case Emitter, GetReg(Reg1 $) of none then
               case Emitter, GetReg(Reg2 $) of none then
                  if IsLast1 then skip
                  elseif IsLast2 then skip
                  else R1 in
                     Emitter, PredictReg(Reg1 ?R1)
                     Emitter, Emit(createVariable(R1))
                  end
               else skip
               end
            elseof R1 then
               case Emitter, GetReg(Reg2 $) of none then skip
               elseof R2 then
                  Emitter, Unify(R1 R2)
               end
            end
            case Emitter, GetTemp(Reg1 $) of none then
               case Emitter, GetTemp(Reg2 $) of none then
                  case Emitter, GetPerm(Reg1 $) of none then
                     case Emitter, GetPerm(Reg2 $) of none then skip
                     elseof YG2 then R1 in
                        Emitter, PredictReg(Reg1 ?R1)
                        Emitter, Emit(move(YG2 R1))
                     end
                  elseof YG1 then
                     case Emitter, GetPerm(Reg2 $) of none then R2 in
                        Emitter, PredictReg(Reg2 ?R2)
                        Emitter, Emit(move(YG1 R2))
                     else skip
                     end
                  end
               elseof X2 then
                  if IsLast1 then skip
                  elseif IsLast2 then skip
                  elsecase Emitter, GetPerm(Reg1 $) of none then R1 in
                     Emitter, PredictReg(Reg1 ?R1)
                     Emitter, Emit(move(X2 R1))
                  else skip
                  end
               end
            elseof X1 then
               case Emitter, GetTemp(Reg2 $) of none then
                  if IsLast1 then skip
                  elseif IsLast2 then skip
                  elsecase Emitter, GetPerm(Reg2 $) of none then R2 in
                     Emitter, PredictReg(Reg2 ?R2)
                     Emitter, Emit(move(X1 R2))
                  else skip
                  end
               else skip
               end
            end
            case Emitter, GetTemp(Reg1 $) of none then
               case Emitter, GetTemp(Reg2 $) of none then skip
               elseif IsLast1 then skip
               elseif IsLast2 then
                  Emitter, TransferTemp(Reg2 Reg1)
               end
            else
               case Emitter, GetTemp(Reg2 $) of none then
                  if IsLast2 then skip
                  elseif IsLast1 then
                     Emitter, TransferTemp(Reg1 Reg2)
                  end
               else skip
               end
            end
         [] vEquateConstant(_ Constant Reg Cont) then
            case Emitter, GetReg(Reg $) of none then
               if self.controlFlowInfoSwitch then R in
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
                  {Dictionary.put @Permanents Reg ThisAddr}
               end
            elseof R then
               if {IsNumber Constant} then
                  Emitter, Emit(getNumber(Constant R))
               elseif {IsLiteral Constant} then
                  Emitter, Emit(getLiteral(Constant R))
               else R2 in
                  Emitter, AllocateShortLivedReg(?R2)
                  Emitter, Emit(putConstant(Constant R2))
                  Emitter, Unify(R R2)
               end
            end
         [] vEquateRecord(_ Literal RecordArity Reg VArgs Cont) then
            if Emitter, TryToUseAsSendMsg(ThisAddr Reg Literal RecordArity
                                          VArgs Cont $)
            then skip
            else Regs in
               {GetRegs VArgs ?Regs nil}
               case Emitter, GetReg(Reg $) of none andthen {Member Reg Regs}
               then R in
                  Emitter, PredictReg(Reg ?R)
                  Emitter, Emit(createVariable(R))
               else skip
               end
               case Emitter, GetReg(Reg $) of none then
                  if Emitter, IsLast(Reg $) then skip
                  else R in
                     Emitter, PredictReg(Reg ?R)
                     Emitter, EmitRecordWrite(Literal RecordArity R
                                              {FilterNonlinearRegs Regs} VArgs)
                  end
               elseof R then
                  Emitter, EmitRecordRead(Literal RecordArity R
                                          {FilterNonlinearRegs Regs} VArgs)
               end
            end
         [] vGetVariable(_ Reg _) then
            case Emitter, GetReg(Reg $) of none then skip
            else Emitter, FreeReg(Reg)
            end
            if Emitter, IsLast(Reg $) then
               Emitter, Emit(getVoid(1))
            else R in
               Emitter, PredictReg(Reg ?R)
               Emitter, Emit(getVariable(R))
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
               of vTestBool(_ !Reg Addr1 Addr2 _ Coord NewCont) then
                  if {Not self.controlFlowInfoSwitch}
                     andthen Emitter, IsFirst(Reg $)
                     andthen Emitter, DoesNotOccurIn(Reg Addr1 $)
                     andthen Emitter, DoesNotOccurIn(Reg Addr2 $)
                     andthen Emitter, DoesNotOccurIn(Reg NewCont $)
                  then
                     TestCont =
                     case Builtinname of 'Value.\'==\'' then
                        [Reg1 Reg2 _] = Regs
                     in
                        case {Dictionary.condGet @Permanents Reg1 none}
                        of vEquateConstant(_ Constant _ _)
                           andthen ({IsNumber Constant} orelse
                                    {IsLiteral Constant})
                        then
                           vTestConstant(OccsRS Reg2 Constant Addr1 Addr2
                                         Coord NewCont)
                        elsecase {Dictionary.condGet @Permanents Reg2 none}
                        of vEquateConstant(_ Constant _ _)
                           andthen ({IsNumber Constant} orelse
                                    {IsLiteral Constant})
                        then
                           vTestConstant(OccsRS Reg1 Constant Addr1 Addr2
                                         Coord NewCont)
                        else ~1
                        end
                     [] 'Value.\'\\=\'' then [Reg1 Reg2 _] = Regs in
                        case {Dictionary.condGet @Permanents Reg1 none}
                        of vEquateConstant(_ Constant _ _)
                           andthen ({IsNumber Constant} orelse
                                    {IsLiteral Constant})
                        then
                           vTestConstant(OccsRS Reg2 Constant Addr2 Addr1
                                         Coord NewCont)
                        elsecase {Dictionary.condGet @Permanents Reg2 none}
                        of vEquateConstant(_ Constant _ _)
                           andthen ({IsNumber Constant} orelse
                                    {IsLiteral Constant})
                        then
                           vTestConstant(OccsRS Reg1 Constant Addr2 Addr1
                                         Coord NewCont)
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
                                     NewCont)
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
            else XsIn XsOut Unifies in
               Emitter, AllocateBuiltinArgs(Regs BIInfo.imods ?XsIn
                                            ?XsOut ?Unifies)
               Emitter, DebugEntry(Coord 'call')
               Emitter, Emit(callBI(Builtinname XsIn#XsOut))
               Emitter, EmitUnifies(Unifies)
               Emitter, DebugExit(Coord 'call')
            end
         [] vCallGlobal(_ Reg Regs Coord _) then
            case Emitter, GetReg(Reg $) of g(_) then Instr R in
               Instr = callGlobal(R {Length Regs} * 2)
               Emitter, GenericEmitCall(any Reg Regs Instr R _ Coord nil)
            else Instr R Arity Which in
               Instr = call(R Arity)
               Which = case @continuations of nil then non_y   % tailCall
                       else any
                       end
               Emitter, GenericEmitCall(Which Reg Regs Instr R Arity Coord nil)
            end
         [] vCallMethod(_ Reg Literal RecordArity Regs Coord _) then Instr R in
            Instr = callMethod(cmi(R Literal false RecordArity) 0)
            Emitter, GenericEmitCall(any Reg Regs Instr R _ Coord nil)
         [] vCall(_ Reg Regs Coord _) then Instr R Arity Which in
            Instr = call(R Arity)
            Which = case @continuations of nil then non_y   % tailCall
                    else any
                    end
            Emitter, GenericEmitCall(Which Reg Regs Instr R Arity Coord nil)
         [] vConsCall(_ Reg Regs Coord _) then Instr R Arity Which in
            Instr = consCall(R Arity)
            Which = case @continuations of nil then non_y   % tailCall
                    else any
                    end
            Emitter, GenericEmitCall(Which Reg Regs Instr R Arity Coord nil)
         [] vDeconsCall(_ Reg1 Reg2 Reg3 Coord _) then Instr R Which in
            Instr = deconsCall(R)
            Which = case @continuations of nil then non_y   % tailCall
                    else any
                    end
            Emitter, GenericEmitCall(Which Reg1 [Reg2 Reg3]
                                     Instr R _ Coord nil)
         [] vCallProcedureRef(_ ProcedureRef Regs Coord _) then Instr in
            Instr = callProcedureRef(ProcedureRef {Length Regs} * 2)
            Emitter, GenericEmitCall(none ~1 Regs Instr _ _ Coord nil)
         [] vCallConstant(_ Constant Regs Coord _) then Instr in
            Instr = callConstant(Constant {Length Regs} * 2)
            Emitter, GenericEmitCall(none ~1 Regs Instr _ _ Coord nil)
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
         [] vInlineAt(_ Feature Reg _) then
            case Emitter, GetReg(Reg $) of none then X in
               Emitter, PredictBuiltinOutput(Reg ?X)
               Emitter, Emit(inlineAt(Feature X cache))
            elseof R then X in
               Emitter, AllocateShortLivedTemp(?X)
               Emitter, Emit(inlineAt(Feature X cache))
               Emitter, Emit(unify(X R))
            end
         [] vInlineAssign(_ Feature Reg _) then X in
            Emitter, AllocateAndInitializeAnyTemp(Reg ?X)
            Emitter, Emit(inlineAssign(Feature X cache))
         [] vGetSelf(_ Reg _) then
            case Emitter, GetReg(Reg $) of none then
               if Emitter, IsLast(Reg $) then skip
               else
                  {Dictionary.put @Permanents Reg ThisAddr}
               end
            elseof R then X in
               Emitter, AllocateShortLivedTemp(?X)
               Emitter, Emit(getSelf(X))
               Emitter, Emit(unify(X R))
            end
         [] vSetSelf(_ Reg _) then
            case Emitter, GetPerm(Reg $) of G=g(_) then
               Emitter, Emit(setSelf(G))
            end
         [] vDefinition(_ Reg PredId ProcedureRef GRegs Code _) then
            if Emitter, IsFirst(Reg $) andthen Emitter, IsLast(Reg $)
               andthen ProcedureRef == unit
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
                                        ProcedureRef Rs Code1))
               Emitter, Emit(endDefinition(StartLabel))
               {ForAll Code2 proc {$ Instr} Emitter, Emit(Instr) end}
               Emitter, Emit(lbl(ContLabel))
               if DoUnify then
                  Emitter, Emit(unify(X Emitter, GetReg(Reg $)))
               end
            end
         [] vDefinitionCopy(_ Reg1 Reg2 PredId ProcedureRef GRegs Code _) then
            if Emitter, IsFirst(Reg2 $) andthen Emitter, IsLast(Reg2 $)
               andthen ProcedureRef == unit
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
                                            ProcedureRef Rs Code1))
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
            Label1 RS RegMap1 OldLocalEnvsInhibited RegMap2
         in
            Emitter, newLabel(?Label1)
            case Addr2 of nil then
               case Cont of nil then
                  case @continuations of Cont1|_ then RS = Cont1.1
                  [] nil then RS = {BitArray.new 0 0}
                  end
               else RS = Cont.1
               end
            else
               case Cont of nil then RS = Addr2.1
               else
                  RS = {BitArray.clone Addr2.1}
                  case @continuations of Cont1|_ then
                     {BitArray.disj RS Cont1.1}
                  [] nil then skip
                  end
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
         [] vPopEx(_ Coord _) then
            Emitter, DebugExit(Coord 'exception handler')
            Emitter, Emit(popEx)
         [] vTestBool(_ Reg Addr1 Addr2 Addr3 Coord _) then
            HasLocalEnv R Dest2 Dest3 RegMap1 RegMap2 RegMap3
         in
            Emitter, MayAllocateEnvLocally(?HasLocalEnv)
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
            Emitter, Emit(testBool(R Dest2 Dest3))
            Emitter, SaveAllRegisterMappings(?RegMap1)
            Emitter, EmitAddrInLocalEnv(Addr1 HasLocalEnv)
            Emitter, RestoreAllRegisterMappings(RegMap1)
            Emitter, Dereference(Addr2 ?Dest2)
            Emitter, SaveAllRegisterMappings(?RegMap2)
            Emitter, EmitAddrInLocalEnv(Addr2 HasLocalEnv)
            Emitter, RestoreAllRegisterMappings(RegMap2)
            Emitter, Dereference(Addr3 ?Dest3)
            Emitter, SaveAllRegisterMappings(?RegMap3)
            Emitter, EmitAddrInLocalEnv(Addr3 HasLocalEnv)
            Emitter, RestoreAllRegisterMappings(RegMap3)
         [] vTestBuiltin(_ Builtinname Regs Addr1 Addr2 _) then
            HasLocalEnv Dest2 BIInfo XsIn XsOut RegMap1 RegMap2
         in
            Emitter, MayAllocateEnvLocally(?HasLocalEnv)
            BIInfo = {Builtins.getInfo Builtinname}
            Emitter, AllocateBuiltinArgs(Regs BIInfo.imods ?XsIn ?XsOut nil)
            Emitter, Emit(testBI(Builtinname XsIn#XsOut Dest2))
            Emitter, SaveAllRegisterMappings(?RegMap1)
            Emitter, EmitAddrInLocalEnv(Addr1 HasLocalEnv)
            Emitter, RestoreAllRegisterMappings(RegMap1)
            Emitter, Dereference(Addr2 ?Dest2)
            Emitter, SaveAllRegisterMappings(?RegMap2)
            Emitter, EmitAddrInLocalEnv(Addr2 HasLocalEnv)
            Emitter, RestoreAllRegisterMappings(RegMap2)
         [] vTestConstant(_ Reg Constant Addr1 Addr2 Coord _) then
            HasLocalEnv R Dest2 InstrLabel RegMap1 RegMap2
         in
            Emitter, MayAllocateEnvLocally(?HasLocalEnv)
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
            Emitter, Dereference(Addr2 ?Dest2)
            Emitter, SaveAllRegisterMappings(?RegMap2)
            Emitter, EmitAddrInLocalEnv(Addr2 HasLocalEnv)
            Emitter, RestoreAllRegisterMappings(RegMap2)
         [] vMatch(_ Reg Addr VHashTableEntries Coord _) then
            HasLocalEnv R Dest NewVHashTableEntries RegMap
         in
            Emitter, MayAllocateEnvLocally(?HasLocalEnv)
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
            Emitter, Emit(match(R ht(Dest NewVHashTableEntries)))
            NewVHashTableEntries =
            {Map VHashTableEntries
             proc {$ VHashTableEntry ?NewEntry} Addr Dest RegMap in
                case VHashTableEntry of onScalar(X A) then
                   Addr = A
                   NewEntry = onScalar(X Dest)
                [] onRecord(X1 X2 A) then
                   Addr = A
                   NewEntry = onRecord(X1 X2 Dest)
                end
                Emitter, Dereference(Addr ?Dest)
                Emitter, SaveAllRegisterMappings(?RegMap)
                Emitter, EmitAddrInLocalEnv(Addr HasLocalEnv)
                Emitter, RestoreAllRegisterMappings(RegMap)
             end}
            Emitter, Dereference(Addr ?Dest)
            Emitter, SaveAllRegisterMappings(?RegMap)
            Emitter, EmitAddrInLocalEnv(Addr HasLocalEnv)
            Emitter, RestoreAllRegisterMappings(RegMap)
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
            Emitter, newLabel(?Dest)
            Emitter, Emit(lockThread(Dest X))
         [] vLockEnd(_ Coord Cont Dest) then
            Emitter, DoInits(nil Cont)
            Emitter, KillAllTemporaries()
            Emitter, Emit(return)
            Emitter, Emit(lbl(Dest))
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
            Emitter, Emit(debugExit(FileName Line Column
                                    {VirtualString.toAtom Comment#'/'#Kind}))
         end
      end

      meth Unify(R1 R2)
         case R1 of x(_) then
            Emitter, Emit(unify(R1 R2))
         elsecase R2 of x(_) then
            Emitter, Emit(unify(R2 R1))
         else X in
            Emitter, AllocateShortLivedTemp(?X)
            Emitter, Emit(move(R1 X))
            Emitter, Emit(unify(X R2))
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
         if self.controlFlowInfoSwitch then false
         elseif Arity >= {Property.get 'limits.bytecode.xregisters'} then false
         elseif Emitter, IsFirst(Reg $) then
            if {OccursInVArgs VArgs Reg} then false
            elsecase Cont of vCall(_ ObjReg [!Reg] Coord Cont2) then
               if Emitter, DoesNotOccurIn(Reg Cont2 $) then
                  Emitter, EmitSendMsg(ObjReg Literal RecordArity
                                       VArgs Coord Cont2)
                  true
               else false
               end
            [] vCallGlobal(_ ObjReg [!Reg] Coord Cont2) then
               if Emitter, DoesNotOccurIn(Reg Cont2 $) then
                  Emitter, EmitSendMsg(ObjReg Literal RecordArity
                                       VArgs Coord Cont2)
                  true
               else false
               end
            [] vCallBuiltin(_ 'Object.new' [ClassReg !Reg ObjReg] Coord Cont2)
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
                if {Dictionary.member @UsedX I - 1} then R in
                   Emitter, AllocateShortLivedReg(?R)
                   Emitter, EmitRecordWrite(Literal RecordArity R
                                            {GetNonlinearRegs VArgs} VArgs)
                   (~I|Regs)#((I - 1)#move(R x(I - 1))|ArgInits)
                else X in
                   Emitter, AllocateThisShortLivedTemp(I - 1 ?X)
                   Emitter, EmitRecordWrite(Literal RecordArity X
                                            {GetNonlinearRegs VArgs} VArgs)
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
             proc {$ Reg}
                %% We have to be careful not to emit any delayed initialization
                %% too soon, so we do not use GetTemp/GetPerm here:
                case {Dictionary.condGet @Temporaries Reg none} of none then
                   case {Dictionary.condGet @Permanents Reg none} of none then
                      skip   % 1)
                   elseif {Member Reg Regs} then   % 4)
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
                [] X=x(_) then
                   case Emitter, GetPerm(Reg $) of none then Y in   % 2)
                      Emitter, AllocatePerm(Reg ?Y)
                      Emitter, Emit(move(X Y))
                   else skip   % 3)
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
            %% The abstraction is not referenced by a register.
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
         if self.controlFlowInfoSwitch then
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
         Emitter, KillAllTemporaries()
         %--** here we should let unused registers die
      end
      meth SetArguments(TheArity ArgInits Regs)
         %%
         %% Regs is the list of argument registers to a call instruction.
         %% This method issues move instructions that place these registers
         %% into x(0), ..., x(TheArity - 1).
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
         %% and corresponding moves are emitted (respecting cycles).
         %%
         Emitter, EnterDelayedInits(ArgInits)
         Arity <- TheArity
         {List.forAllTailInd Regs
          proc {$ Position Reg|Regr} I = Position - 1 in
             if {Dictionary.member @DelayedInitsDict I} then
                if Reg >= 0 then
                   {BitArray.set @LastAliveRS Reg}
                end
             else Instr in
                case {Dictionary.condGet @Permanents Reg none}
                of vEquateConstant(_ Constant _ _) then   % 1)
                   putConstant(Constant x(I))
                [] vGetSelf(_ _ _) then   % 1)
                   getSelf(x(I))
                elsecase Emitter, GetTemp(Reg $) of x(!I) then
                   %% Optimize the special case that the register
                   %% already is located in its destination.
                   'skip'
                elseof X then
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
          end}
         %%
         %% Perform the depth-first search of the graph:
         %%
         Emitter, ConfigureXBank()
      end
      meth ConfigureXBank()
         CurrentID <- 0
         Stack <- nil
         {For 0 @Arity - 1 1
          proc {$ I}
             if {Dictionary.member @DoneDict I} then skip
             else Emitter, OrderMoves(I _)
             end
          end}
         {For 0 @Arity - 1 1
          proc {$ I}
             case {Dictionary.condGet @DelayedInitsDict I 'skip'}
             of move(_ _) then skip
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
               Instr = {Dictionary.condGet @DelayedInitsDict I 'skip'}
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

      meth EmitRecordWrite(Literal RecordArity R NonlinearRegs VArgs)
         case {HoistRecord self.state Literal RecordArity VArgs}
         of constant(Constant) then
            Emitter, Emit(putConstant(Constant R))
         [] record(Literal RecordArity VArgs) then
            Emitter, EmitRecordWriteSub(Literal RecordArity R
                                        NonlinearRegs VArgs)
         end
      end
      meth EmitRecordWriteSub(Literal RecordArity R NonlinearRegs VArgs)
         NewVArgs
      in
         %% Emit in write mode, i.e., bottom-up and using `set':
         Emitter, EmitSubRecordWrites(VArgs NonlinearRegs ?NewVArgs)
         Emitter, Emit(putRecord(Literal RecordArity R))
         Emitter, EmitVArgsWrite(NewVArgs NonlinearRegs)
      end
      meth EmitSubRecordWrites(VArgs NonlinearRegs $)
         case VArgs of VArg|VArgr then
            case VArg of record(Literal RecordArity VArgs) then R in
               Emitter, EmitRecordWriteSub(Literal RecordArity R
                                           NonlinearRegs VArgs)
               reg(R)
            else VArg
            end|Emitter, EmitSubRecordWrites(VArgr NonlinearRegs $)
         [] nil then nil
         end
      end
      meth EmitVArgsWrite(VArgs NonlinearRegs)
         case VArgs of VArg|VArgr then
            case VArg of constant(Constant) then
               Emitter, Emit(setConstant(Constant))
            [] procedureRef(ProcedureRef) then
               Emitter, Emit(setProcedureRef(ProcedureRef))
            [] value(Reg) then
               case Emitter, GetReg(Reg $) of none then
                  if Emitter, IsLast(Reg $)
                     andthen {Not {Member Reg NonlinearRegs}}
                  then
                     Emitter, Emit(setVoid(1))
                  else R in
                     Emitter, PredictReg(Reg ?R)
                     Emitter, Emit(setVariable(R))
                  end
               elseof R then
                  Emitter, Emit(setValue(R))
               end
            [] reg(R) then
               Emitter, AllocateShortLivedReg(?R)
               Emitter, Emit(setValue(R))
            end
            Emitter, EmitVArgsWrite(VArgr NonlinearRegs)
         [] nil then skip
         end
      end
      meth EmitRecordRead(Literal RecordArity R NonlinearRegs VArgs)
         %%--** if the record can be hoisted, is it better to
         %% putConstant/unify it or to emit it in read mode?
         SubRecords
      in
         %% Emit in read mode, i.e., top-down and using `unify':
         Emitter, Emit(getRecord(Literal RecordArity R))
         Emitter, EmitVArgsRead(VArgs NonlinearRegs ?SubRecords nil)
         {ForAll SubRecords
          proc {$ R#record(Literal RecordArity VArgs)}
             Emitter, EmitRecordRead(Literal RecordArity R NonlinearRegs VArgs)
          end}
      end
      meth EmitVArgsRead(VArgs NonlinearRegs SHd STl)
         case VArgs of VArg|VArgr then SInter in
            case VArg of constant(Constant) then
               SHd = SInter
               if {IsNumber Constant} then
                  Emitter, Emit(unifyNumber(Constant))
               elseif {IsLiteral Constant} then
                  Emitter, Emit(unifyLiteral(Constant))
               else R in
                  Emitter, AllocateShortLivedReg(?R)
                  Emitter, Emit(putConstant(Constant R))
                  Emitter, Emit(unifyValue(R))
               end
            [] value(Reg) then
               SHd = SInter
               case Emitter, GetReg(Reg $) of none then
                  if Emitter, IsLast(Reg $)
                     andthen {Not {Member Reg NonlinearRegs}}
                  then
                     Emitter, Emit(unifyVoid(1))
                  else R in
                     Emitter, PredictReg(Reg ?R)
                     Emitter, Emit(unifyVariable(R))
                  end
               elseof R then
                  Emitter, Emit(unifyValue(R))
               end
            [] record(_ _ _) then R in
               Emitter, AllocateShortLivedReg(?R)
               Emitter, Emit(unifyVariable(R))
               SHd = R#VArg|SInter
            end
            Emitter, EmitVArgsRead(VArgr NonlinearRegs SInter STl)
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
      meth Dereference(Addr ?DestLabel)
         case Addr of vShared(_ _ Label _) then
            Emitter, DereferenceSub(Label ?DestLabel)
         [] nil then
            case @continuations of vShared(_ _ Label _)|_ then
               Emitter, DereferenceSub(Label ?DestLabel)
            [] nil then skip
            end
         else skip
         end
         if {IsFree DestLabel} then
            Emitter, newLabel(?DestLabel)
            Emitter, Emit(lbl(DestLabel))
         end
      end
      meth DereferenceSub(Label ?DestLabel)
         case {Dictionary.condGet @sharedDone Label unit} of unit then skip
         [] Ts#Ps then
            if {All {Dictionary.entries Ts}
                fun {$ Reg#X}
                   {Dictionary.condGet @Temporaries Reg none} == X
                end} andthen
               {All {Dictionary.keys Ps}
                fun {$ Reg}
                   {Dictionary.member @Permanents Reg}
                end}
            then
               DestLabel = Label
            end
         end
      end
      meth DeallocateAndReturn()
         Emitter, Emit(deAllocateL(@LocalEnvSize))
         Emitter, Emit(return)
      end
      meth MayAllocateEnvLocally($)
         false
/*--**
         if @LocalEnvsInhibited then false
         elseif self.controlFlowInfoSwitch then false
         elseif self.staticVarnamesSwitch then false
         elseif @continuations == nil andthen {@RegOpt isEmpty($)} then
            %% This means that in a conditional, local environments may be
            %% allocated per branch instead of for the procedure as a whole.
            @LocalEnvSize = 0   % cancel preceding allocateL instruction
            true
         else false
         end
*/
      end
      meth EmitAddrInLocalEnv(Addr HasLocalEnv)
         %% A call to this method must always be followed by a call to
         %% either RestoreRegisterMapping or RestoreAllRegisterMappings;
         %% else the attributes Permanents and UsedY do not contain the
         %% correct values.
         if HasLocalEnv then OldLocalEnvSize NumberOfYs in
            OldLocalEnvSize = @LocalEnvSize
            LocalEnvSize <- NumberOfYs
            case Addr of vShared(OccsRS InitsRS Label Addr2) then
               Emitter, LetDie(Addr)
               Emitter, EmitShared(OccsRS InitsRS Label Addr2
                                   allocateL(NumberOfYs))
            else
               Emitter, Emit(allocateL(NumberOfYs))
               Emitter, EmitAddr(Addr)
            end
            {@RegOpt optimize(?NumberOfYs)}
            RegOpt <- {New RegisterOptimizer init()}
            LocalEnvSize <- OldLocalEnvSize
         else OldLocalEnvsInhibited in
            OldLocalEnvsInhibited = @LocalEnvsInhibited
            LocalEnvsInhibited <- true
            Emitter, EmitAddr(Addr)
            LocalEnvsInhibited <- OldLocalEnvsInhibited
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
            [] nil then true
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

      meth GetReg(Reg ?R)
         %% Return Reg's permanent, if it has one; else return Reg's temporary
         %% or 'none'.  If it has a delayed initialization, emit this, deciding
         %% from the continuation which register to allocate it to.
         case {Dictionary.condGet @Permanents Reg none} of none then
            if Reg < @minReg then I in
               I = @HighestUsedG + 1
               HighestUsedG <- I
               {Dictionary.put @GRegRef I Reg}
               {Dictionary.put @Permanents Reg R=g(I)}
            else
               R = {Dictionary.condGet @Temporaries Reg none}
            end
         [] (Y=y(_))#_ then R = Y
         [] G=g(_) then R = G
         elseof Result then
            {Dictionary.remove @Permanents Reg}
            case Result of vGetSelf(_ _ _) then
               Emitter, PredictTemp(Reg ?R)
            else
               Emitter, PredictReg(Reg ?R)
            end
            Emitter, EmitInitialization(Result R)
         end
      end
      meth GetPerm(Reg ?YG)
         %% Return Reg's permanent, if it has one, or 'none'.  If it has a
         %% delayed initialization that can have a permanent as destination,
         %% emit this, allocating a permanent for it.
         case {Dictionary.condGet @Permanents Reg none} of none then
            if Reg < @minReg then I in
               I = @HighestUsedG + 1
               HighestUsedG <- I
               {Dictionary.put @GRegRef I Reg}
               {Dictionary.put @Permanents Reg YG=g(I)}
            else YG = none
            end
         [] (Y=y(_))#_ then YG = Y
         [] G=g(_) then YG = G
         [] vGetSelf(_ _ _) then YG = none
         elseof Result then
            {Dictionary.remove @Permanents Reg}
            Emitter, AllocatePerm(Reg ?YG)
            Emitter, EmitInitialization(Result YG)
         end
      end
      meth GetTemp(Reg ?X)
         %% Return Reg's temporary, if it has one, or 'none'.  If it has a
         %% delayed initialization, emit this, allocating a temporary for it.
         case {Dictionary.condGet @Permanents Reg none} of none then
            X = {Dictionary.condGet @Temporaries Reg none}
         [] y(_)#_ then
            X = {Dictionary.condGet @Temporaries Reg none}
         [] g(_) then
            X = {Dictionary.condGet @Temporaries Reg none}
         elseof Result then
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
            {Dictionary.put @UsedX I true}
         elseof X0 then X = X0
         end
      end
      meth SpillTemporary(?I)
         I = @LowestFreeX
         if I >= {Property.get 'limits.bytecode.xregisters'} then
            {self.reporter
             error(kind: 'code generation limitation'
                   msg: 'expression too complex; registers exhausted')}
            {Exception.raiseError compiler(internal spillTemporary)}
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
         {Dictionary.put @UsedX I true}
      end
      meth AllocateShortLivedReg(?R)
         if @LowestFreeX >= {Property.get 'limits.bytecode.xregisters'} then
            %% no more temporaries available
            Emitter, AllocateShortLivedPerm(?R)
         else
            Emitter, AllocateShortLivedTemp(?R)
         end
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
         {Dictionary.put @UsedX I true}
         X = x(I)
         ShortLivedTemps <- X|@ShortLivedTemps
      end
      meth AllocateShortLivedPerm(?Y) Is I in
         Is = {FoldR {Dictionary.items @Permanents}
               fun {$ YG In}
                  case YG of _#I then I|In else In end
               end @ShortLivedPerms}
         {@RegOpt decl(Is ?Y ?I)}
         ShortLivedPerms <- I|@ShortLivedPerms
\ifdef DEBUG_OPTIMIZER
         {System.show allocatedShortLivedPerm(I)}
\endif
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
      meth AllocatePerm(Reg ?Y)
         case Emitter, GetPerm(Reg $) of none then Is I in
            Is = {FoldR {Dictionary.items @Permanents}
                  fun {$ YG In}
                     case YG of _#I then I|In else In end
                  end @ShortLivedPerms}
            {@RegOpt decl(Is ?Y ?I)}
\ifdef DEBUG_OPTIMIZER
            {System.show allocatedPerm(Reg I)}
\endif
            {Dictionary.put @Permanents Reg Y#I}
         elseof Y0 then Y = Y0
         end
      end
      meth TransferTemp(Reg1 Reg2)
         {Dictionary.put @Temporaries Reg2
          {Dictionary.get @Temporaries Reg1}}
         {Dictionary.remove @Temporaries Reg1}
      end
      meth FreeReg(Reg)
         case {Dictionary.condGet @Temporaries Reg none} of x(I) then
            {Dictionary.remove @Temporaries Reg}
            Emitter, FreeX(I)
         [] none then skip
         end
         {Dictionary.remove @Permanents Reg}
      end
      meth FreeX(I)
         {Dictionary.remove @UsedX I}
         if I < @LowestFreeX then
            LowestFreeX <- I
         end
      end

      meth PredictBuiltinOutput(Reg ?X)
         %% Here we try to determine whether it would improve
         %% register allocation to reuse one of the argument
         %% registers as the result register, if possible.
         case @continuations of nil then
            Emitter, AllocateShortLivedTemp(?X)
         [] Cont|_ then
            Emitter, LetDie(Cont)
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
         [] vMakePermanent(_ RegIndices Cont2) then
            if {Some RegIndices fun {$ Reg0#_#_} Reg0 == Reg end} then
               Emitter, AllocateAnyTemp(Reg ?R)
            else
               Emitter, PredictRegSub(Reg Cont2 ?R)
            end
         [] vEquateConstant(_ Constant MessageReg Cont2)
            andthen {IsLiteral Constant}
         then
            %% Check whether this will be optimized into a sendMsg instruction.
            case Cont2 of vCall(_ Reg0 [!MessageReg] _ Cont3) then
               Emitter, PredictRegForCall(Reg Reg0 nil Cont3 ?R)
            elseof vCallGlobal(_ Reg0 [!MessageReg] _ Cont3) then
               Emitter, PredictRegForCall(Reg Reg0 nil Cont3 ?R)
            elseof vCallBuiltin(_ 'Object.new' [_ !MessageReg Reg0] _ Cont3)
            then
               Emitter, PredictRegForCall(Reg Reg0 nil Cont3 ?R)
            else
               Emitter, PredictRegSub(Reg Cont2 ?R)
            end
         [] vEquateRecord(_ _ _ MessageReg VArgs Cont2) then
            %% Check whether this will be optimized into a sendMsg instruction.
            case Cont2 of vCall(_ Reg0 [!MessageReg] _ Cont3) then
               Emitter, PredictRegForCall(Reg Reg0 VArgs Cont3 ?R)
            elseof vCallGlobal(_ Reg0 [!MessageReg] _ Cont3) then
               Emitter, PredictRegForCall(Reg Reg0 VArgs Cont3 ?R)
            elseof vCallBuiltin(_ 'Object.new' [_ !MessageReg Reg0] _ Cont3)
            then
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
         [] vCallGlobal(_ _ Regs _ Cont) then
            Emitter, PredictRegForCall(Reg ~1 Regs Cont ?R)
         [] vCallMethod(_ _ _ _ Regs _ Cont) then
            Emitter, PredictRegForCall(Reg ~1 Regs Cont ?R)
         [] vCall(_ Reg0 Regs _ Cont) then
            Emitter, PredictRegForCall(Reg Reg0 Regs Cont ?R)
         [] vConsCall(_ Reg0 Regs _ Cont) then
            Emitter, PredictRegForCall(Reg Reg0 Regs Cont ?R)
         [] vDeconsCall(_ Reg0 Reg1 Reg2 _ Cont) then
            Emitter, PredictRegForCall(Reg Reg0 [Reg1 Reg2] Cont ?R)
         [] vCallProcedureRef(_ _ Regs _ Cont) then
            Emitter, PredictRegForCall(Reg ~1 Regs Cont ?R)
         [] vCallConstant(_ _ Regs _ Cont) then
            Emitter, PredictRegForCall(Reg ~1 Regs Cont ?R)
         [] vShared(_ _ _ _) then
            Emitter, AllocateAnyTemp(Reg ?R)
         [] vExHandler(_ Addr _ _ _ Cont InitsRS) then
            Emitter, PredictRegForInits(Reg InitsRS [Addr Cont] ?R)
         [] vTestBool(_ _ Addr1 Addr2 Addr3 _ Cont) then Addrs in
            Addrs = [Addr1 Addr2 Addr3 Cont]
            Emitter, PredictRegForBranches(Addrs Reg ?R)
         [] vTestBuiltin(_ _ Regs Addr1 Addr2 Cont) then
            if {Member Reg Regs} then
               Emitter, AllocateAnyTemp(Reg ?R)
            else Addrs in
               Addrs = [Addr1 Addr2 Cont]
               Emitter, PredictRegForBranches(Addrs Reg ?R)
            end
         [] vTestConstant(_ _ _ Addr1 Addr2 _ Cont) then Addrs in
            Addrs = [Addr1 Addr2 Cont]
            Emitter, PredictRegForBranches(Addrs Reg ?R)
         [] vMatch(_ _ Addr VHashTableEntries _ Cont) then Addrs in
            Addrs = {FoldR VHashTableEntries
                     fun {$ VHashTableEntry In}
                        case VHashTableEntry of onScalar(_ Addr) then Addr|In
                        [] onRecord(_ _ Addr) then Addr|In
                        end
                     end [Addr Cont]}
            Emitter, PredictRegForBranches(Addrs Reg ?R)
         [] vLockThread(_ Reg0 _ Cont _) then
            if Reg == Reg0 then
               Emitter, AllocateAnyTemp(Reg ?R)
            else
               Emitter, PredictRegSub(Reg Cont ?R)
            end
         [] vLockEnd(_ _ Cont _) then
            Emitter, PredictPermReg(Reg Cont ?R)
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
         Emitter, FlushShortLivedRegs()
         {Dictionary.clone @Permanents}#
         {BitArray.clone @LastAliveRS}#@HighestUsedG
      end
      meth RestoreRegisterMapping(RegisterMapping)
         case RegisterMapping of
            OldPermanents#
            OldLastAliveRS#OldHighestUsedG
         then
            LastAliveRS <- OldLastAliveRS
            {Dictionary.removeAll @Permanents}
            Permanents <- OldPermanents
            {For OldHighestUsedG + 1 @HighestUsedG 1
             proc {$ I}
                {Dictionary.put @Permanents {Dictionary.get @GRegRef I} g(I)}
             end}
            Emitter, KillAllTemporaries()
         end
      end
      meth SaveAllRegisterMappings($)
         Emitter, FlushShortLivedRegs()
         {Dictionary.clone @Temporaries}#{Dictionary.clone @UsedX}#
         @LowestFreeX#
         {Dictionary.clone @Permanents}#
         {BitArray.clone @LastAliveRS}#@HighestUsedG
      end
      meth RestoreAllRegisterMappings(RegisterMapping)
         case RegisterMapping of
            OldTemporaries#OldUsedX#OldLowestFreeX#
            OldPermanents#
            OldLastAliveRS#OldHighestUsedG
         then
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
            LowestFreeX <- OldLowestFreeX
            ShortLivedTemps <- nil
            ShortLivedPerms <- nil
         end
      end
      meth KillAllTemporaries()
         {Dictionary.removeAll @Temporaries}
         {Dictionary.removeAll @UsedX}
         LowestFreeX <- 0
         ShortLivedTemps <- nil
         ShortLivedPerms <- nil
      end

      %%
      %% Emitting Instructions
      %%

      meth Emit(Instr) NewCodeTl in
\ifdef DEBUG_EMIT
         {System.printInfo 'Debug:'}
         {System.show Instr}
\endif
         @CodeTl = Instr|NewCodeTl
         CodeTl <- NewCodeTl
      end
   end
end
