%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Martin Mueller (mmueller@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1997
%%%   Martin Mueller, 1997
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

proc {Delay T} {Wait {Alarm T}} end

local

   %%%
   %%% default initialization
   %%%

   DefaultDelay      = 1000
   DefaultFun        = fun {$} DefaultDelay end
   DefaultNum        = ~1            %%% infinitely often
   DefaultAction     = dummyRep
   DefaultFinal      = finalRep

   %%%
   %%% private attributes
   %%%

   class Repeat
      prop
         locking

      % attributes:
      % Stop      : Stop trigger
      % Action    : Procedure or self message to be repeated
      % Final     : Procedure or self message to be performed at stop
      % Delay     : delay between iterations
      % DelayFun  : Function evaluating to the delay between iterations
      % Number    : number of iterations; loop ends with stop

      attr
         Stop:       unit
         Action:     DefaultAction
         Final:      DefaultFinal
         ActDelay:   DefaultDelay
         DelayFun:   DefaultFun
         NumReset:   DefaultNum
         NumberA:    DefaultNum

      meth setRepAll(action:     A <= DefaultAction
                     final:      F <= DefaultFinal
                     delay:      D <= DefaultDelay
                     delayFun:   DF<= DefaultFun
                     number:     N <= DefaultNum    )

         Repeat, setRepAction(A)
         Repeat, setRepFinal(F)
         Repeat, setRepNum(N)

         if DF == DefaultFun
         then Repeat, setRepDelay(D)
         else Repeat, setRepDelayFun(DF)
         end
      end

      meth getRep(action:    A  <= _
                  final:     F  <= _
                  delay:     D  <= _
                  delayFun:  DF <= _
                  number:    N  <= _
                  actual:    AN <= _)

         A  = @Action
         F  = @Final
         D  = @ActDelay
         DF = @DelayFun
         N  = @NumReset
         AN = @NumberA
      end

      meth setRepAction(A <= DefaultAction)
         Action <- A
      end

      meth setRepFinal(F <= DefaultFinal)
         Final <- F
      end

      meth setRepDelay(D <= DefaultDelay)
         ActDelay <- D
         DelayFun <- proc{$ X} X=D end
      end

      meth setRepDelayFun(F <= DefaultFun)
         ActDelay <- ~1
         DelayFun <- F
      end

      meth setRepNum(N <= DefaultNum)
         NumberA <- N
         NumReset <- N
      end

      %%%
      %%% The iteration core
      %%%

      meth go
         if
            lock
               if {IsDet @Stop}
               then Stop <- _ true
               else false end
            end
         then Repeat, Run
         end
      end

      meth stop
         lock
            @Stop = unit
            NumberA <- @NumReset
         end
      end

      meth Run
         K D DF A N F
      in
         lock
            K = @Stop
            %% D = @ActDelay
            DF= @DelayFun
            ActDelay<-D
            A = @Action
            F = @Final
            N = @NumberA
         end

         D = {DF}

         if {IsDet K}
         then skip
         elseif N==0
         then
            {self stop}
            {self Do(F)}
         else
            %% initiate timer BEFORE action so that the time to
            %% perform the action is included in the count down
            S = {Alarm D}
         in
            {self Do(A)}

            if N>0
            then NumberA <- N-1
            end

            {WaitOr S K}
            if {IsDet K} then skip else Repeat,Run end
         end
      end

      meth Do(A)
         if {IsProcedure A} then {A} else {self A} end
      end

      %%%
      %%% Action parameters to be redefined by inheritance
      %%%

      meth finalRep
         skip
      end

      meth dummyRep
         skip
      end
   end

in

   Time = time(time:   Boot_Time.time
               delay:  Delay
               alarm:  Alarm
               repeat: Repeat)

end
