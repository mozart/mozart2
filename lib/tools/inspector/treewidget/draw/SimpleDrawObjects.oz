%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1999
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%   http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   class SimpleDrawObject from DrawObject
      meth tell($)
         Dirty = @dirty
      in
         if Dirty
         then Dirty
         else
            Parent = @parent
            Index  = @index
            RI     = {Parent getRootIndex(Index $)}
         in
            {Parent replace(Index @value replaceNormal)} RI
         end
      end
   end

   class SimpleGrDrawObject from DrawObject
      meth draw(X Y)
         if @dirty
         then
            Visual = @visual
         in
            dirty <- false
            {Visual tagTreeDown(@contTag)}
            {@visual printXY(if {@entry hasRefs($)} then {@mode drawX(X Y $)}
                             else {@mode dirtyUndraw} X end Y
                             @string @tag @type)}
            {Visual tagTreeUp}
         else {@visual place(if {@entry hasRefs($)}
                             then {@mode drawX(X Y $)} else {@mode dirtyUndraw} X end Y @tag)}
         end
      end
      meth drawX(X Y $)
         SimpleGrDrawObject, draw(X Y) (X + @xDim)
      end
      meth drawY(X Y $)
         SimpleGrDrawObject, draw(X Y) (Y + 1)
      end
      meth getFirstItem($)
         if {@entry hasRefs($)} then {@mode getFirstItem($)} else @tag end
      end
      meth undraw
         if @dirty
         then skip
         else {@mode undraw} {@visual delete(@tag)} SimpleGrDrawObject, makeDirty
         end
      end
      meth makeDirty
         dirty <- true {@entry sleep} {@mode makeDirty}
      end
      meth searchNode(XA YA X Y $)
         DrawObject, searchNode(if {@entry hasRefs($)} then (XA + {@mode getXDim($)})
                                else XA end YA X Y $)
      end
      meth tell($)
         Dirty = @dirty
      in
         if Dirty
         then Dirty
         else
            Parent = @parent
            Index  = @index
            RI     = {Parent getRootIndex(Index $)}
         in
            {@entry checkReplace}
            {Parent replace(Index @value replaceNormal)} RI
         end
      end
      meth notify
         xDim <- _
         {@parent notify}
      end
      meth getTag($)
         @contTag
      end
   end
in
   class GenericDrawObject from SimpleDrawObject end

   class FreeDrawObject from SimpleDrawObject end
   class FreeGrDrawObject from SimpleGrDrawObject end

   class FutureDrawObject from SimpleDrawObject end
   class FutureGrDrawObject from SimpleGrDrawObject end

   class FailedDrawObject from SimpleDrawObject end

   class VariableRefDrawObject from SimpleDrawObject
      meth performDraw(X Y)
         Visual = @visual
      in
         {Visual printXY(X Y @string @tag variableref)}
      end
      meth undraw
         if @dirty
         then skip
         else dirty <- true {@visual delete(@tag)} {self unlinkRef}
         end
      end
      meth makeDirty
         dirty <- true {self unlinkRef}
      end
      meth atomicReplace(Value)
         Parent = @parent
      in
         {Parent doNotify}
         {Parent replace(@index Value replaceNormal)}
         {@next atomicReplace(Value)}
      end
      meth getSelectionNode($)
         self
      end
      meth getValueSelectionNode($)
         {@value getSelectionNode($)}
      end
   end
end

class BitmapDrawObject from DrawObject
   meth draw(X Y)
      if @dirty
      then
         dirty <- false
         {@visual paintXY(X Y @value @tag @type)}
      else {@visual place(X Y @tag)}
      end
   end
   meth drawX(X Y $)
      BitmapDrawObject, draw(X Y) (X + 2)
   end
   meth drawY(X Y $)
      BitmapDrawObject, draw(X Y) (Y + 1)
   end
   meth searchNode(XA YA X Y $)
      if X >= XA andthen X < (XA + 2) andthen YA == Y then self else nil end
   end
   meth modifyWidth(Index N)
      {@parent modifyWidth(Index N)}
   end
   meth modifyDepth(Index N)
      {@parent modifyDepth(Index N)}
   end
end
