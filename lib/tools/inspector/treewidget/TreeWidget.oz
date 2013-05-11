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
   System(eq show)
   Name(newUnique) at 'x-oz://boot/Name'
   HelperComponent('nodes' : Helper) at 'Helper.ozf'
   TreeNodesComponent('nodes' : TreeNodes) at 'TreeNodes.ozf'
   StoreListenerComponent('class' : StoreListener) at 'StoreListener.ozf'
   RelationManagerComponent('class' : RelationManager) at 'RelationManager.ozf'
   GraphicSupportComponent('class': LowlevelSupport
                           'menu' : LowlevelMenu) at 'GraphicSupport.ozf'
export
   'class' : TreeWidget
   'nodes' : AllNodes
define
   %% Identify Reflection Constructs
   Wrapper = {Name.newUnique 'generic.reflected.value'}

   %% Create All Nodes Export Record
   AllNodes = {Record.adjoinAt TreeNodes.all 'helper' Helper}

   fun {HasSub Ss Sub}
      case Ss of _|Sr then Ss == Sub orelse {HasSub Sr Sub} else false end
   end
   fun {CutSub Ss Sub}
      if Ss == Sub then nil elsecase Ss of I|Sr then I|{CutSub Sr Sub} end
   end
   fun {FilterColor Ss}
      {HasSub Ss "Color"}
   end
   fun {FilterMenu Ss}
      {HasSub Ss "Menu"}
   end
   fun {IsUnbound V}
      {Value.isFree V} orelse {Value.isFuture V}
   end

   %%
   %% String related Stuff
   %%
   fun {IsOzString V W}
      if W == 0
      then true
      elseif {IsDet V}
      then
         case V
         of C|Vr then
            ({IsDet C} andthen {Char.is C}) andthen {IsOzString Vr (W - 1)}
         [] nil  then true
         [] _    then false %% This case is need for isAtomic
         else false
         end
      else false
      end
   end

   %%
   %% Abstract Context Menu
   %%
   local
      Transform           = {NewName}
      CreateEntries       = {NewName}
      CreateFilterEntries = {NewName}
      CreateActionEntries = {NewName}
   in
      class ContextMenu
         attr
            type       %% Type Definition
            object     %% Msg Receiver
            menu       %% TkMenu/GtkMenu Object
            menuClass  %% Menu Class
            mapEntries %% Entries in Mapstate
            menuData   %% MenuData List
            menuTitle  %% Menu Title
         meth create(Visual MenuClass Type MenuData)
            Menu = {New MenuClass create(Visual Visual)}
         in
            @type       = Type
            @object     = Visual
            @menu       = Menu
            @menuClass  = MenuClass
            @mapEntries = false|_|_
            @menuData   = MenuData
            @menuTitle  = {Visual get(widgetContextMenuTitle $)}
            %% Create All Menu Items (build the item list first)
            {List.forAll
             ContextMenu, Transform(Type MenuData $)
             proc {$ Item}
                {Menu addEntry(Item _)}
             end}
         end
         meth updateMenu(MenuData)
            if {System.eq @menuData MenuData}
            then skip
            else
               Visual = @object %% Object is Visual
               Menu   = {New @menuClass create(Visual Visual)}
            in
               menu <- Menu
               {List.forAll
                ContextMenu, Transform(@type MenuData $)
                proc {$ Item}
                   {Menu addEntry(Item _)}
                end}
               case @mapEntries
               of true|_|_ then
                  Sep = {Menu addEntry(separator $)}
                  Fun = {Menu addEntry('unmap'(unmap) $)}
               in
                  mapEntries <- true|Sep|Fun
               else skip
               end
            end
         end
         meth !Transform(Type MenuData $)
            case MenuData
            of menu(Ws Ds Fs As) then
               WSkel = ContextMenu, CreateEntries(Ws 'Width ' changeWidth $)
               DSkel = ContextMenu, CreateEntries(Ds 'Depth ' changeDepth $)
               FilterSkel = ContextMenu, CreateFilterEntries(Fs $)
               ActionSkel = ContextMenu, CreateActionEntries(As $)
            in
               [title({@menuTitle Type})
                cascade([title('Exlore Tree')
                         cascade(title('Width')|WSkel)
                         cascade(title('Depth')|DSkel)])
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
               ContextMenu, CreateEntries(Wr Prefix Fun Tail)
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
               ContextMenu, CreateFilterEntries(Fr Tail)
            else Rs = nil
            end
         end
         meth !CreateActionEntries(As Rs)
            case As
            of Action|Ar then
               AL = {Label Action} Tail
            in
               Rs = (AL(action(Action.1)))|Tail
               ContextMenu, CreateActionEntries(Ar Tail)
            else Rs = nil
            end
         end
         meth tkMenu($)
            {@menu getMenu($)}
         end
         meth map
            case @mapEntries
            of Value|_|_ then
               if Value
               then skip
               else
                  Sep = {@menu addEntry(separator $)}
                  Fun = {@menu addEntry('unmap'(unmap) $)}
               in
                  mapEntries <- true|Sep|Fun
               end
            end
         end
         meth unmap
            case @mapEntries
            of Value|Sep|Fun then
               if Value
               then
                  {@menu deleteEntry(Sep)}
                  {@menu deleteEntry(Fun)}
                  mapEntries <- false|_|_
               end
            end
         end
      end
   end

   %%
   %% GraphicSupport Abstract Class
   %%
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
   in
      class GraphicSupport from LowlevelSupport
         attr
            fontX           %% Font X Dimension
            fontY           %% Font Y Dimension
            offY            %% Y Offset due to Separators
            nIndex          %% SubNode MenuIndex
            object          %% Current W/D Menu related Node
            selTag          %% Selection Rectangle Tag
            selObject : nil %% Selection Object
         meth idCounter($)
            IdCounter
         end
         meth adjustFonts(I Vs)
            if I =< @maxPtr
            then
               Node  = {Dictionary.get @nodes I}
               Value = {Node getValue($)}
            in
               {Node undraw}
               LowlevelSupport, delete({Dictionary.get @lines I})
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
         meth getFontData($)
            @fontX|@fontY
         end
         meth globalCanvasHandler(Event)
            case Event
            of menu(X Y) then
               case LowlevelSupport, getDataNode(X Y $)
               of nil  then skip %% No valid Tree on that Position
               [] Node then LowlevelSupport, handleEvent(Node X Y)
               end
            [] select(X Y) then
               case LowlevelSupport, getDataNode(X Y $)
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
               case LowlevelSupport, getDataNode(X Y $)
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
               LowlevelSupport, adjustCanvasView
            [] scrollX(Delta) then
               LowlevelSupport, scrollCanvasX(Delta)
            [] scrollY(Delta) then
               LowlevelSupport, scrollCanvasY(Delta)
            [] scrollYP(Delta) then
               LowlevelSupport, scrollCanvasYP(Delta)
            end
         end
         meth searchNode(I XA YA X CY $)
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
               then GraphicSupport, searchNode((I + 1) XA YM X CY $)
               else nil
               end
            end
         end
         meth getMenuType($)
            inspector|_
         end
         meth getContextMenu(Type $)
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
                  Menu = {New ContextMenu
                          create(self LowlevelMenu Type MenuData)}
               in
                  {Dictionary.put MenuDict Type Menu} Menu
               end
            [] Menu then {Menu updateMenu(MenuData)} Menu
            end
         end
         meth createSelection(Node)
            HP = {Dictionary.get @opDict selectionHandler}
         in
            selObject <- Node
            {HP Node}
            LowlevelSupport, drawSelectionRectangle(Node true)
         end
         meth adjustSelection
            case @selObject
            of nil  then skip
            [] Node then
               if {Node isDirty($)}
               then GraphicSupport, clearSelection
               else LowlevelSupport, drawSelectionRectangle(Node false)
               end
            end
         end
         meth clearSelection
            HP = {Dictionary.get @opDict selectionHandler}
         in
            if @selObject == nil
            then skip
            else
               selObject <- nil
               GraphicSupport, delete(@selTag)
            end
            {HP nil}
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
                  LowlevelSupport, moveLine({Dictionary.get @lines I} NewY)
               end
               GraphicSupport, adjustLines((I + 1) NewY)
            end
         end
         meth exportSelectionNode($)
            @selObject
         end
      end
   end

   %%
   %% Main TreeWidget Class
   %%
   class TreeWidget from StoreListener GraphicSupport
      attr
         widPort       %% TreeWidget Port
         dMode         %% Display Mode (True: GraphMode / False TreeMode)
         dWidth        %% Display Width (Logical Expansion)
         dDepth        %% Display Depth (Locical Expansion)
         curY          %% Current Y Position
         maxX          %% Maxmimal X Dimension
         maxPtr        %% Current Node Counter
         nodes         %% Node Dictionary
         relManDict    %% Relation Manager Dictionary
         curRelMan     %% Current Relation Manager
         curDefRel     %% Current Default Relation
         stopPVar      %% Priv Stop Var (shields stop reactions)
         stopOVar      %% Open Stop Variable
         opDict        %% Option Dictionary
         colDict       %% Color Dictionary
         mapDict       %% Automap Function Dictionary
         lines         %% Separator Dictionary
         treeNodes     %% TreeWidget Node Container (fill (norm|rel)NodesDict)
         normNodesDict %% Normal Mode Nodes
         relNodesDict  %% Relation Mode Nodes
         relGlobal     %% Global Relation Mode
         globalRelMan  %% Global Relation Manager
         isAtomic      %% Atomic Test Function (must not be changed in Oz)
         showString    %% String Flag
         reflMan       %% Reflection Manager
      meth create(Options Parent DspWidth DspHeight)
         StoreListener, create
         GraphicSupport, create(Parent DspWidth DspHeight)
         @curY         = 0
         @maxX         = 0
         @maxPtr       = 0
         @relGlobal    = false
         @globalRelMan = nil
         @nodes        = {Dictionary.new}
         @relManDict   = {Dictionary.new}
         @lines        = {Dictionary.new}
         @reflMan      = {Dictionary.get Options widgetReflectMan}
         %% Tell Dictionary our Context Menu; Hack Alert
         {Dictionary.put Options widgetContextMenuClass ContextMenu}
         TreeWidget, setOptions(Options)
         GraphicSupport, initButtonHandler
      end
      meth resetAll
         curY         <- 0
         maxX         <- 0
         maxPtr       <- 0
         globalRelMan <- nil
         {Dictionary.removeAll @nodes}
         {Dictionary.removeAll @relManDict}
         {Dictionary.removeAll @lines}
         StoreListener, resetAll
      end
      meth setOptions(Options)
         ColDict    = {Dictionary.new}
         MapDict    = {Dictionary.new}
         Keys       = {Dictionary.keys Options}
         StringKeys = {Map Keys Atom.toString}
         Colors     = {Filter StringKeys FilterColor}
         Menus      = {Filter StringKeys FilterMenu}
      in
         case {Dictionary.get Options widgetNodeSets}.
            {Dictionary.get Options widgetUseNodeSet}
         of NSet|RSet then
            Nodes = case {Dictionary.get Options widgetNodesContainer}
                    of default   then TreeNodes
                    [] TreeNodes then TreeNodes
                    end
            fun {Fill D Key#Value}
               {Dictionary.put D Key Nodes.Value} D
            end
         in
            treeNodes     <- Nodes
            normNodesDict <- {FoldL NSet Fill {Dictionary.new}}
            relNodesDict  <- {FoldL RSet Fill {Dictionary.new}}
         end
         opDict  <- Options
         colDict <- ColDict
         mapDict <- MapDict
         TreeWidget, extractColors(Colors Options ColDict)
         TreeWidget, extractAutoMappings(Menus Options MapDict)
         TreeWidget, queryDB
      end
      meth optionConfigure(O V)
         OpDict = @opDict
      in
         {Dictionary.put OpDict O V}
         TreeWidget, setOptions(OpDict)
      end
      meth extractColors(Cs O D)
         case Cs
         of Key|Cr then
            FetchKey = {VirtualString.toAtom Key}
            PutKey   = {VirtualString.toAtom {CutSub Key "Color"}}
         in
            {Dictionary.put D PutKey {Dictionary.get O FetchKey}}
            TreeWidget, extractColors(Cr O D)
         else skip
         end
      end
      meth extractAutoMappings(Ms O D)
         case Ms
         of Key|Mr then
            FetchKey = {VirtualString.toAtom Key}
            PutKey   = {VirtualString.toAtom {CutSub Key "Menu"}}
            Filter   = case {Dictionary.get O FetchKey}
                       of menu(_ _ Fs _) then Fs else nil end
         in
            case TreeWidget, hasAuto(Filter $)
            of auto(F) then {Dictionary.put D PutKey F}
            else skip
            end
            TreeWidget, extractAutoMappings(Mr O D)
         else
            %% Add Default Sited Data Handler
            {Dictionary.put D Wrapper fun {$ V _ _}
                                         %% reflMan is synced
                                         {@reflMan getValue(V $)}
                                      end}
         end
      end
      meth hasAuto(Fs $)
         case Fs
         of Filter|Fr then
            case Filter
            of auto(FT) then auto(FT.1)
            else TreeWidget, hasAuto(Fr $)
            end
         else nil
         end
      end
      meth getOptions($)
         @opDict
      end
      meth queryDB
         OpDict = @opDict
      in
         dWidth     <- {Dictionary.get OpDict widgetTreeWidth}
         dDepth     <- {Dictionary.get OpDict widgetTreeDepth}
         dMode      <- {Not {Dictionary.get OpDict widgetTreeDisplayMode}}
         showString <- {Dictionary.get OpDict widgetShowStrings}
         isAtomic   <- case {Dictionary.get OpDict widgetAtomicTest}
                       of default then
                          fun {$ V}
                             TreeWidget, isAtomic(V $)
                          end
                       [] P then P
                       end
         curDefRel  <-
         TreeWidget, searchDefRel({Dictionary.get OpDict widgetRelationList} $)
         GraphicSupport, queryDB
      end
      meth searchDefRel(Rels $)
         case Rels
         of Rel|Rr then case Rel of auto(F) then F.1 else TreeWidget, searchDefRel(Rr $) end
         else System.eq
         end
      end
      meth set(Name Value)
         {Dictionary.put @opDict Name Value}
      end
      meth get(Name $)
         {Dictionary.get @opDict Name}
      end
      meth setColor(Name Value)
         {Dictionary.put @colDict Name Value}
      end
      meth getColor(Name $)
         {Dictionary.get @colDict Name}
      end
      meth setAuto(Type F)
         {Dictionary.put @mapDict Type F}
      end
      meth setServer(Port)
         @widPort = Port %% This must be assigned once only
      end
      meth getServer($)
         @widPort
      end
      meth getSimpleRootIndex(I $)
         TreeWidget, getRootIndex(I $)
      end
      meth collectTags(I Ts $)
         I|Ts
      end
      meth getRootIndex(I $)
         if @dMode
         then
            if @relGlobal
            then curRelMan <- @globalRelMan
            else
               RelManDict = @relManDict
               RelMan     = {Dictionary.condGet RelManDict I nil}
            in
               curRelMan <- case RelMan of nil then
                               NewRM = {New RelationManager create(@curDefRel)}
                            in
                               {Dictionary.put RelManDict I NewRM} NewRM
                            else RelMan
                            end
            end
         end
         I
      end
      meth notify
         skip
      end
      meth getType($)
         inspector
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
      meth graphMode($)
         @dMode
      end
      meth display(Value)
         MaxPtr = (@maxPtr + 1)
         Nodes  = @nodes
         CurY   = @curY
         StopVar Node
      in
         GraphicSupport, enableStop
         if @dMode
         then
            if @relGlobal
            then
               curRelMan <- case @globalRelMan
                            of nil then
                               {New RelationManager create(@curDefRel)}
                            [] CurRelMan then CurRelMan
                            end
            else
               RelMan = {New RelationManager create(@curDefRel)}
            in
               curRelMan <- RelMan
               {Dictionary.put @relManDict MaxPtr RelMan}
            end
         end
         stopPVar <- StopVar
         stopOVar <- StopVar
         maxPtr   <- MaxPtr
         Node = TreeWidget, treeCreate(Value self MaxPtr 0 $)
         {Dictionary.put Nodes MaxPtr Node}
         {Node layout}
         GraphicSupport, resetTags(MaxPtr)
         {Node draw(0 CurY)}
         case {Node getXYDim($)}
         of XDim|YDim then
            NewY = (CurY + YDim)
         in
            curY <- NewY
            maxX <- {Max @maxX XDim}
%           if true
%           then
            local
               Tag
            in
               {Dictionary.put @lines MaxPtr Tag}
               GraphicSupport, createLine(Tag NewY)
            end
            GraphicSupport, moveCanvasView
         end
      end
      meth call(Obj Mesg)
         RI = {if Obj == self then @object else Obj end getSimpleRootIndex(0 $)}
         StopVar
      in
         GraphicSupport, enableStop
         stopPVar <- StopVar
         stopOVar <- StopVar
         {Obj Mesg}
         TreeWidget, update(RI|nil RI)
      end
      meth selectionCall(Node Mesg)
         RI    = {Node getSimpleRootIndex(0 $)}
         Index = {Node getIndex($)}
         StopVar
      in
         GraphicSupport, enableStop
         stopPVar <- StopVar
         stopOVar <- StopVar
         case Mesg
         of changeWidth(unlimited) then {Node modifyWidth(Index @dWidth)}
         [] changeDepth(unlimited) then {Node modifyDepth(Index @dDepth)}
         [] changeWidth(N)         then {Node modifyWidth(Index N)}
         [] changeDepth(N)         then {Node modifyDepth(Index N)}
         [] reinspect              then {Node reinspect}
         end
         TreeWidget, update(RI|nil RI)
      end
      meth valueToKey(V $)
         case {Value.status V}
         of kinded(Type) then
            case Type
            of int    then fdint
            [] fset   then fsvar
            [] record then kindedrecord
            else Type
            end
         [] det(Type) then
            case Type
            of tuple then
               case {Label V}
               of '#' then hashtuple
               [] '|' then
                  if ({Width V} == 1)
                  then labeltuple
                  elseif (@showString andthen {IsOzString V @dWidth})
                  then string
                  else pipetuple
                  end
               [] !Wrapper then Wrapper
               else labeltuple
               end
            else Type
            end
         elseof Type then Type
         end
      end
      meth treeCreate(Val Parent Index Depth $)
         MaxDepth = @dDepth
      in
         if Depth > MaxDepth
         then {New Helper.bitmap treeCreate(depth Parent Index self Val)}
         else
            ValKey = TreeWidget, valueToKey(Val $)
         in
            case {Dictionary.condGet @mapDict ValKey nil}
            of nil then
               if @dMode
               then TreeWidget, graphCreate(Val Parent Index Depth $)
               else
                  {New {Dictionary.condGet
                        @normNodesDict ValKey @treeNodes.generic}
                   create(Val Parent Index self Depth)}
               end
            elseof F then
               MaxW = @dWidth
               NVal = try {F Val MaxW MaxDepth} catch X then
                         map_failed(ex:{Value.byNeedFuture fun {$} X end}) end
               Node = if @dMode
                      then TreeWidget, graphCreate(NVal Parent Index Depth $)
                      else
                         ValKey = TreeWidget, valueToKey(NVal $)
                      in
                         {New {Dictionary.condGet @normNodesDict
                               ValKey @treeNodes.generic}
                          create(NVal Parent Index self Depth)}
                      end
            in
               if {System.eq NVal Val}
               then Node
               else {New Helper.proxy create({New Helper.box create(Val)} Node Index self Depth)}
               end
            end
         end
      end
      meth isAtomic(V $)
         case {Value.status V}
         of det(Type) then
            case Type
            of tuple  then (@showString andthen {IsOzString V @dWidth})
            [] record then false
            else true
            end
         else false
         end
      end
      meth graphCreate(Val Parent Index Depth $)
         if {@isAtomic Val}
         then
            ValKey = TreeWidget, valueToKey(Val $)
         in
            {New {Dictionary.condGet @relNodesDict ValKey @treeNodes.generic}
             create(Val Parent Index self Depth)}
         else
            Entry = {@curRelMan query(Val $)}
         in
            if {Entry isActive($)}
            then {New @treeNodes.variableRef
                  create(Entry Parent Index self Depth)}
            else
               ValKey = TreeWidget, valueToKey(Val $)
            in
               {New
                {Dictionary.condGet @relNodesDict ValKey @treeNodes.generic}
                gcr(Entry Val Parent Index self Depth)}
            end
         end
      end
      meth listCreate(Val Parent Index RIndex Depth Width Stop $)
         if RIndex > Width orelse {IsDet Stop}
         then {New Helper.bitmap create(width Parent Index self)}
         elseif {IsUnbound Val}
         then TreeWidget, treeCreate(Val Parent Index (Depth + 1) $)
         elsecase Val
         of _|_ then
            Entry = {@curRelMan query(Val $)}
         in
            if {Entry isActive($)}
            then {New @treeNodes.variableRef create(Entry Parent Index self (Depth + 1))}
            else {New @treeNodes.pipeTupleGrS
                  create(Entry Val Parent Index RIndex self Depth Width Stop)}
            end
         else TreeWidget, treeCreate(Val Parent Index (Depth + 1) $)
         end
      end
      meth coreCreate(Val Parent Index Depth $)
         if Depth > @dDepth
         then {New Helper.bitmap treeCreate(dpeth Parent Index self Val)}
         else
            ValKey = TreeWidget, valueToKey(Val $)
         in
            {New {Dictionary.condGet @normNodesDict ValKey @treeNodes.generic}
             create(Val Parent Index self Depth)}
         end
      end
      meth getRefNode($)
         @treeNodes.variableRef
      end
      meth listNode($)
         @treeNodes.pipeTupleGr
      end
      meth getFSVHelperNode($)
         @treeNodes.fsHelper
      end
      meth setRelManager(RelMan)
         relMan <- RelMan
      end
      meth replace(I Value Call)
         Items   = @nodes
         OldNode = {Dictionary.get Items I}
         Node
      in
         {OldNode undraw}
         Node = case Call
                of replaceNormal then
                   TreeWidget, treeCreate(Value self I 0 $)
                [] replaceDepth then
                   {New Helper.bitmap treeCreate(depth self I self {OldNode getValue($)})}
                end
         if {OldNode mustChange($)}
         then {OldNode change(Node)}
         else {Dictionary.put Items I Node}
         end
      end
      meth up(N I)
         Items   = @nodes
         OldNode = {Dictionary.get Items I}
         Value   = {OldNode getValue($)}
         Node
      in
         {OldNode undraw}
         if N > 0
         then
            DDepth = @dDepth
         in
            dDepth <- N
            Node = TreeWidget, treeCreate(Value self I 0 $)
            dDepth <- DDepth
         else Node = {New Helper.bitmap treeCreate(depth self I self Value)}
         end
         if {OldNode mustChange($)}
         then {OldNode change(Node)}
         else {Dictionary.put Items I Node}
         end
      end
      meth link(I Value)
         Items   = @nodes
         OldNode = {Dictionary.get Items I}
         Node Proxy
      in
         {OldNode undraw}
         Node  = TreeWidget, treeCreate(Value self I 0 $)
         Proxy = {New Helper.proxy create(OldNode Node I self 0)}
         {Dictionary.put Items I Proxy}
      end
      meth unlink(I)
         Items   = @nodes
         OldNode = {Dictionary.get Items I}
         Node    = {OldNode unbox($)}
         Value   = {Node getValue($)}
         NewNode
      in
         {OldNode undraw}
         NewNode = TreeWidget, treeCreate(Value self I 0 $)
         {Dictionary.put Items I
          if {Node mustChange($)} then {Node change(NewNode)} Node else NewNode end}
      end
      meth modifyDepth(Index N)
         if N > 0
         then
            Items    = @nodes
            Node     = {Dictionary.get Items Index}
            Value    = {Node getValue($)}
            OldDepth = @dDepth
            NewNode
         in
            {Node undraw}
            dDepth <- (N - 1)
            NewNode = TreeWidget, treeCreate(Value self Index 0 $)
            dDepth <- OldDepth
            if {Node mustChange($)}
            then {Node change(NewNode)}
            else {Dictionary.put Items Index NewNode}
            end
         end
      end
      meth handleStop(I)
         Nodes    = @nodes
         Node     = {Dictionary.get Nodes I}
         WorkNode = if {Node isFresh($)}
                    then
                       NewNode = {New Helper.bitmap create(depth self I self)}
                    in
                       {NewNode setRescueValue({Node getValue($)})}
                       if {Node mustChange($)}
                       then {Node change(NewNode)} Node
                       else {Dictionary.put Nodes I NewNode} NewNode
                       end
                    else {Node eliminateFresh(1)} Node
                    end
         StopVar = @stopPVar
      in
         stopPVar <- _ %% Change Private StopVar to prevent stopping again
         {WorkNode layout}
         case TreeWidget, calcYPos((I - 1) 0 0 $)
         of _|Y then {WorkNode draw(0 Y)} stopPVar <- StopVar
         end
      end
      meth update(Is M)
         case Is
         of I|Ir then
            {{Dictionary.get @nodes I} layout}
            TreeWidget, update(Ir {Min I M})
         elsecase TreeWidget, calcYPos((M - 1) 0 0 $)
         of MX|Y then TreeWidget, performUpdate(M 0 Y MX)
         end
      end
      meth calcYPos(I Y MX $)
         case I
         of 0 then MX|Y
         elsecase {{Dictionary.get @nodes I} getXYDim($)}
         of XDim|YDim then
            TreeWidget, calcYPos((I - 1) (Y + YDim) {Max MX XDim} $)
         end
      end
      meth performUpdate(I X Y MaxX)
         Node = {Dictionary.get @nodes I}
      in
         GraphicSupport, resetTags(I)
         {Node draw(X Y)} %% Draw may change XY Dim
         case {Node getXYDim($)}
         of XDim|YDim then
            NewY = (Y + YDim)
            NewX = {Max MaxX XDim}
         in
            GraphicSupport, moveLine({Dictionary.get @lines I} NewY)
            if I < @maxPtr
            then TreeWidget, performUpdate((I + 1) X NewY NewX)
            else
               maxX <- NewX
               curY <- NewY
               GraphicSupport, adjustSelection
               GraphicSupport, adjustCanvasView
            end
         end
      end
      meth getStopVar($)
         @stopPVar
      end
      meth stopUpdate
         %% Stops only open Var; yields stop if OSV and PSV are equal
         @stopOVar = unit
      end
      meth freeze(FreezeVar)
         {Wait FreezeVar}
      end
      meth terminate
         {Thread.terminate {Thread.this}}
      end
      meth getRelMan($)
         @curRelMan
      end
      meth apply(P)
         {P}
      end
      meth clearAll(F)
         GraphicSupport, enableStop
         TreeWidget, performClearAll(1)
         maxPtr <- 0
         maxX   <- 0
         curY   <- 0
         case @selObject
         of nil  then GraphicSupport,adjustCanvasView
         [] Node then
            GraphicSupport, clearSelection
            TreeWidget, display({Node getValue($)})
         end
         F = unit
      end
      meth performClearAll(I)
         if I =< @maxPtr
         then
            Items = @nodes
            Lines = @lines
            T     = {Dictionary.get Lines I}
         in
            {{Dictionary.get Items I} undraw}
            GraphicSupport, delete(T)
            {Dictionary.remove Items I}
            {Dictionary.remove Lines I}
            TreeWidget, performClearAll((I + 1))
         end
      end
   end
end
