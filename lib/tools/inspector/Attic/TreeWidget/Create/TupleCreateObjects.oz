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
%%% TupleCreateObjects
%%%

local
   class TupleShareCreateObject
      from
         CreateObject

      attr
         items    %% Tuple Items
         width    %% Tuple Width
         widthLen %% Real Tuple Width
         curWidth %% Current Width
         curDepth %% Current Depth
   end
in

   %% HashTupleCreateObject

   class HashTupleCreateObject
      from
         TupleShareCreateObject

      meth create(Value Visual Depth)
         CurWidth = @curWidth
      in
         CreateObject, create(Value Visual (Depth + 1))
         @type     = hashTuple
         @items    = {Dictionary.new}
         @widthLen = {Width Value}
         CurWidth  = {Visual getWidth($)}
         @curDepth = {Visual getDepth($)}
         HashTupleCreateObject, adjustWidth(CurWidth 1)
      end

      meth adjustWidth(CurWidth I)
         WidthLen = @widthLen
      in
         case CurWidth < WidthLen
         then
            Items     = @items
            Visual    = @visual
            Depth     = @depth
            Bitmap    = {New BitmapTreeNode create(width Visual Depth)}
            Separator = {New InternalAtomNode create('#' Visual Depth)}
            NewWidth  = (CurWidth + 1)
            Node
         in
            width <- CurWidth
            case CurWidth
            of 0 then skip
            else
               HashTupleCreateObject, performInsertion(I)
               Node = {Dictionary.get Items CurWidth}
               {Dictionary.put Items CurWidth Node|Separator}
            end
            {Bitmap setParentData(self NewWidth)}
            {Dictionary.put Items NewWidth Bitmap}
            width <- NewWidth
         else
            width <- WidthLen
            HashTupleCreateObject, performInsertion(I)
         end
      end

      meth performInsertion(I)
         Visual = @visual
         Node   = {Create @value.I Visual @depth}
      in
         {Node setParentData(self I)}
         case I < @width
         then
            Separator = {New InternalAtomNode create('#' Visual 0)}
         in
            {Dictionary.put @items I Node|Separator}
            HashTupleCreateObject, performInsertion((I + 1))
         else
            {Dictionary.put @items I Node}
         end
      end
   end

   %% PipeTupleCreateObject

   class PipeTupleCreateObject
      from
         TupleShareCreateObject

      attr
         maxWidth %% Current Max Width
         obrace   %% Open Edge (List Mode)
         cbrace   %% Close Edge (List Mode)

      meth create(Value Visual Depth)
         CurWidth = @curWidth
      in
         CreateObject, create(Value Visual (Depth + 1))
         @items    = {Dictionary.new}
         CurWidth  = {Visual getWidth($)}
         @curDepth = {Visual getDepth($)}
         PipeTupleCreateObject, adjustWidth(CurWidth 1)
      end

      meth adjustWidth(MaxWidth I)
         NewValue = PipeTupleCreateObject, seekStartPos(I @value $)
      in
         maxWidth <- MaxWidth
         PipeTupleCreateObject, performInsertion(I NewValue)
      end

      meth seekStartPos(I Vs $)
         case I
         of 1 then Vs
         else PipeTupleCreateObject, seekStartPos((I - 1) Vs.2 $)
         end
      end

      meth performInsertion(I Vs)
         case I =< @maxWidth
         then
            case {IsFree Vs}
            then
               Node = {Create Vs @visual @depth}
            in
               {Node setParentData(self I)}
               {Dictionary.put @items I Node}
               type  <- pipeTuple
               width <- I
            else
               case Vs
               of V|Vr then
                  Visual    = @visual
                  Depth     = @depth
                  Node      = {Create V Visual Depth}
                  Separator = {New InternalAtomNode create('|' Visual Depth)}
               in
                  {Node setParentData(self I)}
                  {Dictionary.put @items I Node|Separator}
                  PipeTupleCreateObject, performInsertion((I + 1) Vr)
               [] nil  then
                  Visual = @visual
                  Depth  = @depth
               in
                  type  <- list
                  width <- (I - 1)
                  @obrace = {New InternalAtomNode create('[' Visual Depth)}
                  @cbrace = {New InternalAtomNode create(']' Visual Depth)}
                  PipeTupleCreateObject, removeSeparators(1)
               else
                  Node = {Create Vs @visual @depth}
               in
                  {Node setParentData(self I)}
                  {Dictionary.put @items I Node}
                  type  <- pipeTuple
                  width <- I
               end
            end
         else
            Node = {New BitmapTreeNode create(width @visual @depth)}
         in
            {Node setParentData(self I)}
            {Dictionary.put @items I Node}
            width <- I
            type  <- pipeTuple
         end
      end

      meth removeSeparators(I)
         Items          = @items
         Node|Separator = {Dictionary.get Items I}
      in
         {Separator undraw}
         {Dictionary.put Items I Node}
         case I < @width
         then PipeTupleCreateObject, removeSeparators((I + 1))
         else skip
         end
      end

      meth addSeparators(I)
         case I > 0
         then
            Items = @items
            Node  = {Dictionary.get Items I}
            Separator
         in
            Separator = {New InternalAtomNode create('|' @visual @depth)}
            {Dictionary.put Items I Node|Separator}
            PipeTupleCreateObject, addSeparators(I - 1)
         else skip
         end
      end
   end

   %% HashTupleCycleCreateObject

   class HashTupleCycleCreateObject
      from
         HashTupleCreateObject

      attr
         cycleMan  %% HashTuple Cycle Manager
         cycleNode %% HashTuple CycleNode
         cobrace   %% HashTuple Cycle Open Brace
         ccbrace   %% HashTuple Cycle Close Brace

      meth create(Value Visual CycleMan Depth)
         CurWidth = @curWidth
      in
         CreateObject, create(Value Visual (Depth + 1))
         @type      = hashTuple
         @items     = {Dictionary.new}
         @widthLen  = {Width Value}
         @cycleMan  = CycleMan
         @cycleNode = {New InternalAtomNode
                       create({CycleMan register(Value self $)}#'='
                              Visual Depth)}
         @cobrace   = {New InternalAtomNode create('(' Visual Depth)}
         @ccbrace   = {New InternalAtomNode create(')' Visual Depth)}
         CurWidth   = {Visual getWidth($)}
         @curDepth  = {Visual getDepth($)}
         HashTupleCycleCreateObject, adjustWidth(CurWidth 1)
      end

      meth adjustWidth(CurWidth I)
         WidthLen = @widthLen
      in
         case CurWidth < WidthLen
         then
            Items     = @items
            Visual    = @visual
            Depth     = @depth
            Bitmap    = {New BitmapTreeNode create(width Visual Depth)}
            Separator = {New InternalAtomNode create('#' Visual Depth)}
            NewWidth  = (CurWidth + 1)
            Node
         in
            width <- CurWidth
            case CurWidth
            of 0 then skip
            else
               HashTupleCycleCreateObject, performInsertion(I)
               Node = {Dictionary.get Items CurWidth}
               {Dictionary.put Items CurWidth Node|Separator}
            end
            {Bitmap setParentData(self NewWidth)}
            {@cycleMan getStack(Bitmap)}
            {Dictionary.put Items NewWidth Bitmap}
            width <- NewWidth
         else
            width <- WidthLen
            HashTupleCycleCreateObject, performInsertion(I)
         end
      end

      meth performInsertion(I)
         Visual   = @visual
         CycleMan = @cycleMan
         Node
      in
         {CycleMan push}
         Node = {CycleCreate @value.I Visual CycleMan @depth}
         {CycleMan pop}
         {CycleMan getStack(Node)}
         {Node setParentData(self I)}
         case I < @width
         then
            Separator = {New InternalAtomNode create('#' Visual 0)}
         in
            {Dictionary.put @items I Node|Separator}
            HashTupleCycleCreateObject, performInsertion((I + 1))
         else
            {Dictionary.put @items I Node}
         end
      end
   end

   %% PipeTupleCycleCreateObject

   class PipeTupleCycleCreateObject
      from
         PipeTupleCreateObject

      attr
         cycleMan  %% PipeTuple Cycle Manager
         cycleNode %% PipeTuple Cycle Node
         cobrace   %% PipeTuple Cycle Open Brace
         ccbrace   %% PipeTuple Cycle Close Brace

      meth create(Value Visual CycleMan Depth)
         CreateObject, create(Value Visual (Depth + 1))
         @items     = {Dictionary.new}
         @maxWidth  = {Visual getWidth($)}
         @cycleMan  = CycleMan
         @cycleNode = {New InternalAtomNode
                       create({CycleMan register(Value self $)}#'='
                              Visual Depth)}
         @cobrace   = {New InternalAtomNode create('(' Visual Depth)}
         @ccbrace   = {New InternalAtomNode create(')' Visual Depth)}
         @curWidth  = {Visual getWidth($)}
         @curDepth  = {Visual getDepth($)}
         PipeTupleCycleCreateObject, adjustWidth(1)
      end

      meth adjustWidth(I)
         NewValue = PipeTupleCreateObject, seekStartPos(I @value $)
      in
         PipeTupleCycleCreateObject, performInsertion(I NewValue)
      end

      meth performInsertion(I Vs)
         case I =< @maxWidth
         then
            case {IsFree Vs}
            then
               CycleMan = @cycleMan
               Node
            in
               {CycleMan push}
               Node = {CycleCreate Vs @visual CycleMan @depth}
               {CycleMan pop}
               {CycleMan getStack(Node)}
               {Node setParentData(self I)}
               {Dictionary.put @items I Node}
               type  <- pipeTuple
               width <- I
            elsecase Vs
            of V|Vr then
               Visual    = @visual
               Depth     = @depth
               CycleMan  = @cycleMan
               Separator = {New InternalAtomNode create('|' Visual Depth)}
               Node
            in
               {CycleMan push}
               Node = {CycleCreate V Visual CycleMan Depth}
               {CycleMan pop}
               {CycleMan getStack(Node)}
               {Node setParentData(self I)}
               {Dictionary.put @items I Node|Separator}
               case {System.eq Vr @value}
               then PipeTupleCycleCreateObject, endCycleInsertion((I + 1))
               else PipeTupleCycleCreateObject, performInsertion((I + 1) Vr)
               end
            [] nil  then
               Visual = @visual
               Depth  = @depth
            in
               type  <- list
               width <- (I - 1)
               @obrace = {New InternalAtomNode create('[' Visual Depth)}
               @cbrace = {New InternalAtomNode create(']' Visual Depth)}
               PipeTupleCreateObject, removeSeparators(1)
            else
               CycleMan = @cycleMan
               Node
            in
               {CycleMan push}
               Node = {CycleCreate Vs @visual CycleMan @depth}
               {CycleMan pop}
               {CycleMan getStack(Node)}
               {Node setParentData(self I)}
               {Dictionary.put @items I Node}
               type  <- pipeTuple
               width <- I
            end
         else
            Node = {New BitmapTreeNode create(width @visual @depth)}
         in
            {Node setParentData(self I)}
            {@cycleMan getStack(Node)}
            {Dictionary.put @items I Node}
            width <- I
            type  <- pipeTuple
         end
      end

      meth endCycleInsertion(I)
         case I =< @maxWidth
         then
            CycleMan = @cycleMan
            Node
         in
            {CycleMan push}
            Node = {CycleCreate @value @visual CycleMan @depth}
            {CycleMan pop}
            {CycleMan getStack(Node)}
            {Node setParentData(self I)}
            {Dictionary.put @items I Node}
            type  <- pipeTuple
            width <- I
         else
            Node = {New BitmapTreeNode create(width @visual @depth)}
         in
            {Node setParentData(self I)}
            {@cycleMan getStack(Node)}
            {Dictionary.put @items I Node}
            width <- I
            type  <- pipeTuple
         end
      end
   end
end

%% LabelTupleCreateObject

class LabelTupleCreateObject
   from
      CreateObject

   attr
      label    %% Tuple Label
      items    %% Tuple Core Container
      width    %% Tuple Width
      widthLen %% Tuple Real Width
      brace    %% Closing Brace
      curWidth %% Current Width
      curDepth %% Current Depth


   meth create(Value Visual Depth)
      TLabel = @label
   in
      CreateObject, create(Value Visual (Depth + 1))
      @type     = labelTuple
      TLabel    = {New TreeNodes.atomTreeNode
                   create({Label Value} Visual Depth)}
      {TLabel initMenu(@type)}
      @items    = {Dictionary.new}
      @widthLen = {Width Value}
      @brace    = {New InternalAtomNode create(')' Visual Depth)}
      @curWidth = {Visual getWidth($)}
      @curDepth = {Visual getDepth($)}
      {TLabel setLayoutType(tuple)}
      {TLabel setParentData(self 0)}
      {TLabel setRescueValue(Value)}
      LabelTupleCreateObject, adjustWidth(@curWidth 1)
   end

   meth adjustWidth(CurWidth I)
      WidthLen = @widthLen
   in
      case CurWidth < WidthLen
      then
         Bitmap   = {New BitmapTreeNode create(width @visual @depth)}
         NewWidth = (CurWidth + 1)
      in
         width <- CurWidth
         {Bitmap setParentData(self NewWidth)}
         {Dictionary.put @items NewWidth Bitmap}
         case CurWidth < I
         then skip
         else LabelTupleCreateObject, performInsertion(I)
         end
         width <- NewWidth
      else
         width <- WidthLen
         LabelTupleCreateObject, performInsertion(I)
      end
      {@label setParentData(self @width)}
   end

   meth performInsertion(I)
      Node = {Create @value.I @visual @depth}
   in
      {Node setParentData(self I)}
      {Dictionary.put @items I Node}
      case I < @width
      then LabelTupleCreateObject, performInsertion((I + 1))
      else skip
      end
   end
end

%% LabelTupleCycleCreateObject

class LabelTupleCycleCreateObject
   from
      LabelTupleCreateObject

   attr
      cycleMan  %% LabelTuple Cycle Manager
      cycleNode %% LabelTuple Cycle Node

   meth create(Value Visual CycleMan Depth)
      TLabel = @label
   in
      CreateObject, create(Value Visual (Depth + 1))
      @type      = labelTuple
      TLabel     = {New TreeNodes.atomTreeNode
                    create({Label Value} Visual Depth)}
      {TLabel initMenu(@type)}
      @items     = {Dictionary.new}
      @widthLen  = {Width Value}
      @brace     = {New InternalAtomNode create(')' Visual Depth)}
      @curWidth  = {Visual getWidth($)}
      @curDepth  = {Visual getDepth($)}
      @cycleMan  = CycleMan
      @cycleNode = {New InternalAtomNode
                    create({CycleMan register(Value self $)}#'='
                           Visual Depth)}
      {TLabel setLayoutType(tuple)}
      {TLabel setRescueValue(Value)}
      LabelTupleCycleCreateObject, adjustWidth(@curWidth 1)
   end

   meth adjustWidth(CurWidth I)
      WidthLen = @widthLen
   in
      case CurWidth < WidthLen
      then
         Bitmap   = {New BitmapTreeNode create(width @visual @depth)}
         NewWidth = (CurWidth + 1)
      in
         width <- CurWidth
         {Bitmap setParentData(self NewWidth)}
         {@cycleMan getStack(Bitmap)}
         {Dictionary.put @items NewWidth Bitmap}
         case CurWidth < I
         then skip
         else LabelTupleCycleCreateObject, performInsertion(I)
         end
         width <- NewWidth
      else
         width <- WidthLen
         LabelTupleCycleCreateObject, performInsertion(I)
      end
      {@label setParentData(self @width)}
   end

   meth performInsertion(I)
      CycleMan = @cycleMan
      Node
   in
      {CycleMan push}
      Node = {CycleCreate @value.I @visual CycleMan @depth}
      {CycleMan pop}
      {CycleMan getStack(Node)}
      {Node setParentData(self I)}
      {Dictionary.put @items I Node}
      case I < @width
      then LabelTupleCycleCreateObject, performInsertion((I + 1))
      else skip
      end
   end
end
