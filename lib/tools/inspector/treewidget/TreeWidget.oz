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
   FS(value)
   System(eq show)
   Tk(return)
   Property(get)
   HelperComponent('nodes' : Helper) at 'Helper.ozf'
   TreeNodesComponent('nodes' : TreeNodes) at 'TreeNodes.ozf'
   StoreListenerComponent('class' : StoreListener) at 'StoreListener.ozf'
   RelationManagerComponent('class' : RelationManager) at 'RelationManager.ozf'
   GraphicSupportComponent('class' : GraphicSupport) at 'GraphicSupport.ozf'
export
   'class' : TreeWidget
   'nodes' : AllNodes
define
   %% Create All Nodes Export Record
   AllNodes = {Record.adjoinAt TreeNodes.all 'helper' Helper}

   fun {ValueToKey V}
      case {Value.status V}
      of kinded(Type) then
         case Type
         of int    then fdint
         [] fset   then fsvar
         [] record then kindedrecord
         end
      [] det(Type) then
         case Type
         of tuple then
            case {Label V}
            of '#' then hashtuple
            [] '|' then if ({Width V} == 1) then labeltuple else pipetuple end
            else labeltuple
            end
         else Type
         end
      elseof Type then Type
      end
   end

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
         stopPVar      %% Private Stop Variable (shields stop reactions from beeing broken.)
         stopOVar      %% Open Stop Variable
         opDict        %% Option Dictionary
         colDict       %% Color Dictionary
         mapDict       %% Automap Function Dictionary
         lines         %% Separator Dictionary
         treeNodes     %% TreeWidget Node Container (used to fill (norm|rel)NodesDict)
         normNodesDict %% Normal Mode Nodes
         relNodesDict  %% Relation Mode Nodes
         relGlobal     %% Global Relation Mode
         globalRelMan  %% Global Relation Manager
         isAtomic      %% Atomic Test Function (must not be changed in Oz)
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
         case {Dictionary.get Options widgetNodeSets}.{Dictionary.get Options widgetUseNodeSet}
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
            Filter   = case {Dictionary.get O FetchKey} of menu(_ _ Fs _) then Fs else nil end
         in
            case TreeWidget, hasAuto(Filter $)
            of auto(F) then {Dictionary.put D PutKey F}
            else skip
            end
            TreeWidget, extractAutoMappings(Mr O D)
         else skip
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
         dWidth    <- {Dictionary.get OpDict widgetTreeWidth}
         dDepth    <- {Dictionary.get OpDict widgetTreeDepth}
         dMode     <- {Not {Dictionary.get OpDict widgetTreeDisplayMode}}
         curDefRel <- TreeWidget, searchDefRel({Dictionary.get OpDict widgetRelationList} $)
         isAtomic  <- {Dictionary.get OpDict widgetAtomicTest}
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
%       meth display(Value)
%        A B
%       in
%        A = {Property.get time}.total
%        TreeWidget, doDisplay(Value)
%        {Wait {Tk.return update(idletasks)}}
%        B = {Property.get time}.total
%        {System.show 'display time: '#(B - A)}
%       end
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
                            of nil       then {New RelationManager create(@curDefRel)}
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
      meth treeCreate(Val Parent Index Depth $)
         MaxDepth = @dDepth
      in
         if Depth > MaxDepth
         then {New Helper.bitmap treeCreate(depth Parent Index self Val)}
         else
            ValKey = {ValueToKey Val}
         in
            case {Dictionary.condGet @mapDict ValKey nil}
            of nil then
               if @dMode
               then TreeWidget, graphCreate(Val Parent Index Depth $)
               else
                  {New {Dictionary.condGet @normNodesDict ValKey @treeNodes.generic}
                   create(Val Parent Index self Depth)}
               end
            elseof F then
               MaxW = @dWidth
               NVal = try {F Val MaxW MaxDepth} catch X then
                         failed(ex:{Value.byNeed fun {$} X end}) end
               Node = if @dMode
                      then TreeWidget, graphCreate(NVal Parent Index Depth $)
                      else
                         {New {Dictionary.condGet @normNodesDict
                               {ValueToKey NVal} @treeNodes.generic}
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
      meth graphCreate(Val Parent Index Depth $)
         if {@isAtomic Val}
         then
            {New {Dictionary.condGet @relNodesDict {ValueToKey Val} @treeNodes.generic}
             create(Val Parent Index self Depth)}
         else
            Entry = {@curRelMan query(Val $)}
         in
            if {Entry isActive($)}
            then {New @treeNodes.variableRef create(Entry Parent Index self Depth)}
            else
               {New {Dictionary.condGet @relNodesDict {ValueToKey Val} @treeNodes.generic}
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
            {New {Dictionary.condGet @normNodesDict {ValueToKey Val} @treeNodes.generic}
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
%           if true
%           then
            GraphicSupport, moveLine({Dictionary.get @lines I} NewY)
%           end
            if I < @maxPtr
            then TreeWidget, performUpdate((I + 1) X NewY NewX)
            else
               maxX <- NewX
               curY <- NewY
               GraphicSupport, adjustSelection
               GraphicSupport, adjustCanvasView
%              {Wait {Tk.return update(idletasks)}}
            end
         end
      end
      meth getStopVar($)
         @stopPVar
      end
      meth stopUpdate
         @stopOVar = unit %% Stops only open Var; yields stop if OSV and PSV are equal
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
