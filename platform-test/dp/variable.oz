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
   DP
export
   Return
define
   NrOfPhases = 3
   ForkingSpeed = 3
   Sites = 3

   fun {Start EntityProtocol}
      proc {$}
	 Managers
      in
	 try
	    local
	       proc {Loop Ms L R}
		  case Ms
		  of M|Mr then LR in
		     {DP.annotate LR EntityProtocol}
		     thread {StartSite EntityProtocol M L LR} end
		     {Loop Mr LR R}
		  [] nil then
		     L = R
		  end
	       end
	       L R Hosts ControllerThread
	       {DP.annotate L EntityProtocol}
	    in
	       {TestMisc.getHostNames Hosts}
	       {TestMisc.getRemoteManagers Sites Hosts Managers}
	       thread {Loop Managers L R} end
	       thread
		  {Thread.this ControllerThread}
		  {Controller L R 1}
	       end
	       if L == R then
		  %% Controller mission completed
		  {Thread.terminate ControllerThread}
	       else
		  raise dp_variable_test_failed end
	       end
	    end
	 catch X then
	    {TestMisc.gcAll Managers}
	    raise X end
	 end
	 {TestMisc.gcAll Managers}
	 {TestMisc.listApply Managers close}
      end
   end
   
   proc {Controller L R PhaseNr}
      case L of H1|L1 then
	 case R of H2|R1 then
	    if H1 == H2 then
	       H1 = done
	       {Controller L1 R1 PhaseNr+1}
	    else
	       raise dp_variable_test_failed end
	    end
	 else
	    {Controller L R PhaseNr}
	 end
      else
	 {Controller L R PhaseNr}
      end
   end

   proc {StartSite EntityProtocol RMan L R} Error in
      {RMan apply(url:'' functor
			 import
			    Property(put)
			    DP
			 define
			    {Property.put 'close.time' 1000}
			    
			    proc {Process L R PhaseNr NrLeftToFork
				  NrOfPhases ForkingSpeed}
			       if NrLeftToFork == 0 then
				  if PhaseNr == NrOfPhases then
				     {Finnish L R}
				  else
				     {PhaseFinnish L R PhaseNr
				      NrOfPhases ForkingSpeed}
				  end
			       else
				  {Fork L R PhaseNr NrLeftToFork
				   NrOfPhases ForkingSpeed}
			       end
			    end
			    
			    proc {Finnish L R}
			       L = R
			    end
			    
			    proc {PhaseFinnish L R PhaseNr
				  NrOfPhases ForkingSpeed} H L1 R1 in
			       L = H|L1
			       R = H|R1
			       {Wait H}
			       {Process L1 R1 PhaseNr+1 ForkingSpeed
				NrOfPhases ForkingSpeed}
			    end
			    
			    proc {Fork L R PhaseNr NrLeftToFork
				  NrOfPhases ForkingSpeed} LR in
			       {DP.annotate LR EntityProtocol}
			       thread
				  {Process L LR PhaseNr NrLeftToFork-1
				   NrOfPhases ForkingSpeed}
			       end
			       thread
				  {Process LR R PhaseNr NrLeftToFork-1
				   NrOfPhases ForkingSpeed}
			       end
			    end
			    
			    proc {Start L R Cell ForkingSpeed NrOfPhases
				  Error}
			       MemCell = {NewCell ok} in
			       try
				  {Process L R 1 ForkingSpeed
				   NrOfPhases ForkingSpeed}
			       catch X then
				  {Assign MemCell X} 
			       end
			       Error = {Access MemCell}
			    end
			    
			    {Start L R Cell ForkingSpeed NrOfPhases Error}
			 end)}
      {TestMisc.raiseError Error}
   end

   Return = dp([variable({Map [variable reply]
			  fun {$ Prot}
			     Prot({Start Prot} keys:[remote Prot])
			  end})])
end
