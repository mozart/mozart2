%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Contributor:
%%%
%%% Copyright:
%%%   Denys Duchier, 2000
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
import GTK
export
   Register Make none:NONE
   HasWhichFeatureN
   HasFeatureN
   GetFeatureN
   CondGetFeatureN
   MakeChildrenByIndex MakeChildrenByList
   MakeChildrenByIndexNoRecurse MakeChildrenByListNoRecurse
define
   HandlerMap = {NewDictionary}

   proc {Register Info}
      Key         = {Label Info}
      Isa         = {CondSelect Info isa         unit}
      Features    = {CondSelect Info features     nil}
      Signals     = {CondSelect Info signals      nil}
      Make        = {CondSelect Info make        unit}
      MakeRecurse = {CondSelect Info makeRecurse unit}
   in
      HandlerMap.Key := o(isa         : Isa
                          features    : Features
                          signals     : Signals
                          make        : Make
                          makeRecurse : MakeRecurse)
   end

   NONE = {NewName}

   fun {GetFeat ISA F}
      if ISA==unit then NONE else
         Info  = {Dictionary.condGet HandlerMap ISA unit}
         Value = {CondSelect Info F NONE}
      in
         if Value==NONE
         then {GetFeat {CondSelect Info isa unit} F}
         else Value end
      end
   end

   fun {GetMake        ISA} {GetFeat ISA make       } end
   fun {GetMakeRecurse ISA} {GetFeat ISA makeRecurse} end

   fun {HasWhichFeatureN R Fs}
      case Fs
      of nil then NONE
      [] H|T then
         if {HasFeature R H} then H else {HasWhichFeatureN R T} end
      end
   end

   fun {HasFeatureN R Fs} {HasWhichFeatureN R Fs}\=NONE end
   fun {GetFeatureN R Fs} R.{HasWhichFeatureN R Fs} end
   fun {CondGetFeatureN R Fs V}
      F = {HasWhichFeatureN R Fs}
   in
      if F==NONE then V else R.F end
   end
   CondSelectN = CondGetFeatureN

   fun {DictMemberN D Features}
      {Some Features fun {$ F} {Dictionary.member D F} end}
   end

   proc {DictMemberAddN D Features}
      for F in Features do D.F := true end
   end

   proc {Make D W}
      {MakeNoRecurse D W}
      {MakeDoRecurse D W}
   end

   proc {MakeNoRecurse D W}
      ISA           = {Label D}
      MyMake        = {GetMake ISA}
   in
      {CondSelect D handle W W}
      {MyMake D W}
      {Configure D W}
   end

   proc {MakeDoRecurse D W}
      ISA           = {Label D}
      MyMakeRecurse = {GetMakeRecurse ISA}
   in
      if MyMakeRecurse==NONE orelse MyMakeRecurse==unit then skip
      else {MyMakeRecurse D W} end
   end

   proc {Configure D W}
      {DoConfigureIsa D W {Label D} {NewDictionary} {NewDictionary}}
   end

   proc {DoConfigureIsa D W Isa Done SDone}
      if Isa==unit then skip
      elsecase HandlerMap.Isa
      of o(isa:ISA features:FEATS signals:SIGNALS ...) then
         {DoConfigure D W ISA FEATS SIGNALS Done SDone}
      end
   end

   %% to configure a widget, we process all the features of its
   %% descriptors that are understood by itself or one of its
   %% ancestors. at the same time we also process signals/action.
   %% `Done' is a dictionary that keeps track of which features
   %% we already have processed, so that we don't process it
   %% twice (e.g. because 2 distinct ancestors both specify a
   %% handler for this feature). SDone is the same for signals.

   proc {DoConfigure D W Isa Feats Signals Done SDone}
      for X in Feats do
         case X of Features#Handler then
            if {DictMemberN Done Features} then skip else
               K = {HasWhichFeatureN D Features}
            in
               if K==NONE then skip else
                  if {IsAtom Handler} then {W Handler(D.K)}
                  else {Handler W D.K} end
               end
            end
            %% add all features since we don't know which ones
            %% may have been recorded and which not.  All should
            %% now be recorded since they all correspond to the
            %% same abstract feature.
            {DictMemberAddN Done Features}
         end
      end
      if {HasFeature D action}
         andthen {Not {HasFeature SDone clicked}}
         andthen {Member clicked Signals}
      then
         SDone.clicked := true
         {W signalConnect(clicked D.action _)}
      end
      if {HasFeature D signals} then D2=D.signals in
         for X in Signals do
            if {Not {Dictionary.member SDone X}}
               andthen {HasFeature D2 X}
            then
               SDone.X := true
               {W signalConnect(X D2.X _)}
            end
         end
      end
      {DoConfigureIsa D W Isa Done SDone}
   end

   fun {MakeChildrenByIndex D I}
      if {HasFeature D I} then
         ({Make D.I}#D.I)|{MakeChildrenByIndex D I+1}
      else
         nil
      end
   end

   fun {MakeChildrenByList L}
      case L
      of nil then nil
      [] H|T then ({Make H}#H)|{MakeChildrenByList T}
      end
   end

   fun {MakeChildrenByIndexNoRecurse D I}
      if {HasFeature D I} then
         ({MakeNoRecurse D.I}#D.I)
         |{MakeChildrenByIndexNoRecurse D I+1}
      else
         nil
      end
   end

   fun {MakeChildrenByListNoRecurse L}
      case L
      of nil then nil
      [] H|T then ({MakeNoRecurse H}#H)
         |{MakeChildrenByListNoRecurse T}
      end
   end

   fun {ToAlign X}
      case X
      of left   then 0.0
      [] right  then 1.0
      [] center then 0.5
      [] middle then 0.5
      elseif {IsFloat X} then X end
   end

   %% object
   {Register object(signals:[destroy])}

   %% widget
   {Register widget(isa:object
                    signals:[show hide map unmap realize unrealize draw 'draw-focus'
                             'draw-default' 'size-request' 'size-allocate'
                             'state-changed' 'parent-set' 'add-accelerator'
                             'remove-accelerator' 'grab-focus' event
                             'button-press-event' 'button-release-event'
                             'motion-notify-event' 'delete-event' 'destroy-event'
                             'expose-event' 'key-press-event' 'key-release-event'
                             'enter-notify-event' 'leave-notify-event' 'configure-event'
                             'focus-in-event' 'focus-out-event' 'map-event' 'unmap-event'
                             'property-notify-event' 'selection-clear-event'
                             'selection-notify-event' 'selection-get'
                             'selection-received' 'proximity-in-event' 'proximity-out-event'
                             'drag-begin' 'drag-end' 'drag-data-delete' 'drag-leave'
                             'drag-motion' 'drag-drop' 'drag-data-get' 'drag-data-received'
                             'client-event' 'no-expose-event' 'visibility-notify-event'
                             'debug-msg'])}
   %% container
   {Register container(isa:widget
                       signals:[add remove 'check-size' focus 'set-focus-child'])}

   %% bin
   {Register bin(isa:container)}

   %% misc
   {Register misc(isa:widget)}

   %% editable
   {Register editable(
                isa : widget
                features:[[editable]#setEditable]
                signals :
                      [changed 'insert-text' 'delete-text' activate
                       'set-editable' 'move-cursor' 'move-word'
                       'move-page' 'move-to-row' 'move-to-column'
                       'kill-char' 'kill-word' 'kill-line'
                       'cut-clipboard' 'copy-clipboard'
                       'paste-clipboard'])}

   %% window
   local
      Type = o(toplevel:0 dialog:1 popup:2)
   in
      {Register
       window(
          isa        : bin
          features   : [[title]#setTitle]
          signals    : ['set-focus']
          make       :
             fun {$ D} {New GTK.window new(Type.{CondSelect D type toplevel})} end
          makeRecurse:
             proc {$ D W} if {HasFeature D 1} then {W add({Make D.1})} end end)}
   end

   %% hbox, vbox
   local
      fun {MakeHBox D}
         {New GTK.hBox new({CondSelect D homogeneous false}
                           {CondSelect D spacing         0})}
      end
      fun {MakeVBox D}
         {New GTK.vBox new({CondSelect D homogeneous false}
                           {CondSelect D spacing         0})}
      end
      proc {MakeBoxRecurse D W}
         for X in {MakeChildrenByIndex D 1} do
            case X of Child#ChildDesc then AtEnd in
               if {HasFeature ChildDesc atEnd} then AtEnd=ChildDesc.atEnd
               elseif {HasFeature ChildDesc attach} then
                  case ChildDesc.attach
                  of left   then AtEnd=false
                  [] right  then AtEnd=true
                  [] top    then AtEnd=false
                  [] bottom then AtEnd=true
                  end
               else AtEnd=false end
               if AtEnd then
                  {W   packEnd(Child
                               {CondSelect ChildDesc expand  false}
                               {CondSelect ChildDesc fill    false}
                               {CondSelect ChildDesc padding     0})}
               else
                  {W packStart(Child
                               {CondSelect ChildDesc expand  false}
                               {CondSelect ChildDesc fill    false}
                               {CondSelect ChildDesc padding     0})}
               end
            end
         end
      end
   in
      {Register box(isa:container makeRecurse:MakeBoxRecurse)}
      {Register hbox(isa:box make:MakeHBox)}
      {Register vbox(isa:box make:MakeVBox)}
   end

   %% label
   local
      fun {MakeLabel D}
         {New GTK.label new({CondSelectN D [text 1] unit})}
      end
   in
      {Register label(isa:misc
                      features:
                         [[pattern ]#setPattern
                          [justify ]#setJustify
                          [lineWrap]#setLineWrap]
                      make    : MakeLabel)}
   end

   %% button
   local
      ReliefStyle = o(normal:0 half:1 none:2)
      proc {SetRelief W X} {W setRelief(ReliefStyle.X)} end
      fun {MakeButton D}
         {New GTK.button newWithLabel({CondSelectN D [text 1] nil})}
      end
   in
      {Register button(isa     :misc
                       features:[[relief]#SetRelief]
                       signals :[pressed released clicked enter leave]
                       make    :MakeButton)}
   end

   %% htable
   local
      fun {RowLength Row N}
         case Row
         of nil then N
         [] H|T then {RowLength T N+{CondSelect H span 1}}
         end
      end
      fun {HTableSize T}
         %% [Row1 Row2 ...]
         Rows = {CondSelectN T [1 rows] nil}
      in
         {Length Rows}#
         {FoldL Rows
          fun {$ N Row}
             {Max N {RowLength Row 0}}
          end 0}
      end
      proc {HTableAddRow Table Row Nrow Ncol}
         case Row
         of nil then skip
         [] H|T then
            W = {Make H}
            S = {CondSelect H span 1}
         in
            {Table attachDefaults(W Ncol Ncol+S Nrow Nrow+1)}
            {HTableAddRow Table T Nrow Ncol+S}
         end
      end
      proc {HTableAddRows Table Rows Nrow}
         case Rows
         of nil then skip
         [] H|T then
            {HTableAddRow  Table H Nrow 0}
            {HTableAddRows Table T Nrow+1}
         end
      end
      fun {MakeHTable D}
         Nrows#Ncols = {HTableSize D}
      in
         {New GTK.table new(Nrows Ncols {CondSelect D homogeneous false})}
      end
      proc {MakeHTableRecurse D W}
         {HTableAddRows W {CondSelectN D [1 rows] nil} 0}
      end
   in
      {Register htable(isa        : container
                       features   : [[rowSpacings]#setRowSpacings
                                     [colSpacings]#setColSpacings]
                       make       : MakeHTable
                       makeRecurse: MakeHTableRecurse)}
   end

   ShadowType  = o(none:0   'in':1    out:2 etchedIn:3 etchedOut:4
                   flat:0 sunken:1 raised:2   groove:3     ridge:4)

   %% frame
   local
      proc {SetShadowType W X} {W setShadowType(ShadowType.X)} end
      proc {SetLabelAlign W X} {W setLabelAlign({ToAlign X} 0.0)} end
      fun {MakeFrame D} {New GTK.frame new(nil)} end
      proc {MakeFrameRecurse D W}
         for X in {MakeChildrenByIndex D 1} do {W add(X.1)} end
      end
   in
      {Register frame(isa        : bin
                      features   : [[label text title ]#setLabel
                                    [labelAlign textAlign
                                     titleAlign align ]#SetLabelAlign
                                    [shadowType relief]#SetShadowType]
                      make       : MakeFrame
                      makeRecurse: MakeFrameRecurse)}
   end

   %% entry
   local
      fun {MakeEntry D} {New GTK.entry new} end
   in
      {Register entry(
                   isa     :editable
                   features:[[text 1            ]#setText
                             [visibility visible]#setVisibility
                             [editable          ]#setEditable
                             [maxLength         ]#setMaxLength]
                   make    :MakeEntry)}
   end

   %% arrow
   local
      ArrowType = o(up:0 down:1 left:2 right:3)
      fun {MakeArrow D}
         {New GTK.arrow new(ArrowType.{CondSelectN D [arrowType arrowtype type] right}
                            ShadowType.{CondSelectN D [shadowType shadowtype shadow] none})}
      end
   in
      {Register arrow(isa:misc make:MakeArrow)}
   end

   %% calendar
   local
      fun {MakeCalendar D} {New GTK.calendar new} end
      Months = o(january  : 0 jan: 0
                 february : 1 feb: 1
                 march    : 2 mar: 2
                 april    : 3 apr: 3
                 may      : 4
                 june     : 5 jun: 5
                 july     : 6 jul: 6
                 august   : 7 aug: 7
                 september: 8 sep: 8
                 october  : 9 oct: 9
                 november :10 nov:10
                 december :11 dec:11)
      proc {SetMonth W X}
         M = if {IsInt X} then X else Months.X end
      in
         {W selectMonth(M {W getDate($ _ _)})}
      end
      proc {SetYear W Y}
         {W selectMonth({W getDate(_ $ _)} Y)}
      end
   in
      {Register calendar(isa:widget
                         make:MakeCalendar
                         features:[[month]#SetMonth
                                   [year]#SetYear]
                         signals:['month-changed' 'day-selected' 'day-selected-double-click'
                                  'prev-month' 'next-month' 'prev-year' 'next-year'])}
   end

   %% toggle button
   local
      fun {MakeToggleButton D}
         L = {CondSelectN D [text 1] unit}
      in
         if L==unit
         then {New GTK.toggleButton new}
         else {New GTK.toggleButton newWithLabel(L)} end
      end
   in
      {Register togglebutton(isa:button
                             make:MakeToggleButton
                             features:[[mode drawindicator drawIndicator]#setMode
                                       [active]#setActive]
                             signals:[toggled])}
      {Register toggleButton(isa:togglebutton)}
   end

   %% check button
   local skip in
      {Register checkbutton(isa:togglebutton)}
      {Register checkButton(isa:checkbutton)}
   end

   %% file selection
   local
      fun {MakeFileSelection D}
         {New GTK.fileSelection new({CondSelectN D [text 1 title] nil})}
      end
   in
      {Register fileselection(isa:window make:MakeFileSelection
                              features:[[filename]#setFilename])}
      {Register fileSelection(isa:fileselection)}
   end

   %% note book
   PositionType = o(left:0 right:1 top:2 bottom:3)
   local
      fun {MakeNoteBook D} {New GTK.noteBook new} end
      proc {SetTabPos W X} {W setTabPos(PositionType.X)} end
      proc {SetPopupEnable W X}
         if X then {W popupEnable} else {W popupDisable} end
      end
      fun {MakePages D I}
         if {HasFeature D I} then
            case D.I of LD#CD then
               (if {IsVirtualString LD}
                then {Make label(LD)}
                else {Make LD} end
                #{Make CD})|{MakePages D I+1}
            end
         else nil end
      end
      proc {MakeNoteBookRecurse D W}
         for X in {MakePages D 1} do
            case X of ChildLabel#ChildWidget then
               {W appendPage(ChildWidget ChildLabel)}
            end
         end
      end
   in
      {Register notebook(isa:container
                         make:MakeNoteBook
                         signals:['switch-page']
                         features:[[tabpos tabPos]#SetTabPos
                                   [showtab showTab]#setShowTabs
                                   [showborder showBorder]#setShowBorder
                                   [scrollable]#setScrollable
                                   [tabborder tabBorder]#setTabBorder
                                   [popup popupenable popupEnable]#SetPopupEnable
                                   [homogeneousTabs homogeneoustabs homogeneous]#setHomogeneousTabs
                                   [tabHborder tabhborder]#setTabHborder
                                   [tabVborder tabvborder]#setTabVborder]
                         makeRecurse:MakeNoteBookRecurse
                         )}
      {Register noteBook(isa:notebook)}
   end

   %% tree
   local
      fun {MakeTree D} {New GTK.tree new} end
      proc {MakeTreeRecurse D W}
         L = if {HasFeature D items}
             then {MakeChildrenByListNoRecurse D.items}
             else {MakeChildrenByIndexNoRecurse D 1} end
      in
         for X in L do
            case X of CW#CD then
               {W append(CW)}
               {MakeDoRecurse CD CW}
               {CW show}
            end
         end
      end
   in
      {Register tree(isa:container
                     signals:['selection-changed' 'select-child' 'unselect-child']
                     make:MakeTree
                     makeRecurse:MakeTreeRecurse
                    )}
   end

   %% tree item
   {Register item(isa:bin
                  signals:[select deselect toggle])}
   local
      fun {MakeTreeItem D}
         L = {CondSelectN D [text label 1] unit}
      in
         if L==unit
         then {New GTK.treeItem new}
         else {New GTK.treeItem newWithLabel(L)} end
      end
      proc {MakeTreeItemRecurse D W}
         if {HasFeature D subtree} then
            {W setSubtree({Make D.subtree})}
         end
      end
   in
      {Register treeitem(isa:item
                         signals:[collapse expand]
                         make:MakeTreeItem
                         makeRecurse:MakeTreeItemRecurse)}
      {Register treeItem(isa:treeitem)}
   end

   %% scrolled window
%   local
%      fun {MakeScrolledWindow D}
%        Hadj = {New GTK.adjustment new(
%        {New GTK.scrolledWindow new({CondSelect
%   in
%      {Register
%       scrolledwindow(
%         isa:bin
%
%
%         )}
%      {Register
%       scrolledWindow(isa:scrolledwindow)}
%   end

end
