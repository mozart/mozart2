%%%
%%% Authors:
%%%   Tobias Mueller (tmueller@ps.uni-sb.de)
%%%   Martin Mueller (mmueller@ps.uni-sb.de)
%%%
%%% Contributors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Tobias Mueller, 1997
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
   CpSupport(vectorToList:   VectorToList
             expand:         ExpandList)

   at '../CpSupport.ozf'


prepare

   fun {Head H|_} H end

   fun {Tail _|T} T end

   Last = List.last

import
   FSB at 'x-oz://boot/FSB'
   FSP at 'x-oz://boot/FSP'

   FD(bool
      decl
      list
      reflect
      sum
      watch)

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
   newWeights:   FSNewWeights

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

   distribute:  FSDistribute


define
   FSIsIncl     = FSP.include
   FSIsExcl     = FSP.exclude
   FSMatch      = FSP.match
   FSMinN       = FSP.minN
   FSMaxN       = FSP.maxN
   FSSeq        = FSP.seq
   FSIsIn       = FSP.isIn

   local
      FSIsInR = FSP.isInR
   in
      proc {FSIsInReif E S B}
         {FD.bool B}
         {FSIsInR E S B}
      end
   end

   local
      FSEqualR = FSP.equalR
   in
      proc {FSEqualReif S1 S2 B}
         {FD.bool B}
         {FSEqualR S1 S2 B}
      end
   end

   FSSetValue   = FSB.setValue
   FSSet        = FSB.set
   FSDisjoint   = FSP.disjoint
   FSDistinct   = FSP.distinct
\ifdef CONSTRAINT_N_NAIVE
   fun {FSDisjointWith S1}
      proc {$ S2}{FSDisjoint S1 S2} end
   end
\endif
   fun {FSDistinctWith S1}
      proc {$ S2} {FSDistinct S1 S2} end
   end
   FSUnion      = FSP.union
   FSIntersect  = FSP.intersection
   FSSubset     = FSP.subsume
   FSDiff       = FSP.diff
   FSMin        = FSP.min
   FSMax        = FSP.max
   FSConvex     = FSP.convex

   FSisVar         = FSB.isVarB
   FSisValue       = FSB.isValueB
   FSvalueToString = FSB.valueToString

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% DISTRIBUTION

   local

      GetFeaturePath =
      fun {$ Rec Spec Path}
         case Path
         of [F#D] then
            case {HasFeature Spec F} then Rec.(Spec.F)
            else Rec.D end
         [] F#D|T then
            case {HasFeature Spec F} then {GetFeaturePath Rec.(Spec.F) Spec T}
            else {GetFeaturePath Rec.D Spec T} end
         else found_nil_in_path
         end
      end

      Find =
      fun {$ L C}
         {FoldL {Tail L}
          fun {$ I E} case {C I E} then I else E end end
          {Head L}}
      end

      MinElement =
      fun {$ CL}
         Y = {Head CL} in case Y of L#_ then L else Y end
      end

      MaxElement =
      fun {$ CL}
         Y = {Last CL} in case Y of _#R then R else Y end
      end

      MINELEM = {NewName}
      MAXELEM = {NewName}

      LESS =
      fun {$ X Y}
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

      GREATER =
      fun {$ X Y}
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

      WeightMin =
      fun {$ DF}
         fun {$ CL WT}
            case CL == nil then DF
            else {Find {ExpandList CL} fun {$ X Y} {WT X} < {WT Y} end}
            end
         end
      end

      WeightMax =
      fun {$ DF}
         fun {$ CL WT}
            case CL == nil then DF
            else {Find {ExpandList CL} fun {$ X Y} {WT X} > {WT Y} end}
            end
         end
      end

      WeightSum =
      fun {$ CL WT}
         {FD.sum {Map {ExpandList CL} fun {$ X} {WT X} end} '=:'} = {FD.decl}
      end

      OrderFun =
      fun {$ Spec Select WT}

         CardTable =
         c(unknown:    fun {$ S} {FSGetNumOfUnknown {Select S}} end
           lowerBound: fun {$ S} {FSGetNumOfGlb {Select S}} end
           upperBound: fun {$ S} {FSGetNumOfLub {Select S}} end)

         MakeCompTableWeight =
         fun {$ F}
            c(unknown:    fun {$ S} {F {FSGetUnknown {Select S}} WT} end
              lowerBound: fun {$ S} {F {FSGetGlb     {Select S}} WT} end
              upperBound: fun {$ S} {F {FSGetLub     {Select S}} WT} end)
         end

         OrderFunTable =
         s(min: c(card:      CardTable
                  weightMin: {MakeCompTableWeight {WeightMin MAXELEM}}
                  weightMax: {MakeCompTableWeight {WeightMax MAXELEM}}
                  weightSum: {MakeCompTableWeight WeightSum})
           max: c(card:      CardTable
                  weightMin: {MakeCompTableWeight {WeightMin MINELEM}}
                  weightMax: {MakeCompTableWeight {WeightMax MINELEM}}
                  weightSum: {MakeCompTableWeight WeightSum})
          )

         OrderFunTableRel = s(min: LESS max: GREATER)

      in
         case {IsProcedure Spec} then Spec
         else
            case Spec == naive then fun {$ L} L end
            else
               OrderFunRel =
               {GetFeaturePath OrderFunTableRel Spec [sel#min]}

               OrderFun =
               {GetFeaturePath OrderFunTable Spec [sel#min cost#card comp#unknown]}
            in
               fun {$ L}
                  {Sort L fun {$ X Y} {OrderFunRel {OrderFun X} {OrderFun Y}} end}
               end
            end
         end
      end

      ElementFun =
      fun {$ Spec Select WT}
         ElementFunTable =
         v(min: v(unknown: fun {$ S}
                              {MinElement {FSReflect.unknown {Select S}}}
                           end
                  weight:  fun {$ S}
                              {{WeightMin error}
                               {FSReflect.unknown {Select S}} WT}
                           end
                 )
           max: v(unknown: fun {$ S}
                              {MaxElement {FSReflect.unknown {Select S}}}
                           end
                  weight:  fun {$ S}
                              {{WeightMax error}
                               {FSReflect.unknown {Select S}} WT}
                           end
                 )
          )
      in
         case {IsProcedure Spec} then Spec
         else {GetFeaturePath ElementFunTable Spec [sel#min wrt#unknown]}
         end
      end % fun

      FilterFun =
      fun {$ Spec Select}
         case Spec
         of true then
            fun {$ X} {FSGetNumOfUnknown {Select X}} > 0 end
         else
            fun {$ X} Y = {Select X} in
               {FSGetNumOfUnknown Y} > 0 andthen  {Spec Y}
            end
         end % case
      end

      SelectFun =
      fun {$ Spec}
         case Spec
         of id then fun {$ X} X end
         else Spec
         end
      end

      RRobinFun =
      fun {$ Spec}
         case Spec then fun {$ H|T} {Append T [H]} end
         else fun {$ L} L end
         end
      end

      FSDistNaive =
      proc {$ SL}
         case SL == nil then skip
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
                  end % dis
               end % case
            end % choice
         end % case
      end % proc

      FSDistGeneric =
      proc {$ Vs Order FCond Elem RRobin Sel Proc}
         SL = {VectorToList Vs}
      in
         choice
            {Proc}

            choice
               SortedSL = {Order {Filter SL FCond}}
            in
               case SortedSL == nil then skip
               else
                  UnknownVal = {Elem {Head SortedSL}}
                  DistVar    = {Sel {Head SortedSL}}
               in
                  choice
                     {FSIsIncl UnknownVal DistVar}

                     {FSDistGeneric {RRobin SortedSL} Order FCond Elem RRobin Sel Proc}
                  []
                     {FSIsExcl UnknownVal DistVar}

                     {FSDistGeneric {RRobin SortedSL} Order FCond Elem RRobin Sel Proc}
                  end % dis
               end % case
            end % choice
         end% choice
      end % proc
   in

      FSDistribute =
      proc {$ K Vs} L = {VectorToList Vs}
      in
         case K
         of naive then {FSDistNaive L}
         else
            case {Label K}
            of generic then
               Select  = {SelectFun {CondSelect K select id}}
               Weights = {CondSelect K weights {FSNewWeights nil}}
               Order   = {OrderFun {CondSelect K order order} Select Weights}
               Filter  = {FilterFun {CondSelect K filter true} Select}
               Element = {ElementFun {CondSelect K element element}
                          Select Weights}
               RRobin  = {RRobinFun {CondSelect K rrobin false}}
               Proc    = {CondSelect K procedure proc {$} skip end}
            in
               {FSDistGeneric L Order Filter Element RRobin Select Proc}
            else
               raise 'Error in FSDistribute'#K end
            end % case
         end % case
      end % proc

   end % local

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% WATCHING BOUNDS OF FD DOMAINS


   %% {FDWatchMax I P}
   %% I is a finite domain variable and P is a unary procedure.
   %% P is invoked each time the max of I's domain changes.  It is
   %% invoked with this new max as argument.
   proc {FDWatchMax I P}
      case {IsDet I} then {P I}
      else
         Max={FD.reflect.max I}
      in
         {P Max}
         case {FD.watch.max I Max}
         then {FDWatchMax I P} else skip end
      end
   end

   %% similarly with the min.
   proc {FDWatchMin I P}
      case {IsDet I} then {P I}
      else
         Min={FD.reflect.min I}
      in
         {P Min}
         case {FD.watch.min I Min}
         then {FDWatchMin I P} else skip end
      end
   end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% SHORTHANDS

   local
      FSCardBI = FSP.card
   in
      proc {FSCard S C}
         {FD.decl C}
         {FSCardBI S C}
      end
   end

   FSCardRange     = FSB.cardRange

   FSGetUnknown    = FSB.getUnknown
   FSGetGlb        = FSB.getGlb
   FSGetLub        = FSB.getLub

   FSGetCard       = FSB.getCard

   FSGetNumOfGlb     = FSB.getNumOfKnownIn
   FSGetNumOfLub     = FSB.getNumOfKnownNotIn
   FSGetNumOfUnknown = FSB.getNumOfUnknown

\ifdef CONSTRAINT_N_NAIVE
   FSEmpty         = {FSSetValue nil}
\endif
   FSSup           = {FSB.sup}
   FSInf           = 0
   FSUniversalRefl = [0#FSSup]
   FSUniversal     = {FSSetValue FSUniversalRefl}

   fun {FSIntersectN Vs} Xs = {VectorToList Vs}
   in
      {FoldR Xs FSIntersect FSUniversal}
   end

   proc {FSUnionN Vs U}
      {FSP.unionN Vs U}
      {FD.sum {Map {VectorToList Vs} fun {$ V} {FSCard V} end}
       '>=:' {FSCard U}}
   end

   FSDisjointN = FSP.disjointN

   proc {FSDistinctN Vs} Xs = {VectorToList Vs}
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
      {FD.sum {Map {VectorToList Vs} fun {$ V} {FSCard V} end}
       '=:' {FSCard U}}
   end

   fun {FSNewWeights WL}
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
             case E1 < E2 then (((E1+1)#E2)#W)|T
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

      fun {$ E}
         {Dictionary.condGet WeightTable E Default}
      end
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

   FSVar =          v(is:    FSisVar

                      decl:  fun {$}
                                {FSSet nil FSUniversalRefl}
                             end
                      upperBound:
                         fun {$ B}
                            {FSSet nil B}
                         end

                      lowerBound: fun {$ A}
                                     {FSSet A FSUniversalRefl}
                                  end

                      new:   FSSet

                      list:  l(decl: proc {$ Len Ss}
                                        Ss = {MakeList Len}
                                        {ForAll Ss
                                         proc {$ X}
                                            {FSVar.decl X}
                                         end}
                                     end
                               upperBound:  proc {$ Len A Ss}
                                               Ss = {MakeList Len}
                                               {ForAll Ss
                                                proc {$ X}
                                                   {FSVar.upperBound A X}
                                                end}
                                            end
                               lowerBound:  proc {$ Len A Ss}
                                               Ss = {MakeList Len}
                                               {ForAll Ss
                                                proc {$ X}
                                                   {FSVar.lowerBound A X}
                                                end}
                                            end
                               new:  proc {$ Len GLB LUB Ss}
                                        Ss = {MakeList Len}
                                        {ForAll Ss
                                         proc {$ X}
                                            {FSVar.new GLB LUB X}
                                         end}
                                     end
                              )
                      tuple: t(decl: proc {$ L Size Ss}
                                        Ss = {MakeTuple L Size}
                                        {Record.forAll Ss
                                         proc {$ X}
                                            {FSVar.decl X}
                                         end}
                                     end
                               upperBound:  proc {$ L Size A Ss}
                                               Ss = {MakeTuple L Size}
                                               {Record.forAll Ss
                                                proc {$ X}
                                                   {FSVar.upperBound A X}
                                                end}
                                            end
                               lowerBound:  proc {$ L Size A Ss}
                                               Ss = {MakeTuple L Size}
                                               {Record.forAll Ss
                                                proc {$ X}
                                                   {FSVar.lowerBound A X}
                                                end}
                                            end
                               new:  proc {$ L Size GLB LUB Ss}
                                        Ss = {MakeTuple L Size}
                                        {Record.forAll Ss
                                         proc {$ X}
                                            {FSVar.new GLB LUB X}
                                         end}
                                     end
                              )

                      record: r(decl: proc {$ L Ls Ss}
                                         Ss = {MakeRecord L Ls}
                                         {Record.forAll Ss
                                          proc {$ X}
                                             {FSVar.decl X}
                                          end}
                                      end
                                upperBound:  proc {$ L Ls A Ss}
                                                Ss = {MakeRecord L Ls}
                                                {Record.forAll Ss
                                                 proc {$ X}
                                                    {FSVar.upperBound A X}
                                                 end}
                                             end
                                lowerBound:  proc {$ L Ls A Ss}
                                                Ss = {MakeRecord L Ls}
                                                {Record.forAll Ss
                                                 proc {$ X}
                                                    {FSVar.lowerBound A X}
                                                 end}
                                             end
                                new:  proc {$ L Ls GLB LUB Ss}
                                         Ss = {MakeRecord L Ls}
                                         {Record.forAll Ss
                                          proc {$ X}
                                             {FSVar.new GLB LUB X}
                                          end}
                                      end
                               )
                     )

   FSValue =          c(empty:     {FSSetValue nil}
                        universal: {FSSetValue FSUniversalRefl}
                        singl:     fun {$ N}
                                      {FSSetValue [N]}
                                   end
                        new:       FSSetValue
                        is:        FSisValue
                        toString:  FSvalueToString
                       )

   FSReified =     r(isIn:     proc {$ E S B}
                                  {FD.bool B}
                                  {FSIsInReif E S B}
                               end
                     areIn:    proc {$ WList S BList}
                                  BList
                                  = {FD.list {Length WList} 0#1}
                                  = {Map WList
                                     fun {$ E} {FSIsInReif E S} end}
                               end
                     include:  proc {$ E S B}
                                  {FD.bool B}
                                  {FSP.includeR E S B}
                               end
                     bounds:   FSP.bounds
                     boundsN:  FSP.boundsN
                     partition: FSP.partitionReified
                     equal:     FSEqualReif
                    )


   FSMonitorIn =    FSP.monitorIn

   FSMonitorOut =   FSP.monitorOut

   FSReflect =   r( unknown:    FSGetUnknown
                    lowerBound:        FSGetGlb
                    upperBound:        FSGetLub

                    card:       FSGetCard

                    cardOf:     c(lowerBound:     FSGetNumOfGlb
                                  upperBound:     FSGetNumOfLub
                                  unknown: FSGetNumOfUnknown)

                  ) % r

   FSInt =   i(match:        FSMatch
               minN:         FSMinN
               maxN:         FSMaxN
               seq:          FSSeq
               min:          FSMin
               max:          FSMax
               convex:       FSConvex
              )


end
