%%%
%%% Authors:
%%%   Raphael Collet <raph@info.ucl.ac.be>
%%%
%%% Copyright:
%%%   Raphael Collet, 2003
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

import
   Space

export
   Return

define
   Return =
   byneed([
           byneed(proc {$}
                     X Y={ByNeed fun {$} X end}
                  in
                     {Delay 500}
                     {ForAll [X Y] proc {$ Z}
                                      {Value.status Z} = free
                                      {IsNeeded Z} = false
                                   end}
                     {Value.makeNeeded Y}   % makes Y needed
                     {IsNeeded Y} = true
                     true = (X == Y)
                     {IsNeeded X} = true    % X is needed because X=Y
                  end
                  keys:[byneed])

           wait(proc {$}
                   X Y Z
                in
                   {ForAll [X Y Z] proc {$ A} {IsNeeded A} = false end}
                   thread {Wait X} end
                   thread {Value.waitQuiet Y} end
                   thread {WaitNeeded Z} end
                   {Delay 500}
                   {IsNeeded X} = true    % Wait has made X needed
                   {IsNeeded Y} = false   % waitQuiet did not make Y needed
                   {IsNeeded Z} = false   % WaitNeeded did not make Z needed
                end
                keys:[byneed wait waitQuiet waitNeeded])

           lazy(proc {$}   %% lazy functions
                   fun lazy {Next X} X+1 end
                   A = {Next 42}
                in
                   {Delay 500}
                   {Value.status A} = free   % not triggered yet
                   {IsNeeded A} = false
                   {Wait A}                  % trigger now
                   A = 43
                end
                keys:[byneed lazy])

           det(proc {$}   %% determination makes needed
                  X
               in
                  {IsNeeded X} = false
                  X = 42
                  {IsNeeded X} = true
               end
               keys:[byneed det])

           space(proc {$}   %% inter-space need
                    X S
                 in
                    X={ByNeed fun {$} 42 end}
                    S={Space.new proc {$ R} X=1 end}
                    % the space must trigger X and fail
                    {Space.ask S} = failed
                    X=42
                 end
                 keys:[byneed space])
          ])
end
