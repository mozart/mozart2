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
%%% Inspector Functor
%%%

functor $

import
   InspectorOptions
   SupportNodes('options')
   TreeWidget('treeWidget')
   Tk
   TkTools

export
   'class'     : Inspector
   'object'    : Server
   'inspect'   : Inspect
   'configure' : Configure
   'auto'      : Auto
   'close'     : Close

define
   {InspectorOptions.configure}

   Server

   fun {NewServer C I}
      S
      O = {New C I}
      P = {NewPort S}
      Id
   in
      thread
         Id = {Thread.this}
         {ForAll S O}
      end
      proc {$ M}
         {Port.send P M}
      end|(O|Id)
   end

   OpMan      = SupportNodes.'options'
   TrWidget   = TreeWidget.treeWidget

   \insert 'TinyWinMan.oz'

   class Inspector
      from
         WinToplevel

      attr
         mNode %% InspectorMenuNode
         bNode %% ButtonFrameNode
         cNode %% (Scroll)CanvasNode
         uArea %% Used Area

      meth create
         XDim  = {OpMan get(inspectorWidth $)}
         YDim  = {OpMan get(inspectorHeight $)}
         UArea = @uArea
      in
         WinToplevel, create(XDim YDim 'Oz Inspector')
         WinToplevel, hide
         @mNode = {New InspectorMenuNode create(self XDim 0)}
         @bNode = {New ButtonFrameNode create(self XDim 0 self)}
         UArea  = ({@mNode getYDim($)} + {@bNode getYDim($)})
         @cNode = {New ScrollCanvasNode create(self XDim (YDim - UArea))}
         %% {Assign WidgetCell {@cNode getWidget($)}}
      end

      meth inspect(Value)
         WinToplevel, unhide
         {@cNode display(Value)}
      end

      meth configure(Option Value)
         {OpMan set(Option Value)}
      end

      meth setauto(Option Value)
         _#Fun#LsValue = {OpMan get(Option $)}
      in
         {OpMan set(Option Value#Fun#LsValue)}
      end

      meth getType($)
         Inspector
      end

      meth about(Win)
         D L1 L2
      in
         {Win tk(entryconfigure state:disabled)}
         D = {New TkTools.dialog
              tkInit(title:   'About'
                     buttons: ['Ok' # proc {$}
                                         {Server aboutClose(Win D)}
                                      end]
                     default: 1)}

         L1 = {New Tk.label
               tkInit(parent:     D
                      text:       'Oz Inspector'
                      font:       '-adobe-helvetica-bold-r-*-*-*-140-*'
                      foreground: 'blue4'
                      justify:     center)}
         L2 = {New Tk.label
               tkInit(parent:     D
                      text:       'Thorsten Brunklaus\n(bruni@ps.uni-sb.de)'
                      foreground: 'black'
                      justify:    'center')}

         {Tk.batch [grid(L1 row:0 column:0
                         sticky: nsew pady: 5)
                    grid(L2 row:1 column:0
                         sticky: nsew pady: 5)]}
      end

      meth aboutClose(Win D)
         {D tkClose}
         {Win tk(entryconfigure state:normal)}
      end

      meth freeze
         {Wait _}
      end

      meth close
         {Tk.send wm(withdraw @toplevel)}
         visible <- false
         Inspector, addPane
         Inspector, performClose((@divCount - 1))
      end

      meth performClose(I)
         if I\= 0 then
            Inspector, delPane
            Inspector, performClose((I - 1))
         end
      end

      meth iconify
         {Tk.send wm(iconify @toplevel)}
      end

      meth preferences(Win)
         D L1 L2 E1 E2
      in
         {Win tk(entryconfigure state:disabled)}
         D = {New TkTools.dialog
              tkInit(title:   'Preferences'
                     buttons: ['Query'  # proc {$}
                                             {Server queryOptions(E1 E2)}
                                          end
                               'Set'    # proc {$}
                                             {Server setOptions(E1 E2)}
                                          end
                               'Cancel' # proc {$}
                                             {Server updateOptions(Win D)}
                                          end]
                     default: 1)}

         L1 = {New Tk.label
               tkInit(parent:     D
                      text:       'Option:'
                      foreground: 'blue4')}
         L2 = {New Tk.label
               tkInit(parent:     D
                      text:       'Value:'
                      foreground: 'blue4')}
         E1 = {New Tk.entry
               tkInit(parent: D
                      background: ivory
                      width: 30)}
         E2 = {New Tk.entry
               tkInit(parent: D
                      background: ivory
                      width: 30)}

         {Tk.batch [grid(L1 row: 0 column: 0
                         sticky: nsew pady: 2)
                    grid(E1 row: 0 column: 1
                         sticky: nsew pady: 2)
                    grid(L2 row: 1 column: 0
                         sticky: nsew pady: 2)
                    grid(E2 row: 1 column: 1
                         sticky: nsew pady: 2)
                    focus(E1)]}
      end

      meth queryOptions(E1 E2)
         Key = {E1 tkReturnAtom(get $)}
         Value TkVal
      in
         Value = if {OpMan isKey(Key $)}
                 then {OpMan get(Key $)}
                 else 'ERROR: unkown key'
                 end
         TkVal = if {IsAtom Value}
                 then {Atom.toString Value}
                 elseif {IsInt Value}
                 then {Int.toString Value}
                 elseif {IsFloat Value}
                 then {Float.toString Value}
                 elseif Value==true  then 'true'
                 elseif Value==false then 'false'
                 else 'Sorry: unable to display value"'
                 end

         {E2 tk(delete '@0' 'end')}
         {E2 tk(insert 'end' TkVal)}
      end

      meth setOptions(E1 E2)
         Key   = {E1 tkReturnAtom(get $)}
         Value = {E2 tkReturnString(get $)}
         DBVal
      in
         DBVal = if {String.isInt Value}
                 then {String.toInt Value}
                 elseif {String.isFloat Value}
                 then {String.toFloat Value}
                 elseif Value == "true"
                 then true
                 elseif Value == "false"
                 then false
                 elseif {String.isAtom Value}
                 then {String.toAtom Value}
                 else Value
                 end
         {OpMan set(Key DBVal)}
      end

      meth updateOptions(Win D)
         {{@cNode getWidget($)} queryDB}
         {D tkClose}
         {Win tk(entryconfigure state:normal)}
      end

      meth help
         skip
      end

      meth focusDn(Freeze)
         CNode  = @cNode
         Index  = {CNode getIndex($)}
         NIndex NNode NCanvas
         FreezeVar
      in
         if Freeze then
            {CNode freeze(FreezeVar)}
         end
         NIndex  = if Index == @maxPtr then 3 else (Index + 2) end
         NNode   = {Dictionary.get @items NIndex}
         NCanvas = {NNode getCanvas($)}
         {Tk.batch [focus(NCanvas)]}
         cNode <- NNode
         {NNode unfreeze}
         %% {Assign WidgetCell {NNode getWidget($)}}
      end

      meth enterFocus
         case @toplevel
         of nil then skip
         else
            Canvas = {@cNode getCanvas($)}
         in
            {Tk.batch [focus(Canvas)]}
         end
      end

      meth addPane
         XDim     = @width
         YDim     = @height
         UArea    = @uArea
         DivCount = @divCount
         PArea    = 10 * (@maxPtr - DivCount - 2)
         SArea    = (YDim - UArea - PArea)
         SCSpace  = SArea div DivCount
         NCSpace  = (SArea - 10) div (DivCount + 1)
         DeltaY   = {Int.toFloat (NCSpace - SCSpace)}
      in
         Inspector, shrink(3 DeltaY {Int.toFloat SCSpace})
         _ = {New SashGrip create(self XDim 0)}
         _ = {New ScrollCanvasNode create(self XDim NCSpace)}
      end

      meth shrink(I DeltaY SCSpace)
         if I =< @maxPtr
         then
            Node = {Dictionary.get @items I}
            Type = {Node getType($)}
         in
            if Type==canvasNode then
               YDim      = {Int.toFloat {Node getYDim($)}}
               DDim      = {Float.toInt ((YDim / SCSpace) * DeltaY)}
               ConsumedY = {Node tellNewXY(0 DDim $)}
            in
               if ConsumedY\= 0 then
                  WinToplevel, moveY((I + 1) ConsumedY)
               end
            end
            Inspector, shrink((I + 1) DeltaY SCSpace)
         end
      end

      meth delPane
         CNode  = @cNode
         Items  = @items
         I      = {CNode getIndex($)}
         DeltaY = 10 + {CNode getYDim($)}
         AddSpace Pane NNode NCanvas DeltaK
         FreezeVar
      in
         case @divCount
         of 1 then skip
         else
            case I
            of 3 then
               Pane   = {Dictionary.get Items (I + 1)}
               NNode  = {Dictionary.get Items (I + 2)}
               DeltaK = 2
            else
               Pane   = {Dictionary.get Items (I - 1)}
               NNode  = {Dictionary.get Items (I - 2)}
               DeltaK = 1
            end
            NCanvas = {NNode getCanvas($)}
            {CNode freeze(FreezeVar)} %% Disable data processing
            {CNode undraw}
            {CNode terminate} %% Enable garbage collecting
            {Pane undraw}
            cNode <- NNode
            {Tk.batch [focus(NCanvas)]}
            %% {Assign WidgetCell {NNode getWidget($)}}
            WinToplevel, moveY((I + DeltaK) ~DeltaY)
            Inspector, adjustIndex((I + DeltaK))
            AddSpace = (DeltaY div @divCount)
            WinToplevel, tellNewXY(3 0 AddSpace)
         end
      end

      meth stopUpdate(I)
         if I =< @maxPtr
         then
            Node = {Dictionary.get @items I}
            Type = {Node getType($)}
         in
            case Type
            of canvasNode then
               {Node stopUpdate}
            else skip
            end
            Inspector, stopUpdate((I + 1))
         end
      end

      meth adjustIndex(I)
         MaxPtr = @maxPtr
      in
         if I =< MaxPtr
         then
            Items = @items
            Node  = {Dictionary.get Items I}
            NI    = (I - 2)
         in
            {Node setIndex(NI)}
            {Dictionary.put Items NI Node}
            Inspector, adjustIndex((I + 1))
         else
            Items = @items
         in
            maxPtr <- (MaxPtr - 2)
            {Dictionary.remove Items (MaxPtr - 1)}
            {Dictionary.remove Items MaxPtr}
         end
      end
   end

   Server|_ = {NewServer Inspector create}

   proc {Inspect Value}
      {Server inspect(Value)}
   end

   proc {Configure O V}
      {Server configure(O V)}
   end

   proc {Auto O V}
      {Server setauto(O V)}
   end

   proc {Close}
      {Server close}
   end
end
