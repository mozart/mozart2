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
%%% FSSetDrawObject
%%%

class FSSetDrawObject
   from
      DrawObject

   meth draw(X Y)
      case @dirty
      then
         Server = {@visual getServer($)}
      in
         xAnchor <- X
         yAnchor <- Y
         FSSetDrawObject, performDraw(1 X Y)
         {Server logVar(self @value normal)}
         dirty <- false
      else skip
      end
   end

   meth performDraw(I X Y)
      Node|Add = {Dictionary.get @items I}
      XDim     = {Node getXDim($)}
   in
      {Node draw(X Y)}
      case I < @maxPtr
      then FSSetDrawObject, performDraw((I + 1) (X + XDim + Add) Y)
      else skip
      end
   end

   meth undraw
      FSSetDrawObject, performUndraw(1)
      dirty <- true
   end

   meth performUndraw(I)
      Node|_ = {Dictionary.get @items I}
   in
      {Node undraw}
      case I < @maxPtr
      then FSSetDrawObject, performUndraw((I + 1))
      else skip
      end
   end

   meth reDraw(X Y)
      case @dirty
      then
         Server = {@visual getServer($)}
      in
         xAnchor <- X
         yAnchor <- Y
         FSSetDrawObject, performReDraw(1 X Y)
         dirty <- false
         {Server logVar(self @value normal)}
      else
         DeltaX = (X - @xAnchor)
         DeltaY = (Y - @yAnchor)
      in
         case DeltaX
         of 0 then
            case DeltaY
            of 0 then skip
            else
               FSSetDrawObject, moveNodeXY(DeltaX (DeltaX * @xf)
                                           DeltaY (DeltaY * @yf))
            end
         else
            FSSetDrawObject, moveNodeXY(DeltaX (DeltaX * @xf)
                                        DeltaY (DeltaY * @yf))
         end
      end
   end

   meth performReDraw(I X Y)
      Node|Add = {Dictionary.get @items I}
      XDim     = {Node getXDim($)}
   in
      {Node reDraw(X Y)}
      case I < @maxPtr
      then FSSetDrawObject, performReDraw((I + 1) (X + XDim + Add) Y)
      else skip
      end
   end

   meth moveNodeXY(X XF Y YF)
      case @dirty
      then skip
      else
         xAnchor <- (@xAnchor + X)
         yAnchor <- (@yAnchor + Y)
         FSSetDrawObject, performMoveNodeXY(1 X XF Y YF)
      end
   end

   meth performMoveNodeXY(I X XF Y YF)
      Node|_ = {Dictionary.get @items I}
   in
      {Node moveNodeXY(X XF Y YF)}
      case I < @maxPtr
      then FSSetDrawObject, performMoveNodeXY((I + 1) X XF Y YF)
      else skip
      end
   end

   meth tell
      FSSetDrawObject, undraw
      {@parent replace(@index @value replaceNormal)}
   end
end
