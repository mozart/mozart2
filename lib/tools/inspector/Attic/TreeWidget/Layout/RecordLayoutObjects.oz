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
%%% RecordLayoutObjects
%%%

%% RecordLayoutObject

class RecordLayoutObject
   from
      LayoutObject

   attr
      layoutMode %% Layout Mode
      labelXDim  %% X Dimension of Label
      lastXDim   %% X Dimension (Last Entry)

   meth layout
      if @dazzle
      then
         Label      = @label
         StopValue  = {@visual getStop($)}
      in
         {Label layout}
         {@brace layout}
         labelXDim <- {Label getXDim($)}
         RecordLayoutObject, performLayoutCheck(1)
         case @layoutMode
         of horizontal then
            RecordLayoutObject, horizontalLayout(1 @labelXDim StopValue)
         [] vertical   then
            RecordLayoutObject, verticalLayout(1 0 0 StopValue)
         end
         dazzle <- false
         dirty  <- true
      end
   end

   meth performLayoutCheck(I)
      _|Node   = {Dictionary.get @items I}
      NodeType = {Node getType($)}
   in
      case NodeType
      of record       then layoutMode <- vertical
      [] kindedRecord then layoutMode <- vertical
      [] hashTuple    then layoutMode <- vertical
      [] pipeTuple    then layoutMode <- vertical
      [] labelTuple   then layoutMode <- vertical
      [] list         then layoutMode <- vertical
      else
         if I < @width
         then RecordLayoutObject, performLayoutCheck((I + 1))
         else layoutMode <- horizontal
         end
      end
   end

   meth horizontalLayout(I XDim StopValue)
      Label|Node = {Dictionary.get @items I}
      LabelXDim NodeXDim
   in
      if {IsFree StopValue}
      then
         {Label layout}
         {Node layout}
         LabelXDim = {Label getXDim($)}
         NodeXDim  = {Node getXDim($)}
         if I < @width
         then RecordLayoutObject,
            horizontalLayout((I + 1) (XDim + LabelXDim + NodeXDim) StopValue)
         else
            xDim     <- (XDim + LabelXDim + NodeXDim + I)
            yDim     <- 1
            lastXDim <- @xDim
         end
      else
         xDim     <- 0
         yDim     <- 0
         lastXDim <- 0
      end
   end

   meth verticalLayout(I XDim YDim StopValue)
      Label|Node  = {Dictionary.get @items I}
      IXDim IYDim LabelXDim
   in
      if {IsFree StopValue}
      then
         {Label layout}
         {Node layout}
         IXDim|IYDim = {Node getXYDim($)}
         LabelXDim   = {Label getXDim($)}
         if I < @width
         then
            RecordLayoutObject,
            verticalLayout((I + 1) {Max XDim (LabelXDim + IXDim)}
                           (YDim + IYDim) StopValue)
         else
            TXDim  = ({Node getLastXDim($)} + 1)
            RLXDim = @labelXDim
            NXDim  = {Max IXDim TXDim}
         in
            xDim     <- RLXDim + {Max XDim (LabelXDim + NXDim)}
            yDim     <- (YDim + IYDim)
            lastXDim <- (RLXDim + LabelXDim + TXDim)
         end
      else
         xDim     <- 0
         yDim     <- 0
         lastXDim <- 0
      end
   end

   meth getLastXDim($)
      @lastXDim
   end

   meth setLastXDim(XDim)
      lastXDim <- XDim
   end
end

%% KindedRecordLayoutObject

class KindedRecordLayoutObject
   from
      RecordLayoutObject
end

%% RecordCycleLayoutObject

class RecordCycleLayoutObject
   from
      RecordLayoutObject

   attr
      cycleCount : 0 %% Record Cycle Count
      oldCycleCount  %% Previus CycleCount

   meth layout
      if @dazzle
      then
         case @cycleCount
         of 0 then oldCycleCount <- 0
         else oldCycleCount <- (cycleCount <- 0)
         end
         RecordLayoutObject, layout
         case @cycleCount
         of 0 then skip
         else
            Cycle = @cycleNode
            XDim
         in
            {Cycle layout}
            XDim = {Cycle getXDim($)}
            xDim     <- (XDim + @xDim)
            lastXDim <- (XDim + @lastXDim)
         end
      end
   end

   meth incCycleCount
      cycleCount <- (@cycleCount + 1)
   end
end

%% KindedRecordCycleLayoutObject

class KindedRecordCycleLayoutObject
   from
      RecordCycleLayoutObject
end
