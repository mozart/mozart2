%%%
%%% Authors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
   Boot_WeakDictionary  at 'x-oz://boot/WeakDictionary'
   Boot_Dictionary      at 'x-oz://boot/Dictionary'
   Boot_Record          at 'x-oz://boot/Record'
   Boot_Chunk           at 'x-oz://boot/Chunk'
   Boot_VirtualString   at 'x-oz://boot/VirtualString'
   Boot_Array           at 'x-oz://boot/Array'
   Boot_Object          at 'x-oz://boot/Object'
   Boot_Class           at 'x-oz://boot/Class'
   Boot_BitArray        at 'x-oz://boot/BitArray'
   Boot_ForeignPointer  at 'x-oz://boot/ForeignPointer'
   Boot_Thread          at 'x-oz://boot/Thread'
   Boot_Exception       at 'x-oz://boot/Exception'
   Boot_Time            at 'x-oz://boot/Time'
   Boot_BitString       at 'x-oz://boot/BitString'
   Boot_ByteString      at 'x-oz://boot/ByteString'
\ifdef SITE_PROPERTY
   Boot_SiteProperty    at 'x-oz://boot/SiteProperty'
\endif

prepare

   %%
   %% Value
   %%
   Wait         = Boot_Value.wait
   WaitOr       = Boot_Value.waitOr
   WaitQuiet    = Boot_Value.waitQuiet
   WaitNeeded   = Boot_Value.waitNeeded
   MakeNeeded   = Boot_Value.makeNeeded
   IsFree       = Boot_Value.isFree
   IsKinded     = Boot_Value.isKinded
   IsFuture     = Boot_Value.isFuture
   IsFailed     = Boot_Value.isFailed
   IsDet        = Boot_Value.isDet
   IsNeeded     = Boot_Value.isNeeded
   Max          = Boot_Value.max
   Min          = Boot_Value.min
   CondSelect   = Boot_Value.condSelect
   HasFeature   = Boot_Value.hasFeature
   FailedValue  = Boot_Value.failedValue
   NewReadOnly  = Boot_Value.newReadOnly
   BindReadOnly = Boot_Value.bindReadOnly
   ByNeed       = proc {$ P X} thread {WaitNeeded X} {P X} end end
   ByNeedFuture = proc {$ P X}
                     R={NewReadOnly}
                  in
                     thread
                        {WaitNeeded R}
                        try Y in
                           {MakeNeeded Y}
                           {P Y}
                           {WaitQuiet Y} {BindReadOnly R Y}
                        catch E then
                           {BindReadOnly R {FailedValue E}}
                        end
                     end
                     X=R
                  end

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
   SendRecv     = Boot_Port.sendRecv

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
   %% Weak Dictionary
   %%
   IsWeakDictionary     = Boot_WeakDictionary.is
   NewWeakDictionary    = Boot_WeakDictionary.new

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
   %% Object, Class, and OoExtensions
   %%
   IsObject      = Boot_Object.is
   New           = Boot_Object.new
   IsClass       = Boot_Class.is
   %% Methods
   `ooMeth`      = {NewUniqueName 'ooMeth'}
   `ooFastMeth`  = {NewUniqueName 'ooFastMeth'}
   `ooDefaults`  = {NewUniqueName 'ooDefaults'}
   %% Attributes
   `ooAttr`      = {NewUniqueName 'ooAttr'}
   %% Features
   `ooFeat`      = {NewUniqueName 'ooFeat'}
   `ooFreeFeat`  = {NewUniqueName 'ooFreeFeat'}
   `ooFreeFlag`  = {NewUniqueName 'ooFreeFlag'}
   %% Inheritance related
   `ooMethSrc`   = {NewUniqueName 'ooMethSrc'}
   `ooAttrSrc`   = {NewUniqueName 'ooAttrSrc'}
   `ooFeatSrc`   = {NewUniqueName 'ooFeatSrc'}
   %% Other
   `ooPrintName` = {NewUniqueName 'ooPrintName'}
   `ooFallback`  = {NewUniqueName 'ooFallback'}

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
   Raise        = Boot_Exception.'raise'

   %%
   %% Time
   %%
   Alarm        = Boot_Time.alarm

   %%
   %% BitString ByteString
   %%
   IsBitString  = Boot_BitString.is
   IsByteString = Boot_ByteString.is

   \insert 'Exception.oz'
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
   \insert 'WeakDictionary.oz'
   \insert 'Dictionary.oz'
   \insert 'Record.oz'
   \insert 'Chunk.oz'
   \insert 'VirtualString.oz'
   \insert 'Array.oz'
   \insert 'Object.oz'
   \insert 'BitArray.oz'
   \insert 'ForeignPointer.oz'
   \insert 'Thread.oz'
   \insert 'Time.oz'
   \insert 'Functor.oz'
   \insert 'BitString.oz'
   \insert 'ByteString.oz'
\ifdef SITE_PROPERTY
   \insert 'SiteProperty'
\endif

export
   %% Value
   'Value'              : Value
   'Wait'               : Wait
   'WaitOr'             : WaitOr
   'WaitNeeded'         : WaitNeeded
   'IsFree'             : IsFree
   'IsKinded'           : IsKinded
   'IsFuture'           : IsFuture
   'IsFailed'           : IsFailed
   'IsDet'              : IsDet
   'IsNeeded'           : IsNeeded
   'Min'                : Min
   'Max'                : Max
   'CondSelect'         : CondSelect
   'HasFeature'         : HasFeature
   'ByNeed'             : ByNeed
   'ByNeedFuture'       : ByNeedFuture
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
   'Or'                 : Or
   'Not'                : Not
   %% String
   'String'             : String
   'IsString'           : IsString
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
   'IntToFloat'         : IntToFloat
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
   'FloatToInt'         : FloatToInt
   'FloatToString'      : FloatToString
   %% Number
   'Number'             : Number
   'IsNumber'           : IsNumber
   'Pow'                : Pow
   'Abs'                : Abs
   %% Tuple
   'Tuple'              : Tuple
   'IsTuple'            : IsTuple
   'MakeTuple'          : MakeTuple
   %% List
   'List'               : List
   'MakeList'           : MakeList
   'IsList'             : IsList
   'Append'             : Append
   'Member'             : Member
   'Length'             : Length
   'Nth'                : Nth
   'Reverse'            : Reverse
   'Map'                : Map
   'FoldL'              : FoldL
   'FoldR'              : FoldR
   'FoldLTail'          : FoldLTail
   'FoldRTail'          : FoldRTail
   'ForAll'             : ForAll
   'All'                : All
   'ForAllTail'         : ForAllTail
   'AllTail'            : AllTail
   'Some'               : Some
   'Filter'             : Filter
   'Sort'               : Sort
   'Merge'              : Merge
   'Flatten'            : Flatten
   %% Procedure
   'Procedure'          : Procedure
   'IsProcedure'        : IsProcedure
   'ProcedureArity'     : ProcedureArity
   %% Loop
   'Loop'               : Loop
   'For'                : For
   'ForThread'          : ForThread
   %% Record
   'Record'             : Record
   'IsRecord'           : IsRecord
   'Arity'              : Arity
   'Label'              : Label
   'Width'              : Width
   'Adjoin'             : Adjoin
   'AdjoinList'         : AdjoinList
   'AdjoinAt'           : AdjoinAt
   'MakeRecord'         : MakeRecord
   %% Chunk
   'Chunk'              : Chunk
   'IsChunk'            : IsChunk
   'NewChunk'           : NewChunk
   %% VirtualString
   'VirtualString'      : VirtualString
   'IsVirtualString'    : IsVirtualString
   %% WeakDictionary
   'WeakDictionary'     : WeakDictionary
   'IsWeakDictionary'   : IsWeakDictionary
   'NewWeakDictionary'  : NewWeakDictionary
   %% Dictionary
   'Dictionary'         : Dictionary
   'IsDictionary'       : IsDictionary
   'NewDictionary'      : NewDictionary
   %% Array
   'Array'              : Array
   'IsArray'            : IsArray
   'NewArray'           : NewArray
   'Put'                : Put
   'Get'                : Get
   %% Object
   'Object'             : Object
   'IsObject'           : IsObject
   'BaseObject'         : BaseObject
   'New'                : New
   %% Class
   'Class'              : Class
   'IsClass'            : IsClass
   %% Thread
   'Thread'             : Thread
   'IsThread'           : IsThread
   %% Time
   'Time'               : Time
   'Alarm'              : Alarm
   'Delay'              : Delay
   %% Exception
   'Exception'          : Exception
   'Raise'              : Raise
   %% Functor
   'Functor'            : Functor
   %% BitArray
   'BitArray'           : BitArray
   'IsBitArray'         : IsBitArray
   %% ForeignPointer
   'ForeignPointer'     : ForeignPointer
   'IsForeignPointer'   : IsForeignPointer
   %% BitString
   'BitString'          : BitString
   'ByteString'         : ByteString
   'IsBitString'        : IsBitString
   'IsByteString'       : IsByteString

   %% Will be removed by the compiler
   'OoExtensions'       : OoExtensions

\ifdef SITE_PROPERTY
   %% SiteProperty
   'SiteProperty'       : SiteProperty
\endif

end
