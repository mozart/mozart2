%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

fun {$ IMPORT}
   \insert 'lib/import.oz'
   fun {Id X} X end
in
   misc([
              search1(
                     proc {$}
                        {SearchAll fun {$} Ele in thread Ele=a end Ele=b end}
                        =nil
                     end
                     keys:[fixedBugs search])
              search2(
                      proc {$}
                         fun {FailChk}
                            local X={Id a} in
                               try choice true
                                   [] X=b  %% failure
                                   [] Ele in
                                      choice Ele=b(b) %% failure
                                      [] Ele=a        %% failure
                                      end
                                      {Wait Ele}
                                      Ele=b
                                      Ele
                                   [] Ele in
                                      choice Ele=b(b) %% ok
                                      [] Ele=a        %% failure
                                      end
                                      {Wait Ele}
                                      Ele^1=b
                                      Ele
                                   [] Ele in
                                      choice Ele=b(b) %% ok
                                      [] Ele=a        %% failure not caught!
                                      end
                                      {Wait Ele}
                                      Ele^1=b
                                   end
                               catch failure(debug:D) then failure(D)
                               [] error(T debug:D) then error(T D)
                               [] system(T debug:D) then system(T D)
                               end
                            end
                         end
                      in
                         {SearchAll FailChk _}
                      end
                      keys:[fixedBugs search])

\ifdef TODO


{MyShow 5}
local
   proc {P X Y Z} {Wait X} {Wait Y} {Wait Z} X=a Y=b Z=c end
in
   {System.apply P [a b c]}
   local X in thread {System.apply P X} end X=[a b c] end
   local Y in thread {System.apply Y [a b c]} end Y=P end
end

{MyShow 6}
{System.apply {New BaseObject noop} [noop]}

{MyShow 7}
{System.apply IsAtom [nil true]}

/*

declare
Apply={`Builtin` apply noHandler}
{Apply Show [a]}

*/

{MyShow 8}
local
   X = {New class $ from BaseObject
               attr a
               meth test
                  if thread skip end then skip end
               end
            end
        noop}
in
   {X test}
end


{MyShow 9}
% trailing local bindings is necessary with exception handling
local X=f(a b) Y=f(a c)
in
   try
      X={Id Y}
   catch failure(...) then skip
   end
   X=f(a b) Y=f(a c)
end



{MyShow 10}
local X=a|b Y
in
   Y={AdjoinAt X a b}
   case Y =='|'(1:a 2:b a:b) then skip end
end


{MyShow 11}
case {List.toRecord '|' [1#a 2#b]} == a|b then skip end


{MyShow 12}
local
   O = {New class $ from BaseObject
            meth wuff skip end
            end
        wuff}
in
   _={Space.new proc {$ _}
                   {O noop}
                end}
end


{MyShow 13}
if Ele in
   Ele={Id a}
   dis Ele=a then skip
   [] Ele=b then Ele=b
   end
   thread Ele=c end
then fail
else skip
end


{MyShow 14}
local L in L=L|nil case L of nil then fail else skip end end

{MyShow 15}
local
   proc {P}
      X Y Z
   in
      thread if thread X=Y end then Z = unit end end
      {For 1 10000 1 proc {$ X} _=X*X end}
      X=Y
      {Wait Z}
   end
in
   {P}
end

{MyShow 16}
% the getsBound bug: UVAR->SVAR invariant
_={Space.new proc {$ _}
                GB={`Builtin` getsBoundB 2}
                proc {P X}
                 thread Y in thread {Wait Y} end X=Y end
                 {Wait {GB X}}
                 {Show a}
                 case {IsFree X} then
                    {P X}
                 else skip
                 end
              end
                X
             in
              {P X}
             end}


{MyShow 17}
% non-terminating unification
local
   X1=X2|X1
   X2=X1|(X2|X1)
in
   X1=X2
end

% Known bugs in Oz_2
\ifndef Oz_2

{MyShow 100}
% First-class threads and actors tasks
local
   T X
in
   thread
      try
         T = {Thread.this}
         or X = 1 [] X = 2 end
      catch test then X = 1 end
   end
   {Thread.injectException T test}
end

{MyShow 101}
if
   try or fail [] fail end
   catch failure(...) then skip end
then skip
end

{MyShow 102}
local
   X=1|X
in
   case {IsString X} then fail else skip end
end

{MyShow 103}
local
   X=a#1|X
in
   try {Record.adjoinList f X _}
   catch error(kernel(type ...) ...) then skip
   end
end

\endif
% End known bugs in Oz_2

{System.showInfo '.'}

\endif
             ])
end
