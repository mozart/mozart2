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
%%% FDIntLayoutObject
%%%

class FDIntLayoutObject
   from
      LayoutObject

   meth layout
      case @dazzle
      then
         VarName = @varName
         XDim
      in
         {VarName layout}
         {@separator layout}
         {@obrace layout}
         {@cbrace layout}
         XDim = ({VarName getXDim($)} + 3)
         FDIntLayoutObject, performLayout(1 XDim)
      else skip
      end
   end

   meth performLayout(I XDim)
      Node = {Dictionary.get @items I}
      IXDim
   in
      {Node layout}
      IXDim = {Node getXDim($)}
      case I < @width
      then
         FDIntLayoutObject, performLayout((I + 1) (XDim + (IXDim + 1)))
      else
         xDim   <- (XDim + IXDim)
         yDim   <- 1
         dazzle <- false
      end
   end
end
