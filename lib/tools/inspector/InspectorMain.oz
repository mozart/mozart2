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
   TreeWidgetComponent('class' : TreeWidget
                       'nodes' : TreeNodes) at 'TreeWidget.ozf'
   Reflection(reflect unreflect manager)
   InspectorOptions
   System(eq show onToplevel)
\ifndef INSPECTOR_GTK_GUI
   Tk TkTools
\else
   GTK GTKCANVAS
   GBuilder(create)
\endif
   Profiler(open)
export
   'object'     : InspectorObj
   'inspect'    : Inspect
   'inspectN'   : InspectN
   'configure'  : Configure
   'configureN' : ConfigureN
   'close'      : Close
   'nodes'      : TreeNodes
   'new'        : NewInspector
   'reflect'    : Reflect
   'unreflect'  : Unreflect
define
   fun {NewServer O}
      S P
   in
      P = {NewPort S}
      thread
         {ForAll S O}
      end
      P
   end

   local
      Items      = {NewName}
      NumItems   = {NewName}
      NumWidgets = {NewName}
      Width      = {NewName}
      Height     = {NewName}
      MoveY      = {NewName}
      TellNewXY  = {NewName}
      Call       = {NewName}
      CallOne    = {NewName}
      \insert 'FrameManager.oz'

\ifndef INSPECTOR_GTK_GUI
      %%
      %% Tk Based Inspector Stuff
      %%
      \insert 'OptionsGUI.oz'

      class AboutWindow
         meth about(Menu)
            InspPort = @inspPort %% Imported from InspectorObject
            T       = {New Tk.toplevel
                       tkInit(title:    'About Inspector'
                              delete:
                                 proc {$}
                                    {Port.send InspPort aboutClose(Menu T)}
                                 end
                              withdraw: true)}
            UpFrame = {New Tk.frame
                       tkInit(parent:             T
                              borderwidth:        1
                              highlightthickness: 0
                              relief:             raised)}
            DnFrame = {New Tk.frame
                       tkInit(parent:             T
                              borderwidth:        1
                              highlightthickness: 0
                              relief:              raised)}
            Button  = {New Tk.button
                       tkInit(parent:      DnFrame
                              text:        'Ok'
                              width:       6
                              borderwidth: 1
                              action:
                                 proc {$}
                                    {Port.send InspPort aboutClose(Menu T)}
                                 end)}

            L1      = {New Tk.label
                       tkInit(parent:     UpFrame
                              text:
                                 {Dictionary.get @options inspectorLanguage}#
                              ' Inspector'
                              width:      25
                              font:       '-adobe-helvetica-bold-r-*-*-*-140-*'
                              foreground: 'blue4'
                              justify:     center)}
            L2      = {New Tk.label
                       tkInit(parent:     UpFrame
                              text:
                                 'Thorsten Brunklaus\n(brunklaus@ps.uni-sb.de)'
                              foreground: 'black'
                              justify:    'center')}
         in
            {Menu tk(entryconf state: disabled)}
            aboutWin <- T|Menu
            {Tk.batch [grid(row: 0 column: 0 L1 padx: 0 pady: 4 sticky: nsew)
                       grid(row: 1 column: 0 L2 padx: 0 pady: 4 sticky: nsew)
                       grid(row: 0 column: 0 Button padx: 4 pady: 6 sticky: e)
                       grid(row: 0 column: 0 UpFrame
                            padx: 0 pady: 0 sticky: nsew)
                       grid(row: 1 column: 0 DnFrame
                            padx: 0 pady: 0 sticky: nsew)
                       wm(resizable T false false)
                       update(idletasks)
                       wm(deiconify T)]}
         end
         meth aboutClose(Menu D)
            {D tkClose}
            aboutWin <- nil
            {Menu tk(entryconf state: normal)}
         end
      end

      class GuiInspectorClass from Tk.toplevel
         meth create(InspPort Options Frame)
            Width  = {Dictionary.get Options inspectorWidth}
            Height = {Dictionary.get Options inspectorHeight}
         in
            Tk.toplevel, tkInit(title:
                                   {Dictionary.get Options inspectorLanguage}#
                                ' Inspector'
                                delete: proc {$} {Port.send InspPort close} end
                                width:    Width
                                height:   Height
                                withdraw: true)
            Frame = {New Tk.frame
                     tkInit(parent:             self
                            borderwidth:        0
                            highlightthickness: 0)}

            local
               MenuFrame = {New Tk.frame
                            tkInit(parent:             Frame
                                   borderwidth:        1
                                   relief:             raised
                                   highlightthickness: 0)}
               Menu =
               {TkTools.menubar MenuFrame MenuFrame
                [menubutton(text: 'Inspector'
                            menu:
                               [command(label: 'About...'
                                        action:
                                           proc {$}
                                              {Port.send InspPort
                                               about(Menu.inspector.about)}
                                           end
                                        feature: about)
                                separator
                                command(label: 'Add new Widget'
                                        action: proc {$}
                                                   {Port.send InspPort addPane}
                                                end)
                                command(label:  'Delete active Widget'
                                        action: proc {$}
                                                   {Port.send InspPort delPane}
                                                end)
                                separator
                                command(label: 'Clear all but Selection'
                                        action:
                                           proc {$}
                                              {Port.send InspPort
                                               clearAll(
                                                  Menu.inspector.myclear)}
                                           end
                                        key: ctrl(l)
                                        feature: myclear)
                                separator
                                command(label: 'Iconify'
                                        action:
                                           proc {$}
                                              {Port.send InspPort iconify}
                                           end
                                        feature: iconify)
                                command(label:   'Close'
                                        action:  proc {$}
                                                    {Port.send InspPort close}
                                                 end
                                        feature: close)]
                            feature: inspector)
                 menubutton(text: 'Selection'
                            menu: [command(label:  'Expand'
                                           action:
                                              proc {$}
                                                 {Port.send InspPort
                                                  selectionHandler(expand)}
                                              end
                                           feature: expand)
                                   command(label:  'Shrink'
                                           action:
                                              proc {$}
                                                 {Port.send InspPort
                                                  selectionHandler(shrink)}
                                              end
                                           feature: shrink)
                                   separator
                                   command(label:  'Reinspect'
                                           action:
                                              proc {$}
                                                 {Port.send InspPort
                                                  selectionHandler(reinspect)}
                                              end
                                           feature: reinspect)]
                            feature: selection)
                 menubutton(text: 'Options'
                            menu: [command(label: 'Preferences...'
                                           action:
                                              proc {$}
                                                 {Port.send InspPort
                                                  preferences(
                                                     Menu.insoptions.pref)}
                                              end
                                           feature: pref)]
                            feature: insoptions)]
                nil}
               StopB = {New Tk.button
                        tkInit(parent:           MenuFrame
                               bitmap:
                                  '@'#{Dictionary.get Options widgetStopBitmap}
                               foreground:       red
                               activeforeground: red
                               state:            disabled
                               borderwidth:      0
                               action: proc {$}
                                          {Port.send InspPort stopUpdate(1)}
                                       end)}
               StopN = {Tk.getTclName StopB}
            in
               {Tk.send
                v('proc O0 {} {'#StopN#
                  ' conf -state normal;update idletasks};proc F0 {} {'#StopN#
                  ' conf -state disabled}')}
               @selMenu = Menu.selection
               {Menu.inspector tk(conf borderwidth: 1)}
               {Menu.insoptions tk(conf borderwidth: 1)}
               {Menu.inspector.menu tk(conf tearoff: false borderwidth: 1
                                       activeborderwidth: 1)}
               {Menu.selection.menu tk(conf tearoff: false borderwidth: 1
                                       activeborderwidth: 1)}
               {Menu.selection.expand tk(entryconf state:disabled)}
               {Menu.selection.shrink tk(entryconf state:disabled)}
               {Menu.selection.reinspect tk(entryconf state:disabled)}
               {Menu.insoptions.menu
                tk(conf tearoff: false borderwidth: 1 activeborderwidth: 1)}
               {Tk.batch [grid(row: 0 column: 0 Menu sticky: ew)
                          grid(row: 0 column: 1 StopB
                               padx: 4 pady: 2 sticky: ne)
                          grid(row: 0 column: 0 MenuFrame sticky: nsew)
                          grid(columnconfigure MenuFrame 0 weight: 1)
                          grid(columnconfigure MenuFrame 1 weight: 0)]}
               @expandItem    = Menu.selection.expand
               @shrinkItem    = Menu.selection.shrink
               @reinspectItem = Menu.selection.reinspect
            end
         end
         meth showItems(Frame ManagerFrame)
            {Tk.batch [grid(row: 1 column: 0 ManagerFrame sticky: nsew)
                       grid(rowconfigure Frame 1 weight: 1)
                       grid(columnconfigure Frame 0 weight: 1)
                       grid(row: 0 column: 0 Frame sticky: nsew)
                       grid(rowconfigure self 0 weight: 1)
                       grid(columnconfigure self 0 weight: 1)]}
         end
         meth topShow
            {Tk.send wm(deiconify self)}
         end
         meth topHide
            {Tk.send wm(withdraw self)}
         end
         meth iconify
            {Tk.send wm(iconify self)}
         end
         meth winClose(Window)
            {Window tkClose}
         end
         meth winFocus(Window)
            {Tk.send focus(Window)}
         end
         meth winMinDimension(XDim YDim)
            {Tk.send wm(minsize self XDim YDim)}
         end
         meth menuEnable(Menu)
            {Menu tk(entryconf state: normal)}
         end
         meth menuDisable(Menu)
            {Menu tk(entryconf state: disabled)}
         end
         meth setWinTitle(Title)
            {Tk.send wm(title self Title)}
         end
         meth handlePanes
            {self addPane}
            {self performClose((@NumWidgets - 1))}
         end
      end
\else
      %%
      %% Gtk Based Inspector Stuff
      %%
      \insert 'GtkOptionsGUI.oz'

      class AboutWindow
         meth about(Menu)
            InspPort = @inspPort
            T        = {New GTK.dialog new}
            InspType = {Dictionary.get @options inspectorLanguage}#' Inspector'
            L        = {New GTK.label
                        new({VirtualString.toString
                             "\n"#InspType#
                             "\n\nThorsten Brunklaus\n"#
                             "   (brunklaus@ps.uni-sb.de)   \n"})}
            B        = {New GTK.button newWithLabel("Ok")}
         in
            {T setTitle("About Inspector")}
            {B signalConnect('clicked'
                             proc {$ _}
                                {Port.send InspPort aboutClose(Menu T)}
                             end _)}
            {{T dialogGetFieldActionArea($)} add(B)}
            {{T dialogGetFieldVbox($)} add(L)}
            {Menu setSensitive(0)}
            aboutWin <- T|Menu
            {T showAll}
         end
         meth aboutClose(Menu D)
            {D gtkClose}
            aboutWin <- nil
            {Menu setSensitive(1)}
         end
      end

      class GuiInspectorClass from GTK.window
         attr
            toplevelMenu %% Gtk Toplevel Menu Structure
            stopButton   %% Gtk Toplevel Menu Stop Button
         meth create(InspPort Options Frame)
            Title = {Dictionary.get Options inspectorLanguage}#' Inspector'
            Menu  = @toplevelMenu
         in
            GTK.window, new(GTK.'WINDOW_TOPLEVEL')
            GTK.window, setBorderWidth(0)
            GTK.window, setTitle({VirtualString.toString Title})
            {self signalConnect('delete-event'
                                proc {$ Arg} {Port.send InspPort close} end
                                _)}
            Frame = {New GTK.vBox new(0 0)}
            Menu  = {self internalMenu(InspPort Options $)}
            {Frame packStart(Menu 0 0 0)}
            GTK.window, add(Frame)
         end
         meth internalMenu(InspPort Options $)
            AddPane ClearPane AboutMenu ClearMenu PrefMenu
            InspectorMenu =
            submenu(
               menu(append(
                       menuItem(label:    'About...'
                                handle:   AboutMenu
                                activate: InspPort # about(AboutMenu)))
                    append(menuItem())
                    append(
                       menuItem(label:    'Add new Widget'
                                handle:   AddPane
                                activate: InspPort # addPane))
                    append(
                       menuItem(label:    'Delete active Widget'
                                handle:   ClearPane
                                activate: InspPort # delPane))
                    append(menuItem())
                    append(
                       menuItem(label:    'Clear all but Selection'
                                handle:   ClearMenu
                                activate: InspPort # clearAll(ClearMenu)))
                    append(menuItem())
                    append(
                       menuItem(label:    'Iconify'
                                activate: InspPort # iconify))
                    append(
                       menuItem(label:    'Close'
                                activate: InspPort # close))))
            SelectionMenu =
            submenu(
               menu(append(
                       menuItem(label:    'Expand'
                                handle:   @expandItem
                                activate: InspPort # selectionHandler(expand)))
                    append(
                       menuItem(label: 'Shrink'
                                handle:  @shrinkItem
                                activate: InspPort # selectionHandler(shrink)))
                    append(
                       menuItem(label: 'Reinspect'
                                handle: @reinspectItem
                                activate:
                                   InspPort # selectionHandler(reinspect)))))
            OptionsMenu =
            submenu(
               menu(append(
                       menuItem(label: 'Preferences...'
                                handle: PrefMenu
                                activate: InspPort # preferences(PrefMenu)))))
            MenuBarDesc =
            menuBar(
               append(menuItem(label: 'Inspector' InspectorMenu))
               append(menuItem(label: 'Selection' SelectionMenu))
               append(menuItem(label: 'Options' OptionsMenu))
               append(menuItem(label: 'Stop'
                               handle: @stopButton
                               rightJustify: true
                               activate: InspPort # stopUpdate(1))))
            MenuBar     = {GBuilder.create MenuBarDesc}
         in
            {@stopButton setSensitive(0)}
            {AddPane setSensitive(0)}
            {ClearPane setSensitive(0)}
            MenuBar
         end
         meth showItems(Frame ManagerFrame)
            skip
         end
         meth topShow
            GTK.window, showAll
         end
         meth topHide
            GTK.window, hideAll
         end
         meth winClose(Window)
            {Window gtkClose}
         end
         meth iconify
            skip
         end
         meth winFocus(Window)
            GTK.window, setFocus(Window)
         end
         meth winMinDimension(XDim YDim)
            skip
         end
         meth menuEnable(Menu)
            {Menu setSensitive(1)}
         end
         meth menuDisable(Menu)
            {Menu setSensitive(0)}
         end
         meth setWinTitle(Title)
            {self setTitle(Title)}
         end
         meth handlePanes
            Finished
         in
            %% GTK only supports one widget
            {@widget clearAll(Finished)}
            {Wait Finished}
         end
         meth getStopButton($)
            @stopButton
         end
      end
\endif
      %%
      %% Generic Stuff comes here
      %%
   in
      class InspectorClass from GuiInspectorClass FrameManager AboutWindow
         attr
            options           %% Options Dictionary
            isVisible : false %% Visibility Flag
            widget            %% Current Active TreeWidget
            aboutWin  : nil   %% About Window
            configWin : nil   %% Configuration Window
            selMenu           %% Selection Menu
            selNode           %% Selection Node (exported from TreeWidget)
            inspPort          %% Inspector Port Variable
            expandItem        %% Selection Menu Expand
            shrinkItem        %% Selection Menu Shrink
            reinspectItem     %% Selection Menu Reinspect
         prop
            final
         meth create(InspPort NewOptions)
            Options = InspectorOptions.options
            Width Height Frame ManagerFrame
         in
            {Record.forAllInd NewOptions proc {$ F V}
                                            {Dictionary.put Options F V}
                                         end}
            Width     = {Dictionary.get Options inspectorWidth}
            Height    = {Dictionary.get Options inspectorHeight}
            @inspPort = InspPort
            @options  = Options
            {Dictionary.put Options widgetReflectMan Reflection.manager}
            {Dictionary.put Options selectionHandler
             proc {$ Mode}
                {Port.send InspPort selectionHandler(Mode)}
             end}
            {Dictionary.put Options pressHandler
             proc {$ Mode}
                {Port.send InspPort selectionHandler(double(Mode))}
             end}
            GuiInspectorClass, create(InspPort Options Frame)
            ManagerFrame = FrameManager, create(Frame Width Height $)
            @widget      = {New TreeWidgetNode create(self Width Height)}
            GuiInspectorClass, showItems(Frame ManagerFrame)
         end
         meth inspect(Value)
            if @isVisible
            then skip
            else
%              {Profiler.open}
               isVisible <- true
               GuiInspectorClass, topShow
            end
            {@widget display(Value)}
         end
         meth inspectN(N Value)
            if @isVisible
            then skip
            else
               isVisible <- true
               GuiInspectorClass, topShow
            end
            {{Dictionary.get @Items (1 + (N * 2))} display(Value)}
         end
         meth !Call(P)
            {P}
         end
         meth !CallOne(P V)
            {P V}
         end
         meth getOptions($)
            @options
         end
         meth configureEntry(Key Value)
            Options = @options
         in
            if Key == 'inspectorLanguage'
            then GuiInspectorClass, setWinTitle(Value#' Inspector')
            end
            {Dictionary.put Options Key Value}
            InspectorClass, setOptions(Options)
         end
         meth setOptions(Options)
            options <- Options
            case {Dictionary.get Options inspectorOptionsRange}
            of 'all' then InspectorClass, performSetOptions(1 Options)
            else {@widget setOptions(Options)}
            end
         end
         meth configureNEntry(N Key Value)
            {{Dictionary.get @Items (1 + (N * 2))} optionConfigure(Key Value)}
         end
         meth performSetOptions(I Options)
            if I =< @NumItems
            then
               {{Dictionary.get @Items I} setOptions(Options)}
               InspectorClass, performSetOptions((I + 1) Options)
            end
         end
         meth configure(O V)
            Options = @options
         in
            {Dictionary.put Options O V}
            case {Dictionary.get Options inspectorOptionsRange}
            of 'all' then InspectorClass, performConfigure(1 O V)
            else {@widget optionConfigure(O V)}
            end
         end
         meth performConfigure(I O V)
            if I =< @NumItems
            then
               {{Dictionary.get @Items I} optionConfigure(O V)}
               InspectorClass, performConfigure((I + 1) O V)
            end
         end
         meth preferences(WinEntry)
            RealDict = {@widget getOptions($)}
         in
            configWin <- {New InspectorGUIClass
                          create(WinEntry RealDict @inspPort)}|WinEntry
         end
         meth freeze
            {Wait _}
         end
         meth close
            if @isVisible
            then
               isVisible <- false
               GuiInspectorClass, topHide
            end
            GuiInspectorClass, handlePanes
            case @aboutWin
            of nil then skip
            elseof Win|Menu then
               aboutWin <- nil
               GuiInspectorClass, winClose(Win)
               GuiInspectorClass, menuEnable(Menu)
            end
            case @configWin
            of nil then skip
            elseof Win|Menu then
               configWin <- nil
               {Win tellClose}
               GuiInspectorClass, menuEnable(Menu)
               end
         end
         meth performClose(I)
            if I > 0
            then
               InspectorClass, delPane
               InspectorClass, performClose((I - 1))
            else skip
            end
         end
         meth focusDn(Freeze)
            Widget = @widget
            Index  = {Widget getIndex($)}
            NewIndex NewNode NewCanvas
         in
            if Freeze then {Widget freeze(_)} end
            NewIndex  = if Index == @NumItems then 1 else (Index + 2) end
            NewNode   = {Dictionary.get @Items NewIndex}
            NewCanvas = {NewNode getCanvas($)}
            GuiInspectorClass, winFocus(NewCanvas)
            widget <- NewNode
            {NewNode unfreeze}
         end
         meth changeFocus(NewNode)
            NewCanvas = {NewNode getCanvas($)}
         in
            GuiInspectorClass, winFocus(NewCanvas)
            widget <- NewNode
            {NewNode unfreeze}
         end
         meth enterFocus
            if @isVisible
            then GuiInspectorClass, winFocus({@widget getCanvas($)})
            end
         end
         meth addPane
            XDim        = @Width
            YDim        = @Height
            Widgets     = @NumWidgets
            SingleGripY = 10
            GripArea    = SingleGripY * (@NumItems - Widgets)
            CanvasArea  = (YDim - GripArea)
            ACSpace     = CanvasArea div Widgets %% Average Canvas Size
            NCSpace     = (CanvasArea - SingleGripY) div (Widgets + 1) %% New Canvas Size
            DeltaY      = {Int.toFloat (NCSpace - ACSpace)}
         in
            if  NCSpace > 60 %% at least av 60 Pts for Canvas
            then
               YMin = 60 * (Widgets + 1) + (GripArea + SingleGripY)
            in
               InspectorClass, shrink(1 DeltaY {Int.toFloat ACSpace})
               _ = {New SashGrip create(self XDim 0)}
               _ = {New TreeWidgetNode create(self XDim NCSpace)}
               GuiInspectorClass, winMinDimension(120 YMin)
            end
         end
         meth shrink(I DeltaY ACSpace)
            if I =< @NumItems
            then
               Node = {Dictionary.get @Items I}
            in
               case {Node getType($)}
               of canvasNode then
                  YDim = {Int.toFloat {Node getYDim($)}}
                  DDim = {Float.toInt ((YDim / ACSpace) * DeltaY)}
               in
                  case {Node tellNewXY(0 DDim $)}
                  of 0             then skip
                  elseof ConsumedY then FrameManager, MoveY((I + 1) ConsumedY)
                  end
               else skip
               end
               InspectorClass, shrink((I + 1) DeltaY ACSpace)
            end
         end
         meth delPane
            Widget      = @widget
            MyItems     = @Items
            SingleGripY = 10
            Widgets     = @NumWidgets
            I           = {Widget getIndex($)}
            DeltaY      = (SingleGripY + {Widget getYDim($)})
            GripArea    = (@Height - ((@NumItems - Widgets) * SingleGripY))
            AddSpace Pane NNode NCanvas DeltaK
            FreezeVar
         in
            if Widgets > 1
            then
               YMin = (60 * (Widgets - 1)) + (GripArea - SingleGripY)
            in
               case I
               of 1 then
                  Pane   = {Dictionary.get MyItems (I + 1)}
                  NNode  = {Dictionary.get MyItems (I + 2)}
                  DeltaK = 2
               else
                  Pane   = {Dictionary.get MyItems (I - 1)}
                  NNode  = {Dictionary.get MyItems (I - 2)}
                  DeltaK = 1
               end
               NCanvas = {NNode getCanvas($)}
               {Widget freeze(FreezeVar)} %% Disable data processing
               {Widget undraw}
               {Widget terminate} %% Enable garbage collecting
               {Pane undraw}
               widget <- NNode
               GuiInspectorClass, winFocus(NCanvas)
               FrameManager, MoveY((I + DeltaK) ~DeltaY)
               InspectorClass, adjustIndex((I + DeltaK))
               AddSpace = (DeltaY div @NumWidgets)
               FrameManager, TellNewXY(1 0 AddSpace)
               GuiInspectorClass, winMinDimension(120 YMin)
            end
         end
         meth stopUpdate(I)
            if I =< @NumItems
            then
               {{Dictionary.get @Items I} stopUpdate}
               InspectorClass, stopUpdate((I + 1))
            end
         end
         meth adjustIndex(I)
            MaxNum  = @NumItems
            MyItems = @Items
         in
            if I =< MaxNum
            then
               Node = {Dictionary.get MyItems I}
               NI   = (I - 2)
            in
               {Node setIndex(NI)}
               {Dictionary.put MyItems NI Node}
               InspectorClass, adjustIndex((I + 1))
            else
               NumItems <- (MaxNum - 2)
               {Dictionary.remove MyItems (MaxNum - 1)}
               {Dictionary.remove MyItems MaxNum}
            end
         end
         meth clearAll(Menu)
            Finished
         in
            case Menu
            of false then
               {@widget clearAll(Finished)}
               {Wait Finished}
            [] Menu then
               GuiInspectorClass, menuDisable(Menu)
               {@widget clearAll(Finished)}
               {Wait Finished}
               GuiInspectorClass, menuEnable(Menu)
            end
         end
         meth selectionHandler(Mode)
            case Mode
            of nil then
               selNode <- nil
               GuiInspectorClass, menuDisable(@expandItem)
               GuiInspectorClass, menuDisable(@shrinkItem)
               GuiInspectorClass, menuDisable(@reinspectItem)
            [] expand then
               Node = @selNode
            in
               case {Node getType($)}
               of widthbitmap then {@widget selectionCall(Node changeWidth(1))}
               else {@widget selectionCall(Node changeDepth(1))}
               end
            [] shrink    then
               {@widget selectionCall(@selNode changeDepth(~1))}
            [] reinspect then {@widget selectionCall(@selNode reinspect)}
            [] double(Node) then
               case {Node getType($)}
               of widthbitmap then
                  {@widget selectionCall(Node changeWidth(unlimited))}
               [] depthbitmap then
                  {@widget selectionCall(Node changeDepth(unlimited))}
               [] _ then
                  {@widget selectionCall(Node changeDepth(~1))}
               end
            [] Node      then
               selNode <- Node
               case {Node getType($)}
               of depthbitmap then
                  GuiInspectorClass, menuEnable(@expandItem)
                  GuiInspectorClass, menuDisable(@shrinkItem)
                  GuiInspectorClass, menuDisable(@reinspectItem)
               [] widthbitmap then
                  GuiInspectorClass, menuEnable(@expandItem)
                  GuiInspectorClass, menuDisable(@shrinkItem)
                  GuiInspectorClass, menuDisable(@reinspectItem)
               [] variableref then
                  GuiInspectorClass, menuDisable(@expandItem)
                  GuiInspectorClass, menuDisable(@shrinkItem)
                  GuiInspectorClass, menuDisable(@reinspectItem)
               else
                  GuiInspectorClass, menuDisable(@expandItem)
                  GuiInspectorClass, menuEnable(@shrinkItem)
                  GuiInspectorClass, menuEnable(@reinspectItem)
               end
            end
         end
      end
   end

   %%
   %% Object Creation Function
   %%
   Reflect   = Reflection.reflect
   Unreflect = Reflection.unreflect
   fun {NewInspector Options}
      InspectorPort InspectorObject
   in
      InspectorPort   = {NewServer InspectorObject}
      InspectorObject = {New InspectorClass create(InspectorPort Options)}
      proc {$ M}
         {Port.send InspectorPort {Reflect M}}
      end
   end

   %%
   %% Create System Inspector and its access wrappers
   %%
   InspectorObj = {NewInspector unit}

   proc {Inspect Value}
      {InspectorObj inspect(Value)}
   end
   proc {InspectN N Value}
      {InspectorObj inspectN(N Value)}
   end
   proc {Configure Key Value}
      {InspectorObj configureEntry(Key Value)}
   end
   proc {ConfigureN N Key Value}
      {InspectorObj configureNEntry(N Key Value)}
   end
   proc {Close}
      {InspectorObj close}
   end
end
