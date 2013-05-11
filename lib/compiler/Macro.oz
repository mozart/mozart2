functor
export
   MacroExpand1
   MacroExpand
   AugmentMacroEnv
   Defmacro
   MakeVar
   MakeNamedVar
   SequenceToList
   ListToSequence
import
   BootName(newNamed:NewNamedName) at 'x-oz://boot/Name'
   BackquoteMacro(backquoteExpander:BackquoteExpander)
define

   %% macro expansion is performed with respect to an environment
   %% associating macro names to macro expanders.  a macro expander
   %% is a function of 2 arguments: a form and an environment.

   fun {MacroExpandInternal Macro Form Env}
      F = {Dictionary.condGet Env Macro unit}
   in
      if F==unit then raise unknownMacro(Macro Form) end
      else {F Form Env} end
   end

   fun {MacroExpand1 Form Env}
      case Form
        of fMacro(L _) then
         case L of fAtom(Macro _)|_ then
            {MacroExpandInternal Macro Form Env}
         else raise illFormedMacro(Form) end end
      else Form end
   end

   fun {MacroExpand Form Env}
      if {ContainsMacro Form} then
         {FullMacroExpand Form
          if Env==unit then
             GlobalEnvironment
          else Env end}
      else Form end
   end

   %% GLOBAL MACRO ENVIRONMENT

   GlobalEnvironment = {NewDictionary}

   proc {Defmacro Macro Expander}
      {Dictionary.put GlobalEnvironment Macro Expander}
   end

   {Defmacro '`' BackquoteExpander}

   fun {AugmentMacroEnv D R}
      D2 = {Dictionary.clone D}
   in
      {Record.forAllInd R
       proc {$ F V}
          {Dictionary.put D2 F V}
       end}
      D2
   end

   %% CREATING NEW VARIABLES FOR USE IN MACROS

   fun {MakeVar}
      fVar({NewNamedName 'V'} unit)
   end

   fun {MakeNamedVar N}
      fVar({NewNamedName N} unit)
   end


   %% TURNING A LIST OF SYNTAX INTO A SEQUENCE OF SYNTAX

   fun {ListToSequence L}
      case L
      of nil then fSkip(unit)
      [] [H] then H
      [] H|T then fAnd(H {ListToSequence T}) end
   end

   fun {SequenceToList E}
      {Seq2Lst E $ nil}
   end
   proc {Seq2Lst E H T}
      case E
      of fAnd(A B) then M in
         {Seq2Lst A H M}
         {Seq2Lst B M T}
      else H=(E|T) end
   end

   %%

   fun {ContainsMacro E}
      case E
      of fDeclare(P1 P2 _) then
         {ContainsMacro P1} orelse {ContainsMacro P2}
      [] dirSwitch(_) then false
      [] dirPushSwitches then false
      [] dirPopSwitches then false
      [] dirLocalSwitches then false
      [] fStepPoint(P _ _) then {ContainsMacro P}
      [] fAnd(P1 P2) then {ContainsMacro P1} orelse {ContainsMacro P2}
      [] fEq(P1 P2 _) then {ContainsMacro P1} orelse {ContainsMacro P2}
      [] fAssign(P1 P2 _) then {ContainsMacro P1} orelse {ContainsMacro P2}
      [] fOrElse(P1 P2 _) then {ContainsMacro P1} orelse {ContainsMacro P2}
      [] fAndThen(P1 P2 _) then {ContainsMacro P1} orelse {ContainsMacro P2}
      [] fOpApply(_ L _) then {Some L ContainsMacro}
      [] fOpApplyStatement(_ L _) then {Some L ContainsMacro}
      [] fObjApply(P1 P2 _) then {ContainsMacro P1} orelse {ContainsMacro P2}
      [] fAt(P _) then {ContainsMacro P}
      [] fAtom(_ _) then false
      [] fVar(_ _) then false
      [] fAnonVar(_ _ _) then false
      [] fEscape(P _) then {ContainsMacro P}
      [] fWildcard(_) then false
      [] fSelf(_) then false
      [] fDollar(_) then false
      [] fInt(_ _) then false
      [] fFloat(_ _) then false
      [] fColon(_ P) then {ContainsMacro P}
      [] fRecord(Lab L) then {ContainsMacro Lab} orelse {Some L ContainsMacro}
      [] fOpenRecord(Lab L) then {ContainsMacro Lab}
         orelse {Some L ContainsMacro}
      [] fApply(P L _) then {ContainsMacro P} orelse {Some L ContainsMacro}
      [] fProc(P1 L P2 _ _) then
         {ContainsMacro P1} orelse {Some L ContainsMacro}
         orelse {ContainsMacro P2}
      [] fFun(P1 L P2 _ _) then
         {ContainsMacro P1} orelse {Some L ContainsMacro}
         orelse {ContainsMacro P2}
      [] fFunctor(P L _) then {ContainsMacro P} orelse {Some L ContainsMacro}
      [] fRequire(L _) then {Some L ContainsMacro}
      [] fPrepare(P1 P2 _) then {ContainsMacro P1} orelse {ContainsMacro P2}
      [] fImport(L _) then {Some L ContainsMacro}
      [] fExport(L _) then {Some L ContainsMacro}
      [] fDefine(P1 P2 _) then {ContainsMacro P1} orelse {ContainsMacro P2}
      [] fImportItem(_ _ _) then false
      [] fExportItem(_) then false
      [] fClass(P L1 L2 _) then {ContainsMacro P} orelse
         {Some L1 ContainsMacro} orelse {Some L2 ContainsMacro}
      [] fFrom(L _) then {Some L ContainsMacro}
      [] fProp(L _) then {Some L ContainsMacro}
      [] fAttr(L _) then {Some L ContainsMacro}
      [] fFeat(L _) then {Some L ContainsMacro}
      [] fMeth(H P _) then {ContainsMacro H} orelse {ContainsMacro P}
      [] fMethArg(T D) then {ContainsMacro T} orelse {ContainsMacro D}
      [] fNoDefault then false
      [] fDefault(P _) then {ContainsMacro P}
      [] fMethColonArg(F T D) then {ContainsMacro F} orelse
         {ContainsMacro T} orelse {ContainsMacro D}
      [] fLocal(P1 P2 _) then {ContainsMacro P1} orelse {ContainsMacro P2}
      [] fBoolCase(P1 P2 E _) then {ContainsMacro P1} orelse
         {ContainsMacro P2} orelse {ContainsMacro E}
      [] fNoElse(_) then false
      [] fCase(P L E _) then {ContainsMacro P} orelse {Some L ContainsMacro}
         orelse {ContainsMacro E}
      [] fCaseClause(P1 P2) then {ContainsMacro P1} orelse {ContainsMacro P2}
      [] fSideCondition(P1 P2 P3) then {ContainsMacro P1} orelse
         {ContainsMacro P2} orelse {ContainsMacro P3}
      [] fLockThen(P1 P2 _) then {ContainsMacro P1} orelse {ContainsMacro P2}
      [] fLock(P _) then {ContainsMacro P}
      [] fThread(P _) then {ContainsMacro P}
      [] fTry(P Ca Fi _) then {ContainsMacro P} orelse {ContainsMacro Ca}
         orelse {ContainsMacro Fi}
      [] fNoCatch then false
      [] fCatch(L _) then {Some L ContainsMacro}
      [] fNoFinally then false
      [] fRaise(P _) then {ContainsMacro P}
      [] fSkip(_) then false
      [] fFdCompare(_ P1 P2 _) then {ContainsMacro P1}
         orelse {ContainsMacro P2}
      [] fFdIn(_ P1 P2 _) then {ContainsMacro P1} orelse {ContainsMacro P2}
      [] fFail(_) then false
      [] fNot(P _) then {ContainsMacro P}
      [] fCond(L E _) then {Some L ContainsMacro} orelse {ContainsMacro E}
      [] fClause(P1 P2 P3) then {ContainsMacro P1} orelse
         {ContainsMacro P2} orelse {ContainsMacro P3}
      [] fNoThen(_) then false
      [] fOr(L _) then {Some L ContainsMacro}
      [] fDis(L _) then {Some L ContainsMacro}
      [] fChoice(L _) then {Some L ContainsMacro}
      [] fSynTopLevelProductionTemplates(L) then {Some L ContainsMacro}
      [] fProductionTemplate(_ Params Rules Es Rets) then
         {Some Params ContainsMacro} orelse
         {Some Rules ContainsMacro} orelse
         {Some Es ContainsMacro} orelse
         {Some Rets ContainsMacro}
      [] fSyntaxRule(S L E) then {ContainsMacro S} orelse
         {Some L ContainsMacro} orelse {ContainsMacro E}
      [] fSynApplication(S L) then {ContainsMacro S} orelse
         {Some L ContainsMacro}
      [] fSynAction(P) then {ContainsMacro P}
      [] fSynSequence(Vs L) then {Some Vs ContainsMacro} orelse
         {Some L ContainsMacro}
      [] fSynAlternative(L) then {Some L ContainsMacro}
      [] fSynAssignment(V E) then {ContainsMacro V} orelse
         {ContainsMacro E}
      [] fSynTemplateInstantiation(_ L _) then {Some L ContainsMacro}
      [] none then false
      [] fScanner(V Ds Ms Rs _ _) then {ContainsMacro V} orelse
         {Some Ds ContainsMacro} orelse {Some Ms ContainsMacro}
         orelse {Some Rs ContainsMacro}
      [] fParser(V CDs Ms T PDs _ _) then
         {ContainsMacro V} orelse {Some CDs ContainsMacro} orelse
         {Some Ms ContainsMacro} orelse {ContainsMacro T} orelse
         {Some PDs ContainsMacro}
      [] fToken(L) then {Some L ContainsMacro}
      [] fMode(V L) then {ContainsMacro V} orelse {Some L ContainsMacro}
      [] fInheritedModes(L) then {Some L ContainsMacro}
      [] fLexicalAbbreviation(S _) then {ContainsMacro S}
      [] fLexicalRule(_ P) then {ContainsMacro P}
      [] fMacro(_ _) then true
      [] fDotAssign(L R _) then {ContainsMacro L} orelse {ContainsMacro R}
      [] fColonEquals(L R _) then {ContainsMacro L} orelse {ContainsMacro R}
      %TODO [] fFOR(_ _ _) then ...
      %TODO [] fWhile(_ _ _) then ...
      end
   end

   %% FULL RECURSIVE MACRO EXPANSION

   fun {FullMacroExpandList L Env}
      case L of nil then nil
      [] H|T then {FullMacroExpand H Env}|{FullMacroExpandList T Env} end
   end

   fun {FullMacroExpand E Env}
      case E
      of fDeclare(P1 P2 C) then
         fDeclare({FullMacroExpand P1 Env}
                  {FullMacroExpand P2 Env} C)
      [] dirSwitch(_) then E
      [] dirPushSwitches then E
      [] dirPopSwitches then E
      [] dirLocalSwitches then E
      [] fStepPoint(P A C) then fStepPoint({FullMacroExpand P Env} A C)
      [] fAnd(P1 P2) then fAnd({FullMacroExpand P1 Env}
                               {FullMacroExpand P2 Env})
      [] fEq(P1 P2 C) then fEq({FullMacroExpand P1 Env}
                               {FullMacroExpand P2 Env} C)
      [] fAssign(P1 P2 C) then fAssign({FullMacroExpand P1 Env}
                                       {FullMacroExpand P2 Env} C)
      [] fOrElse(P1 P2 C) then fOrElse({FullMacroExpand P1 Env}
                                       {FullMacroExpand P2 Env} C)
      [] fAndThen(P1 P2 C) then fAndThen({FullMacroExpand P1 Env}
                                         {FullMacroExpand P2 Env} C)
      [] fOpApply(A L C) then
         fOpApply(A {FullMacroExpandList L Env} C)
      [] fOpApplyStatement(A L C) then
         fOpApplyStatement(A {FullMacroExpandList L Env} C)
      [] fObjApply(P1 P2 C) then fObjApply({FullMacroExpand P1 Env}
                                           {FullMacroExpand P2 Env} C)
      [] fAt(P C) then fAt({FullMacroExpand P Env} C)
      [] fAtom(_ _) then E
      [] fVar(_ _) then E
      [] fAnonVar(_ _ _) then E
      [] fEscape(P C) then fEscape({FullMacroExpand P Env} C)
      [] fWildcard(_) then E
      [] fSelf(_) then E
      [] fDollar(_) then E
      [] fInt(_ _) then E
      [] fFloat(_ _) then E
      [] fColon(F E) then fColon({FullMacroExpand F Env}
                                 {FullMacroExpand E Env})
      [] fRecord(Lab L) then
         fRecord({FullMacroExpand Lab Env} {FullMacroExpandList L Env})
      [] fOpenRecord(Lab L) then
         fOpenRecord({FullMacroExpand Lab Env} {FullMacroExpandList L Env})
      [] fApply(P L C) then
         fApply({FullMacroExpand P Env} {FullMacroExpandList L Env} C)
      [] fProc(P1 L P2 Fs C) then
         fProc({FullMacroExpand P1 Env}
               {FullMacroExpandList L Env}
               {FullMacroExpand P2 Env} Fs C)
      [] fFun(P1 L P2 Fs C) then
         fFun({FullMacroExpand P1 Env}
              {FullMacroExpandList L Env}
              {FullMacroExpand P2 Env} Fs C)
      [] fFunctor(P L C) then
         fFunctor({FullMacroExpand P Env} {FullMacroExpandList L Env} C)
      [] fRequire(L C) then fRequire({FullMacroExpandList L Env} C)
      [] fPrepare(P1 P2 C) then
         fPrepare({FullMacroExpand P1 Env} {FullMacroExpand P2 Env} C)
      [] fImport(L C) then fImport({FullMacroExpandList L Env} C)
      [] fExport(L C) then fExport({FullMacroExpandList L Env} C)
      [] fDefine(P1 P2 C) then
         fDefine({FullMacroExpand P1 Env} {FullMacroExpand P2 Env} C)
      [] fImportItem(_ _ _) then E
      [] fExportItem(_) then E
      [] fClass(P L1 L2 C) then
         fClass({FullMacroExpand P Env}
                {FullMacroExpandList L1 Env}
                {FullMacroExpandList L2 Env} C)
      [] fFrom(L C) then fFrom({FullMacroExpandList L Env} C)
      [] fProp(L C) then fProp({FullMacroExpandList L Env} C)
      [] fAttr(L C) then fAttr({FullMacroExpandList L Env} C)
      [] fFeat(L C) then fFeat({FullMacroExpandList L Env} C)
      [] fMeth(H P C) then
         fFeat({FullMacroExpand H Env} {FullMacroExpand P Env} C)
      [] fMethArg(T D) then
         fMethArg({FullMacroExpand T Env} {FullMacroExpand D Env})
      [] fNoDefault then E
      [] fDefault(P C) then fDefault({FullMacroExpand P Env} C)
      [] fMethColonArg(F T D) then
         fMethColonArg({FullMacroExpand F Env}
                       {FullMacroExpand T Env}
                       {FullMacroExpand D Env})
      [] fLocal(P1 P2 C) then
         fLocal({FullMacroExpand P1 Env} {FullMacroExpand P2 Env} C)
      [] fBoolCase(P1 P2 E C) then
         fBoolCase({FullMacroExpand P1 Env}
                   {FullMacroExpand P2 Env}
                   {FullMacroExpand E Env} C)
      [] fNoElse(_) then E
      [] fCase(P L E C) then
         fCase({FullMacroExpand P Env}
               {FullMacroExpandList L Env}
               {FullMacroExpand E Env} C)
      [] fCaseClause(P1 P2) then
         fCaseClause({FullMacroExpand P1 Env}
                     {FullMacroExpand P2 Env})
      [] fSideCondition(P1 P2 P3) then
         fSideCondition({FullMacroExpand P1 Env}
                        {FullMacroExpand P2 Env}
                        {FullMacroExpand P3 Env})
      [] fLockThen(P1 P2 C) then
         fLockThen({FullMacroExpand P1 Env}
                   {FullMacroExpand P2 Env} C)
      [] fLock(P C) then fLock({FullMacroExpand P Env} C)
      [] fThread(P C) then fThread({FullMacroExpand P Env} C)
      [] fTry(P Ca Fi C) then
         fTry({FullMacroExpand P Env}
              {FullMacroExpand Ca Env}
              {FullMacroExpand Fi Env} C)
      [] fNoCatch then E
      [] fCatch(L C) then fCatch({FullMacroExpandList L Env} C)
      [] fNoFinally then E
      [] fRaise(P C) then fRaise({FullMacroExpand P Env} C)
      [] fSkip(_) then E
      [] fFdCompare(A P1 P2 C) then
         fFdCompare(A
                    {FullMacroExpand P1 Env}
                    {FullMacroExpand P2 Env} C)
      [] fFdIn(A P1 P2 C) then
         fFdIn(A
               {FullMacroExpand P1 Env}
               {FullMacroExpand P2 Env} C)
      [] fFail(_) then E
      [] fNot(P C) then fNot({FullMacroExpand P Env} C)
      [] fCond(L E C) then
         fCond({FullMacroExpandList L Env}
               {FullMacroExpand E Env} C)
      [] fClause(P1 P2 P3) then
         fClause({FullMacroExpand P1 Env}
                 {FullMacroExpand P2 Env}
                 {FullMacroExpand P3 Env})
      [] fNoThen(_) then E
      [] fOr(L C) then fOr({FullMacroExpandList L Env} C)
      [] fDis(L C) then fDis({FullMacroExpandList L Env} C)
      [] fChoice(L C) then fChoice({FullMacroExpandList L Env} C)
      [] fSynTopLevelProductionTemplates(L) then
         fSynTopLevelProductionTemplates(
            {FullMacroExpandList L Env})
      [] fProductionTemplate(Key Params Rules Es Rets) then
         fProductionTemplate(
            Key
            {FullMacroExpandList Params Env}
            {FullMacroExpandList Rules Env}
            {FullMacroExpandList Es Env}
            {FullMacroExpandList Rets Env})
      [] fSyntaxRule(S L E) then
         fSyntaxRule(
            {FullMacroExpand S Env}
            {FullMacroExpandList L Env}
            {FullMacroExpand E Env})
      [] fSynApplication(S L) then
         fSynApplication(
            {FullMacroExpand S Env}
            {FullMacroExpandList L Env})
      [] fSynAction(P) then fSynAction({FullMacroExpand P Env})
      [] fSynSequence(Vs L) then
         fSynSequence({FullMacroExpandList Vs Env}
                      {FullMacroExpandList L Env})
      [] fSynAlternative(L) then
         fSynAlternative({FullMacroExpandList L Env})
      [] fSynAssignment(V E) then
         fSynAssignment({FullMacroExpand V Env}
                        {FullMacroExpand E Env})
      [] fSynTemplateInstantiation(Key L C) then
         fSynTemplateInstantiation(
            Key {FullMacroExpandList L Env} C)
      [] none then E
      [] fScanner(V Ds Ms Rs A C) then
         fScanner(
            {FullMacroExpand V Env}
            {FullMacroExpandList Ds Env}
            {FullMacroExpandList Ms Env}
            {FullMacroExpandList Rs Env} A C)
      [] fParser(V CDs Ms T PDs I C) then
         fParser(
            {FullMacroExpand V Env}
            {FullMacroExpandList CDs Env}
            {FullMacroExpandList Ms Env}
            {FullMacroExpand T Env}
            {FullMacroExpandList PDs Env} I C)
      [] fToken(L) then fToken({FullMacroExpandList L Env})
      [] fMode(V L) then
         fMode({FullMacroExpand V Env}
               {FullMacroExpandList L Env})
      [] fInheritedModes(L) then
         fInheritedModes({FullMacroExpandList L Env})
      [] fLexicalAbbreviation(S RE) then
         fLexicalAbbreviation(
            {FullMacroExpand S Env} RE)
      [] fLexicalRule(RE P) then
         fLexicalRule(
            RE {FullMacroExpand P Env})
      [] fMacro(_ _) then
         E2 = {MacroExpand1 E Env}
      in
         if {ContainsMacro E2}
         then {FullMacroExpand E2 Env} else E2 end
      [] fDotAssign(L R C) then
         fDotAssign({FullMacroExpand L Env}
                    {FullMacroExpand R Env} C)
      [] fColonEquals(L R C) then
         fColonEquals({FullMacroExpand L Env}
                      {FullMacroExpand R Env} C)
      %TODO [] fFOR(_ _ _) then ...
      %TODO [] fWhile(_ _ _) then ...
      end
   end
end
