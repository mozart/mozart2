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
   Fault
   System
export
   Return

define


   proc{WatchWat S E}
      Inj = proc{$ A B} B = proc{$ _ _} A = unit end end
   in
      E = o(port:_ cell:_ lokk:_ var:_)
      {Fault.siteWatcher S.port {Inj E.port}}
      {Fault.siteWatcher S.cell {Inj E.cell}}
      {Fault.siteWatcher S.lokk {Inj E.lokk}}
      {Fault.siteWatcher S.var  {Inj E.var}}
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

   proc{StartServer S E}
      S={New Remote.manager init(host:{OS.uName}.nodename)}
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
                              var:_)
                      end $)}.my = E
      {S ping}
   end

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
