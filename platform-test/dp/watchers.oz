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

% These tests all start a server that creates a number of entities.
% A local procedure installs watchers and hopes for them to be invoked
% when the remote server is closed.
% Live tests install watchers first and close the server after that,
% Dead tests do it the opposite way around.
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
      Inj = proc{$ A B}
               B = proc{$ _ _}
                      A = unit
                   end
            end
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
         E.cell = cell
         {Assign CC true}
      catch _ then skip end
      try
         E.var = var
         {Assign CC true}
      catch _ then skip end
      try
         E.lokk = lokk
         {Assign CC true}
      catch _ then skip end
      try
         E.object = object
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
                              var:_
                              ctrl:_) % Try to bind this to detect perm
                      end $)}.my = E
      {S ping}
   end

   proc{MakePerm E}
      try E.ctrl=unit catch _ then skip end
   end

   fun {GetLiveTest Try Entity}
      proc {$}
         S Deads Ans in
         {StartServer S Deads}
         {WatchWat Deads Ans}
         {S close}
         {MakePerm Deads}
         {Delay 1000}
         {Try Deads.Entity}
         {Delay 1000}
         {CheckWat Ans}
      end
   end


   fun {GetDeadTest Try Entity}
      proc{$}
         S Deads Ans in
         {StartServer S Deads}
         {S close}
         {MakePerm Deads}
         {WatchWat Deads Ans}
         {Delay 1000}
         {Try Deads.Entity}
         {Delay 1000}
         {CheckWat Ans}
      end
   end

   Return=
   dp([
       fault_watcher_live_cell({GetLiveTest TryCell cell}
                               keys:[fault])

       fault_watcher_live_var({GetLiveTest TryVar var}
                              keys:[fault])

       fault_watcher_live_lokk({GetLiveTest TryLock lokk}
                               keys:[fault])

       fault_watcher_live_port({GetLiveTest TryPort port}
                               keys:[fault])

       fault_watcher_object_code({GetLiveTest TryObjectCode object}
                                 keys:[fault])
       fault_watcher_object_feat({GetLiveTest TryObjectFeat object}
                                 keys:[fault])
       fault_watcher_object_state({GetLiveTest TryObjectState object}
                                  keys:[fault])
       fault_watcher_object_lokk({GetLiveTest TryObjectLock object}
                                 keys:[fault])
       fault_watcher_object_touchedState({GetLiveTest TryObjectTouchedState
                                          object}
                                         keys:[fault])
       fault_watcher_object_touchedLokk({GetLiveTest TryObjectTouchedLock
                                         object}
                                        keys:[fault])

       fault_watcher_live_all(proc{$}
                                 S Deads Ans in
                                 {StartServer S Deads}
                                 {WatchWat Deads Ans}
                                 {S close}
                                 {MakePerm Deads}
                                 {Delay 1000}
                                 {TryPort Deads.port}
                                 {TryVar Deads.var}
                                 {TryCell Deads.cell}
                                 {TryLock Deads.lokk}
                                 {Delay 1000}
                                 {CheckWat Ans}
                              end
                              keys:[fault])

       fault_watcher_dead_cell({GetDeadTest TryCell cell}
                               keys:[fault])

       fault_watcher_dead_var({GetDeadTest TryVar var}
                              keys:[fault])

       fault_watcher_dead_lokk({GetDeadTest TryLock lokk}
                               keys:[fault])
       fault_watcher_dead_port({GetDeadTest TryPort port}
                               keys:[fault])

       fault_watcher_dead_all(proc {$}
                                 S Deads Ans in
                                 {StartServer S Deads}
                                 {S close} {MakePerm Deads}
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
