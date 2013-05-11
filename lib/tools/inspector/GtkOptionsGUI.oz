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

local
   class PopupSelector from GTK.combo
      attr
         popupEntry
         inspPort
      meth new(InspPort)
         GTK.combo, new
         @popupEntry = {self comboGetFieldEntry($)}
         @inspPort   = InspPort
         {@popupEntry setEditable(0)}
      end
      meth create(InspPort InitValue Ls)
         PopupSelector, new(InspPort)
         PopupSelector, configure(InitValue Ls)
      end
      meth configure(InitValue Ls)
         GTK.combo, setPopdownStrings(Ls)
         {@popupEntry setText(InitValue)}
      end
      meth getList($)
         GTK.combo, comboGetFieldList($)
      end
      meth getValue($)
         {VirtualString.toAtom {@popupEntry getText($)}}
      end
   end

   local
      List = ['0'#0  '1'#1 '2'#2 '3'#3 '4'#4 '5'#5
              '6'#6 '7'#7 '8'#8 '9'#9 'a'#10 'b'#11
              'c'#12 'd'#13 'e'#14 'f'#15
              'A'#10 'B'#11 'C'#12 'D'#13 'E'#14 'F'#15]
      D    = {Dictionary.new}
   in
      _ = {Map List
           fun {$ V}
              case V of Key#Value then {Dictionary.put D Key Value} V end
           end}
      fun {HexToInt N}
         {Dictionary.get D {Char.toAtom N}}
      end
   end
   local
      List = [0#'0' 1#'1' 2#'4' 3#'3' 4#'4' 5#'5' 6#'6' 7#'7'
              8#'8' 9#'9' 10#'A'
              11#'B' 12#'C' 13#'D' 14#'E' 15#'F']
      D    = {Dictionary.new}
   in
      _ = {Map List
           fun {$ V}
              case V of Key#Value then {Dictionary.put D Key Value} V end
           end}
      fun {IntToHex N}
         NH = N div 16
         NL = N mod 16
      in
         {Dictionary.get D NH}#{Dictionary.get D NL}
      end
   end

   fun {ComputeColor C}
      case {Map {VirtualString.toString C}.2 HexToInt}
      of [RH RL GH GL BH BL] then
         {Append {Map [RH#RL GH#GL BH#BL]
                  fun {$ H#L}
                     {Int.toFloat (H * 16 + L)}
                  end} [0.0]}
      end
   end

   local
      SubVal = "Menu"
      fun {HasSub Ss S}
         case Ss of _|Sr then Ss == S orelse {HasSub Sr S} else false end
      end
      fun {SubFilter S}
         {HasSub {Atom.toString S} SubVal}
      end
      fun {CutSub Ss S}
         case Ss
         of I|Sr then if Ss == S then nil else I|{CutSub Sr S} end
         else 'Alert'
         end
      end
      fun {CutMap S}
         {CutSub {Atom.toString S} SubVal}
      end
      ExtractAuto   = {NewName}
      CreateFilters = {NewName}
      AdjustFilters = {NewName}
   in
      class DisplayNote
         attr
            displayWidthEntry    %% Width Entry
            displayDepthEntry    %% Depth Entry
            displayTreeMode      %% Widget Tree Mode
            displayRelationPopup %% Selection Relation
            displayTypePopup     %% Mapping Type Selection
            displayApplyPopup    %% Type Automapping Selection
            displayApplyNoMapRB  %% No Default RB
            displayApplyMapRB    %% Map RB
            displayApplyAuto     %% Auto Apply Filter
         meth create(Parent)
            Label = {New GTK.label new("Structure")}
            Frame = {New GTK.vBox new(0 0)}
         in
            DisplayNote, createTraversal(Frame)
            DisplayNote, createRepresentation(Frame)
            DisplayNote, createMapping(Frame)
            {Parent appendPage(Frame Label)}
         end
         meth createTraversal(Parent)
            WLabel  = {New GTK.label new("Width   ")}
            WEntry  = {New GTK.entry new}
            WBox    = {New GTK.hBox new(0 0)}
            HLabel  = {New GTK.label new("Depth   ")}
            HEntry  = {New GTK.entry new}
            HBox    = {New GTK.hBox new(0 0)}
            Table   = {New GTK.vBox new(0 0)}
            Frame   = {New GTK.frame new(" Traversal ")}
            Options = @opDict
            Width   = {Dictionary.get Options widgetTreeWidth}
            Height  = {Dictionary.get Options widgetTreeDepth}
         in
            @displayWidthEntry = WEntry
            @displayDepthEntry = HEntry
            {WLabel setJustify(GTK.'JUSTIFY_LEFT')}
            {HLabel setJustify(GTK.'JUSTIFY_LEFT')}
            {WEntry setText({Int.toString Width})}
            {HEntry setText({Int.toString Height})}
            {WBox packStart(WLabel 0 0 2)}
            {WBox packStart(WEntry 0 0 0)}
            {HBox packStart(HLabel 0 0 2)}
            {HBox packStart(HEntry 0 0 0)}
            {Table packStart(WBox 0 0 0)}
            {Table packStart(HBox 0 0 0)}
            {Frame setShadowType(GTK.'SHADOW_ETCHED_OUT')}
            {Frame setBorderWidth(4)}
            {Frame add(Table)}
            {Parent packStart(Frame 0 0 0)}
         end
         meth createRepresentation(Parent)
            Frame    = {New GTK.frame new(" Representation ")}
            RelRB    = {New GTK.radioButton new(unit)}
            TreeRB   = {New GTK.radioButton
                        newWithLabel({RelRB group($)} "Tree Mode")}
            RelBox   = {New GTK.hBox new(0 0)}
            RelLabel = {New GTK.label new("Relation Mode ")}
            RelEntry = {self relationPopup($)}
            Group    = {New GTK.vBox new(0 0)}
            TreeMode = {Dictionary.get @opDict widgetTreeDisplayMode}
            TreeMInt = if TreeMode then 1 else 0 end
         in
            @displayRelationPopup = RelEntry
            {RelBox packStart(RelLabel 0 0 0)}
            {RelBox packStart(RelEntry 0 0 0)}
            {Group packStart(TreeRB 0 0 0)}
            {Group packStart(RelRB 0 0 0)}
            displayTreeMode <- TreeMode
            {TreeRB setActive(TreeMInt)}
            {RelRB setActive(1 - TreeMInt)}
            {TreeRB signalConnect('toggled' proc {$ _}
                                               displayTreeMode <- true
                                            end _)}
            {RelRB signalConnect('toggled' proc {$ _}
                                              displayTreeMode <- false
                                              %% ToDo: Selection of relation
                                           end _)}
            {RelRB add(RelBox)}
            {Frame setShadowType(GTK.'SHADOW_ETCHED_OUT')}
            {Frame setBorderWidth(4)}
            {Frame add(Group)}
            {Parent packStart(Frame 0 0 0)}
         end
         meth relationPopup($)
            NatReLs = {Dictionary.get @opDict widgetRelationList}
            RelLs RelSel
         in
            RelLs = DisplayNote, filterRelations(NatReLs RelSel $)
            {New PopupSelector create(@inspPort RelSel RelLs)}
         end
         meth filterRelations(Rs SR ?R)
            case Rs
            of Rel|Rr then
               TF      = case Rel
                         of auto(TF) then SR = {Label TF} TF
                         else Rel
                         end
               MyLabel = {Label TF}
               Tail
            in
               R = MyLabel|Tail
               DisplayNote, filterRelations(Rr SR Tail)
            else R = nil
            end
         end
         meth buildRelations(Rs SR ?R)
            case Rs
            of Rel|Rr then
               TF      = case Rel of auto(TF) then TF else Rel end
               MyLabel = {Label TF}
               Tail
            in
               R = if {System.eq MyLabel SR} then auto(TF) else TF end|Tail
               DisplayNote, buildRelations(Rr SR Tail)
            else R = nil
            end
         end
         meth createMapping(Parent)
            Frame      = {New GTK.frame new(" Mapping ")}
            Box        = {New GTK.vBox new(0 0)}
            SelBox     = {New GTK.hBox  new(0 0)}
            SelLabel   = {New GTK.label new("Select a type ")}
            SelEntry   = {self mappingPopup($)}
            TypeFrame  = {New GTK.frame new("Type Defaults")}
            ApplyRB    = {New GTK.radioButton new(unit)}
            ApplyBox   = {New GTK.hBox new(0 0)}
            ApplyLabel = {New GTK.label new("Apply ")}
            ApplyEntry = {New PopupSelector new(@inspPort)}
            DefRB      = {New GTK.radioButton
                          newWithLabel({ApplyRB group($)}
                                       "No Default mapping")}
            RBBox      = {New GTK.vBox new(0 0)}
            SyncCall   = @syncCall
         in
            @displayTypePopup    = SelEntry
            @displayApplyPopup   = ApplyEntry
            @displayApplyNoMapRB = DefRB
            @displayApplyMapRB   = ApplyRB
            {{SelEntry getList($)}
             signalConnect('selection_changed'
                           proc {$ _}
                              {SyncCall configureApply}
                           end _)}
            DisplayNote, configureApply
            {SelBox packStart(SelLabel 0 0 4)}
            {SelBox packStart(SelEntry 0 0 0)}
            {TypeFrame setBorderWidth(4)}
            {ApplyBox packStart(ApplyLabel 0 0 2)}
            {ApplyBox packStart(ApplyEntry 0 0 0)}
            {ApplyRB add(ApplyBox)}
            {RBBox packStart(DefRB 0 0 4)}
            {RBBox packStart(ApplyRB 0 0 4)}
            {TypeFrame add(RBBox)}
            {Frame setBorderWidth(4)}
            {Box packStart(SelBox 0 0 0)}
            {Box packStart(TypeFrame 0 0 0)}
            {Frame add(Box)}
            {Parent packStart(Frame 0 0 0)}
         end
         meth mappingPopup($)
            Options  = @opDict
            TypesLs  = {Map {Filter {Dictionary.keys Options} SubFilter} CutMap}
            FilRwFun = {Dictionary.get Options inspectorOptionsFilter}
            FilLs    = {Filter TypesLs fun {$ Type} {FilRwFun map Type} end}
            MapLs    = {Sort {Map FilLs
                              fun {$ N}
                                 NA = {VirtualString.toAtom N}
                              in
                                 {Dictionary.condGet @printDict NA NA}
                              end}
                        Value.'<'}
            MapSel   = MapLs.1
         in
            {New PopupSelector create(@inspPort MapSel MapLs)}
         end
         meth configureApply
            Options   = @opDict
            PrintType = {@displayTypePopup getValue($)}
            MapType   = {Dictionary.condGet @namesDict PrintType PrintType}
            TypeKey   = {VirtualString.toAtom MapType#'Menu'}
            TypeMenu  = {Dictionary.get Options TypeKey}
            TypeFs    = case TypeMenu of nil then nil else TypeMenu.3 end
            AutoFs    = DisplayNote, ExtractAuto(TypeFs $)
            AutoValue = case AutoFs of nil then 'none' else 'auto'(AutoFs) end
            FilterLs  = DisplayNote, CreateFilters(TypeFs $)
            ShowSel
         in
            case AutoFs
            of nil then
               ShowSel = case TypeFs of F|_ then F else 'No Mapping' end
               displayApplyAuto <- 'none'
               {@displayApplyNoMapRB setActive(1)}
               {@displayApplyMapRB setActive(0)}
            [] AutoFs then
               ShowSel = AutoFs
               displayApplyAuto <- 'auto'(AutoFs)
               {@displayApplyNoMapRB setActive(0)}
               {@displayApplyMapRB setActive(1)}
            end
            {@displayApplyPopup configure(ShowSel FilterLs)}
            %% Register Menu Stuff (if any)
            case TypeMenu
            of menu(WL DL FL AL) then
               NewFL = DisplayNote, AdjustFilters(FL ShowSel $)
            in
               {Dictionary.put Options TypeKey menu(WL DL NewFL AL)}
            [] _ then skip
            end
         end
         meth !AdjustFilters(Fs SF ?R)
            case Fs
            of Filter|Fr then
               TF = case Filter of auto(TF) then TF else Filter end
               Tail
            in
               R = if {Label TF} == SF then auto(TF) else TF end|Tail
               DisplayNote, AdjustFilters(Fr SF Tail)
            else R = nil
            end
         end
         meth !ExtractAuto(Fs $)
            case Fs
            of Filter|Fr then
               case Filter
               of auto(TF) then {Label TF}
               else DisplayNote, ExtractAuto(Fr $) end
            else nil
            end
         end
         meth !CreateFilters(Fs ?R)
            case Fs
            of Filter|Fr then
               TF = case Filter of auto(TF) then TF else Filter end
               Tail
            in
               R = {Label TF}|Tail DisplayNote, CreateFilters(Fr Tail)
            else R = nil
            end
         end
         meth collect
            Options  = @opDict
            WidthStr = {@displayWidthEntry getText($)}
            DepthStr = {@displayDepthEntry getText($)}
            RelLs    = {Dictionary.get Options widgetRelationList}
            NewRels  =
            {self buildRelations(RelLs {@displayRelationPopup getValue($)} $)}
         in
            {Dictionary.put Options widgetTreeWidth {String.toInt WidthStr}}
            {Dictionary.put Options widgetTreeDepth {String.toInt DepthStr}}
            {Dictionary.put Options widgetTreeDisplayMode @displayTreeMode}
            {Dictionary.put Options widgetRelationList NewRels}
         end
      end
   end

   local
      FontSizes = ["10" "12" "14" "18" "24"]
      SubVal    = "Color"
      fun {HasSub Ss S}
         case Ss of _|Sr then Ss == S orelse {HasSub Sr S} else false end
      end
      fun {SubFilter S}
         {HasSub {Atom.toString S} SubVal}
      end
      fun {CutSub Ss S}
         case Ss
         of I|Sr then if Ss == S then nil else I|{CutSub Sr S} end
         else 'Alert'
         end
      end
      fun {CutMap S}
         {CutSub {Atom.toString S} SubVal}
      end
   in
      class VisualNote
         attr
            visualFontSize   %% Font Size
            visualFontBold   %% Font is displayed bold
            visualNodeSet    %% Indent Mode
            visualShowString %% Show Strings
            visualColorItem  %% Current Color Item
         meth create(Parent)
            Label       = {New GTK.label new("Appearance")}
            Frame       = {New GTK.vBox new(0 0)}
            FontFrame   = {New GTK.frame new(" Font ")}
            SubFrame    = {New GTK.frame new(" Subtree Alignment ")}
            StringFrame = {New GTK.frame new(" String Handling ")}
            ColorFrame  = {New GTK.frame new(" Color ")}
         in
            VisualNote, createFont(FontFrame)
            VisualNote, createAlignment(SubFrame)
            VisualNote, createString(StringFrame)
            VisualNote, createColor(ColorFrame)
            {FontFrame setShadowType(GTK.'SHADOW_ETCHED_OUT')}
            {SubFrame setShadowType(GTK.'SHADOW_ETCHED_OUT')}
            {StringFrame setShadowType(GTK.'SHADOW_ETCHED_OUT')}
            {ColorFrame setShadowType(GTK.'SHADOW_ETCHED_OUT')}
            {FontFrame setBorderWidth(4)}
            {SubFrame setBorderWidth(4)}
            {StringFrame setBorderWidth(4)}
            {ColorFrame setBorderWidth(4)}
            {Frame packStart(FontFrame 0 0 2)}
            {Frame packStart(SubFrame 0 0 2)}
            {Frame packStart(StringFrame 0 0 2)}
            {Frame packStart(ColorFrame 0 0 2)}
            {Parent appendPage(Frame Label)}
         end
         meth createFont(Parent)
            Box       = {New GTK.hBox new(0 0)}
            BoldCB    = {New GTK.checkButton newWithLabel("Bold")}
            SizeBox   = {New GTK.hBox new(0 0)}
            SizeLabel = {New GTK.label new(" Size ")}
            SizeEntry = {self fontPopup(BoldCB $)}
         in
            @visualFontSize = SizeEntry
            {BoldCB signalConnect('toggled'
                                  proc {$ _}
                                     visualFontBold <- {Not @visualFontBold}
                                  end _)}
            {SizeBox packStart(SizeLabel 0 0 2)}
            {SizeBox packStart(SizeEntry 0 0 0)}
            {Box packStart(SizeBox 0 0 2)}
            {Box packStart(BoldCB 0 0 0)}
            {Parent add(Box)}
         end
         meth fontPopup(BoldCB $)
            case {Dictionary.get @opDict widgetTreeFont}
            of font(size: SZ weight: W ...) then
               case W
               of 'normal' then
                  visualFontBold <- false
                  {BoldCB setActive(0)}
               [] 'bold' then
                  visualFontBold <- true
                  {BoldCB setActive(1)}
               end
               {New PopupSelector create(@inspPort {Int.toString SZ} FontSizes)}
            end
         end
         meth createAlignment(Parent)
            FixedCB = {New GTK.checkButton
                       newWithLabel("Used Fixed Width indent")}
            NodeSet = {Dictionary.get @opDict widgetUseNodeSet}
         in
            visualNodeSet <- NodeSet
            {FixedCB setActive(if NodeSet == 1 then 0 else 1 end)}
            {FixedCB
             signalConnect('toggled'
                           proc {$ _}
                              visualNodeSet <- case @visualNodeSet
                                               of 1 then 2
                                               [] 2 then 1
                                               end
                           end _)}
            {Parent add(FixedCB)}
         end
         meth createString(Parent)
            StringCB    = {New GTK.checkButton
                           newWithLabel("Show Strings")}
            ShowStrings = {Dictionary.get @opDict widgetShowStrings}
         in
            visualShowString <- ShowStrings
            {StringCB setActive(if ShowStrings then 1 else 0 end)}
            {StringCB
             signalConnect('toggled'
                           proc {$ _}
                              visualShowString <- {Not @visualShowString}
                           end _)}
            {Parent add(StringCB)}
         end
         meth createColor(Parent)
            TypeBox   = {New GTK.hBox new(0 0)}
            TypeLabel = {New GTK.label new("Selected Type: ")}
            TypeEntry = {self colorPopup($)}
            Button    = {New GTK.button newWithLabel(" Change ")}
            SyncCall  = @syncCall
         in
            {Button signalConnect('clicked'
                                  proc {$ _}
                                     {SyncCall handle(colorselection(Button))}
                                  end _)}
            {{TypeEntry getList($)}
             signalConnect('selection_changed'
                           proc {$ _}
                              visualColorItem <- {TypeEntry getValue($)}
                           end _)}
            {TypeBox packStart(TypeLabel 0 0 2)}
            {TypeBox packStart(TypeEntry 0 0 2)}
            {TypeBox packStart(Button 0 0 2)}
            {Parent add(TypeBox)}
         end
         meth colorPopup($)
            Options = @opDict
            RawLs   = {Map {Filter {Dictionary.keys Options} SubFilter} CutMap}
            TypeLs  = {Sort {Map RawLs
                             fun {$ N}
                                NA = {VirtualString.toAtom N}
                             in
                                {Dictionary.condGet @printDict NA NA}
                             end}
                       Value.'<'}
            TypeSel = TypeLs.1
         in
            visualColorItem <- TypeSel
            {New PopupSelector create(@inspPort TypeSel TypeLs)}
         end
         meth collect
            Options = @opDict
         in
            {Dictionary.put Options widgetUseNodeSet @visualNodeSet}
            {Dictionary.put Options widgetShowStrings @visualShowString}
            case {Dictionary.get Options widgetTreeFont}
            of font(family:Family ...) then
               Size   = {String.toInt
                         {Atom.toString {@visualFontSize getValue($)}}}
               Weight = if @visualFontBold then 'bold' else 'normal' end
               Font   = font(family:Family size: Size weight:Weight)
            in
               {Dictionary.put Options widgetTreeFont Font}
            end
         end
      end
   end

   class GlobalNote
      attr
         globalToggleVar %% Toggle Variable
      meth create(Parent)
         Label    = {New GTK.label new("Range")}
         Frame    = {New GTK.frame new(" Apply Settings to ")}
         ActiveRB = {New GTK.radioButton
                     newWithLabel(unit "Active Widget only")}
         AllRB    = {New GTK.radioButton
                     newWithLabel({ActiveRB group($)}
                                  "All shown Widgets")}
         Box      = {New GTK.vBox new(0 0)}
         Value    = {Dictionary.get @opDict inspectorOptionsRange}
      in
         globalToggleVar <- Value
         case Value
         of 'all' then
            {AllRB setActive(1)}
            {ActiveRB setActive(0)}
         [] 'active' then
            {AllRB setActive(0)}
            {ActiveRB setActive(1)}
         end

         {Box packStart(ActiveRB 0 0 2)}
         {Box packStart(AllRB 0 0 2)}
         {ActiveRB
          signalConnect('toggled' proc {$ _}
                                     globalToggleVar <- active
                                  end _)}
         {AllRB
          signalConnect('toggled' proc {$ _}
                                     globalToggleVar <- all
                                  end _)}
         {Frame add(Box)}
         {Frame setBorderWidth(4)}
         {Frame setShadowType(GTK.'SHADOW_ETCHED_OUT')}
         {Parent appendPage(Frame Label)}
      end
      meth collect
         {Dictionary.put @opDict inspectorOptionsRange @globalToggleVar}
      end
   end
in
   class InspectorGUIClass from GTK.dialog GlobalNote DisplayNote VisualNote
      attr
         opDict     %% Options Dictionary
         winEntry   %% Toplevel Menu Item
         printDict  %% Readable Names Dictionary (N->P)
         namesDict  %% Readable Names Dictionary (P->N)
         inspPort   %% Inspector Port
         book       %% Book
         syncCall   %% SyncCall Procedure
         colPannerWin : nil
      meth create(WinEntry Options InspPort)
         ConvTypes = {Dictionary.get Options typeConversion}
      in
         GTK.dialog, new
         {self setTitle("Inspector Settings")}
         @opDict    = Options
         @inspPort  = InspPort
         @printDict = {Dictionary.new}
         @namesDict = {Dictionary.new}
         @winEntry  = WinEntry
         {WinEntry setSensitive(0)}
         @syncCall    = proc {$ M}
                           {Port.send InspPort Call(proc {$} {self M} end)}
                        end
         {self signalConnect('delete-event'
                             proc {$ _}
                                {@syncCall handle(destroy)}
                             end _)}
         InspectorGUIClass, fillNamesDict(ConvTypes)
         InspectorGUIClass, createNotebook
         InspectorGUIClass, createButtons
         {self showAll}
      end
      meth fillNamesDict(Ls)
         case Ls
         of (N#P)|Lr then
            {Dictionary.put @printDict N P}
            {Dictionary.put @namesDict P N}
            InspectorGUIClass, fillNamesDict(Lr)
         [] nil then skip
         end
      end
      meth createNotebook
         Note = {New GTK.notebook new}
      in
         DisplayNote, create(Note)
         VisualNote, create(Note)
         GlobalNote, create(Note)
         {{self dialogGetFieldVbox($)} add(Note)}
      end
      meth createButtons
         Box          = {New GTK.hBox new(1 4)}
         OkButton     = {New GTK.button newWithLabel("   Ok   ")}
         ApplyButton  = {New GTK.button newWithLabel(" Apply  ")}
         CancelButton = {New GTK.button newWithLabel(" Cancel ")}
         SyncCall     = @syncCall
      in
         {OkButton signalConnect('clicked'
                                 proc {$ _}
                                    {SyncCall handle(ok)}
                                 end _)}
         {ApplyButton signalConnect('clicked'
                                    proc {$ _}
                                       {SyncCall handle(apply)}
                                    end _)}
         {CancelButton signalConnect('clicked'
                                     proc {$ _}
                                        {SyncCall handle(cancel)}
                                     end _)}
         {Box packStart(OkButton 0 0 0)}
         {Box packStart(ApplyButton 0 0 0)}
         {Box packStart(CancelButton 0 0 0)}
         {{self dialogGetFieldActionArea($)} add(Box)}
      end
      meth collect
         skip %% This is to satisfy the oo system
      end
      meth handle(Mode)
         InspPort = @inspPort
         SyncCall = @syncCall
      in
         case Mode
         of ok then
            GlobalNote, collect
            DisplayNote, collect
            VisualNote, collect
            {Port.send InspPort setOptions(@opDict)}
            {@winEntry setSensitive(1)}
            InspectorGUIClass, tellClose
         [] apply then
            GlobalNote, collect
            DisplayNote, collect
            VisualNote, collect
            {Port.send InspPort setOptions(@opDict)}
         [] cancel then
            {@winEntry setSensitive(1)}
            InspectorGUIClass, tellClose
         [] destroy then
            {@winEntry setSensitive(1)}
            InspectorGUIClass, tellClose
         [] colorselection(Button) then
            Dialog    = {New GTK.colorSelectionDialog new("Select Color")}
            ColorItem = @visualColorItem
            ColorSel  = {Dictionary.condGet @namesDict ColorItem ColorItem}
            ColorKey  = {VirtualString.toAtom ColorSel#"Color"}
            ColorVal  = {Dictionary.get @opDict ColorKey}
         in
            {Button setSensitive(0)}
            {{Dialog colorSelectionDialogGetFieldColorsel($)}
             setColor({ComputeColor ColorVal})}
            {{Dialog colorSelectionDialogGetFieldOkButton($)}
             signalConnect('clicked'
                           proc {$ _}
                              {SyncCall handle(acceptcolor(Button Dialog))}
                           end _)}
            {{Dialog colorSelectionDialogGetFieldCancelButton($)}
             signalConnect('clicked'
                           proc {$ _}
                              {SyncCall handle(cancelcolor(Button Dialog))}
                           end _)}
            {Dialog showAll}
            colPannerWin <- Dialog
         [] acceptcolor(Button Dialog) then
            Selection = {Dialog colorSelectionDialogGetFieldColorsel($)}
         in
            case {Map {Selection getColor($)} Float.toInt}
            of [R G B _] then
               ColorItem = @visualColorItem
               ColorSel  = {Dictionary.condGet @namesDict ColorItem ColorItem}
               ColorKey  = {VirtualString.toAtom ColorSel#"Color"}
               ColorVal  = {VirtualString.toAtom
                            "#"#{IntToHex R}#{IntToHex G}#{IntToHex B}}
            in
               {Dictionary.put @opDict ColorKey ColorVal}
            end
            {Dialog unmap}
            colPannerWin <- nil
            {Button setSensitive(1)}
         [] cancelcolor(Button Dialog) then
            {Dialog unmap}
            colPannerWin <- nil
            {Button setSensitive(1)}
         [] _ then skip
         end
      end
      meth tellClose
         case @colPannerWin
         of nil  then skip
         [] Node then {Node unmap}
         end
         {self unmap}
      end
   end
end
