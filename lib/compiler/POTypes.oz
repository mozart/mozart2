%%%
%%% Authors:
%%%   Author's name (Author's email address)
%%%
%%% Contributors:
%%%   optional, Contributor's name (Contributor's email address)
%%%
%%% Copyright:
%%%   Organization or Person (Year(s))
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
%%%  Programming Systems Lab,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5627
%%%  Author: Martin Mueller <mmueller@ps.uni-sb.de>

local

   S2A  = String.toAtom
   VS2S = VirtualString.toString

   % add to list if no duplicate
   fun {Add X Ys}
      case {Member X Ys} then Ys else X|Ys end
   end

   % get list of sort names mentioned
   % in Spec (no duplicates)
   fun {GetNames Spec}
      {FoldR Spec
       fun {$ A#B I} {Add A {Add B I}} end
       nil}
   end

   proc {MakePO Spec Def ?Encode ?Decode ?Name2Domain ?NN}

      Names = {GetNames Spec}
      N     = {Length Names}
      Defd  = {Map Def fun {$ def(DN _)} DN end}
      Types = {Append Names Defd}

      % define mapping names -> indexes
      proc {IdxMapping N2I}
         Ds
      in
         N2I = {Record.make n2i Names}

         % each name receives an integer between 1 and N
         {Record.forAll N2I
          proc {$ A}
             A = {FD.int 1#N}
          end}

         % numbering must respect the partial order
         {ForAll Spec
          proc {$ A#B}
             N2I.A >: N2I.B
          end}

         % numbering must be one-one
         {FD.distinct N2I}

         % go
         {FD.distribute naive N2I}
      end

      % define mapping names -> sets
      proc {SetMapping N2S}
         Ss
      in
         N2S = {Record.make n2s Types}

         % each sort is encoded as a subset of {1..N}
         % including the index of the sort (open world!)
         {ForAll Names
          proc {$ X}
             SX = {FS.var.lub [1#N]}
          in
             N2S.X = SX
             {FS.include Name2Index.X SX}
          end}

         % set encoding must respect partial ordering
         {ForAll Spec
          proc {$ A#B}
             {FS.subset N2S.A N2S.B}
          end}

         % minimize set values after proPagation
         {ForAll Names
          proc {$ N}
             S = N2S.N
          in
             choice
                S = {FS.value.new {FS.reflect.glb S}}
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

      % compute mapping names -> sets
      Name2Set = {SearchOne SetMapping}.1

      % compute mapping names -> domains
      Name2Dom = {Record.make n2d Types}

      {ForAll Names
       proc {$ X}
          Name2Dom.X  = {FS.reflect.glb Name2Set.X}
       end}

      fun {AppendDom X Y}
         {Append Name2Dom.X Y}
      end

      fun {UnionSet X Y}
         {FS.union Name2Set.X Y}
      end

   in

      fun {Name2Domain A}
         case A of nil
         then
            nil
         elseof _|_
         then
            {FoldR A AppendDom nil}
         else
            Name2Dom.A
         end
      end

      NN = N

      % encodes type constants
      fun {Encode Pos Neg}
         case Pos==nil
         then
            raise illegalType end
         else
            PosSet = case {IsAtom Pos}
                     then Name2Set.Pos
                     else {FoldR Pos UnionSet FS.value.empty}
                     end
            NegSet = {FoldR Neg UnionSet FS.value.empty}
         in
            {FS.diff PosSet NegSet}
         end
      end

      % return best upper approximation of type
      fun {Decode S}
         case
            {IsFree S}
         then
            [value]
         elsecase
            {FS.reflect.lub S}
         of nil then nil
         elseof (X#Y)|_ then
            N = Index2Name.X
            NS= Name2Set.N
         in
            N | {Decode {FS.diff S NS}}
         elseof X|_ then
            N = Index2Name.X
            NS= Name2Set.N
         in
            N | {Decode {FS.diff S NS}}
         end
      end

      % add defined names
      {ForAll Def
       proc {$ def(N Ns)}
          case
             {Member N Names}
          then
             raise illegalPartialOrderSpecification end
          else
             NSet = {Encode Ns nil}
          in
             Name2Set.N = NSet
             Name2Dom.N = {FS.reflect.lub NSet}
          end
       end}

   end

   fun {PartialOrder Spec Def}
      Enc Dec N2D N
      NewType
   in
      {MakePO Spec Def Enc Dec N2D N}

      proc {NewType Pos Neg S}
         case Pos==value
            andthen Neg==nil
         then
            skip      % efficient representation of top is _
         else
            S = {FS.var.new nil {N2D Pos}}
            S = {FS.cardRange 1 N} % exclude empty set
            {FS.disjoint S {FS.value.new {N2D Neg}}}
         end
      end

      po(encode:   Enc
         decode:   fun {$ X}
                      case {IsFree X} then [value] else {Dec X} end
                   end
         name2dom: N2D
         top:      {FS.value.new [1#N]}
         decl:     proc {$ S}
                      S = {FS.var.lub [1#N]}
                      S = {FS.cardRange 1 N} % exclude empty set
                   end
         new:      NewType
         isa:      fun {$ A B}
                      if {FS.subset {Enc A} {Enc B}}
                      then true else false end
                   end
        )
   end

in

   OzTypes = {PartialOrder
              ['thread' # value  space  # value
               chunk  # value    cell   # value
               recordC# value
               record # recordC
               number # value
               intC   # number
               int    # intC
               float  # number   char   # fdint
               fdint  # int
               tuple  # record   literal# tuple
               atom   # literal  name   # literal
               nilAtom # atom     cons   # tuple
               bool   # name     'unit' # name
               array  # chunk    dictionary # chunk
               'class'# chunk    'object'# chunk
               'lock'   # chunk  port   # chunk
               'nullary procedure' # value
               'unary procedure'   # value
               'binary procedure'  # value
               'ternary procedure' # value
               'n-ary procedure'   # value
               pair # tuple
              ]

              [def(feature           [int literal])
               def(comparable        [number atom])
               def(recordOrChunk     [record chunk])
               def(recordCOrChunk    [recordC chunk])
               def(list              [nilAtom cons])
               def(string            [nilAtom cons])
               def(procedure         ['nullary procedure'
                                      'unary procedure'
                                      'binary procedure'
                                      'ternary procedure'
                                      'n-ary procedure'])
               def(virtualString     [number record])
               def(procedureOrObject [procedure object])
              ]}

   TypeConstants
   = tc(char:     {OzTypes.new char nil}
        nil:      {OzTypes.new nilAtom nil}
        float:    {OzTypes.new float nil}
        fdint:    {OzTypes.new fdint [char]}
        int:      {OzTypes.new int [fdint char]}
        atom:     {OzTypes.new atom [nilAtom]}
        name:     {OzTypes.new name ['unit' bool]}
        bool:     {OzTypes.new bool nil}
        'unit':   {OzTypes.new 'unit' nil}
        tuple:    {OzTypes.new tuple [literal cons pair]}
        record:   {OzTypes.new record [tuple]}
        cons:     {OzTypes.new cons nil}
        pair:     {OzTypes.new pair nil}
        'nullary procedure': {OzTypes.new 'nullary procedure' nil}
        'unary procedure':   {OzTypes.new 'unary procedure' nil}
        'binary procedure':  {OzTypes.new 'binary procedure' nil}
        'ternary procedure': {OzTypes.new 'ternary procedure' nil}
        'n-ary procedure':   {OzTypes.new 'n-ary procedure' nil}
        cell:     {OzTypes.new cell nil}
        'class':  {OzTypes.new 'class' nil}
        object:   {OzTypes.new object nil}
        array:    {OzTypes.new array nil}
        dict:     {OzTypes.new dictionary nil}
        port:     {OzTypes.new port nil}
        'lock':   {OzTypes.new 'lock' nil}
        space:    {OzTypes.new space nil}
        'thread': {OzTypes.new 'thread' nil})

   % consistency check
   % all type constants should be set constants

   {Record.forAllInd TypeConstants
    proc {$ N T}
       try {FS.cardRange 1 1 T}
       catch failure(...) then
          raise nonBasicType(N T) end
       end
    end}

   fun {OzValueToType V}
      case
         {IsDet V}
      then
         case {IsInt V}
         then
            case {IsChar V}
            then TypeConstants.char
            elsecase {FD.is V}
            then TypeConstants.fdint
            else TypeConstants.int
            end
         elsecase {IsFloat V}
         then TypeConstants.float
         elsecase {IsAtom V}
         then
            case V == nil
            then TypeConstants.nil
            else TypeConstants.atom
            end
         elsecase {IsName V}
         then
            case V == true orelse V == false
            then TypeConstants.bool
            elsecase V == unit
            then TypeConstants.'unit'
            else TypeConstants.name
            end
         elsecase {IsTuple V}
         then
            case V of _|_
            then TypeConstants.cons
            [] _#_
            then TypeConstants.pair
            else TypeConstants.tuple
            end
         elsecase {IsRecord V}
         then TypeConstants.record
         elsecase {IsProcedure V}
         then
            case {ProcedureArity V}
            of 0 then TypeConstants.'nullary procedure'
            elseof 1 then TypeConstants.'unary procedure'
            elseof 2 then TypeConstants.'binary procedure'
            elseof 3 then TypeConstants.'ternary procedure'
            else TypeConstants.'n-ary procedure'
            end
         elsecase {IsCell V}
         then TypeConstants.cell
         elsecase {IsChunk V}
         then
            case {IsArray V}
            then TypeConstants.array
            elsecase {IsDictionary V}
            then TypeConstants.dict
            elsecase {IsClass V}
            then TypeConstants.'class'
            elsecase {IsObject V}
            then TypeConstants.object
            elsecase {IsLock V}
            then TypeConstants.'lock'
            elsecase {IsPort V}
            then TypeConstants.port
            else {OzTypes.new chunk [array dictionary 'class'
                                     'object' 'lock' port]}
            end
         elsecase {IsSpace V}
         then TypeConstants.space
         elsecase {IsThread V}
         then TypeConstants.'thread'
         else {OzTypes.new value[int float record procedure
                                 cell chunk space 'thread']}
         end
      elsecase
         {IsKinded V}
      then
         case {FD.is V}
         then {OzTypes.new intC nil}
         elsecase {IsRecordC V}
         then {OzTypes.new recordC nil}
         else {OzTypes.new value [intC recordC]}
         end
      else
         {OzTypes.new value nil}
      end
   end
end
