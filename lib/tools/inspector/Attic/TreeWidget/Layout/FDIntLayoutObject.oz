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
      if @dazzle then
         StopValue = {@visual getStop($)}
         VarName   = @varName
         XDim
      in
         {VarName layout}
         {@separator layout}
         {@obrace layout}
         {@cbrace layout}
         XDim = ({VarName getXDim($)} + 3)
         FDIntLayoutObject, performLayout(1 XDim StopValue)
      end
   end

   meth performLayout(I XDim StopValue)
      Node = {Dictionary.get @items I}
      IXDim
   in
      if {IsFree StopValue}
      then
         {Node layout}
         IXDim = {Node getXDim($)}
         if I < @width
         then
            FDIntLayoutObject, performLayout((I + 1) (XDim + (IXDim + 1)))
         else
            xDim   <- (XDim + IXDim)
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
