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
   Remote(manager)
   Fault
   TestMisc(localHost)
export
   Return

define

   proc{SiteWatcherInstall Entity Proc}
      {Fault.installWatcher Entity [permFail] Proc true}
   end
   /*
   proc{SiteWatcherDeInstall Entity Proc}
      {Fault.deInstallWatcher Entity Proc true}
   end
   */


   proc{WatchWat S E}
      Inj = proc{$ A B} B = proc{$ _ _} A = unit end end
   in
      E = o(port:_ cell:_ lokk:_ var:_ object:_)
      {SiteWatcherInstall S.port {Inj E.port}}
      {SiteWatcherInstall S.cell {Inj E.cell}}
      {SiteWatcherInstall S.lokk {Inj E.lokk}}
      {SiteWatcherInstall S.var  {Inj E.var}}
      {SiteWatcherInstall S.object {Inj E.object}}
   end

   proc{CheckWat E}
      CC = {NewCell false}
   in
      try
         E.port = port
         {Assign CC true}
      catch _ then
         skip
      end
      try
         E.cell = port
         {Assign CC true}
      catch _ then skip end
      try
         E.var = port
         {Assign CC true}
      catch _ then skip end
      try
         E.lokk = port
         {Assign CC true}
      catch _ then skip end
      try
         E.object = port
         {Assign CC true}
      catch _ then skip end
      {Access CC false}
   end

   proc{TryCell C}
      thread try {Access C _} catch _ then skip end end
   end

   proc{TryLock L}
      thread  try lock L then skip end catch _ then skip end end
   end
   proc{TryPort P}
      thread  try {Send P apa} catch _ then skip end end
   end

   proc{TryVar V}
      thread try V = apa catch _ then skip end end
   end

   proc{TryObjectCode O}
      try
         {O c}
      catch _ then skip end
   end

   proc{TryObjectFeat O}
      try
         _ = O.b
      catch _ then skip end
   end

   proc{TryObjectState O}
      try
         {O read(_)}
      catch _ then skip end
   end

   proc{TryObjectLock O}
      try
         {O write(3)}
      catch _ then skip end
   end

   proc{TryObjectTouchedState O}
      try
         _ = O.b
         {O read(_)}
      catch _ then skip end
   end

   proc{TryObjectTouchedLock O}
      try
         _ = O.b
         {O write(3)}
      catch _ then skip end
   end

   proc{StartServer S E}
      S={New Remote.manager init(host:TestMisc.localHost)}
      {S ping}
      {S apply(url:'' functor
                      import
                         Property
                      export
                         My
                      define
                         {Property.put 'close.time' 0}
                         My=o(port:{NewPort _}
                              cell:{NewCell a}
                              lokk:{NewLock}
                              object:{New class $
                                             prop locking
                                             attr a:1
                                             feat b:2
                                             meth c skip end
                                             meth read(A) A=@a end
                                             meth write(A) lock a<-A end end
                                          end
                                      c}
                              var:_)
                      end $)}.my = E
      {S ping}
   end

   proc {LiveTest Try Entity}
      S Deads Ans in
      {StartServer S Deads}
      {WatchWat Deads Ans}
      {S close}
      {Delay 1000}
      {Try Deads.Entity}
      {Delay 1000}
      {CheckWat Ans}
   end

   /*
   proc {DeadTest Try Entity}
      S Deads Ans in
      {StartServer S Deads}
      {S close}
      {WatchWat Deads Ans}
      {Delay 1000}
      {Try Deads.Entity}
      {Delay 1000}
      {CheckWat Ans}
   end
   */

   Return=
   dp([
       fault_watcher_live_cell(
          proc {$}
             S Deads Ans in
             {StartServer S Deads}
             {WatchWat Deads Ans}
             {S close}
             {Delay 1000}
             {TryCell Deads.cell}
             {Delay 1000}
             {CheckWat Ans}
          end
          keys:[fault])

       fault_watcher_live_var(
          proc {$}
             S Deads Ans in
             {StartServer S Deads}
             {WatchWat Deads Ans}
             {S close}
             {Delay 1000}
             {TryVar Deads.var}
             {Delay 1000}
             {CheckWat Ans}
          end
          keys:[fault])

       fault_watcher_live_lokk(
          proc {$}
             S Deads Ans in
             {StartServer S Deads}
             {WatchWat Deads Ans}
             {S close}
             {Delay 1000}
             {TryLock Deads.lokk}
             {Delay 1000}
             {CheckWat Ans}
          end
          keys:[fault])

       fault_watcher_live_port(
          proc {$}
             S Deads Ans in
             {StartServer S Deads}
             {WatchWat Deads Ans}
             {S close}
             {Delay 1000}
             {TryPort Deads.port}
             {Delay 1000}
             {CheckWat Ans}
          end
          keys:[fault])

       fault_watcher_object_code(
          proc {$}
             {LiveTest TryObjectCode object}
          end
          keys:[fault])
       fault_watcher_object_feat(
          proc {$}
             {LiveTest TryObjectFeat object}
          end
          keys:[fault])
       fault_watcher_object_state(
          proc {$}
             {LiveTest TryObjectState object}
          end
          keys:[fault])
       fault_watcher_object_lokk(
          proc {$}
             {LiveTest TryObjectLock object}
          end
          keys:[fault])
       fault_watcher_object_touchedState(
          proc {$}
             {LiveTest TryObjectTouchedState object}
          end
          keys:[fault])
       fault_watcher_object_touchedLokk(
          proc {$}
             {LiveTest TryObjectTouchedLock object}
          end
          keys:[fault])

       fault_watcher_live_all(
          proc {$}
             S Deads Ans in
             {StartServer S Deads}
             {WatchWat Deads Ans}
             {S close}
             {Delay 1000}
             {TryPort Deads.port}
             {TryVar Deads.var}
             {TryCell Deads.cell}
             {TryLock Deads.lokk}
             {Delay 1000}
             {CheckWat Ans}
          end
          keys:[fault])

       fault_watcher_dead_cell(
          proc {$}
             S Deads Ans in
             {StartServer S Deads}
             {S close}
             {WatchWat Deads Ans}
             {Delay 1000}
             {TryCell Deads.cell}
             {Delay 1000}
             {CheckWat Ans}
          end
          keys:[fault])

       fault_watcher_dead_var(
          proc {$}
             S Deads Ans in
             {StartServer S Deads}
             {S close}
             {WatchWat Deads Ans}
             {Delay 1000}
             {TryVar Deads.var}
             {Delay 1000}
             {CheckWat Ans}
          end
          keys:[fault])

       fault_watcher_dead_lokk(
          proc {$}
             S Deads Ans in
             {StartServer S Deads}
             {WatchWat Deads Ans}
             {S close}
             {Delay 1000}
             {TryLock Deads.lokk}
             {Delay 1000}
             {CheckWat Ans}
          end
          keys:[fault])
       fault_watcher_dead_port(
          proc {$}
             S Deads Ans in
             {StartServer S Deads}
             {S close}
             {WatchWat Deads Ans}
             {Delay 1000}
             {TryPort Deads.port}
             {Delay 1000}
             {CheckWat Ans}
          end
          keys:[fault])

       fault_watcher_dead_all(
          proc {$}
             S Deads Ans in
             {StartServer S Deads}
             {S close}
             {WatchWat Deads Ans}
             {Delay 1000}
             {TryPort Deads.port}
             {TryVar Deads.var}
             {TryCell Deads.cell}
             {TryLock Deads.lokk}
             {Delay 1000}
             {CheckWat Ans}
          end
          keys:[fault])
      ])
end
