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
   Fault
export
   Return

define
   proc{InjectorInstall Entity Proc}
      {Fault.install Entity 'thread'(this) [permFail] Proc true}
   end
   proc{InjectorDeInstall Entity Proc}
      {Fault.deInstall Entity 'thread'(this) true}
   end
   proc{SiteWatcherInstall Entity Proc}
      {Fault.installWatcher Entity [permFail] Proc true}
   end
   proc{SiteWatcherDeInstall Entity Proc}
      {Fault.deInstallWatcher Entity Proc true}
   end
   proc{NetWatcherInstall Entity Proc}
      {Fault.installWatcher Entity
       [remoteProblem(permSome) remoteProblem(permAll)] Proc true}
   end
   proc{NetWatcherDeInstall Entity Proc}
      {Fault.deInstallWatcher Entity Proc true}
   end

   proc{InjectInj Ce Lo}
      Inj = proc{$ A B C} raise injector end end
   in
      {InjectorInstall Ce Inj}
      {InjectorInstall  Lo Inj}
   end

proc{WatchWat Ce Lo E}
      Inj = proc{$ A B} B = proc{$ _ _} A = unit end end
in
   E = o(cell:_ lokk:_)
   {SiteWatcherInstall Ce {Inj E.cell}}
   {SiteWatcherInstall Lo {Inj E.lokk}}

end


proc{InjectInj2 Ce Lo E}
      Inj = proc{$ A B} B = proc{$ _ _ _} A = unit end end
in
   E = o(cell:_ lokk:_)
   {InjectorInstall Ce {Inj E.cell}}
   {InjectorInstall Lo {Inj E.lokk}}

end

proc{CheckWat E}
   CC = {NewCell false}
in
   try
      E.cell = port
      {Assign CC true}
   catch _ then skip end
   try
      E.lokk = port
      {Assign CC true}
   catch _ then skip end
   {Access CC false}
end

proc{CheckWatM E}
   CC = {NewCell unit}
in
   try
      E.cell = port
      {Assign CC true}
   catch _ then skip end
   try
      E.lokk = port
      {Assign CC false}
   catch _ then skip end
   {Access CC false}
end


proc{TryCell C}
      try
         {Access C _}
         raise abort end
      catch injector then skip
      end
   end

   proc{TryLock L}
      try
         lock L then skip end
         raise abort end
      catch injector then skip end
   end

   Return=
   dp([
       fault_proxy_naive(
          proc {$}
             S={New Remote.manager init(host:{OS.uName}.nodename)}
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
             {Access CC false}
          end
          keys:[fault])
       fault_state_manager_injector_live(
          proc {$}
             S={New Remote.manager init(host:{OS.uName}.nodename)}
             CC = {NewCell false}
             Sync
             DistCell = {NewCell Sync}
             DistLock = {NewLock}
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
                                lock DistLock then skip end
                             end)}
             {S ping}
             {Wait Sync}
             {InjectInj DistCell DistLock}
             {S close}
             {Delay 100}
             {TryCell DistCell}
          end
          keys:[fault])

       fault_state_manager_injector_dead(
          proc {$}
             S={New Remote.manager init(host:{OS.uName}.nodename)}
             CC = {NewCell false}
             Sync
             DistCell = {NewCell Sync}
             DistLock = {NewLock}
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
             {Delay 100}
             {InjectInj DistCell DistLock}
             {TryCell DistCell}
          end
          keys:[fault])

       fault_state_manager_watcher_live(
          proc {$}
             S={New Remote.manager init(host:{OS.uName}.nodename)}
             CC = {NewCell false}
             Sync
             DistCell = {NewCell Sync}
             DistLock = {NewLock}
             AA
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
                                lock DistLock then skip end
                             end)}
             {S ping}
             {Wait Sync}
             {WatchWat DistCell DistLock AA}
             {InjectInj DistCell DistLock}
             AA.lokk = unit
             {S close}
             {Delay 100}
             {TryCell DistCell}
             {CheckWat AA}
          end
          keys:[fault])


       fault_state_manager_watcher_dead(
          proc {$}
             S={New Remote.manager init(host:{OS.uName}.nodename)}
             CC = {NewCell false}
             Sync
             DistCell = {NewCell Sync}
             DistLock = {NewLock}
             AA
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
                                lock DistLock then skip end
                             end)}
             {S ping}
             {Wait Sync}
             {S close}
             {Delay 100}
             {InjectInj2 DistCell DistLock AA}
             try
                {Access DistCell _}
             catch X then
                skip
             end
             {CheckWatM AA}
          end
          keys:[fault])


       fault_state_proxy_tokenLost_live_injector(
          proc {$}
             S1={New Remote.manager init(host:{OS.uName}.nodename)}
             S2={New Remote.manager init(host:{OS.uName}.nodename)}
             Sync
             DistCell
             Inj = proc{$ A B C} raise injector end end
          in
             {S1 ping}
             {S1 apply(url:'' functor
                              export MyCell
                              define MyCell = {NewCell apa}
                              end $)}.myCell = DistCell

             {S2 ping}
             {S2 apply(url:'' functor
                              import Property System
                              define
                                 {Property.put  'close.time' 0}
                                 {Assign DistCell unit}
                                 !Sync = unit
                              end)}

             {Wait Sync}
             {InjectorInstall DistCell Inj}
             {S2 close}
             {Delay 1000}
             {TryCell DistCell}
             {S1 close}
          end
          keys:[fault])

       fault_state_proxy_tokenLost_dead_injector(
          proc {$}
             S1={New Remote.manager init(host:{OS.uName}.nodename)}
             S2={New Remote.manager init(host:{OS.uName}.nodename)}
             CC = {NewCell false}
             Sync
             DistCell
             Inj = proc{$ A B C} raise injector end end
          in
             {S1 ping}
             {S1 apply(url:'' functor
                              export MyCell
                              define
                                 MyCell = {NewCell apa}
                              end $)}.myCell = DistCell

             {S2 ping}
             {S2 apply(url:'' functor
                              import Property System
                              define
                                 {Property.put  'close.time' 0}
                                 {Assign DistCell unit}
                                 !Sync = unit
                              end)}

             {Wait Sync}
             {InjectorInstall DistCell Inj}
             {S2 close}
             {Delay 1000}
             {TryCell DistCell}
             {S1 close}
          end
          keys:[fault])




       fault_state_proxy_tokenLost_live_watcher(
          proc {$}
             S1={New Remote.manager init(host:{OS.uName}.nodename)}
             S2={New Remote.manager init(host:{OS.uName}.nodename)}
             CC = {NewCell false}
             Sync
             DistCell
             Inj = proc{$ A B} raise injector end end
          in
             {S1 ping}
             {S1 apply(url:'' functor
                              export MyCell
                              define
                                 MyCell = {NewCell apa}
                              end $)}.myCell = DistCell

             {S2 ping}
             {S2 apply(url:'' functor
                              import Property System
                              define
                                 {Property.put  'close.time' 0}
                                 {Assign DistCell unit}
                                 !Sync = unit
                              end)}

             {Wait Sync}
             {SiteWatcherInstall DistCell proc{$ A B}
                                            {Assign CC true}
                                         end}
             {S2 close}
             {Delay 2000}
             {S1 close}
             {Access CC true}
          end
          keys:[fault])


       fault_state_proxy_tokenLost_dead_watcher(
          proc {$}
             S1={New Remote.manager init(host:{OS.uName}.nodename)}
             S2={New Remote.manager init(host:{OS.uName}.nodename)}
             CC = {NewCell false}
             Sync
             DistCell
             Inj = proc{$ A B} raise injector end end
          in
             {S1 ping}
             {S1 apply(url:'' functor
                              export MyCell
                              define
                                 MyCell = {NewCell apa}
                              end $)}.myCell = DistCell

             {S2 ping}
             {S2 apply(url:'' functor
                              import Property System
                              define
                                 {Property.put  'close.time' 0}
                                 {Assign DistCell unit}
                                 !Sync = unit
                              end)}

             {Wait Sync}
             {S2 close}
             {Delay 1000}
             {SiteWatcherInstall DistCell proc{$ B C}
                                            {Assign CC true}
                                         end}
             {Delay 1000}
             {S1 close}
             {Access CC true}
          end
          keys:[fault])


       fault_chain_broken_watcher_dead(
          proc {$}
             S1={New Remote.manager init(host:{OS.uName}.nodename)}
             S2={New Remote.manager init(host:{OS.uName}.nodename)}
             S3={New Remote.manager init(host:{OS.uName}.nodename)}
             CC = {NewCell false}
             DistLock
             Sync1 Sync2 Sync3 Sync4

          in
             {S1 ping}
             {S1 apply(url:'' functor
                              export MyLock
                              define MyLock = {NewLock}
                              end $)}.myLock = DistLock


             {S2 ping}
             {S2 apply(url:'' functor
                              import Property
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
             {Delay 100}
             {S2 close}
             {NetWatcherInstall DistLock
              proc{$ A B}
                 {Assign CC true}
              end}
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

             {Access CC true}

          end
          keys:[fault])


       fault_chain_broken_watcher_live(
          proc {$}
             S1={New Remote.manager init(host:{OS.uName}.nodename)}
             S2={New Remote.manager init(host:{OS.uName}.nodename)}
             S3={New Remote.manager init(host:{OS.uName}.nodename)}
             CC = {NewCell false}
             DistLock
             Sync1 Sync2 Sync3 Sync4

          in
             {S1 ping}
             {S1 apply(url:'' functor
                              export MyLock
                              define MyLock = {NewLock}
                              end $)}.myLock = DistLock


             {S2 ping}
             {S2 apply(url:'' functor
                              import Property
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
             {NetWatcherInstall DistLock
              proc{$ A B}
                 {Assign CC true}
              end}
             {Delay 100}
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
             {Access CC true}

          end
          keys:[fault])
      ])
end
