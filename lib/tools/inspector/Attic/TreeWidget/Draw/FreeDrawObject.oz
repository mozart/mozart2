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
%%% FreeDrawObject
%%%

class FreeDrawObject
   from
      DrawObject

   meth draw(X Y)
      if @dirty
      then
         Visual = @visual
      in
         xAnchor <- X
         yAnchor <- Y
         dirty   <- false
         if @haveTag
         then {@tag tkClose}
         else haveTag <- true
         end
         tag <- {New Tk.canvasTag
                 tkInit(parent: @canvas)}
         {Visual printXY(X Y @string @tag @color)}
         {Visual logVar(self @value normal)}
      end
   end

   meth reDraw(X Y)
      if @dirty
      then
         Visual = @visual
      in
         xAnchor <- X
         yAnchor <- Y
         dirty   <- false
         if @haveTag
         then {@tag tkClose}
         else haveTag <- true
         end
         tag <- {New Tk.canvasTag
                 tkInit(parent: @canvas)}
         {Visual printXY(X Y @string @tag @color)}
         {Visual logVar(self @value normal)}
      else
         DeltaX = (X - @xAnchor)
         DeltaY = (Y - @yAnchor)
      in
         case DeltaX
         of 0 then
            case DeltaY
            of 0 then skip
            else
               DrawObject, moveNodeXY(DeltaX (DeltaX * @xf)
                                      DeltaY (DeltaY * @yf))
            end
         else
            DrawObject, moveNodeXY(DeltaX (DeltaX * @xf)
                                   DeltaY (DeltaY * @yf))
         end
      end
   end

   meth tell
      DrawObject, undraw
      {@parent replace(@index @value replaceNormal)}
   end
end
