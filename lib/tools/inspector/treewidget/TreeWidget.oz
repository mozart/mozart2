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

functor $
import
   FS(value)
   Aux(bitmap box proxy)
   TreeNodes
   StoreListener
   RelationManager('class')
   GraphicSupport('class')
   System(eq show)
   Tk(return)
   Property(get)
export
   'class' : TreeWidget
define
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
            [] '|' then pipetuple
            else labeltuple
            end
         else Type
         end
      elseof Type then Type
      end
   end

   proc {FillDict D Es}
      case Es
      of (Key#Value)|Er then {Dictionary.put D Key Value} {FillDict D Er}
      else skip
      end
   end

   NormalNodes = [int#int float#float atom#atom name#name procedure#procedure
                  hashtuple#hashtuple pipetuple#pipetuple labeltuple#labeltuple
                  record#record kindedrecord#kindedrecord fdint#fdint
                  fset#fsval fsvar#fsvar free#free future#future byteString#bytestring]
   RelNodes    = [int#int float#float atom#atom name#name procedure#procedure
                  hashtuple#hashtupleGr pipetuple#pipetupleGrM
                  labeltuple#labeltupleGr record#recordGr
                  kindedrecord#kindedrecordGr fdint#fdintGr
                  fset#fsvalGr fsvar#fsvarGr free#freeGr future#futureGr byteString#bytestring]

   NDict       = {Dictionary.new} {FillDict NDict NormalNodes}
   RDict       = {Dictionary.new} {FillDict RDict RelNodes}

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

   class TreeWidget from StoreListener.'class' GraphicSupport.'class'
      attr
         widPort    %% TreeWidget Port
         dMode      %% Display Mode (True: GraphMode / False TreeMode)
         dWidth     %% Display Width (Logical Expansion)
         dDepth     %% Display Depth (Locical Expansion)
         curY       %% Current Y Position
         maxX       %% Maxmimal X Dimension
         maxPtr     %% Current Node Counter
         nodes      %% Node Dictionary
         relManDict %% Relation Manager Dictionary
         curRelMan  %% Current Relation Manager
         curDefRel  %% Current Default Relation
         stopPVar   %% Privtate Stop Variable (shields stop reactions from beeing interrupted.)
         stopOVar   %% Open Stop Variable
         opDict     %% Option Dictionary
         colDict    %% Color Dictionary
         mapDict    %% Automap Function Dictionary
         lines      %% Separator Dictionary
      meth create(Options Parent DspWidth DspHeight)
         StoreListener.'class', create
         GraphicSupport.'class', create(Parent DspWidth DspHeight)
         @curY       = 0
         @maxX       = 0
         @maxPtr     = 0
         @nodes      = {Dictionary.new}
         @relManDict = {Dictionary.new}
         @lines      = {Dictionary.new}
         TreeWidget, setOptions(Options)
         GraphicSupport.'class', initButtonHandler
      end
      meth setOptions(Options)
         ColDict    = {Dictionary.new}
         MapDict    = {Dictionary.new}
         Keys       = {Dictionary.keys Options}
         StringKeys = {Map Keys Atom.toString}
         Colors     = {Filter StringKeys FilterColor}
         Menus      = {Filter StringKeys FilterMenu}
      in
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
         GraphicSupport.'class', queryDB
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
      meth getRootIndex(I $)
         if @dMode
         then
            RelManDict = @relManDict
            RelMan     = {Dictionary.condGet RelManDict I nil}
         in
            curRelMan <- case RelMan of nil then
                            NewRM = {New RelationManager.'class' create(@curDefRel)}
                         in
                            {Dictionary.put RelManDict I NewRM} NewRM
                         else RelMan
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
%      meth display(Value)
%        A B
%      in
%        A = {Property.get time}.total
%        TreeWidget, doDisplay(Value)
%        {Wait {Tk.return update(idletasks)}}
%        B = {Property.get time}.total
%        {System.show 'display time: '#(B - A)}
%      end
      meth display(Value)
         MaxPtr = (@maxPtr + 1)
         Nodes  = @nodes
         CurY   = @curY
         StopVar Node
      in
         GraphicSupport.'class', enableStop
         if @dMode
         then
            RelMan = {New RelationManager.'class' create(@curDefRel)}
         in
            curRelMan <- RelMan
            {Dictionary.put @relManDict MaxPtr RelMan}
         end
         stopPVar <- StopVar
         stopOVar <- StopVar
         maxPtr   <- MaxPtr
         Node = TreeWidget, treeCreate(Value self MaxPtr 0 $)
         {Dictionary.put Nodes MaxPtr Node}
         {Node layout}
         GraphicSupport.'class', resetTags(MaxPtr)
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
               GraphicSupport.'class', createLine(Tag NewY)
            end
            GraphicSupport.'class', moveCanvasView
         end
      end
      meth call(Obj Mesg)
         RI = {if Obj == self then @object else Obj end getSimpleRootIndex(0 $)}
         StopVar
      in
         GraphicSupport.'class', enableStop
         stopPVar <- StopVar
         stopOVar <- StopVar
         {Obj Mesg}
         TreeWidget, update(RI|nil RI)
      end
      meth treeCreate(Val Parent Index Depth $)
         if Depth > @dDepth
         then {New Aux.bitmap treeCreate(depth Parent Index self Val)}
         else
            ValKey = {ValueToKey Val}
         in
            case {Dictionary.condGet @mapDict ValKey nil}
            of nil then
               if @dMode
               then TreeWidget, graphCreate(Val Parent Index Depth $)
               else
                  NodeKey = {Dictionary.condGet NDict ValKey generic}
               in
                  {New TreeNodes.NodeKey create(Val Parent Index self Depth)}
               end
            elseof F then
               NVal = try {F Val} catch X then
                         failed(ex:{Value.byNeed fun {$} X end}) end
               Box  = {New Aux.box create(Val)}
               Node
            in
               Node = if @dMode
                      then TreeWidget, graphCreate(NVal Parent Index Depth $)
                      else
                         NodeKey = {Dictionary.condGet NDict {ValueToKey NVal} generic}
                      in
                         {New TreeNodes.NodeKey create(NVal Parent Index self Depth)}
                      end
               {New Aux.proxy create(Box Node Index self Depth)}
            end
         end
      end
      meth graphCreate(Val Parent Index Depth $)
         Atomic = case {Value.status Val}
                  of det(Type) then
                     case Type
                     of tuple  then false
                     [] record then false
                     else true
                     end
                  else false
                  end
      in
         if Atomic
         then
            NodeKey = {Dictionary.condGet RDict {ValueToKey Val} generic}
         in
            {New TreeNodes.NodeKey create(Val Parent Index self Depth)}
         else
            Entry = {@curRelMan query(Val $)}
         in
            if {Entry isActive($)}
            then {New TreeNodes.atomRef create(Entry Parent Index self Depth)}
            else
               NodeKey = {Dictionary.condGet RDict {ValueToKey Val} generic}
            in
               {New TreeNodes.NodeKey gcr(Entry Val Parent Index self Depth)}
            end
         end
      end
      meth listCreate(Val Parent Index RIndex Depth Width Stop $)
         if RIndex > Width orelse {IsDet Stop}
         then {New Aux.bitmap create(width Parent Index self)}
         elseif {IsFree Val}
         then TreeWidget, treeCreate(Val Parent Index (Depth + 1) $)
         elsecase Val
         of _|_ then
            Entry = {@curRelMan query(Val $)}
         in
            if {Entry isActive($)}
            then {New TreeNodes.atomRef create(Entry Parent Index self (Depth + 1))}
            else {New TreeNodes.pipetupleGrS
                  create(Entry Val Parent Index RIndex self Depth Width Stop)}
            end
         else TreeWidget, treeCreate(Val Parent Index (Depth + 1) $)
         end
      end
      meth coreCreate(Val Parent Index Depth $)
         if Depth > @dDepth
         then {New Aux.bitmap treeCreate(dpeth Parent Index self Val)}
         else
            NodeKey = {Dictionary.condGet NDict {ValueToKey Val} generic}
         in
            {New TreeNodes.NodeKey create(Val Parent Index self Depth)}
         end
      end
      meth getRefNode($)
         TreeNodes.atomRef
      end
      meth listNode($)
         TreeNodes.pipetupleGr
      end
      meth getFSVHelperNode($)
         TreeNodes.fshelper
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
                   {New Aux.bitmap treeCreate(depth self I self {OldNode getValue($)})}
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
         else Node = {New Aux.bitmap treeCreate(depth self I self Value)}
         end
         {Dictionary.put Items I Node}
      end
      meth link(I Value)
         Items   = @nodes
         OldNode = {Dictionary.get Items I}
         Node Proxy
      in
         {OldNode undraw}
         Node  = TreeWidget, treeCreate(Value self I 0 $)
         Proxy = {New Aux.proxy create(OldNode Node I self 0)}
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
            {Dictionary.put Items Index NewNode}
         end
      end
      meth handleStop(I)
         Nodes    = @nodes
         Node     = {Dictionary.get Nodes I}
         WorkNode = if {Node isFresh($)}
                    then
                       NewNode = {New Aux.bitmap create(depth self I self)}
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
         GraphicSupport.'class', resetTags(I)
         {Node draw(X Y)} %% Draw may change XY Dim
         case {Node getXYDim($)}
         of XDim|YDim then
            NewY = (Y + YDim)
            NewX = {Max MaxX XDim}
         in
%           if true
%           then
            GraphicSupport.'class', moveLine({Dictionary.get @lines I} NewY)
%           end
            if I < @maxPtr
            then TreeWidget, performUpdate((I + 1) X NewY NewX)
            else
               maxX <- NewX
               curY <- NewY
               GraphicSupport.'class', adjustCanvasView
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
   end
end
