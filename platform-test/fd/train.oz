%%%
%%% Authors:
%%%   Gert Smolka <smolka@ps.uni-sb.de>
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Gert Smolka, 1998
%%%   Christian Schulte, 1998
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
import FD Search
export Return
prepare
   TrainSol = [r(a:1895 b:1904 n:1918 x:1)
               r(a:1896 b:1905 n:1920 x:1)]
define

   fun {Year}
      {FD.int 1700#1999}
   end

   fun {Day}
      {FD.int 1#365}
   end

   fun {DS Y}
      [A B C D] = {FD.list 4 0#9}
      Q         = {FD.int 0#36}
   in
      1000*A + 100*B +10*C + D =: Y
      Q =: A+B+C+D
      Q
   end

   fun {Third X N}
      proc {$ _}
         C  = {Year}  % C's year of birth
         Y  = {Day}   % C's day of birth
         Q  = {DS C}
      in
         thread
            or Y<:X  Q=:N-C  []  Y>:X  Q=:N-C-1 end
         end
         {FD.distribute split [Y C]}
      end
   end

   proc {NoThird X N}
      thread
         {Search.base.one {Third X N} nil}
      end
   end

   proc {Train S}
      N = {Year}  % year of train ride
      X = {Day}   % day of train ride
      A = {Year}  % A's year of birth
      B = {Year}  % B's year of birth
   in
      S=r(a:A b:B n:N x:X)
      N >=: 1825   % no trains before that year
      {DS A} =: N-A
      {DS B} =: N-B
      A <: B       % wlog
      {NoThird X N}
      {FD.distribute split [A B X]}
   end

   Return =
   fd([train([all(equal(fun {$}
                           {Search.base.all Train}
                        end
                        TrainSol)
                  keys: [fd space])
              all_entailed(entailed(proc {$}
                                       {Search.base.all Train _}
                                    end)
                           keys: [fd space])])])

end
