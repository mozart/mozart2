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

local
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
in
   class QuietInterface from GenericInterface
      prop final
      attr
         Verbose: false History: nil SourceVS: ""
         HasErrors: false HasBeenTopped: false
      meth init(CompilerObject DoVerbose <= false)
         Verbose <- DoVerbose
         GenericInterface, init(CompilerObject Serve)
      end
      meth reset()
         lock
            History <- nil
            SourceVS <- ""
            HasErrors <- false
            HasBeenTopped <- false
         end
      end
      meth Serve(Ms)
         case Ms of M|Mr then OutputMessage in
            case M of info(_) then
               OutputMessage = M
            [] info(_ _) then
               OutputMessage = M
            [] message(_ _) then
               OutputMessage = M
            [] displaySource(_ _ VS) then
               case @SourceVS of "" then
                  SourceVS <- VS
               elseof SVS then
                  SourceVS <- SVS#'\n\n'#VS
               end
               OutputMessage = unit
            [] errorFound() then
               HasErrors <- true
               OutputMessage = unit
            [] toTop() then
               HasBeenTopped <- true
               OutputMessage = unit
            else
               OutputMessage = unit
            end
            case OutputMessage of unit then skip
            elsecase @Verbose of true then
               {System.printError {MessageToVS OutputMessage}}
            [] auto then
               History <- OutputMessage|@History
               case @HasBeenTopped then
                  {System.printError {HistoryToVS @History}}
                  History <- nil
                  Verbose <- true
               else skip
               end
            else
               History <- OutputMessage|@History
            end
            QuietInterface, Serve(Mr)
         end
      end

      meth setVerbosity(B)
         Verbose <- B
      end
      meth hasErrors($)
         @HasErrors
      end
      meth hasBeenTopped($)
         @HasBeenTopped
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
      meth getSource($)
         @SourceVS
      end
   end
end
