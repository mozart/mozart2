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

               proc{Locker Nr D S Lim}
                  L = {NewLock} in
                  if(Nr mod Lim == 0) then
                     {System.print l}
                     thread {Wait S} lock L then skip end
                     end
                  end
                  {Send D store(L Nr)}
               end

               proc{Celler Nr D S Lim}
                  L = {NewCell Nr} in
                  if(Nr mod Lim == 0) then
                     {System.print l}
                     thread {Wait S} {Access L} = Nr end
                  end
                  {Send D store(L Nr)}
               end


               proc{Variabler Nr D S Lim}
                  L in
                  if(Nr mod Lim == 0) then
                     {System.print l}
                     thread {Wait S} L = Nr end
                  end
                  {Send D store(L Nr)}
               end

               proc{Porter Nr D S Lim}
                  St P= {NewPort St}   in
                  if(Nr mod Lim == 0) then
                     {System.print l}
                     thread {Wait S} {Send P Nr} St.1 = Nr end
                  end
                  {Send D store(P Nr)}
               end

               proc{Stuffer PP}
                  S
                  PPP = proc{$ Nr} {PP.1 Nr D S 100} end
               in
                  {For 1 PP.2 1 PPP}
                  {Send D gc}
                  {System.gcDo}
                  {Send D gcR(S)}
                  {Wait S}
                  {System.gcDo}
                  {System.gcDo}
               end
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

               {ForAll [Celler#40#celler
                        Locker#300#locker
                        Celler#100#celler
                        Porter#564#porter
                        Locker#1003#locker
                        Celler#267#celler
                        Variabler#1200#variabler
                        Celler#5000#celler
                        Locker#45#locker
                        Locker#10000#locker
                        Celler#10000#celler
                       ]

                Stuffer}

               {S close}
            end
            keys:[remote])
      ])
end
