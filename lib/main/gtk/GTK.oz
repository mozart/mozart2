%%%
%%% Author:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%   Andreas Simon <asimon@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 2000
%%%   Andreas  Simon, 2000
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL WARRANTIES.
%%%

functor $

import
   GtkNative at 'GTK.so{native}'
   System

export
   % Classes
   Adjustment
   Alignment
   Arrow
   AspectFrame
   Bin
   Box
   Button
   ButtonBox
   Calendar
   CheckButton
   CheckMenuItem
   CList
   ColorSelection
   ColorSelectionDialog
   Combo
   Container
   Curve
   Data
   Dialog
   DrawingArea
   Editable
   FileSelection
   Fixed
   FontSelection
   FontSelectionDialog
   Frame
   GammaCurve
   HBox
   HButtonBox
   HPaned
   HRuler
   HScale
   HScrollbar
   HSeparator
   Item
   Label
   Layout
   list: GList % get rid of a name clash
   Menu
   MenuBar
   MenuItem
   MenuShell
   Misc
   Notebook
   Object
   OptionMenu
   Paned
   RadioButton
   Range
   Ruler
   Scale
   Scrollbar
   ScrolledWindow
   Separator
   Statusbar
   Table
   Text
   ToggleButton
   VBox
   VButtonBox
   VPaned
   VRuler
   VScale
   VScrollbar
   VSeparator
   Widget
   Window

   % Miscelleanous procedures, i.e. procedures that are part of no class
   Exit
   Main
   MainQuit

   % Special stuff
   Dispatcher
   GetObject

   \insert 'constdeclarations.oz'

define

   \insert 'constdefinitions.oz'

% -----------------------------------------------------------------------------
% Dispatcher
% -----------------------------------------------------------------------------

   local
      PollingIntervall = 50
   in
      class DispatcherClass
         attr
            id_counter : 0
            registry % A dictionary with id <--> handler corrospondences
            port
            stream
            fillerThread
         meth init
            proc {FillStream}
               {GtkNative.handlePendingEvents} % Send all pending GTK events to the Oz port
               {Time.delay PollingIntervall}
               {FillStream}
            end
         in
            registry <- {Dictionary.new}
            port     <- {Port.new @stream}
            {GtkNative.initializeSignalPort @port} % Tell the 'C side' about the signal port
            thread
               fillerThread <- {Thread.this $}
               {FillStream}
            end
            {System.show 'leaving SignalDispatcher init'}
         end
         meth GetUniqueID($)
            id_counter <- @id_counter + 1
            @id_counter
         end
         meth registerHandler(Handler ?Id)
         {self GetUniqueID(Id)}
            {Dictionary.put @registry Id Handler}
         end
         meth unregisterHandler(Id)
            {Dictionary.remove @registry Id}
         end
         meth dispatch
            Handler
            Event
            Tail
         in
            @stream = Event|Tail
            {Dictionary.get @registry Event Handler}
            % TODO: suspend marshaller with sending a new variable to a second port
            {Handler}
            % TODO: terminate marshaller with bounding this variable
            stream <- Tail
            DispatcherClass,dispatch
         end
         meth exit
            {Thread.terminate {Thread.this $}}
         end
      end
   end

% -----------------------------------------------------------------------------
% Non-OO Stuff
% -----------------------------------------------------------------------------

   proc {Main}
      {GtkNative.main}
   end

   proc {MainQuit}
      {Dispatcher exit}
      {GtkNative.mainQuit}
   end

   proc {Exit}
      {GtkNative.exit 0}
      {Dispatcher exit}
   end

% -----------------------------------------------------------------------------
% Object Registry
% -----------------------------------------------------------------------------

   % stores GTK object --> OZ object corrospondence
   ObjectRegistry = {Dictionary.new $}

   % Get the corrosponding Oz object from a GTK object
   proc {GetObject MyForeignPointer ?MyObject}
      if MyForeignPointer == 0 then
         MyObject = nil
      else
         {Dictionary.get
          ObjectRegistry
          {ForeignPointer.toInt MyForeignPointer}
          MyObject}
      end
   end

% -----------------------------------------------------------------------------
% Object
% -----------------------------------------------------------------------------

   class Object
      attr nativeObject
      meth registerObject
         {Dictionary.put
          ObjectRegistry
          {ForeignPointer.toInt @nativeObject}
          self}
      end
      meth getNative($) % get native GTK object from an Oz object
         @nativeObject
      end
      meth ref
         {GtkNative.ref @nativeObject}
      end
      meth unref
         {GtkNative.unref @nativeObject}
      end

% Signal (made part of Object)

      meth signalConnect(Name Handler ?Id)
         % TODO: support user data (maybe superfluous)
         {Dispatcher registerHandler(Handler Id)}
         {GtkNative.signalConnect @nativeObject Name Id _}
      end
      meth signalDisconnect(Id)
         {Dispatcher unregisterSignal(Id)}
         {GtkNative.signalDisconnect @nativeObject Id}
      end
      meth signalHandlerBlock(HandlerId)
         {GtkNative.signalBlock @nativeObject HandlerId}
      end
      meth signalHandlerUnblock(HandlerId)
         {GtkNative.signalUnblock @nativeObject HandlerId}
      end
      meth signalEmitByName(Name)
         {GtkNative.signalEmitByName @nativeObject Name}
      end
   end

% -----------------------------------------------------------------------------
% Data
% -----------------------------------------------------------------------------

   class Data from Object
   end

% -----------------------------------------------------------------------------
% Adjustment
% -----------------------------------------------------------------------------

   class Adjustment from Data
      meth init(Value Lower Upper StepIncrement PageIncrement PageSize)
         nativeObject <- {GtkNative.adjustmentNew
                          Value
                          Lower
                          Upper
                          StepIncrement
                          PageIncrement
                          PageSize}
         Object, registerObject
      end
      meth setValue(Value)
         {GtkNative.adjustmentSetValue @nativeObject Value}
      end
      meth clampPage(Lower Upper)
         {GtkNative.adjustmentClampPage @nativeObject Lower Upper}
      end
      meth changed
         {GtkNative.adjustmentChanged @nativeObject}
      end
      meth valueChanged
         {GtkNative.adjustmentValueChanged @nativeObject}
      end
   end

% -----------------------------------------------------------------------------
% Widget
% -----------------------------------------------------------------------------

   class Widget from Object
      meth initNative(NativeWidget) % used for implizid widgets
         nativeObject <- NativeWidget
      end
      meth ref
         {GtkNative.widgetRef @nativeObject}
      end
      meth unref
         {GtkNative.widgetUnref @nativeObject}
      end
      meth destroy
         {GtkNative.widgetDestroy @nativeObject}
      end
      meth unparent
         {GtkNative.widgetUnparent @nativeObject}
      end
      meth show
         {GtkNative.widgetShow @nativeObject}
      end
      meth showNow
         {GtkNative.widgetShowNow @nativeObject}
      end
      meth hide
         {GtkNative.widgetHide @nativeObject}
      end
      meth showAll
         {GtkNative.widgetShowAll @nativeObject}
      end
      meth hideAll
         {GtkNative.widgetHideAll @nativeObject}
      end
      meth map
         {GtkNative.widgetMap @nativeObject}
      end
      meth unmap
         {GtkNative.widgetUnmap @nativeObject}
      end
      meth realize
         {GtkNative.widgetRealize @nativeObject}
      end
      meth unrealize
         {GtkNative.widgetUnrealize @nativeObject}
      end
      meth queueDraw
         {GtkNative.widgetQueueDraw @nativeObject}
      end
      meth queueResize
         {GtkNative.widgetQueueResize @nativeObject}
      end
      meth drawFocus
         {GtkNative.widgetDrawFocus @nativeObject}
      end
      meth drawDefault
         {GtkNative.widgetDrawDefault @nativeObject}
      end
      meth setName(Name)
         {GtkNative.widgetSetName @nativeObject Name}
      end
      meth getName($)
         {GtkNative.widgetGetName @nativeObject $}
      end
      meth setState(State)
         {GtkNative.widgetSetState @nativeObject State}
      end
      meth setSensitive(Sensitive)
         {GtkNative.widgetSetSensitive @nativeObject Sensitive}
      end
      meth setParent(Parent)
         {GtkNative.widgetSetParent @nativeObject {Parent getName($)}}
      end
      meth setUposition(X Y)
         {GtkNative.widgetSetUposition @nativeObject X Y}
      end
      meth setUsize(Width Height)
         {GtkNative.widgetSetUsize @nativeObject Width Height}
      end
      meth setEvents(Events)
         {GtkNative.widgetSetEvents @nativeObject Events}
      end
      meth addEvents(Events)
         {GtkNative.widgetAddEvents @nativeObject Events}
      end
      meth grabDefault
         {GtkNative.widgetGrabDefault @nativeObject}
      end
      meth grabFocus
         {GtkNative.widgetGrabFocus @nativeObject}
      end
      %
      % Gtk macros
      %
      meth visible($)
         {GtkNative.widgetVisible @nativeObject $}
      end
      meth sensitive($)
         {GtkNative.widgetSensitive @nativeObject $}
      end
      meth setFlags(Flag)
         {GtkNative.widgetSetFlags @nativeObject Flag}
      end
      meth unsetFlags(Flag)
         {GtkNative.widgetUnsetFlags @nativeObject Flag}
      end
   end

% -----------------------------------------------------------------------------
% Calendar
% -----------------------------------------------------------------------------

   class Calendar from Widget
      meth init
         nativeObject <- {GtkNative.calendarNew}
         Object, registerObject
      end
      meth selectMonth(Month Year ?Ok)
         Ok = {GtkNative.calendarSelectMonth @nativeObject Month Year}
      end
      meth selectDay(Day)
         {GtkNative.calendarSelectDay @nativeObject Day}
      end
      meth markDay(Day ?Ok)
         Ok = {GtkNative.calendarMarkDay @nativeObject Day}
      end
      meth unmarkDay(Day ?Ok)
         Ok = {GtkNative.calendarUnmarkDay @nativeObject Day}
      end
      meth clearMarks
         {GtkNative.calendarClearMarks @nativeObject}
      end
      meth displayOptions(Flags)
         {GtkNative.calendarDisplayOptions @nativeObject Flags}
      end
      meth getDate(?Year ?Month ?Day)
         {GtkNative.calendarGetDate @nativeObject Year Month Day}
      end
      meth freeze
         {GtkNative.calendarFreeze @nativeObject}
      end
      meth thaw
         {GtkNative.calendarThaw @nativeObject}
      end
   end

% -----------------------------------------------------------------------------
% DrawingArea
% -----------------------------------------------------------------------------

   class DrawingArea from Widget
      meth init
         nativeObject <- {GtkNative.drawingAreaNew}
         Object, registerObject
      end
      meth size(Width Height)
         {GtkNative.drawingAreaSize @nativeObject Width Height}
      end
   end

% -----------------------------------------------------------------------------
% Curve
% -----------------------------------------------------------------------------

   class Curve from DrawingArea
      meth init
         nativeObject <- {GtkNative.curveNew}
         Object, registerObject
      end
      meth reset
         {GtkNative.curveReset @nativeObject}
      end
      meth setGamma(Gamma)
         {GtkNative.curveSetGamme @nativeObject Gamma}
      end
      meth setRange(MinX MaxX MinY MaxY)
         {GtkNative.curveSetRange @nativeObject MinX MaxX MinY MaxY}
      end
      meth getVector(VecLen ?Vector)
         {GtkNative.curveGetVector @nativeObject VecLen Vector}
      end
      meth setVector(VecLen Vector)
         {GtkNative.curveGetVector @nativeObject VecLen Vector}
      end
      meth setCurveType(Type)
         {GtkNative.curveSetCurveType @nativeObject Type}
      end
   end

% -----------------------------------------------------------------------------
% GammaCurve
% -----------------------------------------------------------------------------

   class GammaCurve from Curve
      meth init
         nativeObject <- {GtkNative.gammaCurveNew}
         Object, registerObject
      end
   end

% -----------------------------------------------------------------------------
% Editable
% -----------------------------------------------------------------------------

   class Editable from Widget
      attr
         textPosition : 0
         editable      : false
      meth selectRegion(Start End)
         {GtkNative.editableSelectRegion @nativeObject Start End}
      end
      meth insertText(NewText NewTextLength Position ?NewPosition)
         NewPosition = {GtkNative.editableInsertText
                        @nativeObject
                        NewText
                        NewTextLength
                        Position}
      end
      meth deleteText(Start End)
         {GtkNative.editableDeleteText @nativeObject Start End}
      end
      meth getChars(Start End ?Chars)
         Chars = {GtkNative.editableGetChars @nativeObject Start End}
      end
      meth cutClipboard
         {GtkNative.editableCutClipboard @nativeObject}
      end
      meth copyClipboard
         {GtkNative.editableCopyClipboard @nativeObject}
      end
      meth pasteClipboard
         {GtkNative.editablePasteClipboard @nativeObject}
      end
      meth claimSelection(Claim Time)
         {GtkNative.editableClaimSelection @nativeObject Claim Time}
      end
      meth deleteSelection
         {GtkNative.editableDeleteSelection @nativeObject}
      end
      meth changed
         {GtkNative.editableChanged @nativeObject}
      end
      meth setPosition(Pos)
         {GtkNative.editableSetPosition @nativeObject Pos}
      end
      meth getPosition(?Pos)
         pos = {GtkNative.editableGetPosition @nativeObject}
      end
      meth setEditable(IsEditable)
         {GtkNative.editableSetEditable @nativeObject IsEditable}
      end
   end

% -----------------------------------------------------------------------------
% Text
% -----------------------------------------------------------------------------

   class Text from Editable
      attr
         hadjustment
         vadjustment
         lineWrap
         wordWrap
      meth init(Hadj Vadj)
         hadjustment <- Hadj
         vadjustment <- Vadj
         nativeObject = {GtkNative.textNew Hadj Vadj}
         Object, registerObject
      end
      meth setEditable(Editable)
         editable <- Editable
         {GtkNative.textSetEditable @nativeObject Editable}
      end
      meth setWordWrap(WordWrap)
         wordWrap <- WordWrap
         {GtkNative.textSetWordWrap @nativeObject WordWrap}
      end
      meth setLineWrap(LineWrap)
         lineWrap <- LineWrap
         {GtkNative.textSetLineWrap @nativeObject LineWrap}
      end
      meth setAdjustments(Hadj Vadj)
         hadjustment <- Hadj
         vadjustment <- Vadj
         {GtkNative.textSetAdjustments @nativeObject Hadj Vadj}
      end
      meth setPoint(Index)
         {GtkNative.textSetPoint @nativeObject Index}
      end
      meth getPoint($)
         {GtkNative.textGetPoint @nativeObject}
      end
      meth getLength($)
         {GtkNative.textGetLength @nativeObject}
      end
      meth freeze
         {GtkNative.textFreeze @nativeObject}
      end
      meth thaw
         {GtkNative.textThaw @nativeObject}
      end
      meth insert(Font ForegroundColor BackgroundColor Chars Length)
         {GtkNative.textInsert
          @nativeObject
          ForegroundColor
          BackgroundColor
          Chars
          Length}
      end
      meth backwardDelete(Nchars)
         {GtkNative.textBackwardDelete @nativeObject Nchars}
      end
      meth forwardDelete(Nchars)
         {GtkNative.textForwardDelete @nativeObject Nchars}
      end
   end

% -----------------------------------------------------------------------------
% Range
% -----------------------------------------------------------------------------

   class Range from Widget
      attr
         updatePolicy
      meth getAdjustment($)
         {GtkNative.rangeAdjustment @nativeObject}
      end
      meth setUpdatePolicy(Policy)
         {GtkNative.rangeSetUpdatePolicy @nativeObject Policy}
      end
      meth setAdjustment(Adjustment)
         {GtkNative.rangeSetAdjustment
          @nativeObject
          {Adjustment getNative($)}}
      end
      meth drawBackground
         {GtkNative.rangeDrawBackground @nativeObject}
      end
      meth drawTrough
         {GtkNative.rangeDrawTrough @nativeObject}
      end
      meth drawSlider
         {GtkNative.rangeDrawSlider @nativeObject}
      end
      meth drawStepForw
         {GtkNative.rangeDrawStepForw @nativeObject}
      end
      meth drawStepBack
         {GtkNative.rangeDrawStepBack @nativeObject}
      end
      meth drawSliderUpdate
         {GtkNative.rangeSliderUpdate @nativeObject}
      end
      meth troughClick(X Y ?Result ?JumpPerc)
         {GtkNative.rangeTroughClick
          @nativeObject
          X
          Y
          Result
          JumpPerc}
      end
      meth defaultHsliderUpdate
         {GtkNative.rangeDefaultHsliderUpdate @nativeObject}
      end
      meth defaultVsliderUpdate
         {GtkNative.rangeDefaultVsliderUpdate @nativeObject}
      end
      meth defaultHtroughClick(X Y ?Result ?JumpPerc)
         {GtkNative.rangeDefaultHtroughClick
          @nativeObject
          X
          Y
          Result
          JumpPerc}
      end
      meth defaultVtroughClick(X Y ?Result ?JumpPerc)
         {GtkNative.rangeDefaultVtroughClick
          @nativeObject
          X
          Y
          Result
          JumpPerc}
      end
      meth defaultHmotion
         {GtkNative.rangeDefaultHmotion @nativeObject}
      end
      meth defaultVmotion
         {GtkNative.rangeDefaultVmotion @nativeObject}
      end
      meth clearBackground
         {GtkNative.rangeClearBackground @nativeObject}
      end
   end

% -----------------------------------------------------------------------------
% Scale
% -----------------------------------------------------------------------------

   class Scale from Range
      meth setDigits(Digits)
         {GtkNative.scaleSetDigits @nativeObject Digits}
      end
      meth setDrawValue(DrawValue)
         {GtkNative.scaleSetDrawValue @nativeObject DrawValue}
      end
      meth setValuePos(Pos)
         {GtkNative.scaleSetValuePos @nativeObject Pos}
      end
      meth getValueWidth($)
         {GtkNative.scaleGetValueWidth @nativeObject}
      end
   end

% -----------------------------------------------------------------------------
% HScale
% -----------------------------------------------------------------------------

   class HScale from Scale
      attr
         adjustment
      meth init
         nativeObject <- {GtkNative.hscaleNew}
         Object, registerObject
      end
   end

% -----------------------------------------------------------------------------
% VScale
% -----------------------------------------------------------------------------

   class VScale from Scale
      attr
         adjustment
      meth init
         nativeObject <- {GtkNative.vscaleNew}
         Object, registerObject
      end
   end

% -----------------------------------------------------------------------------
% Scrollbar
% -----------------------------------------------------------------------------

   class Scrollbar from Range
   end
% -----------------------------------------------------------------------------
% HScrollbar
% -----------------------------------------------------------------------------

   class HScrollbar from Scrollbar
      attr
         adjustment
      meth init(Adjustment)
         nativeObject <- {GtkNative.hscrollbarNew {Adjustment getNative($)}}
         Object, registerObject
      end
   end

% -----------------------------------------------------------------------------
% VScrollbar
% -----------------------------------------------------------------------------

   class VScrollbar from Scrollbar
      attr
         adjustment
      meth init(Adjustment)
         nativeObject <- {GtkNative.vscrollbarNew {Adjustment getNative($)}}
         Object, registerObject
      end
   end

% -----------------------------------------------------------------------------
% Ruler
% -----------------------------------------------------------------------------

   class Ruler from Widget
      meth setMetric(Metric)
         {GtkNative.rulerSetMetric @nativeObject Metric}
      end
      meth setRange(Lower Upper Position MaxSize)
         {GtkNative.rulerSetRange
          @nativeObject
          Lower
          Upper
          Position
          MaxSize}
      end
      meth drawTicks
         {GtkNative.rulerDrawTicks @nativeObject}
      end
      meth drawPos
         {GtkNative.rulerDrawPos @nativeObject}
      end
   end

% -----------------------------------------------------------------------------
% HRuler
% -----------------------------------------------------------------------------

   class HRuler from Ruler
      meth init
         nativeObject <- {GtkNative.hrulerNew}
         Object, registerObject
      end
   end

% -----------------------------------------------------------------------------
% VRuler
% -----------------------------------------------------------------------------

   class VRuler from Ruler
      meth init
         nativeObject <- {GtkNative.vrulerNew}
         Object, registerObject
      end
   end

% -----------------------------------------------------------------------------
% Separator
% -----------------------------------------------------------------------------

   class Separator from Widget
   % just used to derive HSeparator and VSeparator
   end

% -----------------------------------------------------------------------------
% HSeparator
% -----------------------------------------------------------------------------

   class HSeparator from Separator
      meth init
         nativeObject <- {GtkNative.hseparatorNew}
         Object, registerObject
      end
   end

% -----------------------------------------------------------------------------
% VSeparator
% -----------------------------------------------------------------------------

   class VSeparator from Separator
      meth init
         nativeObject <- {GtkNative.vseparatorNew}
         Object, registerObject
      end
   end

% -----------------------------------------------------------------------------
% Container
% -----------------------------------------------------------------------------

   class Container from Widget
      attr
         borderWidth : 0
         resizeMode  : GTK_RESIZE_PARENT
         child        : 0
      meth add(Widget)
         child <- Widget
         {GtkNative.containerAdd @nativeObject {Widget getNative($)}}
      end
      meth remove(Widget)
         children <- 0
         {GtkNative.containerRemove @nativeObject {Widget getNative($)}}
      end
      meth setResizeMode(ResizeMode)
         {GtkNative.containerSetResizeMode @nativeObject ResizeMode}
      end
      meth checkResize
         {GtkNative.containerCheckResize @nativeObject}
      end
      meth foreach
         skip
         % TODO: Implement this
      end
      meth children($)
         {GtkNative.containerChildren @nativeObject}
      end
      meth focus(Direction Result)
         Result = {GtkNative.containerFocus @nativeObject Direction}
      end
      meth setFocusChild(Child)
         {GtkNative.containerSetFocusChild
          @nativeObject
          {Child getNative($)}}
      end
      meth setFocusVadjustment(Adjustment)
         {GtkNative.containerSetFocusVadjustment
          @nativeObject
          {Adjustment getNative($)}}
      end
      meth setFocusHadjustment(Adjustment)
         {GtkNative.containerSetFocusHadjustment
          @nativeObject
          {Adjustment getNative($)}}
      end
      meth registerToplevel
         {GtkNative.containerRegisterToplevel @nativeObject}
      end
      meth unregisterToplevel
         {GtkNative.containerUnregisterToplevel @nativeObject}
      end
      meth resizeChildren
         {GtkNative.containerResizeChildren @nativeObject}
      end
      meth childType($)
         {GtkNative.containerChildType @nativeObject}
      end
      meth addChildArgType(ArgName ArgType ArgFlags ArgId)
         {GtkNative.containerAddChildArgType
          @nativeObject
          ArgName
          ArgType
          ArgFlags
          ArgId}
      end
      % TODO query_child_
      %      addv
      %      child_set
      meth queueResize
         {GtkNative.containerQueueResize @nativeObject}
      end
      meth clearResizeWidgets
         {GtkNative.containerClearResizeWidgets @nativeObject}
      end
      % TODO: arg_
      %       child_args_collect
      %       child_arg_get_info
      %       forall
      meth childCompositeName(Child ?Name)
         Name = {GtkNative.containerChildCompositeName
                 @nativeObject
                 {Child getNative($)}}
      end
      meth getToplevel($)
         {GtkNative.containerGetToplevel @nativeObject}
      end
      meth setBorderWidth(Width)
         borderWidth <- Width
         {GtkNative.containerSetBorderWidth @nativeObject Width}
      end
   end

% -----------------------------------------------------------------------------
% CList
% -----------------------------------------------------------------------------

   class CList from Container
      attr
         nColumns
         shadowType
         selectionMode
         rowHeight
         reorderable
         titlesActive
         useDragIcons
      meth init(Columns Titles<=nil)
         nativeObject <- case Titles of nil then
                             {GtkNative.clistNew Columns}
                          else
                             {GtkNative.clistNewWithTitles Columns Titles}
                         end
         Object, registerObject
      end
      meth construct(Columns Titles)
         {GtkNative.clistConstruct @nativeObject Columns Titles}
      end
      meth setShadowType(Type)
         {GtkNative.clistSetShadowType @nativeObject Type}
      end
      meth setSelectionMode(Mode)
         {GtkNative.clistSetSelectionMode @nativeObject Mode}
      end
      meth freeze
         {GtkNative.clistFreeze @nativeObject}
      end
      meth thaw
         {GtkNative.clistThaw @nativeObject}
      end
      meth columnTitlesShow
         {GtkNative.clistColumnTitlesShow @nativeObject}
      end
      meth columnTitlesHide
         {GtkNative.clistColumnTitlesHide @nativeObject}
      end
      meth columnTitleActive(Column)
         {GtkNative.clistColumnTitleActive @nativeObject Column}
      end
      meth columnTitlePassive(Column)
         {GtkNative.clistColumnTitlePassive @nativeObject Column}
      end
      meth columnTitlesActive
         {GtkNative.clistColumnTitlesActive @nativeObject}
      end
      meth columnTitlesPassive
         {GtkNative.clistColumnTitlesPassive @nativeObject}
      end
      meth setColumnTitle(Column Title)
         {GtkNative.clistSetColumnTitle @nativeObject Column Title}
      end
      meth setColumnWidget(Column Widget)
         {GtkNative.clistSetColumnWidget
          @nativeObject
          Column
          {Widget getNative($)}}
      end
      meth setColumnJustification(Column Justification)
         {GtkNative.clistSetColumnJustification @nativeObject Justification}
      end
      meth setColumnVisibility(Column Visibibe)
         {GtkNative.clistSetColumnVisibility @nativeObject Visibibe}
      end
      meth setColumnResizeable(Column Resizeable)
         {GtkNative.clist_set_columnResizeable @nativeObject Resizeable}
      end
      meth setColumnAutoResize(Column AutoResize)
         {GtkNative.clistSetColumnAutoResize
          @nativeObject
          Column
          AutoResize}
      end
      meth optimalColumnWidth(Column)
         {GtkNative.clistOptimalColumnWidth @nativeObject Column}
      end
      meth setColumnWidth(Column Width)
         {GtkNative.clistSetColumnWidth @nativeObject Column Width}
      end
      meth setColumnMinWidth(Column MaxWidth)
         {GtkNative.clistSetColumnMinWidth @nativeObject Column MaxWidth}
      end
      meth setColumnMaxWidth(Column MinWidth)
         {GtkNative.clistSetColumnMaxWidth @nativeObject Column MinWidth}
      end
      meth setRowHeight(Row Height)
         {GtkNative.clistSetRowHeight @nativeObject Row Height}
      end
      meth moveto(Row Column RowAlign ColAlign)
         {GtkNative.clistMoveto @nativeObject Row Column RowAlign ColAlign}
      end
      meth rowIsVisible(Row ?IsVisible)
         IsVisible = {GtkNative.clistRowIsVisible @nativeObject Row}
      end
      meth getCellType(Row Column ?Type)
         Type = {GtkNative.clistGetCellType @nativeObject Row Column}
      end
      meth setText(Row Column Text)
         {GtkNative.clistSetText @nativeObject Row Column Text}
      end
      meth getText(Row Column ?Result ?Text)
         {GtkNative.clistGetText @nativeObject Row Column Result Text}
      end
      meth setPixmap(Row Column Pixmap Mask)
         {GtkNative.clistSetPixmap @nativeObject Row Column Pixmap Mask}
      end
      meth getPixmap(Row Column ?Result ?Pixmap ?Mask)
         {GtkNative.clistGetPixmap
          @nativeObject
          Row
          Column
          Result
          Pixmap
          Mask}
      end
      meth setPixtext(Row Column Text Spacing Pixmap Mask)
         {GtkNative.clistSetPixtext
          @nativeObject
          Row
          Column
          Text
          Spacing
          Pixmap
          Mask}
      end
      meth getPixtext(Row Column ?Result ?Text ?Spacing ?Pixmap ?Mask)
         {GtkNative.clistGetPixtext
          @nativeObject
          Row
          Column
          Result
          Text
          Spacing
          Pixmap
          Mask}
      end
      meth setForeground(Row Color)
         {GtkNative.clistSetForeground @nativeObject Row Color}
      end
      meth setBackground(Row Color)
         {GtkNative.clistSetBackground @nativeObject Row Color}
      end
      meth setCellStyle(Row Column Style)
         {GtkNative.clistSetCellStyle @nativeObject Row Column Style}
      end
      meth getCellStyle(Row Column ?Style)
         Style = {GtkNative.clistSetCellStyle @nativeObject Row Column}
      end
      meth setRowStyle(Row Style)
         {GtkNative.clistSetRowStyle @nativeObject Row Style}
      end
      meth getRowStyle(Row ?Style)
         Style = {GtkNative.clistGetRowStyle @nativeObject Row}
      end
      meth setShift(Row Column Vertical Horizontal)
         {GtkNative.clistSetShift
          @nativeObject
          Row
          Column
          Vertical
          Horizontal}
      end
      meth setSelectable(Row Selectable)
         {GtkNative.clistSetSelectable @nativeObject Row Selectable}
      end
      meth getSelectable(Row ?Selectable)
         Selectable = {GtkNative.clist_get_selectable @nativeObject Row}
      end
      meth prepend(TextList)
         {GtkNative.clistPrepend @nativeObject TextList}
      end
      meth append(TextList)
         {GtkNative.clistAppend @nativeObject TextList}
      end
      meth insert(Row TextList)
         {GtkNative.clistInsert @nativeObject Row TextList}
      end
      meth remove(Row)
         {GtkNative.clistRemove @nativeObject Row}
      end
      % TODO: Support Data ???
      meth selectRow(Row Column)
         {GtkNative.clistSelectRow @nativeObject Row Column}
      end
      meth unselectRow(Row Column)
         {GtkNative.clistUnselectRow @nativeObject Row Column}
      end
      meth undoSelection
         {GtkNative.clistUndoSelection @nativeObject}
      end
      meth clear
         {GtkNative.clistClear @nativeObject}
      end
      meth getSelectionInfo(X Y ?Result ?Row ?Column)
         {GtkNative.clistGetSelectionInfo
          @nativeObject
          X
          Y
          Result
          Row
          Column}
      end
      meth selectAll
         {GtkNative.clistSelectAll @nativeObject}
      end
      meth unselectAll
         {GtkNative.clistUnselectAll @nativeObject}
      end
      meth swapRows(Row1 Row2)
         {GtkNative.clistSwapRows @nativeObject Row1 Row2}
      end
      % TODO: Compare Function
      meth setSortColumn(Column)
         {GtkNative.clistSetSortColumn @nativeObject Column}
      end
      meth setSortType(Sort_type)
         {GtkNative.clistSetSortType @nativeObject Sort_type}
      end
      meth sort
         {GtkNative.clistSort @nativeObject}
      end
      meth setAutoSort(AutoSort)
         {GtkNative.clistSetAutoSort @nativeObject AutoSort}
      end
      meth columnsAutosize
         {GtkNative.clistColumnsAutosize @nativeObject}
      end
      meth getColumnTitle(Column ?Title)
         Title = {GtkNative.clistGetColumnTitle @nativeObject Column}
      end
      meth getColumnWidget(Column ?Widget)
         % TODO: Get Oz object, not native widget
         Widget = {GtkNative.clistGetColumnWidget @nativeObject Column}
      end
      meth getHadjustment(?Adjustment)
         Adjustment = {GtkNative.clistGetHadjustment @nativeObject}
      end
      meth getVadjustment(?Adjustment)
         Adjustment = {GtkNative.clistGetVadjustment @nativeObject}
      end
      meth rowMove(SourceRow DestRow)
         {GtkNative.clistRowMove @nativeObject SourceRow DestRow}
      end
      meth setButtonActions(Button ButtonActions)
         {GtkNative.clistSetButtonActions @nativeObject Button ButtonActions}
      end
      meth setHadjustment(Hadjustment)
         {GtkNative.clistSetHadjustment
          @nativeObject
          {Hadjustment getNative($)}}
      end
      meth setReorderable(Reorderable)
         {GtkNative.clistSetReorderable @nativeObject Reorderable}
      end
      meth setUserDragIcons(UseIcons)
         {GtkNative.clistSetUseDragIcons @nativeObject UseIcons}
      end
      meth setVadjustment(Vadjustment)
         {GtkNative.clistSetVadjustment
          @nativeObject
          {Vadjustment getNative($)}}
      end
   end

% -----------------------------------------------------------------------------
% Fixed
% -----------------------------------------------------------------------------

   class Fixed from Container
      meth init
         nativeObject <- {GtkNative.fixedNew}
         Object, registerObject
      end
      meth put(Child X Y)
         {GtkNative.fixedPut @nativeObject {Child getNative($)} X Y}
      end
      meth move(Child X Y)
         {GtkNative.fixedMove @nativeObject {Child getNative($)} X Y}
      end
   end

% -----------------------------------------------------------------------------
% Layout
% -----------------------------------------------------------------------------

   class Layout from Container
      meth init(Hadjustment Vadjustment)
         nativeObject <- {GtkNative.layoutNew
                           {Hadjustment getNative($)}
                          {Vadjustment getNative($)}}
         Object, registerObject
      end
      meth put(Widget X Y)
         {GtkNative.layoutPut
          @nativeObject
          {Widget getNative($)}
          X
          Y}
      end
      meth move(Widget X Y)
         {GtkNative.layoutMove
          @nativeObject
          {Widget getNative($)}
          X
          Y}
      end
      meth setSize(Width Height)
         {GtkNative.layoutSetSize @nativeObject Width Height}
      end
      meth freeze
         {GtkNative.layoutFreeze @nativeObject}
      end
      meth thaw
         {GtkNative.layoutThaw @nativeObject}
      end
      meth getHadjustment($)
         {GtkNative.layoutGetHadjustment @nativeObject}
      end
      meth getVadjustment($)
         {GtkNative.layoutGetVadjustment @nativeObject}
      end
      meth setHadjustment(Hadjustment)
         {GtkNative.layoutSetHadjustment
          @nativeObject
          {Hadjustment getNative($)}}
      end
      meth setVadjustment(Vadjustment)
         {GtkNative.layoutSetVadjustment
          @nativeObject
          {Vadjustment getNative($)}}
      end
   end

% -----------------------------------------------------------------------------
% List
% -----------------------------------------------------------------------------

% There is a name clash between the List class and the List module
% so the List class is named GList and exported as 'list'

   class GList from Container
      meth init
         nativeObject <- {GtkNative.listNew}
         Object, registerObject
      end
      meth insertItems(Items Position)
         {GtkNative.listInsertItems
          @nativeObject
          {List.map Items fun {$ Object} {Object getNative($)} end $}
          Position}
      end
      meth appendItems(Items)
         {GtkNative.listAppendItems
          @nativeObject
          {List.map Items fun {$ Object} {Object getNative($)} end $}}
      end
      meth prependItems(Items)
         {GtkNative.listPrependItems
          @nativeObject
          {List.map Items fun {$ Object} {Object getNative($)} end $}}
      end
      meth removeItems(Items)
         {GtkNative.listRemoveItems
          @nativeObject
          {List.map Items fun {$ Object} {Object getNative($)} end $}}
      end
      meth removeItemsNoUnref(Items)
         {GtkNative.listRemoveItemsNounref
          @nativeObject
          {List.map Items fun {$ Object} {Object getNative($)} end $}}
      end
      meth clearItems(Start End)
         {GtkNative.listClearItems @nativeObject Start End}
      end
      meth selectItem(Item)
         {GtkNative.listSelectItem @nativeObject Item}
      end
      meth unselectItem(Item)
         {GtkNative.listUnselectItem @nativeObject Item}
      end
      meth childPosition(Child ?Position)
         Position = {GtkNative.listChildPosition
                     @nativeObject
                     {Child getNative($)}}
      end
      meth setSelectionMode(Mode)
         {GtkNative.listSetSelectionMode @nativeObject Mode}
      end
      meth extendSelection(ScrollType Position AutoStartSelection)
         {GtkNative.listExtendSelection
          @nativeObject
          ScrollType
          Position
          AutoStartSelection}
      end
      meth startSelection
         {GtkNative.listStartSelection @nativeObject}
      end
      meth endSelection
         {GtkNative.listEndSelection @nativeObject}
      end
      meth selectAll
         {GtkNative.listSelectAll @nativeObject}
      end
      meth unselectAll
         {GtkNative.listUnselectAll @nativeObject}
      end
      meth scrollHorizontal(ScrollType Position)
         {GtkNative.listScrollHorizontal @nativeObject ScrollType Position}
      end
      meth scrollVertical(ScrollType Position)
         {GtkNative.listScrollVertical @nativeObject ScrollType Position}
      end
      meth toggleAddMode
         {GtkNative.listToggleAddMode @nativeObject}
      end
      meth toggleFocusRow
         {GtkNative.listToggleFocusRow @nativeObject}
      end
      meth toggleRow(Item)
         {GtkNative.listToggleRow
          @nativeObject
          {Item getNative($)}}
      end
      meth undoSelection
         {GtkNative.listUndoSelection @nativeObject}
      end
      meth endDragSelection
         {GtkNative.listEndDragSelection @nativeObject}
      end
   end

% -----------------------------------------------------------------------------
% MenuShell
% -----------------------------------------------------------------------------

   class MenuShell from Container
      meth append(Child)
         {GtkNative.menuShellAppend @nativeObject {Child getNative($)}}
      end
      meth prepend(Child)
         {GtkNative.menuShellPrepend @nativeObject {Child getNative($)}}
      end
      meth insert(Child Position)
         {GtkNative.menuShellInsert
          @nativeObject
          {Child getNative($)}
          Position}
      end
      meth deactivate
         {GtkNative.menuShellDeactivate @nativeObject}
      end
      meth selectItem(MenuItem)
         {GtkNative.menuShellSelectItem
          @nativeObject
          {MenuItem getNative($)}}
      end
      meth activateItem(MenuItem ForceDeactivation)
         {GtkNative.menuShellActivateItem
          @nativeObject
          {MenuItem getNative($)}
          ForceDeactivation}
      end
   end

% -----------------------------------------------------------------------------
% Notebook
% -----------------------------------------------------------------------------

   class Notebook from Container
      attr
         page
         tabPos      : 2
         tabBorder
         tabHborder
         tabVborder
         showTabs    : 1
         showBorder  : 1
         scrollable  : 1
         enablePopup
      meth init
         nativeObject <- {GtkNative.notebookNew}
         Object, registerObject
      end
      meth appendPage(Child TabLabel)
         {GtkNative.notebookAppendPage
          @nativeObject
          {Child getNative($)}
          {TabLabel getNative($)}}
      end
      meth appendPageMenu(Child TabLabel MenuLabel)
         {GtkNative.notebookAppendPage
          @nativeObject
          {Child getNative($)}
          {TabLabel getNative($)}
          {MenuLabel getNative($)}}
      end
      meth prependPage(Child TabLabel)
         {GtkNative.notebookPrependPage
          @nativeObject
          {Child getNative($)}
          {TabLabel getNative($)}}
      end
      meth prependPageMenu(Child TabLabel MenuLabel)
         {GtkNative.notebookPrependPage
          @nativeObject
          {Child getNative($)}
          {TabLabel getNative($)}
          {MenuLabel getNative($)}}
      end
      meth insertPage(Child TabLabel Position)
         {GtkNative.notebookInsertPage
          @nativeObject
          {Child getNative($)}
          {TabLabel getNative($)}
          Position}
      end
      meth insertPageMenu(Child TabLabel MenuLabel Position)
         {GtkNative.notebookInsertPage
          @nativeObject
          {Child getNative($)}
          {TabLabel getNative($)}
          {MenuLabel getNative($)}
          Position}
      end
      meth removePage(PageNum)
         {GtkNative.notebookRemovePage @nativeObject PageNum}
      end
      meth pageNum(Child ?Ret)
         {GtkNative.notebookPageNum
          @nativeObject
          {Child getNative($)}
          Ret}
      end
      meth setPage(PageNum)
         page <- PageNum
         {GtkNative.notebookSetPage @nativeObject PageNum}
      end
      meth next_page
         {GtkNative.notebookNextPage @nativeObject}
      end
      meth prev_page
         {GtkNative.notebookPrevPage @nativeObject}
      end
      meth reorder_child(Child Position)
         {GtkNative.notebookPrevPage
          @nativeObject
          {Child getNative($)}
          Position}
      end
      meth setTabPos(Pos)
         {GtkNative.notebookSetTabPos @nativeObject Pos}
      end
      meth setShowTabs(ShowTabs)
         {GtkNative.notebookSetShowTabs @nativeObject ShowTabs}
      end
      meth setShowBorder(ShowBorder)
         {GtkNative.notebookSetShowBorder @nativeObject ShowBorder}
      end
      meth setScrollable(Scrollabel)
         {GtkNative.notebookSetScrollabel @nativeObject Scrollabel}
      end
      meth setTabBorder(BorderWidth)
         {GtkNative.notebookSetTabBorder @nativeObject BorderWidth}
      end
      meth popupEnable
         {GtkNative.notebookPopupEnable @nativeObject}
      end
      meth popupDisable
         {GtkNative.notebookPopupDisable @nativeObject}
      end
      meth getCurrentPage($)
         {GtkNative.notebookPopupGetCurrentPage @nativeObject}
      end
      meth getMenuLabel(Child ?Label)
         Label = {GtkNative.notebookGetMenuLabel
                  @nativeObject
                  {Child getNative($)}}
      end
      meth getNthPage(PageNum ?Page)
         Page = {GtkNative.notebookGetNthPage
                 @nativeObject
                 PageNum}
      end
      meth getTabLabel(Child ?Label)
         Label = {GtkNative.notebookGetNthPage
                  @nativeObject
                  {Child getNative($)}}
      end
      meth queryTabLabelPacking(Child ?Expand ?Fill ?PackType)
         {GtkNative.notebookQueryTabLabelPacking
          {Child getNative($)}
          Expand
          Fill
          PackType}
      end
      meth setHomogeneousTabs(Homogeneous)
         {GtkNative.notebookSetHomogeneousTabs @nativeObject Homogeneous}
      end
      meth setMenuLabel(Child MenuLabel)
         {GtkNative.notebookSetMenuLabel
          @nativeObject
          {Child getNative($)}
          {MenuLabel getNative($)}}
      end
      meth setMenuLabelText(Child MenuText)
         {GtkNative.notebookSetMenuLabel
          @nativeObject
          {Child getNative($)}
          MenuText}
      end
      meth setTabHborder(TabHborder)
         {GtkNative.notebookSetTabHborder @nativeObject TabHborder}
      end
      meth setTabLabel(Child TabLabel)
         {GtkNative.notebookSetTabLabel
          @nativeObject
          {Child getNative($)}
          {TabLabel getNative($)}}
      end
      meth setTabLabelPacking(Child Expand Fill PackType)
         {GtkNative.notebookSetTabLabelPacking
          @nativeObject
          {Child getNative($)}
          Expand
          Fill
          PackType}
      end
      meth setTabLabelText(Child TabText)
         {GtkNative.notebookSetTabLabelText
          @nativeObject
          {Child getNative($)}
          TabText}
      end
      meth setTabVborder(TabVborder)
         {GtkNative.notebookSetTabVborder @nativeObject TabVborder}
      end
   end

% -----------------------------------------------------------------------------
% FontSelection
% -----------------------------------------------------------------------------

   class FontSelection from Notebook
      meth init
         nativeObject <- {GtkNative.fontSelectionNew}
         Object, registerObject
      end
      meth getFont($)
         {GtkNative.fontSelectionGetFont @nativeObject}
      end
      meth getFontName($)
         {GtkNative.fontSelectionGetFontName @nativeObject}
      end
      meth setFontName(Fontname ?Ret)
         Ret = {GtkNative.fontSelectionSetFontName @nativeObject Fontname}
      end
      meth getPreviewText($)
         {GtkNative.fontSelectionGetPreviewText @nativeObject}
      end
      meth setPreviewText(Text)
         {GtkNative.fontSelectionSetPreviewText @nativeObject Text}
      end
      meth setFilter(FilterType FontType Foundries Weigths Slants Setwidths Spacings Charsets)
         {GtkNative.fontSelectionSetFilter
          @nativeObject
          FilterType
          FontType
          Foundries
          Weigths
          Slants
          Setwidths
          Spacings
          Charsets}
      end
   end

% -----------------------------------------------------------------------------
% Paned
% -----------------------------------------------------------------------------

   class Paned from Container
      meth add1(Child)
         {GtkNative.paned_add1 @nativeObject {Child getNative($)}}
      end
      meth add2(Child)
         {GtkNative.paned_add2 @nativeObject {Child getNative($)}}
      end
      meth computePosition(Allocation Child1Req Child2Req)
         {GtkNative.panedComputePosition
          @nativeObject
          Allocation
          Child1Req
          Child2Req}
      end
      meth pack1(Child Resize Shrink)
         {GtkNative.panedPack1
          @nativeObject
          {Child getNative($)}
          Resize
          Shrink}
      end
      meth pack2(Child Resize Shrink)
         {GtkNative.panedPack2
          @nativeObject
          {Child getNative($)}
          Resize
          Shrink}
      end
      meth setGutterSize(Size)
         {GtkNative.paned_set_gutter_size @nativeObject Size}
      end
      meth setPosition(Position)
         {GtkNative.panedSetPosition @nativeObject Position}
      end
   end

% -----------------------------------------------------------------------------
% HPaned
% -----------------------------------------------------------------------------

   class HPaned from Paned
      meth init
         nativeObject <- {GtkNative.hpanedNew}
         Object, registerObject
      end
   end

% -----------------------------------------------------------------------------
% VPaned
% -----------------------------------------------------------------------------

   class VPaned from Paned
      meth init
         nativeObject <- {GtkNative.vpanedNew}
         Object, registerObject
      end
   end

% -----------------------------------------------------------------------------
% Bin
% -----------------------------------------------------------------------------

   class Bin from Container
      % not useful but it is in GTK
   end

% -----------------------------------------------------------------------------
% Alignment
% -----------------------------------------------------------------------------

   class Alignment from Bin
      attr
         xalign
         yalign
         xscale
         yscale
      meth init(Xalign Yalign Xscale Yscale)
         xalign <- Xalign
         yalign <- Yalign
         xscale <- Xscale
         yscale <- Yscale
         nativeObject <- {GtkNative.alignmentNew Xalign Yalign Xscale Yscale}
         Object, registerObject
      end
      meth set(Xalign Yalign Xscale Yscale)
         xalign <- Xalign
         yalign <- Yalign
         xscale <- Xscale
         yscale <- Yscale
         {GtkNative.alignmentSet @nativeObject Xalign Yalign Xscale Yscale}
      end
   end

% -----------------------------------------------------------------------------
% Frame
% -----------------------------------------------------------------------------

   class Frame from Bin
      attr
         label
         label_xalign
         label_yalign
         shadow
      meth init(Label)
         label         <- Label
         nativeObject <- {GtkNative.frameNew Label}
         Object, registerObject
      end
      meth setLabel(Label)
         label         <- Label
         {GtkNative.frameSetLabel @nativeObject Label}
      end
      meth setLabelAlign(Xalign Yalign)
         label_xaling <- Xalign
         label_yalign <- Yalign
         {GtkNative.frameSetLabelAlign @nativeObject Xalign Yalign}
      end
      meth set_shadow_type(Type)
         shadow <- Type
         {GtkNative.frameSetShadowType @nativeObject Type}
      end
   end

% -----------------------------------------------------------------------------
% AspectFrame
% -----------------------------------------------------------------------------

   class AspectFrame from Frame
      meth init(Label Xalign Yalign Ratio ObeyChild)
         label <- Label
         nativeObject <- {GtkNative.aspectFrameNew
                           Label
                           Xalign
                           Yalign
                           Ratio
                          ObeyChild}
         Object, registerObject
      end
      meth set(Xalign Yalign Ratio ObeyChild)
         {GtkNative.aspectFrameSet
          @nativeObject
          Xalign
          Yalign
          Ratio
          ObeyChild}
      end
   end

% -----------------------------------------------------------------------------
% Item
% -----------------------------------------------------------------------------

   class Item from Bin
      meth select
         {GtkNative.itemSelect @nativeObject}
      end
      meth deselect
         {GtkNative.itemDeselect @nativeObject}
      end
      meth toggle
         {GtkNative.itemToggle @nativeObject}
      end
   end

% -----------------------------------------------------------------------------
% MenuItem
% -----------------------------------------------------------------------------

   class MenuItem from Item
      meth init(Label<=false)
         nativeObject <- case Label of false then
                             {GtkNative.menuItemNew}
                          else
                             {GtkNative.menuItemNewWithLabel Label}
                         end
         Object, registerObject
      end
      meth setSubmenu(Submenu)
         {GtkNative.menuItemSetSubmenu
          @nativeObject
          {Submenu getNative($)}}
      end
      meth removeSubmenu
         {GtkNative.menuItemRemoveSubmenu @nativeObject}
      end
      meth setPlacement(Placement)
         {GtkNative.menuItemSetPlacement @nativeObject Placement}
      end
      meth configure(Show_toggle_indicator Show_submenu_indicator)
         {GtkNative.menu_item_configure
          @nativeObject
          Show_toggle_indicator
          Show_submenu_indicator}
      end
      meth select
         {GtkNative.menuItemSelect @nativeObject}
      end
      meth deselect
         {GtkNative.menuItemDeselect @nativeObject}
      end
      meth activate
         {GtkNative.menuItemActivate @nativeObject}
      end
      meth rightJustigy
         {GtkNative.menuitemRightJustify @nativeObject}
      end
   end

% -----------------------------------------------------------------------------
% CheckMenuItem
% -----------------------------------------------------------------------------

   class CheckMenuItem from MenuItem
      meth init(Label<=false)
         nativeObject <- case Label of false then
                             {GtkNative.checkMenuItemNew}
                          else
                             {GtkNative.checkMenuItemNewWithLabel Label}
                         end
         Object, registerObject
      end
      meth setActive(IsActive)
         {GtkNative.checkMenuItemSetActive @nativeObject IsActive}
      end
      meth setShowToggle(Always)
         {GtkNative.checkMenuItemSetShowToggle @nativeObject Always}
      end
      meth toggles
         {GtkNative.checkMenuItemToggled @nativeObject}
      end
   end

% -----------------------------------------------------------------------------
% Box
% -----------------------------------------------------------------------------

   class Box from Container
      attr
         spacing     : 0
         homogeneous : false
      meth packStart(Child Expand<=true Fill<=true Padding<=0)
         {GtkNative.boxPackStart
          @nativeObject
          {Child getNative($)}
          Expand
          Fill
          Padding}
      end
      meth packEnd(Child Expand<=true Fill<=true Padding<=0)
         {GtkNative.boxPackEnd
          @nativeObject
          {Child getNative($)}
          Expand
          Fill
          Padding}
      end
      % pack_start_defaults and pack_end_defaults are superfluous
      meth setHomogeneous(Homogeneous)
         homogeneous <- Homogeneous
         {GtkNative.boxSetHomogeneous @nativeObject Homogeneous}
      end
      meth setSpacing(Spacing)
         spacing <- Spacing
         {GtkNative.boxSetSpacing @nativeObject Spacing}
      end
      meth reorderChild(Child Position)
         {GtkNative.boxReorderChild
          @nativeObject
          {Child getNative($)}
          Position}
      end
      meth queryChildPacking(Child Expand Fill Padding PackType)
         {GtkNative.boxQueryChildPacking
          @nativeObject
          {Child getNative($)}
          Expand
          Fill
          Padding
          PackType}
      end
      meth setChildPacking(Child Expand Fill Padding PackType)
         {GtkNative.boxQueryChildPacking
          @nativeObject
          {Child getNative($)}
          Expand
          Fill
          Padding
          PackType}
      end
   end

% -----------------------------------------------------------------------------
% Table
% -----------------------------------------------------------------------------

   class Table from Container
      attr
         nRows
         nColumns
         rowSpacing
         columnSpacing
         homogeneous
      meth init(Rows Columns Homogeneous)
         nRows <- Rows
         nColumns <- Columns
         homogeneous <- Homogeneous
         nativeObject <- {GtkNative.tableNew Rows Columns Homogeneous}
         Object, registerObject
      end
      meth resize(Rows Columns)
         nRows <- Rows
         nColumns <- Columns
         {GtkNative.tableResize Rows Columns}
      end
      meth attach(Child LeftAttach RightAttach TopAttach BottomAttach
                  Xoptions Yoptions Xpadding Ypadding)
         {GtkNative.tableAttach
          @nativeObject
          {Child getNative($)}
          LeftAttach
          RightAttach
          TopAttach
          BottomAttach
          Xoptions
          Yoptions
          Xpadding
          Ypadding}
      end
      meth setRowSpacing(Row Spacing)
         {GtkNative.tableSetRowSpacing @nativeObject Row Spacing}
      end
      meth setColSpacing(Col Spacing)
         {GtkNative.tableSetColSpacing @nativeObject Col Spacing}
      end
      meth setRowSpacings(Spacing)
         {GtkNative.tableSetRowSpacings @nativeObject Spacing}
      end
      meth setColSpacings(Spacing)
         {GtkNative.tableSetColSpacings @nativeObject Spacing}
      end
      meth setHomogeneous(Homogeneous)
         {GtkNative.tableSetHomogeneous @nativeObject Homogeneous}
      end
   end

% -----------------------------------------------------------------------------
% ScrolledWindow
% -----------------------------------------------------------------------------

   class ScrolledWindow from Bin
      meth init(Hadjustment<=nil Vadjustment<=nil)
         Hadj
         Vadj
      in
         Hadj = if Hadjustment == nil then {New Adjustment init(0.0 0.0 0.0 0.0 0.0 0.0)} else Hadjustment end
         Vadj = if Vadjustment == nil then {New Adjustment init(0.0 0.0 0.0 0.0 0.0 0.0)} else Vadjustment end

         nativeObject <- {GtkNative.scrolledWindowNew {Hadj getNative($)} {Vadj getNative($)}}

         Object,registerObject
      end
      meth getHadjustment($)
         {GetObject {GtkNative.scrolledWindowGetHadjustment @nativeObject $} $}
      end
      meth getVadjustment($)
         {GetObject {GtkNative.scrolledWindowGetVadjustment @nativeObject $} $}
      end
      meth setPolicy(HscrollbarPolicy VscrollbarPolicy)
         {GtkNative.scrolledWindowSetPolicy @nativeObject HscrollbarPolicy VscrollbarPolicy}
      end
      meth addWithViewport(Child)
         {GtkNative.scrolledWindowAddWithViewport @nativeObject {Child getNative($)}}
      end
      meth setHadjustment(Hadjustment)
         {GtkNative.scrolledWindowSetHadjustment @nativeObject {Hadjustment getNative($)}}
      end
      meth setPlacement(WindowPlacement)
         {GtkNative.scrolledWindowSetPlacement @nativeObject WindowPlacement}
      end
      meth setVadjustment(Vadjustment)
         {GtkNative.scrolledWindowSetVadjustment @nativeObject {Vadjustment getNative($)}}
      end
   end

% -----------------------------------------------------------------------------
% Window
% -----------------------------------------------------------------------------

   class Window from Bin
      attr
         type
         title           : ""
         auto_shrink     : false
         allow_shrink    : false
         allow_grow      : true
         modal           : false
         window_position : GTK_WIN_POS_NONE
      meth init(Window_type<=GTK_WINDOW_TOPLEVEL)
         type            <- Window_type
         nativeObject    <- {GtkNative.windowNew Window_type}
         Object, registerObject
      end
      meth setTitle(Title)
         title <- Title
         {GtkNative.windowSetTitle @nativeObject Title}
      end
      meth setWMClass(WMClassName WMClassClass)
         {GtkNative.windowSetWMClass @nativeObject WMClassName WMClassClass}
      end
      meth setFocus(Focus)
         {GtkNative.windowSetFocus @nativeObject {Focus getNative($)}}
      end
      meth setDefault(Default)
         {GtkNative.windowSetDefault @nativeObject {Default getNative($)}}
      end
      meth setPolicy(AllowShrink AllowGrow AutoShrink)
         {GtkNative.windowSetPolicy @nativeObject AllowShrink AllowGrow AutoShrink}
      end
   end

% -----------------------------------------------------------------------------
% ColorSelectionDialog
% -----------------------------------------------------------------------------

   class ColorSelectionDialog from Window
      attr
         colorsel
         cancelButton
         okButton
      meth init(Title)
         title         <- Title
         nativeObject  <- {GtkNative.colorSelectionDialogNew Title}
         colorsel      <- {New ColorSelection initNative({GtkNative.colorSelectionDialogColorsel
                                                          @nativeObject
                                                          $})}
         cancelButton  <- {New Button initNative({GtkNative.colorSelectionDialogCancelButton
                                                  @nativeObject
                                                  $})}
         okButton      <- {New Button initNative({GtkNative.colorSelectionDialogOkButton
                                                  @nativeObject
                                                  $})}
         Object, registerObject
      end
      meth colorsel($)
         @colorsel
      end
      meth okButton($)
         @okButton
      end
      meth cancelButton($)
         @cancelButton
      end
   end

% -----------------------------------------------------------------------------
% Dialog
% -----------------------------------------------------------------------------

   class Dialog from Window
      attr
         window
         vbox
         actionArea
      meth init
         nativeObject <- {GtkNative.dialogNew}
         window       <- {New Window initNative({GtkNative.dialogWindow
                                                 @nativeObject
                                                 $})}
         vbox         <- {New VBox initNative({GtkNative.dialogVbox
                                               @nativeObject
                                               $})}
         actionArea   <- {New HBox initNative({GtkNative.dialogActionArea
                                               @nativeObject
                                               $})}
         Object, registerObject
      end
      meth window($)
         @window
      end
      meth vbox($)
         @vbox
      end
      meth actionArea($)
         @actionArea
      end
   end

% -----------------------------------------------------------------------------
% FileSelection
% -----------------------------------------------------------------------------

   class FileSelection from Window
      meth init(Title)
         title <- Title
         nativeObject <- {GtkNative.fileSelectionNew Title}
         Object, registerObject
         {System.show filesel}
      end
      meth setFilename(Filename)
         {GtkNative.fileSelectionSetFilename @nativeObject Filename}
      end
      meth getFilename($)
         {GtkNative.fileSelectionGetFilename @nativeObject}
      end
      meth complete(Pattern)
         {GtkNative.fileSelectionComplete @nativeObject Pattern}
      end
      meth showFileopButtons
         {GtkNative.fileSelectionShowFileopButtons @nativeObject}
      end
      meth hideFileopButtons
         {GtkNative.fileSelectionHideFileopButtons @nativeObject}
      end
   end

% -----------------------------------------------------------------------------
% FontSelectionDialog
% -----------------------------------------------------------------------------

   class FontSelectionDialog from Window
      meth init(Title)
         nativeObject <- {GtkNative.fontSelectionDialogNew Title}
         Object, registerObject
      end
      meth getFont($)
         {GtkNative.fontSelectionDialogGetFont @nativeObject}
      end
      meth getFontName($)
         {GtkNative.fontSelectionDialogGetFontName @nativeObject}
      end
      meth setFontName(Fontname ?Ret)
         Ret = {GtkNative.fontSelectionDialogSetFontName @nativeObject Fontname}
      end
      meth getPreviewText($)
         {GtkNative.fontSelectionDialogGetPreviewText @nativeObject}
      end
      meth setPreviewText(Text)
         {GtkNative.fontSelectionDialogSetPreviewText @nativeObject Text}
      end
      meth setFilter(FilterType FontType Foundries Weigths Slants SetWidths Spacings Charsets)
         {GtkNative.fontSelectionDialogSetFilter
          @nativeObject
          FilterType
          FontType
          Foundries
          Weigths
          Slants
          SetWidths
          Spacings
          Charsets}
      end
   end

% -----------------------------------------------------------------------------
% Button
% -----------------------------------------------------------------------------

   class Button from Bin
      attr
         label  : ""
         reliefStyle : GTK_RELIEF_NORMAL
      meth init
         nativeObject <- {GtkNative.buttonNew}
         Object, registerObject
      end
      meth initWithLabel(Label)
         label         <- Label
         nativeObject <- {GtkNative.buttonNewWithLabel Label}
      end
      meth getRelief($)
         @relief_style
      end
      meth setRelief(ReliefStyle)
         reliefStyle <- ReliefStyle
         {GtkNative.buttonSetRelief @nativeObject ReliefStyle}
      end
   end

% -----------------------------------------------------------------------------
% OptionMenu
% -----------------------------------------------------------------------------

   class OptionMenu from Button
      meth init
         nativeObject <- {GtkNative.optionMenuNew}
         Object, registerObject
      end
      meth getMenu(?Menu)
         Menu = {GtkNative.optionMenuGetMenu @nativeObject}
      end
      meth setMenu(Menu)
         {GtkNative.optionMenuSetMenu @nativeObject {Menu getNative($)}}
      end
      meth removeMenu
         {GtkNative.optionMenuRemoveMenu @nativeObject}
      end
      meth setHistory(Index)
         {GtkNative.optionMenuSetHistory @nativeObject Index}
      end
   end

% -----------------------------------------------------------------------------
% ToggleButton
% -----------------------------------------------------------------------------

   class ToggleButton from Button
      meth init(Label<=false)
         nativeObject <- case Label of false then
                             {GtkNative.toggleButtonNew}
                          else % Label should be a string
                             {GtkNative.toggleButtonNewWithLabel Label}
                         end
         Object, registerObject
      end
      % init_with_label is obsolete
      meth setMode(DrawIndicator)
         {GtkNative.toggleButtonSetMode @nativeObject DrawIndicator}
      end
      meth toggled
         {GtkNative.toggleButtonToggled @nativeObject}
      end
      meth getActive($)
         {GtkNative.toggleButtonGetActive @nativeObject}
      end
      meth setActive(Is_active)
         {GtkNative.toggleButtonSetActive @nativeObject Is_active}
      end
   end

% -----------------------------------------------------------------------------
% CheckButton
% -----------------------------------------------------------------------------

   class CheckButton from ToggleButton
      meth init(Label<=nil)
         nativeObject <- case Label of nil then
                             {GtkNative.checkButtonNew}
                          else
                             {GtkNative.checkButtonNewWithLabel Label}
                         end
         Object, registerObject
      end
   end

% -----------------------------------------------------------------------------
% RadioButton
% -----------------------------------------------------------------------------

   class RadioButton from CheckButton
      attr group
      meth init(Group)
         nativeObject <- {GtkNative.radioButtonNew Group}
         Object, registerObject
      end
      meth initFromWidget(Group)
         nativeObject <- {GtkNative.radioButtonNewFromWidget {Group getNative($)}}
         Object, registerObject
      end
      meth initWithLabel(Group Label)
         nativeObject <- {GtkNative.radioButtonNewWithLabel Group Label}
         Object, registerObject
      end
      meth initWithLabelFromWidget(Group Label)
         nativeObject <- {GtkNative.radioButtonNewWithLabelFromWidget {Group getNative($)} Label}
         Object, registerObject
      end
      meth group(?Group)
         Group = {GtkNative.radioButtonGroup @nativeObject}
      end
      meth setGroup(Group)
         group <- Group
         {GtkNative.radioButtonSetGroup @nativeObject Group}
      end
   end

% -----------------------------------------------------------------------------
% ButtonBox
% -----------------------------------------------------------------------------

   class ButtonBox from Box
      meth getChildSizeDefaults(Min_width Min_height)
         {GtkNative.buttonBoxGetChildSizeDefaults
          Min_width
          Min_height}
      end
      meth getChildIpaddingDefaults(Ipad_x Ipad_y)
         {GtkNative.buttonBoxGetChildIpaddingDefaults
          Ipad_x
          Ipad_y}
      end
      meth setChildSizeDefaults(Min_width Min_height)
         {GtkNative.button_box_set_child_size_defaults
          Min_width
          Min_height}
      end
      meth setChildIpaddingDefaults(Ipad_x Ipad_y)
         {GtkNative.button_box_set_child_ipadding_defaults
          Ipad_x
          Ipad_y}
      end
      meth getSpacing($)
         {GtkNative.buttonBoxGetSpacing @nativeObject}
      end
      meth getLayout($)
         {GtkNative.buttonBoxGetLayout @nativeObject}
      end
      meth getChildSize(Min_width Min_height)
         {GtkNative.buttonBoxGetChildSize
          @nativeObject
          Min_width
          Min_height}
      end
      meth getChildIpadding(Ipad_x Ipad_y)
         {GtkNative.buttonBoxGetChildSize
          @nativeObject
          Ipad_x
          Ipad_y}
      end
      meth setSpacing(Spacing)
         {GtkNative.buttonBoxSetSpacing
          @nativeObject
          Spacing}
      end
      meth setLayout(LayoutStyle)
         {GtkNative.buttonBoxSetLayout
          @nativeObject
          LayoutStyle}
      end
      meth setChildSize(Min_width Min_height)
         {GtkNative.buttonBoxSetChildSize
          @nativeObject
          Min_width
          Min_height}
      end
      meth setChildIpadding(Ipad_x Ipad_y)
         {GtkNative.buttonBoxSetChildIpadding
          @nativeObject
          Ipad_x
          Ipad_y}
      end
      meth childRequisition(Widget Nvis_children Width Heigth)
         {GtkNative.buttonBoxChildRequisition
          {Widget getNative($)}
          Nvis_children
          Widget
          Heigth}
      end
   end

% -----------------------------------------------------------------------------
% HButtonBox
% -----------------------------------------------------------------------------

   class HButtonBox from ButtonBox
      meth init
         nativeObject <- {GtkNative.hbuttonBoxNew}
         Object, registerObject
      end
      meth getSpacingDefault($)
         {GtkNative.hbuttonBoxGetSpacingDefault}
      end
      meth getLayoutDefault($)
         {GtkNative.hbuttonBoxGetLayoutDefault}
      end
      meth setSpacingDefault(Spacing)
         {GtkNative.hbuttonBoxSetSpacingDefault Spacing}
      end
      meth setLayoutDefault(Layout)
         {GtkNative.hbuttonBoxSetLayoutDefault Layout}
      end
   end

% -----------------------------------------------------------------------------
% VButtonBox
% -----------------------------------------------------------------------------

   class VButtonBox from ButtonBox
      meth init
         nativeObject <- {GtkNative.vbuttonBoxNew}
         Object, registerObject
      end
      meth getSpacingDefault($)
         {GtkNative.vbuttonBoxGetSpacingDefault}
      end
      meth getLayoutDefault($)
         {GtkNative.vbuttonBoxGetLayoutDefault}
      end
      meth setSpacingDefault(Spacing)
         {GtkNative.vbuttonBoxSetSpacingDefault Spacing}
      end
      meth setLayoutDefault(Layout)
         {GtkNative.vbuttonBoxSetLayoutDefault Layout}
      end
   end

% -----------------------------------------------------------------------------
% Menu
% -----------------------------------------------------------------------------

   class Menu from MenuShell
      meth init
         nativeObject <- {GtkNative.menu_new}
         Object, registerObject
      end
      meth append(Child)
         {GtkNative.menuAppend
          @nativeObject
          {Child getNative($)}}
      end
      meth prepend(Child)
         {GtkNative.menuPrepend
          @nativeObject
          {Child getNative($)}}
      end
      meth insert(Child Position)
         {GtkNative.menuInsert
          @nativeObject
          {Child getNative($)}
          Position}
      end
      meth reorderChild(Child Position)
         {GtkNative.menuReorderChild
          @nativeObject
          {Child getNative($)}
          Position}
      end
      meth setTitle(Title)
         {GtkNative.menuSetTitle @nativeObject Title}
      end
      meth popdown
         {GtkNative.menuPopdown @nativeObject}
      end
      meth reposition
         {GtkNative.menuReposition @nativeObject}
      end
      meth getActive($)
         {GtkNative.menuGetActive @nativeObject}
      end
      meth setActive(Index)
         {GtkNative.menuSetActive @nativeObject Index}
      end
      meth setTearoffState(Torn_off)
         {GtkNative.menuSetTearoffState @nativeObject Torn_off}
      end
   end

% -----------------------------------------------------------------------------
% MenuBar
% -----------------------------------------------------------------------------

   class MenuBar from MenuShell
      attr
         shadow : GTK_SHADOW_OUT
      meth init
         nativeObject <- {GtkNative.menuBarNew}
         Object, registerObject
      end
      meth append(Child)
         {GtkNative.menuBarAppend
          @nativeObject
          {Child get_active($)}}
      end
      meth prepend(Child)
         {GtkNative.menuBarPrepend
          @nativeObject
          {Child get_active($)}}
      end
      meth insert(Child Position)
         {GtkNative.menuBarPrepend
          @nativeObject
          {Child get_active($)}
          Position}
      end
      meth setShadowType(Type)
         {GtkNative.menuBarSetShadowType
          @nativeObject
          Type}
         shadow <- Type
      end
   end

% -----------------------------------------------------------------------------
% HBox
% -----------------------------------------------------------------------------

   class HBox from Box
      meth init(Spacing Homogeneous)
         nativeObject <- {GtkNative.hboxNew Spacing Homogeneous}
         Object, registerObject
         spacing <- Spacing
         homogeneous <- Homogeneous
      end
   end

% -----------------------------------------------------------------------------
% Combo
% -----------------------------------------------------------------------------

   class Combo from HBox
      meth init
         nativeObject <- {GtkNative.comboNew}
         Object, registerObject
      end
      meth setValueInList(Value OkIfEmpty)
         {GtkNative.comboSetValueInList @nativeObject Value OkIfEmpty}
      end
      meth setUseArrows(Value)
         {GtkNative.comboSetUseArrows @nativeObject Value}
      end
      meth setUseArrowsAlways(Value)
         {GtkNative.comboSetUseArrowsAlways @nativeObject Value}
      end
      meth setCaseSensitive(Value)
         {GtkNative.comboSetCaseSensitive @nativeObject Value}
      end
      meth setItemString(Item ItemValue)
         {GtkNative.comboSetItemString
          @nativeObject
          {Item getNative($)}
          ItemValue}
      end
      meth setPopdownStrings(Strings)
         {GtkNative.comboSetPopdownStrings @nativeObject Strings}
      end
      meth disableActivate
         {GtkNative.comboDisableActivate @nativeObject}
      end
   end

% -----------------------------------------------------------------------------
% Statusbar
% -----------------------------------------------------------------------------

   class Statusbar from HBox
      meth init
         nativeObject <- {GtkNative.statusbarNew}
         Object, registerObject
      end
      meth getContextId(ContextDescription ContextId)
         ContextId = {GtkNative.statusbarGetContextId @nativeObject ContextDescription}
      end
      meth push(ContextId Text ?MessageId)
         MessageId = {GtkNative.statusbarPush @nativeObject ContextId Text}
      end
      meth pop(ContextId)
         {GtkNative.statusbarPop @nativeObject ContextId}
      end
      meth remove(ContextId MessageId)
         {GtkNative.statusbarRemove @nativeObject ContextId MessageId}
      end
   end

% -----------------------------------------------------------------------------
% VBox
% -----------------------------------------------------------------------------

   class VBox from Box
      meth init(Homogeneous Spacing)
         nativeObject <- {GtkNative.vboxNew Homogeneous Spacing}
         Object, registerObject
         spacing <- Spacing
         homogeneous <- Homogeneous
      end
   end

% -----------------------------------------------------------------------------
% ColorSelection
% -----------------------------------------------------------------------------

   class ColorSelection from VBox
      meth init
         nativeObject <- {GtkNative.colorSelectionNew}
         Object, registerObject
      end
      meth setUpdatePolicy(Policy)
         {GtkNative.colorSelectionSetUpdatePolicy
          @nativeObject
          Policy}
      end
      meth setOpacity(UseOpacity)
         {GtkNative.colorSelectionSetOpacity
          @nativeObject
          UseOpacity}
      end
      meth setColor(Color)
         {GtkNative.colorSelectionSetColor
          @nativeObject
          Color}
      end
      meth getColor($)
         {GtkNative.colorSelectionGetColor @nativeObject}
      end
   end

% -----------------------------------------------------------------------------
% Misc
% -----------------------------------------------------------------------------

   class Misc from Widget
      attr
         xalign
         yalign
         xpad
         ypad
      meth setAlignment(Xalign Yalign)
         {GtkNative.miscSetAlignment @nativeObject Xalign Yalign}
         xalign <- Xalign
         yalign <- Yalign
      end
      meth setPadding(Xpad Ypad)
         {GtkNative.miscSetPadding @nativeObject Xpad Ypad}
         xpad <- Xpad
         ypad <- Ypad
      end
   end

% -----------------------------------------------------------------------------
% Arrow
% -----------------------------------------------------------------------------

   class Arrow from Misc
      attr
         arrow_type
         shadow_type
      meth init(Arrow_type Shadow_type)
         arrow_type    <- Arrow_type
         shadow_type   <- Shadow_type
         nativeObject <- {GtkNative.arrowNew Arrow_type Shadow_type}
         Object, registerObject
      end
      meth set(Arrow_type Shadow_type)
         arrow_type    <- Arrow_type
         shadow_type   <- Shadow_type
         {GtkNative.arrowSet @nativeObject Arrow_type Shadow_type}
      end
   end

% -----------------------------------------------------------------------------
% Label
% -----------------------------------------------------------------------------

   class Label from Misc
      attr
         label         : ""
         pattern       : ""
         justification
      meth init(String)
         nativeObject <- {GtkNative.labelNew String}
         Object, registerObject
      end
      meth setPattern(Pattern)
         {GtkNative.labelSetPattern @nativeObject Pattern}
      end
      meth setJustification(Jtype)
         {GtkNative.labelSetJustification @nativeObject Jtype}
      end
      meth get($)
         {GtkNative.labelGet @nativeObject}
      end
      meth parseUline(String ?Keyval)
         Keyval = {GtkNative.labelParseUline @nativeObject String}
      end
      meth setLineWrap(Wrap)
         {GtkNative.labelSetLineWrap @nativeObject Wrap}
      end
      meth setText(String)
         {GtkNative.labelSetText @nativeObject String}
         label <- Label
      end
   end

   % Start the dispatcher
   Dispatcher = {New DispatcherClass init}
   {System.show 'going to start dispatcher'}
   thread {Dispatcher dispatch} end
   {System.show 'dispatcher is running ...'}

end % functor
