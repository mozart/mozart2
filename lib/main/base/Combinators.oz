%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1999
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%declare

local
   NewSpace   = Space.new
   DictWaitOr = Boot_Dictionary.waitOr
   Ask        = Boot_Space.askUnsafe

   local
      proc {Skip}
         skip
      end
   in
      fun {Guardify C}
         case {Procedure.arity C}
         of 1 then C
         [] 0 then fun {$} {C} Skip end
         end
      end
      fun {NewGuard C}
         {NewSpace {Guardify C}}
      end
   end

   proc {CommitGuard G}
      {{Space.merge G}}
   end

   fun {DerefCheck S}
      if {IsDet S} then
         case S
         of blocked(S)      then {DerefCheck S}
         [] alternatives(_) then suspended
         [] succeeded(S)    then S
         else S
         end
      else S
      end
   end

   fun {Deref S}
      case S
      of blocked(S)      then {Deref S}
      [] alternatives(_) then suspended
      [] succeeded(S)    then S
      else S
      end
   end

   proc {WUHFI}
      {Wait _}
   end

   local
      proc {Init N C G A}
         if N>0 then NG={NewGuard C.N} in
            G.N=NG {Dictionary.put A N {Ask NG}}
            {Init N-1 C G A}
         end
      end
   in
      proc {InitGuards N C ?G ?A}
         G={MakeTuple '#' N}
         A={Dictionary.new}
         {Init N C G A}
      end
   end

   proc {DiscardGuards Is G}
      case Is of nil then skip
      [] I|Ir then {Space.discard G.I} {DiscardGuards Ir G}
      end
   end

   local
      proc {Cond1 C E}
         G={NewGuard C}
      in
         case {Deref {Ask G}}
         of failed    then {E}
         [] entailed  then {CommitGuard G}
         [] suspended then {WUHFI}
         end
      end

      proc {Resolve G A N B E}
         if N==0 then
            if B then {WUHFI} else {E} end
         else
            I  = {DictWaitOr A}
            AI = {DerefCheck {Dictionary.get A I}}
         in
            if {IsDet AI} then
               {Dictionary.remove A I}
               case AI
               of failed    then
                  {Resolve G A N-1 B E}
               [] suspended then
                  {Space.discard G.I}
                  {Resolve G A N-1 true E}
               [] entailed then
                  {DiscardGuards {Dictionary.keys A} G}
                  {CommitGuard G.I}
               end
            else
               {Dictionary.put A I AI}
               {Resolve G A N B E}
            end
         end
      end
   in
      proc {Cond C E}
         case {Width C}
         of 0 then {E}
         [] 1 then {Cond1 C.1 E}
         [] N then G A in
            {InitGuards N C G A}
            {Resolve G A N false E}
         end
      end
   end


   local
      proc {WaitFailed G A N}
         if N>0 then
            I  = {DictWaitOr A}
            AI = {DerefCheck {Dictionary.get A I}}
         in
            if {IsDet AI} then
               {Dictionary.remove A I}
               if AI==failed then
                  {WaitFailed G A N-1}
               else
                  {WUHFI}
               end
            else
               {Dictionary.put A I AI}
               {WaitFailed G A N}
            end
         end
      end
      proc {Resolve G A N}
         if N>1 then
            I  = {DictWaitOr A}
            AI = {DerefCheck {Dictionary.get A I}}
         in
            if {IsDet AI} then
               {Dictionary.remove A I}
               if AI==failed then
                  {Resolve G A N-1}
               else
                  {WaitFailed G A N-1}
                  {CommitGuard G.I}
               end
            else
               {Dictionary.put A I AI}
               {Resolve G A N}
            end
         else [I]={Dictionary.keys A} in
            {CommitGuard G.I}
         end
      end
   in
      proc {Or C}
         case {Width C}
         of 0 then fail
         [] 1 then {{{Guardify C.1}}}
         [] N then G A in
            {InitGuards N C G A}
            {Resolve G A N}
         end
      end
   end

   local
      proc {CommitOrDiscard G J I}
         if I==J then {CommitGuard G} else {Space.discard G} end
      end
      Tell    = Boot_Combinators.tell
      Reflect = Boot_Combinators.reflect
      local
         fun {ExpandPair L U Xs}
            if L=<U then L|{ExpandPair L+1 U Xs} else Xs end
         end
      in
         fun {Expand Xs}
            case Xs of nil then nil
            [] X|Xr then
               case X of L#R then {ExpandPair L R {Expand Xr}}
               else X|{Expand Xr}
               end
            end
         end
      end
      proc {Control G A J I}
         {WaitOr A I}
         if {IsDet I} then {CommitOrDiscard G J I}
         else DA={DerefCheck A} in
            if {IsDet DA} then
               case DA
               of failed then {Tell compl(J) I}
               [] merged then skip
               else {CommitOrDiscard G J I}
               end
            else {Control G DA J I}
            end
         end
      end
   in
      proc {Dis C}
         case {Width C}
         of 0 then fail
         [] 1 then {{{Guardify C.1}}}
         [] N then I in
            {Tell 1#N I}
            {For 1 N 1 proc {$ J}
                          G={NewGuard C.J}
                       in
                          thread {Control G {Ask G} J I} end
                       end}
            {Space.waitStable}
            if {IsDet I} then skip else
               I={Space.choose {List.toTuple '#' {Expand {Reflect I}}}}
            end
         end
      end
   end

   proc {Choice C}
      {{Space.choose C}}
   end

in

   Combinators = combinators('choice': Choice
                             'or':     Or
                             'dis':    Dis
                             'cond':   Cond)

end
