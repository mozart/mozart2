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

functor

import

   BootDictionary(waitOr: DictWaitOr)
   at 'x-oz://boot/Dictionary'

   BootSpace(askUnsafe: AskSpace
             merge:     MergeSpace
             discard:   DiscardSpace
             new:       NewSpace)
   at 'x-oz://boot/Space'

   FDB(int:           FdInt
       'reflect.dom': FdReflectDom)
   at 'x-oz://boot/FDB'

export
   Choice
   Or
   Dis
   Cond

require
   CpSupport(expand:         Expand)

prepare

   WaitStableSpace = Space.waitStable
   ChooseSpace     = Space.choose

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

define

   fun {GetDomList X}
      {Expand {FdReflectDom X}}
   end

   fun {NewGuard C}
      {NewSpace {Guardify C}}
   end

   proc {CommitGuard G}
      {{MergeSpace G}}
   end

   local
      proc {Init N C G A}
         if N>0 then NG={NewGuard C.N} in
            G.N=NG {Dictionary.put A N {AskSpace NG}}
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
      [] I|Ir then {DiscardSpace G.I} {DiscardGuards Ir G}
      end
   end

   local
      proc {Cond1 C E}
         G={NewGuard C}
      in
         case {Deref {AskSpace G}}
         of failed    then {E}
         [] entailed  then {CommitGuard G}
         [] suspended then {WUHFI}
         end
      end

      proc {Resolve G A N B E}
         if N==0 then
            if B then {WUHFI} else {E} end
         else I={DictWaitOr A} in
            case {Dictionary.get A I}
            of failed    then
               {Dictionary.remove A I}
               {Resolve G A N-1 B E}
            [] succeeded(suspended) then
               {Dictionary.remove A I}
               {DiscardSpace G.I}
               {Resolve G A N-1 true E}
            [] alternatives(_) then
               {Dictionary.remove A I}
               {DiscardSpace G.I}
               {Resolve G A N-1 true E}
            [] succeeded(entailed) then
               {Dictionary.remove A I}
               {DiscardGuards {Dictionary.keys A} G}
               {CommitGuard G.I}
            [] blocked(AI) then
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
         if N>0 then I={DictWaitOr A} in
            case {Dictionary.get A I}
            of failed then
               {Dictionary.remove A I}
               {WaitFailed G A N-1}
            [] blocked(AI) then
               {Dictionary.put A I AI}
               {WaitFailed G A N}
            else
               {WUHFI}
            end
         end
      end
      proc {Resolve G A N}
         if N>1 then I={DictWaitOr A} in
            case {Dictionary.get A I}
            of failed then
               {Dictionary.remove A I}
               {Resolve G A N-1}
            [] blocked(AI) then
               {Dictionary.put A I AI}
               {Resolve G A N}
            else
               {Dictionary.remove A I}
               {WaitFailed G A N-1}
               {CommitGuard G.I}
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
         if I==J then {CommitGuard G} else {DiscardSpace G} end
      end
      proc {Control G A J I}
         {WaitOr A I}
         if {IsDet I} then
            {CommitOrDiscard G J I}
         else
            case A
            of failed     then {FdInt compl(J) I}
            [] merged     then skip
            [] blocked(A) then {Control G A J I}
            else {CommitOrDiscard G J I}
            end
         end
      end
   in
      proc {Dis C}
         case {Width C}
         of 0 then fail
         [] 1 then {{{Guardify C.1}}}
         [] N then I={FdInt 1#N} in
            {For 1 N 1 proc {$ J}
                          G={NewGuard C.J}
                       in
                          thread {Control G {AskSpace G} J I} end
                       end}
            {WaitStableSpace}
            if {IsDet I} then skip else
               I={ChooseSpace {List.toTuple '#' {GetDomList I}}}
            end
         end
      end
   end

   proc {Choice C}
      {{ChooseSpace C}}
   end

end
