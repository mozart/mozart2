%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
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

export
   Return

define
   Return=
   'thread'([resumeThis(proc {$}
			   {Thread.resume {Thread.this}}
			end
			keys:['thread' 'resume' fixedBug])
	     termLock(entailed(proc {$}
				  ID L={NewLock}
				  S A
			       in
				  thread
				     lock L then S=unit {Wait A} end
				  end
				  thread
				     ID={Thread.this}
				     lock L then skip end
				  end
				  {Wait ID}
				  %% Kill thread
				  {Thread.terminate ID}
				  A=1
				  lock L then skip end
			       end)
		      keys: ['thread' 'lock' 'injectExcpetion' 'raise'])
	     termLock2(proc {$}
			  % As reported in bug 595
			  L={NewLock} DeathAgony=100 T1 T2
			  proc {TryLock N}
			     try
				lock L then {Delay 1000} end
			     catch abortLock then
				{Delay DeathAgony}
			     end
			  end
		       in
			  thread T1={Thread.this} {TryLock 1} end
			  {Delay 100}
			  thread T2={Thread.this} {TryLock 2} end
			  {Delay 100}
			  {Thread.injectException T2 abortLock}
		       end
		       keys: ['thread' 'lock' efixedBug])
	    ])
end
