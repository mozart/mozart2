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
%%% BaseLayoutObject
%%%

class LayoutObject
   from
      BaseObject

   attr
      xDim          %% X Dimension in Characters
      yDim          %% Y Dimension in Characters
      string        %% Graphical Representation
      color         %% Drawing Color
      dazzle : true %% Layout Flag

   meth layout
      if @dazzle
      then
         xDim   <- 0
         yDim   <- 0
         dazzle <- false
         dirty  <- true
      end
   end

   meth getXDim($)
      @xDim
   end

   meth getYDim($)
      @yDim
   end

   meth getXYDim($)
      @xDim|@yDim
   end

   meth setXDim(XDim)
      xDim <- XDim
   end

   meth setYDim(YDim)
      yDim <- YDim
   end

   meth getLastXDim($)
      @xDim
   end

   meth setLastXDim(XDim)
      skip
   end

   meth pure($)
      true
   end

   meth stopCreation
      dazzle <- false
      xDim   <- 0
      yDim   <- 0
   end
end
