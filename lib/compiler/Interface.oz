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

class Interface from ErrorListener.'class'
   prop final
   attr InsertedFiles: nil SourceVS: "" Waiting: unit
   meth init(CompilerObject DoVerbose <= false)
      ErrorListener.'class', init(CompilerObject ServeOne DoVerbose)
      Waiting <- {NewDictionary}
   end
   meth reset()
      InsertedFiles <- nil
      SourceVS <- ""
   end
   meth ServeOne(M)
      case M of insert(VS _) then
         InsertedFiles <- VS|@InsertedFiles
      [] displaySource(_ _ VS) then
         case @SourceVS of "" then
            SourceVS <- VS
         elseof SVS then
            SourceVS <- SVS#'\n\n'#VS
         end
      [] removeQuery(Id) then
         {Dictionary.condGet @Waiting Id unit} = unit
      else skip
      end
   end

   meth wait(Id) X N in
      {Dictionary.put @Waiting Id X}
      ErrorListener.'class', getNarrator(?N)
      if {IsFree {N getQueryState(Id $)}} then
         {Wait X}
      end
      {Dictionary.remove @Waiting Id}
   end
   meth getInsertedFiles($)
      {Reverse @InsertedFiles}
   end
   meth getSource($)
      @SourceVS
   end
end
