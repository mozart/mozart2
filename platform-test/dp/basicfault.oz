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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%\define DBG
functor

import
   Remote(manager)
   Fault
   System
   TestMisc(localHost)
export
   Return

define
\ifdef DBG
   PrintPort
   thread {ForAll {NewPort $ PrintPort} System.show} end
   proc {Show X}
      {Send PrintPort X}
   end
\else
   proc {Show _} skip end
\endif
   proc{SiteWatcherInstall Entity Proc}
      {Fault.installWatcher Entity [permFail] Proc true}
   end
   proc{SiteWatcherDeInstall Entity Proc}
      {Fault.deInstallWatcher Entity Proc true}
   end
   proc{InjectorInstall Entity Proc}
      {Fault.install Entity 'thread'(this) [permFail] Proc true}
   end
   proc{InjectorDeInstall Entity Proc}
      {Fault.deInstall Entity 'thread'(this) true}
   end
/*
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
*/

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
      [] _ then
         skip
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

       fault_detecting_managerLost_at_importing(
          proc {$}
             Po
             Va
             S1
             S2={New Remote.manager init(host:TestMisc.localHost)}
             Ans
          in
             {StartServer S1 o(port:Po cell:_ lokk:_ var:Va)}
             {S1 close}
             {Delay 1000}

             try
                {Send Po apa}
                raise stop end
             catch _ then
                skip
             end
             {S2 ping}

             thread
                % A helper that will stop this test if
                % the proxy suspends.
                % If you run the test repeatedly the delay has to be
                % this high!
                {Delay 100000}
                try Ans = crash {Show timeout} catch _ then skip end
             end

             {S2 apply(url:'' functor
                              define
                                 T in
                                 try
                                    {Show sending}
                                    {Send Po apa}
                                    {Show sent}
                                       % if the send succeds => crash
% This is no longer true, a send may succeed if we don't yet know the other
% site was lost. AN!
%                                   Ans = crash
                                 catch _ then
                                    {Show did_not_send}
                                 end

                                 thread
                                    try
                                       {Show binding}
                                       Va = unit
                                       {Show bound}
                                    catch _ then
                                       {Show did_not_bind}
                                       T  = done
                                    end
                                 end
                                 {Delay 500}
                                 % if the binding suspends => crash
                                 if{IsDet T} then
                                    Ans = ok
                                 else
                                    Ans = crash
                                 end
                              end)}

             {Show evaluating(Ans)}
             if Ans == crash then
                raise stop end
             end
             {Show evaluated(Ans)}
             {S2 close}
             {Show done}
          end
             keys:[fault])
      ])
end
