%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
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


%%%
%%% Necessary Forward Declarations
%%%
\insert 'standard/Forward.oz'


%%%
%%% Basic Setup
%%%
\insert 'standard/Value.oz'
\insert 'standard/Literal.oz'
\insert 'standard/Unit.oz'
\insert 'standard/Lock.oz'
\insert 'standard/Cell.oz'
\insert 'standard/Port.oz'
\insert 'standard/Atom.oz'
\insert 'standard/Name.oz'
\insert 'standard/Bool.oz'
\insert 'standard/String.oz'
\insert 'standard/Char.oz'
\insert 'standard/Int.oz'
\insert 'standard/Float.oz'
\insert 'standard/Number.oz'
\insert 'standard/Tuple.oz'
\insert 'standard/List.oz'
\insert 'standard/Procedure.oz'
\insert 'standard/Loop.oz'
\insert 'standard/Dictionary.oz'
\insert 'standard/Record.oz'
\insert 'standard/Chunk.oz'
\insert 'standard/VirtualString.oz'
\insert 'standard/Array.oz'
\insert 'standard/Space.oz'
\insert 'standard/Object.oz'
\insert 'standard/Class.oz'
\insert 'standard/BitArray.oz'
\insert 'standard/ForeignPointer.oz'
\insert 'standard/Thread.oz'
\insert 'standard/Exception.oz'
\insert 'standard/Time.oz'
\insert 'standard/Functor.oz'

\ifndef OZM

{Pickle.save
functor $ prop once

export
   %% Unit
   '`unit`':             `unit`
   %% Bool
   '`true`':             `true`
   '`false`':            `false`

   %% Value
   'Value':              Value
   'Wait':               Wait
   'WaitOr':             WaitOr
   'IsFree':             IsFree
   'IsKinded':           IsKinded
   'IsDet':              IsDet
   'Min':                Min
   'Max':                Max
   'CondSelect':         CondSelect
   'HasFeature':         HasFeature
   'ByNeed':             ByNeed
   %% Literal
   'Literal':            Literal
   'IsLiteral':          IsLiteral
   %% Unit
   'Unit':               Unit
   'IsUnit':             IsUnit
   %% Lock
   'Lock':               Lock
   'IsLock':             IsLock
   'NewLock':            NewLock
   %% Cell
   'Cell':               Cell
   'IsCell':             IsCell
   'NewCell':            NewCell
   'Exchange':           Exchange
   'Assign':             Assign
   'Access':             Access
   %% Port
   'Port':               Port
   'IsPort':             IsPort
   'NewPort':            NewPort
   'Send':               Send
   %% Atom
   'Atom':               Atom
   'IsAtom':             IsAtom
   'AtomToString':       AtomToString
   %% Name
   'Name':               Name
   'IsName':             IsName
   'NewName':            NewName
   %% Bool
   'Bool':               Bool
   'IsBool':             IsBool
   'And':                And
   'Or':                 Or
   'Not':                Not
   %% String
   'String':             String
   'IsString':           IsString
   'StringToAtom':       StringToAtom
   'StringToInt':        StringToInt
   'StringToFloat':      StringToFloat
   %% Char
   'Char':               Char
   'IsChar':             IsChar
   %% Int
   'Int':                Int
   'IsInt':              IsInt
   'IsNat':              IsNat
   'IsOdd':              IsOdd
   'IsEven':             IsEven
   'IntToFloat':         IntToFloat
   'IntToString':        IntToString
   %% Float
   'Float':              Float
   'IsFloat':            IsFloat
   'Exp':                Exp
   'Log':                Log
   'Sqrt':               Sqrt
   'Ceil':               Ceil
   'Floor':              Floor
   'Sin':                Sin
   'Cos':                Cos
   'Tan':                Tan
   'Asin':               Asin
   'Acos':               Acos
   'Atan':               Atan
   'Atan2':              Atan2
   'Round':              Round
   'FloatToInt':         FloatToInt
   'FloatToString':      FloatToString
   %% Number
   'Number':             Number
   'IsNumber':           IsNumber
   'Pow':                Pow
   'Abs':                Abs
   %% Tuple
   'Tuple':              Tuple
   'IsTuple':            IsTuple
   'MakeTuple':          MakeTuple
   %% List
   'List':               List
   'MakeList':           MakeList
   'IsList':             IsList
   'Append':             Append
   'Member':             Member
   'Length':             Length
   'Nth':                Nth
   'Reverse':            Reverse
   'Map':                Map
   'FoldL':              FoldL
   'FoldR':              FoldR
   'FoldLTail':          FoldLTail
   'FoldRTail':          FoldRTail
   'ForAll':             ForAll
   'All':                All
   'ForAllTail':         ForAllTail
   'AllTail':            AllTail
   'Some':               Some
   'Filter':             Filter
   'Sort':               Sort
   'Merge':              Merge
   'Flatten':            Flatten
   %% Procedure
   'Procedure':          Procedure
   'IsProcedure':        IsProcedure
   'ProcedureArity':     ProcedureArity
   %% Loop
   'Loop':               Loop
   'For':                For
   'ForThread':          ForThread
   %% Record
   'Record':             Record
   'IsRecord':           IsRecord
   'Arity':              Arity
   'Label':              Label
   'Width':              Width
   'Adjoin':             Adjoin
   'AdjoinList':         AdjoinList
   'AdjoinAt':           AdjoinAt
   'IsRecordC':          IsRecordC
   'WidthC':             WidthC
   'TellRecord':         TellRecord
   'MakeRecord':         MakeRecord
   %% Chunk
   'Chunk':              Chunk
   'IsChunk':            IsChunk
   'NewChunk':           NewChunk
   %% VirtualString
   'VirtualString':      VirtualString
   'IsVirtualString':    IsVirtualString
   %% Dictionary
   'Dictionary':         Dictionary
   'IsDictionary':       IsDictionary
   'NewDictionary':      NewDictionary
   %% Array
   'Array':              Array
   'IsArray':            IsArray
   'NewArray':           NewArray
   'Put':                Put
   'Get':                Get
   %% Space
   'Space':              Space
   'IsSpace':            IsSpace
   %% Object
   'Object':             Object
   'IsObject':           IsObject
   'BaseObject':         BaseObject
   'New':                New
   %% Class
   'Class':              Class
   'IsClass':            IsClass
   %% Thread
   'Thread':             Thread
   'IsThread':           IsThread
   %% Time
   'Time':               Time
   'Alarm':              Alarm
   'Delay':              Delay
   %% Exception
   'Exception':          Exception
   'Raise':              Raise
   %% Functor
   'Functor':            Functor
   %% BitArray
   'BitArray':           BitArray
   'IsBitArray':         IsBitArray
   %% ForeignPointer
   'ForeignPointer':     ForeignPointer
   'IsForeignPointer':   IsForeignPointer

body
   skip
end
'Standard.ozf'}

\endif
