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
   System(printName)
   CompilerSupport at 'x-oz://boot/CompilerSupport'
   Builtins(getInfo)
export
   InternalAssemble
   Assemble
define
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
      [] deAllocateL(I)|return|(Rest=lbl(_)|deAllocateL(!I)|return|_) then
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
end
