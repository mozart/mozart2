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
   'thread'([
             stopResume(proc {$}
                        T X Y in
                        thread
                           T = {Thread.this}
                           {Wait X}
                           Y = unit
                        end

                        %% wait until T determined and stop it
                        {Thread.suspend T}

                        %% wakeup T, Note: T is scheduled
                        X = unit

                        %% ensure that T is removed from the runnable queue
                        {Thread.preempt {Thread.this}}

                        %% now resume T
                        {Thread.resume T}

                        %% wait until T is finished
                        {Wait Y}
                     end
                     keys:['thread' 'resume' fixedBug])
             resumeThis(proc {$}
                           {Thread.resume {Thread.this}}
                        end
                        keys:['thread' 'resume' fixedBug])
            ])
end
