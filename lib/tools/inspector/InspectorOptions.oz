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
   System(eq)
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
         fun {StructEqual X Y}
            ({IsDet X} andthen {IsDet Y} andthen X == Y)
            orelse {System.eq X Y}
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
            fun {TupPruneOdd V}
               Arity = {GetEven {Record.arity V}}
               NewV  = {Tuple.make {Label V} {Length Arity}}
            in
               {CopyTupVal Arity 1 NewV V}
            end
            fun {TupPruneEven V}
               Arity = {GetOdd {Record.arity V}}
               NewV  = {Tuple.make {Label V} {Length Arity}}
            in
               {CopyTupVal Arity 1 NewV V}
            end
            fun {TupSplitOddEven V}
               case {SplitArity {Record.arity V} 1 nil nil}
               of AO|AE then
                  MyLabel = {Record.label V}
               in
                  MyLabel({CopyTupVal AO 1 {Tuple.make od {Length AO}} V}
                          {CopyTupVal AE 1 {Tuple.make ev {Length AE}} V})
               end
            end
            fun {PipPruneOdd V}
               case {SplitList V 1 nil nil} of _|AE then ev(AE) end
            end
            fun {PipPruneEven V}
               case {SplitList V 1 nil nil} of AO|_ then od(AO) end
            end
            fun {PipSplitOddEven V}
               case {SplitList V 1 nil nil} of AO|AE then [od(AO) ev(AE)] end
            end
            fun {RecPruneOdd V}
               Arity = {GetEven {Record.arity V}}
               NewV  = {Record.make {Label V} Arity}
            in
               {CopyRecVal Arity NewV V}
            end
            fun {RecPruneEven V}
               Arity = {GetOdd {Record.arity V}}
               NewV  = {Record.make {Label V} Arity}
            in
               {CopyRecVal Arity NewV V}
            end
            fun {RecSplitOddEven V}
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
               Dict = {NewName}
            in
               fun {MapDict V}
                  {Dictionary.toRecord Dict V}
               end
            end
            local
               Arr = {NewName}
            in
               fun {MapArray V}
                  {Array.toRecord Arr V}
               end
            end
            local
               Chunk = {NewName}
            in
               fun {MapChunk V}
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
%%             OOProp  = {BN.newUnique 'ooProperties'}
               OOList  = [OOAttr OOFeat OOMeth]
            in
               fun {MapClass V}
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
               fun {MapObject V}
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
               Cell = {NewName}
            in
               fun {MapCell V}
                  Cell({Access V})
               end
               fun {CleanCell V}
                  {Exchange V _ _} V
               end
            end
            fun {StringShow V}
               if {String.is V} then {ByteString.make V} else V end
            end
         end
      in
         DefaultValues =
         [inspectorWidth        # 600
          inspectorHeight       # 400
          optionsRange          # 'all'

          widgetTreeWidth       # 100 %  Browser has (50)
          widgetTreeDepth       # 15  % Browser has (15)
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
          atomMenu               # nil
          atomrefMenu            # nil
          hashtupleMenu          # menu(WidthList DepthList
                                        ['Prune Odd'(TupPruneOdd)
                                         'Prune Even'(TupPruneEven)
                                         'Split Odd/Even'(TupSplitOddEven)]
                                        nil)
          pipetupleMenu          # menu(WidthList DepthList
                                        ['Prune Odd'(PipPruneOdd)
                                         'Prune Even'(PipPruneEven)
                                         'Split Odd/Even'(PipSplitOddEven)]
                                        nil)
          listMenu               # menu(WidthList DepthList
                                        ['Prune Odd'(PipPruneOdd)
                                         'Prune Even'(PipPruneEven)
                                         'Split Odd/Even'(PipSplitOddEven)
                                         'ShowAsString'(StringShow)]
                                        nil)
          labeltupleMenu         # menu(WidthList DepthList
                                        ['Prune Odd'(TupPruneOdd)
                                         'Prune Even'(TupPruneEven)
                                         'Split Odd/Even'(TupSplitOddEven)]
                                        nil)
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

          arrayMenu              # menu(nil nil [auto('Show Contents'(MapArray))] nil)
          dictionaryMenu         # menu(nil nil [auto('Show Contents'(MapDict))] nil)
          classMenu              # menu(nil nil [auto('Show Contents'(MapClass))] nil)
          objectMenu             # menu(nil nil [auto('Show Contents'(MapObject))] nil)
          lockMenu               # nil
          portMenu               # nil
          chunkMenu              # menu(nil nil [auto('Show Contents'(MapChunk))] nil)
          cellMenu               # menu(nil nil [auto('Show Contents'(MapCell))
                                                 'Garbage Contents'(CleanCell)] nil)
         ]
      end
   in
      fun {Options}
         {FillDict DefaultValues {Dictionary.new}}
      end
   end
end
