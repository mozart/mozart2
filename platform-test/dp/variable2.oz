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
   TestMisc(localHost)
   System
export
   Return

define
   
   Return=
   dp([
       var_isDet_and_gc(
% Test the isdetProtocol and garbage collection.
proc {$}
   S={New Remote.manager init(host:TestMisc.localHost)}
   Sync 
   % used to put a manager var from the proxy in.
   DistCell = {NewCell Sync}
   
in
   {S ping}
   {S apply(url:'' functor
		   import
		      Property
		   define
		      {Property.put  'close.time' 0}
		      {Wait DistCell}
		      {Access DistCell} = unit
		      {Assign DistCell _}
		   end)}
   {S ping}
   {Wait Sync}
   {Access DistCell _} %% Just transfer the state.
   {Wait {Loop.forThread 1 100 1
	  fun{$ Acc _}
	     AccOut in
	     thread {IsDet {Access DistCell} _} AccOut=Acc end
	     {System.gcDo}
	     AccOut
	  end
	  done}}
   {S close}
   {Delay 500}
end
	  keys:[var])
       var_deregister_and_gc(
% Test the deregistration of proxies at a variable manager.
% The aim is to have the variable bound and then receive a
% deregister from the client. 
proc {$}
   S={New Remote.manager init(host:TestMisc.localHost)}
   PP
in
   {S ping}
   {S apply(url:'' functor
		   import
		      Property
		      System
		   define
		      S in
		      {Property.put  'close.time' 0}
		      PP = {NewPort S}
		      thread 
			 {ForAll S proc{$ _}  {System.gcDo} end}
		      end
		   end)}
   {S ping}

   {Wait {Loop.forThread 1 100 1
	  fun{$ Acc X}
	     AccOut  Y Z G in
	     {Send PP Y}
	     thread {Delay X} Y = a(Z G)  AccOut=Acc end
	     {System.gcDo}
	     AccOut
	  end
	  done}}
   {S ping}
   {S close}
   {Delay 500}
end
	  keys:[var])
       
       
      ])
end




