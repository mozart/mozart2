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
      if @dirty
      then
         Visual    = @visual
         Server    = {Visual getServer($)}
         StopValue = {Visual getStop($)}
      in
         xAnchor <- X
         yAnchor <- Y
         FSSetDrawObject, performDraw(1 X Y StopValue)
         {Server logVar(self @value normal)}
         dirty <- false
      end
   end

   meth performDraw(I X Y StopValue)
      Node|Add = {Dictionary.get @items I}
      XDim     = {Node getXDim($)}
   in
      if {IsFree StopValue}
      then
         {Node draw(X Y)}
         if I < @maxPtr
         then FSSetDrawObject,
            performDraw((I + 1) (X + XDim + Add) Y StopValue)
         end
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
      if I < @maxPtr
      then FSSetDrawObject, performUndraw((I + 1))
      end
   end

   meth reDraw(X Y)
      if @dirty
      then
         Visual    = @visual
         Server    = {Visual getServer($)}
         StopValue = {Visual getStop($)}
      in
         xAnchor <- X
         yAnchor <- Y
         FSSetDrawObject, performReDraw(1 X Y StopValue)
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

   meth performReDraw(I X Y StopValue)
      Node|Add = {Dictionary.get @items I}
      XDim     = {Node getXDim($)}
   in
      if {IsFree StopValue}
      then
         {Node reDraw(X Y)}
         if I < @maxPtr
         then FSSetDrawObject,
            performReDraw((I + 1) (X + XDim + Add) Y StopValue)
         end
      end
   end

   meth moveNodeXY(X XF Y YF)
      if @dirty
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
      if I < @maxPtr
      then FSSetDrawObject, performMoveNodeXY((I + 1) X XF Y YF)
      end
   end

   meth tell
      FSSetDrawObject, undraw
      {@parent replace(@index @value replaceNormal)}
   end
end
