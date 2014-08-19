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
   System(show:Show)
   Boot_Record at 'x-oz://boot/Record'
   Boot_Dictionary at 'x-oz://boot/Dictionary'
export
   Translate
   ParseErrorToMessage
define
   DictCondExchangeFun = Boot_Dictionary.condExchangeFun

   fun {CtxPos Ctx}
      if {HasFeature Ctx pos} then
         Ctx.pos
      elseif {HasFeature Ctx posbegin} then
         Ctx.posbegin
      else
         unknown
      end
   end

   fun {NewError Ctx ErrorMessages}
      if {HasFeature Ctx pos} then
         error(ErrorMessages pos: Ctx.pos)
      elseif {HasFeature Ctx posbegin} then
         error(ErrorMessages pos: Ctx.posbegin)
      else % Unknown position
         error(ErrorMessages)
      end
   end

   proc {FailedCtxWithError Ctx ErrorMessages ?Result}
     CtxTmp
     Error = {NewError Ctx ErrorMessages}
  in
      {Boot_Record.adjoinAtIfHasFeature Ctx valid false ?CtxTmp true}
      Result = {AdjoinAt CtxTmp error Error}
   end

   proc {FailedCtxWithoutError Ctx ErrorMessages ?Result}
      {Boot_Record.adjoinAtIfHasFeature Ctx valid false ?Result true}
   end

   fun {ComparePos pos(F1 L1 C1) pos(F2 L2 C2)}
      if F1 \= F2 then unknown
      elseif L1 > L2 then greaterThan
      elseif L1 < L2 then lessThan
      else
         if C1 > C2 then greaterThan
         elseif C1 < C2 then lessThan
         else equal
         end
      end
   end

   fun {CompareError E1 E2}
      case E1#E2
      of error(_ pos: P1)#error(_ pos: P2) then {ComparePos P1 P2}
      else unknown
      end
   end

   fun {MergeErrors E1 E2}
      case {CompareError E1 E2}
      of unknown     then E2
      [] lessThan    then E2
      [] greaterThan then E1
      [] equal       then
         case E1#E2 of error(M1 pos: P1)#error(M2 pos: _) then
            error({Append
                   {Filter M1 fun {$ X} {Not {Member X M2}} end}
                   M2} pos: P1)
         end
      end
   end

   fun {AddErrorMessageWithError Ctx Msg}
      {AdjoinAt Ctx
       error if {HasFeature Ctx error} then
                if {Member Msg Ctx.error.1} then Ctx.error
                else {AdjoinAt Ctx.error 1 Msg|Ctx.error.1}
                end
             else {NewError Ctx [Msg]}
             end}
   end

   fun {AddErrorMessageWithoutError Ctx Msg} Ctx end

   fun {MergeContextsWithError C1 C2}
      if {HasFeature C1 error} then
         if {HasFeature C2 error} then
            {AdjoinAt C2 error {MergeErrors C1.error C2.error}}
         else
            {AdjoinAt C2 error C1.error}
         end
      else C2
      end
   end

   fun {MergeContextsWithoutError C1 C2} C2 end

   proc{Translate WG Opts ?TG}
      UseCache = {CondSelect Opts useCache false}
      HandleErrors = {CondSelect Opts handleErrors true}
      NoCache = {CondSelect Opts noCache noCache}

      MergeContexts = if HandleErrors then MergeContextsWithError
                      else MergeContextsWithoutError
                      end
      FailedCtx = if HandleErrors then FailedCtxWithError
                  else FailedCtxWithoutError
                  end

      AddErrorMessage = if HandleErrors then AddErrorMessageWithError
                        else AddErrorMessageWithoutError
                        end

      TemporaryRules = {Dictionary.new}

      fun {LookupRule Name}
         local Result in
            {Dictionary.condExchange TemporaryRules Name _ Result Result}
            Result
         end
      end

      fun{TranslateRule G}
         case G
         of raw(P) then
            P
         [] success(S) then
            proc{$ CtxIn CtxOut Sem}
               CtxOut = CtxIn
               Sem=S
            end
         [] empty then
            proc{$ CtxIn CtxOut Sem}
               CtxOut=CtxIn
               Sem=nil
            end
         [] seq(X Y) then
            XX={TranslateRule X}
            YY={TranslateRule Y}
         in
            proc{$ CtxIn CtxOut Sem} CtxMid CtxEnd Sem1 Sem2 in
               {XX CtxIn CtxMid Sem1}
               if CtxMid.valid then
                  Sem=Sem1|Sem2
                  {YY CtxMid CtxEnd Sem2}
                  CtxOut = {MergeContexts CtxMid CtxEnd}
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
            proc{$ CtxIn CtxOut Sem} CtxMid CtxEnd Sem1 in
               {XX CtxIn CtxMid Sem1}
               if CtxMid.valid then
                  {YY CtxMid CtxEnd Sem}
                  CtxOut = {MergeContexts CtxMid CtxEnd}
               else
                  Sem=Sem1
                  CtxOut=CtxMid
               end
            end
         [] seq1(X Y) then
            XX={TranslateRule X}
            YY={TranslateRule Y}
         in
            proc{$ CtxIn CtxOut Sem} CtxMid CtxEnd in
               {XX CtxIn CtxMid Sem}
               if CtxMid.valid then
                  {YY CtxMid CtxEnd _}
                  CtxOut = {MergeContexts CtxMid CtxEnd}
               else
                  CtxOut=CtxMid
               end
            end
         [] alt(X Y) then
            XX={TranslateRule X}
            YY={TranslateRule Y}
         in
            proc{$ CtxIn CtxOut Sem} Ctx1 Ctx2 Sem1 Sem2 in
               {XX CtxIn Ctx1 Sem1}
               if Ctx1.valid then
                  Sem=Sem1
                  CtxOut=Ctx1
               else
                  {YY CtxIn Ctx2 Sem2}
                  CtxOut = {MergeContexts Ctx1 Ctx2}
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
                  CtxOut = {FailedCtx CtxIn nil}
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
                  CtxOut={FailedCtx CtxIn nil}
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
            Rule = {LookupRule X}
         in
            if UseCache andthen {Not {HasFeature NoCache X}} then
               proc{$ CtxIn CtxOut Sem} N in
                  true=CtxIn.valid
                  case {DictCondExchangeFun CtxIn.cache X unit N $}
                  of unit then
                     N=CtxOut#Sem
                     {Rule CtxIn CtxOut Sem}
                  [] Ctx#S then
                     N=Ctx#S
                     CtxOut=Ctx
                     Sem=S
                  end
               end
            else
               Rule
            end
         [] cache(X) then
            {TranslateRule cache(X _)}
         [] cache(X P) then
            true = UseCache
            if {IsFree P} then
               Id={NewName} XX in
               proc{P CtxIn CtxOut Sem} N in
                  true=CtxIn.valid
                  case {DictCondExchangeFun CtxIn.cache Id unit N $}
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
               CtxOut={MergeContexts CtxIn CtxIn.rest}
               Sem=CtxIn.first
            end
         [] ts(nil) then {TranslateRule empty}
         [] ts(X|Xr) then
            {TranslateRule seq(is(wc fun{$ Y}X==Y end) ts(Xr))}
         [] is(wc P) then
            proc {$ CtxIn CtxOut Sem}
               true = CtxIn.valid
               Sem = CtxIn.first
               if {P Sem} then
                  CtxOut = {MergeContexts CtxIn CtxIn.rest}
               else
                  CtxOut = {FailedCtx CtxIn.rest nil}
               end
            end
         [] is(X P) then
            XX={TranslateRule X} in
            proc{$ CtxIn CtxOut Sem} CtxTmp in
               {XX CtxIn CtxTmp Sem}
               if CtxTmp.valid then
                  if {P Sem} then
                     CtxOut = CtxTmp
                  else
                     CtxOut = {FailedCtx CtxTmp nil}
                  end
               else
                  CtxOut=CtxTmp
               end
            end
         [] elem(P) andthen {IsProcedure P} then
            proc {$ CtxIn CtxOut Sem}
               true = CtxIn.valid
               V = CtxIn.first in
               case {P V}
               of some(Sem0) then
                  CtxOut = {MergeContexts CtxIn CtxIn.rest}
                  Sem = Sem0
               [] false then
                  CtxOut = {FailedCtx CtxIn.rest nil}
                  Sem = V
               end
            end
         [] elem(V) then
            proc {P CtxIn CtxOut Sem}
               true = CtxIn.valid in
               Sem = CtxIn.first
               if Sem == V then
                  CtxOut = {MergeContexts CtxIn CtxIn.rest}
               else
                  CtxOut = {FailedCtx CtxIn.rest nil}
               end
            end
         in
            {TranslateRule label('\''#V#'\'' raw(P))}
         [] star(X) then
            XX={TranslateRule X}
            proc {P CtxIn CtxOut Sem} CtxMid CtxEnd Sem1 Sem2 in
               {XX CtxIn CtxMid Sem1}
               if CtxMid.valid then
                  Sem=Sem1|Sem2
                  {P CtxMid CtxEnd Sem2}
                  CtxOut = {MergeContexts CtxMid CtxEnd}
               else
                  Sem=nil
                  CtxOut= {MergeContexts CtxMid CtxIn}
               end
            end
         in
            P
         [] plus(X) then
            XX={TranslateRule X}
         in
            {TranslateRule seq(raw(XX) star(raw(XX)))}
         [] sep(X Y) then
            XX={TranslateRule X}
         in
            {TranslateRule seq(raw(XX) star(seq2(Y raw(XX))))}
         [] opt(X) then
            {TranslateRule alt(X empty)}
         [] opt(X Y) then
            {TranslateRule alt(X empty#fun{$ _}Y end)}
         [] label(Label X) then
            XX = {TranslateRule X}
         in
            proc {$ CtxIn CtxOut Sem} CtxMid in
               {XX CtxIn CtxMid Sem}
               CtxOut = {AdjoinAt CtxMid error {NewError CtxIn [expected(Label)]}}
            end
         [] context(Context X) then
            XX = {TranslateRule X}
         in
            proc {$ CtxIn CtxOut Sem} CtxMid in
               {XX CtxIn CtxMid Sem}
               CtxOut = {AddErrorMessage CtxMid context(Context {CtxPos CtxIn})}
            end
         [] X andthen {Literal.is X} andthen {HasFeature WG X} then
            {TranslateRule nt(X)}
         [] nil then {TranslateRule empty}
         [] _|_ then {TranslateRule seq(G)}
         [] X#R andthen {Not {IsProcedure R}} then
            {TranslateRule sem(X proc{$ Cin Sin Cout Sout}
                                    Cout=Cin
                                    if Cin.valid then
                                       Sout=R
                                    else
                                       Sout=Sin
                                    end
                                 end)}
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
         elsecase G
         of alt(...) then {TranslateRule alt({Record.toList G})}
         else {Show error(G)} unit
         end
      end
   in
      {Record.forAllInd WG
       proc {$ RuleName Production}
          {LookupRule RuleName} = {TranslateRule Production}
       end}

      TG = {Dictionary.toRecord g TemporaryRules}
   end

   local
      MaxShownTokens = 10

      fun {GroupBy F Xs}
         case Xs
         of X|Xr then
            V = {F X}
            GroupX Rest
         in
            {List.takeDropWhile Xr fun {$ Y} {F Y} == V end GroupX Rest}
            (X|GroupX)|{GroupBy F Rest}
         [] nil then nil
         end
      end

      fun {JoinWithOr Messages}
         case Messages
         of [A]   then A
         [] [A B] then A#' or '#B
         [] X|Xs  then X#', '#{JoinWithOr Xs}
         [] nil   then nil
         end
      end

      fun {ExpectedTokens Messages}
         {Reverse
          {Map {Filter Messages fun {$ X} {Label X} == expected end}
           fun {$ expected(X)} X end}}
      end

      proc {FormatExpected Messages ?Message ?ExtraItem}
         Tokens = {ExpectedTokens Messages}
      in
         case Tokens
         of nil then
            Message = 'parse error'
            ExtraItem = nil
         [] [Token] then
            Message = {VirtualString.toAtom 'expected '#Token}
            ExtraItem = nil
         [] Token|ExtraTokens then
            Message = {VirtualString.toAtom 'expected '#Token}

            local
               TokensToShow Hidden
               {List.takeDrop ExtraTokens MaxShownTokens TokensToShow Hidden}

               ListToShow = if Hidden == nil then
                               TokensToShow
                            else
                               HiddenCount = {Length Hidden}
                            in
                               {Append TokensToShow
                                if HiddenCount == 1 then
                                   Hidden.1
                                else
                                   ["one of "#HiddenCount#" others"]
                                end}
                            end
            in
               ExtraItem = line('(other candidates: '#{JoinWithOr ListToShow}#')')
            end
         end
      end

      fun {ContextLessThan context(_ PosA) context(_ PosB)}
         {ComparePos PosA PosB} == greaterThan
      end

      fun {SortedContexts Messages Pos}
         {Sort {Filter Messages fun {$ M}
                                   {Label M} == context andthen
                                   {ComparePos Pos M.2} == greaterThan
                                end}
          ContextLessThan}
      end

      fun {GroupedContexts Messages Pos}
         {Map {GroupBy fun {$ X} X.2 end {SortedContexts Messages Pos}}
          fun {$ Contexts}
             Pos = (Contexts.1).2
          in
             context({Map Contexts fun {$ C} C.1 end} pos: Pos)
          end}
      end

      fun {FormatContexts Messages Pos}
         {Map {GroupedContexts Messages Pos}
          fun {$ context(Contexts pos: Pos)}
             hint(l: Pos m: 'inside '#{JoinWithOr Contexts})
          end}
      end
   in
      fun {ParseErrorToMessage error(Messages pos: Pos)}
         Message ExtraItem
         Contexts = {FormatContexts Messages Pos}
      in
         {FormatExpected Messages Message ExtraItem}
         error(kind:'parse error' msg: Message
               items: if ExtraItem == nil then Pos|Contexts
                      else ExtraItem|Pos|Contexts
                      end)
      end
   end
end
