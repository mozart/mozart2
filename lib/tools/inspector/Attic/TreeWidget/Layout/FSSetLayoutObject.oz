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
%%% FSSetLayoutObject
%%%

class FSSetLayoutObject
   from
      LayoutObject

   meth layout
      case @dazzle
      then
         StopValue = {@visual getStop($)}
      in
         FSSetLayoutObject, performLayout(1 0 StopValue)
      else skip
      end
   end

   meth performLayout(I XDim StopValue)
      Node|Add = {Dictionary.get @items I}
      IXDim
   in
      case {IsFree StopValue}
      then
         {Node layout}
         IXDim = {Node getXDim($)}
         case I < @maxPtr
         then
            FSSetLayoutObject, performLayout((I + 1) (XDim + IXDim + Add))
         else
            xDim   <- (XDim + IXDim + Add)
            yDim   <- 1
            dazzle <- false
         end
      else
         xDim   <- 0
         yDim   <- 0
         dazzle <- false
      end
   end
end
