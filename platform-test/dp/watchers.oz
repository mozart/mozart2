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
      Inj = proc{$ A B} B = proc{$ _ _} E.A = unit end end
   in
      {Fault.SiteWatcher S.port {Inj E.port}}
      {Fault.SiteWatcher S.cell {Inj E.cell}}
      {Fault.SiteWatcher S.lokk {Inj E.lokk}}
      {Fault.SiteWatcher S.var  {Inj E.var}}
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
      thread {Access C _} end
   end

   proc{TryLock L}
      thread lock L then skip end end
   end
   proc{TryPort P}
      thread {Send P apa} end
   end

   proc{TryVar V}
      thread V = apa end
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
             S Deads in
             {StartServer S Deads}
             {WatchWat Deads}
             {S close}
             {Delay 2000}
             {TryCell Deads.cell}
          end
          keys:[fault])

       fault_inject_live_var(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {WatchWat Deads}
             {S close}
             {Delay 1000}
             {TryVar Deads.var}
          end
          keys:[fault])

       fault_inject_live_lokk(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {WatchWat Deads}
             {S close}
             {Delay 1000}
             {TryLock Deads.lokk}
          end
          keys:[fault])

       fault_inject_live_port(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {WatchWat Deads}
             {S close}
             {Delay 1000}
             {TryPort Deads.port}
          end
          keys:[fault])

       fault_inject_live_all(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {WatchWat Deads}
             {S close}
             {Delay 1000}
             {TryPort Deads.port}
             {TryVar Deads.var}
             {TryCell Deads.cell}
             {TryLock Deads.lokk}
          end
          keys:[fault])

       fault_inject_dead_cell(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {S close}
             {WatchWat Deads}
             {Delay 1000}
             {TryCell Deads.cell}
          end
          keys:[fault])

       fault_inject_dead_var(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {S close}
             {WatchWat Deads}
             {Delay 1000}
             {TryVar Deads.var}
          end
          keys:[fault])

       fault_inject_dead_lokk(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {WatchWat Deads}
             {S close}
             {Delay 1000}
             {TryLock Deads.lokk}
          end
          keys:[fault])
       fault_inject_dead_port(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {S close}
             {WatchWat Deads}
             {Delay 1000}
             {TryPort Deads.port}
          end
          keys:[fault])

       fault_inject_dead_all(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {S close}
             {WatchWat Deads}
             {Delay 1000}
             {TryPort Deads.port}
             {TryVar Deads.var}
             {TryCell Deads.cell}
             {TryLock Deads.lokk}
          end
          keys:[fault])
      ])
end
