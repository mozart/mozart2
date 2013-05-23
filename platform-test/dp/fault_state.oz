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
   System(show showInfo)
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
   proc{SiteWatcherInstall Entity Proc}
      {Fault.installWatcher Entity [permFail] Proc true}
   end
   /*
   proc{SiteWatcherDeInstall Entity Proc}
      {Fault.deInstallWatcher Entity Proc true}
   end
   */
   proc{NetWatcherInstall Entity Proc}
      {Fault.installWatcher Entity
       [remoteProblem(permSome) remoteProblem(permAll)] Proc true}
   end
   /*
   proc{NetWatcherDeInstall Entity Proc}
      {Fault.deInstallWatcher Entity Proc true}
   end
   */
   
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
   /*
   proc{TryLock L}
      try
	 lock L then skip end
	 raise abort end
      catch injector then skip end
   end
   */
   proc{WaitPerm P}
      try
	 {Send P hi}
	 {Delay 10}
	 {WaitPerm P}
      catch system(dp(conditions:[permFail] ...) ...) then
	 skip
      end
   end
   
   Return=
   dp([
       fault_proxy_naive(
	  proc {$}
	     S={New Remote.manager init(host:TestMisc.localHost)}
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
				{Access DistCell} = {NewPort _}
				{Assign DistCell skit}
			     end)}
	     {S ping}
	     {Wait Sync}
	     {S close}
	     {WaitPerm Sync}
	     try
		{Access DistCell _}
		{Assign CC true}
	     catch _ then
		skip
	     end
	     try
		{Access CC false}
	     catch _ then {System.showInfo 'fault_proxy_naive'} end
	  end
	  keys:[fault])
       fault_state_manager_injector_live(
	  proc {$}
	     S={New Remote.manager init(host:TestMisc.localHost)}
	     _ = {NewCell false}
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
				{Access DistCell} = {NewPort _}
				{Assign DistCell skit}
				lock DistLock then skip end
			     end)}
	     {S ping}
	     {Wait Sync}
	     {InjectInj DistCell DistLock}
	     {S close}
	     {WaitPerm Sync}
	     try
		{TryCell DistCell}
	     catch abort then {System.showInfo 'dp_fault_state_manager_injector_live may have a problem'} end
	  end
	  keys:[fault])

       fault_state_manager_injector_dead(
	  proc {$}
	     S={New Remote.manager init(host:TestMisc.localHost)}
	     _ = {NewCell false}
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
				{Access DistCell} = {NewPort _}
				{Assign DistCell skit}
			     end)}
	     {S ping}
	     {Wait Sync}
	     {S close}
	     {WaitPerm Sync}
	     {InjectInj DistCell DistLock}
	     try
		{TryCell DistCell}
	     catch abort then {System.showInfo 'dp_fault_state_manager_injector_dead may have a problem'} end
	  end
	  keys:[fault])

       fault_state_manager_watcher_live(
	  proc {$}
	     S={New Remote.manager init(host:TestMisc.localHost)}
	     _ = {NewCell false}
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
				{Access DistCell} = {NewPort _}
				{Assign DistCell skit}
				lock DistLock then skip end
			     end)}
	     {S ping}
	     {Wait Sync}
% Swap these two lines
% and it doesn't work	     
 	     {InjectInj DistCell DistLock}
	     {WatchWat DistCell DistLock AA}
%	     {InjectInj DistCell DistLock}
%	     
	     AA.lokk = unit
	     {S close}
	     {WaitPerm Sync}
	     try
		{TryCell DistCell}
		{CheckWat AA}
	     catch _ then {System.showInfo 'dp_fault_state_manager_watcher_live may have a problem'} end
	  end
	  keys:[fault])

       fault_state_manager_watcher_dead(
	  proc {$}
	     S={New Remote.manager init(host:TestMisc.localHost)}
	     _ = {NewCell false}
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
				{Access DistCell} = {NewPort _}
				{Assign DistCell skit}
				lock DistLock then skip end
			     end)}
	     {S ping}
	     {Wait Sync}
	     {S close}
	     {WaitPerm Sync}
	     {InjectInj2 DistCell DistLock AA}
	     try
	        {Access DistCell _}
	     catch _ then 
                skip
	     end
	     try
		{CheckWatM AA}
	     catch _ then {System.showInfo 'dp_fault_manager_watcher_dead may have a problem'} end
	  end
	  keys:[fault])

%        ERIK, this test has allso race konditions.        
%        fault_state_proxy_tokenLost_live_injector(
% 	  proc {$}
% 	     S1={New Remote.manager init(host:TestMisc.localHost)}
% 	     S2={New Remote.manager init(host:TestMisc.localHost)}
% 	     P2
% 	     Sync
% 	     DistCell
% 	     Inj = proc{$ A B C} raise injector end end
% 	  in
% 	     {S1 ping}
% 	     {S1 apply(url:'' functor
% 			      export MyCell
% 			      define
% 				 MyCell = {NewCell apa}
% 			      end $)}.myCell=DistCell

% 	     {S2 ping}
% 	     {S2 apply(url:'' functor
% 			      export
% 				 MyPort
% 			      import Property
% 			      define
% 				 MyPort = {NewPort _}
% 				 {Property.put  'close.time' 0}
% 				 {Assign DistCell unit}
% 				 !Sync = unit
% 			      end $)}.myPort=P2

% 	     {Wait Sync}
% 	     {InjectorInstall DistCell Inj}
% 	     {S2 close}
% 	     {WaitPerm P2}
% 	     try
% 		{TryCell DistCell}
% 	     catch abort then {System.showInfo 'dp_fault_state_proxy_tokenLost_live_injector may have a problem'} end
% 	     {S1 close}
% 	  end
% 	  keys:[fault])

       %% kost@ : this test has a race condition;
%        fault_state_proxy_tokenLost_dead_injector(
% 	  proc {$}
% 	     S1={New Remote.manager init(host:TestMisc.localHost)}
% 	     S2={New Remote.manager init(host:TestMisc.localHost)}
% 	     _ = {NewCell false}
% 	     P2
% 	     Sync
% 	     DistCell
% 	     Inj = proc{$ A B C} raise injector end end
% 	  in
% 	     {S1 ping}
% 	     {S1 apply(url:'' functor
% 			      export MyCell
% 			      define
% 				 MyCell = {NewCell apa}
% 			      end $)}.myCell = DistCell
%
% 	     {S2 ping}
% 	     {S2 apply(url:'' functor
% 			      export MyPort
% 			      import Property
% 			      define
% 				 MyPort={NewPort _}
% 				 {Property.put  'close.time' 0}
% 				 {Assign DistCell unit}
% 				 !Sync = unit
% 			      end $)}.myPort=P2
%
% 	     {Wait Sync}
% 	     {InjectorInstall DistCell Inj}
% 	     {S2 close}
% 	     {WaitPerm P2}
% 	     try
% 		{System.show "access"#{Access DistCell}}
% 	     catch E then
% 		{System.show E}
% 	     end
% 	     {TryCell DistCell}
% 	     {S1 close}
% 	  end
%	  keys:[fault])

       fault_state_proxy_tokenLost_live_watcher(
	  proc {$}
	     S1={New Remote.manager init(host:TestMisc.localHost)}
	     S2={New Remote.manager init(host:TestMisc.localHost)}
	     P1 P2
	     CC = {NewCell false}
	     Sync
	     DistCell
	     _ = proc{$ A B} raise injector end end
	  in
	     {S1 ping}
	     {S1 apply(url:'' functor
			      export MyCell MyPort
			      define
				 MyPort={NewPort _}
				 MyCell = {NewCell apa}
			      end $)}='export'(myCell:DistCell myPort:P1)

	     {S2 ping}
	     {S2 apply(url:'' functor
			      export MyPort
			      import Property
			      define
				 MyPort={NewPort _}
				 {Property.put  'close.time' 0}
				 {Assign DistCell unit}
				 !Sync = unit
			      end $)}.myPort=P2

	     {Wait Sync}
	     {SiteWatcherInstall DistCell proc{$ A B}
					     {Assign CC true}
					  end}
	     {S2 close}
	     {S1 close}
	     {WaitPerm P2}
	     {WaitPerm P1}
	     try
		{Access CC true}
	     catch _ then {System.showInfo 'dp_fault_state_proxy_tokenLost_live_watcher may have a problem'} end
	  end
	  keys:[fault])


       fault_state_proxy_tokenLost_dead_watcher(
	  proc {$}
	     S1={New Remote.manager init(host:TestMisc.localHost)}
	     S2={New Remote.manager init(host:TestMisc.localHost)}
	     P1 P2
	     CC = {NewCell false}
	     Sync
	     DistCell
	     _ = proc{$ A B} raise injector end end
	  in
	     {S1 ping}
	     {S1 apply(url:'' functor
			      export MyCell MyPort
			      define
				 MyPort={NewPort _}
				 MyCell = {NewCell apa}
			      end $)}='export'(myCell:DistCell myPort:P1)
	     {S2 ping}
	     {S2 apply(url:'' functor
			      export MyPort
			      import Property
			      define
				 MyPort={NewPort _}
				 {Property.put  'close.time' 0}
				 {Assign DistCell unit}
				 !Sync = unit
			      end $)}.myPort=P2

	     {Wait Sync}
	     {S2 close}
	     {WaitPerm P2}
	     {SiteWatcherInstall DistCell proc{$ B C}
					     {Assign CC true}
					  end}
	     {S1 close}
	     {WaitPerm P1}
	     try
		{Access CC true}
	     catch _ then {System.showInfo 'dp_fault_state_proxy_tokenLost_dead_watcher may have a problem'} end
	  end
	  keys:[fault])
       
       
       fault_chain_broken_watcher_dead(
	  proc {$}
	     S1={New Remote.manager init(host:TestMisc.localHost)}
	     S2={New Remote.manager init(host:TestMisc.localHost)}
	     S3={New Remote.manager init(host:TestMisc.localHost)}
	     P1 P2 P3
	     CC = {NewCell false}
	     DistLock
	     Sync1 Sync2 Sync3 Sync4
	     
	  in
	     {S1 ping}
	     {S1 apply(url:'' functor
			      export MyLock MyPort
			      define
				 MyPort={NewPort _}
				 MyLock = {NewLock}
			      end $)} = 'export'(myLock:DistLock myPort:P1)
	     

	     {S2 ping}
	     {S2 apply(url:'' functor
			      export MyPort
			      import Property
			      define
				 MyPort={NewPort _}
				 {Property.put 'close.time' 0}
				 thread
				    lock DistLock then  
				       !Sync2 = unit
				       {Wait Sync1}
				    end
				 end
			      end $)} = 'export'(myPort:P2)
	     
	     
	     {Wait Sync2}
	     {S2 close}
	     {WaitPerm P2}
	     {NetWatcherInstall DistLock
	      proc{$ A B}
		 {Assign CC true}
	      end}

	     {S3 apply(url:'' functor
			      export MyPort
			      define
				 MyPort={NewPort _}
				 thread
				    lock DistLock then  
				       !Sync3 = unit
				    end
				 end
			      end $)} = 'export'(myPort:P3)
	       
	     {S3 ping}
	     
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
	     {WaitPerm P3}
	     {WaitPerm P1}
	     try
		{Access CC true}
	     catch _ then {System.showInfo 'dp_fault_chain_broken_watcher_dead may have a problem'} end
	  end
	  keys:[fault])

       fault_chain_broken_watcher_live(
	  proc {$}
	     S1={New Remote.manager init(host:TestMisc.localHost)}
	     S2={New Remote.manager init(host:TestMisc.localHost)}
	     S3={New Remote.manager init(host:TestMisc.localHost)}
	     P1 P2 P3
	     CC = {NewCell false}
	     DistLock
	     Sync1 Sync2 Sync3 Sync4
	     
	  in
	     {S1 ping}
	     {S1 apply(url:'' functor
			      export MyLock MyPort
			      define
				 MyPort={NewPort _}
				 MyLock = {NewLock}
			      end $)} = 'export'(myLock:DistLock myPort:P1)
	     

	     {S2 ping}
	     {S2 apply(url:'' functor
			      export MyPort
			      import Property
			      define
				 MyPort={NewPort _}
				 {Property.put 'close.time' 0}
				 thread
				    lock DistLock then  
				       !Sync2 = unit
				       {Wait Sync1}
				    end
				 end
			      end $)} = 'export'(myPort:P2)
	     
	     
	     {Wait Sync2}
	     {NetWatcherInstall DistLock
	      proc{$ A B}
		 {Assign CC true}
	      end}
	     {S2 close}
	     {WaitPerm P2}

	     {S3 apply(url:'' functor
			      export MyPort
			      define
				 MyPort={NewPort _}
				 thread
				    lock DistLock then  
				       !Sync3 = unit
				    end
				 end
			      end $)} = 'export'(myPort:P3)
	       
	     {S3 ping}
	     
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
	     {WaitPerm P3}
	     {WaitPerm P1}
	     try
		{Access CC true}
	     catch _ then {System.showInfo 'dp_fault_chain_broken_watcher_live may have a problem'} end
	  end
	  keys:[fault])
      ])
end




