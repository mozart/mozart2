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
%%% SupportLayoutObjects
%%%

%% EmbraceLayoutObject

class EmbraceLayoutObject
   from
      LayoutObject

   attr
      lastXDim %% X Dimension (last Entry)

   meth layout
      Node = @node
      XDim YDim LXDim TXDim NXDim
   in
      {@obrace layout}
      {Node layout}
      {@cbrace layout}
      XDim|YDim = {Node getXYDim($)}
      LXDim     = {Node getLastXDim($)}
      TXDim     = (LXDim + 1)
      NXDim     = {Max TXDim XDim}
      xDim     <- (1 + NXDim)
      yDim     <- YDim
      lastXDim <- (2 + LXDim)
   end

   meth getLastXDim($)
      @lastXDim
   end

   meth setLastXDim(XDim)
      lastXDim <- XDim
   end

   meth pure($)
      false
   end

   meth incCycleCount
      {@node incCycleCount}
   end

   meth setTellNode(Node)
      {@node setTellNode(Node)}
   end

   meth setLayoutType(Type)
      {@node setLayoutType(Type)}
   end
end

%% NullLayoutObject

class NullLayoutObject
   from
      LayoutObject

   meth layout
      if @dazzle
      then
         xDim   <- 0
         yDim   <- 1
         dazzle <- false
      end
   end
end

%% ProxyLayoutObject

class ProxyLayoutObject
   from
      BaseObject

   meth layout
      {@currentNode layout}
   end

   meth getXDim($)
      {@currentNode getXDim($)}
   end

   meth getYDim($)
      {@currentNode getYDim($)}
   end

   meth getXYDim($)
      {@currentNode getXYDim($)}
   end

   meth setXDim(XDim)
      {@currentNode setXDim(XDim)}
   end

   meth setYDim(YDim)
      {@currentNode setYDim(YDim)}
   end

   meth getLastXDim($)
      {@currentNode getLastXDim($)}
   end

   meth setLastXDim(XDim)
      {@currentNode setLastXDim(XDim)}
   end

   meth pure($)
      {@currentNode pure($)}
   end

   meth incCycleCount
      {@currentNode incCycleCount}
   end

   meth setTellNode(Node)
      {@currentNode setTellNode(Node)}
   end

   meth setLayoutType(Type)
      {@currentNode setLayoutType(Type)}
   end
end

%% InternalAtomLayoutObject

class InternalAtomLayoutObject
   from
      LayoutObject

   attr
      tellNode : nil %% "Parent" Tell Node

   meth layout
      TellNode = @tellNode
   in
      if @dazzle
      then
         String   = @value
      in
         @string = String
         @xDim   = {VirtualString.length String}
         @yDim   = 1
         @color  = black
         dazzle <- false
         dirty  <- true
      end
      case TellNode
      of nil then skip
      else {TellNode incCycleCount}
      end
   end

   meth setTellNode(Node)
      tellNode <- Node
   end
end

%% BitmapLayoutObject

class BitmapLayoutObject
   from
      LayoutObject

   meth layout
      if @dazzle
      then
         @xDim  = 2
         @color = '#b22222'
         yDim   <- 1
         dazzle <- false
      end
   end
end

%% GenericLayoutObject

class GenericLayoutObject
   from
      ProxyLayoutObject
end
