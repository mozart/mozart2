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
   System
export
   Return

define
   proc{InjectorInstall Entity Proc}
      {Fault.install Entity 'thread'(this) [permFail] Proc true}
   end
   /*
   proc{InjectorDeInstall Entity Proc}
      {Fault.deInstall Entity 'thread'(this) true}
   end
   */

   proc{InjectInj S}
      Inj = proc{$ A B C} raise injector end end
   in
      {InjectorInstall S.port Inj}
      {InjectorInstall S.cell Inj}
      {InjectorInstall S.lokk Inj}
      {InjectorInstall S.var Inj}
      {InjectorInstall S.object Inj}
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
         {For 1 1000000000 1
          proc {$ _} {Send P apa} {Delay 50} end}
         raise abort end
      catch injector then skip end
   end

   proc{TryVar V}
      try
         V = apa
         raise abort end
      catch injector then skip end
   end

   proc{TryObjectCode O}
      try
         {O c}
         raise abort end
      catch injector then skip end
   end

   proc{TryObjectFeat O}
      try
         _ = O.b
         raise abort end
      catch injector then skip end
   end

   proc{TryObjectState O}
      try
         {O read(_)}
         raise abort end
      catch injector then skip end
   end

   proc{TryObjectLock O}
      try
         {O write(3)}
         raise abort end
      catch injector then skip end
   end

   proc{TryObjectTouchedState O}
      try
         _ = O.b
         {O read(_)}
         raise abort end
      catch injector then skip end
   end

   proc{TryObjectTouchedLock O}
      try
         _ = O.b
         {O write(3)}
         raise abort end
      catch injector then skip end
   end

   proc{WaitPerm P}
      try
         {Send P hi}
         {Delay 10}
         {WaitPerm P}
      catch system(dp(conditions:[permFail] ...) ...) then
         skip
      end
   end

   proc{StartServer S E CtrlPort}
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
                              var:_)#{NewPort _}
                      end $)}.my = E#CtrlPort
      {S ping}
   end

   Return=
   dp([
       fault_inject_live_cell(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {InjectInj Deads}
             {S close}
             {WaitPerm P}
             {TryCell Deads.cell}
          end
          keys:[fault])

       fault_inject_live_var(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {InjectInj Deads}
             {S close}
             {WaitPerm P}
             {TryVar Deads.var}
          end
          keys:[fault])

       fault_inject_live_lokk(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {InjectInj Deads}
             {S close}
             {WaitPerm P}
             {TryLock Deads.lokk}
          end
          keys:[fault])

       fault_inject_live_port(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {InjectInj Deads}
             {S close}
             {WaitPerm P}
             {TryPort Deads.port}
          end
          keys:[fault])

       fault_inject_live_object_code(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {InjectInj Deads}
             {S close}
             {WaitPerm P}
             {TryObjectCode Deads.object}
          end
          keys:[fault])

       fault_inject_live_object_feat(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {InjectInj Deads}
             {S close}
             {WaitPerm P}
             {TryObjectFeat Deads.object}
          end
          keys:[fault])

       fault_inject_live_object_state(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {InjectInj Deads}
             {S close}
             {WaitPerm P}
             {TryObjectState Deads.object}
          end
          keys:[fault])

       fault_inject_live_object_lokk(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {InjectInj Deads}
             {S close}
             {WaitPerm P}
             {TryObjectLock Deads.object}
          end
          keys:[fault])

       fault_inject_live_object_touchedState(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {InjectInj Deads}
             {S close}
             {WaitPerm P}
             {TryObjectTouchedState Deads.object}
          end
          keys:[fault])

       fault_inject_live_object_touchedLokk(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {InjectInj Deads}
             {S close}
             {WaitPerm P}
             {TryObjectTouchedLock Deads.object}
          end
          keys:[fault])

       fault_inject_live_all(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {InjectInj Deads}
             {S close}
             {WaitPerm P}
             {TryPort Deads.port}
             {TryVar Deads.var}
             {TryCell Deads.cell}
             {TryLock Deads.lokk}
             {TryObjectCode Deads.object}
             {TryObjectFeat Deads.object}
             {TryObjectState Deads.object}
             {TryObjectLock Deads.object}
             {TryObjectTouchedState Deads.object}
             {TryObjectTouchedLock Deads.object}
          end
          keys:[fault])

       fault_inject_dead_cell(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
             {TryCell Deads.cell}
          end
          keys:[fault])

       fault_inject_dead_var(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
             {TryVar Deads.var}
          end
          keys:[fault])

       fault_inject_dead_lokk(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {InjectInj Deads}
             {S close}
             {WaitPerm P}
             {TryLock Deads.lokk}
          end
          keys:[fault])
       fault_inject_dead_port(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
             {TryPort Deads.port}
          end
          keys:[fault])

       fault_inject_dead_code(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
          end
          keys:[fault])
       fault_inject_dead_feat(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
          end
          keys:[fault])
       fault_inject_dead_state(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
          end
          keys:[fault])
       fault_inject_dead_lokk(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
          end
          keys:[fault])
       fault_inject_dead_object_code(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
             {TryObjectCode Deads.object}
          end
          keys:[fault])
       fault_inject_dead_object_feat(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
          end
          keys:[fault])
       fault_inject_dead_object_state(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
             {TryObjectState Deads.object}
             {TryObjectFeat Deads.object}
          end
          keys:[fault])
       fault_inject_dead_object_lokk(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
             {TryObjectLock Deads.object}
          end
          keys:[fault])
       fault_inject_dead_object_touchedState(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
             {TryObjectTouchedState Deads.object}
          end
          keys:[fault])
       fault_inject_dead_object_touchedLokk(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
             {TryObjectTouchedLock Deads.object}
          end
          keys:[fault])

       fault_inject_dead_all(
          proc {$}
             S Deads P in
             {StartServer S Deads P}
             {S close}
             {InjectInj Deads}
             {WaitPerm P}
             {TryPort Deads.port}
             {TryVar Deads.var}
             {TryCell Deads.cell}
             {TryLock Deads.lokk}
             {TryObjectCode Deads.object}
             {TryObjectFeat Deads.object}
             {TryObjectState Deads.object}
             {TryObjectLock Deads.object}
             {TryObjectTouchedState Deads.object}
             {TryObjectTouchedLock Deads.object}
          end
          keys:[fault])
      ])
end
