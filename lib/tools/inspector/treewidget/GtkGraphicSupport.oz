%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 2001
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

functor $
import
   Tk
   System(eq show)
   GDK    at 'x-oz://system/gtk/GDK.ozf'
   GTK    at 'x-oz://system/gtk/GTK.ozf'
   Canvas at 'x-oz://system/gtk/GTKCANVAS.ozf'
export
   'class' : GraphicSupport
define
   %% Gtk Based Menu
   class GtkMenu
      attr
         menu   %% System Menu Handle
         visual %% Visual Object
      meth create(Parent Visual)
         @visual = Visual
         @menu   = unit
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
         unit
      end
   end

   %% Gtk GraphicSupport
   local
      local
         N = {NewName}
      in
         class Counter
            attr
               !N
            prop
               final
               locking
            meth create
               @N = 0
            end
            meth inc($)
               lock %% Not needed for inspector but for other apps
                  N <- (@N + 1)
               end
            end
         end
      end

      %% Only used for canvas creation
      IdCounter           = {New Counter create}

      GlobalCanvasHandler = {NewName}
      SearchNode          = {NewName}
      HandleEvent         = {NewName}
      GetMenu             = {NewName}
      ComputeFontDim      = {NewName}

      local
         ParseObj = {New GDK.color noop}
         Map      = {New GDK.colormap getSystem}
      in
         fun {MakeColor Str}
            Color = {New GDK.color new(0 0 0)}
         in
            {ParseObj parse(Str Color _)}
            {Map allocColor(Color 0 1 _)}
            Color
         end
      end

      fun {MakeFont Fam Size Weight}
         {VirtualString.toString "-unknown-"#Fam#"-normal-r-"#Weight#
          "-*-*-"#Size#"0-*"}
      end
   in
      class GraphicSupport from Canvas.canvas
         attr
            canvasId        %% Local Canvas Id
            tagVar          %% Canvas Tag Variable
            tagTree         %% Canvas Tag Tree List
            font     : nil  %% Fontname
            fontO           %% Tk Font Object
            fontX           %% Font X Dimension
            fontY           %% Font Y Dimension
            offY            %% Y Offset due to Separators
            curCX           %% Current Canvas X Dimension
            curCY           %% Current Canvas Y Dimension
            nIndex          %% SubNode MenuIndex
            object          %% Current W/D Menu related Node
            menuDict        %% TkMenu Dictionary
            isMapped        %% Menu Mapping State
            selObject : nil %% Selection Object
            selItem         %% selection Rectangle Item
            selTag          %% Selection Rectangle Tag
            miscObj         %% GDK Misc Services Object
            groupType       %% Canvas Group Type
            textType        %% Canvas Text Type
            rectType        %% Canvas Rectangle Type
            imageType       %% Canvas Image Type
            textAnchor      %% Canvas Text Anchor
            blackColor      %% GDK Black Color
            whiteColor      %% GDK White Color
         meth create(Parent DspWidth DspHeight)
            CanvasId = {IdCounter inc($)}
            Root     = {self root($)}
         in
            Canvas.canvas, new
            Canvas.canvas, setUsize(DspWidth DspHeight)
            Canvas.canvas, setScrollRegion(0.0 0.0
                                           {Int.toFloat DspWidth}
                                           {Int.toFloat DspHeight})
            Canvas.canvas, scrollTo(0 0)
            @canvasId   = CanvasId
            @tagVar     = Root
            @tagTree    = [Root]
            @miscObj    = {New GDK.misc noop}
            @menuDict   = {Dictionary.new}
            @groupType  = {@tagVar getType($)}
            @textType   = {self textGetType($)}
            @rectType   = {self rectGetType($)}
            @imageType  = {self imageGetType($)}
            @textAnchor = GTK.'ANCHOR_NW'
            @selItem    = unit
            @selTag     = {self newTag($)}
            @blackColor = {MakeColor "#000000"}
            @whiteColor = {MakeColor "#ffffff"}
            {self newItem(Root @rectType
                          ["x1"#0.0
                           "y1"#0.0
                           "x2"#{Int.toFloat DspWidth - 100}
                           "y2"#{Int.toFloat DspHeight - 100}
                           "fill_color_gdk"#@whiteColor
                           "outline_color_gdk"#@blackColor
                           "width_pixels"#0] _)}
         end
         meth resetTags(I)
            offY <- ((I - 1) * 3)
         end
         meth queryDB
            OpDict = @opDict
            Col    = {Dictionary.get OpDict backgroundColor}
            Font   = {Dictionary.get OpDict widgetTreeFont}
            Bitmap = {Dictionary.get OpDict widgetSepBitmap}
            ArgW   = {GTK.makeArg "width" 0}
            ArgH   = {GTK.makeArg "height" 0}
            Width Height
         in
            {self getv(1 ArgW)}
            Width = {GTK.getArg unit ArgW}
            {GTK.freeArg ArgW}
            {self getv(1 ArgH)}
            Height = {GTK.getArg unit ArgH}
            {GTK.freeArg ArgH}
            %% Set BG COlor : Col
            curCX <- Width
            if Font \= @font
            then
               GraphicSupport, ComputeFontDim(Font Bitmap)
            end
            GraphicSupport, GlobalCanvasHandler(adjust(Width Height))
         end
         meth !ComputeFontDim(Font Bitmap)
            if {System.eq Font @font}
            then skip
            elsecase Font
            of font(family: Fam size: SZ weight: WS) then
               %% {Makefont Fam SZ WS}
               FontO = {New GDK.font load("-unknown-Lucida Console-normal-r-normal-*-*-140-*-*-m-*-microsoft-russian")}
               X Y
            in
               %% X/Y Dim of Fonts
               X = {@miscObj stringWidth(FontO "t" $)}
               Y = {@miscObj stringHeight(FontO "t" $)}
               font    <- Font
               fontO   <- FontO
               fontX   <- X
               fontY   <- Y
               GraphicSupport, adjustFonts(1 nil)
            end
         end
         meth adjustFonts(I Vs)
            if I =< @maxPtr
            then
               Node  = {Dictionary.get @nodes I}
               Value = {Node getValue($)}
            in
               {Node undraw}
               GraphicSupport, delete({Dictionary.get @lines I})
               GraphicSupport, adjustFonts((I + 1) Value|Vs)
            else
               {self resetAll}
               GraphicSupport, redisplay({Reverse Vs})
            end
         end
         meth redisplay(Vs)
            case Vs
            of Value|Vr then
               {self display(Value)}
               GraphicSupport, redisplay(Vr)
            [] nil then skip
            end
         end
         meth initButtonHandler
%           WidPort = {self getServer($)}
%        in
%           Tk.canvas, tkBind(event: '<1>'
%                             args:  [int(x) int(y)]
%                             action: proc {$ X Y}
%                                        {Port.send WidPort GlobalCanvasHandler(select(X Y))}
%                                     end)
%           Tk.canvas, tkBind(event: '<Double-Button-2>'
%                             args:  [int(x) int(y)]
%                             action: proc {$ X Y}
%                                        {Port.send WidPort GlobalCanvasHandler(doublepress(X Y))}
%                                     end)
%           Tk.canvas, tkBind(event:  '<3>'
%                             args:   [int(x) int(y)]
%                             action: proc {$ X Y}
%                                        {Port.send WidPort GlobalCanvasHandler(menu(X Y))}
%                                     end)
%           Tk.canvas, tkBind(event:  '<Configure>'
%                             args:   [int(w) int(h)]
%                             action: proc {$ W H}
%                                        {Port.send WidPort GlobalCanvasHandler(adjust(W H))}
%                                     end)
%           Tk.canvas, tkBind(event: '<KeyPress-Left>'
%                             action: proc {$}
%                                        {Port.send WidPort GlobalCanvasHandler(scrollX(~1))}
%                                     end)
%           Tk.canvas, tkBind(event: '<KeyPress-Right>'
%                             action: proc {$}
%                                        {Port.send WidPort GlobalCanvasHandler(scrollX(1))}
%                                     end)
%           Tk.canvas, tkBind(event: '<KeyPress-Up>'
%                             action: proc {$}
%                                        {Port.send WidPort GlobalCanvasHandler(scrollY(~1))}
%                                     end)
%           Tk.canvas, tkBind(event: '<KeyPress-Down>'
%                             action: proc {$}
%                                        {Port.send WidPort GlobalCanvasHandler(scrollY(1))}
%                                     end)
%           Tk.canvas, tkBind(event: '<KeyPress-Next>'
%                             action: proc {$}
%                                        {Port.send WidPort GlobalCanvasHandler(scrollYP(1))}
%                                     end)
%           Tk.canvas, tkBind(event: '<KeyPress-Prior>'
%                             action: proc {$}
%                                        {Port.send WidPort GlobalCanvasHandler(scrollYP(~1))}
%                                     end)
            skip
         end
         meth getDataNode(X Y $)
%           CX = Tk.canvas, tkReturnInt(canvasx(X) $) div @fontX
%           CY = Tk.canvas, tkReturnInt(canvasy(Y) $) %% y needs to be offset-adjusted (later)
%        in
%           if @maxPtr == 0 then nil else GraphicSupport, SearchNode(1 0 0 CX CY $) end
            unit
         end
         meth !GlobalCanvasHandler(Event)
            case Event
            of menu(X Y) then
               case GraphicSupport, getDataNode(X Y $)
               of nil  then skip %% No valid Tree on that Position
               [] Node then GraphicSupport, HandleEvent(Node X Y)
               end
            [] select(X Y) then
               case GraphicSupport, getDataNode(X Y $)
               of nil  then skip %% No valid Tree on that Position
               [] Node then
                  SelNode = {Node getSelectionNode($)}
               in
                  if {System.eq SelNode @selObject}
                  then skip
                  else
                     GraphicSupport, clearSelection
                     GraphicSupport, createSelection(SelNode)
                  end
               end
            [] doublepress(X Y) then
               case GraphicSupport, getDataNode(X Y $)
               of nil  then skip
               [] Node then
                  {{Dictionary.get @opDict pressHandler}
                   {Node getSelectionNode($)}}
               end
            [] adjust(W H) then
               curCX <- W
               curCY <- H
               offY  <- ({Max (@maxPtr - 1) 0} * 3)
               GraphicSupport, adjustLines(1 0)
               GraphicSupport, adjustCanvasView
            [] scrollX(Delta) then
               GraphicSupport, scrollCanvasX(Delta)
            [] scrollY(Delta) then
               GraphicSupport, scrollCanvasY(Delta)
            [] scrollYP(Delta) then
               GraphicSupport, scrollCanvasYP(Delta)
            end
         end
         meth !SearchNode(I XA YA X CY $)
            Node = {Dictionary.get @nodes I}
            Y    = (CY - ((I - 1) * 3)) div @fontY
         in
            case Node
            of nil then nil
            elsecase {Node getXYDim($)}
            of XDim|YDim then
               XM = (XA + XDim)
               YM = (YA + YDim)
            in
               if X >= XA andthen X < XM andthen Y >= YA andthen Y < YM
               then {Node searchNode(XA YA X Y $)}
               elseif I < @maxPtr
               then GraphicSupport, SearchNode((I + 1) XA YM X CY $)
               else nil
               end
            end
         end
         meth !HandleEvent(Node X Y)
%           case {Node getMenuType($)}
%           of Type|Object then
%              case GraphicSupport, GetMenu(Type $)
%              of nil  then skip %% No Menu defined
%              [] Menu then
%                 Index    = {Node getIndex($)}
%                 IsMapped = {Object isMapped(Index $)}
%                 RootX    = {Tk.returnInt winfo(rootx self)}
%                 RootY    = {Tk.returnInt winfo(rooty self)}
%              in
%                 object <- Object
%                 nIndex <- Index
%                 if IsMapped then {Menu map} else {Menu unmap} end
%                 {Tk.send tk_popup({Menu tkMenu($)} (RootX + X) (RootY + Y))}
%              end
%           end
            skip
         end
         meth getMenuType($)
            inspector|_
         end
         meth !GetMenu(Type $)
            MenuDict = @menuDict
            MenuData = {Dictionary.condGet @opDict
                        {VirtualString.toAtom Type#'Menu'} nil}
         in
            case {Dictionary.condGet MenuDict Type nil}
            of nil then
               case MenuData
               of nil then nil
               else
                  ContextMenu = {self get(widgetContextMenuClass $)}
                  Menu = {New ContextMenu create(self GtkMenu Type MenuData)}
               in
                  {Dictionary.put MenuDict Type Menu} Menu
               end
            [] Menu then {Menu updateMenu(MenuData)} Menu
            end
         end
         meth changeDepth(N)
            {@object modifyDepth(@nIndex N)}
         end
         meth changeWidth(N)
            {@object modifyWidth(@nIndex N)}
         end
         meth map(F)
            {@object map(@nIndex F)}
         end
         meth unmap
            {@object unmap}
         end
         meth isMapped(Index $)
            Node = {Dictionary.get @nodes Index}
         in
            {Node isProxy($)}
         end
         meth action(P)
            {@object action(@nIndex P)}
         end
         meth getVisualData($)
            self|@fontX|@fontY
         end
         meth getCanvas($)
            self
         end
         meth newTag($)
            {self newItem(@tagVar @groupType ["x"#0.0 "y"#0.0] $)}
         end
         meth getTclId($)
            @canvasId
         end
         meth printXY(X Y String Tag ColorKey)
            Color = case {Dictionary.condGet @colDict ColorKey nil}
                    of nil then @blackColor
                    [] Str then {MakeColor Str}
                    end
         in
            %% Place item in tree
            case @tagTree of RootTag|_ then {Tag reparent(RootTag)} end
            {self newItem(Tag @textType
                          ["text"#String
                           "x"#{Int.toFloat (@fontX * X)}
                           "y"#{Int.toFloat ((@fontY * Y) + @offY)}
                           "font"#@fontO
                           "anchor"#@textAnchor
                           "fill_color_gdk"#Color] _)}
         end
         meth paintXY(X Y Image Tag ColorKey)
            Color = case {Dictionary.condGet @colDict ColorKey nil}
                    of nil then @blackColor
                    [] Str then {MakeColor Str}
                    end
            ImageX = {Image imageGetFieldWidth($)}
            ImageY = {Image imageGetFieldHeight($)}
         in
            %% Place item in tree
            case @tagTree of RootTag|_ then {Tag reparent(RootTag)} end
            {self newItem(Tag @imageType
                          ["image"#Image
                           "x"#{Int.toFloat (@fontX * X)}
                           "y"#{Int.toFloat ((@fontY * Y) + @offY)}
                           "width"#{Int.toFloat ImageX}
                           "height"#{Int.toFloat ImageY}
                           "anchor"#@textAnchor] _)}
         end
         meth delete(Tag)
            {Tag closeItem}
         end
         meth drawRectangle(X Y Tag XYDim Dirty)
%           case XYDim
%           of XDim|YDim then
%              FX = @fontX
%              FY = @fontY
%              OY = @offY
%              X1 = ((X * FX) + 1)
%              Y1 = (((Y * FY) + OY) + 1)
%              X2 = ((X + XDim) * FX)
%              Y2 = (((Y + YDim) * FY) + OY)
%           in
%              if Dirty
%              then
%                 FillCol = {Dictionary.get @colDict proxy}
%              in
%                 {Tk.send v(@canvasRDraw#X1#' '#Y1#' '#X2#' '#Y2#' '#FillCol#' '#Tag)}
%              else {Tk.send v(@canvasRMove#X1#' '#Y1#' '#X2#' '#Y2#' '#Tag)}
%              end
%           end
            skip
         end
         meth getFontData($)
            @fontX|@fontY
         end
         meth move(X Y Tag FTag)
            skip
%           {Tk.send v(@canvasMove#(@fontX * X)#' '#((@fontY * Y) + @offY)#' '#Tag#' '#FTag)}
         end
         meth place(X Y Tag)
            XCur YCur
         in
            %% Tag only knows bounding box; since only NW anchor
            %% is used, this is ok.
            {Tag getBounds(0#XCur 0#YCur 0#_ 0#_)}
            {Tag move((X - XCur) (Y - YCur))}
         end
         meth doublePlace(X Y XD Tag SecTag)
            skip
%           CanvasPlace = @canvasPlace
%           FontX       = @fontX
%           YPos        = ((@fontY * Y) + @offY)
%        in
%           {Tk.send v(CanvasPlace#' '#(FontX * X)#' '#YPos#' '#Tag#';'#CanvasPlace#' '#
%                      (FontX * (X + XD))#' '#YPos#' '#SecTag)}
         end
         meth tagTreeDown(Tag)
            TagTree = @tagTree
         in
            case TagTree of RootTag|_ then {Tag reparent(RootTag)} end
            tagTree <- Tag|TagTree
         end
         meth tagTreeUp
            case @tagTree of _|Tr then tagTree <- Tr end
         end
         meth createLine(T Y)
%           T = GraphicSupport, newTag($)
%           {Tk.send v(@canvasCSp#@curCX#' '#((Y *  @fontY) + @offY + 1)#' '#T)}
            skip
         end
         meth moveLine(T Y)
%           {Tk.send v(@canvasMSp#@curCX#' '#((Y * @fontY) + @offY + 1)#' '#T)}
            skip
         end
         meth moveCanvasView
            MaxX = (@maxX * @fontX)
            MaxY = ((@curY * @fontY) + @offY)
            NewY = {Max 0 (MaxY - @curCY)}
         in
            {System.show 'dimension MX='#MaxX#'; MY='#MaxY#'; NewY='#NewY#'; CurCY='#@curCY}
            Canvas.canvas, setScrollRegion(0.0 0.0
                                           {Int.toFloat MaxX}
                                           {Int.toFloat MaxY})
%           Canvas.canvas, scrollTo(0 NewY)
         end
         meth adjustCanvasView
            MaxX = (@maxX * @fontX)
            MaxY = ((@curY * @fontY) + @offY)
         in
            Canvas.canvas, setScrollRegion(0.0 0.0
                                           {Int.toFloat MaxX}
                                           {Int.toFloat MaxY})
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
         meth adjustLines(I OldY)
            if I =< @maxPtr
            then
               NewY
            in
               case {{Dictionary.get @nodes I} getXYDim($)}
               of _|YDim then
                  NewY = (OldY + YDim)
                  offY <- ((I - 1) * 3)
                  GraphicSupport, moveLine({Dictionary.get @lines I} NewY)
               end
               GraphicSupport, adjustLines((I + 1) NewY)
            end
         end
         meth enableStop
%           {Tk.send v('O0')}
            skip
         end
         meth disableStop
%           {Tk.send v('F0')}
            skip
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
                     selItem <- {self newItem(SelTag @rectType
                                             ["x1"#{Int.toFloat X1}
                                              "y1"#{Int.toFloat Y1}
                                              "x2"#{Int.toFloat X2}
                                              "y2"#{Int.toFloat Y2}
                                              "fill_color_gdk"#FC
                                              "outline_color_gdk"#@blackColor
                                              "width_pixels"#0] $)}
                  else
                     {self configureItem(@selItem ["x1"#{Int.toFloat X1}
                                                   "y1"#{Int.toFloat Y1}
                                                   "x2"#{Int.toFloat X2}
                                                   "y2"#{Int.toFloat Y2}])}
                  end
                  %% Raise TreeTag over SelTag (to be done)
               end
            end
         end
         meth exportSelectionNode($)
            @selObject
         end
         meth getTreeCoords(Tag I $)
            OffY = ((I - 1) * 3)
            X Y
         in
            {Tag getBounds(0#X 0#Y 0#_ 0#_)}
            offY <-OffY
            (X div @fontX)|((Y - OffY) div @fontY)
         end
         meth createSelection(Node)
            HP = {Dictionary.get @opDict selectionHandler}
         in
            selObject <- Node
            {HP Node}
            GraphicSupport, drawSelectionRectangle(Node true)
         end
         meth adjustSelection
            case @selObject
            of nil  then skip
            [] Node then
               if {Node isDirty($)}
               then GraphicSupport, clearSelection
               else GraphicSupport, drawSelectionRectangle(Node false)
               end
            end
         end
         meth clearSelection
            HP = {Dictionary.get @opDict selectionHandler}
         in
            selObject <- nil
            {@selTag close}
            {HP nil}
         end
      end
   end
end
