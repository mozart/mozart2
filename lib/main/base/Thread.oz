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


declare
   Thread IsThread
in


%%
%% Global
%%
IsThread = {`Builtin` 'Thread.is' 2}


%%
%% Module
%%
local
   GetThreadPriority = {`Builtin` 'Thread.getPriority' 2}
   SetThreadPriority = {`Builtin` 'Thread.setPriority' 2}
   ThisThread        = {`Builtin` 'Thread.this' 1}
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
                    suspend:            {`Builtin` 'Thread.suspend'         1}
                    resume:             {`Builtin` 'Thread.resume'          1}
                    preempt:            {`Builtin` 'Thread.preempt'         1}
                    terminate:          proc {$ T}
                                           {Thread.injectException T
                                            {Exception.system
                                             kernel(terminate)}}
                                        end
                    injectException:    {`Builtin` 'Thread.injectException' 2}
                    state:              {`Builtin` 'Thread.state'           2}
                    isSuspended:        {`Builtin` 'Thread.isSuspended'     2})

end
