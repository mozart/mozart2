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
%%% FreeLayoutObject
%%%

class FreeLayoutObject
   from
      LayoutObject

   meth layout
      if @dazzle then
         string <- {System.printName @value}
         xDim   <- {VirtualString.length @string}
         yDim   <- 1
         color  <- {OpMan get(freeVarColor $)}
         dazzle <- false
         dirty  <- true
      end
   end
end
