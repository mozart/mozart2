%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
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

local
   AskPrintName = {Type.ask.generic PrintName.is printName}

   proc {File X}
      case X of parseError then skip
      else {ForAll X CompilationUnit}
      end
   end

   proc {CompilationUnit X}
      case X of dirSwitch(Ss) then {ForAll Ss Switch}
      [] dirLocalSwitches then skip
      [] dirPushSwitches then skip
      [] dirPopSwitches then skip
      [] fDeclare(P1 P2 C) then {Phrase P1} {Phrase P2} {Coord C}
      [] fSynTopLevelProductionTemplates(Ts) then
         {ForAll Ts ProdClause}
      else {Phrase X}
      end
   end

   proc {Switch X}
      case X of on(S C) then {Type.ask.atom S} {Coord C}
      [] off(S C) then {Type.ask.atom S} {Coord C}
      end
   end

   proc {Phrase X}
      case X of fStepPoint(P A C) then {Phrase P} {Type.ask.atom A} {Coord C}
      [] fAnd(P1 P2) then {Phrase P1} {Phrase P2}
      [] fEq(P1 P2 C) then {Phrase P1} {Phrase P2} {Coord C}
      [] fAssign(P1 P2 C) then {Phrase P1} {Phrase P2} {Coord C}
      [] fOrElse(P1 P2 C) then {Phrase P1} {Phrase P2} {Coord C}
      [] fAndThen(P1 P2 C) then {Phrase P1} {Phrase P2} {Coord C}
      [] fOpApply(A Ps C) then
         if {IsProcedure A} then skip else {Type.ask.atom A} end
         {ForAll Ps Phrase} {Coord C}
      [] fOpApplyStatement(A Ps C) then
         if {IsProcedure A} then skip else {Type.ask.atom A} end
         {ForAll Ps Phrase} {Coord C}
      [] fObjApply(P1 P2 C) then {Phrase P1} {Phrase P2} {Coord C}
      [] fAt(P C) then {Phrase P} {Coord C}
      [] fAtom(A C) then {Type.ask.literal A} {Coord C}
      [] fVar(V C) then {AskPrintName V} {Coord C}
      [] fEscape(Y C1) then
         case Y of fVar(V C2) then {AskPrintName V} {Coord C2} end {Coord C1}
      [] fWildcard(C) then {Coord C}
      [] fSelf(C) then {Coord C}
      [] fDollar(C) then {Coord C}
      [] fInt(I C) then {Type.ask.int I} {Coord C}
      [] fFloat(F C) then {Type.ask.float F} {Coord C}
      [] fRecord(L RAs) then {Label L} {ForAll RAs RecordArgument}
      [] fOpenRecord(L RAs) then {Label L} {ForAll RAs RecordArgument}
      [] fApply(P Ps C) then {Phrase P} {ForAll Ps Phrase} {Coord C}
      [] fProc(P1 Ps P2 Fs C) then
         {Phrase P1} {ForAll Ps Phrase} {Phrase P2} {ForAll Fs Atom}
         {Coord C}
      [] fFun(P1 Ps P2 Fs C) then
         {Phrase P1} {ForAll Ps Phrase} {Phrase P2} {ForAll Fs Atom}
         {Coord C}
      [] fFunctor(P Fs C) then
         {Phrase P} {ForAll Fs FunctorDescriptor} {Coord C}
      [] fClass(P Cs Ms C) then
         {Phrase P} {ForAll Cs ClassDescriptor} {ForAll Ms Meth} {Coord C}
      [] fLocal(P1 P2 C) then {Phrase P1} {Phrase P2} {Coord C}
      [] fBoolCase(P1 P2 E C) then
         {Phrase P1} {Phrase P2} {OptElse E} {Coord C}
      [] fCase(P Cs E C) then
         {Phrase P} {ForAll Cs CaseClause} {OptElse E} {Coord C}
      [] fLockThen(P1 P2 C) then {Phrase P1} {Phrase P2} {Coord C}
      [] fLock(P C) then {Phrase P} {Coord C}
      [] fThread(P C) then {Phrase P} {Coord C}
      [] fTry(P Ca F C) then {Phrase P} {Catch Ca} {Finally F} {Coord C}
      [] fRaise(P C) then {Phrase P} {Coord C}
      [] fSkip(C) then {Coord C}
      [] fFail(C) then {Coord C}
      [] fNot(P C) then {Phrase P} {Coord C}
      [] fCond(Cs E C) then {ForAll Cs Clause} {OptElse E} {Coord C}
      [] fOr(Cs C) then
         {ForAll Cs ClauseOptThen} {Coord C}
      [] fDis(Cs C) then
         {ForAll Cs ClauseOptThen} {Coord C}
      [] fChoice(Ps C) then
         {ForAll Ps Phrase} {Coord C}
      [] fScanner(V Cs Ms Rs A C) then
         {NakedVariable V}
         {ForAll Cs ClassDescriptor} {ForAll Ms Meth}
         {ForAll Rs ScannerRule}
         {Type.ask.atom A} {Coord C}
      [] fParser(V Cs Ms T Ps I C) then
         {NakedVariable V}
         {ForAll Cs ClassDescriptor} {ForAll Ms Meth}
         {TokenClause T} {ForAll Ps ParserDescriptor}
         {Type.ask.int I} {Coord C}
      [] fLoop(E C) then {Phrase E} {Coord C}
      [] fMacro(Es C) then {ForAll Es Phrase} {Coord C}
      [] fDotAssign(P1 P2 C) then {Phrase P1} {Phrase P2} {Coord C}
      [] fColonEquals(P1 P2 C) then {Phrase P1} {Phrase P2} {Coord C}
      [] fFOR(Ds B C) then {ForAll Ds ForDecl} {Phrase B} {Coord C}
      else {FDExpression X}
      end
   end

   proc {ForDecl D}
      case D
      of forFeature(F E) then {Atom F} {Phrase E}
      [] forPattern(X G) then {Pattern X}
         case G
         of forGeneratorList(E) then {Phrase E}
         [] forGeneratorInt(E1 E2 E3) then
            {Phrase E1} {Phrase E2}
            if E3==unit then skip else {Phrase E3} end
         [] forGeneratorC(E1 E2 E3) then
            {Phrase E1} {Phrase E2}
            if E3==unit then skip else {Phrase E3} end
         end
      end
   end

   proc {Label X}
      case X of fAtom(A C) then {Type.ask.atom A} {Coord C}
      [] fVar(V C) then {AskPrintName V} {Coord C}
      end
   end

   proc {Atom X}
      case X of fAtom(A C) then {Type.ask.atom A} {Coord C} end
   end

   proc {RecordArgument X}
      case X of fColon(F P) then {Feature F} {Phrase P}
      else {Phrase X}
      end
   end

   proc {FunctorDescriptor X}
      case X of fRequire(Is C) then {ForAll Is ImportDecl} {Coord C}
      [] fPrepare(P1 P2 C) then {Phrase P1} {Phrase P2} {Coord C}
      [] fImport(Is C) then {ForAll Is ImportDecl} {Coord C}
      [] fExport(Es C) then {ForAll Es ExportDecl} {Coord C}
      [] fProp(Ps C) then {ForAll Ps Phrase} {Coord C}
      [] fDefine(P1 P2 C) then {Phrase P1} {Phrase P2} {Coord C}
      end
   end

   proc {ImportDecl X}
      case X of fImportItem(fVar(V C) Fs A) then
         {AskPrintName V} {Coord C} {ForAll Fs AliasedFeature} {At A}
      end
   end

   proc {AliasedFeature X}
      case X of fVar(V C)#F then {AskPrintName V} {Coord C} {FeatureNoVar F}
      else {FeatureNoVar X}
      end
   end

   proc {At X}
      case X of fImportAt(A) then {Atom A}
      [] fNoImportAt then skip
      end
   end

   proc {ExportDecl X}
      case X of fExportItem(Y) then
         case Y of fColon(F V) then
            {FeatureNoVar F}
            case V of fVar(V C) then {AskPrintName V} {Coord C} end
         [] fVar(V C) then {AskPrintName V} {Coord C}
         end
      end
   end

   proc {FDExpression X}
      case X of fFdCompare(A P1 P2 C) then
         {Type.ask.atom A} {Phrase P1} {Phrase P2} {Coord C}
      [] fFdIn(A P1 P2 C) then
         {Type.ask.atom A} {Phrase P1} {Phrase P2} {Coord C}
      end
   end

   proc {ClassDescriptor X}
      case X of fFrom(Ps C) then {ForAll Ps Phrase} {Coord C}
      [] fProp(Ps C) then {ForAll Ps Phrase} {Coord C}
      [] fAttr(As C) then {ForAll As AttrFeat} {Coord C}
      [] fFeat(As C) then {ForAll As AttrFeat} {Coord C}
      end
   end

   proc {AttrFeat X}
      case X of F#P then {EscapedFeature F} {Phrase P}
      else {Phrase X}
      end
   end

   proc {Meth X}
      case X of fMeth(H P C) then {MethHead H} {Phrase P} {Coord C} end
   end

   proc {MethHead X}
      case X of fEq(H1 fVar(V C1) C2) then
         {MethHead1 H1} {AskPrintName V} {Coord C1} {Coord C2}
      else {MethHead1 X}
      end
   end

   proc {MethHead1 X}
      case X of fAtom(A C) then {Type.ask.atom A} {Coord C}
      [] fVar(V C) then {AskPrintName V} {Coord C}
      [] fEscape(Y C1) then
         case Y of fVar(V C2) then {AskPrintName V} {Coord C2} end {Coord C1}
      [] fRecord(L RAs) then
         {MethHeadLabel L} {ForAll RAs MethHeadArgument}
      [] fOpenRecord(L RAs) then
         {MethHeadLabel L} {ForAll RAs MethHeadArgument}
      end
   end

   proc {MethHeadLabel X}
      case X of fEscape(fVar(V C1) C2) then
         {AskPrintName V} {Coord C1} {Coord C2}
      else {Label X}
      end
   end

   proc {MethHeadArgument X}
      case X of fMethArg(T D) then {MethHeadTerm T} {Default D}
      [] fMethColonArg(F T D) then {Feature F} {MethHeadTerm T} {Default D}
      end
   end

   proc {MethHeadTerm X}
      case X of fVar(V C) then {AskPrintName V} {Coord C}
      [] fWildcard(C) then {Coord C}
      [] fDollar(C) then {Coord C}
      end
   end

   proc {Default X}
      case X of fNoDefault then skip
      [] fDefault(P C) then {Phrase P} {Coord C}
      end
   end

   proc {Feature X}
      case X of fVar(V C) then {AskPrintName V} {Coord C}
      else {FeatureNoVar X}
      end
   end

   proc {FeatureNoVar X}
      case X of fAtom(A C) then {Type.ask.atom A} {Coord C}
      [] fInt(I C) then {Type.ask.int I} {Coord C}
      end
   end

   proc {EscapedFeature X}
      case X of fEscape(fVar(V C1) C2) then
         {AskPrintName V} {Coord C1} {Coord C2}
      else {Feature X}
      end
   end

   proc {CaseClause X}
      case X of fCaseClause(P1 P2) then {Pattern P1} {Phrase P2} end
   end

   proc {Pattern X}
      case X of fSideCondition(P1 P2 P3 C) then
         {Phrase P1} {Phrase P2} {Phrase P3} {Coord C}
      else {Phrase X}
      end
   end

   proc {Catch X}
      case X of fCatch(Cs C) then {ForAll Cs CaseClause} {Coord C}
      [] fNoCatch then skip
      end
   end

   proc {Finally X}
      case X of fNoFinally then skip
      else {Phrase X}
      end
   end

   proc {Clause X}
      case X of fClause(P1 P2 P3) then {Phrase P1} {Phrase P2} {Phrase P3} end
   end

   proc {ClauseOptThen X}
      case X of fClause(P1 P2 P3) then {Phrase P1} {Phrase P2} {OptThen P3} end
   end

   proc {OptThen X}
      case X of fNoThen(C) then {Coord C}
      else {Phrase X}
      end
   end

   proc {OptElse X}
      case X of fNoElse(C) then {Coord C}
      else {Phrase X}
      end
   end

   proc {NakedVariable X}
      case X of fVar(V C) then {AskPrintName V} {Coord C} end
   end

   proc {GrammarSymbol X}
      case X of fAtom(A C) then {Type.ask.atom A} {Coord C}
      else {NakedVariable X}
      end
   end

   proc {ScannerRule X}
      case X of fMode(V Ms) then
         {NakedVariable V} {ForAll Ms ModeDescriptor}
      else {LexClause X}
      end
   end

   proc {ModeDescriptor X}
      case X of fInheritedModes(Vs) then {ForAll Vs NakedVariable}
      else {LexClause X}
      end
   end

   proc {LexClause X}
      case X of fLexicalAbbreviation(G R) then {GrammarSymbol G} {Regex R}
      [] fLexicalRule(R P) then {Regex R} {Phrase P}
      end
   end

   proc {Regex X}
      {Type.ask.string X}
   end

   proc {TokenClause X}
      case X of fToken(Ds) then {ForAll Ds TokenDecl} end
   end

   proc {TokenDecl X}
      case X of A#P then {Atom A} {Phrase P}
      else {Atom X}
      end
   end

   proc {ParserDescriptor X}
      case X of fProductionTemplate(...) then {ProdClause X}
      else {SyntaxRule X}
      end
   end

   proc {ProdClause X}
      case X of fProductionTemplate(K Fs Rs Es Rs) then
         {ProdKey K} {ForAll Fs ProdParam} {ForAll Rs SyntaxRule}
         {ForAll Es SynExpression} {ForAll Rs ProdRet}
      end
   end

   proc {ProdParam X}
      case X of fWildcard(C) then {Coord C}
      else {NakedVariable X}
      end
   end

   proc {ProdKey X}
      case X of A#S then {Type.ask.atom A} {Type.ask.string S} end
   end

   proc {ProdRet X}
      case X of none then skip
      [] fDollar(C) then {Coord C}
      else {NakedVariable X}
      end
   end

   proc {SyntaxRule X}
      case X of fSyntaxRule(G Fs E) then
         {GrammarSymbol G} {ForAll Fs SynFormal} {SynExpression E}
      end
   end

   proc {SynFormal X}
      case X of fDollar(C) then {Coord C}
      [] fWildcard(C) then {Coord C}
      else {NakedVariable X}
      end
   end

   proc {Variable X}
      case X of fEscape(V C) then {NakedVariable V} {Coord C}
      else {NakedVariable X}
      end
   end

   proc {SynExpression X}
      case X of fSynApplication(G Ps) then {GrammarSymbol G} {ForAll Ps Phrase}
      [] fSynAction(P) then {Phrase P}
      [] fSynSequence(Vs Es) then
         {ForAll Vs NakedVariable} {ForAll Es SynExpression}
      [] fSynAlternative(Es) then {ForAll Es SynExpression}
      [] fSynAssignment(V E) then {Variable V} {SynExpression E}
      [] fSynTemplateInstantiation(K Es C) then
         {ProdKey K} {ForAll Es SynExpression} {Coord C}
      end
   end

   proc {Coord X}
      case X of pos(A I1 I2) then
         {Type.ask.atom A} {Type.ask.int I1} {Type.ask.int I2}
         I1 > 0 = true I2 >= ~1 = true
      [] pos(A1 I1 I2 A2 I3 I4) then
         {Type.ask.atom A1} {Type.ask.int I1} {Type.ask.int I2}
         {Type.ask.atom A2} {Type.ask.int I3} {Type.ask.int I4}
         I1 > 0 = true I2 >= ~1 = true I3 > 0 = true I4 >= ~1 = true
      [] fineStep(A I1 I2) then
         {Type.ask.atom A} {Type.ask.int I1} {Type.ask.int I2}
         I1 > 0 = true I2 >= ~1 = true
      [] fineStep(A1 I1 I2 A2 I3 I4) then
         {Type.ask.atom A1} {Type.ask.int I1} {Type.ask.int I2}
         {Type.ask.atom A2} {Type.ask.int I3} {Type.ask.int I4}
         I1 > 0 = true I2 >= ~1 = true I3 > 0 = true I4 >= ~1 = true
      [] coarseStep(A I1 I2) then
         {Type.ask.atom A} {Type.ask.int I1} {Type.ask.int I2}
         I1 > 0 = true I2 >= ~1 = true
      [] coarseStep(A1 I1 I2 A2 I3 I4) then
         {Type.ask.atom A1} {Type.ask.int I1} {Type.ask.int I2}
         {Type.ask.atom A2} {Type.ask.int I3} {Type.ask.int I4}
         I1 > 0 = true I2 >= ~1 = true I3 > 0 = true I4 >= ~1 = true
      [] unit then skip
      end
   end
in
   proc {CheckTupleSyntax X}
      try {File X}
      catch E then
         case E of error(kernel(noElse _ _) ...) then
            {Exception.raiseError compiler(malformedSyntaxTree)}
         elseof error(kernel(noElse _ _ X) ...) then
            {Exception.raiseError compiler(malformedSyntaxTree X)}
         elseof failure(...) then
            {Exception.raiseError compiler(malformedSyntaxTree)}
         else
            {Raise E}
         end
      end
   end
end
