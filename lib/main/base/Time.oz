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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

declare

   Time
   Alarm
   Delay

in

Alarm = {`Builtin` 'Time.alarm' 2}
Delay = {`Builtin` 'Time.delay' 1}

local

   fun {AddWaiter W T P}
      case W
      of (T1#P1)|R then
         case T1>T then (T#P)|(T1-T#P1)|R
         else (T1#P1)|{AddWaiter R T P}
         end
      else [T#P]
      end
   end

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

      from BaseObject

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

         case DF == DefaultFun
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
         case
            lock
               case {IsDet @Stop}
               then Stop <- _ true
               else false end
            end
         then Repeat, Run
         else skip end
      end

      meth stop
         lock
            @Stop = unit
            NumberA <- @NumReset
         end
      end

      meth Run
         K D A N F
      in
         lock
            K = @Stop
            D = @ActDelay
            A = @Action
            F = @Final
            N = @NumberA
         end

         case {IsDet K}
         then skip
         elsecase N==0
         then
            {self stop}
            {self Do(F)}
         else
            S = {Alarm D}
         in
            {self Do(A)}

            case N>0
            then NumberA <- N-1
            else skip end

            {WaitOr S K}
            case {IsDet S}
            then Repeat, Run
            else skip end
         end
      end

      meth Do(A)
         case {IsProcedure A}
         then {A} else {self A} end
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

   Time = time(time:   {`Builtin` 'Time.time' 1}
               delay:  Delay
               alarm:  Alarm
               repeat: Repeat)

end
