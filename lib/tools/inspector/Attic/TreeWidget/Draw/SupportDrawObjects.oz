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
%%% SupportDrawObjects
%%%

%% EmbraceDrawObject

class EmbraceDrawObject
   from
      DrawObject

   meth draw(X Y)
      Node  = @node
      LXDim = {Node getLastXDim($)}
      YDim  = ({Node getYDim($)} - 1)
      NX    = (X + 1)
   in
      {@obrace draw(X Y)}
      {@node draw(NX Y)}
      {@cbrace draw((NX + LXDim) (Y + YDim))}
   end

   meth undraw
      {@obrace undraw}
      {@node undraw}
      {@cbrace undraw}
   end

   meth moveNodeXY(X XF Y YF)
      {@obrace moveNodeXY(X XF Y YF)}
      {@node moveNodeXY(X XF Y YF)}
      {@cbrace moveNodeXY(X XF Y YF)}
   end

   meth reDraw(X Y)
      Node  = @node
      LXDim = {Node getLastXDim($)}
      YDim  = ({Node getYDim($)} - 1)
      NX    = (X + 1)
   in
      {@obrace reDraw(X Y)}
      {@node reDraw(NX Y)}
      {@cbrace reDraw((NX + LXDim) (Y + YDim))}
   end

   meth searchNode(Coord $)
      coord(X Y) = Coord
   in
      {@node searchNode(coord((X - 1) Y) $)}
   end

   meth initMenu(Type)
      {@node initMenu(Type)}
   end

   meth updateMenu(Type Status)
      {@node updateMenu(Type Status)}
   end

   meth getMenu($)
      {@node getMenu($)}
   end

   meth setMenuStatus(Status)
      {@node setMenuStatus(Status)}
   end

   meth getMenuStatus($)
      {@node getMenuStatus($)}
   end

   meth expandWidth(N)
      {@node expandWidth(N)}
   end

   meth expandDepth(N)
      {@node expandDepth(N)}
   end
end

%% NullDrawObject

class NullDrawObject
   from
      DrawObject

   meth draw(X Y)
      skip
   end

   meth undraw
      skip
   end

   meth notify(I)
      {@node notify(I)}
   end

   meth update(I)
      {@node update(I)}
   end

   meth moveNodeXY(X XF Y YF)
      skip
   end

   meth reDraw(X Y)
      skip
   end
end

%% ProxyDrawObject

class ProxyDrawObject
   from
      BaseObject

   meth draw(X Y)
      {@currentNode draw(X Y)}
      if @expanded
      then {@currentNode setMenuStatus(expanded)}
      else {@currentNode setMenuStatus(normal)}
      end
   end

   meth undraw
      {@currentNode undraw}
   end

   meth notify(I)
      {@currentNode notify(I)}
   end

   meth update(I)
      {@currentNode update(I)}
   end

   meth moveNodeXY(X XF Y YF)
      {@currentNode moveNodeXY(X XF Y YF)}
   end

   meth reDraw(X Y)
      {@currentNode reDraw(X Y)}
      if @expanded
      then {@currentNode setMenuStatus(expanded)}
      else {@currentNode setMenuStatus(normal)}
      end
   end

   meth searchNode(Coord $)
      {@currentNode searchNode(Coord $)}
   end

   meth initMenu(Type)
      {@currentNode initMenu(Type)}
   end

   meth updateMenu(Type Status)
      {@currentNode updateMenu(Type Status)}
   end

   meth getMenu($)
      {@currentNode getMenu($)}
   end

   meth setMenuStatus(Status)
      {@currentNode setMenuStatus(Status)}
   end

   meth getMenuStatus($)
      {@currentNode getMenuStatus($)}
   end

   meth expandWidth(N)
      {@currentNode expandWidth(N)}
   end

   meth expandDepth(N)
      {@currentNode expandDepth(N)}
   end
end

%% InternalAtomDrawObject

class InternalAtomDrawObject
   from
      DrawObject

   meth expand(F)
      NewValue = {F @expValue}
   in
      {@parent link(@index NewValue)}
   end
end

%% BitmapDrawObject

class BitmapDrawObject
   from
      DrawObject

   meth draw(X Y)
      if @dirty
      then
         DrawObject, initMenu(@bitmapMode)
         xAnchor <- X
         yAnchor <- Y
         dirty   <- false
         if @haveTag
         then {@tag tkClose}
         else haveTag <- true
         end
         tag <- {New Tk.canvasTag
                 tkInit(parent: @canvas)}
         {@visual paintXY(X Y @value @tag @color)}
      end
   end

   meth reDraw(X Y)
      if @dirty
      then
         DrawObject, initMenu(@bitmapMode)
         xAnchor <- X
         yAnchor <- Y
         dirty   <- false
         if @haveTag
         then {@tag tkClose}
         else haveTag <- true
         end
         tag <- {New Tk.canvasTag
                 tkInit(parent: @canvas)}
         {@visual paintXY(X Y @value @tag @color)}
      else
         DeltaX = (X - @xAnchor)
         DeltaY = (Y - @yAnchor)
      in
         DrawObject, moveNodeXY(DeltaX
                                (DeltaX * @xf)
                                DeltaY
                                (DeltaY * @yf))
      end
   end

   meth expandWidth(N)
      {@parent handleWidthExpansion(N @index)}
   end

   meth expandDepth(N)
      {@parent handleDepthExpansion(N @buffer @index)}
   end
end

%% GenericDrawObject

class GenericDrawObject
   from
      ProxyDrawObject
end
