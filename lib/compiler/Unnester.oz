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
require
   FD(sup: FdSup)
prepare
   fun {IsFd I}
      I =< FdSup andthen I >= 0
   end
import
   CompilerSupport(concatenateAtomAndInt) at 'x-oz://boot/CompilerSupport'
\ifndef NO_GUMP
   Debug(getRaiseOnBlock setRaiseOnBlock) at 'x-oz://boot/Debug'
   Gump(transformParser transformScanner)
\endif
   System(printName)
   PrintName(downcase)
   Core
   RunTime(procs)
export
   MakeExpressionQuery
   UnnestQuery
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

   fun {LastCoordinatesOf P}
      case P of fAnd(_ S) then {LastCoordinatesOf S}
      [] fAtom(_ C) then C
      [] fVar(_ C) then C
      [] fWildcard(C) then C
      [] fEscape(_ C) then C
      [] fSelf(C) then C
      [] fDollar(C) then C
      [] fInt(_ C) then C
      [] fFloat(_ C) then C
      [] fRecord(L _) then {CoordinatesOf L}
      [] fOpenRecord(L _) then {CoordinatesOf L}
      [] fLocal(_ P _) then {LastCoordinatesOf P}
      else unit
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

\ifndef NO_GUMP
   proc {MyWaitGump X}
      T = {Thread.this}
      RaiseOnBlock = {Debug.getRaiseOnBlock T}
   in
      {Debug.setRaiseOnBlock T false}
      case X of transformScanner then
         {Wait Gump.transformScanner}
      [] transformParser then
         {Wait Gump.transformParser}
      end
      {Debug.setRaiseOnBlock T RaiseOnBlock}
   end
\endif

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

   proc {MakeBoolCase GArbiter GCaseTrue GCaseFalse C NoBoolShared BA
         ?GBoolCase} GT GF in
      GT = {New Core.boolClause init(GCaseTrue)}
      case GCaseFalse of noElse(C) then
         GF = {New Core.noElse init(C)}
      else
         GF = {New Core.elseNode init(GCaseFalse)}
      end
      GBoolCase = {New Core.boolCase init(GArbiter GT GF C)}
      GBoolCase.noBoolShared = NoBoolShared
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

   fun {GroundToOzValue FE Rep}
      case FE of fAtom(A _) then A
      [] fInt(I _) then I
      [] fFloat(F _) then F
      [] fRecord(L As) then
         try ArgCounter in
            ArgCounter = {NewCell 1}
            {List.toRecord L.1
             {Map As
              fun {$ Arg}
                 case Arg of fColon(F E) then
                    {GroundToOzValue F Rep}#{GroundToOzValue E Rep}
                 else N NewN in
                    {Exchange ArgCounter ?N NewN}
                    NewN = N + 1
                    N#{GroundToOzValue Arg Rep}
                 end
              end}}
         catch failure(...) then
            {Rep error(coord: {CoordinatesOf L} kind: ExpansionError
                       msg: 'duplicate feature in record')}
         end
      end
   end

   fun {IsPattern FE}
      %% Returns `true' if FE is a pattern as allowed in case and
      %% catch patterns and in proc/fun heads, else `false'.
      %% (Variables are allowed in label and feature position.)
      case FE of fEq(E1 E2 _) then
         case E1 of fVar(_ _) then {IsPattern E2}
         [] fWildcard(_) then {IsPattern E2}
         elsecase E2 of fVar(_ _) then {IsPattern E1}
         [] fWildcard(_) then {IsPattern E1}
         else false
         end
      [] fAtom(_ _) then true
      [] fVar(_ _) then true
      [] fWildcard(_) then true
      [] fEscape(_ _) then true
      [] fInt(_ _) then true
      [] fFloat(_ _) then true
      [] fRecord(_ As) then   % label is always legal due to syntax rules
         {All As IsPattern}
      [] fOpenRecord(_ As) then   % label is always legal due to syntax rules
         {All As IsPattern}
      [] fColon(_ E) then   % feature is always legal due to syntax rules
         {IsPattern E}
      else false
      end
   end

   fun {EscapePattern FE PrintNames}
      case FE of fEq(E1 E2 C) then
         fEq({EscapePattern E1 PrintNames} {EscapePattern E2 PrintNames} C)
      [] fAtom(_ _) then FE
      [] fVar(PrintName C) then
         if {Member PrintName PrintNames} then fEscape(FE C)
         else FE
         end
      [] fWildcard(_) then FE
      [] fEscape(_ _) then FE
      [] fInt(_ _) then FE
      [] fFloat(_ _) then FE
      [] fRecord(L As) then
         fRecord(L {Map As fun {$ A} {EscapePattern A PrintNames} end})
      [] fOpenRecord(L As) then
         fOpenRecord(L {Map As fun {$ A} {EscapePattern A PrintNames} end})
      [] fColon(F E) then   % feature is always legal due to syntax rules
         fColon(F {EscapePattern E PrintNames})
      end
   end

   fun {IsConstraint FE}
      case FE of fEq(_ _ _) then true
      [] fAtom(_ _) then true
      [] fVar(_ _) then true
      [] fWildcard(_) then true
      [] fEscape(_ _) then true
      [] fInt(_ _) then true
      [] fFloat(_ _) then true
      [] fRecord(_ _) then true
      [] fOpenRecord(_ _) then true
      else false
      end
   end

   proc {SortFunctorDescriptors FDescriptors Rep
         FRequire FPrepare FImport FExport FProp FDefine1 FDefine2}
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
         [] fProp(Ps C) then
            if {IsFree FProp} then FProp = Ps
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `prop\' descriptor '#
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
          FRequire FPrepare FImport FExport FProp FDefine1 FDefine2}
      [] nil then
         if {IsFree FRequire} then FRequire = unit end
         if {IsFree FPrepare} then FPrepare = unit end
         if {IsFree FImport} then FImport = nil end
         if {IsFree FExport} then FExport = nil end
         if {IsFree FProp} then FProp = nil end
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
            GT = {New Core.atomNode init(X C)}
         [] fInt(X C) then
            GEqs = nil
            GT = {New Core.intNode init(X C)}
         [] fFloat(X C) then
            GEqs = nil
            GT = {New Core.floatNode init(X C)}
         else
            Unnester, UnnestToVar(FE Origin ?GEqs ?GT)
         end
      end
      meth UnnestToVar(FE Origin ?GEqs ?GVO)
         case FE of fVar(PrintName C) then
            GEqs = nil
            {@BA refer(PrintName C ?GVO)}
         [] fWildcard(C) then GV in
            GEqs = nil
            {@BA generate('Wildcard' C ?GV)}
            {GV occ(C ?GVO)}
         [] fEscape(FV _) then fVar(PrintName C) = FV in
            GEqs = nil
            {@BA refer(PrintName C ?GVO)}
         [] fGetBinder(FV GV) then fVar(PrintName C) = FV in
            GEqs = nil
            {@BA refer(PrintName C ?GVO)}
            {GVO getVariable(?GV)}
         else NewOrigin C = {CoordinatesOf FE} GV FV in
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
            FV = fVar({GV getPrintName($)} C)
            Unnester, UnnestExpression(FE FV ?GEqs)
            {GV occ(C ?GVO)}
         end
      end
      meth MakeLabelOrFeature(F $)
         case F of fAtom(X C) then
            {New Core.atomNode init(X C)}
         [] fVar(PrintName C) then
            {@BA refer(PrintName C $)}
         [] fInt(X C) then
            {New Core.intNode init(X C)}
         [] fEscape(V _) then   % this case is needed for class attr/feat
            Unnester, MakeLabelOrFeature(V $)
         end
      end
      meth GenerateNewVar(Origin FVs C ?GV)
         {@BA openScope()}
         {ForAll FVs proc {$ fVar(PrintName C)} {@BA bind(PrintName C _)} end}
         {@BA generateForOuterScope(Origin C ?GV)}
         {@BA closeScope(_)}
      end

      meth UnnestStatement(FS $)
         case FS of fStepPoint(FS Kind C) then GS in
            Unnester, UnnestStatement(FS ?GS)
            if {@state getSwitch(debuginfocontrol $)} andthen {IsStep C}
            then {New Core.stepPoint init(GS Kind C)}
            else GS
            end
         [] fAnd(FS1 FS2) then
            Unnester, UnnestStatement(FS1 $)|
            Unnester, UnnestStatement(FS2 $)
         [] fEq(FE1 FE2 C) then
            if {IsStep C} andthen
               {IsConstraint FE1} andthen {IsConstraint FE2}
            then GV1 FV1 GV2 FV2 GFront1 GBack1 GFront2 GBack2 Equation in
               {@BA generate('Left' C ?GV1)}
               FV1 = fVar({GV1 getPrintName($)} C)
               {@BA generate('Left' C ?GV2)}
               FV2 = fVar({GV2 getPrintName($)} C)
               Unnester, UnnestConstraint(FE1 FV1 ?GFront1 ?GBack1)
               Unnester, UnnestConstraint(FE2 FV2 ?GFront2 ?GBack2)
               Unnester, UnnestStatement(fOpApplyStatement('=' [FV1 FV2] C)
                                         ?Equation)
               GFront1|GFront2|Equation|GBack1|GBack2
            else GFront GBack in
               case FE2 of fVar(_ _) then
                  Unnester, UnnestConstraint(FE1 FE2 ?GFront ?GBack)
               elseof fEscape(FV=fVar(_ _) _) then
                  Unnester, UnnestConstraint(FE1 FV ?GFront ?GBack)
               elsecase FE1 of fVar(_ _) then
                  Unnester, UnnestConstraint(FE2 FE1 ?GFront ?GBack)
               elseof fEscape(FV=fVar(_ _) _) then
                  Unnester, UnnestConstraint(FE2 FV ?GFront ?GBack)
               else GV FV in
                  {@BA generate('Equation' C ?GV)}
                  FV = fVar({GV getPrintName($)} C)
                  Unnester, UnnestConstraint(FS FV ?GFront ?GBack)
               end
               GFront|GBack
            end
         [] fAssign(FE1 FE2 C) then
            if @Stateful then
               StateUsed <- true
            else
               {@reporter
                error(coord: C kind: ExpansionError
                      msg: 'attribute assignment used outside of method')}
            end
            Unnester, UnnestStatement(fOpApplyStatement('<-' [FE1 FE2] C) $)
         [] fOpApplyStatement(Op FEs C) then
            GVO GFrontEqs1 GFrontEqs2 GTs GS
         in
            {RunTime.procs.Op occ(C ?GVO)}
            Unnester, UnnestApplyArgs(FEs ?GFrontEqs1 ?GFrontEqs2 ?GTs)
            GS = {New Core.application init(GVO GTs C)}
            GFrontEqs1|GFrontEqs2|GS
         [] fFdCompare(Op FE1 FE2 C) then
            GFrontEq1 NewFE1 GFrontEq2 NewFE2 FS in
            Unnester, UnnestFDExpression(FE1 ?GFrontEq1 ?NewFE1)
            Unnester, UnnestFDExpression(FE2 ?GFrontEq2 ?NewFE2)
            FS = {MakeFdCompareStatement Op NewFE1 NewFE2 C}
            GFrontEq1|GFrontEq2|Unnester, UnnestStatement(FS $)
         [] fFdIn(Op FE1 FE2 C) then Feature CND FS in
            %% note: reverse arguments!
            Feature = case Op of '::' then 'int'
                      [] ':::' then 'dom'
                      end
            CND = {CoordNoDebug C}
            FS = fApply(fOpApply('.' [fVar('FD' C) fAtom(Feature C)] CND)
                        [FE2 FE1] C)
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
            Unnester, UnnestStatement(fOpApplyStatement(',' [FE1 FE2] C) $)
         [] fDollar(C) then
            {@reporter error(coord: C kind: ExpansionError
                             msg: 'illegal use of nesting marker')}
            {New Core.skipNode init(C)}
         [] fApply(FE1 FEs C) then GFrontEq GVO GFrontEqs1 GFrontEqs2 GTs GS in
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
            if N \= 1 andthen LazyFlags \= nil then
               {@reporter
                error(coord: {CoordinatesOf FE1} kind: SyntaxError
                      msg: 'exactly one $ in head of lazy procedure required')}
            elseif N =< 1 then skip
            else
               {@reporter
                error(coord: {DollarCoord FEs} kind: SyntaxError
                      msg: 'at most one $ in procedure head allowed')}
            end
            Unnester, UnnestProc(FEs FS LazyFlags \= nil C ?GS)
            {@BA closeScope(?GFormals)}
            IsStateUsing = @StateUsed
            StateUsed <- IsStateUsing orelse OldStateUsed
            GD = {New Core.definition
                  init(GVO GFormals GS IsStateUsing RestFlags C)}
            if {@state getSwitch(debuginfovarnames $)} then
               {GD setAllVariables({@BA getAllVariables($)})}
            end
            GFrontEq|GD   % Definition node must always be second element!
         [] fFun(FE1 FEs FE2 ProcFlags C) then
            GFrontEq GVO OldStateUsed NewFEs ProcFlagAtoms LazyFlags RestFlags
            GS GFormals IsStateUsing GD
         in
            Unnester, UnnestToVar(FE1 'Fun' ?GFrontEq ?GVO)
            OldStateUsed = (StateUsed <- false)
            ProcFlagAtoms = {Map ProcFlags fun {$ fAtom(A _)} A end}
            {List.partition ProcFlagAtoms fun {$ A} A == 'lazy' end
             ?LazyFlags ?RestFlags}
            {@BA openScope()}
            if {DollarsInScope FEs 0} == 0 then
               NewFEs = {Append FEs [fDollar(C)]}
            else
               {@reporter error(coord: {DollarCoord FEs} kind: SyntaxError
                                msg: 'no $ in function head allowed')}
               NewFEs = FEs
            end
            Unnester, UnnestProc(NewFEs FE2 LazyFlags \= nil C ?GS)
            {@BA closeScope(?GFormals)}
            IsStateUsing = @StateUsed
            StateUsed <- IsStateUsing orelse OldStateUsed
            GD = {New Core.functionDefinition
                  init(GVO GFormals GS IsStateUsing RestFlags C)}
            if {@state getSwitch(debuginfovarnames $)} then
               {GD setAllVariables({@BA getAllVariables($)})}
            end
            GFrontEq|GD   % Definition node must always be second element!
         [] fFunctor(FE FDescriptors C) then
            FRequire FPrepare FImport FExport FProp FDefine1 FDefine2
         in
            {SortFunctorDescriptors FDescriptors @reporter
             ?FRequire ?FPrepare ?FImport ?FExport ?FProp ?FDefine1 ?FDefine2}
            if FRequire == unit andthen FPrepare == unit then
               GFrontEq GVO FV
               ImportGV ImportFV ImportFeatures FImportArgs ImportFS
               FExportArgs FColons CND NewFDefine
               FunGV FunFV FFun OldImportFV OldAdditionalImports GFun
               FImportDesc FExportDesc FS
               GNewFunctor GS
            in
               Unnester, UnnestToVar(FE 'Functor' ?GFrontEq ?GVO)
               FV = fVar({{GVO getVariable($)} getPrintName($)}
                         {CoordinatesOf FE})
               {@BA openScope()}
               Unnester, AnalyseImports(FImport ImportFV
                                        ?ImportFeatures ?FImportArgs ?ImportFS)
               Unnester, AnalyseExports(FExport ?FExportArgs ?FColons)
               {@BA generate('IMPORT' C ?ImportGV)}
               {@BA closeScope(_)}
               ImportFV = fVar({ImportGV getPrintName($)} C)
               CND = {CoordNoDebug C}
               NewFDefine = fLocal(fAnd(ImportFS FDefine1)
                                   fAnd(FDefine2
                                        fRecord(fAtom('export' CND) FColons))
                                   C)
               {@BA generate('Body' C ?FunGV)}
               FunFV = fVar({FunGV getPrintName($)} C)
               FFun = fFun(FunFV [ImportFV] NewFDefine
                           fAtom('instantiate' C)|FProp CND)
               OldImportFV = @CurrentImportFV
               OldAdditionalImports = @AdditionalImports
               CurrentImportFV <- ImportFV
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
               FS = fOpApplyStatement('NewFunctor'
                                      [FImportDesc FExportDesc FunFV FV] CND)
               Unnester, UnnestStatement(FS ?GNewFunctor)
               GS = GFun|GNewFunctor
               GFrontEq|if {@state getSwitch(debuginfocontrol $)}
                           andthen {IsStep C}
                        then {New Core.stepPoint init(GS 'definition' C)}
                        else GS
                        end
            else GV1 GV2 FV1 FV2 FS1 CND BaseURL FS2 in
               {@BA openScope()}
               %--** enter all FRequire/FPrepare variables
               {@BA generate('OuterFunctor' C ?GV1)}
               {@BA generate('InnerFunctor' C ?GV2)}
               {@BA closeScope(_)}
               FV1 = fVar({GV1 getPrintName($)} C)
               FV2 = fVar({GV2 getPrintName($)} C)
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
                                          fAtom(inner unit)] CND) CND)
               Unnester, UnnestStatement(fLocal(FV1 fAnd(FS1 FS2) C) $)
            end
         [] fDoImport(_ GV ImportFV) then
            fVar(PrintName C) = ImportFV DotGVO ImportGVO
            GFrontEqs FeatureGVO ResGVO CND
         in
            {RunTime.procs.'.' occ(C ?DotGVO)}
            {@BA refer(PrintName C ?ImportGVO)}
            Unnester, UnnestToVar(fAtom({GV getPrintName($)} C) 'Feature'
                                  ?GFrontEqs ?FeatureGVO)
            {GV occ(C ?ResGVO)}
            CND = {CoordNoDebug C}
            GFrontEqs|
            {New Core.application
             init(DotGVO [ImportGVO FeatureGVO ResGVO] CND)}
         [] fClass(FE FDescriptors FMeths C) then
            GFrontEq GVO FPrivates GPrivates
            FFrom FProp FAttr FFeat
            GS1 GS2 GS3 GS4 GParents GProps GAttrs
            OldStateful OldStateUsed GFeats GMeths GVs GClass
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
             fun {$ FV} fVar(PrintName C) = FV FS in
                {@BA bind(PrintName C _)}
                FS = fOpApplyStatement('ooPrivate' [FV] C)
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
            GMeths = {Map FMeths
                      fun {$ FMeth} Unnester, UnnestMeth(FMeth $) end}
            Stateful <- OldStateful
            StateUsed <- OldStateUsed
            {@BA closeScope(?GVs)}
            GClass = {New Core.classNode
                      init(GVO GParents GProps GAttrs GFeats GMeths C)}
            GFrontEq|{MakeDeclaration GVs GPrivates|GS1|GS2|GS3|GS4|GClass C}
\ifndef NO_GUMP
         [] fScanner(T Ds Ms Rules Prefix C) then
            From Prop Attr Feat Flags FS Is
         in
            {SortClassDescriptors Ds @reporter ?From ?Prop ?Attr ?Feat}
            Flags = flags(prefix: Prefix
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
            {MyWaitGump transformScanner}
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
                          outputSimplified:
                             {@state
                              getSwitch(gumpparseroutputsimplified $)}
                          verbose:
                             {@state getSwitch(gumpparserverbose $)})
            {MyWaitGump transformParser}
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
                [] fDoImport(FI GV _) then
                   fImportItem(fVar(PrintName C) Fs _) = FI NewFs
                in
                   {@BA bindImport(PrintName C NewFs ?GV)}
                   Unnester, UnnestImportFeatures(Fs ?NewFs)
                end
             end}
            GS = (Unnester, UnnestStatement(NewFS1 $)|
                  Unnester, UnnestStatement(FS2 $))
            {MakeDeclaration {@BA closeScope($)} GS C}
         [] fBoolCase(FE FS1 FS2 C) then Lbl = {Label FE} in
            if {Not {@state getSwitch(debuginfovarnames $)}}
               andthen {Not {@state getSwitch(debuginfocontrol $)}}
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
                  fun {ApplyFalseProc} noElse(C) end
               else GBody GS2 in
                  {@BA openScope()}
                  Unnester, UnnestStatement(FS2 ?GBody)
                  GS2 = {MakeDeclaration {@BA closeScope($)} GBody C}
                  Unnester, MakeClauseBody('FalseCase' GS2 {CoordinatesOf FS2}
                                           ?GSFalseProc ?ApplyFalseProc)
               end
               GSTrueProc|GSFalseProc|GClauseBodies|
               Unnester, UnnestBoolGuard(FE ApplyTrueProc ApplyFalseProc
                                         _ ?GClauseBodies $)
            else GFrontEq GVO GBody GT GF in
               Unnester, UnnestToVar(FE 'BoolGuard' ?GFrontEq ?GVO)
               {@BA openScope()}
               Unnester, UnnestStatement(FS1 ?GBody)
               GT = {MakeDeclaration {@BA closeScope($)} GBody C}
               case FS2 of fNoElse(C) then
                  GF = noElse(C)
               else GBody in
                  {@BA openScope()}
                  Unnester, UnnestStatement(FS2 ?GBody)
                  GF = {MakeDeclaration {@BA closeScope($)} GBody C}
               end
               GFrontEq|{MakeBoolCase GVO GT GF C _ @BA}
            end
         [] fCase(FE FClausess FS C) then GFrontEq GVO NewFClauses in
            Unnester, UnnestToVar(FE 'Arbiter' ?GFrontEq ?GVO)
            %% `elseof' is equivalent to `[]':
            NewFClauses = {FoldR FClausess Append nil}
            GFrontEq|
            Unnester, UnnestCase({GVO getVariable($)} NewFClauses FS C $)
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
         [] fTry(_ FCatch _ _) then
            Unnester, UnnestTry(FS $)
         [] fRaise(FE C) then
            Unnester, UnnestStatement(fOpApplyStatement('Raise' [FE] C) $)
         [] fRaiseWith(FE1 FE2 C) then GFrontEqs GVO FV CND FS in
            Unnester, UnnestToVar(FE1 'Exception' ?GFrontEqs ?GVO)
            FV = fVar({{GVO getVariable($)} getPrintName($)} C)
            CND = {CoordNoDebug C}
            FS = fBoolCase(fOpApply('RaiseDebugCheck' [FV] CND)
                           fOpApplyStatement('RaiseDebugExtend' [FV FE2] C)
                           fOpApplyStatement('Raise' [FV] C) CND)
            GFrontEqs|Unnester, UnnestStatement(FS $)
         [] fSkip(C) then
            {New Core.skipNode init(C)}
         [] fFail(C) then
            {New Core.failNode init(C)}
         [] fNot(FS C) then NewFS in
            NewFS = fThread(fCond([fClause(fSkip(C) FS fFail(C))]
                                  fSkip(C) C) C)
            Unnester, UnnestStatement(NewFS $)
         [] fCond(FClauses FElse C) then GClauses GElse in
            Unnester, UnnestClauses(FClauses fif ?GClauses)
            case FElse of fNoElse(C) then
               GElse = {New Core.noElse init(C)}
            else GS in
               Unnester, UnnestStatement(FElse ?GS)
               GElse = {New Core.elseNode init(GS)}
            end
            {New Core.ifNode init(GClauses GElse C)}
         [] fOr(FClauses Kind C) then GClauses in
            Unnester, UnnestClauses(FClauses Kind ?GClauses)
            case Kind of for then
               {New Core.orNode init(GClauses C)}
            [] fdis then
               {New Core.disNode init(GClauses C)}
            [] fchoice then
               {New Core.choiceNode init(GClauses C)}
            end
         [] fCondis(FClauses C) then GFrontEqCell NewFClauses GS in
            {@BA openScope()}
            GFrontEqCell = {NewCell nil}
            {Map FClauses
             fun {$ FClause}
                {Map FClause
                 fun {$ FS} GFrontEq NewFS GFrontEqs in
                    case FS of fFdCompare(Op FE1 FE2 C) then
                       GFrontEq1 NewFE1 GFrontEq2 NewFE2 in
                       Unnester, UnnestFDExpression(FE1 ?GFrontEq1 ?NewFE1)
                       Unnester, UnnestFDExpression(FE2 ?GFrontEq2 ?NewFE2)
                       GFrontEq = GFrontEq1|GFrontEq2
                       NewFS = fFdCompare(Op NewFE1 NewFE2 C)
                    [] fFdIn(Op FE1 FE2 C) then
                       GFrontEq1 NewFE1 GFrontEq2 GO GV NewFE2 in
                       case Op of '::' then GO GV in
                          Unnester, UnnestToVar(FE1 'UnnestFDIn'
                                                ?GFrontEq1 ?GO)
                          GV = {GO getVariable($)}
                          NewFE1 = fVar({GV getPrintName($)} {GV getCoord($)})
                       [] ':::' then
                          Unnester, UnnestFDList(FE1 ?GFrontEq1 ?NewFE1)
                       end
                       Unnester, UnnestToVar(FE2 'UnnestDomain' ?GFrontEq2 ?GO)
                       GV = {GO getVariable($)}
                       NewFE2 = fVar({GV getPrintName($)} {GV getCoord($)})
                       GFrontEq = GFrontEq1|GFrontEq2
                       NewFS = fFdIn(Op NewFE1 NewFE2 C)
                    end
                    {Exchange GFrontEqCell ?GFrontEqs GFrontEqs|GFrontEq}
                    NewFS
                 end}
             end ?NewFClauses}
            Unnester, UnnestStatement({MakeCondis NewFClauses @BA C} ?GS)
            {MakeDeclaration {@BA closeScope($)} {Access GFrontEqCell}|GS C}
         else C = {CoordinatesOf FS} GV in
            {@reporter error(coord: C kind: SyntaxError
                             msg: 'expression at statement position')}
            {@BA generate('Error' C ?GV)}
            Unnester, UnnestExpression(FS fVar({GV getPrintName($)} C) $)
         end
      end

      meth UnnestExpression(FE FV $) C = {CoordinatesOf FE} in
         case FE of fTypeOf(GV) then fVar(PrintName C) = FV GVO in
            {@BA refer(PrintName C ?GVO)}
            {New Core.typeOf init(GV GVO)}
         [] fStepPoint(FE Kind C) then GS in
            Unnester, UnnestExpression(FE FV ?GS)
            if {@state getSwitch(debuginfocontrol $)} andthen {IsStep C}
            then {New Core.stepPoint init(GS Kind C)}
            else GS
            end
         [] fAnd(FS1 FE2) then
            Unnester, UnnestStatement(FS1 $)|
            Unnester, UnnestExpression(FE2 FV $)
         [] fEq(FE1 FE2 C) then GFront GBack in
            Unnester, UnnestConstraint(FE FV ?GFront ?GBack)
            GFront|GBack
         [] fAssign(FE1 FE2 C) then FApply in
            if @Stateful then
               StateUsed <- true
            else
               {@reporter
                error(coord: C kind: ExpansionError
                      msg: 'attribute exchange used outside of method')}
            end
            FApply = fOpApplyStatement('ooExch' [FE1 FE2 FV] C)
            Unnester, UnnestStatement(FApply $)
         [] fOrElse(FE1 FE2 C) then FS in
            FS = fBoolCase(FE1 fEq(FV fAtom(true C) C) fEq(FV FE2 C) C)
            Unnester, UnnestStatement(FS $)
         [] fAndThen(FE1 FE2 C) then FS in
            FS = fBoolCase(FE1 fEq(FV FE2 C) fEq(FV fAtom(false C) C) C)
            Unnester, UnnestStatement(FS $)
         [] fOpApply(Op FEs C) then
            if {DollarsInScope FEs 0} \= 0 then OpKind in
               OpKind = case FEs of [_] then 'prefix' else 'infix' end
               {@reporter
                error(coord: {DollarCoord FEs} kind: SyntaxError
                      msg: OpKind#' operator cannot take $ as argument')}
            end
            case FE of fOpApply('.' [fVar(X C2) FA=fAtom(Y _)] _) then
               Unnester, OptimizeImportFeature(FV C X C2 Y FA $)
            elseof fOpApply('.' [fVar(X C2) FI=fInt(Y _)] _) then
               Unnester, OptimizeImportFeature(FV C X C2 Y FI $)
            else GVO GFrontEqs1 GFrontEqs2 GTs GS in
               {RunTime.procs.Op occ(C ?GVO)}
               Unnester, UnnestApplyArgs({Append FEs [FV]}
                                         ?GFrontEqs1 ?GFrontEqs2 ?GTs)
               GS = {New Core.application init(GVO GTs C)}
               GFrontEqs1|GFrontEqs2|GS
            end
         [] fUnoptimizedDot(FV2 FT) then
            fVar(X C) = FV2 LeftGVO DotGVO GFrontEqs1 GFrontEqs2 GTs
         in
            {@BA referUnchecked(X C ?LeftGVO)}
            {RunTime.procs.'byNeedDot' occ(C ?DotGVO)}
            Unnester, UnnestApplyArgs([FT FV] ?GFrontEqs1 ?GFrontEqs2 ?GTs)
            GFrontEqs1|GFrontEqs2|
            {New Core.application init(DotGVO LeftGVO|GTs C)}
         [] fFdCompare(Op FE1 FE2 C) then
            GFrontEq1 NewFE1 GFrontEq2 NewFE2 FS in
            Unnester, UnnestFDExpression(FE1 ?GFrontEq1 ?NewFE1)
            Unnester, UnnestFDExpression(FE2 ?GFrontEq2 ?NewFE2)
            FS = {MakeFdCompareExpression Op NewFE1 NewFE2 C FV}
            GFrontEq1|GFrontEq2|Unnester, UnnestStatement(FS $)
         [] fFdIn(Op FE1 FE2 C) then Feature CND FS in
            %% note: reverse arguments!
            Feature = case Op of '::' then 'int'
                      [] ':::' then 'dom'
                      end
            CND = {CoordNoDebug C}
            FS = fApply(fOpApply('.' [fOpApply('.' [fVar('FD' C)
                                                    fAtom('reified' C)] C)
                                      fAtom(Feature C)] CND)
                        [FE2 FE1 FV] C)
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
            NewFE2 = {ReplaceDollar FE2 FV}
            Unnester, UnnestStatement(fOpApplyStatement(',' [FE1 NewFE2] C) $)
         [] fAt(FE C) then
            if @Stateful then
               StateUsed <- true
            else
               {@reporter
                error(coord: C kind: ExpansionError
                      msg: 'attribute access used outside of method')}
            end
            Unnester, UnnestStatement(fOpApplyStatement('@' [FE FV] C) $)
         [] fAtom(X C) then fVar(PrintName VC) = FV GVO in
            {@BA refer(PrintName VC ?GVO)}
            {New Core.equation init(GVO {New Core.atomNode init(X C)} C)}
         [] fVar(PrintName C) then fVar(VPrintName VC) = FV GVO1 GVO2 in
            {@BA refer(VPrintName VC ?GVO1)}
            {@BA refer(PrintName C ?GVO2)}
            {New Core.equation init(GVO1 GVO2 C)}
         [] fWildcard(C) then
            {New Core.skipNode init(C)}
         [] fEscape(FV2 _) then
            Unnester, UnnestExpression(FV2 FV $)
         [] fSelf(C) then fVar(PrintName VC) = FV in
            if @Stateful then
               StateUsed <- true
            else
               {@reporter error(coord: C kind: ExpansionError
                                msg: 'self used outside of method')}
            end
            {New Core.getSelf init({@BA refer(PrintName VC $)} C)}
         [] fDollar(C) then
            {@reporter error(coord: C kind: ExpansionError
                             msg: 'illegal use of nesting marker')}
            {New Core.skipNode init(C)}
         [] fInt(X C) then fVar(PrintName VC) = FV GVO in
            {@BA refer(PrintName VC ?GVO)}
            {New Core.equation init(GVO {New Core.intNode init(X C)} C)}
         [] fFloat(X C) then fVar(PrintName VC) = FV GVO in
            {@BA refer(PrintName VC ?GVO)}
            {New Core.equation init(GVO {New Core.floatNode init(X C)} C)}
         [] fRecord(Label Args) then
            fVar(PrintName C) = FV GVO GV RecordPrintName GRecord GBack
         in
            {@BA refer(PrintName C ?GVO)}
            {GVO getVariable(?GV)}
            RecordPrintName = case {GV getOrigin($)} of generated then ''
                              else PrintName
                              end
            Unnester, UnnestRecord(RecordPrintName Label Args false
                                   ?GRecord ?GBack)
            {New Core.equation init(GVO GRecord C)}|GBack
         [] fOpenRecord(Label Args) then
            fVar(PrintName C) = FV GVO GV RecordPrintName GRecord GBack
         in
            {@BA refer(PrintName C ?GVO)}
            {GVO getVariable(?GV)}
            RecordPrintName = case {GV getOrigin($)} of generated then ''
                              else PrintName
                              end
            Unnester, UnnestRecord(RecordPrintName Label Args true
                                   ?GRecord ?GBack)
            {New Core.equation init(GVO GRecord C)}|GBack
         [] fApply(FE1 FEs C) then N1 N2 in
            N1 = {DollarsInScope FE1 0}
            N2 = {DollarsInScope FEs 0}
            if N1 == 0 andthen N2 == 0 then NewFEs in
               NewFEs = {Append FEs [FV]}
               Unnester, UnnestStatement(fApply(FE1 NewFEs C) $)
            elseif N1 == 0 andthen N2 == 1 then NewFEs in
               NewFEs = {ReplaceDollar FEs FV}
               Unnester, UnnestStatement(fApply(FE1 NewFEs C) $)
            elseif N1 == 1 andthen N2 == 0 then NewFE1 NewFEs in
               NewFE1 = {ReplaceDollar FE1 FV}
               NewFEs = {Append FEs [FV]}
               Unnester, UnnestStatement(fApply(NewFE1 NewFEs C) $)
            else
               {@reporter
                error(coord: {DollarCoord FE1|FEs} kind: ExpansionError
                      msg: ('at most one nesting marker allowed '#
                            'in nested application'))}
               Unnester, UnnestStatement(FE $)
            end
         [] fProc(FE1 FEs FS ProcFlags C) then
            case FE1 of fDollar(_) then
               Unnester, UnnestStatement(fProc(FV FEs FS ProcFlags C) $)
            else
               {@reporter error(coord: {CoordinatesOf FE1} kind: SyntaxError
                                msg: ('nesting marker expected as designator '#
                                      'of nested procedure'))}
               Unnester, UnnestStatement(FE $)
            end
         [] fFun(FE1 FEs FE2 ProcFlags C) then
            case FE1 of fDollar(_) then
               Unnester, UnnestStatement(fFun(FV FEs FE2 ProcFlags C) $)
            else
               {@reporter error(coord: {CoordinatesOf FE1} kind: SyntaxError
                                msg: ('nesting marker expected as designator '#
                                      'of nested function'))}
               Unnester, UnnestStatement(FE $)
            end
         [] fFunctor(FE FDescriptors C) then
            case FE of fDollar(_) then
               Unnester,
               UnnestStatement(fFunctor(FV FDescriptors C) $)
            else
               {@reporter
                error(coord: {CoordinatesOf FE} kind: SyntaxError
                      msg: 'nesting marker expected in nested functor')}
               Unnester, UnnestStatement(FE $)
            end
         [] fClass(FE1 FDescriptors FMeths C) then
            case FE1 of fDollar(_) then
               Unnester, UnnestStatement(fClass(FV FDescriptors FMeths C) $)
            else
               {@reporter
                error(coord: {CoordinatesOf FE1} kind: SyntaxError
                      msg: 'nesting marker expected in nested class')}
               Unnester, UnnestStatement(FE $)
            end
         [] fScanner(FE1 Ds Ms Rules Prefix C) then
            case FE1 of fDollar(_) then
               Unnester, UnnestStatement(fScanner(FV Ds Ms Rules Prefix C) $)
            else
               {@reporter
                error(coord: {CoordinatesOf FE1} kind: SyntaxError
                      msg: 'nesting marker expected in nested scanner class')}
            end
         [] fParser(FE1 Ds Ms Tokens Rules Expect C) then
            case FE1 of fDollar(_) then
               Unnester,
               UnnestStatement(fParser(FV Ds Ms Tokens Rules Expect C) $)
            else
               {@reporter
                error(coord: {CoordinatesOf FE1} kind: SyntaxError
                      msg: 'nesting marker expected in nested parser class')}
            end
         [] fLocal(FS FE C) then fVar(PrintName VC) = FV GVO NewFS FVs in
            {@BA refer(PrintName VC ?GVO)}
            {@BA openScope()}
            NewFS = {MakeTrivialLocalPrefix FS FVs nil}
            if   % is a new temporary needed to avoid name clashes?
               {FoldL FVs fun {$ In FV}
                             case FV of fVar(X C) then
                                {@BA bind(X C _)}
                                {Or In X == PrintName}
                             [] fDoImport(FI GV _) then
                                fImportItem(fVar(X C) Fs _) = FI NewFs
                             in
                                {@BA bindImport(X C NewFs ?GV)}
                                Unnester, UnnestImportFeatures(Fs ?NewFs)
                                {Or In X == PrintName}
                             end
                          end false}
            then NewGV NewFV GS in
               {@BA generateForOuterScope('AntiNameClash' C ?NewGV)}
               NewFV = fVar({NewGV getPrintName($)} C)
               GS = (Unnester, UnnestStatement(NewFS $)|
                     Unnester, UnnestExpression(FE NewFV $))
               {New Core.equation init(GVO {NewGV occ(C $)} C)}|
               {MakeDeclaration {@BA closeScope($)} GS C}
            else GS in
               GS = (Unnester, UnnestStatement(NewFS $)|
                     Unnester, UnnestExpression(FE FV $))
               {MakeDeclaration {@BA closeScope($)} GS C}
            end
         [] fBoolCase(FE1 FE2 FE3 C) then FElse C2 in
            C2 = {LastCoordinatesOf FE2}
            FElse = case FE3 of fNoElse(_) then FE3
                    else fEq(FV FE3 {LastCoordinatesOf FE3})
                    end
            Unnester, UnnestStatement(fBoolCase(FE1 fEq(FV FE2 C2) FElse C) $)
         [] fCase(FE1 FClausess FE2 C) then
            PrintName GFrontEq GVO GV FV2 FClauses FVs FCase NewFV FS
         in
            PrintName = FV.1
            Unnester, UnnestToVar(FE1 'Arbiter' ?GFrontEq ?GVO)
            {GVO getVariable(?GV)}
            FV2 = fVar({GV getPrintName($)} {GV getCoord($)})
            %% `elseof' is equivalent to `[]':
            FClauses = {FoldR FClausess Append nil}
            {FoldL FClauses
             fun {$ FVs fCaseClause(FE _)}
                {GetPatternVariablesExpression FE FVs $}
             end FVs nil}
            FCase = fCase(FV2 [{Map FClauses
                                fun {$ fCaseClause(FE1 FE2)} C in
                                   C = {LastCoordinatesOf FE2}
                                   fCaseClause(FE1 fEq(NewFV FE2 C))
                                end}]
                          case FE2 of fNoElse(_) then FE2
                          else fEq(FV FE2 {LastCoordinatesOf FE2})
                          end C)
            if {Some FVs fun {$ fVar(X _)} X == PrintName end} then NewGV in
               %% use a temporary to avoid name clash
               Unnester, GenerateNewVar(PrintName FVs C ?NewGV)
               NewFV = fVar({NewGV getPrintName($)} C)
               FS = fAnd(fEq(NewFV FV C) FCase)
            else
               NewFV = FV
               FS = FCase
            end
            GFrontEq|Unnester, UnnestStatement(FS $)
         [] fLockThen(FE1 FE2 C) then
            Unnester, UnnestStatement(fLockThen(FE1 fEq(FV FE2 C) C) $)
         [] fLock(FE C) then
            if @Stateful then
               StateUsed <- true
            else
               {@reporter error(coord: C kind: ExpansionError
                                msg: 'object lock used outside of method')}
            end
            Unnester, UnnestStatement(fLock(fEq(FV FE C) C) $)
         [] fThread(FE C) then C2 in
            C2 = {LastCoordinatesOf FE}
            Unnester, UnnestStatement(fThread(fEq(FV FE C2) C) $)
         [] fTry(FE FCatch FFinally C) then GV2 FV2 TryFS in
            {@BA generate('TryResult' C ?GV2)}
            FV2 = fVar({GV2 getPrintName($)} C)
            TryFS = fAnd(fEq(FV2 FE C) fEq(FV FV2 C))
            case FCatch of fNoCatch then
               Unnester, UnnestStatement(fTry(TryFS fNoCatch FFinally C) $)
            [] fCatch(FCaseClauses C2) then FVs PrintName NewFV FS NewFCatch in
               {FoldL FCaseClauses
                fun {$ FVs fCaseClause(FE _)}
                   {GetPatternVariablesExpression FE FVs $}
                end FVs nil}
               PrintName = FV.1
               if {Some FVs fun {$ fVar(X _)} X == PrintName end} then GV in
                  Unnester, GenerateNewVar(PrintName FVs C ?GV)
                  NewFV = fVar({GV getPrintName($)} C)
                  FS = fAnd(fEq(FV NewFV C) fTry(TryFS
                                                 fCatch(NewFCatch C2)
                                                 FFinally C))
               else
                  NewFV = FV
                  FS = fTry(TryFS fCatch(NewFCatch C2) FFinally C)
               end
               NewFCatch = {Map FCaseClauses
                            fun {$ fCaseClause(FE1 FE2)}
                               fCaseClause(FE1 fEq(NewFV FE2 C))
                            end}
               Unnester, UnnestStatement(FS $)
            end
         [] fRaise(_ C) then
            Unnester, UnnestStatement(FE $)
         [] fRaiseWith(_ _ C) then
            Unnester, UnnestStatement(FE $)
         [] fNot(FE C) then
            Unnester, UnnestStatement(fNot(fEq(FV FE C) C) $)
         [] fFail(C) then
            {New Core.failNode init(C)}
         [] fCond(FClauses FE C) then fVar(PrintName _) = FV FVs NewFV FS in
            {FoldL FClauses
             fun {$ FVs fClause(FE _ _)}
                {GetPatternVariablesExpression FE FVs $}
             end FVs nil}
            FS = fCond({Map FClauses
                        fun {$ fClause(FVs FS FE)}
                           fClause(FVs FS fEq(NewFV FE C))
                        end}
                       case FE of fNoElse(_) then FE
                       else fEq(NewFV FE C)
                       end C)
            if {Some FVs fun {$ fVar(X _)} X == PrintName end} then NewGV in
               %% use a temporary to avoid name clash
               Unnester, GenerateNewVar(PrintName FVs C ?NewGV)
               NewFV = fVar({NewGV getPrintName($)} C)
               Unnester, UnnestStatement(fAnd(fEq(NewFV FV C) FS) $)
            else
               NewFV = FV
               Unnester, UnnestStatement(FS $)
            end
         [] fOr(FClauses Kind C) then fVar(PrintName _) = FV FVs NewFV FS in
            {FoldL FClauses
             fun {$ FVs fClause(FE _ _)}
                {GetPatternVariablesExpression FE FVs $}
             end FVs nil}
            FS = fOr({Map FClauses
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
                      end} Kind C)
            if {Some FVs fun {$ fVar(X _)} X == PrintName end} then NewGV in
               %% use a temporary to avoid name clash
               Unnester, GenerateNewVar(PrintName FVs C ?NewGV)
               NewFV = fVar({NewGV getPrintName($)} C)
               Unnester, UnnestStatement(fAnd(fEq(NewFV FV C) FS) $)
            else
               NewFV = FV
               Unnester, UnnestStatement(FS $)
            end
         else
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
               C GV GRecord GBack GEquation GFrontEqr1 GFrontEqr2 GTr
            in
               C = {CoordinatesOf Label}
               {@BA generate('UnnestApply' C ?GV)}
               Unnester, UnnestRecord('' Label Args false ?GRecord ?GBack)
               GFrontEqs1 = GBack|GFrontEqr1
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
      meth UnnestConstraint(FE FV ?GFront ?GBack)
         case FE of fEq(FE1 FE2 _) then GFront1 GBack1 GFront2 GBack2 in
            Unnester, UnnestConstraint(FE1 FV ?GFront1 ?GBack1)
            Unnester, UnnestConstraint(FE2 FV ?GFront2 ?GBack2)
            GFront = GFront1|GFront2
            GBack = GBack1|GBack2
         [] fRecord(Label Args) then
            fVar(PrintName C) = FV GRecord GVO
         in
            Unnester, UnnestRecord(PrintName Label Args false ?GRecord ?GBack)
            {@BA refer(PrintName C ?GVO)}
            GFront = {New Core.equation init(GVO GRecord C)}
         [] fOpenRecord(Label Args) then
            fVar(PrintName C) = FV GVO GRecord GVO
         in
            Unnester, UnnestRecord(PrintName Label Args true ?GRecord ?GBack)
            {@BA refer(PrintName C ?GVO)}
            GFront = {New Core.equation init(GVO GRecord C)}
         [] fVar(_ _) then
            GBack = nil
            Unnester, UnnestExpression(FE FV ?GFront)
         [] fWildcard(_) then
            GFront = nil
            GBack = nil
         [] fEscape(NewFE _) then
            GBack = nil
            Unnester, UnnestExpression(NewFE FV ?GFront)
         [] fAtom(_ _) then
            GBack = nil
            Unnester, UnnestExpression(FE FV ?GFront)
         [] fInt(_ _) then
            GBack = nil
            Unnester, UnnestExpression(FE FV ?GFront)
         [] fFloat(_ _) then
            GBack = nil
            Unnester, UnnestExpression(FE FV ?GFront)
         else
            GFront = nil
            Unnester, UnnestExpression(FE FV ?GBack)
         end
      end
      meth UnnestRecord(PrintName Label Args IsOpen ?GRecord ?GBack)
         GLabel N GArgs NewGArgs X
      in
         Unnester, MakeLabelOrFeature(Label ?GLabel)
         N = {NewCell 1}
         GArgs#GBack =
         {List.foldL Args
          fun {$ GArgs#GBack Arg} FE NewGArgs GArg FeatPrintName in
             case Arg of fColon(FF FE0) then GF in
                Unnester, MakeLabelOrFeature(FF ?GF)
                FE = FE0
                NewGArgs = GF#GArg|GArgs
                FeatPrintName = case FF of fAtom(X _) then {System.printName X}
                                [] fVar(PrintName C) then PrintName
                                [] fInt(X C) then X
                                end
             else
                FE = Arg
                NewGArgs = GArg|GArgs
                FeatPrintName = {Access N}
                {Assign N {Access N} + 1}
             end
             case FE of fEq(_ _ C) then GV FV GFront0 GBack0 in
                {@BA generate('Equation' C ?GV)}
                {GV occ(C ?GArg)}
                FV = fVar({GV getPrintName($)} C)
                Unnester, UnnestConstraint(FE FV ?GFront0 ?GBack0)
                NewGArgs#(GFront0|GBack|GBack0)
             [] fRecord(Label Args) then
                NewPrintName = case PrintName of '' then ''
                               else PrintName#'.'#FeatPrintName
                               end
                GBack0
             in
                Unnester, UnnestRecord(NewPrintName Label Args false
                                       ?GArg ?GBack0)
                NewGArgs#(GBack|GBack0)
             [] fOpenRecord(Label Args) then
                NewPrintName = case PrintName of '' then ''
                               else PrintName#'.'#FeatPrintName
                               end
                GBack0
             in
                Unnester, UnnestRecord(NewPrintName Label Args true
                                       ?GArg ?GBack0)
                NewGArgs#(GBack|GBack0)
             else GBack0 in
                Unnester, UnnestToTerm(FE 'RecordArg' ?GBack0 ?GArg)
                case PrintName of '' then skip
                elsecase {GetLast GBack0} of nil then skip
                elseof GS then
                   {GS setPrintName({VirtualString.toAtom
                                     PrintName#'.'#FeatPrintName})}
                end
                NewGArgs#(GBack|GBack0)
             end
          end nil#nil}
         {SortNoColonsToFront {Reverse GArgs} ?NewGArgs X X nil}
         GRecord = {New Core.construction init(GLabel NewGArgs IsOpen)}
      end

      meth UnnestProc(FEs FS IsLazy C ?GS)
         FGuards FResultVars C2 NewFS FBody0 FBody GBody
      in
         %% each formal argument in FEs must be a basic constraint;
         %% all unnested formal arguments must be pairwise distinct variables
         Unnester, UnnestProcFormals(FEs nil ?FGuards nil ?FResultVars nil)
         C2 = {LastCoordinatesOf FS}
         NewFS = {FoldR FGuards
                  fun {$ FV#FE#C In}
                     fCase(FV [[fCaseClause(FE In)]] fNoElse(C) C)
                  end FS}
         FBody0 = if IsLazy then CND in
                     CND = {CoordNoDebug C}
                     fOpApply('byNeed'
                              [fFun(fDollar(C) nil NewFS nil CND)] CND)
                  else NewFS
                  end
         FBody = {FoldL FResultVars fun {$ FS FV} fEq(FV FS C2) end FBody0}
         {@BA openScope()}
         Unnester, UnnestStatement(FBody ?GBody)
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
               GdHd = fVar({GV getPrintName($)} C)#fEscape(FE C)#C|GdTl
               RtHd = RtTl
            else
               {@BA bind(PrintName C _)}
               NewOccs = PrintName|Occs
               GdHd = GdTl
               RtHd = RtTl
            end
         [] fWildcard(C) then
            {@BA generate('Wildcard' C _)}
            NewOccs = Occs
            GdHd = GdTl
            RtHd = RtTl
         [] fDollar(C) then GV in
            {@BA generate('Result' C ?GV)}
            NewOccs = Occs
            GdHd = GdTl
            RtHd = fVar({GV getPrintName($)} C)|RtTl
         else C GV in
            C = {CoordinatesOf FE}
            if {IsPattern FE} then skip
            else
               {@reporter
                error(coord: C kind: SyntaxError
                      msg: 'only patterns in `proc\'/`fun\' head allowed')}
            end
            {@BA generate('Formal' C ?GV)}
            NewOccs = Occs
            GdHd = (fVar({GV getPrintName($)} C)#{EscapePattern FE Occs}#C|
                    GdTl)
            RtHd = RtTl
         end
      end

      meth AnalyseImports(Ds ImportFV ?ImportFeatures ?FImportArgs ?ImportFS)
         case Ds of D|Dr then
            fImportItem(FV=fVar(PrintName C) Fs FImportAt) = D
            FFsList FS ImportFeaturesr FInfo FImportArgr ImportFS2
         in
            {@BA bind(PrintName C _)}
            Unnester, AnalyseImportFeatures(Fs FV ?FFsList ?FS)
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
            ImportFS = fAnd(fAnd(fDoImport(D _ ImportFV) FS) ImportFS2)
            Unnester, AnalyseImports(Dr ImportFV
                                     ?ImportFeaturesr ?FImportArgr ?ImportFS2)
         [] nil then
            ImportFeatures = nil
            FImportArgs = nil
            ImportFS = fSkip(unit)
         end
      end
      meth AnalyseImportFeatures(Fs FV ?FFsList ?FS)
         case Fs of X|Xr then F FFsListr FSr in
            case X of (FFV=fVar(PrintName C))#F0 then
               {@BA bind(PrintName C _)}
               F = F0
               FS = fAnd(fEq(FFV fUnoptimizedDot(FV F0) unit) FSr)
            else
               F = X
               FS = FSr
            end
            FFsList = fRecord(fAtom('|' unit) [F FFsListr])
            Unnester, AnalyseImportFeatures(Xr FV ?FFsListr ?FSr)
         [] nil then
            FFsList = fAtom(nil unit)
            FS = fSkip(unit)
         end
      end
      meth UnnestImportFeatures(Fs $)
         case Fs of X|Xr then
            case X of fVar(PrintName C)#F then GV in
               {@BA bind(PrintName C ?GV)}
               case F of fAtom(X C) then X#C#_#GV
               [] fInt(I C) then I#C#_#GV
               end
            elsecase X of fAtom(X C) then X#C#_
            [] fInt(I C) then I#C#_
            end|Unnester, UnnestImportFeatures(Xr $)
         [] nil then nil
         end
      end
      meth OptimizeImportFeature(FV C X C2 Y FF $) IsImport LeftGVO in
         {@BA referImport(X C2 Y ?IsImport ?LeftGVO)}
         if {Not IsImport}
            orelse {{LeftGVO getVariable($)} isRestricted($)}
         then DotGVO GFrontEqs1 GFrontEqs2 GTs in
            {RunTime.procs.'.' occ(C ?DotGVO)}
            Unnester, UnnestApplyArgs([FF FV] ?GFrontEqs1 ?GFrontEqs2 ?GTs)
            GFrontEqs1|GFrontEqs2|
            {New Core.application init(DotGVO LeftGVO|GTs C)}
         else fVar(Z C3) = FV RightGVO in
            {@BA refer(Z C3 ?RightGVO)}
            {New Core.equation init(LeftGVO RightGVO C)}
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

      meth UnnestMeth(FMeth ?GMeth)
         fMeth(FHead FP C) = FMeth
         RealFHead GVMsg GLabel FFormals IsOpen N GFormals GBody
      in
         {@BA openScope()}
         case FHead of fEq(FHead2 fVar(PrintName C) _) then
            RealFHead = FHead2
            {@BA bind(PrintName C ?GVMsg)}
         else
            RealFHead = FHead
         end
         Unnester, UnnestMethHead(RealFHead GVMsg ?GLabel ?FFormals ?IsOpen)
         Unnester, UnnestMethFormals1(FFormals GVMsg)
         N = {DollarsInScope FFormals 0}
         ArgCounter <- 1
         if N == 0 then GFormals0 GS1 GS2 in
            Unnester, UnnestMethFormals2(FFormals nil ?GFormals0)
            {@BA openScope()}
            Unnester, UnnestStatement(FP ?GS1)
            Unnester, UnnestMethBody(GVMsg GFormals0 GS1 ?GFormals ?GS2)
            GBody = {MakeDeclaration {@BA closeScope($)} GS2 C}
         else DollarC GV FV NewFFormals GFormals0 GS1 GS2 in
            DollarC = {DollarCoord FFormals}
            if N > 1 then
               {@reporter error(coord: DollarC kind: SyntaxError
                                msg: 'at most one $ in method head allowed')}
            end
            {@BA generate('Result' DollarC ?GV)}
            FV = fVar({GV getPrintName($)} C)
            NewFFormals = {ReplaceDollar FFormals FV}
            Unnester, UnnestMethFormals2(NewFFormals nil ?GFormals0)
            {@BA openScope()}
            Unnester, UnnestExpression(FP FV ?GS1)
            Unnester, UnnestMethBody(GVMsg GFormals0 GS1 ?GFormals ?GS2)
            GBody = {MakeDeclaration {@BA closeScope($)} GS2 C}
         end
         if {@state getSwitch(debuginfocontrol $)} andthen {IsFree GVMsg}
         then
            {@BA generate('Message' C ?GVMsg)}
         end
         {@BA closeScope(_)}
         if {IsFree GVMsg} then
            GMeth = {New Core.method init(GLabel GFormals GBody C)}
         else
            GMeth = {New Core.methodWithDesignator
                     init(GLabel GFormals IsOpen GVMsg GBody C)}
         end
         if {@state getSwitch(debuginfovarnames $)} then
            {GMeth setAllVariables({@BA getAllVariables($)})}
         end
      end
      meth UnnestMethHead(FHead GVMsg ?GLabel ?FFormals ?IsOpen)
         case FHead of fAtom(X C) then
            GLabel = {New Core.atomNode init(X C)}
            FFormals = nil
            IsOpen = false
         [] fVar(PrintName C) then
            {@BA refer(PrintName C ?GLabel)}
            FFormals = nil
            IsOpen = false
         [] fEscape(FV _) then fVar(PrintName C) = FV in
            {@BA refer(PrintName C ?GLabel)}
            FFormals = nil
            IsOpen = false
         [] fRecord(FLabel FArgs) then
            Unnester, UnnestMethHead(FLabel GVMsg ?GLabel _ _)
            FFormals = FArgs
            IsOpen = false
         [] fOpenRecord(FLabel FArgs) then C in
            C = {CoordinatesOf FLabel}
            if {IsFree GVMsg} then
               {@BA generate('Message' C ?GVMsg)}
            end
            Unnester, UnnestMethHead(FLabel GVMsg ?GLabel _ _)
            FFormals = FArgs
            IsOpen = true
         end
      end
      meth UnnestMethFormals1(FFormals GVMsg)
         %% This simply declares all arguments so that their variables
         %% may be used inside features or defaults.
         {ForAll FFormals
          proc {$ FFormal}
             case FFormal of fMethArg(FV _) then
                case FV of fVar(PrintName C) then
                   {@BA bind(PrintName C _)}
                [] fWildcard(_) then skip
                [] fDollar(_) then skip
                end
             [] fMethColonArg(FF FV _) then
                case FF of fVar(_ C) then
                   if {IsFree GVMsg} then
                      {@BA generate('Message' C ?GVMsg)}
                   end
                else skip
                end
                case FV of fVar(PrintName C) then
                   {@BA bind(PrintName C _)}
                [] fWildcard(_) then skip
                [] fDollar(_) then skip
                end
             end
          end}
      end
      meth UnnestMethFormals2(FFormals Occs ?GFormals)
         case FFormals of FA|FAr then GA NewOccs GAr in
            Unnester, UnnestMethFormal(FA Occs ?GA ?NewOccs)
            GFormals = GA|GAr
            Unnester, UnnestMethFormals2(FAr NewOccs ?GAr)
         [] nil then
            GFormals = nil
         end
      end
      meth UnnestMethFormal(FFormal Occs ?GFormal ?NewOccs)
         FF GF GV FDefault PrintName in
         case FFormal of fMethArg(FV FE) then N = @ArgCounter in
            FF = fInt(N {CoordinatesOf FV})
            ArgCounter <- N + 1
            case FV of fVar(PrintName C) then
               {@BA bind(PrintName C ?GV)}
            [] fWildcard(C) then
               {@BA generate('Wildcard' C ?GV)}
            end
            FDefault = FE
         [] fMethColonArg(FF0 FV FE) then
            FF = FF0
            case FV of fVar(PrintName C) then
               {@BA bind(PrintName C ?GV)}
            [] fWildcard(C) then
               {@BA generate('Wildcard' C ?GV)}
            end
            FDefault = FE
         end
         Unnester, MakeLabelOrFeature(FF ?GF)
         PrintName = {GV getPrintName($)}
         if {Member PrintName Occs} then
            {@reporter error(coord: {GV getCoord($)} kind: SyntaxError
                             msg: ('argument variables in method head '#
                                   'must be distinct'))}
            NewOccs = Occs
         else
            NewOccs = PrintName|Occs
         end
         case FDefault of fNoDefault then
            GFormal = {New Core.methFormal init(GF GV)}
         [] fDefault(FE C) then
            case FE of fWildcard(_) then
               GFormal = {New Core.methFormalOptional init(GF GV false)}
            else
               if {IsGround FE} then Val in
                  Val = {GroundToOzValue FE self}
                  GFormal = {New Core.methFormalWithDefault init(GF GV Val)}
               else FV in
                  FV = fVar({GV getPrintName($)} C)
                  GFormal = ({New Core.methFormalOptional init(GF GV true)}#
                             FF#FV#fEq(FV FE C))
               end
            end
         end
      end
      meth UnnestMethBody(GVMsg GFormals0 GS1 ?GFormals ?GS2) FVMsg in
         if {IsDet GVMsg} then
            FVMsg = fVar({GVMsg getPrintName($)} {GVMsg getCoord($)})
         end
         GFormals#GS2 =
         {FoldR GFormals0
          fun {$ GFormal0 GFormals#GS}
             case GFormal0 of GFormal#FF#FV#FS then C FS0 GS0 in
                C = {CoordinatesOf FF}
                if {IsFree GVMsg} then
                   {@BA generateForOuterScope('Message' C ?GVMsg)}
                   FVMsg = fVar({GVMsg getPrintName($)} C)
                end
                FS0 = fBoolCase(fOpApply('hasFeature' [FVMsg FF] C)
                                fEq(FV fOpApply('.' [FVMsg FF] C) C) FS C)
                Unnester, UnnestStatement(FS0 ?GS0)
                (GFormal|GFormals)#(GS0|GS)
             else
                (GFormal0|GFormals)#GS
             end
          end nil#GS1}
      end

      meth UnnestBoolGuard(FE ApplyTrueProc ApplyFalseProc NoBoolShared
                           ?GClauseBodies ?GS)
         %% optimization of `case E1 orelse E2 then S1 else S2 end'
         %% and the like
         case FE of fOrElse(FE1 FE2 C) then
            GClauseBodies1 GElse GClauseBody ApplyElseProc GClauseBodies2
         in
            Unnester, UnnestBoolGuard(FE2 ApplyTrueProc ApplyFalseProc
                                      NoBoolShared ?GClauseBodies1 ?GElse)
            Unnester, MakeClauseBody('FalseCase' GElse C ?GClauseBody
                                     ?ApplyElseProc)
            GClauseBodies = GClauseBodies1|GClauseBody|GClauseBodies2
            Unnester, UnnestBoolGuard(FE1 ApplyTrueProc ApplyElseProc
                                      NoBoolShared ?GClauseBodies2 ?GS)
         [] fAndThen(FE1 FE2 C) then
            GClauseBodies1 GThen GClauseBody ApplyThenProc GClauseBodies2
         in
            Unnester, UnnestBoolGuard(FE2 ApplyTrueProc ApplyFalseProc
                                      NoBoolShared ?GClauseBodies1 ?GThen)
            Unnester, MakeClauseBody('TrueCase' GThen C ?GClauseBody
                                     ?ApplyThenProc)
            GClauseBodies = GClauseBodies1|GClauseBody|GClauseBodies2
            Unnester, UnnestBoolGuard(FE1 ApplyThenProc ApplyFalseProc
                                      NoBoolShared ?GClauseBodies2 ?GS)
         else GFrontEq GVO C GS0 in
            {@BA openScope()}
            Unnester, UnnestToVar(FE 'BoolGuard' ?GFrontEq ?GVO)
            C = {CoordinatesOf FE}
            GClauseBodies = nil
            GS0 = GFrontEq|{MakeBoolCase GVO {ApplyTrueProc} {ApplyFalseProc} C
                            NoBoolShared @BA}
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

      meth UnnestCase(GV FClauses FElse C ?GS) GCs GElse in
         Unnester, UnnestCaseClauses(FClauses ?GCs)
         GS = {New Core.patternCase init({GV occ(C $)} GCs GElse C)}
         case FElse of fNoElse(C) then
            GElse = {New Core.noElse init(C)}
         else GBody0 GBody in
            {@BA openScope()}
            Unnester, UnnestStatement(FElse ?GBody0)
            GBody = {MakeDeclaration {@BA closeScope($)} GBody0
                     {CoordinatesOf FElse}}
            GElse = {New Core.elseNode init(GBody)}
         end
      end
      meth UnnestCaseClauses(FCs ?GCs)
         case FCs of FC|FCr then fCaseClause(FPattern FS) = FC GCr in
            if {IsPattern FPattern} then PatternPNs GPattern GS0 GS GVs in
               {@BA openScope()}
               PatternPNs = {Map {GetPatternVariablesExpression FPattern $ nil}
                             fun {$ fVar(PrintName C)}
                                {@BA bind(PrintName C _)}
                                PrintName
                             end}
               Unnester, TranslatePattern(FPattern PatternPNs true ?GPattern)
               {@BA openScope()}
               Unnester, UnnestStatement(FS ?GS0)
               GS = {MakeDeclaration {@BA closeScope($)} GS0
                     {CoordinatesOf FPattern}}
               {@BA closeScope(?GVs)}
               GCs = {New Core.patternClause init(GVs GPattern GS)}|GCr
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
         %% Precondition: {IsPattern FPattern} == true.
         case FPattern of fEq(FE1 FE2 C) then
            case FE1 of fVar(PrintName C) then GVO GPattern in
               {{@BA refer(PrintName C $)}
                makeIntoPatternVariableOccurrence(?GVO)}
               Unnester, TranslatePattern(FE2 PatternPNs true ?GPattern)
               {New Core.equationPattern init(GVO GPattern C)}
            [] fWildcard(_) then
               Unnester, TranslatePattern(FE2 PatternPNs true $)
            elsecase FE2 of fVar(PrintName C) then GVO GPattern in
               {{@BA refer(PrintName C $)}
                makeIntoPatternVariableOccurrence(?GVO)}
               Unnester, TranslatePattern(FE1 PatternPNs true ?GPattern)
               {New Core.equationPattern init(GVO GPattern C)}
            [] fWildcard(_) then
               Unnester, TranslatePattern(FE1 PatternPNs true $)
            end
         [] fAtom(X C) then
            {New Core.atomNode init(X C)}
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
         [] fWildcard(C) then GV in
            {@BA generate('Wildcard' C ?GV)}
            {{GV occ(C $)} makeIntoPatternVariableOccurrence($)}
         [] fEscape(FV _) then fVar(PrintName C) = FV in
            if {Member PrintName PatternPNs} then
               {{@BA refer(PrintName C $)}
                makeIntoPatternVariableOccurrence($)}
            else
               {@BA refer(PrintName C $)}
            end
         [] fInt(X C) then
            {New Core.intNode init(X C)}
         [] fFloat(X C) then
            {New Core.floatNode init(X C)}
         [] fRecord(L As) then
            Unnester, TranslateRecord(L As false PatternPNs $)
         [] fOpenRecord(L As) then
            Unnester, TranslateRecord(L As true PatternPNs $)
         end
      end
      meth TranslateRecord(L Args IsOpen PatternPNs $)
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
            CND V FV X FX FException NewFS1 NewFS2
         in
            CND = {CoordNoDebug C}
            {@BA generate('ReRaise' C ?V)}
            FV = fVar({V getPrintName($)} C)
            {@BA generate('Exception' C ?X)}
            FX = fVar({X getPrintName($)} C)
            FException = fRecord(fAtom('ex' C) [FX])
            NewFS1 = fTry(fAnd(FS fEq(FV fAtom(unit C) CND))
                          fCatch([fCaseClause(FX fEq(FV FException CND))] CND)
                          fNoFinally C)
            NewFS2 = fCase(FV [[fCaseClause(FException
                                            fOpApplyStatement('Raise' [FX]
                                                              CND))]]
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
            FX = fVar({X getPrintName($)} C)
            case FCaseClauses of [fCaseClause(fVar(_ _) _)] then
               FElse = fNoElse(C2)
            else
               FElse = fOpApplyStatement('Raise' [FX] C2)
            end
            %--** does this work with step points?
            NewC = case C#C2 of pos(_ _ _ F2 L2 C2)#pos(F1 L1 C1) then
                      pos(F1 L1 C1 F2 L2 C2)
                   else C2
                   end
            NewFS = fCase(FX [FCaseClauses] FElse NewC)
            Unnester, UnnestStatement(NewFS ?GCatchBody)
            {@BA closeScope(_)}
            {New Core.tryNode init(GS X GCatchBody C)}
         elseof fTry(FS FCatch FFinally C) then
            Unnester,
            UnnestTry(fTry(fTry(FS FCatch fNoFinally C) fNoCatch FFinally
                           {CoordNoDebug C}) $)
         end
      end

      meth UnnestClauses(FClauses Kind ?GClauses)
         case FClauses of FClause|FClauser then
            FLocals FGuard FBody NewFS FVs GGuard K GBody GCr in
            fClause(FLocals FGuard FBody) = FClause
            {@BA openScope()}
            NewFS = {MakeTrivialLocalPrefix FLocals ?FVs nil}
            {ForAll FVs
             proc {$ fVar(PrintName C)} {@BA bind(PrintName C _)} end}
            GGuard = (Unnester, UnnestStatement(NewFS $)|
                      Unnester, UnnestStatement(FGuard $))
            case FBody of fSkip(C) then
               case Kind of fif then K = ask
               [] for then K = waitTop
               [] fdis then K = waitTop
               [] fchoice then K = wait
               end
               GBody = {New Core.skipNode init(C)}
            [] fNoThen(C) then
               K = waitTop
               GBody = {New Core.skipNode init(C)}
            else GS C = {CoordinatesOf FBody} in
               K = case Kind of fif then ask else wait end
               {@BA openScope()}
               Unnester, UnnestStatement(FBody ?GS)
               GBody = {MakeDeclaration {@BA closeScope($)} GS C}
            end
            GClauses =
            {New Core.clause init({@BA closeScope($)} GGuard K GBody)}|GCr
            Unnester, UnnestClauses(FClauser Kind ?GCr)
         [] nil then
            GClauses = nil
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
               NewFE = fVar({GV getPrintName($)} C)
               Unnester, UnnestExpression(FE NewFE ?GFrontEqs)
            end
         [] fVar(_ _) then
            GFrontEqs = nil
            NewFE = FE
         [] fInt(_ _) then
            GFrontEqs = nil
            NewFE = FE
         else C = {CoordinatesOf FE} GV in
            {@BA generate('UnnestFD' C ?GV)}
            NewFE = fVar({GV getPrintName($)} C)
            Unnester, UnnestExpression(FE NewFE ?GFrontEqs)
         end
      end
      meth UnnestFDList(FE ?GFrontEqs ?NewFE)
         case FE of fRecord(L=fAtom('|' _) [FE1 FE2]) then
            GFrontEq1 GO GFrontEq2 GV NewFE1 NewFE2
         in
            Unnester, UnnestToVar(FE1 'UnnestFDList' ?GFrontEq1 ?GO)
            Unnester, UnnestFDList(FE2 ?GFrontEq2 ?NewFE2)
            GFrontEqs = GFrontEq1|GFrontEq2
            GV = {GO getVariable($)}
            NewFE1 = fVar({GV getPrintName($)} {GV getCoord($)})
            NewFE = fRecord(L [NewFE1 NewFE2])
         [] fAtom('nil' _) then
            GFrontEqs = nil
            NewFE = FE
         else
            {@reporter
             error(coord: {CoordinatesOf FE} kind: SyntaxError
                   msg: ('explicitly given list of variables expected'#
                         'as first argument to `:::\' in a condis clause'))}
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
      fun {MakeExpressionQuery Queries}
         {MakeExpressionQuerySub Queries $ _}
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

      fun {NP P}
         case P of fDeclare(P1 P2 C) then fDeclare({NP P1} {NP P2} C)
         [] fAnd(P1 P2) then fAnd({NP P1} {NP P2})
         [] fEq(P1 P2 C) then fEq({NP P1} {NP P2} C)   %--** {FS C}?
         [] fAssign(P1 P2 C) then fAssign({NP P1} {NP P2} {FS C})
         [] fOrElse(P1 P2 C) then fOrElse({NP P1} {NP P2} C)
         [] fAndThen(P1 P2 C) then fAndThen({NP P1} {NP P2} C)
         [] fOpApply(X Ps C) then fOpApply(X {Map Ps NP} {FS C})
         [] fOpApplyStatement(X Ps C) then
            fOpApplyStatement(X {Map Ps NP} {FS C})
         [] fFdCompare(X P1 P2 C) then fFdCompare(X {NP P1} {NP P2} {FS C})
         [] fFdIn(X P1 P2 C) then fFdIn(X {NP P1} {NP P2} {FS C})
         [] fObjApply(P1 P2 C) then fObjApply({NP P1} {NP P2} {FS C})
         [] fAt(P C) then fAt({NP P} {FS C})
         [] fAtom(_ _) then P
         [] fVar(_ _) then P
         [] fEscape(_ _) then P
         [] fWildcard(_) then P
         [] fSelf(_) then P
         [] fDollar(_) then P
         [] fInt(_ _) then P
         [] fFloat(_ _) then P
         [] fRecord(L As) then fRecord(L {Map As NP})
         [] fOpenRecord(L As) then fOpenRecord(L {Map As NP})
         [] fColon(F P) then fColon(F {NP P})
         [] fApply(P Ps C) then fApply({NP P} {Map Ps NP} {FS C})
         [] fProc(P1 Ps P2 Fs C) then fProc({NP P1} Ps {SP P2} Fs {FS C})
         [] fFun(P1 Ps P2 Fs C) then fFun({NP P1} Ps {SP P2} Fs {FS C})
         [] fFunctor(P1 Ds C) then
            fFunctor({NP P1} {Map Ds NP} {FS C})
         [] fRequire(_ _) then P
         [] fPrepare(P1 P2 C) then fPrepare({SP P1} {SP P2} C)
         [] fImport(_ _) then P
         [] fExport(_ _) then P
         [] fDefine(P1 P2 C) then fDefine({SP P1} {SP P2} C)
         [] fClass(P Ds Ms C) then
            fClass({NP P} {Map Ds NP} {Map Ms SP} {FS C})
         [] fFrom(Ps C) then fFrom({Map Ps NP} C)
         [] fProp(Ps C) then fProp({Map Ps NP} C)
         [] fAttr(Ps C) then fAttr({Map Ps NP} C)
         [] fFeat(Ps C) then fFeat({Map Ps NP} C)
         [] P1#P2 then {NP P1}#{NP P2}
         [] fLocal(P1 P2 C) then fLocal({NP P1} {NP P2} C)
         [] fBoolCase(P1 P2 P3 C) then
            fBoolCase({NP P1} {NP P2} {NP P3} {FS C})
         [] fNoElse(C) then fNoElse({FS C})
         [] fCase(P1 Css P2 C) then
            fCase({NP P1} {Map Css fun {$ Cs} {Map Cs NP} end} {NP P2} {FS C})
         [] fCaseClause(P1 P2) then fCaseClause(P1 {NP P2})
         [] fLockThen(P1 P2 C) then fLockThen({NP P1} {NP P2} {FS C})
         [] fLock(P C) then fLock({NP P} {FS C})
         [] fThread(P C) then fThread({SP P} {FS C})
         [] fTry(P1 P2 P3 C) then fTry({NP P1} {NP P2} {SP P3} {FS C})
         [] fCatch(Cs C) then fCatch({Map Cs NP} {FS C})
         [] fNoCatch then P
         [] fRaise(P C) then fRaise({NP P} {FS C})
         [] fRaiseWith(P1 P2 C) then fRaiseWith({NP P1} {NP P2} {FS C})
         [] fSkip(_) then P
         [] fFail(_) then P
         [] fNot(P C) then fNot({NP P} {FS C})
         [] fCond(Cs P C) then fCond({Map Cs NP} {NP P} {FS C})
         [] fClause(P1 P2 P3) then fClause({NP P1} {NP P2} {NP P3})
         [] fNoThen(_) then P
         [] fOr(Cs X C) then fOr({Map Cs NP} X {FS C})
         [] fCondis(Pss C) then
            fCondis({Map Pss fun {$ Ps} {Map Ps NP} end} {FS C})
         [] fScanner(P1 Ds Ms Rs X C) then
            fScanner({NP P1} {Map Ds NP} {Map Ms SP} {Map Rs SP} X {FS C})
         [] fParser(P1 Ds Ms T Ps X C) then
            fParser({NP P1} {Map Ds NP} {Map Ms SP} T {Map Ps SP} X {FS C})
         end
      end

      fun {SP P}
         case P of fDeclare(P1 P2 C) then NewP1 Vs in
            NewP1 = {MakeTrivialLocalPrefix P1 ?Vs nil}
            fDeclare({VsToFAnd Vs} {SP fAnd(NewP1 P2)} C)
         [] fAnd(P1 P2) then fAnd({SP P1} {SP P2})
         [] fEq(P1 P2 C) then fEq({NP P1} {NP P2} {CS C})
         [] fAssign(P1 P2 C) then fAssign({NP P1} {NP P2} {CS C})
         [] fOrElse(P1 P2 C) then fOrElse({NP P1} {NP P2} C)
         [] fAndThen(P1 P2 C) then fAndThen({NP P1} {NP P2} C)
         [] fOpApply(X Ps C) then fOpApply(X {Map Ps NP} {CS C})
         [] fOpApplyStatement(X Ps C) then
            fOpApplyStatement(X {Map Ps NP} {CS C})
         [] fFdCompare(X P1 P2 C) then fFdCompare(X {NP P1} {NP P2} {CS C})
         [] fFdIn(X P1 P2 C) then fFdIn(X {NP P1} {NP P2} {CS C})
         [] fObjApply(P1 P2 C) then fObjApply({NP P1} {NP P2} {CS C})
         [] fAt(P C) then fAt({NP P} {CS C})
         [] fAtom(X C) then fAtom(X {CS C})
         [] fVar(X C) then fVar(X {CS C})
         [] fEscape(V C) then fEscape(V {CS C})
         [] fWildcard(C) then fWildcard({CS C})
         [] fSelf(C) then fSelf({CS C})
         [] fDollar(C) then fDollar({CS C})
         [] fInt(X C) then fInt(X {CS C})
         [] fFloat(X C) then fFloat(X {CS C})
         [] fRecord(L As) then fRecord({SP L} {Map As NP})
         [] fOpenRecord(L As) then fOpenRecord({SP L} {Map As NP})
         [] fApply(P Ps C) then fApply({NP P} {Map Ps NP} {CS C})
         [] fProc(P1 Ps P2 Fs C) then fProc({NP P1} Ps {SP P2} Fs {CS C})
         [] fFun(P1 Ps P2 Fs C) then fFun({NP P1} Ps {SP P2} Fs {CS C})
         [] fFunctor(P1 Ds C) then
            fFunctor({NP P1} {Map Ds NP} {CS C})
         [] fClass(P Ds Ms C) then
            fClass({NP P} {Map Ds NP} {Map Ms SP} {CS C})
         [] fMeth(X P C) then fMeth(X {SP P} C)
         [] fLocal(P1 P2 C) then NewP1 Vs in
            NewP1 = {MakeTrivialLocalPrefix P1 ?Vs nil}
            fLocal({VsToFAnd Vs} {SP fAnd(NewP1 P2)} C)
         [] fBoolCase(P1 P2 P3 C) then
            fBoolCase({NP P1} {SP P2} {SP P3} {CS C})
         [] fNoElse(C) then fNoElse({CS C})
         [] fCase(P1 Css P2 C) then
            fCase({NP P1} {Map Css fun {$ Cs} {Map Cs SP} end} {SP P2} {CS C})
         [] fCaseClause(P1 P2) then fCaseClause(P1 {SP P2})
         [] fLockThen(P1 P2 C) then fLockThen({NP P1} {SP P2} {CS C})
         [] fLock(P C) then fLock({SP P} {CS C})
         [] fThread(P C) then fThread({SP P} {CS C})
         [] fTry(P1 P2 P3 C) then fTry({SP P1} {SP P2} {SP P3} {CS C})
         [] fCatch(Cs C) then fCatch({Map Cs SP} {CS C})
         [] fNoCatch then P
         [] fNoFinally then P
         [] fRaise(P C) then fRaise({NP P} {CS C})
         [] fRaiseWith(P1 P2 C) then fRaiseWith({NP P1} {NP P2} {CS C})
         [] fSkip(C) then fSkip({CS C})
         [] fFail(C) then fFail({CS C})
         [] fNot(P C) then fNot({SP P} {CS C})
         [] fCond(Cs P C) then fCond({Map Cs SP} {SP P} {CS C})
         [] fClause(P1 P2 P3) then NewP1 Vs in
            NewP1 = {MakeTrivialLocalPrefix P1 ?Vs nil}
            fClause({VsToFAnd Vs} {SP fAnd(NewP1 P2)} {SP P3})
         [] fNoThen(C) then fNoThen({CS C})
         [] fOr(Cs X C) then fOr({Map Cs SP} X {CS C})
         [] fCondis(Pss C) then
            fCondis({Map Pss fun {$ Ps} {Map Ps SP} end} {CS C})
         [] fScanner(P1 Ds Ms Rs X C) then
            fScanner({NP P1} {Map Ds NP} {Map Ms SP} {Map Rs SP} X {CS C})
         [] fMode(V Ms) then fMode(V {Map Ms SP})
         [] fInheritedModes(_) then P
         [] fLexicalAbbreviation(_ _) then P
         [] fLexicalRule(R P) then fLexicalRule(R {SP P})
         [] fParser(P1 Ds Ms T Ps X C) then
            fParser({NP P1} {Map Ds NP} {Map Ms SP} T {Map Ps SP} X {CS C})
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
         end
      end
   in
      proc {UnnestQuery TopLevel Reporter State Query ?GVs ?GS ?FreeGVs}
         O = {New Unnester init(TopLevel Reporter State)}
         Query0 = if {State getSwitch(debuginfocontrol $)} then {SP Query}
                  else Query
                  end
      in
         {O unnestQuery(Query0 ?GVs ?GS ?FreeGVs)}
      end
   end
end
