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

functor $
import
   Tk(canvas font getTclName menu menuentry returnInt localize send text)
   System(eq show)
export
   'class' : GraphicSupport
define
   local
      BuildEntries        = {NewName}
      Transform           = {NewName}
      CreateEntries       = {NewName}
      CreateFilterEntries = {NewName}
      CreateActionEntries = {NewName}
   in
      class MenuClass
         attr
            type       %% Type Definition
            widPort    %% Widget Port
            object     %% Msg Receiver
            menu       %% TkMenu Object
            font       %% Font
            color      %% FG Color
            mapEntries %% Entries in Mapstate
            menuData   %% MenuData List
         meth create(Visual Type MenuData)
            @type       = Type
            @widPort    = {Visual getServer($)}
            @object     = Visual
            @font       = {Visual get(widgetContextMenuFont $)}
            @color      = {Visual get(widgetContextMenuABg $)}
            @menu       = {New Tk.menu
                           tkInit(parent:  Visual
                                  tearoff: false)}
            @mapEntries = false|_|_
            @menuData   = MenuData
            MenuClass, BuildEntries(@menu MenuClass, Transform(Type MenuData $))
         end
         meth updateMenu(MenuData)
            if {System.eq @menuData MenuData}
            then skip
            else
               Visual = @object
               Menu   = {New Tk.menu
                         tkInit(parent:  Visual
                                tearoff: false)}
            in
               menu <- Menu
               MenuClass, BuildEntries(Menu MenuClass, Transform(@type MenuData $))
               case @mapEntries
               of true|_|_ then
                  Sep = MenuClass, addEntry(@menu separator $)
                  Fun = MenuClass, addEntry(@menu 'unmap'(unmap) $)
               in
                  mapEntries <- true|Sep|Fun
               else skip
               end
            end
         end
         meth !BuildEntries(Menu MDs)
            case MDs
            of Entry|MDr then
               _ = MenuClass, addEntry(Menu Entry $)
               MenuClass, BuildEntries(Menu MDr)
            else skip
            end
         end
         meth addEntry(Menu Entry $)
            Font = @font
         in
            case Entry
            of title(Name) then
               Title = {New Tk.menuentry.command
                        tkInit(parent: Menu
                               label:  Name
                               font:   Font
                               state:  disabled)}
            in
               _  = {New Tk.menuentry.separator tkInit(parent: Menu)}
               Title
            [] separator   then {New Tk.menuentry.separator tkInit(parent: Menu)}
            [] cascade(Es) then
               case Es
               of title(Title)|Er then
                  SubMenu = {New Tk.menu
                             tkInit(parent:  Menu
                                    tearoff: false)}
                  Cascade = {New Tk.menuentry.cascade
                             tkInit(parent: Menu
                                    label:  Title
                                    font:   Font
                                    menu:   SubMenu)}
               in
                  case Er
                  of nil then {Cascade tk(entryconf state: disabled)}
                  else MenuClass, BuildEntries(SubMenu Er)
                  end
                  Cascade
               end
            else
               Mesg = Entry.1
            in
               {New Tk.menuentry.command
                tkInit(parent:           Menu
                       label:            {Label Entry}
                       font:             Font
                       activebackground: @color
                       action:           proc {$}
                                            {Port.send @widPort call(@object Mesg)}
                                         end)}
            end
         end
         meth !Transform(Type MenuData $)
            case MenuData
            of menu(Ws Ds Fs As) then
               WidthSkel  = MenuClass, CreateEntries(Ws 'Width ' changeWidth $)
               DepthSkel  = MenuClass, CreateEntries(Ds 'Depth ' changeDepth $)
               FilterSkel = MenuClass, CreateFilterEntries(Fs $)
               ActionSkel = MenuClass, CreateActionEntries(As $)
            in
               [title({VirtualString.toAtom Type#' Menu'})
                cascade([title('Exlore Tree')
                         cascade(title('Width')|WidthSkel)
                         cascade(title('Depth')|DepthSkel)])
                cascade(title('Filter')|FilterSkel)
                cascade(title('Actions')|ActionSkel)]
            else MenuData
            end
         end
         meth !CreateEntries(Ws Prefix Fun ?Rs)
            case Ws
            of WVal|Wr then
               Tail
            in
               case WVal
               of 0 then Rs = separator|Tail
               else
                  TitleInd = if WVal < 0 then '-' else '+' end
                  Title    = {VirtualString.toAtom Prefix#TitleInd#{Abs WVal}}
               in
                  Rs = (Title(Fun(WVal)))|Tail
               end
               MenuClass, CreateEntries(Wr Prefix Fun Tail)
            else Rs = nil
            end
         end
         meth !CreateFilterEntries(Fs Rs)
            case Fs
            of Filter|Fr then
               TF = case Filter of auto(TF) then TF else Filter end
               TL = {Label TF}
               Tail
            in
               Rs = (TL(map(TF.1)))|Tail
               MenuClass, CreateFilterEntries(Fr Tail)
            else Rs = nil
            end
         end
         meth !CreateActionEntries(As Rs)
            case As
            of Action|Ar then
               AL = {Label Action} Tail
            in
               Rs = (AL(action(Action.1)))|Tail
               MenuClass, CreateActionEntries(Ar Tail)
            else Rs = nil
            end
         end
         meth tkMenu($)
            @menu
         end
         meth map
            case @mapEntries
            of Value|_|_ then
               if Value
               then skip
               else
                  Sep = MenuClass, addEntry(@menu separator $)
                  Fun = MenuClass, addEntry(@menu 'unmap'(unmap) $)
               in
                  mapEntries <- true|Sep|Fun
               end
            end
         end
         meth unmap
            case @mapEntries
            of Value|Sep|Fun then
               if Value
               then {Sep tkClose} {Fun tkClose} mapEntries <- false|_|_
               end
            end
         end
      end
   end

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

      IdCounter           = {New Counter create} %% Only used for canvas creation

      GlobalCanvasHandler = {NewName}
      SearchNode          = {NewName}
      HandleEvent         = {NewName}
      GetMenu             = {NewName}
      ComputeFontDim      = {NewName}

      InitValues = [canvasPrint|'CP' canvasPaint|'CT' canvasMove|'CM' canvasDelete|'CD'
                    canvasPlace|'CS' canvasRDraw|'CR' canvasRMove|'CL'
                    canvasUp|'Up' canvasDn|'Dn' canvasMCV|'MC' canvasACV|'AC'
                    canvasCSp|'SS' canvasMSp|'MS']
   in
      class GraphicSupport from Tk.canvas
         attr
            canvasId       %% Local Canvas Id
            canvasPrint    %% Tcl Print Procecure
            canvasPaint    %% Tcl Bitmap Paint Procedure
            canvasMove     %% Tcl Move Procedure
            canvasDelete   %% Tcl Delete Procedure
            canvasPlace    %% Tcl Placement Procedure
            canvasRDraw    %% Tcl Rectangle Draw Procedure
            canvasRMove    %% Tcl Rectangle Move Procedure
            canvasUp       %% Tcl Tag Tree Up Procedure
            canvasDn       %% Tcl Tag Tree Down Procedure
            canvasMCV      %% Tcl MoveCanvasView Procedure
            canvasACV      %% Tcl AdjustCanvasView Procedure
            canvasCSp      %% Tcl Create Separator Procedure
            canvasMSp      %% Tcl Move Separator Procedure
            canvasName     %% Canvas Tcl Name (getTclName)
            tagVar         %% Canvas Tag Variable
            tagCount       %% Tag Counter
            font     : nil %% Fontname
            fontO          %% Tk Font Object
            fontX          %% Font X Dimension
            fontY          %% Font Y Dimension
            offY           %% Y Offset due to Separators
            fAscent        %% Font Ascent
            curCX          %% Current Canvas X Dimension
            curCY          %% Current Canvas Y Dimension
            nIndex         %% SubNode MenuIndex
            object         %% Current W/D Menu related Node
            menuDict       %% TkMenu Dictionary
            isMapped       %% Menu Mapping State
            ftw            %% Font XY Dimension Test Widget
         meth create(Parent DspWidth DspHeight)
            CanvasId = {IdCounter inc($)}
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
            @tagCount   = 0
            @menuDict   = {Dictionary.new}
            @ftw        = {New Tk.text
                           tkInit(parent:Parent
                                  width:1 height:1 bd:0
                                  exportselection:0 highlightthickness:0
                                  padx:0 pady:0 selectborderwidth:0
                                  spacing1:0 spacing2:0 spacing3:0)}
            {ForAll InitValues proc {$ V}
                                  case V of K|N then @K = {VirtualString.toAtom N#CanvasId#' '} end
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
            if Font \= @font then GraphicSupport, ComputeFontDim(Font Bitmap) end
            GraphicSupport, GlobalCanvasHandler(adjust(W H))
         end
         meth !ComputeFontDim(Font Bitmap)
            if {System.eq Font @font}
            then skip
            elsecase Font
            of font(family: Fam size: SZ weight: WS) then
               CanvasName = @canvasName
               FontO      = {New Tk.font tkInit(family: Fam size: SZ weight: WS)}
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
               GraphicSupport, adjustFonts(1 0)
            end
         end
         meth adjustFonts(I Y)
            if I =< @maxPtr
            then
               Node = {Dictionary.get @nodes I}
            in
               GraphicSupport, resetTags(I)
               {Node undraw}
               case {Node drawY(0 Y $)}
               of NewY then
                  GraphicSupport, moveLine({Dictionary.get @lines I} NewY)
                  GraphicSupport, adjustFonts((I + 1) NewY)
               end
            end
         end
         meth initButtonHandler
            WidPort = {self getServer($)}
         in
            Tk.canvas, tkBind(event:  '<3>'
                              args:   [int(x) int(y)]
                              action: proc {$ X Y}
                                         {Port.send WidPort GlobalCanvasHandler(menu(X Y))}
                                      end)
            Tk.canvas, tkBind(event:  '<Configure>'
                              args:   [int(w) int(h)]
                              action: proc {$ W H}
                                         {Port.send WidPort GlobalCanvasHandler(adjust(W H))}
                                      end)
         end
         meth !GlobalCanvasHandler(Event)
            case Event
            of menu(X Y) then
               CX = Tk.canvas, tkReturnInt(canvasx(X) $) div @fontX
               CY = Tk.canvas, tkReturnInt(canvasy(Y) $) div @fontY
            in
               case GraphicSupport, SearchNode(1 0 0 CX CY $)
               of nil  then skip %% No valid Tree on that Position
               [] Node then GraphicSupport, HandleEvent(Node X Y)
               end
            [] adjust(W H) then
               curCX <- W
               curCY <- H
               offY  <- ({Max (@maxPtr - 1) 0} * 3)
               GraphicSupport, adjustCanvasView
            end
         end
         meth !SearchNode(I XA YA X Y $)
            Node = {Dictionary.get @nodes I}
         in
            case {Node getXYDim($)}
            of XDim|YDim then
               XM = (XA + XDim)
               YM = (YA + YDim)
            in
               if X >= XA andthen X < XM andthen Y >= YA andthen Y < YM
               then {Node searchNode(XA YA X Y $)}
               elseif I < @maxPtr
               then GraphicSupport, SearchNode((I + 1) XA YM X Y $)
               else nil
               end
            end
         end
         meth !HandleEvent(Node X Y)
            case {Node getMenuType($)}
            of Type|Object then
               case GraphicSupport, GetMenu(Type $)
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
         meth getMenuType($)
            inspector|_
         end
         meth !GetMenu(Type $)
            MenuDict = @menuDict
            MenuData = {Dictionary.condGet @opDict {VirtualString.toAtom Type#'Menu'} nil}
         in
            case {Dictionary.condGet MenuDict Type nil}
            of nil then
               case MenuData
               of nil then nil
               else
                  Menu = {New MenuClass create(self Type MenuData)}
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
         meth drawRectangle(X Y Tag XYDim Dirty)
            case XYDim
            of XDim|YDim then
               FX = @fontX
               FY = @fontY
               OY = @offY
               X1 = (X * FX)
               Y1 = ((Y * FY) + OY)
               X2 = (((X + XDim) * FX) + 1)
               Y2 = (((Y + YDim) * FY) + OY + 1)
            in
               if Dirty
               then
                  FillCol = {Dictionary.get @colDict proxy}
               in
                  {Tk.send v(@canvasRDraw#X1#' '#Y1#' '#X2#' '#Y2#' '#FillCol#' '#Tag)}
               else {Tk.send v(@canvasRMove#X1#' '#Y1#' '#X2#' '#Y2#' '#Tag)}
               end
            end
         end
         meth getFontData($)
            @fontX|@fontY
         end
         meth move(X Y Tag FTag)
            {Tk.send v(@canvasMove#(@fontX * X)#' '#((@fontY * Y) + @offY)#' '#Tag#' '#FTag)}
         end
         meth place(X Y Tag)
            {Tk.send v(@canvasPlace#(@fontX * X)#' '#((@fontY * Y) + @offY)#' '#Tag)}
         end
         meth doublePlace(X Y XD Tag SecTag)
            CanvasPlace = @canvasPlace
            FontX       = @fontX
            YPos        = ((@fontY * Y) + @offY)
         in
            {Tk.send v(CanvasPlace#' '#(FontX * X)#' '#YPos#' '#Tag#';'#CanvasPlace#' '#
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
            MaxY = ((@curY * @fontY) + @offY)
            NewY = MaxY div @curCY
         in
            {Tk.send v(@canvasMCV#(@maxX * @fontX)#' '#MaxY#' '#NewY#';F0')}
         end
         meth adjustCanvasView
            {Tk.send v(@canvasACV#(@maxX * @fontX)#' '#((@curY * @fontY) + @offY#';F0'))}
         end
         meth enableStop
            {Tk.send v('O0')}
         end
         meth disableStop
            {Tk.send v('F0')}
         end
      end
   end
end
