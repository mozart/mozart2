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


functor

require
   Boot_Value           at 'x-oz://boot/Value'
   Boot_Literal         at 'x-oz://boot/Literal'
   Boot_Unit            at 'x-oz://boot/Unit'
   Boot_Lock            at 'x-oz://boot/Lock'
   Boot_Cell            at 'x-oz://boot/Cell'
   Boot_Port            at 'x-oz://boot/Port'
   Boot_Atom            at 'x-oz://boot/Atom'
   Boot_Name            at 'x-oz://boot/Name'
   Boot_Bool            at 'x-oz://boot/Bool'
   Boot_String          at 'x-oz://boot/String'
   Boot_Char            at 'x-oz://boot/Char'
   Boot_Int             at 'x-oz://boot/Int'
   Boot_Float           at 'x-oz://boot/Float'
   Boot_Number          at 'x-oz://boot/Number'
   Boot_Tuple           at 'x-oz://boot/Tuple'
   Boot_List            at 'x-oz://boot/List'
   Boot_Procedure       at 'x-oz://boot/Procedure'
   Boot_Dictionary      at 'x-oz://boot/Dictionary'
   Boot_Record          at 'x-oz://boot/Record'
   Boot_Chunk           at 'x-oz://boot/Chunk'
   Boot_VirtualString   at 'x-oz://boot/VirtualString'
   Boot_Array           at 'x-oz://boot/Array'
   Boot_Space           at 'x-oz://boot/Space'
   Boot_Object          at 'x-oz://boot/Object'
   Boot_Class           at 'x-oz://boot/Class'
   Boot_BitArray        at 'x-oz://boot/BitArray'
   Boot_ForeignPointer  at 'x-oz://boot/ForeignPointer'
   Boot_Thread          at 'x-oz://boot/Thread'
   Boot_Exception       at 'x-oz://boot/Exception'
   Boot_Time            at 'x-oz://boot/Time'
   Boot_BitString       at 'x-oz://boot/BitString'
   Boot_ByteString      at 'x-oz://boot/ByteString'

prepare

   %%
   %% Value
   %%
   Wait         = Boot_Value.wait
   WaitOr       = Boot_Value.waitOr
   IsFree       = Boot_Value.isFree
   IsKinded     = Boot_Value.isKinded
   IsFuture     = Boot_Value.isFuture
   IsDet        = Boot_Value.isDet
   Max          = Boot_Value.max
   Min          = Boot_Value.min
   CondSelect   = Boot_Value.condSelect
   HasFeature   = Boot_Value.hasFeature
   ByNeed       = Boot_Value.byNeed

   %%
   %% Literal
   %%
   IsLiteral    = Boot_Literal.is

   %%
   %% Unit
   %%
   IsUnit       = Boot_Unit.is
   `unit`       = {Boot_Name.newUnique 'unit'}

   %%
   %% Lock
   %%
   IsLock       = Boot_Lock.is
   NewLock      = Boot_Lock.new

   %%
   %% Cell
   %%
   IsCell       = Boot_Cell.is
   NewCell      = Boot_Cell.new
   Exchange     = proc {$ C Old New} Old = {Boot_Cell.exchangeFun C New} end
   Assign       = Boot_Cell.assign
   Access       = Boot_Cell.access

   %%
   %% Port
   %%
   IsPort       = Boot_Port.is
   NewPort      = Boot_Port.new
   Send         = Boot_Port.send

   %%
   %% Atom
   %%
   IsAtom       = Boot_Atom.is
   AtomToString = Boot_Atom.toString

   %%
   %% Name
   %%
   IsName       = Boot_Name.is
   NewName      = Boot_Name.new
   NewUniqueName= Boot_Name.newUnique % not exported

   %%
   %% Bool
   %%
   IsBool       = Boot_Bool.is
   Not          = Boot_Bool.'not'
   And          = Boot_Bool.'and'
   Or           = Boot_Bool.'or'
   `true`       = {NewUniqueName 'true'}
   `false`      = {NewUniqueName 'false'}

   %%
   %% String
   %%
   IsString     = Boot_String.is
   StringToAtom = Boot_String.toAtom
   StringToInt  = Boot_String.toInt
   StringToFloat= Boot_String.toFloat

   %%
   %% Char
   %%
   IsChar       = Boot_Char.is

   %%
   %% Int
   %%
   IsInt        = Boot_Int.is
   IntToFloat   = Boot_Int.toFloat
   IntToString  = Boot_Int.toString

   %%
   %% Float
   %%
   IsFloat      = Boot_Float.is
   Exp          = Boot_Float.exp
   Log          = Boot_Float.log
   Sqrt         = Boot_Float.sqrt
   Ceil         = Boot_Float.ceil
   Floor        = Boot_Float.floor
   Sin          = Boot_Float.sin
   Cos          = Boot_Float.cos
   Tan          = Boot_Float.tan
   Asin         = Boot_Float.asin
   Acos         = Boot_Float.acos
   Atan         = Boot_Float.atan
   Atan2        = Boot_Float.atan2
   Round        = Boot_Float.round
   FloatToInt   = Boot_Float.toInt
   FloatToString= Boot_Float.toString

   %%
   %% Number
   %%
   IsNumber     = Boot_Number.is
   Abs          = Boot_Number.abs

   %%
   %% Tuple
   %%
   IsTuple      = Boot_Tuple.is
   MakeTuple    = Boot_Tuple.make

   %%
   %% Procedure
   %%
   IsProcedure          = Boot_Procedure.is
   ProcedureArity       = Boot_Procedure.arity

   %%
   %% Dictionary
   %%
   IsDictionary = Boot_Dictionary.is
   NewDictionary= Boot_Dictionary.new

   %%
   %% Record
   %%
   Arity        = Boot_Record.arity
   IsRecord     = Boot_Record.is
   Label        = Boot_Record.label
   Width        = Boot_Record.width
   Adjoin       = Boot_Record.adjoin
   AdjoinList   = Boot_Record.adjoinList
   AdjoinAt     = Boot_Record.adjoinAt
   IsRecordC    = Boot_Record.isC
   WidthC       = Boot_Record.widthC
   TellRecord   = Boot_Record.tellRecord

   %%
   %% Chunk
   %%
   IsChunk      = Boot_Chunk.is
   NewChunk     = Boot_Chunk.new

   %%
   %% VirtualString
   %%
   IsVirtualString      = Boot_VirtualString.is

   %%
   %% Array
   %%
   NewArray     = Boot_Array.new
   IsArray      = Boot_Array.is
   Put          = Boot_Array.put
   Get          = Boot_Array.get

   %%
   %% Space
   %%
   IsSpace      = Boot_Space.is

   %%
   %% Object
   %%
   IsObject      = Boot_Object.is
   New           = Boot_Object.new
   %% Properties
   `ooLocking`   = {NewUniqueName 'ooLocking'}
   `ooNative`    = {NewUniqueName 'ooNative'}
   %% Methods
   `ooMeth`      = {NewUniqueName 'ooMeth'}
   `ooFastMeth`  = {NewUniqueName 'ooFastMeth'}
   `ooDefaults`  = {NewUniqueName 'ooDefaults'}
   %% Attributes
   `ooAttr`      = {NewUniqueName 'ooAttr'}
   %% Features
   `ooFreeFlag`  = {NewUniqueName 'ooFreeFlag'}
   `ooUnFreeFeat`= {NewUniqueName 'ooUnFreeFeat'}
   `ooFreeFeatR` = {NewUniqueName 'ooFreeFeatR'}
   %% Inheritance related
   `ooParents`   = {NewUniqueName 'ooParents'}
   `ooMethSrc`   = {NewUniqueName 'ooMethSrc'}
   `ooAttrSrc`   = {NewUniqueName 'ooAttrSrc'}
   `ooFeatSrc`   = {NewUniqueName 'ooFeatSrc'}
   %% Other
   `ooPrintName` = {NewUniqueName 'ooPrintName'}
   `ooFallback`  = {NewUniqueName 'ooFallback'}

   %%
   %% Class
   %%
   {Wait Boot_Class}            % force linking

   %%
   %% BitArray
   %%
   IsBitArray   = Boot_BitArray.is

   %%
   %% ForeignPointer
   %%
   IsForeignPointer     = Boot_ForeignPointer.is

   %%
   %% Thread
   %%
   IsThread     = Boot_Thread.is

   %%
   %% Exception
   %%
   `RaiseError` = Boot_Exception.raiseError
   Raise        = Boot_Exception.'raise'

   %%
   %% Time
   %%
   Alarm        = Boot_Time.alarm
   Delay        = Boot_Time.delay

   %%
   %% BitString ByteString
   %%
   IsBitString  = Boot_BitString.is
   IsByteString = Boot_ByteString.is

   \insert 'Value.oz'
   \insert 'Literal.oz'
   \insert 'Unit.oz'
   \insert 'Lock.oz'
   \insert 'Cell.oz'
   \insert 'Port.oz'
   \insert 'Atom.oz'
   \insert 'Name.oz'
   \insert 'Bool.oz'
   \insert 'String.oz'
   \insert 'Char.oz'
   \insert 'Int.oz'
   \insert 'Float.oz'
   \insert 'Number.oz'
   \insert 'Tuple.oz'
   \insert 'List.oz'
   \insert 'Procedure.oz'
   \insert 'Loop.oz'
   \insert 'Dictionary.oz'
   \insert 'Record.oz'
   \insert 'Chunk.oz'
   \insert 'VirtualString.oz'
   \insert 'Array.oz'
   \insert 'Space.oz'
   \insert 'Object.oz'
   \insert 'Class.oz'
   \insert 'BitArray.oz'
   \insert 'ForeignPointer.oz'
   \insert 'Thread.oz'
   \insert 'Exception.oz'
   \insert 'Time.oz'
   \insert 'Functor.oz'
   \insert 'BitString.oz'
   \insert 'ByteString.oz'

export
   %% Value
   'Value'              : Value
   'Wait'               : Wait
   'WaitOr'             : WaitOr
   'IsFree'             : IsFree
   'IsKinded'           : IsKinded
   'IsFuture'           : IsFuture
   'IsDet'              : IsDet
   'Min'                : Min
   'Max'                : Max
   'CondSelect'         : CondSelect
   'HasFeature'         : HasFeature
   'ByNeed'             : ByNeed
   %% Literal
   'Literal'            : Literal
   'IsLiteral'          : IsLiteral
   %% Unit
   'Unit'               : Unit
   'IsUnit'             : IsUnit
   %% Lock
   'Lock'               : Lock
   'IsLock'             : IsLock
   'NewLock'            : NewLock
   %% Cell
   'Cell'               : Cell
   'IsCell'             : IsCell
   'NewCell'            : NewCell
   'Exchange'           : Exchange
   'Assign'             : Assign
   'Access'             : Access
   %% Port
   'Port'               : Port
   'IsPort'             : IsPort
   'NewPort'            : NewPort
   'Send'               : Send
   %% Atom
   'Atom'               : Atom
   'IsAtom'             : IsAtom
   'AtomToString'       : AtomToString
   %% Name
   'Name'               : Name
   'IsName'             : IsName
   'NewName'            : NewName
   %% Bool
   'Bool'               : Bool
   'IsBool'             : IsBool
   'And'                : And
   'Or'         : Or
   'Not'                : Not
   %% String
   'String'             : String
   'IsString'   : IsString
   'StringToAtom'       : StringToAtom
   'StringToInt'        : StringToInt
   'StringToFloat'      : StringToFloat
   %% Char
   'Char'               : Char
   'IsChar'             : IsChar
   %% Int
   'Int'                : Int
   'IsInt'              : IsInt
   'IsNat'              : IsNat
   'IsOdd'              : IsOdd
   'IsEven'             : IsEven
   'IntToFloat' : IntToFloat
   'IntToString'        : IntToString
   %% Float
   'Float'              : Float
   'IsFloat'            : IsFloat
   'Exp'                : Exp
   'Log'                : Log
   'Sqrt'               : Sqrt
   'Ceil'               : Ceil
   'Floor'              : Floor
   'Sin'                : Sin
   'Cos'                : Cos
   'Tan'                : Tan
   'Asin'               : Asin
   'Acos'               : Acos
   'Atan'               : Atan
   'Atan2'              : Atan2
   'Round'              : Round
   'FloatToInt' : FloatToInt
   'FloatToString'      : FloatToString
   %% Number
   'Number'             : Number
   'IsNumber'   : IsNumber
   'Pow'                : Pow
   'Abs'                : Abs
   %% Tuple
   'Tuple'              : Tuple
   'IsTuple'            : IsTuple
   'MakeTuple'  : MakeTuple
   %% List
   'List'               : List
   'MakeList'   : MakeList
   'IsList'             : IsList
   'Append'             : Append
   'Member'             : Member
   'Length'             : Length
   'Nth'                : Nth
   'Reverse'            : Reverse
   'Map'                : Map
   'FoldL'              : FoldL
   'FoldR'              : FoldR
   'FoldLTail'  : FoldLTail
   'FoldRTail'  : FoldRTail
   'ForAll'             : ForAll
   'All'                : All
   'ForAllTail' : ForAllTail
   'AllTail'            : AllTail
   'Some'               : Some
   'Filter'             : Filter
   'Sort'               : Sort
   'Merge'              : Merge
   'Flatten'            : Flatten
   %% Procedure
   'Procedure'  : Procedure
   'IsProcedure'        : IsProcedure
   'ProcedureArity'     : ProcedureArity
   %% Loop
   'Loop'               : Loop
   'For'                : For
   'ForThread'  : ForThread
   %% Record
   'Record'             : Record
   'IsRecord'   : IsRecord
   'Arity'              : Arity
   'Label'              : Label
   'Width'              : Width
   'Adjoin'             : Adjoin
   'AdjoinList' : AdjoinList
   'AdjoinAt'   : AdjoinAt
   'IsRecordC'  : IsRecordC
   'WidthC'             : WidthC
   'TellRecord' : TellRecord
   'MakeRecord' : MakeRecord
   %% Chunk
   'Chunk'              : Chunk
   'IsChunk'            : IsChunk
   'NewChunk'   : NewChunk
   %% VirtualString
   'VirtualString'      : VirtualString
   'IsVirtualString'    : IsVirtualString
   %% Dictionary
   'Dictionary' : Dictionary
   'IsDictionary'       : IsDictionary
   'NewDictionary'      : NewDictionary
   %% Array
   'Array'              : Array
   'IsArray'            : IsArray
   'NewArray'   : NewArray
   'Put'                : Put
   'Get'                : Get
   %% Space
   'Space'              : Space
   'IsSpace'            : IsSpace
   %% Object
   'Object'             : Object
   'IsObject'   : IsObject
   'BaseObject' : BaseObject
   'New'                : New
   %% Class
   'Class'              : Class
   'IsClass'            : IsClass
   %% Thread
   'Thread'             : Thread
   'IsThread'   : IsThread
   %% Time
   'Time'               : Time
   'Alarm'              : Alarm
   'Delay'              : Delay
   %% Exception
   'Exception'  : Exception
   'Raise'              : Raise
   %% Functor
   'Functor'            : Functor
   %% BitArray
   'BitArray'   : BitArray
   'IsBitArray' : IsBitArray
   %% ForeignPointer
   'ForeignPointer'     : ForeignPointer
   'IsForeignPointer': IsForeignPointer
   %% BitString
   'BitString'  : BitString
   'ByteString' : ByteString
   'IsBitString'        : IsBitString
   'IsByteString'       : IsByteString

end
