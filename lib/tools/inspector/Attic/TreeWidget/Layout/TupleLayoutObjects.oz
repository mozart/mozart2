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
         case @dazzle
         then
            layoutMode <- horizontal
            TupleShareLayoutObject, performLayoutCheck(1)
            case @layoutMode
            of horizontal then TupleShareLayoutObject, horizontalLayout(1 0)
            [] vertical   then TupleShareLayoutObject, verticalLayout(1 0 0)
            end
            dazzle <- false
            dirty  <- true
         else skip
         end
      end

      meth performLayoutCheck(I)
         Items = @items
      in
         case I < @width
         then
            Node|Separator = {Dictionary.get Items I}
            NodeType       = {Node getType($)}
         in
            case NodeType
            of record       then layoutMode <- vertical
            [] kindedRecord then layoutMode <- vertical
            [] hashTuple    then
               case {Node pure($)}
               then
                  NewNode = {New EmbraceNode create(Node @visual round)}
               in
                  {Dictionary.put Items I NewNode|Separator}
               else skip
               end
               layoutMode <- vertical
            [] pipeTuple    then
               case {Node pure($)}
               then
                  NewNode = {New EmbraceNode create(Node @visual round)}
               in
                  {Dictionary.put Items I NewNode|Separator}
               else skip
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
               case {Node pure($)}
               then
                  NewNode = {New EmbraceNode create(Node @visual round)}
               in
                  {Dictionary.put Items I NewNode}
               else skip
               end
               layoutMode <- vertical
            [] pipeTuple    then
               case {Node pure($)}
               then
                  NewNode = {New EmbraceNode create(Node @visual round)}
               in
                  {Dictionary.put Items I NewNode}
               else skip
               end
               layoutMode <- vertical
            [] labelTuple   then layoutMode <- vertical
            [] list         then layoutMode <- vertical
            else skip
            end
         end
      end

      meth horizontalLayout(I XDim)
         case I < @width
         then
            Node|Separator = {Dictionary.get @items I}
            IXDim
         in
            {Node layout}
            {Separator layout}
            IXDim = {Node getXDim($)}
            TupleShareLayoutObject, horizontalLayout((I + 1)
                                                     (XDim + (IXDim + 1)))
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
      end

      meth verticalLayout(I XDim YDim)
         case I < @width
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
            TupleShareLayoutObject, verticalLayout((I + 1)
                                                   {Max XDim NXDim}
                                                   (YDim + IYDim))
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
         case @dazzle
         then
            {@obrace layout}
            {@cbrace layout}
            PipeTupleLayoutObject, performFastLayoutCheck(1)
            case @layoutMode
            of horizontal then
               PipeTupleLayoutObject, fastHorizontalLayout(1 1)
            [] vertical   then
               PipeTupleLayoutObject, fastVerticalLayout(1 0 0)
            end
            dazzle <- false
            dirty  <- true
         else skip
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
         else
            case I < @width
            then PipeTupleLayoutObject, performFastLayoutCheck((I + 1))
            else layoutMode <- horizontal
            end
         end
      end

      meth fastHorizontalLayout(I XDim)
         Node = {Dictionary.get @items I}
         IXDim
      in
         {Node layout}
         IXDim = {Node getXDim($)}
         case I < @width
         then
            PipeTupleLayoutObject, fastHorizontalLayout((I + 1)
                                                        (XDim + IXDim))
         else
            xDim     <- (XDim + IXDim + I)
            yDim     <- 1
            lastXDim <- @xDim
         end
      end

      meth fastVerticalLayout(I XDim YDim)
         Node = {Dictionary.get @items I}
         IXDim IYDim
      in
         {Node layout}
         IXDim|IYDim = {Node getXYDim($)}
         case I < @width
         then
            PipeTupleLayoutObject, fastVerticalLayout((I + 1)
                                                      {Max XDim IXDim}
                                                      (YDim + IYDim))
         else
            LXDim = ({Node getLastXDim($)} + 1)
            NXDim = {Max LXDim IXDim}
         in
            xDim     <-  (1 + {Max XDim NXDim})
            yDim     <- (YDim + IYDim)
            lastXDim <- (LXDim + 1)
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
         case @dazzle
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
               case (NLXDim > NXDim)
               then xDim <- NLXDim
               else xDim <- NXDim
               end
               lastXDim <- NLXDim
            end
         else skip
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
         case @dazzle
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
         else skip
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
      case @dazzle
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
      else skip
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
      elsecase I < @width
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
      case I < @width
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
      case I < @width
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
      case @dazzle
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
      else skip
      end
   end

   meth incCycleCount
      cycleCount <- (@cycleCount + 1)
   end
end
