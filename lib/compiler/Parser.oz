%%% Copyright © 2013, Université catholique de Louvain
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%
%%% * Redistributions of source code must retain the above copyright notice,
%%% this list of conditions and the following disclaimer.
%%% * Redistributions in binary form must reproduce the above copyright notice,
%%% this list of conditions and the following disclaimer in the documentation
%%% and/or other materials provided with the distribution.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%%% POSSIBILITY OF SUCH DAMAGE.

functor

import
   PEG(translate:Translate)
   Preprocessor
   Lexer

export
   file:ParseFile
   virtualString:ParseVS

define

   fun {MkPos P1 P2}
      case P1#P2
      of pos(F1 L1 C1)#pos(F2 L2 C2) then
         pos(F1 L1 C1 F2 L2 C2)
      end
   end

   KeywordsAndSymbols = {Append Lexer.ozKeywords Lexer.ozSymbols}
   RulesL = {Map KeywordsAndSymbols
                 fun {$ KwSym}
                    KwSym #
                    ([pB elem(KwSym) pE] #
                     fun {$ [P1 _ P2]} fKeyword(KwSym {MkPos P1 P2}) end)
                 end}

   Rules =
   g(
      %% positions %%
      pB: raw(proc {$ CtxIn CtxOut SemOut}
                 CtxOut = CtxIn
                 SemOut = CtxIn.posbegin
              end)
      pE: raw(proc {$ CtxIn CtxOut SemOut}
                 CtxOut = CtxIn
                 SemOut = CtxIn.posend
              end)

      %% tokens %%
      string:
         [pB elem(fun {$ Tok} case Tok of tkString(V) then some(V) else false end end) pE] #
         fun {$ [P1 L P2]}
            {FoldR L fun {$ C S}
                        fRecord(fAtom('|' P1) [fInt(C P1) S])
                     end fAtom(nil P2)}
         end

      character:
         [pB elem(fun {$ Tok} case Tok of tkCharacter(V) then some(V) else false end end) pE] #
         fun {$ [P1 C P2]}
            fInt(C {MkPos P1 P2})
         end

      atom:
         [pB elem(fun {$ Tok} case Tok of tkAtom(V) then some(V) else false end end) pE] #
         fun {$ [P1 C P2]}
            fAtom(C {MkPos P1 P2})
         end

      variable:
         [pB elem(fun {$ Tok} case Tok of tkVariable(V) then some(V) else false end end) pE] #
         fun {$ [P1 C P2]}
            fVar(C {MkPos P1 P2})
         end

      atomL:
         [pB elem(fun {$ Tok} case Tok of tkAtomLabel(V) then some(V) else false end end) pE] #
         fun {$ [P1 C P2]}
            fAtom(C {MkPos P1 P2})
         end

      variableL:
         [pB elem(fun {$ Tok} case Tok of tkVariableLabel(V) then some(V) else false end end) pE] #
         fun {$ [P1 C P2]}
            fVar(C {MkPos P1 P2})
         end

      integer:
         [pB elem(fun {$ Tok} case Tok of tkInteger(V) then some(V) else false end end) pE] #
         fun {$ [P1 C P2]}
            fInt(C {MkPos P1 P2})
         end

      float:
         [pB elem(fun {$ Tok} case Tok of tkFloat(V) then some(V) else false end end) pE] #
         fun {$ [P1 C P2]}
            fFloat(C {MkPos P1 P2})
         end

      %% top-level %%
      input: [star(compilationUnit) eof]
      compilationUnit: alt(cuDirective cuDeclare phrase)
      cuDirective: alt(
         [pB elem(fun {$ Tok} case Tok of tkDirSwitch(Ss) then some(Ss) else false end end) pE] #
         fun {$ [P1 Ss P2]}
            Pos = {MkPos P1 P2}
         in
            dirSwitch({Map Ss fun {$ Sw} L = {Label Sw} in L(Sw.1 Pos) end})
         end

         elem(tkPreprocessorDirective('showSwitches')) # dirShowSwitches
         elem(tkPreprocessorDirective('pushSwitches')) # dirPushSwitches
         elem(tkPreprocessorDirective('popSwitches')) # dirPopSwitches
         elem(tkPreprocessorDirective('localSwitches')) # dirLocalSwitches
      )
      eof: elem(fun {$ Tok} case Tok of tkEof(Defs) then some(Defs) else false end end)

      cuDeclare: alt(
         [pB 'declare' phrase 'in' phrase pE] #
         fun {$ [P1 _ S1 _ S2 P2]} fDeclare(S1 S2 {MkPos P1 P2}) end

         [pB 'declare' phrase pE] #
         fun{$ [P1 _ S1 P2]} fDeclare(S1 fSkip(P2) {MkPos P1 P2}) end
      )

      %% expressions & statements %%
      phrase:alt(
                [lvl0 phrase]#fun{$ [S1 S2]}fAnd(S1 S2)end
                lvl0
                )

      lvl0:alt(
              [pB lvl1 '=' lvl0 pE]#fun{$ [P1 S1 _ S2 P2]}fEq(S1 S2 {MkPos P1 P2})end
              lvl1
              )
      lvl1:alt(
              [pB lvl2 '<-' lvl1 pE]#fun{$ [P1 S1 _ S2 P2]}fAssign(S1 S2 {MkPos P1 P2})end
              [pB dotted ':=' lvl1 pE]#fun{$ [P1 S1 _ S2 P2]}
                                          case S1
                                          of fOpApply('.' ...) then
                                             fDotAssign(S1 S2 {MkPos P1 P2})
                                          else
                                             fColonEquals(S1 S2 {MkPos P1 P2})
                                          end
                                       end
              [pB lvl2 ':=' lvl1 pE]#fun{$ [P1 S1 _ S2 P2]}fColonEquals(S1 S2 {MkPos P1 P2})end
              lvl2
              )
      lvl2:alt(
              [pB lvl3 'orelse' lvl2 pE]#fun{$ [P1 S1 _ S2 P2]}fOrElse(S1 S2 {MkPos P1 P2})end
              lvl3
              )
      lvl3:alt(
              [pB lvl4 'andthen' lvl3 pE]#fun{$ [P1 S1 _ S2 P2]}fAndThen(S1 S2 {MkPos P1 P2})end
              lvl4
              )
      lvl4:alt(
              [pB lvl5 alt('==' '\\=' '<' '=<' '>' '>=') lvl5 pE]#fun{$ [P1 S1 Op S2 P2]}fOpApply(Op.1 [S1 S2] {MkPos P1 P2})end
              [pB lvl5 alt('=:' '\\=:' '<:' '=<:' '>:' '>=:') lvl5 pE]#fun{$ [P1 S1 Op S2 P2]}fFdCompare(Op.1 S1 S2 {MkPos P1 P2})end
              lvl5
              )
      lvl5:alt(
              [pB lvl6 alt('::' ':::') lvl6 pE]#fun{$ [P1 S1 Op S2 P2]}fFdIn(Op.1 S1 S2 {MkPos P1 P2})end
              lvl6
              )
      lvl6:alt(
              [lvl7 pB '|' pE lvl6]#fun{$ [S1 P1 _ P2 S2]}fRecord(fAtom('|' {MkPos P1 P2}) [S1 S2])end
              lvl7
              )
      lvl7:alt(
              [lvl8 pla([pB '#' pE]) plus(seq2('#' lvl8))]#fun{$ [S1 [P1 _ P2] Sr]}fRecord(fAtom('#' {MkPos P1 P2}) S1|Sr)end
              lvl8
              )
      lvl8:alt(
              [pB lvl9 plus(
                          [alt('+' '-') lvl9 pE]#fun{$ [Op S2 P2]}fun{$ P1 S1}fOpApply(Op.1 [S1 S2] {MkPos P1 P2})end end
                          )]#fun{$ [P1 S1 Ms]}{FoldL Ms fun{$ S M}{M P1 S}end S1}end
              lvl9
              )
      lvl9:alt(
              [pB lvlA plus(
                          [alt('*' '/' 'mod' 'div') lvlA pE]#fun{$ [Op S2 P2]}fun{$ P1 S1}fOpApply(Op.1 [S1 S2] {MkPos P1 P2})end end
                          )]#fun{$ [P1 S1 Ms]}{FoldL Ms fun{$ S M}{M P1 S}end S1}end
              lvlA
              )
      lvlA:alt(
              [pB lvlB ',' lvlA pE]#fun{$ [P1 S1 _ S2 P2]}fObjApply(S1 S2 {MkPos P1 P2})end
              lvlB
              )
      lvlB:alt(
              [pB '~' lvlC pE]#fun{$ [P1 _ S1 P2]}fOpApply('~' [S1] {MkPos P1 P2})end
              lvlC
              )
      dotted:[pB lvlD plus(
                         [alt('.' '^') alt(feature lvlD) pE]#fun{$ [Op S2 P2]}fun{$ P1 S1}fOpApply(Op.1 [S1 S2] {MkPos P1 P2})end end
                         )]#fun{$ [P1 S1 Ms]}{FoldL Ms fun{$ S M}{M P1 S}end S1}end
      lvlC:alt(
              dotted
              lvlD
              )
      lvlD:alt(
              [pB '@' lvlD pE]#fun{$ [P1 _ S1 P2]}fAt(S1 {MkPos P1 P2})end
              [pB '!!' lvlD pE]#fun{$ [P1 _ S1 P2]}fOpApply('!!' [S1] {MkPos P1 P2})end
              atPhrase
              )
      atPhrase:alt(
                  ['local' inPhrase 'end']#fun{$ [_ S _]}S end
                  ['(' inPhrase ')']#fun{$ [_ S _]}S end
                  [pB 'proc' star(atom) '{' plus(lvl0) '}' inPhrase 'end' pE]#fun{$ [P1 _ Fs _ As _ S _ P2]}
                                                                                 fProc(As.1 As.2 S Fs {MkPos P1 P2})
                                                                              end
                  [pB 'fun' star(atom) '{' plus(lvl0) '}' inPhrase 'end' pE]#fun{$ [P1 _ Fs _ As _ S _ P2]}
                                                                                fFun(As.1 As.2 S Fs {MkPos P1 P2})
                                                                             end
                  [pB '{' plus(lvl0) '}' pE]#fun{$ [P1 _ As _ P2]}fApply(As.1 As.2 {MkPos P1 P2}) end
                  [pB 'if' internalIf 'end' pE]#fun{$ [P1 _ S _ P2]}{AdjoinAt S 4 {MkPos P1 P2}}end
                  [pB 'case' internalCase 'end' pE]#fun{$ [P1 _ S _ P2]}{AdjoinAt S 4 {MkPos P1 P2}}end
                  [pB 'lock' phrase 'then' inPhrase 'end' pE]#fun{$ [P1 _ S1 _ S2 _ P2]}fLockThen(S1 S2 {MkPos P1 P2})end
                  [pB 'lock' inPhrase 'end' pE]#fun{$ [P1 _ S1 _ P2]}fLock(S1 {MkPos P1 P2})end
                  [pB 'thread' inPhrase 'end' pE]#fun{$ [P1 _ S _ P2]}fThread(S {MkPos P1 P2})end
                  [pB 'try' inPhrase
                   opt([pB 'catch' caseClauses pE]#fun{$ [P1 _ Cs P2]}fCatch(Cs {MkPos P1 P2})end fNoCatch)
                   opt(seq2('finally' inPhrase) fNoFinally)
                   'end' pE]#fun{$ [P1 _ S C F _ P2]}fTry(S C F {MkPos P1 P2})end
                  [pB 'cond' condClauses optElse 'end' pE]#fun{$ [P1 _ Cs E _ P2]}fCond(Cs E {MkPos P1 P2})end
                  [pB 'dis' disClauses 'end' pE]#fun{$ [P1 _ Cs _ P2]}fDis(Cs {MkPos P1 P2})end
                  [pB 'or' disClauses 'end' pE]#fun{$ [P1 _ Cs _ P2]}fOr(Cs {MkPos P1 P2})end
                  [pB 'choice' sep(inPhrase '[]')'end' pE]#fun{$ [P1 _ Ss _ P2]}fChoice(Ss {MkPos P1 P2})end
                  [pB 'raise' inPhrase 'end' pE]#fun{$ [P1 _ S _ P2]}fRaise(S {MkPos P1 P2})end
                  [pB 'class' exprOrImplDollar star(classDescr) star(method) 'end' pE]#fun{$ [P1 _ S Ds Ms _ P2]}
                                                                                                            fClass(S Ds Ms {MkPos P1 P2})
                                                                                                         end
                  [pB 'functor' exprOrImplDollar star(funcDescr) 'end' pE]#fun{$ [P1 _ S Ds _ P2]}
                                                                              fFunctor(S Ds {MkPos P1 P2})
                                                                           end
                  [pB 'for' star(forDecl) 'do' inPhrase 'end' pE]#fun{$ [P1 _ Ds _ S _ P2]}fFOR(Ds S {MkPos P1 P2})end
                  ['[' plus([lvl0 pE]) pB ']']#fun{$ [_ Ss P _]}
                                                  {FoldR Ss fun{$ [H P] T}
                                                               fRecord(fAtom('|' P) [H T])
                                                            end fAtom('nil' P)}
                                               end
                  [alt(atomL variableL) '(' star(subtree) opt(['...']) ')']#fun{$ [L _ Ts D _]}
                                                                               LL=if D==nil then fRecord else fOpenRecord end in
                                                                               LL(L Ts)
                                                                            end
                  [pB 'skip' pE]#fun{$ [P1 _ P2]}fSkip({MkPos P1 P2})end
                  [pB 'fail' pE]#fun{$ [P1 _ P2]}fFail({MkPos P1 P2})end
                  [pB 'self' pE]#fun{$ [P1 _ P2]}fSelf({MkPos P1 P2})end
                  dollar
                  underscore
                  string
                  float
                  feature
                  escVar
                  )
      forDecl:alt(
                 [lvl0 'in' forGen]#fun{$ [A _ S]}forPattern(A S)end
                 [lvl0 'from' lvl0]#fun{$ [A _ S]}forFrom(A S)end
                 [atom ':' lvl0]#fun{$ [A _ S]}forFeature(A S)end
                 atom#fun{$ A}forFlag(A)end
                 )
      forGen:alt(
                [lvl0 '..' lvl0 opt(seq2(';' lvl0) unit)]#fun{$ [S1 _ S2 S3]}forGeneratorInt(S1 S2 S3)end
                ['(' forGenC ')']#fun{$ [_ S _]}S end
                forGenC
                lvl0#fun{$ S}forGeneratorList(S)end
                )
      forGenC:alt(
                 [lvl0 ';' lvl0 opt(seq2(';' lvl0) unit)]#fun{$ [S1 _ S2 S3]}forGeneratorC(S1 S2 S3) end
                 )
      exprOrImplDollar:alt(lvl0 pE#fun{$ P}fDollar(P)end)
      dollar:[pB '$' pE]#fun{$ [P1 _ P2]}fDollar({MkPos P1 P2})end
      underscore: [pB '_' pE]#fun{$ [P1 _ P2]}fWildcard({MkPos P1 P2})end
      escVar: [pB '!' variable  pE]#fun{$ [P1 _ V P2]}fEscape(V {MkPos P1 P2})end
      escVarL:[pB '!' variableL pE]#fun{$ [P1 _ V P2]}fEscape(V {MkPos P1 P2})end
      internalIf:[phrase 'then' inPhrase optElse2]#fun{$ [S1 _ S2 S3]}fBoolCase(S1 S2 S3 unit)end
      internalCase:[phrase 'of' caseClauses optElse2]#fun{$ [S1 _ Cs S2]}fCase(S1 Cs S2 unit)end
      funcDescr:alt(
                   [pB 'import' plus(importDecl) pE]#fun{$ [P1 _ Ds P2]}fImport(Ds {MkPos P1 P2})end
                   [pB 'define' phrase alt(seq2('in' phrase) pE#fun{$ P}fSkip(P)end) pE]#fun{$ [P1 _ D S P2]}
                                                                                            fDefine(D S {MkPos P1 P2})
                                                                                          end
                   [pB 'require' plus(importDecl) pE]#fun{$ [P1 _ Ds P2]}fRequire(Ds {MkPos P1 P2})end
                   [pB 'prepare' phrase alt(seq2('in' phrase) pE#fun{$ P}fSkip(P)end) pE]#fun{$ [P1 _ D S P2]}
                                                                                             fPrepare(D S {MkPos P1 P2})
                                                                                          end
                   [pB 'export' plus(exportDecl) pE]#fun{$ [P1 _ Ds P2]}fExport(Ds {MkPos P1 P2})end
                   )
      importDecl:alt([variable optAt]#fun{$ [V A]}fImportItem(V nil A)end
                     [variableL '(' plus(alt([alt(integer atom) ':' variable]#fun{$ [F _ V]}V#F end
                                             integer atom
                                            )) ')' optAt]#fun{$ [V _ Fs _ A]}fImportItem(V Fs A)end
                     )
      optAt:opt(seq2('at' atom)#fun{$ A}fImportAt(A)end fNoImportAt)
      exportDecl:alt([alt(atom integer) ':' variable]#fun{$ [F _ V]}fColon(F V)end
                     variable)#fun{$ I}fExportItem(I)end
      classDescr:alt(
                    [pB 'from' plus(lvl0) pE]#fun{$ [P1 _ Ss P2]}fFrom(Ss {MkPos P1 P2})end
                    [pB 'prop' plus(lvl0) pE]#fun{$ [P1 _ Ss P2]}fProp(Ss {MkPos P1 P2})end
                    [pB 'attr' plus(attrOrFeat) pE]#fun{$ [P1 _ As P2]}fAttr(As {MkPos P1 P2})end
                    [pB 'feat' plus(attrOrFeat) pE]#fun{$ [P1 _ As P2]}fFeat(As {MkPos P1 P2})end
                    )
      attrOrFeat:[alt(escVar feature) opt([':' lvl0])]#fun{$ [K V]}
                                                          if V==nil then K
                                                          else K#(V.2).1
                                                          end
                                                       end
      method:[pB 'meth' methodHead inPhrase 'end' pE]#fun{$ [P1 _ H S _ P2]}
                                                         fMeth(H S {MkPos P1 P2})
                                                      end
      methodHead:alt([pB methodHead1 '=' variable pE]#fun{$ [P1 S1 _ S2 P2]}
                                                         fEq(S1 S2 {MkPos P1 P2})
                                                      end
                     methodHead1)
      methodHead1:alt(
                     atom variable escVar
                     [alt(atomL variableL escVarL)
                      '(' star(methFormal) opt(['...']) ')']#fun{$ [L _ Ts D _]}
                                                                LL=if D==nil then fRecord else fOpenRecord end in
                                                                LL(L Ts)
                                                             end
                     )
      methFormal:alt(
                    [feature ':' methFormAt opt(methDefault fNoDefault)]#fun{$ [F _ A D]}fMethColonArg(F A D)end
                    [methFormAt opt(methDefault fNoDefault)]#fun{$ [A D]}fMethArg(A D)end
                    )
      methFormAt:alt(variable dollar underscore)
      methDefault:[pB '<=' lvl0 pE]#fun{$ [P1 _ S P2]}fDefault(S {MkPos P1 P2}) end
      condClauses:sep(alt(
                         [phrase 'in' phrase 'then' phrase]#fun{$ [S1 _ S2 _ S3]}fClause(S1 S2 S3)end
                         [pB phrase 'then' phrase]#fun{$ [P S1 _ S2]}fClause(fSkip(P) S1 S2)end
                         ) '[]')
      disClauses:sep(alt(
                        [phrase 'in' phrase 'then' phrase]#fun{$ [S1 _ S2 _ S3]}fClause(S1 S2 S3)end
                        [pB phrase 'then' phrase]#fun{$ [P S1 _ S2]}fClause(fSkip(P) S1 S2)end
                        [phrase 'in' phrase pE]#fun{$ [S1 _ S2 P]}fClause(S1 S2 fNoThen(P))end
                        [pB phrase pE]#fun{$ [P1 S1 P2]}fClause(fSkip(P1) S1 fNoThen(P2))end
                        ) '[]')
      caseClauses:alt(
                     caseClause|seq2(alt('[]' 'elseof') caseClauses)
                     [caseClause]
                     )
      inPhrase:alt(
                  [pB phrase 'in' phrase pE]#fun{$ [P1 S1 _ S2 P2]}fLocal(S1 S2 {MkPos P1 P2})end
                  phrase
                  )
      optElse2:alt(
                  [pB 'elseif' internalIf pE]#fun{$ [P1 _ S P2]}{AdjoinAt S 4 {MkPos P1 P2}}end
                  [pB 'elsecase' internalCase pE]#fun{$ [P1 _ S P2]}{AdjoinAt S 4 {MkPos P1 P2}}end
                  optElse
                  )
      optElse:alt(
                 seq2('else' inPhrase)
                 pE#fun{$ P}fNoElse(P)end
                 )
      subtree:alt(
                 [feature ':' lvl0]#fun{$ [F _ S]}fColon(F S)end
                 lvl0)
      feature:alt(variable atom integer character)
      caseClause:alt(
                    [pB pat0 'andthen' opt(seq1(phrase 'in') fSkip(unit)) phrase pE 'then' inPhrase]
                    #fun{$ [P1 S1 _ OS S2 P2 _ S3]}
                        fCaseClause(fSideCondition(S1 OS S2 {MkPos P1 P2}) S3)
                     end
                    [pat0 'then' inPhrase]#fun{$ [S1 _ S2]}fCaseClause(S1 S2)end
                    )
      pat0:alt(
              [pB lvl4 '=' pat0 pE]#fun{$ [P1 S1 _ S2 P2]}fEq(S1 S2 {MkPos P1 P2})end
              lvl4
              )
      )

   TG = {Translate {Record.adjoinList Rules RulesL}
         opts(useCache:true useLastNoSuccess:true)}

   local
      fun {ParseGeneric MakeInitCtxProc Opts}
         DefsDict = Opts.defines
         InitialDefines = {Dictionary.toRecord defines DefsDict}
         CtxIn = {MakeInitCtxProc InitialDefines}

         CtxOut Sem
      in
         {TG.input CtxIn ?CtxOut ?Sem}

         if CtxOut.valid then
            [AST FinalDefines] = Sem
         in
            {Dictionary.removeAll DefsDict}
            {ForAll {Arity FinalDefines} proc {$ D} DefsDict.D := true end}
            AST#nil
         else
            LastNoSuccess = {Access CtxOut.lastNoSuccess}
            Pos = LastNoSuccess.posbegin
         in
            parseError#[error(kind:'parse error' msg:'Parse error'
                              items:[Pos])]
         end
      end
   in
      fun {ParseVS VS Opts}
         fun {MakeInitCtxProc Defines}
            {Preprocessor.readAndPreprocessVS VS './' Defines}
         end
      in
         {ParseGeneric MakeInitCtxProc Opts}
      end

      fun {ParseFile FN Opts}
         fun {MakeInitCtxProc Defines}
            {Preprocessor.readAndPreprocessSourceFile FN Defines}
         end
      in
         {ParseGeneric MakeInitCtxProc Opts}
      end
   end
end
