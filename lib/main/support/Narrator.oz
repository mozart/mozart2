%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%   http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
import
   Error(registerFormatter)
export
   'class': Narrator
define
   {Error.registerFormatter narrator
    fun {$ E}
       T = 'narrator error'
    in
       case E of narrator(register P) then
          error(kind: T
                msg: 'Trying to register a non-port'
                items: [hint(l: 'Argument' m: oz(P))])
       else
          error(kind: T
                items: [line(oz(E))])
       end
    end}

   fun {NormalizeCoord Coord}
      case Coord of unit then Coord
      else pos({CondSelect Coord 1 ''} Coord.2 {CondSelect Coord 3 ~1})
      end
   end

   class PrivateNarrator
      attr
         Narrator: unit
         LogPhases: false
         MaxNumberOfErrors: 17
         ErrorCount: unit
      meth init(NarratorObject)
         Narrator <- NarratorObject
      end
      meth setLogPhases(B)
         LogPhases <- B
      end
      meth setMaxNumberOfErrors(N)
         MaxNumberOfErrors <- N
      end

      meth tell(M)
         {@Narrator tell(M)}
      end
      meth startBatch()
         ErrorCount <- 0
      end
      meth startPhase(VS)
         if @LogPhases then
            {@Narrator tell(info('%%%     '#VS#' ...\n'))}
         end
      end
      meth startSubPhase(VS)
         if @LogPhases then
            {@Narrator tell(info('%%%         '#VS#' ...\n'))}
         end
      end
      meth endBatch(Kind)
         case Kind of accepted then
            {@Narrator tell(info('% -------------------- accepted\n'))}
         [] rejected then VS in
            VS = ('%** ------------------ rejected'#
                  case @ErrorCount of 0 then ""
                  elseof N then
                     ' ('#N#' error'#if N == 1 then "" else 's' end#')'
                  end#'\n')
            {@Narrator tell([attention info(VS)])}
         [] aborted then VS in
            VS = '%** ------------------ aborted\n'
            {@Narrator tell([attention info(VS)])}
         [] crashed then VS in
            VS = '%** ------------------ crashed'
            {@Narrator tell([attention info(VS)])}
         [] interrupted then
            {@Narrator tell(info('% -------------------- interrupted'))}
         end
         ErrorCount <- unit
      end

      meth error(coord: Coord <= unit
                 kind: Kind <= unit
                 msg: Msg <= unit
                 items: Items <= nil) NewCoord in
         NewCoord = {NormalizeCoord Coord}
         {@Narrator
          tell(message(error(kind: Kind msg: Msg
                             items: case NewCoord of unit then Items
                                    else {Append Items [NewCoord]}
                                    end) NewCoord))}
         case @ErrorCount of unit then skip
         elseof N then
            ErrorCount <- N + 1
            if @MaxNumberOfErrors >= 0 andthen @ErrorCount > @MaxNumberOfErrors
            then
               raise tooManyErrors end
            end
         end
      end
      meth warn(coord: Coord <= unit
                kind: Kind <= unit
                msg: Msg <= unit
                items: Items <= nil) NewCoord in
         NewCoord = {NormalizeCoord Coord}
         {@Narrator
          tell(message(warn(kind: Kind msg: Msg
                           items: case NewCoord of unit then Items
                                  else {Append Items [NewCoord]}
                                  end) NewCoord))}
      end
      meth hasSeenError($)
         @ErrorCount > 0
      end
   end

   class Narrator
      attr Registered: nil RegistrationLock: unit BatchLock: unit
      meth init($)
         RegistrationLock <- {NewLock}
         BatchLock <- {NewLock}
         {New PrivateNarrator init(self)}
      end
      meth register(P)
         if {IsPort P} then skip
         else {Exception.raiseError narrator(register P)}
         end
         lock @RegistrationLock then
            Registered <- P|@Registered
            {self newListener(P)}
         end
      end
      meth newListener(P)
         % is invoked when a new listener P is registered.
         % May be overridden; actions might be:  Give the new Listener
         % a summary of the current state (whether idle or busy, state
         % of the queue ...)
         skip
      end
      meth unregister(P)
         lock @RegistrationLock then
            Registered <- {Filter @Registered fun {$ P0} P0 \= P end}
         end
      end

      meth tell(M)
         lock @RegistrationLock then
            case M of _|_ then
               lock @BatchLock then
                  {ForAll @Registered
                   proc {$ P} {ForAll M proc {$ M} {Send P M} end} end}
               end
            else
               {ForAll @Registered proc {$ P} {Send P M} end}
            end
         end
      end
   end
end
