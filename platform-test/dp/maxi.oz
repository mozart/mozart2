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
   OS(uName)
   Property
   Connection
   System
export
   Return

define
   Return=
   dp([
       maxi(
          proc{$}
             S My in
             S={New Remote.manager init(host:{OS.uName}.nodename)}
             {S ping}
             {S apply(url:'' functor
                             import
                                Property
                                Remote
                                OS
                                System
                                Connection
                             export
                                My
                             define
                                {Property.put 'close.time' 0}
                                {System.show startinS1}
                                local S A in
                                   S={New Remote.manager init(host:{OS.uName}.nodename)}
                                   {System.show s1(1)}
                                   {S ping}
                                   {System.show s1(2)}
                                   try
                                   {S apply(url:'' functor
                                                   import
                                                      Connection
                                                      Property
                                                      Remote
                                                      System
                                                   export
                                                      My
                                                   define
                                                      {System.show startinS2}
                                                      My = {Connection.offer _}
                                                   end $)}.my = A

                                   catch XX then
                                      {System.show s1(XX)}
                                   end
                                   {System.show a(A)}
                                   {S close}
                                   My = A#{Connection.offer _}
                                end
                             end $)}.my = My
             {S ping}
             {System.show my(My)}
             try
                {Connection.take My.1 _}
                raise hell end
             catch C then
                {System.show  C}
             end

             {S close}

             try
                {Connection.take My.2 _}
                raise hell end
             catch C then
                {System.show  C}
             end

             try
                {Connection.take My.1 _}
                raise hell end
             catch C then
                {System.show  C}
             end

             {S close}

             try
                {Connection.take My.2 _}
                raise hell end
             catch C then
                {System.show  C}
             end
          end
          keys:[fault])
      ])
end
