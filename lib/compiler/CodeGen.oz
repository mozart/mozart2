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
   CompilerSupport(isBuiltin featureLess) at 'x-oz://boot/CompilerSupport'
   System(printName)
   Builtins(getInfo)
   Core
   RunTime(literals procValues)
export
   %% mixin classes for the abstract syntax:
   statement: CodeGenStatement
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
   abstractElse: CodeGenAbstractElse
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
   failNode: CodeGenFailNode
   condNode: CodeGenCondNode
   choicesAndDisjunctions: CodeGenChoicesAndDisjunctions
   orNode: CodeGenOrNode
   disNode: CodeGenDisNode
   choiceNode: CodeGenChoiceNode
   clause: CodeGenClause
   valueNode: CodeGenValueNode
   variable: CodeGenVariable
   variableOccurrence: CodeGenVariableOccurrence
   patternVariableOccurrence: CodeGenPatternVariableOccurrence

   %% mixin classes for token representations:
   token: CodeGenToken
   procedureToken: CodeGenProcedureToken
define
   \insert CodeEmitter
   \insert CodeStore

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

   proc {StepPoint Coord Comment VHd VTl VInter1 VInter2}
      if {IsStep Coord} then
         VInter2 = nil
         VHd = vStepPoint(_ VInter1 Coord Comment VTl)
      else
         VHd = VInter1
         VInter2 = VTl
      end
   end

   proc {MakeUnify Reg1 Reg2 VHd VTl}
      if Reg1 == Reg2 then
         %% If we left it in, it would create unnecessary Reg occurrences.
         VHd = VTl
      else
         VHd = vUnify(_ Reg1 Reg2 VTl)
      end
   end

   proc {MakePermanent Vs ?Regs VHd VTl}
      Regs = {FoldR Vs
              fun {$ V In}
                 if {V getPrintName($)} \= unit then {V reg($)}|In
                 else In
                 end
              end nil}
      case Regs of nil then
         VHd = VTl
      else
         VHd = vMakePermanent(_ Regs VTl)
      end
   end

   proc {Clear Regs VHd VTl}
      case Regs of nil then
         VHd = VTl
      else
         VHd = vClear(_ Regs VTl)
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
         else
            if CS.debugInfoControlSwitch then skip
            else
               case Builtinname of 'Value.\'.\'' then
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
               [] 'Object.\'@\'' then [Arg1 Arg2] = ActualArgs Atomname in
                  {Arg1 getCodeGenValue(?Atomname)}
                  if {IsDet Atomname} andthen {IsLiteral Atomname} then
                     VHd = vInlineAt(_ Atomname {Arg2 reg($)} VTl)
                  end
               [] 'Object.\'<-\'' then [Arg1 Arg2] = ActualArgs Atomname in
                  {Arg1 getCodeGenValue(?Atomname)}
                  if {IsDet Atomname} andthen {IsLiteral Atomname} then
                     VHd = vInlineAssign(_ Atomname {Arg2 reg($)} VTl)
                  end
               [] 'Object.\',\'' then [Arg1 Arg2] = ActualArgs Value in
                  {Arg2 getCodeGenValue(?Value)}
                  if {IsDet Value} andthen {IsRecord Value}
                     andthen {Record.all Value
                              fun {$ Arg}
                                 {HasFeature Arg Core.imAVariableOccurrence}
                                 andthen {IsDet {Arg reg($)}}
                              end}
                  then
                     RecordArity ActualArgs Regs Cont1 in
                     RecordArity = if {IsTuple Value} then {Width Value}
                                   else {Arity Value}
                                   end
                     ActualArgs = {Record.toList Value}
                     {MakeMessageArgs ActualArgs CS ?Regs VHd Cont1}
                     if {{Arg1 getVariable($)} isToplevel($)} then
                        Cont1 = vGenCall(_ {Arg1 reg($)} true
                                         {Label Value} RecordArity Regs
                                         Coord VTl)
                     else
                        Cont1 = vApplMeth(_ {Arg1 reg($)}
                                          {Label Value} RecordArity Regs
                                          Coord VTl)
                     end
                  end
               else skip
               end
            end
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
            VHd = vFastCall(_ Value {GetRegs ActualArgs} Coord VTl)
         end
      end
   in
      proc {MakeApplication Designator Coord ActualArgs CS VHd VTl}
         VInter NewActualArgs Value Def
      in
         {LoadActualArgs ActualArgs CS VHd VInter ?NewActualArgs}
         {Designator getValue(?Value)}
         if {HasFeature Value Core.imAToken}
            andthen ({Value getDefinition(?Def)} Def \= unit)
         then
            if {IsProcedure Def} then
               {MakeDirectApplication Def Coord NewActualArgs CS VInter VTl}
            else   % it's a Definition node
               {Def codeGenApply(Designator Coord NewActualArgs CS VInter VTl)}
            end
         elseif {{Designator getVariable($)} isToplevel($)}
            andthen {Not CS.debugInfoControlSwitch}
         then
            VInter = vGenCall(_ {Designator reg($)}
                              false '' {Length NewActualArgs}
                              {GetRegs NewActualArgs} Coord VTl)
         else
            VInter = vCall(_ {Designator reg($)} {GetRegs NewActualArgs}
                           Coord VTl)
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

   proc {MakeException Literal Coord VOs CS VHd VTl} Reg VO VArgs VInter in
      {CS newReg(?Reg)}
      VO = {New PseudoVariableOccurrence init(Reg)}
      VArgs = constant(Literal)|{Append
                                 case Coord of unit then
                                    [constant('') constant(unit)]
                                 else
                                    [constant(Coord.1) constant(Coord.2)]
                                 end
                                 {Map VOs fun {$ VO} value({VO reg($)}) end}}
      VHd = vEquateRecord(_ 'kernel' {Length VArgs} Reg VArgs VInter)
      {MakeRunTimeProcApplication 'RaiseError' {CoordNoDebug Coord}
       [VO] CS VInter VTl}
   end

   \insert PatternMatching

   proc {MakeThread VHd VTl VInstr Coord}
      %--** should use Thread.create builtin
      VHd = vThread(_ VInstr Coord VTl _)
   end

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
         {MakeConstruction CS VO Label Args false VHd VTl}
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
      proc {MakeConstructionOpen CS VO TheLabel Args VHd VTl}
         C CND WidthReg WidthVO Cont1 Cont2
      in
         %% translate the construction as:
         %%    {`tellRecordSize` Label Width ?VO}
         %%    {`^` VO Feat1 Subtree1} ... {`^` VO Featn Subtreen}
         {TheLabel getCoord(?C)}
         CND = {CoordNoDebug C}
         {CS newReg(?WidthReg)}
         WidthVO = {New PseudoVariableOccurrence init(WidthReg)}
         VHd = vEquateConstant(_ {Length Args} WidthReg Cont1)
         if {HasFeature TheLabel Core.imAVariableOccurrence} then
            {MakeRunTimeProcApplication 'tellRecordSize' CND
             [TheLabel WidthVO VO] CS Cont1 Cont2}
         else LabelReg LabelVO LabelValue Inter in
            {CS newReg(?LabelReg)}
            LabelVO = {New PseudoVariableOccurrence init(LabelReg)}
            {TheLabel getCodeGenValue(?LabelValue)}
            Cont1 = vEquateConstant(_ LabelValue LabelReg Inter)
            {MakeRunTimeProcApplication 'tellRecordSize' CND
             [LabelVO WidthVO VO] CS Inter Cont2}
         end
         {List.foldLInd Args
          proc {$ I VHd Arg VTl} VO1 VO2 VInter1 in
             case Arg of F#T then VInter2 in
                {F makeVO(CS VHd VInter2 ?VO1)}
                {T makeVO(CS VInter2 VInter1 ?VO2)}
             else VInter2 in
                VO1 = {NewPseudoVariableOccurrence CS}
                VO1.value = I
                VHd = vEquateConstant(_ I {VO1 reg($)} VInter2)
                {Arg makeVO(CS VInter2 VInter1 ?VO2)}
             end
             {MakeRunTimeProcApplication '^' CND [VO VO1 VO2] CS VInter1 VTl}
          end Cont2 VTl}
      end
      proc {MakeConstructionTuple CS VO TheLabel Rec VHd VTl}
         C SubtreesReg SubtreesVO WidthValue WidthReg WidthVO Cont1 Cont2
      in
         %% translate the construction as:
         %%    {`tuple` Label [Subtree1 ... Subtreen] Width ?Reg}
         {TheLabel getCoord(?C)}
         {CS newReg(?SubtreesReg)}
         SubtreesVO = {New PseudoVariableOccurrence init(SubtreesReg)}
         WidthValue = {Width Rec}
         {CS newReg(?WidthReg)}
         WidthVO = {New PseudoVariableOccurrence init(WidthReg)}
         case WidthValue of 0 then
            VHd = vEquateConstant(_ nil SubtreesReg Cont1)
         else
            fun {MakeList I VHd VTl}
               if I =< WidthValue then
                  ArgIn VInter1 ConsReg VInter2 NewArg
               in
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
            VInter2 = vEquateRecord(_ '|' 2 SubtreesReg [NewArg Arg] Cont1)
         end
         Cont1 = vEquateConstant(_ WidthValue WidthReg Cont2)
         if {HasFeature TheLabel Core.imAVariableOccurrence} then
            {MakeRunTimeProcApplication 'tuple' {CoordNoDebug C}
             [TheLabel SubtreesVO WidthVO VO] CS Cont2 VTl}
         else LabelReg LabelVO LabelValue Inter in
            {CS newReg(?LabelReg)}
            LabelVO = {New PseudoVariableOccurrence init(LabelReg)}
            {TheLabel getCodeGenValue(?LabelValue)}
            Cont2 = vEquateConstant(_ LabelValue LabelReg Inter)
            {MakeRunTimeProcApplication 'tuple' {CoordNoDebug C}
             [LabelVO SubtreesVO WidthVO VO] CS Inter VTl}
         end
      end
      proc {MakeConstructionRecord CS VO TheLabel Args VHd VTl}
         C SubtreesReg SubtreesVO Cont
      in
         %% translate the construction as:
         %%    {`record` Label [Feat1#Subtree1 ... Featn#Subtreen] ?Reg}
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
            {MakeRunTimeProcApplication 'record' {CoordNoDebug C}
             [TheLabel SubtreesVO VO] CS Cont VTl}
         else LabelReg LabelVO LabelValue Inter in
            {CS newReg(?LabelReg)}
            LabelVO = {New PseudoVariableOccurrence init(LabelReg)}
            {TheLabel getCodeGenValue(?LabelValue)}
            Cont = vEquateConstant(_ LabelValue LabelReg Inter)
            {MakeRunTimeProcApplication 'record' {CoordNoDebug C}
             [LabelVO SubtreesVO VO] CS Inter VTl}
         end
      end
   in
      proc {MakeConstruction CS VO TheLabel Args IsOpen VHd VTl}
         %% Determine in which way the record may be constructed.
         if IsOpen then
            {MakeConstructionOpen CS VO TheLabel Args VHd VTl}
         else Label Feats LabelIsDet FeatsAreDet in
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
         CS = {New CodeStore init(State Reporter)}
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
                    pid('Toplevel abstraction' 0 pos('' 1 0) [native]
                        NLiveRegs)
                    unit {List.mapInd GRegs fun {$ I _} g(I - 1) end}
                    BodyCode)|
         endDefinition(StartLabel)|
         {Append BodyCode2 [lbl(EndLabel) tailCall(x(0) 0)]}
      end
   end

   class CodeGenTypeOf
      meth codeGen(CS VHd VTl)
         VHd = vEquateConstant(_ @value {@res reg($)} VTl)
      end
   end

   class CodeGenStepPoint
      meth codeGen(CS VHd VTl) VInter1 VInter2 in
         {CodeGenList @statements CS VInter1 VInter2}
         {StepPoint @coord @kind VHd VTl VInter1 VInter2}
      end
   end

   class CodeGenDeclaration
      meth codeGen(CS VHd VTl)
         {ForAll @localVars proc {$ V} {V setReg(CS)} end}
         if CS.debugInfoVarnamesSwitch then Regs Cont1 Cont2 in
            {MakePermanent @localVars ?Regs VHd Cont1}
            {CodeGenList @statements CS Cont1 Cont2}
            {Clear Regs Cont2 VTl}
         else
            {CodeGenList @statements CS VHd VTl}
         end
      end
   end

   class CodeGenSkipNode
      meth codeGen(CS VHd VTl) VInter in
         {StepPoint @coord 'skip' VHd VTl VInter VInter}
      end
   end

   class CodeGenEquation
      meth codeGen(CS VHd VTl)
         {@right makeEquation(CS @left VHd VTl)}
      end
   end

   class CodeGenConstruction from CodeGenConstructionOrPattern
      meth makeEquation(CS VO VHd VTl)
         {MakeConstruction CS VO @label @args @isOpen VHd VTl}
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
         if {Not @isOpen} andthen {IsDet Label} andthen {All Feats IsDet} then
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

   class CodeGenDefinition
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
                      if {Member native @procFlags} then [native]
                      else nil
                      end
                      OuterNLiveRegs)
\ifdef DEBUG_DEFS
         {System.show PredId}
\endif
         if @isStateUsing then
            if CS.debugInfoVarnamesSwitch then
               {CS newSelfReg(?StateReg)}
            else
               {CS newReg(?StateReg)}
            end
         else
            StateReg = none
         end
         case @toCopy of unit then
            FormalRegs AllRegs BodyVInter BodyVInstr GRegs Code VInter
         in
            {CS startDefinition()}
            FormalRegs = {Map @formalArgs
                          fun {$ V}
                             {V setReg(CS)}
                             {V reg($)}
                          end}
            if CS.debugInfoVarnamesSwitch then Regs Cont1 Cont2 in
               {MakePermanent @formalArgs ?Regs BodyVInter Cont1}
               {CodeGenList @statements CS Cont1 Cont2}
               {Clear Regs Cont2 nil}
            else
               {CodeGenList @statements CS BodyVInter nil}
            end
            AllRegs = case @allVariables of nil then nil
                      else {Map @allVariables fun {$ V} {V reg($)} end}
                      end
            case StateReg of none then
               BodyVInstr = BodyVInter
               VHd0 = VInter
            else
               BodyVInstr = vSetSelf(_ StateReg BodyVInter)
               VHd0 = vGetSelf(_ StateReg VInter)
            end
            {CS endDefinition(BodyVInstr FormalRegs AllRegs ?GRegs ?Code
                              ?OuterNLiveRegs)}
            VInter = vDefinition(_ {V reg($)} PredId @predicateRef
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
                      else {GetRegs @allVariables}
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
                               4: if {Member native @procFlags} then [native]
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
                                   predicateRef(X)
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
            VInter = vDefinition(_ {V reg($)} PredId @predicateRef
                                 OuterGRegs OuterCode VTl0)
         end
         {StepPoint @coord 'definition' VHd VTl VHd0 VTl0}
         statements <- unit   % hand them to the garbage collector
      end
      meth codeGenApply(Designator Coord ActualArgs CS VHd VTl)
         case @predicateRef of unit then
            VHd = vCall(_ {Designator reg($)} {GetRegs ActualArgs} Coord VTl)
         elseof ID then
            VHd = vFastCall(_ ID {GetRegs ActualArgs} Coord VTl)
         end
      end
   end
   class CodeGenClauseBody
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
            VHd = vShared(_ Label {NewCell 0} Addr)
            {CodeGenList @statements CS Addr nil}
         end
      end
   end

   class CodeGenApplication
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

   class CodeGenIfNode
      meth codeGen(CS VHd VTl) Value in
         {@arbiter getCodeGenValue(?Value)}
         if {IsDet Value} andthen Value == true then
            {@consequent codeGen(CS VHd VTl)}
         elseif {IsDet Value} andthen Value == false then
            {@alternative codeGen(CS VHd VTl)}
         else ThenAddr AltAddr ErrAddr in
            {@consequent codeGen(CS ThenAddr nil)}
            {@alternative codeGen(CS AltAddr nil)}
            ErrAddr = self.noBoolShared
            if {IsFree ErrAddr} then Label Addr in
               {CS newLabel(?Label)}
               ErrAddr = vShared(_ Label {NewCell 0} Addr)
               {MakeException boolCaseType @coord [@arbiter] CS Addr nil}
            end
            VHd = vTestBool(_ {@arbiter reg($)} ThenAddr AltAddr ErrAddr
                            @coord VTl _)
         end
      end
   end

   class CodeGenIfClause
      meth codeGen(CS VHd VTl)
         {CodeGenList @statements CS VHd VTl}
      end
   end

   class CodeGenPatternCase
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
      meth codeGenPattern(Mapping VHd VTl CS)
         if {IsDet @reached} then
            {Exception.raiseError
             compiler(internal {@statements.1 getCoord($)})}
         end
         @reached = true
         {@pattern assignRegs(nil Mapping)}
         if CS.debugInfoVarnamesSwitch then Regs VInter1 VInter2 in
            {MakePermanent @localVars ?Regs VHd VInter1}
            {CodeGenList @statements CS VInter1 VInter2}
            {Clear Regs VInter2 VTl}
         else
            {CodeGenList @statements CS VHd VTl}
         end
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
      meth codeGenTest(ThenVInstr ElseVInstr VHd VTl CS) VInter ErrVInstr in
         {ForAll @localVars proc {$ V} {V setReg(CS)} end}
         if CS.debugInfoVarnamesSwitch then Regs VInter1 VInter2 in
            {MakePermanent @localVars ?Regs VHd VInter1}
            {CodeGenList @statements CS VInter1 VInter2}
            {Clear Regs VInter2 VInter}
         else
            {CodeGenList @statements CS VHd VInter}
         end
         {MakeException boolCaseType @coord [@arbiter] CS ErrVInstr nil}
         VInter = vTestBool(_ {@arbiter reg($)} ThenVInstr ElseVInstr ErrVInstr
                            @coord VTl _)
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

   class CodeGenAbstractElse
      meth codeGenPattern(Mapping VHd VTl CS) Reg VO in
         Reg = {PosToReg nil Mapping}
         VO = {New PseudoVariableOccurrence init(Reg)}
         {self codeGenWithArbiter(CS VO VHd VTl)}
      end
   end
   class CodeGenElseNode
      meth codeGen(CS VHd VTl)
         {CodeGenList @statements CS VHd VTl}
      end
      meth codeGenWithArbiter(CS VO VHd VTl)
         {CodeGenList @statements CS VHd VTl}
      end
   end
   class CodeGenNoElse
      meth codeGen(CS VHd VTl)
         {MakeException noElse @coord nil CS VHd VTl}
      end
      meth codeGenWithArbiter(CS VO VHd VTl)
         {MakeException noElse @coord [VO] CS VHd VTl}
      end
   end

   class CodeGenTryNode
      meth codeGen(CS VHd VTl) TryBodyVInstr CatchBodyVInstr in
         {CodeGenList @tryStatements CS TryBodyVInstr vPopEx(_ @coord nil)}
         {@exception setReg(CS)}
         if CS.debugInfoVarnamesSwitch then Regs Cont1 Cont2 in
            {MakePermanent [@exception] ?Regs CatchBodyVInstr Cont1}
            {CodeGenList @catchStatements CS Cont1 Cont2}
            {Clear Regs Cont2 nil}
         else
            {CodeGenList @catchStatements CS CatchBodyVInstr nil}
         end
         VHd = vExHandler(_ TryBodyVInstr {@exception reg($)}
                          CatchBodyVInstr @coord VTl _)
      end
   end

   class CodeGenLockNode
      meth codeGen(CS VHd VTl) SharedData Cont1 in
         VHd = vLockThread(_ {@lockVar reg($)} @coord Cont1 SharedData)
         {CodeGenList @statements CS Cont1 vLockEnd(_ @coord VTl SharedData)}
      end
   end

   class CodeGenClassNode
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
         PN = case @printName of '' then
                 {{@designator getVariable($)} getPrintName($)}
              else @printName
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
         {MakeRunTimeProcApplication 'class' {CoordNoDebug @coord}
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
      feat MessagePatternVO
      meth isOptimizable($)
         {Not @isOpen} andthen @messageDesignator == unit andthen
         {All @formalArgs
          fun {$ Formal} Value in
             {{Formal getFeature($)} getCodeGenValue(?Value)}
             {IsDet Value} andthen ({IsInt Value} orelse {IsLiteral Value})
          end}
      end
      meth makeQuadruple(PrintName CS Reg IsToplevel VHd VTl)
         HasDefaults FileName Line Col FastMeth SlowMeth
         VInter1 VInter2 X = unit
      in
         HasDefaults = {Some @formalArgs
                        fun {$ Formal} {Formal hasDefault($)} end}
         case @coord of unit then FileName = '' Line = 1 Col = 0
         elseof C then FileName = C.1 Line = C.2 Col = C.3
         end
         CodeGenMethod, MakeFastMeth(PrintName FileName Line Col CS
                                     VHd VInter1 ?FastMeth)
         CodeGenMethod, MakeSlowMeth(PrintName FileName Line Col HasDefaults
                                     IsToplevel CS VInter1 VInter2 FastMeth
                                     ?SlowMeth)
         if FastMeth == unit then
            VInter2 = vEquateRecord(_ '|' 2 Reg
                                    [{@label makeRecordArgument(CS X X $)}
                                     value(SlowMeth)] VTl)
         elseif HasDefaults then Args VO VInter3 in
            Args = {Map @formalArgs
                    fun {$ Formal}
                       {Formal getFeature($)}#{Formal getDefault($)}
                    end}
            VO = {NewPseudoVariableOccurrence CS}
            {MakeConstruction CS VO @label Args false VInter2 VInter3}
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
      meth MakeFastMeth(PrintName FileName Line Col CS VHd VTl ?FastMeth)
         if CodeGenMethod, isOptimizable($) then
            RecordArity PredId NLiveRegs FormalRegs AllRegs BodyVInstr
            GRegs Code
         in
            CodeGenMethod, SortFormals(CS ?RecordArity)
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
            {CS newReg(?FastMeth)}
            VHd = vDefinition(_ FastMeth PredId @predicateRef GRegs Code VTl)
         else
            VHd = VTl
            FastMeth = unit
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
      meth MakeBody(?AllRegs CS VHd VTl)
         AllRegs = case @allVariables of nil then nil
                   else {GetRegs @allVariables}
                   end
         if CS.debugInfoVarnamesSwitch then
            StateReg Vs Regs Cont1 Cont2 Cont3 Cont4 Cont5
         in
            {CS newSelfReg(?StateReg)}
            VHd = vMakePermanent(_ [StateReg] Cont1)
            Cont1 = vGetSelf(_ StateReg Cont2)
            Vs = {FoldR @formalArgs fun {$ F In} {F getVariable($)}|In end
                  case @messageDesignator of unit then nil
                  elseof V then [V]
                  end}
            {MakePermanent Vs ?Regs Cont2 Cont3}
            {CodeGenList @statements CS Cont3 Cont4}
            {Clear Regs Cont4 Cont5}
            {Clear [StateReg] Cont5 VTl}
         else
            {CodeGenList @statements CS VHd VTl}
         end
         statements <- unit   % hand them to the garbage collector
      end
      meth MakeSlowMeth(PrintName FileName Line Col HasDefaults IsToplevel CS
                        VHd VTl FastMeth ?SlowMeth)
         PredId NLiveRegs Cont1 MessageReg MessageVO BodyVInstr
         AllRegs GRegs Code VInter1 VInter2
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
         MessageVO = {New PseudoVariableOccurrence init(MessageReg)}
         CodeGenMethod, MakeArityCheck(HasDefaults MessageVO CS
                                       BodyVInstr VInter1)
         %--** use pattern matching
         {FoldL @formalArgs
          proc {$ VHd Formal VTl}
             {Formal bindMethFormal(MessageVO CS VHd VTl)}
          end VInter1 VInter2}
         case FastMeth of unit then
            CodeGenMethod, MakeBody(?AllRegs CS VInter2 nil)
         else FormalRegs Coord in
            FormalRegs = {Map @formalArgs
                          fun {$ Formal}
                             {{Formal getVariable($)} reg($)}
                          end}
            Coord = {CoordNoDebug @coord}
            case @predicateRef of unit then
               VInter2 = vCall(_ FastMeth FormalRegs Coord nil)
            elseof ID then
               VInter2 = vFastCall(_ ID FormalRegs Coord nil)
            end
            AllRegs = nil
         end
         {CS endDefinition(BodyVInstr [MessageReg] AllRegs
                           ?GRegs ?Code ?NLiveRegs)}
         {CS newReg(?SlowMeth)}
         Cont1 = vDefinition(_ SlowMeth PredId unit GRegs Code VTl)
      end
      meth MakeArityCheckInit(HasDefaults CS VHd VTl)
         if @isOpen then
            VHd = VTl
         else
            self.MessagePatternVO = {NewPseudoVariableOccurrence CS}
            if HasDefaults then LabelReg LabelVO in
               {CS newReg(?LabelReg)}
               LabelVO = {New PseudoVariableOccurrence init(LabelReg)}
               LabelVO.value = 'messagePattern'
               {MakeConstruction CS self.MessagePatternVO LabelVO
                {Map @formalArgs
                 fun {$ Formal} VO in
                    VO = {NewPseudoVariableOccurrence CS}
                    VO.value = unit
                    {Formal getFeature($)}#VO
                 end} false VHd VTl}
            else
               VHd = VTl
            end
         end
      end
      meth MakeArityCheck(HasDefaults MessageVO CS VHd VTl)
         if @isOpen then
            VHd = VTl
         elseif HasDefaults then
            %--** when generating a pattern instead of statements:
            %--**    Inter = Pos#expr(self)|Tl
            {MakeRunTimeProcApplication 'aritySublist' {CoordNoDebug @coord}
             [MessageVO self.MessagePatternVO] CS VHd VTl}
         else NArgs LabelValue in
            NArgs = {Length @formalArgs}
            {@label getCodeGenValue(?LabelValue)}
            if NArgs == 0 andthen {IsDet LabelValue} then
               VHd = vEquateConstant(_ LabelValue {MessageVO reg($)} VTl)
            else Reg VO Cont1 in
               {CS newReg(?Reg)}
               VO = {New PseudoVariableOccurrence init(Reg)}
               VHd = vEquateConstant(_ NArgs Reg Cont1)
               {MakeRunTimeProcApplication 'width' {CoordNoDebug @coord}
                [MessageVO VO] CS Cont1 VTl}
            end
         end
      end
      meth codeGenTest(ThenVInstr ElseVInstr VHd VTl CS)
         skip   %--** when generating pattern instead of statements
      end
   end

   class CodeGenMethFormal
      meth getDefault($)
         {New Core.valueNode init(RunTime.literals.ooRequiredArg unit)}
      end
      meth bindMethFormal(MessageVO CS VHd VTl) C FeatureVO ArgVO VInter in
         {@arg setFreshReg(CS)}
         {@feature getCoord(?C)}
         ArgVO = {New PseudoVariableOccurrence init({@arg reg($)})}
         {@feature makeVO(CS VHd VInter ?FeatureVO)}
         {MakeRunTimeProcApplication '.' {CoordNoDebug C}
          [MessageVO FeatureVO ArgVO] CS VInter VTl}
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
                           unit VTl _)
         {@arg reg(?ArgReg)}
         ThenVInstr = vUnify(_ ArgReg TempVO.reg nil)
         case @default of unit then ElseVInstr = nil
         elseof VO then ArgVO in
            ArgVO = {New PseudoVariableOccurrence init(ArgReg)}
            {VO makeEquation(CS ArgVO ElseVInstr nil)}
         end
         {MakeException boolCaseType Coord [ArbiterVO] CS ErrVInstr nil}
      end
   end

   class CodeGenObjectLockNode
      meth codeGen(CS VHd VTl) Reg Arg SharedData Cont1 Cont2 in
         {CS newReg(?Reg)}
         Arg = {New PseudoVariableOccurrence init(Reg)}
         {MakeRunTimeProcApplication 'ooGetLock' {CoordNoDebug @coord}
          [Arg] CS VHd Cont1}
         Cont1 = vLockThread(_ Reg @coord Cont2 SharedData)
         {CodeGenList @statements CS Cont2 vLockEnd(_ @coord VTl SharedData)}
      end
   end

   class CodeGenGetSelf
      meth codeGen(CS VHd VTl)
         VHd = vGetSelf(_ {@destination reg($)} VTl)
      end
   end

   class CodeGenFailNode
      meth codeGen(CS VHd VTl) VInter in
         {StepPoint @coord 'fail' VHd VTl vFailure(_ VInter) VInter}
      end
   end

   class CodeGenCondNode
      meth codeGen(CS VHd VTl) AllocatesRS VClauses AltVInstr in
         {CS makeRegSet(?AllocatesRS)}
         VClauses = {Map @clauses
                     fun {$ Clause} GuardVInstr VTl Cont BodyVInstr in
                        {CS enterVs({Clause getGuardGlobalVars($)}
                                    AllocatesRS)}
                        {Clause
                         codeGen(CS ?GuardVInstr ?VTl ?Cont ?BodyVInstr)}
                        VTl = Cont
                        _#GuardVInstr#BodyVInstr
                     end}
         {@alternative codeGen(CS AltVInstr nil)}
         VHd = vCreateCond(_ VClauses AltVInstr VTl @coord AllocatesRS _)
      end
   end

   class CodeGenChoicesAndDisjunctions
      meth codeGen(Label CS VHd VTl) AllocatesRS VClauses in
         {CS makeRegSet(?AllocatesRS)}
         VClauses = {Map @clauses
                     fun {$ Clause} GuardVInstr VTl Cont BodyVInstr in
                        {CS enterVs({Clause getGuardGlobalVars($)}
                                    AllocatesRS)}
                        {Clause
                         codeGen(CS ?GuardVInstr ?VTl ?Cont ?BodyVInstr)}
                        VTl = Cont
                        _#GuardVInstr#BodyVInstr
                     end}
         VHd = Label(_ VClauses VTl @coord AllocatesRS _)
      end
   end
   class CodeGenOrNode
      meth codeGen(CS VHd VTl)
         CodeGenChoicesAndDisjunctions, codeGen(vCreateOr CS VHd VTl)
      end
   end
   class CodeGenDisNode
      meth codeGen(CS VHd VTl)
         CodeGenChoicesAndDisjunctions, codeGen(vCreateEnumOr CS VHd VTl)
      end
   end
   class CodeGenChoiceNode
      meth codeGen(CS VHd VTl)
         CodeGenChoicesAndDisjunctions, codeGen(vCreateChoice CS VHd VTl)
      end
   end

   class CodeGenClause
      meth codeGen(CS ?GuardVInstr ?VTl ?Cont ?BodyVInstr) GuardVHd Coord in
         {ForAll @localVars proc {$ V} {V setReg(CS)} end}
         {CodeGenList @guard CS GuardVHd nil}
         {@guard.1 getCoord(?Coord)}
         {MakeThread GuardVInstr VTl GuardVHd Coord}
         Cont = case @kind of ask then vAsk(_ nil)
                [] wait then vWait(_ nil)
                [] waitTop then vWaitTop(_ nil)
                end
         if CS.debugInfoVarnamesSwitch then Regs Cont3 Cont4 in
            {MakePermanent @localVars ?Regs BodyVInstr Cont3}
            {CodeGenList @statements CS Cont3 Cont4}
            {Clear Regs Cont4 nil}
         else
            {CodeGenList @statements CS BodyVInstr nil}
         end
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
         if {IsDet @value} then
            if @value == self then _
            else {@value getCodeGenValue($)}
            end
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
      meth makePattern(Arbiter Pos Hd Tl Seen CS)
         Hd = Pos#constant(self)|Tl
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

   class CodeGenPatternVariableOccurrence
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

   class CodeGenProcedureToken
      meth getDefinition($)
         @definition
      end
   end
end
