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
%%% RecordDrawObjects
%%%

%% RecordDrawObject

class RecordDrawObject
   from
      DrawObject

   meth draw(X Y)
      if @dirty
      then
         StopValue = {@visual getStop($)}
      in
         xAnchor <- X
         yAnchor <- Y
         {@label draw(X Y)}
         case @layoutMode
         of horizontal then
            RecordDrawObject, horizontalDraw(1 (X + @labelXDim) Y StopValue)
         [] vertical   then
            RecordDrawObject, verticalDraw(1 (X + @labelXDim) Y StopValue)
         end
         dirty <- false
      end
   end

   meth horizontalDraw(I X Y StopValue)
      Label|Node = {Dictionary.get @items I}
      LabelXDim  = {Label getXDim($)}
      NodeXDim   = {Node getXDim($)}
      DeltaX     = (X + LabelXDim)
   in
      if {IsFree StopValue}
      then
         {Label draw(X Y)}
         {Node draw(DeltaX Y)}
         if I < @width
         then RecordDrawObject,
            horizontalDraw((I + 1) (DeltaX + NodeXDim + 1) Y StopValue)
         else {@brace draw((DeltaX + NodeXDim) Y)}
         end
      else
         {self stopDraw(I X Y)}
      end
   end

   meth verticalDraw(I X Y StopValue)
      Label|Node = {Dictionary.get @items I}
      LabelXDim  = {Label getXDim($)}
      NodeYDim   = {Node getYDim($)}
   in
      if {IsFree StopValue}
      then
         {Label draw(X Y)}
         {Node draw((X + LabelXDim) Y)}
         if I < @width
         then RecordDrawObject,
            verticalDraw((I + 1) X (Y + NodeYDim) StopValue)
         else
            LXDim = {Node getLastXDim($)}
         in
            {@brace draw(((X + LabelXDim) + LXDim) (Y + (NodeYDim - 1)))}
         end
      else
         {self stopDraw(I X Y)}
      end
   end

   meth stopDraw(I X Y)
      Visual  = @visual
      Depth   = @depth
      Bitmap  = {New BitmapTreeNode create(width self I Visual Depth)}
      NullObj = {New NullNode create(nil self I Visual Depth)}
      RI      = {self getRootIndex(0 $)}
   in
      {Dictionary.put @items I NullObj|Bitmap}
      width <- I
      RecordDrawObject, notify
      {@visual update(RI|nil)}
   end

   meth undraw
      {@label undraw}
      {@brace undraw}
      RecordDrawObject, performUndraw(1)
      dirty <- true
   end

   meth performUndraw(I)
      Label|Node = {Dictionary.get @items I}
   in
      {Label undraw}
      {Node undraw}
      if I < @width
      then RecordDrawObject, performUndraw((I + 1))
      end
   end

   meth replace(I Value Call)
      Items         = @items
      Label|OldNode = {Dictionary.get Items I}
      Node          = {self Call(OldNode Value I $)}
   in
      {OldNode undraw}
      if {OldNode isProxy($)}
      then {OldNode alter(Node)}
      else {Dictionary.put Items I Label|Node}
      end
      RecordDrawObject, notify
   end

   meth replaceNormal(OldNode Value I $)
      {Create Value self I @visual @depth}
   end

   meth replaceDepth(OldNode Value I $)
      RValue = {OldNode getValue($)}
      Node   = {New BitmapTreeNode create(depth self I @visual @depth)}
   in
      {Node setRescueValue(RValue)}
      Node
   end

   meth link(I Value)
      Items = @items
      Label|OldNode = {Dictionary.get Items I}
      Node          = {self replaceNormal(OldNode Value I $)}
      Proxy         = {New ProxyNode create(OldNode Node)}
   in
      {OldNode undraw}
      {Dictionary.put Items I Label|Proxy}
      RecordDrawObject, notify
   end

   meth unlink(I)
      Items         = @items
      Label|OldNode = {Dictionary.get Items I}
      Node          = {OldNode delete($)}
   in
      {OldNode undraw}
      {Dictionary.put Items I Label|Node}
      RecordDrawObject, notify
   end

   meth shrink(I)
      {@parent unlink(@index)}
   end

   meth notify
      dazzle <- true
      {@parent notify}
   end

   meth moveNodeXY(X XF Y YF)
      if @dirty
      then skip
      else
         xAnchor <- (@xAnchor + X)
         yAnchor <- (@yAnchor + Y)
         {@label moveNodeXY(X XF Y YF)}
         RecordDrawObject, performMoveNodeXY(1 X XF Y YF)
      end
   end

   meth performMoveNodeXY(I X XF Y YF)
      Label|Node = {Dictionary.get @items I}
   in
      {Label moveNodeXY(X XF Y YF)}
      {Node moveNodeXY(X XF Y YF)}
      if I < @width
      then RecordDrawObject, performMoveNodeXY((I + 1) X XF Y YF)
      else {@brace moveNodeXY(X XF Y YF)}
      end
   end

   meth reDraw(X Y)
      if @dirty
      then
         StopValue = {@visual getStop($)}
      in
         xAnchor <- X
         yAnchor <- Y
         {@label reDraw(X Y)}
         case @layoutMode
         of horizontal then
            RecordDrawObject, horizontalReDraw(1 (X + @labelXDim) Y StopValue)
         [] vertical   then
            RecordDrawObject, verticalReDraw(1 (X + @labelXDim) Y StopValue)
         end
         dirty <- false
      else
         DeltaX = (X - @xAnchor)
         DeltaY = (Y - @yAnchor)
      in
         case DeltaX
         of 0 then
            case DeltaY
            of 0 then skip
            else
               RecordDrawObject, moveNodeXY(DeltaX (DeltaX * @xf)
                                            DeltaY (DeltaY * @yf))
            end
         else
            RecordDrawObject, moveNodeXY(DeltaX (DeltaX * @xf)
                                         DeltaY (DeltaY * @yf))
         end
      end
   end

   meth horizontalReDraw(I X Y StopValue)
      Label|Node = {Dictionary.get @items I}
      LabelXDim  = {Label getXDim($)}
      NodeXDim   = {Node getXDim($)}
      DeltaX     = (X + LabelXDim)
   in
      if {IsFree StopValue}
      then
         {Label reDraw(X Y)}
         {Node reDraw(DeltaX Y)}
         if I < @width
         then RecordDrawObject,
            horizontalReDraw((I + 1) (DeltaX + NodeXDim + 1) Y StopValue)
         else {@brace reDraw((DeltaX + NodeXDim) Y)}
         end
      end
   end

   meth verticalReDraw(I X Y StopValue)
      Label|Node = {Dictionary.get @items I}
      LabelXDim  = {Label getXDim($)}
      NodeYDim   = {Node getYDim($)}
   in
      if {IsFree StopValue}
      then
         {Label reDraw(X Y)}
         {Node reDraw((X + LabelXDim) Y)}
         if I < @width
         then RecordDrawObject,
            verticalReDraw((I + 1) X (Y + NodeYDim) StopValue)
         else
            LXDim = {Node getLastXDim($)}
         in
            {@brace reDraw(((X + LabelXDim) + LXDim) (Y + (NodeYDim - 1)))}
         end
      end
   end

   meth searchNode(Coord $)
      coord(X Y) = Coord
      Label      = @label
      XDim       = {Label getXDim($)}
      LabelNode  = {Label searchNode(Coord $)}
   in
      case LabelNode
      of nil then
         case @layoutMode
         of horizontal then
            RecordDrawObject, horizontalSearch(1 XDim X $)
         [] vertical   then
            RecordDrawObject, verticalSearch(1 0 (X - XDim) Y $)
         end
      else LabelNode
      end
   end

   meth horizontalSearch(I Min X $)
      if I =< @width
      then
         Label|Node = {Dictionary.get @items I}
         LabelX     = {Label getXDim($)}
         Max        = ((Min + {Node getXDim($)}) + LabelX)
      in
         if X >= Min andthen X =< Max
         then {Node searchNode(coord((X - Min - LabelX) 0) $)}
         else RecordDrawObject, horizontalSearch((I + 1) (Max + 1) X $)
         end
      else nil
      end
   end

   meth verticalSearch(I Min X Y $)
      if I =< @width
      then
         Label|Node = {Dictionary.get @items I}
         LabelX     = {Label getXDim($)}
         Max        = (Min + {Node getYDim($)})
      in
         if Y >= Min andthen Y =< Max
         then {Node searchNode(coord((X - LabelX) (Y - Min)) $)}
         else RecordDrawObject, verticalSearch((I + 1) Max X Y $)
         end
      else nil
      end
   end

   meth initMenu(Type)
      {@label initMenu(Type)}
   end

   meth updateMenu(Type Status)
      {@label updateMenu(Type Status)}
   end

   meth getMenu($)
      {@label getMenu($)}
   end

   meth setMenuStatus(Status)
      {@label setMenuStatus(Status)}
   end

   meth getMenuStatus($)
      {@label getMenuStatus($)}
   end

   meth menuHint(Index Status)
      _|Node = {Dictionary.get @items Index}
   in
      {Node setMenuStatus(Status)}
   end

   meth handleLabelWidthExpansion(N)
      RecordDrawObject, handleWidthExpansion(N @width)
   end

   meth handleWidthExpansion(N Index)
      if N > 0
      then
         _|Node = {Dictionary.get @items Index}
         Type   = {Node getType($)}
      in
         case Type
         of widthBitmap then
            NewWidth = {Min ((@width - 1) + N) @arityLen}
         in
            RecordDrawObject, eraseSingleNode(Index)
            {self adjustWidth(NewWidth Index)}
            RecordDrawObject, notify
         else skip
         end
      elsecase N
      of 0 then skip
      else
         ArityLen = @arityLen
         Width    = @width
         _|Node   = {Dictionary.get @items Index}
         Type     = {Node getType($)}
         DelCount NewWidth NewIndex
      in
         case Type
         of widthBitmap then
            NewWidth = {Max (@width - 1 + N) 0}
            DelCount = {Min ({Abs N} + 1) Width}
         else
            NewWidth = {Max (@width + N) 0}
            DelCount = {Min {Abs N} ArityLen}
         end
         NewIndex = {Max (Index - DelCount + 1) 1}
         RecordDrawObject, eraseNodes(Index DelCount)
         {self adjustWidth(NewWidth NewIndex)}
         RecordDrawObject, notify
      end
   end

   meth eraseSingleNode(I)
      Label|Node = {Dictionary.get @items I}
   in
      {Label undraw}
      {Node undraw}
   end

   meth eraseNodes(Index N)
      RecordDrawObject, eraseSingleNode(Index)
      if N > 1
      then RecordDrawObject, eraseNodes((Index - 1) (N - 1))
      end
   end

   meth handleDepthExpansion(N Value Index)
      if N < 0
      then
         {@parent up((N + 1) @index)}
      elsecase N
      of 0 then skip
      elsecase Index
      of 0 then {@parent up(N @index)}
      else
         Items      = @items
         Visual     = @visual
         Label|Node = {Dictionary.get Items Index}
         OldDepth   = {Visual getDepth($)}
         NewDepth   = (@depth + N - 1)
         NewNode
      in
         {Visual setDepth(NewDepth)}
         NewNode = {self replaceNormal(Node Value Index $)}
         {Visual setDepth(OldDepth)}
         {Node undraw}
         {Dictionary.put Items Index Label|NewNode}
         RecordDrawObject, notify
      end
   end

   meth up(N I)
      if N < 0
      then {@parent up((N + 1) @index)}
      else {self replace(I nil replaceDepth)} %% nil is Dummy Value
      end
   end
end

%% KindedRecordDrawObject

class KindedRecordDrawObject
   from
      RecordDrawObject

   attr
      labelVar          %% Label Variable (Monitor)
      haveLabel : false %% Label Hint

   meth draw(X Y)
      if @dirty
      then
         RecordDrawObject, draw(X Y)
         {@visual logVar(self @monitorValue normal)}
         KindedRecordDrawObject, watchLabel
      end
   end

   meth watchLabel
      if @haveLabel
      then skip
      else
         LabelVar = @labelVar
      in
         {@visual logVar(self LabelVar label)}
         thread
            LabelVar = {Label @value}
         end
      end
   end

   meth reDraw(X Y)
      if @dirty
      then
         RecordDrawObject, reDraw(X Y)
         {@visual logVar(self @monitorValue normal)}
         KindedRecordDrawObject, watchLabel
      else
         DeltaX = (X - @xAnchor)
         DeltaY = (Y - @yAnchor)
      in
         case DeltaX
         of 0 then
            case DeltaY
            of 0 then skip
            else
               RecordDrawObject, moveNodeXY(DeltaX (DeltaX * @xf)
                                            DeltaY (DeltaY * @yf))
            end
         else
            RecordDrawObject, moveNodeXY(DeltaX (DeltaX * @xf)
                                         DeltaY (DeltaY * @yf))
         end
      end
   end

   meth tell
      I      = @width
      _|Node = {Dictionary.get @items I}
   in
      {Node undraw}
      KindedRecordCreateObject, computeArityLen(@arity 1)
      RecordCreateObject, adjustWidth(@curWidth I)
      RecordDrawObject, notify
   end

   meth tellLabel
      OldLabel = @label
      Label
   in
      {OldLabel undraw}
      label <- {New TreeNodes.atomTreeNode
                create(@labelVar self 0 @visual @depth)}
      Label = @label
      {Label setLayoutType(tuple)}
      {Label setRescueValue(@value)}
      {Label initMenu(@type)}
      haveLabel <- true
      RecordDrawObject, notify
   end
end

%% RecordCycleDrawObject

class RecordCycleDrawObject
   from
      RecordDrawObject

   meth draw(X Y)
      case @cycleCount
      of 0 then
         RecordDrawObject, draw(X Y)
      else
         CycleNode = @cycleNode
         XDim      = {CycleNode getXDim($)}
      in
         {CycleNode draw(X Y)}
         RecordDrawObject, draw((X + XDim) Y)
      end
   end

   meth stopDraw(I X Y)
      Visual    = @visual
      Depth     = @depth
      Items     = @items
      _|OldNode = {Dictionary.get Items I}
      OldStack  = {OldNode getStack($)}
      Bitmap    = {New BitmapTreeNode create(width self I Visual Depth)}
      NullObj   = {New NullNode create(nil self I Visual Depth)}
      RI        = {self getRootIndex(0 $)}
   in
      {Bitmap setStack(OldStack)}
      {Dictionary.put Items I NullObj|Bitmap}
      width <- I
      RecordDrawObject, notify
      {@visual update(RI|nil)}
   end

   meth undraw
      case @cycleCount
      of 0 then skip
      else {@cycleNode undraw}
      end
      {@label undraw}
      {@brace undraw}
      RecordDrawObject, performUndraw(1)
      dirty <- true
   end

   meth replaceNormal(OldNode Value I $)
      OldStack = {OldNode getStack($)}
      CycleMan = @cycleMan
      Node
   in
      {CycleMan setStack(OldStack)}
      {CycleMan push}
      Node = {CycleCreate Value self I @visual CycleMan @depth}
      {CycleMan pop}
      {CycleMan tellStack(Node)}
      Node
   end

   meth replaceDepth(OldNode Value I $)
      RValue   = {OldNode getValue($)}
      OldStack = {OldNode getStack($)}
      Node     = {New BitmapTreeNode create(depth self I @visual @depth)}
   in
      {Node setRescueValue(RValue)}
      {Node setStack(OldStack)}
      Node
   end

   meth moveNodeXY(X XF Y YF)
      if @dirty
      then skip
      else
         case @cycleCount
         of 0 then skip
         else {@cycleNode moveNodeXY(X XF Y YF)}
         end
         xAnchor <- (@xAnchor + X)
         yAnchor <- (@yAnchor + Y)
         {@label moveNodeXY(X XF Y YF)}
         RecordDrawObject, performMoveNodeXY(1 X XF Y YF)
      end
   end

   meth reDraw(X Y)
      case @cycleCount
      of 0 then
         case @oldCycleCount
         of 0 then skip
         else {@cycleNode undraw}
         end
         RecordDrawObject, reDraw(X Y)
      else
         CycleNode = @cycleNode
         XDim      = {CycleNode getXDim($)}
      in
         {CycleNode reDraw(X Y)}
         RecordDrawObject, reDraw((X + XDim) Y)
      end
   end
end

%% KindedRecordCycleDrawObject

class KindedRecordCycleDrawObject
   from
      KindedRecordDrawObject
      RecordCycleDrawObject

   meth draw(X Y)
      case @cycleCount
      of 0 then
         case @oldCycleCount
         of 0 then skip
         else {@cycleNode undraw}
         end
         KindedRecordDrawObject, draw(X Y)
      else
         CycleNode = @cycleNode
         XDim      = {CycleNode getXDim($)}
      in
         {CycleNode draw(X Y)}
         KindedRecordDrawObject, draw((X + XDim) Y)
      end
   end

   meth reDraw(X Y)
      case @cycleCount
      of 0 then
         case @oldCycleCount
         of 0 then skip
         else {@cycleNode undraw}
         end
         KindedRecordDrawObject, reDraw(X Y)
      else
         CycleNode = @cycleNode
         XDim      = {CycleNode getXDim($)}
      in
         {CycleNode reDraw(X Y)}
         KindedRecordDrawObject, reDraw((X + XDim) Y)
      end
   end

   meth tell
      I         = @width
      _|Node    = {Dictionary.get @items I}
      OldStack  = {Node getStack($)}
   in
      {Node undraw}
      {@cycleMan setStack(OldStack)}
      KindedRecordDrawObject, computeArityLen(@arity 1)
      RecordCreateObject, adjustWidth(@curWidth I)
      RecordDrawObject, notify
   end

   meth searchNode(Coord $)
      coord(X Y) = Coord
      Label      = @label
      XDim LabelNode
   in
      case @cycleCount
      of 0 then
         XDim      = {Label getXDim($)}
         LabelNode = {Label searchNode(Coord $)}
      else
         RXDim = {@cycleNode getXDim($)}
      in
         XDim      = ({Label getXDim($)} + RXDim)
         LabelNode = {Label searchNode(coord((X - RXDim) Y) $)}
      end
      case LabelNode
      of nil then
         case @layoutMode
         of horizontal then
            RecordDrawObject, horizontalSearch(1 XDim X $)
         [] vertical   then
            RecordDrawObject, verticalSearch(1 0 (X - XDim) Y $)
         end
      else LabelNode
      end
   end
end
