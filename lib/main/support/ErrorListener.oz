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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
import
   Error(msg formatLine)
   System(printError)
   Listener('class')
export
   'class': ErrorListener
define
   fun {MessageToVS Item}
      case Item of info(VS) then VS
      [] info(VS _) then VS
      [] message(Record _) then VSCell in
         VSCell = {NewCell ""}
         {Error.msg
          proc {$ X}
             {Assign VSCell {Access VSCell}#{Error.formatLine X}}
          end
          Record}
         {Access VSCell}
      end
   end

   fun {HistoryToVS History}
      {FoldL History
       fun {$ In M}
          {MessageToVS M}#In
       end ""}
   end

   class ErrorListener from Listener.'class'
      attr
         Fallback: unit
         Verbose: false History: nil
         HasErrors: false IsActive: false
      meth init(NarratorObject ServeOne <= unit DoVerbose <= false)
         Fallback <- ServeOne
         Verbose <- DoVerbose
         Listener.'class', init(NarratorObject Serve)
      end
      meth reset()
         skip
      end
      meth Serve(Ms)
         case Ms of M|Mr then OutputMessage in
            case M of info(_) then
               OutputMessage = M
            [] info(_ _) then
               OutputMessage = M
            [] attention() then
               IsActive <- true
               OutputMessage = unit
            [] message(M1 _) then
               IsActive <- true
               if {Label M1} == error then
                  HasErrors <- true
               end
               OutputMessage = M
            [] close() then
               History <- nil
               HasErrors <- false
               IsActive <- false
               {self reset()}
               OutputMessage = unit
            else
               case @Fallback of unit then skip
               elseof L then {self L(M)}
               end
               OutputMessage = unit
            end
            case OutputMessage of unit then skip
            elsecase @Verbose of true then
               {System.printError {MessageToVS OutputMessage}}
            [] auto then
               History <- OutputMessage|@History
               if @IsActive then
                  {System.printError {HistoryToVS @History}}
                  History <- nil
                  Verbose <- true
               end
            else
               History <- OutputMessage|@History
            end
            ErrorListener, Serve(Mr)
         end
      end

      meth setVerbosity(B)
         Verbose <- B
      end
      meth hasErrors($)
         @HasErrors
      end
      meth isActive($)
         @IsActive
      end
      meth getVS($)
         {HistoryToVS @History}
      end
      meth getMessages($)
         {FoldL @History
          fun {$ In M}
             case M of message(Record _) then Record|In
             else In
             end
          end nil}
      end
      meth formatMessages(History $)
         {HistoryToVS {Reverse History}}
      end
   end
end
