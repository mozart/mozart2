%%%
%%% Authors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%   Christian Schulte <schulte@dfki.de>
%%%
%%% Copyright:
%%%   Denys Duchier, 1998
%%%   Christian Schulte, 1997, 1998
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

%%% NOTE: this file must be compiled with -l StandardBuiltins

local
   %%
   %% all definitions are outside of the functor so that
   %% they may always have the same gnames, regardless
   %% of how many times the functor is instantiated,
   %% e.g. by using -l Standard with the compiler
   %%
   \insert 'base/Value.oz'
   \insert 'base/Literal.oz'
   \insert 'base/Unit.oz'
   \insert 'base/Lock.oz'
   \insert 'base/Cell.oz'
   \insert 'base/Port.oz'
   \insert 'base/Atom.oz'
   \insert 'base/Name.oz'
   \insert 'base/Bool.oz'
   \insert 'base/String.oz'
   \insert 'base/Char.oz'
   \insert 'base/Int.oz'
   \insert 'base/Float.oz'
   \insert 'base/Number.oz'
   \insert 'base/Tuple.oz'
   \insert 'base/List.oz'
   \insert 'base/Procedure.oz'
   \insert 'base/Loop.oz'
   \insert 'base/Dictionary.oz'
   \insert 'base/Record.oz'
   \insert 'base/Chunk.oz'
   \insert 'base/VirtualString.oz'
   \insert 'base/Array.oz'
   \insert 'base/Space.oz'
   \insert 'base/Object.oz'
   \insert 'base/Class.oz'
   \insert 'base/BitArray.oz'
   \insert 'base/ForeignPointer.oz'
   \insert 'base/Thread.oz'
   \insert 'base/Exception.oz'
   \insert 'base/Time.oz'
   \insert 'base/Functor.oz'
   \insert 'base/BitString.oz'
   \insert 'base/ByteString.oz'
in
   functor $ prop once

   export
      %% Unit
      '`unit`'          : `unit`
      %% Bool
      '`true`'          : `true`
      '`false`'         : `false`

      %% Value
      'Value'           : Value
      'Wait'            : Wait
      'WaitOr'          : WaitOr
      'IsFree'          : IsFree
      'IsKinded'        : IsKinded
      'IsDet'           : IsDet
      'Min'             : Min
      'Max'             : Max
      'CondSelect'      : CondSelect
      'HasFeature'      : HasFeature
      'ByNeed'          : ByNeed
      %% Literal
      'Literal'         : Literal
      'IsLiteral'       : IsLiteral
      %% Unit
      'Unit'            : Unit
      'IsUnit'          : IsUnit
      %% Lock
      'Lock'            : Lock
      'IsLock'          : IsLock
      'NewLock'         : NewLock
      %% Cell
      'Cell'            : Cell
      'IsCell'          : IsCell
      'NewCell'         : NewCell
      'Exchange'        : Exchange
      'Assign'          : Assign
      'Access'          : Access
      %% Port
      'Port'            : Port
      'IsPort'          : IsPort
      'NewPort'         : NewPort
      'Send'            : Send
      %% Atom
      'Atom'            : Atom
      'IsAtom'          : IsAtom
      'AtomToString'    : AtomToString
      %% Name
      'Name'            : Name
      'IsName'          : IsName
      'NewName'         : NewName
      %% Bool
      'Bool'            : Bool
      'IsBool'          : IsBool
      'And'             : And
      'Or'              : Or
      'Not'             : Not
      %% String
      'String'          : String
      'IsString'        : IsString
      'StringToAtom'    : StringToAtom
      'StringToInt'     : StringToInt
      'StringToFloat'   : StringToFloat
      %% Char
      'Char'            : Char
      'IsChar'          : IsChar
      %% Int
      'Int'             : Int
      'IsInt'           : IsInt
      'IsNat'           : IsNat
      'IsOdd'           : IsOdd
      'IsEven'          : IsEven
      'IntToFloat'      : IntToFloat
      'IntToString'     : IntToString
      %% Float
      'Float'           : Float
      'IsFloat'         : IsFloat
      'Exp'             : Exp
      'Log'             : Log
      'Sqrt'            : Sqrt
      'Ceil'            : Ceil
      'Floor'           : Floor
      'Sin'             : Sin
      'Cos'             : Cos
      'Tan'             : Tan
      'Asin'            : Asin
      'Acos'            : Acos
      'Atan'            : Atan
      'Atan2'           : Atan2
      'Round'           : Round
      'FloatToInt'      : FloatToInt
      'FloatToString'   : FloatToString
      %% Number
      'Number'          : Number
      'IsNumber'        : IsNumber
      'Pow'             : Pow
      'Abs'             : Abs
      %% Tuple
      'Tuple'           : Tuple
      'IsTuple'         : IsTuple
      'MakeTuple'       : MakeTuple
      %% List
      'List'            : List
      'MakeList'        : MakeList
      'IsList'          : IsList
      'Append'          : Append
      'Member'          : Member
      'Length'          : Length
      'Nth'             : Nth
      'Reverse'         : Reverse
      'Map'             : Map
      'FoldL'           : FoldL
      'FoldR'           : FoldR
      'FoldLTail'       : FoldLTail
      'FoldRTail'       : FoldRTail
      'ForAll'          : ForAll
      'All'             : All
      'ForAllTail'      : ForAllTail
      'AllTail'         : AllTail
      'Some'            : Some
      'Filter'          : Filter
      'Sort'            : Sort
      'Merge'           : Merge
      'Flatten'         : Flatten
      %% Procedure
      'Procedure'       : Procedure
      'IsProcedure'     : IsProcedure
      'ProcedureArity'  : ProcedureArity
      %% Loop
      'Loop'            : Loop
      'For'             : For
      'ForThread'       : ForThread
      %% Record
      'Record'          : Record
      'IsRecord'        : IsRecord
      'Arity'           : Arity
      'Label'           : Label
      'Width'           : Width
      'Adjoin'          : Adjoin
      'AdjoinList'      : AdjoinList
      'AdjoinAt'        : AdjoinAt
      'IsRecordC'       : IsRecordC
      'WidthC'          : WidthC
      'TellRecord'      : TellRecord
      'MakeRecord'      : MakeRecord
      %% Chunk
      'Chunk'           : Chunk
      'IsChunk'         : IsChunk
      'NewChunk'        : NewChunk
      %% VirtualString
      'VirtualString'   : VirtualString
      'IsVirtualString' : IsVirtualString
      %% Dictionary
      'Dictionary'      : Dictionary
      'IsDictionary'    : IsDictionary
      'NewDictionary'   : NewDictionary
      %% Array
      'Array'           : Array
      'IsArray'         : IsArray
      'NewArray'        : NewArray
      'Put'             : Put
      'Get'             : Get
      %% Space
      'Space'           : Space
      'IsSpace'         : IsSpace
      %% Object
      'Object'          : Object
      'IsObject'        : IsObject
      'BaseObject'      : BaseObject
      'New'             : New
      %% Class
      'Class'           : Class
      'IsClass'         : IsClass
      %% Thread
      'Thread'          : Thread
      'IsThread'        : IsThread
      %% Time
      'Time'            : Time
      'Alarm'           : Alarm
      'Delay'           : Delay
      %% Exception
      'Exception'       : Exception
      'Raise'           : Raise
      %% Functor
      'Functor'         : Functor
      %% BitArray
      'BitArray'        : BitArray
      'IsBitArray'      : IsBitArray
      %% ForeignPointer
      'ForeignPointer'  : ForeignPointer
      'IsForeignPointer': IsForeignPointer
      %% BitString
      'BitString'       : BitString
      'ByteString'      : ByteString
      'IsBitString'     : IsBitString
      'IsByteString'    : IsByteString
   define
      skip
   end
end
