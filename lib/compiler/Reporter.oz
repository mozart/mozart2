%%%
%%% Authors:
%%%   Leif Kornstaedt (kornstae@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
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
   ErrorMsg = Error.msg
   ErrorFormatPos = Error.formatPos
   ErrorFormatLine = Error.formatLine
in
   class Reporter
      prop final
      attr ErrorCount MaxNumberOfErrors HeapUsed TimeUsed ThisPhaseLevel
      feat Switches Interface
      meth init(SwitchObject InterfaceObject)
         self.Interface = InterfaceObject
         MaxNumberOfErrors <- 17
         self.Switches = SwitchObject
         Reporter, clearErrors()
         ThisPhaseLevel <- none
      end
      meth clearErrors()
         ErrorCount <- 0
      end
      meth setMaxNumberOfErrors(N)
         MaxNumberOfErrors <- N
      end
      meth getMaxNumberOfErrors($)
         @MaxNumberOfErrors
      end

      meth ProfileStart(PhaseLevel)
         case {self.Switches get(showcompiletime $)} then
            TimeUsed <- {System.get time}.user
            ThisPhaseLevel <- PhaseLevel
         else skip
         end
         case {self.Switches get(showcompilememory $)} then
            {System.gcDo}
            HeapUsed <- {GetUsedHeap}
            ThisPhaseLevel <- PhaseLevel
         else skip
         end
      end
      meth ProfileEnd()
         case {self.Switches get(compilerpasses $)}
            andthen @ThisPhaseLevel \= none
         then
            Indent = case @ThisPhaseLevel of phase then '%%%         '
                     [] subphase then '%%%             '
                     end
         in
            case {self.Switches get(showcompiletime $)} then T in
               T = {System.get time}.user
               {self.Interface
                ShowInfo(Indent#'time: '#(T - @TimeUsed)#' msec\n')}
               TimeUsed <- T
            else skip
            end
            case {self.Switches get(showcompilememory $)} then H0 H1 in
               H0 = {GetUsedHeap}
               {System.gcDo}
               H1 = {GetUsedHeap}
               {self.Interface
                ShowInfo(Indent#'heap allocation: '#(H0 - @HeapUsed)#' KB\n')}
               {self.Interface
                ShowInfo(Indent#'active size: '#H1#' KB\n')}
               HeapUsed <- H1
            else skip
            end
            ThisPhaseLevel <- none
         else skip
         end
      end

      meth logDeclare(Coord)
         case {self.Switches get(compilerpasses $)} then VS in
            case Coord of pos(F L C) then
               VS = {ErrorFormatPos F L C unit}
               {self.Interface
                ShowInfo('%%% processing query in '#VS#'\n' Coord)}
            else
               {self.Interface ShowInfo('%%% processing query')}
            end
         else skip
         end
      end
      meth logPhase(VS)
         Reporter, ProfileEnd()
         Reporter, ProfileStart(phase)
         case {self.Switches get(compilerpasses $)} then
            {self.Interface ShowInfo('%%%     '#VS#'\n')}
         else skip
         end
      end
      meth logSubPhase(VS)
         Reporter, ProfileEnd()
         Reporter, ProfileStart(subphase)
         case {self.Switches get(compilerpasses $)} then
            {self.Interface ShowInfo('%%%         '#VS#'\n')}
         else skip
         end
      end
      meth logAccept()
         Reporter, ProfileEnd()
         {self.Interface ShowInfo('% -------------------- accepted\n')}
      end
      meth logReject()
         Reporter, ProfileEnd()
         {self.Interface ShowInfo('%** ------------------ rejected '#
                                  '('#@ErrorCount#' error'#
                                  case @ErrorCount == 1 then "" else 's' end#
                                  ')\n')}
      end
      meth logAbort()
         Reporter, ProfileEnd()
         {self.Interface ShowInfo('%** ------------------ aborted\n')}
      end
      meth logCrash()
         Reporter, ProfileEnd()
         {self.Interface ShowInfo('%** ------------------ compiler crashed\n')}
      end
      meth logHalt()
         Reporter, ProfileEnd()
         {self.Interface ShowInfo('% -------------------- halting\n')}
      end
      meth logInterrupt()
         Reporter, ProfileEnd()
         {self.Interface ShowInfo('% -------------------- interrupted\n')}
      end
      meth displaySource(Title Ext VS)
         {self.Interface DisplaySource(Title Ext VS)}
      end
      meth userInfo(VS)
         {self.Interface ShowInfo(VS)}
      end

      meth error(coord: Coord <= unit
                 kind: Kind <= unit
                 msg: Msg <= unit
                 body: Body <= nil)
         case @ErrorCount == 0 then
            {self.Interface ToTop()}
         else skip
         end
         {ErrorMsg
          proc {$ X} {self.Interface ShowInfo({ErrorFormatLine X} Coord)} end
          error(kind: Kind msg: Msg
                body: case Coord == unit then Body
                      else {Append Body [Coord]}
                      end)}
         ErrorCount <- @ErrorCount + 1
         case @MaxNumberOfErrors < 0 then skip
         elsecase @ErrorCount > @MaxNumberOfErrors then
            raise tooManyErrors end
         else skip
         end
      end
      meth warn(coord: Coord <= unit
                kind: Kind <= unit
                msg: Msg <= unit
                body: Body <= nil)
         {ErrorMsg
          proc {$ X} {self.Interface ShowInfo({ErrorFormatLine X} Coord)} end
          warn(kind: Kind msg: Msg
               body: case Coord == unit then Body
                     else {Append Body [Coord]}
                     end)}
      end
      meth addErrors(N)
         case @ErrorCount == 0 then
            {self.Interface ToTop()}
         else skip
         end
         ErrorCount <- @ErrorCount + N
      end
      meth hasSeenError($)
         @ErrorCount > 0
      end
   end
end
