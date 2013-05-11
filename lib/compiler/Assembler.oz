%%%
%%% Authors:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%   Ralf Scheidhauer <scheidhr@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997-2001
%%%   Ralf Scheidhauer, 1997
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

%%
%% This file defines the procedure `Assemble' which takes a list of
%% machine instructions, applies peephole optimizations and returns
%% an AssemblerClass object.  Its methods provide for the output,
%% feeding and loading of assembled machine code.
%%
%% Notes:
%% -- The code may contain no backward-only references to labels that
%%    are not reached during a forward-scan through the code.
%% -- The definition(...) and definitionCopy(...) instructions differ
%%    from the format expected by the assembler proper:  An additional
%%    argument stores the code for the definition's body.  This way,
%%    less garbage is produced during code generation.
%%

functor
import
\ifdef MOZART_1_ASSEMBLER
   System(printName)
   CompilerSupport
   Builtins(getInfo)
\else
   NewAssembler(assemble)
   CompilerSupport
\endif
export
   InternalAssemble
   Assemble
define
\ifdef MOZART_1_ASSEMBLER
   InstructionSizes = {CompilerSupport.getInstructionSizes}

   local
      local
         IsUniqueName           = CompilerSupport.isUniqueName
         IsCopyableName         = CompilerSupport.isCopyableName
         IsCopyableProcedureRef = CompilerSupport.isCopyableProcedureRef

         fun {ListToVirtualString Vs In FPToIntMap}
            case Vs of V|Vr then
               {ListToVirtualString Vr
                In#' '#{MyValueToVirtualString V FPToIntMap} FPToIntMap}
            [] nil then In
            end
         end

         fun {TupleSub I N In Value FPToIntMap}
            if I =< N then
               {TupleSub I + 1 N
                In#' '#{MyValueToVirtualString Value.I FPToIntMap}
                Value FPToIntMap}
            else In
            end
         end

         fun {TupleToVirtualString Value FPToIntMap}
            {TupleSub 2 {Width Value}
             {Label Value}#'('#{MyValueToVirtualString Value.1 FPToIntMap}
             Value FPToIntMap}#')'
         end

         fun {MyValueToVirtualString Val FPToIntMap}
            if {IsName Val} then
               case Val of true then 'true'
               [] false then 'false'
               [] unit then 'unit'
               elseif {IsUniqueName Val} then
                  %--** these only work if the name's print name is friendly
                  %--** and all names' print names are distinct
                  '<U: '#{System.printName Val}#'>'
               elseif {IsCopyableName Val} then
                  '<M: '#{System.printName Val}#'>'
               else
                  '<N: '#{System.printName Val}#'>'
               end
            elseif {IsAtom Val} then
               %% the atom must not be mistaken for a token
               if {HasFeature InstructionSizes Val} then '\''#Val#'\''
               else
                  case Val of lbl then '\'lbl\''
                  [] pid then '\'pid\''
                  [] ht then '\'ht\''
                  [] onScalar then '\'onScalar\''
                  [] onRecord then '\'onRecord\''
                  [] cmi then '\'cmi\''
                  [] pos then '\'pos\''
                  else
                     {Value.toVirtualString Val 0 0}
                  end
               end
            elseif {ForeignPointer.is Val} then I in
               %% foreign pointers are assigned increasing integers
               %% in order of appearance so that diffs are sensible
               I = {ForeignPointer.toInt Val}
               if {IsCopyableProcedureRef Val} then '<Q: '
               else '<P: '
               end#
               case {Dictionary.condGet FPToIntMap I unit} of unit then N in
                  N = {Dictionary.get FPToIntMap 0} + 1
                  {Dictionary.put FPToIntMap 0 N}
                  {Dictionary.put FPToIntMap I N}
                  N
               elseof V then
                  V
               end#'>'
            elsecase Val of V1|Vr then
               {ListToVirtualString Vr
                '['#{MyValueToVirtualString V1 FPToIntMap}
                FPToIntMap}#']'
            [] V1#V2 then
               {MyValueToVirtualString V1 FPToIntMap}#"#"#
               {MyValueToVirtualString V2 FPToIntMap}
            elseif {IsTuple Val} then
               {TupleToVirtualString Val FPToIntMap}
            else
               {Value.toVirtualString Val 1000 1000}
            end
         end
      in
         fun {InstrToVirtualString Instr FPToIntMap}
            if {IsAtom Instr} then
               Instr
            elsecase Instr of putConstant(C R) then
               'putConstant('#{Value.toVirtualString C 1000 1000}#' '#
               {MyValueToVirtualString R FPToIntMap}#')'
            [] setConstant(C R) then
               'setConstant('#{Value.toVirtualString C 1000 1000}#' '#
               {MyValueToVirtualString R FPToIntMap}#')'
            else
               {TupleToVirtualString Instr FPToIntMap}
            end
         end
      end
   in
      class AssemblerClass
         prop final
         attr InstrsHd InstrsTl LabelDict Size
         feat Profile controlFlowInfo
         meth init(ProfileSwitch ControlFlowInfoSwitch)
            InstrsHd <- 'skip'|@InstrsTl
            LabelDict <- {NewDictionary}
            Size <- InstructionSizes.'skip'
            %% Code must not start at address 0, since this is interpreted as
            %% NOCODE by the emulator - thus the dummy instruction 'skip'.
            self.Profile = ProfileSwitch
            self.controlFlowInfo = ControlFlowInfoSwitch
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
             proc {$ L#V}
                if {IsFree V} then
                   {Exception.raiseError compiler(assembler undeclaredLabel L)}
                end
             end}
         end
         meth append(Instr) NewTl in
            case Instr
            of definition(_ L _ _ _) then AssemblerClass, declareLabel(L)
            [] definitionCopy(_ L _ _ _) then AssemblerClass, declareLabel(L)
            [] endDefinition(L) then AssemblerClass, declareLabel(L)
            [] branch(L) then AssemblerClass, declareLabel(L)
            [] exHandler(L) then AssemblerClass, declareLabel(L)
            [] testBI(_ _ L) then AssemblerClass, declareLabel(L)
            [] testLT(_ _ _ L) then
               AssemblerClass, declareLabel(L)
            [] testLE(_ _ _ L) then
               AssemblerClass, declareLabel(L)
            [] testLiteral(_ _ L) then
               AssemblerClass, declareLabel(L)
            [] testNumber(_ _ L) then
               AssemblerClass, declareLabel(L)
            [] testBool(_ L1 L2) then
               AssemblerClass, declareLabel(L1)
               AssemblerClass, declareLabel(L2)
            [] testRecord(_ _ _ L) then
               AssemblerClass, declareLabel(L)
            [] testList(_ L) then
               AssemblerClass, declareLabel(L)
            [] match(_ HT) then ht(L Cases) = HT in
               AssemblerClass, declareLabel(L)
               {ForAll Cases
                proc {$ Case}
                   case Case
                   of onScalar(_ L) then AssemblerClass, declareLabel(L)
                   [] onRecord(_ _ L) then AssemblerClass, declareLabel(L)
                   end
                end}
            [] lockThread(L _) then AssemblerClass, declareLabel(L)
            else skip
            end
            @InstrsTl = Instr|NewTl
            InstrsTl <- NewTl
            Size <- @Size + InstructionSizes.{Label Instr}
            case Instr of definition(_ _ _ _ _) andthen self.Profile then
               AssemblerClass, append(profileProc)
            [] definitionCopy(_ _ _ _ _) andthen self.Profile then
               AssemblerClass, append(profileProc)
            else skip
            end
         end
         meth output($) AddrToLabelMap FPToIntMap in
            AssemblerClass, MarkEnd()
            AddrToLabelMap = {NewDictionary}
            FPToIntMap = {NewDictionary}
            {Dictionary.put FPToIntMap 0 0}
            {ForAll {Dictionary.entries @LabelDict}
             proc {$ Label#Addr}
                if {IsDet Addr} then
                   {Dictionary.put AddrToLabelMap Addr Label}
                end
             end}
            '%% Code Size:\n'#@Size#' % words\n'#
            AssemblerClass, OutputSub(@InstrsHd AddrToLabelMap FPToIntMap 0 $)
         end
         meth OutputSub(Instrs AddrToLabelMap FPToIntMap Addr ?VS)
            case Instrs of Instr|Ir then LabelVS NewInstr VSRest NewAddr in
               LabelVS = if {Dictionary.member AddrToLabelMap Addr} then
                            'lbl('#Addr#')'#
                            if Addr < 100 then '\t\t' else '\t' end
                         else '\t\t'
                         end
               AssemblerClass, TranslateInstrLabels(Instr ?NewInstr)
               VS = (LabelVS#{InstrToVirtualString NewInstr FPToIntMap}#'\n'#
                     VSRest)
               NewAddr = Addr + InstructionSizes.{Label Instr}
               AssemblerClass, OutputSub(Ir AddrToLabelMap FPToIntMap NewAddr
                                         ?VSRest)
            [] nil then
               VS = ""
            end
         end
         meth load(Globals $)
            AssemblerClass, MarkEnd()
            {CompilerSupport.storeInstructions
             @Size Globals @InstrsHd @LabelDict}
         end
         meth MarkEnd()
            @InstrsTl = nil
         end

         meth TranslateInstrLabels(Instr $)
            case Instr of definition(X1 L X2 X3 X4) then A in
               A = {Dictionary.get @LabelDict L}
               definition(X1 A X2 X3 X4)
            [] definitionCopy(X1 L X2 X3 X4) then A in
               A = {Dictionary.get @LabelDict L}
               definitionCopy(X1 A X2 X3 X4)
            [] endDefinition(L) then A in
               A = {Dictionary.get @LabelDict L}
               endDefinition(A)
            [] branch(L) then A in
               A = {Dictionary.get @LabelDict L}
               branch(A)
            [] exHandler(L) then A in
               A = {Dictionary.get @LabelDict L}
               exHandler(A)
            [] testBI(X1 X2 L) then A in
               A = {Dictionary.get @LabelDict L}
               testBI(X1 X2 A)
            [] testLT(X1 X2 X3 L) then A in
               A = {Dictionary.get @LabelDict L}
               testLT(X1 X2 X3 A)
            [] testLE(X1 X2 X3 L) then A in
               A = {Dictionary.get @LabelDict L}
               testLE(X1 X2 X3 A)
            [] testLiteral(X1 X2 L) then A in
               A = {Dictionary.get @LabelDict L}
               testLiteral(X1 X2 A)
            [] testNumber(X1 X2 L) then A in
               A = {Dictionary.get @LabelDict L}
               testNumber(X1 X2 A)
            [] testRecord(X1 X2 X3 L) then A in
               A = {Dictionary.get @LabelDict L}
               testRecord(X1 X2 X3 A)
            [] testList(X1 L) then A in
               A = {Dictionary.get @LabelDict L}
               testList(X1 A)
            [] testBool(X1 L1 L2) then A1 A2 in
               A1 = {Dictionary.get @LabelDict L1}
               A2 = {Dictionary.get @LabelDict L2}
               testBool(X1 A1 A2)
            [] match(X HT) then ht(L Cases) = HT A NewCases in
               A = {Dictionary.get @LabelDict L}
               NewCases = {Map Cases
                           fun {$ Case}
                              case Case of onScalar(X L) then A in
                                 A = {Dictionary.get @LabelDict L}
                                 onScalar(X A)
                              [] onRecord(X1 X2 L) then A in
                                 A = {Dictionary.get @LabelDict L}
                                 onRecord(X1 X2 A)
                              end
                           end}
               match(X ht(A NewCases))
            [] lockThread(L X) then A in
               A = {Dictionary.get @LabelDict L}
               lockThread(A X)
            else
               Instr
            end
         end
      end
   end

   fun {RecordArityWidth RecordArity}
      if {IsInt RecordArity} then RecordArity
      else {Length RecordArity}
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

   proc {SetVoids Instrs InI ?OutI ?Rest}
      case Instrs of I1|Ir then
         case I1 of setVoid(J) then
            {SetVoids Ir InI + J ?OutI ?Rest}
         else
            OutI = InI
            Rest = Instrs
         end
      [] nil then
         OutI = InI
         Rest = nil
      end
   end

   proc {UnifyVoids Instrs InI ?OutI ?Rest}
      case Instrs of I1|Ir then
         case I1 of unifyVoid(J) then
            {UnifyVoids Ir InI + J ?OutI ?Rest}
         else
            OutI = InI
            Rest = Instrs
         end
      [] nil then
         OutI = InI
         Rest = nil
      end
   end

   proc {GetVoids Instrs InI ?OutI ?Rest}
      case Instrs of I1|Ir then
         case I1 of getVoid(J) then
            {GetVoids Ir InI + J ?OutI ?Rest}
         else
            OutI = InI
            Rest = Instrs
         end
      [] nil then
         OutI = InI
         Rest = nil
      end
   end

   proc {MakeDeAllocate I Assembler}
      case I of 0 then skip
      [] 1 then {Assembler append(deAllocateL1)}
      [] 2 then {Assembler append(deAllocateL2)}
      [] 3 then {Assembler append(deAllocateL3)}
      [] 4 then {Assembler append(deAllocateL4)}
      [] 5 then {Assembler append(deAllocateL5)}
      [] 6 then {Assembler append(deAllocateL6)}
      [] 7 then {Assembler append(deAllocateL7)}
      [] 8 then {Assembler append(deAllocateL8)}
      [] 9 then {Assembler append(deAllocateL9)}
      [] 10 then {Assembler append(deAllocateL10)}
      else {Assembler append(deAllocateL)}
      end
   end

   fun {SkipDeadCode Instrs Assembler}
      case Instrs of I1|Rest then
         case I1 of lbl(I) andthen {Assembler isLabelUsed(I $)} then Instrs
         [] endDefinition(I) andthen {Assembler isLabelUsed(I $)} then Instrs
         [] globalVarname(_) then Instrs
         [] localVarname(_) then Instrs
         else {SkipDeadCode Rest Assembler}
         end
      [] nil then nil
      end
   end

   proc {EliminateDeadCode Instrs Assembler}
      {Peephole {SkipDeadCode Instrs Assembler} Assembler}
   end

   fun {HasLabel Instrs L}
      case Instrs of lbl(!L)|_ then true
      [] lbl(_)|Rest then {HasLabel Rest L}
      else false
      end
   end

   proc {Peephole Instrs Assembler}
      case Instrs of lbl(I)|Rest then
         {Assembler setLabel(I)}
         {Peephole Rest Assembler}
      [] definition(Register Label PredId ProcedureRef GRegRef Code)|Rest then
         {Assembler
          append(definition(Register Label PredId ProcedureRef GRegRef))}
         {Peephole Code Assembler}
         {Peephole Rest Assembler}
      [] definitionCopy(Register Label PredId ProcedureRef GRegRef Code)|Rest
      then
         {Assembler
          append(definitionCopy(Register Label PredId ProcedureRef GRegRef))}
         {Peephole Code Assembler}
         {Peephole Rest Assembler}
      [] clear(_)|_ then Clears Rest in
         {GetClears Instrs ?Clears ?Rest}
         case Rest of deAllocateL(_)|_ then skip
         else
            {ForAll Clears
             proc {$ clear(Y)}
                {Assembler append(clear(Y))}
             end}
         end
         {Peephole Rest Assembler}
      [] move(X1=x(_) Y1=y(_))|move(X2=x(_) Y2=y(_))|Rest then
         {Assembler append(moveMove(X1 Y1 X2 Y2))}
         {Peephole Rest Assembler}
      [] move(Y1=y(_) X1=x(_))|move(Y2=y(_) X2=x(_))|Rest then
         {Assembler append(moveMove(Y1 X1 Y2 X2))}
         {Peephole Rest Assembler}
      [] move(X1=x(_) Y1=y(_))|move(Y2=y(_) X2=x(_))|Rest then
         {Assembler append(moveMove(X1 Y1 Y2 X2))}
         {Peephole Rest Assembler}
      [] createVariable(R)|move(R X=x(_))|Rest then
         {Peephole createVariableMove(R X)|Rest Assembler}
      [] createVariable(X=x(_))|move(X R)|Rest then
         {Peephole createVariableMove(R X)|Rest Assembler}
      [] putRecord('|' 2 R)|Rest then
         {Assembler append(putList(R))}
         {Peephole Rest Assembler}
      [] setVoid(I)|Rest then OutI Rest1 in
         {SetVoids Rest I ?OutI ?Rest1}
         {Assembler append(setVoid(OutI))}
         {Peephole Rest1 Assembler}
      [] getRecord('|' 2 X1=x(_))|
         unifyValue(X2=x(_))|unifyVariable(X3=x(_))|Rest
      then
         {Assembler append(getListValVar(X1 X2 X3))}
         {Peephole Rest Assembler}
      [] getRecord('|' 2 R)|Rest then
         {Assembler append(getList(R))}
         {Peephole Rest Assembler}
      [] unifyValue(R1)|unifyVariable(R2)|Rest then
         {Assembler append(unifyValVar(R1 R2))}
         {Peephole Rest Assembler}
      [] unifyVoid(I)|Rest then OutI Rest1 in
         {UnifyVoids Rest I ?OutI ?Rest1}
         {Assembler append(unifyVoid(OutI))}
         {Peephole Rest1 Assembler}
      [] (allocateL(I)=I1)|Rest then
         case I of 0 then skip
         [] 1 then {Assembler append(allocateL1)}
         [] 2 then {Assembler append(allocateL2)}
         [] 3 then {Assembler append(allocateL3)}
         [] 4 then {Assembler append(allocateL4)}
         [] 5 then {Assembler append(allocateL5)}
         [] 6 then {Assembler append(allocateL6)}
         [] 7 then {Assembler append(allocateL7)}
         [] 8 then {Assembler append(allocateL8)}
         [] 9 then {Assembler append(allocateL9)}
         [] 10 then {Assembler append(allocateL10)}
         else {Assembler append(I1)}
         end
         {Peephole Rest Assembler}
      [] deAllocateL(I)|return|(Rest=lbl(_)|deAllocateL(J)|return|_) andthen
            I == J then
         {Peephole Rest Assembler}
      [] deAllocateL(I)|Rest then
         {MakeDeAllocate I Assembler}
         {Peephole Rest Assembler}
      [] 'skip'|Rest then
         {Peephole Rest Assembler}
      [] branch(L)|Rest then Rest1 in
         {Assembler declareLabel(L)}
         Rest1 = {SkipDeadCode Rest Assembler}
         case Rest1 of lbl(!L)|_ then skip
         else {Assembler append(branch(L))}
         end
         {Peephole Rest1 Assembler}
      [] return|Rest then
         {Assembler append(return)}
         {EliminateDeadCode Rest Assembler}
      [] (callBI(Builtinname Args)=I1)|Rest
         andthen {Not Assembler.controlFlowInfo}
      then BIInfo in
         BIInfo = {Builtins.getInfo Builtinname}
         if {CondSelect BIInfo doesNotReturn false} then
            case Rest of deAllocateL(I)|return|_ then
               {MakeDeAllocate I Assembler}
            else skip
            end
         end
         case Builtinname of 'Int.\'+1\'' then [X1]#[X2] = Args in
            {Assembler append(inlinePlus1(X1 X2))}
         [] 'Int.\'-1\'' then [X1]#[X2] = Args in
            {Assembler append(inlineMinus1(X1 X2))}
         [] 'Number.\'+\'' then [X1 X2]#[X3] = Args in
            {Assembler append(inlinePlus(X1 X2 X3))}
         [] 'Number.\'-\'' then [X1 X2]#[X3] = Args in
            {Assembler append(inlineMinus(X1 X2 X3))}
         [] 'Value.\'>\'' then [X1 X2]#Out = Args in
            {Assembler append(callBI('Value.\'<\'' [X2 X1]#Out))}
         [] 'Value.\'>=\'' then [X1 X2]#Out = Args in
            {Assembler append(callBI('Value.\'=<\'' [X2 X1]#Out))}
         else
            {Assembler append(I1)}
         end
%--** this does not work with current liveness analysis
%--**    if {CondSelect BIInfo doesNotReturn false} then
%--**       {EliminateDeadCode Rest Assembler}
%--**    else
            {Peephole Rest Assembler}
%--**    end
      [] callGlobal(G ArityAndIsTail)|deAllocateL(I)|return|Rest
         andthen ArityAndIsTail mod 2 == 0
      then
         {MakeDeAllocate I Assembler}
         {Assembler append(callGlobal(G ArityAndIsTail + 1))}
         {EliminateDeadCode Rest Assembler}
      [] callMethod(CMI 0)|deAllocateL(I)|return|Rest then
         {MakeDeAllocate I Assembler}
         {Assembler append(callMethod({AdjoinAt CMI 3 true} 0))}
         {EliminateDeadCode Rest Assembler}
      [] call(R Arity)|deAllocateL(I)|return|Rest then NewR in
         case R of y(_) then
            {Assembler append(move(R NewR=x(Arity)))}
         else
            NewR = R
         end
         {MakeDeAllocate I Assembler}
         {Assembler append(tailCall(NewR Arity))}
         {EliminateDeadCode Rest Assembler}
      [] callProcedureRef(ProcedureRef ArityAndIsTail)|
         deAllocateL(I)|return|Rest andthen ArityAndIsTail mod 2 == 0
      then
         {MakeDeAllocate I Assembler}
         {Assembler append(callProcedureRef(ProcedureRef ArityAndIsTail + 1))}
         {EliminateDeadCode Rest Assembler}
      [] callConstant(Abstraction ArityAndIsTail)|
         deAllocateL(I)|return|Rest
         andthen {IsDet Abstraction}
         andthen {IsProcedure Abstraction}
         andthen ArityAndIsTail mod 2 == 0
      then
         {MakeDeAllocate I Assembler}
         {Assembler append(callConstant(Abstraction ArityAndIsTail + 1))}
         {EliminateDeadCode Rest Assembler}
      [] sendMsg(Literal R RecordArity Cache)|deAllocateL(I)|return|Rest
      then NewR in
         case R of y(_) then
            NewR = x({RecordArityWidth RecordArity})
            {Assembler append(move(R NewR))}
         else
            NewR = R
         end
         {MakeDeAllocate I Assembler}
         {Assembler append(tailSendMsg(Literal NewR RecordArity Cache))}
         {EliminateDeadCode Rest Assembler}
      [] (testBI(Builtinname Args L1)=I1)|Rest then NewInstrs in
         case Rest of branch(L2)|NewRest then BIInfo in
            BIInfo = {Builtins.getInfo Builtinname}
            case {CondSelect BIInfo negated unit} of unit then skip
            elseof NegatedBuiltinname then
               NewInstrs = (testBI(NegatedBuiltinname Args L2)|
                            'skip'|branch(L1)|NewRest)
            end
         else skip
         end
         if {IsDet NewInstrs} then
            {Peephole NewInstrs Assembler}
         else
            case Builtinname of 'Value.\'<\'' then [X1 X2]#[X3] = Args in
               {Assembler append(testLT(X1 X2 X3 L1))}
            [] 'Value.\'=<\'' then [X1 X2]#[X3] = Args in
               {Assembler append(testLE(X1 X2 X3 L1))}
            [] 'Value.\'>=\''then [X1 X2]#[X3] = Args in
               {Assembler append(testLE(X2 X1 X3 L1))}
            [] 'Value.\'>\'' then [X1 X2]#[X3] = Args in
               {Assembler append(testLT(X2 X1 X3 L1))}
            else
               {Assembler append(I1)}
            end
            {Peephole Rest Assembler}
         end
      [] testRecord(R '|' 2 L)|Rest then
         {Assembler append(testList(R L))}
         {Peephole Rest Assembler}
      [] match(R ht(ElseL [onScalar(true TrueL) onScalar(false FalseL)]))|Rest
         andthen {HasLabel Rest TrueL}
      then
         {Assembler append(testBool(R FalseL ElseL))}
         {Peephole Rest Assembler}
      [] match(R ht(ElseL [onScalar(false FalseL) onScalar(true TrueL)]))|Rest
         andthen {HasLabel Rest TrueL}
      then
         {Assembler append(testBool(R FalseL ElseL))}
         {Peephole Rest Assembler}
      [] match(R ht(ElseL [onScalar(X L)]))|Rest andthen {HasLabel Rest L} then
         if {IsNumber X} then
            {Assembler append(testNumber(R X ElseL))}
         else
            {Assembler append(testLiteral(R X ElseL))}
         end
         {Peephole Rest Assembler}
      [] match(R ht(ElseL [onRecord(Label RecordArity L)]))|Rest
         andthen {HasLabel Rest L}
      then
         case Label#RecordArity of '|'#2 then
            {Assembler append(testList(R ElseL))}
         else
            {Assembler append(testRecord(R Label RecordArity ElseL))}
         end
         {Peephole Rest Assembler}
      [] (match(_ _)=I1)|Rest then
         {Assembler append(I1)}
         {EliminateDeadCode Rest Assembler}
      [] getVariable(R1)|getVariable(R2)|Rest then
         {Assembler append(getVarVar(R1 R2))}
         {Peephole Rest Assembler}
      [] getVoid(I)|Rest then OutI Rest1 in
         {GetVoids Rest I ?OutI ?Rest1}
         case Rest1 of getVariable(_)|_ then
            {Assembler append(getVoid(OutI))}
         else skip
         end
         {Peephole Rest1 Assembler}
      [] deconsCall(R)|deAllocateL(I)|return|Rest then NewR in
         case R of y(_) then
            {Assembler append(move(R NewR=x(2)))}
         else
            NewR = R
         end
         {MakeDeAllocate I Assembler}
         {Assembler append(tailDeconsCall(NewR))}
         {EliminateDeadCode Rest Assembler}
      [] consCall(R Arity)|deAllocateL(I)|return|Rest then NewR in
         case R of y(_) then
            {Assembler append(move(R NewR=x(Arity)))}
         else
            NewR = R
         end
         {MakeDeAllocate I Assembler}
         {Assembler append(tailConsCall(NewR Arity))}
         {EliminateDeadCode Rest Assembler}
      [] I1|Rest then
         {Assembler append(I1)}
         {Peephole Rest Assembler}
      [] nil then skip
      end
   end

   proc {InternalAssemble Code Switches ?Assembler}
      ProfileSwitch = {CondSelect Switches profile false}
      ControlFlowInfoSwitch = {CondSelect Switches controlflowinfo false}
      Verify = {CondSelect Switches verify true}
      DoPeephole = {CondSelect Switches peephole true}
   in
      Assembler = {New AssemblerClass
                   init(ProfileSwitch ControlFlowInfoSwitch)}
      if DoPeephole then
         {Peephole Code Assembler}
      else
         {ForAll Code
          proc {$ Instr}
             case Instr of lbl(I) then
                {Assembler setLabel(I)}
             else
                {Assembler append(Instr)}
             end
          end}
      end
      if Verify then
         {Assembler checkLabels()}
      end
   end

   proc {Assemble Code Globals Switches ?P ?VS}
      Assembler = {InternalAssemble Code Switches}
   in
      {Assembler load(Globals ?P)}
      VS = {ByNeedFuture fun {$} {Assembler output($)} end}
   end

\else

   class CompatAssemblerClass
      attr
         codeAreas
         mainCodeArea

      meth init()
         codeAreas := nil
         mainCodeArea := unit
      end

      meth addCodeArea(CodeArea VS)
         codeAreas := (CodeArea#VS) | @codeAreas
      end

      meth setMainCodeArea(CodeArea)
         mainCodeArea := CodeArea
      end

      meth load(Globals ?P)
         P = {CompilerSupport.newAbstraction @mainCodeArea Globals}
      end

      meth output(?VS)
         VS = {FoldL @codeAreas
               fun {$ Prev _#VS}
                  {Wait VS}
                  Prev#'\n'#VS
               end nil}
      end
   end

   % Magical conversion function that turns old code into new code

   fun {ComputeXCountInOldCode Code MaxXCount}
      case Code
      of Head|Tail then
         NewMaxXCount = {Record.foldL Head
                         fun {$ Prev Arg}
                            case Arg of x(I) then {Max Prev I+1}
                            else Prev
                            end
                         end MaxXCount}
      in
         {ComputeXCountInOldCode Tail NewMaxXCount}
      [] nil then
         MaxXCount
      end
   end

   fun {ExtractArityAndIsTail ArityAndIsTail}
      (ArityAndIsTail div 2) # (ArityAndIsTail mod 2 \= 0)
   end

   fun {OldCodeToNewCode ProcArity Code AssembleInner}
      UserXCount = {ByNeedFuture
                    fun {$} {ComputeXCountInOldCode Code ProcArity} end}

      fun {MakeInitGRegs SourceRegs Rest}
         case SourceRegs
         of SrcReg|SrcRegTail then
            arrayFill(SrcReg) | {MakeInitGRegs SrcRegTail Rest}

         [] nil then
            {Loop Rest}
         end
      end

      fun {TransformMatchItem Item}
         case Item
         of onScalar(Value Lbl) then
            Value#Lbl
         [] onRecord(Label WidthOrArity Lbl) then
            Arity = if {IsInt WidthOrArity} then
                       {List.number 1 WidthOrArity 1}
                    else
                       WidthOrArity
                    end
            ArityAndCaptures = {List.mapInd Arity
                                fun {$ Index Feature}
                                   Feature #
                                   {CompilerSupport.newPatMatCapture
                                    UserXCount + Index - 1}
                                end}
         in
            {List.toRecord Label ArityAndCaptures} # Lbl
         end
      end

      fun {TransformMatch R ht(ElseLbl HashList) Rest}
         NewHashList = {Map HashList TransformMatchItem}
         NewHashTable = {List.toTuple '#' NewHashList}
      in
         patternMatch(R k(NewHashTable)) | branch(ElseLbl) | {Loop Rest}
      end

      fun {TransformPatMatGets Code NextXIndex}
         case Code
         of getVariable(R) | Rest then
            move(x(NextXIndex) R) | {TransformPatMatGets Rest NextXIndex+1}
         [] getVarVar(R1 R2) | Rest then
            move(x(NextXIndex) R1) | move(x(NextXIndex+1) R2) |
               {TransformPatMatGets Rest NextXIndex+2}
         [] getVoid(N) | Rest then
            {TransformPatMatGets Rest NextXIndex+N}
         else
            {Loop Code}
         end
      end

      fun {Loop Code}
         case Code

         % allocateL / deAllocateL become allocateY / nothing
         of allocateL(I) | Rest then
            allocateY(I) | {Loop Rest}
         [] deAllocateL(_) | Rest then
            {Loop Rest}

         % createVariable and createVariableMove are renamed
         [] createVariable(R) | Rest then
            createVar(R) | {Loop Rest}
         [] createVariableMove(R1 R2) | Rest then
            createVarMove(R1 R2) | {Loop Rest}

         % exHandler and popEx are renamed
         [] exHandler(Lbl) | Rest then
            setupExceptionHandler(Lbl) | {Loop Rest}
         [] popEx | Rest then
            popExceptionHandler | {Loop Rest}

         % patch for putConstant followed by setValue/unifyValue (TODO unsafe!)
         % IMO it's a bug in the codegen in the first place
         [] putConstant(Value R1) | setValue(R2) | Rest andthen R1 == R2 then
            {Loop setConstant(Value) | Rest}
         [] putConstant(Value R1) | unifyValue(R2) | Rest andthen R1 == R2 then
            {Loop unifyConstant(Value) | Rest}

         % putConstant(Value Reg) become moveKX / moveKY
         [] putConstant(Value R) | Rest then
            move(k(Value) R) | {Loop Rest}

         % putList and putRecord become createConsStore and Co.
         [] putRecord('|' 2 Dest) | Rest then
            createConsStore(Dest) | {Loop Rest}
         [] putList(Dest) | Rest then
            createConsStore(Dest) | {Loop Rest}
         [] putRecord(Label WidthOrArity Dest) | Rest then
            if {IsInt WidthOrArity} then
               % Tuple
               Width = WidthOrArity
            in
               createTupleStore(k(Label) Width Dest) | {Loop Rest}
            else
               % Record
               Arity = {CompilerSupport.makeArity Label WidthOrArity}
               Width = {Length WidthOrArity}
            in
               createRecordStore(k(Arity) Width Dest) | {Loop Rest}
            end

         % setThings become arrayFillThings
         [] setConstant(Value) | Rest then
            arrayFill(k(Value)) | {Loop Rest}
         [] setValue(R) | Rest then
            arrayFill(R) | {Loop Rest}
         [] setVariable(R) | Rest then
            arrayFillNewVar(R) | {Loop Rest}
         [] setVoid(N) | Rest then
            arrayFillNewVars(N) | {Loop Rest}

         % getNumber(I R) and getLiteral(L R) become unifyRK
         [] getNumber(I R) | Rest then
            unify(R k(I)) | {Loop Rest}
         [] getLiteral(L R) | Rest then
            unify(R k(L)) | {Loop Rest}

         % getList and getRecord become createConsUnify and Co.
         [] getRecord('|' 2 Dest) | Rest then
            createConsUnify(Dest) | {Loop Rest}
         [] getList(Dest) | Rest then
            createConsUnify(Dest) | {Loop Rest}
         [] getRecord(Label WidthOrArity Dest) | Rest then
            if {IsInt WidthOrArity} then
               % Tuple
               Width = WidthOrArity
            in
               createTupleUnify(k(Label) Width Dest) | {Loop Rest}
            else
               % Record
               Arity = {CompilerSupport.makeArity Label WidthOrArity}
               Width = {Length WidthOrArity}
            in
               createRecordUnify(k(Arity) Width Dest) | {Loop Rest}
            end

         % getListValVar is desugared for now
         [] getListValVar(D R1 R2) | Rest then
            createConsUnify(D) | arrayFill(R1) | arrayFillNewVar(R2) |
               {Loop Rest}

         % unifyThings become arrayFillThings
         [] unifyConstant(Value) | Rest then
            arrayFill(k(Value)) | {Loop Rest}
         [] unifyNumber(Value) | Rest then
            arrayFill(k(Value)) | {Loop Rest}
         [] unifyLiteral(Value) | Rest then
            arrayFill(k(Value)) | {Loop Rest}
         [] unifyValue(R) | Rest then
            arrayFill(R) | {Loop Rest}
         [] unifyVariable(R) | Rest then
            arrayFillNewVar(R) | {Loop Rest}
         [] unifyValVar(R1 R2) | Rest then
            arrayFill(R1) | arrayFillNewVar(R2) | {Loop Rest}
         [] unifyVoid(N) | Rest then
            arrayFillNewVars(N) | {Loop Rest}

         % callBI and inlineDot become callBuiltin
         [] callBI(Builtin InArgs#OutArgs) | Rest then
            callBuiltin(k(Builtin) {Append InArgs OutArgs}) | {Loop Rest}
         [] inlineDot(R1=x(_) I R2=x(_) cache) | Rest then
            move(k(I) x(UserXCount)) |
            callBuiltin(k(Value.'.') [R1 x(UserXCount) R2]) |
            {Loop Rest}

         % callConstant becomes callK
         [] callConstant(P ArityAndIsTail) | Rest then
            Arity # IsTail = {ExtractArityAndIsTail ArityAndIsTail}
         in
            if IsTail then
               tailCall(k(P) Arity)
            else
               call(k(P) Arity)
            end | {Loop Rest}

         % callGlobal becomes call
         [] callGlobal(R=g(_) ArityAndIsTail) | Rest then
            Arity # IsTail = {ExtractArityAndIsTail ArityAndIsTail}
         in
            if IsTail then
               tailCall(R Arity)
            else
               call(R Arity)
            end | {Loop Rest}

         % sendMsg and tailSendMsg change format
         [] sendMsg(Label ObjR ArityOrWidth _) | Rest then
            if {IsInt ArityOrWidth} then
               sendMsg(ObjR k(Label) ArityOrWidth)
            else
               sendMsg(ObjR
                       k({CompilerSupport.makeArity Label ArityOrWidth})
                       {Length ArityOrWidth})
            end | {Loop Rest}
         [] tailSendMsg(Label ObjR ArityOrWidth _) | Rest then
            if {IsInt ArityOrWidth} then
               tailSendMsg(ObjR k(Label) ArityOrWidth)
            else
               tailSendMsg(ObjR
                           k({CompilerSupport.makeArity Label ArityOrWidth})
                           {Length ArityOrWidth})
            end | {Loop Rest}

         % testBool(R L1 L2) becomes condBranch(R L1 L2) | lbl(L3)
         [] testBool(R=x(_) L1 L2) | Rest then
            condBranch(R L1 L2) | {Loop Rest}
         [] testBool(R L1 L2) | Rest then
            {Loop move(R x(UserXCount)) | testBool(x(UserXCount) L1 L2) | Rest}

         % match and other testX become a deep pattern matching
         [] match(R HashTable) | Rest then
            {TransformMatch R HashTable Rest}

         % Following pattern matching statements, getVariable fetches a capture
         [] getVariable(_) | _ then {TransformPatMatGets Code UserXCount}
         [] getVarVar(_ _) | _ then {TransformPatMatGets Code UserXCount}
         [] getVoid(_)     | _ then {TransformPatMatGets Code UserXCount}

         % definition + endDefinition become createAbstraction
         [] definition(Dest _ pid(Name Arity Pos _ _)
                       unit GRegRef InnerCode) |
               endDefinition(_) | Rest then
            DebugData = case Pos
                        of pos(F L C) then d(file:F line:L column:C)
                        else unit
                        end
            InnerCodeArea = {AssembleInner Arity InnerCode Name DebugData}
            GCount = {Length GRegRef}
         in
            createAbstractionStore(k(InnerCodeArea) GCount Dest) |
               {MakeInitGRegs GRegRef Rest}

         % other things are kept as is
         [] H|Rest then
            H|{Loop Rest}
         [] nil then
            nil
         end
      end
   in
      {Loop Code}
   end

   proc {InternalAssemble Code Switches ?Assembler}
      !Assembler = {New CompatAssemblerClass init()}

      proc {AssembleInner Arity Code PrintName DebugData ?CodeArea}
         NewCode = {OldCodeToNewCode Arity Code AssembleInner}
         VS
      in
         {NewAssembler.assemble Arity NewCode PrintName DebugData Switches
          ?CodeArea ?VS}
         {Assembler addCodeArea(CodeArea VS)}
      end

      CodeArea = {AssembleInner 0 Code '' unit}
   in
      {Assembler setMainCodeArea(CodeArea)}
   end

   proc {Assemble Code Globals Switches ?P ?VS}
      Assembler = {InternalAssemble Code Switches}
   in
      {Assembler load(Globals ?P)}
      VS = {ByNeedFuture fun {$} {Assembler output($)} end}
   end
\endif

end
