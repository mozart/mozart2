%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
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
%% meth output(R ?FS)
%%    Only statement nodes have this method.  It produces a format
%%    string FS as defined by Gump.  The value of R indicates with
%%    which options to output:
%%       R.realcore     corresponds the switch realcore
%%       R.debugValue   output value attributes
%%       R.debugType    output variable types
%%
%% meth output2(R ?FS1 ?FS2)
%%    This corresponds to the above method, except that it is used
%%    for non-statement nodes.  FS2 is an additional format string
%%    to insert after the current statement.
%%

functor
import
   CompilerSupport(concatenateAtomAndInt)
   System(printName)
   Annotate
   StaticAnalysis
   CodeGen
export
   %% procedures:
   FlattenSequence
   Output

   %% names:
   ImAValueNode
   ImAVariableOccurrence
   ImAToken

   %% classes for abstract syntax:
   Statement
   TypeOf
   StepPoint
   Declaration
   SkipNode
   Equation
   Construction
   Definition
   ClauseBody
   Application
   IfNode
   IfClause
   PatternCase
   PatternClause
   RecordPattern
   SideCondition
   EquationPattern
   ElseNode
   NoElse
   TryNode
   LockNode
   ClassNode
   Method
   MethFormal
   MethFormalOptional
   MethFormalWithDefault
   ObjectLockNode
   GetSelf
   ExceptionNode
   ValueNode
   Variable
   UserVariable
   GeneratedVariable
   RestrictedVariable
   VariableOccurrence
   PatternVariableOccurrence

   %% classes for token representations:
   Token
   ProcedureToken
   ClassToken
   ObjectToken
prepare
   %% some format string auxiliaries for output
   IN = format(indent)
   EX = format(exdent)
   PU = format(push)
   PO = format(pop)
   GL = format(glue(" "))
   NL = format(break)
define
   fun {LI Xs Sep R}
      list({Map Xs fun {$ X} {X output(R $)} end} Sep)
   end

   fun {LI2 Xs Sep R ?FS}
      case Xs of X1|Xr then FS01 FS02 FSs in
         {X1 output2(R ?FS01 ?FS02)}
         FSs#FS = {FoldL Xr
                   fun {$ FSs#FS X} FS01 FS02 in
                      {X output2(R ?FS01 ?FS02)}
                      (FS01|FSs)#(FS#FS02)
                   end [FS01]#FS02}
         list({Reverse FSs} Sep)
      [] nil then
         FS = ""
         ""
      end
   end

   fun {OutputAttrFeat I R ?FS}
      case I of F#T then FS1 FS2 in
         FS = FS1#FS2
         {F outputEscaped2(R $ ?FS1)}#': '#{T output2(R $ ?FS2)}
      else
         {I outputEscaped2(R $ ?FS)}
      end
   end

   local
      ConcatenateAtomAndInt = CompilerSupport.concatenateAtomAndInt

      proc {Generate Xs Origin D N}
         case Xs of X|Xr then PrintName in
            PrintName = {ConcatenateAtomAndInt Origin N}
            if {Dictionary.member D PrintName} then
               {Generate Xs Origin D N + 1}
            else
               X = PrintName
               {Generate Xr Origin D N + 1}
            end
         [] nil then skip
         end
      end
   in
      proc {Output DeclaredGVs GS Switches FS} R in
         R = debug(realcore: {Switches getSwitch(realcore $)}
                   debugValue: {Switches getSwitch(debugvalue $)}
                   debugType: {Switches getSwitch(debugtype $)}
                   printNames: {NewDictionary}
                   toGenerate: {NewDictionary})
         FS = (case DeclaredGVs of nil then ""
               else
                  'declare'#GL#
                  {LI DeclaredGVs GL {AdjoinAt R realcore true}}#GL#'in'#NL
               end#{LI GS NL R})
         {ForAll {Dictionary.entries R.toGenerate}
          proc {$ Origin#Xs}
             {Generate {Reverse Xs} Origin R.printNames 1}
          end}
      end
   end

   local
      proc {FlattenSequenceSub X Hd Tl}
         %% This procedure converts a statement sequence represented
         %% using '|' as a pair constructor, whose left and/or right
         %% element may also be a pair, into a list.
         case X of S1|S2 then Inter in
            {FlattenSequenceSub S1 Hd Inter}
            {FlattenSequenceSub S2 Inter Tl}
         [] nil then
            Hd = Tl
         else
            if {X isRedundant($)} then
               Hd = Tl
            else
               Hd = X|Tl
            end
         end
      end

      fun {GetFirst X}
         case X of S1|S2 then First in
            First = {GetFirst S1}
            case First of nil then {GetFirst S2}
            else First
            end
         [] nil then nil
         else X
         end
      end

      fun {SetPointers Prev Next}
         {Prev setNext(Next)}
         Next
      end

      proc {LinkList First|Rest} Last in
         Last = {FoldL Rest SetPointers First}
         {Last setNext(Last)}   % termination
      end
   in
      proc {FlattenSequence X ?Res} Hd in
         {FlattenSequenceSub X Hd nil}
         Res = case Hd of nil then First in
                  First = {GetFirst X}
                  case First of nil then [{New SkipNode init(unit)}]
                  else [First]
                  end
               else Hd
               end
         {LinkList Res}
      end
   end

   fun {FilterUnitsToVS Xs}
      case Xs of X|Xr then
         case X of unit then {FilterUnitsToVS Xr}
         else X#{FilterUnitsToVS Xr}
         end
      [] nil then ""
      end
   end

   ImAValueNode          = StaticAnalysis.imAValueNode
   ImAVariableOccurrence = StaticAnalysis.imAVariableOccurrence
   ImAToken              = StaticAnalysis.imAToken

   class Statement
      attr next: unit coord: unit
      meth setPrintName(_)
         skip
      end
      meth isRedundant($)
         false
      end
      meth setNext(S)
         next <- S
      end
      meth getCoord($)
         @coord
      end
   end

   class TypeOf
      from Statement Annotate.typeOf StaticAnalysis.typeOf CodeGen.typeOf
      prop final
      attr arg: unit res: unit value: unit
      meth init(Arg Res)
         arg <- Arg
         res <- Res
         value <- type([value])
      end
      meth output(R $) FS in
         {@res output2(R $ ?FS)}#' = '#
         {Value.toVirtualString @value 50 1000}#
         '   % typeof '#{@arg output(R $)}#FS
      end
   end

   class StepPoint
      from Statement Annotate.stepPoint StaticAnalysis.stepPoint
         CodeGen.stepPoint
      prop final
      attr statements: unit kind: unit
      meth init(Statements Kind Coord)
         statements <- {FlattenSequence Statements}
         kind <- Kind
         coord <- Coord
      end
      meth output(R $)
         {LI @statements NL R}
      end
   end

   class Declaration
      from Statement Annotate.declaration StaticAnalysis.declaration
         CodeGen.declaration
      prop final
      attr localVars: unit statements: unit
      meth init(LocalVars Statements Coord)
         localVars <- LocalVars
         statements <- {FlattenSequence Statements}
         coord <- Coord
      end
      meth output(R $)
         'local'#GL#IN#{LI @localVars GL R}#EX#GL#'in'#IN#NL#
         {LI @statements NL R}#EX#NL#'end'
      end
   end

   class SkipNode
      from Statement StaticAnalysis.skipNode Annotate.skipNode
         CodeGen.skipNode
      prop final
      meth init(Coord)
         coord <- Coord
      end
      meth isRedundant($)
         true
      end
      meth output(_ $)
         'skip skip'
      end
   end

   class Equation
      from Statement Annotate.equation StaticAnalysis.equation CodeGen.equation
      prop final
      attr left: unit right: unit
      meth init(Left Right Coord)
         left <- Left
         right <- Right
         coord <- Coord
      end
      meth output(R $) FS1 FS2 in
         {@left output2(R $ ?FS1)}#' = '#{@right output2(R $ ?FS2)}#FS1#FS2
      end
   end

   class Construction
      from Annotate.construction StaticAnalysis.construction
         CodeGen.construction
      prop final
      attr label: unit args: unit
      meth init(Label Args)
         label <- Label
         args <- Args
         StaticAnalysis.construction, init()
      end
      meth getCoord($)
         {@label getCoord($)}
      end
      meth output2(R $ ?FS) FS1 FS2 in
         FS = FS1#FS2
         {@label output2(R $ ?FS1)}#'('#PU#
         case @args of X1|Xr then Start FSs in
            case X1 of F#T then FS01 FS02 FS11 FS12 in
               {F output2(R ?FS01 ?FS02)}
               {T output2(R ?FS11 ?FS12)}
               Start = [FS01#': '#FS11]#(FS02#FS12)
            else FS01 FS02 in
               {X1 output2(R ?FS01 ?FS02)}
               Start = [FS01]#FS02
            end
            FSs#FS2 = {FoldL Xr
                       fun {$ FSs#FS X}
                          case X of F#T then FS01 FS02 FS11 FS12 in
                             {F output2(R ?FS01 ?FS02)}
                             {T output2(R ?FS11 ?FS12)}
                             (FS01#': '#FS11|FSs)#(FS#FS02#FS12)
                          else FS01 FS02 in
                             {X output2(R ?FS01 ?FS02)}
                             (FS01|FSs)#(FS#FS02)
                          end
                       end Start}
            list({Reverse FSs} GL)
         else
            FS2 = ""
            ""
         end#')'#PO
      end
      meth isConstruction($)
         true
      end
   end

   local
      class DefinitionBase
         from Statement Annotate.definition StaticAnalysis.definition
         attr
            designator: unit formalArgs: unit statements: unit
            isStateUsing: unit procFlags: unit printName: '' toCopy: unit
            allVariables: nil procedureRef: unit
         meth init(Designator FormalArgs Statements IsStateUsing ProcFlags
                   Coord)
            designator <- Designator
            formalArgs <- FormalArgs
            statements <- {FlattenSequence Statements}
            isStateUsing <- IsStateUsing
            procFlags <- ProcFlags
            coord <- Coord
         end
         meth setAllVariables(Vs)
            allVariables <- Vs
         end
         meth setPrintName(PrintName)
            printName <- PrintName
         end
         meth output(R $) FS1 in
            {FoldL @procFlags
             fun {$ In A} In#{Value.toVirtualString A 0 0}#' ' end
             'proc '}#
            '{'#PU#{@designator output2(R $ ?FS1)}#
            case @formalArgs of _|_ then GL#{LI @formalArgs GL R}
            [] nil then ""
            end#'}'#
            if {self isClauseBody($)} then '   % clause body' else "" end#
            PO#IN#FS1#NL#
            {LI @statements NL R}#EX#NL#'end'
         end
         meth isClauseBody($)
            false
         end
      end
   in
      class Definition
         from DefinitionBase CodeGen.definition
         prop final
      end
      class ClauseBody
         from DefinitionBase CodeGen.clauseBody
         prop final
         meth isClauseBody($)
            true
         end
      end
   end

   class Application
      from Statement Annotate.application StaticAnalysis.application
         CodeGen.application
      prop final
      attr designator: unit actualArgs: unit
      feat codeGenMakeEquateLiteral
      meth init(Designator ActualArgs Coord)
         designator <- Designator
         actualArgs <- ActualArgs
         coord <- Coord
      end
      meth output(R $)
         if R.realcore then
            Application, OutputApplication(R $)
         else PN P in
            {{@designator getVariable($)} getPrintName(?PN)}
            P = if {IsFree PN} then unit else PN end
            case P of '`Object.exchange`' then Attr New Old FS1 FS2 FS3 in
               @actualArgs = [Attr New Old]
               {Old output2(R $ ?FS1)}#' = '#
               {Attr output2(R $ ?FS2)}#' <- '#{New output2(R $ ?FS3)}#
               FS1#FS2#FS3
            [] '`Object.\'@\'`' then
               Application, OutputPrefixExpression('@' R $)
            [] '`~`' then Application, OutputPrefixExpression('~' R $)
            [] '`Object.\'<-\'`' then
               Application, OutputInfixStatement(' <- ' R $)
            [] '`,`' then Application, OutputInfixStatement(', ' R $)
            [] '`==`' then Application, OutputInfixExpression(' == ' R $)
            [] '`<`' then Application, OutputInfixExpression(' < ' R $)
            [] '`>`' then Application, OutputInfixExpression(' > ' R $)
            [] '`=<`' then Application, OutputInfixExpression(' =< ' R $)
            [] '`>=`' then Application, OutputInfixExpression(' >= ' R $)
            [] '`\\=`' then Application, OutputInfixExpression(' \\= ' R $)
            [] '`div`' then Application, OutputInfixExpression(' div ' R $)
            [] '`mod`' then Application, OutputInfixExpression(' mod ' R $)
            [] '`+`' then Application, OutputInfixExpression(' + ' R $)
            [] '`-`' then Application, OutputInfixExpression(' - ' R $)
            [] '`*`' then Application, OutputInfixExpression(' * ' R $)
            [] '`/`' then Application, OutputInfixExpression(' / ' R $)
            [] '`.`' then Application, OutputInfixExpression('.' R $)
            [] '`::`' then Application, OutputFdInStatement(' :: ' R $)
            [] '`:::`' then Application, OutputFdInStatement(' ::: ' R $)
            [] '`::R`' then Application, OutputFdInExpression(' :: ' R $)
            [] '`:::R`' then Application, OutputFdInExpression(' ::: ' R $)
            [] '`Raise`' then E FS in
               @actualArgs = [E]
               'raise '#{E output2(R $ ?FS)}#' end'#FS
            else
               Application, OutputApplication(R $)
            end
         end
      end
      meth OutputApplication(R $) FS1 FS2 in
         '{'#PU#{@designator output2(R $ ?FS1)}#
         case @actualArgs of _|_ then GL#{LI2 @actualArgs GL R ?FS2}
         [] nil then FS2 = "" ""
         end#'}'#PO#FS1#FS2
      end
      meth OutputPrefixExpression(Op R $) E1 E2 FS1 FS2 in
         @actualArgs = [E1 E2]
         {E2 output2(R $ ?FS1)}#' = '#Op#{E1 output2(R $ ?FS2)}#FS1#FS2
      end
      meth OutputInfixStatement(Op R $) E1 E2 FS1 FS2 in
         @actualArgs = [E1 E2]
         {E1 output2(R $ ?FS1)}#Op#{E2 output2(R $ ?FS2)}#FS1#FS2
      end
      meth OutputInfixExpression(Op R $) E1 E2 E3 FS1 FS2 FS3 in
         @actualArgs = [E1 E2 E3]
         {E3 output2(R $ ?FS1)}#' = '#
         {E1 output2(R $ ?FS2)}#Op#{E2 output2(R $ ?FS3)}#FS1#FS2#FS3
      end
      meth OutputFdInStatement(Op R $) E1 E2 FS1 FS2 in
         @actualArgs = [E1 E2]
         {E2 output2(R $ ?FS1)}#Op#{E1 output2(R $ ?FS2)}#FS1#FS2
      end
      meth OutputFdInExpression(Op R $) E1 E2 E3 FS1 FS2 FS3 in
         @actualArgs = [E1 E2 E3]
         {E3 output2(R $ ?FS1)}#' = '#
         {E2 output2(R $ ?FS2)}#Op#{E1 output2(R $ ?FS3)}#FS1#FS2#FS3
      end
   end

   class IfNode
      from Statement Annotate.ifNode StaticAnalysis.ifNode CodeGen.ifNode
      prop final
      attr arbiter: unit consequent: unit alternative: unit
      meth init(Arbiter Consequent Alternative Coord)
         arbiter <- Arbiter
         consequent <- Consequent
         alternative <- Alternative
         coord <- Coord
      end
      meth output(R $) FS in
         'if '#{@arbiter output2(R $ ?FS)}#' then'#IN#NL#
         {@consequent output(R $)}#EX#NL#{@alternative output(R $)}#'end'#FS
      end
   end

   class IfClause
      from Annotate.ifClause StaticAnalysis.ifClause CodeGen.ifClause
      prop final
      attr statements: unit
      meth init(Statements)
         statements <- {FlattenSequence Statements}
      end
      meth output(R $)
         {LI @statements NL R}
      end
   end

   class PatternCase
      from Statement Annotate.patternCase StaticAnalysis.patternCase
         CodeGen.patternCase
      prop final
      attr arbiter: unit clauses: unit alternative: unit
      meth init(Arbiter Clauses Alternative Coord)
         arbiter <- Arbiter
         clauses <- Clauses
         alternative <- Alternative
         coord <- Coord
      end
      meth output(R $) FS in
         'case '#{@arbiter output2(R $ ?FS)}#' of'#
         {LI @clauses NL#'[]' R}#NL#
         {@alternative output(R $)}#'end'#FS
      end
   end

   class PatternClause
      from Annotate.patternClause StaticAnalysis.patternClause
         CodeGen.patternClause
      prop final
      attr localVars: unit pattern: unit statements: unit
      meth init(LocalVars Pattern Statements)
         localVars <- LocalVars
         pattern <- Pattern
         statements <- {FlattenSequence Statements}
      end
      meth output(R $) FS in
         IN#GL#{@pattern outputPattern2(R @localVars $ ?FS)}#EX#GL#'then'#IN#
         FS#NL#{LI @statements NL R}#EX
      end
   end

   class SideCondition
      from Annotate.sideCondition StaticAnalysis.sideCondition
         CodeGen.sideCondition
      prop final
      attr
         pattern: unit localVars: unit statements: unit arbiter: unit
         coord: unit
      meth init(Pattern LocalVars Statements Arbiter Coord)
         pattern <- Pattern
         localVars <- LocalVars
         statements <- {FlattenSequence Statements}
         arbiter <- Arbiter
         coord <- Coord
      end
      meth getCoord($)
         {@statements.1 getCoord($)}
      end
      meth outputPattern2(R Vs $ ?FS) FS1#FS2 = FS in
         {@pattern outputPattern2(R Vs $ ?FS1)}#NL#'andthen'#GL#
         case @localVars of nil then ""
         elseof Vs then {LI Vs GL R}#GL#'in'#NL
         end#{LI @statements NL R}#GL#{@arbiter output2(R $ ?FS2)}
      end
      meth isConstruction($)
         {@pattern isConstruction($)}
      end
   end

   class RecordPattern
      from Annotate.recordPattern StaticAnalysis.recordPattern
         CodeGen.recordPattern
      prop final
      attr label: unit args: unit isOpen: unit
      meth init(Label Args IsOpen)
         label <- Label
         args <- Args
         isOpen <- IsOpen
         StaticAnalysis.recordPattern, init()
      end
      meth getCoord($)
         {@label getCoord($)}
      end
      meth outputPattern2(R Vs $ ?FS) FS1 FS2 Args in
         FS = FS1#FS2
         case @args of X1|Xr then Start FSs in
            case X1 of F#P then FS01 FS02 FS11 FS12 in
               {F output2(R ?FS01 ?FS02)}
               {P outputPattern2(R Vs ?FS11 ?FS12)}
               Start = [FS01#': '#FS11]#(FS02#FS12)
            else FS01 FS02 in
               {X1 outputPattern2(R Vs ?FS01 ?FS02)}
               Start = [FS01]#FS02
            end
            FSs#FS2 = {FoldL Xr
                       fun {$ FSs#FS Arg}
                          case Arg of F#P then FS01 FS02 FS11 FS12 in
                             {F output2(R ?FS01 ?FS02)}
                             {P outputPattern2(R Vs ?FS11 ?FS12)}
                             (FS01#': '#FS11|FSs)#(FS#FS02#FS12)
                          else FS01 FS02 in
                             {Arg outputPattern2(R Vs ?FS01 ?FS02)}
                             (FS01|FSs)#(FS#FS02)
                          end
                       end Start}
            Args = list({Reverse FSs} GL)
         else
            FS2 = ""
            Args = ""
         end
         {@label output2(R $ ?FS1)}#'('#PU#Args#
         if @isOpen then
            case Args of nil then '...' else GL#'...' end
         else ""
         end#')'#PO
      end
      meth isConstruction($)
         true
      end
   end

   class EquationPattern
      from Annotate.equationPattern StaticAnalysis.equationPattern
         CodeGen.equationPattern
      prop final
      attr left: unit right: unit coord: unit
      meth init(Left Right Coord)
         left <- Left
         right <- Right
         coord <- Coord
      end
      meth getCoord($)
         @coord
      end
      meth outputPattern2(R Vs $ ?FS) FS1 FS2 in
         FS = FS1#FS2
         {@left outputPattern2(R Vs $ ?FS1)}#'='#
         {@right outputPattern2(R Vs $ ?FS2)}
      end
      meth isConstruction($)
         {@right isConstruction($)}
      end
   end

   class ElseNode
      from Annotate.elseNode StaticAnalysis.elseNode CodeGen.elseNode
      prop final
      attr statements: unit
      meth init(Statements)
         statements <- {FlattenSequence Statements}
      end
      meth output(R $)
         'else'#IN#NL#
         {LI @statements NL R}#EX#NL
      end
   end
   class NoElse
      from Annotate.noElse StaticAnalysis.noElse CodeGen.noElse
      prop final
      attr coord: unit
      meth init(Coord)
         coord <- Coord
      end
      meth getCoord($)
         @coord
      end
      meth output(_ $)
         ""
      end
   end

   class TryNode
      from Statement Annotate.tryNode StaticAnalysis.tryNode CodeGen.tryNode
      prop final
      attr tryStatements: unit exception: unit catchStatements: unit
      meth init(TryStatements Exception CatchStatements Coord)
         tryStatements <- {FlattenSequence TryStatements}
         exception <- Exception
         catchStatements <- {FlattenSequence CatchStatements}
         coord <- Coord
      end
      meth output(R $)
         'try'#IN#NL#
         {LI @tryStatements NL R}#EX#NL#
         'catch '#{@exception output(R $)}#' then'#
         IN#NL#{LI @catchStatements NL R}#EX#NL#'end'
      end
   end

   class LockNode
      from Statement Annotate.lockNode StaticAnalysis.lockNode CodeGen.lockNode
      prop final
      attr lockVar: unit statements: unit
      meth init(LockVar Statements Coord)
         lockVar <- LockVar
         statements <- {FlattenSequence Statements}
         coord <- Coord
      end
      meth output(R $) FS in
         'lock '#{@lockVar output2(R $ ?FS)}#' then'#IN#NL#
         {LI @statements NL R}#EX#NL#'end'#FS
      end
   end

   class ClassNode
      from Statement Annotate.classNode StaticAnalysis.classNode
         CodeGen.classNode
      prop final
      attr
         designator: unit parents: unit properties: unit
         attributes: unit features: unit methods: unit
         printName: '' isToplevel: false
      meth init(Designator Parents Props Attrs Feats Meths Coord)
         designator <- Designator
         parents <- Parents
         properties <- Props
         attributes <- Attrs
         features <- Feats
         methods <- Meths
         coord <- Coord
      end
      meth setPrintName(PrintName)
         printName <- PrintName
      end
      meth output(R $) FS1 in
         'class '#{@designator output2(R $ ?FS1)}#IN#FS1#
         if @parents \= nil
            orelse @properties \= nil
            orelse @attributes \= nil
            orelse @features \= nil
            orelse @methods \= nil
         then NL
         else ""
         end#
         case @parents of _|_ then FS2 in
            PU#'from'#GL#{LI2 @parents GL R ?FS2}#PO#FS2#
            if @properties \= nil
               orelse @attributes \= nil
               orelse @features \= nil
               orelse @methods \= nil
            then NL
            else ""
            end
         else ""
         end#
         case @properties of _|_ then FS3 in
            PU#'prop'#GL#{LI2 @properties GL R ?FS3}#PO#FS3#
            if @attributes \= nil
               orelse @features \= nil
               orelse @methods \= nil
            then NL
            else ""
            end
         else ""
         end#
         case @attributes of A1|Ar then FS0 FS1 FSs FS4 in
            FS1 = {OutputAttrFeat A1 R ?FS0}
            FSs#FS4 = {FoldL Ar
                       fun {$ FSs#FS I} FS0 in
                          ({OutputAttrFeat I R ?FS0}|FSs)#(FS#FS0)
                       end [FS1]#FS0}
            PU#'attr'#GL#list({Reverse FSs} GL)#PO#FS4#
            if @features \= nil orelse @methods \= nil then NL else "" end
         else ""
         end#
         case @features of F1|Fr then FS0 FS1 FSs FS5 in
            FS1 = {OutputAttrFeat F1 R ?FS0}
            FSs#FS5 = {FoldL Fr
                       fun {$ FSs#FS I} FS0 in
                          ({OutputAttrFeat I R ?FS0}|FSs)#(FS#FS0)
                       end [FS1]#FS0}
            PU#'feat'#GL#list({Reverse FSs} GL)#PO#FS5#
            if @methods \= nil then NL else "" end
         else ""
         end#{LI @methods NL R}#EX#NL#'end'
      end
   end

   class Method
      from Annotate.method StaticAnalysis.method CodeGen.method
      prop final
      attr
         'self': unit
         label: unit formalArgs: unit isOpen: unit messageDesignator: unit
         statements: unit coord: unit allVariables: nil procedureRef: unit
      meth init(Self Label FormalArgs IsOpen MessageDesignator Statements Coord)
         'self' <- Self
         label <- Label
         formalArgs <- FormalArgs
         isOpen <- IsOpen
         messageDesignator <- MessageDesignator
         statements <- {FlattenSequence Statements}
         coord <- Coord
      end
      meth setAllVariables(Vs)
         allVariables <- Vs
      end
      meth getCoord($)
         @coord
      end
      meth output(R $) FS1 FS2 in
         'meth '#{@label outputEscaped2(R $ ?FS1)}#'('#PU#
         {LI2 @formalArgs GL R ?FS2}#
         if @isOpen then
            case @formalArgs of nil then '...' else GL#'...' end
         else ""
         end#')'#
         case @messageDesignator of unit then ""
         elseof V then '='#{V output(R $)}
         end#PO#IN#FS1#FS2#NL#
         {LI @statements NL R}#EX#NL#'end'
      end
   end

   local
      class MethFormalBase
         attr feature: unit arg: unit
         meth init(Feature Arg)
            feature <- Feature
            arg <- Arg
         end
         meth getFeature($)
            @feature
         end
         meth getVariable($)
            @arg
         end
         meth output2(R $ ?FS)
            {@feature output2(R $ ?FS)}#': '#{@arg output(R $)}
         end
      end
   in
      class MethFormal
         prop final
         from
            MethFormalBase Annotate.methFormal
            StaticAnalysis.methFormal CodeGen.methFormal
         meth hasDefault($)
            false
         end
      end
      class MethFormalOptional
         from
            MethFormalBase Annotate.methFormalOptional
            StaticAnalysis.methFormalOptional CodeGen.methFormalOptional
         prop final
         meth hasDefault($)
            true
         end
         meth output2(R $ ?FS)
            MethFormalBase, output2(R $ ?FS)#' <= _'
         end
      end
      class MethFormalWithDefault
         from
            MethFormalBase Annotate.methFormalWithDefault
            StaticAnalysis.methFormalWithDefault CodeGen.methFormalWithDefault
         prop final
         attr default: unit
         meth init(Feature Arg Default)
            MethFormalBase, init(Feature Arg)
            default <- Default
         end
         meth hasDefault($)
            true
         end
         meth output2(R $ ?FS)
            case @default of unit then
               MethFormalBase, output2(R $ ?FS)#' <= _'
            elseof VO then FS1#FS2 = FS in
               MethFormalBase, output2(R $ ?FS1)#' <= '#{VO output2(R $ ?FS2)}
            end
         end
      end
   end

   class ObjectLockNode
      from Statement Annotate.objectLockNode StaticAnalysis.objectLockNode
         CodeGen.objectLockNode
      prop final
      attr statements: unit
      meth init(Statements Coord)
         statements <- {FlattenSequence Statements}
         coord <- Coord
      end
      meth output(R $)
         'lock'#IN#NL#{LI @statements NL R}#EX#NL#'end'
      end
   end

   class GetSelf
      from Statement Annotate.getSelf StaticAnalysis.getSelf CodeGen.getSelf
      prop final
      attr destination: unit
      meth init(Destination Coord)
         fail
         destination <- Destination
         coord <- Coord
      end
      meth output(R $) FS in
         {@destination output2(R $ ?FS)}#' = self'#FS
      end
   end

   class ExceptionNode
      from Statement Annotate.exceptionNode StaticAnalysis.exceptionNode
         CodeGen.exceptionNode
      prop final
      meth init(Coord)
         coord <- Coord
      end
      meth output(_ $) F L in
         F#L = case @coord of unit then ''#unit
               elseof C then C.1#C.2
               end
         'raise'#IN#GL#'kernel('#PU#'noElse'#GL#{Value.toVirtualString F 0 0}#
         GL#L#')'#PO#EX#GL#'end'
      end
   end

   class ValueNode
      from Annotate.valueNode StaticAnalysis.valueNode CodeGen.valueNode
      attr value: unit coord: unit
      feat !ImAValueNode: unit
      meth init(Value Coord)
         value <- Value
         coord <- Coord
         StaticAnalysis.valueNode, init()
      end
      meth getCoord($)
         @coord
      end
      meth getValue($)
         @value
      end
      meth isConstruction($)
         false
      end
      meth output2(_ $ ?FS)
         FS = ""
         {Value.toVirtualString @value 10 10}
      end
      meth outputPattern2(R _ $ ?FS)
         ValueNode, output2(R $ ?FS)
      end
      meth outputEscaped2(R $ ?FS)
         ValueNode, output2(R $ ?FS)
      end
   end

   local
      class VariableBase
         from StaticAnalysis.variable CodeGen.variable
         attr coord: unit isToplevel: false
         meth isRestricted($)
            false
         end
         meth isDenied(Feature ?GV $)
            GV = unit
            false
         end
         meth getCoord($)
            @coord
         end
         meth setToplevel(T)
            isToplevel <- T
         end
         meth isToplevel($)
            @isToplevel
         end
         meth occ(Coord ?VO)
            VO = {New VariableOccurrence init(self Coord)}
         end
         meth outputEscaped(R $)
            '!'#{self output(R $)}
         end
         meth outputPattern(R Vs $)
            if {Member self Vs} then
               {self output(R $)}
            else
               {self outputEscaped(R $)}
            end
         end
      end
      class UserVariableBase
         from VariableBase
         attr printName: unit
         meth init(PrintName Coord)
            printName <- PrintName
            coord <- Coord
            VariableBase, init()
         end
         meth getPrintName($)
            @printName
         end
         meth output(R $) PN = @printName in
            if {IsFree PN} then pn(PN)
            elseif {IsAtom PN} then
               {Dictionary.put R.printNames PN true}
               pn(PN)
            else PN2 D X in
               PN2 = {System.printName PN}
               D = R.toGenerate
               {Dictionary.put D PN2 X|{Dictionary.condGet D PN2 nil}}
               printName <- X
               pn(X)
            end
         end
      end
   in
      class Variable
         from VariableBase
         prop final
      end

      class UserVariable
         prop final
         from UserVariableBase Annotate.userVariable
      end

      class RestrictedVariable
         from UserVariableBase Annotate.restrictedVariable
         prop final
         attr features: unit
         meth init(PrintName Features Coord)
            UserVariableBase, init(PrintName Coord)
            features <- Features
         end
         meth isRestricted($)
            @features \= nil
         end
         meth isDenied(Feature ?GV $) Fs = @features in
            case Fs of nil then
               GV = unit
               false
            else
               RestrictedVariable, IsDenied(Fs Feature ?GV $)
            end
         end
         meth IsDenied(Fs Feature ?GV $)
            case Fs of X|Fr then
               if Feature == X.1 then
                  X.3 = true
                  GV = case X of _#_#_#GV0 then GV0
                       else unit
                       end
                  false
               else
                  RestrictedVariable, IsDenied(Fr Feature ?GV $)
               end
            [] nil then
               GV = unit
               true
            end
         end
      end

      class GeneratedVariable
         from VariableBase Annotate.generatedVariable
         prop final
         attr origin: unit
         meth init(Origin Coord)
            origin <- Origin
            coord <- Coord
            VariableBase, init()
         end
         meth getPrintName($)
            unit
         end
         meth output(R $)
            case @origin of FS=pn(_) then FS
            elseof Origin then D X FS in
               D = R.toGenerate
               {Dictionary.put D Origin X|{Dictionary.condGet D Origin nil}}
               FS = pn(X)
               origin <- FS
               FS
            end
         end
      end
   end

   local
      class VariableOccurrenceBase
         from Annotate.variableOccurrence StaticAnalysis.variableOccurrence
         attr variable: unit coord: unit value: unit
         feat !ImAVariableOccurrence: unit
         meth init(Variable Coord)
            variable <- Variable
            coord <- Coord
            value <- self
         end
         meth getCoord($)
            @coord
         end
         meth getValue($)
            @value
         end
         meth setValue(Value)
            value <- Value
         end
         meth isConstruction($)
            false
         end
         meth makeIntoPatternVariableOccurrence($)
            {New PatternVariableOccurrence init(@variable @coord)}
         end
         meth getVariable($)
            @variable
         end
         meth output2(R $ ?FS)
            VariableOccurrenceBase, OutputValue(R ?FS)
            {@variable output(R $)}
         end
         meth outputEscaped2(R $ ?FS)
            VariableOccurrenceBase, OutputValue(R ?FS)
            {@variable outputEscaped(R $)}
         end
         meth outputPattern2(R Vs $ ?FS)
            VariableOccurrenceBase, OutputValue(R ?FS)
            {@variable outputPattern(R Vs $)}
         end
         meth OutputValue(R $)
            DebugOutputs =
            {FilterUnitsToVS
             if R.debugValue then
                NL#'%    value: '#
                StaticAnalysis.variableOccurrence, outputDebugValue($)
             else unit
             end|
             if R.debugType then
                [NL#'%    type: '#{@variable outputDebugType($)}
                 case {@variable outputDebugProps($)} of unit then unit
                 elseof Ps then
                    NL#'%    prop: '#{Value.toVirtualString Ps 10 10}
                 end
                 case {@variable outputDebugAttrs($)} of unit then unit
                 elseof As then
                    NL#'%    attr: '#{Value.toVirtualString As 10 10}
                 end
                 case {@variable outputDebugFeats($)} of unit then unit
                 elseof Fs then
                    NL#'%    feat: '#{Value.toVirtualString Fs 10 10}
                 end
                 case {@variable outputDebugMeths($)} of unit then unit
                 elseof Ms then
                    NL#'%    meth: '#{Value.toVirtualString Ms 10 10}
                 end]
             else nil
             end}
         in
            case DebugOutputs of nil then ""
            else
               NL#'% '#{@variable output({AdjoinAt R realcore true} $)}#':'#
               DebugOutputs
            end
         end
      end
   in
      class VariableOccurrence
         from VariableOccurrenceBase CodeGen.variableOccurrence
         prop final
      end

      class PatternVariableOccurrence
         from VariableOccurrenceBase CodeGen.patternVariableOccurrence
         prop final
      end
   end

   local
      class TokenBase from StaticAnalysis.token
         attr value: unit
         feat !ImAToken: unit
         meth init(Value)
            value <- Value
            StaticAnalysis.token, init()
         end
         meth getValue($)
            @value
         end
         meth isConstruction($)
            false
         end
      end
   in
      class Token
         from TokenBase CodeGen.token
         prop final
      end

      class ProcedureToken
         from TokenBase CodeGen.procedureToken
         prop final
         attr definition: unit
         meth init(Value Definition)
            definition <- Definition
            TokenBase, init(Value)
         end
      end

      class ClassToken
         from TokenBase CodeGen.token
         prop final
         attr props: unit attrs: unit feats: unit meths: unit
         meth setProperties(Props)
            props <- Props
         end
         meth getProperties($)
            @props
         end
         meth setAttributes(Attrs)
            attrs <- Attrs
         end
         meth getAttributes($)
            @attrs
         end
         meth setFeatures(Feats)
            feats <- Feats
         end
         meth getFeatures($)
            @feats
         end
         meth setMethods(Meths)
            meths <- Meths
         end
         meth getMethods($)
            @meths
         end
      end

      class ObjectToken
         from TokenBase CodeGen.token
         prop final
         attr classNode: unit
         meth init(TheObject ClassNode)
            value <- TheObject
            StaticAnalysis.token, init()
            classNode <- ClassNode
         end
         meth getClassNode($)
            @classNode
         end
      end
   end
end
