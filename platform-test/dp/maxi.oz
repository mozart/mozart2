%%%
%%% Authors:
%%%  Erik Klintskog (erik@sics.se)
%%%
%%%
%%% Copyright:
%%%
%%%
%%% Last change:
%%%   $ $ by $Author$
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
   Property
   Connection
   TestMisc(localHost)
   System
export
   Return

define
   Return=
   dp([
       maxi(
          proc{$}
             S My CC = {NewCell false}
             LocalHost = TestMisc.localHost in
             S={New Remote.manager init(host:LocalHost)}
             {S ping}
             {S apply(url:'' functor
                             import
                                Property
                                Remote
                                System
                                Connection
                             export
                                My
                             define
                                {Property.put 'close.time' 0}
                                local S A in
                                   S={New Remote.manager init(host:LocalHost)}
                                   {S ping}
                                   try
                                   {S apply(url:'' functor
                                                   import
                                                      Connection
                                                      Property
                                                   export
                                                      My
                                                   define
                                                      {Property.put 'close.time' 0}
                                                      My = {Connection.offer _}
                                                   end $)}.my = A

                                   catch XX then
                                      {System.show s1(XX)}
                                   end
                                   {S close}
                                   My = A#{Connection.offer _}
                                end
                             end $)}.my = My
             {S ping}

             {Delay 1000}
             try
                {Connection.take My.1 apa}
                {Assign CC true}
             catch _ then
                skip
             end

             {S close}

             try

                {Connection.take My.2 apa}
                {Assign CC true}

             catch _ then
                skip
             end

             try

                {Connection.take My.1 apa}
                {Assign CC true}

             catch _ then
                skip
             end

             try

                {Connection.take My.2 apa}
                {Assign CC true}

             catch _ then
                skip
             end
             {Access CC false}
          end
          keys:[fault])
      ])
end
