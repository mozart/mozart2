%%%
%%% Authors:
%%%   Joerg Wuertz (wuertz@dfki.de)
%%%   Tobias Mueller (tmueller@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Joerg Wuertz, 1997
%%%   Tobias Mueller, 1997
%%%   Christian Schulte, 1997, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local

   %%
   %% Vector conversion
   %%

   fun {VectorToType V}
      case {IsList V}       then list
      elsecase {IsTuple V}  then tuple
      elsecase {IsRecord V} then record
      else
         {`RaiseError`
          kernel(type VectorToType [V] vector 1
                 'Vector as input argument expected.')} illegal
      end
   end

   fun {VectorToList V}
      case {VectorToType V}==list then V
      else {Record.toList V}
      end
   end

   fun {VectorsToLists V}
      {Map {VectorToList V} VectorToList}
   end

   local
      proc {RecordToTuple As I R T}
         case As of nil then skip
         [] A|Ar then R.A=T.I {RecordToTuple Ar I+1 R T}
         end
      end
   in
      proc {VectorToTuple V ?T}
         case {VectorToType V}
         of list   then T={List.toTuple '#' V}
         [] tuple  then T=V
         [] record then
            T={MakeTuple '#' {Width V}} {RecordToTuple {Arity V} 1 V T}
         end
      end
   end

   fun {CloneList Xs}
      case Xs of nil then nil
      [] _|Xr then _|{CloneList Xr}
      end
   end

   local
      fun {ExpandPair L U Xs}
         case L=<U then L|{ExpandPair L+1 U Xs} else Xs end
      end
   in
      fun {Expand Xs}
         case Xs of nil then nil
         [] X|Xr then
            case X of L#R then {ExpandPair L R {Expand Xr}}
            else X|{Expand Xr}
            end
         end
      end
   end


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
   %%
   %% General abstractions for distribution
   %%

   proc {WaitStable}
      choice skip end
   end

   %%
   %% Error formatting
   %%

   local
      ArithOps = ['=:' '\\=:' '<:' '=<:' '>:' '>=:']

      BuiltinNames
      = bi(fdp_twice:         [fdp_twice           ['FD.plus' 'FD.minus']]
           fdp_square:        [fdp_square          ['FD.times']]
           fdp_plus:          ['FD.plus'           ['FD.distance']]
           fdp_plus_rel:      ['FD.plus'           ['FD.distance' '+']]
           fdp_minus:         ['FD.minus'          nil]
           fdp_times:         ['FD.times'          nil]
           fdp_times_rel:     ['FD.plus'           ['FD.distance' '*']]
           fdp_divD:          ['FD.divD'           nil]
           fdp_divI:          ['FD.divI'           nil]
           fdp_modD:          ['FD.modD'           nil]
           fdp_modI:          ['FD.modI'           nil]
           fdp_conj:          ['FD.conj'           nil]
           fdp_disj:          ['FD.disj'           nil]
           fdp_exor:          ['FD.exor'           nil]
           fdp_impl:          ['FD.impl'           nil]
           fdp_equi:          ['FD.equi'           nil]
           fdp_nega:          ['FD.nega'           ['FD.exor' 'FD.impl' 'FD.equi']]
           fdp_sumCR:         ['FD.reified.sumC'   ArithOps]
           fdp_intR:          ['FD.refied.int'     ['FD.reified.dom']]
           fdp_card:          ['FD.reified.card'   nil]
           fdp_exactly:       ['FD.exactly'        nil]
           fdp_atLeast:       ['FD.atLeast'        nil]
           fdp_atMost:        ['FD.atMost'         nil]
           fdp_element:       ['FD.element'        nil]
           fdp_disjoint:      ['FD.disjoint'       nil]
           fdp_disjointC:     ['FD.disjointC'      nil]
           fdp_distance:      ['FD.distance'       nil]
           fdp_notEqOff:      [fdp_notEqOff        ['FD.sumC' '\\=:']]
           fdp_lessEqOff:     ['FD.lesseq'         ['FD.sumC' '=<:' '<:' '>=:'
                                                    '>:' 'FD.min' 'FD.max'
                                                    'FD.modD'
                                                    'FD.modI' 'FD.disjoint'
                                                    'FD.disjointC' 'FD.distance'
                                                   ]]
           fdp_minimum:        ['FD.min'                   nil]
           fdp_maximum:        ['FD.max'                   nil]
           fdp_inter:          ['FD.inter'                 nil]
           fdp_union:          ['FD.union'                 nil]
           fdp_distinct:       ['FD.distinct'              nil]
           fdp_distinctOffset: ['FD.distinctOffset'        nil]
           fdp_subset:         [fdp_subset         ['FD.union' 'FD.inter']]
           fdp_sumC:           ['FD.sumC'          'FD.sumCN'|'FD.reified.sumC'|ArithOps]
           fdp_sumCN:          ['FD.sumCN'         ArithOps]
           fdp_sumAC:          ['FD.sumAC'         nil]

           sched_disjoint_card:['FD.schedule.disjoint'             nil]
           sched_cpIterate:    ['FD.schedule.serialized'           nil]
           sched_disjunctive:  ['FD.schedule.serializedDisj'       nil]

           fdGetMin:           ['FD.reflect.min'   nil]
           fdGetMid:           ['FD.reflect.mid'   nil]
           fdGetMax:           ['FD.reflect.max'   nil]
           fdGetDom:           ['FD.reflect.dom'   ['FD.reflect.domList']]
           fdGetCard:          ['FD.reflect.size'  nil]
           fdGetNextSmaller:   ['FD.reflect.nextSmaller'   nil]
           fdGetNextLarger:    ['FD.reflect.nextLarger'    nil]

           fdWatchSize:        ['FD.watch.size'    nil]
           fdWatchMin:         ['FD.watch.min'     nil]
           fdWatchMax:         ['FD.watch.max'     nil]

           fdConstrDisjSetUp:  [fdConstrDisjSetUp  ['condis ... end']]
           fdConstrDisj:       [fdConstrDisj       ['condis ... end']]
           fd_sumCD:           [fdp_sumCD          ['condis ... end']]
           fd_sumCCD:          [fdp_sumCCD         ['condis ... end']]
           fd_sumCNCD:         [fdp_sumCNCD        ['condis ... end']]
          )

      fun {BIPrintName X}
         case {IsAtom X}
            andthen {HasFeature BuiltinNames X}
         then BuiltinNames.X.1
         else X end
      end

      fun {BIOrigin X}
         BuiltinNames.X.2.1
      end

   in

      fun {FormatOrigin A}
         B = {BIPrintName A}
      in
         case {HasFeature BuiltinNames B}
            andthen {BIOrigin B}\=nil
         then
            [unit
             hint(l:'Possible origin of procedure' m:oz({BIPrintName B}))
             line(oz({BIOrigin B}))]
         else nil end
      end
   end

in

   functor $ prop once

   import
      Foreign.{staticLoad}

      ErrorRegistry.{put}

      Error.{formatGeneric
             formatAppl
             formatTypes
             formatHint
             format
             dispatch}

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
      power:          FdpPower
      divI:           FdpDivI
      divD:           FdpDivD
      modI:           FdpModI
      modD:           FdpModD
      max:            FdpMaximum
      min:            FdpMinimum
      distance:       FdpDistance
      less:           FdLess
      greater:        FdGreater
      lesseq:         FdLesseq
      greatereq:      FdGreatereq
      disjointC:      FdDisjointC
      disjoint:       FdpDisjoint

      %% Constructive disjunction support (compiler)
      cd:             FdCD

      %% Distribution
      distribute:     FdDistribute
      choose:         FdChoose

      %% Miscellaneous
      sup:            FdSup
      is:             FdIs

   body

      foreign(fdp_plus:           FdpPlus
              fdp_minus:          FdpMinus
              fdp_times:          FdpTimes
              fdp_power:          FdpPower
              fdp_divD:           FdpDivD
              fdp_divI:           FdpDivI
              fdp_modD:           FdpModD
              fdp_modI:           FdpModI
              fdp_conj:           FdpConj
              fdp_disj:           FdpDisj
              fdp_exor:           FdpExor
              fdp_impl:           FdpImpl
              fdp_nega:           FdpNega
              fdp_equi:           FdpEqui
              fdp_intR:           FdpIntR
              fdp_card:           FdpCard
              fdp_exactly:        FdpExactly
              fdp_atLeast:        FdpAtLeast
              fdp_atMost:         FdpAtMost
              fdp_element:        FdpElement
              fdp_lessEqOff:      FdpLessEqOff
              fdp_minimum:        FdpMinimum
              fdp_maximum:        FdpMaximum
              fdp_distinct:       FdpDistinct
              fdp_distinct2:      FdpDistinct2
              fdp_distinctD:      FdpDistinctD
              fdp_distinctOffset: FdpDistinctOffset
              fdp_disjoint:       FdpDisjoint
              fdp_disjointC:      FdpDisjointC
              fdp_distance:       FdpDistance
              fdp_sum:            FdpSum
              fdp_sumC:           FdpSumC
              fdp_dsum:           FdpDSum
              fdp_dsumC:          FdpDSumC
              fdp_sumAC:          FdpSumAC
              fdp_sumCN:          FdpSumCN
              fdp_sumR:           FdpSumR
              fdp_sumCR:          FdpSumCR
              fdp_sumCNR:         FdpSumCNR
              fdp_sumCD:          FdpSumCD
              fdp_sumCCD:         FdpSumCCD
              fdp_sumCNCD:        FdpSumCNCD

              fdd_selVarMin:      FddSelVarMin
              fdd_selVarMax:      FddSelVarMax
              fdd_selVarSize:     FddSelVarSize
              fdd_selVarNaive:    FddSelVarNaive
              fdd_selVarNbSusps:  FddSelVarNbSusps
              ...)
      = {Foreign.staticLoad 'libFDP.so'}

      %%
      %% Telling Domains
      %%

      local
         FdPutList = {`Builtin` fdTellConstraint 2}

         proc {ListDom Xs Dom}
            case Xs of nil then skip
            [] X|Xr then {FdPutList X Dom} {ListDom Xr Dom}
            end
         end

         proc {TupleDom N T Dom}
            case N>0 then {FdPutList T.N Dom} {TupleDom N-1 T Dom}
            else skip
            end
         end

         proc {RecordDom As R Dom}
            case As of nil then skip
            [] A|Ar then {FdPutList R.A Dom} {RecordDom Ar R Dom}
            end
         end
      in
         FdSup = {{`Builtin` fdGetLimits 2} 0}

         proc {FdInt Dom X}
            {FdPutList X Dom}
         end

         local
            BoolDom = [0#1]
         in
            proc {FdBool X}
               {FdPutList X BoolDom}
            end
         end

         local
            MaxDom = [0#FdSup]
         in
            proc {FdDecl X}
               {FdPutList X MaxDom}
            end
         end

         proc {FdDom Dom Vec}
            case {VectorToType Vec}
            of list   then {ListDom Vec Dom}
            [] tuple  then {TupleDom {Width Vec} Vec Dom}
            [] record then {RecordDom {Arity Vec} Vec Dom}
            end
         end

         fun {FdList N Dom}
            case N>0 then {FdPutList $ Dom}|{FdList N-1 Dom}
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

      FdIs = {`Builtin` fdIs 2}


      %%
      %% Reflection
      %%

      local
         GetDomCompact = {`Builtin` fdGetDom  2}
      in
         FdReflect = reflect(min:           {`Builtin` fdGetMin         2}
                             mid:           {`Builtin` fdGetMid         2}
                             max:           {`Builtin` fdGetMax         2}
                             nextLarger:    {`Builtin` fdGetNextLarger  3}
                             nextSmaller:   {`Builtin` fdGetNextSmaller 3}
                             size:          {`Builtin` fdGetCard        2}
                             nbSusps:       {`Builtin` 'System.nbSusps' 2}
                             domList:       fun {$ X}
                                               {Expand {GetDomCompact X}}
                                            end
                             dom:           GetDomCompact)
      end



      %%
      %% Constructive disjunction
      %%

      local
         FdPutListCD = {`Builtin` fdTellConstraintCD 3}

         proc {ListDomCD Xs Dom C}
            case Xs of nil then skip
            [] X|Xr then {FdPutListCD X Dom C} {ListDomCD Xr Dom C}
            end
         end

         proc {TupleDomCD N T Dom C}
            case N>0 then {FdPutListCD T.N Dom C} {TupleDomCD N-1 T Dom C}
            else skip
            end
         end

         proc {RecordDomCD As R Dom C}
            case As of nil then skip
            [] A|Ar then {FdPutListCD R.A Dom C} {RecordDomCD Ar R Dom C}
            end
         end

         proc {FdIntCD Dom X C}
            {FdPutListCD X Dom C}
         end

         proc {FdDomCD Dom Vec C}
            case {VectorToType Vec}
            of list   then {ListDomCD Vec Dom C}
            [] tuple  then {TupleDomCD {Width Vec} Vec Dom C}
            [] record then {RecordDomCD {Arity Vec} Vec Dom C}
            end
         end

      in

         FdCD = cd(header: {`Builtin` fdConstrDisjSetUp 4}
                   'body': {`Builtin` fdConstrDisj      3}
                   sum:    FdpSumCD
                   sumC:   FdpSumCCD
                   sumCN:  FdpSumCNCD
                   int:    FdIntCD
                   dom:    FdDomCD)

      end


      %%
      %% Generic Propagators
      %%

      proc {GenSumACN IIs DDs Rel D}
         thread
            Ds      = {VectorsToLists DDs}
            Coeffs1 = {VectorToList IIs}
            Coeffs2 = {Map Coeffs1 Number.'~'}
         in
            case FwdRelTable.Rel then
               {FdpSumCN Coeffs1 Ds Rel D}
               {FdpSumCN Coeffs2 Ds Rel D}
            else
               D1 D2 B1 B2
               TVars1   = {Map Ds CloneList}
               TVars2   = {Map Ds CloneList}
               TVars1_D = {VectorToTuple D1|{FoldL TVars1 Append nil}}
               TVars2_D = {VectorToTuple D2|{FoldL TVars2 Append nil}}
               TVars    = {VectorToTuple D|{FoldL Ds Append nil}}
            in
               {FdCD.header 1#1 B1#B2 TVars TVars1_D#TVars2_D}
               {FdCD.sumCN  Coeffs1 TVars1 Rel D1 B1}
               {FdCD.sumCN  Coeffs2 TVars2 Rel D2 B2}
               {FdCD.'body' B1#B2 TVars TVars1_D#TVars2_D}
            end
         end
      end

      %%
      %% Reified constraints
      %%

      local
         proc {FdIntR Dom D B}
            {FdBool B} {FdDecl D} {FdpIntR D Dom B}
         end

         proc {GenSumR X O D R}
            {FdBool R} {FdpSumR X O D R}
         end

         proc {GenSumCR A X O D R}
            {FdBool R} {FdpSumCR A X O D R}
         end

         proc {GenSumCNR A X O D R}
            {FdBool R} {FdpSumCNR A X O D R}
         end

         local
            proc {MapIntR N T TR Dom}
               case N==0 then skip else
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
            {FdBool B}
            thread
               case {FdIs Low} andthen {FdIs Up} then
                  case {IsLiteral Ds} then
                     or B=1 Low=0
                     [] B=0 {FdInt 1#FdSup Low}
                     end
                  else
                     {FdpCard {VectorToTuple Ds} Low Up B}
                  end
               else
                  {`RaiseError`
                   kernel(type
                          'FD.reified.card'
                          [Low Ds Up B]
                          fd
                          case {FdIs Low} then 3 else 1 end
                          'Cardinality limits must be finite domain.')}
               end
            end
         end

         proc {GenSumACR IV DV Rel D B}
            thread
               NegRel = NegRelTable.Rel
               IT     = {VectorToTuple IV}
               NIT    = {Record.map IT Number.'~'}
               DT     = {VectorToTuple DV}
            in
               {FdBool B}
               case FwdRelTable.Rel then
                  or B=1
                     {FdpSumC IT  DT Rel D}
                     {FdpSumC NIT DT Rel D}
                  [] B=0
                     {FdpSumC IT  DT NegRel D}
                  [] B=0
                     {FdpSumC NIT DT NegRel D}
                  end
               else
                  or B1 B2 D1 D2
                     ND = {Width DT}
                     TVars1   = {MakeTuple '#' ND}
                     TVars2   = {MakeTuple '#' ND}
                     TVars1_D = {Tuple.append v(D1) TVars1}
                     TVars2_D = {Tuple.append v(D2) TVars2}
                     TVars    = {Tuple.append v(D)  DT}
                  in
                     B=1
                     {FdCD.header 1#1 B1#B2 TVars TVars1_D#TVars2_D}
                     {FdCD.sumC IT  TVars1 Rel D1 B1}
                     {FdCD.sumC NIT TVars2 Rel D2 B2}
                     {FdCD.'body' B1#B2 TVars TVars1_D#TVars2_D}
                  [] B=0
                     {FdpSumC IT  DT NegRel D}
                     {FdpSumC NIT DT NegRel D}
                  end
               end
            end
         end

         proc {GenSumACNR IIs DDs Rel D B}
            thread
               NegRel  = NegRelTable.Rel
               Ds      = {VectorsToLists DDs}
               Coeffs1 = {VectorToList IIs}
               Coeffs2 = {Map Coeffs1 Number.'~'}
            in
               {FdBool B}
               case FwdRelTable.Rel then
                  or B=1
                     {FdpSumCN Coeffs1 Ds Rel D}
                     {FdpSumCN Coeffs2 Ds Rel D}
                  [] B=0
                     {FdpSumCN Coeffs1 Ds NegRel D}
                  [] B=0
                     {FdpSumCN Coeffs2 Ds NegRel D}
                  end
               else
                  or
                     D1 D2 B1 B2
                     TVars1   = {Map Ds CloneList}
                     TVars2   = {Map Ds CloneList}
                     TVars1_D = {VectorToTuple D1|{FoldL TVars1 Append nil}}
                     TVars2_D = {VectorToTuple D2|{FoldL TVars2 Append nil}}
                     TVars    = {VectorToTuple D|{FoldL Ds Append nil}}
                  in
                     B=1
                     {FdCD.header 1#1 B1#B2 TVars TVars1_D#TVars2_D}
                     {FdCD.sumCN Coeffs1 {VectorToTuple TVars1} Rel D1 B1}
                     {FdCD.sumCN Coeffs2 {VectorToTuple TVars2} Rel D2 B2}
                     {FdCD.'body' B1#B2 TVars TVars1_D#TVars2_D}
                  [] B=0
                     {FdpSumCN Coeffs1 Ds NegRel D}
                     {FdpSumCN Coeffs2 Ds NegRel D}
                  end
               end
            end
         end

         proc {DistanceR X Y Rel D B}
            {GenSumACR [1 ~1] [X Y] Rel D B}
         end

      in

         FdReified = reified(int:        FdIntR
                             dom:        FdDomR
                             sum:        GenSumR
                             sumC:       GenSumCR
                             sumCN:      GenSumCNR
                             sumAC:      GenSumACR
                             sumACN:     GenSumACNR
                             distance:   DistanceR
                             card:       Card)
      end


      %%
      %% Distribution
      %%

      local

         local
            ForceClone = {NewName}
         in
            proc {MakeDistrTuple V ?T}
               T = case {VectorToType V}==tuple then
                      {Adjoin V ForceClone}
                   else {VectorToTuple V}
                   end
               case {Record.all T FdIs} then skip else
                  {`RaiseError`
                   kernel(type 'MakeDistrTuple' [V T] list(fd) 1
                          'Distribution vector must contain finite domains.')}
               end
            end
         end

         local
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

            %% Optimized only
            OptSelVar = map(min:     FddSelVarMin
                            max:     FddSelVarMax
                            size:    FddSelVarSize
                            naive:   FddSelVarNaive
                            nbSusps: FddSelVarNbSusps)

            %% Generic only
            GenSelVar = map(naive:   fun {$ _ _}
                                        false
                                     end
                            size:    fun {$ X Y}
                                        {FdReflect.size X}<{FdReflect.size Y}
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

            GenSelPro = map(noProc: proc {$}
                                       skip
                                    end)

            GenSelSel = map(id:     fun {$ X}
                                       X
                                    end)

            fun {MapSelect Map AOP}
               case {IsAtom AOP} then Map.AOP else AOP end
            end

         in

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
               case IsOpt then
                  opt(order: OptSelVar.(FullSpec.order)
                      value: SelVal.(FullSpec.value))
               else
                  gen(order:     {MapSelect GenSelVar FullSpec.order}
                      value:     {MapSelect SelVal FullSpec.value}
                      select:    {MapSelect GenSelSel FullSpec.select}
                      filter:    {MapSelect GenSelFil FullSpec.filter}
                      procedure: {MapSelect GenSelPro FullSpec.procedure})
               end
            end
         end

         fun {Choose Xs Y Order}
            case Xs of nil then Y
            [] X|Xr then {Choose Xr case {Order X Y} then X else Y end Order}
            end
         end

      in

         proc {FdDistribute RawSpec Vec}
            {WaitStable}
            case {PreProcessSpec RawSpec}
            of opt(value:SelVal order:SelVar) then
               VecTuple = {MakeDistrTuple Vec}
               proc {Do}
                  V={SelVar VecTuple}
                  D={SelVal V}
               in
                  choice {FdInt D V} [] {FdInt compl(D) V} end
                  {WaitStable}
                  {Do}
               end
            in
               try {Do}
               catch ~1 then skip
               end
            [] gen(value:     SelVal
                   order:     Order
                   select:    Select
                   filter:    Fil
                   procedure: Proc) then

               proc {Do Xs}
                  case {Filter Xs Fil} of nil then skip elseof Xs=X|Xr then
                     V={Select {Choose Xr X Order}}
                     D={SelVal V}
                  in
                     {Proc}
                     {WaitStable}
                     choice {FdInt D V} [] {FdInt compl(D) V} end
                     {WaitStable}
                     {Do Xs}
                  end
               end
            in
               {Do {VectorToList Vec}}
            end
         end


         proc {FdChoose RawSpec Vec ?V ?D}
            {WaitStable}
            try
               case {PreProcessSpec RawSpec}
               of opt(value:SelVal order:SelVar) then
                  V={SelVar {MakeDistrTuple Vec}}
                  D={SelVal V}
               [] gen(value:     SelVal
                      order:     Order
                      select:    Select
                      filter:    Fil
                      procedure: _)
               then
                  case {Filter {VectorToList Vec} Fil} of nil then
                     raise ~1 end
                  elseof Xs=X|Xr then
                     V={Select {Choose Xr X Order}}
                     D={SelVal V}
                  end
               end
            catch ~1 then
               {`RaiseError`
                fd(noChoice 'FD.choose' [RawSpec Vec V D] 2
                   'Vector must contain non-determined elements.')}
            end
         end
      end


      %%
      %% Watching variables
      %%

      FdWatch = watch(size: {`Builtin` fdWatchSize 3}
                      min:  {`Builtin` fdWatchMin  3}
                      max:  {`Builtin` fdWatchMax  3})


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
      proc {FdDisjointC X XD Y YD C}
         {FdBool C}
         {FdpDisjointC X XD Y YD C}
      end

      %%
      %% Register error formatter
      %%

      {ErrorRegistry.put

       fd

       fun {$ Exc}
          E = {Error.dispatch Exc}
          T = 'error in finite domain system'
       in
          case E
          of fd(scheduling A Xs T P S) then

         % expected Xs:list, T:atom, P:int S:virtualString

             {Error.format
              T unit
              hint(l:'At argument' m:P)
              | {Append
                 {Error.formatTypes T}
                 hint(l:'In statement' m:{Error.formatAppl A Xs})
                 | {Append {FormatOrigin A} {Error.formatHint S}}}
              Exc}

          elseof fd(noChoice A Xs P S) then

         % expected Xs:list, P:int, S:virtualString

             {Error.format
              T unit
              hint(l:'At argument' m:P)
              | hint(l:'In statement' m:{Error.formatAppl A Xs})
              | {Append {FormatOrigin A} {Error.formatHint S}}
              Exc}

          else
             {Error.formatGeneric T Exc}
          end
       end}

   end

end
