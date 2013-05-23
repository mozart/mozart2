%%%
%%% Authors:
%%%   Andreas Sundstroem (andreas@sics.se)
%%%
%%% Copyright:
%%%   Andreas Sundstroem (andreas@sics.se)
%%%
%%% Last change:
%%%   $Date$Author: 
%%%   $Revision: 
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
   TestMisc
export
   Return
define
   Sites = 3
   
   proc {Start} Managers in
      try
	 local
	    proc {Loop Ms I Ss Ps}
	       case Ms
	       of M|Mr then S Sr Pr in
		  Ss = {NewPort S}|Sr
		  Ps = proc {$} {StartSite M S I*100} end | Pr
		  {Loop Mr I Sr Pr}
	       [] nil then
		  Ss = Ps = nil
	       end
	    end
	    SendPorts Procs Hosts
	 in
	    {TestMisc.getHostNames Hosts}
	    {TestMisc.getRemoteManagers Sites Hosts Managers}
	    {Loop Managers 1 SendPorts Procs}
	    {TestMisc.barrierSync Procs}
	    {MsgManager SendPorts 60 3 3}
	    {List.forAll SendPorts proc {$ SP} {Send SP kill} end}
	 end
      catch X then
	 {TestMisc.gcAll Managers}
	 raise X end
      end	 
      {TestMisc.gcAll Managers}
      {TestMisc.listApply Managers close}
   end

   proc {StartSite RMan Ls Id} Error in
      {RMan apply(url:'' functor
			 import
			    Property(put)
			 define
			    {Property.put 'close.time' 1000}
			    
			    proc {Server Ls Id} L Lr in
			       L|Lr = Ls
			       case L
			       of newSenders(N S P) then
				  {StartSenders N Id S P}
				  {Server Lr Id}
			       [] kill then
				  skip
			       end
			    end
			    
			    proc {StartSenders N Id S P}
			       if N == 0 then
				  skip
			       else
				  thread {Sender S Id+N 0 P} end
				  {StartSenders N-1 Id S P}
			       end
			    end
			    
			    proc {Sender Ls Id LastMsg Port} L Lr in
			       L|Lr = Ls
			       case L
			       of newPort(P) then
				  {Send Port ack}
				  {Sender Lr Id LastMsg P}
			       [] send then
				  {Send Port msg(Id LastMsg+1)}
				  {Sender Lr Id LastMsg+1 Port}
			       [] kill then
				  skip
			       end
			    end

			    proc {Start Ls Id Error}
			       MemCell = {NewCell ok} in
			       try
				  thread {Server Ls Id} end
			       catch X then
				  {Assign MemCell X} 
			       end
			       Error = {Access MemCell}
			    end

			    {Start Ls Id Error}
			 end)}
      {TestMisc.raiseError Error}
   end
			       
   
   proc {Receiver Ls History AckCtr} L Lr Old in
      L|Lr = Ls
      case L
      of msg(Id MsgNr) then
	 {Dictionary.condGet History Id 0 Old}
	 if Old > MsgNr then
	    raise dp_port_test_failed end
	 else skip end
	 {Receiver Lr History AckCtr}
      [] ack then
	 if AckCtr == 1 then
	    skip
	 else
	    {Receiver Lr History AckCtr-1}
	 end
      end
   end

   proc {MsgManager SitePorts NrOfSenders NrOfMsgs NrOfPortChanges}
      proc {CommandToSend I} {Send Pout send} end
      Sin Pin Sout Pout SendersPerSite
   in
      SendersPerSite = NrOfSenders div {Length SitePorts}
      Pin = {NewPort Sin}
      Pout = {NewPort Sout}
      thread {Receiver Sin {NewDictionary} NrOfSenders} end
      {List.forAll SitePorts proc {$ SP}
			   {Send SP newSenders(SendersPerSite Sout Pin)}
			end}
      {For 1 NrOfMsgs 1 CommandToSend}
      {For 1 NrOfPortChanges 1 proc {$ _} S P in
				  P = {NewPort S}
				  thread
				    {Receiver S {NewDictionary} NrOfSenders}
				  end
				  {Send Pout newPort(P)}
				  {For 1 NrOfMsgs 1 CommandToSend}
			       end}
      {Send Pout newPort(_)}
      {Send Pout kill}
   end

   Return = dp([port(Start keys:[remote])])
end
