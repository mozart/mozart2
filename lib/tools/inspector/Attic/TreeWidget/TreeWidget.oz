%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% TreeWidget Functor
%%%

functor $

import
   SupportNodes
   TreeNodes
   StoreListener
   CycleManager
   Tk(returnInt send)

export
   treeWidget : TreeWidget

define
   OpMan            = SupportNodes.options
   ProxyNode        = SupportNodes.proxyNode
   BitmapTreeNode   = SupportNodes.bitmapTreeNode
   InternalAtomNode = SupportNodes.internalAtomNode

   \insert 'Create/CreateProcs.oz'

   class TreeWidget
      from
         StoreListener.storeListener

      attr
         server %% Own Adapter Variable
         canvas %% Canvas Window
         dMode  %% Display Mode
         dWidth %% Display Width (Logical Expansion)
         dDepth %% Display Depth (Locical Expansion)
         curY   %% Current Y Position
         maxX   %% Maxmimal X Dimension
         maxPtr %% Current Node Counter
         nodes  %% Node Dictionary
         font   %% Fontname
         fontX  %% Font X Dimension
         fontY  %% Font Y Dimension
         fmaxX  %% Max X Dimension
         fmaxY  %% Max Y Dimension
         rPhase %% Display Phase (needed for stop)

      meth create(Canvas DspWidth DspHeight)
         Font = {OpMan get(canvasFont $)}
      in
         StoreListener.storeListener, create

         @curY   = 1
         @maxX   = 0
         @maxPtr = 0
         @nodes  = {Dictionary.new}
         @font   = Font.fontName
         @fontX  = Font.xDim
         @fontY  = Font.yDim
         @fmaxX  = DspWidth div Font.xDim
         @fmaxY  = DspHeight div Font.yDim
         @canvas = Canvas
         @rPhase = 0

         TreeWidget, queryDB
         TreeWidget, initButtonHandler
      end

      meth queryDB
         dWidth <- {OpMan get(treeWidth $)}
         dDepth <- {OpMan get(treeDepth $)}
         dMode  <- {OpMan get(treeDisplayMode $)}
      end

      meth configure(W H)
         fmaxX <- {Max (W div @fontX) 1}
         fmaxY <- {Max (H div @fontY) 1}
         TreeWidget, adjustCanvasView
      end

      meth initButtonHandler
         Canvas = @canvas
      in
         {Canvas
          tkBind(event:  '<3>'
                 args:   [int(x) int(y)]
                 action: proc {$ X Y}
                            Node|FX|FY = TreeWidget, searchNode(X Y $)
                         in
                            case Node
                            of nil then skip
                            else {Node handleRightButton(X FX Y FY)}
                            end
                         end)}

         {Canvas
          tkBind(event:  '<Configure>'
                 args:   [int(w) int(h)]
                 action: proc {$ W H}
                            TreeWidget, configure(W H)
                         end)}
      end

      meth searchNode(X Y $)
         Canvas = @canvas
         FontX  = @fontX
         FontY  = @fontY
         FX FY Node
      in
         FX = {Canvas tkReturnInt(canvasx(X FontX) $)} div FontX
         FY = {Canvas tkReturnInt(canvasy(Y FontY) $)} div FontY
         Node = TreeWidget, performSearchNode(1 0 FX FY $)
         Node|FX|FY
      end

      meth performSearchNode(I Min X Y $)
         case I =< @maxPtr
         then
            Node = {Dictionary.get @nodes I}
            Max  = (Min + {Node getYDim($)})
         in
            case Y >= Min andthen Y =< Max
            then {Node searchNode(coord(X (Y - Min)) $)}
            else TreeWidget, performSearchNode((I + 1) Max X Y $)
            end
         else nil
         end
      end

      meth setServer(Server)
         server <- Server
      end

      meth getServer($)
         @server
      end

      meth getOrigin($)
         Canvas = @canvas
         RX     = {Tk.returnInt winfo(rootx Canvas)}
         RY     = {Tk.returnInt winfo(rooty Canvas)}
      in
         RX|RY
      end

      meth getVisualData($)
         @canvas|@fontX|@fontY
      end

      meth getCanvas($)
         @canvas
      end

      meth getRootIndex(I $)
         I
      end

      meth getWidth($)
         @dWidth
      end

      meth setWidth(Width)
         dWidth <- Width
      end

      meth getDepth($)
         @dDepth
      end

      meth setDepth(Depth)
         dDepth <- Depth
      end

      meth printXY(X Y String Tag Color)
         {@canvas
          tk(cre text (X * @fontX) (Y * @fontY)
             anchor:  w
             justify: left
             font:    @font
             fill:    Color
             text:    String
             tags:    Tag)}
      end

      meth paintXY(X Y Image Tag Color)
         {@canvas
          tk(cre bitmap (X * @fontX) (Y * @fontY)
             anchor:     w
             foreground: Color
             bitmap:     Image
             tags:       Tag)}
      end

      meth display(Value)
         try
            Node MaxPtr YDim
         in
            rPhase <- 1
            Node   = TreeWidget, performCreation(Value $)
            MaxPtr = (@maxPtr + 1)
            maxPtr <- MaxPtr
            {Dictionary.put @nodes MaxPtr Node}
            {Node setParentData(self MaxPtr)}
            {Node layout}
            YDim = {Node getYDim($)}
            rPhase <- 2
            {Node draw(1 @curY)}
            curY <- (@curY + YDim)
            TreeWidget, moveCanvasView
            rPhase <- 0
            %%   {Wait {Tk.return update(idletasks)}}
         catch interrupted then
            case @rPhase
            of 0 then skip
            [] 1 then skip
            [] 2 then skip
            end
         end
      end

      meth call(Obj Mesg)
         RI = {Obj getRootIndex(0 $)}
      in
         {Obj Mesg}
         TreeWidget, update(RI|nil)
      end

      meth performCreation(Value $)
         case @dMode
         of normal then
            {Create Value self 0}
         [] cycle  then
            CycleMan = {New CycleManager.cycleManager create}
         in
            {CycleCreate Value self CycleMan 0}
         [] graph then
            CycleMan = {New BaseObject noop} %% Graph Manager
         in
            {CycleCreate Value self CycleMan 0}
         end
      end

      meth calcMaxX(I)
         case I =< @maxPtr
         then
            Node = {Dictionary.get @nodes I}
            XDim = {Node getXDim($)}
         in
            case @maxX < XDim
            then maxX <- XDim
            else skip
            end
            TreeWidget, calcMaxX((I + 1))
         else skip
         end
      end

      meth moveCanvasView
         Canvas = @canvas
         CurY   = @curY
         NewY   = ((CurY div @fmaxY) * @fmaxX)
      in
         maxX <- 0
         TreeWidget, calcMaxX(1)
         {Canvas tk(configure
                    scrollregion: q(0
                                    0
                                    ((@maxX + 1) * @fontX)
                                    (CurY  * @fontY)))}
         {Canvas tk(yview moveto NewY)}
      end

      meth adjustCanvasView
         Canvas = @canvas
         CurY   = @curY
      in
         maxX <- 0
         TreeWidget, calcMaxX(1)
         {Canvas tk(configure
                    scrollregion: q(0
                                    0
                                    ((@maxX + 1) * @fontX)
                                    (CurY  * @fontY)))}
      end

      meth replace(I Value Call)
         Items   = @nodes
         OldNode = {Dictionary.get Items I}
         YDim    = {OldNode getYDim($)}
         Node    = {self Call(OldNode Value $)}
      in
         {OldNode undraw}
         {Node setYDim(YDim)}
         case {OldNode isProxy($)}
         then {OldNode alter(Node)}
         else {Dictionary.put Items I Node}
         end
         {Node setParentData(self I)}
      end

      meth replaceNormal(OldNode Value $)
         TreeWidget, performCreation(Value $)
      end

      meth replaceDepth(OldNode Value $)
         Node   = {New BitmapTreeNode create(depth self 0)}
         RValue = {OldNode getValue($)}
      in
         {Node setRescueValue(RValue)}
         Node
      end

      meth up(N I)
         Items   = @nodes
         OldNode = {Dictionary.get Items I}
         YDim    = {OldNode getYDim($)}
         Node    = {New BitmapTreeNode create(depth self 0)}
         Value   = {OldNode getValue($)}
      in
         {OldNode undraw}
         {Node setYDim(YDim)}
         {Node setRescueValue(Value)}
         {Dictionary.put Items I Node}
         {Node setParentData(self I)}
      end

      meth link(I Value)
         Items   = @nodes
         OldNode = {Dictionary.get Items I}
         YDim    = {OldNode getYDim($)}
         Node    = TreeWidget, performCreation(Value $)
         Proxy   = {New ProxyNode create(OldNode Node)}
      in
         {OldNode undraw}
         {Node setYDim(YDim)}
         {Dictionary.put Items I Proxy}
         {Node setParentData(self I)}
      end

      meth unlink(I)
         Items   = @nodes
         OldNode = {Dictionary.get Items I}
         YDim    = {OldNode getYDim($)}
         Node    = {OldNode delete($)}
      in
         {OldNode undraw}
         {Node setYDim(YDim)}
         {Dictionary.put Items I Node}
      end

      meth shrink(I)
         Items   = @nodes
         OldNode = {Dictionary.get Items I}
         YDim    = {OldNode getYDim($)}
         Node    = {OldNode delete($)}
         NYDim   = {Node getYDim($)}
         Delta   = (NYDim - YDim)
      in
         curY <- (@curY + Delta)
         {OldNode undraw}
         {Dictionary.put Items I Node}
      end

      meth handleDepthExpansion(N Value Index)
         case N =< 0
         then skip
         else
            Items    = @nodes
            Node     = {Dictionary.get Items Index}
            YDim     = {Node getYDim($)}
            OldDepth = @dDepth
            NewNode
         in
            dDepth <- (N - 1)
            NewNode = TreeWidget, performCreation(Value $)
            dDepth <- OldDepth
            {Node undraw}
            {Dictionary.put Items Index NewNode}
            {NewNode setYDim(YDim)}
            {NewNode setParentData(self Index)}
         end
      end

      meth menuHint(Index Status)
         Node = {Dictionary.get @nodes Index}
      in
         {Node setMenuStatus(Status)}
      end

      meth notify
         skip
      end

      meth update(Is)
         case Is
         of I|Ir then
            TreeWidget, updateNode(I)
            TreeWidget, update(Ir)
         [] nil  then
            TreeWidget, adjustCanvasView
%%          {Wait {Tk.return update(idletasks)}}
         end
      end

      meth updateNode(I)
         Node   = {Dictionary.get @nodes I}
         StartY = TreeWidget, calcYPos((I - 1) 1 $)
         YDim   = {Node getYDim($)}
         NYDim Delta
      in
         {Node layout}
         NYDim = {Node getYDim($)}
         {Node reDraw(1 StartY)}
         Delta = (NYDim - YDim)
         curY <- (@curY + Delta)
         case Delta
         of 0 then skip
         elsecase I == @maxPtr
         then skip
         else
            Zero = 0
         in
            TreeWidget, moveNodes((I + 1) Zero Zero Delta (Delta * @fontY))
         end
      end

      meth calcYPos(I A $)
         case I
         of 0 then A
         else
            Node = {Dictionary.get @nodes I}
            YDim = {Node getYDim($)}
         in
            TreeWidget, calcYPos((I - 1) (A + YDim) $)
         end
      end

      meth moveNodes(I X XF Y YF)
         Node = {Dictionary.get @nodes I}
      in
         {Node moveNodeXY(X XF Y YF)}
         case I < @maxPtr
         then TreeWidget, moveNodes((I + 1) X XF Y YF)
         else skip
         end
      end

      meth popup(X Y Menu)
         RX|RY = TreeWidget, getOrigin($)
      in
         {Tk.send
          tk_popup(Menu
                   (RX + X)
                   (RY + Y))}
      end

      meth freeze(FreezeVar)
         {Wait FreezeVar}
      end
   end
end
