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
   Property(get)
\ifndef INSPECTOR_GTK_GUI
   Tk(localize)
\else
   Resolve(localize)
\endif
   BS(chunkArity shortName) at 'x-oz://boot/Browser'
   BO(getClass send) at 'x-oz://boot/Object'
   BN(newUnique) at 'x-oz://boot/Name'
   DefaultURL(homeUrl)
   URL(make resolve toAtom)
export
   options : Options
define
   ChunkArity = BS.chunkArity
   ShortName  = BS.shortName
   %%
   %% Inspector Global Settings
   %%
   InspectorDefaults =
   [inspectorWidth         # 600
    inspectorHeight        # 400
    inspectorLanguage      # 'Oz' %% Value shown as Prefix
    inspectorOptionsFilter # fun {$ Mode Type} true end %% No Filtering
    inspectorOptionsRange  # 'active' %% 'active' or 'all'
   ]

   %%
   %% TreeWidget Specific Settings
   %%
   %% Node Translation Tables
   NormalNodes      = [int#int float#float atom#atom name#name
                       procedure#procedure
                       hashtuple#hashTuple pipetuple#pipeTuple
                       labeltuple#labelTuple
                       record#record kindedrecord#kindedRecord fdint#fdInt
                       fset#fsVal fsvar#fsVar free#free future#future
                       failed#failed
                       string#string byteString#byteString]
   RelationNodes    = [int#int float#float atom#atom name#name
                       procedure#procedure
                       hashtuple#hashTupleGr pipetuple#pipeTupleGrM
                       labeltuple#labelTupleGr record#recordGr
                       kindedrecord#kindedRecordGr fdint#fdIntGr
                       fset#fsValGr fsvar#fsVarGr free#freeGr future#futureGr
                       failed#failed
                       string#string byteString#byteString]
   NormalIndNodes   = [int#int float#float atom#atom name#name
                       procedure#procedure
                       hashtuple#hashTuple pipetuple#pipeTuple
                       labeltuple#labelTupleInd
                       record#recordInd kindedrecord#kindedRecordInd
                       fdint#fdInt
                       fset#fsVal fsvar#fsVar free#free future#future
                       failed#failed
                       string#string byteString#byteString]
   RelationIndNodes = [int#int float#float atom#atom name#name
                       procedure#procedure
                       hashtuple#hashTupleGr pipetuple#pipeTupleGrM
                       labeltuple#labelTupleGrInd record#recordGrInd
                       kindedrecord#kindedRecordGrInd fdint#fdIntGr
                       fset#fsValGr fsvar#fsVarGr free#freeGr future#futureGr
                       failed#failed
                       string#string byteString#byteString]

   local
      %% Stuctural Equality (Unification Function)
      local
         local
            local
               fun {Eq X#Y PX#PY}
                  {System.eq X PX} andthen {System.eq Y PY}
               end
            in
               fun {IsMember V Set}
                  case Set
                  of P|Sr then ({Eq V P} orelse {IsMember V Sr})
                  [] nil  then false
                  end
               end
            end
            fun {IsRec X}
               {IsDet X} andthen {IsRecord X}
            end
            fun {SameArity X Y}
               {IsRec X} andthen {IsRec Y} andthen
               ({Label X} == {Label Y}) andthen ({Arity X} == {Arity Y})
            end
            fun {ArityPush As X Y S}
               case As
               of F|Ar then {ArityPush Ar X Y (X.F#Y.F)|S}
               [] nil  then S
               end
            end
         in
            fun {DoUnify Stack Set}
               case Stack
               of (X#Y)|Sr then
                  if {System.eq X Y}
                  then {DoUnify Sr Set}
                  elseif {IsMember X#Y Set}
                  then {DoUnify Sr Set}
                  elseif {SameArity X Y}
                  then
                     NewStack = {ArityPush {Arity X} X Y Stack}
                     NewSet   = (X#Y)|(Y#X)|Set
                  in
                     {DoUnify NewStack NewSet}
                  else false
                  end
               [] nil then true
               end
            end
         end
      in
         fun {StructEqual X Y}
            {DoUnify (X#Y)|nil nil}
         end
      end
      %% TK Bitmap Localize Function
      local
         BitmapUrl = {URL.toAtom {URL.resolve DefaultURL.homeUrl
                                  {URL.make 'images/inspector/'}}}

         fun {TranslateToUrl Ss}
            case Ss
            of S|Sr then if S == &\\ then &/ else S end|{TranslateToUrl Sr}
            [] nil  then nil
            end
         end
      in
\ifndef INSPECTOR_GTK_GUI
         fun {Root X}
            F = {Tk.localize BitmapUrl#X}
         in
            {TranslateToUrl {VirtualString.toString {ShortName F}}}
         end
\else
         fun {Root X}
            F = case {Resolve.localize BitmapUrl#X}
                of old(F) then F
                [] new(F) then F
                end
         in
            {TranslateToUrl {VirtualString.toString {ShortName F}}}
         end
\endif
      end
      %% Context Menu Title Preparation Functions
      fun {MakeMenuTitle Type}
         TypeS = case {Map {VirtualString.toString Type} Char.toLower}
                 of FC|Tr then {Char.toUpper FC}|Tr
                 end
      in
         {VirtualString.toAtom TypeS#'-Menu'}
      end
   in
      WidgetDefaults = [
                        widgetTreeWidth        # 50
                        widgetTreeDepth        # 15
                        widgetTreeDisplayMode  # true
                        widgetShowStrings      # false
                        widgetInternalAtomSize # 1000
                        widgetUseNodeSet       # 1 %% Select the used node-set (1,2)
                        widgetNodesContainer   # default %% default or Interface Record
                        widgetNodeSets         # ((NormalNodes|RelationNodes)#
                                                  (NormalIndNodes|RelationIndNodes))
                        widgetRelationList     #
                        ['Structural Equality'(StructEqual)
                         auto('Token Equality'(System.eq))]
\ifndef INSPECTOR_GTK_GUI
                        widgetWidthLimitBitmap # {Root 'width.xbm'}
                        widgetDepthLimitBitmap # {Root 'depth.xbm'}
\else
                        widgetWidthLimitBitmap # {Root 'width.jpg'}
                        widgetDepthLimitBitmap # {Root 'depth.jpg'}
\endif
                        widgetStopBitmap       # {Root 'stop.xbm'}
                        widgetSepBitmap        # {Root 'sep.xbm'}
                        widgetTreeFont         #
                        font(family:'courier' size:10 weight:normal)
                        widgetContextMenuFont  #
                        '-adobe-helvetica-bold-r-*-*-*-100-*'
                        widgetContextMenuABg   # '#d9d9d9'
                        widgetContextMenuTitle # MakeMenuTitle
                        %% This must not be changed!!!!
                        widgetAtomicTest       # default
                       ]
   end

   %%
   %% Default Color settings
   %%
   local
      Color1 = '#a020f0'
      Color2 = '#bc8f8f'
      Color3 = '#000000'
      Color4 = '#0000ff'
      Color5 = '#228b22'
      Color6 = '#ff0000'
      Color7 = '#b22222'
      Color8 = '#b886b0'
      Color9 = '#ffffff'
      BackC  = '#f5f5f5'
   in
      ColorDefaults = [
                       backgroundColor  # Color9
                       intColor         # Color1
                       floatColor       # Color1
                       atomColor        # Color2
                       stringColor      # Color2
                       variablerefColor # Color3
                       refColor         # Color6
                       labelColor       # Color4
                       featureColor     # Color5
                       colonColor       # Color3
                       boolColor        # Color1
                       unitColor        # Color1
                       nameColor        # Color3
                       procedureColor   # Color3
                       futureColor      # Color8
                       failedColor      # Color3
                       bytestringColor  # Color4
                       freeColor        # Color8
                       fdintColor       # Color7
                       genericColor     # Color3
                       internalColor    # Color3
                       bracesColor      # Color3
                       widthbitmapColor # Color6
                       depthbitmapColor # Color6
                       separatorColor   # Color1
                       proxyColor       # BackC
                       selectionColor   # '#f7dfb6'
                      ]
   end


   %%
   %% Default Menu Settings
   %%
   %%  menu(WidthList DepthList FilterList ActionList)


   local
      %% Default Width and Depth Lists
      WidthList = [1 5 10 0 ~1 ~5 ~10]
      DepthList = [1 5 10 0 ~1 ~5 ~10]

      %% Partial Clone Function
      fun {CopyRecVal As NV V}
         case As of F|Ar then NV.F = V.F {CopyRecVal Ar NV V} else NV end
      end

      %% Default Arrow Menus
      ArrowMenus = [
                    widthbitmapMenu # [title('Explore Width')
                                       'Width +1'(changeWidth(1))
                                       'Width +5'(changeWidth(5))
                                       'Width +10'(changeWidth(10))
                                       separator
                                       'Width -1'(changeWidth(~1))
                                       'Width -5'(changeWidth(~5))
                                       'Width -10'(changeWidth(~10))]
                    depthbitmapMenu # [title('Explore Depth')
                                       'Depth +1'(changeDepth(1))
                                       'Depth +5'(changeDepth(5))
                                       'Depth +10'(changeDepth(10))
                                       separator
                                       'Depth -1'(changeDepth(~1))
                                       'Depth -5'(changeDepth(~5))
                                       'Depth -10'(changeDepth(~10))]
                   ]

      %% Default Simple-Type Menus
      SimpleMenus = [
                     intMenu         # nil
                     floatMenu       # nil
                     stringMenu      # nil
                     bytestringMenu  # nil
                     atomMenu        # nil
                     variablerefMenu # nil
                     boolMenu        # nil
                     unitMenu        # nil
                     nameMenu        # nil
                     procedureMenu   # nil
                     lockMenu        # nil
                     portMenu        # nil
                     genericMenu     # nil
                    ]

      %% Default Container-Type Menus
      local
         %% VirtualString Menu Functions
         local
            fun {IsString V W}
               if {IsDet V} andthen W > 0
               then
                  case V
                  of C|Vr then ({IsDet C} andthen {Char.is C}) andthen {IsString Vr (W - 1)}
                  [] nil  then true
                  else false
                  end
               else false
               end
            end
            local
               LimitInd = {NewName}
               D        = {Dictionary.new}
            in
               {Dictionary.put D 1 LimitInd}
               proc {InsertVals I M T}
                  if I =< M then T.I = {Dictionary.get D I} {InsertVals (I + 1) M T} end
               end
               fun {IsCollectable V W}
                  {IsDet V} andthen
                  ({IsAtom V} orelse {IsInt V} orelse {IsFloat V} orelse {IsString V W})
               end
               fun {Convert DI V I TW W F}
                  if I =< TW
                  then
                     Val = V.I
                  in
                     if I =< W andthen {IsCollectable Val W}
                     then
                        CurVal  = {Dictionary.get D DI}
                        RealVal = if {System.eq CurVal LimitInd} then nil else CurVal end
                     in
                        {Dictionary.put D DI
                         {Append RealVal {VirtualString.toString Val}}}
                        {Convert DI V (I + 1) TW W true}
                     else
                        ValDI NewDI
                     in
                        if {System.eq {Dictionary.get D DI} LimitInd}
                        then ValDI = DI       NewDI = (DI + 1)
                        else ValDI = (DI + 1) NewDI = (DI + 2)
                        end
                        {Dictionary.put D ValDI Val} {Dictionary.put D NewDI LimitInd}
                        {Convert NewDI V (I + 1) TW W F}
                     end
                  else
                     RetVal
                  in
                     if F
                     then
                        RealDI = if {System.eq {Dictionary.get D DI} LimitInd}
                                 then (DI - 1) else DI end
                     in
                        RetVal = {MakeTuple '#' RealDI} {InsertVals 1 RealDI RetVal}
                     else RetVal = V
                     end
                     {Dictionary.removeAll D} {Dictionary.put D 1 LimitInd}
                     RetVal
                  end
               end
            end
         in
            fun {ShowVirtualString V W D}
               {Convert 1 V 1 {Width V} W false}
            end
         end
         %% Pruning Functions
         local
            Rev = Reverse
            fun {SplitArity As I AO AE}
               case As
               of F|Ar then
                  case I mod 2
                  of 0 then {SplitArity Ar (I + 1) AO F|AE}
                  else {SplitArity Ar (I + 1) F|AO AE}
                  end
               else {Rev AO}|{Rev AE}
               end
            end
            fun {SplitList As I AO AE}
               if {IsFree As}
               then case I mod 2 of 0 then {Rev AO}|{Rev As|AE} else {Rev As|AO}|{Rev AE} end
               elsecase As
               of F|Ar then
                  case I mod 2
                  of 0 then {SplitList Ar (I + 1) AO F|AE}
                  else {SplitList Ar (I + 1) F|AO AE}
                  end
               [] nil then {Rev AO}|{Rev AE}
               elsecase I mod 2 of 0 then {Rev AO}|{Rev As|AE} else {Rev As|AO}|{Rev AE} end
            end
            fun {GetEven A}
               case {SplitArity A 1 nil nil} of _|AE then AE end
            end
            fun {GetOdd A}
               case {SplitArity A 1 nil nil} of AO|_ then AO end
            end
            fun {CopyTupVal As I NV V}
               case As of F|Ar then NV.I = V.F {CopyTupVal Ar (I + 1) NV V} else NV end
            end
         in
            fun {TupPruneOdd V W D}
               Arity = {GetEven {Record.arity V}}
               NewV  = {Tuple.make {Label V} {Length Arity}}
            in
               {CopyTupVal Arity 1 NewV V}
            end
            fun {TupPruneEven V W D}
               Arity = {GetOdd {Record.arity V}}
               NewV  = {Tuple.make {Label V} {Length Arity}}
            in
               {CopyTupVal Arity 1 NewV V}
            end
            fun {TupSplitOddEven V W D}
               case {SplitArity {Record.arity V} 1 nil nil}
               of AO|AE then
                  MyLabel = {Record.label V}
               in
                  MyLabel({CopyTupVal AO 1 {Tuple.make od {Length AO}} V}
                          {CopyTupVal AE 1 {Tuple.make ev {Length AE}} V})
               end
            end
            fun {PipPruneOdd V W D}
               case {SplitList V 1 nil nil} of _|AE then ev(AE) end
            end
            fun {PipPruneEven V W D}
               case {SplitList V 1 nil nil} of AO|_ then od(AO) end
            end
            fun {PipSplitOddEven V W D}
               case {SplitList V 1 nil nil} of AO|AE then [od(AO) ev(AE)] end
            end
            fun {RecPruneOdd V W D}
               Arity = {GetEven {Record.arity V}}
               NewV  = {Record.make {Label V} Arity}
            in
               {CopyRecVal Arity NewV V}
            end
            fun {RecPruneEven V W D}
               Arity = {GetOdd {Record.arity V}}
               NewV  = {Record.make {Label V} Arity}
            in
               {CopyRecVal Arity NewV V}
            end
            fun {RecSplitOddEven V W D}
               case {SplitArity {Record.arity V} 1 nil nil}
               of AO|AE then
                  MyLabel = {Record.label V}
               in
                  MyLabel({CopyRecVal AO {Record.make od AO} V}
                          {CopyRecVal AE {Record.make ev AE} V})
               end
            end
         end
      in
         ContainerMenus = [
                           hashtupleMenu   # menu(WidthList
                                                  DepthList
                                                  ['Show VirtualString'(ShowVirtualString)
                                                   'Prune Odd'(TupPruneOdd)
                                                   'Prune Even'(TupPruneEven)
                                                   'Split Odd/Even'(TupSplitOddEven)]
                                                  nil)
                           pipetupleMenu   # menu(WidthList
                                                  DepthList
                                                  ['Prune Odd'(PipPruneOdd)
                                                   'Prune Even'(PipPruneEven)
                                                   'Split Odd/Even'(PipSplitOddEven)]
                                                  nil)
                           listMenu        # menu(WidthList
                                                  DepthList
                                                  ['Prune Odd'(PipPruneOdd)
                                                   'Prune Even'(PipPruneEven)
                                                   'Split Odd/Even'(PipSplitOddEven)]
                                                  nil)
                           labeltupleMenu  # menu(WidthList
                                                  DepthList
                                                  ['Prune Odd'(TupPruneOdd)
                                                   'Prune Even'(TupPruneEven)
                                                   'Split Odd/Even'(TupSplitOddEven)]
                                                  ['Reinspect'(reinspect)])
                           recordMenu      # menu(WidthList
                                                  DepthList
                                                  ['Prune Odd'(RecPruneOdd)
                                                   'Prune Even'(RecPruneEven)
                                                   'Split Odd/Even'(RecSplitOddEven)]
                                                  nil)
                           kindedrecordMenu # menu(WidthList
                                                   DepthList
                                                   nil
                                                   nil)
                          ]
      end

      %% Default Variable-Type Menus
      local
         %% Variable/Future Specific Functions
         Force = Value.makeNeeded
      in
         VariableMenus = [
                          futureMenu # menu(nil nil nil ['Make Needed'(Force)])
                          freeMenu   # menu(nil nil nil ['Make Needed'(Force)])
                          fdintMenu  # menu(WidthList
                                            DepthList
                                            nil
                                            nil)
                          fsetMenu   # menu(WidthList
                                            DepthList
                                            nil
                                            nil)
                         ]
      end

      %% Default Abstract-Type Menus
      local
         %% Array-specific Functions
         local
            ArrayContents = {NewName}
            ArrayStats    = {NewName}
         in
            fun {ShowArrayCont V W D}
               {Array.toRecord ArrayContents V}
            end
            fun {ShowArrayStat V W D}
               L = {Array.low V}
               H = {Array.high V}
            in
               ArrayStats(low: L high: H width: ((H - L) + 1))
            end
         end
         %% Dictionary Secific Functions
         local
            DictKeys    = {NewName}
            DictItems   = {NewName}
            DictEntries = {NewName}
         in
            fun {ShowDictKeys V W D}
               DictKeys({Dictionary.keys V})
            end
            fun {ShowDictItems V W D}
               DictItems({Dictionary.items V})
            end
            fun {ShowDictCont V W D}
               {Dictionary.toRecord DictEntries V}
            end
         end
         %% WeakDictionary Secific Functions
         local
            WeakDictKeys    = {NewName}
            WeakDictItems   = {NewName}
            WeakDictEntries = {NewName}
         in
            fun {ShowWeakDictKeys V W D}
               WeakDictKeys({WeakDictionary.keys V})
            end
            fun {ShowWeakDictItems V W D}
               WeakDictItems({WeakDictionary.items V})
            end
            fun {ShowWeakDictCont V W D}
               {WeakDictionary.toRecord WeakDictEntries V}
            end
         end
         %% Class Specific Functions
         local
            OOMeth  = {BN.newUnique 'ooMeth'}
            OOAttr  = {BN.newUnique 'ooAttr'}
            OOFeat  = {BN.newUnique 'ooFeat'}
            OOPrint = {BN.newUnique 'ooPrintName'}
            %%         OOProp  = {BN.newUnique 'ooProperties'}
            OOList  = [OOAttr OOFeat OOMeth]
         in
            fun {MapClass V W D}
               Arity = {Filter {ChunkArity V} fun {$ A} {Member A OOList} end}
            in
               {CopyRecVal Arity {Record.make V.OOPrint Arity} V}
            end
         end
         %% Object Specific Functions
         local
            class SpyObject
               meth getAttr(A $) @A end
               meth getFeat(A $) self.A end
            end
            OOAttr  = {BN.newUnique 'ooAttr'}
            OOFeat  = {BN.newUnique 'ooFeat'}
            OOPrint = {BN.newUnique 'ooPrintName'}
         in
            proc {MapAttr As V Res}
               case As
               of A|Ar then
                  Res.A = {BO.send getAttr(A $) SpyObject V} {MapAttr Ar V Res}
               else skip
               end
            end
            proc {MapFeat As V Res}
               case As
               of A|Ar then
                  Res.A = {BO.send getFeat(A $) SpyObject V} {MapFeat Ar V Res}
               else skip
               end
            end
            fun {MapObject V W D}
               Class = {BO.getClass V}
               Name  = Class.OOPrint
               Attr  = {Record.arity Class.OOAttr}
               Feat  = {Record.arity Class.OOFeat}
               AttrR = {Record.make attributes Attr}
               FeatR = {Record.make features Feat}
            in
               {MapAttr Attr V AttrR}
               {MapFeat Feat V FeatR}
               {List.toTuple Name [AttrR FeatR]}
            end
         end
         %% Chunk Specific Functions
         local
            Chunk = {NewName}
         in
            fun {MapChunk V W D}
               Arity = {ChunkArity V}
            in
               {CopyRecVal Arity {Record.make Chunk Arity} V}
            end
         end
         %% Cell Specific Functions
         local
            CellContent = {NewName}
         in
            fun {ShowCellCont V W D}
               CellContent({Access V})
            end
         end
         %% Failed Value Specific Functions
         local
            Failed = {NewName}
         in
            fun {MapFailed V W D}
               Failed(try {Wait V} unit catch E then E end)
            end
         end
      in
         AbstractMenus = [
                          arrayMenu     # menu(nil
                                               nil
                                               [auto('Show Contents'(ShowArrayCont))
                                                'Show Sizeinfo'(ShowArrayStat)]
                                               nil)
                          dictionaryMenu # menu(nil
                                                nil
                                                ['Show Keys'(ShowDictKeys)
                                                 'Show Items'(ShowDictItems)
                                                 auto('Show Entries'(ShowDictCont))]
                                                nil)
                          weakDictionaryMenu # menu(nil
                                                    nil
                                                    ['Show Keys'(ShowWeakDictKeys)
                                                     'Show Items'(ShowWeakDictItems)
                                                     auto('Show Entries'(ShowWeakDictCont))]
                                                    nil)
                          classMenu      # menu(nil
                                                nil
                                                [auto('Show Entries'(MapClass))]
                                                nil)
                          objectMenu     # menu(nil
                                                nil
                                                [auto('Show Entries'(MapObject))]
                                                nil)
                          chunkMenu      # menu(nil
                                                nil
                                                [auto('Show Entries'(MapChunk))]
                                                nil)
                          cellMenu       # menu(nil
                                                nil
                                                ['Show Contents'(ShowCellCont)]
                                                nil)
                          failedMenu     # menu(nil
                                                nil
                                                ['Show Exception'(MapFailed)]
                                                nil)
                         ]
      end
   in
      MenuDefaults = {FoldL [ArrowMenus SimpleMenus ContainerMenus VariableMenus AbstractMenus]
                      Append nil}
   end

   %% GUI Specific Conversion Table

   ConversionTable =
   [typeConversion # [ procedure    # 'Procedure'
                       future       # 'Future'
                       free         # 'Logic Variable'
                       failed       # 'Failed Value'
                       fdint        # 'Finite Domain Integer'
                       fset         # 'Finite Sets'
                       array        # 'Array'
                       dictionary   # 'Dictionary'
                       'class'      # 'Class'
                       object       # 'Object'
                       'lock'       # 'Lock'
                       int          # 'Integer'
                       float        # 'Floating Point Number'
                       port         # 'Port'
                       atom         # 'Atom'
                       variableref  # 'Co-Reference Usage'
                       hashtuple    # 'Hashtuple'
                       pipetuple    # 'Piped List'
                       cell         # 'Cell'
                       list         # 'Closed List'
                       labeltuple   # 'Tuple'
                       record       # 'Record'
                       kindedrecord # 'Feature Constraint'
                       'unit'       # 'Unit'
                       name         # 'Name'
                       colon        # 'Colon'
                       bytestring   # 'ByteString'
                       internal     # 'Internal'
                       braces       # 'Braces'
                       separator    # 'Pipe Symbol'
                       background   # 'TreeWidget Background'
                       proxy        # 'Mapped Background'
                       selection    # 'Selection Background'
                       ref          # 'Co-Reference Definition'
                       label        # 'Label'
                       feature      # 'Feature'
                       chunk        # 'Chunk'
                       bool         # 'Boolean'
                       generic      # 'Default Type'
                       depthbitmap  # 'Bitmap (Depthlimit)'
                       widthbitmap  # 'Bitmap (Widthlimit)'
                     ]
   ]

   %% Finally glue everthing together
   Options = {FoldL
              {FoldL [InspectorDefaults WidgetDefaults
                      ColorDefaults MenuDefaults ConversionTable]
               Append nil}
              fun {$ D O}
                 case O
                 of Key#Value then
                    {Dictionary.put D Key Value} D
                 else D
                 end
              end {Dictionary.new}}
end
