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
         {Fault.removeInjector Po Pro}
         {Assign CC false}
      catch _ then skip end

      {Fault.injector Po Pro}
      {Fault.removeInjector Po Pro}

      try
         {Fault.removeInjector Po Pro}
         {Assign CC false}
      catch _ then skip end
      {Access CC} = true
   end


   proc{DeinstallWat Po Pro}
      CC = {NewCell true}
   in
      try
         {Fault.removeSiteWatcher Po Pro}
         {Assign CC false}
      catch _ then skip end

      {Fault.siteWatcher Po Pro}
      {Fault.removeSiteWatcher Po Pro}

      try
         {Fault.removeSiteWatcher Po Pro}
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
             Pro = proc{$ A B} raise hell end end
          in
             {Fault.injector Po Pro}
             {Fault.removeInjector Po Pro}

             {Fault.injector Va Pro}
             {Fault.removeInjector Va Pro}

             {Fault.injector Ce Pro}
             {Fault.removeInjector Ce Pro}

             {Fault.injector Lo Pro}
             {Fault.removeInjector Lo Pro}

             {Fault.injector Po Pro}
             {Fault.injector Va Pro}
             {Fault.injector Ce Pro}
             {Fault.injector Lo Pro}
             {System.gcDo}
             {Fault.removeInjector Lo Pro}
             {Fault.removeInjector Po Pro}
             {Fault.removeInjector Va Pro}
             {Fault.removeInjector Ce Pro}
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
             {Fault.siteWatcher Po Pro}
             {Fault.removeSiteWatcher Po Pro}

             {Fault.siteWatcher Va Pro}
             {Fault.removeSiteWatcher Va Pro}

             {Fault.siteWatcher Ce Pro}
             {Fault.removeSiteWatcher Ce Pro}

             {Fault.siteWatcher Lo Pro}
             {Fault.removeSiteWatcher Lo Pro}

             {Fault.siteWatcher Po Pro}
             {Fault.siteWatcher Va Pro}
             {Fault.siteWatcher Ce Pro}
             {Fault.siteWatcher Lo Pro}
             {System.gcDo}
             {Fault.removeSiteWatcher Lo Pro}
             {Fault.removeSiteWatcher Po Pro}
             {Fault.removeSiteWatcher Va Pro}
             {Fault.removeSiteWatcher Ce Pro}
          end
          keys:[fault])
       fault_global_install_deinstall_injector(
          proc {$}
             Va
             Po
             Ce
             Lo
             Pro = proc{$ A B} raise hell end end
             S
          in
             {StartServer S o(port:Po cell:Ce lokk:Lo var:Va)}

             {Fault.injector Po Pro}
             {Fault.removeInjector Po Pro}

             {Fault.injector Va Pro}
             {Fault.removeInjector Va Pro}

             {Fault.injector Ce Pro}
             {Fault.removeInjector Ce Pro}

             {Fault.injector Lo Pro}
             {Fault.removeInjector Lo Pro}

             {Fault.injector Po Pro}
             {Fault.injector Va Pro}
             {Fault.injector Ce Pro}
             {Fault.injector Lo Pro}
             {System.gcDo}
             {Fault.removeInjector Lo Pro}
             {Fault.removeInjector Po Pro}
             {Fault.removeInjector Va Pro}
             {Fault.removeInjector Ce Pro}

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

             {Fault.siteWatcher Po Pro}
             {Fault.removeSiteWatcher Po Pro}

             {Fault.siteWatcher Va Pro}
             {Fault.removeSiteWatcher Va Pro}

             {Fault.siteWatcher Ce Pro}
             {Fault.removeSiteWatcher Ce Pro}

             {Fault.siteWatcher Lo Pro}
             {Fault.removeSiteWatcher Lo Pro}

             {Fault.siteWatcher Po Pro}
             {Fault.siteWatcher Va Pro}
             {Fault.siteWatcher Ce Pro}
             {Fault.siteWatcher Lo Pro}
             {System.gcDo}
             {Fault.removeSiteWatcher Lo Pro}
             {Fault.removeSiteWatcher Po Pro}
             {Fault.removeSiteWatcher Va Pro}
             {Fault.removeSiteWatcher Ce Pro}
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
             Va
             Po
             Ce
             Lo
             Pro1 = proc{$ A B} raise hell end end
             Sync
             Pro2 = proc{$ A B} Sync = false end
             S
             CC = {NewCell false}
          in

             {Fault.injector Po Pro1}
             {Fault.injector Va Pro1}
             {Fault.injector Ce Pro1}
             {Fault.injector Lo Pro1}

             {Fault.siteWatcher Po Pro2}
             {Fault.siteWatcher Va Pro2}
             {Fault.siteWatcher Ce Pro2}
             {Fault.siteWatcher Lo Pro2}



             {StartServer S o(port:Po cell:Ce lokk:Lo var:Va)}
             {S close}
             {Delay 1000}
             try
                {TryVar  Va}
                {Assign CC true}
             catch hell then skip end

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
             Pro = proc{$ A B}  Sync = false end
             S
          in
             {StartServer S o(port:Po cell:Ce lokk:Lo var:Va)}


             {DeinstallInj Po Pro}
             {DeinstallInj Va Pro}
             {DeinstallInj Ce Pro}
             {DeinstallInj Lo Pro}

             {DeinstallWat Po Pro}
             {DeinstallWat Va Pro}
             {DeinstallWat Ce Pro}
             {DeinstallWat Lo Pro}

             {DeinstallInj Pol Pro}
             {DeinstallInj Val Pro}
             {DeinstallInj Cel Pro}
             {DeinstallInj Lol Pro}

             {DeinstallWat Pol Pro}
             {DeinstallWat Val Pro}
             {DeinstallWat Cel Pro}
             {DeinstallWat Lol Pro}

             {S close}

          end
          keys:[fault])
      ])
end
