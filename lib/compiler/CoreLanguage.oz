%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Martin Mueller (mmueller@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
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

local
   %% some format strings auxiliaries for output
   IN = format(indent)
   EX = format(exdent)
   PU = format(push)
   PO = format(pop)
   GL = format(glue(" "))
   NL = format(break)
   fun {LI Xs Sep R}
      format(list({Map Xs fun {$ X} {X output(R $)} end} Sep))
   end
   fun {LI2 Xs Sep R ?FS}
      case Xs of X1|Xr then FS01 FS02 FSs in
         {X1 output2(R ?FS01 ?FS02)}
         FSs#FS = {FoldL Xr
                   fun {$ FSs#FS X} FS01 FS02 in
                      {X output2(R ?FS01 ?FS02)}
                      (FS01|FSs)#(FS#FS02)
                   end [FS01]#FS02}
         format(list({Reverse FSs} Sep))
      [] nil then
         FS = ""
         ""
      end
   end

   fun {CheckOutput R Flagname}
      {CondSelect R Flagname false}
   end

   fun {OutputAttrFeat I R ?FS}
      case I of F#T then FS1 FS2 in
         FS = FS1#FS2
         {F outputEscaped2(R $ ?FS1)}#': '#{T output2(R $ ?FS2)}
      else
         {I outputEscaped2(R $ ?FS)}
      end
   end
in
   local
      proc {FlattenSequenceSub X Hd Tl}
         % This procedure converts a statement sequence represented
         % using '|' as a pair constructor, whose left and/or right
         % element may also be a pair, into a list.
         case X of S1|S2 then Inter in
            {FlattenSequenceSub S1 Hd Inter}
            {FlattenSequenceSub S2 Inter Tl}
         [] nil then
            Hd = Tl
         elsecase {X isRedundant($)} then
            Hd = Tl
         else
            Hd = X|Tl
         end
      end

      fun {GetFirst X}
         case X of S1|S2 then First in
            First = {GetFirst S1}
            case First == nil then {GetFirst S2}
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
         Res = case Hd == nil then First in
                  First = {GetFirst X}
                  case First of nil then [{New Core.skipNode init(unit)}]
                  else [First]
                  end
               else Hd
               end
         {LinkList Res}
      end
   end

   local
      class Statement
         from Annotate.statement SA.statement CodeGen.statement
         attr next: unit coord: unit
         meth setPrintName(_ _)
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

      class Declaration
         from Statement Annotate.declaration SA.declaration CodeGen.declaration
         prop final
         attr localVars: unit body: unit
         meth init(LocalVars Body Coord)
            localVars <- LocalVars
            body <- {FlattenSequence Body}
            coord <- Coord
         end
         meth output(R $)
            'local'#GL#IN#{LI @localVars GL true}#EX#GL#'in'#IN#NL#
            {LI @body NL R}#EX#NL#'end'
         end
      end

      class SkipNode
         from Statement Annotate.skipNode SA.skipNode CodeGen.skipNode
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
         from Statement Annotate.equation SA.equation CodeGen.equation
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
         from Annotate.construction SA.construction CodeGen.construction
         prop final
         attr label: unit args: unit isOpen: unit value
         feat !ImAConstruction: unit expansionOccs
         meth init(Label Args IsOpen)
            self.expansionOccs = expansionOccs('`tuple`': _
                                               '`record`': _
                                               '`tellRecordSize`': _
                                               '`^`': _)
            label <- Label
            args <- Args
            isOpen <- IsOpen
            SA.construction, init()
         end
         meth getCoord($)
            {@label getCoord($)}
         end
         meth isVariableOccurrence($)
            false
         end
         meth isConstruction($)
            true
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
               format(list({Reverse FSs} GL))
            else
               FS2 = ""
               ""
            end#
            case @isOpen then
               case @args of nil then '...' else GL#'...' end
            else ""
            end#')'#PO
         end
      end

      class Definition
         from Statement Annotate.definition SA.definition CodeGen.definition
         attr
            designator: unit formalArgs: unit body: unit isStateUsing: unit
            procFlags: unit printName: '' toplevelNames: unit
         feat expansionOccs abstractionTableID
         meth init(Designator FormalArgs Body IsStateUsing ProcFlags Coord)
            self.expansionOccs = expansionOccs('`ooSetSelf`': _)
            designator <- Designator
            formalArgs <- FormalArgs
            body <- {FlattenSequence Body}
            isStateUsing <- IsStateUsing
            procFlags <- ProcFlags
            coord <- Coord
         end
         meth setPrintName(PrintName FeatPrintName)
            printName <- {String.toAtom
                          {VirtualString.toString PrintName#'.'#FeatPrintName}}
         end
         meth output(R $) FS1 in
            'proc {'#PU#{@designator output2(R $ ?FS1)}#
            case @formalArgs of _|_ then GL#{LI @formalArgs GL R}
            [] nil then ""
            end#'}'#
            case {self isClauseBody($)} then '   % clause body' else "" end#
            PO#IN#FS1#NL#
            {LI @body NL R}#EX#NL#'end'
         end
         meth isClauseBody($)
            false
         end
      end
      class FunctionDefinition
         from Definition Annotate.functionDefinition SA.functionDefinition
            CodeGen.functionDefinition
         prop final
      end
      class ClauseBody
         from Definition Annotate.clauseBody SA.clauseBody CodeGen.clauseBody
         prop final
         meth isClauseBody($)
            true
         end
      end

      class Application
         from Statement Annotate.application SA.application CodeGen.application
         prop final
         attr designator: unit actualArgs: unit
         feat codeGenMakeEquateLiteral
         meth init(Designator ActualArgs Coord)
            designator <- Designator
            actualArgs <- ActualArgs
            coord <- Coord
         end
         meth output(R $)
            case {CheckOutput R realcore} then
               Application, OutputApplication(R $)
            else P = {{@designator getVariable($)} getPrintName($)} in
               case P of '`ooExch`' then Attr New Old FS1 FS2 FS3 in
                  @actualArgs = [Attr New Old]
                  {Old output2(R $ ?FS1)}#' = '#
                  {Attr output2(R $ ?FS2)}#' <- '#{New output2(R $ ?FS3)}#
                  FS1#FS2#FS3
               [] '`@`' then Application, OutputPrefixExpression('@' R $)
               [] '`~`' then Application, OutputPrefixExpression('~' R $)
               [] '`<-`' then Application, OutputInfixStatement(' <- ' R $)
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
               [] '`^`' then Application, OutputInfixExpression('^' R $)
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

      class BoolCase
         from Statement Annotate.boolCase SA.boolCase CodeGen.boolCase
         prop final
         attr arbiter: unit consequent: unit alternative: unit
         feat expansionOccs noBoolShared
         meth init(Arbiter Consequent Alternative Coord)
            self.expansionOccs = expansionOccs('`RaiseError`': _
                                               '`true`': _
                                               '`false`': _)
            arbiter <- Arbiter
            consequent <- Consequent
            alternative <- Alternative
            coord <- Coord
         end
         meth output(R $) FS in
            'case '#{@arbiter output2(R $ ?FS)}#' then'#IN#NL#
            {@consequent output(R $)}#EX#NL#{@alternative output(R $)}#'end'#FS
         end
      end

      class BoolClause
         from Annotate.boolClause SA.boolClause CodeGen.boolClause
         prop final
         attr body: unit
         meth init(Body)
            body <- {FlattenSequence Body}
         end
         meth output(R $)
            {LI @body NL R}
         end
      end

      class PatternCase
         from Statement Annotate.patternCase SA.patternCase CodeGen.patternCase
         prop final
         attr arbiter: unit clauses: unit alternative: unit
         meth init(Arbiter Clauses Alternative Coord)
            arbiter <- Arbiter
            clauses <- Clauses
            alternative <- Alternative
            coord <- Coord
         end
         meth output(R $) FS in
            'case '#{@arbiter output2(R $ ?FS)}#' of '#
            {LI @clauses NL#'[] ' R}#NL#
            {@alternative output(R $)}#'end'#FS
         end
      end

      class PatternClause
         from Annotate.patternClause SA.patternClause CodeGen.patternClause
         prop final
         attr localVars: unit pattern: unit body: unit
         meth init(LocalVars Pattern Body)
            localVars <- LocalVars
            pattern <- Pattern
            body <- {FlattenSequence Body}
         end
         meth output(R $) FS in
            PU#{@pattern outputPattern2(R @localVars $ ?FS)}#PO#GL#'then'#IN#
            FS#NL#{LI @body NL R}#EX
         end
      end

      class RecordPattern
         from Annotate.recordPattern SA.recordPattern CodeGen.recordPattern
         prop final
         attr label: unit args: unit isOpen: unit value
         feat !ImAConstruction: unit expansionOccs
         meth init(Label Args IsOpen)
            self.expansionOccs = expansionOccs('`tuple`': _
                                               '`record`': _
                                               '`tellRecordSize`': _
                                               '`^`': _
                                               '`nonBlockingLabel`': _
                                               '`nonBlockingDot`': _)
            label <- Label
            args <- Args
            isOpen <- IsOpen
            SA.recordPattern, init()
         end
         meth getCoord($)
            {@label getCoord($)}
         end
         meth isVariableOccurrence($)
            false
         end
         meth isConstruction($)
            true
         end
         meth output2(R $ ?FS) FS1 FS2 Args in
            FS = FS1#FS2
            case @args of X1|Xr then Start FSs in
               case X1 of F#P then FS01 FS02 FS11 FS12 in
                  {F output2(R ?FS01 ?FS02)}
                  {P output2(R ?FS11 ?FS12)}
                  Start = [FS01#': '#FS11]#(FS02#FS12)
               else FS01 FS02 in
                  {X1 output2(R ?FS01 ?FS02)}
                  Start = [FS01]#FS02
               end
               FSs#FS2 = {FoldL Xr
                          fun {$ FSs#FS X}
                             case X of F#P then FS01 FS02 FS11 FS12 in
                                {F output2(R ?FS01 ?FS02)}
                                {P output2(R ?FS11 ?FS12)}
                                (FS01#': '#FS11|FSs)#(FS#FS02#FS12)
                             else FS01 FS02 in
                                {X output2(R ?FS01 ?FS02)}
                                (FS01|FSs)#(FS#FS02)
                             end
                          end Start}
               Args = format(list({Reverse FSs} GL))
            else
               FS2 = ""
               Args = ""
            end
            {@label output2(R $ ?FS1)}#'('#PU#Args#
            case @isOpen then
               case Args of nil then '...' else GL#'...' end
            else ""
            end#')'#PO
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
               Args = format(list({Reverse FSs} GL))
            else
               FS2 = ""
               Args = ""
            end
            {@label output2(R $ ?FS1)}#'('#PU#Args#
            case @isOpen then
               case Args of nil then '...' else GL#'...' end
            else ""
            end#')'#PO
         end
      end

      class EquationPattern
         from Annotate.equationPattern SA.equationPattern
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
         meth isConstruction($)
            {@right isConstruction($)}
         end
         meth isVariableOccurrence($)
            {@right isVariableOccurrence($)}
         end
         meth output2(R $ ?FS) FS1 FS2 in
            FS = FS1#FS2
            {@left output2(R $ ?FS1)}#'='#{@right output2(R $ ?FS2)}
         end
         meth outputPattern2(R Vs $ ?FS) FS1 FS2 in
            FS = FS1#FS2
            {@left outputPattern2(R Vs $ ?FS1)}#'='#
            {@right outputPattern2(R Vs $ ?FS2)}
         end
      end

      class AbstractElse
         from Annotate.abstractElse SA.abstractElse CodeGen.abstractElse
      end
      class ElseNode
         from AbstractElse Annotate.elseNode SA.elseNode CodeGen.elseNode
         prop final
         attr body: unit
         meth init(Body)
            body <- {FlattenSequence Body}
         end
         meth output(R $)
            'else'#IN#NL#
            {LI @body NL R}#EX#NL
         end
      end
      class NoElse
         from AbstractElse Annotate.noElse SA.noElse CodeGen.noElse
         prop final
         attr coord: unit
         feat expansionOccs
         meth init(Coord)
            self.expansionOccs = expansionOccs('`RaiseError`': _)
            coord <- Coord
         end
         meth getCoord($)
            @coord
         end
         meth output(_ $)
            ""
         end
      end

      class ThreadNode
         from Statement Annotate.threadNode SA.threadNode CodeGen.threadNode
         prop final
         attr body: unit
         meth init(Body Coord)
            body <- {FlattenSequence Body}
            coord <- Coord
         end
         meth output(R $)
            'thread'#IN#NL#
            {LI @body NL R}#EX#NL#'end'
         end
      end

      class TryNode
         from Statement Annotate.tryNode SA.tryNode CodeGen.tryNode
         prop final
         attr tryBody: unit exception: unit catchBody: unit
         meth init(TryBody Exception CatchBody Coord)
            tryBody <- {FlattenSequence TryBody}
            exception <- Exception
            catchBody <- {FlattenSequence CatchBody}
            coord <- Coord
         end
         meth output(R $)
            'try'#IN#NL#
            {LI @tryBody NL R}#EX#NL#
            'catch '#{@exception output(R $)}#' then'#
            IN#NL#{LI @catchBody NL R}#EX#NL#'end'
         end
      end

      class LockNode
         from Statement Annotate.lockNode SA.lockNode CodeGen.lockNode
         prop final
         attr lockVar: unit body: unit
         meth init(LockVar Body Coord)
            lockVar <- LockVar
            body <- {FlattenSequence Body}
            coord <- Coord
         end
         meth output(R $) FS in
            'lock '#{@lockVar output2(R $ ?FS)}#' then'#IN#NL#
            {LI @body NL R}#EX#NL#'end'#FS
         end
      end

      class ClassNode
         from Statement Annotate.classNode SA.classNode CodeGen.classNode
         prop final
         attr
            designator: unit parents: unit properties: unit
            attributes: unit features: unit methods: unit
            printName: '' isVirtualToplevel: false
         feat expansionOccs
         meth init(Designator Parents Props Attrs Feats Meths Coord)
            self.expansionOccs = expansionOccs('`class`': _
                                               '`ooFreeFlag`': _
                                               '`tuple`': _
                                               '`record`': _
                                               '`tellRecordSize`': _
                                               '`^`': _)
            designator <- Designator
            parents <- Parents
            properties <- Props
            attributes <- Attrs
            features <- Feats
            methods <- Meths
            coord <- Coord
         end
         meth setPrintName(PrintName FeatPrintName)
            printName <- {String.toAtom
                          {VirtualString.toString PrintName#'.'#FeatPrintName}}
         end
         meth output(R $) FS1 in
            'class '#{@designator output2(R $ ?FS1)}#IN#FS1#
            case @parents \= nil
               orelse @properties \= nil
               orelse @attributes \= nil
               orelse @features \= nil
               orelse @methods \= nil
            then NL
            else ""
            end#
            case @parents of _|_ then FS2 in
               PU#'from'#GL#{LI2 @parents GL R ?FS2}#PO#FS2#
               case @properties \= nil
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
               case @attributes \= nil
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
               PU#'attr'#GL#format(list({Reverse FSs} GL))#PO#FS4#
               case @features \= nil orelse @methods \= nil then NL else "" end
            else ""
            end#
            case @features of F1|Fr then FS0 FS1 FSs FS5 in
               FS1 = {OutputAttrFeat F1 R ?FS0}
               FSs#FS5 = {FoldL Fr
                          fun {$ FSs#FS I} FS0 in
                             ({OutputAttrFeat I R ?FS0}|FSs)#(FS#FS0)
                          end [FS1]#FS0}
               PU#'feat'#GL#format(list({Reverse FSs} GL))#PO#FS5#
               case @methods \= nil then NL else "" end
            else ""
            end#{LI @methods NL R}#EX#NL#'end'
         end
      end

      class Method
         from Annotate.method SA.method CodeGen.method
         attr label: unit formalArgs: unit body: unit coord: unit
         feat expansionOccs
         meth init(Label FormalArgs Body Coord)
            self.expansionOccs = expansionOccs('`ooRequiredArg`': _
                                               '`ooDefaultVar`': _
                                               '`true`': _
                                               '`false`' : _
                                               '`.`': _
                                               '`width`': _
                                               '`hasFeature`': _
                                               '`RaiseError`': _
                                               '`aritySublist`': _
                                               '`condSelect`': _
                                               '`tuple`': _
                                               '`record`': _)
            label <- Label
            formalArgs <- FormalArgs
            body <- {FlattenSequence Body}
            coord <- Coord
         end
         meth getCoord($)
            @coord
         end
         meth output(R $) FS1 FS2 in
            'meth '#{@label outputEscaped2(R $ ?FS1)}#'('#PU#
            {LI2 @formalArgs GL R ?FS2}#')'#PO#IN#FS1#FS2#NL#
            {LI @body NL R}#EX#NL#'end'
         end
      end
      class MethodWithDesignator
         from Method Annotate.methodWithDesignator SA.methodWithDesignator
            CodeGen.methodWithDesignator
         prop final
         attr messageDesignator: unit isOpen: unit
         meth init(Label FormalArgs IsOpen MessageDesignator Body Coord)
            Method, init(Label FormalArgs Body Coord)
            isOpen <- IsOpen
            messageDesignator <- MessageDesignator
         end
         meth output(R $) FS1 FS2 in
            'meth '#{@label outputEscaped2(R $ ?FS1)}#'('#PU#
            {LI2 @formalArgs GL R ?FS2}#
            case @isOpen then
               case @formalArgs of nil then '...' else GL#'...' end
            else ""
            end#') = '#{@messageDesignator output(R $)}#PO#IN#FS1#FS2#NL#
            {LI @body NL R}#EX#NL#'end'
         end
      end

      class MethFormal
         from Annotate.methFormal SA.methFormal CodeGen.methFormal
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
         meth hasDefault($)
            false
         end
         meth output2(R $ ?FS)
            {@feature output2(R $ ?FS)}#': '#{@arg output(R $)}
         end
      end
      class MethFormalOptional
         from MethFormal Annotate.methFormalOptional SA.methFormalOptional
            CodeGen.methFormalOptional
         prop final
         attr isInitialized: unit
         meth init(Feature Arg IsInitialized)
            feature <- Feature
            arg <- Arg
            isInitialized <- IsInitialized
         end
         meth hasDefault($)
            true
         end
         meth output2(R $ ?FS)
            MethFormal, output2(R $ ?FS)#' <= _'
         end
      end
      class MethFormalWithDefault
         from MethFormal Annotate.methFormalWithDefault
            SA.methFormalWithDefault CodeGen.methFormalWithDefault
         prop final
         attr default: unit
         meth init(Feature Arg Default)
            MethFormal, init(Feature Arg)
            default <- Default
         end
         meth hasDefault($)
            true
         end
         meth output2(R $ ?FS)
            MethFormal, output2(R $ ?FS)#' <= '#
            {System.valueToVirtualString @default 50 1000}
         end
      end

      class ObjectLockNode
         from Statement Annotate.objectLockNode SA.objectLockNode
            CodeGen.objectLockNode
         prop final
         attr body: unit
         feat expansionOccs
         meth init(Body Coord)
            self.expansionOccs = expansionOccs('`ooGetLock`': _)
            body <- {FlattenSequence Body}
            coord <- Coord
         end
         meth output(R $)
            'lock'#IN#NL#{LI @body NL R}#EX#NL#'end'
         end
      end

      class GetSelf
         from Statement Annotate.getSelf SA.getSelf CodeGen.getSelf
         prop final
         attr destination: unit
         meth init(Destination Coord)
            destination <- Destination
            coord <- Coord
         end
         meth output(R $) FS in
            {@destination output2(R $ ?FS)}#' = self'#FS
         end
      end

      class FailNode
         from Statement Annotate.failNode SA.failNode CodeGen.failNode
         prop final
         meth init(Coord)
            coord <- Coord
         end
         meth output(_ $)
            'fail'
         end
      end

      class IfNode
         from Statement Annotate.ifNode SA.ifNode CodeGen.ifNode
         prop final
         attr clauses: unit alternative: unit
         meth init(Clauses Alternative Coord)
            clauses <- Clauses
            alternative <- Alternative
            coord <- Coord
         end
         meth output(R $)
            'if '#IN#{LI @clauses EX#NL#'[] '#IN R}#EX#NL#
            {@alternative output(R $)}#'end'
         end
      end

      class ChoicesAndDisjunctions
         from Statement Annotate.choicesAndDisjunctions
            SA.choicesAndDisjunctions CodeGen.choicesAndDisjunctions
         attr clauses: unit
         meth init(Clauses Coord)
            clauses <- Clauses
            coord <- Coord
         end
      end
      class OrNode
         from ChoicesAndDisjunctions Annotate.orNode SA.orNode CodeGen.orNode
         prop final
         meth output(R $)
            'or '#IN#{LI @clauses EX#NL#'[] '#IN R}#EX#NL#'end'
         end
      end
      class DisNode
         from ChoicesAndDisjunctions Annotate.disNode SA.disNode
            CodeGen.disNode
         prop final
         meth output(R $)
            'dis '#IN#{LI @clauses EX#NL#'[] '#IN R}#EX#NL#'end'
         end
      end
      class ChoiceNode
         from ChoicesAndDisjunctions Annotate.choiceNode SA.choiceNode
            CodeGen.choiceNode
         prop final
         meth output(R $)
            'choice '#IN#{LI @clauses EX#NL#'[] '#IN R}#EX#NL#'end'
         end
      end

      class Clause
         from Annotate.clause SA.clause CodeGen.clause
         prop final
         attr localVars: unit guard: unit kind: unit body: unit
         meth init(LocalVars Guard Kind Body)
            localVars <- LocalVars
            guard <- {FlattenSequence Guard}
            kind <- Kind
            body <- {FlattenSequence Body}
         end
         meth output(R $)
            case @localVars of _|_ then
               {LI @localVars GL R}#EX#GL#'in'#IN#NL
            [] nil then ""
            end#{LI @guard NL R}#EX#NL#'then'#IN#NL#
            case @kind == waitTop then 'skip   % top commit'
            else {LI @body NL R}
            end
         end
      end

      class ValueNode
         from Annotate.valueNode SA.valueNode CodeGen.valueNode
         attr value: unit coord: unit
         feat !ImAValueNode: unit
         meth init(Value Coord)
            value <- Value
            coord <- Coord
            SA.valueNode, init()
         end
         meth isVariableOccurrence($)
            false
         end
         meth isConstruction($)
            false
         end
         meth getCoord($)
            @coord
         end
         meth getValue($)
            @value
         end
         meth outputEscaped2(R $ ?FS)
            {self output2(R $ ?FS)}
         end
      end

      class AtomNode
         from ValueNode Annotate.atomNode SA.atomNode CodeGen.atomNode
         prop final
         meth output2(_ $ ?FS)
            FS = ""
            {System.valueToVirtualString @value 0 0}
         end
         meth outputPattern2(_ _ $ ?FS)
            FS = ""
            {System.valueToVirtualString @value 0 0}
         end
      end

      class IntNode
         from ValueNode Annotate.intNode SA.intNode CodeGen.intNode
         prop final
         meth output2(_ $ ?FS)
            FS = ""
            case @value < 0 then '~'#~@value else @value end
         end
         meth outputPattern2(_ _ $ ?FS)
            FS = ""
            case @value < 0 then '~'#~@value else @value end
         end
      end

      class FloatNode
         from ValueNode Annotate.floatNode SA.floatNode CodeGen.floatNode
         prop final
         meth output2(_ $ ?FS)
            FS = ""
            case @value < 0.0 then '~'#~@value else @value end
         end
         meth outputPattern2(_ _ $ ?FS)
            FS = ""
            case @value < 0.0 then '~'#~@value else @value end
         end
      end

      class Variable
         from Annotate.variable SA.variable CodeGen.variable
         prop final
         attr printName: unit origin: unit coord: unit isToplevel: false
         meth init(PrintName Origin Coord)
            printName <- PrintName
            origin <- Origin
            coord <- Coord
            SA.variable, init()
         end
         meth getPrintName($)
            @printName
         end
         meth getOrigin($)
            @origin
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
         meth output(R $) P = @printName in
            case {CheckOutput R realcore} then {PrintNameToVirtualString P}
            elsecase P of '`unit`' then 'unit'
            [] '`true`' then 'true'
            [] '`false`' then 'false'
            else {PrintNameToVirtualString P}
            end
         end
         meth outputEscaped(R $) P = @printName in
            case {CheckOutput R realcore} then '!'#{PrintNameToVirtualString P}
            elsecase P of '`unit`' then 'unit'
            [] '`true`' then 'true'
            [] '`false`' then 'false'
            else '!'#{PrintNameToVirtualString P}
            end
         end
         meth outputPattern(R Vs $) PrintName = @printName in
            case {Some Vs fun {$ V} {V getPrintName($)} == PrintName end} then
               Variable, output(R $)
            else
               Variable, outputEscaped(R $)
            end
         end
      end

      class VariableOccurrence
         from Annotate.variableOccurrence SA.variableOccurrence
            CodeGen.variableOccurrence
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
         meth isVariableOccurrence($)
            true
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
            VariableOccurrence, OutputValue(R ?FS)
            {@variable output(R $)}
         end
         meth outputEscaped2(R $ ?FS)
            VariableOccurrence, OutputValue(R ?FS)
            {@variable outputEscaped(R $)}
         end
         meth outputPattern2(R Vs $ ?FS)
            VariableOccurrence, OutputValue(R ?FS)
            {@variable outputPattern(R Vs $)}
         end
         meth OutputValue(R $)
            case {CheckOutput R debugValue} then
               NL#'% '#{@variable output(debug(realcore: true) $)}#' = '#
               SA.variableOccurrence, outputDebugValue($)
            else ""
            end#
            case {CheckOutput R debugType} then
               NL#'% '#{@variable output(debug(realcore: true) $)}#': '#
               {@variable outputDebugType($)}
            else ""
            end
         end
      end

      class PatternVariableOccurrence
         from VariableOccurrence Annotate.patternVariableOccurrence
            CodeGen.patternVariableOccurrence
         prop final
      end

      class Token from SA.token CodeGen.token
         feat !ImAToken: unit kind: 'token'
         attr value: unit
         meth getValue($)
            @value
         end
         meth isVariableOccurrence($)
            false
         end
         meth isConstruction($)
            false
         end
         meth isChunk($)
            false
         end
         meth output2(_ $ ?FS)
            FS = ""
            '<'#self.kind#'>'
         end
      end

      class NameToken from Token CodeGen.nameToken
         prop final
         attr printName: unit isToplevel: unit
         feat kind: 'name'
         meth init(PrintName Value IsToplevel)
            printName <- PrintName
            value <- Value
            isToplevel <- IsToplevel
            SA.token, init()
         end
         meth getPrintName($)
            @printName
         end
      end

      class BuiltinToken from Token CodeGen.builtinToken
         prop final
         feat kind: 'builtin'
         meth init(Builtin)
            value <- Builtin
            SA.token, init()
         end
         meth output2(_ $ ?FS)
            FS = ""
            '<'#self.kind#'/'#{Procedure.arity @value}#'>'
         end
      end

      class ProcedureToken from Token CodeGen.procedureToken
         prop final
         feat kind: procedure abstractionTableID clauseBodyStatements
         meth init(TheProcedure)
            value <- TheProcedure
            SA.token, init()
         end
         meth output2(_ $ ?FS)
            FS = ""
            '<'#self.kind#'/'#{Procedure.arity @value}#'>'
         end
      end

      class CellToken from Token
         prop final
         feat kind: 'cell'
         meth init(TheCell)
            value <- TheCell
            SA.token, init()
         end
      end

      class ChunkToken from Token
         prop final
         feat kind: 'chunk'
         meth init(TheChunk)
            value <- TheChunk
            SA.token, init()
         end
         meth isChunk($)
            true
         end
      end

      class ArrayToken from Token
         prop final
         feat kind: 'array'
         meth init(TheArray)
            value <- TheArray
            SA.token, init()
         end
         meth isChunk($)
            true
         end
      end

      class DictionaryToken from Token
         prop final
         feat kind: 'dictionary'
         meth init(TheDictionary)
            value <- TheDictionary
            SA.token, init()
         end
         meth isChunk($)
            true
         end
      end

      class ClassToken from Token
         prop final
         attr props: unit attrs: unit feats: unit meths: unit
         feat kind: 'class'
         meth init(TheClass)
            value <- TheClass
            SA.token, init()
            props <- unit
            attrs <- unit
            feats <- unit
            meths <- unit
         end
         meth isChunk($)
            true
         end
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

      class ObjectToken from Token
         prop final
         attr classNode: unit
         feat kind: 'object'
         meth init(TheObject ClassNode)
            value <- TheObject
            SA.token, init()
            classNode <- ClassNode
         end
         meth isChunk($)
            true
         end
         meth getClassNode($)
            @classNode
         end
      end

      class LockToken from Token
         prop final
         feat kind: 'lock'
         meth init(TheLock)
            value <- TheLock
            SA.token, init()
         end
         meth isChunk($)
            true
         end
      end

      class PortToken from Token
         prop final
         feat kind: 'port'
         meth init(ThePort)
            value <- ThePort
            SA.token, init()
         end
         meth isChunk($)
            true
         end
      end

      class ThreadToken from Token
         prop final
         feat kind: 'thread'
         meth init(TheThread)
            value <- TheThread
            SA.token, init()
         end
      end

      class SpaceToken from Token
         prop final
         feat kind: 'space'
         meth init(TheSpace)
            value <- TheSpace
            SA.token, init()
         end
      end
   in
      Core = core(statement: Statement
                  declaration: Declaration
                  skipNode: SkipNode
                  equation: Equation
                  construction: Construction
                  definition: Definition
                  functionDefinition: FunctionDefinition
                  clauseBody: ClauseBody
                  application: Application
                  boolCase: BoolCase
                  boolClause: BoolClause
                  patternCase: PatternCase
                  patternClause: PatternClause
                  recordPattern: RecordPattern
                  equationPattern: EquationPattern
                  abstractElse: AbstractElse
                  elseNode: ElseNode
                  noElse: NoElse
                  threadNode: ThreadNode
                  tryNode: TryNode
                  lockNode: LockNode
                  classNode: ClassNode
                  method: Method
                  methodWithDesignator: MethodWithDesignator
                  methFormal: MethFormal
                  methFormalOptional: MethFormalOptional
                  methFormalWithDefault: MethFormalWithDefault
                  objectLockNode: ObjectLockNode
                  getSelf: GetSelf
                  failNode: FailNode
                  ifNode: IfNode
                  choicesAndDisjunctions: ChoicesAndDisjunctions
                  orNode: OrNode
                  disNode: DisNode
                  choiceNode: ChoiceNode
                  clause: Clause
                  valueNode: ValueNode
                  atomNode: AtomNode
                  intNode: IntNode
                  floatNode: FloatNode
                  variable: Variable
                  variableOccurrence: VariableOccurrence
                  patternVariableOccurrence: PatternVariableOccurrence
                  token: Token
                  nameToken: NameToken
                  builtinToken: BuiltinToken
                  procedureToken: ProcedureToken
                  cellToken: CellToken
                  chunkToken: ChunkToken
                  arrayToken: ArrayToken
                  dictionaryToken: DictionaryToken
                  classToken: ClassToken
                  objectToken: ObjectToken
                  lockToken: LockToken
                  portToken: PortToken
                  threadToken: ThreadToken
                  spaceToken: SpaceToken)
   end
end
