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


   proc{InjectInj S}
      Inj = proc{$ A B} raise injector end end
   in
      {Fault.injector S.port Inj}
      {Fault.injector S.cell Inj}
      {Fault.injector S.lokk Inj}
      {Fault.injector S.var Inj}
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
   proc{TryPort P}
      try
         {Send P apa}
         raise abort end
      catch injector then skip end
   end

   proc{TryVar V}
      try
         V = apa
         raise abort end
      catch injector then skip end
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
       fault_inject_live_cell(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {InjectInj Deads}
             {S close}
             {Delay 2000}
             {TryCell Deads.cell}
          end
          keys:[fault])

       fault_inject_live_var(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {InjectInj Deads}
             {S close}
             {Delay 1000}
             {TryVar Deads.var}
          end
          keys:[fault])

       fault_inject_live_lokk(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {InjectInj Deads}
             {S close}
             {Delay 1000}
             {TryLock Deads.lokk}
          end
          keys:[fault])

       fault_inject_live_port(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {InjectInj Deads}
             {S close}
             {Delay 1000}
             {TryPort Deads.port}
          end
          keys:[fault])

       fault_inject_live_all(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {InjectInj Deads}
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
             {InjectInj Deads}
             {Delay 1000}
             {TryCell Deads.cell}
          end
          keys:[fault])

       fault_inject_dead_var(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {S close}
             {InjectInj Deads}
             {Delay 1000}
             {TryVar Deads.var}
          end
          keys:[fault])

       fault_inject_dead_lokk(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {InjectInj Deads}
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
             {InjectInj Deads}
             {Delay 1000}
             {TryPort Deads.port}
          end
          keys:[fault])

       fault_inject_dead_all(
          proc {$}
             S Deads in
             {StartServer S Deads}
             {S close}
             {InjectInj Deads}
             {Delay 1000}
             {TryPort Deads.port}
             {TryVar Deads.var}
             {TryCell Deads.cell}
             {TryLock Deads.lokk}
          end
          keys:[fault])
      ])
end
