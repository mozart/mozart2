%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1997-1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% FDIntDrawObject
%%%

class FDIntDrawObject
   from
      DrawObject

   meth draw(X Y)
      if @dirty
      then
         VarName   = @varName
         XDim      = {VarName getXDim($)}
         DeltaX    = (X + XDim)
         Visual    = @visual
         Server    = {Visual getServer($)}
         StopValue = {Visual getStop($)}
      in
         xAnchor <- X
         yAnchor <- Y
         {VarName draw(X Y)}
         {@separator draw(DeltaX Y)}
         {@obrace draw((DeltaX + 1) Y)}
         FDIntDrawObject, performDraw(1 (DeltaX + 2) Y StopValue)
         {Server logVar(self @value normal)}
         dirty <- false
      end
   end

   meth performDraw(I X Y StopValue)
      Node = {Dictionary.get @items I}
      XDim = {Node getXDim($)}
   in
      if {IsFree StopValue}
      then
         {Node draw(X Y)}
         if I < @width
         then FDIntDrawObject,
            performDraw((I + 1) (X + (XDim + 1)) Y StopValue)
         else {@cbrace draw((X + XDim) Y)}
         end
      else
         skip
      end
   end

   meth undraw
      {@varName undraw}
      {@separator undraw}
      {@obrace undraw}
      FDIntDrawObject, performUndraw(1)
      dirty <- true
   end

   meth performUndraw(I)
      Node = {Dictionary.get @items I}
   in
      {Node undraw}
      if I < @width
      then FDIntDrawObject, performUndraw((I + 1))
      else {@cbrace undraw}
      end
   end

   meth reDraw(X Y)
      if @dirty
      then
         VarName   = @varName
         XDim      = {VarName getXDim($)}
         DeltaX    = (X + XDim)
         Visual    = @visual
         Server    = {Visual getServer($)}
         StopValue = {Visual getStop($)}
      in
         xAnchor <- X
         yAnchor <- Y
         {VarName reDraw(X Y)}
         {@separator reDraw(DeltaX Y)}
         {@obrace reDraw((DeltaX + 1) Y)}
         FDIntDrawObject, performReDraw(1 (DeltaX + 2) Y StopValue)
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
               FDIntDrawObject, moveNodeXY(DeltaX (DeltaX * @xf)
                                           DeltaY (DeltaY * @yf))
            end
         else
            FDIntDrawObject, moveNodeXY(DeltaX (DeltaX * @xf)
                                        DeltaY (DeltaY * @yf))
         end
      end
   end

   meth performReDraw(I X Y StopValue)
      Node = {Dictionary.get @items I}
      XDim = {Node getXDim($)}
   in
      if {IsFree StopValue}
      then
         {Node reDraw(X Y)}
         if I < @width
         then FDIntDrawObject,
            performReDraw((I + 1) (X + (XDim + 1)) Y StopValue)
         else {@cbrace reDraw((X + XDim) Y)}
         end
      else
         skip
      end
   end

   meth moveNodeXY(X XF Y YF)
      if @dirty
      then skip
      else
         xAnchor <- (@xAnchor + X)
         yAnchor <- (@yAnchor + Y)
         {@varName moveNodeXY(X XF Y YF)}
         {@separator moveNodeXY(X XF Y YF)}
         {@obrace moveNodeXY(X XF Y YF)}
         FDIntDrawObject, performMoveNodeXY(1 X XF Y YF)
      end
   end

   meth performMoveNodeXY(I X XF Y YF)
      Node = {Dictionary.get @items I}
   in
      {Node moveNodeXY(X XF Y YF)}
      if I < @width
      then FDIntDrawObject, performMoveNodeXY((I + 1) X XF Y YF)
      else {@cbrace moveNodeXY(X XF Y YF)}
      end
   end

   meth tell
      FDIntDrawObject, undraw
      {@parent replace(@index @value replaceNormal)}
   end
end
