%%%
%%% Authors:
%%%  Erik Klintskog (erik@sics.se)
%%%
%%%
%%% Copyright:
%%%  Erik Klintskog, 1998
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

   proc{SiteWatcherInstall Entity Proc}
      {Fault.installWatcher Entity [permFail] Proc true}
   end
   proc{SiteWatcherDeInstall Entity Proc}
      {Fault.deInstallWatcher Entity Proc true}
   end
   proc{InjectorInstall Entity Proc}
      {Fault.install 'thread'(this) Entity [permFail] Proc true}
   end
   proc{InjectorDeInstall Entity Proc}
      {Fault.deInstall 'thread'(this) Entity true}
   end

   proc{WatchWat S E}
      Inj = proc{$ A B} B = proc{$ _ _} A = unit end end
   in
      E = o(port:_ cell:_ lokk:_ var:_)
      {SiteWatcherInstall S.port {Inj E.port}}
      {SiteWatcherInstall S.cell {Inj E.cell}}
      {SiteWatcherInstall S.lokk {Inj E.lokk}}
      {SiteWatcherInstall S.var  {Inj E.var}}
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
       try {Access C _}
             catch X then if(X==hell) then raise hell end end end

   end

   proc{TryLock L}
        try lock L then skip end
              catch X then if(X==hell) then raise hell end end end

   end

   proc{TryPort P}
        try {Send P apa}
              catch X then if(X==hell) then raise hell end end end

   end

   proc{TryVar V}
      try V = apa
      catch hell  then
         raise hell end
      [] X then {System.show tv(X)}
      end
   end



   proc{DeinstallInj Po Pro}
      CC = {NewCell true}
   in
      try
         {InjectorDeInstall Po Pro}
         {Assign CC false}
      catch _ then skip end

      {InjectorInstall Po Pro}
      {InjectorDeInstall Po Pro}

      try
         {InjectorDeInstall Po Pro}
         {Assign CC false}
      catch _ then skip end
      {Access CC} = true
   end


   proc{DeinstallWat Po Pro}
      CC = {NewCell true}
   in
      try
         {SiteWatcherDeInstall Po Pro}
         {Assign CC false}
      catch _ then skip end

      {SiteWatcherInstall Po Pro}
      {SiteWatcherDeInstall Po Pro}

      try
         {SiteWatcherDeInstall Po Pro}
         {Assign CC false}
      catch _ then skip end
      {Access CC} = true
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
       fault_local_install_deinstall_injector(
          proc {$}
             Va
             Po = {NewPort _}
             Ce = {NewCell apa}
             Lo = {NewLock}
             Pro = proc{$ A B C} raise hell end end
          in
             {InjectorInstall Po Pro}
             {InjectorDeInstall Po Pro}
             {InjectorInstall Va Pro}
             {InjectorDeInstall Va Pro}
             {InjectorInstall Ce Pro}
             {InjectorDeInstall Ce Pro}
             {InjectorInstall Lo Pro}
             {InjectorDeInstall Lo Pro}
             {InjectorInstall Po Pro}
             {InjectorInstall Va Pro}
             {InjectorInstall Ce Pro}
             {InjectorInstall Lo Pro}
             {System.gcDo}
             {InjectorDeInstall Lo Pro}
             {InjectorDeInstall Po Pro}
             {InjectorDeInstall Va Pro}
             {InjectorDeInstall Ce Pro}
          end
          keys:[fault])


       fault_local_install_deinstall_watcher(
          proc {$}
             Va
             Po = {NewPort _}
             Ce = {NewCell apa}
             Lo = {NewLock}
             Pro = proc{$ A B} raise hell end end
          in
             {SiteWatcherInstall Po Pro}
             {SiteWatcherDeInstall Po Pro}

             {SiteWatcherInstall Va Pro}
             {SiteWatcherDeInstall Va Pro}

             {SiteWatcherInstall Ce Pro}
             {SiteWatcherDeInstall Ce Pro}

             {SiteWatcherInstall Lo Pro}
             {SiteWatcherDeInstall Lo Pro}

             {SiteWatcherInstall Po Pro}
             {SiteWatcherInstall Va Pro}
             {SiteWatcherInstall Ce Pro}
             {SiteWatcherInstall Lo Pro}
             {System.gcDo}
             {SiteWatcherDeInstall Lo Pro}
             {SiteWatcherDeInstall Po Pro}
             {SiteWatcherDeInstall Va Pro}
             {SiteWatcherDeInstall Ce Pro}
          end
          keys:[fault])
       fault_global_install_deinstall_injector(
          proc {$}
             Va
             Po
             Ce
             Lo
             Pro = proc{$ A B C} raise hell end end
             S
          in
             {StartServer S o(port:Po cell:Ce lokk:Lo var:Va)}

             {InjectorInstall Po Pro}
             {InjectorDeInstall Po Pro}

             {InjectorInstall Va Pro}
             {InjectorDeInstall Va Pro}

             {InjectorInstall Ce Pro}
             {InjectorDeInstall Ce Pro}

             {InjectorInstall Lo Pro}
             {InjectorDeInstall Lo Pro}

             {InjectorInstall Po Pro}
             {InjectorInstall Va Pro}
             {InjectorInstall Ce Pro}
             {InjectorInstall Lo Pro}
             {System.gcDo}
             {InjectorDeInstall Lo Pro}
             {InjectorDeInstall Po Pro}
             {InjectorDeInstall Va Pro}
             {InjectorDeInstall Ce Pro}

             {S close}

             {TryVar  Va}
             {TryCell Ce}
             {TryPort Po}
             {TryLock Lo}


          end
          keys:[fault])


       fault_global_install_deinstall_watcher(
          proc {$}
             Va
             Po
             Ce
             Lo
             Sync
             Pro = proc{$ A B}  Sync = false end
             S
          in
             {StartServer S o(port:Po cell:Ce lokk:Lo var:Va)}

             {SiteWatcherInstall Po Pro}
             {SiteWatcherDeInstall Po Pro}

             {SiteWatcherInstall Va Pro}
             {SiteWatcherDeInstall Va Pro}

             {SiteWatcherInstall Ce Pro}
             {SiteWatcherDeInstall Ce Pro}

             {SiteWatcherInstall Lo Pro}
             {SiteWatcherDeInstall Lo Pro}

             {SiteWatcherInstall Po Pro}
             {SiteWatcherInstall Va Pro}
             {SiteWatcherInstall Ce Pro}
             {SiteWatcherInstall Lo Pro}
             {System.gcDo}
             {SiteWatcherDeInstall Lo Pro}
             {SiteWatcherDeInstall Po Pro}
             {SiteWatcherDeInstall Va Pro}
             {SiteWatcherDeInstall Ce Pro}
             {S close}

             {TryVar  Va}
             {TryCell Ce}
             {TryPort Po}
             {TryLock Lo}
             local CC = {NewCell false} in
                try
                   Sync = true
                catch _ then
                   {Assign CC true}
                end
                {Access CC false}
             end

          end
          keys:[fault])


       fault_handover_watcher_injector(
          proc {$}
             Po
             Ce
             Lo
             Pro1 = proc{$ A B C} raise hell end end
             Sync
             Pro2 = proc{$ A B} Sync = false end
             S
             CC = {NewCell false}
          in

             {InjectorInstall Po Pro1}
             {InjectorInstall Ce Pro1}
             {InjectorInstall Lo Pro1}

             {SiteWatcherInstall Po Pro2}
             {SiteWatcherInstall Ce Pro2}
             {SiteWatcherInstall Lo Pro2}

             {StartServer S o(port:Po cell:Ce lokk:Lo var:_)}
             {S close}
             {Delay 1000}
             try
                {TryCell Ce}
                {Assign CC true}
             catch hell then skip end

             try
                {TryPort Po}
                {Assign CC true}
             catch hell then skip end

             try
                {TryLock Lo}
                {Assign CC true}
             catch hell then skip end


             try
                Sync = true
                raise hell end
             catch hell then
                raise hell end
             [] _ then skip end

             {Access CC false}
          end
          keys:[fault])

       fault_global_deinstall_watcher_handler(
          proc {$}
             Pol = {NewPort _}
             Cel = {NewCell apa}
             Lol = {NewLock}
             Val

             Po
             Ce
             Lo
             Va

             Sync
             Pro = proc{$ A B C}  Sync = false end
             ProW = proc{$ A B}  Sync = false end
             S
          in
             {StartServer S o(port:Po cell:Ce lokk:Lo var:Va)}


             {DeinstallInj Po Pro}
             {DeinstallInj Va Pro}
             {DeinstallInj Ce Pro}
             {DeinstallInj Lo Pro}

             {DeinstallWat Po ProW}
             {DeinstallWat Va ProW}
             {DeinstallWat Ce ProW}
             {DeinstallWat Lo ProW}

             {DeinstallInj Pol Pro}
             {DeinstallInj Val Pro}
             {DeinstallInj Cel Pro}
             {DeinstallInj Lol Pro}

             {DeinstallWat Pol ProW}
             {DeinstallWat Val ProW}
             {DeinstallWat Cel ProW}
             {DeinstallWat Lol ProW}

             {S close}

          end
          keys:[fault])
      ])
end
