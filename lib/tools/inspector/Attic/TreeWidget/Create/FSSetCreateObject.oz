%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% FSSetCreateObject
%%%

class FSSetCreateObject
   from
      CreateObject

   attr
      items  %% Items Dictionary
      maxPtr %% MaxPtr

   meth create(Value Parent Index Visual Depth)
      PName     = {System.printName Value}
      Card      = {FS.reflect.card Value}
      StopValue = {Visual getStop($)}
   in
      CreateObject, create(Value Parent Index Visual Depth)
      @type   = fset
      @items  = {Dictionary.new}
      @maxPtr = 0

      FSSetCreateObject, internalAdd(PName 0)
      FSSetCreateObject, internalAdd('{' 0)
      FSSetCreateObject, internalAdd('{' 0)
      FSSetCreateObject, iterateList({FS.reflect.lowerBound Value} StopValue)
      FSSetCreateObject, internalAdd('}' 0)
      FSSetCreateObject, internalAdd('..' 0)
      FSSetCreateObject, internalAdd('{' 0)
      FSSetCreateObject, iterateList({FS.reflect.upperBound Value} StopValue)
      FSSetCreateObject, internalAdd('}' 0)
      FSSetCreateObject, internalAdd('}' 0)
      FSSetCreateObject, internalAdd('#' 0)
      FSSetCreateObject, internalAdd('{' 0)
      FSSetCreateObject, add(Card 0)
      FSSetCreateObject, internalAdd('}' 0)
   end

   meth iterateList(Ls StopValue)
      if {IsFree StopValue}
      then
         case Ls
         of Li|Lr then
            FSSetCreateObject, add(Li 1)
            FSSetCreateObject, iterateList(Lr StopValue)
         else
            Items  = @items
            MaxPtr = @maxPtr
            Node|_ = {Dictionary.get Items MaxPtr}
         in
            {Dictionary.put Items MaxPtr Node|0}
         end
      end
   end

   meth add(Value Add)
      MaxPtr = (@maxPtr + 1)
      Node   = {Create Value self MaxPtr @visual @depth}
   in
      {Dictionary.put @items MaxPtr Node|Add}
      maxPtr <- MaxPtr
   end

   meth internalAdd(Value Add)
      MaxPtr = (@maxPtr + 1)
      Node   = {New InternalAtomNode
                create(Value self MaxPtr @visual @depth)}
   in
      {Dictionary.put @items MaxPtr Node|Add}
      maxPtr <- MaxPtr
   end
end
