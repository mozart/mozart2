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
   System
   TestMisc(localHost)
export
   Return

define
   Return=
   dp([
       fault_proxy(
          proc {$}
             S={New Remote.manager init(host:TestMisc.localHost)}
             CC = {NewCell false}
             Sync
             DistCell = {NewCell Sync}
          in
             {S ping}
             {S apply(url:'' functor
                             import
                                Property
                             define
                                {Property.put  'close.time' 0}
                                {Wait DistCell}
                                {Access DistCell} = unit
                                {Assign DistCell skit}
                             end)}
             {S ping}
             {Wait Sync}
             {S close}
             {Delay 1000}
             try
                {Access DistCell _}
                {Assign CC true}
             catch XX then
                skip
             end
             if {Access CC} then
                raise dp('fail' error) end
             else
                skip
             end
          end
          keys:[fault])





       fault_tokenLost(
          proc {$}
             S1={New Remote.manager init(host:TestMisc.localHost)}
             S2={New Remote.manager init(host:TestMisc.localHost)}
             CC = {NewCell false}
             Sync
             DistCell
          in
             {S1 ping}
             {S1 apply(url:'' functor
                              export
                                 MyCell
                              define
                                 MyCell = {NewCell apa}
                              end $)}.myCell = DistCell

             {S2 ping}
             {S2 apply(url:'' functor
                              import
                                 Property
                                 System
                              define
                                 {Property.put  'close.time' 0}
                                 {Assign DistCell unit}
                                 !Sync = unit
                              end)}

             {Wait Sync}
             {S2 close}
             {Delay 1000}
             try
                {Access DistCell _}
                {Assign CC true}
             catch _ then
                skip
             end

             {S1 close}

             if {Access CC} then
                raise dp('fail' error) end
             else
                skip
             end
          end
          keys:[fault])

       fault_chain_broken(
          proc {$}
             S1={New Remote.manager init(host:TestMisc.localHost)}
             S2={New Remote.manager init(host:TestMisc.localHost)}
             S3={New Remote.manager init(host:TestMisc.localHost)}
             CC = {NewCell false}
             DistLock
             Sync1 Sync2 Sync3 Sync4

          in
             {S1 ping}
             {S1 apply(url:'' functor
                              export
                                 MyLock
                              define
                                 MyLock = {NewLock}
                              end $)}.myLock = DistLock


             {S2 ping}
             {S2 apply(url:'' functor
                              import
                                 Property
                              define
                                 {Property.put 'close.time' 0}
                                 thread
                                    lock DistLock then
                                       !Sync2 = unit
                                       {Wait Sync1}
                                    end
                                 end
                              end)}


             {Wait Sync2}
             {S2 close}

             {S3 apply(url:'' functor
                              define
                                 thread
                                    lock DistLock then
                                       !Sync3 = unit
                                    end
                                 end
                              end)}

             {S3 ping}
             {Delay 1000}

             /*
             Watcher released

              We give the distlayer 3 secs then
             we crash the thing
             */


             thread
                {Delay 3000}
                try
                   Sync4 = bunit
                catch _ then
                   skip
                end
             end

             thread
                {Wait Sync3}
                lock DistLock then
                   Sync4 = unit
                end
             end
             {Wait Sync4}
             Sync4 = unit
             {S3 close}
             {S1 close}

          end
          keys:[fault])
      ])
end
