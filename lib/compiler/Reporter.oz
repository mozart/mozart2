%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%
%%  Notes about the switches 'showcompiletime' and 'showcompilememory':
%%     Unless you deactive the garbage collector and the compiler is
%%     the only Oz thread running, the data produced by these switches
%%     is very unreliable.  Furthermore, data is only collected if the
%%     switch 'compilerpasses' is set at the same time.
%%

local
   GetUsedHeap = {`Builtin` heapUsed 1}
in
   class Reporter
      prop final
      attr ErrorCount HeapUsed TimeUsed ThisPhaseLevel
      feat Compiler Wrapper
      meth init(CompilerObject WrapperObject)
         self.Compiler = CompilerObject
         self.Wrapper = WrapperObject
         ErrorCount <- 0
         ThisPhaseLevel <- none
      end
      meth clearErrors()
         ErrorCount <- 0
      end

      meth ProfileStart(PhaseLevel)
         case {self.Compiler getSwitch(showcompiletime $)} then
            TimeUsed <- {System.get time}.user
            ThisPhaseLevel <- PhaseLevel
         else skip
         end
         case {self.Compiler getSwitch(showcompilememory $)} then
            {System.gcDo}
            HeapUsed <- {GetUsedHeap}
            ThisPhaseLevel <- PhaseLevel
         else skip
         end
      end
      meth ProfileEnd()
         case {self.Compiler getSwitch(compilerpasses $)}
            andthen @ThisPhaseLevel \= none
         then
            Indent = case @ThisPhaseLevel of phase then '%%%         '
                     [] subphase then '%%%             '
                     end
         in
            case {self.Compiler getSwitch(showcompiletime $)} then T in
               T = {System.get time}.user
               {self.Wrapper
                notify(info(Indent#'time: '#(T - @TimeUsed)#' msec\n'))}
               TimeUsed <- T
            else skip
            end
            case {self.Compiler getSwitch(showcompilememory $)} then H0 H1 in
               H0 = {GetUsedHeap}
               {System.gcDo}
               H1 = {GetUsedHeap}
               {self.Wrapper notify(info(Indent#'heap allocation: '#
                                         (H0 - @HeapUsed)#' KB\n'))}
               {self.Wrapper notify(info(Indent#'active size: '#H1#' KB\n'))}
               HeapUsed <- H1
            else skip
            end
            ThisPhaseLevel <- none
         else skip
         end
      end

      meth logDeclare(Coord)
         case {self.Compiler getSwitch(compilerpasses $)} then VS in
            case Coord of pos(F L C) then
               VS = {Error.formatPos F L C unit}
               {self.Wrapper notify(info('%%% processing query in '#VS#'\n'
                                         Coord))}
            else
               {self.Wrapper notify(info('%%% processing query'))}
            end
         else skip
         end
      end
      meth logPhase(VS)
         Reporter, ProfileEnd()
         Reporter, ProfileStart(phase)
         case {self.Compiler getSwitch(compilerpasses $)} then
            {self.Wrapper notify(info('%%%     '#VS#'\n'))}
         else skip
         end
      end
      meth logSubPhase(VS)
         Reporter, ProfileEnd()
         Reporter, ProfileStart(subphase)
         case {self.Compiler getSwitch(compilerpasses $)} then
            {self.Wrapper notify(info('%%%         '#VS#'\n'))}
         else skip
         end
      end
      meth logAccept()
         Reporter, ProfileEnd()
         {self.Wrapper notify(info('% -------------------- accepted\n'))}
      end
      meth logReject()
         Reporter, ProfileEnd()
         {self.Wrapper notify(info('%** ------------------ rejected '#
                                   '('#@ErrorCount#' error'#
                                   case @ErrorCount == 1 then "" else 's' end#
                                   ')\n'))}
      end
      meth logAbort()
         Reporter, ProfileEnd()
         {self.Wrapper notify(info('%** ------------------ aborted\n'))}
         {self.Wrapper notify(unsuccessful())}
      end
      meth logCrash()
         Reporter, ProfileEnd()
         {self.Wrapper
          notify(info('%** ------------------ compiler crashed\n'))}
      end
      meth logHalt()
         Reporter, ProfileEnd()
         {self.Wrapper notify(info('% -------------------- halting\n'))}
      end
      meth logInterrupt()
         Reporter, ProfileEnd()
         {self.Wrapper notify(info('% -------------------- interrupted\n'))}
      end
      meth displaySource(Title Ext VS)
         {self.Wrapper notify(displaySource(Title Ext VS))}
      end
      meth userInfo(VS)
         {self.Wrapper notify(info(VS))}
      end

      meth error(coord: Coord <= unit
                 kind: Kind <= unit
                 msg: Msg <= unit
                 body: Body <= nil) MaxNumberOfErrors in
         case @ErrorCount == 0 then
            {self.Wrapper notify(toTop())}
            {self.Wrapper notify(unsuccessful())}
         else skip
         end
         {Error.msg
          proc {$ X}
             {self.Wrapper notify(info({Error.formatLine X} Coord))}
          end
          error(kind: Kind msg: Msg
                body: case Coord == unit then Body
                      else {Append Body [Coord]}
                      end)}
         ErrorCount <- @ErrorCount + 1
         {self.Compiler getMaxNumberOfErrors(?MaxNumberOfErrors)}
         case MaxNumberOfErrors < 0 then skip
         elsecase @ErrorCount > MaxNumberOfErrors then
            raise tooManyErrors end
         else skip
         end
      end
      meth warn(coord: Coord <= unit
                kind: Kind <= unit
                msg: Msg <= unit
                body: Body <= nil)
         {Error.msg
          proc {$ X}
             {self.Wrapper notify(info({Error.formatLine X} Coord))}
          end
          warn(kind: Kind msg: Msg
               body: case Coord == unit then Body
                     else {Append Body [Coord]}
                     end)}
      end
      meth addErrors(N)
         case @ErrorCount == 0 then
            {self.Wrapper notify(toTop())}
            {self.Wrapper notify(unsuccessful())}
         else skip
         end
         ErrorCount <- @ErrorCount + N
      end
      meth hasSeenError($)
         @ErrorCount > 0
      end
   end
end
