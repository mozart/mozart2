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
   %% test the basic ticket mechanism of Mozart.
   %% Creates one client that in turn creates a second
   %% client. Both clients creates tickets and exports
   %% them back to the Manager.
   %% The manager first tries to take the ticket of
   %% the second client(killed bu the first client)
   %% then kills the first client and then tries to
   %% take the ticket from the first client.
   %%
   %% The test succeds if the Manager is unable to
   %% take any of the tickets. 
   %%
import
   DP
   Remote(manager)
   Connection
   TestMisc(localHost)
export
   Return

define
   proc{WaitPerm P}
      {Wait P}
      {List.member permFail {DP.getFaultStream P}}=true
   end
   
   Return=
   dp([
       maxi(
	  proc{$}
	     ClientPort Ticket1 Ticket2 
	     S CC = {NewCell false}
	     LocalHost = TestMisc.localHost in
	     S={New Remote.manager init(host:LocalHost)}
	     {S ping}
	     {S apply(url:'' functor
			     import
				Property
				Remote
				System
				Connection
				DP
			     export
				My
			     define
				{Property.put 'close.time' 0}
				proc{WaitPerm P}
				   {Wait P}
				   {List.member permFail
				    {DP.getFaultStream P}}=true
				end
				local
				   S A ClientPort
				   P = {NewPort _}
				in
				   S={New Remote.manager init(host:LocalHost)}
				   {S ping}
				   try 
				      {S apply(url:'' functor
						      import
							 Connection
							 Property
						      export
							 MyExp
						      define
							 {Property.put 'close.time' 0}
							 MyExp = {NewPort _}#{Connection.offer _}
						      end $)}.myExp = ClientPort#A
					 
				   catch XX then
				      {System.show s1(XX)}
				   end
				   {S close}
				   {WaitPerm ClientPort}
				   My = P#A#{Connection.offer _}
				      
				end
			     end $)}.my = ClientPort#Ticket2#Ticket1
	     {S ping}
	     try
		{Connection.take Ticket2 _}
		
		{Assign CC true}
	     catch _ then
		skip
	     end
	     
	     {S close}
	     {WaitPerm ClientPort}
	     
	     try
		{Connection.take Ticket1 _}
		{Assign CC true}
		
	     catch _ then
		skip
	     end
	     
	     try
		{Connection.take Ticket2 _}
		{Assign CC true}
		
	     catch _ then
		skip
	     end
	     
	     try
		{Connection.take Ticket1 _}
		{Assign CC true}
		
	     catch _ then
		skip
	     end
	     {Access CC false}
	  end
	  keys:[fault])
      ])
end










