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

\ifndef INSPECTOR_GTK_GUI
functor $
import
   Tk(canvas font getTclName menu menuentry returnInt localize send text)
   System(eq show)
export
   'class' : GraphicSupport
   'menu'  : TkMenu
define
   %% Tk Based Menu
   class TkMenu
      attr
         menu   %% System Menu Handle
         visual %% Visual Object
      meth create(Parent Visual)
         @visual = Visual
         @menu   = {New Tk.menu
                    tkInit(parent:  Parent
                           tearoff: false)}
      end
      meth getMenu($)
         @menu
      end
      meth getFont($)
         {@visual get(widgetContextMenuFont $)}
      end
      meth getColor($)
         {@visual get(widgetContextMenuABg $)}
      end
      meth addEntry(Entry $)
         Menu = @menu
      in
         case Entry
         of title(Name) then
            Title = {New Tk.menuentry.command
                     tkInit(parent: Menu
                            label:  Name
                            font:   {self getFont($)}
                            state:  disabled)}
         in
            _  = {New Tk.menuentry.separator tkInit(parent: Menu)}
            Title
         [] separator then
            {New Tk.menuentry.separator tkInit(parent: Menu)}
         [] cascade(Es) then
            case Es
            of title(Title)|Er then
               SubMenu = {New TkMenu create(Menu @visual)}
               Cascade = {New Tk.menuentry.cascade
                          tkInit(parent: Menu
                                 label:  Title
                                 font:   {self getFont($)}
                                 menu:   {SubMenu getMenu($)})}
            in
               case Er
               of nil then {Cascade tk(entryconf state: disabled)}
               else
                  {List.forAll Er proc {$ Item}
                                     {SubMenu addEntry(Item _)}
                                  end}
               end
               Cascade
            end
         else
            Visual = @visual
            Msg    = Entry.1
         in
            {New Tk.menuentry.command
             tkInit(parent:           Menu
                    label:            {Label Entry}
                    font:             {self getFont($)}
                    activebackground: {self getColor($)}
                    action:
                       proc {$}
                          {Port.send {Visual getServer($)} call(Visual Msg)}
                       end)}
         end
      end
      meth deleteEntry(Menu)
         {Menu tkClose}
      end
   end

   %% Tk GraphicSupport
   local
      InitValues =
      [canvasPrint|'CP' canvasPaint|'CT' canvasMove|'CM' canvasDelete|'CD'
       canvasPlace|'CS' canvasRDraw|'CR' canvasRMove|'CL'
       canvasUp|'Up' canvasDn|'Dn' canvasMCV|'MC' canvasACV|'AC'
       canvasCSp|'SS' canvasMSp|'MS']
   in
      class GraphicSupport from Tk.canvas
         attr
            canvasId        %% Local Canvas Id
            canvasPrint     %% Tcl Print Procecure
            canvasPaint     %% Tcl Bitmap Paint Procedure
            canvasMove      %% Tcl Move Procedure
            canvasDelete    %% Tcl Delete Procedure
            canvasPlace     %% Tcl Placement Procedure
            canvasRDraw     %% Tcl Rectangle Draw Procedure
            canvasRMove     %% Tcl Rectangle Move Procedure
            canvasUp        %% Tcl Tag Tree Up Procedure
            canvasDn        %% Tcl Tag Tree Down Procedure
            canvasMCV       %% Tcl MoveCanvasView Procedure
            canvasACV       %% Tcl AdjustCanvasView Procedure
            canvasCSp       %% Tcl Create Separator Procedure
            canvasMSp       %% Tcl Move Separator Procedure
            canvasName      %% Canvas Tcl Name (getTclName)
            tagVar          %% Canvas Tag Variable
            tagCount        %% Tag Counter
            font     : nil  %% Fontname
            fontO           %% Tk Font Object
            fontX           %% Font X Dimension
            fontY           %% Font Y Dimension
            offY            %% Y Offset due to Separators
            fAscent         %% Font Ascent
            curCX           %% Current Canvas X Dimension
            curCY           %% Current Canvas Y Dimension
            nIndex          %% SubNode MenuIndex
            object          %% Current W/D Menu related Node
            menuDict        %% TkMenu Dictionary
            isMapped        %% Menu Mapping State
            ftw             %% Font XY Dimension Test Widget
            selObject : nil %% Selection Object
            selTag          %% Selection Rectangle Tag
         meth create(Parent DspWidth DspHeight)
            CanvasId = {{self idCounter($)} inc($)}
         in
            Tk.canvas, tkInit(parent:             Parent
                              width:              DspWidth
                              height:             DspHeight
                              background:         white
                              highlightthickness: 1
                              takefocus:          0
                              borderwidth:        0)
            @canvasId   = CanvasId
            @canvasName = {Tk.getTclName self}
            @tagVar     = {VirtualString.toAtom 'Tg'#CanvasId}
            @tagCount   = 1
            @selTag     = 0
            @menuDict   = {Dictionary.new}
            @ftw        = {New Tk.text
                           tkInit(parent:Parent
                                  width:1 height:1 bd:0
                                  exportselection:0 highlightthickness:0
                                  padx:0 pady:0 selectborderwidth:0
                                  spacing1:0 spacing2:0 spacing3:0)}
            {ForAll InitValues proc {$ V}
                                  case V
                                  of K|N then
                                     @K = {VirtualString.toAtom N#
                                           CanvasId#' '}
                                  end
                               end}
            GraphicSupport, buildInterface
         end
         meth buildInterface
            CanvasName = @canvasName
            TagVar     = @tagVar
         in
            {Tk.send v('proc '#@canvasPaint#'{X Y C S G} {upvar #0 '#TagVar#' T;'#CanvasName#' cre bitmap $X $Y -anchor nw -foreground $C -bitmap @$S -tags [linsert $T 0 t$G]}')}
            {Tk.send v('proc '#@canvasMove#'{X Y T F} {if {[scan ['#CanvasName#' coo t$F] "%f%f" XR YR] == 2} {scan $XR "%d" OX;scan $YR "%d" OY;set DX [expr $X - $OX];set DY [expr $Y - $OY];if {$DX != 0 || $DY != 0} {'#CanvasName#' mo t$T $DX $DY}}}')}
            {Tk.send v('proc '#@canvasDelete#'{T} {'#CanvasName#' del t$T}')}
            {Tk.send v('proc '#@canvasPlace#'{X Y T} {'#CanvasName#' coo t$T $X $Y}')}
            {Tk.send v('proc '#@canvasRDraw#'{X Y XS YS C G} {upvar #0 '#TagVar#' T;'#CanvasName#' cre rectangle $X $Y $XS $YS -fill $C -outline "" -tags [linsert $T 0 t$G]}')}
            {Tk.send v('proc '#@canvasRMove#'{X Y XS YS T} {'#CanvasName#' coo t$T $X $Y $XS $YS}')}
            {Tk.send v('proc '#@canvasDn#'{G} {upvar #0 '#TagVar#' T;set T [linsert $T 0 t$G]}')}
            {Tk.send v('proc '#@canvasUp#'{} {upvar #0 '#TagVar#' T;set T [lreplace $T 0 0]}')}
            {Tk.send v('proc '#@canvasMCV#'{X Y F} {'#CanvasName#' conf -scrollregion [list 0 0 $X $Y];'#CanvasName#' yvi moveto $F;'#CanvasName#' xvi moveto 0}')}
            {Tk.send v('proc '#@canvasACV#'{X Y} {'#CanvasName#' conf -scrollregion [list 0 0 $X $Y]}')}
            {Tk.send v('proc '#@canvasMSp#'{X Y T} {'#CanvasName#' coo t$T 0 $Y $X $Y}')}
         end
         meth resetTags(I)
            offY <- ((I - 1) * 3)
            {Tk.send v('set '#@tagVar#' t')}
         end
         meth queryDB
            OpDict = @opDict
            Col    = {Dictionary.get OpDict backgroundColor}
            Font   = {Dictionary.get OpDict widgetTreeFont}
            Bitmap = {Dictionary.get OpDict widgetSepBitmap}
            W      = {Tk.returnInt winfo(reqwidth self)}
            H      = {Tk.returnInt winfo(reqheight self)}
         in
            Tk.canvas, tk(conf background: Col)
            curCX <- W
            if Font \= @font
            then GraphicSupport, computeFontDim(Font Bitmap)
            end
            {self globalCanvasHandler(adjust(W H))}
         end
         meth computeFontDim(Font Bitmap)
            if {System.eq Font @font}
            then skip
            elsecase Font
            of font(family: Fam size: SZ weight: WS) then
               CanvasName = @canvasName
               FontO      = {New Tk.font
                             tkInit(family: Fam size: SZ weight: WS)}
               FName      = {Tk.getTclName FontO}
               FTW        = @ftw
               X Y
            in
               {@ftw tk(conf font:FontO)}
               X = {Tk.returnInt winfo(reqwidth FTW)}
               Y = {Tk.returnInt winfo(reqheight FTW)}
               {Wait X} {Wait Y}
               font    <- Font
               fontO   <- FontO
               fontX   <- X
               fontY   <- Y
               fAscent <- {String.toInt {FontO tkReturnList(metrics $)}.2.1}
               {Tk.send v('proc '#@canvasPrint#'{X Y C S G} {upvar #0 '#@tagVar#' T;'#CanvasName#' cre text $X $Y -anchor nw -font '#FName#' -fill $C -text $S -tags [linsert $T 0 t$G]}')}
               {Tk.send v('proc '#@canvasCSp#'{X Y T} {'#CanvasName#' cre line 0 $Y $X $Y -fill black -stipple @'#Bitmap#' -tags t$T}')}
               {self adjustFonts(1 nil)}
            end
         end
         meth initButtonHandler
            WidPort = {self getServer($)}
         in
            Tk.canvas,
            tkBind(event: '<1>'
                   args:  [int(x) int(y)]
                   action: proc {$ X Y}
                              {Port.send WidPort
                               globalCanvasHandler(select(X Y))}
                           end)
            Tk.canvas,
            tkBind(event: '<Double-Button-2>'
                   args:  [int(x) int(y)]
                   action: proc {$ X Y}
                              {Port.send WidPort
                               globalCanvasHandler(doublepress(X Y))}
                           end)
            Tk.canvas,
            tkBind(event:  '<3>'
                   args:   [int(x) int(y)]
                   action: proc {$ X Y}
                              {Port.send WidPort globalCanvasHandler(menu(X Y))}
                           end)
            Tk.canvas,
            tkBind(event:  '<Configure>'
                   args:   [int(w) int(h)]
                   action: proc {$ W H}
                              {Port.send WidPort
                               globalCanvasHandler(adjust(W H))}
                           end)
            Tk.canvas,
            tkBind(event: '<KeyPress-Left>'
                   action: proc {$}
                              {Port.send WidPort
                               globalCanvasHandler(scrollX(~1))}
                           end)
            Tk.canvas,
            tkBind(event: '<KeyPress-Right>'
                   action: proc {$}
                              {Port.send WidPort
                               globalCanvasHandler(scrollX(1))}
                           end)
            Tk.canvas,
            tkBind(event: '<KeyPress-Up>'
                   action: proc {$}
                              {Port.send WidPort
                               globalCanvasHandler(scrollY(~1))}
                           end)
            Tk.canvas,
            tkBind(event: '<KeyPress-Down>'
                   action: proc {$}
                              {Port.send WidPort
                               globalCanvasHandler(scrollY(1))}
                           end)
            Tk.canvas,
            tkBind(event: '<KeyPress-Next>'
                   action: proc {$}
                              {Port.send WidPort
                               globalCanvasHandler(scrollYP(1))}
                           end)
            Tk.canvas,
            tkBind(event: '<KeyPress-Prior>'
                   action: proc {$}
                              {Port.send WidPort
                               globalCanvasHandler(scrollYP(~1))}
                           end)
         end
         meth getDataNode(X Y $)
            CX = Tk.canvas, tkReturnInt(canvasx(X) $) div @fontX
            %% y needs to be offset-adjusted (later)
            CY = Tk.canvas, tkReturnInt(canvasy(Y) $)
         in
            if @maxPtr == 0
            then nil
            else {self searchNode(1 0 0 CX CY $)}
            end
         end
         meth handleEvent(Node X Y)
            case {Node getMenuType($)}
            of Type|Object then
               case {self getContextMenu(Type $)}
               of nil  then skip %% No Menu defined
               [] Menu then
                  Index    = {Node getIndex($)}
                  IsMapped = {Object isMapped(Index $)}
                  RootX    = {Tk.returnInt winfo(rootx self)}
                  RootY    = {Tk.returnInt winfo(rooty self)}
               in
                  object <- Object
                  nIndex <- Index
                  if IsMapped then {Menu map} else {Menu unmap} end
                  {Tk.send tk_popup({Menu tkMenu($)} (RootX + X) (RootY + Y))}
               end
            end
         end
         meth newTag($)
            tagCount <- (@tagCount + 1)
         end
         meth getTclId($)
            @canvasId
         end
         meth printXY(X Y String Tag ColorKey)
            DrCol = {Dictionary.condGet @colDict ColorKey black}
         in
            {Tk.send v(@canvasPrint#(@fontX * X)#' '#((@fontY * Y) + @offY)#
                       ' '#DrCol#' "'#String#'" '#Tag)}
         end
         meth paintXY(X Y Image Tag ColorKey)
            DrCol = {Dictionary.get @colDict ColorKey}
         in
            {Tk.send v(@canvasPaint#(@fontX * X)#' '#((@fontY * Y) + @offY)#
                       ' '#DrCol#' '#Image#' '#Tag)}
         end
         meth delete(Tag)
            {Tk.send v(@canvasDelete#Tag)}
         end
         meth rectangleDelete(TagAndItem $)
            {Tk.send v(@canvasDelete#TagAndItem)} TagAndItem
         end
         meth drawRectangle(X Y Tag XYDim Dirty)
            case XYDim
            of XDim|YDim then
               FX = @fontX
               FY = @fontY
               OY = @offY
               X1 = ((X * FX) + 1)
               Y1 = (((Y * FY) + OY) + 1)
               X2 = ((X + XDim) * FX)
               Y2 = (((Y + YDim) * FY) + OY)
            in
               if Dirty
               then
                  FillCol = {Dictionary.get @colDict proxy}
               in
                  {Tk.send v(@canvasRDraw#X1#' '#Y1#' '#X2#' '#
                             Y2#' '#FillCol#' '#Tag)}
               else {Tk.send v(@canvasRMove#X1#' '#Y1#' '#X2#' '#Y2#' '#Tag)}
               end
            end
         end
         meth move(X Y Tag FTag)
            {Tk.send v(@canvasMove#(@fontX * X)#' '#
                       ((@fontY * Y) + @offY)#' '#Tag#' '#FTag)}
         end
         meth place(X Y Tag)
            {Tk.send v(@canvasPlace#(@fontX * X)#' '#
                       ((@fontY * Y) + @offY)#' '#Tag)}
         end
         meth doublePlace(X Y XD Tag SecTag)
            CanvasPlace = @canvasPlace
            FontX       = @fontX
            YPos        = ((@fontY * Y) + @offY)
         in
            {Tk.send v(CanvasPlace#' '#(FontX * X)#' '#YPos#' '#Tag#';'#
                       CanvasPlace#' '#
                       (FontX * (X + XD))#' '#YPos#' '#SecTag)}
         end
         meth tagTreeDown(Tag)
            {Tk.send v(@canvasDn#Tag)}
         end
         meth tagTreeUp
            {Tk.send v(@canvasUp)}
         end
         meth createLine(T Y)
            T = GraphicSupport, newTag($)
            {Tk.send v(@canvasCSp#@curCX#' '#((Y *  @fontY) + @offY + 1)#' '#T)}
         end
         meth moveLine(T Y)
            {Tk.send v(@canvasMSp#@curCX#' '#((Y * @fontY) + @offY + 1)#' '#T)}
         end
         meth moveCanvasView
            MaxX = (@maxX * @fontX)
            MaxY = ((@curY * @fontY) + @offY)
            NewY = MaxY div @curCY
         in
            {Tk.send v(@canvasMCV#MaxX#' '#MaxY#' '#NewY#';F0')}
         end
         meth adjustCanvasView
            MaxX = (@maxX * @fontX)
            MaxY = ((@curY * @fontY) + @offY)
         in
            {Tk.send v(@canvasACV#MaxX#' '#MaxY#';F0')}
         end
         meth scrollCanvasX(XScroll)
            {Tk.send v(@canvasName#' xvi scroll '#XScroll#' units')}
         end
         meth scrollCanvasY(YScroll)
            {Tk.send v(@canvasName#' yvi scroll '#YScroll#' units')}
         end
         meth scrollCanvasYP(YScroll)
            {Tk.send v(@canvasName#' yvi scroll '#YScroll#' pages')}
         end
         meth enableStop
            {Tk.send v('O0')}
         end
         meth disableStop
            {Tk.send v('F0')}
         end
         meth drawSelectionRectangle(Node Fresh)
            SelTag   = @selTag
            FirstTag = {Node getFirstItem($)}
            TreeTag  = {Node getTag($)}
            RI       = {Node getSimpleRootIndex(0 $)}
         in
            case GraphicSupport, getTreeCoords(FirstTag RI $)
            of X|Y then
               case {Node getXYDim($)}
               of XDim|YDim then
                  FX = @fontX
                  FY = @fontY
                  OY = @offY
                  X1 = ((X * FX) + 1)
                  Y1 = (((Y * FY) + OY) + 1)
                  X2 = ((X + XDim) * FX)
                  Y2 = (((Y + YDim) * FY) + OY)
               in
                  if Fresh
                  then
                     FC = {Dictionary.get @colDict selection}
                  in
                     {Tk.send v(@canvasName#' cre rectangle '#X1#' '#Y1#' '#
                                X2#' '#Y2#' -fill '#FC#' -tags t'#SelTag)}
                  else {Tk.send v(@canvasName#' coords t'#SelTag#' '#X1#' '#Y1#
                                  ' '#X2#' '#Y2)}
                  end
                  {Tk.send v(@canvasName#' raise t'#TreeTag#' t'#SelTag)}
               end
            end
         end
         meth getTreeCoords(Tag I $)
            case Tk.canvas, tkReturnListInt(coords t#Tag $)
            of [X Y] then
               OffY =  ((I - 1) * 3)
            in
               offY <-OffY
               (X div @fontX)|((Y - OffY) div @fontY)
            [] _     then nil %% This case must not happen
            end
         end
      end
   end
end
\else
\insert 'GtkGraphicSupport.oz'
\endif
