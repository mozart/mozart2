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
%%% Tiny Window Manager based on TK Place Geometry Manager
%%%

%% Basic Toplevel Widget

class WinToplevel
   from
      BaseObject

   attr
      visible : true %% Tk Toplevel is visible
      toplevel       %% TK Toplevel Window
      frame          %% TK Widget Container
      items          %% Internal Items
      maxPtr         %% Current Items Count
      divCount       %% Item Division Counter
      width          %% Current Width
      height         %% Current Height

   meth create(Width Height Title)
      Toplevel = @toplevel
      Frame    = @frame
   in
      Toplevel = {New Tk.toplevel
                  tkInit(title:  Title
                         width:  Width
                         height: Height)}

      Frame    = {New Tk.frame
                  tkInit(parent:            Toplevel
                         width:             Width
                         height:             Height
                         borderwidth:        0
                         highlightthickness: 0)}

      {Frame tkBind(event:  '<Configure>'
                    args:   [int(w) int(h)]
                    action: proc {$ W H}
                                  {Server configure(W H)}
                            end)}

      {Frame tkBind(event: '<Enter>'
                    action: proc {$}
                               {Server enterFocus}
                            end)}

      @items    = {Dictionary.new}
      @maxPtr   = 0
      @divCount = 0
      @width    = Width
      @height   = Height

      {Tk.batch [place(Frame
                       x:         0
                       y:         0
                       anchor:    nw
                       relwidth:  1.0
                       relheight: 1.0)]}
   end

   meth hide
      if  @visible then
         {Tk.send wm(withdraw @toplevel)}
         visible <- false
      end
   end

   meth unhide
      if @visible
      then skip
      else
         {Tk.send wm(deiconify @toplevel)}
         visible <- true
      end
   end

   meth getFrame($)
      @frame
   end

   meth getWidth($)
      @width
   end

   meth getHeight($)
      @height
   end

   meth getNThElement(I $)
      {Dictionary.get @items I}
   end

   meth append(X WinObject)
      OldMax = @maxPtr
      MaxPtr = (OldMax + 1)
      Y      = WinToplevel, calcYPos(OldMax 0 $)
   in
      {Dictionary.put @items MaxPtr WinObject}
      {WinObject setIndex(MaxPtr)}
      case MaxPtr
      of 2 then {WinObject setXYPos(X (Y - 1))}
      else {WinObject setXYPos(X Y)}
      end
      {WinObject draw}
      maxPtr <- MaxPtr
   end

   meth incDivCount
      divCount <- (@divCount + 1)
   end

   meth decDivCount
      divCount <- (@divCount - 1)
   end

   meth calcYPos(I A $)
      case I
      of 0 then A
      else
         Node   = {Dictionary.get @items I}
         _|YDim = {Node getXYDim($)}
      in
         WinToplevel, calcYPos((I - 1) (A + YDim) $)
      end
   end

   meth configure(W H)
      DeltaX = (W - @width)
      DeltaY = (H - @height)
   in
      if DeltaX == 0 andthen DeltaY == 0
      then skip
      else
         DivCount = @divCount
      in
         width  <- W
         height <- H
         case DivCount
         of 0 then WinToplevel, tellNewXY(1 DeltaX 0)
         else WinToplevel, tellNewXY(1 DeltaX (DeltaY div DivCount))
         end
      end
   end

   meth tellNewXY(I DeltaX DeltaY)
      MaxPtr = @maxPtr
   in
      if I =< MaxPtr
      then
         Node      = {Dictionary.get @items I}
         ConsumedY = {Node tellNewXY(DeltaX DeltaY $)}
      in
         case ConsumedY
         of 0 then skip
         else WinToplevel, moveY((I + 1) ConsumedY)
         end
         WinToplevel, tellNewXY((I + 1) DeltaX DeltaY)
      else skip
      end
   end

   meth moveY(I DeltaY)
      if I =< @maxPtr
      then
         Node = {Dictionary.get @items I}
      in
         {Node moveY(DeltaY)}
         WinToplevel, moveY((I + 1) DeltaY)
      end
   end

   meth calcMinMax(Index $)
      Items  = @items
      NodeUp = {Dictionary.get Items (Index - 1)}
      NodeDn = {Dictionary.get Items (Index + 1)}
      MinY   = {NodeUp getMaxShrinkY($)}
      MaxY   = {NodeDn getMaxShrinkY($)}
   in
      MinY|MaxY
   end

   meth handleResize(Index DeltaY)
      Items  = @items
      NodeUp = {Dictionary.get Items (Index - 1)}
      SGrip  = {Dictionary.get Items Index}
      NodeDn = {Dictionary.get Items (Index + 1)}
      ConsY
   in
      ConsY = {NodeUp tellNewXY(0 DeltaY $)}
      {NodeDn moveY(ConsY)}
      {SGrip moveY(DeltaY)}
      _ = {NodeDn tellNewXY(0 ~DeltaY $)}
   end
end

%% Basic Window Widget

class WinNode
   from
      BaseObject

   attr
      top   %% WinToplevel
      index %% Toplevel Index
      node  %% TK Node
      x     %% X Position
      y     %% Y Position
      xDim  %% X Dimension
      yDim  %% Y Dimension

   meth create(Toplevel XDim YDim)
      @top  = Toplevel
      @xDim = XDim
      @yDim = YDim
   end

   meth getType($)
      winNode
   end

   meth setIndex(Index)
      index <- Index
   end

   meth getIndex($)
      @index
   end

   meth draw
      {Tk.batch [place(@node
                       x:      @x
                       y:      @y
                       width:  @xDim
                       height: @yDim
                       anchor: nw)]}
   end

   meth undraw
      {Tk.batch [place(forget @node)]}
   end

   meth getXYPos($)
      @x|@y
   end

   meth setXYPos(X Y)
      x <- X
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

   meth tellNewXY(DeltaX DeltaY $)
      XDim = (@xDim + DeltaX)
      YDim = (@yDim + DeltaY)
   in
      xDim <- XDim
      yDim <- YDim
      {Tk.batch [place(configure @node
                       width:  XDim
                       height: YDim)]}
      DeltaY
   end

   meth moveY(Y)
      NY = (@y + Y)
   in
      y <- NY
      {Tk.batch [place(configure @node y: NY)]}
   end
end

%% Topline MenuWidget

class MenuNode
   from
      WinNode

   meth create(Toplevel XDim YDim)
      WinNode, create(Toplevel XDim YDim)
      {self createMenu}
      {Toplevel append(0 self)}
   end

   meth getType($)
      menuNode
   end

   meth tellNewXY(DeltaX DeltaY $)
      XDim = (@xDim + DeltaX)
   in
      xDim <- XDim
      {Tk.batch [place(configure @node width: XDim)]}
      0
   end

   meth createMenu
      skip
   end
end

%% InspectorMenuNode

class InspectorMenuNode
   from
      MenuNode

   meth createMenu
      Node  = @node
      Frame = {@top getFrame($)}
   in
      Node = {TkTools.menubar Frame Frame
              [menubutton(text:      'Inspector'
                          menu: [command(label:   'About...'
                                         action:
                                         proc {$}
                                            {Server
                                             about(Node.inspector.about)}
                                         end
                                         feature: about)
                                 separator
                                 command(label:  'Iconify'
                                         action:  Server # iconify
                                         feature: iconify)
                                 command(label:   'Close'
                                          action:  Server # close
                                         feature: close)]
                          feature: inspector)
               menubutton(text: 'Options'
                          menu: [command(label:   'Preferences...'
                                         action:
                                            proc {$}
                                               {Server
                                                preferences(Node.options.preferences)}
                                            end
                                         feature: preferences)]
                          feature: options)]
              [menubutton(text: 'Help'
                          menu: [command(label:  'Inspector tutorial...'
                                         action:  Server # help
                                         feature: tutorial)]
                          feature: help)]}

      {Node tk(configure borderwidth: 1)}
      {Node tk(configure highlightthickness: 1)}
      {Wait {Tk.returnInt update(idletasks)}}
      yDim <- {Tk.returnInt winfo(reqheight Node)}
      {Node.inspector.menu tk(configure tearoff: false borderwidth: 1)}
      {Node.options.menu tk(configure tearoff: false borderwidth: 1)}
      {Node.help.menu tk(configure tearoff: false borderwidth: 1)}
   end

   meth draw
      {Tk.batch [place(@node
                       x:      @x
                       y:      @y
                       width:  @xDim
                       height: @yDim
                       anchor: nw)]}
   end
end

%% ButtonFrameNode

class ButtonFrameNode
   from
      WinNode

   attr
      moreB
      lessB
      stopB
      sW

   meth create(Toplevel XDim YDim GUIObj)
      TFrame = {Toplevel getFrame($)}
      Frame  = @node
      SW = @sW
      MW
   in
      WinNode, create(Toplevel (XDim - 2) YDim)
      Frame  = {New Tk.frame
                tkInit(parent: TFrame
                       width:              (XDim - 4)
                       height:             30
                       borderwidth:        1
                       relief:             sunken
                       highlightthickness: 0)}

      @moreB = {New Tk.button
                tkInit(parent:      Frame
                       text:        'Add Pane'
                       font:        '-adobe-helvetica-medium-r-*-*-*-100-*'
                       foreground:  'green4'
                       takefocus:   0
                       borderwidth: 1
                       action:      Server # addPane)}
      @lessB = {New Tk.button
                tkInit(parent:      Frame
                       text:        'Del Pane'
                       font:        '-adobe-helvetica-medium-r-*-*-*-100-*'
                       foreground:  'red4'
                       takefocus:   0
                       borderwidth: 1
                       action:      Server # delPane)}
      @stopB = {New Tk.button
                tkInit(parent:      Frame
                       text:        'STOP'
                       font:        '-adobe-helvetica-medium-r-*-*-*-100-*'
                       foreground:  'red4'
                       takefocus:   0
                       borderwidth: 1
                       action:      Server # stopUpdate(1))}

      MW     = {Tk.returnInt winfo(reqwidth @moreB)}
      SW     = {Tk.returnInt winfo(reqwidth @stopB)}

      {Tk.batch [place(@moreB   x:1 y:2)
                 place(@lessB x:(3 + MW) y:2)
                 place(@stopB x:(XDim - 6 - SW) y: 2)]}

      yDim <- {Tk.returnInt winfo(reqheight Frame)}

      {Toplevel append(1 self)}
   end

   meth getType($)
      buttonFrameNode
   end

   meth tellNewXY(DeltaX DeltaY $)
      XDim = (@xDim + DeltaX)
   in
      xDim <- XDim
      {Tk.batch [place(configure @node width: XDim)
                 place(configure @stopB x: (XDim - 4 - @sW))]}
      0
   end
end

%% ScrollCanvasNode

class ScrollCanvasNode
   from
      WinNode

   attr
      canvas    %% Canvas
      scrollX   %% X Scrollbar
      scrollY   %% Y ScrollBar
      cWidth    %% Canvas Width
      cHeight   %% Canvas Height
      dHeight   %% Smallest Possible Height
      deltaVal  %% Delta Val
      focDim    %% Focus Dimension
      widget    %% Tree Widget
      freezeVar %% FreezeVar
      wObj      %% Widget Object (needed for Stop)
      wThread   %% Adapter Thread

   meth create(Toplevel XDim YDim)
      Frame          = {Toplevel getFrame($)}
      DspBackground  = 'ivory'    %% {OpMan get(canvasBackground $)}
%      ShowScroll     = true       %% {OpMan get(canvasScrollbar $)}
      BDeltaVal      = 4          %% Toplevel Delta + Focus Delta
      CWidth         = @cWidth
      CHeight        = @cHeight
      DeltaVal       = @deltaVal
      Canvas         = @canvas
      ScrollX        = @scrollX
      ScrollY        = @scrollY
   in
      WinNode, create(Toplevel XDim YDim)
      {Toplevel incDivCount}
      DeltaVal = (12 + BDeltaVal)
      @dHeight = (11 + DeltaVal)
      CWidth   = (XDim - DeltaVal)
      CHeight  = (YDim - DeltaVal)
      Canvas   = {New Tk.canvas
                  tkInit(parent:             Frame
                         width:              CWidth
                         height:             CHeight
                         background:         DspBackground
                         highlightthickness: 1
                         takefocus:          0
                         borderwidth:        0)}

      {Canvas tkBind(event: '<KeyPress-Tab>'
                     action: Server # focusDn(false))}

      {Canvas tkBind(event: '<Shift-KeyPress-Tab>'
                     action: Server # focusDn(true))}

      {Canvas tkBind(event: '<KeyPress-a>'
                     action: Server # addPane)}

      {Canvas tkBind(event: '<KeyPress-d>'
                     action: Server # delPane)}

      @focDim                  = 2
      @widget|(@wObj|@wThread) = {NewServer
                                  TrWidget create(Canvas CWidth CHeight)}
      {@widget setServer(@widget)}

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
      {Toplevel append(1 self)}
   end

   meth getType($)
      canvasNode
   end

   meth getWidget($)
      @widget
   end

   meth getThread($)
      @wThread
   end

   meth getCanvas($)
      @canvas
   end

   meth getCanvasXYDim($)
      @cWidth|@cHeight
   end

   meth display(Value)
      {@widget display(Value)}
   end

   meth stopUpdate
      {@wObj stopUpdate}
   end

   meth draw
      Canvas  = @canvas
      FocDim  = @focDim
      CWidth  = (@cWidth + FocDim)
      CHeight = (@cHeight + FocDim)
      X       = @x
      Y       = @y
      ScrDim  = 12
   in
      {Tk.batch [place(Canvas
                       x: X y: Y
                       width: CWidth height: CHeight
                       anchor: nw)
                 place(@scrollY
                       x: (X + CWidth) y: Y
                       width: ScrDim height: CHeight
                       anchor: nw)
                 place(@scrollX
                       x: X y: (Y + CHeight)
                       width: CWidth height: ScrDim
                       anchor: nw)]}
   end

   meth undraw
      Toplevel = @top
   in
      {Tk.batch [place(forget @canvas)
                 place(forget @scrollY)
                 place(forget @scrollX)]}
      {Toplevel decDivCount}
   end

   meth tellNewXY(DeltaX DeltaY $)
      X       = @x
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
      {Tk.batch [place(configure @canvas width: CWidth height: CHeight)
                 place(configure @scrollY
                       x: (X + CWidth) height: CHeight)
                 place(configure @scrollX y: (Y + CHeight) width: CWidth)]}
      DeltaY
   end

   meth moveY(Y)
      NY = (@y + Y)
   in
      y <- NY
      {Tk.batch [place(configure @canvas y: NY)
                 place(configure @scrollY y: NY)
                 place(configure @scrollX y: (NY + @cHeight))]}
   end

   meth getMaxShrinkY($)
      (@yDim - @dHeight)
   end

   meth freeze(FreezeVar)
      freezeVar <- FreezeVar
      {@widget freeze(FreezeVar)}
   end

   meth unfreeze
      @freezeVar = unit
   end

   meth terminate
      {Thread.terminate @wThread}
   end
end

%% SashGrip

class SashGrip
   from
      WinNode

   attr
      sash  %% Sash Line
      grip  %% Grip Button
      saveY %% Save Y Positon
      addDY %% DeltaY Sum
      minY  %% Maximal Y Upper Move
      maxY  %% Maximal Y Down Move

   meth create(Toplevel XDim YDim)
      Frame = {Toplevel getFrame($)}
      DXDim = (XDim - 2)
      Grip  = @grip
   in
      WinNode, create(Toplevel DXDim 10)
      @sash = {New Tk.frame
               tkInit(parent:             Frame
                      width:              DXDim
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
                              MinY|MaxY = {@top calcMinMax(@index $)}
                           in
                              saveY <- @y
                              addDY <- 0
                              minY  <- MinY
                              maxY  <- MaxY
                              {@grip tk(configure relief: sunken)}
                              {Tk.batch ['raise'(@sash)
                                         'raise'(@grip)]}
                           end)}

      {Grip tkBind(event: '<Button1-Motion>'
                   args: [int('Y')]
                   action: proc {$ Y}
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
                   action: proc {$ Y}
                              y <- @saveY
                              {Server handleResize(@index @addDY)}
                              {@grip tk(configure relief: raised)}
                           end)}

      {Toplevel append(1 self)}
   end

   meth getType($)
      sashNode
   end

   meth draw
      X = @x
      Y = @y
   in
      {Tk.batch [place(@sash
                       x: X y: (Y + 2)
                       width: @xDim height: 4)
                 place(@grip
                       x: (@xDim - 20) y: Y
                       width: 8 height: 8)]}
   end

   meth undraw
      {Tk.batch [place(forget @sash)
                 place(forget @grip)]}
   end

   meth tellNewXY(DeltaX DeltaY $)
      XDim = (@xDim + DeltaX)
   in
      xDim <- XDim
      {Tk.batch [place(configure @sash width: XDim)
                 place(configure @grip x: (@xDim - 20))]}
      0
   end

   meth moveY(Y)
      NY = (@y + Y)
   in
      y <- NY
      {Tk.batch [place(configure @sash y: (NY + 2))
                 place(configure @grip y: NY)]}
   end
end
