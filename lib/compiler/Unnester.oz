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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
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

local
   SyntaxError = 'syntax error'
   ExpansionError = 'expansion error'
   ExpansionWarning = 'expansion warning'

   fun {CoordNoDebug Coord}
      case Coord of pos(F L C) then posNoDebug(F L C)
      [] pos(F L C _ _ _) then posNoDebug(F L C)
      else Coord
      end
   end

   fun {GetLast X}
      case X of S1|S2 then Last in
         Last = {GetLast S2}
         case Last == nil then {GetLast S1}
         else Last
         end
      [] nil then nil
      else X
      end
   end

   proc {MyWait X}
      T = {Thread.this}
      RaiseOnBlock = {Thread.getRaiseOnBlock T}
   in
      {Thread.setRaiseOnBlock T false}
      {Wait X}
      {Thread.setRaiseOnBlock T RaiseOnBlock}
   end

   %% The following three functions (DollarsInScope, DollarCoord and
   %% ReplaceDollar) operate on the dollars in pattern position,
   %% corresponding to the definition of GetPatternVariablesExpression.

   fun {DollarsInScope FE I}
      % Returns the number of dollars in pattern position in a given
      % expression.  (FE may also be a list of expressions.)
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
      % Returns the coordinates of the leftmost dollar in pattern
      % position in a given expression, if there is one, else unit.
      % (FE may also be a list of expressions.)
      case FE of fEq(E1 E2 _) then
         case {DollarCoord E1} of unit then {DollarCoord E2}
         elseof C then C
         end
      [] fDollar(C) then
         C
      [] fRecord(_ As) then
         {FoldL As fun {$ In A}
                      case In == unit then {DollarCoord A}
                      else In
                      end
                   end unit}
      [] fOpenRecord(_ As) then
         {FoldL As fun {$ In A}
                      case In == unit then {DollarCoord A}
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
                      case In == unit then {DollarCoord E}
                      else In
                      end
                   end unit}
      else unit
      end
   end

   fun {ReplaceDollar FE FV}
      % Returns an expression in which all dollars (0 or more) in pattern
      % position in an expression are replaced by a given variable.
      % (FE may also be a list of expressions.)
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
      % Given a `local' prefix FS (i. e., S in `local S in P end'),
      % compute its pattern variables and place them in the difference
      % list FVsHd-FVsTl.  Return the statement, from which single
      % variables occurring as statements have been removed.
      case FS of fAnd(S1 S2) then FVsInter in
         fAnd({MakeTrivialLocalPrefix S1 FVsHd FVsInter}
              {MakeTrivialLocalPrefix S2 FVsInter FVsTl})
      [] fVar(_ C) then   % remove single variable
         FVsHd = FS|FVsTl
         fSkip(C)
      [] fWildcard(C) then   % ignore solitary wildcard
         FVsHd = FVsTl
         fSkip(C)
      else
         {GetPatternVariablesStatement FS FVsHd FVsTl}
         FS
      end
   end

   proc {SetExpansionOccs Node BA} Coord in
      {Node getCoord(?Coord)}
      {Record.forAllInd Node.expansionOccs
       proc {$ PrintName GVO}
          {BA referExpansionOcc(PrintName {CoordNoDebug Coord} ?GVO)}
       end}
   end

   fun {MakeDeclaration GVs GS C}
      % If GVs (a list of variables local to statement GS) is empty,
      % return GS, else instantiate a Declaration node.
      case GVs of _|_ then {New Core.declaration init(GVs GS C)}
      else GS
      end
   end

   proc {MakeBoolCase GArbiter GCaseTrue GCaseFalse C NoBoolShared BA
         ?GBoolCase} GT GF in
      GT = {New Core.boolClause init(GCaseTrue)}
      case GCaseFalse of noElse(C) then
         GF = {New Core.noElse init(C)}
         {SetExpansionOccs GF BA}
      else
         GF = {New Core.elseNode init(GCaseFalse)}
      end
      GBoolCase = {New Core.boolCase init(GArbiter GT GF C)}
      GBoolCase.noBoolShared = NoBoolShared
      {SetExpansionOccs GBoolCase BA}
   end

   proc {SortNoColonsToFront Args IHd ITl FHd FTl}
      case Args of Arg|Argr then IInter FInter in
         case Arg of fColon(_ _) then
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
      % Return `true' if FE is a ground term, else `false'.
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
      % Returns `true' if FE is a pattern as allowed in case and
      % catch patterns and in proc/fun heads, else `false'.
      % (Variables are allowed in label and feature position.)
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

   proc {SortClassDescriptors FDescriptors Rep ?FFrom ?FProp ?FAttr ?FFeat}
      case FDescriptors of D|Dr then
         case D of fFrom(Fs C) then
            case {IsFree FFrom} then FFrom = Fs
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `from\' descriptor '#
                                'in class definition'))}
            end
         [] fProp(Ps C) then
            case {IsFree FProp} then FProp = Ps
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `prop\' descriptor '#
                                'in class definition'))}
            end
         [] fAttr(As C) then
            case {IsFree FAttr} then FAttr = As
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `attr\' descriptor '#
                                'in class definition'))}
            end
         [] fFeat(Fs C) then
            case {IsFree FFeat} then FFeat = Fs
            else
               {Rep error(coord: C kind: SyntaxError
                          msg: ('more than one `feat\' descriptor '#
                                'in class definition'))}
            end
         end
         {SortClassDescriptors Dr Rep ?FFrom ?FProp ?FAttr ?FFeat}
      [] nil then
         case {IsFree FFrom} then FFrom = nil else skip end
         case {IsFree FProp} then FProp = nil else skip end
         case {IsFree FAttr} then FAttr = nil else skip end
         case {IsFree FFeat} then FFeat = nil else skip end
      end
   end

   class Unnester
      attr
         BA             % this holds an instance of `BindingAnalysis'
         Stateful       % true iff state access allowed (i. e., in method)
         StateUsed      % true iff state has been accessed
         ArgCounter     % temporarily used while transforming method heads
         reporter
         switches

      meth init(TopLevel Reporter State)
         BA <- {New BindingAnalysis init(TopLevel Reporter)}
         reporter <- Reporter
         switches <- State
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
            GS = {FlattenSequence {MakeDeclaration GVs0 GS0 C}}
            {@BA closeScope(?GVs)}
         else GS0 C = {CoordinatesOf Query} in
            GVs = nil
            {@BA openScope()}
            Unnester, UnnestStatement(Query ?GS0)
            GS = {FlattenSequence {MakeDeclaration {@BA closeScope($)} GS0 C}}
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
         else NewOrigin C = {CoordinatesOf FE} GV FV in
            NewOrigin = case FE of fSelf(_) then 'Self'
                        [] fProc(_ _ _ _ _) then 'Proc'
                        [] fFun(_ _ _ _ _) then 'Fun'
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
         case FS of fAnd(FS1 FS2) then
            Unnester, UnnestStatement(FS1 $)|
            Unnester, UnnestStatement(FS2 $)
         [] fEq(FE1 FE2 C) then GFront GBack in
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
         [] fAssign(FE1 FE2 C) then
            case @Stateful then
               StateUsed <- true
            else
               {@reporter
                error(coord: C kind: ExpansionError
                      msg: 'attribute assignment used outside of method')}
            end
            Unnester, UnnestStatement(fApply(fVar('`<-`' C) [FE1 FE2] C) $)
         [] fFdCompare(Op FE1 FE2 C) then
            GFrontEq1 NewFE1 GFrontEq2 NewFE2 FS in
            Unnester, UnnestFDExpression(FE1 ?GFrontEq1 ?NewFE1)
            Unnester, UnnestFDExpression(FE2 ?GFrontEq2 ?NewFE2)
            FS = {MakeFdCompareStatement Op NewFE1 NewFE2 C}
            GFrontEq1|GFrontEq2|Unnester, UnnestStatement(FS $)
         [] fFdIn(Op FE1 FE2 C) then PrintName FS in
            PrintName = {String.toAtom {VirtualString.toString '`'#Op#'`'}}
            % note: reverse arguments!
            FS = fApply(fVar(PrintName C) [FE2 FE1] C)
            Unnester, UnnestStatement(FS $)
         [] fObjApply(FE1 FE2 C) then
            case @Stateful then
               StateUsed <- true
               case FE1 of fSelf(C) then
                  {@reporter
                   error(coord: C kind: ExpansionError
                         msg: '"self, message" not allowed'
                         body: [hint(l: 'Hint'
                                     m: ('use a class in front of "," '#
                                         'or use "{self message}"'))])}
               else skip
               end
            else
               {@reporter
                error(coord: C kind: ExpansionError
                      msg: 'object application used outside of method')}
            end
            Unnester, UnnestStatement(fApply(fVar('`,`' C) [FE1 FE2] C) $)
         [] fDollar(C) then GV in
            {@reporter error(coord: C kind: ExpansionError
                             msg: 'illegal use of nesting marker')}
            {@BA generate('Error' C ?GV)}
            {GV occ(C $)}
         [] fApply(FE1 FEs C) then GFrontEq GVO GFrontEqs1 GFrontEqs2 GTs GS in
            Unnester, UnnestToVar(FE1 'UnnestApply' ?GFrontEq ?GVO)
            Unnester, UnnestApplyArgs(FEs ?GFrontEqs1 ?GFrontEqs2 ?GTs)
            GS = {New Core.application init(GVO GTs C)}
            GFrontEq|GFrontEqs1|GFrontEqs2|GS
         [] fProc(FE1 FEs FS ProcFlags C) then
            GFrontEq GVO OldStateUsed GS GFormals IsStateUsing GD
         in
            Unnester, UnnestToVar(FE1 'Proc' ?GFrontEq ?GVO)
            OldStateUsed = (StateUsed <- false)
            {@BA openScope()}
            case {DollarsInScope FEs 0} =< 1 then skip
            else
               {@reporter
                error(coord: {DollarCoord FEs} kind: SyntaxError
                      msg: 'at most one $ in procedure head allowed')}
            end
            Unnester, UnnestProc(FEs FS C ?GS)
            {@BA closeScope(?GFormals)}
            IsStateUsing = @StateUsed
            StateUsed <- IsStateUsing orelse OldStateUsed
            GD = {New Core.definition
                  init(GVO GFormals GS IsStateUsing
                       {Map ProcFlags fun {$ fAtom(A _)} A end} C)}
            case {@switches getSwitch(debuginfovarnames $)} then
               {GD setAllVariables({@BA getAllVariables($)})}
            else skip
            end
            {SetExpansionOccs GD @BA}
            GFrontEq|GD   % Definition node must always be second element!
         [] fFun(FE1 FEs FE2 ProcFlags C) then
            GFrontEq GVO OldStateUsed NewFEs ProcFlagAtoms NewFE2
            GS GFormals IsStateUsing GD
         in
            Unnester, UnnestToVar(FE1 'Fun' ?GFrontEq ?GVO)
            OldStateUsed = (StateUsed <- false)
            {@BA openScope()}
            case {DollarsInScope FEs 0} == 0 then
               NewFEs = {Append FEs [fDollar(C)]}
            else
               {@reporter error(coord: {DollarCoord FEs} kind: SyntaxError
                                msg: 'no $ in function head allowed')}
               NewFEs = FEs
            end
            ProcFlagAtoms = {Map ProcFlags fun {$ fAtom(A _)} A end}
            NewFE2 = case {Member 'lazy' ProcFlagAtoms} then
                        fApply(fApply(fVar('`.`' C)
                                      [fVar('Lazy' C) fAtom('apply' C)] C)
                               [fFun(fDollar(C) nil FE2 nil C)] C)
                     else FE2
                     end
            Unnester, UnnestProc(NewFEs NewFE2 C ?GS)
            {@BA closeScope(?GFormals)}
            IsStateUsing = @StateUsed
            StateUsed <- IsStateUsing orelse OldStateUsed
            GD = {New Core.functionDefinition
                  init(GVO GFormals GS IsStateUsing ProcFlagAtoms C)}
            {SetExpansionOccs GD @BA}
            GFrontEq|GD   % Definition node must always be second element!
         [] fClass(FE FDescriptors FMeths C) then
            GFrontEq GVO FPrivates GPrivates
            FFrom FProp FAttr FFeat
            GS1 GS2 GS3 GS4 GParents GProps GAttrs
            OldStateful OldStateUsed GFeats GMeths GVs GClass
         in
            Unnester, UnnestToVar(FE 'Class' ?GFrontEq ?GVO)
            {@BA openScope()}
            % declare private members:
            {SortClassDescriptors FDescriptors @reporter
             ?FFrom ?FProp ?FAttr ?FFeat}
            FPrivates = {FoldR FAttr PrivateAttrFeat
                         {FoldR FFeat PrivateAttrFeat
                          {FoldR FMeths PrivateMeth nil}}}
            {Map {UniqueVariables FPrivates}
             fun {$ FV} fVar(PrintName C) = FV FS in
                {@BA bind(PrintName C _)}
                FS = fApply(fVar('`ooPrivate`' C) [FV] C)
                Unnester, UnnestStatement(FS $)
             end ?GPrivates}
            % unnest the descriptors:
            Unnester, UnnestFromProp(FFrom 'Parent' ?GS1 nil ?GParents nil)
            Unnester, UnnestFromProp(FProp 'Property' ?GS2 nil ?GProps nil)
            Unnester, UnnestAttrFeat(FAttr 'Attribute' ?GS3 nil ?GAttrs nil)
            Unnester, UnnestAttrFeat(FFeat 'Feature' ?GS4 nil ?GFeats nil)
            % transform methods:
            OldStateful = (Stateful <- true)
            OldStateUsed = (StateUsed <- false)
            GMeths = {Map FMeths
                      fun {$ FMeth} Unnester, UnnestMeth(FMeth $) end}
            Stateful <- OldStateful
            StateUsed <- OldStateUsed
            {@BA closeScope(?GVs)}
            GClass = {New Core.classNode
                      init(GVO GParents GProps GAttrs GFeats GMeths C)}
            {SetExpansionOccs GClass @BA}
            GFrontEq|{MakeDeclaration GVs GPrivates|GS1|GS2|GS3|GS4|GClass C}
         [] fScanner(T Ds Ms Rules Prefix C) then
            From Prop Attr Feat Flags FS
         in
            {SortClassDescriptors Ds @reporter ?From ?Prop ?Attr ?Feat}
            Flags = flags(prefix: Prefix
                          bestfit:
                             {@switches getSwitch(gumpscannerbestfit $)}
                          caseless:
                             {@switches getSwitch(gumpscannercaseless $)}
                          nowarn:
                             {@switches getSwitch(gumpscannernowarn $)}
                          backup:
                             {@switches getSwitch(gumpscannerbackup $)}
                          perfreport:
                             {@switches getSwitch(gumpscannerperfreport $)}
                          statistics:
                             {@switches getSwitch(gumpscannerstatistics $)})
            {MyWait Gump}
            FS = {Gump.transformScanner
                  T From Prop Attr Feat Ms Rules C Flags @reporter}
            Unnester, UnnestStatement(FS $)
         [] fParser(T Ds Ms Tokens Rules Expect C) then
            From Prop Attr Feat Flags FS
         in
            {SortClassDescriptors Ds @reporter ?From ?Prop ?Attr ?Feat}
            Flags = flags(expect: Expect
                          outputSimplified:
                             {@switches
                              getSwitch(gumpparseroutputsimplified $)}
                          verbose:
                             {@switches getSwitch(gumpparserverbose $)})
            {MyWait Gump}
            FS = {Gump.transformParser
                  T From Prop Attr Feat Ms Tokens Rules C Flags
                  {@switches getProductionTemplates($)}
                  @reporter}
            Unnester, UnnestStatement(FS $)
         [] fLocal(FS1 FS2 C) then NewFS1 FVs GS in
            {@BA openScope()}
            NewFS1 = {MakeTrivialLocalPrefix FS1 ?FVs nil}
            {ForAll FVs
             proc {$ fVar(PrintName C)} {@BA bind(PrintName C _)} end}
            GS = (Unnester, UnnestStatement(NewFS1 $)|
                  Unnester, UnnestStatement(FS2 $))
            {MakeDeclaration {@BA closeScope($)} GS C}
         [] fBoolCase(FE FS1 FS2 C) then Lbl = {Label FE} in
            case
               {Not {@switches getSwitch(debuginfovarnames $)}}
               andthen ({@switches getSwitch(staticanalysis $)}
                        orelse {Not {@switches getSwitch(codegen $)}})
               % Note:
               % a) debugging information breaks dead code elimination when
               %    sharing code segments with andthen/orelse optimization;
               % b) when not doing value propagation, applications of
               %    ClauseBodies are not recognized
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
         [] fCase(FE FClausess FS C) then GFrontEq GVO in
            Unnester, UnnestToVar(FE 'Arbiter' ?GFrontEq ?GVO)
            GFrontEq|
            Unnester, UnnestCase({GVO getVariable($)} FClausess FS C $)
         [] fLockThen(FE FS C) then GFrontEq GVO GS in
            Unnester, UnnestToVar(FE 'Lock' ?GFrontEq ?GVO)
            Unnester, UnnestStatement(FS ?GS)
            GFrontEq|{New Core.lockNode init(GVO GS C)}
         [] fLock(FS C) then GS GRes in
            case @Stateful then
               StateUsed <- true
            else
               {@reporter error(coord: C kind: ExpansionError
                                msg: 'object lock used outside of method')}
            end
            Unnester, UnnestStatement(FS ?GS)
            GRes = {New Core.objectLockNode init(GS C)}
            {SetExpansionOccs GRes @BA}
            GRes
         [] fThread(FS C) then GBody GS in
            {@BA openScope()}
            Unnester, UnnestStatement(FS ?GBody)
            GS = {MakeDeclaration {@BA closeScope($)} GBody C}
            {New Core.threadNode init(GS C)}
         [] fTry(_ FCatch _ _) then
            Unnester, UnnestTry(FS $)
         [] fRaise(FE C) then
            Unnester, UnnestStatement(fApply(fVar('`Raise`' C) [FE] C) $)
         [] fRaiseWith(FE1 FE2 C) then GFrontEqs GVO FV FS in
            Unnester, UnnestToVar(FE1 'Exception' ?GFrontEqs ?GVO)
            FV = fVar({{GVO getVariable($)} getPrintName($)} C)
            FS = fBoolCase(fApply(fVar('`RaiseDebugCheck`' C) [FV] C)
                           fApply(fVar('`RaiseDebugExtend`' C) [FV FE2] C)
                           fApply(fVar('`Raise`' C) [FV] C) C)
            GFrontEqs|Unnester, UnnestStatement(FS $)
         [] fSkip(C) then
            {New Core.skipNode init(C)}
         [] fFail(C) then
            {New Core.failNode init(C)}
         [] fNot(FS C) then NewFS in
            NewFS = fThread(fIf([fClause(fSkip(C) FS fFail(C))] fSkip(C) C) C)
            Unnester, UnnestStatement(NewFS $)
         [] fIf(FClauses FElse C) then GClauses GElse in
            Unnester, UnnestClauses(FClauses fif ?GClauses)
            case FElse of fNoElse(C) then
               GElse = {New Core.noElse init(C)}
               {SetExpansionOccs GElse @BA}
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

      meth UnnestExpression(FE FV $)
         case FE of fAnd(FS1 FE2) then
            Unnester, UnnestStatement(FS1 $)|
            Unnester, UnnestExpression(FE2 FV $)
         [] fEq(_ _ _) then GFront GBack in
            Unnester, UnnestConstraint(FE FV ?GFront ?GBack)
            GFront|GBack
         [] fAssign(FE1 FE2 C) then FApply in
            case @Stateful then
               StateUsed <- true
            else
               {@reporter
                error(coord: C kind: ExpansionError
                      msg: 'attribute exchange used outside of method')}
            end
            FApply = fApply(fVar('`ooExch`' C) [FE1 FE2 FV] C)
            Unnester, UnnestStatement(FApply $)
         [] fOrElse(FE1 FE2 C) then FS in
            FS = fBoolCase(FE1 fEq(FV fVar('`true`' C) C) fEq(FV FE2 C) C)
            Unnester, UnnestStatement(FS $)
         [] fAndThen(FE1 FE2 C) then FS in
            FS = fBoolCase(FE1 fEq(FV FE2 C) fEq(FV fVar('`false`' C) C) C)
            Unnester, UnnestStatement(FS $)
         [] fOpApply(Op FEs C) then PrintName in
            case {DollarsInScope FEs 0} == 0 then skip
            else OpKind in
               OpKind = case FEs of [_] then 'prefix' else 'infix' end
               {@reporter
                error(coord: {DollarCoord FEs} kind: SyntaxError
                      msg: OpKind#' operator cannot take $ as argument')}
            end
            PrintName = {String.toAtom {VirtualString.toString '`'#Op#'`'}}
            Unnester, UnnestStatement(fApply(fVar(PrintName C)
                                             {Append FEs [FV]} C) $)
         [] fFdCompare(Op FE1 FE2 C) then
            GFrontEq1 NewFE1 GFrontEq2 NewFE2 FS in
            Unnester, UnnestFDExpression(FE1 ?GFrontEq1 ?NewFE1)
            Unnester, UnnestFDExpression(FE2 ?GFrontEq2 ?NewFE2)
            FS = {MakeFdCompareExpression Op NewFE1 NewFE2 C FV}
            GFrontEq1|GFrontEq2|Unnester, UnnestStatement(FS $)
         [] fFdIn(Op FE1 FE2 C) then PrintName FS in
            PrintName = {String.toAtom {VirtualString.toString '`'#Op#'R`'}}
            % note: reverse arguments!
            FS = fApply(fVar(PrintName C) [FE2 FE1 FV] C)
            Unnester, UnnestStatement(FS $)
         [] fObjApply(FE1 FE2 C) then NewFE2 in
            case @Stateful then
               StateUsed <- true
               case {DollarsInScope FE2 0} == 1 then
                  case FE1 of fSelf(C) then
                     {@reporter
                      error(coord: C kind: ExpansionError
                            msg: '"self, message" not allowed'
                            body: [hint(l: 'Hint'
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
            Unnester, UnnestStatement(fApply(fVar('`,`' C) [FE1 NewFE2] C) $)
         [] fAt(FE C) then
            case @Stateful then
               StateUsed <- true
            else
               {@reporter
                error(coord: C kind: ExpansionError
                      msg: 'attribute access used outside of method')}
            end
            Unnester, UnnestStatement(fApply(fVar('`@`' C) [FE FV] C) $)
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
            case @Stateful then
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
            fVar(PrintName C) = FV GVO GV RecordPrintName GFront GRecord GBack
         in
            {@BA refer(PrintName C ?GVO)}
            {GVO getVariable(?GV)}
            RecordPrintName = case {GV getOrigin($)} == generated then ''
                              else PrintName
                              end
            Unnester, UnnestRecord(RecordPrintName Label Args false
                                   ?GFront ?GRecord ?GBack)
            GFront|{New Core.equation init(GVO GRecord C)}|GBack
         [] fOpenRecord(Label Args) then
            fVar(PrintName C) = FV GVO GV RecordPrintName GFront GRecord GBack
         in
            {@BA refer(PrintName C ?GVO)}
            {GVO getVariable(?GV)}
            RecordPrintName = case {GV getOrigin($)} == generated then ''
                              else PrintName
                              end
            Unnester, UnnestRecord(RecordPrintName Label Args true
                                   ?GFront ?GRecord ?GBack)
            GFront|{New Core.equation init(GVO GRecord C)}|GBack
         [] fApply(FE1 FEs C) then N1 N2 in
            N1 = {DollarsInScope FE1 0}
            N2 = {DollarsInScope FEs 0}
            case N1 == 0 andthen N2 == 0 then NewFEs in
               NewFEs = {Append FEs [FV]}
               Unnester, UnnestStatement(fApply(FE1 NewFEs C) $)
            elsecase N1 == 0 andthen N2 == 1 then NewFEs in
               NewFEs = {ReplaceDollar FEs FV}
               Unnester, UnnestStatement(fApply(FE1 NewFEs C) $)
            elsecase N1 == 1 andthen N2 == 0 then NewFE1 NewFEs in
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
            case   % is a new temporary needed to avoid name clashes?
               {Some FVs fun {$ fVar(X C)}
                            {@BA bind(X C _)}
                            X == PrintName
                         end}
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
         [] fBoolCase(FE1 FE2 FE3 C) then FElse in
            FElse = case FE3 of fNoElse(_) then FE3
                    else fEq(FV FE3 C)
                    end
            Unnester, UnnestStatement(fBoolCase(FE1 fEq(FV FE2 C) FElse C) $)
         [] fCase(FE1 FClausess FE2 C) then PrintName GFrontEq GVO GV FV2 FS in
            PrintName = FV.1
            Unnester, UnnestToVar(FE1 'Arbiter' ?GFrontEq ?GVO)
            {GVO getVariable(?GV)}
            FV2 = fVar({GV getPrintName($)} {GV getCoord($)})
            FS = {FoldR FClausess
                  fun {$ FClauses FElse} FVs in
                     {FoldL FClauses
                      fun {$ FVs fCaseClause(FE _)}
                         {GetPatternVariablesExpression FE FVs $}
                      end FVs nil}
                     case {Some FVs fun {$ fVar(X _)} X == PrintName end} then
                        NewGV NewFV in
                        % use a temporary to avoid name clash
                        Unnester, GenerateNewVar(PrintName FVs C ?NewGV)
                        NewFV = fVar({NewGV getPrintName($)} C)
                        fAnd(fEq(NewFV FV C)
                             fCase(FV2 [{Map FClauses
                                         fun {$ fCaseClause(FE1 FE2)}
                                            fCaseClause(FE1 fEq(NewFV FE2 C))
                                         end}] FElse C))
                     else
                        fCase(FV2 [{Map FClauses
                                    fun {$ fCaseClause(FE1 FE2)}
                                       fCaseClause(FE1 fEq(FV FE2 C))
                                    end}] FElse C)
                     end
                  end
                  case FE2 of fNoElse(_) then FE2
                  else fEq(FV FE2 C)
                  end}
            GFrontEq|Unnester, UnnestStatement(FS $)
         [] fLockThen(FE1 FE2 C) then
            Unnester, UnnestStatement(fLockThen(FE1 fEq(FV FE2 C) C) $)
         [] fLock(FE C) then
            case @Stateful then
               StateUsed <- true
            else
               {@reporter error(coord: C kind: ExpansionError
                                msg: 'object lock used outside of method')}
            end
            Unnester, UnnestStatement(fLock(fEq(FV FE C) C) $)
         [] fThread(FE C) then
            Unnester, UnnestStatement(fThread(fEq(FV FE C) C) $)
         [] fTry(FE FCatch FFinally C) then
            case FCatch of fNoCatch then
               Unnester, UnnestStatement(fTry(fEq(FV FE C)
                                              FCatch FFinally C) $)
            [] fCatch(FCaseClauses C2) then FVs PrintName NewFV FS NewFCatch in
               {FoldL FCaseClauses
                fun {$ FVs fCaseClause(FE _)}
                   {GetPatternVariablesExpression FE FVs $}
                end FVs nil}
               PrintName = FV.1
               case {Some FVs fun {$ fVar(X _)} X == PrintName end} then GV in
                  Unnester, GenerateNewVar(PrintName FVs C ?GV)
                  NewFV = fVar({GV getPrintName($)} C)
                  FS = fAnd(fEq(FV NewFV C) fTry(fEq(NewFV FE C)
                                                 fCatch(NewFCatch C2)
                                                 FFinally C))
               else
                  NewFV = FV
                  FS = fTry(fEq(FV FE C) fCatch(NewFCatch C2) FFinally C)
               end
               NewFCatch = {Map FCaseClauses
                            fun {$ fCaseClause(FE1 FE2)}
                               fCaseClause(FE1 fEq(NewFV FE2 C))
                            end}
               Unnester, UnnestStatement(FS $)
            end
         [] fRaise(_ C) then
            Unnester, UnnestStatement(FE $)|
            Unnester, UnnestExpression(fVar('`unit`' C) FV $)
         [] fRaiseWith(_ _ C) then
            Unnester, UnnestStatement(FE $)|
            Unnester, UnnestExpression(fVar('`unit`' C) FV $)
         [] fNot(FE C) then
            Unnester, UnnestStatement(fNot(fEq(FV FE C) C) $)
         [] fIf(FClauses FE C) then fVar(PrintName _) = FV FVs NewFV FS in
            {FoldL FClauses
             fun {$ FVs fClause(FE _ _)}
                {GetPatternVariablesExpression FE FVs $}
             end FVs nil}
            FS = fIf({Map FClauses
                      fun {$ fClause(FVs FS FE)}
                         fClause(FVs FS fEq(NewFV FE C))
                      end}
                     case FE of fNoElse(_) then FE else fEq(NewFV FE C) end C)
            case {Some FVs fun {$ fVar(X _)} X == PrintName end} then
               NewGV NewFV in
               % use a temporary to avoid name clash
               Unnester, GenerateNewVar(PrintName FVs C ?NewGV)
               NewFV = fVar({NewGV getPrintName($)} C)
               Unnester, UnnestStatement(fAnd(fEq(NewFV FV C) FS C) $)
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
            case {Some FVs fun {$ fVar(X _)} X == PrintName end} then
               NewGV NewFV in
               % use a temporary to avoid name clash
               Unnester, GenerateNewVar(PrintName FVs C ?NewGV)
               NewFV = fVar({NewGV getPrintName($)} C)
               Unnester, UnnestStatement(fAnd(fEq(NewFV FV C) FS C) $)
            else
               NewFV = FV
               Unnester, UnnestStatement(FS $)
            end
         else
            {@reporter error(coord: {CoordinatesOf FE} kind: SyntaxError
                             msg: 'statement at expression position')}
            Unnester, UnnestStatement(FE $)
         end
      end

      meth UnnestApplyArgs(FEs ?GFrontEqs1 ?GFrontEqs2 ?GTs)
         case FEs of FE|FEr then
            case FE of fRecord(Label Args) then
               C GV GFront GRecord GBack GEquation GFrontEqr1 GFrontEqr2 GTr
            in
               C = {CoordinatesOf Label}
               {@BA generate('UnnestApply' C ?GV)}
               Unnester, UnnestRecord('' Label Args false
                                      ?GFront ?GRecord ?GBack)
               GFrontEqs1 = GBack|GFrontEqr1
               GEquation = {New Core.equation init({GV occ(C $)} GRecord C)}
               GFrontEqs2 = GFront|GEquation|GFrontEqr2
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
         case FE of fEq(FE1 FE2 _) then
            case FE1 of fWildcard(_) then
               Unnester, UnnestConstraint(FE2 FV ?GFront ?GBack)
            elsecase FE2 of fWildcard(_) then
               Unnester, UnnestConstraint(FE1 FV ?GFront ?GBack)
            else GFront1 GBack1 GFront2 GBack2 in
               Unnester, UnnestConstraint(FE1 FV ?GFront1 ?GBack1)
               Unnester, UnnestConstraint(FE2 FV ?GFront2 ?GBack2)
               GFront = GFront1|GFront2
               GBack = GBack1|GBack2
            end
         [] fRecord(Label Args) then
            fVar(PrintName C) = FV GFront0 GRecord GVO
         in
            Unnester, UnnestRecord(PrintName Label Args false
                                   ?GFront0 ?GRecord ?GBack)
            {@BA refer(PrintName C ?GVO)}
            GFront = GFront0|{New Core.equation init(GVO GRecord C)}
         [] fOpenRecord(Label Args) then
            fVar(PrintName C) = FV GVO GFront0 GRecord GVO
         in
            Unnester, UnnestRecord(PrintName Label Args true
                                   ?GFront0 ?GRecord ?GBack)
            {@BA refer(PrintName C ?GVO)}
            GFront = GFront0|{New Core.equation init(GVO GRecord C)}
         [] fVar(PrintName C) then GVO fVar(PrintName2 C2) = FV GVO2 in
            {@BA refer(PrintName C ?GVO)}
            {@BA refer(PrintName2 C2 ?GVO2)}
            GFront = {New Core.equation init(GVO GVO2 C)}
            GBack = nil
         else
            GFront = nil
            Unnester, UnnestExpression(FE FV ?GBack)
         end
      end
      meth UnnestRecord(PrintName Label Args IsOpen ?GFront ?GRecord ?GBack)
         GLabel NewArgs X GArgs
      in
         Unnester, MakeLabelOrFeature(Label ?GLabel)
         {SortNoColonsToFront Args ?NewArgs X X nil}
         GArgs#GFront#GBack =
         {List.foldRInd NewArgs
          fun {$ I Arg GArgs#GFront#GBack} FE NewGArgs GArg FeatPrintName in
             case Arg of fColon(FF FE0) then GF in
                Unnester, MakeLabelOrFeature(FF ?GF)
                FE = FE0
                NewGArgs = GF#GArg|GArgs
                FeatPrintName = case FF of fAtom(X _) then X
                                [] fVar(PrintName C) then PrintName
                                [] fInt(X C) then X
                                end
             else
                FE = Arg
                NewGArgs = GArg|GArgs
                FeatPrintName = I
             end
             case FE of fRecord(Label Args) then
                NewPrintName = case PrintName == '' then ''
                               else PrintName#'.'#FeatPrintName
                               end
                GFront0 GBack0
             in
                Unnester, UnnestRecord(NewPrintName Label Args false
                                       ?GFront0 ?GArg ?GBack0)
                NewGArgs#(GFront|GFront0)#(GBack|GBack0)
             [] fOpenRecord(Label Args) then
                NewPrintName = case PrintName == '' then ''
                               else PrintName#'.'#FeatPrintName
                               end
                GFront0 GBack0
             in
                Unnester, UnnestRecord(NewPrintName Label Args true
                                       ?GFront0 ?GArg ?GBack0)
                NewGArgs#(GFront0|GFront)#(GBack0|GBack)
             else GBack0 in
                Unnester, UnnestToTerm(FE 'RecordArg' ?GBack0 ?GArg)
                case PrintName == '' then skip
                elsecase {GetLast GBack0} of nil then skip
                elseof GS then
                   {GS setPrintName(PrintName FeatPrintName)}
                end
                NewGArgs#GFront#(GBack0|GBack)
             end
          end nil#nil#nil}
         GRecord = {New Core.construction init(GLabel GArgs IsOpen)}
         {SetExpansionOccs GRecord @BA}
      end

      meth UnnestProc(FEs FS C ?GS) FGuards FResultVars NewFS FBody GBody in
         % each formal argument in FEs must be a basic constraint;
         % all unnested formal arguments must be pairwise distinct variables
         Unnester, UnnestProcFormals(FEs nil ?FGuards nil ?FResultVars nil)
         NewFS = {FoldL FResultVars fun {$ FS FV} fEq(FV FS FV.2) end FS}
         case FGuards of FG1|FGr then FGuard FVs in
            FGuard = {FoldL FGr fun {$ FGuard FS} fAnd(FGuard FS) end FG1}
            % the local variables of the guard are all pattern variables
            % of the head minus the remaining formals:
            {VarListSub
             {Map {@BA getVars($)}   % the coordinates do not matter:
              fun {$ GV} fVar({GV getPrintName($)} _) end}
             {FoldL FEs proc {$ FVsHd FE FVsTl}
                           {GetPatternVariablesExpression FE FVsHd FVsTl}
                        end $ nil}
             ?FVs nil}
            case FVs of FV1|FVr then FLocals in
               FLocals = {FoldL FVr fun {$ X Y} fAnd(X Y) end FV1}
               FBody = fIf([fClause(FLocals FGuard NewFS)] fNoElse(C) C)
            [] nil then
               FBody = fIf([fClause(fSkip(C) FGuard NewFS)] fNoElse(C) C)
            end
         else
            FBody = NewFS
         end
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
            case {Member PrintName Occs} then GV in
               NewOccs = Occs
               {@BA generate('Formal' C ?GV)}
               GdHd = fEq(fVar({GV getPrintName($)} C) FE C)|GdTl
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
            GdHd = GdTl
            RtHd = fVar({GV getPrintName($)} C)|RtTl
         else C GV in
            C = {CoordinatesOf FE}
            case {IsPattern FE} then skip
            else
               {@reporter error(coord: C kind: SyntaxError
                                msg: 'only patterns in proc/fun head allowed')}
            end
            {@BA generate('Formal' C ?GV)}
            NewOccs = Occs
            GdHd = fEq(fVar({GV getPrintName($)} C) FE C)|GdTl
            RtHd = RtTl
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
         case N == 0 then GFormals0 GS1 GS2 in
            Unnester, UnnestMethFormals2(FFormals nil ?GFormals0)
            {@BA openScope()}
            Unnester, UnnestStatement(FP ?GS1)
            Unnester, UnnestMethBody(GVMsg GFormals0 GS1 ?GFormals ?GS2)
            GBody = {MakeDeclaration {@BA closeScope($)} GS2 C}
         else DollarC GV FV NewFFormals GFormals0 GS1 GS2 in
            DollarC = {DollarCoord FFormals}
            case N == 1 then skip
            else
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
         case {@switches getSwitch(debuginfocontrol $)} andthen {IsFree GVMsg}
         then
            {@BA generate('Message' C ?GVMsg)}
         else skip
         end
         {@BA closeScope(_)}
         case {IsFree GVMsg} then
            GMeth = {New Core.method init(GLabel GFormals GBody C)}
         else
            GMeth = {New Core.methodWithDesignator
                     init(GLabel GFormals IsOpen GVMsg GBody C)}
         end
         case {@switches getSwitch(debuginfovarnames $)} then
            {GMeth setAllVariables({@BA getAllVariables($)})}
         else skip
         end
         {SetExpansionOccs GMeth @BA}
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
            case {IsFree GVMsg} then {@BA generate('Message' C ?GVMsg)}
            else skip
            end
            Unnester, UnnestMethHead(FLabel GVMsg ?GLabel _ _)
            FFormals = FArgs
            IsOpen = true
         end
      end
      meth UnnestMethFormals1(FFormals GVMsg)
         % This simply declares all arguments so that their variables
         % may be used inside features or defaults.
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
                   case {IsFree GVMsg} then {@BA generate('Message' C ?GVMsg)}
                   else skip
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
         case {Member PrintName Occs} then
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
            elsecase {IsGround FE} then Val in
               Val = {GroundToOzValue FE self}
               GFormal = {New Core.methFormalWithDefault init(GF GV Val)}
            else FV in
               FV = fVar({GV getPrintName($)} C)
               GFormal = ({New Core.methFormalOptional init(GF GV true)}#
                          FF#FV#fEq(FV FE C))
            end
         end
      end
      meth UnnestMethBody(GVMsg GFormals0 GS1 ?GFormals ?GS2) FVMsg in
         case {IsDet GVMsg} then
            FVMsg = fVar({GVMsg getPrintName($)} {GVMsg getCoord($)})
         else skip
         end
         GFormals#GS2 =
         {FoldR GFormals0
          fun {$ GFormal0 GFormals#GS}
             case GFormal0 of GFormal#FF#FV#FS then C FS0 GS0 in
                C = {CoordinatesOf FF}
                case {IsFree GVMsg} then
                   {@BA generateForOuterScope('Message' C ?GVMsg)}
                   FVMsg = fVar({GVMsg getPrintName($)} C)
                else skip
                end
                FS0 = fBoolCase(fApply(fVar('`hasFeature`' C) [FVMsg FF] C)
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
         % optimization of `case E1 orelse E2 then S1 else S2 end'
         % and the like
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
         {SetExpansionOccs GS @BA}
         fun {ApplyProc}
            {New Core.application init({GV occ(C $)} nil C)}
         end
      end

      meth UnnestCase(GV FClausess FElse C ?GS) FCs FCsr GCs GElse in
         FClausess = FCs|FCsr
         case FCs of [fCaseClause(FX=fVar(_ C) FS)] then FV NewFS in
            %    case Arbiter of X then S1 {elseof ... then Si} [else Sn] end
            % =>
            %    local X in X = Arbiter S1 end
            case FCsr \= nil then
               {@reporter
                warn(coord: C kind: ExpansionWarning
                     msg: 'ignoring clauses following catch-all pattern')}
            elsecase {Label FElse} \= fNoElse then
               {@reporter
                warn(coord: C kind: ExpansionWarning
                     msg: 'ignoring else clause following catch-all pattern')}
            else skip
            end
            FV = fVar({GV getPrintName($)} {GV getCoord($)})
            NewFS = fLocal(FX fAnd(fEq(FX FV C) FS) C)
            Unnester, UnnestStatement(NewFS ?GS)
         else
            Unnester, UnnestCaseClauses(FCs ?GCs)
            GS = {New Core.patternCase init({GV occ(C $)} GCs GElse C)}
            case FCsr of _|_ then GElse0 in
               Unnester, UnnestCase(GV FCsr FElse {CoordNoDebug C} ?GElse0)
               GElse = {New Core.elseNode init(GElse0)}
            [] nil then
               case FElse of fNoElse(C) then
                  GElse = {New Core.noElse init(C)}
                  {SetExpansionOccs GElse @BA}
               else GBody0 GBody in
                  {@BA openScope()}
                  Unnester, UnnestStatement(FElse ?GBody0)
                  GBody = {MakeDeclaration {@BA closeScope($)} GBody0
                           {CoordinatesOf FElse}}
                  GElse = {New Core.elseNode init(GBody)}
               end
            end
         end
      end
      meth UnnestCaseClauses(FCs ?GCs)
         case FCs of FC|FCr then fCaseClause(FPattern FS) = FC GCr in
            case {IsPattern FPattern} then PatternPNs GPattern GS0 GS GVs in
               {@BA openScope()}
               PatternPNs = {Map {GetPatternVariablesExpression FPattern $ nil}
                             fun {$ fVar(PrintName C)}
                                {@BA bind(PrintName C _)}
                                PrintName
                             end}
               Unnester, TranslatePattern(FPattern PatternPNs ?GPattern)
               {@BA openScope()}
               Unnester, UnnestStatement(FS ?GS0)
               GS = {MakeDeclaration {@BA closeScope($)} GS0
                     {CoordinatesOf FPattern}}
               {@BA closeScope(?GVs)}
               GCs = {New Core.patternClause init(GVs GPattern GS)}|GCr
            else
               {@reporter
                error(coord: {CoordinatesOf FPattern} kind: SyntaxError
                      msg: ('only simple patterns in `case\' conditional '#
                            'allowed')
                      body: [hint(l: 'Hint'
                                  m: ('to create a deep guard, use the '#
                                      '`if\' conditional)'))])}
               GCs = GCr
            end
            Unnester, UnnestCaseClauses(FCr ?GCr)
         [] nil then
            GCs = nil
         end
      end
      meth TranslatePattern(FPattern PatternPNs $)
         % Precondition: {IsPattern FPattern} == true.
         case FPattern of fEq(FE1 FE2 C) then
            case FE1 of fVar(PrintName C) then GVO GPattern in
               {{@BA refer(PrintName C $)}
                makeIntoPatternVariableOccurrence(?GVO)}
               Unnester, TranslatePattern(FE2 PatternPNs ?GPattern)
               {New Core.equationPattern init(GVO GPattern C)}
            [] fWildcard(_) then
               Unnester, TranslatePattern(FE2 PatternPNs $)
            elsecase FE2 of fVar(PrintName C) then GVO GPattern in
               {{@BA refer(PrintName C $)}
                makeIntoPatternVariableOccurrence(?GVO)}
               Unnester, TranslatePattern(FE1 PatternPNs ?GPattern)
               {New Core.equationPattern init(GVO GPattern C)}
            [] fWildcard(_) then
               Unnester, TranslatePattern(FE1 PatternPNs $)
            end
         [] fAtom(X C) then
            {New Core.atomNode init(X C)}
         [] fVar(PrintName C) then
            case {Member PrintName PatternPNs} then
               {{@BA refer(PrintName C $)}
                makeIntoPatternVariableOccurrence($)}
            else
               {@BA refer(PrintName C $)}
            end
         [] fWildcard(C) then GV in
            {@BA generate('Wildcard' C ?GV)}
            {{GV occ(C $)} makeIntoPatternVariableOccurrence($)}
         [] fEscape(FV _) then fVar(PrintName C) = FV in
            case {Member PrintName PatternPNs} then
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
      meth TranslateRecord(L Args IsOpen PatternPNs ?GPattern)
         GL NewArgs X GArgs
      in
         Unnester, TranslatePattern(L PatternPNs ?GL)
         {SortNoColonsToFront Args ?NewArgs X X nil}
         GArgs = {Map NewArgs
                  fun {$ Arg}
                     case Arg of fColon(F E) then
                        Unnester, TranslatePattern(F PatternPNs $)#
                        Unnester, TranslatePattern(E PatternPNs $)
                     else
                        Unnester, TranslatePattern(Arg PatternPNs $)
                     end
                  end}
         GPattern = {New Core.recordPattern init(GL GArgs IsOpen)}
         {SetExpansionOccs GPattern @BA}
      end

      meth UnnestTry(FS $)
         case FS of fTry(FS fNoCatch fNoFinally C) then GBody in
            {@BA openScope()}
            Unnester, UnnestStatement(FS ?GBody)
            {MakeDeclaration {@BA closeScope($)} GBody C}
         elseof fTry(FS fNoCatch FFinally C) then
            V FV X FX FException NewFS1 NewFS2
         in
            {@BA generate('ReRaise' C ?V)}
            FV = fVar({V getPrintName($)} C)
            {@BA generate('Exception' C ?X)}
            FX = fVar({X getPrintName($)} C)
            FException = fRecord(fAtom('ex' C) [FX])
            NewFS1 = fTry(fAnd(FS fEq(FV fVar('`unit`' C) C))
                          fCatch([fCaseClause(FX fEq(FV FException C))] C)
                          fNoFinally C)
            NewFS2 = fCase(FV [[fCaseClause(FException
                                            fApply(fVar('`Raise`'
                                                        {CoordNoDebug C})
                                                   [FX] {CoordNoDebug C}))]]
                           fSkip(C) {CoordNoDebug C})
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
               FElse = fNoElse
            else
               FElse = fApply(fVar('`Raise`' {CoordNoDebug C}) [FX] C)
            end
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
               K = case Kind == fif then ask else wait end
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
         % only '+', '-', '*' and '~' may remain as operators;
         % only variables and integers may remain as operands.
         case FE of fOpApply(Op FEs C) then
            case Op == '+' orelse Op == '-' orelse Op == '*' then
               GFrontEqs1 NewFE1 GFrontEqs2 NewFE2
               [FE1 FE2] = FEs in
               Unnester, UnnestFDExpression(FE1 ?GFrontEqs1 ?NewFE1)
               Unnester, UnnestFDExpression(FE2 ?GFrontEqs2 ?NewFE2)
               GFrontEqs = GFrontEqs1|GFrontEqs2
               NewFE = fOpApply(Op [NewFE1 NewFE2] C)
            elsecase Op == '~' then [FE1] = FEs NewFE1 in
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
      case Query of dirHalt then true
      [] dirHelp then true
      [] dirSwitch(_) then true
      [] dirShowSwitches then true
      [] dirPushSwitches then true
      [] dirPopSwitches then true
      [] dirFeed(_) then true
      [] dirThreadedFeed(_) then true
      [] dirCore(_) then true
      [] dirMachine(_) then true
      else false
      end
   end
in
   local
      fun {VariableMember PrintName Vs}
         case Vs of fVar(PrintName0 _)|Vr then
            PrintName == PrintName0 orelse {VariableMember PrintName Vr}
         [] nil then false
         end
      end

      fun {AreDisjointVariableLists Vs1 Vs2}
         case Vs1 of fVar(PrintName _)|Vr then
            case {VariableMember PrintName Vs2} then false
            else {AreDisjointVariableLists Vr Vs2}
            end
         elseof nil then true
         end
      end

      fun {JoinQueriesSub Queries}
         case Queries of Q1|(Qr=Q2|Qrr) then
            case {IsDirective Q1} then
               Q1|{JoinQueriesSub Qr}
            elsecase Q1 of fDeclare(P11 P12 C1) then
               case Q2 of fDeclare(P21 P22 C2) then NewP1 NewP2 Vs1 Vs2 in
                  NewP1 = {MakeTrivialLocalPrefix P11 ?Vs1 nil}
                  NewP2 = {MakeTrivialLocalPrefix P21 ?Vs2 nil}
                  case {AreDisjointVariableLists Vs1 Vs2} then NewQ in
                     NewQ = fDeclare({FoldR {Append Vs1 Vs2}
                                      fun {$ V Rest} fAnd(V Rest) end
                                      fSkip(C1)}
                                     fAnd(NewP1 fAnd(P12 fAnd(NewP2 P22))) C1)
                     {JoinQueriesSub NewQ|Qrr}
                  else
                     Q1|{JoinQueriesSub Qr}
                  end
               else
                  {JoinQueriesSub fDeclare(P11 fAnd(P12 Q2) C1)|Qrr}
               end
            else
               Q1|{JoinQueriesSub Qr}
            end
         else
            Queries
         end
      end
   in
      fun {JoinQueries Queries Reporter} Directives OtherQueries NewQueries in
         {List.takeDropWhile Queries IsDirective ?Directives ?OtherQueries}
         {JoinQueriesSub OtherQueries ?NewQueries}
         case NewQueries of [fDeclare(P1 P2 C)] then
            {Append Directives [fLocal(P1 P2 C)]}
         elseof [FE] then
            {Append Directives NewQueries}
         [] nil then
            Directives
         else
            {Reporter error(kind: ExpansionError
                            msg: ('Ozma only supports at most one query '#
                                  'per input'))}
            Directives
         end
      end
   end

   local
      proc {MakeExpressionQuerySub Qs ?NewQs ?Found}
         case Qs of Q1|Qr then NewQr Found0 in
            {MakeExpressionQuerySub Qr ?NewQr ?Found0}
            case Found0 then
               NewQs = Q1|NewQr
               Found = true
            elsecase {IsDirective Q1} then
               NewQs = Qs
               Found = false
            elsecase Q1 of fDeclare(FS FE C) then
               NewQs = fDeclare(FS fEq(fVar('`result`' unit) FE unit) C)|Qr
               Found = true
            else
               NewQs = fEq(fVar('`result`' unit) Q1 unit)|Qr
               Found = true
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

   proc {UnnestQuery TopLevel Reporter State Query ?GVs ?GS ?FreeGVs}
      O = {New Unnester init(TopLevel Reporter State)}
   in
      {O unnestQuery(Query ?GVs ?GS ?FreeGVs)}
   end
end
