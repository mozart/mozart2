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
   System(show:Show)
export
   Translate
define
   fun{Translate WG}
      fun{TranslateRule G}
         case G
         of empty() then
            proc{$ CtxIn CtxOut Sem}
               CtxOut=CtxIn
               Sem=nil
            end
         [] seq(X Y) then
            XX={TranslateRule X}
            YY={TranslateRule Y}
         in
            proc{$ CtxIn CtxOut Sem} CtxMid Sem1 Sem2 in
               {XX CtxIn CtxMid Sem1}
               if CtxMid.valid then
                  Sem=Sem1|Sem2
                  {YY CtxMid CtxOut Sem2}
               else
                  Sem=Sem1
                  CtxOut=CtxMid
               end
            end
         [] seq(nil) then {TranslateRule empty}
         [] seq(X|Xr) then {TranslateRule seq(X seq(Xr))}
         [] seq(X) then {TranslateRule X}
         [] seq2(X Y) then
            XX={TranslateRule X}
            YY={TranslateRule Y}
         in
            proc{$ CtxIn CtxOut Sem} CtxMid Sem1 in
               {XX CtxIn CtxMid Sem1}
               if CtxMid.valid then
                  {YY CtxMid CtxOut Sem}
               else
                  Sem=Sem1
                  CtxOut=CtxMid
               end
            end
         [] seq1(X Y) then
            XX={TranslateRule X}
            YY={TranslateRule Y}
         in
            proc{$ CtxIn CtxOut Sem} CtxMid in
               {XX CtxIn CtxMid Sem}
               if CtxMid.valid then
                  {YY CtxMid CtxOut _}
               else
                  CtxOut=CtxMid
               end
            end
         [] alt(X Y) then
            XX={TranslateRule X}
            YY={TranslateRule Y}
         in
            proc{$ CtxIn CtxOut Sem} CtxTmp Sem1 Sem2 in
               {XX CtxIn CtxTmp Sem1}
               if CtxTmp.valid then
                  Sem=Sem1
                  CtxOut=CtxTmp
               else
                  {YY CtxIn CtxOut Sem2}
                  if CtxOut.valid then
                     Sem=Sem2
                  else
                     Sem=Sem1#Sem2
                  end
               end
            end
         [] alt(nil) then {TranslateRule nla(empty)}
         [] alt([X]) then {TranslateRule X}
         [] alt(X|Xr) then {TranslateRule alt(X alt(Xr))}
         [] nla(X) then
            XX={TranslateRule X}
         in
            proc{$ CtxIn CtxOut Sem} CtxTmp in
               {XX CtxIn CtxTmp Sem}
               if CtxTmp.valid then
                  CtxOut={AdjoinAt CtxIn valid false}
               else
                  CtxOut=CtxIn
               end
            end
         [] pla(X) then
            XX={TranslateRule X}
         in
            proc{$ CtxIn CtxOut Sem} CtxTmp in
               {XX CtxIn CtxTmp Sem}
               if CtxTmp.valid then
                  CtxOut=CtxIn
               else
                  CtxOut={AdjoinAt CtxIn valid false}
               end
            end
         [] sem(X P) then
            XX={TranslateRule X}
         in
            proc{$ CtxIn CtxOut Sem} CtxMid SemMid in
               {XX CtxIn CtxMid SemMid}
               {P CtxMid SemMid CtxOut Sem}
            end
         [] nt(X) then
            proc{$ CtxIn CtxOut Sem} N in
               true=CtxIn.valid
               case {Dictionary.condExchange CtxIn.cache X unit $ N}
               of unit then
                  N=CtxOut#Sem
                  {CtxIn.grammar.X CtxIn CtxOut Sem}
               [] Ctx#S then
                  N=Ctx#S
                  CtxOut=Ctx
                  Sem=S
               end
            end
         [] cache(X P) then
            if {IsFree P} then
               Id={NewName} XX in
               proc{P CtxIn CtxOut Sem} N in
                  true=CtxIn.valid
                  case {Dictionary.condExchange CtxIn.cache Id unit $ N}
                  of unit then
                     N=CtxOut#Sem
                     {XX CtxIn CtxOut Sem}
                  [] Ctx#S then
                     N=Ctx#S
                     CtxOut=Ctx
                     Sem=S
                  end
               end
               XX={TranslateRule X}
            end
            P
         [] wc then
            proc{$ CtxIn CtxOut Sem}
               true=CtxIn.valid
               Pair=CtxIn.value in
               CtxOut=Pair.1
               Sem=Pair.2
            end
         [] ts(nil) then {TranslateRule empty}
         [] ts(X|Xr) then
            {TranslateRule seq(is(wc fun{$ Y}X==Y end) ts(Xr))}
         [] is(X P) then
            XX={TranslateRule X} in
            proc{$ CtxIn CtxOut Sem} CtxTmp in
               {XX CtxIn CtxTmp Sem}
               if CtxTmp.valid then
                  CtxOut={AdjoinAt CtxTmp valid {P Sem}}
               else
                  CtxOut=CtxTmp
               end
            end
         [] star(X) then
            R=cache(alt(seq(X R) empty) _)
         in
            {TranslateRule R}
         [] plus(X) then
            R=cache(alt(seq(X R) seq(X empty)) _)
         in
            {TranslateRule R}
         [] sep(X Y) then
            {TranslateRule seq(X star(seq2(Y X)))}
         [] opt(X) then
            {TranslateRule alt(X empty)}
         [] opt(X Y) then
            {TranslateRule alt(X empty#fun{$ _}Y end)}
         [] X andthen {Literal.is X} andthen {HasFeature WG X} then
            {TranslateRule nt(X)}
         [] nil then {TranslateRule empty}
         [] _|_ then {TranslateRule seq(G)}
         [] X#P andthen {Procedure.arity P}==4 then
            {TranslateRule sem(X P)}
         [] X#P andthen {Procedure.arity P}==2 then
            {TranslateRule sem(X proc{$ Cin Sin Cout Sout}
                                    Cout=Cin
                                    if Cin.valid then
                                       Sout={P Sin}
                                    else
                                       Sout=Sin
                                    end
                                 end)}
         elseif {Char.is G} then
            {TranslateRule is(wc fun{$ X}X==G end)}
         elsecase {Label G}
         of alt then {TranslateRule alt({Record.toList G})}
         else {Show error(G)} unit
         end
      end
   in
      {Record.map WG TranslateRule}
   end
end
