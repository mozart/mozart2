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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
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
   fun {GetUsedHeap}
      {Property.get 'heap.used'}
   end

   fun {NormalizeCoord Coord}
      case Coord of pos(_ _ _) then Coord
      [] pos(F L C _ _ _) then pos(F L C)
      [] fineStep(F L C) then pos(F L C)
      [] fineStep(F L C _ _ _) then pos(F L C)
      [] coarseStep(F L C) then pos(F L C)
      [] coarseStep(F L C _ _ _) then pos(F L C)
      [] unit then unit
      end
   end
in
   class Reporter
      prop final
      attr ErrorCount HeapUsed TimeUsed ThisPhaseLevel Raised
      feat Compiler Wrapper
      meth init(CompilerObject WrapperObject)
         self.Compiler = CompilerObject
         self.Wrapper = WrapperObject
         Reporter, clearErrors()
         ThisPhaseLevel <- none
      end
      meth clearErrors()
         ErrorCount <- 0
         Raised <- false
      end
      meth ToTop(IsError)
         if @Raised then skip
         else
            if IsError then {self.Wrapper notify(errorFound())} end
            {self.Wrapper notify(toTop())}
            Raised <- true
         end
      end

      meth ProfileStart(PhaseLevel)
         if {self.Compiler getSwitch(showcompiletime $)} then
            TimeUsed <- {Property.get time}.user
            ThisPhaseLevel <- PhaseLevel
         end
         if {self.Compiler getSwitch(showcompilememory $)} then
            {System.gcDo}
            HeapUsed <- {GetUsedHeap}
            ThisPhaseLevel <- PhaseLevel
         end
      end
      meth ProfileEnd()
         if {self.Compiler getSwitch(compilerpasses $)}
            andthen @ThisPhaseLevel \= none
         then
            Indent = case @ThisPhaseLevel of phase then '%%%         '
                     [] subphase then '%%%             '
                     end
         in
            if {self.Compiler getSwitch(showcompiletime $)} then T in
               T = {Property.get time}.user
               Reporter, userInfo(Indent#'time: '#(T - @TimeUsed)#' msec\n')
               TimeUsed <- T
            end
            if {self.Compiler getSwitch(showcompilememory $)} then H0 H1 in
               H0 = {GetUsedHeap}
               {System.gcDo}
               H1 = {GetUsedHeap}
               Reporter, userInfo(Indent#'heap allocation: '#
                                  (H0 - @HeapUsed)#' KB\n')
               Reporter, userInfo(Indent#'active size: '#H1#' KB\n')
               HeapUsed <- H1
            end
            ThisPhaseLevel <- none
         end
      end

      meth logDeclare(Coord)
         if {self.Compiler getSwitch(compilerpasses $)} then NewCoord VS in
            NewCoord = {NormalizeCoord Coord}
            case NewCoord of pos(F L C) then
               VS = {Error.formatPos F L C unit}
               Reporter, userInfo('%%% processing query in '#VS#'\n' NewCoord)
            else
               Reporter, userInfo('%%% processing query')
            end
         end
      end
      meth logInsert(FileName Coord <= unit)
         {self.Wrapper notify(insert(FileName Coord))}
         if {self.Compiler getSwitch(showinsert $)} then
            Reporter, userInfo('%%%         inserted file "'#FileName#'"\n')
         end
      end
      meth logPhase(VS)
         Reporter, ProfileEnd()
         Reporter, ProfileStart(phase)
         if {self.Compiler getSwitch(compilerpasses $)} then
            Reporter, userInfo('%%%     '#VS#'\n')
         end
      end
      meth logSubPhase(VS)
         Reporter, ProfileEnd()
         Reporter, ProfileStart(subphase)
         if {self.Compiler getSwitch(compilerpasses $)} then
            Reporter, userInfo('%%%         '#VS#'\n')
         end
      end
      meth logAccept()
         Reporter, ProfileEnd()
         Reporter, userInfo('% -------------------- accepted\n')
      end
      meth logReject()
         Reporter, ProfileEnd()
         Reporter, userInfo('%** ------------------ rejected'#
                            if @ErrorCount > 0 then
                               ' ('#@ErrorCount#' error'#
                               if @ErrorCount == 1 then "" else 's' end#')'
                            else ""
                            end#'\n')
      end
      meth logAbort()
         Reporter, ProfileEnd()
         Reporter, userInfo('%** ------------------ aborted\n')
         {self.Wrapper notify(errorFound())}
      end
      meth logCrash()
         Reporter, ProfileEnd()
         Reporter, userInfo('%** ------------------ compiler crashed\n')
         Reporter, ToTop(true)
      end
      meth logHalt()
         Reporter, ProfileEnd()
         Reporter, userInfo('% -------------------- halting\n')
      end
      meth logInterrupt()
         Reporter, ProfileEnd()
         Reporter, userInfo('% -------------------- interrupted\n')
      end
      meth displaySource(Title Ext VS)
         {self.Wrapper notify(displaySource(Title Ext VS))}
      end
      meth userInfo(VS Coord <= unit)
         case Coord of unit then
            {self.Wrapper notify(info(VS))}
         else
            {self.Wrapper notify(info(VS Coord))}
         end
      end

      meth error(coord: Coord <= unit
                 kind: Kind <= unit
                 msg: Msg <= unit
                 items: Items <= nil
                 abort: Abort <= true) NewCoord MaxNumberOfErrors in
         NewCoord = {NormalizeCoord Coord}
         Reporter, ToTop(true)
         {self.Wrapper
          notify(message(error(kind: Kind msg: Msg
                               items: case NewCoord of unit then Items
                                      else {Append Items [NewCoord]}
                                      end) NewCoord))}
         ErrorCount <- @ErrorCount + 1
         {self.Compiler getMaxNumberOfErrors(?MaxNumberOfErrors)}
         if MaxNumberOfErrors >= 0 andthen @ErrorCount > MaxNumberOfErrors
            andthen Abort
         then
            raise tooManyErrors end
         end
      end
      meth warn(coord: Coord <= unit
                kind: Kind <= unit
                msg: Msg <= unit
                items: Items <= nil) NewCoord in
         NewCoord = {NormalizeCoord Coord}
         Reporter, ToTop(false)
         {self.Wrapper
          notify(message(warn(kind: Kind msg: Msg
                              items: case NewCoord of unit then Items
                                     else {Append Items [NewCoord]}
                                     end) NewCoord))}
      end
      meth addErrors(N)
         Reporter, ToTop(true)
         ErrorCount <- @ErrorCount + N
      end
      meth hasSeenError($)
         @ErrorCount > 0
      end
   end
end
