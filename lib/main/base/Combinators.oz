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
   NewSpace = Space.new
   WaitOr   = Boot_Dictionary.waitOr
%   [BS]={Module.link ['x-oz://boot/Space']}
%   Ask      = BS.askUnsafe
   Ask      = Boot_Space.askUnsafe

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
            I  = {WaitOr A}
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
            I  = {WaitOr A}
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
            I  = {WaitOr A}
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
      skip
   in
      proc {Dis C}
         case {Width C}
         of 0 then fail
         [] 1 then {{{Guardify C.1}}}
         [] 2 then
            dis B in B={{Guardify C.1}} then {B}
            []  B in B={{Guardify C.2}} then {B}
            end
         [] 3 then
            dis B in B={{Guardify C.1}} then {B}
            []  B in B={{Guardify C.2}} then {B}
            []  B in B={{Guardify C.3}} then {B}
            end
         [] 4 then
            dis B in B={{Guardify C.1}} then {B}
            []  B in B={{Guardify C.2}} then {B}
            []  B in B={{Guardify C.3}} then {B}
            []  B in B={{Guardify C.4}} then {B}
            end
         end
      end
   end

   proc {Choice C}
      {{Space.register C}}
   end

in

   Combinators = combinators('choice': Choice
                             'or':     Or
                             'dis':    Dis
                             'cond':   Cond)

end



/*

declare A={MakeTuple '#' 4}

declare
fun {Guard A I}
   fun {$}
      {For 1 {Width A}-1 1 proc {$ I} A.I=1 end}
      A.{Width A}=I
      proc {$} {Show clause(I)} end
   end
end

{CombCond
 '#'({Guard A 1}
     {Guard A 2}
     {Guard A 3}
     {Guard A 4}
     {Guard A 5}) proc {$} {Show no} end}

A.4=1
A.1=2
A.4=1
*/
