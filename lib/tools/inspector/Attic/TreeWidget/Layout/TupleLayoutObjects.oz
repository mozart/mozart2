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
%%% TupleLayoutObjects
%%%

local
   class TupleShareLayoutObject
      from
         LayoutObject

      attr
         lastXDim   %% X Dimension (Last Entry)
         layoutMode %% Layout Mode

      meth layout
         if @dazzle
         then
            StopValue = {@visual getStop($)}
         in
            layoutMode <- horizontal
            TupleShareLayoutObject, performLayoutCheck(1)
            case @layoutMode
            of horizontal then
               TupleShareLayoutObject, horizontalLayout(1 0 StopValue)
            [] vertical   then
               TupleShareLayoutObject, verticalLayout(1 0 0 StopValue)
            end
            dazzle <- false
            dirty  <- true
         end
      end

      meth performLayoutCheck(I)
         Items = @items
      in
         if I < @width
         then
            Node|Separator = {Dictionary.get Items I}
            NodeType       = {Node getType($)}
         in
            case NodeType
            of record       then layoutMode <- vertical
            [] kindedRecord then layoutMode <- vertical
            [] hashTuple    then
               if {Node pure($)}
               then
                  NewNode = {New EmbraceNode
                             create(Node self I @visual round)}
               in
                  {Dictionary.put Items I NewNode|Separator}
               end
               layoutMode <- vertical
            [] pipeTuple    then
               if {Node pure($)}
               then
                  NewNode = {New EmbraceNode
                             create(Node self I @visual round)}
               in
                  {Dictionary.put Items I NewNode|Separator}
               end
               layoutMode <- vertical
            [] labelTuple   then layoutMode <- vertical
            [] list         then layoutMode <- vertical
            else skip
            end
            TupleShareLayoutObject, performLayoutCheck((I + 1))
         else
            Node     = {Dictionary.get Items I}
            NodeType = {Node getType($)}
         in
            case NodeType
            of record       then layoutMode <- vertical
            [] kindedRecord then layoutMode <- vertical
            [] hashTuple    then
               if {Node pure($)}
               then
                  NewNode = {New EmbraceNode
                             create(Node self I @visual round)}
               in
                  {Dictionary.put Items I NewNode}
               end
               layoutMode <- vertical
            [] pipeTuple    then
               if {Node pure($)}
               then
                  NewNode = {New EmbraceNode
                             create(Node self I @visual round)}
               in
                  {Dictionary.put Items I NewNode}
               end
               layoutMode <- vertical
            [] labelTuple   then layoutMode <- vertical
            [] list         then layoutMode <- vertical
            else skip
            end
         end
      end

      meth horizontalLayout(I XDim StopValue)
         if {IsFree StopValue}
         then
            if I < @width
            then
               Node|Separator = {Dictionary.get @items I}
               IXDim
            in
               {Node layout}
               {Separator layout}
               IXDim = {Node getXDim($)}
               TupleShareLayoutObject,
               horizontalLayout((I + 1) (XDim + (IXDim + 1)) StopValue)
            else
               Node = {Dictionary.get @items I}
               IXDim
            in
               {Node layout}
               IXDim = {Node getXDim($)}
               xDim     <- (XDim + IXDim)
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
         if {IsFree StopValue}
         then
            if I < @width
            then
               Node|Separator = {Dictionary.get @items I}
               IXDim IYDim ILXDim TXDim NXDim
            in
               {Node layout}
               {Separator layout}
               IXDim|IYDim = {Node getXYDim($)}
               ILXDim      = {Node getLastXDim($)}
               TXDim       = (ILXDim + 1)
               NXDim       = {Max TXDim IXDim}
               TupleShareLayoutObject,
               verticalLayout((I + 1) {Max XDim NXDim}
                              (YDim + IYDim) StopValue)
            else
               Node = {Dictionary.get @items I}
               IXDim IYDim ILXDim
            in
               {Node layout}
               IXDim|IYDim = {Node getXYDim($)}
               ILXDim      = {Node getLastXDim($)}
               xDim     <- {Max XDim IXDim}
               yDim     <- (YDim + IYDim)
               lastXDim <- ILXDim
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
in

   %% HashTupleLayoutObject

   class HashTupleLayoutObject
      from
         TupleShareLayoutObject
   end

   %% PipeTupleLayoutObject

   class PipeTupleLayoutObject
      from
         TupleShareLayoutObject

      meth layout
         case @type
         of list      then PipeTupleLayoutObject, fastLayout
         [] pipeTuple then TupleShareLayoutObject, layout
         end
      end

      meth fastLayout
         if @dazzle
         then
            StopValue = {@visual getStop($)}
         in
            {@obrace layout}
            {@cbrace layout}
            PipeTupleLayoutObject, performFastLayoutCheck(1)
            case @layoutMode
            of horizontal then
               PipeTupleLayoutObject, fastHorizontalLayout(1 1 StopValue)
            [] vertical   then
               PipeTupleLayoutObject, fastVerticalLayout(1 0 0 StopValue)
            end
            dazzle <- false
            dirty  <- true
         end
      end

      meth performFastLayoutCheck(I)
         Node     = {Dictionary.get @items I}
         NodeType = {Node getType($)}
      in
         case NodeType
         of record       then layoutMode <- vertical
         [] kindedRecord then layoutMode <- vertical
         [] hashTuple    then layoutMode <- vertical
         [] pipeTuple    then layoutMode <- vertical
         [] labelTuple   then layoutMode <- vertical
         [] list         then layoutMode <- vertical
         elseif I < @width
         then PipeTupleLayoutObject, performFastLayoutCheck((I + 1))
         else layoutMode <- horizontal
         end
      end

      meth fastHorizontalLayout(I XDim StopValue)
         Node = {Dictionary.get @items I}
         IXDim
      in
         if {IsFree StopValue}
         then
            {Node layout}
            IXDim = {Node getXDim($)}
            if I < @width
            then
               PipeTupleLayoutObject,
               fastHorizontalLayout((I + 1) (XDim + IXDim) StopValue)
            else
               xDim     <- (XDim + IXDim + I)
               yDim     <- 1
               lastXDim <- @xDim
            end
         else
            xDim     <- 0
            yDim     <- 0
            lastXDim <- 0
         end
      end

      meth fastVerticalLayout(I XDim YDim StopValue)
         Node = {Dictionary.get @items I}
         IXDim IYDim
      in
         if {IsFree StopValue}
         then
            {Node layout}
            IXDim|IYDim = {Node getXYDim($)}
            if I < @width
            then
               PipeTupleLayoutObject,
               fastVerticalLayout((I + 1) {Max XDim IXDim}
                                 (YDim + IYDim) StopValue)
            else
               LXDim = ({Node getLastXDim($)} + 1)
               NXDim = {Max LXDim IXDim}
            in
               xDim     <-  (1 + {Max XDim NXDim})
               yDim     <- (YDim + IYDim)
               lastXDim <- (LXDim + 1)
            end
         else
            xDim     <- 0
            yDim     <- 0
            lastXDim <- 0
         end
      end
   end

   %% HashTupleCycleLayoutObject

   class HashTupleCycleLayoutObject
      from
         HashTupleLayoutObject

      attr
         cycleCount    : 0 %% HashTuple Cycle Count
         oldCycleCount     %% Old Cycle Count

      meth layout
         if @dazzle
         then
            oldCycleCount <- (cycleCount <- 0)
            TupleShareLayoutObject, layout
            case @cycleCount
            of 0 then skip
            else
               CycleNode = @cycleNode
               XDim NXDim LXDim NLXDim
            in
               {CycleNode layout}
               {@cobrace layout}
               {@ccbrace layout}
               XDim   = ({CycleNode getXDim($)} + 1)
               NXDim  = (@xDim + XDim)
               LXDim  = (@lastXDim + XDim)
               NLXDim = (LXDim + 1)
               if (NLXDim > NXDim)
               then xDim <- NLXDim
               else xDim <- NXDim
               end
               lastXDim <- NLXDim
            end
         end
      end

      meth incCycleCount
         cycleCount <- (@cycleCount + 1)
      end
   end

   class PipeTupleCycleLayoutObject
      from
         PipeTupleLayoutObject

      attr
         cycleCount    : 0 %% PipeTuple Cycle Count
         oldCycleCount     %% Old Cycle Count

      meth layout
         if @dazzle
         then
            oldCycleCount <- (cycleCount <- 0)
            PipeTupleLayoutObject, layout
            case @cycleCount
            of 0 then skip
            elsecase @type
            of pipeTuple then
               CycleNode = @cycleNode
               XDim NXDim LXDim NLXDim
            in
               {CycleNode layout}
               {@cobrace layout}
               {@ccbrace layout}
               XDim   = ({CycleNode getXDim($)} + 1)
               NXDim  = (@xDim + XDim)
               LXDim  = (@lastXDim + XDim)
               NLXDim = (LXDim + 1)
               xDim     <- {Max NLXDim NXDim}
               lastXDim <- NLXDim
            [] list      then
               CycleNode = @cycleNode
               XDim
            in
               {CycleNode layout}
               XDim = {CycleNode getXDim($)}
               xDim     <- (XDim + @xDim)
               lastXDim <- (XDim + @lastXDim)
            end
         end
      end

      meth incCycleCount
         cycleCount <- (@cycleCount + 1)
      end
   end
end

%% LabelTupleLayoutObject

class LabelTupleLayoutObject
   from
      LayoutObject

   attr
      layoutMode %% Layout Mode
      lastXDim   %% X Dimension (Last Entry)
      labelXDim  %% X Dimension (Tuple Label)

   meth layout
      if @dazzle
      then
         {@label layout}
         {@brace layout}
         LabelTupleLayoutObject, performLayoutCheck(1)
         case @layoutMode
         of horizontal then LabelTupleLayoutObject, horizontalLayout(1 0)
         [] vertical   then LabelTupleLayoutObject, verticalLayout(1 0 0)
         end
         dazzle <- false
         dirty  <- true
      end
   end

   meth performLayoutCheck(I)
      Node     = {Dictionary.get @items I}
      NodeType = {Node getType($)}
   in
      case NodeType
      of record       then layoutMode <- vertical
      [] kindedRecord then layoutMode <- vertical
      [] hashTuple    then layoutMode <- vertical
      [] pipeTuple    then layoutMode <- vertical
      [] labelTuple   then layoutMode <- vertical
      [] list         then layoutMode <- vertical
      elseif I < @width
      then LabelTupleLayoutObject, performLayoutCheck(I + 1)
      else layoutMode <- horizontal
      end
   end

   meth horizontalLayout(I XDim)
      Node = {Dictionary.get @items I}
      IXDim
   in
      {Node layout}
      IXDim = {Node getXDim($)}
      if I < @width
      then LabelTupleLayoutObject, horizontalLayout((I + 1) (XDim + IXDim))
      else
         LXDim = {@label getXDim($)}
      in
         xDim      <- (XDim + IXDim + LXDim + I)
         yDim      <- 1
         lastXDim  <- @xDim
         labelXDim <- LXDim
      end
   end

   meth verticalLayout(I XDim YDim)
      Node = {Dictionary.get @items I}
      IXDim IYDim
   in
      {Node layout}
      IXDim|IYDim = {Node getXYDim($)}
      if I < @width
      then LabelTupleLayoutObject, verticalLayout((I + 1)
                                                  {Max XDim IXDim}
                                                  (YDim + IYDim))
      else
         LXDim  = {@label getXDim($)}
         ILXDim = {Node getLastXDim($)}
         TXDim  = (ILXDim + 1)
         NXDim  = {Max TXDim IXDim}
      in
         xDim      <- (LXDim + {Max XDim NXDim})
         yDim      <- (YDim + IYDim)
         lastXDim  <- (LXDim + TXDim)
         labelXDim <- LXDim
      end
   end

   meth getLastXDim($)
      @lastXDim
   end

   meth setLastXDim(LXDim)
      lastXDim <- LXDim
   end
end

%% LabelTupleCycleLayoutObject

class LabelTupleCycleLayoutObject
   from
      LabelTupleLayoutObject

   attr
      cycleCount    : 0 %% LabelTuple Cycle Count
      oldCycleCount     %% Previous Cycle Count

   meth layout
      if @dazzle
      then
         oldCycleCount <- (cycleCount <- 0)
         LabelTupleLayoutObject, layout
         case @cycleCount
         of 0 then skip
         else
            CycleNode = @cycleNode
            XDim
         in
            {CycleNode layout}
            XDim = {CycleNode getXDim($)}
            xDim     <- (XDim + @xDim)
            lastXDim <- (XDim + @lastXDim)
         end
      end
   end

   meth incCycleCount
      cycleCount <- (@cycleCount + 1)
   end
end
