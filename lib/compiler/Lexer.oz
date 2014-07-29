%%% Copyright © 2013-2014, Université catholique de Louvain
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
   PEG

export
   OzKeywords
   OzSymbols

   TokenizeVS

define

   %% Grammar %%

   EofCh = &\032

   OzKeywords = [
      'andthen' 'at' 'attr' 'case' 'catch' 'choice'
      'class' 'cond' 'declare' 'define' 'dis' 'do'
      'div' 'else' 'elsecase' 'elseif' 'elseof' 'end'
      'export' 'fail' 'feat' 'finally' 'from' 'for'
      'fun' 'functor' 'if' 'import' 'in' 'local'
      'lock' 'meth' 'mod' 'not' 'of' 'or' 'orelse'
      'prepare' 'proc' 'prop' 'raise' 'require'
      'self' 'skip' 'suchthat' 'then' 'thread' 'try'
   ]

   OzKeywordTokens0 = {Record.make kw OzKeywords}
   {ForAll OzKeywords proc {$ Kw} OzKeywordTokens0.Kw = Kw end}

   OzKeywordTokens1 =
   kw('true':tkAtom(true)
      'false':tkAtom(false)
      'unit':tkAtom(unit))

   OzKeywordTokens = {Adjoin OzKeywordTokens0 OzKeywordTokens1}

   OzSymbols0 = [
      '(' ')' '[' ']' '{' '}'
      '|' '#' ':' '...' '=' '.' ':=' '^' '[]' '$'
      '!' '_' '~' '+' '-' '*' '/' '@' '<-'
      ',' '!!' '<=' '==' '\\=' '<' '=<' '>'
      '>=' '=:' '\\=:' '<:' '=<:' '>:' '>=:' '::' ':::'
      '..' ';'
   ]

   OzSymbols = {List.sort OzSymbols0
                fun {$ L1 L2}
                   {VirtualString.length L1} > {VirtualString.length L2}
                end}

   TokenRules =
   g(
      %% top-level %%

      input: alt(
         float
         inputNoFloat
      )

      inputNoFloat: alt(
         whitespaceToken
         varKwOrAtomMaybeLabel
         integer
         character
         string
         symbol
         EofCh # tkEof
         seq2(&\\ preprocesorDirective)
         wc # tkParseError('Scan error')
      )

      %% whitespace %%

      whitespace:      star(whitespaceItem)
      whitespaceItem:  alt(simpleSpace comment)
      simpleSpace:     alt(&\t &\v &\f & )
      newLine:         alt(&\r &\n)
      comment:         alt(&? blockComment [&% star([nla(alt(newLine EofCh)) wc])])
      blockComment:    ["/*" star(alt(
                                     [nla("/*") nla("*/") nla(EofCh) wc]
                                     blockComment
                                     )) "*/"]

      %% tokens %%

      whitespaceToken: plus(alt(newLine whitespaceItem)) # tkWhitespace

      varKwOrAtomMaybeLabel:
         [alt(variable atomOrKw) pla(alt(&( empty))] #
         fun {$ [IdentKwOrAtom OptParen]}
            if OptParen == nil then
               IdentKwOrAtom
            elsecase IdentKwOrAtom
            of tkVariable(Name) then
               tkVariableLabel(Name)
            [] tkAtom(Value) then
               tkAtomLabel(Value)
            else
               IdentKwOrAtom
            end
         end

      variable: alt(
         seq(ucLetter star(alNum)) #
         fun {$ Name}
            tkVariable({String.toAtom Name})
         end
         [&` star(variableChar) &`] #
         fun {$ [_ L _]}
            tkVariable({String.toAtom &`|{Append L "`"}})
         end
      )

      atomOrKw: alt(
         seq(lcLetter star(alNum)) #
         fun {$ Name}
            NameAtom = {String.toAtom Name}
         in
            {CondSelect OzKeywordTokens NameAtom tkAtom(NameAtom)}
         end
         [&' star(atomChar) &'] #
         fun {$ [_ L _]}
            tkAtom({String.toAtom L})
         end
      )

      atom: is(atomOrKw fun {$ Tok}
                           case Tok of tkAtom(_) then true else false end
                        end)

      string:
         [&" star(stringChar) &"] #
         fun {$ [_ L _]}
            tkString(L)
         end

      character:
         seq2(&& alt(seq2(nla(alt(&\\ 0)) wc) pseudoChar)) #
         fun {$ C} tkCharacter(C) end

      integer:
         [
            opt("~")
            alt(
               nzDigit|star(digit)
               &0|alt(&x &X)|plus(hexDigit)
               &0|alt(&b &B)|plus(binDigit)
               plus(octDigit)
            )
         ] #
         fun {$ [S L]}
            tkInteger({String.toInt {Append S L}})
         end

      float:
         [
            opt("~")
            plus(digit)
            seq1(&. nla(&.))|star(digit)
            opt([alt(&e &E) opt("~") plus(digit)])
         ] #
         fun {$ [S M D E]}
            tkFloat({String.toFloat {Flatten [S M D E]}})
         end

      symbol:
         alt({Map OzSymbols fun {$ Sym} {AtomToString Sym} # Sym end})

      %% preprocessor directives %%

      preprocesorDirective: seq1(alt(
         seq2(
            "switch"
            star(
               [whitespace alt(&+ &-) whitespace atom] #
               fun {$ [_ S _ A]}
                  case S
                  of &+ then on(A.1)
                  [] &- then off(A.1)
                  end
               end
            )
         ) #
         fun {$ Ss}
            tkDirSwitch(Ss)
         end

         alt(
            "showSwitches" "pushSwitches" "popSwitches" "localSwitches"
            "else" "endif"
         ) # fun {$ D} tkPreprocessorDirective({String.toAtom D}) end

         [
            alt("define" "undef" "ifdef" "ifndef")
            whitespace
            preprocessorVar
         ] # fun {$ [D _ V]} tkPreprocessorDirective({String.toAtom D} V) end

         [
            "insert"
            whitespace
            preprocessorFileName
         ] # fun {$ [_ _ F]} tkPreprocessorDirective('insert' F) end

         [
            "line"
            opt(seq2(whitespace preprocessorInteger))
            opt(seq2(whitespace preprocessorFileName))
         ] # fun {$ [_ Line FileName]} tkPreprocessorLine(Line FileName) end
      ) [whitespace alt(newLine pla(EofCh))])

      preprocessorVar:
         seq(ucLetter star(alNum)) #
         fun {$ V} {String.toAtom V} end

      preprocessorInteger:
         integer # fun {$ Tok} Tok.1 end

      preprocessorFileName: alt(
         plus(alt(alNum &/ &_ &~ &. &-))
         [&' star(atomChar) &'] # fun {$ [_ L _]} L end
      )

      %% character classes %%

      ucLetter:  is(wc Char.isUpper)
      lcLetter:  is(wc Char.isLower)
      digit:     is(wc Char.isDigit)
      nzDigit:   seq2(nla(&0) digit)
      alNum:     alt(ucLetter lcLetter digit &_)
      binDigit:  alt(&0 &1)
      octDigit:  alt(&0 &1 &2 &3 &4 &5 &6 &7)
      octDigitV: octDigit # fun {$ X} X-&0 end
      hexDigit:  alt(digit &a &b &c &d &e &f &A &B &C &D &E &F)
      hexDigitV: alt(
         digit                  # fun {$ X} X-&0 end
         alt(&a &b &c &d &e &f) # fun {$ X} 10+X-&a end
         alt(&A &B &C &D &E &F) # fun {$ X} 10+X-&A end
      )
      pseudoChar: seq2(&\\ alt(
         [ octDigitV octDigitV octDigitV] # fun {$ [A B C]} A*64+B*8+C end
         [alt(&x &X) hexDigitV hexDigitV] # fun {$ [_ A B]} A*16+B end
         &a # &\a
         &b # &\b
         &f # &\f
         &n # &\n
         &r # &\r
         &t # &\t
         &v # &\v
         &\\ &' &" &` &&
      ))
      variableChar: alt(
         seq2(nla(alt(&` &\\ 0 EofCh)) wc)
         pseudoChar
      )
      atomChar: alt(
         seq2(nla(alt(&' &\\ 0 EofCh)) wc)
         pseudoChar
      )
      stringChar: alt(
         seq2(nla(alt(&" &\\ 0 EofCh)) wc)
         pseudoChar
      )
   )

   TokenGrammar = {PEG.translate TokenRules opts(useCache:false handleErrors:false)}

   %% Functions %%

   local
      proc {DoMakeStringContext Input FileName Line Column ?Result}
         {WaitNeeded Result}
         Pos = pos(FileName Line Column)
      in
         case Input
         of nil then
            Result = ctx(valid:true first:EofCh pos:Pos input:Input rest:Result)
         [] H|T then
            NextResult
         in
            Result = ctx(valid:true first:H pos:Pos input:Input rest:!!NextResult)

            if H == &\n orelse
               (H == &\r andthen case T of &\n|_ then false else true end) then
               {DoMakeStringContext T FileName Line+1 1 ?NextResult}
            else
               {DoMakeStringContext T FileName Line Column+1 ?NextResult}
            end
         end
      end
   in
      fun {MakeStringContext S FileName Line Column}
         !!thread {DoMakeStringContext S FileName Line Column} end
      end
   end

   proc {DoTokenize CtxIn PrevWasDot ?Result}
      CtxOut Token
   in
      % If the previous token was a '.', disable parsing of a float
      % Rationale: parse L.2.1 as (L.2).1, and not L.(2.1)
      if PrevWasDot then
         {TokenGrammar.inputNoFloat CtxIn ?CtxOut ?Token}
      else
         {TokenGrammar.input CtxIn ?CtxOut ?Token}
      end

      % Always valid because we handle the parse error in the grammar
      true = CtxOut.valid

      case Token
      of tkWhitespace then
         {DoTokenize CtxOut PrevWasDot ?Result}

      [] tkPreprocessorLine(OptLine OptFileName) then
         FileName = if OptFileName == nil then CtxOut.pos.1 else OptFileName end
         Line = if OptLine == nil then CtxOut.pos.2 else OptLine end
         NewCtx = {MakeStringContext CtxOut.input FileName Line 1}
      in
         {DoTokenize NewCtx false ?Result}

      [] tkEof then
         Result = reader(tkEof CtxIn.pos#CtxOut.pos true Result)

      [] tkParseError(_) then
         Result = reader(Token CtxIn.pos#CtxOut.pos true Result)

      else
         NextResult
      in
         Result = reader(Token CtxIn.pos#CtxOut.pos false NextResult)
         {DoTokenize CtxOut (Token == '.') ?NextResult}
      end
   end

   /** Tokenize the contents of an Oz source virtual string
    *  @param VS         Virtual string to tokenize
    *  @param FileName   File name for positions
    *  @return A reader of the tokens in the VS
    */
   fun {TokenizeVS VS FileName}
      CtxIn = {MakeStringContext {VirtualString.toString VS} FileName 1 1}
   in
      {DoTokenize CtxIn /* PrevWasDot = */ false}
   end

end
