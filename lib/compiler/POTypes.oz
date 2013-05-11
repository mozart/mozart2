%%%
%%% Author:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Martin Mueller, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%%
%%% when a new data type is added, edit
%%%  OzTypes (definition of the partial order)
%%%  OzValueToType
%%% define corresponding token classes in CoreLanguage.oz
%%% and edit the method valToSubst in StaticAnalysis.oz
%%%  such that it uses the extended core language definition
%%%

local

   %% add to list if no duplicate
   fun {Add X Ys}
      if {Member X Ys} then Ys else X|Ys end
   end

   %% get list of sort names mentioned
   %% in Ord (no duplicates)
   fun {GetNames Ord}
      {FoldR Ord
       fun {$ A#B I} {Add A {Add B I}} end
       nil}
   end

\ifdef HAS_CSS
   proc {PartialOrder Ord Def ?Name2Lists ?Name2Index}

      Names = {GetNames Ord}
      N     = {Length Names}

      %% define mapping names -> indexes
      proc {IdxMapping N2I}
         N2I = {FD.record n2i Names 1#N}

         %% numbering must respect the partial order
         {ForAll Ord
          proc {$ A#B}
             {FD.less N2I.B N2I.A}
          end}

         %% numbering must be one-one
         {FD.distinct N2I}

         %% go
         {FD.distribute naive N2I}
      end

      % define mapping names -> bit arrays
      proc {SetMapping ?N2S}
         N2S = {Record.make n2s Names}

         % for propagation purposes,
         % each sort is encoded as a subset of {1..N}
         % including the index of the sort (open world!)
         {ForAll Names
          proc {$ X}
             SX = {FS.var.upperBound [1#N]}
          in
             N2S.X = SX
             {FS.include Name2Index.X SX}
          end}

         % set encoding must respect partial ordering
         {ForAll Ord
          proc {$ A#B}
             {FS.subset N2S.A N2S.B}
          end}

         % minimize set values after proPagation
         {ForAll Names
          proc {$ Nam}
             S = N2S.Nam
          in
             {Space.waitStable}
             S = {FS.value.make {FS.reflect.lowerBound S}}
          end}
      end

      Name2Sets
   in
      % compute mapping (basic) names <-> indexes
      Name2Index = {Search.base.one IdxMapping}.1
      % compute mapping (basic) names <-> sets
      Name2Sets = {Search.base.one SetMapping}.1
      % compute mapping (basic) names <-> lists of integers
      Name2Lists = {Record.map Name2Sets FS.monitorIn}
   end
\else
   Set = set(
      new: NewDictionary
      member: Dictionary.member
      include: proc {$ S X} {Dictionary.put S X unit} end
      exclude: Dictionary.remove
      isEmpty: Dictionary.isEmpty
      putAll: proc {$ S Xs}
                 {ForAll Xs proc {$ X} {Dictionary.put S X unit} end}
              end
      toList: Dictionary.keys
   )

   proc {PartialOrder Ord Def ?Name2Lists ?Name2Index}
      Names = {GetNames Ord}
      N = {Length Names}
      Index2Name

      proc {Assign_Index2Name_And_Name2Index_Through_TopologicalSort}
         !Index2Name = {MakeTuple i2n N}
         !Name2Index = {MakeRecord n2i Names}

         GraphAsDictOfIngoingEdges = {NewDictionary}
         {ForAll Names
          proc {$ Name}
             {Dictionary.put GraphAsDictOfIngoingEdges Name {Set.new}}
          end}

         WithNoOutgoingEdge = {Set.new}
         {Set.putAll WithNoOutgoingEdge Names}

         Visited = {Set.new}
         NextIndex = {NewCell 1}

         proc {GetNextIndex ?I}
            I = @NextIndex
            NextIndex := I + 1
         end

         {ForAll Ord
          proc {$ SubType#SuperType}
             IngoingEdges = {Dictionary.get GraphAsDictOfIngoingEdges SuperType}
          in
             {Set.include IngoingEdges SubType}
             {Set.exclude WithNoOutgoingEdge SubType}
          end}

         proc {Visit Name}
            if {Not {Set.member Visited Name}} then
               IngoingEdges
               Index
            in
               {Set.include Visited Name}

               IngoingEdges = {Dictionary.get GraphAsDictOfIngoingEdges Name}
               {ForAll {Set.toList IngoingEdges} Visit}

               Index = {GetNextIndex}
               Index2Name.Index = Name
               Name2Index.Name = Index
            end
         end
      in
         {ForAll {Set.toList WithNoOutgoingEdge} Visit}
      end

      proc {Assign_Name2Lists}
         Name2Bits = {MakeRecord n2b Names}
      in
         Name2Lists = {MakeRecord n2s Names}

         {For 1 N 1
          proc {$ I}
             Name = Index2Name.I
             Bits = {BitArray.new 1 N}
          in
             {BitArray.set Bits I}
             {ForAll Ord
              proc {$ SubType#SuperType}
                 if SuperType == Name then
                    {BitArray.disj Bits Name2Bits.SubType}
                 end
              end}
             Name2Bits.Name = Bits
             Name2Lists.Name = {BitArray.toList Bits}
          end}
      end
   in
      {Assign_Index2Name_And_Name2Index_Through_TopologicalSort}
      {Assign_Name2Lists}
   end
\endif

   fun {MkPartialOrder Name2Lists Name2Index DefinedNames}

      Names    = {Arity Name2Lists}
      N        = {Width Name2Lists}
      AllNames = {Append {Map DefinedNames fun {$ def(N _)} N end} Names}

      % compute mapping index <-> sort name
      Index2Name = {Tuple.make i2n {Width Name2Index}}

      {ForAll Names
       proc {$ Nam}
          Index2Name.(Name2Index.Nam) = Nam
       end}

      % each sort (basic or not) is represented as bit array
      Name2Bits = {Record.make n2b AllNames}

      {Record.forAll Name2Bits
       proc {$ B} B = {BitArray.new 1 N} end}

      {ForAll Names
       proc {$ Nam}
          {For 1 N 1
           proc {$ I}
              if {Member I Name2Lists.Nam}
              then {BitArray.set Name2Bits.Nam I}
              else skip end
           end}
       end}

      % encodes type: V Pos and not & Neg
      proc {Constrain Pos Neg S}
         if {IsAtom Pos}
         then {BitArray.disj S Name2Bits.Pos}
         else {ForAll Pos
               proc {$ P}
                  if {HasFeature Name2Bits P}
                  then {BitArray.disj S Name2Bits.P}
                  else {Exception.raiseError compiler(internal constrain)}
                  end
               end}
         end
         {ForAll Neg
          proc {$ N}
             if {HasFeature Name2Bits N}
             then {BitArray.nimpl S Name2Bits.N}
             else {Exception.raiseError compiler(internal contrain)} end
          end}
      end

      proc {Encode Pos Neg ?S}
         if Pos==nil
         then {Exception.raiseError compiler(internal illegalType)}
         else S = {BitArray.new 1 N} {Constrain Pos Neg S} end
      end

      % return best upper approximation of type
      local
         fun {DecodeAux S}
            case {BitArray.toList S} % BitArray.min waere nett
            of nil then nil
            elseof I|_ then
               N = Index2Name.I
            in
               {BitArray.nimpl S Name2Bits.N}
               N | {DecodeAux S}
            end
         end
      in
         fun {Decode S}
            if {IsFree S}
            then [value]
            else {DecodeAux {BitArray.clone S}}
            end
         end
      end

   in

      % add defined names
      {ForAll DefinedNames
       proc {$ def(N Ns)}
          if {Member N Names}
          then {Exception.raiseError
                compiler(internal illegalPartialOrderSpecification)}
          else Name2Bits.N = {Constrain Ns nil}
          end
       end}

      po(encode:    Encode
         decode:    Decode
         decl:      fun {$} {BitArray.new 1 N} end
         isMinimal: fun {$ T} {BitArray.card T} == 1 end
         constrain: BitArray.conj
         clash:     BitArray.disjoint
         clone:     BitArray.clone
         toList:    fun {$ T}
                       {Map {BitArray.toList T} fun {$ I} Index2Name.I end}
                    end
        )

   end

   % inclusion subtypes
   OzInclusions
   = ['thread' # value
      space  # value
      chunk  # value
      cell   # value
      foreignPointer # value
      fset   # value
      recordC# value
      record # recordC
      number # value
      int    # number
      float  # number
      char   # fdIntC
      fdIntC # int
      tuple  # record
      literal# tuple
      atom   # literal
      name   # literal
      nilAtom# atom
      cons   # tuple
      bool   # name
      'unit' # name
      bitArray # chunk
      array  # chunk
      dictionary # chunk
      'class'# chunk
      'object'# chunk
      'lock'   # chunk
      port   # chunk
      'procedure/0' # value
      'procedure/1'   # value
      'procedure/2'  # value
      'procedure/3' # value
      'procedure/4' # value
      'procedure/5' # value
      'procedure/6' # value
      'procedure/>6'   # value
      pair # tuple
      bitString # value
      byteString # value
     ]

   % partitioned subtypes
   OzDefinedNames
   = [def(feature           [int literal])
      def(comparable        [number atom])
      def(recordOrChunk     [record chunk])
      def(recordCOrChunk    [recordC chunk])
      def(list              [nilAtom cons])
      def(string            [nilAtom cons])
      def(procedure         ['procedure/0'
                             'procedure/1'
                             'procedure/2'
                             'procedure/3'
                             'procedure/4'
                             'procedure/5'
                             'procedure/6'
                             'procedure/>6'])
      def(virtualString     [number record byteString])
      def(procedureOrObject [procedure object])
      def(unaryProcOrObject ['procedure/1' object])
     ]

   OzPartialOrderAsSets
   OzName2Index

in

   {PartialOrder OzInclusions OzDefinedNames
    OzPartialOrderAsSets
    OzName2Index}

   fun {MkOzPartialOrder}
      {MkPartialOrder OzPartialOrderAsSets OzName2Index OzDefinedNames}
   end
end
