%%%
%%% Authors:
%%%   Joerg Wuertz (wuertz@dfki.de)
%%%   Tobias Mueller (tmueller@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Joerg Wuertz, 1997
%%%   Tobias Mueller, 1997
%%%   Christian Schulte, 1997
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


%%% Development switch
%%%
%%%\define DEBUG_LOCAL_LIBRARIES
%%%\undef  DEBUG_LOCAL_LIBRARIES
%%%

`::` `:::`

`GenSum` `GenSumC` `GenSumCN`
`PlusRel` `TimesRel`
`Lec` `Gec` `Nec` `Lepc` `Nepc` `Neq`

`GenSumR` `GenSumCR` `GenSumCNR`
`::R` `:::R`

`CDHeader` `CDBody`
`GenSumCD` `GenSumCCD` `GenSumCNCD`
`::CD` `:::CD`

local

   CompileDate

   local
      HasForeignFDP = {{`Builtin` foreignFDProps 1}}

      fun {GetBiArity Spec}
         BiName # BiArity = Spec in BiArity
      end

      fun {GetBi Spec}
         BiName # BiArity = Spec in {`Builtin` BiName BiArity}
      end
   in
      fun {LoadLibrary LibName LibSpec}
         case HasForeignFDP then
            OzHome      = {System.get home}
            OS#CPU      = {System.get platform}
\ifdef DEBUG_LOCAL_LIBRARIES
            ObjectFile  = '/home/ps-home3/tmueller/Oz/Emulator/' # LibName
            {Show {StringToAtom
                   {VirtualString.toString '   Loading: ' # ObjectFile}}}
\else
            ObjectFile  = OzHome#'/platform/'#OS#'-'#CPU#'/'#LibName
\endif
         in
            {Foreign.dload
             ObjectFile
             {Record.map LibSpec GetBiArity}
             _
            }
         else
            {Record.map LibSpec GetBi}
         end
      end
   end

   FDP = {LoadLibrary 'fdlib.so'
          fdp(init:           fdp_init           #1
              plus_rel:       fdp_plus_rel       #3
              plus:           fdp_plus           #3
              minus:          fdp_minus          #3
              times:          fdp_times          #3
              times_rel:      fdp_times_rel      #3
              power:          fdp_power          #3
              divD:           fdp_divD           #3
              divI:           fdp_divI           #3
              modD:           fdp_modD           #3
              modI:           fdp_modI           #3
              conj:           fdp_conj           #3
              disj:           fdp_disj           #3
              exor:           fdp_exor           #3
              impl:           fdp_impl           #3
              nega:           fdp_nega           #2
              equi:           fdp_equi           #3
              intR:           fdp_intR           #3
              card:           fdp_card           #4
              exactly:        fdp_exactly        #3
              atLeast:        fdp_atLeast        #3
              atMost:         fdp_atMost         #3
              element:        fdp_element        #3
              notEqOff:       fdp_notEqOff       #3
              lessEqOff:      fdp_lessEqOff      #3
              minimum:        fdp_minimum        #3
              maximum:        fdp_maximum        #3
              distinct:       fdp_distinct       #1
              distinctD:      fdp_distinctD      #1
              distinctOffset: fdp_distinctOffset #2
              disjoint:       fdp_disjoint       #4
              disjointC:      fdp_disjointC      #5
              distance:       fdp_distance       #4
              sum:            fdp_sum            #3
              sumC:           fdp_sumC           #4
              dsum:           fdp_dsum           #3
              dsumC:          fdp_dsumC          #4
              sumAC:          fdp_sumAC          #4
              sumCN:          fdp_sumCN          #4
              sumR:           fdp_sumR           #4
              sumCR:          fdp_sumCR          #5
              sumCNR:         fdp_sumCNR         #5
              sumCD:          fdp_sumCD          #4
              sumCCD:         fdp_sumCCD         #5
              sumCNCD:        fdp_sumCNCD        #5)}

   SchedLib = {LoadLibrary 'schedlib.so'
               sched(disjoint_card:      sched_disjoint_card      #4
                     cpIterate:          sched_cpIterate          #3
                     taskIntervals:      sched_taskIntervals      #3
                     disjunctive:        sched_disjunctive        #3
                     cpIterateCap:       sched_cpIterateCap       #5
                     cumulativeTI:       sched_cumulativeTI       #5
                     cpIterateCapUp:     sched_cpIterateCapUp     #5
                     taskIntervalsProof: sched_taskIntervalsProof #5
                     firstsLasts:        sched_firstsLasts        #5)}

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% Converter functions
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   fun {Convert In}
      case {IsList In} then In
      elsecase {IsLiteral In} then nil
      elsecase {IsRecord In} then {Record.toList In}
      else
         {`RaiseError`
          kernel(type
                 'Convert'
                 [In]
                 vector
                 1
                 'A propagator expected a vector as input argument.')}
         nil
      end
   end

   local
      fun {MapConvert Xs}
         case Xs
         of X|Xr then {Convert X}|{MapConvert Xr}
         [] nil  then nil
         end
      end
   in
      fun {ConvertAll In}
         case {IsList In} then {MapConvert In}
         elsecase {IsRecord In} then {MapConvert {Record.toList In}}
         else
            {`RaiseError`
             kernel(type
                    'ConvertAll'
                    [In]
                    vector
                    1
                    'A propagator expected a vector of vectors as input argument.')}
            '#'
         end
      end
   end

   fun {ConvertToTuple In}
      case {IsLiteral In} then
         '#'
      elsecase {IsList In} then
         {List.toTuple '#' In}
      elsecase {IsTuple In} then
         In
      elsecase {IsRecord In} then
         {List.toTuple '#' {Record.toList In}}
      else
         {`RaiseError`
          kernel(type
                 'ConvertToTuple'
                 [In]
                 vector
                 1
                 'A propagator expected a vector as input argument.') }
         '#'
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% Telling Domains
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   local
      FdPutList = {`Builtin` fdTellConstraint 2}
      Inf=0
   in
      FiniteDomainBound = {{`Builtin` fdGetLimits 2} Inf}

      proc {!`::` Descr D} {FdPutList D Descr} end

      proc {FDDecl X} {FdPutList X [Inf#FiniteDomainBound]} end

      proc {!`:::` Descr Ds}
         {ForAll {Convert Ds} proc{$ D}
                                 {`::` Descr D}
                              end}
      end

      proc {ListDef I Descr Xs}
         Xs = {MakeList I}
         {`:::` Descr Xs}
      end

      proc {TupleDef L I Descr T}
         T={MakeTuple L I}
         {Record.forAll T proc{$ X} {FdPutList X Descr} end}
      end

      proc {RecordDef L Feats Descr R}
         R={MakeRecord L Feats}
         {Record.forAll R proc{$ X} {FdPutList X Descr} end}
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% Reflection
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   GetMin            = {`Builtin` fdGetMin  2}
   GetMid            = {`Builtin` fdGetMid  2}
   GetMax            = {`Builtin` fdGetMax  2}
   GetSize           = {`Builtin` fdGetCard 2}
   GetDomCompact     = {`Builtin` fdGetDom  2}

   local
      fun {ExpandPair L U Xs}
         case L=<U then L|{ExpandPair L+1 U Xs} else Xs end
      end
      fun {Expand Xs}
         case Xs of nil then nil
         [] X|Xr then
            case X of L#R then {ExpandPair L R {Expand Xr}}
            else X|{Expand Xr}
            end
         end
      end
   in
      fun {GetFiniteDomain X}
         {Expand {GetDomCompact X}}
      end
   end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%% Generic Propagators
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


   %% necessary for propagators using abs
   !`CDHeader`   = {`Builtin` fdConstrDisjSetUp 4}
   !`CDBody`     = {`Builtin` fdConstrDisj      3}
   !`GenSumCD`   = FDP.sumCD
   !`GenSumCCD`  = FDP.sumCCD
   !`GenSumCNCD` = FDP.sumCNCD

/*
   GenSumAC = proc{$ IIs DDs Rel D}
                 thread
                    Ds       = {Convert DDs}
                    Coeffs1  = {Convert IIs}
                    Coeffs2  = {Map Coeffs1 fun{$ X} ~X end}
                 in
                    case Rel == '=<:' orelse
                       Rel == '<:' orelse
                       Rel == '\\=:'
                    then
                       {`GenSumC` Coeffs1 Ds Rel D}
                       {`GenSumC` Coeffs2 Ds Rel D}
                    else
                       D1 D2 B1 B2
                       LDs      = {Length Ds}
                       TVars1   = {MakeList LDs}
                       TVars2   = {MakeList LDs}
                       TVars1_D = {ConvertToTuple D1|TVars1}
                       TVars2_D = {ConvertToTuple D2|TVars2}
                       TVars    = {ConvertToTuple D|Ds}
                    in
                       {`CDHeader` 1#1 B1#B2 TVars TVars1_D#TVars2_D}
                       {`GenSumCCD` Coeffs1 TVars1 Rel D1 B1}
                       {`GenSumCCD` Coeffs2 TVars2 Rel D2 B2}
                       {`CDBody` B1#B2 TVars TVars1_D#TVars2_D}
                    end
                 end
              end
   */
   GenSumAC = FDP.sumAC

   GenSumACN = proc{$  IIs DDs Rel D}
                  thread
                     Ds = {ConvertAll DDs}
                     Coeffs1 = {Convert IIs}
                     Coeffs2 = {Map Coeffs1 fun{$ X} ~X end}
                  in
                     case Rel == '=<:' orelse
                        Rel == '<:' orelse
                        Rel == '\\=:'
                     then
                        {`GenSumCN` Coeffs1 Ds Rel D}
                        {`GenSumCN` Coeffs2 Ds Rel D}
                     else
                        D1 D2 B1 B2
                        LDs      = {Length Ds}
                        TVars1   = {MakeList LDs}
                        TVars2   = {MakeList LDs}
                        {List.forAllInd TVars1
                         fun{$ I}
                            {MakeList {Length {Nth Ds I}}}
                         end}
                        {List.forAllInd TVars2
                         fun{$ I}
                            {MakeList {Length {Nth Ds I}}}
                         end}
                        TVars1_D = {ConvertToTuple D1|{FoldR TVars1 Append nil}}
                        TVars2_D = {ConvertToTuple D2|{FoldR TVars2 Append nil}}
                        TVars    = {ConvertToTuple D|{FoldR Ds Append nil}}
                     in
                        {`CDHeader` 1#1 B1#B2 TVars TVars1_D#TVars2_D}
                        {`GenSumCNCD` Coeffs1 TVars1 Rel D1 B1}
                        {`GenSumCNCD` Coeffs2 TVars2 Rel D2 B2}
                        {`CDBody` B1#B2 TVars TVars1_D#TVars2_D}
                     end
                  end
               end




   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% Reified constraints
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   GenSumR   = proc{$ X O D R}   {`::` 0#1 R} {FDP.sumR X O D R}     end
   GenSumCR  = proc{$ A X O D R} {`::` 0#1 R} {FDP.sumCR A X O D R}  end
   GenSumCNR = proc{$ A X O D R} {`::` 0#1 R} {FDP.sumCNR A X O D R} end

   IsFDB = {`Builtin` fdIs 2}
   local
      FDIntR    = FDP.intR
      proc {DoDoms Descr Ds B Propagator}
         Bs={Map Ds fun{$ D} D::Descr end}
      in
         {GenSumR Bs '=:' {Length Ds} B}
      end
   in
      proc {!`::R` Descr D B}
         {`::` 0#1 B}
         {FDDecl D}
         {FDIntR D Descr B}
      end

      proc {!`:::R` Descr Ds B}
         thread
            {DoDoms Descr {Convert Ds} B FDIntR}
         end
      end

   end

   local
      CardBI = FDP.card
   in
      proc {Card Low Ds Up B}
         thread
            {`::` 0#1 B}
            case  {IsFDB Low} then
               case {IsFDB Up}
               then case {IsLiteral Ds}
                    then
                       or B=1 Low=0 [] B=0 Low>:0 end
                    else
                       {CardBI {ConvertToTuple Ds} Low Up B}
                    end
               else
                  {`RaiseError`
                   kernel(type
                          'FD.reified.card'
                          [Low Ds Up B]
                          fd
                          1
                          'The lower limit of cardinality must be a finite domain.')}
               end
            else
               {`RaiseError`
                kernel(type
                       'FD.reified.card'
                       [Low Ds Up B]
                       fd
                       3
                       'The upper limit of cardinality must be a finite domain.')}
            end
         end
      end
   end


   local
      NegRelTable = negRelTable( '=:'   : '\\=:'
                                 '=<:'  : '>:'
                                 '<:'   : '>=:'
                                 '>=:'  : '<:'
                                 '>:'   : '=<:'
                                 '\\=:' : '=:'
                               )
   in
      GenSumACR = proc{$ IIs DDs Rel D B}
                     thread
                        NegRel  = NegRelTable.Rel
                        Ds      = {Convert DDs}
                        Coeffs1 = {Convert IIs}
                        Coeffs2 = {Map Coeffs1 fun {$ X} ~X end}
                     in
                        {`::` 0#1 B}
                        case Rel == '=<:' orelse
                           Rel == '<:' orelse
                           Rel == '\\=:'
                        then
                           or B=1
                              {`GenSumC` Coeffs1 Ds Rel D}
                              {`GenSumC` Coeffs2 Ds Rel D}
                           [] B=0 {`GenSumC` Coeffs1 Ds NegRel D}
                           [] B=0 {`GenSumC` Coeffs2 Ds NegRel D}
                           end
                        else
                           or B1 B2 D1 D2
                              LDs      = {Length Ds}
                              TVars1   = {MakeList LDs}
                              TVars2   = {MakeList LDs}
                              TVars1_D = {ConvertToTuple D1|TVars1}
                              TVars2_D = {ConvertToTuple D2|TVars2}
                              TVars    = {ConvertToTuple D|Ds}
                           in
                              B=1
                              {`CDHeader` 1#1 B1#B2 TVars TVars1_D#TVars2_D}
                              {`GenSumCCD` Coeffs1 TVars1 Rel D1 B1}
                              {`GenSumCCD` Coeffs2 TVars2 Rel D2 B2}
                              {`CDBody` B1#B2 TVars TVars1_D#TVars2_D}
                           [] B=0
                              {`GenSumC` Coeffs1 Ds NegRel D}
                              {`GenSumC` Coeffs2 Ds NegRel D}
                           end
                        end
                     end
                  end


      GenSumACNR = proc{$ IIs DDs Rel D B}
                      thread
                         NegRel  = NegRelTable.Rel
                         Ds = {ConvertAll DDs}
                         Coeffs1 = {Convert IIs}
                         Coeffs2 = {Map Coeffs1 fun{$ X} ~X end}
                      in
                         {`::` 0#1 B}
                         case Rel == '=<:' orelse
                            Rel == '<:' orelse
                            Rel == '\\=:'
                         then
                            or B=1
                               {`GenSumCN` Coeffs1 Ds Rel D}
                               {`GenSumCN` Coeffs2 Ds Rel D}
                            [] B=0 {`GenSumCN` Coeffs1 Ds NegRel D}
                            [] B=0 {`GenSumCN` Coeffs2 Ds NegRel D}
                            end
                         else
                            or
                               D1 D2 B1 B2
                               LDs      = {Length Ds}
                               TVars1   = {MakeList LDs}
                               TVars2   = {MakeList LDs}
                               {List.forAllInd TVars1
                                fun{$ I}
                                   {MakeList {Length {Nth Ds I}}}
                                end}
                               {List.forAllInd TVars2
                                fun{$ I}
                                   {MakeList {Length {Nth Ds I}}}
                                end}
                               TVars1_D = {ConvertToTuple D1|{FoldR TVars1 Append nil}}
                               TVars2_D = {ConvertToTuple D2|{FoldR TVars2 Append nil}}
                               TVars    = {ConvertToTuple D|{FoldR Ds Append nil}}
                            in
                               B=1
                               {`CDHeader` 1#1 B1#B2 TVars TVars1_D#TVars2_D}
                               {`GenSumCNCD` Coeffs1 {ConvertToTuple TVars1} Rel D1 B1}
                               {`GenSumCNCD` Coeffs2 {ConvertToTuple TVars2} Rel D2 B2}
                               {`CDBody` B1#B2 TVars TVars1_D#TVars2_D}
                            [] B=0
                               {`GenSumCN` Coeffs1 Ds NegRel D}
                               {`GenSumCN` Coeffs2 Ds NegRel D}
                            end
                         end
                      end
                   end

      DistanceR = proc{$ X Y Rel D B}
                     {GenSumACR [1 ~1] [X Y] Rel D B}
                  end
   end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %%  constructive disjunction
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   local
      FdPutList = {`Builtin` fdTellConstraintCD 3}
   in
      !`:::CD` = proc {$ Descr Ds C}
                    {ForAll {Convert Ds} proc{$ D}
                                            {FdPutList D Descr C}
                                         end}
                 end
      !`::CD` = proc {$ Descr D C}
                  {FdPutList D Descr C}
               end
   end



   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% Needed for compiler
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   !`GenSumR`   = proc{$ X O D R}   {`::` 0#1 R} {FDP.sumR X O D R}     end
   !`GenSumCR`  = proc{$ A X O D R} {`::` 0#1 R} {FDP.sumCR A X O D R}  end
   !`GenSumCNR` = proc{$ A X O D R} {`::` 0#1 R} {FDP.sumCNR A X O D R} end

   !`Lec`      = proc{$ X Y} {`::` 0#Y X} end
   !`Gec`      = proc{$ X Y} {`::` Y#FiniteDomainBound X} end
   !`PlusRel`  = FDP.plus_rel
   !`TimesRel` = FDP.times_rel
   !`Nepc`     = FDP.notEqOff
   !`Neq`      = proc {$ X Y} {FDP.notEqOff X Y 0} end
   !`Lepc`     = FDP.lessEqOff
   !`Nec`      = proc {$ X Y} {FDP.notEqOff X Y 0} end



   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% Scheduling (including also distribution strategies)
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   local
      CPIterate          = SchedLib.cpIterate
      Disjunctive        = SchedLib.disjunctive
      TaskInts           = SchedLib.taskIntervals
      CPIterateCap       = SchedLib.cpIterateCap
      CumulativeTIS      = SchedLib.cumulativeTI
      CPIterateCapUp     = SchedLib.cpIterateCapUp
   in
      proc {Serialized Tasks Start Dur}
         {CPIterate Tasks Start Dur}
      end

      proc {TaskIntervals Tasks Start Dur}
         {TaskInts Tasks Start Dur}
      end

      proc {SerializedDisj Tasks Start Dur}
         {Disjunctive Tasks Start Dur}
      end

      proc {CumulativeD Tasks Start Dur Use Capacities}
         {CPIterateCap Tasks Start Dur Use Capacities}
      end

      proc {CumulativeTI Tasks Start Dur Use Capacities}
         {CumulativeTIS Tasks Start Dur Use Capacities}
      end

      proc {CumulativeUp Tasks Start Dur Use Capacities}
         {CPIterateCapUp Tasks Start Dur Use Capacities}
      end
   end

   local
      FirstsLasts        = SchedLib.firstsLasts
      TaskIntervalsProof = SchedLib.taskIntervalsProof

      proc {Check Tasks Start Dur}
         {ForAll Tasks
          proc{$ Ts}
             case {IsList Tasks}
             then
                {ForAll Ts
                 proc{$ T}
                    case {HasFeature Start T} andthen
                       {HasFeature Dur T}
                    then skip
                    else
                       {`RaiseError`
                        fd(scheduling
                           'Check'
                           [Tasks Start Dur]
                           vector(vector)
                           1
                           'Scheduling applications expect that all task symbols are features of the records denoting the start times and durations.')}
                    end
                 end}
             end
          end}
         case {HasFeature Start pe} then skip
         else
            {`RaiseError`
             fd(scheduling
                'Check'
                [Tasks Start Dur]
                record
                2
                'For scheduling distribution, the record denoting the start times of tasks must contain the task 'pe'.') }
         end
         {Record.forAll Start
          proc{$ S}
             case {IsFDB S} then skip
             else
                {`RaiseError`
                 kernel(type
                        'Check'
                        [Tasks Start Dur]
                        record(fd)
                        2
                        'For scheduling applications the record denoting the start times must contain finite domains.')}
             end
          end}
         {Record.forAll Dur
          proc{$ D}
             case {IsInt D} then skip
             else
                {`RaiseError`
                 kernel(type
                        'Check'
                        [Tasks Start Dur]
                        record(int)
                        2
                        'For scheduling applications the record denoting the durations must contain integers.')}
             end
          end}
      end

      fun {MakeTaskTuple Ts}
         {ConvertToTuple {Map Ts ConvertToTuple}}
      end

      proc {EnumTI ETTuple Start Dur OldOut Stream}
         choice
            NewStream NewOut
         in
            Stream = dist(OldOut NewOut)|NewStream
            case NewOut
            of ~1 then
               %% finished
               NewStream = nil
            else
               Res#Left#Right = NewOut
               Tasks          = ETTuple.(Res+1)
               LeftTask       = Tasks.(Left+1)
               RightTask      = Tasks.(Right+1)
            in
               dis
                  Start.LeftTask + Dur.LeftTask =<: Start.RightTask
               then
                  {EnumTI ETTuple Start Dur Res#Left#Right NewStream}
               []
                  Start.RightTask + Dur.RightTask =<: Start.LeftTask
               then
                     {EnumTI ETTuple Start Dur Res#Right#Left NewStream}
               end
            end
         end
      end

      local
         proc {Before Task RT Tasks Start Dur}
            StartTask = Start.(Tasks.(Task+1))
            DurTask = Dur.(Tasks.(Task+1))
         in
            {ForAll RT proc{$ T}
                          case Task==T then skip
                          else StartTask+DurTask =<: Start.(Tasks.(1+T))
                          end
                       end}
         end

         proc {After Task RT Tasks Start Dur}
            StartTask = Start.(Tasks.(Task+1))
         in
            {ForAll RT proc{$ T}
                          case Task==T then skip
                          else Start.(Tasks.(1+T))+Dur.(Tasks.(1+T)) =<: StartTask
                          end
                       end}
         end
         fun {MinimalStartOrder Task1 Task2 Start Dur Tasks}
            Start1 = Start.(Tasks.(Task1+1))
            Start2 = Start.(Tasks.(Task2+1))
         in
            {FD.reflect.min Start1}<{FD.reflect.min Start2}
            orelse
            ({FD.reflect.min Start1}=={FD.reflect.min Start2}
             andthen
             {FD.reflect.max Start1}<{FD.reflect.max Start2})
         end

         fun {MinimalEndOrder Task1 Task2 Start Dur Tasks}
            Start1 = Start.(Tasks.(Task1+1))
            Start2 = Start.(Tasks.(Task2+1))
            Dur1 = Dur.(Tasks.(Task1+1))
            Dur2 = Dur.(Tasks.(Task2+1))
         in
            %% good for proof of optimality
            {FD.reflect.max Start1}+Dur1>{FD.reflect.max Start2}+Dur2
            orelse
            ({FD.reflect.max Start1}+Dur1=={FD.reflect.max Start2}+Dur2
             andthen
             {FD.reflect.min Start1}+Dur1>{FD.reflect.min Start2}+Dur2)
         end

         proc {Try FLs RestTasks Mode Tasks ETTuple Start Dur Stream}
            choice
               case FLs of nil then
                  fail
               [] H|T then
                  case T
                  of nil then
                     case Mode of firsts then
                        {Before H RestTasks Tasks Start Dur}
                     else
                        {After H RestTasks Tasks Start Dur}
                     end
                     {EnumFL ETTuple Start Dur '#'(H) Stream}
                  else
                     choice
                        case Mode of firsts then
                           {Before H RestTasks Tasks Start Dur}
                        else {After H RestTasks Tasks Start Dur}
                        end
                        {EnumFL ETTuple Start Dur '#'(H) Stream}
                     []
                        {Try T RestTasks Mode Tasks ETTuple Start Dur Stream}
                     end
                  end
               end
            end
         end

      in
         proc {EnumFL ETTuple Start Dur OldOut Stream}
            choice
               NewStream NewOut
            in
               Stream = dist(OldOut NewOut)|NewStream
               case NewOut
               of finished then
                  NewStream = nil
               else
                  Mode#FL#RestTasks#Res = NewOut
                  Tasks                 = ETTuple.(Res+1)
                  Sorted = case Mode
                           of firsts
                           then {Sort FL fun{$ X Y}
                                            {MinimalStartOrder X Y Start Dur Tasks}
                                         end}
                           else {Sort FL fun{$ X Y}
                                            {MinimalEndOrder X Y Start Dur Tasks}
                                         end}
                           end
               in
                  {Try Sorted RestTasks Mode Tasks ETTuple Start Dur NewStream}
               end
            end
         end
      end

      proc {HelpDist Dist Enum Tasks Start Dur Flag}
         Stream
         Converted = {ConvertAll Tasks}
         TaskTuple = {MakeTaskTuple Tasks}
      in
         {Check Converted Start Dur}
         {Dist TaskTuple Start Dur Stream Flag}
         {Enum TaskTuple Start Dur nil Stream}
      end
   in
      proc {TaskIntervalsDistO Tasks Start Dur}
         {HelpDist TaskIntervalsProof EnumTI Tasks Start Dur 1}
      end

      proc {TaskIntervalsDistP Tasks Start Dur}
         {HelpDist TaskIntervalsProof EnumTI Tasks Start Dur 0}
      end

      proc {NewDistFL Tasks Start Dur}
         {HelpDist FirstsLasts EnumFL Tasks Start Dur 0}
      end

      proc {NewDistF Tasks Start Dur}
         {HelpDist FirstsLasts EnumFL Tasks Start Dur 1}
      end

      proc {NewDistL Tasks Start Dur}
         {HelpDist FirstsLasts EnumFL Tasks Start Dur 2}
      end

   end


   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %% Distribution
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   local

      local
         proc {ListToTuple Xs I T}
            case Xs of nil then skip
            [] X|Xr then
               case {IsFDB X} then T.I=X {ListToTuple Xr I+1 T}
               else
                  {`RaiseError`
                   kernel(type
                          'ListToTuple'
                          [Xs I T]
                          list(fd)
                          1
                          'For FD.distribute and FD.choose, the vector to distribute must contain finite domains.')}
               end
            end
         end

         proc {TupleToTuple T1 I T2}
            case I==0 then skip
            else X=T1.I in
               case {IsFDB X} then X=T2.I {TupleToTuple T1 I-1 T2}
               else
                  {`RaiseError`
                   kernel(type
                          'TupleToTuple'
                          [T1 I T2]
                          list(fd)
                          1
                          'For FD.distribute and FD.choose, the vector to distribute must contain finite domains.')}
               end
            end
         end

         proc {RecordToTuple As R I T}
            case As of nil then skip
            [] A|Ar then X=R.A in
               case {IsFDB X} then X=T.I {RecordToTuple Ar R I+1 T}
               else
                  {`RaiseError`
                   kernel(type
                          'RecordToTuple'
                          [As R I T]
                          list(fd)
                          1
                          'For FD.distribute and FD.choose, the vector to distribute must contain finite domains.')}
               end
            end
         end
      in
         proc {MakeDistrTuple V ?T}
            case V of _|_ then
               T={MakeTuple '#' {Length V}} {ListToTuple V 1 T}
            elsecase {IsRecord V} then W={Width V} in
               T={MakeTuple '#' W}
               case {IsTuple V} then {TupleToTuple V W T}
               else {RecordToTuple {Arity V} V 1 T}
               end
            else
               {`RaiseError`
                kernel(type
                       'MakeDistrTuple'
                       [V T]
                       vector
                       1
                       'For FD.distribute and FD.choose, the input argument must be a vector.')}
            end
         end
      end

      local
         DistGenFast = {`Builtin` fddistribute 5}
      in
         proc {DistrFast T Order Value}
            DistrVar DistrVal
         in
            {DistGenFast T Order Value ?DistrVar ?DistrVal}
            case DistrVal of ~1 then skip else
               choice
                  DistrVar=DistrVal
                  choice {DistrFast T Order Value} end
               [] {`Nec` DistrVar DistrVal}
                  choice {DistrFast T Order Value} end
               end
            end
         end

         proc {ChooseFast T Order Value ?Selected ?Spec}
            {DistGenFast T Order Value ?Selected ?Spec}
            case Spec of ~1 then
               {`RaiseError`
                fd(noChoice
                   'FD.choose'
                   [T Order Value Selected Spec]
                   1
                   'The vector to choose from does not contain non-determined elements.')}
            else skip
            end
         end

         proc {DistrFF T}
            DistrVar DistrVal
         in
            {DistGenFast T size min ?DistrVar ?DistrVal}
            case DistrVal of ~1 then skip else
               choice
                  DistrVar=DistrVal
                  choice {DistrFF T} end
               [] {`Nec` DistrVar DistrVal}
                     choice {DistrFF T} end
               end
            end
         end

         proc {ChooseFF T ?Selected ?Spec}
            {DistGenFast T size min ?Selected ?Spec}
            case Spec of ~1 then
               {`RaiseError`
                fd(noChoice
                   'FD.choose'
                   [T Selected Spec]
                   1
                   'The vector to choose from does not contain non-determined elements.')}
            else skip
            end
         end

         proc {DistrNaive T}
            DistrVar DistrVal
         in
            {DistGenFast T naive min ?DistrVar ?DistrVal}
            case DistrVal of ~1 then skip else
               choice
                  DistrVar=DistrVal
                  choice {DistrNaive T} end
               [] {`Nec` DistrVar DistrVal}
                  choice {DistrNaive T} end
                  end
            end
         end

         proc {ChooseNaive T ?Selected ?Spec}
            {DistGenFast T naive min ?Selected ?Spec}
            case Spec of ~1 then
               {`RaiseError`
                fd(noChoice
                   'FD.choose'
                   [T Selected Spec]
                   1
                   'The vector to choose from does not contain non-determined elements.')}
            else skip
            end
         end

         proc {DistrFastSplitMin T Order}
            DistrVar DistrVal
         in
            {DistGenFast T Order mid ?DistrVar ?DistrVal}
            case DistrVal of ~1 then skip else
               choice
                  {`Lec` DistrVar DistrVal}
                  choice {DistrFastSplitMin T Order} end
               [] {`Gec` DistrVar DistrVal+1}
                  choice {DistrFastSplitMin T Order} end
               end
            end
         end

         proc {ChooseFastSplitMin T Order ?Selected ?Spec}
            Val = {DistGenFast T Order mid ?Selected}
         in
            case Val of ~1 then
               {`RaiseError`
                fd(noChoice
                   'FD.choose'
                   [T Order Selected Spec]
                   1
                   'The vector to choose from does not contain non-determined elements.')}
            else Spec = 0#Val
            end
         end

         proc {DistrFastSplitMax T Order}
            DistrVar DistrVal
         in
            {DistGenFast T Order mid ?DistrVar ?DistrVal}
            case DistrVal of ~1 then skip else
               choice
                  {`Gec` DistrVar DistrVal+1}
                  choice {DistrFastSplitMax T Order} end
               [] {`Lec` DistrVar DistrVal}
                  choice {DistrFastSplitMax T Order} end
               end
            end
         end

         proc {ChooseFastSplitMax T Order ?Selected ?Spec}
            Val = {DistGenFast T Order mid ?Selected}
         in
            case Val of ~1 then
               {`RaiseError`
                fd(noChoice
                   'FD.choose'
                   [T Order Selected Spec]
                   1
                   'The vector to choose from does not contain non-determined elements.')}
            else Spec = (Val+1)#FD.sup
            end
         end
      end

      %%
      %% The generic part of distribution
      %%
      fun {Choose Xs Y Order}
         case Xs of nil then Y
         [] X|Xr then {Choose Xr case {Order X Y} then X else Y end Order}
         end
      end

      %%
      %% Order for distribution
      %%
      fun {OrderNaive _ _}
         false
      end

      fun {OrderSize X Y}
         {GetSize X} < {GetSize Y}
      end

      fun {OrderNbSusps X Y}
         L1={System.nbSusps X} L2={System.nbSusps Y}
      in
         L1>L2 orelse
         (L1==L2 andthen
          local S1={GetSize X} S2={GetSize Y} in S1<S2 end)
      end

      fun {OrderMin X Y}
         {GetMin X} < {GetMin Y}
      end

      fun {OrderMax X Y}
         {GetMax X} > {GetMax Y}
      end

      %%
      %% Selection for distribution
      %%
      fun {SelectId X}
         X
      end

      %%
      %% Filtering for distribution
      %%
      fun {FilterUnDet X}
         {GetSize X} > 1
      end

      %%
      %% Value distribution
      %%
      proc {ValueMin X Xs Cont Proc}
         {Proc}

         choice
            Min={GetMin X}
         in
            choice X=Min
               choice {Cont Xs} end
            []  {`Nec` X Min}
               choice {Cont Xs} end
            end
         end
      end

      proc {ValueMid X Xs Cont Proc}
         {Proc}

         choice
            Mid={GetMid X}
         in
            choice X=Mid
               choice {Cont Xs} end
            []  {`Nec` X Mid}
               choice {Cont Xs} end
            end
         end
      end

      proc {ValueMax X Xs Cont Proc}
         {Proc}

         choice
            Max={GetMax X}
         in
            choice  X=Max
               choice {Cont Xs} end
            []  {`Nec` X Max}
               choice {Cont Xs} end
            end
         end
      end

      proc {ValueSplitMin X Xs Cont Proc}
         {Proc}

         choice
            Mid={GetMid X}
         in
            choice {`Lec` X Mid}
               choice {Cont Xs} end
            []    {`Gec` X Mid+1}
               choice {Cont Xs} end
            end
         end
      end

      proc {ValueSplitMax X Xs Cont Proc}
         {Proc}

         choice
            Mid={GetMid X}
         in
            choice  {`Gec` X Mid+1}
               choice {Cont Xs} end
            []   {`Lec` X Mid}
               choice {Cont Xs} end
            end
         end
      end

      fun {SelectValueMin S} {GetMin S} end
      fun {SelectValueMax S} {GetMax S} end
      fun {SelectValueMid S} {GetMid S} end
      fun {SelectValueSplitMin S} 0#{GetMid S} end
      fun {SelectValueSplitMax S} ({GetMid S}+1)#FiniteDomainBound end

      fun {DoChoose Xs FilterDistr SelectDistr OrderDistr}
         case {Filter Xs FilterDistr}
         of nil then
            {`RaiseError`
             fd(noChoice
                'FD.choose'
                [Xs FilterDistr SelectDistr OrderDistr]
                1
                'The vector to choose from does not contain non-determined elements.')}
            _
         elseof Xs=X|Xr then
            {SelectDistr {Choose Xr X OrderDistr}}
         end
      end
   in
      proc {Distribute Dist Vector}
         choice
            case Dist
            of naive then
               {DistrNaive {MakeDistrTuple Vector}}
            [] ff    then
               {DistrFF {MakeDistrTuple Vector}}
            [] split then
               {DistrFastSplitMin {MakeDistrTuple Vector} size}
            elsecase {Label Dist}
            of generic then
               OrderSpec  = {CondSelect Dist order  size}
               FilterSpec = {CondSelect Dist filter undet}
               SelectSpec = {CondSelect Dist select id}
               ValueSpec  = {CondSelect Dist value  min}
               ProcSpec   = {CondSelect Dist procedure noProc}
            in
               case
                  SelectSpec==id andthen FilterSpec==undet andthen
                  {Member OrderSpec [size naive nbSusps min max]} andthen
                  {Member ValueSpec [min max mid splitMin splitMax]} andthen
                  ProcSpec == noProc
               then
                  % no proc
                  case ValueSpec
                  of splitMin then
                     {DistrFastSplitMin {MakeDistrTuple Vector} OrderSpec}
                  [] splitMax then
                     {DistrFastSplitMax {MakeDistrTuple Vector} OrderSpec}
                  else
                     {DistrFast {MakeDistrTuple Vector} OrderSpec ValueSpec}
                  end
               else
                  % with proc
                  OrderDistr  = case OrderSpec
                                of size        then OrderSize
                                [] naive       then OrderNaive
                                [] nbSusps     then OrderNbSusps
                                [] min         then OrderMin
                                [] max         then OrderMax
                                else OrderSpec
                                end
                  FilterDistr = case FilterSpec
                                of undet then FilterUnDet
                                else FilterSpec
                                end
                  SelectDistr = case SelectSpec
                                of id then SelectId
                                else SelectSpec
                                end
                  ValueDistr  = case ValueSpec
                                of min      then ValueMin
                                [] max      then ValueMax
                                [] mid      then ValueMid
                                [] splitMin then ValueSplitMin
                                [] splitMax then ValueSplitMax
                                else ValueSpec
                                end
                  ProcDistr = case ProcSpec
                              of noProc then proc {$} skip end
                              else ProcSpec
                              end

                  proc {DoDistribute Xs }
                     case {Filter Xs FilterDistr}
                     of nil then skip
                     elseof Xs=X|Xr then
                        {ValueDistr {SelectDistr {Choose Xr X OrderDistr}}
                         Xs DoDistribute ProcDistr}
                     end
                  end
               in
                  {DoDistribute {Convert Vector}}
               end
            else
               {`RaiseError`
                kernel(type
                       'FD.distribute'
                       [Dist Vector]
                       fdDistrDesc
                       1
                       'Incorrect specification for distribution.')}
            end
         end
      end

      proc {FDChoose Dist Vector ?Selected ?Spec}
         choice
            case Dist
            of naive then
               {ChooseNaive {MakeDistrTuple Vector} Selected Spec}
            [] ff    then
               {ChooseFF {MakeDistrTuple Vector} Selected Spec}
            [] split then
               {ChooseFastSplitMin {MakeDistrTuple Vector} size Selected Spec}
            elsecase {Label Dist}
            of generic then
               OrderSpec   = {CondSelect Dist order  size}
               FilterSpec  = {CondSelect Dist filter undet}
               SelectSpec  = {CondSelect Dist select id}
               ValueSpec   = {CondSelect Dist value  min}
            in
               case
                  SelectSpec==id andthen FilterSpec==undet andthen
                  {Member OrderSpec [size naive nbSusps min max]} andthen
                  {Member ValueSpec [min max mid splitMin splitMax]}
               then
                  case ValueSpec
                  of splitMin then
                     {ChooseFastSplitMin {MakeDistrTuple Vector} OrderSpec Selected Spec}
                  [] splitMax then
                     {ChooseFastSplitMax {MakeDistrTuple Vector} OrderSpec Selected Spec}
                  else
                     {ChooseFast {MakeDistrTuple Vector} OrderSpec ValueSpec Selected Spec}
                  end
               else
                  OrderDistr  = case OrderSpec
                                of size        then OrderSize
                                [] naive       then OrderNaive
                                [] nbSusps     then OrderNbSusps
                                [] min         then OrderMin
                                [] max         then OrderMax
                                else OrderSpec
                                end
                  FilterDistr = case FilterSpec
                                of undet then FilterUnDet
                                else FilterSpec
                                end
                  SelectDistr = case SelectSpec
                                of id then SelectId
                                else SelectSpec
                                end
                  ValueSelect = case ValueSpec
                                of min      then SelectValueMin
                                [] max      then SelectValueMax
                                [] mid      then SelectValueMid
                                [] splitMin then SelectValueSplitMin
                                [] splitMax then SelectValueSplitMax
                                else ValueSpec
                                end
               in
                  Selected = {DoChoose {Convert Vector} FilterDistr SelectDistr OrderDistr}
                  Spec     = {ValueSelect Selected}
               end
            else
               {`RaiseError`
                kernel(type
                       'FD.distribute'
                       [Dist Vector]
                       fdDistrDesc
                       1
                       'Incorrect specification for distribution.')}
            end
         end
      end

   end

in

   FD=fd(
          %% Telling Domains
          int:         `::`
          dom:         `:::`
          decl:        FDDecl
          list:        ListDef
          tuple:       TupleDef
          record:      RecordDef

          %% Reflection
          reflect: reflect(min:           GetMin
                           mid:           GetMid
                           max:           GetMax
                           nextLarger:    {`Builtin` fdGetNextLarger  3}
                           nextSmaller:   {`Builtin` fdGetNextSmaller 3}
                           size:          GetSize
                           nbSusps:       System.nbSusps
                           domList:       GetFiniteDomain
                           dom:           GetDomCompact)

          %% Watching Domains
          watch: watch(size:  {`Builtin` fdWatchSize 3}
                       min:   {`Builtin` fdWatchMin  3}
                       max:   {`Builtin` fdWatchMax  3})

          %% Generic Propagators
          sum:         FDP.sum = `GenSum`
          sumC:        FDP.sumC = `GenSumC`
          sumCN:       FDP.sumCN = `GenSumCN`
          sumAC:       GenSumAC
          sumACN:      GenSumACN
          sumD:        FDP.dsum
          sumCD:       FDP.dsumC

          %% Symbolic Propagators
          distinct:       FDP.distinct
          distinctD:      FDP.distinctD
          distinctOffset: FDP.distinctOffset
          atMost:         FDP.atMost
          atLeast:        FDP.atLeast
          exactly:        FDP.exactly
          element:        FDP.element

          %% 0/1 Propagators
          conj:           FDP.conj
          disj:           FDP.disj
          nega:           FDP.nega
          exor:           FDP.exor
          impl:           FDP.impl
          equi:           FDP.equi

          %% Reified Propagators
          reified: reified(int:        `::R`
                           dom:        `:::R`
                           sum:        GenSumR
                           sumC:       GenSumCR
                           sumCN:      GenSumCNR
                           sumAC:      GenSumACR
                           sumACN:     GenSumACNR
                           distance:   DistanceR
                           card:       Card)

          %% Miscellaneous Propagators
          plus:        FDP.plus
          minus:       FDP.minus
          times:       FDP.times
          power:       FDP.power
          divI:        FDP.divI
          divD:        FDP.divD
          modI:        FDP.modI
          modD:        FDP.modD
          max:         FDP.maximum
          min:         FDP.minimum
          distance:    FDP.distance
          less:        proc {$ X Y} {`Lepc` X Y ~1} end
          greater:     proc {$ X Y} {`Lepc` Y X ~1} end
          lesseq:      proc {$ X Y} {`Lepc` X Y 0} end
          greatereq:   proc {$ X Y} {`Lepc` Y X 0} end
          disjointC:   proc {$ X XD Y YD C}
                          {`::` 0#1 C}
                          {FDP.disjointC X XD Y YD C}
                       end
          disjoint:    FDP.disjoint

          %% Scheduling
          schedule: schedule(serialized:            Serialized
                             serializedDisj:        SerializedDisj
                             disjoint:              SchedLib.disjoint_card
%                            cumulativeI:           CumulativeI
                             taskIntervals:          TaskIntervals
                             cumulative:            CumulativeD
                             cumulativeTI:          CumulativeTI
                             cumulativeUp:          CumulativeUp
                             taskIntervalsDistP:    TaskIntervalsDistP
                             taskIntervalsDistO:    TaskIntervalsDistO
                             firstsLastsDist:       NewDistFL
                             firstsDist:            NewDistF
                             lastsDist:             NewDistL
                            )

          %% Distribution
          distribute:  Distribute
          choose:     FDChoose

          %% Miscellaneous
          sup: FiniteDomainBound
          is:  IsFDB
        )

   _ = {FDP.init}

end
