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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   % add to list if no duplicate
   fun {Add X Ys}
      case {Member X Ys} then Ys else X|Ys end
   end

   % get list of sort names mentioned
   % in Ord (no duplicates)
   fun {GetNames Ord}
      {FoldR Ord
       fun {$ A#B I} {Add A {Add B I}} end
       nil}
   end

   fun {PartialOrder Ord Def}

      Names = {GetNames Ord}
      N     = {Length Names}
      Defd  = {Map Def fun {$ def(DN _)} DN end}
      Types = {Append Names Defd}

      % define mapping names -> indexes
      proc {IdxMapping N2I}
         N2I = {Record.make n2i Names}

         % each name receives an integer between 1 and N
         {Record.forAll N2I
          proc {$ A}
             A = {FD.int 1#N}
          end}

         % numbering must respect the partial order
         {ForAll Ord
          proc {$ A#B}
             {FD.less N2I.B N2I.A}
          end}

         % numbering must be one-one
         {FD.distinct N2I}

         % go
         {FD.distribute naive N2I}
      end

      % define mapping names -> bit arrays
      proc {BitMapping N2B}
         N2S = {Record.make n2s Types}
      in
         N2B = {Record.make n2b Types}

         % ultimately, each sort is represented as bit array

         {Record.forAll N2B
          proc {$ B} B = {BitArray.new 1 N} end}

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
             choice
                S = {FS.value.new {FS.reflect.lowerBound S}}
                {Loop.for 1 N 1
                 proc {$ I}
                    case {FS.isIn I S}
                    then {BitArray.set N2B.Nam I}
                    else skip end
                 end}
             end
          end}
      end

      % compute mapping names <-> indexes
      Name2Index = {SearchOne IdxMapping}.1
      Index2Name = {Tuple.make i2n {Width Name2Index}}

      {ForAll Names
       proc {$ X}
          Index2Name.(Name2Index.X) = X
       end}

      % compute mapping names -> bit arrays
      Name2Bits = {SearchOne BitMapping}.1

      % encodes type: V Pos and not & Neg
      proc {Constrain Pos Neg S}
         case {IsAtom Pos} then
            {BitArray.'or' S Name2Bits.Pos}
         else
            {ForAll Pos
             proc {$ P}
                case {HasFeature Name2Bits P}
                then {BitArray.'or' S Name2Bits.P}
                else raise crashed end end
             end}
         end
         {ForAll Neg
          proc {$ N}
             case {HasFeature Name2Bits N}
             then {BitArray.nimpl S Name2Bits.N}
             else raise crashed end end
          end}
      end

      proc {Encode Pos Neg ?S}
         case Pos==nil
         then
            raise illegalType end
         else
            S = {BitArray.new 1 N}
            {Constrain Pos Neg S}
         end
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
            case
               {IsFree S}
            then
               [value]
            else
               {DecodeAux {BitArray.clone S}}
            end
         end
      end

   in

      % add defined names
      {ForAll Def
       proc {$ def(N Ns)}
          case
             {Member N Names}
          then
             raise illegalPartialOrderSpecification end
          else
             Name2Bits.N = {Constrain Ns nil}
          end
       end}

      po(encode:   Encode
         decode:   Decode
         decl:     fun {$} {BitArray.new 1 N} end)

   end

in

   OzTypes
   = {PartialOrder

      % inclusion subtypes

      ['thread' # value
       space  # value
       chunk  # value
       cell   # value
       foreignPointer # value
       fset   # value
       recordC# value
       record # recordC
       number # value
       intC   # number
       int    # intC
       float  # number
       char   # fdint
       fdint  # int
       tuple  # record
       literal# tuple
       atom   # literal
       name   # literal
       nilAtom # atom
       cons   # tuple
       bool   # name
       'unit' # name
       bitArray # chunk
       promise # chunk
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
      ]

      % partitioned subtypes

      [def(feature           [int literal])
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
       def(virtualString     [number record])
       def(procedureOrObject [procedure object])
       def(unaryProcOrObject ['procedure/1' object])
      ]}

   fun {OzValueToType V}
      case
         {IsDet V}
      then
         case {IsInt V}
         then
            case {IsChar V}
            then {OzTypes.encode char nil}
            elsecase {FD.is V}
            then {OzTypes.encode fdint nil}
            else {OzTypes.encode int nil}
            end
         elsecase {IsFloat V}
         then {OzTypes.encode float nil}
         elsecase {IsAtom V}
         then
            case V == nil
            then {OzTypes.encode nilAtom nil}
            else {OzTypes.encode atom nil}
            end
         elsecase {IsName V}
         then
            case V == true orelse V == false
            then {OzTypes.encode bool nil}
            elsecase V == unit
            then {OzTypes.encode 'unit' nil}
            else {OzTypes.encode name nil}
            end
         elsecase {IsTuple V}
         then
            case V of _|_
            then {OzTypes.encode cons nil}
            [] _#_
            then {OzTypes.encode pair nil}
            else {OzTypes.encode tuple nil}
            end
         elsecase {IsRecord V}
         then {OzTypes.encode record nil}
         elsecase {IsProcedure V}
         then
            case {ProcedureArity V}
            of 0 then {OzTypes.encode 'procedure/0' nil}
            elseof 1 then {OzTypes.encode 'procedure/1' nil}
            elseof 2 then {OzTypes.encode 'procedure/2' nil}
            elseof 3 then {OzTypes.encode 'procedure/3' nil}
            elseof 4 then {OzTypes.encode 'procedure/4' nil}
            elseof 5 then {OzTypes.encode 'procedure/5' nil}
            elseof 6 then {OzTypes.encode 'procedure/6' nil}
            else {OzTypes.encode 'procedure/>6' nil}
            end
         elsecase {IsCell V}
         then {OzTypes.encode cell nil}
         elsecase {IsChunk V}
         then
            case {IsArray V}
            then {OzTypes.encode array nil}
            elsecase {IsDictionary V}
            then
               {OzTypes.encode dictionary nil}
            elsecase {IsClass V}
            then {OzTypes.encode 'class' nil}
            elsecase {IsObject V}
            then {OzTypes.encode object nil}
            elsecase {IsLock V}
            then {OzTypes.encode 'lock' nil}
            elsecase {IsPort V}
            then {OzTypes.encode port nil}
            else {OzTypes.encode chunk [array dictionary 'class'
                                        'object' 'lock' port
                                        bitArray promise]}
            end
         elsecase {IsSpace V}
         then {OzTypes.encode space nil}
         elsecase {IsThread V}
         then {OzTypes.encode 'thread' nil}
         else {OzTypes.encode value [int float record procedure
                                     cell chunk space 'thread']}
         end
      elsecase
         {IsKinded V}
      then
         case {FD.is V}
         then {OzTypes.encode intC nil}
         elsecase {IsRecordC V}
         then {OzTypes.encode recordC nil}
         else {OzTypes.encode value [intC recordC]}
         end
      else
         {OzTypes.encode value nil}
      end
   end
end
