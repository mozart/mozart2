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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%
%% This file defines the mixin class `Unnester' which transforms
%% Oz code in tuple representation into equivalent code in graph
%% representation.  The following steps are performed:
%% -- Expand any abbreviations not eliminated during the parse.
%% -- Make implicit declarations explicit.
%% -- Unnest expressions inside statements.
%% -- Instantiate the graph nodes.
%%
%% General naming conventions for variables:
%%    S   statement
%%    E   expression
%%    P   phrase (statement or expression)
%%    C   coordinates
%%    V   variable
%%    F   feature
%%    L   label
%%    T   term (i.e., T in Doc/CoreLanguage)
%%
%% Where it adds to the clarity, prefixes are used to indicate the
%% type of Oz abstract syntax the variable holds:
%%    F   tuple representation (F for `full syntax', see Doc/TupleSyntax)
%%    G   graph representation (see Doc/CoreLanguage)
%%

functor
import
   CompilerSupport(concatenateAtomAndInt) at 'x-oz://boot/CompilerSupport'
\ifndef NO_GUMP
   Gump(transformParser transformScanner)
\endif
   System(printName)
   PrintName(downcase)
   Core
   RunTime(procs makeVar)
   Macro(macroExpand:MacroExpand)
   ForLoop(compile)
export
   MakeExpressionQuery
   UnnestQuery
require
   FD(sup: FdSup)
prepare
   fun {IsFd I}
      I =< FdSup andthen I >= 0
   end
define
   \insert TupleSyntax
   \insert BindingAnalysis
   \insert UnnestFD

   SyntaxError = 'syntax error'
   ExpansionError = 'expansion error'

   fun {IsStep Coord}
      case {Label Coord} of pos then false
      [] unit then false
      else true
      end
   end

   fun {CoordNoDebug Coord}
      case {Label Coord} of pos then Coord
      else {Adjoin Coord pos}
      end
   end

   fun {GetLast X}
      case X of S1|S2 then Last in
         Last = {GetLast S2}
         if Last == nil then {GetLast S1}
         else Last
         end
      [] nil then nil
      else X
      end
   end

   %% The following three functions (DollarsInScope, DollarCoord and
   %% ReplaceDollar) operate on the dollars in pattern position,
   %% corresponding to the definition of GetPatternVariablesExpression.

   fun {DollarsInScope FE I}
      %% Returns the number of dollars in pattern position in a given
      %% expression.  (FE may also be a list of expressions.)
      case FE of fEq(E1 E2 _) then
         {DollarsInScope E2 {DollarsInScope E1 I}}
      [] fDollar(_) then
         I + 1
      [] fRecord(_ As) then
         {DollarsInScope As I}
      [] fOpenRecord(_ As) then
         {DollarsInScope As I}
      [] fColon(_ E) then
         {DollarsInScope E I}
      [] fMethArg(E _) then
         {DollarsInScope E I}
      [] fMethColonArg(_ E _) then
         {DollarsInScope E I}
      [] FE1|FEr then   % list of expressions
         {DollarsInScope FEr {DollarsInScope FE1 I}}
      else I
      end
   end

   fun {DollarCoord FE}
      %% Returns the coordinates of the leftmost dollar in pattern
      %% position in a given expression, if there is one, else unit.
      %% (FE may also be a list of expressions.)
      case FE of fEq(E1 E2 _) then
         case {DollarCoord E1} of unit then {DollarCoord E2}
         elseof C then C
         end
      [] fDollar(C) then
         C
      [] fRecord(_ As) then
         {FoldL As fun {$ In A}
                      case In of unit then {DollarCoord A}
                      else In
                      end
                   end unit}
      [] fOpenRecord(_ As) then
         {FoldL As fun {$ In A}
                      case In of unit then {DollarCoord A}
                      else In
                      end
                   end unit}
      [] fColon(_ E) then
         {DollarCoord E}
      [] fMethArg(E _) then
         {DollarCoord E}
      [] fMethColonArg(_ E _) then
         {DollarCoord E}
      [] _|_ then
         {FoldL FE fun {$ In E}
                      case In of unit then {DollarCoord E}
                      else In
                      end
                   end unit}
      else unit
      end
   end

   fun {ReplaceDollar FE FV}
      %% Returns an expression in which all dollars (0 or more) in pattern
      %% position in an expression are replaced by a given variable.
      %% (FE may also be a list of expressions.)
      case FE of fEq(E1 E2 C) then
         fEq({ReplaceDollar E1 FV} {ReplaceDollar E2 FV} C)
      [] fDollar(_) then
         FV
      [] fRecord(L As) then
         fRecord(L {Map As fun {$ A} {ReplaceDollar A FV} end})
      [] fOpenRecord(L As) then
         fOpenRecord(L {Map As fun {$ A} {ReplaceDollar A FV} end})
      [] fColon(F E1) then
         fColon(F {ReplaceDollar E1 FV})
      [] fMethArg(E D) then
         fMethArg({ReplaceDollar E FV} D)
      [] fMethColonArg(F E D) then
         fMethColonArg(F {ReplaceDollar E FV} D)
      [] _|_ then
         {Map FE fun {$ E} {ReplaceDollar E FV} end}
      else
         FE
      end
   end

   fun {MakeTrivialLocalPrefix FS FVsHd FVsTl}
      %% Given a `local' prefix FS (i. e., S in `local S in P end'),
      %% compute its pattern variables and place them in the difference
      %% list FVsHd-FVsTl.  Return the statement, from which single
      %% variables occurring as statements have been removed.
      case FS of fAnd(S1 S2) then FVsInter in
         fAnd({MakeTrivialLocalPrefix S1 FVsHd FVsInter}
              {MakeTrivialLocalPrefix S2 FVsInter FVsTl})
      [] fVar(_ _) then   % remove single variable
         FVsHd = FS|FVsTl
         fSkip(unit)
      [] fWildcard(_) then   % ignore solitary wildcard
         FVsHd = FVsTl
         fSkip(unit)
      [] fDoImport(_ _ _) then
         FVsHd = FS|FVsTl
         FS
      else
         {GetPatternVariablesStatement FS FVsHd FVsTl}
         FS
      end
   end

   fun {MakeDeclaration GVs GS C}
      %% If GVs (a list of variables local to statement GS) is empty,
      %% return GS, else instantiate a Declaration node.
      case GVs of _|_ then {New Core.declaration init(GVs GS C)}
      else GS
      end
   end

   fun {MakeIfNode GArbiter GIfTrue GIfFalse C BA}
      GT GF
   in
      GT = {New Core.ifClause init(GIfTrue)}
      case GIfFalse of noElse(C) then
         GF = {New Core.noElse init(C)}
      else
         GF = {New Core.elseNode init(GIfFalse)}
      end
      {New Core.ifNode init(GArbiter GT GF C)}
   end

   proc {SortNoColonsToFront Args IHd ITl FHd FTl}
      case Args of Arg|Argr then IInter FInter in
         case Arg of _#_ then
            IHd = IInter
            FHd = Arg|FInter
         else
            IHd = Arg|IInter
            FHd = FInter
         end
         {SortNoColonsToFront Argr IInter ITl FInter FTl}
      [] nil then
         IHd = ITl
         FHd = FTl
      end
   end

   fun {IsGround FE}
      %% Return `true' if FE is a ground term, else `false'.
      case FE of fAtom(_ _) then true
      [] fInt(_ _) then true
      [] fFloat(_ _) then true
      [] fRecord(L As) then
         case L of fAtom(_ _) then {All As IsGround}
         else false
         end
      [] fColon(F E) then
         case F of fAtom(_ _) then {IsGround E}
         [] fInt(_ _) then {IsGround E}
         else false
         end
      else false
      end
   end

   local
      fun {IsPatternSub As AllowDollar}
         case As of A|Ar then
            case A of fColon(_ E) then {IsPattern E AllowDollar}
            else {IsPattern A AllowDollar}
            end
            andthen {IsPatternSub Ar AllowDollar}
         [] nil then true
         end
      end
   in
      fun {IsPattern FE AllowDollar}
         %% Returns `true' if FE is a pattern as allowed in case and
         %% catch patterns and in proc/fun heads, else `false'.
         %% (Variables are allowed in label and feature position.)
         case FE of fEq(E1 E2 _) then
            case E1 of fVar(_ _) then {IsPattern E2 AllowDollar}
            [] fWildcard(_) then {IsPattern E2 AllowDollar}
            elsecase E2 of fVar(_ _) then {IsPattern E1 AllowDollar}
            [] fWildcard(_) then {IsPattern E1 AllowDollar}
            else false
            end
         [] fAtom(_ _) then true
         [] fVar(_ _) then true
         [] fAnonVar(_ _ _) then true
         [] fWildcard(_) then true
         [] fDollar(_) then AllowDollar
         [] fEscape(_ _) then true
         [] fInt(_ _) then true
         [] fFloat(_ _) then true
         [] fRecord(_ As) then
            {IsPatternSub As AllowDollar}
         [] fOpenRecord(_ As) then
            {IsPatternSub As AllowDollar}
         else false
         end
      end
   end

   proc {SortFunctorDescriptors FDescriptors Rep
         FRequire FPrepare FImport FExport FDefine1 FDefine2}
      case FDescriptors of D|Dr then
         case D of fRequire(Rs C) then
            if {IsFree FRequire} then FRequire = Rs
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `require\' descriptor '#
                                'in functor definition'))}
            end
         [] fPrepare(_ _ C) then
            if {IsFree FPrepare} then FPrepare = D
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `prepare\' descriptor '#
                                'in functor definition'))}
            end
         [] fImport(Is C) then
            if {IsFree FImport} then FImport = Is
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `import\' descriptor '#
                                'in functor definition'))}
            end
         [] fExport(Es C) then
            if {IsFree FExport} then FExport = Es
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `export\' descriptor '#
                                'in functor definition'))}
            end
         [] fDefine(D1 D2 C) then
            if {IsFree FDefine1} then FDefine1 = D1 FDefine2 = D2
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `define\' descriptor '#
                                'in functor definition'))}
            end
         end
         {SortFunctorDescriptors Dr Rep
          FRequire FPrepare FImport FExport FDefine1 FDefine2}
      [] nil then
         if {IsFree FRequire} then FRequire = unit end
         if {IsFree FPrepare} then FPrepare = unit end
         if {IsFree FImport} then FImport = nil end
         if {IsFree FExport} then FExport = nil end
         if {IsFree FDefine1} then
            FDefine1 = fSkip(unit)
            FDefine2 = fSkip(unit)
         end
      end
   end

   fun {GenerateImportFeature I Fs} A in
      A = {CompilerSupport.concatenateAtomAndInt 'implicit' I}
      if {Member A Fs} then {GenerateImportFeature I + 1 Fs}
      else A
      end
   end

   proc {SortClassDescriptors FDescriptors Rep FFrom FProp FAttr FFeat}
      case FDescriptors of D|Dr then
         case D of fFrom(Fs C) then
            if {IsFree FFrom} then FFrom = Fs
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `from\' descriptor '#
                                'in class definition'))}
            end
         [] fProp(Ps C) then
            if {IsFree FProp} then FProp = Ps
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `prop\' descriptor '#
                                'in class definition'))}
            end
         [] fAttr(As C) then
            if {IsFree FAttr} then FAttr = As
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `attr\' descriptor '#
                                'in class definition'))}
            end
         [] fFeat(Fs C) then
            if {IsFree FFeat} then FFeat = Fs
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `feat\' descriptor '#
                                'in class definition'))}
            end
         end
         {SortClassDescriptors Dr Rep FFrom FProp FAttr FFeat}
      [] nil then
         if {IsFree FFrom} then FFrom = nil end
         if {IsFree FProp} then FProp = nil end
         if {IsFree FAttr} then FAttr = nil end
         if {IsFree FFeat} then FFeat = nil end
      end
   end

   fun {DotPrintName PrintName FeatPrintName}
      if {IsName PrintName} then unit
      else
         {VirtualString.toAtom
          PrintName#'.'#{Value.toVirtualString FeatPrintName 0 0}}
      end
   end

   proc {SetPrintName GBack0 PrintName FeatPrintName}
      if {IsName PrintName} then skip
      elsecase {GetLast GBack0} of nil then skip
      elseof GS then
         {GS setPrintName({DotPrintName PrintName FeatPrintName})}
      end
   end

   class Unnester
      attr
         BA                  % this holds an instance of `BindingAnalysis'
         CurrentImportFV     % temporarily used while transforming functors
         AdditionalImports   % temporarily used while transforming functors
         Stateful            % true iff state access allowed (i. e., in method)
         StateUsed           % true iff state has been accessed
         ArgCounter          % temporarily used while transforming method heads
         reporter
         state

      meth init(TopLevel Reporter State)
         BA <- {New BindingAnalysis init(TopLevel Reporter State)}
         CurrentImportFV <- unit
         AdditionalImports <- nil
         reporter <- Reporter
         state <- State
      end

      meth unnestQuery(Query ?GVs ?GS ?FreeGVs)
         Stateful <- false
         case Query of fDeclare(FS1 FS2 C) then NewFS1 FVs GS0 GVs0 in
            NewFS1 = {MakeTrivialLocalPrefix FS1 ?FVs nil}
            {@BA openScope()}
            {ForAll FVs
             proc {$ fVar(PrintName C)} {@BA bind(PrintName C _)} end}
            {@BA openScope()}
            GS0 = (Unnester, UnnestStatement(NewFS1 $)|
                   Unnester, UnnestStatement(FS2 $))
            {@BA closeScope(?GVs0)}
            GS = {Core.flattenSequence {MakeDeclaration GVs0 GS0 C}}
            {@BA closeScope(?GVs)}
            {ForAll GVs
             proc {$ V}
                {V setUse(multiple)}
                {V setToplevel(true)}
             end}
         else GS0 C = {CoordinatesOf Query} in
            GVs = nil
            {@BA openScope()}
            Unnester, UnnestStatement(Query ?GS0)
            GS = {Core.flattenSequence
                  {MakeDeclaration {@BA closeScope($)} GS0 C}}
         end
         {@BA getFreeVariablesOfQuery(?FreeGVs)}
      end

      meth UnnestToTerm(FE Origin ?GEqs ?GT)
         case FE of fAtom(X C) then
            GEqs = nil
            GT = {New Core.valueNode init(X C)}
         [] fInt(X C) then
            GEqs = nil
            GT = {New Core.valueNode init(X C)}
         [] fFloat(X C) then
            GEqs = nil
            GT = {New Core.valueNode init(X C)}
         else
            Unnester, UnnestToVar(FE Origin ?GEqs ?GT)
         end
      end
      meth UnnestToVar(FE Origin ?GEqs ?GVO)
         case FE of fVar(PrintName C) then
            GEqs = nil
            {@BA refer(PrintName C ?GVO)}
         [] fOcc(V) then
            GEqs = nil
            {V occ({V getCoord($)} ?GVO)}
         [] fWildcard(C) then GV in
            GEqs = nil
            {@BA generate('Wildcard' C ?GV)}
            {GV occ(C ?GVO)}
         [] fEscape(fVar(PrintName C) _) then
            GEqs = nil
            {@BA refer(PrintName C ?GVO)}
         [] fGetBinder(FV GV) then
            GEqs = nil
            case FV of fVar(PrintName C) then
               {@BA refer(PrintName C ?GVO)}
               {GVO getVariable(?GV)}
            [] fOcc(X) then
               GV = X
               {GV occ({GV getCoord($)} ?GVO)}
            end
         [] fOpApply('.' [fVar(X C) fAtom(Y _)] _)
            andthen SubtreeGVO in {@BA referImport(X C Y $ ?SubtreeGVO)}
         then
            GEqs = nil
            GVO = SubtreeGVO
         elseof fOpApply('.' [fVar(X C) fInt(Y _)] _)
            andthen SubtreeGVO in {@BA referImport(X C Y $ ?SubtreeGVO)}
         then
            GEqs = nil
            GVO = SubtreeGVO
         else NewOrigin C = {CoordinatesOf FE} GV in
            NewOrigin = case FE of fSelf(_) then 'Self'
                        [] fProc(_ _ _ _ _) then 'Proc'
                        [] fFun(_ _ _ _ _) then 'Fun'
                        [] fFunctor(_ _ _) then 'Functor'
                        [] fClass(_ _ _ _) then 'Class'
                        [] fScanner(_ _ _ _ _ _) then 'Scanner'
                        [] fParser(_ _ _ _ _ _ _) then 'Parser'
                        else Origin
                        end
            {@BA generate(NewOrigin C ?GV)}
            Unnester, UnnestExpression(FE GV ?GEqs)
            {GV occ(C ?GVO)}
         end
      end
      meth MakeLabelOrFeature(F $)
         case F of fAtom(X C) then
            {New Core.valueNode init(X C)}
         [] fInt(X C) then
            {New Core.valueNode init(X C)}
         [] fVar(PrintName C) then
            {@BA refer(PrintName C $)}
         [] fEscape(fVar(PrintName C) _) then
            %% this case is needed for class attr/feat
            {@BA refer(PrintName C $)}
         end
      end
      meth GenerateNewVar(Origin FVs C ?GV)
         {@BA openScope()}
         {ForAll FVs proc {$ fVar(PrintName C)} {@BA bind(PrintName C _)} end}
         {@BA generateForOuterScope(Origin C ?GV)}
         {@BA closeScope(_)}
      end
      meth Refer(FV ?GVO)
         case FV of fVar(PrintName C) then
            {@BA refer(PrintName C ?GVO)}
         [] fOcc(GV) then
            {GV occ({GV getCoord($)} ?GVO)}
         end
      end

      meth UnnestStatement(FS $)
         case FS of fStepPoint(FS Kind C) then GS in
            Unnester, UnnestStatement(FS ?GS)
            if {@state getSwitch(controlflowinfo $)} andthen {IsStep C}
            then {New Core.stepPoint init(GS Kind C)}
            else GS
            end
         [] fAnd(FS1 FS2) then
            Unnester, UnnestStatement(FS1 $)|
            Unnester, UnnestStatement(FS2 $)
         [] fEq(FE1 FE2 C) then GFront GBack in
            case FE2 of fVar(PrintName C2) then GV in
               {{@BA refer(PrintName C2 $)} getVariable(?GV)}   %--**
               Unnester, UnnestConstraint(FE1 GV ?GFront ?GBack)
            [] fOcc(GV) then
               Unnester, UnnestConstraint(FE1 GV ?GFront ?GBack)
            [] fEscape(fVar(PrintName C2) _) then GV in
               {{@BA refer(PrintName C2 $)} getVariable(?GV)}   %--**
               Unnester, UnnestConstraint(FE1 GV ?GFront ?GBack)
            elsecase FE1 of fVar(PrintName C2) then GV in
               {{@BA refer(PrintName C2 $)} getVariable(?GV)}   %--**
               Unnester, UnnestConstraint(FE2 GV ?GFront ?GBack)
            [] fOcc(GV) then
               Unnester, UnnestConstraint(FE2 GV ?GFront ?GBack)
            [] fEscape(fVar(PrintName C2) _) then GV in
               {{@BA refer(PrintName C2 $)} getVariable(?GV)}   %--**
               Unnester, UnnestConstraint(FE2 GV ?GFront ?GBack)
            else GV in
               {@BA generate('Equation' C ?GV)}
               Unnester, UnnestConstraint(FS GV ?GFront ?GBack)
            end
            GFront|GBack
         [] fAssign(FE1 FE2 C) then
            if @Stateful then
               StateUsed <- true
            else
               {@reporter
                error(coord: C kind: ExpansionError
                      msg: 'attribute assignment used outside of method')}
            end
            Unnester, UnnestStatement(fOpApplyStatement('Object.\'<-\''
                                                        [FE1 FE2] C) $)
         [] fOpApplyStatement(Op FEs C) then
            GVO GFrontEqs1 GFrontEqs2 GTs GS
         in
            if {IsAtom Op} then
               {RunTime.procs.Op occ(C ?GVO)}
            else
               {{RunTime.makeVar {System.printName Op} Op} occ(C ?GVO)}
            end
            Unnester, UnnestApplyArgs(FEs ?GFrontEqs1 ?GFrontEqs2 ?GTs)
            GS = {New Core.application init(GVO GTs C)}
            GFrontEqs1|GFrontEqs2|GS
         [] fFdCompare(Op FE1 FE2 C) then
            GFrontEq1 NewFE1 GFrontEq2 NewFE2 FS FD
         in
            Unnester, UnnestFDExpression(FE1 ?GFrontEq1 ?NewFE1)
            Unnester, UnnestFDExpression(FE2 ?GFrontEq2 ?NewFE2)
            Unnester, AddImport('x-oz://system/FD.ozf' ?FD)
            FS = {MakeFdCompareStatement Op NewFE1 NewFE2 C FD}
            GFrontEq1|GFrontEq2|Unnester, UnnestStatement(FS $)
         [] fFdIn(Op FE1 FE2 C) then FS in
            %% note: reverse arguments!
            case Unnester, AddImport('x-oz://system/FD.ozf' $)
            of unit then
               FS = fOpApplyStatement(case Op of '::' then 'FD.int'
                                      [] ':::' then 'FD.dom'
                                      end [FE2 FE1] C)
            elseof FE then Feature CND in
               Feature = case Op of '::' then 'int'
                         [] ':::' then 'dom'
                         end
               CND = {CoordNoDebug C}
               FS = fApply(fOpApply('.' [FE fAtom(Feature C)] CND)
                           [FE2 FE1] C)
            end
            Unnester, UnnestStatement(FS $)
         [] fObjApply(FE1 FE2 C) then
            if @Stateful then
               StateUsed <- true
               case FE1 of fSelf(C) then
                  {@reporter
                   error(coord: C kind: ExpansionError
                         msg: '"self, message" not allowed'
                         items: [hint(l: 'Hint'
                                      m: ('use a class in front of "," '#
                                          'or use "{self message}"'))])}
               else skip
               end
            else
               {@reporter
                error(coord: C kind: ExpansionError
                      msg: 'object application used outside of method')}
            end
            Unnester, UnnestStatement(fOpApplyStatement('Object.\',\''
                                                        [FE1 FE2] C) $)
         [] fDollar(C) then
            {@reporter error(coord: C kind: ExpansionError
                             msg: 'illegal use of nesting marker')}
            {New Core.skipNode init(C)}
         [] fApply(FE1 FEs C) then GFrontEq GVO GFrontEqs1 GFrontEqs2 GTs GS in
            case FE1 of fSelf(_) then
               case FEs of [_] then skip else
                  {@reporter error(coord:C kind: ExpansionError
                                   msg:'illegal application of self')}
               end
            else skip end
            Unnester, UnnestToVar(FE1 'UnnestApply' ?GFrontEq ?GVO)
            Unnester, UnnestApplyArgs(FEs ?GFrontEqs1 ?GFrontEqs2 ?GTs)
            GS = {New Core.application init(GVO GTs C)}
            GFrontEq|GFrontEqs1|GFrontEqs2|GS
         [] fProc(FE1 FEs FS ProcFlags C) then
            GFrontEq GVO OldStateUsed ProcFlagAtoms LazyFlags RestFlags N
            GS GFormals IsStateUsing GD
         in
            Unnester, UnnestToVar(FE1 'Proc' ?GFrontEq ?GVO)
            OldStateUsed = (StateUsed <- false)
            ProcFlagAtoms = {Map ProcFlags fun {$ fAtom(A _)} A end}
            {List.partition ProcFlagAtoms fun {$ A} A == 'lazy' end
             ?LazyFlags ?RestFlags}
            {@BA openScope()}
            N = {DollarsInScope FEs 0}
            if LazyFlags \= nil then
               {@reporter
                error(coord: C kind: SyntaxError
                      msg: 'procedure flag `lazy\' only allowed on functions')}
            elseif N =< 1 then skip
            else
               {@reporter
                error(coord: {DollarCoord FEs} kind: SyntaxError
                      msg: 'at most one $ in procedure head allowed')}
            end
            Unnester, UnnestProc(FEs FS C ?GS)
            {@BA closeScope(?GFormals)}
            IsStateUsing = (@StateUsed orelse
                            @Stateful andthen
                            {@state getSwitch(staticvarnames $)})
            StateUsed <- IsStateUsing orelse OldStateUsed
            GD = {New Core.definition
                  init(GVO GFormals GS IsStateUsing RestFlags C)}
            if {@state getSwitch(staticvarnames $)} then
               {GD setAllVariables({@BA getAllVariables($)})}
            end
            GFrontEq|GD   % Definition node must always be second element!
         [] fFun(FE1 FEs FE2 ProcFlags C) then LazyFlags RestFlags in
            {List.partition ProcFlags fun {$ fAtom(A _)} A == 'lazy' end
             ?LazyFlags ?RestFlags}
            if {DollarsInScope FEs 0} > 0 then
               {@reporter error(coord: {DollarCoord FEs} kind: SyntaxError
                                msg: 'no $ in function head allowed')}
               nil
            elseif LazyFlags == nil then
               GFrontEq GVO OldStateUsed NewFEs GS GFormals IsStateUsing GD
            in
               Unnester, UnnestToVar(FE1 'Fun' ?GFrontEq ?GVO)
               OldStateUsed = (StateUsed <- false)
               {@BA openScope()}
               NewFEs = {Append FEs [fDollar(C)]}
               Unnester, UnnestProc(NewFEs FE2 C ?GS)
               {@BA closeScope(?GFormals)}
               IsStateUsing = (@StateUsed orelse
                               @Stateful andthen
                               {@state getSwitch(staticvarnames $)})
               StateUsed <- IsStateUsing orelse OldStateUsed
               GD = {New Core.definition
                     init(GVO GFormals GS IsStateUsing
                          {Map RestFlags fun {$ fAtom(A _)} A end} C)}
               if {@state getSwitch(staticvarnames $)} then
                  {GD setAllVariables({@BA getAllVariables($)})}
               end
               GFrontEq|GD   % Definition node must always be second element!
            else CND Formals NewFE NewFS in
               CND = {CoordNoDebug C}
               Formals#NewFE = {FoldR FEs
                                fun {$ FE1 Formals#FE2} GV in
                                   (fAnonVar('Result' C GV)|Formals)#
                                   fCase(fOcc(GV) [fCaseClause(FE1 FE2)]
                                         fNoElse(CND)   %--** better exception
                                         CND)
                                end nil#FE2}
               NewFS = fFun(FE1 Formals
                            fOpApply('Value.byNeed'
                                     [fFun(fDollar(CND) nil NewFE nil CND)]
                                     CND) RestFlags C)
               Unnester, UnnestStatement(NewFS $)
            end
         [] fFunctor(FE FDescriptors C) then
            FRequire FPrepare FImport FExport FDefine1 FDefine2
         in
            {SortFunctorDescriptors FDescriptors @reporter
             ?FRequire ?FPrepare ?FImport ?FExport ?FDefine1 ?FDefine2}
            if FRequire == unit andthen FPrepare == unit then
               GFrontEq GVO ImportGV ImportFeatures FImportArgs ImportFS
               FExportArgs FColons CND NewFDefine
               FunGV FunFV FFun OldImportFV OldAdditionalImports GFun
               FImportDesc FExportDesc FS
               GNewFunctor GS
            in
               Unnester, UnnestToVar(FE 'Functor' ?GFrontEq ?GVO)
               Unnester, AnalyseImports(FImport ImportGV
                                        ?ImportFeatures ?FImportArgs ?ImportFS)
               Unnester, AnalyseExports(FExport ?FExportArgs ?FColons)
               CND = {CoordNoDebug C}
               NewFDefine = fLocal(fAnd(ImportFS FDefine1)
                                   fAnd(FDefine2
                                        fRecord(fAtom('export' CND) FColons))
                                   C)
               {@BA generate('Body' C ?FunGV)}
               FunFV = fOcc(FunGV)
               FFun = fFun(FunFV [fAnonVar('IMPORT' C ImportGV)] NewFDefine
                           [fAtom('instantiate' C)] CND)
               OldImportFV = @CurrentImportFV
               OldAdditionalImports = @AdditionalImports
               CurrentImportFV <- fOcc(ImportGV)
               AdditionalImports <- nil
               Unnester, UnnestStatement(FFun ?GFun)
               FImportDesc = fRecord(fAtom('import' CND)
                                     {FoldR @AdditionalImports
                                      fun {$ X#F In#Fs} Type From in
                                         X = {GenerateImportFeature 1 Fs}
                                         Type = fColon(fAtom('type' unit)
                                                       fAtom(nil unit))
                                         From = fColon(fAtom('from' unit)
                                                       fAtom(F unit))
                                         (fColon(fAtom(X unit)
                                                 fRecord(fAtom(info unit)
                                                         [Type From]))|In)#
                                         (X|Fs)
                                      end FImportArgs#ImportFeatures}.1)
               AdditionalImports <- OldAdditionalImports
               CurrentImportFV <- OldImportFV
               FExportDesc = fRecord(fAtom('export' CND) FExportArgs)
               FS = fOpApplyStatement('Functor.new'
                                      [FImportDesc FExportDesc FunFV
                                       fOcc({GVO getVariable($)})] CND)
               Unnester, UnnestStatement(FS ?GNewFunctor)
               GS = GFun|GNewFunctor
               GFrontEq|
               if {@state getSwitch(controlflowinfo $)} andthen {IsStep C}
               then {New Core.stepPoint init(GS 'definition' C)}
               else GS
               end
            else GV1 GV2 FV1 FV2 FS1 CND BaseURL FS2 in
               {@BA generate('OuterFunctor' C ?GV1)}
               {@BA generate('InnerFunctor' C ?GV2)}
               FV1 = fOcc(GV1)
               FV2 = fOcc(GV2)
               FS1 = fFunctor(FV1 [fImport(case FRequire of unit then nil
                                           else FRequire
                                           end unit)
                                   fExport([fExportItem(fColon(fAtom(inner
                                                                     unit)
                                                               FV2))] unit)
                                   fDefine(fAnd({CondSelect FPrepare 1
                                                 fSkip(unit)}
                                                fFunctor(FV2
                                                         [fImport(FImport unit)
                                                          fExport(FExport unit)
                                                          fDefine(FDefine1
                                                                  FDefine2
                                                                  unit)]
                                                         C))
                                           {CondSelect FPrepare 2 fSkip(unit)}
                                           unit)] C)
               %% FE = {`ApplyFunctor` N FV1}.inner
               CND = {CoordNoDebug C}
               BaseURL = case {@state getBaseURL($)} of unit then
                            {CondSelect C 1 ''}
                         elseof A then A
                         end
               FS2 = fEq(FE fOpApply('.' [fOpApply('ApplyFunctor'
                                                   [fAtom(BaseURL unit) FV1]
                                                   CND)
                                          fAtom(inner unit)] CND) C)
               Unnester, UnnestStatement(FS1 $)|
               Unnester, UnnestStatement(FS2 $)
            end
         [] fDoImport(_ GV ImportGV) then
            C DotGVO ImportGVO CND GFrontEqs FeatureGVO ResGVO
         in
            {ImportGV getCoord(?C)}
            {RunTime.procs.'.' occ(C ?DotGVO)}
            {ImportGV occ(C ?ImportGVO)}
            CND = {CoordNoDebug C}
            Unnester, UnnestToVar(fAtom({GV getPrintName($)} CND) 'Feature'
                                  ?GFrontEqs ?FeatureGVO)
            {GV occ(C ?ResGVO)}
            GFrontEqs|{New Core.application
                       init(DotGVO [ImportGVO FeatureGVO ResGVO] CND)}
         [] fClass(FE FDescriptors FMeths C) then
            GFrontEq GVO FPrivates GPrivates
            FFrom FProp FAttr FFeat
            GS1 GS2 GS3 GS4 GParents GProps GAttrs GFeats
            OldStateful OldStateUsed GS5 GMeths GVs GClass
         in
            Unnester, UnnestToVar(FE 'Class' ?GFrontEq ?GVO)
            {@BA openScope()}
            %% declare private members:
            {SortClassDescriptors FDescriptors @reporter
             ?FFrom ?FProp ?FAttr ?FFeat}
            FPrivates = {FoldR FAttr PrivateAttrFeat
                         {FoldR FFeat PrivateAttrFeat
                          {FoldR FMeths PrivateMeth nil}}}
            {Map {UniqueVariables FPrivates}
             fun {$ FV=fVar(PrintName C)} FS in
                {@BA bind(PrintName C _)}
                FS = fOpApplyStatement('Name.new' [FV] C)
                Unnester, UnnestStatement(FS $)
             end ?GPrivates}
            %% unnest the descriptors:
            Unnester, UnnestFromProp(FFrom 'Parent' ?GS1 nil ?GParents nil)
            Unnester, UnnestFromProp(FProp 'Property' ?GS2 nil ?GProps nil)
            Unnester, UnnestAttrFeat(FAttr 'Attribute' ?GS3 nil ?GAttrs nil)
            Unnester, UnnestAttrFeat(FFeat 'Feature' ?GS4 nil ?GFeats nil)
            %% transform methods:
            OldStateful = (Stateful <- true)
            OldStateUsed = (StateUsed <- false)
            Unnester, UnnestMeths(FMeths ?GS5 ?GMeths)
            Stateful <- OldStateful
            StateUsed <- OldStateUsed
            {@BA closeScope(?GVs)}
            GClass = {New Core.classNode
                      init(GVO GParents GProps GAttrs GFeats GMeths C)}
            GFrontEq|
            {MakeDeclaration GVs GPrivates|GS1|GS2|GS3|GS4|GS5|GClass C}
\ifndef NO_GUMP
         [] fScanner(T Ds Ms Rules Prefix C) then
            From Prop Attr Feat Flags FS Is
         in
            {SortClassDescriptors Ds @reporter ?From ?Prop ?Attr ?Feat}
            Flags = flags(prefix: Prefix
                          directory: {@state getGumpDirectory($)}
                          bestfit:
                             {@state getSwitch(gumpscannerbestfit $)}
                          caseless:
                             {@state getSwitch(gumpscannercaseless $)}
                          nowarn:
                             {@state getSwitch(gumpscannernowarn $)}
                          backup:
                             {@state getSwitch(gumpscannerbackup $)}
                          perfreport:
                             {@state getSwitch(gumpscannerperfreport $)}
                          statistics:
                             {@state getSwitch(gumpscannerstatistics $)})
            FS#Is = {Gump.transformScanner
                     T From Prop Attr Feat Ms Rules C Flags
                     @CurrentImportFV @reporter}
            case Is of nil then skip
            else
               AdditionalImports <- {Append @AdditionalImports Is}
            end
            Unnester, UnnestStatement(FS $)
         [] fParser(T Ds Ms Tokens Rules Expect C) then
            From Prop Attr Feat Flags FS
         in
            {SortClassDescriptors Ds @reporter ?From ?Prop ?Attr ?Feat}
            Flags = flags(expect: Expect
                          directory: {@state getGumpDirectory($)}
                          outputSimplified:
                             {@state
                              getSwitch(gumpparseroutputsimplified $)}
                          verbose:
                             {@state getSwitch(gumpparserverbose $)})
            FS = {Gump.transformParser
                  T From Prop Attr Feat Ms Tokens Rules C Flags
                  {@state getProductionTemplates($)}
                  @reporter}
            Unnester, UnnestStatement(FS $)
\else
         [] fScanner(T _ _ _ _ _) then C = {CoordinatesOf T} in
            {@reporter error(coord: C kind: 'bootstrap compiler restriction'
                             msg: 'Gump definitions not supported')}
            {New Core.skipNode init(C)}
         [] fParser(T _ _ _ _ _ _) then C = {CoordinatesOf T} in
            {@reporter error(coord: C kind: 'bootstrap compiler restriction'
                             msg: 'Gump definitions not supported')}
            {New Core.skipNode init(C)}
\endif
         [] fLocal(FS1 FS2 C) then NewFS1 FVs GS in
            {@BA openScope()}
            NewFS1 = {MakeTrivialLocalPrefix FS1 ?FVs nil}
            {ForAll FVs
             proc {$ FV}
                case FV of fVar(PrintName C) then
                   {@BA bind(PrintName C _)}
                [] fDoImport(fImportItem(fVar(PrintName C) Fs _) GV _) then
                   NewFs
                in
                   {@BA bindImport(PrintName C NewFs ?GV)}
                   Unnester, UnnestImportFeatures(Fs ?NewFs)
                end
             end}
            GS = (Unnester, UnnestStatement(NewFS1 $)|
                  Unnester, UnnestStatement(FS2 $))
            {MakeDeclaration {@BA closeScope($)} GS C}
         [] fBoolCase(FE FS1 FS2 C) then Lbl = {Label FE} in
            if {Not {@state getSwitch(staticvarnames $)}}
               andthen {Not {@state getSwitch(controlflowinfo $)}}
               andthen ({@state getSwitch(staticanalysis $)}
                        orelse {Not {@state getSwitch(codegen $)}})
               %% Note:
               %% a) debugging information breaks dead code elimination when
               %%    sharing code segments with andthen/orelse optimization;
               %% b) when not doing value propagation, applications of
               %%    ClauseBodies are not recognized
               andthen (Lbl == fOrElse orelse Lbl == fAndThen)
            then
               GBody GS1 GSTrueProc ApplyTrueProc GSFalseProc ApplyFalseProc
               GClauseBodies
            in
               {@BA openScope()}
               Unnester, UnnestStatement(FS1 ?GBody)
               GS1 = {MakeDeclaration {@BA closeScope($)} GBody C}
               Unnester, MakeClauseBody('TrueCase' GS1 {CoordinatesOf FS1}
                                        ?GSTrueProc ?ApplyTrueProc)
               case FS2 of fNoElse(C) then
                  GSFalseProc = {New Core.skipNode init(C)}
                  fun {ApplyFalseProc} GSFalseProc end
               [] fNoElseInternal(C) then
                  GSFalseProc = {New Core.skipNode init(C)}
                  fun {ApplyFalseProc} noElse(C) end
               else GBody GS2 in
                  {@BA openScope()}
                  Unnester, UnnestStatement(FS2 ?GBody)
                  GS2 = {MakeDeclaration {@BA closeScope($)} GBody C}
                  Unnester, MakeClauseBody('FalseCase' GS2 {CoordinatesOf FS2}
                                           ?GSFalseProc ?ApplyFalseProc)
               end
               GSTrueProc|GSFalseProc|GClauseBodies|
               Unnester, UnnestIfArbiter(FE ApplyTrueProc ApplyFalseProc
                                         ?GClauseBodies $)
            else GFrontEq GVO GBody GT GF in
               Unnester, UnnestToVar(FE 'IfArbiter' ?GFrontEq ?GVO)
               {@BA openScope()}
               Unnester, UnnestStatement(FS1 ?GBody)
               GT = {MakeDeclaration {@BA closeScope($)} GBody C}
               case FS2 of fNoElse(C) then
                  GF = {New Core.skipNode init(C)}
               [] fNoElseInternal(C) then
                  GF = noElse(C)
               else GBody in
                  {@BA openScope()}
                  Unnester, UnnestStatement(FS2 ?GBody)
                  GF = {MakeDeclaration {@BA closeScope($)} GBody C}
               end
               GFrontEq|{MakeIfNode GVO GT GF C @BA}
            end
         [] fCase(FE FClauses FElse C) then GFrontEq GVO GCs GElse in
            Unnester, UnnestToVar(FE 'Arbiter' ?GFrontEq ?GVO)
            Unnester, UnnestCaseClauses(FClauses ?GCs)
            GElse = case FElse of fNoElse(C) then
                       {New Core.noElse init(C)}
                    else GBody0 GBody in
                       {@BA openScope()}
                       Unnester, UnnestStatement(FElse ?GBody0)
                       GBody = {MakeDeclaration {@BA closeScope($)} GBody0 C}
                       {New Core.elseNode init(GBody)}
                    end
            GFrontEq|{New Core.patternCase init(GVO GCs GElse C)}
         [] fLockThen(FE FS C) then GFrontEq GVO GS in
            Unnester, UnnestToVar(FE 'Lock' ?GFrontEq ?GVO)
            Unnester, UnnestStatement(FS ?GS)
            GFrontEq|{New Core.lockNode init(GVO GS C)}
         [] fLock(FS C) then GS in
            if @Stateful then
               StateUsed <- true
            else
               {@reporter error(coord: C kind: ExpansionError
                                msg: 'object lock used outside of method')}
            end
            Unnester, UnnestStatement(FS ?GS)
            {New Core.objectLockNode init(GS C)}
         [] fThread(FS C) then CND NewFS in
            CND = {CoordNoDebug C}
            NewFS = fStepPoint(fOpApplyStatement('Thread.create'
                                                 [fProc(fDollar(CND) nil FS
                                                        [fAtom('dynamic' unit)]
                                                        CND)]
                                                 CND) 'thread' C)
            Unnester, UnnestStatement(NewFS $)
         [] fTry(_ _ _ _) then
            Unnester, UnnestTry(FS $)
         [] fRaise(FE C) then
            Unnester, UnnestStatement(fOpApplyStatement('Exception.\'raise\''
                                                        [FE] C) $)
         [] fSkip(C) then
            {New Core.skipNode init(C)}
         [] fFail(C) then CND NewFS in
            CND = {CoordNoDebug C}
            NewFS = fStepPoint(fOpApplyStatement('Exception.\'fail\'' nil CND)
                               'fail' C)
            Unnester, UnnestStatement(NewFS $)
         [] fNot(FS C) then CND CombinatorFS NewFS in
            CND = {CoordNoDebug C}
            case Unnester, AddImport('x-oz://system/Combinator.ozf' $)
            of unit then
               CombinatorFS = fOpApplyStatement('Combinator.\'not\''
                                                [fProc(fDollar(C) nil FS
                                                       nil CND)] CND)
            elseof FE then
               CombinatorFS = fApply(fOpApply('.' [FE fAtom('not' CND)] CND)
                                     [fProc(fDollar(C) nil FS nil CND)] CND)
            end
            NewFS = fStepPoint(CombinatorFS 'combinator' C)
            Unnester, UnnestStatement(NewFS $)
         [] fException(C) then
            {New Core.exceptionNode init(C)}
         [] fCond(FClauses FElse C) then
            FClauseProcs FElseProc CND CombinatorFS NewFS
         in
            Unnester, UnnestClauses(FClauses ?FClauseProcs)
            FElseProc = fProc(fDollar(C) nil
                              case FElse of fNoElse(C) then
                                 fException(C)
                              else FElse
                              end nil CND)
            CND = {CoordNoDebug C}
            case Unnester, AddImport('x-oz://system/Combinator.ozf' $)
            of unit then
               CombinatorFS = fOpApplyStatement('Combinator.\'cond\''
                                                [fRecord(fAtom('#' C)
                                                         FClauseProcs)
                                                 FElseProc] CND)
            elseof FE then
               CombinatorFS = fApply(fOpApply('.' [FE fAtom('cond' CND)] CND)
                                     [fRecord(fAtom('#' C) FClauseProcs)
                                      FElseProc] CND)
            end
            NewFS = fStepPoint(CombinatorFS 'combinator' C)
            Unnester, UnnestStatement(NewFS $)
         [] fOr(FClauses C) then FClauseProcs CND CombinatorFS NewFS in
            Unnester, UnnestClauses(FClauses ?FClauseProcs)
            CND = {CoordNoDebug C}
            case Unnester, AddImport('x-oz://system/Combinator.ozf' $)
            of unit then
               CombinatorFS = fOpApplyStatement('Combinator.\'or\''
                                                [fRecord(fAtom('#' C)
                                                         FClauseProcs)] CND)
            elseof FE then
               CombinatorFS = fApply(fOpApply('.' [FE fAtom('or' CND)] CND)
                                     [fRecord(fAtom('#' C) FClauseProcs)] CND)
            end
            NewFS = fStepPoint(CombinatorFS 'combinator' C)
            Unnester, UnnestStatement(NewFS $)
         [] fDis(FClauses C) then FClauseProcs CND CombinatorFS NewFS in
            Unnester, UnnestClauses(FClauses ?FClauseProcs)
            CND = {CoordNoDebug C}
            case Unnester, AddImport('x-oz://system/Combinator.ozf' $)
            of unit then
               CombinatorFS = fOpApplyStatement('Combinator.\'dis\''
                                                [fRecord(fAtom('#' C)
                                                         FClauseProcs)] CND)
            elseof FE then
               CombinatorFS = fApply(fOpApply('.' [FE fAtom('dis' CND)] CND)
                                     [fRecord(fAtom('#' C) FClauseProcs)] CND)
            end
            NewFS = fStepPoint(CombinatorFS 'combinator' C)
            Unnester, UnnestStatement(NewFS $)
         [] fChoice(FSs C) then CND N CombinatorFE NewFS in
            %% choice S1 [] ... [] Sn end
            %% =>
            %% case {Space.choose n} of 1 then S1
            %% [] ...
            %% [] n then Sn
            %% end
            CND = {CoordNoDebug C}
            N = {Length FSs}
            case Unnester, AddImport('x-oz://system/Space.ozf' $) of unit then
               CombinatorFE = fOpApply('Space.choose' [fInt(N C)] CND)
            elseof FE then
               CombinatorFE = fApply(fOpApply('.' [FE fAtom('choose' CND)] CND)
                                     [fInt(N C)] CND)
            end
            NewFS = fStepPoint(fCase(CombinatorFE
                                     {List.mapInd FSs
                                      fun {$ I FS}
                                         fCaseClause(fInt(I C) FS)
                                      end}
                                     fNoElse(C) CND)
                               'combinator' C)
            Unnester, UnnestStatement(NewFS $)
         [] fLoop(_ _) then
            Unnester, UnnestStatement({MacroExpand FS unit} $)
         [] fMacro(_ _) then
            Unnester, UnnestStatement({MacroExpand FS unit} $)
         [] fMacrolet(_ _) then
            Unnester, UnnestStatement({MacroExpand FS unit} $)
         [] fFOR(_ _ _) then
            Unnester, UnnestStatement({ForLoop.compile FS} $)
         [] fDotAssign(Left Right C) then %% DotAssign is _._ := _
            case Left
            of fOpApply('.' [Table Key] _) then
               Unnester,UnnestStatement(fOpApplyStatement('dotAssign'
                                                          [Table Key Right] C)
                                        $)
            else GV in
               % Shouldn't happen since parser has checked the lhs already
               {@reporter error(coord: C kind: SyntaxError
                                msg: 'expected dot expression to the left of :=')}
               {@BA generate('Error' C ?GV)}
               Unnester, UnnestExpression(Left GV _)
               Unnester, UnnestExpression(Right GV _)
               {New Core.skipNode init(C)}
            end
         [] fColonEquals(Left Right C) then   %% ColonEquals is a _ := _
               % Left could be cell,  could be attribute, could be a
               % table entry (D#I pair).
            if @Stateful then
               % We pessimistically assume its an attribute and set the StateUsed flag.
               % An optimisation would be to delay setting the flag until after
               % Static Analysis,  when we may know better if lhs is an attribute.
               StateUsed <- true
            end
            % Here,  we set the operation to 'catAssign' a builtin
            % which checks the type of lhs and calls Value.Assign,
            % Object.'<-', or Dictionary.put appropriately.
            % After the static analysis we will usually know the type of lhs.
            % We then optimise this call statically during byte code generation.
            % (not yet implemented)
            %
            Unnester, UnnestStatement(fOpApplyStatement('catAssign'
                                                        [Left Right] C) $)
         else C = {CoordinatesOf FS} GV in
            {@reporter error(coord: C kind: SyntaxError
                             msg: 'expression at statement position')}
            {@BA generate('Error' C ?GV)}
            Unnester, UnnestExpression(FS GV $)
         end
      end

      meth UnnestExpression(FE ToGV $)
         case FE of fTypeOf(GV) then GVO in
            {ToGV occ({ToGV getCoord($)} ?GVO)}
            {New Core.typeOf init(GV GVO)}
         [] fStepPoint(FE Kind C) then GS in
            Unnester, UnnestExpression(FE ToGV ?GS)
            if {@state getSwitch(controlflowinfo $)} andthen {IsStep C}
            then {New Core.stepPoint init(GS Kind C)}
            else GS
            end
         [] fAnd(FS1 FE2) then
            Unnester, UnnestStatement(FS1 $)|
            Unnester, UnnestExpression(FE2 ToGV $)
         [] fEq(_ _ _) then GFront GBack in
            Unnester, UnnestConstraint(FE ToGV ?GFront ?GBack)
            GFront|GBack
         [] fAssign(FE1 FE2 C) then FApply in
            if @Stateful then
               StateUsed <- true
            else
               {@reporter
                error(coord: C kind: ExpansionError
                      msg: 'attribute exchange used outside of method')}
            end
            FApply = fOpApplyStatement('Object.exchange'
                                       [FE1 FE2 fOcc(ToGV)] C)
            Unnester, UnnestStatement(FApply $)
         [] fOrElse(FE1 FE2 C) then FV FS in
            FV = fOcc(ToGV)
            FS = fBoolCase(FE1 fEq(FV fAtom(true C) C) fEq(FV FE2 C) C)
            Unnester, UnnestStatement(FS $)
         [] fAndThen(FE1 FE2 C) then FV FS in
            FV = fOcc(ToGV)
            FS = fBoolCase(FE1 fEq(FV FE2 C) fEq(FV fAtom(false C) C) C)
            Unnester, UnnestStatement(FS $)
         [] fOpApply(Op FEs C) then
            if {DollarsInScope FEs 0} \= 0 then OpKind in
               OpKind = case FEs of [_] then 'prefix' else 'infix' end
               {@reporter
                error(coord: {DollarCoord FEs} kind: SyntaxError
                      msg: OpKind#' operator cannot take $ as argument')}
            end
            case FE of fOpApply('.' [fVar(X C2) fAtom(Y _)] C3)
               andthen LeftGVO in {@BA referImport(X C2 Y $ ?LeftGVO)}
            then RightGVO in
               {ToGV occ(C3 ?RightGVO)}
               {New Core.equation init(LeftGVO RightGVO C)}
            elseof fOpApply('.' [fVar(X C2) fInt(Y _)] C3)
               andthen LeftGVO in {@BA referImport(X C2 Y $ ?LeftGVO)}
            then RightGVO in
               {ToGV occ(C3 ?RightGVO)}
               {New Core.equation init(LeftGVO RightGVO C)}
            elseof fOpApply('^' [FE1 FE2] C) then NewFS in
               NewFS = case Unnester, AddImport('x-oz://system/RecordC.ozf' $)
                       of unit then
                          fOpApplyStatement('RecordC.\'^\''
                                            [FE1 FE2 fOcc(ToGV)] C)
                       elseof FE then CND in
                          CND = {CoordNoDebug C}
                          fApply(fOpApply('.' [FE fAtom('^' CND)] CND)
                                 [FE1 FE2 fOcc(ToGV)] C)
                       end
               Unnester, UnnestStatement(NewFS $)
            else GVO GFrontEqs1 GFrontEqs2 GTs GS in
               if {IsAtom Op} then
                  {RunTime.procs.Op occ(C ?GVO)}
               else
                  {{RunTime.makeVar {System.printName Op} Op} occ(C ?GVO)}
               end
               Unnester, UnnestApplyArgs({Append FEs [fOcc(ToGV)]}
                                         ?GFrontEqs1 ?GFrontEqs2 ?GTs)
               GS = {New Core.application init(GVO GTs C)}
               GFrontEqs1|GFrontEqs2|GS
            end
         [] fByNeedDot(fVar(X C) FT) then
            LeftGVO DotGVO GFrontEqs1 GFrontEqs2 GTs
         in
            {@BA referUnchecked(X C ?LeftGVO)}
            {RunTime.procs.'Value.byNeedDot' occ(C ?DotGVO)}
            Unnester, UnnestApplyArgs([FT fOcc(ToGV)]
                                      ?GFrontEqs1 ?GFrontEqs2 ?GTs)
            GFrontEqs1|GFrontEqs2|
            {New Core.application init(DotGVO LeftGVO|GTs C)}
         [] fFdCompare(Op FE1 FE2 C) then
            GFrontEq1 NewFE1 GFrontEq2 NewFE2 FS FD
         in
            Unnester, UnnestFDExpression(FE1 ?GFrontEq1 ?NewFE1)
            Unnester, UnnestFDExpression(FE2 ?GFrontEq2 ?NewFE2)
            Unnester, AddImport('x-oz://system/FD.ozf' ?FD)
            FS = {MakeFdCompareExpression Op NewFE1 NewFE2 C fOcc(ToGV) FD}
            GFrontEq1|GFrontEq2|Unnester, UnnestStatement(FS $)
         [] fFdIn(Op FE1 FE2 C) then FS in
            %% note: reverse arguments!
            case Unnester, AddImport('x-oz://system/FD.ozf' $)
            of unit then
               FS = fOpApplyStatement(case Op of '::' then 'FD.reified.int'
                                      [] ':::' then 'FD.reified.dom'
                                      end [FE2 FE1 fOcc(ToGV)] C)
            elseof FE then Feature CND in
               Feature = case Op of '::' then 'int'
                         [] ':::' then 'dom'
                         end
               CND = {CoordNoDebug C}
               FS = fApply(fOpApply('.' [fOpApply('.' [FE fAtom('reified' C)]
                                                  C)
                                         fAtom(Feature C)] CND)
                           [FE2 FE1 fOcc(ToGV)] C)
            end
            Unnester, UnnestStatement(FS $)
         [] fObjApply(FE1 FE2 C) then NewFE2 in
            if @Stateful then
               StateUsed <- true
               if {DollarsInScope FE2 0} == 1 then
                  case FE1 of fSelf(C) then
                     {@reporter
                      error(coord: C kind: ExpansionError
                            msg: '"self, message" not allowed'
                            items: [hint(l: 'Hint'
                                         m: ('use a class in front of "," '#
                                             'or use {self message}'))])}
                  else skip
                  end
               else
                  {@reporter
                   error(coord: C kind: ExpansionError
                         msg: ('message of nested object application '#
                               'must contain exactly one nesting marker'))}
               end
            else
               {@reporter
                error(coord: C kind: ExpansionError
                      msg: 'object application used outside of method')}
            end
            NewFE2 = {ReplaceDollar FE2 fOcc(ToGV)}
            Unnester, UnnestStatement(fOpApplyStatement('Object.\',\''
                                                        [FE1 NewFE2] C) $)
         [] fAt(FE C) then FS in
            % FE may be either a cell, attribute, or table entry
            if @Stateful then
               % We always set StateUsed see comment on UnnestStatement(fDotAssign(...))
               StateUsed <- true
            end
            FS = fOpApplyStatement('catAccess' [FE fOcc(ToGV)] C)
            Unnester, UnnestStatement(FS $)
         [] fAtom(_ _) then GFront GBack in
            Unnester, UnnestConstraint(FE ToGV ?GFront ?GBack)
            GFront|GBack
         [] fVar(PrintName C) then GVO1 GVO2 in
            {ToGV occ(C ?GVO1)}
            {@BA refer(PrintName C ?GVO2)}
            {New Core.equation init(GVO1 GVO2 C)}
         [] fOcc(GV) then C GVO1 GVO2 in
            {ToGV getCoord(?C)}
            {ToGV occ(C ?GVO1)}
            {GV occ(C ?GVO2)}
            {New Core.equation init(GVO1 GVO2 C)}
         [] fWildcard(C) then
            {New Core.skipNode init(C)}
         [] fEscape(FV2 _) then
            Unnester, UnnestExpression(FV2 ToGV $)
         [] fSelf(C) then GVO in
            if @Stateful then
               StateUsed <- true
            else
               {@reporter error(coord: C kind: ExpansionError
                                msg: 'self used outside of method')}
            end
            {ToGV occ(C ?GVO)}
            {New Core.getSelf init(?GVO C)}
         [] fDollar(C) then
            {@reporter error(coord: C kind: ExpansionError
                             msg: 'illegal use of nesting marker')}
            {New Core.skipNode init(C)}
         [] fInt(_ _) then GFront GBack in
            Unnester, UnnestConstraint(FE ToGV ?GFront ?GBack)
            GFront|GBack
         [] fFloat(_ _) then GFront GBack in
            Unnester, UnnestConstraint(FE ToGV ?GFront ?GBack)
            GFront|GBack
         [] fRecord(_ _) then GRecord GBack in
            Unnester, UnnestConstraint(FE ToGV ?GRecord ?GBack)
            GRecord|GBack
         [] fOpenRecord(_ _) then GRecord GBack in
            Unnester, UnnestConstraint(FE ToGV ?GRecord ?GBack)
            GRecord|GBack
         [] fApply(FE1 FEs C) then N1 N2 FV in
            case FE1 of fSelf(_) then
               case FEs of [_] then skip else
                  {@reporter error(coord:C kind: ExpansionError
                                   msg:'illegal application of self')}
               end
            else skip end
            N1 = {DollarsInScope FE1 0}
            N2 = {DollarsInScope FEs 0}
            FV = fOcc(ToGV)
            case N1#N2 of 0#0 then NewFEs in
               NewFEs = {Append FEs [FV]}
               Unnester, UnnestStatement(fApply(FE1 NewFEs C) $)
            [] 0#1 then NewFEs in
               NewFEs = {ReplaceDollar FEs FV}
               Unnester, UnnestStatement(fApply(FE1 NewFEs C) $)
            [] 1#_ then
               Unnester, UnnestStatement(FE $)   % reports an error
            else
               {@reporter
                error(coord: {DollarCoord FE1|FEs} kind: ExpansionError
                      msg: ('at most one nesting marker allowed '#
                            'in nested application'))}
               Unnester, UnnestStatement(FE $)
            end
         [] fProc(FE1 FEs FS ProcFlags C) then
            case FE1 of fDollar(_) then NewFS in
               NewFS = fProc(fOcc(ToGV) FEs FS ProcFlags C)
               Unnester, UnnestStatement(NewFS $)
            else
               {@reporter error(coord: {CoordinatesOf FE1} kind: SyntaxError
                                msg: ('nesting marker expected as designator '#
                                      'of nested procedure'))}
               Unnester, UnnestStatement(FE $)
            end
         [] fFun(FE1 FEs FE2 ProcFlags C) then
            case FE1 of fDollar(_) then NewFS in
               NewFS = fFun(fOcc(ToGV) FEs FE2 ProcFlags C)
               Unnester, UnnestStatement(NewFS $)
            else
               {@reporter error(coord: {CoordinatesOf FE1} kind: SyntaxError
                                msg: ('nesting marker expected as designator '#
                                      'of nested function'))}
               Unnester, UnnestStatement(FE $)
            end
         [] fFunctor(FE FDescriptors C) then
            case FE of fDollar(_) then NewFS in
               NewFS = fFunctor(fOcc(ToGV) FDescriptors C)
               Unnester, UnnestStatement(NewFS $)
            else
               {@reporter
                error(coord: {CoordinatesOf FE} kind: SyntaxError
                      msg: 'nesting marker expected in nested functor')}
               Unnester, UnnestStatement(FE $)
            end
         [] fClass(FE1 FDescriptors FMeths C) then
            case FE1 of fDollar(_) then NewFS in
               NewFS = fClass(fOcc(ToGV) FDescriptors FMeths C)
               Unnester, UnnestStatement(NewFS $)
            else
               {@reporter
                error(coord: {CoordinatesOf FE1} kind: SyntaxError
                      msg: 'nesting marker expected in nested class')}
               Unnester, UnnestStatement(FE $)
            end
         [] fScanner(FE1 _ _ _ _ _) then
            {@reporter
             error(coord: {CoordinatesOf FE1} kind: SyntaxError
                   msg: ('scanner definition not allowed '#
                         'at expression position'))}
            Unnester, UnnestStatement(FE1 $)
         [] fParser(FE1 _ _ _ _ _ _) then
            {@reporter
             error(coord: {CoordinatesOf FE1} kind: SyntaxError
                   msg: ('parser definition not allowed '#
                         'at expression position'))}
            Unnester, UnnestStatement(FE1 $)
         [] fLocal(FS FE C) then PrintName NewFS FVs in
            {ToGV getPrintName(?PrintName)}
            {@BA openScope()}
            NewFS = {MakeTrivialLocalPrefix FS FVs nil}
            if   % is a new temporary needed to avoid name clashes?
               {FoldL FVs
                fun {$ In FV}
                   case FV of fVar(X C) then
                      {@BA bind(X C _)}
                      {Or In X == PrintName}
                   [] fDoImport(fImportItem(fVar(X C) Fs _) GV _) then NewFs in
                      {@BA bindImport(X C NewFs ?GV)}
                      Unnester, UnnestImportFeatures(Fs ?NewFs)
                      {Or In X == PrintName}
                   end
                end false}
            then GVO NewGV GS in
               {ToGV occ(C ?GVO)}
               {@BA generateForOuterScope('AntiNameClash' C ?NewGV)}
               GS = (Unnester, UnnestStatement(NewFS $)|
                     Unnester, UnnestExpression(FE NewGV $))
               {New Core.equation init(GVO {NewGV occ(C $)} C)}|
               {MakeDeclaration {@BA closeScope($)} GS C}
            else GS in
               GS = (Unnester, UnnestStatement(NewFS $)|
                     Unnester, UnnestExpression(FE ToGV $))
               {MakeDeclaration {@BA closeScope($)} GS C}
            end
         [] fBoolCase(FE1 FE2 FE3 C) then FV FS in
            FV = fOcc(ToGV)
            FS = fBoolCase(FE1 fEq(FV FE2 C)
                           case FE3 of fNoElse(C) then fNoElseInternal(C)
                           else fEq(FV FE3 C)
                           end C)
            Unnester, UnnestStatement(FS $)
         [] fCase(FE1 FClauses FE2 C) then FS NewFV FVs PrintName in
            FS = fCase(FE1 {Map FClauses
                            fun {$ fCaseClause(FE1 FE2)}
                               fCaseClause(FE1 fEq(NewFV FE2 C))
                            end}
                       case FE2 of fNoElse(_) then FE2
                       else fEq(NewFV FE2 C)
                       end C)
            {FoldL FClauses
             fun {$ FVs fCaseClause(FE _)}
                {GetPatternVariablesExpression FE FVs $}
             end FVs nil}
            {ToGV getPrintName(?PrintName)}
            if {Some FVs fun {$ fVar(X _)} X == PrintName end} then NewGV in
               %% use a temporary to avoid name clash
               Unnester, GenerateNewVar(PrintName FVs C ?NewGV)
               NewFV = fOcc(NewGV)
               Unnester, UnnestStatement(fAnd(fEq(NewFV fOcc(ToGV) C) FS) $)
            else
               NewFV = fOcc(ToGV)
               Unnester, UnnestStatement(FS $)
            end
         [] fLockThen(FE1 FE2 C) then
            Unnester, UnnestStatement(fLockThen(FE1 fEq(fOcc(ToGV) FE2 C) C) $)
         [] fLock(FE C) then
            if @Stateful then
               StateUsed <- true
            else
               {@reporter error(coord: C kind: ExpansionError
                                msg: 'object lock used outside of method')}
            end
            Unnester, UnnestStatement(fLock(fEq(fOcc(ToGV) FE C) C) $)
         [] fThread(FE C) then
            Unnester, UnnestStatement(fThread(fEq(fOcc(ToGV) FE C) C) $)
         [] fTry(FE FCatch FFinally C) then FV GV2 FV2 TryFS in
            FV = fOcc(ToGV)
            {@BA generate('TryResult' C ?GV2)}
            FV2 = fOcc(GV2)
            TryFS = fAnd(fEq(FV2 FE C) fEq(FV FV2 C))
            case FCatch of fNoCatch then
               Unnester, UnnestStatement(fTry(TryFS fNoCatch FFinally C) $)
            [] fCatch(FCaseClauses C2) then FVs PrintName NewFV FS NewFCatch in
               FS = fTry(TryFS fCatch(NewFCatch C2) FFinally C)
               NewFCatch = {Map FCaseClauses
                            fun {$ fCaseClause(FE1 FE2)}
                               fCaseClause(FE1 fEq(NewFV FE2 C))
                            end}
               {FoldL FCaseClauses
                fun {$ FVs fCaseClause(FE _)}
                   {GetPatternVariablesExpression FE FVs $}
                end FVs nil}
               {ToGV getPrintName(?PrintName)}
               if {Some FVs fun {$ fVar(X _)} X == PrintName end} then GV in
                  Unnester, GenerateNewVar(PrintName FVs C ?GV)
                  NewFV = fOcc(GV)
                  Unnester, UnnestStatement(fAnd(fEq(FV NewFV C) FS) $)
               else
                  NewFV = FV
                  Unnester, UnnestStatement(FS $)
               end
            end
         [] fRaise(_ _) then
            Unnester, UnnestStatement(FE $)
         [] fFail(_) then
            Unnester, UnnestStatement(FE $)
         [] fCond(FClauses FE C) then PrintName FVs NewFV FS in
            FS = fCond({Map FClauses
                        fun {$ fClause(FVs FS FE)}
                           fClause(FVs FS fEq(NewFV FE C))
                        end}
                       case FE of fNoElse(_) then FE
                       else fEq(NewFV FE C)
                       end C)
            {FoldL FClauses
             fun {$ FVs fClause(FE _ _)}
                {GetPatternVariablesExpression FE FVs $}
             end FVs nil}
            {ToGV getPrintName(?PrintName)}
            if {Some FVs fun {$ fVar(X _)} X == PrintName end} then NewGV in
               %% use a temporary to avoid name clash
               Unnester, GenerateNewVar(PrintName FVs C ?NewGV)
               NewFV = fOcc(NewGV)
               Unnester, UnnestStatement(fAnd(fEq(NewFV fOcc(ToGV) C) FS) $)
            else
               NewFV = fOcc(ToGV)
               Unnester, UnnestStatement(FS $)
            end
         [] fOr(FClauses C) then
            Unnester, TransformExpressionOr(fOr FClauses C ToGV $)
         [] fDis(FClauses C) then
            Unnester, TransformExpressionOr(fDis FClauses C ToGV $)
         [] fChoice(FEs C) then NewFV FS in
            NewFV = fOcc(ToGV)
            FS = fChoice({Map FEs fun {$ FE} fEq(NewFV FE C) end} C)
            Unnester, UnnestStatement(FS $)
         [] fLoop(_ _) then
            Unnester, UnnestExpression({MacroExpand FE unit} ToGV $)
         [] fMacro(_ _) then
            Unnester, UnnestExpression({MacroExpand FE unit} ToGV $)
         [] fMacrolet(_ _) then
            Unnester, UnnestExpression({MacroExpand FE unit} ToGV $)
         [] fFOR(_ _ _) then
            Unnester, UnnestExpression({ForLoop.compile FE} ToGV $)
         [] fDotAssign(Left Right C) then FApply in
            case Left
            of fOpApply('.' [Table Key] _) then
               FApply = fOpApplyStatement('dotExchange'
                                          [Table Key Right fOcc(ToGV)] C)
               Unnester, UnnestStatement(FApply $)
            else GV in
               % Shouldn't happen since parser has checked the lhs already
               {@reporter error(coord: C kind: SyntaxError
                                msg: 'expected dot expression to the left of :=')}
               {@BA generate('Error' C ?GV)}
               Unnester, UnnestExpression(Left GV _)
               Unnester, UnnestExpression(Right GV _)
               {New Core.skipNode init(C)}
            end
         [] fColonEquals(Left Right C) then FApply in
            % Left is cell, attribute, or table entry
            if @Stateful then
               % See comments on UnnestStatement(fDotAssign(...))
               StateUsed <- true
            end
            FApply = fOpApplyStatement('catExchange' [Left Right fOcc(ToGV)] C)
            Unnester, UnnestStatement(FApply $)
         else C = {CoordinatesOf FE} in
            {@reporter error(coord: C kind: SyntaxError
                             msg: 'statement at expression position')}
            Unnester, UnnestStatement(FE $)
         end
      end

      meth UnnestApplyArgs(FEs ?GFrontEqs1 ?GFrontEqs2 ?GTs)
         case FEs of FE|FEr then
            case FE of fRecord(Label Args) then
               %% Records as arguments are treated in a special way here
               %% so as to make the sendMsg optimization apply in more
               %% cases, e.g.:
               C GV GFront GRecord GBack GEquation GFrontEqr1 GFrontEqr2 GTr
            in
               C = {CoordinatesOf Label}
               {@BA generate('UnnestApply' C ?GV)}
               Unnester, UnnestRecord(unit Label Args false
                                      ?GFront ?GRecord ?GBack)
               GFrontEqs1 = GFront|GBack|GFrontEqr1
               GEquation = {New Core.equation init({GV occ(C $)} GRecord C)}
               GFrontEqs2 = GEquation|GFrontEqr2
               GTs = {GV occ(C $)}|GTr
               Unnester, UnnestApplyArgs(FEr ?GFrontEqr1 ?GFrontEqr2 ?GTr)
            else GFrontEq GFrontEqr GT GTr in
               GFrontEqs1 = GFrontEq|GFrontEqr
               GTs = GT|GTr
               Unnester, UnnestToVar(FE 'UnnestApply' ?GFrontEq ?GT)
               Unnester, UnnestApplyArgs(FEr ?GFrontEqr ?GFrontEqs2 ?GTr)
            end
         [] nil then
            GFrontEqs1 = nil
            GFrontEqs2 = nil
            GTs = nil
         end
      end
      meth UnnestConstraint(FE ToGV ?GFront ?GBack)
         case FE of fEq(FE1 FE2 _) then GFront1 GBack1 GFront2 GBack2 in
            GFront = GFront1|GFront2
            GBack = GBack1|GBack2
            Unnester, UnnestConstraint(FE1 ToGV ?GFront1 ?GBack1)
            Unnester, UnnestConstraint(FE2 ToGV ?GFront2 ?GBack2)
         [] fRecord(Label Args) then C GVO PrintName GFront1 GFront2 GRecord in
            GFront = GFront1|GFront2
            C = {CoordinatesOf Label}
            {ToGV occ(C ?GVO)}
            {ToGV getPrintName(?PrintName)}
            Unnester, UnnestRecord(PrintName Label Args false
                                   ?GFront1 ?GRecord ?GBack)
            Unnester, MakeEquation(GVO GRecord C ?GFront2)
         [] fOpenRecord(Label Args) then
            C GVO PrintName GFront1 GFront2 GRecord
         in
            GFront = GFront1|GFront2
            C = {CoordinatesOf Label}
            {ToGV occ(C ?GVO)}
            {ToGV getPrintName(?PrintName)}
            Unnester, UnnestRecord(PrintName Label Args true
                                   ?GFront1 ?GRecord ?GBack)
            Unnester, MakeEquation(GVO GRecord C ?GFront2)
         [] fOcc(GV) then C GVO1 GVO2 in
            GBack = nil
            {ToGV getCoord(?C)}
            {ToGV occ(C ?GVO1)}
            {GV occ(C ?GVO2)}
            GFront = {New Core.equation init(GVO1 GVO2 C)}
         [] fVar(PrintName C) then GVO1 GVO2 in
            GBack = nil
            {ToGV occ(C ?GVO1)}
            {@BA refer(PrintName C ?GVO2)}
            Unnester, MakeEquation(GVO1 GVO2 C ?GFront)
         [] fWildcard(_) then
            GFront = nil
            GBack = nil
         [] fEscape(NewFE _) then
            Unnester, UnnestConstraint(NewFE ToGV ?GFront ?GBack)
         [] fAtom(X C) then GVO GRight in
            GBack = nil
            {ToGV occ(C ?GVO)}
            GRight = {New Core.valueNode init(X C)}
            Unnester, MakeEquation(GVO GRight C ?GFront)
         [] fInt(X C) then GVO GRight in
            GBack = nil
            {ToGV occ(C ?GVO)}
            GRight = {New Core.valueNode init(X C)}
            Unnester, MakeEquation(GVO GRight C ?GFront)
         [] fFloat(X C) then GVO GRight in
            GBack = nil
            {ToGV occ(C ?GVO)}
            GRight = {New Core.valueNode init(X C)}
            Unnester, MakeEquation(GVO GRight C ?GFront)
         else
            GFront = nil
            Unnester, UnnestExpression(FE ToGV ?GBack)
         end
      end
      meth MakeEquation(GVO GRight C $)
         if {IsStep C} then AppGVO in
            {RunTime.procs.'=' occ(C ?AppGVO)}
            if {HasFeature GRight Core.imAVariableOccurrence} then RightGVO in
               RightGVO = GRight
               {New Core.application init(AppGVO [GVO RightGVO] C)}
            else RightGV RightGVO in
               {@BA generate('Right' C ?RightGV)}
               {RightGV occ(C ?RightGVO)}
               {New Core.equation init({RightGV occ(C $)} GRight C)}|
               {New Core.application init(AppGVO [GVO RightGVO] C)}
            end
         else
            {New Core.equation init(GVO GRight C)}
         end
      end
      meth UnnestRecord(PrintName Label Args IsOpen ?GFront ?GRecord ?GBack)
         GLabel N GFront1 GFront2 GArgs NewGArgs X
      in
         Unnester, MakeLabelOrFeature(Label ?GLabel)
         N = {NewCell 1}
         GFront = GFront1|GFront2
         GFront1#GArgs#GBack =
         {List.foldL Args
          fun {$ GFront#GArgs#GBack Arg} FE NewGArgs GArg FeatPrintName in
             case Arg of fColon(FF FE0) then GF in
                Unnester, MakeLabelOrFeature(FF ?GF)
                FE = FE0
                NewGArgs = GF#GArg|GArgs
                FeatPrintName = case FF of fAtom(X _) then {System.printName X}
                                [] fVar(PrintName _) then PrintName
                                [] fInt(X _) then X
                                end
             else
                FE = Arg
                NewGArgs = GArg|GArgs
                FeatPrintName = {Access N}
                {Assign N {Access N} + 1}
             end
             if IsOpen then GBack0 in
                Unnester, UnnestToVar(FE 'RecordArg' ?GBack0 ?GArg)
                {SetPrintName GBack0 PrintName FeatPrintName}
                GFront#NewGArgs#(GBack|GBack0)
             elsecase FE of fEq(_ _ C) then GV GFront0 GBack0 in
                {@BA generate('Equation' C ?GV)}
                {GV occ(C ?GArg)}
                Unnester, UnnestConstraint(FE GV ?GFront0 ?GBack0)
                GFront#NewGArgs#(GFront0|GBack|GBack0)
             [] fRecord(Label Args) then NewPrintName GFront0 GBack0 in
                NewPrintName = {DotPrintName PrintName FeatPrintName}
                Unnester, UnnestRecord(NewPrintName Label Args false
                                       ?GFront0 ?GArg ?GBack0)
                (GFront|GFront0)#NewGArgs#(GBack|GBack0)
             [] fOpenRecord(Label Args) then NewPrintName GFront0 GBack0 in
                NewPrintName = {DotPrintName PrintName FeatPrintName}
                Unnester, UnnestRecord(NewPrintName Label Args true
                                       ?GFront0 ?GArg ?GBack0)
                (GFront|GFront0)#NewGArgs#(GBack|GBack0)
             else GBack0 in
                Unnester, UnnestToTerm(FE 'RecordArg' ?GBack0 ?GArg)
                {SetPrintName GBack0 PrintName FeatPrintName}
                GFront#NewGArgs#(GBack|GBack0)
             end
          end nil#nil#nil}
         {SortNoColonsToFront {Reverse GArgs} ?NewGArgs X X nil}
         if IsOpen then CND RecordGV GFront3 LabelGVO FSs in
            %% {`RecordC.tellSize` Label Width ?VO}
            %% {`^` VO Feat1 Subtree1} ... {`^` VO Featn Subtreen}
            CND = {CoordNoDebug {GLabel getCoord($)}}
            {@BA generate('OpenRecord' CND ?RecordGV)}
            Unnester, UnnestToVar(Label 'Label' ?GFront3 ?LabelGVO)
            FSs = (case Unnester, AddImport('x-oz://system/RecordC.ozf' $)
                   of unit then
                      fOpApplyStatement('RecordC.tellSize'
                                        [fOcc({LabelGVO getVariable($)})
                                         fInt({Length NewGArgs} CND)
                                         fOcc(RecordGV)] CND)
                   elseof FE then
                      fApply(fOpApply('.' [FE fAtom('tellSize' CND)] CND)
                             [fOcc({LabelGVO getVariable($)})
                              fInt({Length NewGArgs} CND)
                              fOcc(RecordGV)] CND)
                   end|
                   {List.mapInd NewGArgs
                    fun {$ I GArg} Feat Subtree in
                       Feat#Subtree =
                       case GArg of F#T then
                          if {HasFeature F Core.imAVariableOccurrence} then
                             fOcc({F getVariable($)})
                          else Feat in
                             {F getValue(?Feat)}
                             if {IsLiteral Feat} then
                                fAtom(Feat CND)
                             else   % if {IsInt Feat} then
                                fInt(Feat CND)
                             end
                          end#fOcc({T getVariable($)})
                       elseof T then
                          fInt(I CND)#fOcc({T getVariable($)})
                       end
                       fEq(fOpApply('^' [fOcc(RecordGV) Feat] CND) Subtree CND)
                    end})
            GFront2 = GFront3|{Map FSs fun {$ FS}
                                          Unnester, UnnestStatement(FS $)
                                       end}
            {RecordGV occ(CND ?GRecord)}
         else
            GFront2 = nil
            GRecord = {New Core.construction init(GLabel NewGArgs)}
         end
      end

      meth UnnestProc(FEs FS C ?GS) FMatches FResultVars FS1 FS2 GBody in
         %% each formal argument in FEs must be a pattern;
         %% all pattern variables must be pairwise distinct
         Unnester, UnnestProcFormals(FEs nil ?FMatches nil ?FResultVars nil)
         FS1 = {FoldL FResultVars fun {$ FS FV} fEq(FV FS C) end FS}
         FS2 = {FoldR FMatches
                fun {$ FV#FE#C In}
                   fCase(FV [fCaseClause(FE In)]
                         fNoElse(C)   %--** better exception
                         C)
                end FS1}
         {@BA openScope()}
         Unnester, UnnestStatement(FS2 ?GBody)
         GS = {MakeDeclaration {@BA closeScope($)} GBody C}
      end
      meth UnnestProcFormals(FEs Occs GdHd GdTl RtHd RtTl)
         case FEs of FE|FEr then NewOccs GdMid RtMid in
            Unnester, UnnestProcFormal(FE Occs ?NewOccs GdHd GdMid RtHd RtMid)
            Unnester, UnnestProcFormals(FEr NewOccs GdMid GdTl RtMid RtTl)
         [] nil then
            GdHd = GdTl
            RtHd = RtTl
         end
      end
      meth UnnestProcFormal(FE Occs ?NewOccs GdHd GdTl RtHd RtTl)
         case FE of fVar(PrintName C) then
            if {Member PrintName Occs} then GV in
               NewOccs = Occs
               {@BA generate('Formal' C ?GV)}
               GdHd = fOcc(GV)#fEscape(FE C)#C|GdTl
               RtHd = RtTl
            else
               {@BA bind(PrintName C _)}
               NewOccs = PrintName|Occs
               GdHd = GdTl
               RtHd = RtTl
            end
         [] fAnonVar(Origin C GV) then
            {@BA generate(Origin C ?GV)}
            NewOccs = Occs
            GdHd = GdTl
            RtHd = RtTl
         [] fWildcard(C) then
            {@BA generate('Wildcard' C _)}
            NewOccs = Occs
            GdHd = GdTl
            RtHd = RtTl
         [] fDollar(C) then GV in
            {@BA generate('Result' C ?GV)}
            NewOccs = Occs
            GdHd = GdTl
            RtHd = fOcc(GV)|RtTl
         else C GV in
            C = {CoordinatesOf FE}
            {@BA generate('Formal' C ?GV)}
            NewOccs = Occs
            if {IsPattern FE true} then NewPattern in
               Unnester, EscapePattern(FE Occs RtHd RtTl ?NewPattern)
               GdHd = fOcc(GV)#NewPattern#C|GdTl
            else
               {@reporter
                error(coord: C kind: SyntaxError
                      msg: 'only patterns in `proc\'/`fun\' head allowed')}
               GdHd = GdTl
               RtHd = RtTl
            end
         end
      end
      meth EscapePattern(FE PrintNames RtHd RtTl $)
         case FE of fEq(E1 E2 C) then RtInter in
            fEq(Unnester, EscapePattern(E1 PrintNames RtHd RtInter $)
                Unnester, EscapePattern(E2 PrintNames RtInter RtTl $) C)
         [] fVar(PrintName C) then
            RtHd = RtTl
            if {Member PrintName PrintNames} then fEscape(FE C)
            else FE
            end
         [] fDollar(C) then GV in
            RtHd = fOcc(GV)|RtTl
            fAnonVar('Result' C GV)
         [] fRecord(L As) then NewAs in
            Unnester, EscapePatternSub(As PrintNames RtHd RtTl ?NewAs)
            fRecord(L NewAs)
         [] fOpenRecord(L As) then NewAs in
            Unnester, EscapePatternSub(As PrintNames RtHd RtTl ?NewAs)
            fOpenRecord(L NewAs)
         else
            RtHd = RtTl
            FE
         end
      end
      meth EscapePatternSub(As PrintNames RtHd RtTl $)
         case As of A|Ar then RtInter in
            case A of fColon(F E) then
               fColon(F Unnester, EscapePattern(E PrintNames RtHd RtInter $))
            else
               Unnester, EscapePattern(A PrintNames RtHd RtInter $)
            end|Unnester, EscapePatternSub(Ar PrintNames RtInter RtTl $)
         [] nil then
            RtHd = RtTl
            nil
         end
      end

      meth AddImport(From $)
         case @CurrentImportFV of unit then unit
         elseof ImportFV then Feature in
            Unnester, AddImportSub(@AdditionalImports From Feature)
            fOpApply('.' [ImportFV fAtom(Feature unit)] unit)
         end
      end
      meth AddImportSub(Imports From Feature)
         case Imports of F#!From|_ then Feature = F
         [] _|Rest then Unnester, AddImportSub(Rest From Feature)
         [] nil then
            AdditionalImports <- {Append @AdditionalImports [Feature#From]}
         end
      end

      meth AnalyseImports(Ds ImportGV ?ImportFeatures ?FImportArgs ?ImportFS)
         case Ds of fImportItem(FV=fVar(PrintName C) Fs FImportAt)|Dr then
            NewFs FFsList FS ImportFeaturesr FInfo FImportArgr ImportFS2
         in
            Unnester, AnalyseImportFeatures(Fs FV ?NewFs ?FFsList ?FS)
            %--** check that all features are distinct
            %--** read corresponding type description from pickle
            ImportFeatures = PrintName|ImportFeaturesr
            FInfo = fRecord(fAtom('info' C)
                            fColon(fAtom('type' C) FFsList)|
                            case FImportAt of fImportAt(FE) then
                               [fColon(fAtom('from' C) FE)]
                            [] fNoImportAt then nil
                            end)
            FImportArgs = fColon(fAtom(PrintName C) FInfo)|FImportArgr
            ImportFS = fAnd(fAnd(fDoImport(fImportItem(FV NewFs FImportAt) _
                                           ImportGV) FS) ImportFS2)
            Unnester, AnalyseImports(Dr ImportGV
                                     ?ImportFeaturesr ?FImportArgr ?ImportFS2)
         [] nil then
            ImportFeatures = nil
            FImportArgs = nil
            ImportFS = fSkip(unit)
         end
      end
      meth AnalyseImportFeatures(Fs FV ?NewFs ?FFsList ?FS)
         case Fs of X|Xr then F FFV FSr NewFsr FFsListr in
            case X of FFV0#F0 then
               F = F0
               FFV = FFV0
               NewFs = X|NewFsr
            else GV in
               F = X
               FFV = fOcc(GV)
               NewFs = fAnonVar('ImportSubtree' {CoordinatesOf F} GV)#F|NewFsr
            end
            FS = fAnd(fEq(FFV fByNeedDot(FV F) unit) FSr)
            FFsList = fRecord(fAtom('|' unit) [F FFsListr])
            Unnester, AnalyseImportFeatures(Xr FV ?NewFsr ?FFsListr ?FSr)
         [] nil then
            NewFs = nil
            FFsList = fAtom(nil unit)
            FS = fSkip(unit)
         end
      end
      meth UnnestImportFeatures(Fs $)
         case Fs of V#F|Xr then GV in
            GV = case V of fVar(PrintName C) then
                    {@BA bind(PrintName C $)}
                 [] fAnonVar(Origin C GV) then
                    {@BA generate(Origin C ?GV)}
                    GV
                 end
            case F of fAtom(X C) then X#C#_#GV
            [] fInt(I C) then I#C#_#GV
            end|Unnester, UnnestImportFeatures(Xr $)
         [] nil then nil
         end
      end
      meth AnalyseExports(Ds ?FExportArgs ?FColons)
         case Ds of D|Dr then
            fExportItem(FEI) = D FeatureName FV GV FExportArgr FColonr
         in
            case FEI of fColon(X Y) then
               FeatureName = X
               FV = Y
            [] fVar(PrintName2 C) then
               FeatureName = fAtom({PrintName.downcase PrintName2} C)
               FV = FEI
            end
            FExportArgs = fColon(FeatureName fTypeOf(GV))|FExportArgr
            FColons = fColon(FeatureName fGetBinder(FV GV))|FColonr
            Unnester, AnalyseExports(Dr ?FExportArgr ?FColonr)
         [] nil then
            FExportArgs = nil
            FColons = nil
         end
      end

      meth UnnestFromProp(FEs O GSHd GSTl GEsHd GEsTl)
         case FEs of FE|FEr then GEqs GVO GSInter GEsInter in
            Unnester, UnnestToVar(FE O ?GEqs ?GVO)
            GSHd = GEqs|GSInter
            GEsHd = GVO|GEsInter
            Unnester, UnnestFromProp(FEr O GSInter GSTl GEsInter GEsTl)
         [] nil then
            GSHd = GSTl
            GEsHd = GEsTl
         end
      end
      meth UnnestAttrFeat(FAttrFeats O GSHd GSTl GAttrFeatsHd GAttrFeatsTl)
         case FAttrFeats of X|Xr then GSInter GAFInter in
            case X of F#E then GF GEqs GVO in
               Unnester, MakeLabelOrFeature(F ?GF)
               Unnester, UnnestToVar(E O ?GEqs ?GVO)
               GSHd = GEqs|GSInter
               GAttrFeatsHd = (GF#GVO)|GAFInter
            else GF in
               Unnester, MakeLabelOrFeature(X ?GF)
               GSHd = GSInter
               GAttrFeatsHd = GF|GAFInter
            end
            Unnester, UnnestAttrFeat(Xr O GSInter GSTl GAFInter GAttrFeatsTl)
         [] nil then
            GSHd = GSTl
            GAttrFeatsHd = GAttrFeatsTl
         end
      end

      meth UnnestMeths(FMeths ?GFrontEq ?GMeths)
         case FMeths of fMeth(FHead FP C)|FMethRest then
            GFrontEq1 GMeth GFrontEq2 GMethRest
         in
            Unnester, UnnestMeth(FHead FP C ?GFrontEq1 ?GMeth)
            GFrontEq = GFrontEq1|GFrontEq2
            GMeths = GMeth|GMethRest
            Unnester, UnnestMeths(FMethRest ?GFrontEq2 ?GMethRest)
         elseof nil then
            GFrontEq = nil
            GMeths = nil
         end
      end
      meth UnnestMeth(FHead FP C ?GFrontEq ?GMeth)
         RealFHead GVMsg GLabel FFormals IsOpen N GFormals GBody
      in
         {@BA openScope()}
         case FHead of fEq(FHead2 fVar(PrintName C) _) then
            RealFHead = FHead2
            {@BA bind(PrintName C ?GVMsg)}
         else
            RealFHead = FHead
         end
         Unnester, UnnestMethHead(RealFHead ?GLabel ?FFormals ?IsOpen)
         Unnester, BindMethFormals(FFormals)
         N = {DollarsInScope FFormals 0}
         ArgCounter <- 1
         if N == 0 then GFormals0 GS1 GS2 in
            Unnester, UnnestMethFormals(FFormals ?GFrontEq ?GFormals0)
            {@BA openScope()}
            Unnester, UnnestStatement(FP ?GS1)
            Unnester, UnnestMethBody(GVMsg GFormals0 GS1 ?GFormals ?GS2)
            GBody = {MakeDeclaration {@BA closeScope($)} GS2 C}
         else DollarC GV NewFFormals GFormals0 GS1 GS2 in
            DollarC = {DollarCoord FFormals}
            if N > 1 then
               {@reporter error(coord: DollarC kind: SyntaxError
                                msg: 'at most one $ in method head allowed')}
            end
            {@BA generate('Result' DollarC ?GV)}
            NewFFormals = {ReplaceDollar FFormals fOcc(GV)}
            Unnester, UnnestMethFormals(NewFFormals ?GFrontEq ?GFormals0)
            {@BA openScope()}
            Unnester, UnnestExpression(FP GV ?GS1)
            Unnester, UnnestMethBody(GVMsg GFormals0 GS1 ?GFormals ?GS2)
            GBody = {MakeDeclaration {@BA closeScope($)} GS2 C}
         end
         if {@state getSwitch(controlflowinfo $)} andthen {IsFree GVMsg}
         then
            {@BA generate('Message' C ?GVMsg)}
         end
         {@BA closeScope(_)}
         if {IsFree GVMsg} then
            GVMsg = unit
         end
         GMeth = {New Core.method init(GLabel GFormals IsOpen GVMsg GBody C)}
         if {@state getSwitch(staticvarnames $)} then
            {GMeth setAllVariables({@BA getAllVariables($)})}
         end
      end
      meth UnnestMethHead(FHead ?GLabel ?FFormals ?IsOpen)
         case FHead of fAtom(X C) then
            GLabel = {New Core.valueNode init(X C)}
            FFormals = nil
            IsOpen = false
         [] fVar(PrintName C) then
            {@BA refer(PrintName C ?GLabel)}
            FFormals = nil
            IsOpen = false
         [] fEscape(fVar(PrintName C) _) then
            {@BA refer(PrintName C ?GLabel)}
            FFormals = nil
            IsOpen = false
         [] fRecord(FLabel FArgs) then
            Unnester, UnnestMethHead(FLabel ?GLabel _ _)
            FFormals = FArgs
            IsOpen = false
         [] fOpenRecord(FLabel FArgs) then
            Unnester, UnnestMethHead(FLabel ?GLabel _ _)
            FFormals = FArgs
            IsOpen = true
         end
      end
      meth BindMethFormals(FFormals)
         %% This simply declares all formal argument variables so that
         %% they can be used inside defaults and we can check they are
         %% not used as features.
         {ForAll FFormals
          proc {$ FFormal} FV in
             FV = case FFormal of fMethArg(FV0 _) then FV0
                  [] fMethColonArg(_ FV0 _) then FV0
                  end
             case FV of fVar(PrintName C) then
                if {@BA isBoundLocally(PrintName $)} then
                   {@reporter error(coord: C kind: SyntaxError
                                    msg: ('argument variables in method head '#
                                          'must be distinct'))}
                else
                   {@BA bind(PrintName C _)}
                end
             [] fWildcard(_) then skip
             [] fDollar(_) then skip
             end
          end}
      end
      meth UnnestMethFormals(FFormals ?GFrontEq ?GFormals)
         case FFormals of FA|FAr then GFrontEq1 GA GFrontEq2 GAr in
            Unnester, UnnestMethFormal(FA ?GFrontEq1 ?GA)
            GFrontEq = GFrontEq1|GFrontEq2
            GFormals = GA|GAr
            Unnester, UnnestMethFormals(FAr ?GFrontEq2 ?GAr)
         [] nil then
            GFrontEq = nil
            GFormals = nil
         end
      end
      meth UnnestMethFormal(FFormal ?GFrontEq ?GFormal) FF GF GV FDefault in
         case FFormal of fMethArg(FV FE) then N = @ArgCounter in
            FF = fInt(N {CoordinatesOf FV})
            ArgCounter <- N + 1
            case FV of fVar(PrintName C) then
               {@BA bind(PrintName C ?GV)}
            [] fWildcard(C) then
               {@BA generate('Wildcard' C ?GV)}
            [] fOcc(X) then
               GV = X
            end
            FDefault = FE
         [] fMethColonArg(FF0 FV FE) then
            FF = FF0
            case FF of fVar(PrintName C) then
               if {@BA isBoundLocally(PrintName $)} then
                  {@reporter error(coord: C kind: SyntaxError
                                   msg: ('nonsensical use of formal argument '#
                                         'variable as feature'))}
               end
            else skip
            end
            case FV of fVar(PrintName C) then
               {@BA bind(PrintName C ?GV)}
            [] fWildcard(C) then
               {@BA generate('Wildcard' C ?GV)}
            [] fOcc(X) then
               GV = X
            end
            FDefault = FE
         end
         Unnester, MakeLabelOrFeature(FF ?GF)
         case FDefault of fNoDefault then
            GFrontEq = nil
            GFormal = {New Core.methFormal init(GF GV)}
         [] fDefault(FE C) then
            case FE of fWildcard(_) then
               GFrontEq = nil
               GFormal = {New Core.methFormalWithDefault init(GF GV unit)}
            elseif {IsGround FE} then DefaultGV in
               {@BA generateForOuterScope('Default' C ?DefaultGV)}
               Unnester, UnnestExpression(FE DefaultGV ?GFrontEq)
               GFormal = {New Core.methFormalWithDefault
                          init(GF GV {DefaultGV occ(C $)})}
            else
               GFrontEq = nil
               GFormal = ({New Core.methFormalOptional init(GF GV)}#
                          FF#fOcc(GV)#FE)
            end
         end
      end
      meth UnnestMethBody(GVMsg GFormals0 GS1 ?GFormals ?GS2)
         GFormals#GS2 =
         {FoldR GFormals0
          fun {$ GFormal0 GFormals#GS}
             case GFormal0 of GFormal#FF#FV#FE then
                C ArbiterGV ArbiterFV TempGV TempFV FS0 FS1 GS0 GS1
             in
                C = {CoordinatesOf FF}
                if {IsFree GVMsg} then
                   {@BA generateForOuterScope('Message' C ?GVMsg)}
                end
                {@BA generate('Arbiter' C ?ArbiterGV)}
                ArbiterFV = fOcc(ArbiterGV)
                {@BA generate('Temp' C ?TempGV)}
                TempFV = fOcc(TempGV)
                FS0 = fOpApplyStatement('Record.testFeature'
                                        [fOcc(GVMsg) FF ArbiterFV TempFV] C)
                FS1 = fBoolCase(ArbiterFV fEq(FV TempFV C) fEq(FV FE C) C)
                Unnester, UnnestStatement(FS0 ?GS0)
                Unnester, UnnestStatement(FS1 ?GS1)
                (GFormal|GFormals)#(GS0|GS1|GS)
             else
                (GFormal0|GFormals)#GS
             end
          end nil#GS1}
      end

      meth UnnestIfArbiter(FE ApplyTrueProc ApplyFalseProc ?GClauseBodies ?GS)
         %% optimization of `case E1 orelse E2 then S1 else S2 end'
         %% and the like
         case FE of fOrElse(FE1 FE2 C) then
            GClauseBodies1 GElse GClauseBody ApplyElseProc GClauseBodies2
         in
            Unnester, UnnestIfArbiter(FE2 ApplyTrueProc ApplyFalseProc
                                      ?GClauseBodies1 ?GElse)
            Unnester, MakeClauseBody('FalseCase' GElse C ?GClauseBody
                                     ?ApplyElseProc)
            GClauseBodies = GClauseBodies1|GClauseBody|GClauseBodies2
            Unnester, UnnestIfArbiter(FE1 ApplyTrueProc ApplyElseProc
                                      ?GClauseBodies2 ?GS)
         [] fAndThen(FE1 FE2 C) then
            GClauseBodies1 GThen GClauseBody ApplyThenProc GClauseBodies2
         in
            Unnester, UnnestIfArbiter(FE2 ApplyTrueProc ApplyFalseProc
                                      ?GClauseBodies1 ?GThen)
            Unnester, MakeClauseBody('TrueCase' GThen C ?GClauseBody
                                     ?ApplyThenProc)
            GClauseBodies = GClauseBodies1|GClauseBody|GClauseBodies2
            Unnester, UnnestIfArbiter(FE1 ApplyThenProc ApplyFalseProc
                                      ?GClauseBodies2 ?GS)
         else GFrontEq GVO C GS0 in
            {@BA openScope()}
            Unnester, UnnestToVar(FE 'IfArbiter' ?GFrontEq ?GVO)
            C = {CoordinatesOf FE}
            GClauseBodies = nil
            GS0 = (GFrontEq|
                   {MakeIfNode GVO {ApplyTrueProc} {ApplyFalseProc} C @BA})
            GS = {MakeDeclaration {@BA closeScope($)} GS0 C}
         end
      end
      meth MakeClauseBody(Origin GBody C ?GS ?ApplyProc) GV in
         {@BA generate(Origin C ?GV)}
         GS = {New Core.clauseBody init({GV occ(C $)} nil GBody unit nil C)}
         fun {ApplyProc}
            {New Core.application init({GV occ(C $)} nil C)}
         end
      end

      meth UnnestCaseClauses(FCs ?GCs)
         case FCs of fCaseClause(FPattern0 FS)|FCr then FPattern GCr in
            FPattern = case FPattern0 of fSideCondition(FP _ _ _) then FP
                       else FPattern0
                       end
            if {IsPattern FPattern false} then PatternPNs GPattern in
               {@BA openScope()}
               PatternPNs = {Map {GetPatternVariablesExpression FPattern $ nil}
                             fun {$ fVar(PrintName C)}
                                {@BA bind(PrintName C _)}
                                PrintName
                             end}
               Unnester, TranslatePattern(FPattern PatternPNs true ?GPattern)
               case FPattern0 of fSideCondition(_ FLocals FE C) then
                  NewFS FVs GArbiter GCondition GS0 GS GLocals GPattern2 GVs
               in
                  {@BA openScope()}
                  NewFS = {MakeTrivialLocalPrefix FLocals ?FVs nil}
                  {ForAll FVs
                   proc {$ fVar(PrintName C)} {@BA bind(PrintName C _)} end}
                  {@BA generate('SideCondition' C ?GArbiter)}
                  GCondition = (Unnester, UnnestStatement(NewFS $)|
                                Unnester, UnnestExpression(FE GArbiter $))
                  {@BA openScope()}
                  Unnester, UnnestStatement(FS ?GS0)
                  GS = {MakeDeclaration {@BA closeScope($)} GS0
                        {CoordinatesOf FPattern}}
                  {@BA closeScope(?GLocals)}
                  GPattern2 = {New Core.sideCondition
                               init(GPattern GLocals GCondition
                                    {GArbiter occ(C $)} C)}
                  {@BA closeScope(?GVs)}
                  GCs = {New Core.patternClause init(GVs GPattern2 GS)}|GCr
               else GS0 GS GVs in
                  {@BA openScope()}
                  Unnester, UnnestStatement(FS ?GS0)
                  GS = {MakeDeclaration {@BA closeScope($)} GS0
                        {CoordinatesOf FPattern}}
                  {@BA closeScope(?GVs)}
                  GCs = {New Core.patternClause init(GVs GPattern GS)}|GCr
               end
            else
               {@reporter
                error(coord: {CoordinatesOf FPattern} kind: SyntaxError
                      msg: ('only patterns in `case\' conditional allowed'))}
               GCs = GCr
            end
            Unnester, UnnestCaseClauses(FCr ?GCr)
         [] nil then
            GCs = nil
         end
      end
      meth TranslatePattern(FPattern PatternPNs PVAllowed $)
         %% Precondition: {IsPattern FPattern false} == true.
         case FPattern of fEq(FE1 FE2 C) then
            case FE1 of fVar(PrintName C2) then GVO GPattern in
               {{@BA refer(PrintName C2 $)}
                makeIntoPatternVariableOccurrence(?GVO)}
               Unnester, TranslatePattern(FE2 PatternPNs true ?GPattern)
               {New Core.equationPattern init(GVO GPattern C)}
            [] fWildcard(_) then
               Unnester, TranslatePattern(FE2 PatternPNs true $)
            elsecase FE2 of fVar(PrintName C2) then GVO GPattern in
               {{@BA refer(PrintName C2 $)}
                makeIntoPatternVariableOccurrence(?GVO)}
               Unnester, TranslatePattern(FE1 PatternPNs true ?GPattern)
               {New Core.equationPattern init(GVO GPattern C)}
            [] fWildcard(_) then
               Unnester, TranslatePattern(FE1 PatternPNs true $)
            end
         [] fAtom(X C) then
            {New Core.valueNode init(X C)}
         [] fVar(PrintName C) then
            if {Member PrintName PatternPNs} then
               if PVAllowed then skip
               else
                  {@reporter
                   error(coord: C kind: SyntaxError
                         msg: ('nonsensical use of pattern variable '#
                               'as label or feature'))}
               end
               {{@BA refer(PrintName C $)}
                makeIntoPatternVariableOccurrence($)}
            else
               {@BA refer(PrintName C $)}
            end
         [] fAnonVar(Origin C GV) then
            {@BA generate(Origin C ?GV)}
            {{GV occ(C $)} makeIntoPatternVariableOccurrence($)}
         [] fWildcard(C) then GV in
            {@BA generate('Wildcard' C ?GV)}
            {{GV occ(C $)} makeIntoPatternVariableOccurrence($)}
         [] fEscape(fVar(PrintName C) _) then
            if {Member PrintName PatternPNs} then
               {{@BA refer(PrintName C $)}
                makeIntoPatternVariableOccurrence($)}
            else
               {@BA refer(PrintName C $)}
            end
         [] fInt(X C) then
            {New Core.valueNode init(X C)}
         [] fFloat(X C) then
            {New Core.valueNode init(X C)}
         [] fRecord(L As) then
            Unnester, TranslateRecordPattern(L As false PatternPNs $)
         [] fOpenRecord(L As) then
            Unnester, TranslateRecordPattern(L As true PatternPNs $)
         end
      end
      meth TranslateRecordPattern(L Args IsOpen PatternPNs $)
         GL GArgs NewGArgs X
      in
         Unnester, TranslatePattern(L PatternPNs false ?GL)
         GArgs = {Map Args
                  fun {$ Arg}
                     case Arg of fColon(F E) then
                        Unnester, TranslatePattern(F PatternPNs false $)#
                        Unnester, TranslatePattern(E PatternPNs true $)
                     else
                        Unnester, TranslatePattern(Arg PatternPNs true $)
                     end
                  end}
         {SortNoColonsToFront GArgs ?NewGArgs X X nil}
         {New Core.recordPattern init(GL NewGArgs IsOpen)}
      end

      meth UnnestTry(FS $)
         case FS of fTry(FS fNoCatch fNoFinally C) then GBody in
            {@BA openScope()}
            Unnester, UnnestStatement(FS ?GBody)
            {MakeDeclaration {@BA closeScope($)} GBody C}
         elseof fTry(FS fNoCatch FFinally C) then
            CND V FV FX FException NewFS1 NewFS2
         in
            CND = {CoordNoDebug C}
            {@BA generate('ReRaise' C ?V)}
            FV = fOcc(V)
            FX = fVar('X' C)
            FException = fRecord(fAtom('ex' C) [FX])
            NewFS1 = fTry(fAnd(FS fEq(FV fAtom(unit CND) CND))
                          fCatch([fCaseClause(FX fEq(FV FException C))] CND)
                          fNoFinally C)
            NewFS2 = fCase(FV [fCaseClause(FException
                                           fOpApplyStatement(
                                              'Exception.\'raise\'' [FX] CND))]
                           fSkip(CND) CND)
            Unnester, UnnestTry(NewFS1 $)|
            Unnester, UnnestStatement(FFinally $)|
            Unnester, UnnestStatement(NewFS2 $)
         elseof fTry(FS fCatch(FCaseClauses C2) fNoFinally C) then
            GBody GS X FX FElse NewC NewFS GCatchBody
         in
            {@BA openScope()}
            Unnester, UnnestStatement(FS ?GBody)
            GS = {MakeDeclaration {@BA closeScope($)} GBody C}
            {@BA openScope()}
            {@BA generate('Exception' C ?X)}
            FX = fOcc(X)
            case FCaseClauses of [fCaseClause(fVar(_ _) _)] then
               FElse = fNoElse(C2)
            [] [fCaseClause(fWildcard(_) _)] then
               FElse = fNoElse(C2)
            else
               FElse = fOpApplyStatement('Exception.\'raise\'' [FX] C2)
            end
            NewC = case C#C2 of pos(_ _ _ F2 L2 C2)#pos(F1 L1 C1) then
                      pos(F1 L1 C1 F2 L2 C2)
                   [] fineStep(_ _ _ F2 L2 C2)#pos(F1 L1 C1) then
                      fineStep(F1 L1 C1 F2 L2 C2)
                   [] coarseStep(_ _ _ F2 L2 C2)#pos(F1 L1 C1) then
                      coarseStep(F1 L1 C1 F2 L2 C2)
                   elsecase C2 of unit then unit
                   else
                      {Adjoin C2 {Label C}}
                   end
            NewFS = fCase(FX FCaseClauses FElse NewC)
            Unnester, UnnestStatement(NewFS ?GCatchBody)
            {@BA closeScope(_)}
            {New Core.tryNode init(GS X GCatchBody C)}
         elseof fTry(FS FCatch FFinally C) then
            Unnester,
            UnnestTry(fTry(fTry(FS FCatch fNoFinally C) fNoCatch FFinally
                           {CoordNoDebug C}) $)
         end
      end

      meth UnnestClauses(FClauses ?FClauseProcs)
         case FClauses of fClause(FLocals FGuard FBody)|FClauser then
            FProc|FClauseProcr = FClauseProcs
         in
            FProc = case FBody of fNoThen(C) then CND in
                       %% S1 in S2
                       %% =>
                       %% proc {$} S1 in S2 end
                       CND = {CoordNoDebug C}
                       fProc(fDollar(C) nil
                             fLocal(FLocals FGuard C) nil CND)
                    else C = {CoordinatesOf FBody} CND in
                       %% S1 in S2 then S3
                       %% =>
                       %% fun {$} S1 in S2 proc {$} S3 end end
                       CND = {CoordNoDebug C}
                       fFun(fDollar(C) nil
                            fLocal(FLocals fAnd(FGuard
                                                fProc(fDollar(C) nil FBody
                                                      nil CND)) C) nil CND)
                    end
            Unnester, UnnestClauses(FClauser ?FClauseProcr)
         [] nil then
            FClauseProcs = nil
         end
      end
      meth TransformExpressionOr(Label FClauses C ToGV $)
         PrintName FVs NewFV FS
      in
         FS = Label({Map FClauses
                     fun {$ fClause(FLocals FGuard FBody)}
                        case FBody of fNoThen(C) then
                           {@reporter
                            error(coord: C kind: SyntaxError
                                  msg: ('`then\' part in nested `or\' '#
                                        'not optional'))}
                           fClause(FLocals FGuard FBody)
                        else
                           fClause(FLocals FGuard fEq(NewFV FBody C))
                        end
                     end} C)
         {FoldL FClauses
          fun {$ FVs fClause(FE _ _)}
             {GetPatternVariablesExpression FE FVs $}
          end FVs nil}
         {ToGV getPrintName(?PrintName)}
         if {Some FVs fun {$ fVar(X _)} X == PrintName end} then NewGV in
            %% use a temporary to avoid name clash
            Unnester, GenerateNewVar(PrintName FVs C ?NewGV)
            NewFV = fOcc(NewGV)
            Unnester, UnnestStatement(fAnd(fEq(NewFV fOcc(ToGV) C) FS) $)
         else
            NewFV = fOcc(ToGV)
            Unnester, UnnestStatement(FS $)
         end
      end

      meth UnnestFDExpression(FE ?GFrontEqs ?NewFE)
         %% only '+', '-', '*' and '~' may remain as operators;
         %% only variables and integers may remain as operands.
         case FE of fOpApply(Op FEs C) then
            if Op == '+' orelse Op == '-' orelse Op == '*' then
               GFrontEqs1 NewFE1 GFrontEqs2 NewFE2
               [FE1 FE2] = FEs in
               Unnester, UnnestFDExpression(FE1 ?GFrontEqs1 ?NewFE1)
               Unnester, UnnestFDExpression(FE2 ?GFrontEqs2 ?NewFE2)
               GFrontEqs = GFrontEqs1|GFrontEqs2
               NewFE = fOpApply(Op [NewFE1 NewFE2] C)
            elseif Op == '~' then [FE1] = FEs NewFE1 in
               Unnester, UnnestFDExpression(FE1 ?GFrontEqs ?NewFE1)
               NewFE = fOpApply('~' [NewFE1] C)
            else GV in
               {@BA generate('UnnestFD' C ?GV)}
               NewFE = fOcc(GV)
               Unnester, UnnestExpression(FE GV ?GFrontEqs)
            end
         [] fVar(_ _) then
            GFrontEqs = nil
            NewFE = FE
         [] fInt(_ _) then
            GFrontEqs = nil
            NewFE = FE
         else C = {CoordinatesOf FE} GV in
            {@BA generate('UnnestFD' C ?GV)}
            NewFE = fOcc(GV)
            Unnester, UnnestExpression(FE GV ?GFrontEqs)
         end
      end
   end

   fun {IsDirective Query}
      case Query of dirSwitch(_) then true
      [] dirLocalSwitches then true
      [] dirPushSwitches then true
      [] dirPopSwitches then true
      else false
      end
   end

   local
      proc {MakeExpressionQuerySub Qs ?NewQs ?Found}
         case Qs of Q1|Qr then NewQr Found0 in
            {MakeExpressionQuerySub Qr ?NewQr ?Found0}
            if Found0 then
               NewQs = Q1|NewQr
               Found = true
            elseif {IsDirective Q1} then
               NewQs = Qs
               Found = false
            else
               case Q1 of fDeclare(FS FE C) then
                  %--** `result`
                  NewQs = fDeclare(FS fEq(fVar('`result`' unit) FE unit) C)|Qr
                  Found = true
               else
                  %--** `result`
                  NewQs = fEq(fVar('`result`' unit) Q1 unit)|Qr
                  Found = true
               end
            end
         [] nil then
            NewQs = nil
            Found = false
         end
      end
   in
      fun {MakeExpressionQuery Queries} NewQueries Found in
         {MakeExpressionQuerySub Queries ?NewQueries ?Found}
         NewQueries#Found
      end
   end

   local
      fun {VsToFAnd Vs}
         case Vs of V|Vr then
            case Vr of nil then V
            else fAnd(V {VsToFAnd Vr})
            end
         [] nil then fSkip(unit)
         end
      end

      fun {FS C}
         case C of unit then C else {Adjoin C fineStep} end
      end

      fun {CS C}
         case C of unit then C else {Adjoin C coarseStep} end
      end

      fun {SP P}
         case P of fDeclare(P1 P2 C) then NewP1 Vs in
            NewP1 = {MakeTrivialLocalPrefix P1 ?Vs nil}
            fDeclare({VsToFAnd Vs} {SP fAnd(NewP1 P2)} C)
         [] fAnd(P1 P2) then fAnd({SP P1} {SP P2})
         [] fEq(P1 P2 C) then fEq({TP P1} {SP P2} C)
         [] fAssign(P1 P2 C) then fAssign({TP P1} {TP P2} {CS C})
         [] fOrElse(P1 P2 C) then fOrElse({TP P1} {TP P2} C)
         [] fAndThen(P1 P2 C) then fAndThen({TP P1} {TP P2} C)
         [] fOpApply(X Ps C) then fOpApply(X {Map Ps TP} {CS C})
         [] fOpApplyStatement(X Ps C) then
            fOpApplyStatement(X {Map Ps TP} {CS C})
         [] fFdCompare(X P1 P2 C) then fFdCompare(X {TP P1} {TP P2} {CS C})
         [] fFdIn(X P1 P2 C) then fFdIn(X {TP P1} {TP P2} {CS C})
         [] fObjApply(P1 P2 C) then fObjApply({TP P1} {TP P2} {CS C})
         [] fAt(P C) then fAt({TP P} {CS C})
         [] fAtom(X C) then fAtom(X {CS C})
         [] fVar(X C) then fVar(X {CS C})
         [] fEscape(V C) then fEscape(V {CS C})
         [] fWildcard(C) then fWildcard({CS C})
         [] fSelf(C) then fSelf({CS C})
         [] fDollar(C) then fDollar({CS C})
         [] fInt(X C) then fInt(X {CS C})
         [] fFloat(X C) then fFloat(X {CS C})
         [] fRecord(L As) then fRecord({SP L} {Map As TP})
         [] fOpenRecord(L As) then fOpenRecord({SP L} {Map As TP})
         [] fApply(P Ps C) then fApply({TP P} {Map Ps TP} {CS C})
         [] fProc(P1 Ps P2 Fs C) then fProc({TP P1} Ps {SP P2} Fs {CS C})
         [] fFun(P1 Ps P2 Fs C) then fFun({TP P1} Ps {SP P2} Fs {CS C})
         [] fFunctor(P1 Ds C) then
            fFunctor({TP P1} {Map Ds EP} {CS C})
         [] fClass(P Ds Ms C) then
            fClass({TP P} {Map Ds EP} {Map Ms SP} {CS C})
         [] fMeth(X P C) then fMeth(X {SP P} C)
         [] fLocal(P1 P2 C) then NewP1 Vs in
            NewP1 = {MakeTrivialLocalPrefix P1 ?Vs nil}
            fLocal({VsToFAnd Vs} {SP fAnd(NewP1 P2)} C)
         [] fBoolCase(P1 P2 P3 C) then
            fBoolCase({TP P1} {SP P2} {SP P3} {CS C})
         [] fNoElse(C) then fNoElse({CS C})
         [] fCase(P1 Cs P2 C) then
            fCase({TP P1} {Map Cs SP} {SP P2} {CS C})
         [] fCaseClause(P1 P2) then fCaseClause(P1 {SP P2})
         [] fLockThen(P1 P2 C) then fLockThen({TP P1} {SP P2} {CS C})
         [] fLock(P C) then fLock({SP P} {CS C})
         [] fThread(P C) then fThread({SP P} {CS C})
         [] fTry(P1 P2 P3 C) then fTry({SP P1} {SP P2} {SP P3} {CS C})
         [] fCatch(Cs C) then fCatch({Map Cs SP} C)
         [] fNoCatch then P
         [] fNoFinally then P
         [] fRaise(P C) then fRaise({TP P} {CS C})
         [] fSkip(C) then fSkip({CS C})
         [] fFail(C) then fFail({CS C})
         [] fNot(P C) then fNot({SP P} {CS C})
         [] fCond(Cs P C) then fCond({Map Cs SP} {SP P} {CS C})
         [] fClause(P1 P2 P3) then NewP1 Vs in
            NewP1 = {MakeTrivialLocalPrefix P1 ?Vs nil}
            fClause({VsToFAnd Vs} {SP fAnd(NewP1 P2)} {SP P3})
         [] fNoThen(C) then fNoThen({CS C})
         [] fOr(Cs C) then fOr({Map Cs SP} {CS C})
         [] fDis(Cs C) then fDis({Map Cs SP} {CS C})
         [] fChoice(Ps C) then fChoice({Map Ps SP} {CS C})
         [] fScanner(P1 Ds Ms Rs X C) then
            fScanner({TP P1} {Map Ds EP} {Map Ms SP} {Map Rs SP} X {CS C})
         [] fMode(V Ms) then fMode(V {Map Ms SP})
         [] fInheritedModes(_) then P
         [] fLexicalAbbreviation(_ _) then P
         [] fLexicalRule(R P) then fLexicalRule(R {SP P})
         [] fParser(P1 Ds Ms T Ps X C) then
            fParser({TP P1} {Map Ds EP} {Map Ms SP} T {Map Ps SP} X {CS C})
         [] fProductionTemplate(K Ps Rs E R) then
            fProductionTemplate(K Ps {Map Rs SP} {SP E} R)
         [] fSyntaxRule(G Ds E) then fSyntaxRule(G Ds {SP E})
         [] fSynApplication(_ _) then P
         [] fSynAction(P) then fSynAction({SP P})
         [] fSynSequence(Vs Es C) then fSynSequence(Vs {Map Es SP} C)
         [] fSynAlternative(Es) then fSynAlternative({Map Es SP})
         [] fSynAssignment(V E) then fSynAssignment(V {SP E})
         [] fSynTemplateInstantiation(K Es C) then
            fSynTemplateInstantiation(K {Map Es SP} C)
         [] fLoop(S C) then fLoop({SP S} {CS C})
         [] fMacro(Ss C) then fMacro({Map Ss SP} {CS C})
         [] fDotAssign(L R C) then fDotAssign({EP L} {EP R} {CS C})
         [] fColonEquals(L R C) then fColonEquals({EP L} {EP R} {CS C})
         [] fFOR(Ds B C) then fFOR({Map Ds FP} {SP B} {CS C})
         end
      end

      fun {EP P}
         case P of fDeclare(P1 P2 C) then fDeclare({EP P1} {EP P2} C)
         [] fAnd(P1 P2) then fAnd({EP P1} {EP P2})
         [] fEq(P1 P2 C) then fEq({TP P1} {EP P2} C)
         [] fAssign(P1 P2 C) then fAssign({TP P1} {TP P2} {FS C})
         [] fOrElse(P1 P2 C) then fOrElse({TP P1} {TP P2} C)
         [] fAndThen(P1 P2 C) then fAndThen({TP P1} {TP P2} C)
         [] fOpApply(X Ps C) then fOpApply(X {Map Ps TP} {FS C})
         [] fOpApplyStatement(X Ps C) then
            fOpApplyStatement(X {Map Ps TP} {FS C})
         [] fFdCompare(X P1 P2 C) then fFdCompare(X {TP P1} {TP P2} {FS C})
         [] fFdIn(X P1 P2 C) then fFdIn(X {TP P1} {TP P2} {FS C})
         [] fObjApply(P1 P2 C) then fObjApply({TP P1} {TP P2} {FS C})
         [] fAt(P C) then fAt({TP P} {FS C})
         [] fAtom(X C) then fAtom(X {FS C})
         [] fVar(X C) then fVar(X {FS C})
         [] fEscape(V C) then fEscape(V {FS C})
         [] fWildcard(C) then fWildcard({FS C})
         [] fSelf(C) then fSelf({FS C})
         [] fDollar(C) then fDollar({FS C})
         [] fInt(X C) then fInt(X {FS C})
         [] fFloat(X C) then fFloat(X {FS C})
         [] fRecord(L As) then fRecord({EP L} {Map As TP})
         [] fOpenRecord(L As) then fOpenRecord({EP L} {Map As TP})
         [] fApply(P Ps C) then fApply({TP P} {Map Ps TP} {FS C})
         [] fProc(P1 Ps P2 Fs C) then fProc({TP P1} Ps {SP P2} Fs {FS C})
         [] fFun(P1 Ps P2 Fs C) then fFun({TP P1} Ps {SP P2} Fs {FS C})
         [] fFunctor(P1 Ds C) then
            fFunctor({TP P1} {Map Ds EP} {FS C})
         [] fRequire(_ _) then P
         [] fPrepare(P1 P2 C) then fPrepare({EP P1} {EP P2} C)
         [] fImport(_ _) then P
         [] fExport(_ _) then P
         [] fDefine(P1 P2 C) then fDefine({SP P1} {SP P2} C)
         [] fClass(P Ds Ms C) then
            fClass({TP P} {Map Ds EP} {Map Ms SP} {FS C})
         [] fFrom(Ps C) then fFrom({Map Ps TP} C)
         [] fProp(Ps C) then fProp({Map Ps TP} C)
         [] fAttr(Ps C) then fAttr({Map Ps TP} C)
         [] fFeat(Ps C) then fFeat({Map Ps TP} C)
         [] P1#P2 then {TP P1}#{TP P2}
         [] fLocal(P1 P2 C) then fLocal({EP P1} {EP P2} C)
         [] fBoolCase(P1 P2 P3 C) then
            fBoolCase({TP P1} {EP P2} {EP P3} {FS C})
         [] fNoElse(C) then fNoElse({FS C})
         [] fCase(P1 Cs P2 C) then
            fCase({TP P1} {Map Cs EP} {EP P2} {FS C})
         [] fCaseClause(P1 P2) then fCaseClause(P1 {EP P2})
         [] fLockThen(P1 P2 C) then fLockThen({TP P1} {EP P2} {FS C})
         [] fLock(P C) then fLock({EP P} {FS C})
         [] fThread(P C) then fThread({SP P} {FS C})
         [] fTry(P1 P2 P3 C) then fTry({EP P1} {EP P2} {SP P3} {FS C})
         [] fCatch(Cs C) then fCatch({Map Cs EP} C)
         [] fNoCatch then P
         [] fRaise(P C) then fRaise({TP P} {FS C})
         [] fSkip(C) then fSkip({FS C})
         [] fFail(C) then fFail({FS C})
         [] fNot(P C) then fNot({EP P} {FS C})
         [] fCond(Cs P C) then fCond({Map Cs EP} {EP P} {FS C})
         [] fClause(P1 P2 P3) then fClause({EP P1} {EP P2} {EP P3})
         [] fNoThen(_) then P
         [] fOr(Cs C) then fOr({Map Cs EP} {FS C})
         [] fDis(Cs C) then fDis({Map Cs EP} {FS C})
         [] fChoice(Ps C) then fChoice({Map Ps EP} {FS C})
         [] fScanner(P1 Ds Ms Rs X C) then
            fScanner({TP P1} {Map Ds EP} {Map Ms SP} {Map Rs SP} X {FS C})
         [] fParser(P1 Ds Ms T Ps X C) then
            fParser({TP P1} {Map Ds EP} {Map Ms SP} T {Map Ps SP} X {FS C})
         [] fLoop(S C) then fLoop({EP S} {FS C})
         [] fMacro(Ss C) then fMacro({Map Ss EP} {CS C})
         [] fDotAssign(L R C) then fDotAssign({EP L} {EP R} {FS C})
         [] fColonEquals(L R C) then fColonEquals({EP L} {EP R} {FS C})
         [] fFOR(Ds B C) then fFOR({Map Ds FP} {SP B} {FS C})
         end
      end

      fun {TP P}
         case P of fAtom(_ _) then P
         [] fVar(_ _) then P
         [] fEscape(_ _) then P
         [] fWildcard(_) then P
         [] fSelf(_) then P
         [] fDollar(_) then P
         [] fInt(_ _) then P
         [] fFloat(_ _) then P
         [] fRecord(L As) then fRecord(L {Map As TP})
         [] fOpenRecord(L As) then fOpenRecord(L {Map As TP})
         [] fColon(F P) then fColon(F {TP P})
         else {EP P}
         end
      end

      fun {FP D}
         case D
         of forFeature(F E) then forFeature(F {EP E})
         [] forFrom(X G) then forFrom(X {EP G})
         [] forPattern(X G) then
            forPattern(
               X
               case G
               of forGeneratorList(E) then
                  forGeneratorList({EP E})
               [] forGeneratorInt(E1 E2 E3) then
                  forGeneratorInt(
                     {EP E1} {EP E2}
                     if E3==unit then unit else {EP E3} end)
               [] forGeneratorC(E1 E2 E3) then
                  forGeneratorC(
                     {EP E1} {EP E2}
                     if E3==unit then unit else {EP E3} end)
               end)
         end
      end
   in
      proc {UnnestQuery TopLevel Reporter State Query ?GVs ?GS ?FreeGVs}
         O = {New Unnester init(TopLevel Reporter State)}
         Query0 = if {State getSwitch(controlflowinfo $)} then {SP Query}
                  else Query
                  end
      in
         {O unnestQuery(Query0 ?GVs ?GS ?FreeGVs)}
      end
   end
end
