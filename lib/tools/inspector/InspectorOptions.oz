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
   Tk(localize)
   BS(chunkArity) at 'x-oz://boot/Browser'
   BO(getClass send) at 'x-oz://boot/Object'
   BN(newUnique) at 'x-oz://boot/Name'
export
   options : Options
define
   ChunkArity = BS.chunkArity

   local
      fun {FillDict Os D}
         case Os
         of (Key#Value)|Or then {Dictionary.put D Key Value} {FillDict Or D}
         else D
         end
      end

      local
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
         fun {Root X}
            {Property.get 'oz.home'}#'/share/images/inspector/'#X
         end
         Color1    = '#a020f0'
         Color2    = '#bc8f8f'
         Color3    = '#000000'
         Color4    = '#0000ff'
         Color5    = '#228b22'
         Color6    = '#ff0000'
         Color7    = '#b22222'
         Color8    = '#b886b0'
         Color9    = '#ffffff'
         BackC     = '#f5f5f5'
         WidthList = [1 5 10 0 ~1 ~5 ~10]
         DepthList = [1 5 10 0 ~1 ~5 ~10]
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
            fun {CopyRecVal As NV V}
               case As of F|Ar then NV.F = V.F {CopyRecVal Ar NV V} else NV end
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
            proc {Force V}
               try _ = V.foo catch _ then skip end
            end
            local
               ArrayContents = {NewName}
            in
               fun {ShowArrayCont V W D}
                  {Array.toRecord ArrayContents V}
               end
            end
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
            local
               Chunk = {NewName}
            in
               fun {MapChunk V W D}
                  Arity = {ChunkArity V}
               in
                  {CopyRecVal Arity {Record.make Chunk Arity} V}
               end
            end
            local
               OOMeth  = {BN.newUnique 'ooMeth'}
               OOAttr  = {BN.newUnique 'ooAttr'}
               OOFeat  = {BN.newUnique 'ooFeat'}
               OOPrint = {BN.newUnique 'ooPrintName'}
               %%              OOProp  = {BN.newUnique 'ooProperties'}
               OOList  = [OOAttr OOFeat OOMeth]
            in
               fun {MapClass V W D}
                  Arity = {Filter {ChunkArity V} fun {$ A} {Member A OOList} end}
               in
                  {CopyRecVal Arity {Record.make V.OOPrint Arity} V}
               end
            end
            local
               class SpyObject meth getAttr(A $) @A end meth getFeat(A $) self.A end end
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
                  Res   = {Record.make Name {Append Attr Feat}}
               in
                  {MapAttr Attr V Res} {MapFeat Feat V Res} Res
               end
            end
            local
               CellContent = {NewName}
            in
               fun {ShowCellCont V W D}
                  CellContent({Access V})
               end
            end
            local
               fun {IsString V W}
                  if W > 0
                  then
                     case V
                     of C|Vr then {Char.is C} andthen {IsString Vr (W - 1)}
                     [] nil  then true
                     end
                  else false
                  end
               end
               fun {InsertNew I Ls V}
                  case Ls
                  of L|Lr then V.I = L {InsertNew (I + 1) Lr V}
                  [] nil  then V
                  end
               end
               fun {Convert NIs Ls V I TW W F}
                  if I =< TW
                  then
                     Val = V.I
                  in
                     if I =< W andthen
                        ({IsAtom Val} orelse {IsInt Val} orelse {IsFloat Val}
                         orelse {IsString Val W})
                     then {Convert NIs {Append Ls {VirtualString.toString Val}} V (I + 1) TW W true}
                     elsecase Ls
                     of nil then {Convert V|NIs nil V (I + 1) TW W F}
                     [] Ls  then {Convert V|Ls|NIs nil V (I + 1) TW W F}
                     end
                  else
                     NewNIs = case Ls of nil then NIs [] Ls then Ls|NIs end
                  in
                     if F
                     then {InsertNew 1 {Reverse NewNIs} {MakeTuple '#' {Length NewNIs}}}
                     else V
                     end
                  end
               end
            in
               fun {ShowString V W D}
                  if {IsString V W} then {ByteString.make "\""#V#"\""} else V end
               end
               fun {ShowVirtualString V W D}
                  {Convert nil nil V 1 {Width V} W false}
               end
            end
         end
      in
         DefaultValues =
         [inspectorWidth        # 600
          inspectorHeight       # 400
          optionsRange          # 'active' %% 'active' or 'all'

          widgetTreeWidth       # 50
          widgetTreeDepth       # 15
          widgetTreeDisplayMode # true
          widgetRelationList    # ['Structural Equality'(StructEqual)
                                   auto('Token Equality'(System.eq))]
          widgetWidthLimitBitmap # {Root 'width.xbm'}
          widgetDepthLimitBitmap # {Root 'depth.xbm'}
          widgetStopBitmap       # {Root 'stop.xbm'}
          widgetSepBitmap        # {Root 'sep.xbm'}
          widgetTreeFont         # font(family:'courier' size:14 weight:normal)
          widgetContextMenuFont  # '-adobe-helvetica-bold-r-*-*-*-100-*'
          widgetContextMenuABg   # '#d9d9d9'

          backgroundColor        # Color9
          intColor               # Color1
          floatColor             # Color1
          atomColor              # Color2
          atomrefColor           # Color3
          refColor               # Color6
          labelColor             # Color4
          featureColor           # Color5
          colonColor             # Color3
          boolColor              # Color1
          unitColor              # Color1
          nameColor              # Color3
          procedureColor         # Color3
          futureColor            # Color8
          bytestringColor        # Color4
          freeColor              # Color8
          fdintColor             # Color7
          genericColor           # Color3
          internalColor          # Color3
          bracesColor            # Color3
          widthbitmapColor       # Color6
          depthbitmapColor       # Color6
          separatorColor         # Color1
          proxyColor             # BackC
          selectionColor         # '#f7dfb6'

          %%  menu(WidthList DepthList FilterList ActionList)

          widthbitmapMenu        # [title('Explore Width')
                                    'Width +1'(changeWidth(1))
                                    'Width +5'(changeWidth(5))
                                    'Width +10'(changeWidth(10))
                                    separator
                                    'Width -1'(changeWidth(~1))
                                    'Width -5'(changeWidth(~5))
                                    'Width -10'(changeWidth(~10))]
          depthbitmapMenu        # [title('Explore Depth')
                                    'Depth +1'(changeDepth(1))
                                    'Depth +5'(changeDepth(5))
                                    'Depth +10'(changeDepth(10))
                                    separator
                                    'Depth -1'(changeDepth(~1))
                                    'Depth -5'(changeDepth(~5))
                                    'Depth -10'(changeDepth(~10))]

          intMenu                # nil
          floatMenu              # nil
          bytestringMenu         # menu(nil nil nil nil)
          atomMenu               # nil
          atomrefMenu            # nil
          hashtupleMenu          # menu(WidthList DepthList
                                        [auto('Show VirtualString'(ShowVirtualString))
                                         'Prune Odd'(TupPruneOdd)
                                         'Prune Even'(TupPruneEven)
                                         'Split Odd/Even'(TupSplitOddEven)]
                                        nil)
          pipetupleMenu          # menu(WidthList DepthList
                                        [auto('Show String'(ShowString))
                                         'Prune Odd'(PipPruneOdd)
                                         'Prune Even'(PipPruneEven)
                                         'Split Odd/Even'(PipSplitOddEven)]
                                        nil)
          listMenu               # menu(WidthList DepthList
                                        ['Prune Odd'(PipPruneOdd)
                                         'Prune Even'(PipPruneEven)
                                         'Split Odd/Even'(PipSplitOddEven)]
                                        nil)
          labeltupleMenu         # menu(WidthList DepthList
                                        ['Prune Odd'(TupPruneOdd)
                                         'Prune Even'(TupPruneEven)
                                         'Split Odd/Even'(TupSplitOddEven)]
                                        ['Reinspect'(reinspect)])
          recordMenu             # menu(WidthList DepthList
                                        ['Prune Odd'(RecPruneOdd)
                                         'Prune Even'(RecPruneEven)
                                         'Split Odd/Even'(RecSplitOddEven)]
                                        nil)
          kindedrecordMenu       # menu(WidthList DepthList nil nil)
          boolMenu               # nil
          unitMenu               # nil
          nameMenu               # nil
          procedureMenu          # nil
          futureMenu             # menu(nil nil nil ['Force Evaluation'(Force)])
          freeMenu               # nil
          fdintMenu              # menu(WidthList DepthList nil nil)
          fsetMenu               # menu(WidthList DepthList nil nil)
          genericMenu            # nil

          arrayMenu              # menu(nil nil [auto('Show Contents'(ShowArrayCont))] nil)
          dictionaryMenu         # menu(nil nil ['Show Keys'(ShowDictKeys)
                                                 'Show Items'(ShowDictItems)
                                                 auto('Show Entries'(ShowDictCont))] nil)
          classMenu              # menu(nil nil [auto('Show Entries'(MapClass))] nil)
          objectMenu             # menu(nil nil [auto('Show Entries'(MapObject))] nil)
          lockMenu               # nil
          portMenu               # nil
          chunkMenu              # menu(nil nil [auto('Show Entries'(MapChunk))] nil)
          cellMenu               # menu(nil nil [auto('Show Entries'(ShowCellCont))] nil)

          %% This is to enable Human readable Selections in OptionsGUI
          typeConversion         # [ procedure    # 'Procedure'
                                     future       # 'Future'
                                     free         # 'Logic Variable'
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
                                     atomref      # 'Atomref' %% Don't now
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
                                     ref          # 'Ref'
                                     label        # 'Label'
                                     feature      # 'Feature'
                                     chunk        # 'Chunk'
                                     bool         # 'Boolean'
                                     generic      # 'Default Type'
                                     depthbitmap  # 'Bitmap (Depthlimit)'
                                     widthbitmap  # 'Bitmap (Widthlimit)'
                                   ]
         ]
      end
   in
      fun {Options}
         {FillDict DefaultValues {Dictionary.new}}
      end
   end
end
