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

local
   FrameColor       = '#d9d9d9'
   MediumFontFamily = '-*-helvetica-medium-r-normal--*-'
   FontMatch        = '-*-*-*-*-*-*'
   MediumFont       = MediumFontFamily # 120 # FontMatch

   fun {SyncCall CallPort P}
      proc {$}
         {Port.send CallPort Call(P)}
      end
   end

   fun {SyncOne CallPort P}
      proc {$ V}
         {Port.send CallPort CallOne(P V)}
      end
   end

   class PopupSelector from Tk.frame
      attr
         popupToplevel
         popupLabel
         popupValue
         popupMenu
         popupHandler
         inspPort
      meth create(Parent Width Sel ActiveCheck Handler Ls InspPort)
         Tk.frame, tkInit(parent:             Parent
                          borderwidth:        1
                          relief:             raised
                          highlightthickness: 0)
         local
            MyLabel = {New Tk.label
                       tkInit(parent:      self
                              text:        Sel
                              font:        MediumFont
                              anchor:      w
                              width:       Width
                              background:  white)}
            MyCanvas = {New Tk.canvas
                        tkInit(parent:             self
                               width:              11
                               height:             11
                               borderwidth:        0
                               highlightthickness: 0)}
            Toplevel
         in
            @inspPort = InspPort
            PopupSelector, makeMenu(Toplevel _ Ls) %% _ equals Menu
            @popupToplevel = Toplevel
            @popupValue    = Sel
            @popupLabel    = MyLabel
            @popupHandler  = Handler
            {MyCanvas tkBind(event:  '<1>'
                             action:
                                {SyncCall InspPort proc {$}
                                             if {ActiveCheck}
                                             then {self popup} end
                                          end})}
            {MyCanvas tk(cre line 11 1 1 1 5 11)}
            {MyCanvas tk(cre line 10 0 5 10)}
            {Tk.batch [grid(row: 0 column: 0 MyLabel sticky: nw)
                       grid(row: 0 column: 1 MyCanvas sticky: w)]}
         end
      end
      meth makeMenu(?Toplevel ?Menu Ls)
         Toplevel = {New Tk.toplevel
                     tkInit(withdraw: true)}
         Menu     = {New Tk.menu
                     tkInit(parent:            Toplevel
                            tearoff:           false
                            borderwidth:       1
                            background:        white
                            activebackground:  blue4
                            activeforeground:  white
                            activeborderwidth: 0)}
         PopupSelector, createEntries(Menu Ls)
      end
      meth createEntries(Menu Es)
         case Es
         of Entry|Er then
            _ = {New Tk.menuentry.command
                 tkInit(parent: Menu
                        label:  Entry
                        font:   MediumFont
                        action: {SyncCall @inspPort
                                 proc {$} {self handle(Entry)} end})}
            PopupSelector, createEntries(Menu Er)
         else popupMenu <- Menu
         end
      end
      meth configure(SelVal SelList)
         Toplevel
      in
         popupToplevel <- Toplevel
         popupValue    <- SelVal
         {@popupLabel tk(conf text: SelVal)}
         PopupSelector, makeMenu(Toplevel _ SelList) %% _ equals menu
      end
      meth handle(Entry)
         OldEntry = @popupValue
      in
         popupValue <- Entry
         if OldEntry == Entry
         then skip
         else
            {@popupLabel tk(configure text: Entry)}
            {@popupHandler Entry}
         end
      end
      meth popup
         RootX  = {Tk.returnInt winfo(rootx self)}
         RootY  = {Tk.returnInt winfo(rooty self)}
         Height = {Tk.returnInt winfo(reqheight self)}
      in
         {Tk.send tk_popup(@popupMenu RootX (RootY + Height))}
      end
      meth getValue($)
         @popupValue
      end
   end

   class GlobalNote
      attr
         globalVariable
      meth create
         MyBook   = @book
         MyNote   = {New TkTools.note
                     tkInit(parent: MyBook
                            text:   'Range')}
         MyCanvas = {New Tk.canvas
                     tkInit(parent:             MyNote
                            width:              400
                            height:             400
                            borderwidth:        0
                            highlightthickness: 0)}
         MyFrame  = {New Tk.frame
                     tkInit(parent:             self
                            borderwidth:        0
                            highlightthickness: 0)}
         OpDict   = @opDict
      in
         {MyCanvas tk(cre window 0 0 anchor: nw window: MyFrame)}
         {MyBook add(MyNote)}
         local
            TextFrame  = {New TkTools.textframe
                          tkInit(parent: MyFrame
                                 text:   'Apply Settings to')}
            InnerFrame = TextFrame.inner
            MyVar      = {New Tk.variable
                          tkInit({Dictionary.get OpDict inspectorOptionsRange})}
            SingleRad  = {New Tk.radiobutton
                          tkInit(parent:   InnerFrame
                                 text:     'Active Widget only'
                                 font:     MediumFont
                                 variable: MyVar
                                 value:    'active'
                                 anchor:   w)}
            AllRad     = {New Tk.radiobutton
                          tkInit(parent:   InnerFrame
                                 text:     'All shown Widgets'
                                 font:     MediumFont
                                 variable: MyVar
                                 value:    'all'
                                 anchor:   w)}
            Canvas    = {New Tk.canvas
                         tkInit(parent:             InnerFrame
                                width:              233 %% 228
                                height:             0
                                borderwidth:        0
                                highlightthickness: 0)}
         in
            @globalVariable = MyVar
            {Tk.batch [grid(row: 0 column: 0 SingleRad padx: 4 pady: 4 sticky: nw)
                       grid(row: 0 column: 1 Canvas padx: 4 pady: 4 sticky: nw)
                       grid(row: 1 column: 0 AllRad padx: 4 pady: 4 sticky: nw)
                       grid(row: 0 column: 0 TextFrame padx: 4 pady: 4 sticky: nw)]}
         end
         {Tk.send pack(MyCanvas anchor: nw padx: 0 pady: 0)}
      end
      meth collect
         {Dictionary.put @opDict inspectorOptionsRange {@globalVariable tkReturnAtom($)}}
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
         case Ss of I|Sr then if Ss == S then nil else I|{CutSub Sr S} end else 'Alert' end
         %%      if Ss == S then nil elsecase Ss of I|Sr then I|{CutSub Sr S} end
      end
      fun {CutMap S}
         {CutSub {Atom.toString S} SubVal}
      end
      ExtractAuto     = {NewName}
      CreateFilters   = {NewName}
      HandleNewFilter = {NewName}
      AdjustFilters   = {NewName}
   in
      class DisplayNote
         attr
            displayWidth
            displayDepth
            displayVariable
            displayRelation
            mappingType
            mappingSelector
            mappingVariable
            mappingNoAuto
            mappingAuto
         meth create
            MyBook   = @book
            MyNote   = {New TkTools.note
                        tkInit(parent: MyBook
                               text:   'Structure')}
            MyCanvas = {New Tk.canvas
                        tkInit(parent:             MyNote
                               width:              400
                               height:             400
                               borderwidth:        0
                               highlightthickness: 0)}
            MyFrame  = {New Tk.frame
                        tkInit(parent:             self
                               borderwidth:        0
                               highlightthickness: 0)}
            OpDict   = @opDict
            InspPort = @inspPort
         in
            {MyCanvas tk(cre window 0 0 anchor: nw window: MyFrame)}
            {MyBook add(MyNote)}
            local
               TravFrame  = {New TkTools.textframe
                             tkInit(parent: MyFrame
                                    text: 'Traversal')}
               TravInner  = TravFrame.inner
               WidthLabel = {New Tk.label
                             tkInit(parent: TravInner
                                    text:   'Width Limit:'
                                    font:   MediumFont)}
               DepthLabel = {New Tk.label
                             tkInit(parent: TravInner
                                    text:   'Depth Limit:'
                                    font:   MediumFont)}
               WidthEntry = @displayWidth
               DepthEntry = @displayDepth
               FillCanvas = {New Tk.canvas
                             tkInit(parent:             TravInner
                                    width:              225 %% 230
                                    height:             0
                                    borderwidth:        0
                                    highlightthickness: 0)}
            in
               WidthEntry = {New TkTools.numberentry
                             tkInit(parent:      TravInner
                                    width:       6
                                    min:         0
                                    val:         {Dictionary.get OpDict widgetTreeWidth})}
               DepthEntry = {New TkTools.numberentry
                             tkInit(parent:      TravInner
                                    width:       6
                                    min:         0
                                    val:         {Dictionary.get OpDict widgetTreeDepth})}

               {WidthEntry.entry tk(conf background: white)}
               {DepthEntry.entry tk(conf background: white)}
               {Tk.batch [grid(row: 0 column: 0 WidthLabel padx: 4 pady: 4 sticky: w)
                          grid(row: 0 column: 1 WidthEntry padx: 4 pady: 4 sticky: nw)
                          grid(row: 0 column: 2 FillCanvas padx: 4 pady: 4 sticky: nw)
                          grid(row: 1 column: 0 DepthLabel padx: 4 pady: 4 sticky: w)
                          grid(row: 1 column: 1 DepthEntry padx: 4 pady: 4 sticky: nw)
                          grid(row: 0 column: 0 TravFrame padx: 4 pady: 4 sticky: ew)]}
            end
            local
               RepFrame   = {New TkTools.textframe
                             tkInit(parent: MyFrame
                                    text:   'Representation')}
               RepInner   = RepFrame.inner
               VarVal     = if {Dictionary.get OpDict widgetTreeDisplayMode}
                            then 'true' else 'false' end
               MyVar      = {New Tk.variable
                             tkInit(VarVal)}
               TreeRad    = {New Tk.radiobutton
                             tkInit(parent:   RepInner
                                    text:     'Tree Mode'
                                    font:     MediumFont
                                    variable: MyVar
                                    value:   'true'
                                    anchor:  w)}
               RelRad     = {New Tk.radiobutton
                             tkInit(parent:   RepInner
                                    text:     'Relation Mode'
                                    font:     MediumFont
                                    variable: MyVar
                                    value:    'false'
                                    anchor:   w)}
               RelHandler = proc {$ Type}
                               skip
                            end
               StartSel
               NatRelList = {Dictionary.get OpDict widgetRelationList}
               RelList    = DisplayNote, filterRels(NatRelList StartSel $)
               RelActive  = fun {$}
                               {MyVar tkReturnAtom($)} == 'false'
                            end
               RelPopup   = {New PopupSelector
                             create(RepInner 20 StartSel RelActive RelHandler RelList InspPort)}
               FillCanvas = {New Tk.canvas
                             tkInit(parent:             RepInner
                                    width:              0
                                    height:             0
                                    borderwidth:        0
                                    highlightthickness: 0)}
            in
               @displayVariable = MyVar
               @displayRelation = RelPopup
               {Tk.batch [grid(row: 0 column: 0 TreeRad padx: 4 pady: 4 sticky: nw)
                          grid(row: 0 column: 1 FillCanvas padx: 4 pady: 4 sticky: nw)
                          grid(row: 1 column: 0 RelRad padx: 4 pady: 4 sticky: nw)
                          grid(row: 1 column: 1 RelPopup padx: 4 pady: 4 sticky:nw)
                          grid(row: 1 column: 0 RepFrame padx: 4 pady: 4 sticky: ew)]}
            end
            local
               TextFrame     = {New TkTools.textframe
                                tkInit(parent: MyFrame
                                       text:   'Mapping')}
               NewMyFrame    = TextFrame.inner
               TypeFrame     = {New Tk.frame
                                tkInit(parent:             NewMyFrame
                                       borderwidth:        0
                                       highlightthickness: 0)}
               TypeLabel     = {New Tk.label
                                tkInit(parent: TypeFrame
                                       text:   'Selected Type:'
                                       font:    MediumFont)}
               TypeHandler   = proc {$ Type}
                                  OldType = @mappingType
                               in
                                  if OldType == Type
                                  then skip
                                  else
                                     DisplayNote, HandleNewFilter(OldType Type)
                                     mappingType <- Type
                                  end
                               end
               TypeActive    = fun {$}
                                  true
                               end
               TypesList     = {Map {Filter {Dictionary.keys OpDict} SubFilter} CutMap}
               FilRawFun     = {Dictionary.get OpDict inspectorOptionsFilter}
               FilTypesList  = {Filter TypesList
                                fun {$ Type}
                                   {FilRawFun map Type}
                                end}
               TypPrList     = {Sort {Map FilTypesList
                                      fun {$ N}
                                         NA = {VirtualString.toAtom N}
                                      in
                                         {Dictionary.condGet @printDict NA NA}
                                      end}
                                Value.'<'}
               MappingType   = TypPrList.1
               TypeSelector  = {New PopupSelector
                                create(TypeFrame 20 MappingType TypeActive TypeHandler TypPrList InspPort)}
               MappingFrame  = {New TkTools.textframe
                                tkInit(parent: NewMyFrame
                                       text:  'Type Defaults')}
               MappingInner  = MappingFrame.inner
               MapTypeName   = {Dictionary.condGet @namesDict MappingType MappingType}
               AllTypeMenu   = {Dictionary.get OpDict {VirtualString.toAtom MapTypeName#'Menu'}}
               AllFilter     = case AllTypeMenu of nil then nil else AllTypeMenu.3 end
               AutoFilter    = DisplayNote, ExtractAuto(AllFilter $)
               VarValue      = case AutoFilter of nil then 'none' else 'auto' end
               MyVar         = {New Tk.variable
                                tkInit(VarValue)}
               NoneRad       = {New Tk.radiobutton
                                tkInit(parent:   MappingInner
                                       text:     'No Default Mapping'
                                       font:     MediumFont
                                       variable: MyVar
                                       value:    'none'
                                       anchor:   w)}
               ApplyRad      = {New Tk.radiobutton
                                tkInit(parent:   MappingInner
                                       text:     'Apply'
                                       font:     MediumFont
                                       variable: MyVar
                                       value:    'auto'
                                       anchor:   w)}
               ApplyHandler  = proc {$ Type}
                                  skip
                               end
               ApplyActive   = fun {$}
                                  {@mappingVariable tkReturnAtom($)} == 'auto'
                               end
               FilterList    = DisplayNote, CreateFilters(AllFilter $)
               ShowSel       = case AutoFilter of nil then
                                  case AllFilter of F|_ then F else 'No Mapfunctions defined' end
                               else AutoFilter end
               ApplySelector = {New PopupSelector
                                create(MappingInner 20 ShowSel ApplyActive
                                       ApplyHandler FilterList InspPort)}
               FillCanvas    = {New Tk.canvas
                                tkInit(parent:             MappingInner
                                       width:              215%240
                                       height:             0
                                       borderwidth:        0
                                       highlightthickness: 0)}
            in
               @mappingType     = MappingType
               @mappingSelector = ApplySelector
               @mappingVariable = MyVar
               @mappingNoAuto   = NoneRad
               @mappingAuto     = ApplyRad
               {Tk.batch [grid(row: 0 column: 0 TypeLabel padx: 4 pady: 4 sticky: w)
                          grid(row: 0 column: 1 TypeSelector padx: 4 pady: 4 sticky: nw)
                          grid(row: 0 column: 0 TypeFrame padx: 4 pady: 4 sticky: nw)
                          grid(row: 0 column: 0 NoneRad padx: 4 pady: 4 sticky: nw)
                          grid(row: 0 column: 1 FillCanvas padx: 4 pady: 4 sticky: nw)
                          grid(row: 1 column: 0 ApplyRad padx: 4 pady: 4 sticky: nw)
                          grid(row: 1 column: 1 ApplySelector padx: 4 pady: 4 sticky: nw)
                          grid(row: 1 column: 0 MappingFrame padx: 4 pady: 4 sticky: nw)
                          grid(row: 2 column: 0 TextFrame padx: 4 pady: 4 sticky: nw)]}
            end
            {Tk.send pack(MyCanvas anchor: nw padx: 0 pady: 0)}
         end
         meth filterRels(Rs SR ?R)
            case Rs
            of Rel|Rr then
               TF      = case Rel of auto(TF) then SR = {Label TF} TF else Rel end
               MyLabel = {Label TF}
               Tail
            in
               R = MyLabel|Tail
               DisplayNote, filterRels(Rr SR Tail)
            else R = nil
            end
         end
         meth buildRels(Rs SR ?R)
            case Rs
            of Rel|Rr then
               TF      = case Rel of auto(TF) then TF else Rel end
               MyLabel = {Label TF}
               Tail
            in
               R = if {System.eq MyLabel SR} then auto(TF) else TF end|Tail
               DisplayNote, buildRels(Rr SR Tail)
            else R = nil
            end
         end
         meth !HandleNewFilter(OldType NewType)
            NamesDict = @namesDict
            OTA       = {VirtualString.toAtom OldType}
            NTA       = {VirtualString.toAtom NewType}
            OTN       = {Dictionary.condGet NamesDict OTA OTA}
            NTN       = {Dictionary.condGet NamesDict NTA NTA}
            AutoLabel = case {@mappingVariable tkReturnAtom($)}
                        of 'auto' then {@mappingSelector getValue($)} else nil end
            OpDict    = @opDict
            OldKey    = {VirtualString.toAtom OTN#'Menu'}
            NewKey    = {VirtualString.toAtom NTN#'Menu'}
         in
            case {Dictionary.get OpDict OldKey}
            of menu(WL DL FL AL) then
               NewFL = DisplayNote, AdjustFilters(FL AutoLabel $)
            in
               {Dictionary.put OpDict OldKey menu(WL DL NewFL AL)}
            else skip
            end
            if OldKey \= NewKey
            then
               FL = case {Dictionary.get OpDict NewKey} of menu(_ _ FL _) then FL else nil end
               AutoLabel  = DisplayNote, ExtractAuto(FL $)
               FilterList = DisplayNote, CreateFilters(FL $)
               VarValue   = case AutoLabel of nil then 'none' else 'auto' end
               MyVar      = {New Tk.variable tkInit(VarValue)}
               ShowSel    = case AutoLabel of nil then
                               case FilterList of F|_ then F else 'No Mapfunctions defined' end
                            else AutoLabel
                            end
            in
               mappingVariable <- MyVar
               {@mappingNoAuto tk(conf variable: MyVar)}
               {@mappingAuto tk(conf variable: MyVar)}
               {@mappingSelector configure(ShowSel FilterList)}
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
               case Filter of auto(TF) then {Label TF} else DisplayNote, ExtractAuto(Fr $) end
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
            OpDict  = @opDict
            Width   = case {@displayWidth.entry tkReturnInt(get $)} of false then 0 elseof N then N end
            Height  = case {@displayDepth.entry tkReturnInt(get $)} of false then 0 elseof N then N end
            Mode    = case {@displayVariable tkReturnAtom($)} of 'false' then false else true end
            Rels    = {Dictionary.get OpDict widgetRelationList}
            NewRels = DisplayNote, buildRels(Rels {@displayRelation getValue($)} $)
            MapType = @mappingType
         in
            {Dictionary.put OpDict widgetTreeWidth Width}
            {Dictionary.put OpDict widgetTreeDepth Height}
            {Dictionary.put OpDict widgetTreeDisplayMode Mode}
            {Dictionary.put OpDict widgetRelationList NewRels}
            DisplayNote, HandleNewFilter(MapType MapType)
         end
      end
   end
   ChangeColor = {NewName} %% is needed for GUI Class
   local
      FontSizes = ['10' '12' '14' '18' '24']
      SubVal    = "Color"
      fun {HasSub Ss S}
         case Ss of _|Sr then Ss == S orelse {HasSub Sr S} else false end
      end
      fun {SubFilter S}
         {HasSub {Atom.toString S} SubVal}
      end
      fun {CutSub Ss S}
         case Ss of I|Sr then if Ss == S then nil else I|{CutSub Sr S} end else 'Alert' end
         %%      if Ss == S then nil elsecase Ss of I|Sr then I|{CutSub Sr S} end
      end
      fun {CutMap S}
         {CutSub {Atom.toString S} SubVal}
      end
      ComputeColorList  = {NewName}
      ComputeColorParts = {NewName}
      StretchColorList  = {NewName}
      MatchColor        = {NewName}
      local
         List = ['0'#0  '1'#1 '2'#2 '3'#3 '4'#4 '5'#5
                 '6'#6 '7'#7 '8'#8 '9'#9 'a'#10 'b'#11 'c'#12 'd'#13 'e'#14 'f'#15
                 'A'#10 'B'#11 'C'#12 'D'#13 'E'#14 'F'#15]
         D    = {Dictionary.new}
      in
         _ = {Map List fun {$ V} case V of Key#Value then {Dictionary.put D Key Value} V end end}
         fun {HexToInt N}
            {Dictionary.get D {Char.toAtom N}}
         end
      end
      local
         List = [0#'0' 1#'1' 2#'4' 3#'3' 4#'4' 5#'5' 6#'6' 7#'7' 8#'8' 9#'9' 10#'A'
                 11#'B' 12#'C' 13#'D' 14#'E' 15#'F']
         D    = {Dictionary.new}
      in
         _ = {Map List fun {$ V} case V of Key#Value then {Dictionary.put D Key Value} V end end}
         fun {IntToHex N}
            NH = N div 16
            NL = N mod 16
         in
            {Dictionary.get D NH}#{Dictionary.get D NL}
         end
      end
   in
      class VisualNote
         attr
            visualCurType
            visualCanvas
            visualColDict
            visualTagDict
            visualSelection
            visualFontSize
            visualFontBold
            visualRed
            visualGreen
            visualBlue
            visualRecAlign
            visualStringShow
         meth create
            MyBook   = @book
            MyNote   = {New TkTools.note
                        tkInit(parent: MyBook
                               text:   'Appearance')}
            MyCanvas = {New Tk.canvas
                        tkInit(parent:             MyNote
                               width:              400
                               height:             400
                               borderwidth:        0
                               highlightthickness: 0)}
            MyFrame  = {New Tk.frame
                        tkInit(parent:             self
                               borderwidth:        0
                               highlightthickness: 0)}
            OpDict   = @opDict
            InspPort = @inspPort
         in
            {MyCanvas tk(cre window 0 0 anchor: nw window: MyFrame)}
            {MyBook add(MyNote)}
            local
               ColorFrame   = {New TkTools.textframe
                               tkInit(parent: MyFrame
                                      text:   'Colors')}
               ColFrInner   = ColorFrame.inner
               TypeFrame    = {New Tk.frame
                               tkInit(parent:             ColFrInner
                                      borderwidth:        0
                                      highlightthickness: 0)}
               TypeLabel    = {New Tk.label
                               tkInit(parent: TypeFrame
                                      text:   'Selected Type:'
                                      font:   MediumFont)}
               THandler     = proc {$ Type}
                                 OldType = @visualCurType
                              in
                                 if OldType \= Type
                                 then
                                    TN    = {Dictionary.condGet @namesDict Type Type}
                                    Color = {Dictionary.get @opDict
                                             {VirtualString.toAtom TN#'Color'}}
                                 in
                                    visualCurType <- Type
                                    {self handle(selCol(VisualNote, MatchColor(1 Color $)))}
                                 end
                              end
               TAct         = fun {$}
                                 true
                              end
               ColorKeys    = {Filter {Dictionary.keys OpDict} SubFilter}
               KnownColors  = VisualNote, ComputeColorList(OpDict ColorKeys nil $)
               ColorList    = {Map ColorKeys CutMap}
               FilRawFun    = {Dictionary.get OpDict inspectorOptionsFilter}
               FilColList   = {Filter ColorList
                               fun {$ Type}
                                  {FilRawFun color Type}
                               end}
               ColPrList    = {Sort {Map FilColList
                                     fun {$ N}
                                        NA = {VirtualString.toAtom N}
                                     in
                                        {Dictionary.condGet @printDict NA NA}
                                     end}
                               Value.'<'}
               SelColor     = ColPrList.1
               TypeSelector = {New PopupSelector
                               create(TypeFrame 20 SelColor TAct THandler ColPrList InspPort)}
               ColorCanvas  = {New Tk.canvas
                               tkInit(parent:             ColFrInner
                                      width:              260
                                      height:             100
                                      borderwidth:        0
                                      highlightthickness: 0)}
               FillCanvas   = {New Tk.canvas
                               tkInit(parent:             TypeFrame
                                      width:              111 % 110
                                      height:             0
                                      borderwidth:        0
                                      highlightthickness: 0)}
               FontFrame    = {New TkTools.textframe
                               tkInit(parent: MyFrame
                                      text:   'Font')}
               FontInner    = FontFrame.inner
               SizeLabel    = {New Tk.label
                               tkInit(parent: FontInner
                                      text:   'Font Size:'
                                      font:   MediumFont)}
               SizeHandler  = proc {$ Size}
                                 visualFontSize <- {String.toInt {Atom.toString Size}}
                              end
               SizeActive   = fun {$}
                                 true
                              end
               InitFont     = {Dictionary.get OpDict widgetTreeFont}
               InitFSize    = InitFont.size
               SizeSelector = {New PopupSelector
                               create(FontInner 3 InitFSize SizeActive SizeHandler FontSizes InspPort)}
               BoldVar      = {New Tk.variable
                               tkInit(InitFont.weight)}
               BoldButton   = {New Tk.checkbutton
                               tkInit(parent:   FontInner
                                      text:     'Bold'
                                      onvalue:  bold
                                      offvalue: normal
                                      font:     MediumFont
                                      variable: BoldVar
                                      anchor:   w)}
               BoldFillCanv = {New Tk.canvas
                               tkInit(parent:             FontInner
                                      width:              190 % 205
                                      height:             0
                                      borderwidth:        0
                                      highlightthickness: 0)}
               SelColN      = {Dictionary.condGet @namesDict SelColor SelColor}
               GetColor     = {Dictionary.get OpDict {VirtualString.toAtom SelColN#'Color'}}
               RecordFrame  = {New TkTools.textframe
                               tkInit(parent: MyFrame
                                      text:   'Subtree Alignment')}
               RecordInner  = RecordFrame.inner
               RecordVar    = local
                                 Val    = {Dictionary.get OpDict widgetUseNodeSet}
                                 NewVal = if Val == 3 then 1 else Val end
                              in
                                 {New Tk.variable tkInit(NewVal)}
                              end
               RecordButton = {New Tk.checkbutton
                               tkInit(parent:   RecordInner
                                      text:     'Use Fixed Width Indent'
                                      onvalue:  2
                                      offvalue: 1
                                      font:     MediumFont
                                      variable: RecordVar
                                      anchor:   w)}
               RecordFillC  = {New Tk.canvas
                               tkInit(parent:             RecordInner
                                      width:              211 % 221
                                      height:             0
                                      borderwidth:        0
                                      highlightthickness: 0)}
               StringFrame  = {New TkTools.textframe
                               tkInit(parent: MyFrame
                                      text:   'String Handling')}
               StringInner  = StringFrame.inner
               StringVar    = local
                                 Val = {Dictionary.get OpDict
                                        widgetShowStrings}
                                 NewVal = if Val then 1 else 0 end
                              in
                                 {New Tk.variable tkInit(NewVal)}
                              end
               StringButton = {New Tk.checkbutton
                               tkInit(parent:   StringInner
                                      text:     'Show Strings'
                                      onvalue:  1
                                      offvalue: 0
                                      font:     MediumFont
                                      variable: StringVar
                                      anchor:   w)}
               StringFillC = {New Tk.canvas
                              tkInit(parent:             StringInner
                                     width:              265
                                     height:             0
                                     borderwidth:        0
                                     highlightthickness: 0)}
            in
               @visualCurType = SelColor
               @visualCanvas  = ColorCanvas
               @visualColDict = {Dictionary.new}
               VisualNote, fillColorDict(KnownColors 1)
               @visualTagDict = {Dictionary.new}
               VisualNote, createColors(1 0 0)
               @visualFontBold = BoldVar
               @visualFontSize = InitFSize
               @visualRecAlign = RecordVar
               @visualStringShow = StringVar
               {self handle(selCol(VisualNote, MatchColor(1 GetColor $)))}
               {Tk.batch [grid(row: 0 column: 0 SizeLabel padx: 4 pady: 4 sticky: w)
                          grid(row: 0 column: 1 SizeSelector padx: 4 pady: 4 sticky: nw)
                          grid(row: 0 column: 2 BoldFillCanv padx: 0 pady: 0 sticky: nw)
                          grid(row: 0 column: 3 BoldButton padx: 4 pady: 4 sticky: w)
                          grid(row: 0 column: 0 FontFrame padx: 4 pady: 4 sticky: nw)

                          grid(row: 0 column: 0 RecordButton padx: 4 pady: 4 sticky: nw)
                          grid(row: 0 column: 1 RecordFillC padx:0 pady:0 sticky: nw)
                          grid(row: 1 column: 0 RecordFrame padx: 4 pady:4 sticky: nw)

                          grid(row: 0 column: 0 StringButton padx: 4 pady: 4 sticky: nw)
                          grid(row: 0 column: 1 StringFillC padx: 0 pady: 0 sticky: nw)
                          grid(row: 2 column: 0 StringFrame padx: 4 pady: 4 sticky: nw)

                          grid(row: 0 column: 0 TypeLabel padx: 4 pady: 4 sticky: w)
                          grid(row: 0 column: 1 TypeSelector padx: 4 pady: 4 sticky: nw)
                          grid(row: 0 column: 2 FillCanvas   padx: 0 pady: 0 sticky: nw)
                          grid(row: 0 column: 0 TypeFrame padx: 4 pady: 4 sticky:nw)
                          grid(row: 1 column: 0 ColorCanvas padx: 50 pady: 4 sticky: nw)
                          grid(row: 3 column: 0 ColorFrame padx: 4 pady: 4 sticky: nw)]}
            end
            {Tk.send pack(MyCanvas anchor: nw padx: 0 pady: 0)}
         end
         meth !ComputeColorList(D Keys Cs $)
            case Keys
            of Key|Kr then
               Color = {Dictionary.get D {VirtualString.toAtom Key}}
            in
               VisualNote, ComputeColorList(D Kr if {Member Color Cs} then Cs else Color|Cs end $)
            else VisualNote, StretchColorList({Length Cs} Cs $)
            end
         end
         meth !StretchColorList(I Cs $)
            if I =< 24
            then VisualNote, StretchColorList((I + 1) '#ffffff'|Cs $)
            else {Reverse Cs}
            end
         end
         meth !MatchColor(I Color $)
            if I =< 24
            then
               if {System.eq {Dictionary.get @visualColDict I} Color}
               then I
               else VisualNote, MatchColor((I + 1) Color $)
               end
            else nil
            end
         end
         meth !ChangeColor(I)
            Color    = {Dictionary.get @visualColDict I}
            T        = {New Tk.toplevel
                        tkInit(title:    'Change Color'
                               withdraw: true
                               delete:   {SyncCall @inspPort proc {$} colPannerWin <- nil {T tkClose} end})}
            TopFrame = {New Tk.frame
                        tkInit(parent:             T
                               borderwidth:        1
                               highlightthickness: 0
                               relief:             raised)}
            BotFrame = {New Tk.frame
                        tkInit(parent:             T
                               borderwidth:        1
                               highlightthickness: 0
                               relief:             raised)}
            BtFrame  = {New Tk.frame
                        tkInit(parent:             BotFrame
                               borderwidth:        0
                               highlightthickness: 0)}
            ColFrame = {New Tk.frame
                        tkInit(parent:             TopFrame
                               height:             2#c
                               borderwidth:        0
                               highlightthickness: 0)}
            OkButton =
            {New Tk.button
             tkInit(parent:      BtFrame
                    text:        'Ok'
                    borderwidth: 1
                    width:       6
                    action:      {SyncCall @inspPort
                                  proc {$}
                                     Color = {VirtualString.toAtom
                                              "#"#{IntToHex @visualRed}#
                                              {IntToHex @visualGreen}#
                                              {IntToHex @visualBlue}}
                                  in
                                     colPannerWin <- nil
                                     {T tkClose}
                                     {self handle(updateCol(I Color))}
                                  end})}
            CcButton = {New Tk.button
                        tkInit(parent:      BtFrame
                               text:        'Cancel'
                               width:       6
                               borderwidth: 1
                               action:      {SyncCall @inspPort
                                             proc {$}
                                                colPannerWin <- nil
                                                {T tkClose}
                                             end})}
            Ss
         in
            colPannerWin <- T
            case VisualNote, ComputeColorParts(Color $)
            of RedVal|GreenVal|BlueVal then
               Ss = {Map ['Red'#RedVal 'Green'#GreenVal 'Blue'#BlueVal]
                     fun {$ T}
                        case T
                        of C#Val then
                           Attr    = {VirtualString.toAtom visual#C}
                           AttrVar = {New Tk.variable tkInit(Val)}
                        in
                           Attr <- Val
                           {New Tk.scale
                            tkInit(parent:   TopFrame
                                   label:    C
                                   'from':   0
                                   'to'  :   255
                                   variable: AttrVar
                                   args:     [int]
                                   orient:   horizontal
                                   action:
                                      {SyncOne @inspPort
                                       proc {$ V}
                                          Attr <- V
                                          {ColFrame tk(conf bg: c(@visualRed
                                                                  @visualGreen
                                                                  @visualBlue))}
                                       end})}
                        end
                     end}
            end
            {Tk.batch [pack(b(Ss) ColFrame fill: x)
                       grid(row: 0 column: 0 OkButton padx: 4 pady: 4 sticky: nw)
                       grid(row: 0 column: 1 CcButton padx: 4 pady: 4 sticky: nw)
                       pack(BtFrame anchor:e fill:x)
                       grid(row: 0 column: 0 TopFrame padx: 0 pady: 0 sticky: nwse)
                       grid(row: 1 column: 0 BotFrame padx: 0 pady: 0 sticky: nwse)
                       update(idletasks)
                       wm(deiconify T)]}
         end
         meth !ComputeColorParts(C $)
            case {Atom.toString C}
            of [35 R1 R0 G1 G0  B1 B0] then
               ({HexToInt R1} * 16 + {HexToInt R0})|
               ({HexToInt G1} * 16 + {HexToInt G0})|
               ({HexToInt B1} * 16 + {HexToInt B0})
            end
         end
         meth fillColorDict(Cs I)
            case Cs
            of Color|Cr then
               {Dictionary.put @visualColDict I Color}
               VisualNote, fillColorDict(Cr (I + 1))
            else skip
            end
         end
         meth createColors(I Row Col)
            if I =< 24
            then
               NewRow = case Col of 5 then (Row + 1) else Row end
               NewCol = (Col + 1) mod 6
               Box    = {New Tk.canvasTag
                         tkInit(parent: @visualCanvas)}
               X      = Col * (35 + 4 + 4)
               Y      = Row * (15 + 4 + 4)
            in
               {Dictionary.put @visualTagDict I Box}
               VisualNote, drawBox(X Y Box I)
               VisualNote, createColors((I + 1) NewRow NewCol)
            else @visualSelection = nil
            end
         end
         meth drawBox(X Y Tag I)
            NX    = (X + 2)
            NY    = (Y + 2)
            Color = {Dictionary.get @visualColDict I}
         in
            {@visualCanvas tk(cre rectangle NX NY (NX + 36) (NY + 16)
                              fill:Color outline: FrameColor width: 2 tags: Tag)}
            {Tag tkBind(event: '<1>'
                        action: {SyncCall @inspPort proc {$} {self handle(selCol(I))} end})}
            {Tag tkBind(event: '<3>'
                        action: {SyncCall @inspPort proc {$} {self handle(changeCol(I))} end})}
         end
         meth collect
            OpDict = @opDict
         in
            {Dictionary.put OpDict
             widgetTreeFont font(family: 'courier'
                                 size:   @visualFontSize
                                 weight: {@visualFontBold tkReturnAtom($)})}
            {Dictionary.put OpDict widgetUseNodeSet {@visualRecAlign tkReturnInt($)}}
            {Dictionary.put OpDict widgetShowStrings
             ({@visualStringShow tkReturnInt($)} == 1)}
         end
      end
   end
in
   class InspectorGUIClass from Tk.toplevel GlobalNote DisplayNote VisualNote
      attr
         book
         winEntry
         opDict
         cloneOpDict %% Clone-Dict (used for apply)
         printDict   %% Readable Names Dictionary (N->P)
         namesDict   %% Option Names Dictionary (P->N)
         inspPort    %% Inspector Port
         colPannerWin : nil
      prop
         final
      meth create(WinEntry Options InspPort)
         MyBook = @book
      in
         @inspPort = InspPort
         Tk.toplevel, tkInit(title:    'Inspector Settings'
                             delete:   {SyncCall @inspPort proc {$} {self handle(cancel)} end}
                             withdraw: true)
         @winEntry    = WinEntry
         @opDict      = Options
         @cloneOpDict = {Dictionary.clone Options}
         @printDict   = {Dictionary.new}
         @namesDict   = {Dictionary.new}
         InspectorGUIClass, fillConvDict({Dictionary.get @opDict typeConversion})
         local
            UpFrame    = {New Tk.frame
                          tkInit(parent:             self
                                 borderwidth:        1
                                 relief:             raised
                                 highlightthickness: 0)}
            DnFrame    = {New Tk.frame
                          tkInit(parent:             self
                                 borderwidth:        1
                                 relief:             raised
                                 highlightthickness: 0)}
            BtFrame    = {New Tk.frame
                          tkInit(parent:             DnFrame
                                 borderwidth:        0
                                 highlightthickness: 0)}
            OkButton   = {New Tk.button
                          tkInit(parent:      BtFrame
                                 text:        'Ok'
                                 width:       6
                                 borderwidth: 1
                                 action:      {SyncCall @inspPort proc {$} {self handle(ok)} end})}
            AppButton  = {New Tk.button
                          tkInit(parent:      BtFrame
                                 text:        'Apply'
                                 width:       6
                                 borderwidth: 1
                                 action:      {SyncCall @inspPort proc {$} {self handle(apply)} end})}
            ClButton   = {New Tk.button
                          tkInit(parent:      BtFrame
                                 text:        'Cancel'
                                 width:       6
                                 borderwidth: 1
                                 action:      {SyncCall @inspPort proc {$} {self handle(cancel)} end})}
            FillCanvas = {New Tk.canvas
                          tkInit(parent:             DnFrame
                                 width:              180 %% former 200
                                 height:             0
                                 borderwidth:        0
                                 highlightthickness: 0)}
         in
            MyBook = {New TkTools.notebook
                      tkInit(parent: UpFrame)}
            DisplayNote, create
            VisualNote, create
            GlobalNote, create
            {WinEntry tk(entryconf state:disabled)}
            {Tk.batch [pack(MyBook fill: both padx: 4 pady: 4)
                       grid(row: 0 column: 0 OkButton padx: 4 pady: 6 sticky: nw)
                       grid(row: 0 column: 1 AppButton padx: 4 pady: 6 sticky: nw)
                       grid(row: 0 column: 2 ClButton padx: 4 pady: 6 sticky: nw)
                       grid(row: 0 column: 0 FillCanvas padx: 0 pady: 0 sticky: nw)
                       grid(row: 0 column: 1 BtFrame padx: 0 pady: 0 sticky: nw)
                       grid(row: 0 column: 0 UpFrame padx: 0 pady: 0 sticky: we)
                       grid(row: 1 column: 0 DnFrame padx: 0 pady: 0 sticky: we)
                       wm(resizable self false false)
                       update(idletasks)
                       wm(deiconify self)]}
         end
      end
      meth fillConvDict(Ls)
         case Ls
         of (N#P)|Lr then
            {Dictionary.put @printDict N P}
            {Dictionary.put @namesDict P N}
            InspectorGUIClass, fillConvDict(Lr)
         [] nil then skip
         end
      end
      meth collect
         skip %% This is to satisfy the OO System
      end
      meth handle(Mode)
         InspPort = @inspPort
      in
         case Mode
         of ok        then
            GlobalNote, collect
            DisplayNote, collect
            VisualNote, collect
            Tk.toplevel, tkClose
            {Port.send InspPort setOptions(@opDict)}
            {@winEntry tk(entryconf state: normal)}
         [] apply     then
            GlobalNote, collect
            DisplayNote, collect
            VisualNote, collect
            {Port.send InspPort setOptions(@opDict)}
         [] cancel    then
            Tk.toplevel, tkClose
            {@winEntry tk(entryconf state: normal)}
         [] selCol(I) then
            TagDict = @visualTagDict
            Canvas  = @visualCanvas
            VCType  = @visualCurType
            CurTypN = {Dictionary.condGet @namesDict VCType VCType}
         in
            case @visualSelection
            of nil then skip
            elseof OldI then
               {Canvas tk(itemconfigure {Dictionary.get TagDict OldI} outline: FrameColor)}
            end
            case @colPannerWin of nil then skip [] T then colPannerWin <- nil {T tkClose} end
            visualSelection <- I
            {Dictionary.put @opDict {VirtualString.toAtom CurTypN#'Color'}
             {Dictionary.get @visualColDict I}}
            {Canvas tk(itemconfigure {Dictionary.get TagDict I} outline: black)}
         [] changeCol(I) then
            case @visualSelection
            of nil then skip
            elseof CurI then
               if CurI == I andthen @colPannerWin == nil then VisualNote, ChangeColor(I) end
            end
         [] updateCol(I Col) then
            TagDict = @visualTagDict
            Canvas  = @visualCanvas
         in
            {Dictionary.put @visualColDict I Col}
            {Canvas tk(itemconfigure {Dictionary.get TagDict I} fill: Col)}
            InspectorGUIClass, handle(selCol(@visualSelection))
         end
      end
      meth tellClose
         case @colPannerWin
         of nil then skip
         [] Node then {Node tkClose}
         end
         Tk.toplevel, tkClose
      end
   end
end
