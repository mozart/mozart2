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

%%
%% General Notes:
%%
%% meth codeGen(CS ?VInstr)
%%    CS is an instance of the CodeStore class.  It encapsulates the
%%    internal state of the code generator (generation of virtual
%%    registers as well as compiler switches) and stores the produced
%%    code.  Its methods annotate this code, perform register assignment,
%%    and emit the code.
%%

%\define DEBUG_DEFS

functor
import
   Debug(getRaiseOnBlock setRaiseOnBlock) at 'x-oz://boot/Debug'
   CompilerSupport(isBuiltin featureLess) at 'x-oz://boot/CompilerSupport'
   Space(new ask merge)
   FD(decl distinct sumC reflect assign)
   System(show printName)
   Property(get)
   Builtins(getInfo)
   Core
   RunTime(literals procValues)
   CodeStore('class')
export
   %% mixin classes for the abstract syntax:
   typeOf: CodeGenTypeOf
   stepPoint: CodeGenStepPoint
   declaration: CodeGenDeclaration
   skipNode: CodeGenSkipNode
   equation: CodeGenEquation
   construction: CodeGenConstruction
   definition: CodeGenDefinition
   clauseBody: CodeGenClauseBody
   application: CodeGenApplication
   ifNode: CodeGenIfNode
   ifClause: CodeGenIfClause
   patternCase: CodeGenPatternCase
   patternClause: CodeGenPatternClause
   sideCondition: CodeGenSideCondition
   recordPattern: CodeGenRecordPattern
   equationPattern: CodeGenEquationPattern
   elseNode: CodeGenElseNode
   noElse: CodeGenNoElse
   tryNode: CodeGenTryNode
   lockNode: CodeGenLockNode
   classNode: CodeGenClassNode
   method: CodeGenMethod
   methFormal: CodeGenMethFormal
   methFormalOptional: CodeGenMethFormalOptional
   methFormalWithDefault: CodeGenMethFormalWithDefault
   objectLockNode: CodeGenObjectLockNode
   getSelf: CodeGenGetSelf
   exceptionNode: CodeGenExceptionNode
   valueNode: CodeGenValueNode
   variable: CodeGenVariable
   variableOccurrence: CodeGenVariableOccurrence
   patternVariableOccurrence: CodeGenPatternVariableOccurrence

   %% mixin classes for token representations:
   token: CodeGenToken
   procedureToken: CodeGenProcedureToken
define
   proc {CodeGenList Nodes CS VHd VTl}
      case Nodes of Node|Noder then VInter in
         {Node codeGen(CS VHd VInter)}
         {CodeGenList Noder CS VInter VTl}
      [] nil then
         VHd = VTl
      end
   end

   fun {CoordNoDebug Coord}
      case {Label Coord} of pos then Coord
      else {Adjoin Coord pos}
      end
   end

   fun {IsStep Coord}
      case {Label Coord} of pos then false
      [] unit then false
      else true
      end
   end

   proc {StepPoint Coord Kind VHd VTl VInter1 VInter2}
      if {IsStep Coord} then
         VHd = vDebugEntry(_ Coord Kind VInter1)
         VInter2 = vDebugExit(_ Coord Kind VTl)
      else
         VHd = VInter1
         VInter2 = VTl
      end
   end

   proc {MakeUnify Reg1 Reg2 VHd VTl}
      if {IsDet Reg1} andthen {IsDet Reg2} andthen Reg1 == Reg2 then
         %% We omit the unification to avoid unnecessary Reg occurrences.
         %% (Reg1 or Reg2 can be undetermined in SideConditions, see PR#634.
         %% The reason is the the test is processed before the subpattern,
         %% and registers are assigned to variables only when the subpattern
         %% is processed.)
         VHd = VTl
      else
         VHd = vUnify(_ Reg1 Reg2 VTl)
      end
   end

   proc {MakePermanent Vs VHd Cont1 Cont2 VTl CS}
      if CS.staticVarnamesSwitch orelse CS.dynamicVarnamesSwitch then
         RegIndices = {FoldR Vs
                       fun {$ V In} Reg in
                          {V reg(?Reg)}
                          case {V getPrintName($)} of unit then In
                          elseof PN andthen {IsAtom PN} then Reg#_#PN|In
                          else In
                          end
                       end nil}
      in
         case RegIndices of nil then
            VHd = Cont1
            Cont2 = VTl
         else
            {ForAll RegIndices proc {$ _#I#_} {CS nextYIndex(?I)} end}
            VHd = vMakePermanent(_ RegIndices Cont1)
            if CS.staticVarnamesSwitch then Regs in
               Regs = {Map RegIndices fun {$ Reg#_#_} Reg end}
               Cont2 = vClear(_ Regs VTl)
            else
               Cont2 = VTl
            end
         end
      else
         VHd = Cont1
         Cont2 = VTl
      end
   end

   %%
   %% Instances of PseudoVariableOccurrences are used when in some
   %% code generation context a variable occurrence is required but
   %% only a register index is available (for example, in case of
   %% a late expansion where said register is freshly generated).
   %%

   class PseudoVariableOccurrence
      prop final
      feat reg value coord
      meth init(Reg)
         self.reg = Reg
      end
      meth getCoord($) C = self.coord in
         if {IsDet C} then C else unit end
      end
      meth getVariable($)
         self
      end
      meth getPrintName($)
         unit
      end
      meth isToplevel($)
         false
      end
      meth getCodeGenValue($)
         self.value
      end
      meth reg($)
         self.reg
      end
      meth makeEquation(CS VO VHd VTl) Value = self.value in
         if {IsDet Value} andthen ({IsNumber Value} orelse {IsLiteral Value})
         then
            VHd = vEquateConstant(_ Value {VO reg($)} VTl)
         else
            {MakeUnify self.reg {VO reg($)} VHd VTl}
         end
      end
      meth makeRecordArgument(CS VHd VTl $) Value = self.value in
         VHd = VTl
         if {IsDet Value} andthen ({IsNumber Value} orelse {IsLiteral Value})
         then constant(Value)
         else value(self.reg)
         end
      end
      meth makeVO(CS VHd VTl ?VO)
         VHd = VTl
         VO = self
      end
   end

   fun {NewPseudoVariableOccurrence CS}
      {New PseudoVariableOccurrence init({CS newReg($)})}
   end

   proc {MakeMessageArgs ActualArgs CS ?Regs VHd VTl}
      case ActualArgs of Arg|Argr then Reg1 Regr VInter VO in
         {Arg makeVO(CS VHd VInter ?VO)}
         {VO reg(?Reg1)}
         Regs = Reg1|Regr
         {MakeMessageArgs Argr CS ?Regr VInter VTl}
      [] nil then
         Regs = nil
         VHd = VTl
      end
   end

   fun {GetRegs VOs}
      case VOs of VO|VOr then {VO reg($)}|{GetRegs VOr}
      [] nil then nil
      end
   end

   local
      proc {LoadActualArgs ActualArgs CS VHd VTl ?NewArgs}
         case ActualArgs of Arg|Argr then Value VInter NewArgr in
            {Arg getCodeGenValue(?Value)}
            if {IsDet Value} andthen {IsName Value} then PVO in
               PVO = {NewPseudoVariableOccurrence CS}
               PVO.value = Value
               VHd = vEquateConstant(_ Value {PVO reg($)} VInter)
               NewArgs = PVO|NewArgr
            else
               VHd = VInter
               NewArgs = Arg|NewArgr
            end
            {LoadActualArgs Argr CS VInter VTl ?NewArgr}
         [] nil then
            VHd = VTl
            NewArgs = nil
         end
      end

      proc {MakeBuiltinApplication Builtinname Coord ActualArgs CS VHd VTl}
         case Builtinname of 'Object.new' then
            [Arg1 Arg2 Arg3] = ActualArgs ObjReg Cont
         in
            %% this ensures that the created object is always a fresh
            %% register and that the message is sent before the new
            %% object is unified with the output variable.  This is
            %% needed for the correctness of the sendMsg-optimization
            %% performed in the CodeEmitter:
            {CS newReg(?ObjReg)}
            VHd = vCallBuiltin(_ 'Object.new'
                               [{Arg1 reg($)} {Arg2 reg($)} ObjReg]
                               Coord Cont)
            Cont = vUnify(_ ObjReg {Arg3 reg($)} VTl)
         [] 'Number.\'+\'' then [Arg1 Arg2 Arg3] = ActualArgs Value in
            {Arg1 getCodeGenValue(?Value)}
            if {IsDet Value} then
               case Value of 1 then
                  VHd = vCallBuiltin(_ 'Int.\'+1\''
                                     [{Arg2 reg($)} {Arg3 reg($)}]
                                     Coord VTl)
               [] ~1 then
                  VHd = vCallBuiltin(_ 'Int.\'-1\''
                                     [{Arg2 reg($)} {Arg3 reg($)}]
                                     Coord VTl)
               else skip
               end
            end
            if {IsDet VHd} then skip
            else Value in
               {Arg2 getCodeGenValue(?Value)}
               if {IsDet Value} then
                  case Value of 1 then
                     VHd = vCallBuiltin(_ 'Int.\'+1\''
                                        [{Arg1 reg($)} {Arg3 reg($)}]
                                        Coord VTl)
                  [] ~1 then
                     VHd = vCallBuiltin(_ 'Int.\'-1\''
                                        [{Arg1 reg($)} {Arg3 reg($)}]
                                        Coord VTl)
                  else skip
                  end
               end
            end
         [] 'Number.\'-\'' then [Arg1 Arg2 Arg3] = ActualArgs Value in
            {Arg2 getCodeGenValue(?Value)}
            if {IsDet Value} then
               case Value of 1 then
                  VHd = vCallBuiltin(_ 'Int.\'-1\''
                                     [{Arg1 reg($)} {Arg3 reg($)}]
                                     Coord VTl)
               [] ~1 then
                  VHd = vCallBuiltin(_ 'Int.\'+1\''
                                     [{Arg1 reg($)} {Arg3 reg($)}]
                                     Coord VTl)
               else skip
               end
            else skip
            end
         elseif CS.controlFlowInfoSwitch then skip
         elsecase Builtinname of 'Value.\'.\'' then
            [Arg1 Arg2 Arg3] = ActualArgs Feature in
            {Arg2 getCodeGenValue(?Feature)}
            if {IsDet Feature}
               andthen ({IsLiteral Feature} orelse {IsInt Feature})
            then Value1 AlwaysSucceeds in
               {Arg1 getCodeGenValue(?Value1)}
               AlwaysSucceeds = ({IsDet Value1}
                                 andthen {IsRecord Value1}
                                 andthen {HasFeature Value1 Feature})
               if AlwaysSucceeds
                  andthen {IsObject Value1.Feature}
                  andthen {HasFeature Value1.Feature
                           Core.imAVariableOccurrence}
                  andthen {IsDet {Value1.Feature reg($)}}
               then
                  %% Evaluate by issuing an equation.
                  %% Note: {Value1.Feature reg($)} may be undetermined
                  %% for nested records annotated by valToSubst.
                  {Arg3 makeEquation(CS Value1.Feature VHd VTl)}
               else
                  %% Because the static analyzer may annotate some
                  %% variable equality at Arg3, we cannot use the
                  %% (dereferencing) {Arg3 reg($)} call but have to
                  %% use the variable's original register:
                  VHd = vInlineDot(_ {Arg1 reg($)} Feature
                                   {{Arg3 getVariable($)} reg($)}
                                   AlwaysSucceeds Coord VTl)
               end
            end
         [] 'Object.\'@\'' then [Arg1 Arg2] = ActualArgs Feature in
            {Arg1 getCodeGenValue(?Feature)}
            if {IsDet Feature}
               andthen ({IsInt Feature} orelse {IsLiteral Feature})
            then
               VHd = vInlineAt(_ Feature {Arg2 reg($)} VTl)
            end
         [] 'Value.catAccessOO' then [Arg1 Arg2]  = ActualArgs Feature in
            {Arg1 getCodeGenValue(?Feature)}
            if {IsDet Feature}
               andthen ({IsInt Feature} orelse {IsLiteral Feature})
            then
               VHd = vInlineAt(_ Feature {Arg2 reg($)} VTl)
            end
         [] 'Object.\'<-\'' then [Arg1 Arg2] = ActualArgs Feature in
            {Arg1 getCodeGenValue(?Feature)}
            if {IsDet Feature}
               andthen ({IsInt Feature} orelse {IsLiteral Feature})
            then
               VHd = vInlineAssign(_ Feature {Arg2 reg($)} VTl)
            end
         [] 'Value.catAssignOO' then [Arg1 Arg2] = ActualArgs Feature in
            {Arg1 getCodeGenValue(?Feature)}
            if {IsDet Feature}
               andthen ({IsInt Feature} orelse {IsLiteral Feature})
            then
               VHd = vInlineAssign(_ Feature {Arg2 reg($)} VTl)
            end
         [] 'Object.\',\'' then [Arg1 Arg2] = ActualArgs Value in
            {Arg2 getCodeGenValue(?Value)}
            if {{Arg1 getVariable($)} isToplevel($)}
               andthen {IsDet Value} andthen {IsRecord Value}
               andthen {Record.all Value
                        fun {$ Arg}
                           {Not {HasFeature Arg Core.imAVariableOccurrence}}
                           orelse {IsDet {Arg reg($)}}
                        end}
            then RecordArity ActualArgs Regs Cont1 in
               RecordArity = if {IsTuple Value} then {Width Value}
                             else {Arity Value}
                             end
               ActualArgs = {Record.toList Value}
               {MakeMessageArgs ActualArgs CS ?Regs VHd Cont1}
               Cont1 = vCallMethod(_ {Arg1 reg($)}
                                   {Label Value} RecordArity
                                   Regs Coord VTl)
            end
         else skip
         end
         if {IsDet VHd} then skip
         else
            VHd = vCallBuiltin(_ Builtinname {GetRegs ActualArgs} Coord VTl)
         end
      end

      proc {MakeDirectApplication Value Coord ActualArgs CS VHd VTl}
         if {CompilerSupport.isBuiltin Value} then Builtinname in
            Builtinname = {System.printName Value}
            {MakeBuiltinApplication Builtinname Coord ActualArgs CS VHd VTl}
         else
            VHd = vCallConstant(_ Value {GetRegs ActualArgs} Coord VTl)
         end
      end
   in
      proc {MakeApplication Designator Coord ActualArgs CS VHd VTl}
         VInter NewActualArgs Proc
      in
         {LoadActualArgs ActualArgs CS VHd VInter ?NewActualArgs}
         {Designator getCodeGenValue(?Proc)}
         if {IsDet Proc} andthen {IsProcedure Proc} then
            {MakeDirectApplication Proc Coord NewActualArgs CS VInter VTl}
         else Value Def in
            {Designator getValue(?Value)}
            if {HasFeature Value Core.imAToken}
               andthen ({Value getDefinition(?Def)} Def \= unit)
            then
               {Def codeGenApply(Designator Coord NewActualArgs CS VInter VTl)}
            elseif {{Designator getVariable($)} isToplevel($)}
               andthen {Not CS.controlFlowInfoSwitch}
            then
               VInter = vCallGlobal(_ {Designator reg($)}
                                    {GetRegs NewActualArgs} Coord VTl)
            else
               VInter = vCall(_ {Designator reg($)} {GetRegs NewActualArgs}
                              Coord VTl)
            end
         end
      end

      proc {MakeRunTimeProcApplication Name Coord ActualArgs CS VHd VTl}
         VInter NewActualArgs
      in
         {LoadActualArgs ActualArgs CS VHd VInter ?NewActualArgs}
         {MakeDirectApplication RunTime.procValues.Name
          Coord NewActualArgs CS VInter VTl}
      end
   end

   proc {MakeException Lab Literal Coord VOs CS VHd VTl} Reg VO VArgs VInter in
      {CS newReg(?Reg)}
      VO = {New PseudoVariableOccurrence init(Reg)}
      VArgs = constant(Literal)|{Append
                                 case Coord of unit then
                                    [constant('') constant(unit)]
                                 else
                                    [constant(Coord.1) constant(Coord.2)]
                                 end
                                 {Map VOs fun {$ VO} value({VO reg($)}) end}}
      VHd = vEquateRecord(_ Lab {Length VArgs} Reg VArgs VInter)
      {MakeRunTimeProcApplication 'Exception.raiseError' {CoordNoDebug Coord}
       [VO] CS VInter VTl}
   end

   \insert PatternMatching

   local
      fun {MakeFromPropSub FromProp CS VHd VTl}
         case FromProp of VO|VOr then ArgIn VInter ConsReg X = unit NewArg in
            ArgIn = {MakeFromPropSub VOr CS VHd VInter}
            {CS newReg(?ConsReg)}
            {VO makeRecordArgument(CS X X ?NewArg)}
            VInter = vEquateRecord(_ '|' 2 ConsReg [NewArg ArgIn] VTl)
            value(ConsReg)
         [] nil then
            VHd = VTl
            constant(nil)
         end
      end
   in
      proc {MakeFromProp FromProp CS VHd VTl ?VO} Reg in
         case FromProp of _|_ then
            value(Reg) = {MakeFromPropSub FromProp CS VHd VTl}
         [] nil then
            {CS newReg(?Reg)}
            VHd = vEquateConstant(_ nil Reg VTl)
         end
         VO = {New PseudoVariableOccurrence init(Reg)}
      end
   end

   local
      fun {MakeAttrFeatSub Xs CS}
         case Xs of X|Xr then
            case X of _#_ then X
            else VO in
               VO = {NewPseudoVariableOccurrence CS}
               VO.value = RunTime.literals.ooFreeFlag
               X#VO
            end|{MakeAttrFeatSub Xr CS}
         [] nil then
            nil
         end
      end
   in
      proc {MakeAttrFeat Kind AttrFeat CS VHd VTl ?VO}
         Label = {New Core.valueNode init(Kind unit)}
         Args = {MakeAttrFeatSub AttrFeat CS}
      in
         VO = {NewPseudoVariableOccurrence CS}
         {MakeConstruction CS VO Label Args VHd VTl}
      end
   end

   local
      proc {MakeConstructionBasic CS VO Label Feats TheLabel Args VHd VTl}
         case Feats of nil then   % transform `f()' into `f':
            VHd = vEquateConstant(_ Label {VO reg($)} VTl)
         else PairList Rec RecordArity VArgs VInter in
            PairList = {List.zip Feats Args
                        fun {$ F Arg}
                           case Arg of _#T then F#T else F#Arg end
                        end}
            try
               Rec = {List.toRecord Label PairList}
            catch error(kernel(recordConstruction ...) ...) then C in
               {TheLabel getCoord(?C)}
               {CS.reporter
                error(coord: C kind: 'code generation error'
                      msg: 'duplicate feature in record construction')}
               Rec = {AdjoinList Label() PairList}
            end
            RecordArity = if {IsTuple Rec} then {Width Rec}
                          else {Arity Rec}
                          end
            VArgs#VInter = {Record.foldR Rec
                            fun {$ X In#VTl} VArg VHd in
                               {X makeRecordArgument(CS VHd VTl ?VArg)}
                               (VArg|In)#VHd
                            end nil#VTl}
            VHd = vEquateRecord(_ Label RecordArity {VO reg($)} VArgs VInter)
         end
      end
      proc {MakeConstructionTuple CS VO TheLabel Rec VHd VTl}
         C SubtreesReg SubtreesVO WidthValue Cont
      in
         %% translate the construction as:
         %%    {`List.toTuple` Label [Subtree1 ... Subtreen] ?Reg}
         {TheLabel getCoord(?C)}
         {CS newReg(?SubtreesReg)}
         SubtreesVO = {New PseudoVariableOccurrence init(SubtreesReg)}
         WidthValue = {Width Rec}
         case WidthValue of 0 then
            VHd = vEquateConstant(_ nil SubtreesReg Cont)
         else
            fun {MakeList I VHd VTl}
               if I =< WidthValue then ArgIn VInter1 ConsReg VInter2 NewArg in
                  ArgIn = {MakeList I + 1 VHd VInter1}
                  {CS newReg(?ConsReg)}
                  {Rec.I makeRecordArgument(CS VInter1 VInter2 ?NewArg)}
                  VInter2 = vEquateRecord(_ '|' 2 ConsReg [NewArg ArgIn] VTl)
                  value(ConsReg)
               else
                  VHd = VTl
                  constant(nil)
               end
            end
            Arg VInter1 VInter2 NewArg
         in
            Arg = {MakeList 2 VHd VInter1}
            {Rec.1 makeRecordArgument(CS VInter1 VInter2 ?NewArg)}
            VInter2 = vEquateRecord(_ '|' 2 SubtreesReg [NewArg Arg] Cont)
         end
         {MakeRunTimeProcApplication 'List.toTuple' {CoordNoDebug C}
          [TheLabel SubtreesVO VO] CS Cont VTl}
      end
      proc {MakeConstructionRecord CS VO TheLabel Args VHd VTl}
         C SubtreesReg SubtreesVO Cont
      in
         %% translate the construction as:
         %%    {`List.toRecord` Label [Feat1#Subtree1 ... Featn#Subtreen] ?Reg}
         {TheLabel getCoord(?C)}
         {CS newReg(?SubtreesReg)}
         SubtreesVO = {New PseudoVariableOccurrence init(SubtreesReg)}
         case Args of (F1#A1)|Argr then   % else it would have been a tuple
            fun {MakePairList Args VHd VTl}
               case Args of F#A|Argr then
                  ArgIn VInter1 PairReg ConsReg PairArg1 PairArg2
                  VInter2 VInter3
               in
                  ArgIn = {MakePairList Argr VHd VInter1}
                  {CS newReg(?PairReg)}
                  {CS newReg(?ConsReg)}
                  PairArg1 = if {IsInt F} orelse {IsLiteral F} then constant(F)
                             else value({F reg($)})
                             end
                  {A makeRecordArgument(CS VInter1 VInter2 ?PairArg2)}
                  VInter2 = vEquateRecord(_ '#' 2 PairReg [PairArg1 PairArg2]
                                          VInter3)
                  VInter3 = vEquateRecord(_ '|' 2 ConsReg
                                          [value(PairReg) ArgIn] VTl)
                  value(ConsReg)
               [] nil then
                  VHd = VTl
                  constant(nil)
               end
            end
            Arg VInter1 PairReg PairArg1 PairArg2 VInter2 VInter3
         in
            Arg = {MakePairList Argr VHd VInter1}
            {CS newReg(?PairReg)}
            PairArg1 = if {IsInt F1} orelse {IsLiteral F1} then constant(F1)
                       else value({F1 reg($)})
                       end
            {A1 makeRecordArgument(CS VInter1 VInter2 ?PairArg2)}
            VInter2 = vEquateRecord(_ '#' 2 PairReg
                                    [PairArg1 PairArg2] VInter3)
            VInter3 = vEquateRecord(_ '|' 2 SubtreesReg
                                    [value(PairReg) Arg] Cont)
         end
         if {HasFeature TheLabel Core.imAVariableOccurrence} then
            {MakeRunTimeProcApplication 'List.toRecord' {CoordNoDebug C}
             [TheLabel SubtreesVO VO] CS Cont VTl}
         else LabelReg LabelVO LabelValue Inter in
            {CS newReg(?LabelReg)}
            LabelVO = {New PseudoVariableOccurrence init(LabelReg)}
            {TheLabel getCodeGenValue(?LabelValue)}
            Cont = vEquateConstant(_ LabelValue LabelReg Inter)
            {MakeRunTimeProcApplication 'List.toRecord' {CoordNoDebug C}
             [LabelVO SubtreesVO VO] CS Inter VTl}
         end
      end
   in
      proc {MakeConstruction CS VO TheLabel Args VHd VTl}
         %% Determine in which way the record may be constructed.
         Label Feats LabelIsDet FeatsAreDet
      in
         {TheLabel getCodeGenValue(?Label)}
         Feats = {List.mapInd Args
                  fun {$ I Arg}
                     case Arg of F#_ then {F getCodeGenValue($)}
                     else I
                     end
                  end}
         LabelIsDet = {IsDet Label}
         FeatsAreDet = {All Feats IsDet}
         if LabelIsDet andthen FeatsAreDet then
            {MakeConstructionBasic CS VO Label Feats TheLabel Args VHd VTl}
         elseif FeatsAreDet then PairList Rec in
            PairList = {List.zip Feats Args
                        fun {$ F Arg}
                           case Arg of _#T then F#T else F#Arg end
                        end}
            try
               Rec = {List.toRecord someLabel PairList}
            catch error(kernel(recordConstruction ...) ...) then C in
               {TheLabel getCoord(?C)}
               {CS.reporter
                error(coord: C kind: 'code generation error'
                      msg: 'duplicate feature in record construction')}
               Rec = {AdjoinList someLabel() PairList}
            end
            if {IsTuple Rec} then
               {MakeConstructionTuple CS VO TheLabel Rec VHd VTl}
            else NewArgs in
               NewArgs = {Record.toListInd Rec}
               {MakeConstructionRecord CS VO TheLabel NewArgs VHd VTl}
            end
         else NewArgs in
            NewArgs = {List.zip Feats Args
                       fun {$ FV Arg} F T in
                          case Arg of X#Y then F = X T = Y else T = Arg end
                          if {IsDet FV} andthen
                             ({IsInt FV} orelse {IsLiteral FV})
                          then FV
                          else F
                          end#T
                       end}
            {MakeConstructionRecord CS VO TheLabel NewArgs VHd VTl}
         end
      end
   end

   class CodeGenConstructionOrPattern
      meth getCodeGenValue($)
         if {IsDet {@label getCodeGenValue($)}}
            andthen {All @args
                     fun {$ Arg}
                        case Arg of F#_ then {IsDet {F getCodeGenValue($)}}
                        else true
                        end
                     end}
         then {@value getValue($)}
         else _
         end
      end
   end

   class CodeGenStatement
      meth startCodeGen(Nodes State Reporter OldVs NewVs ?GPNs ?Code)
         CS StartAddr GRegs BodyCode0 NLiveRegs
         BodyCode1 BodyCode2 BodyCode StartLabel EndLabel
      in
         CS = {New CodeStore.'class' init(State Reporter)}
         {ForAll OldVs proc {$ V} {V setFreshReg(CS)} end}
         {ForAll NewVs proc {$ V} {V setFreshReg(CS)} end}
         {CS startDefinition()}
         {CodeGenList Nodes CS StartAddr nil}
         {CS endDefinition(StartAddr nil nil ?GRegs ?BodyCode0 ?NLiveRegs)}
         BodyCode0 = BodyCode1#BodyCode2
         BodyCode = BodyCode1
         {CS getRegNames(GRegs ?GPNs)}
         StartLabel = {NewName}
         EndLabel = {NewName}
         Code =
         lbl(StartLabel)|
         definition(x(0) EndLabel
                    pid('Toplevel abstraction' 0 pos('' 1 0) [sited]
                        NLiveRegs)
                    unit {List.mapInd GRegs fun {$ I _} g(I - 1) end}
                    BodyCode)|
         endDefinition(StartLabel)|
         {Append BodyCode2 [lbl(EndLabel) tailCall(x(0) 0)]}
      end
   end

   class CodeGenTypeOf from CodeGenStatement
      meth codeGen(CS VHd VTl)
         VHd = vEquateConstant(_ @value {@res reg($)} VTl)
      end
   end

   class CodeGenStepPoint from CodeGenStatement
      meth codeGen(CS VHd VTl) VInter1 VInter2 in
         {CodeGenList @statements CS VInter1 VInter2}
         {StepPoint @coord @kind VHd VTl VInter1 VInter2}
      end
   end

   class CodeGenDeclaration from CodeGenStatement
      meth codeGen(CS VHd VTl) Cont1 Cont2 in
         {ForAll @localVars proc {$ V} {V setReg(CS)} end}
         {MakePermanent @localVars VHd Cont1 Cont2 VTl CS}
         {CodeGenList @statements CS Cont1 Cont2}
      end
   end

   class CodeGenSkipNode from CodeGenStatement
      meth codeGen(CS VHd VTl) VInter in
         {StepPoint @coord 'skip' VHd VTl VInter VInter}
      end
   end

   class CodeGenEquation from CodeGenStatement
      meth codeGen(CS VHd VTl)
         {@right makeEquation(CS @left VHd VTl)}
      end
   end

   class CodeGenConstruction from CodeGenConstructionOrPattern
      meth makeEquation(CS VO VHd VTl)
         {MakeConstruction CS VO @label @args VHd VTl}
      end
      meth makeVO(CS VHd VTl ?VO)
         VO = {NewPseudoVariableOccurrence CS}
         CodeGenConstruction, makeEquation(CS VO VHd VTl)
      end
      meth makeRecordArgument(CS VHd VTl $) Label Feats in
         {@label getCodeGenValue(?Label)}
         Feats = {List.mapInd @args
                  fun {$ I Arg}
                     case Arg of F#_ then {F getCodeGenValue($)} else I end
                  end}
         if {IsDet Label} andthen {All Feats IsDet} then
            case Feats of nil then
               VHd = VTl
               constant(Label)
            else PairList Rec RecordArity VArgs in
               PairList = {List.zip Feats @args
                           fun {$ F Arg}
                              case Arg of _#T then F#T else F#Arg end
                           end}
               try
                  Rec = {List.toRecord Label PairList}
               catch error(kernel(recordConstruction ...) ...) then C in
                  {@label getCoord(?C)}
                  {CS.reporter
                   error(coord: C kind: 'code generation error'
                         msg: 'duplicate feature in record construction')}
                  Rec = {AdjoinList Label() PairList}
               end
               RecordArity = if {IsTuple Rec} then {Width Rec}
                             else {Arity Rec}
                             end
               VArgs#VHd = {Record.foldR Rec
                            fun {$ X In#VTl} VArg VHd in
                               {X makeRecordArgument(CS VHd VTl ?VArg)}
                               (VArg|In)#VHd
                            end nil#VTl}
               record(Label RecordArity VArgs)
            end
         else VO in
            VO = {NewPseudoVariableOccurrence CS}
            CodeGenConstruction, makeEquation(CS VO VHd VTl)
            value({VO reg($)})
         end
      end
   end

   class CodeGenDefinition from CodeGenStatement
      meth codeGen(CS VHd VTl)
         VHd0 VTl0 V FileName Line Col PrintName PredId OuterNLiveRegs StateReg
      in
         {@designator getVariable(?V)}
         case @coord of unit then FileName = '' Line = 1 Col = 0
         elseof C then FileName = C.1 Line = C.2 Col = C.3
         end
         PrintName = case {V getPrintName($)} of unit then @printName
                     elseof PN then PN
                     end
         PredId = pid(PrintName {Length @formalArgs} pos(FileName Line Col)
                      if {Member sited @procFlags} then [sited]
                      else nil
                      end
                      OuterNLiveRegs)
\ifdef DEBUG_DEFS
         {System.show PredId}
\endif
         if @isStateUsing then
            if {CS.state getSwitch(staticvarnames $)} then
               {CS newSelfReg(?StateReg)}
            else
               {CS newReg(?StateReg)}
            end
         else
            StateReg = none
         end
         case @toCopy of unit then
            FormalRegs AllRegs AllRegs2 BodyVInter BodyVInstr GRegs Code VInter
            Cont1 Cont2
         in
            {CS startDefinition()}
            FormalRegs = {Map @formalArgs
                          fun {$ V}
                             {V setReg(CS)}
                             {V reg($)}
                          end}
            {MakePermanent @formalArgs BodyVInter Cont1 Cont2 nil CS}
            {CodeGenList @statements CS Cont1 Cont2}
            AllRegs = case @allVariables of nil then nil
                      elseof Vs then {GetRegs Vs}
                      end
            case StateReg of none then
               BodyVInstr = BodyVInter
               VHd0 = VInter
               AllRegs2 = AllRegs
            else
               BodyVInstr = vSetSelf(_ StateReg BodyVInter)
               VHd0 = vGetSelf(_ StateReg VInter)
               AllRegs2 = StateReg|AllRegs
            end
            {CS endDefinition(BodyVInstr FormalRegs AllRegs2 ?GRegs ?Code
                              ?OuterNLiveRegs)}
            VInter = vDefinition(_ {V reg($)} PredId @procedureRef
                                 GRegs Code VTl0)
         else
            VInter FormalRegs AllRegs
            InnerBodyVInter InnerBodyVInstr InnerGRegs InnerCode
            InnerDefinitionReg InnerPredId InnerNLiveRegs
            OuterBodyVInstr OuterBodyVInter2 OuterGRegs OuterCode
         in
            {CS startDefinition()}
            FormalRegs = {Map @formalArgs
                          fun {$ V}
                             {V setReg(CS)}
                             {V reg($)}
                          end}
            {CS startDefinition()}
            {CodeGenList @statements CS InnerBodyVInter nil}
            AllRegs = case @allVariables of nil then nil
                      elseof Vs then {GetRegs Vs}
                      end
            case StateReg of none then
               InnerBodyVInstr = InnerBodyVInter
               VHd0 = VInter
            else
               InnerBodyVInstr = vSetSelf(_ StateReg InnerBodyVInter)
               VHd0 = vGetSelf(_ StateReg VInter)
            end
            {CS endDefinition(InnerBodyVInstr nil AllRegs
                              ?InnerGRegs ?InnerCode ?InnerNLiveRegs)}
            {CS newReg(?InnerDefinitionReg)}
            InnerPredId = {Adjoin PredId
                           pid(case PrintName of '' then ''
                               else {VirtualString.toAtom PrintName#'/body'}
                               end 0
                               4: if {Member sited @procFlags} then [sited]
                                  else nil
                                  end
                               5: InnerNLiveRegs)}
            case @toCopy of nil then Reg OuterBodyVInter1 in
               {CS newReg(?Reg)}
               OuterBodyVInstr = vEquateConstant(_ nil Reg OuterBodyVInter1)
               OuterBodyVInter1 = vDefinitionCopy(_ Reg InnerDefinitionReg
                                                  InnerPredId unit
                                                  InnerGRegs InnerCode
                                                  OuterBodyVInter2)
            elseof Xs then
               fun {MakeCopyList Xs VHd VTl}
                  case Xs of X|Xr then ArgIn VInter1 ConsReg ConsArg1 in
                     ArgIn = {MakeCopyList Xr VHd VInter1}
                     {CS newReg(?ConsReg)}
                     ConsArg1 = if {ForeignPointer.is X} then
                                   procedureRef(X)
                                elseif {IsName X} then
                                   constant(X)
                                else
                                   {Exception.raiseError
                                    compiler(internalTypeError X
                                             'ForeignPointerOrName')}
                                   unit
                                end
                     VInter1 = vEquateRecord(_ '|' 2 ConsReg [ConsArg1 ArgIn]
                                             VTl)
                     value(ConsReg)
                  [] nil then
                     VHd = VTl
                     constant(nil)
                  end
               end
               Reg OuterBodyVInter1
            in
               value(Reg) = {MakeCopyList Xs OuterBodyVInstr OuterBodyVInter1}
               OuterBodyVInter1 = vDefinitionCopy(_ Reg InnerDefinitionReg
                                                  InnerPredId unit
                                                  InnerGRegs InnerCode
                                                  OuterBodyVInter2)
            end
            OuterBodyVInter2 = vCall(_ InnerDefinitionReg nil unit nil)
            {CS endDefinition(OuterBodyVInstr FormalRegs AllRegs
                              ?OuterGRegs ?OuterCode ?OuterNLiveRegs)}
            VInter = vDefinition(_ {V reg($)} PredId @procedureRef
                                 OuterGRegs OuterCode VTl0)
         end
         {StepPoint @coord 'definition' VHd VTl VHd0 VTl0}
         statements <- unit   % hand them to the garbage collector
      end
      meth codeGenApply(Designator Coord ActualArgs CS VHd VTl)
         case @procedureRef of unit then
            VHd = vCall(_ {Designator reg($)} {GetRegs ActualArgs} Coord VTl)
         elseof ID andthen {ForeignPointer.is ID} then
            VHd = vCallProcedureRef(_ ID {GetRegs ActualArgs} Coord VTl)
         end
      end
   end
   class CodeGenClauseBody from CodeGenDefinition
      feat ClauseBodyShared
      meth codeGen(CS VHd VTl)
         %% code for the clause body is only generated when it is applied
         VHd = VTl
      end
      meth codeGenApply(Designator Coord ActualArgs CS VHd VTl)
         ActualArgs = nil   % by construction
         VHd = self.ClauseBodyShared
         VTl = nil
         if {IsFree VHd} then Label Addr in
            {CS newLabel(?Label)}
            VHd = vShared(_ _ Label Addr)
            {CodeGenList @statements CS Addr nil}
         end
      end
   end

   class CodeGenApplication from CodeGenStatement
      meth codeGen(CS VHd VTl)
         if {IsDet self.codeGenMakeEquateLiteral} then VHd0 VTl0 in
            %% the application is either a toplevel application of NewName
            %% or any application of NewUniqueName:
            VHd0 = vEquateConstant(_ self.codeGenMakeEquateLiteral
                                   {{List.last @actualArgs} reg($)} VTl0)
            {StepPoint @coord 'name generation' VHd VTl VHd0 VTl0}
         else
            {MakeApplication @designator @coord @actualArgs CS VHd VTl}
         end
      end
   end

   class CodeGenIfNode from CodeGenStatement
      meth codeGen(CS VHd VTl) Value in
         {@arbiter getCodeGenValue(?Value)}
         if {IsDet Value} andthen Value == true then
            {@consequent codeGen(CS VHd VTl)}
         elseif {IsDet Value} andthen Value == false then
            {@alternative codeGen(CS VHd VTl)}
         else ThenAddr AltAddr ErrAddr VInter1 VInter2 in
            {@consequent codeGen(CS ThenAddr nil)}
            {@alternative codeGen(CS AltAddr nil)}
            {MakeException kernel boolCaseType @coord [@arbiter] CS
             ErrAddr nil}
            VInter1 = vTestBool(_ {@arbiter reg($)} ThenAddr AltAddr ErrAddr
                                @coord VInter2)
            {StepPoint @coord 'conditional' VHd VTl VInter1 VInter2}
         end
      end
   end

   class CodeGenIfClause
      meth codeGen(CS VHd VTl)
         {CodeGenList @statements CS VHd VTl}
      end
   end

   class CodeGenPatternCase from CodeGenStatement
      meth codeGen(CS VHd VTl)
         {OptimizePatterns {@arbiter reg($)}
          {Map @clauses
           fun {$ Clause}
              {Clause makePattern({@arbiter getCodeGenValue($)} CS $)}
           end}
          @alternative VHd VTl @coord CS}
         {ForAll @clauses proc {$ Clause} {Clause warnUnreachable(CS)} end}
      end
   end

   class CodeGenPatternClause
      attr reached
      meth makePattern(Arbiter CS $)
         {@pattern makePattern(Arbiter nil $ nil {NewDictionary} CS)}#self
      end
      meth codeGenPattern(Mapping VHd VTl CS) VInter1 VInter2 in
         if {IsDet @reached} then
            {Exception.raiseError
             compiler(internal {@statements.1 getCoord($)})}
         end
         @reached = true
         {@pattern assignRegs(nil Mapping)}
         {MakePermanent @localVars VHd VInter1 VInter2 VTl CS}
         {CodeGenList @statements CS VInter1 VInter2}
      end
      meth warnUnreachable(CS)
         if {IsFree @reached} then
            {CS.reporter warn(coord: {@statements.1 getCoord($)}
                              kind: 'code generation warning'
                              msg: 'statement unreachable')}
         end
      end
   end

   class CodeGenSideCondition
      meth makePattern(Arbiter Pos Hd Tl Seen CS) Inter in
         {@pattern makePattern(Arbiter Pos Hd Inter Seen CS)}
         Inter = Pos#expr(self)|Tl
      end
      meth assignRegs(Pos Mapping)
         {@pattern assignRegs(Pos Mapping)}
      end
      meth codeGenTest(ThenVInstr ElseVInstr VHd VTl CS)
         ErrVInstr VInter1 VInter2 VInter3 VInter4 VInter5
      in
         {ForAll @localVars proc {$ V} {V setReg(CS)} end}
         {MakePermanent @localVars VHd VInter1 VInter2 VInter3 CS}
         {CodeGenList @statements CS VInter1 VInter2}
         {MakeException kernel boolCaseType @coord [@arbiter] CS ErrVInstr nil}
         VInter4 = vTestBool(_ {@arbiter reg($)} ThenVInstr ElseVInstr
                             ErrVInstr @coord VInter5)
         {StepPoint @coord 'conditional' VInter3 VTl VInter4 VInter5}
      end
   end

   fun {SortPairList PairList}
      {Sort {Map PairList fun {$ F#_} F end}
       fun {$ F1 F2}
          if {IsObject F1} then
             if {IsObject F2} then {F1 getPrintName($)} < {F2 getPrintName($)}
             else false
             end
          else
             if {IsObject F2} then true
             else {CompilerSupport.featureLess F1 F2}
             end
          end
       end}
   end

   class CodeGenRecordPattern from CodeGenConstructionOrPattern
      meth makePattern(Arbiter Pos Hd Tl Seen CS)
         TheLabel IsNonBasic LabelV PairList Inter
      in
         {@label getCodeGenValue(?TheLabel)}
         LabelV = if {IsDet TheLabel} then TheLabel
                  else
                     IsNonBasic = true
                     @label
                  end
         PairList = {List.mapInd @args
                     fun {$ I Arg}
                        case Arg of F#P then Feature in
                           {F getCodeGenValue(?Feature)}
                           if {IsDet Feature} then Feature#P
                           else
                              IsNonBasic = true
                              F#P
                           end
                        else I#Arg
                        end
                     end}
         if @isOpen then
            Hd = Pos#label(LabelV)|{FoldL PairList
                                    proc {$ Hd F#_ Tl}
                                       Hd = Pos#feature(F)|Tl
                                    end $ Inter}
         elseif {IsDet IsNonBasic} then ArityV in
            %% We sort the arity to improve the approximation for
            %% comparing partially known arities.  Variables are
            %% sorted to the back and by printname.
            ArityV = {SortPairList PairList}
            Hd = Pos#nonbasic(LabelV ArityV)|Inter
         else Rec RecordArity in
            try
               Rec = {List.toRecord TheLabel PairList}
            catch error(kernel(recordConstruction ...) ...) then Coord in
               {@label getCoord(?Coord)}
               {CS.reporter
                error(coord: Coord kind: 'code generation error'
                      msg: 'duplicate feature in record construction')}
               Rec = {AdjoinList TheLabel() PairList}
            end
            RecordArity = if {IsTuple Rec} then {Width Rec}
                          else {Arity Rec}
                          end
            if {IsDet Arbiter}
               andthen {IsRecord Arbiter}
               andthen {Label Arbiter} == TheLabel
               andthen {Arity Arbiter} == {Arity Rec}
               andthen {Record.all Arbiter
                        fun {$ X}
                           {HasFeature X Core.imAVariableOccurrence}
                        end}
            then
               Hd = Pos#get({Record.foldRInd Arbiter
                             fun {$ F X In} F#{X reg($)}|In end nil})|Inter
            elseif RecordArity == 0 then
               Hd = Pos#scalar(TheLabel)|Inter
            else
               Hd = Pos#record(TheLabel RecordArity)|Inter
            end
         end
         {FoldL PairList
          proc {$ Hd F#S Tl}
             {S makePattern(if {IsDet Arbiter} andthen {IsRecord Arbiter}
                               andthen {HasFeature Arbiter F}
                            then {Arbiter.F getCodeGenValue($)}
                            else _
                            end {Append Pos [F]} Hd Tl Seen CS)}
          end Inter Tl}
      end
      meth assignRegs(Pos Mapping)
         {List.forAllInd @args
          proc {$ I Arg}
             case Arg of F#P then Value FV in
                {F getCodeGenValue(?Value)}
                FV = if {IsDet Value} then Value
                     else F
                     end
                {P assignRegs({Append Pos [FV]} Mapping)}
             else {Arg assignRegs({Append Pos [I]} Mapping)}
             end
          end}
      end
   end

   class CodeGenEquationPattern
      meth makePattern(Arbiter Pos Hd Tl Seen CS) Inter in
         {@right makePattern(Arbiter Pos Hd Inter Seen CS)}
         {@left makePattern(Arbiter Pos Inter Tl Seen CS)}
      end
      meth assignRegs(Pos Mapping)
         {@left assignRegs(Pos Mapping)}
         {@right assignRegs(Pos Mapping)}
      end
   end

   local
      class CodeGenAbstractElse
         meth codeGenPattern(Mapping VHd VTl CS) Reg VO in
            Reg = {PosToReg nil Mapping}
            VO = {New PseudoVariableOccurrence init(Reg)}
            {self codeGenWithArbiter(CS VO VHd VTl)}
         end
      end
   in
      class CodeGenElseNode from CodeGenAbstractElse
         meth codeGen(CS VHd VTl)
            {CodeGenList @statements CS VHd VTl}
         end
         meth codeGenWithArbiter(CS VO VHd VTl)
            {CodeGenList @statements CS VHd VTl}
         end
      end
      class CodeGenNoElse from CodeGenAbstractElse
         meth codeGen(CS VHd VTl)
            {MakeException kernel noElse @coord nil CS VHd VTl}
         end
         meth codeGenWithArbiter(CS VO VHd VTl)
            {MakeException kernel noElse @coord [VO] CS VHd VTl}
         end
      end
   end

   class CodeGenTryNode from CodeGenStatement
      meth codeGen(CS VHd VTl) TryBodyVInstr CatchBodyVInstr Cont1 Cont2 in
         {CodeGenList @tryStatements CS TryBodyVInstr vPopEx(_ @coord nil)}
         {@exception setReg(CS)}
         {MakePermanent [@exception] CatchBodyVInstr Cont1 Cont2 nil CS}
         {CodeGenList @catchStatements CS Cont1 Cont2}
         VHd = vExHandler(_ TryBodyVInstr {@exception reg($)}
                          CatchBodyVInstr @coord VTl _)
      end
   end

   class CodeGenLockNode from CodeGenStatement
      meth codeGen(CS VHd VTl) SharedData Cont1 in
         VHd = vLockThread(_ {@lockVar reg($)} @coord Cont1 SharedData)
         {CodeGenList @statements CS Cont1 vLockEnd(_ @coord VTl SharedData)}
      end
   end

   class CodeGenClassNode from CodeGenStatement
      meth codeGen(CS VHd VTl)
         VHd0 VTl0 From Attr Feat Prop PN Meth PrintName
         VInter1 VInter2 VInter3
      in
         local Cont1 Cont2 Cont3 in
            {MakeFromProp @parents CS VHd0 Cont1 ?From}
            {MakeFromProp @properties CS Cont1 Cont2 ?Prop}
            {MakeAttrFeat 'attr' @attributes CS Cont2 Cont3 ?Attr}
            {MakeAttrFeat 'feat' @features CS Cont3 VInter1 ?Feat}
         end
         PN = case @printName of '' then X in
                 {{@designator getVariable($)} getPrintName(X)}
                 case X of unit then '_' else X end
              elseof X then X
              end
         Meth = {NewPseudoVariableOccurrence CS}
         case @methods of _|_ then
            fun {MakeMethods Methods VHd VTl}
               case Methods of M|Mr then MethReg VInter in
                  {CS newReg(?MethReg)}
                  {M makeQuadruple(PN CS MethReg @isToplevel VHd VInter)}
                  value(MethReg)|{MakeMethods Mr VInter VTl}
               [] nil then
                  VHd = VTl
                  nil
               end
            end
            Cont Args
         in
            Args = {MakeMethods @methods VInter1 Cont}
            Cont = vEquateRecord(_ '#' {Length @methods} {Meth reg($)}
                                 Args VInter2)
         [] nil then
            VInter1 = vEquateConstant(_ '#' {Meth reg($)} VInter2)
         end
         methods <- unit   % hand them to the garbage collector
         local Reg in
            {CS newReg(?Reg)}
            VInter2 = vEquateConstant(_ PN Reg VInter3)
            PrintName = {New PseudoVariableOccurrence init(Reg)}
         end
         {MakeRunTimeProcApplication 'Object.\'class\'' {CoordNoDebug @coord}
          [From Meth Attr Feat Prop PrintName @designator] CS VInter3 VTl0}
         {StepPoint @coord 'definition' VHd VTl VHd0 VTl0}
      end
   end

   fun {GetMethPrintName Node}
      if {HasFeature Node Core.imAVariableOccurrence} then
         {{Node getVariable($)} getPrintName($)}
      else
         {System.printName {Node getValue($)}}
      end
   end

   class CodeGenMethod
      feat MessagePatternVO MessageVO
      meth isOptimizable($)
         {Not @isOpen} andthen @messageDesignator == unit andthen
         {All @formalArgs
          fun {$ Formal} Value in
             {{Formal getFeature($)} getCodeGenValue(?Value)}
             {IsDet Value} andthen ({IsInt Value} orelse {IsLiteral Value})
          end}
      end
      meth makeQuadruple(PrintName CS Reg IsToplevel VHd VTl)
         HasDefaults FileName Line Col FastMeth RecordArity SlowMeth
         VInter1 VInter2 X = unit
      in
         HasDefaults = {Some @formalArgs
                        fun {$ Formal} {Formal hasDefault($)} end}
         case @coord of unit then FileName = '' Line = 1 Col = 0
         elseof C then FileName = C.1 Line = C.2 Col = C.3
         end
         if CodeGenMethod, isOptimizable($) then
            {CS newReg(?FastMeth)}
            CodeGenMethod, SortFormals(CS ?RecordArity)
         else
            FastMeth = unit
         end
         CodeGenMethod, MakeSlowMeth(PrintName FileName Line Col HasDefaults
                                     IsToplevel CS VHd VInter1 FastMeth
                                     ?SlowMeth)
         CodeGenMethod, MakeFastMeth(PrintName FileName Line Col RecordArity CS
                                     VInter1 VInter2 FastMeth)
         case FastMeth of unit then
            VInter2 = vEquateRecord(_ '|' 2 Reg
                                    [{@label makeRecordArgument(CS X X $)}
                                     value(SlowMeth)] VTl)
         elseif HasDefaults then Args VO VInter3 in
            Args = {Map @formalArgs
                    fun {$ Formal}
                       {Formal getFeature($)}#{Formal getDefault($)}
                    end}
            VO = {NewPseudoVariableOccurrence CS}
            {MakeConstruction CS VO @label Args VInter2 VInter3}
            VInter3 = vEquateRecord(_ '#' [1 2 default fast] Reg
                                    [{@label makeRecordArgument(CS X X $)}
                                     value(SlowMeth) value({VO reg($)})
                                     value(FastMeth)] VTl)
         else
            VInter2 = vEquateRecord(_ '#' [1 2 fast] Reg
                                    [{@label makeRecordArgument(CS X X $)}
                                     value(SlowMeth) value(FastMeth)] VTl)
         end
      end
      meth MakeSlowMeth(PrintName FileName Line Col HasDefaults IsToplevel CS
                        VHd VTl FastMeth ?SlowMeth)
         PredId NLiveRegs Cont1 MessageReg BodyVInstr
         AllRegs GRegs Code VInter
      in
         PredId = pid({VirtualString.toAtom
                       case PrintName of unit then '_' else PrintName end#
                       ','#{GetMethPrintName @label}}
                      1 pos(FileName Line Col) nil NLiveRegs)
\ifdef DEBUG_DEFS
         {System.show PredId}
\endif
         CodeGenMethod, MakeArityCheckInit(HasDefaults CS VHd Cont1)
         {CS startDefinition()}
         case @messageDesignator of unit then
            {CS newReg(?MessageReg)}
         elseof V then
            {V setReg(CS)}
            {V reg(?MessageReg)}
         end
         self.MessageVO = {New PseudoVariableOccurrence init(MessageReg)}
         CodeGenMethod, MakePattern(CS BodyVInstr VInter)
         case FastMeth of unit then
            CodeGenMethod, MakeBody(?AllRegs CS VInter nil)
         else FormalRegs Coord in
            FormalRegs = {Map @formalArgs
                          fun {$ Formal}
                             {{Formal getVariable($)} reg($)}
                          end}
            Coord = {CoordNoDebug @coord}
            case @procedureRef of unit then
               VInter = vCall(_ FastMeth FormalRegs Coord nil)
            elseof ID andthen {ForeignPointer.is ID} then
               VInter = vCallProcedureRef(_ ID FormalRegs Coord nil)
            end
            AllRegs = nil
         end
         {CS endDefinition(BodyVInstr [MessageReg] AllRegs
                           ?GRegs ?Code ?NLiveRegs)}
         {CS newReg(?SlowMeth)}
         Cont1 = vDefinition(_ SlowMeth PredId unit GRegs Code VTl)
      end
      meth MakeArityCheckInit(HasDefaults CS VHd VTl) LabelReg LabelVO in
         self.MessagePatternVO = {NewPseudoVariableOccurrence CS}
         {CS newReg(?LabelReg)}
         LabelVO = {New PseudoVariableOccurrence init(LabelReg)}
         LabelVO.value = 'messagePattern'
         {MakeConstruction CS self.MessagePatternVO LabelVO
          {Map @formalArgs
           fun {$ Formal} VO in
              VO = {NewPseudoVariableOccurrence CS}
              VO.value = unit
              {Formal getFeature($)}#VO
           end} VHd VTl}
      end
      meth MakePattern(CS BodyVInstr VInter)
         Lab ReqArgs OptArgs Pattern Statement
      in
         {@label getCodeGenValue(?Lab)}
         ReqArgs#OptArgs = {FoldR @formalArgs
                            fun {$ Arg In1#In2}
                               if {Arg hasDefault($)} then In1#(Arg|In2)
                               else F Value in
                                  {Arg getFeature(?F)}
                                  {F getCodeGenValue(?Value)}
                                  (if {IsDet Value} then Value else F end#
                                   {Arg getVariable($)}|In1)#In2
                               end
                            end nil#nil}
         if OptArgs \= nil orelse @isOpen then Inter in
            {FoldL ReqArgs
             proc {$ Hd F#_ Tl}
                Hd = nil#feature(F)|Tl
             end Pattern Inter}
            Inter = if @isOpen then nil
                    else [nil#expr(self)]
                    end
            Statement = {New CodeGenMethodBody
                         init(self.MessageVO ReqArgs OptArgs VInter)}
         elseif {IsFree Lab} orelse {Not {IsLiteral Lab}} then
            Pattern = [nil#nonbasic(@label {Map ReqArgs fun {$ F#_} F end})]
            Statement = {New CodeGenMethodBody
                         init(self.MessageVO ReqArgs OptArgs VInter)}
         elseif {Some ReqArgs fun {$ F#_} {IsObject F} end} then
            Pattern = [nil#nonbasic(Lab {Map ReqArgs fun {$ F#_} F end})]
            Statement = {New CodeGenMethodBody
                         init(self.MessageVO ReqArgs OptArgs VInter)}
         else Rec RecordArity in
            try
               Rec = {List.toRecord Lab ReqArgs}
            catch error(kernel(recordConstruction ...) ...) then C in
               {@label getCoord(?C)}
               {CS.reporter
                error(coord: C kind: 'code generation error'
                      msg: 'duplicate feature in method head')}
               Rec = {AdjoinList Lab ReqArgs}
            end
            RecordArity = if {IsTuple Rec} then {Width Rec}
                          else {Arity Rec}
                          end
            case RecordArity of 0 then
               Pattern = [nil#scalar(Lab)]
            else
               Pattern = [nil#record(Lab RecordArity)]
            end
            Statement = {New CodeGenMethodBody
                         init(self.MessageVO {Record.toListInd Rec}
                              OptArgs VInter)}
         end
         {OptimizePatterns {self.MessageVO reg($)} [Pattern#Statement]
          self BodyVInstr nil @coord CS}
      end
      meth MakeFastMeth(PrintName FileName Line Col RecordArity CS VHd VTl
                        FastMeth)
         case FastMeth of unit then
            VHd = VTl
         else PredId NLiveRegs FormalRegs AllRegs BodyVInstr GRegs Code in
            PredId = pid({VirtualString.toAtom
                          case PrintName of unit then '_' else PrintName end#
                          ','#{GetMethPrintName @label}#'/fast'}
                         RecordArity pos(FileName Line Col) nil NLiveRegs)
\ifdef DEBUG_DEFS
            {System.show PredId}
\endif
            {CS startDefinition()}
            FormalRegs = {Map @formalArgs
                          fun {$ Formal} V = {Formal getVariable($)} in
                             {V setFreshReg(CS)}
                             {V reg($)}
                          end}
            CodeGenMethod, MakeBody(?AllRegs CS BodyVInstr nil)
            {CS endDefinition(BodyVInstr FormalRegs AllRegs
                              ?GRegs ?Code ?NLiveRegs)}
            VHd = vDefinition(_ FastMeth PredId @procedureRef GRegs Code VTl)
         end
      end
      meth SortFormals(CS ?RecordArity) PairList Rec in
         %% Sort the formal arguments by feature
         %% (important for order of fast methods' formal parameters):
         PairList = {Map @formalArgs
                     fun {$ Formal}
                        {{Formal getFeature($)} getCodeGenValue($)}#Formal
                     end}
         try
            Rec = {List.toRecord someLabel PairList}
            RecordArity = if {IsTuple Rec} then {Width Rec}
                          else {Arity Rec}
                          end
            formalArgs <- {Record.toList Rec}
         catch error(kernel(recordConstruction ...)...) then C in
            {@label getCoord(?C)}
            {CS.reporter
             error(coord: C kind: 'code generation error'
                   msg: 'duplicate feature in record construction')}
            RecordArity = {Length @formalArgs}
         end
      end
      meth MakeBody(?AllRegs CS VHd VTl) Vs in
         AllRegs = case @allVariables of nil then nil
                   elseof Vs then {GetRegs Vs}
                   end
         Vs = {FoldR @formalArgs fun {$ F In} {F getVariable($)}|In end
               case @messageDesignator of unit then nil
               elseof V then [V]
               end}
         if {CS.state getSwitch(staticvarnames $)} then
            StateReg Cont1 Cont2 Cont3
         in
            {CS newSelfReg(?StateReg)}
            {MakePermanent {New PseudoVariableOccurrence init(StateReg)}|Vs
             VHd Cont1 Cont3 VTl CS}
            %--** would it not be better to get self before making permanent?
            Cont1 = vGetSelf(_ StateReg Cont2)
            {CodeGenList @statements CS Cont2 Cont3}
         else Cont1 Cont2 in
            {MakePermanent Vs VHd Cont1 Cont2 VTl CS}
            {CodeGenList @statements CS Cont1 Cont2}
         end
         statements <- unit   % hand them to the garbage collector
      end
      meth codeGenTest(ThenVInstr ElseVInstr VHd VTl CS)
         ResultVO VInter ErrVInstr
      in
         ResultVO = {NewPseudoVariableOccurrence CS}
         {MakeRunTimeProcApplication 'aritySublist' {CoordNoDebug @coord}
          [self.MessageVO self.MessagePatternVO ResultVO] CS VHd VInter}
         {MakeException kernel boolCaseType unit [ResultVO] CS ErrVInstr nil}
         VInter = vTestBool(_ {ResultVO reg($)} ThenVInstr ElseVInstr
                            ErrVInstr unit VTl)
      end
      meth codeGenPattern(Mapping VHd VTl CS) SelfVO VInter in
         SelfVO = {NewPseudoVariableOccurrence CS}
         VHd = vGetSelf(_ {SelfVO reg($)} VInter)
         {MakeException object arityMismatch @coord [self.MessageVO SelfVO]
          CS VInter VTl}
      end
   end

   class CodeGenMethodBody
      attr messageVO reqArgs optArgs vInter
      meth init(MessageVO ReqArgs OptArgs VInter)
         messageVO <- MessageVO
         reqArgs <- ReqArgs
         optArgs <- OptArgs
         vInter <- VInter
      end
      meth codeGenPattern(Mapping VHd VTl CS)
         {ForAll @reqArgs
          proc {$ F#V}
             {V reg({PosToReg [F] Mapping})}   % set it
          end}
         {FoldL @optArgs
          proc {$ VHd Arg VTl}
             {Arg bindMethFormal(@messageVO CS VHd VTl)}
          end VHd @vInter}
         VTl = nil
      end
   end

   class CodeGenMethFormal
      meth getDefault($)
         {New Core.valueNode init(RunTime.literals.ooRequiredArg unit)}
      end
   end
   class CodeGenMethFormalOptional
      meth getDefault($)
         {New Core.valueNode init(RunTime.literals.ooDefaultVar unit)}
      end
      meth bindMethFormal(MessageVO CS VHd VTl)
         {@arg setFreshReg(CS)}
         VHd = VTl
      end
   end
   class CodeGenMethFormalWithDefault
      meth getDefault($)
         case @default of unit then
            {New Core.valueNode init(RunTime.literals.ooDefaultVar unit)}
         elseof VO then VO
         end
      end
      meth bindMethFormal(MessageVO CS VHd VTl)
         Coord CND FeatureVO ArbiterVO TempVO
         ArgReg ThenVInstr ElseVInstr ErrVInstr Cont1 Cont2
      in
         {@arg setFreshReg(CS)}
         {@arg getCoord(?Coord)}
         CND = {CoordNoDebug Coord}
         {@feature makeVO(CS VHd Cont1 ?FeatureVO)}
         ArbiterVO = {NewPseudoVariableOccurrence CS}
         TempVO = {NewPseudoVariableOccurrence CS}
         {MakeRunTimeProcApplication 'Record.testFeature' CND
          [MessageVO FeatureVO ArbiterVO TempVO] CS Cont1 Cont2}
         Cont2 = vTestBool(_ ArbiterVO.reg ThenVInstr ElseVInstr ErrVInstr
                           unit VTl)
         {@arg reg(?ArgReg)}
         ThenVInstr = vUnify(_ ArgReg TempVO.reg nil)
         case @default of unit then ElseVInstr = nil
         elseof VO then ArgVO in
            ArgVO = {New PseudoVariableOccurrence init(ArgReg)}
            {VO makeEquation(CS ArgVO ElseVInstr nil)}
         end
         {MakeException kernel boolCaseType Coord [ArbiterVO] CS ErrVInstr nil}
      end
   end

   class CodeGenObjectLockNode from CodeGenStatement
      meth codeGen(CS VHd VTl) Reg Arg SharedData Cont1 Cont2 in
         {CS newReg(?Reg)}
         Arg = {New PseudoVariableOccurrence init(Reg)}
         {MakeRunTimeProcApplication 'ooGetLock' {CoordNoDebug @coord}
          [Arg] CS VHd Cont1}
         Cont1 = vLockThread(_ Reg @coord Cont2 SharedData)
         {CodeGenList @statements CS Cont2 vLockEnd(_ @coord VTl SharedData)}
      end
   end

   class CodeGenGetSelf from CodeGenStatement
      meth codeGen(CS VHd VTl)
         VHd = vGetSelf(_ {@destination reg($)} VTl)
      end
   end

   class CodeGenExceptionNode from CodeGenStatement
      meth codeGen(CS VHd VTl)
         {MakeException kernel noElse @coord nil CS VHd VTl}
      end
   end

   class CodeGenValueNode
      meth getCodeGenValue($)
         @value
      end
      meth makeEquation(CS VO VHd VTl)
         VHd = vEquateConstant(_ @value {VO reg($)} VTl)
      end
      meth makeVO(CS VHd VTl ?VO)
         VO = {NewPseudoVariableOccurrence CS}
         VO.value = @value
         VHd = vEquateConstant(_ @value {VO reg($)} VTl)
      end
      meth makeRecordArgument(CS VHd VTl $)
         VHd = VTl
         constant(@value)
      end
      meth makePattern(Arbiter Pos Hd Tl Seen CS)
         Hd = Pos#scalar(@value)|Tl
      end
      meth assignRegs(Pos Mapping)
         skip
      end
   end

   class CodeGenVariable
      attr reg
      meth setReg(CS)
         @reg = {CS newVariableReg(self $)}
      end
      meth setFreshReg(CS)
         reg <- {CS newVariableReg(self $)}
      end
      meth reg($)
         @reg
      end
   end

   class CodeGenVariableOccurrence
      meth getCodeGenValue($)
         if {IsDet @value} andthen @value \= self then
            {@value getCodeGenValue($)}
         else _
         end
      end
      meth reg($) Value = @value in
         if {IsDet Value}
            andthen {IsObject Value}
            andthen {HasFeature Value Core.imAVariableOccurrence}
         then Reg in
            {{Value getVariable($)} reg(?Reg)}
            %% This variable occurrence may have been equated to a variable
            %% occurrence invented by valToSubst.  Such occurrences are
            %% assigned no registers, so we check for this case explicitly:
            if {IsDet Reg} then Reg
            else {@variable reg($)}
            end
         else {@variable reg($)}
         end
      end
      meth makeEquation(CS VO VHd VTl) Value in
         CodeGenVariableOccurrence, getCodeGenValue(?Value)
         if {IsDet Value}
            andthen ({IsNumber Value} orelse {IsLiteral Value})
         then
            VHd = vEquateConstant(_ Value {{VO getVariable($)} reg($)} VTl)
         else Value in
            {VO getCodeGenValue(?Value)}
            if {IsDet Value}
               andthen ({IsNumber Value} orelse {IsLiteral Value})
            then
               VHd = vEquateConstant(_ Value {@variable reg($)} VTl)
            else
               {MakeUnify {@variable reg($)} {{VO getVariable($)} reg($)}
                VHd VTl}
            end
         end
         %% If above just VO was used instead of {VO getVariable($)}, then
         %% incorrect code would be generated:  The static analysis annotates
         %% the occurrences to be equal, so a trivial (and wrong) vUnify(R R _)
         %% would be generated.
      end
      meth makeRecordArgument(CS VHd VTl $) Value in
         VHd = VTl
         CodeGenVariableOccurrence, getCodeGenValue(?Value)
         if {IsDet Value} andthen ({IsNumber Value} orelse {IsLiteral Value})
         then constant(Value)
         else value({@variable reg($)})
         end
      end
      meth makeVO(CS VHd VTl ?VO)
         VHd = VTl
         VO = self
      end
      meth makePattern(Arbiter Pos Hd Tl Seen CS) Value in
         CodeGenVariableOccurrence, getCodeGenValue(?Value)
         if {IsDet Value} andthen ({IsNumber Value} orelse {IsLiteral Value})
         then
            Hd = Pos#scalar(Value)|Tl
         else
            Hd = Pos#constant(self)|Tl
         end
      end
      meth assignRegs(Pos Mapping)
         skip
      end
   end

   fun {Assoc Xs V}
      case Xs of !V#Pos|_ then Pos
      [] _#_|Xr then {Assoc Xr V}
      [] nil then unit
      end
   end

   class CodeGenPatternVariableOccurrence from CodeGenVariableOccurrence
      meth makePattern(Arbiter Pos Hd Tl Seen CS)
         case {@variable getPrintName($)} of unit then Xs in
            Xs = {Dictionary.condGet Seen 1 nil}
            case {Assoc Xs @variable} of unit then
               {Dictionary.put Seen 1 @variable#Pos|Xs}
               Hd = Tl
            elseof FirstPos then
               Hd = Pos#equal(FirstPos)|Tl
            end
         elseof PrintName then
            case {Dictionary.condGet Seen PrintName unit} of unit then
               {Dictionary.put Seen PrintName Pos}
               Hd = Tl
            elseof FirstPos then
               Hd = Pos#equal(FirstPos)|Tl
            end
         end
      end
      meth assignRegs(Pos Mapping) Reg in
         {self reg(?Reg)}
         if {IsFree Reg} then
            Reg = {PosToReg Pos Mapping}
         end
      end
      meth makeEquation(CS VO VHd VTl)
         {MakeUnify {@variable reg($)} {VO reg($)} VHd VTl}
      end
   end

   class CodeGenToken
      meth getCodeGenValue($)
         _
      end
      meth getDefinition($)
         unit
      end
   end

   class CodeGenProcedureToken from CodeGenToken
      meth getDefinition($)
         @definition
      end
   end
end
