%%%
%%% Authors:
%%%   Joerg Wuertz (wuertz@dfki.de)
%%%   Tobias Mueller (tmueller@ps.uni-sb.de)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Joerg Wuertz, 1997
%%%   Tobias Mueller, 1997, 1998
%%%   Christian Schulte, 1997, 1998
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

require
   CpSupport(vectorToType:   VectorToType
             vectorToList:   VectorToList
             vectorToTuple:  VectorToTuple
             vectorMap:      VectorMap

             expand:         Expand

             formatOrigin:   FormatOrigin)


prepare
   FwdRelTable = fwdRelTable('=:':   false
                             '=<:':  true
                             '<:' :  true
                             '>=:':  false
                             '>:':   false
                             '\\=:': true)

   NegRelTable = negRelTable('=:':   '\\=:'
                             '=<:':  '>:'
                             '<:' :  '>=:'
                             '>=:':  '<:'
                             '>:':   '=<:'
                             '\\=:': '=:')

   FddOptVarMap = map(naive:   0
                      size:    1
                      min:     2
                      max:     3
                      nbSusps: 4
                      width:   5)

   FddOptValMap = map(min:      0
                      mid:      1
                      max:      2
                      splitMin: 3
                      splitMax: 4)


import
   FDB at 'x-oz://boot/FDB'
   FDP at 'x-oz://boot/FDP'
   Space(waitStable)

   Error(registerFormatter)

   System(nbSusps)

export
   %% Telling Domains
   int:            FdInt
   bool:           FdBool
   dom:            FdDom
   decl:           FdDecl
   list:           FdList
   tuple:          FdTuple
   record:         FdRecord

   %% Reflection
   reflect:        FdReflect

   %% Watching Domains
   watch:          FdWatch

   %% Generic Propagators
   sum:            FdpSum
   sumC:           FdpSumC
   sumCN:          FdpSumCN
   sumAC:          FdpSumAC
   sumACN:         GenSumACN
   sumD:           FdpDSum
   sumCD:          FdpDSumC

   %% Symbolic Propagators
   distinct:       FdpDistinct
   distinct2:      FdpDistinct2
   distinctB:      FdpDistinctB
   distinctD:      FdpDistinctD
   distinctOffset: FdpDistinctOffset
   atMost:         FdpAtMost
   atLeast:        FdpAtLeast
   exactly:        FdpExactly
   element:        FdpElement

   %% 0/1 Propagators
   conj:           FdpConj
   disj:           FdpDisj
   nega:           FdpNega
   exor:           FdpExor
   impl:           FdpImpl
   equi:           FdpEqui

   %% Reified Propagators
   reified:        FdReified

   %% Miscellaneous Propagators
   plus:           FdpPlus
   minus:          FdpMinus
   times:          FdpTimes
   plusD:          FdpPlusD
   minusD:         FdpMinusD
   timesD:         FdpTimesD
   power:          FdpPower
   divI:           FdpDivI
   divD:           FdpDivD
   modI:           FdpModI
   modD:           FdpModD
   max:            FdpMaximum
   min:            FdpMinimum
   distance:       FdpDistance
   tasksOverlap:   FdpTasksOverlap
   less:           FdLess
   greater:        FdGreater
   lesseq:         FdLesseq
   greatereq:      FdGreatereq
   disjointC:      FdDisjointC
   disjoint:       FdpDisjoint

   %% Distribution
   assign:         FdAssign
   distribute:     FdDistribute
   choose:         FdChoose

   %% Miscellaneous
   inf:            FdInf
   sup:            FdSup
   is:             FdIs

define

   {Wait Space.waitStable}
   {Wait FDB.int}

   FdpPlus = FDP.plus
   proc {FdpMinus X Y Z}
      {FdpPlus Z Y X}
   end
   FdpTimes = FDP.times
   FdpPlusD = FDP.plusD
   proc {FdpMinusD X Y Z}
      {FdpPlusD Z Y X}
   end
   FdpTimesD = FDP.timesD
   FdpPower = FDP.power
   FdpDivD = FDP.divD
   FdpDivI = FDP.divI
   FdpModD = FDP.modD
   FdpModI = FDP.modI
   FdpConj = FDP.conj
   FdpDisj = FDP.disj
   FdpExor = FDP.exor
   FdpImpl = FDP.impl
   FdpNega = FDP.nega
   FdpEqui = FDP.equi
   FdpIntR = FDP.'reified.int'
   FdpCard = FDP.'reified.card'
   FdpExactly = FDP.exactly
   FdpAtLeast = FDP.atLeast
   FdpAtMost = FDP.atMost
   FdpElement = FDP.element
   FdpLessEqOff = FDP.lessEqOff
   FdpMinimum = FDP.min
   FdpMaximum = FDP.max

   FdpDistinct = FDP.distinct
   FdpDistinct2 = FDP.distinct2
   FdpDistinctD = FDP.distinctD
   FdpDistinctB = FDP.distinctB
   FdpDistinctOffset = FDP.distinctOffset

   FdpDisjoint = FDP.disjoint
   FdpDisjointC = FDP.disjointC
   FdpDistance = FDP.distance
   FdpTasksOverlap = FDP.tasksOverlap

   FdpSum = FDP.sum
   FdpSumC = FDP.sumC
   FdpDSum = FDP.sumD
   FdpDSumC = FDP.sumCD
   FdpSumAC = FDP.sumAC
   FdpSumCN = FDP.sumCN
   FdpSumR = FDP.'reified.sum'
   FdpSumCR = FDP.'reified.sumC'
   FdpSumCNR = FDP.'reified.sumCN'

   %%
   %% Telling Domains
   %%

   local
      FdPutList = FDB.'int'

      proc {ListDom Xs Dom}
         case Xs of nil then skip
         [] X|Xr then {FdPutList Dom X} {ListDom Xr Dom}
         end
      end

      proc {TupleDom N T Dom}
         if N>0 then {FdPutList Dom T.N} {TupleDom N-1 T Dom} end
      end

      proc {RecordDom As R Dom}
         case As of nil then skip
         [] A|Ar then {FdPutList Dom R.A} {RecordDom Ar R Dom}
         end
      end
   in
      FdInf = {FDB.getLimits $ _}
      FdSup = {FDB.getLimits _}

      FdInt  = FdPutList
      FdBool = FDB.'bool'
      FdDecl = FDB.'decl'

      proc {FdDom Dom Vec}
         case {VectorToType Vec}
         of list   then {ListDom Vec Dom}
         [] tuple  then {TupleDom {Width Vec} Vec Dom}
         [] record then {RecordDom {Arity Vec} Vec Dom}
         end
      end

      fun {FdList N Dom}
         if N>0 then {FdPutList Dom}|{FdList N-1 Dom}
         else nil
         end
      end

      proc {FdTuple L N Dom ?T}
         T={MakeTuple L N} {TupleDom N T Dom}
      end

      proc {FdRecord L As Dom ?R}
         R={MakeRecord L As} {RecordDom As R Dom}
      end
   end

   FdIs = FDB.'is'


   %%
   %% Reflection
   %%

   local
      GetDomCompact = FDB.'reflect.dom'
   in
      FdReflect = reflect(min:           FDB.'reflect.min'
                          mid:           FDB.'reflect.mid'
                          max:           FDB.'reflect.max'
                          nextLarger:    FDB.'reflect.nextLarger'
                          nextSmaller:   FDB.'reflect.nextSmaller'
                          size:          FDB.'reflect.size'
                          width:         FDB.'reflect.width'
                          nbSusps:       System.nbSusps
                          domList:       fun {$ X}
                                            {Expand {GetDomCompact X}}
                                         end
                          dom:           GetDomCompact)
   end


   %%
   %% Generic Propagators
   %%

   proc {GenSumACN IV DDV Rel D}
      NIV = {VectorMap IV Number.'~'}
   in
      if FwdRelTable.Rel then
         {FdpSumCN IV  DDV Rel D}
         {FdpSumCN NIV DDV Rel D}
      else
         thread
            or {FdpSumCN IV  DDV Rel D}
            [] {FdpSumCN NIV DDV Rel D}
            end
         end
      end
   end

   %%
   %% Reified constraints
   %%

   local
      FdIntR = FdpIntR

      GenSumR   = FdpSumR
      GenSumCR  = FdpSumCR
      GenSumCNR = FdpSumCNR

      local
         proc {MapIntR N T TR Dom}
            if N\=0 then
               {FdIntR Dom T.N TR.N} {MapIntR N-1 T TR Dom}
            end
         end
      in
         proc {FdDomR Dom V B}
            thread
               T  = {VectorToTuple V}
               N  = {Width T}
               TR = {MakeTuple '#' N}
            in
               {MapIntR N T TR Dom}
               {GenSumR TR '=:' N B}
            end
         end
      end

      proc {Card Low Ds Up B}
         thread
            if {FdIs Low} andthen {FdIs Up} then
               if {IsLiteral Ds} then
                  {FdBool B}
                  or B=1 Low=0
                  [] B=0 {FdInt 1#FdSup Low}
                  end
               else
                  {FdpCard {VectorToTuple Ds} Low Up B}
               end
            else
               {Exception.raiseError
                kernel(type
                       'FD.reified.card'
                       [Low Ds Up B]
                       fd
                       if {FdIs Low} then 3 else 1 end
                       'Cardinality limits must be finite domain.')}
            end
         end
      end

      proc {GenSumACR IV DV Rel D B}
         NegRel = NegRelTable.Rel
      in
         {FdBool B}
         thread
            or B=1 {FdpSumAC IV DV Rel    D}
            [] B=0 {FdpSumAC IV DV NegRel D}
            end
         end
      end

      proc {GenSumACNR IV DDV Rel D B}
         NegRel = NegRelTable.Rel
      in
         {FdBool B}
         thread
            or B=1 {GenSumACN IV DDV Rel    D}
            [] B=0 {GenSumACN IV DDV NegRel D}
            end
         end
      end

      proc {DistanceR X Y Rel D B}
         {GenSumACR 1#~1 X#Y Rel D B}
      end

   in

      FdReified = reified(int:        FdIntR
                          dom:        FdDomR
                          sum:        GenSumR
                          sumC:       GenSumCR
                          sumCN:      proc {$ A B C D E}
                                         thread {GenSumCNR A B C D E} end
                                      end
                          sumAC:      GenSumACR
                          sumACN:     GenSumACNR
                          distance:   DistanceR
                          card:       Card)
   end


   %%
   %% Distribution
   %%

   local

      proc {MakeDistrTuple V ?T}
         T = {VectorToTuple V}
         if {Record.all T FdIs} then skip else
            {Exception.raiseError
             kernel(type MakeDistrTuple [V T] 'vector(fd)' 1
                    'Distribution vector must contain finite domains.')}
         end
      end

      %% Optimized and generic
      SelVal = map(min:      FdReflect.min
                   max:      FdReflect.max
                   mid:      FdReflect.mid
                   splitMin: fun {$ V}
                                0#{FdReflect.mid V}
                             end
                   splitMax: fun {$ V}
                                {FdReflect.mid V}+1#FdSup
                             end)

      %% Generic only
      GenSelVar = map(naive:   fun {$ _ _}
                                  false
                               end
                      size:    fun {$ X Y}
                                  {FdReflect.size X}<{FdReflect.size Y}
                               end
                      width:   fun {$ X Y}
                                  {FdReflect.width X}<{FdReflect.width Y}
                               end
                      nbSusps: fun {$ X Y}
                                  L1={FdReflect.nbSusps X}
                                  L2={FdReflect.nbSusps Y}
                               in
                                  L1>L2 orelse
                                  (L1==L2 andthen
                                   {FdReflect.size X}<{FdReflect.size Y})
                               end
                      min:     fun {$ X Y}
                                  {FdReflect.min X}<{FdReflect.min Y}
                               end
                      max:     fun {$ X Y}
                                  {FdReflect.max X}>{FdReflect.max Y}
                               end)

      GenSelFil = map(undet:  fun {$ X}
                                 {FdReflect.size X} > 1
                              end)

      %% use unit as default value to recognize the case when
      %% we can void the overhead of a procedure call and a synchronization
      %% on stability
      GenSelPro = map(noProc: unit)

      GenSelSel = map(id:     fun {$ X}
                                 X
                              end)

      fun {MapSelect Map AOP}
         if {IsAtom AOP} then Map.AOP else AOP end
      end

      fun {PreProcessSpec Spec}
         FullSpec = {Adjoin
                     generic(order:     size
                             filter:    undet
                             select:    id
                             value:     min
                             procedure: noProc)
                     case Spec
                     of naive then generic(order:naive)
                     [] ff    then generic
                     [] split then generic(value:splitMin)
                     else Spec
                     end}
         IsOpt =    case FullSpec
                    of generic(select:id filter:undet procedure:noProc
                               order:OrdSpec value:ValSpec) then
                       {IsAtom OrdSpec} andthen {IsAtom ValSpec}
                    else false
                    end
      in
         if IsOpt then
            opt(order: FullSpec.order
                value: FullSpec.value)
         else
            gen(order:     {MapSelect GenSelVar FullSpec.order}
                value:     {MapSelect SelVal FullSpec.value}
                select:    {MapSelect GenSelSel FullSpec.select}
                filter:    {MapSelect GenSelFil FullSpec.filter}
                procedure: {MapSelect GenSelPro FullSpec.procedure})
         end
      end

      %% 1st argument must be a list, records are too slow
      fun {Choose Vars Order Filter}
         fun {Loop Vars Accu}
            case Vars of nil then Accu
            [] H|T then
               {Loop T
                if {Filter H} andthen (Accu==unit orelse {Order H Accu})
                then H else Accu end}
            end
         end
      in
         {Loop Vars unit}
      end

      %% Same as Choose,  but returns the filtered list of vars
      %% as well as the chosen variable.
      fun {ChooseAndRetFiltVars Vars Order Filter}
         NewVars
         fun {Loop Vars Accu NewTail}
            case Vars of nil then
               NewTail=nil
               Accu|NewVars
            [] H|T then
               if {Filter H} then LL in NewTail=(H|LL)
                  {Loop T
                   if Accu==unit orelse {Order H Accu}
                   then H else Accu end
                   LL}
               else {Loop T Accu NewTail} end
            end
         end
      in
         {Loop Vars unit NewVars}
      end

   in

      proc {FdDistribute RawSpec Vec}
         case {PreProcessSpec RawSpec}
         of opt(value:SelVal order:SelVar) then
            {Wait {FDP.distribute FddOptVarMap.SelVar FddOptValMap.SelVal Vec}}
         [] gen(value:     SelVal
                order:     Order
                select:    Select
                filter:    Fil
                procedure: Proc) then
            if {Width Vec}>0 then
               proc {Do Xs}
                  {Space.waitStable}
                  E|Fs={ChooseAndRetFiltVars Xs Order Fil}
               in
                  if E\=unit then
                     V={Select E}
                     D={SelVal V}
                  in
                     if Proc\=unit then
                        {Proc}
                        {Space.waitStable}
                     end
                     choice {FdInt D        V}
                     []     {FdInt compl(D) V}
                     end
                     {Do Fs}
                  end
               end
            in
               {Do {VectorToList Vec}}
            end
         end
      end

      proc {FdChoose RawSpec Vec ?V ?D}
         {Space.waitStable}
%        try
            case {PreProcessSpec RawSpec}
            of opt(value:SelValSpec order:SelVarSpec) then
               case {Filter {VectorToList Vec} GenSelFil.undet}
               of nil then D=unit
               [] X|Xs then
                  {Choose Xs X {MapSelect GenSelVar SelVarSpec} V}
                  {{MapSelect SelVal SelValSpec} V D}
               end
            [] gen(value:     SelVal
                   order:     Order
                   select:    Select
                   filter:    Fil
                   procedure: _)
            then
               case {Filter {VectorToList Vec} Fil} of nil then
                  D=unit
               [] X|Xr then
                  V={Select {Choose Xr X Order}}
                  D={SelVal V}
               end
            end
%        catch ~1 then
%           {Exception.raiseError
%            fd(noChoice 'FD.choose' [RawSpec Vec V D] 2
%               'Vector must contain non-determined elements.')}
%        end
      end
   end

   proc {FdAssign Spec V}
      {Wait {FDP.assign Spec V}}
   end

   %%
   %% Watching variables
   %%

   FdWatch = watch(size: FDB.'watch.size'
                   min:  FDB.'watch.min'
                   max:  FDB.'watch.max')


   %%
   %% Miscalleanous
   %%

   proc {FdLess X Y}
      {FdpLessEqOff X Y ~1}
   end
   proc {FdGreater X Y}
      {FdpLessEqOff Y X ~1}
   end
   proc {FdLesseq X Y}
      {FdpLessEqOff X Y 0}
   end
   proc {FdGreatereq X Y}
      {FdpLessEqOff Y X 0}
   end

   FdDisjointC = FdpDisjointC

   %%
   %% Register error formatter
   %%

   {Error.registerFormatter fd
    fun {$ E}
       T = 'error in finite domain system'
    in
       case E
       of fd(noChoice A Xs P S) then
          %% expected Xs:list, P:int, S:virtualString
          error(kind: T
                items: (hint(l:'At argument' m:P)|
                        hint(l:'In statement' m:apply(A Xs))|
                        {Append {FormatOrigin A} [line(S)]}))

       else
          error(kind: T
                items: [line(oz(E))])
       end
    end}

end
