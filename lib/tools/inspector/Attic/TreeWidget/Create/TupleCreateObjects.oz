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

      meth ignoreStop($)
         false
      end
   end
in

   %% HashTupleCreateObject

   class HashTupleCreateObject
      from
         TupleShareCreateObject

      meth create(Value Parent Index Visual Depth)
         CurWidth = @curWidth
      in
         CreateObject, create(Value Parent Index Visual (Depth + 1))
         @type     = hashTuple
         @items    = {Dictionary.new}
         @widthLen = {Width Value}
         CurWidth  = {Visual getWidth($)}
         @curDepth = {Visual getDepth($)}
         HashTupleCreateObject, adjustWidth(CurWidth 1)
      end

      meth adjustWidth(CurWidth I)
         StopValue = {@visual getStop($)}
      in
         width <- {Min CurWidth @widthLen}
         {self performInsertion(I StopValue)}
      end

      meth performInsertion(I StopValue)
         Visual = @visual
         Depth  = @depth
      in
         if {IsFree StopValue}
         then
            if I < @width
            then
               Node      = {Create @value.I self I Visual Depth}
               Separator = {New InternalAtomNode create('#' self I Visual Depth)}
            in
               {Dictionary.put @items I Node|Separator}
               HashTupleCreateObject, performInsertion((I + 1) StopValue)
            elseif I == @widthLen
            then
               Node = {Create @value.I self I Visual Depth}
            in
               {Dictionary.put @items I Node}
            else
               Items     = @items
               Node      = {Create @value.I self I Visual Depth}
               Separator = {New InternalAtomNode create('#' self I Visual Depth)}
               NewWidth  = (I + 1)
               Bitmap    = {New BitmapTreeNode
                            create(width self NewWidth Visual Depth)}
            in
               {Dictionary.put Items I Node|Separator}
               {Dictionary.put Items NewWidth Bitmap}
               width <- NewWidth
            end
         else
            {self stopCreation}
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

      meth create(Value Parent Index Visual Depth)
         CurWidth = @curWidth
      in
         CreateObject, create(Value Parent Index Visual (Depth + 1))
         @items    = {Dictionary.new}
         CurWidth  = {Visual getWidth($)}
         @curDepth = {Visual getDepth($)}
         PipeTupleCreateObject, adjustWidth(CurWidth 1)
      end

      meth adjustWidth(MaxWidth I)
         NewValue  = PipeTupleCreateObject, seekStartPos(I @value $)
         StopValue = {@visual getStop($)}
      in
         maxWidth <- MaxWidth
         {self performInsertion(I NewValue StopValue)}
      end

      meth seekStartPos(I Vs $)
         case I
         of 1 then Vs
         else PipeTupleCreateObject, seekStartPos((I - 1) Vs.2 $)
         end
      end

      meth performInsertion(I Vs StopValue)
         if {IsFree StopValue}
         then
            if I =< @maxWidth
            then
               if {IsFree Vs}
               then
                  Node = {Create Vs self I @visual @depth}
               in
                  {Dictionary.put @items I Node}
                  type  <- pipeTuple
                  width <- I
               elsecase Vs
               of V|Vr then
                  Visual    = @visual
                  Depth     = @depth
                  Node      = {Create V self I Visual Depth}
                  Separator = {New InternalAtomNode
                               create('|' self I Visual Depth)}
               in
                  {Dictionary.put @items I Node|Separator}
                  PipeTupleCreateObject,
                  performInsertion((I + 1) Vr StopValue)
               [] nil  then
                  Visual = @visual
                  Depth  = @depth
               in
                  type  <- list
                  width <- (I - 1)
                  @obrace = {New InternalAtomNode
                             create('[' self I Visual Depth)}
                  @cbrace = {New InternalAtomNode
                             create(']' self I Visual Depth)}
                  PipeTupleCreateObject, removeSeparators(1)
               else
                  Node = {Create Vs self I @visual @depth}
               in
                  {Dictionary.put @items I Node}
                  type  <- pipeTuple
                  width <- I
               end
            else
               Node = {New BitmapTreeNode create(width self I @visual @depth)}
            in
               {Dictionary.put @items I Node}
               width <- I
               type  <- pipeTuple
            end
         else
            {self stopCreation}
         end
      end

      meth removeSeparators(I)
         Items          = @items
         Node|Separator = {Dictionary.get Items I}
      in
         {Separator undraw}
         {Dictionary.put Items I Node}
         if I < @width
         then PipeTupleCreateObject, removeSeparators((I + 1))
         end
      end

      meth addSeparators(I)
         if I > 0
         then
            Items = @items
            Node  = {Dictionary.get Items I}
            Separator = {New InternalAtomNode
                         create('|' self I @visual @depth)}
         in
            {Dictionary.put Items I Node|Separator}
            PipeTupleCreateObject, addSeparators(I - 1)
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

      meth create(Value Parent Index Visual CycleMan Depth)
         CurWidth = @curWidth
      in
         CreateObject, create(Value Parent Index Visual (Depth + 1))
         @type      = hashTuple
         @items     = {Dictionary.new}
         @widthLen  = {Width Value}
         @cycleMan  = CycleMan
         @cycleNode = {New InternalAtomNode
                       create({CycleMan register(Value self $)}#'='
                              self 0 Visual Depth)}
         @cobrace   = {New InternalAtomNode
                       create('(' self 0 Visual Depth)}
         @ccbrace   = {New InternalAtomNode
                       create(')' self 0 Visual Depth)}
         CurWidth   = {Visual getWidth($)}
         @curDepth  = {Visual getDepth($)}
         HashTupleCreateObject, adjustWidth(CurWidth 1)
      end

      meth performInsertion(I StopValue)
         Visual   = @visual
         Depth    = @depth
         CycleMan = @cycleMan
      in
         if {IsFree StopValue}
         then
            if I < @width
            then
               Separator = {New InternalAtomNode
                            create('#' self I Visual Depth)}
               Node
            in
               {CycleMan push}
               Node = {CycleCreate @value.I self I Visual CycleMan Depth}
               {CycleMan pop}
               {CycleMan getStack(Node)}
               {Dictionary.put @items I Node|Separator}
               HashTupleCycleCreateObject,
               performInsertion((I + 1) StopValue)
            elseif I == @widthLen
            then
               Node
            in
               {CycleMan push}
               Node = {CycleCreate @value.I self I Visual CycleMan Depth}
               {CycleMan pop}
               {CycleMan getStack(Node)}
               {Dictionary.put @items I Node}
            else
               Items     = @items
               Separator = {New InternalAtomNode
                            create('#' self I Visual Depth)}
               Bitmap    = {New BitmapTreeNode create(width self I Visual Depth)}
               NewWidth  = (I + 1)
               Node
            in
               {CycleMan push}
               Node = {CycleCreate @value.I self I Visual CycleMan Depth}
               {CycleMan pop}
               {CycleMan getStack(Node)}
               {CycleMan getStack(Bitmap)}
               {Dictionary.put Items I Node|Separator}
               {Dictionary.put Items NewWidth Bitmap}
               width <- NewWidth
            end
         else
            {self stopCreation}
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
         CurWidth = @curWidth
      in
         CreateObject, create(Value Visual (Depth + 1))
         @items     = {Dictionary.new}
         @cycleMan  = CycleMan
         @cycleNode = {New InternalAtomNode
                       create({CycleMan register(Value self $)}#'='
                              self 0 Visual Depth)}
         @cobrace   = {New InternalAtomNode
                       create('(' self 0 Visual Depth)}
         @ccbrace   = {New InternalAtomNode
                       create(')' self 0 Visual Depth)}
         CurWidth   = {Visual getWidth($)}
         @curDepth  = {Visual getDepth($)}
         PipeTupleCreateObject, adjustWidth(CurWidth 1)
      end

      meth performInsertion(I Vs StopValue)
         if {IsFree StopValue}
         then
            if I =< @maxWidth
            then
               if {IsFree Vs}
               then
                  CycleMan = @cycleMan
                  Node
               in
                  {CycleMan push}
                  Node = {CycleCreate Vs self I @visual CycleMan @depth}
                  {CycleMan pop}
                  {CycleMan getStack(Node)}
                  {Dictionary.put @items I Node}
                  type  <- pipeTuple
                  width <- I
               elsecase Vs
               of V|Vr then
                  Visual    = @visual
                  Depth     = @depth
                  CycleMan  = @cycleMan
                  Separator = {New InternalAtomNode
                               create('|' self I Visual Depth)}
                  Node
               in
                  {CycleMan push}
                  Node = {CycleCreate V self I Visual CycleMan Depth}
                  {CycleMan pop}
                  {CycleMan getStack(Node)}
                  {Dictionary.put @items I Node|Separator}
                  if {System.eq Vr @value}
                  then PipeTupleCycleCreateObject, endCycleInsertion((I + 1))
                  else PipeTupleCycleCreateObject, performInsertion((I + 1) Vr)
                  end
               [] nil  then
                  Visual = @visual
                  Depth  = @depth
               in
                  type  <- list
                  width <- (I - 1)
                  @obrace = {New InternalAtomNode
                             create('[' self I Visual Depth)}
                  @cbrace = {New InternalAtomNode
                             create(']' self I Visual Depth)}
                  PipeTupleCreateObject, removeSeparators(1)
               else
                  CycleMan = @cycleMan
                  Node
               in
                  {CycleMan push}
                  Node = {CycleCreate Vs self I @visual CycleMan @depth}
                  {CycleMan pop}
                  {CycleMan getStack(Node)}
                  {Dictionary.put @items I Node}
                  type  <- pipeTuple
                  width <- I
               end
            else
               Node = {New BitmapTreeNode create(width self I @visual @depth)}
            in
               {@cycleMan getStack(Node)}
               {Dictionary.put @items I Node}
               width <- I
               type  <- pipeTuple
            end
         else
            {self stopCreation}
         end
      end

      meth endCycleInsertion(I)
         CycleMan = @cycleMan
      in
         if I =< @maxWidth
         then
            Node
         in
            {CycleMan push}
            Node = {CycleCreate @value self I @visual CycleMan @depth}
            {CycleMan pop}
            {CycleMan getStack(Node)}
            {Dictionary.put @items I Node}
            type  <- pipeTuple
            width <- I
         else
            Node = {New BitmapTreeNode create(width self I @visual @depth)}
         in
            {CycleMan getStack(Node)}
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


   meth create(Value Parent Index Visual Depth)
      TLabel = @label
   in
      CreateObject, create(Value Parent Index Visual (Depth + 1))
      @type     = labelTuple
      TLabel    = {Create {Label Value} self 0 Visual Depth}
      {TLabel initMenu(@type)}
      @items    = {Dictionary.new}
      @widthLen = {Width Value}
      @brace    = {New InternalAtomNode create(')' self 0 Visual Depth)}
      @curWidth = {Visual getWidth($)}
      @curDepth = {Visual getDepth($)}
      {TLabel setLayoutType(tuple)}
      {TLabel setRescueValue(Value)}
      LabelTupleCreateObject, adjustWidth(@curWidth 1)
   end

   meth adjustWidth(CurWidth I)
      StopValue = {@visual getStop($)}
   in
      width <- {Min CurWidth @widthLen}
      {self performInsertion(I StopValue)}
   end

   meth performInsertion(I StopValue)
      Width = @width
   in
      if {IsFree StopValue}
      then
         if I =< Width
         then
            Node = {Create @value.I self I @visual @depth}
         in
            {Dictionary.put @items I Node}
            LabelTupleCreateObject, performInsertion((I + 1) StopValue)
         elseif Width < @widthLen
         then
            Bitmap = {New BitmapTreeNode create(width self I @visual @depth)}
         in
            {Dictionary.put @items I Bitmap}
            width <- I
         else skip
         end
      else
         {self stopCreation}
      end
   end

   meth ignoreStop($)
      false
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
      LabelTupleCreateObject, adjustWidth(@curWidth 1)
   end

   meth performInsertion(I StopValue)
      Width    = @width
      CycleMan = @cycleMan
   in
      if {IsFree StopValue}
      then
         if I =< Width
         then
            Node
         in
            {CycleMan push}
            Node = {CycleCreate @value.I self I @visual CycleMan @depth}
            {CycleMan pop}
            {CycleMan getStack(Node)}
            {Dictionary.put @items I Node}
            LabelTupleCycleCreateObject, performInsertion((I + 1) StopValue)
         elseif Width < @widthLen
         then
            Bitmap = {New BitmapTreeNode create(width @visual @depth)}
         in
            {CycleMan getStack(Bitmap)}
            {Dictionary.put @items I Bitmap}
            width <- I
         end
      else
         {self stopCreation}
      end
   end
end
