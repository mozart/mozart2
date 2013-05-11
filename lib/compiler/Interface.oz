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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
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
      Interface, clear()
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
      [] pong(X) then
         {Dictionary.condGet @Waiting X unit} = unit
      else skip
      end
   end

   meth clear()
      ErrorListener.'class', clear()
      InsertedFiles <- nil
      SourceVS <- ""
   end
   meth sync() X Y in
      X = {NewName}
      {Dictionary.put @Waiting X Y}
      {ErrorListener.'class', getNarrator($) enqueue(ping(_ X))}
      {Wait Y}
      {Dictionary.remove @Waiting X}
   end
   meth getInsertedFiles($)
      {Reverse @InsertedFiles}
   end
   meth getSource($)
      @SourceVS
   end
end
