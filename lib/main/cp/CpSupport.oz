%%%
%%% Authors:
%%%   Joerg Wuertz (wuertz@dfki.de)
%%%   Tobias Mueller (tmueller@ps.uni-sb.de)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor

prepare

   R2L = Record.toList

   %%
   %% Vector conversion
   %%

   fun {VectorToType V}
      if {IsList V}       then list
      elseif {IsTuple V}  then tuple
      elseif {IsRecord V} then record
      else
         {Exception.raiseError
          kernel(type VectorToType [V] vector 1
                 'Vector as input argument expected.')} illegal
      end
   end

   fun {VectorToList V}
      if {VectorToType V}==list then V
      else {R2L V}
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
         if L=<U then L|{ExpandPair L+1 U Xs} else Xs end
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
      = bi(twice:         [twice           ['FD.plus' 'FD.minus']]
           square:        [square          ['FD.times']]
           plus:          ['FD.plus'           ['FD.distance']]
           plus_rel:      ['FD.plus'           ['FD.distance' '+']]
           minus:         ['FD.minus'          nil]
           times:         ['FD.times'          nil]
           times_rel:     ['FD.plus'           ['FD.distance' '*']]
           divD:          ['FD.divD'           nil]
           divI:          ['FD.divI'           nil]
           modD:          ['FD.modD'           nil]
           modI:          ['FD.modI'           nil]
           conj:          ['FD.conj'           nil]
           disj:          ['FD.disj'           nil]
           exor:          ['FD.exor'           nil]
           impl:          ['FD.impl'           nil]
           equi:          ['FD.equi'           nil]
           nega:          ['FD.nega'           ['FD.exor' 'FD.impl' 'FD.equi']]
           sumCR:         ['FD.reified.sumC'   ArithOps]
           intR:          ['FD.refied.int'     ['FD.reified.dom']]
           card:          ['FD.reified.card'   nil]
           exactly:       ['FD.exactly'        nil]
           atLeast:       ['FD.atLeast'        nil]
           atMost:        ['FD.atMost'         nil]
           element:       ['FD.element'        nil]
           disjoint:      ['FD.disjoint'       nil]
           disjointC:     ['FD.disjointC'      nil]
           distance:      ['FD.distance'       nil]
           notEqOff:      [notEqOff        ['FD.sumC' '\\=:']]
           lessEqOff:     ['FD.lesseq'         ['FD.sumC' '=<:' '<:' '>=:'
                                                    '>:' 'FD.min' 'FD.max'
                                                    'FD.modD'
                                                    'FD.modI' 'FD.disjoint'
                                                    'FD.disjointC' 'FD.distance'
                                                   ]]
           minimum:        ['FD.min'                   nil]
           maximum:        ['FD.max'                   nil]
           inter:          ['FD.inter'                 nil]
           union:          ['FD.union'                 nil]
           distinct:       ['FD.distinct'              nil]
           distinctOffset: ['FD.distinctOffset'        nil]
           subset:         [subset         ['FD.union' 'FD.inter']]
           sumC:           ['FD.sumC'          'FD.sumCN'|'FD.reified.sumC'|ArithOps]
           sumCN:          ['FD.sumCN'         ArithOps]
           sumAC:          ['FD.sumAC'         nil]

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
           sumCD:              [sumCD          ['condis ... end']]
           sumCCD:             [sumCCD         ['condis ... end']]
           sumCNCD:            [sumCNCD        ['condis ... end']]
          )

      fun {BIPrintName X}
         if {IsAtom X} andthen {HasFeature BuiltinNames X} then
            BuiltinNames.X.1
         else X
         end
      end

      fun {BIOrigin X}
         BuiltinNames.X.2.1
      end

   in

      fun {FormatOrigin A}
         B = {BIPrintName A}
      in
         if {HasFeature BuiltinNames B} andthen {BIOrigin B}\=nil then
            [unit
             hint(l:'Possible origin of procedure' m:oz({BIPrintName B}))
             line(oz({BIOrigin B}))]
         else nil
         end
      end
   end

export
   formatOrigin:   FormatOrigin

   waitStable:     WaitStable

   vectorToType:   VectorToType
   vectorToList:   VectorToList
   vectorsToLists: VectorsToLists
   vectorToTuple:  VectorToTuple

   expand:         Expand

   cloneList:      CloneList

end
