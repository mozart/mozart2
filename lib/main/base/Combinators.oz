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

declare

local
   [BS]={Module.link ['x-oz://boot/Space']}
   NewSpace = Space.new
   Discard  = Space.discard
   Ask      = BS.askUnsafe
   proc {SKIP}
      skip
   end
   fun {NewGuard C}
      {NewSpace if {Procedure.arity C}==1 then C
                else proc {$ X} {C} X=SKIP end
                end}
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
         [] failed          then failed
         end
      else S
      end
   end
   fun {Deref S}
      case S
      of blocked(S)      then {Deref S}
      [] alternatives(_) then suspended
      [] succeeded(S)    then S
      [] failed          then failed
      end
   end
   proc {WUHFI}
      {Wait _}
   end
   local
      proc {Before I T1 T2}
         if I>0 then T2.I=T1.I {Before I-1 T1 T2} end
      end
      proc {After I N T1 T2}
         if I=<N then I1=I+1 in T2.I=T1.I1 {After I1 N T1 T2} end
      end
   in
      proc {Drop T1 I ?T2}
         N={Width T1}-1
      in
         T2={Tuple.make '#' N}
         {Before I-1 T1 T2} {After I N T1 T2}
      end
   end
in

   proc {CombCond1 C E}
      G={NewGuard C}
   in
      case {Deref {Ask G}}
      of failed    then {E}
      [] entailed  then {CommitGuard G}
      [] suspended then {WUHFI}
      end
   end

   local
      proc {Resolve G A N B E}
         {Show resolve(G A N B)}
         if N==0 then
            if B then {WUHFI} else {E} end
         else
            M  = {Record.waitOr A}
            AM = {DerefCheck A.M}
         in
            if {IsDet AM} then
               case AM
               of failed    then
                  {Resolve {Drop G M} {Drop A M} N-1 B E}
               [] suspended then
                  {Discard G.M}
                  {Resolve {Drop G M} {Drop A M} N-1 true E}
               [] entailed then
                  {Record.forAll {Drop G M} Discard}
                  {CommitGuard G.M}
               end
            else {Resolve G {AdjoinAt A M AM} N B E}
            end
         end
      end
   in
      proc {CombCond C E}
         G={Record.map C NewGuard}
         A={Record.map G Ask}
      in
         {Resolve G A {Width C} false E}
      end
   end


   local
      skip
   in
      proc {CombOr2 C1 C2}
         skip
      end
   end

   local
      proc {WaitAllFailed G A N B}
         if N>0 then
            M  = {Record.waitOr A}
            AM = {DerefCheck A.M}
         in
            if {IsDet AM} then
               case AM
               of failed    then
                  {WaitAllFailed {Drop G M} {Drop A M} N-1 B}
               [] suspended then
                  {WUHFI}
               [] entailed then
                  B1={Space.merge G.M}
               in
                  if B1==SKIP then
                     if {IsSpace B} then
                        {Discard B}
                     end
                     {Record.forAll {Drop G M} Discard}
                  else
                     {WUHFI}
                  end
               end
            else {WaitAllFailed G {AdjoinAt A M AM} N B}
            end
         else
            if {IsProcedure B} then {B} else {CommitGuard B} end
         end
      end
      proc {Resolve G A N}
         {Show resolve(G A N)}
         if N>1 then
            M  = {Record.waitOr A}
            AM = {DerefCheck A.M}
         in
            if {IsDet AM} then
               case AM
               of failed    then
                  {Resolve {Drop G M} {Drop A M} N-1}
               [] suspended then
                  {WaitAllFailed {Drop G M} {Drop A M} N-1 G.M}
               [] entailed then
                  B={Space.merge G.M}
               in
                  if B==SKIP then
                     {Record.forAll {Drop G M} Discard}
                  else
                     {WaitAllFailed {Drop G M} {Drop A M} N-1 B}
                  end
               end
            else {Resolve G {AdjoinAt A M AM} N}
            end
         else
            {CommitGuard G.1}
         end
      end
   in
      proc {CombOr C}
         G={Record.map C NewGuard}
         A={Record.map G Ask}
      in
         {Resolve G A {Width C}}
      end
   end

   local
      skip
   in
      proc {CombDis C}
         skip
      end
   end

   local
      skip
   in
      proc {CombDis2 C1 C2}
         skip
      end
   end

   local
      skip
   in
      proc {CombChoice C}
         skip
      end
   end

   local
      skip
   in
      proc {CombChoice2 C}
         skip
      end
   end

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
