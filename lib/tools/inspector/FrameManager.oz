%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1999
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%   http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   NotifyWidgets = {NewName}
in
   local
      Frame     = {NewName}
      Configure = {NewName}
      CalcYPos  = {NewName}
   in
\ifndef INSPECTOR_GTK_GUI
      class GuiFrameManager
         meth create(Parent FWidth FHeight $)
            InspPort = @inspPort
            MyFrame  = @Frame
         in
            MyFrame = {New Tk.frame
                       tkInit(parent:             Parent
                              width:              FWidth
                              height:             FHeight
                              borderwidth:        0
                              highlightthickness: 0)}
            {MyFrame tkBind(event:  '<Configure>'
                            args:   [int(w) int(h)]
                            action: proc {$ W H}
                                       {Port.send InspPort Configure(W H)}
                                    end)}
            {MyFrame tkBind(event: '<Enter>'
                            action: proc {$}
                                       {Port.send InspPort enterFocus}
                                    end)}
            MyFrame
         end
      end
\else
      class GuiFrameManager
         meth create(Parent FWidth FHeight $)
            InspPort = @inspPort
            MyFrame  = @Frame
            Menu     = @toplevelMenu
         in
            MyFrame = {New GTKCANVAS.canvas new(false)}
            {MyFrame setUsize(FWidth FHeight)}
            {MyFrame setScrollRegion(0.0 0.0
                                     {Int.toFloat FWidth}
                                     {Int.toFloat FHeight})}
            {Parent packStart(MyFrame 1 1 0)}
            {{self getEventWindow($)}
             signalConnect(
                'event'
                proc {$ [Event]}
                   case Event
                   of 'GDK_CONFIGURE'(width: W height: H ...) then
                      Req = {New GTK.requisition requisitionNativeNew}
                      RH NewH
                   in
                      {Menu getChildRequisition(Req)}
                      RH   = {Req requisitionGetFieldHeight($)}
                      %% Minimal Y Height is 30
                      NewH = {Max 30 (H - RH)}
                      {MyFrame setScrollRegion(0.0 0.0
                                               {Int.toFloat W}
                                               {Int.toFloat NewH})}
                      {Req requisitionNativeDestroy}
                      {Port.send InspPort Configure(W NewH)}
                   [] 'GDK_ENTER_NOTIFY'(...) then
                      {Port.send InspPort enterFocus}
                   [] _ then skip
                   end
                end _)}
            MyFrame
         end
         meth getEventWindow($)
            self %% self = GTK.window
         end
         meth newItem(Item X Y W H $)
            MyFrame = @Frame
         in
            {MyFrame newItem(widget(parent : {MyFrame rootItem($)}
                                    widget : {MyFrame unwrapItem(Item $)}
                                    x      : X
                                    y      : Y
                                    width  : W
                                    height : H
                                    anchor : GTK.'ANCHOR_NW') $)}
         end
      end
\endif

      class FrameManager from GuiFrameManager
         attr
            !Items      %% Widget Dictionary
            !NumItems   %% Number of Widgets
            !NumWidgets %% Number of TreeWidgets
            !Width      %% Current Width
            !Height     %% Current Height
            !Frame      %% Widget Container
         meth create(Parent FWidth FHeight $)
            @Items      = {Dictionary.new}
            @NumItems   = 0
            @NumWidgets = 0
            @Width      = FWidth
            @Height     = FHeight
            GuiFrameManager, create(Parent FWidth FHeight $)
         end
         meth getFrame($)
            @Frame
         end
         meth append(Widget)
            CurNum = @NumItems
            NewNum = (CurNum + 1)
            CurY   = FrameManager, CalcYPos(CurNum 0 $)
         in
            NumItems <- NewNum
            {Dictionary.put @Items NewNum Widget}
            {Widget setIndex(NewNum)}
            {Widget setYPos(CurY)}
            {Widget draw}
         end
         meth calcMinMax(I $)
            MyItems = @Items
            NodeUp  = {Dictionary.get MyItems (I - 1)}
            NodeDn  = {Dictionary.get MyItems (I + 1)}
            MinY    = {NodeUp getMaxShrinkY($)}
            MaxY    = {NodeDn getMaxShrinkY($)}
         in
            MinY|MaxY
         end
         meth handleResize(Index DeltaY)
            MyItems = @Items
            NodeUp  = {Dictionary.get MyItems (Index - 1)}
            SGrip   = {Dictionary.get MyItems Index}
            NodeDn  = {Dictionary.get MyItems (Index + 1)}
            ConsY
         in
            if {Abs DeltaY} < 3 %% Ignore Bunny Moves
            then skip
            else
               ConsY = {NodeUp tellNewXY(0 DeltaY $)}
               {NodeDn moveY(ConsY)}
               {SGrip moveY(DeltaY)}
               _ = {NodeDn tellNewXY(0 ~DeltaY $)}
            end
         end
         meth !NotifyWidgets(N)
            NumWidgets <- (@NumWidgets + N)
         end
         meth !CalcYPos(I CurY $)
            case I
            of 0 then CurY
            elsecase {{Dictionary.get @Items I} getXYDim($)}
            of _|YDim then FrameManager, CalcYPos((I - 1) (CurY + YDim) $)
            end
         end
         meth !Configure(W H)
            DeltaX = (W - @Width)
            DeltaY = (H - @Height)
         in
            if DeltaX == 0 andthen DeltaY == 0
            then skip
            else
               Width  <- W
               Height <- H
               case @NumWidgets
               of 0     then skip
               elseof N then
                  DeltaYPart = (DeltaY div N)
                  DeltaYRem  = (DeltaY mod N)
               in
                  FrameManager, TellNewXY(1 DeltaX DeltaYPart)
                  _ = {{Dictionary.get @Items @NumItems}
                       tellNewXY(0 DeltaYRem $)}
               end
            end
         end
         meth !TellNewXY(I DeltaX DeltaY)
            if I =< @NumItems
            then
               case {{Dictionary.get @Items I} tellNewXY(DeltaX DeltaY $)}
               of 0             then skip
               elseof ConsumedY then FrameManager, MoveY((I + 1) ConsumedY)
               end
               FrameManager, TellNewXY((I + 1) DeltaX DeltaY)
            end
         end
         meth !MoveY(I DeltaY)
            if I =< @NumItems
            then
               {{Dictionary.get @Items I} moveY(DeltaY)}
               FrameManager, MoveY((I + 1) DeltaY)
            end
         end
         meth getInspPort($)
            @inspPort
         end
      end
   end

   local
      class GuiFrameNode
         meth setDimension(Y XDim YDim)
            skip
         end
         meth setPosition(NY)
            skip
         end
      end

      class FrameNode from GuiFrameNode
         attr
            parent   %% Window Object
            index    %% Parent Index
            y        %% Y Position
            xDim     %% X Dimension
            yDim     %% Y Dimension
            inspPort %% Inspector Port
         meth create(Parent XDim YDim)
            @inspPort = {Parent getInspPort($)}
            @parent   = Parent
            @xDim     = XDim
            @yDim     = YDim
         end
         meth setIndex(Index)
            index <- Index
         end
         meth getIndex($)
            @index
         end
         meth setYPos(Y)
            y <- Y
         end
         meth getXYDim($)
            @xDim|@yDim
         end
         meth getXDim($)
            @xDim
         end
         meth getYDim($)
            @yDim
         end
         meth getInspPort($)
            {@parent getInspPort($)}
         end
         meth tellNewXY(DeltaX DeltaY $)
            XDim = (@xDim + DeltaX)
            YDim = (@yDim + DeltaY)
         in
            xDim <- XDim
            yDim <- YDim
            GuiFrameNode, setDimension(0 XDim YDim)
            DeltaY
         end
         meth moveY(Y)
            NY = (@y + Y)
         in
            y <- NY
            GuiFrameNode, setPosition(NY)
         end
      end
   in
      %% Avoid Parallel Method Inheritance (setDim/Pos from FrameNode)
\ifndef INSPECTOR_GTK_GUI
      class GuiTreeWidgetNode from FrameNode
         meth create(Parent XYDim Canvas)
            Frame    = {Parent getFrame($)}
            InspPort = {Parent getInspPort($)}
            ScrollX  = @scrollX
            ScrollY  = @scrollY
         in
            {Canvas tkBind(event:  '<KeyPress-Tab>'
                           action: proc {$}
                                      {Port.send InspPort focusDn(false)}
                                   end)}
            {Canvas tkBind(event:  '<KeyPress-l>'
                           action: proc {$}
                                      {Port.send InspPort clearAll(false)}
                                   end)}
            {Canvas tkBind(event: '<2>'
                           action: proc {$}
                                      {Port.send InspPort changeFocus(self)}
                                   end)}
            ScrollX  = {New Tk.scrollbar
                        tkInit(parent:             Frame
                               width:              10
                               orient:             horizontal
                               highlightthickness: 0
                               borderwidth:        1)}
            ScrollY  = {New Tk.scrollbar
                        tkInit(parent:             Frame
                               width:              10
                               orient:             vertical
                               highlightthickness: 0
                               borderwidth:        1)}
            {Tk.addXScrollbar Canvas ScrollX}
            {Tk.addYScrollbar Canvas ScrollY}
         end
         meth draw
            Canvas  = @widObj
            FocDim  = @focDim
            CWidth  = (@cWidth + FocDim)
            CHeight = (@cHeight + FocDim)
            Y       = @y
            ScrDim  = 12
         in
            {Tk.batch [place(Canvas x: 0 y: Y
                             width: CWidth height: CHeight anchor: nw)
                       place(@scrollY x: CWidth y: Y
                             width: ScrDim height: CHeight anchor: nw)
                       place(@scrollX x: 0 y: (Y + CHeight)
                             width:CWidth height:ScrDim anchor: nw)]}
         end
         meth undraw
            {Tk.batch [place(forget @widObj)
                       place(forget @scrollY) place(forget @scrollX)]}
            {@parent NotifyWidgets(~1)}
         end
         meth setDimension(Y CWidth CHeight)
            {Tk.batch [place(conf @widObj width: CWidth height: CHeight)
                       place(conf @scrollY x: CWidth height: CHeight)
                       place(conf @scrollX y: (Y + CHeight) width: CWidth)]}
         end
         meth setPosition(NY)
            {Tk.batch [place(conf @widObj y: NY)
                       place(conf @scrollY y: NY)
                       place(conf @scrollX y: (NY + @cHeight))]}
         end
      end
\else
      class GuiTreeWidgetNode from FrameNode
         attr
            canvasItem
            scrollXItem
            scrollYItem
         meth create(Parent XYDim Canvas)
            ScrollX  = @scrollX
            ScrollY  = @scrollY
            InspPort = {Parent getInspPort($)}
            AdjX     = {Canvas getXAdjustment($)}
            AdjY     = {Canvas getYAdjustment($)}
            EventWin = {Parent getEventWindow($)}
         in
            ScrollX  = {New GTK.hScrollbar new(AdjX)}
            ScrollY  = {New GTK.vScrollbar new(AdjY)}
            {Canvas setScrollbars(ScrollX ScrollY)}
            {Canvas setEventWindow(EventWin {Parent getStopButton($)})}
            %% Should be Canvas rather than EventWindow (from FrameManager)
            {EventWin
             signalConnect('event'
                           proc {$ [Event]}
                              case Event
                              of 'GDK_BUTTON_PRESS'(button: 2 ...) then
                                 {Port.send InspPort changefocus(self)}
                                 %% GDK_Tab = 0xFF09
                              [] 'GDK_KEY_PRESS'(keyval: 0xFF09 ...) then
                                 {Port.send InspPort focusDn(false)}
                                 %% GDK_l = 0x6c
                              [] 'GDK_KEY_PRESS'(keyval: 0x06c ...) then
                                 {Port.send InspPort clearAll(false)}
                              [] _ then skip
                              end
                           end _)}
         end
         meth draw
            Canvas  = @widObj
            FocDim  = @focDim
            CWidth  = (@cWidth + FocDim)
            CHeight = (@cHeight + FocDim)
            Y       = @y
            ScrDim  = 12
            Parent  = @parent
         in
            @canvasItem  = {Parent newItem(Canvas 0 Y CWidth CHeight $)}
            @scrollYItem = {Parent newItem(@scrollY CWidth Y ScrDim CHeight $)}
            @scrollXItem = {Parent
                            newItem(@scrollX 0 (Y + CHeight) CWidth ScrDim $)}
         end
         meth undraw
            {@canvasItem destroy}
            {@scrollYItem destroy}
            {@scrollXItem destroy}
            {@parent NotifyWidgets(~1)}
         end
         meth setDimension(Y CWidth CHeight)
            Frame = {@parent getFrame($)}
         in
            {Frame configureItem(@canvasItem
                                 options(width  : {Int.toFloat CWidth}
                                         height : {Int.toFloat CHeight}))}
            {Frame configureItem(@scrollYItem
                                 options(x      : {Int.toFloat CWidth}
                                         height : {Int.toFloat CHeight}))}
            {Frame configureItem(@scrollXItem
                                 options(y     : {Int.toFloat (Y + CHeight)}
                                         width : {Int.toFloat CWidth}))}
            %% Propagate configure to Canvas
            %% This is definitly a bug
            {Port.send @widPort globalCanvasHandler(adjust(CWidth CHeight))}
         end
         meth setPosition(NY)
            Frame = {@parent getFrame($)}
         in
            {Frame configureItem(@canvasItem options(y : {Int.toFloat NY}))}
            {Frame configureItem(@scrollY options(y : {Int.toFloat NY}))}
            {Frame
             configureItem(@scrollX options(y : {Int.toFloat (NY + @cHeight)}))}
         end
      end
\endif

      class TreeWidgetNode from GuiTreeWidgetNode
         attr
            scrollX   %% X Scrollbar
            scrollY   %% Y ScrollBar
            cWidth    %% Canvas Width
            cHeight   %% Canvas Height
            dHeight   %% Smallest Possible Height
            deltaVal  %% Delta Val
            focDim    %% Focus Dimension
            widPort   %% Widget Port
            widObj    %% Widget Object (equals TK.canvas)
            freezeVar %% FreezeVar
         prop
            final
         meth create(Parent XDim YDim)
            Frame     = {Parent getFrame($)}
            BDeltaVal = 4          %% Toplevel Delta + Focus Delta
            CWidth    = @cWidth
            CHeight   = @cHeight
            DeltaVal  = @deltaVal
            Canvas    = @widObj
            WidPort   = @widPort
         in
            FrameNode, create(Parent XDim YDim)
            {Parent NotifyWidgets(1)}
            DeltaVal = (12 + BDeltaVal)
            @dHeight = (22 + DeltaVal)
            CWidth   = (XDim - DeltaVal)
            CHeight  = (YDim - DeltaVal)
            @focDim  = 2
            Canvas   = {New TreeWidget
                        create({Parent getOptions($)} Frame CWidth CHeight)}
            WidPort  = {NewServer Canvas}
            {Canvas setServer(WidPort)}
            GuiTreeWidgetNode, create(Parent XDim#YDim Canvas)
            {Parent append(self)}
         end
         meth getType($)
            canvasNode
         end
         meth getCanvas($)
            @widObj
         end
         meth getPort($)
            @widPort
         end
         meth getCanvasXYDim($)
            @cWidth|@cHeight
         end
         meth display(Value)
            {Port.send @widPort display(Value)}
         end
         meth selectionCall(Node Mesg)
            {Port.send @widPort selectionCall(Node Mesg)}
         end
         meth clearAll(F)
            {Port.send @widPort clearAll(F)}
         end
         meth apply(P)
            {Port.send @widPort apply(P)}
         end
         meth exportSelectionNode(Node)
            {Port.send @widPort exportSelectionNode(Node)}
         end
         meth getOptions($)
            {Port.send @widPort getOptions($)}
         end
         meth optionConfigure(O V)
            {Port.send @widPort optionConfigure(O V)}
         end
         meth stopUpdate
            {@widObj stopUpdate}
         end
         meth setOptions(Options)
            {Port.send @widPort setOptions(Options)}
         end
         meth tellNewXY(DeltaX DeltaY $)
            if DeltaX == 0 andthen DeltaY == 0
            then skip
            else
               Y       = @y
               XDim    = (@xDim + DeltaX)
               YDim    = (@yDim + DeltaY)
               FocDim  = @focDim
               DWidth  = (@cWidth + DeltaX)
               DHeight = (@cHeight + DeltaY)
               CWidth  = (DWidth + FocDim)
               CHeight = (DHeight + FocDim)
            in
               xDim    <- XDim
               yDim    <- YDim
               cWidth  <- DWidth
               cHeight <- DHeight
               GuiTreeWidgetNode, setDimension(Y CWidth CHeight)
            end
            DeltaY
         end
         meth moveY(Y)
            NY = (@y + Y)
         in
            GuiTreeWidgetNode, setPosition(NY)
            y <- NY
         end
         meth getMaxShrinkY($)
            {Max 0 (@yDim - @dHeight)}
         end
         meth freeze(FreezeVar)
            freezeVar <- FreezeVar
            {Port.send @widPort freeze(FreezeVar)}
         end
         meth unfreeze
            @freezeVar = unit
         end
         meth terminate
            {Port.send @widPort terminate}
         end
      end

\ifndef INSPECTOR_GTK_GUI
      class GuiSashGrip from FrameNode
         meth create(Parent XDim YDim)
            Frame    = {Parent getFrame($)}
            Grip     = @grip
            InspPort = {Parent getInspPort($)}
         in
            @sash = {New Tk.frame
                     tkInit(parent:             Frame
                            width:              XDim
                            height:             4
                            borderwidth:        1
                            relief:             sunken
                            highlightthickness: 0)}
            Grip  = {New Tk.frame
                     tkInit(parent:             Frame
                            width:              8
                            height:             8
                            borderwidth:        1
                            relief:             raised
                            highlightthickness: 0)}
            {Grip tkBind(event: '<ButtonPress-1>'
                         args: [int('Y')]
                         action: proc {$ Y}
                                    Value     = {Parent calcMinMax(@index $)}
                                    MinY|MaxY = Value
                                 in
                                    saveY <- @y
                                    addDY <- 0
                                    minY  <- MinY
                                    maxY  <- MaxY
                                    {@grip tk(conf relief: sunken)}
                                    {Tk.batch ['raise'(@sash)
                                               'raise'(@grip)]}
                                 end)}
            {Grip tkBind(event: '<Button1-Motion>'
                         args: [int('Y')]
                         action:
                            proc {$ Y}
                               DeltaY = (Y - {Tk.returnInt winfo(rooty @grip)})
                               AddDY  = (@addDY + DeltaY)
                            in
                               if AddDY < 0 andthen {Abs AddDY} =< @minY
                               then
                                  addDY <- AddDY
                                  SashGrip, moveY(DeltaY)
                               elseif AddDY > 0 andthen AddDY =< @maxY
                               then
                                  addDY <- AddDY
                                  SashGrip, moveY(DeltaY)
                               end
                            end)}
            {Grip tkBind(event: '<ButtonRelease-1>'
                         args:[int('Y')]
                         action:
                            proc {$ Y}
                               y <- @saveY
                               {Port.send InspPort handleResize(@index @addDY)}
                               {@grip tk(conf relief: raised)}
                            end)}
         end
         meth draw
            Y = @y
         in
            {Tk.batch [place(@sash x: 0 y: (Y + 2) width: @xDim height: 4)
                       place(@grip x: (@xDim - 20) y: Y width: 8 height: 8)]}
         end
         meth undraw
            {Tk.batch [place(forget @sash) place(forget @grip)]}
         end
         meth setDimension(Y XDim YDim)
            {Tk.batch [place(conf @sash width: XDim)
                       place(conf @grip x: (XDim - 20))]}
         end
         meth setPosition(NY)
            {Tk.batch [place(conf @sash y: (NY + 2)) place(conf @grip y: NY)]}
         end
      end
\else
      class GuiSashGrip from FrameNode
         meth create(Parent XDim YDim)
            skip
         end
         meth draw
            skip
         end
         meth undraw
            skip
         end
         meth setDimension(Y XDim YDim)
            skip
         end
         meth setPosition(NY)
            skip
         end
      end
\endif

      class SashGrip from GuiSashGrip
         attr
            sash  %% Sash Line
            grip  %% Grip Button
            saveY %% Save Y Positon
            addDY %% DeltaY Sum
            minY  %% Maximal Y Upper Move
            maxY  %% Maximal Y Down Move
         prop
            final
         meth create(Parent XDim YDim)
            DXDim = (XDim - 2)
         in
            FrameNode, create(Parent DXDim 10)
            GuiSashGrip, create(Parent DXDim YDim)
            {Parent append(self)}
         end
         meth getType($)
            sashNode
         end
         meth tellNewXY(DeltaX DeltaY $)
            if DeltaX == 0
            then skip
            else
               XDim = (@xDim + DeltaX)
            in
               xDim <- XDim
               GuiSashGrip, setDimension(0 XDim 0)
            end
            0
         end
         meth moveY(Y)
            NY = (@y + Y)
         in
            y <- NY
            GuiSashGrip, setPosition(NY)
         end
         meth stopUpdate
            skip
         end
         meth setOptions(Options)
            skip
         end
         meth optionConfigure(O V)
            skip
         end
      end
   end
end
