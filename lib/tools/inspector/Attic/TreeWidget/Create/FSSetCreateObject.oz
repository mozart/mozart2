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

   meth create(Value Visual Depth)
      PName = {System.printName Value}
      Card  = {FS.reflect.card Value}
   in
      CreateObject, create(Value Visual Depth)
      @type   = fset
      @items  = {Dictionary.new}
      @maxPtr = 0

      FSSetCreateObject, add({New InternalAtomNode create(PName Visual Depth)} 0)
      FSSetCreateObject, add({New InternalAtomNode create('{' Visual Depth)} 0)
      FSSetCreateObject, add({New InternalAtomNode create('{' Visual Depth)} 0)
      FSSetCreateObject, iterateList({FS.reflect.lowerBound Value})
      FSSetCreateObject, add({New InternalAtomNode create('}' Visual Depth)} 0)
      FSSetCreateObject, add({New InternalAtomNode create('..' Visual Depth)} 0)
      FSSetCreateObject, add({New InternalAtomNode create('{' Visual Depth)} 0)
      FSSetCreateObject, iterateList({FS.reflect.upperBound Value})
      FSSetCreateObject, add({New InternalAtomNode create('}' Visual Depth)} 0)
      FSSetCreateObject, add({New InternalAtomNode create('}' Visual Depth)} 0)
      FSSetCreateObject, add({New InternalAtomNode create('#' Visual Depth)} 0)
      FSSetCreateObject, add({New InternalAtomNode create('{' Visual Depth)} 0)
      FSSetCreateObject, add({Create Card Visual Depth} 0)
      FSSetCreateObject, add({New InternalAtomNode create('}' Visual Depth)} 0)
   end

   meth iterateList(Ls)
      case Ls
      of Li|Lr then
         FSSetCreateObject, add({Create Li @visual @depth} 1)
         FSSetCreateObject, iterateList(Lr)
      else
         Items  = @items
         MaxPtr = @maxPtr
         Node|_ = {Dictionary.get Items MaxPtr}
      in
         {Dictionary.put Items MaxPtr Node|0}
      end
   end

   meth add(Node Add)
      MaxPtr = (@maxPtr + 1)
   in
      {Dictionary.put @items MaxPtr Node|Add}
      maxPtr <- MaxPtr
   end
end
