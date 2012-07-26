%%% Copyright © 2012, Université catholique de Louvain
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
   Open
export
   file:ParseFile
   virtualString:ParseVS
define
   fun{FileName Context FN}
      case FN
      of &/|_ then FN
      else
         {Append Context FN}
      end
   end
   fun{ReadFile Context FN}
      try
         {{New Open.file init(name:{FileName Context FN})} read(list:$ size:all)}
      catch system(os(os "open" 2 ...) ...) then
         {{New Open.file init(name:{Append {FileName Context FN} ".oz"})} read(list:$ size:all)}
      end
   end
   fun{FileContext Context FN}
      {Reverse {List.dropWhile {Reverse {FileName Context FN}} fun{$ C}C\=&/ end}}
   end
   fun lazy {MkContext S F L C R TG D CS FS FC Next}
      ctx(valid: true
          value: case S
                 of nil then
                    Next#eof
                 [] &\n|T then
                    {MkContext T F L+1 0 false TG D CS FS FC Next}#&\n
                 [] H|T andthen R then
                    {MkContext T F L+1 0 H==&\r TG D CS FS FC Next}#H
                 [] H|T then
                    {MkContext T F L C+1 H==&\r TG D CS FS FC Next}#H
                 end
          grammar: TG
          cache: {Dictionary.new}

          defines:D
          condStack:CS
          f:F l:L c:C r:R
          fileStack:FS
          fileContext:FC
          rebind:fun{$ Opts}
                    {MkContext
                     S
                     {CondSelect Opts file F}
                     {CondSelect Opts line L}
                     {CondSelect Opts column C}
                     {CondSelect Opts crSeen R}
                     {CondSelect Opts grammar TG}
                     {CondSelect Opts defines D}
                     {CondSelect Opts condStack CS}
                     {CondSelect Opts fileStack FS}
                     {CondSelect Opts fileContext FC}
                     Next
                    }
                 end
         )
   end

   fun{MkPos P1 P2}
      case P1#P2
      of pos(F1 L1 C1)#pos(F2 L2 C2) then
         pos(F1 L1 C1 F2 L2 C2)
      end
   end
   OzKW=["true" "false" "unit"
         "andthen" "at" "attr" "case" "catch" "choice"
         "class" "cond" "declare" "define" "dis" "do"
         "div" "else" "elsecase" "elseif" "elseof" "end"
         "export" "fail" "feat" "finally" "from" "for"
         "fun" "functor" "if" "import" "in" "local"
         "lock" "meth" "mod" "not" "of" "or" "orelse"
         "prepare" "proc" "prop" "raise" "require"
         "self" "skip" "then" "thread" "try"
        ]
   OzSymb=["(" ")" "[" "]" "{" "}"
           "|" "#" ":" "..." "=" "." ":=" "^" "[]" "$"
           "!" "_" "~" "+" "-" "*" "/" "@" "<-"
           "," "!!" "<=" "==" "\\=" "<" "=<" ">"
           ">=" "=:" "\\=:" "<:" "=<:" ">:" ">=:" "::" ":::"
           ".." ";"

           "\\switch" "\\pushSwitches" "\\popSwitches" "\\localSwitches"

           "\\line" "\\insert" "\\define" "\\undef"
           "\\ifdef" "\\ifndef" "\\else" "\\endif"
          ]
   RulesL=
   {Flatten
    [
     {Map OzKW fun{$ K}
                  KA={String.toAtom &p|&p|&_|K}
                  KB={String.toAtom K} in
                  KA#([pos K nla(alNum) pos]#fun{$ [P1 _ _ P2]} fKeyword(KB {MkPos P1 P2}) end)
               end}
     {Map OzKW fun{$ K}
                  KA={String.toAtom &p|&p|&_|K}
                  KB={String.toAtom K} in
                  KB#seq2(whiteSpace KA)
               end}
     {Map OzSymb fun{$ S}
                    SA={String.toAtom &p|&p|&_|S}
                    SB={String.toAtom S} in
                    SA#(
                        [
                         pos
                         nla(alt({Map {Filter OzSymb fun{$ S2}{List.isPrefix S S2} andthen S\=S2 end} String.toAtom}))
                         case S
                         of &\\|&=|_ then S
                         [] &\\|_ then [S nla(alNum)]
                         else S
                         end
                         pos
                        ]#fun{$ [P1 _ _ P2]}fKeyword(SB {MkPos P1 P2}) end
                       )
                 end}
     {Map OzSymb fun{$ S}
                    SA={String.toAtom &p|&p|&_|S}
                    SB={String.toAtom S} in
                    SB#seq2(whiteSpace SA)
                 end}
    ]
   }
   SpecialChars=t(&a:&\a &b:&\b &f:&\f &n:&\n &r:&\r &t:&\t &v:&\v)
   KWVal=k('unit':unit 'true':true 'false':false)
   fun{Nest CanHaveElse}
      proc{$ CIn SIn COut SOut}
         SOut=SIn
         if CIn.valid then
            COut={CIn.rebind o(condStack:CanHaveElse|CIn.condStack)}
         else
            COut=CIn
         end
      end
   end
   proc{Unnest CIn SIn COut SOut}
      SOut=SIn
      if CIn.valid then
         COut={CIn.rebind o(condStack:CIn.condStack.2)}
      else
         COut=CIn
      end
   end
   Rules=
   g(
      %% LEXICAL ANALYSIS %%
      pos:empty#proc{$ CIn _ COut SOut}
                   COut=CIn
                   SOut=pos(CIn.f CIn.l CIn.c)
                end
      lineStart: alt(is(pos fun{$ pos(_ _ C)}C==0 end) nla(wc))

      %% character classes %%
      ucLetter:  is(wc Char.isUpper)
      lcLetter:  is(wc Char.isLower)
      digit:     is(wc Char.isDigit)
      nzDigit:   seq2(nla(&0) digit)
      alNum:     alt(ucLetter lcLetter digit &_)
      binDigit:  alt(&0 &1)
      octDigit:  alt(&0 &1 &2 &3 &4 &5 &6 &7)
      octDigitV: octDigit                     #fun{$ X}X-&0 end
      hexDigit:  alt(digit &a &b &c &d &e &f &A &B &C &D &E &F)
      hexDigitV: alt(
                    digit                     #fun{$ X}X-&0 end
                    alt(&a &b &c &d &e &f)    #fun{$ X}10+X-&a end
                    alt(&A &B &C &D &E &F)    #fun{$ X}10+X-&A end
                    )
      pseudoChar: seq2(&\\ alt(
                              [ octDigitV octDigitV octDigitV] #fun{$ [A B C]}A*64+B*8+C end
                              [alt(&x &X) hexDigitV hexDigitV] #fun{$ [_ A B]}A*16+B end
                              alt(&a &b &f &n &r &t &v)        #fun{$ X}SpecialChars.X end
                              alt(&\\ &' &" &` &&)
                              ))
      variableChar: alt(
                       seq2(nla(alt(&` &\\ 0)) wc)
                       pseudoChar
                       )
      atomChar: alt(
                   seq2(nla(alt(&' &\\ 0)) wc)
                   pseudoChar
                   )
      stringChar: alt(
                     seq2(nla(alt(&" &\\ 0)) wc)
                     pseudoChar
                     )

      %% naked tokens %%
      variableN: alt(
                    [pos ucLetter star(alNum) pos]     #fun{$ [P1 H T P2]}
                                                           fVar({String.toAtom H|T} {MkPos P1 P2})
                                                        end
                    [pos &` star(variableChar) &` pos] #fun{$ [P1 _ L _ P2]}
                                                           fVar({String.toAtom &`|{Append L "`"}} {MkPos P1 P2})
                                                        end
                    )
      keyword: alt({Map OzKW fun{$ S}{String.toAtom &p|&p|&_|S}end})
      symbol: alt({Map OzSymb fun{$ S}{String.toAtom &p|&p|&_|S}end})
      atomN: alt(
                [nla(keyword) pos lcLetter star(alNum) pos] #fun{$ [_ P1 H T P2]} fAtom({String.toAtom H|T} {MkPos P1 P2}) end
                [pos &' star(atomChar) &' pos]              #fun{$ [P1 _ L _ P2]} fAtom({String.toAtom L  } {MkPos P1 P2}) end
                )
      pp_string: [&" star([pos stringChar pos]) &" pos] #fun{$ [_ L _ P]}
                                                      {FoldR L fun{$ [P1 C P2] S}
                                                                  fRecord(fAtom('|' P2) [fInt(C {MkPos P1 P2}) S])
                                                               end fAtom(nil P)}
                                                   end
      pp_character: [pos && alt(seq2(nla(alt(&\\ 0)) wc) pseudoChar) pos] #fun{$ [P1 _ C P2]} fInt(C {MkPos P1 P2}) end
      pp_atom: seq1(atomN nla(&())
      pp_variable: seq1(variableN nla(&())
      pp_kwValue:seq1(alt('pp_true' 'pp_false' 'pp_unit') nla(&())
      pp_atomL: seq1(atomN pla(&())
      pp_variableL: seq1(variableN pla(&())
      pp_kwValueL:seq1(alt('pp_true' 'pp_false' 'pp_unit') pla(&())
      pp_integer: [pos
                   opt("~")
                   alt(
                      nzDigit|star(digit)
                      plus(octDigit)
                      &0|alt(&x &X)|plus(hexDigit)
                      &0|alt(&b &B)|plus(binDigit)
                      )
                   pos] #fun{$ [P1 S L P2]} fInt({String.toInt {Append S L}} {MkPos P1 P2}) end
      pp_float: [pos
                 opt("~")
                 plus(digit)
                 seq1(&. nla([&. &.]))|star(digit)
                 opt([alt(&e &E) opt("~") plus(digit)])
                 pos] #fun{$ [P1 S M D E P2]}fFloat({String.toFloat {Flatten [S M D E]}} {MkPos P1 P2}) end

      fileName: alt(
                   star(alt(alNum &~ &. &/ &-))
                   [&' star(atomChar) &'] #fun{$ [_ L _]} L end
                   )
      pp_whiteSpace: star(alt(
                             simpleSpace
                             comment
                             ))
      simpleSpace:  alt(&\t &\v &\f & )
      comment:      alt(&? blockComment [&% star([nla(lineStart) wc])])
      blockComment: ["/*" star(alt(
                                  [nla("/*") nla("*/") wc]
                                  blockComment
                                  )) "*/"]
      whiteToEOL: [pp_whiteSpace star(alt(&\r &\n)) lineStart]

      %% pre-processing %%
      preprocessor:alt(
                      ['pp_\\line'   pp_whiteSpace pp_integer pp_whiteSpace fileName whiteToEOL]#proc{$ CtxIn SemIn CtxOut SemOut}
                                                                                                    SemOut=SemIn
                                                                                                    if CtxIn.valid then
                                                                                                       [_ _ L _ FN _]=SemIn in
                                                                                                       CtxOut={CtxIn.rebind
                                                                                                               o(file:{String.toAtom FN}
                                                                                                                 line:L.1)}
                                                                                                    else
                                                                                                       CtxOut=CtxIn
                                                                                                    end
                                                                                                  end
                      ['pp_\\line'   pp_whiteSpace fileName whiteToEOL]#proc{$ CtxIn SemIn CtxOut SemOut}
                                                                           SemOut=SemIn
                                                                           if CtxIn.valid then
                                                                              [_ _ FN _]=SemIn in
                                                                              CtxOut={CtxIn.rebind
                                                                                      o(file:{String.toAtom FN})}
                                                                           else
                                                                              CtxOut=CtxIn
                                                                           end
                                                                        end
                      ['pp_\\insert' pp_whiteSpace fileName whiteToEOL]#proc{$ CtxIn SemIn CtxOut SemOut}
                                                                           SemOut=SemIn
                                                                           if CtxIn.valid then
                                                                              [_ _ FN _]=SemIn in
                                                                              CtxOut={MkContext
                                                                                      {ReadFile CtxIn.fileContext FN}
                                                                                      {String.toAtom FN} 1 0 false
                                                                                      CtxIn.grammar CtxIn.defines nil
                                                                                      CtxIn|CtxIn.fileStack
                                                                                      {FileContext CtxIn.fileContext FN}
                                                                                      ctx(valid:false)
                                                                                     }
                                                                           else
                                                                              CtxOut=CtxIn
                                                                           end
                                                                        end
                      ['pp_\\define' pp_whiteSpace pp_variable whiteToEOL]#proc{$ CtxIn SemIn CtxOut SemOut}
                                                                              SemOut=SemIn
                                                                              if CtxIn.valid then
                                                                                 [_ _ D _]=SemIn in
                                                                                 CtxOut={CtxIn.rebind
                                                                                         o(defines:D.1|CtxIn.defines)}
                                                                              else
                                                                                 CtxOut=CtxIn
                                                                              end
                                                                           end
                      ['pp_\\undef'  pp_whiteSpace pp_variable whiteToEOL]#proc{$ CtxIn SemIn CtxOut SemOut}
                                                                              SemOut=SemIn
                                                                              if CtxIn.valid then
                                                                                 [_ _ D _]=SemIn in
                                                                                 CtxOut={CtxIn.rebind
                                                                                         o(defines:{Filter
                                                                                                    CtxIn.defines
                                                                                                    fun{$ X}
                                                                                                       X\=D
                                                                                                    end})}
                                                                              else
                                                                                 CtxOut=CtxIn
                                                                              end
                                                                           end
                      
                      ['pp_\\ifdef'  pp_whiteSpace defined whiteToEOL]#{Nest true}
                      ['pp_\\ifndef' pp_whiteSpace undefined whiteToEOL]#{Nest true}
                      ['pp_\\ifdef'  pp_whiteSpace undefined whiteToEOL ignore 'pp_\\else' whiteToEOL]#{Nest false}
                      ['pp_\\ifndef' pp_whiteSpace defined   whiteToEOL ignore 'pp_\\else' whiteToEOL]#{Nest false}
                      
                      ['pp_\\ifdef'  pp_whiteSpace undefined whiteToEOL ignore 'pp_\\endif' whiteToEOL]
                      ['pp_\\ifndef' pp_whiteSpace defined   whiteToEOL ignore 'pp_\\endif' whiteToEOL]
                      [ nestedCondE  'pp_\\else'   whiteToEOL ignore 'pp_\\endif' whiteToEOL]#Unnest
                      [ nestedCond   'pp_\\endif'  whiteToEOL]#Unnest
                      )
      nestedCondE: empty#proc{$ CtxIn SemIn CtxOut SemOut}
                            SemOut=SemIn
                            if CtxIn.valid then
                               CtxOut={AdjoinAt CtxIn valid CtxIn.condStack\=nil andthen CtxIn.condStack.1}
                            else
                               CtxOut=CtxIn
                            end
                         end
      nestedCond: empty#proc{$ CtxIn SemIn CtxOut SemOut}
                            SemOut=SemIn
                            if CtxIn.valid then
                               CtxOut={AdjoinAt CtxIn valid CtxIn.condStack\=nil}
                            else
                               CtxOut=CtxIn
                            end
                         end
      defined: pp_variable#proc{$ CtxIn SemIn CtxOut SemOut}
                            SemOut=SemIn
                            if CtxIn.valid then
                               CtxOut={AdjoinAt CtxIn valid {Member SemIn.1 CtxIn.defines}}
                            else
                               CtxOut=CtxIn
                            end
                         end
      undefined: pp_variable#proc{$ CtxIn SemIn CtxOut SemOut}
                                SemOut=SemIn
                                if CtxIn.valid then
                                   CtxOut={AdjoinAt CtxIn valid {Not {Member SemIn.1 CtxIn.defines}}}
                                else
                                   CtxOut=CtxIn
                                end
                             end
      ignore: alt(
                 [alt('pp_\\ifdef' 'pp_\\ifndef') ignore 'pp_\\else' ignore 'pp_\\endif' ignore]
                 [alt('pp_\\ifdef' 'pp_\\ifndef') ignore 'pp_\\endif' ignore]
                 seq1(alt(keyword
                          [nla(alt('pp_\\ifdef' 'pp_\\ifndef' 'pp_\\else' 'pp_\\endif')) symbol]
                          pp_string
                          pp_character
                          atomN
                          variableN
                          pp_float
                          pp_integer
                          simpleSpace comment &\r &\n) ignore)
                 empty
                 )
      whiteSpace: star(alt(simpleSpace comment &\r &\n preprocessor popFile))
      popFile: nla(wc)#proc{$ CtxIn SemIn CtxOut SemOut}
                          SemOut=SemIn
                          if CtxIn.valid andthen CtxIn.condStack==nil andthen CtxIn.fileStack\=nil then
                             CtxOut=CtxIn.fileStack.1
                          elseif CtxIn.valid then
                             CtxOut={AdjoinAt CtxIn valid false}
                          else
                             CtxOut=CtxIn
                          end
                       end
      %% tokens %%
      string: seq2(whiteSpace pp_string)
      character: seq2(whiteSpace pp_character)
      atom: seq2(whiteSpace pp_atom)
      variable: seq2(whiteSpace pp_variable)
      kwValue: seq2(whiteSpace pp_kwValue)#fun{$ K}fAtom(KWVal.(K.1) K.2)end
      atomL: seq2(whiteSpace pp_atomL)
      variableL: seq2(whiteSpace pp_variableL)
      kwValueL: seq2(whiteSpace pp_kwValueL)#fun{$ K}fAtom(KWVal.(K.1) K.2)end
      integer: seq2(whiteSpace pp_integer)
      float: seq2(whiteSpace pp_float)

      %% SYNTACTICAL ANALYSIS %%
      pB: seq2(whiteSpace pos)
      pE: pos

      %% top-level %%
      input: seq1(star(compilationUnit) atEnd)
      compilationUnit:alt(cuDirective cuDeclare phrase)
      cuDirective:alt(
                     ['\\switch'
                      star(
                         [pp_whiteSpace alt('pp_+' 'pp_-') pp_whiteSpace pp_atom]#fun{$ [_ S _ A]}
                                                                                     case S.1
                                                                                     of '+' then on(A.1 A.2)
                                                                                     [] '-' then off(A.1 A.2)
                                                                                     end
                                                                                  end
                         )
                      whiteToEOL]#fun{$ [_ Ss _]}dirSwitch(Ss)end
                     seq1('\\pushSwitches' whiteToEOL) #fun{$ _}dirPushSwitches end
                     seq1('\\popSwitches' whiteToEOL)  #fun{$ _}dirPopSwitches end
                     seq1('\\localSwitches' whiteToEOL)#fun{$ _}dirLocalSwitches end
                     )
      cuDeclare:alt(
                   [pB 'declare' phrase 'in' phrase pE]#fun{$ [P1 _ S1 _ S2 P2]}fDeclare(S1 S2        {MkPos P1 P2})end
                   [pB 'declare' phrase pE]            #fun{$ [P1 _ S1      P2]}fDeclare(S1 fSkip(P2) {MkPos P1 P2})end
                   )
      atEnd:[whiteSpace nla(wc)]#proc{$ CtxIn SemIn CtxOut SemOut}
                                    SemOut=SemIn
                                    if CtxIn.valid then
                                       CtxOut={AdjoinAt CtxIn valid CtxIn.condStack==nil andthen CtxIn.fileStack==nil}
                                    else
                                       CtxOut=CtxIn
                                    end
                                 end

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
              [pB '@' atPhrase pE]#fun{$ [P1 _ S1 P2]}fAt(S1 {MkPos P1 P2})end
              [pB '!!' atPhrase pE]#fun{$ [P1 _ S1 P2]}fOpApply('!!' [S1] {MkPos P1 P2})end
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
                  [alt(atomL variableL kwValueL) '(' star(subtree) opt(['...']) ')']#fun{$ [L _ Ts D _]}
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
                                                          else K#V.2.1
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
                     atom variable kwValue escVar
                     [alt(atomL variableL kwValueL escVarL)
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
      feature:alt(variable atom integer character kwValue)
      caseClause:alt(
                    [pB lvl0 'andthen' opt(seq1(phrase 'in') fSkip(unit)) phrase pE 'then' inPhrase]
                    #fun{$ [P1 S1 _ OS S2 P2 _ S3]}
                        fCaseClause(fSideCondition(S1 OS S2 {MkPos P1 P2}) S3)
                     end
                    [lvl0 'then' inPhrase]#fun{$ [S1 _ S2]}fCaseClause(S1 S2)end
                    )
      )

   TG={Translate {Record.adjoinList Rules RulesL}}

   fun {ParseContext CtxIn Defs}
      CtxOut
      Sem
   in
      {CtxIn.grammar.input CtxIn CtxOut Sem}
      if CtxOut.valid then
         {Dictionary.removeAll Defs}
         {ForAll CtxOut.defines proc{$ D}Defs.D:=true end}
         Sem#nil
      else
         parseError#[error(kind:'parse error' msg:'Parse error')]
      end
   end

   fun{ParseVS VS Opts}
      CtxIn={MkContext {VirtualString.toString VS}
             'top level' 1 0 false TG {Dictionary.keys Opts.defines} nil nil "./" ctx(valid:false)}
   in
      {ParseContext CtxIn Opts.defines}
   end

   fun{ParseFile FN Opts}
      CtxIn={MkContext {ReadFile "./" {VirtualString.toString FN}}
             {VirtualString.toAtom FN} 1 0 false TG {Dictionary.keys Opts.defines} nil nil "./" ctx(valid:false)}
   in
      {ParseContext CtxIn Opts.defines}
   end
end
