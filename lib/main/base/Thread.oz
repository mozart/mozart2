%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Martin Mueller (mmueller@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1997
%%%   Martin Mueller, 1997
%%%   Christian Schulte, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
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


%%
%% Module
%%
local
   GetThreadPriority = Boot_Thread.getPriority
   SetThreadPriority = Boot_Thread.setPriority
   ThisThread        = Boot_Thread.this
   fun {GetThisPriority}
      {GetThreadPriority {ThisThread}}
   end
   proc {SetThisPriority I}
      {SetThreadPriority {ThisThread} I}
   end
in

   Thread= 'thread'(setPriority:        SetThreadPriority
                    getPriority:        GetThreadPriority
                    setThisPriority:    SetThisPriority
                    getThisPriority:    GetThisPriority
                    this:               ThisThread
                    is:                 IsThread
                    suspend:            Boot_Thread.suspend
                    resume:             Boot_Thread.resume
                    preempt:            Boot_Thread.preempt
                    terminate:          proc {$ T}
                                           {Thread.injectException T
                                            {Exception.system
                                             kernel(terminate)}}
                                        end
                    injectException:    Boot_Thread.injectException
                    state:              Boot_Thread.state
                    isSuspended:        Boot_Thread.isSuspended)

end
