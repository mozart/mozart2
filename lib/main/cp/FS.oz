%%%
%%% Authors:
%%%   Tobias Mueller (tmueller@ps.uni-sb.de)
%%%   Martin Mueller (mmueller@ps.uni-sb.de)
%%%
%%% Contributors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Tobias Mueller, 1998
%%%   Martin Mueller, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

require
   CpSupport(vectorToList:
                VectorToList
             expand:
                ExpandList)

prepare

   fun {Head H|_} H end

   fun {Tail _|T} T end

   Last = List.last

import
   FSB at 'x-oz://boot/FSB'
   FSP at 'x-oz://boot/FSP'

   FD(decl list sum)

   ErrorRegistry(put)

export
   include:      FSIsIncl
   exclude:      FSIsExcl
   intersect:    FSIntersect
   intersectN:   FSIntersectN
   union:        FSUnion
   unionN:       FSUnionN
   subset:       FSSubset

   disjoint:     FSDisjoint
   disjointN:    FSDisjointN
   distinct:     FSDistinct
   distinctN:    FSDistinctN
   partition:    FSPartition
   makeWeights:  FSMakeWeights

   card:         FSCard
   cardRange:    FSCardRange


   sup:          FSSup
   inf:          FSInf

   diff:         FSDiff
   compl:        FSCompl
   complIn:      FSComplIn

   isIn:         FSIsIn
   forAllIn:     FSForAllIn

   var:          FSVar
   value:        FSValue

   reified:      FSReified

   monitorIn:    FSMonitorIn
   monitorOut:   FSMonitorOut

   reflect:      FSReflect

   int:          FSInt

   distribute:   FSDistribute


define
   FSIsIncl        = FSP.include
   FSIsExcl        = FSP.exclude
   FSMatch         = FSP.match
   FSMinN          = FSP.minN
   FSMaxN          = FSP.maxN
   FSSeq           = FSP.seq
   FSIsIn          = FSP.isIn

   FSIsInReif      = FSP.isInR
   FSEqualReif     = FSP.equalR

   FSSetValue      = FSB.setValue
   FSSet           = FSB.set
   FSDisjoint      = FSP.disjoint
   FSDistinct      = FSP.distinct
   FSDistinctWith  = fun {$ S1} proc {$ S2} {FSDistinct S1 S2} end end
   FSUnion         = FSP.union
   FSIntersect     = FSP.intersection
   FSSubset        = FSP.subsume
   FSDiff          = FSP.diff
   FSMin           = FSP.min
   FSMax           = FSP.max
   FSConvex        = FSP.convex

   FSisVar         = FSB.isVarB
   FSisValue       = FSB.isValueB
   FSvalueToString = FSB.valueToString

   %%
   %% Distribution
   %%

   local
      fun {GetFeaturePath Rec Spec Path}
         case Path of FD|T then
            F#D = FD
            PP  = if {HasFeature Spec F} then Rec.(Spec.F)
                  else Rec.D
                  end
         in
            if T==nil then PP else {GetFeaturePath PP Spec T} end
         else found_nil_in_path
         end
      end

      fun {Find L C}
         {FoldL {Tail L}
          fun {$ I E} if {C I E} then I else E end end
          {Head L}}
      end

      fun {MinElement CL}
         Y = {Head CL} in case Y of L#_ then L else Y end
      end

      fun {MaxElement CL}
         Y = {Last CL} in case Y of _#R then R else Y end
      end

      MINELEM = {NewName}
      MAXELEM = {NewName}

      fun {LESS X Y}
         case X#Y
         of     !MINELEM#!MINELEM then false
         elseof !MINELEM#_       then true
         elseof       _#!MINELEM then false
         elseof !MAXELEM#!MAXELEM then false
         elseof !MAXELEM#_       then false
         elseof       _#!MAXELEM then true
         else X < Y
         end
      end

      fun {GREATER X Y}
         case X#Y
         of     !MINELEM#!MINELEM then false
         elseof !MINELEM#_       then false
         elseof       _#!MINELEM then true
         elseof !MAXELEM#!MAXELEM then false
         elseof !MAXELEM#_       then true
         elseof       _#!MAXELEM then false
         else X > Y
         end
      end

      fun {WeightMin DF}
         fun {$ CL WT}
            if CL == nil then DF
            else {Find {ExpandList CL} fun {$ X Y} {WT X} < {WT Y} end}
            end
         end
      end

      fun {WeightMax DF}
         fun {$ CL WT}
            if CL == nil then DF
            else {Find {ExpandList CL} fun {$ X Y} {WT X} > {WT Y} end}
            end
         end
      end

      fun {WeightSum CL WT}
         {FD.sum {Map {ExpandList CL} fun {$ X} {WT X} end} '=:'} = {FD.decl}
      end

      fun {OrderFun Spec Select WT}
         CardTable =
         c(unknown:
              fun {$ S} {FSGetNumOfUnknown {Select S}} end
           lowerBound:
              fun {$ S} {FSGetNumOfGlb {Select S}} end
           upperBound:
              fun {$ S} {FSGetNumOfLub {Select S}} end)

         fun {MakeCompTableWeight F}
            c(unknown:
                 fun {$ S} {F {FSGetUnknown {Select S}} WT} end
              lowerBound:
                 fun {$ S} {F {FSGetGlb     {Select S}} WT} end
              upperBound:
                 fun {$ S} {F {FSGetLub     {Select S}} WT} end)
         end

         OrderFunTable =
         s(min: c(card:
                     CardTable
                  weightMin:
                     {MakeCompTableWeight {WeightMin MAXELEM}}
                  weightMax:
                     {MakeCompTableWeight {WeightMax MAXELEM}}
                  weightSum:
                     {MakeCompTableWeight WeightSum})
           max: c(card:
                     CardTable
                  weightMin:
                     {MakeCompTableWeight {WeightMin MINELEM}}
                  weightMax:
                     {MakeCompTableWeight {WeightMax MINELEM}}
                  weightSum:
                     {MakeCompTableWeight WeightSum})
          )

         OrderFunTableRel = s(min: LESS max: GREATER)

      in
         if {IsProcedure Spec} then Spec
         else
            if Spec == naive then fun {$ L} L end
            else
               OrderFunRel = {GetFeaturePath OrderFunTableRel Spec [sel#min]}

               OrderFun = {GetFeaturePath OrderFunTable Spec
                           [sel#min cost#card comp#unknown]}
            in
               fun {$ L}
                  {Sort L fun {$ X Y}
                             {OrderFunRel {OrderFun X} {OrderFun Y}}
                          end}
               end
            end
         end
      end

      fun {ElementFun Spec Select WT}
         ElementFunTable =
         v(min: v(unknown:
                     fun {$ S}
                        {MinElement {FSReflect.unknown {Select S}}}
                     end
                  weight:
                     fun {$ S}
                        {{WeightMin error}
                         {FSReflect.unknown {Select S}} WT}
                     end)
           max: v(unknown:
                     fun {$ S}
                        {MaxElement {FSReflect.unknown {Select S}}}
                     end
                  weight:
                     fun {$ S}
                        {{WeightMax error}
                         {FSReflect.unknown {Select S}} WT}
                     end)
          )
      in
         if {IsProcedure Spec} then Spec
         else {GetFeaturePath ElementFunTable Spec [sel#min wrt#unknown]}
         end
      end

      fun {FilterFun Spec Select}
         case Spec
         of true then
            fun {$ X} {FSGetNumOfUnknown {Select X}} > 0 end
         else
            fun {$ X} Y = {Select X} in
               {FSGetNumOfUnknown Y} > 0 andthen  {Spec Y}
            end
         end
      end

      fun {SelectFun Spec}
         case Spec
         of id then fun {$ X} X end
         else Spec
         end
      end

      fun {RRobinFun Spec}
         if Spec then fun {$ H|T} {Append T [H]} end
         else fun {$ L} L end
         end
      end

      proc {FSDistNaive SL}
         if SL == nil then skip
         else
            choice
               case {FSReflect.unknown {Head SL}}
               of nil then {FSDistNaive {Tail SL}}
               elseof Unknown then
                  UnknownVal = {MinElement Unknown}
               in
                  choice
                     {FSIsIncl UnknownVal {Head SL}}

                     {FSDistNaive SL}
                  []
                     {FSIsExcl UnknownVal {Head SL}}

                     {FSDistNaive SL}
                  end
               end
            end
         end
      end

      proc {FSDistGeneric Vs Order FCond Elem RRobin Sel Proc}
         SL = {VectorToList Vs}
      in
         choice
            {Proc}

            choice
               SortedSL = {Order {Filter SL FCond}}
            in
               if SortedSL \= nil then
                  UnknownVal = {Elem {Head SortedSL}}
                  DistVar    = {Sel {Head SortedSL}}
               in
                  choice
                     {FSIsIncl UnknownVal DistVar}

                     {FSDistGeneric {RRobin SortedSL}
                      Order FCond Elem RRobin Sel Proc}
                  []
                     {FSIsExcl UnknownVal DistVar}

                     {FSDistGeneric {RRobin SortedSL}
                      Order FCond Elem RRobin Sel Proc}
                  end
               end
            end
         end
      end
   in
      proc {FSDistribute K Vs}
         L = {VectorToList Vs}
      in
         case K
         of naive then {FSDistNaive L}
         else
            case {Label K}
            of generic then
               Select  = {SelectFun {CondSelect K select id}}
               Weights = {CondSelect K weights {FSMakeWeights nil}}
               Order   = {OrderFun {CondSelect K order order} Select Weights}
               Filter  = {FilterFun {CondSelect K filter true} Select}
               Element = {ElementFun {CondSelect K element element}
                          Select Weights}
               RRobin  = {RRobinFun {CondSelect K rrobin false}}
               Proc    = {CondSelect K procedure proc {$} skip end}
            in
               {FSDistGeneric L Order Filter Element RRobin Select Proc}
            else
               {Exception.raiseError
                fs(unknownDistributionStrategy
                   'FS.distribute' [K Vs] 1)}
            end
         end
      end
   end

   %%
   %% Shorthands
   %%

   FSCard = FSP.card
   FSCardRange     = FSB.cardRange

   FSGetUnknown    = FSB.getUnknown
   FSGetGlb        = FSB.getGlb
   FSGetLub        = FSB.getLub

   FSGetCard       = FSB.getCard

   FSGetNumOfGlb     = FSB.getNumOfKnownIn
   FSGetNumOfLub     = fun {$ S}
                          FSSup - FSInf + 1 - {FSB.getNumOfKnownNotIn S}
                       end
   FSGetNumOfUnknown = FSB.getNumOfUnknown

   FSSup           = {FSB.sup}
   FSInf           = 0
   FSUniversalRefl = [0#FSSup]
   FSUniversal     = {FSSetValue FSUniversalRefl}

   fun {FSIntersectN Vs}
      Xs = {VectorToList Vs}
   in
      {FoldR Xs FSIntersect FSUniversal}
   end

   proc {FSUnionN Vs U}
      {FSP.unionN Vs U}
      {FD.sum {Map {VectorToList Vs} fun {$ V} {FSCard V} end}
       '>=:' {FSCard U}}
   end

   FSDisjointN = FSP.disjointN

   proc {FSDistinctN Vs}
      Xs = {VectorToList Vs}
   in
      {ForAllTail Xs
       proc {$ Ts}
          case Ts
          of nil then skip
          [] T|Tr then {ForAll Tr {FSDistinctWith T}}
          end
       end}
   end

   proc {FSPartition Vs U}
      {FSP.partition Vs U}
      {FD.sum {Map {VectorToList Vs} fun {$ V} {FSCard V} end} '=:' {FSCard U}}
   end

   fun {FSMakeWeights WL}
      WeightTable = {NewDictionary}
      ScanWeightDescr =
      proc {$ D}
         case D
         of (default#W)|T then
            {Dictionary.put WeightTable default W}
            {ScanWeightDescr T}
         elseof ((E1#E2)#W)|T then
            {Dictionary.put WeightTable E1 W}
            {ScanWeightDescr
             if E1 < E2 then (((E1+1)#E2)#W)|T
             else T end}
         elseof (E#W)|T then
            {Dictionary.put WeightTable E W}
            {ScanWeightDescr T}
         elseof nil then skip
         end
      end
      Default
   in
      {Dictionary.put WeightTable default 0}
      {ScanWeightDescr WL}
      Default = {Dictionary.get WeightTable default}

      fun {$ E} {Dictionary.condGet WeightTable E Default} end
   end

   fun {FSCompl S}
      {FSDiff FSUniversal S}
   end

   proc {FSComplIn S1 A S2}
      {FSDisjoint S1 S2}
      {FSUnion S1 S2 A}
   end

   proc {FSForAllIn S P}
      {ForAll {FSMonitorIn S} P}
   end

   FSVar = var(is:
                  FSisVar
               decl:
                  fun {$} {FSSet nil FSUniversalRefl} end
               upperBound:
                  fun {$ B} {FSSet nil B} end
               lowerBound:
                  fun {$ A} {FSSet A FSUniversalRefl} end
               bounds:
                  FSSet

               list:  list(decl:
                              proc {$ Len Ss}
                                 Ss = {MakeList Len}
                                 {ForAll Ss FSVar.decl}
                              end
                           upperBound:
                              proc {$ Len A Ss}
                                 Ss = {MakeList Len}
                                 {ForAll Ss
                                  proc {$ X}
                                     {FSVar.upperBound A X}
                                  end}
                              end
                           lowerBound:
                              proc {$ Len A Ss}
                                 Ss = {MakeList Len}
                                 {ForAll Ss
                                  proc {$ X}
                                     {FSVar.lowerBound A X}
                                  end}
                              end
                           bounds:
                              proc {$ Len GLB LUB Ss}
                                 Ss = {MakeList Len}
                                 {ForAll Ss
                                  proc {$ X}
                                     {FSVar.bounds GLB LUB X}
                                  end}
                              end)

               tuple: tuple(decl:
                               proc {$ L Size Ss}
                                  Ss = {MakeTuple L Size}
                                  {Record.forAll Ss FSVar.decl}
                               end
                            upperBound:
                               proc {$ L Size A Ss}
                                  Ss = {MakeTuple L Size}
                                  {Record.forAll Ss
                                   proc {$ X}
                                      {FSVar.upperBound A X}
                                   end}
                               end
                            lowerBound:
                               proc {$ L Size A Ss}
                                  Ss = {MakeTuple L Size}
                                  {Record.forAll Ss
                                   proc {$ X}
                                      {FSVar.lowerBound A X}
                                   end}
                               end
                            bounds:
                               proc {$ L Size GLB LUB Ss}
                                  Ss = {MakeTuple L Size}
                                  {Record.forAll Ss
                                   proc {$ X}
                                      {FSVar.bounds GLB LUB X}
                                   end}
                               end)

               record: record(decl:
                                 proc {$ L Ls Ss}
                                    Ss = {MakeRecord L Ls}
                                    {Record.forAll Ss FSVar.decl}
                                 end
                              upperBound:
                                 proc {$ L Ls A Ss}
                                    Ss = {MakeRecord L Ls}
                                    {Record.forAll Ss
                                     proc {$ X}
                                        {FSVar.upperBound A X}
                                     end}
                                 end
                              lowerBound:
                                 proc {$ L Ls A Ss}
                                    Ss = {MakeRecord L Ls}
                                    {Record.forAll Ss
                                     proc {$ X}
                                        {FSVar.lowerBound A X}
                                     end}
                                 end
                              bounds:
                                 proc {$ L Ls GLB LUB Ss}
                                    Ss = {MakeRecord L Ls}
                                    {Record.forAll Ss
                                     proc {$ X}
                                        {FSVar.bounds GLB LUB X}
                                     end}
                                 end)
              )

   FSValue = value(empty:
                      {FSSetValue nil}
                   universal:
                      {FSSetValue FSUniversalRefl}
                   singl:
                      fun {$ N} {FSSetValue [N]} end
                   make:
                      FSSetValue
                   is:
                      FSisValue
                   toString:
                      FSvalueToString)

   FSReified = reified(isIn:
                          FSIsInReif
                       areIn:
                          proc {$ WList S BList}
                             BList
                             = {FD.list {Length WList} 0#1}
                             = {Map WList fun {$ E} {FSIsInReif E S} end}
                          end
                       include:
                          FSP.includeR
                       bounds:
                          FSP.bounds
                       boundsN:
                          FSP.boundsN
                       partition:
                          FSP.partitionReified
                       equal:
                          FSEqualReif)


   FSMonitorIn = FSP.monitorIn

   FSMonitorOut = FSP.monitorOut


   FSReflect = reflect(unknown:
                          FSGetUnknown
                       unknownList:
                          fun {$ S}
                             {ExpandList {FSGetUnknown S}}
                          end
                       lowerBound:
                          FSGetGlb
                       lowerBoundList:
                          fun {$ S}
                             {ExpandList {FSGetGlb S}}
                          end
                       upperBound:
                          FSGetLub
                       upperBoundList:
                          fun {$ S}
                             {ExpandList {FSGetLub S}}
                          end
                       card:
                          FSGetCard
                       cardOf:
                          card(lowerBound:
                                  FSGetNumOfGlb
                               upperBound:
                                  FSGetNumOfLub
                               unknown:
                                  FSGetNumOfUnknown))

   FSInt = int(match:
                  FSMatch
               minN:
                  FSMinN
               maxN:
                  FSMaxN
               seq:
                  FSSeq
               min:
                  FSMin
               max:
                  FSMax
               convex:
                  FSConvex)

   %%
   %% Register error formatter
   %%

   {ErrorRegistry.put fs
    fun {$ E}
       T = 'error in finite set system'
    in
       case E
       of fs(unknownDistributionStrategy A Xs P) then
          error(kind: T
                msg: 'Unknown distribution strategy encountered.'
                items: [hint(l:'At argument' m:P)
                        hint(l:'In statement' m:apply(A Xs))])
       else
          error(kind: T
                items: [line(oz(E))])
       end
    end}


end
