%%%
%%% Authors:
%%%   Erik Klintskog (erik@sics.se)
%%%
%%% Copyright:
%%%   Erik Klintskog, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor

import
   Remote(manager)
   OS(uName)
   System
export
   Return

define
   Return=
   dp([
       table(
            proc {$}
               S={New Remote.manager init(host:{OS.uName}.nodename)}
               D
               Lim = 10000
            in
               {S ping}
               {S apply(url:'' functor
                               import
                                  Property(put)
                                  System
                               export
                                  PP
                               define
                                  S
                                  P = {NewPort S}
                                  CC = {NewCell nil}
                                  proc{R X}
                                     case X of
                                        store(E Nr) then
                                        {Assign CC E|{Access CC}}
                                        if(Nr == Lim) then
                                           {System.print o}
                                        else skip end
                                     elseof gc then
                                        {System.gcDo}
                                        {System.print c}
                                     elseof gcR(A) then
                                        {Assign CC nil}
                                        {System.gcDo}
                                        A = unit

                                     end
                                  end


                                  thread
                                     {ForAll S R}
                                  end
                                  PP = P
                               end $)}.pP = D

               {For 1 Lim 1 proc{$ Nr}
                               {Send D store({NewCell Nr} Nr)}
                            end}
               {Send D gc}
               {System.gcDo}
               local S in
                  {Send D gcR(S)}
                  {Wait S}
               end

               {For 1 Lim 1 proc{$ Nr}
                               {Send D store({NewLock} Nr)}
                            end}
               {Send D gc}
               {System.gcDo}
               local S in
                  {Send D gcR(S)}
                  {Wait S}
               end

               {S close}
            end
            keys:[remote])
      ])
end
