%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 2002
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
   System(eq show)
   GDK GTK GTKCANVAS
export
   'class' : GraphicSupport
   'menu'  : GtkMenu
define
   class GTKMenu from GTK.menu
      meth popup(X Y Time)
         GTK.menu, popup(unit unit unit unit 3 Time)
      end
   end

   %% Gtk Based Menu
   class GtkMenu
      attr
         menu   %% System Menu Handle
         visual %% Visual Object
      meth create(Parent Visual)
         @visual = Visual
         @menu   = {New GTKMenu new}
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
            Item = {New GTK.menuItem newWithLabel(Name)}
         in
            {Item setSensitive(0)}
            {Menu append(Item)}
            {Menu append({New GTK.menuItem new})}
            Item
         [] separator   then
            Separator = {New GTK.menuItem new}
         in
            {Menu append(Separator)} Separator
         [] cascade(Es) then
            case Es
            of title(Title)|Er then
               SubMenu = {New GtkMenu create(Menu @visual)}
               Cascade = {New GTK.menuItem newWithLabel(Title)}
            in
               {Cascade setSubmenu({SubMenu getMenu($)})}
               case Er
               of nil then {Cascade setSensitive(0)}
               else
                  {List.forAll Er proc {$ Item}
                                     {SubMenu addEntry(Item _)}
                                  end}
               end
               {Menu append(Cascade)}
               Cascade
            end
         else
            Visual = @visual
            WidPort = {Visual getServer($)}
            Mesg   = Entry.1
            Item   = {New GTK.menuItem newWithLabel({Label Entry})}
         in
            {Item signalConnect('activate'
                                proc {$ _}
                                   {Port.send WidPort call(Visual Mesg)}
                                end _)}
            {@menu append(Item)}
            Item
         end
      end
      meth deleteEntry(Menu)
         {Menu destroy}
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
      IdCounter = {New Counter create}

      %% Private Methods
      InternalCanvasView        = {NewName}
      InternalScroll            = {NewName}
      InternalAdjNew            = {NewName}
      InternalScrollCanvasEvent = {NewName}
      LoadImage                 = {NewName}
      StopUpdate                = {NewName}
      ReleaseUpdate             = {NewName}

      fun {MakeFont Family Size Weight}
         {VirtualString.toString
          "-*-"#Family#"-medium-r-"#Weight#"-*-"#Size#"-*-*-*-m-*-iso8859-1"}
      end

\ifndef INSPECTOR_GTK_SLOW
      local
         Tools= {{New GTKCANVAS.canvas noop} inspectorTools($)}
      in
         NewText    = Tools.text
         NewImage   = Tools.image
         UnwrapItem = Tools.unwrap
      end
\endif
   in
      class GraphicSupport from GTKCANVAS.canvas
         attr
            canvasId        %% Local Canvas Id
            tagVar          %% Canvas Tag Variable
            tagRoot         %% First Item In Tree List
            tagTree         %% Canvas Tag Tree List
            font     : nil  %% Fontname
            fontO           %% Tk Font Object
            curCX           %% Current Canvas X Dimension
            curCY           %% Current Canvas Y Dimension
            innerX          %% Current X Scroll Position
            innerY          %% Current Y Scroll Position
            menuDict        %% TkMenu Dictionary
            isMapped        %% Menu Mapping State
            selItem         %% selection Rectangle Item
            miscObj         %% GDK Misc Services Object
            imageObj        %% GDK Dummy Image Object
            textAnchor      %% Canvas Text Anchor
            lineStyle       %% Canvas Line Style
            blackColor      %% GDK Black Color
            whiteColor      %% GDK White Color
            scrollXAdj      %% GTK ScrollXAdjustment
            scrollYAdj      %% GTK ScrollYAdjustment
            scrollBars      %% GTK Scrollbars
            backgroundItem  %% Canvas Background Item
            imageDict       %% Canvas GDKImlibImage Item Dictionary
            stopButton      %% Stop Button
         meth create(Parent DspWidth DspHeight)
            CanvasId = {IdCounter inc($)}
            Root
         in
            %% We do need image support
            GTKCANVAS.canvas, new(true)
            GTKCANVAS.canvas, setUsize(DspWidth DspHeight)
            GTKCANVAS.canvas, setScrollRegion(0.0 0.0
                                              {Int.toFloat DspWidth}
                                              {Int.toFloat DspHeight})
            @scrollXAdj = GraphicSupport, InternalAdjNew(
                                             innerX
                                             0.0 0.0
                                             {Int.toFloat DspWidth}
                                             1.0
                                             {Int.toFloat DspWidth}
                                             {Int.toFloat DspWidth} $)
            @scrollYAdj = GraphicSupport, InternalAdjNew(
                                             innerY
                                             0.0
                                             0.0 {Int.toFloat DspHeight}
                                             1.0
                                             {Int.toFloat DspHeight}
                                             {Int.toFloat DspHeight} $)
            @canvasId        = CanvasId
            Root             = {self rootItem($)}
            @tagRoot         = Root
            @tagVar          = Root
            @tagTree         = [Root]
            @miscObj         = {New GDK.misc noop}
            @imageObj        = {New GDK.imlib noop}
            @menuDict        = {Dictionary.new}
            @textAnchor      = GTK.'ANCHOR_NW'
            @lineStyle       = GDK.'LINE_ON_OFF_DASH'
            @selItem         = unit
            @selTag          = unit % {self newTagItem($)}
            @blackColor      = {self itemColor('#000000' $)}
            @whiteColor      = {self itemColor('#ffffff' $)}
            @innerX          = 0.0
            @innerY          = 0.0
            @imageDict       = {Dictionary.new}
            @backgroundItem =
            {self newItem(rectangle(parent            : Root
                                    x1                : 0
                                    y1                : 0
                                    x2                : DspWidth
                                    y2                : DspHeight
                                    fill_color_gdk    : @whiteColor
                                    outline_color_gdk : @whiteColor
                                    width_pixels      : 0) $)}
         end
         meth setScrollbars(XScroll YScroll)
            @scrollBars = XScroll#YScroll
         end
         meth setEventWindow(Window StopButton)
            WidPort = @widPort
         in
            %% This imports the inspector stop button
            @stopButton = StopButton
            %% This is necessary to redirect the key events
            {Window
             signalConnect('event'
                           proc {$ [Event]}
                              case Event
                                 %% GDK_Left = 0xFF50
                              of 'GDK_KEY_PRESS'(keyval: 0xFF50 ...) then
                                 {Port.send WidPort
                                  globalCanvasHandler(scrollX(~1))}
                                 %% GDK_Right = 0xFF53
                              [] 'GDK_KEY_PRESS'(keyval: 0xFF53 ...) then
                                 {Port.send WidPort
                                  globalCanvasHandler(scrollX(1))}
                                 %% GDK_Up = 0xFF52
                              [] 'GDK_KEY_PRESS'(keyval: 0xFF52 ...) then
                                 {Port.send WidPort
                                  globalCanvasHandler(scrollY(~1))}
                                 %% GDK_Down = 0xFF54
                              [] 'GDK_KEY_PRESS'(keyval: 0xFF54 ...) then
                                 {Port.send WidPort
                                  globalCanvasHandler(scrollY(1))}
                                 %% GDK_Next = 0xFF56
                              [] 'GDK_KEY_PRESS'(keyval: 0xFF56 ...) then
                                 {Port.send WidPort
                                  globalCanvasHandler(scrollYP(1))}
                                 %% GDK_Prior = 0xFF55
                              [] 'GDK_KEY_PRESS'(keyval: 0xFF55 ...) then
                                 {Port.send WidPort
                                  globalCanvasHandler(scrollYP(~1))}
                              [] _ then skip
                              end
                           end _)}
         end
         meth resetTags(I)
            offY <- ((I - 1) * 3)
         end
         meth queryDB
            OpDict = @opDict
            Col    = {Dictionary.get OpDict backgroundColor}
            Font   = {Dictionary.get OpDict widgetTreeFont}
            Bitmap = {Dictionary.get OpDict widgetSepBitmap}
            ArgW   = {GTK.makeArg 'width' 0}
            ArgH   = {GTK.makeArg 'height' 0}
            Width Height
         in
            {self getv(1 ArgW)}
            Width = {GTK.getArg unit ArgW}
            {GTK.freeArg ArgW}
            {self getv(1 ArgH)}
            Height = {GTK.getArg unit ArgH}
            {GTK.freeArg ArgH}
            {self
             configureItem(@backgroundItem
                           options(fill_color_gdk : {self itemColor(Col $)}))}
            curCX <- Width
            if Font \= @font
            then GraphicSupport, computeFontDim(Font Bitmap)
            end
            {self globalCanvasHandler(adjust(Width Height))}
         end
         meth computeFontDim(Font Bitmap)
            if {System.eq Font @font}
            then skip
            elsecase Font
            of font(family: Fam size: SZ weight: WS) then
               FontO   = {New GDK.font load({MakeFont Fam SZ WS})}
               FHeight = ({FontO fontGetFieldAscent($)} +
                          {FontO fontGetFieldDescent($)})
               FWidth  = {@miscObj stringWidth(FontO "W" $)}
            in
               font  <- Font
               fontO <- {self unwrapItem(FontO $)}
               %% X/Y Dim of Fonts
               fontX <- FWidth
               fontY <- FHeight
               {self adjustFonts(1 nil)}
            end
         end
         meth initButtonHandler
            WidPort = @widPort
         in
            {self
             signalConnect('event'
                           proc {$ [Event]}
                              case Event
                              of 'GDK_BUTTON_PRESS'(button: 1 ...) then
                                 XP = {Float.toInt Event.x}
                                 YP = {Float.toInt Event.y}
                              in
                                 {Port.send WidPort
                                  globalCanvasHandler(select(XP YP))}
                              [] 'GDK_BUTTON_PRESS'(button: 3 ...) then
                                 XP = {Float.toInt Event.x}
                                 YP = {Float.toInt Event.y}
                              in
                                 {Port.send WidPort
                                  globalCanvasHandler(menu(XP#YP Event.time))}
                              [] 'GDK_2BUTTON_PRESS'(button: 2 ...) then
                                 XP = {Float.toInt Event.x}
                                 YP = {Float.toInt Event.y}
                              in
                                 {Port.send WidPort
                                  globalCanvasHandler(doublepress(XP YP))}
                              [] _ then skip
                              end
                           end _)}
         end
         meth getDataNode(XOrY TimeOrY $)
            BaseX = {Float.toInt @innerX}
            BaseY = {Float.toInt @innerY}
            NX NY CX CY
         in
            %% menu and select have different arguments
            case XOrY
            of X#Y then NX = X NY = Y
            else NX = XOrY NY = TimeOrY
            end
            %% Hm, it is necessrary to adjust the coordinates
            %% with the given offset. Otherwise the results are bad.
            CX = (BaseX + NX) div @fontX
            %% y needs to be font-offset-adjusted (later)
            CY = (BaseY + NY)
            if @maxPtr == 0
            then nil
            else {self searchNode(1 0 0 CX CY $)}
            end
         end
         meth handleEvent(Node XY Time)
            case {Node getMenuType($)}
            of Type|Object then
               case {self getContextMenu(Type $)}
               of nil  then skip %% No Menu defined
               [] Menu then
                  Index    = {Node getIndex($)}
                  IsMapped = {Object isMapped(Index $)}
                  GtkMenu  = {Menu tkMenu($)}
               in
                  case XY
                  of X#Y then
                     object <- Object
                     nIndex <- Index
                     if IsMapped then {Menu map} else {Menu unmap} end
                     {GtkMenu showAll}
                     {GtkMenu popup(X Y Time)}
                  end
               end
            end
         end
         meth newTag($)
            _
         end
         meth getTclId($)
            @canvasId
         end
         meth printXY(X Y String Tag ColorKey)
            Color = case {Dictionary.condGet @colDict ColorKey nil}
                    of nil then @blackColor
                    [] Str then {self itemColor(Str $)}
                    end
         in
            %% Place item in tree
\ifdef INSPECTOR_GTK_SLOW
            Tag = {self newItem(group(parent: @tagRoot) $)}
            {self
             newItem(text(parent         : Tag
                          text           : String
                          x              : (@fontX * X)
                          y              : ((@fontY * Y) + @offY)
                          anchor         : @textAnchor
                          font_gdk       : @fontO
                          fill_color_gdk : Color) _)}
\else
            Tag = {NewText @tagRoot String
                   (@fontX * X) ((@fontY * Y) + @offY) @fontO Color}
\endif
         end
         meth paintXY(X Y ImageName Tag _)
            Image  = GraphicSupport, LoadImage({String.toAtom ImageName} $)
            FontX  = @fontX
            FontY  = @fontY
            ImageX = {Max 0 ((2 * FontX) - 2)}
            ImageY = {Max 0 (FontY - 4)}
         in
            %% Place item in tree
\ifdef INSPECTOR_GTK_SLOW
            Tag = {self newItem(group(parent: @tagRoot) $)}
            {self newItem(image(parent : Tag
                                image  : Image
                                x      : (FontX * X)
                                y      : ((FontY * Y) + @offY)
                                width  : ImageX
                                height : ImageY
                                anchor : @textAnchor) _)}
\else
            Tag = {NewImage @tagRoot Image
                   (FontX * X) ((FontY * Y) + @offY) ImageX ImageY}
\endif
         end
         meth !LoadImage(ImageName $)
            ImageDict = @imageDict
            ImageObj  = {Dictionary.condGet ImageDict ImageName nil}
         in
            case ImageObj
            of nil then
\ifdef INSPECTOR_GTK_SLOW
               NewImage = {@imageObj loadImage(ImageName $)}
\else
               NewImage = {UnwrapItem {@imageObj loadImage(ImageName $)}}
\endif
            in
               {Dictionary.put ImageDict ImageName NewImage} NewImage
            [] ImageObj then ImageObj
            end
         end
         meth delete(Tag)
            {self destroyItem(Tag)}
         end
         meth rectangleDelete(TagAndItem $)
            case TagAndItem of Tag|_ then {self destroyItem(Tag)} end _
         end
         meth drawRectangle(X Y TagAndItem XYDim Dirty)
            case XYDim
            of XDim|YDim then
               FX = @fontX
               FY = @fontY
               OY = @offY
               X1 = ((X * FX) + 1)
               Y1 = (((Y * FY) + OY) + 1)
               X2 = (((X + XDim) * FX) - 1)
               Y2 = ((((Y + YDim) * FY) + OY) - 1)
            in
               if Dirty
               then
                  FillCol = {self itemColor({Dictionary.get @colDict proxy} $)}
                  Tag     = {self newItem(group(parent: @tagRoot) $)}
                  Item
               in
                  TagAndItem = Tag|Item
                  Item =
                  {self
                   newItem(rectangle(parent            : Tag
                                     x1                : X1
                                     y1                : Y1
                                     x2                : X2
                                     y2                : Y2
                                     fill_color_gdk    : FillCol
                                     outline_color_gdk : FillCol
                                     width_pixels      : 0) $)}
               elsecase TagAndItem
               of _|Item then
                  {self configureItem(Item options(x1 : {Int.toFloat X1}
                                                   y1 : {Int.toFloat Y1}
                                                   x2 : {Int.toFloat X2}
                                                   y2 : {Int.toFloat Y2}))}
               end
            end
         end
         meth move(X Y Tag FTag)
            {self moveItemTo(Tag (@fontX * X) ((@fontY * Y) + @offY))}
         end
         meth place(X Y Tag)
            {self moveItemTo(Tag (@fontX * X) ((@fontY * Y) + @offY))}
         end
         meth doublePlace(X Y XD Tag SecTag)
            FontX = @fontX
            X1Pos = (FontX * X)
            X2Pos = (FontX * (X + XD))
            YPos  = ((@fontY * Y) + @offY)
         in
            {self moveItemTo(Tag X1Pos YPos)}
            {self moveItemTo(SecTag X2Pos YPos)}
         end
         meth tagTreeDown(Tag)
            if {IsFree Tag}
            then Tag = {self newItem(group(parent: @tagRoot) $)}
            end
            tagRoot <- Tag
            tagTree <- Tag|@tagTree
         end
         meth tagTreeUp
            TagTree = @tagTree.2
         in
            tagRoot <- TagTree.1
            tagTree <- TagTree
         end
         meth createLine(T Y)
            XP = {Max @curCX (@maxX * @fontX)}
            YP = ((Y * @fontY) + @offY)
         in
            T = {self newItem(line(parent         : @tagVar
                                   points         : [0 YP XP YP]
                                   fill_color_gdk : @blackColor
                                   line_style     : @lineStyle
                                   width_pixels   : 1) $)}
         end
         meth moveLine(T Y)
            XP = {Max @curCX (@maxX * @fontX)}
            YP = ((Y * @fontY) + @offY)
         in
            {self configureItem(T options('points' : [0 YP XP YP]))}
         end
         meth !InternalCanvasView(Move)
            MaxX  = (@maxX * @fontX)
            MaxY  = ((@curY * @fontY) + @offY)
            CurCX = @curCX
            CurCY = @curCY
            NewX  = {Int.toFloat {Max CurCX MaxX}}
            NewY  = {Int.toFloat {Max CurCY MaxY}}
         in
            GTKCANVAS.canvas, setScrollRegion(0.0 0.0 NewX NewY)
            {self configureItem(@backgroundItem options(x2 : NewX y2 : NewY))}
            if Move
            then
               NewY = {Max 0 (MaxY - CurCY)}
            in
               innerY <- {Int.toFloat NewY}
               GTKCANVAS.canvas, scrollTo(0 NewY)
            end
            GraphicSupport, InternalScroll({Int.toFloat CurCX}
                                           {Int.toFloat CurCY}
                                           NewX NewY)
            GraphicSupport, disableStop
         end
         meth !InternalScroll(XDim YDim XMax YMax)
            FontX = {Int.toFloat @fontX}
            FontY = {Int.toFloat @fontY}
            AdjX  = GraphicSupport, InternalAdjNew(
                                       innerX
                                       @innerX 0.0 XMax FontX XDim XDim $)
            AdjY  = GraphicSupport, InternalAdjNew(
                                       innerY
                                       @innerY 0.0 YMax FontY YDim YDim $)
            Bars  = @scrollBars
         in
            if {IsFree Bars}
            then skip
            elsecase @scrollBars
            of XScroll#YScroll then
               {XScroll set('adjustment' AdjX)}
               {YScroll set('adjustment' AdjY)}
               {XScroll sliderUpdate}
               {YScroll sliderUpdate}
            end
         end
         meth !InternalAdjNew(Dim V1 V2 V3 V4 V5 V6 $)
            Adj = {New GTK.adjustment new(V1 V2 V3 V4 V5 V6)}
         in
            {Adj signalConnect('value_changed'
                               proc {$ _}
                                  {Port.send @widPort
                                   InternalScrollCanvasEvent(Dim Adj)}
                               end _)}
            Adj
         end
         meth !InternalScrollCanvasEvent(Dim Adj)
            XPos YPos
         in
            GraphicSupport, StopUpdate
            Dim <- {Adj adjustmentGetFieldValue($)}
            XPos = {Float.toInt @innerX}
            YPos = {Float.toInt @innerY}
            GTKCANVAS.canvas, scrollTo(XPos YPos)
            GraphicSupport, ReleaseUpdate
         end
         meth !StopUpdate
            GTKCANVAS.canvas, freeze
         end
         meth !ReleaseUpdate
            GTKCANVAS.canvas, thaw
         end
         meth moveCanvasView
            GraphicSupport, InternalCanvasView(true)
         end
         meth adjustCanvasView
            GraphicSupport, InternalCanvasView(false)
         end
         meth getXAdjustment($)
            @scrollXAdj
         end
         meth getYAdjustment($)
            @scrollYAdj
         end
         meth scrollCanvasX(XScroll)
%           {Tk.send v(@canvasName#' xvi scroll '#XScroll#' units')}
            skip
         end
         meth scrollCanvasY(YScroll)
%           {Tk.send v(@canvasName#' yvi scroll '#YScroll#' units')}
            skip
         end
         meth scrollCanvasYP(YScroll)
%           {Tk.send v(@canvasName#' yvi scroll '#YScroll#' pages')}
            skip
         end
         meth enableStop
            {@stopButton setSensitive(1)}
            GraphicSupport, StopUpdate
         end
         meth disableStop
            StopButton = @stopButton
         in
            if {IsFree StopButton}
            then skip
            else {StopButton setSensitive(0)}
            end
            GraphicSupport, ReleaseUpdate
         end
         meth drawSelectionRectangle(Node Fresh)
            FirstTag = {Node getFirstItem($)}
            TreeTag  = {Node getTag($)}
            RI       = {Node getSimpleRootIndex(0 $)}
            SelTag
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
                  GraphicSupport, StopUpdate
                  if Fresh
                  then
                     FC = {self
                           itemColor({Dictionary.get @colDict selection} $)}
                  in
                     %% Assoc selection rectangle with covered tree
                     SelTag  = {self newItem(group(parent : TreeTag) $)}
                     selTag  <- SelTag
                     selItem <-
                     {self
                      newItem(rectangle(parent            : SelTag
                                        x1                : X1
                                        y1                : Y1
                                        x2                : X2
                                        y2                : Y2
                                        fill_color_gdk    : FC
                                        outline_color_gdk : @blackColor
                                        width_pixels      : 0) $)}
                     %% Make it the lowest item within the spanned tree
                     {self lowerItem(SelTag 0)}
                     %% In case of a proxy node the rectangle must be raised
                     %% by one to cover the mapping rectangles
                     if {Node isProxy($)}
                     then {self raiseItem(SelTag 1)}
                     else skip
                     end
                  else
                     {self
                      configureItem(@selItem options(x1 : {Int.toFloat X1}
                                                     y1 : {Int.toFloat Y1}
                                                     x2 : {Int.toFloat X2}
                                                     y2 : {Int.toFloat Y2}))}
                  end
                  GraphicSupport, ReleaseUpdate
               end
            end
         end
         meth getTreeCoords(Tag I $)
            OffY = ((I - 1) * 3)
            X Y
         in
            {self itemGetPosition(Tag X Y)}
            offY <- OffY
            (X div @fontX)|((Y - OffY) div @fontY)
         end
      end
   end
end
