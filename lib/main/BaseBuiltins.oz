%%%
%%% builtins are here made available under their standard names
%%% so that they may be used to compile the standard modules with
%%% appropriate optimizations
%%%

functor prop once
import
   Boot_Value           @ 'x-oz://boot/Value'
   Boot_Literal         @ 'x-oz://boot/Literal'
   Boot_Unit            @ 'x-oz://boot/Unit'
   Boot_Lock            @ 'x-oz://boot/Lock'
   Boot_Cell            @ 'x-oz://boot/Cell'
   Boot_Port            @ 'x-oz://boot/Port'
   Boot_Atom            @ 'x-oz://boot/Atom'
   Boot_Name            @ 'x-oz://boot/Name'
   Boot_Bool            @ 'x-oz://boot/Bool'
   Boot_String          @ 'x-oz://boot/String'
   Boot_Char            @ 'x-oz://boot/Char'
   Boot_Int             @ 'x-oz://boot/Int'
   Boot_Float           @ 'x-oz://boot/Float'
   Boot_Number          @ 'x-oz://boot/Number'
   Boot_Tuple           @ 'x-oz://boot/Tuple'
   Boot_Procedure       @ 'x-oz://boot/Procedure'
   Boot_Dictionary      @ 'x-oz://boot/Dictionary'
   Boot_Record          @ 'x-oz://boot/Record'
   Boot_Chunk           @ 'x-oz://boot/Chunk'
   Boot_VirtualString   @ 'x-oz://boot/VirtualString'
   Boot_Array           @ 'x-oz://boot/Array'
   Boot_Space           @ 'x-oz://boot/Space'
   Boot_Object          @ 'x-oz://boot/Object'
   Boot_Class           @ 'x-oz://boot/Class'
   Boot_BitArray        @ 'x-oz://boot/BitArray'
   Boot_ForeignPointer  @ 'x-oz://boot/ForeignPointer'
   Boot_Thread          @ 'x-oz://boot/Thread'
   Boot_Exception       @ 'x-oz://boot/Exception'
   Boot_Time            @ 'x-oz://boot/Time'
   Boot_BitString       @ 'x-oz://boot/BitString'
   Boot_ByteString      @ 'x-oz://boot/ByteString'
export
   %%
   %% Value
   %%
   'Boot_Value'         : Boot_Value
   'Wait'               : Wait
   'WaitOr'             : WaitOr
   'IsFree'             : IsFree
   'IsKinded'           : IsKinded
   'IsDet'              : IsDet
   'Min'                : Min
   'Max'                : Max
   'CondSelect'         : CondSelect
   'HasFeature'         : HasFeature
   'ByNeed'             : ByNeed
   %%
   %% Literal
   %%
   'Boot_Literal'       : Boot_Literal
   'IsLiteral'          : IsLiteral
   %%
   %% Unit
   %%
   'Boot_Unit'          : Boot_Unit
   'IsUnit'             : IsUnit
   '`unit`'             : `unit`
   %%
   %% Lock
   %%
   'Boot_Lock'          : Boot_Lock
   'IsLock'             : IsLock
   'NewLock'            : NewLock
   %%
   %% Cell
   %%
   'Boot_Cell'          : Boot_Cell
   'IsCell'             : IsCell
   'NewCell'            : NewCell
   'Exchange'           : Exchange
   'Assign'             : Assign
   'Access'             : Access
   %%
   %% Port
   %%
   'Boot_Port'          : Boot_Port
   'IsPort'             : IsPort
   'NewPort'            : NewPort
   'Send'               : Send
   %%
   %% Atom
   %%
   'Boot_Atom'          : Boot_Atom
   'IsAtom'             : IsAtom
   'AtomToString'       : AtomToString
   %%
   %% Name
   %%
   'Boot_Name'          : Boot_Name
   'IsName'             : IsName
   'NewName'            : NewName
   %%
   %% Bool
   %%
   'Boot_Bool'          : Boot_Bool
   'IsBool'             : IsBool
   'And'                : And
   'Or'                 : Or
   'Not'                : Not
   '`true`'             : `true`
   '`false`'            : `false`
   %%
   %% String
   %%
   'Boot_String'        : Boot_String
   'IsString'           : IsString
   'StringToAtom'       : StringToAtom
   'StringToInt'        : StringToInt
   'StringToFloat'      : StringToFloat
   %%
   %% Char
   %%
   'Boot_Char'          : Boot_Char
   'IsChar'             : IsChar
   %%
   %% Int
   %%
   'Boot_Int'           : Boot_Int
   'IsInt'              : IsInt
   'IntToFloat'         : IntToFloat
   'IntToString'        : IntToString
   %%
   %% Float
   %%
   'Boot_Float'         : Boot_Float
   'IsFloat'            : IsFloat
   'Exp'                : Exp
   'Log'                : Log
   'Sqrt'               : Sqrt
   'Ceil'               : Ceil
   'Floor'              : Floor
   'Round'              : Round
   'Sin'                : Sin
   'Cos'                : Cos
   'Tan'                : Tan
   'Asin'               :  Asin
   'Acos'               : Acos
   'Atan'               : Atan
   'Atan2'              : Atan2
   'FloatToInt'         : FloatToInt
   'FloatToString'      : FloatToString
   %%
   %% Number
   %%
   'Boot_Number'        : Boot_Number
   'IsNumber'           : IsNumber
   'Abs'                : Abs
   %%
   %% Tuple
   %%
   'Boot_Tuple'         : Boot_Tuple
   'MakeTuple'          : MakeTuple
   'IsTuple'            : IsTuple
   %%
   %% Procedure
   %%
   'Boot_Procedure'     : Boot_Procedure
   'IsProcedure'        : IsProcedure
   'ProcedureArity'     : ProcedureArity
   %%
   %% Dictionary
   %%
   'Boot_Dictionary'    : Boot_Dictionary
   'IsDictionary'       : IsDictionary
   'NewDictionary'      : NewDictionary
   %%
   %% Record
   %%
   'Boot_Record'        : Boot_Record
   'IsRecord'           : IsRecord
   'Label'              : Label
   'Width'              : Width
   'Adjoin'             : Adjoin
   'Arity'              : Arity
   'AdjoinList'         : AdjoinList
   'AdjoinAt'           : AdjoinAt
   'IsRecordC'          : IsRecordC
   'WidthC'             : WidthC
   'TellRecord'         : TellRecord
   %%
   %% Chunk
   %%
   'Boot_Chunk'         : Boot_Chunk
   'IsChunk'            : IsChunk
   'NewChunk'           : NewChunk
   %%
   %% VirtualString
   %%
   'Boot_VirtualString' : Boot_VirtualString
   'IsVirtualString'    : IsVirtualString
   %%
   %% Array
   %%
   'Boot_Array'         : Boot_Array
   'NewArray'           : NewArray
   'IsArray'            : IsArray
   'Put'                : Put
   'Get'                : Get
   %%
   %% Space
   %%
   'Boot_Space'         : Boot_Space
   'IsSpace'            : IsSpace
   %%
   %% Object
   %%
   'Boot_Object'        : Boot_Object
   'IsObject'           : IsObject
   'New'                : New
   '`ooFreeFlag`'       : `ooFreeFlag`
   '`ooParents`'        : `ooParents`
   '`ooPrintName`'      : `ooPrintName`
   '`ooMeth`'           : `ooMeth`
   '`ooAttr`'           : `ooAttr`
   '`ooLocking`'        : `ooLocking`
   '`ooNative`'         : `ooNative`
   '`ooUnFreeFeat`'     : `ooUnFreeFeat`
   '`ooFreeFeatR`'      : `ooFreeFeatR`
   %% these should not be reexported
   '`ooNewAttr`'        : `ooNewAttr`
   '`ooNewFeat`'        : `ooNewFeat`
   '`ooFastMeth`'       : `ooFastMeth`
   '`ooNewMeth`'        : `ooNewMeth`
   '`ooDefaults`'       : `ooDefaults`
   '`ooFallback`'       : `ooFallback`
   '`ooId`'             : `ooId`
   %%
   %% Class
   %%
   'Boot_Class'         : Boot_Class
   %%
   %% BitArray
   %%
   'Boot_BitArray'      : Boot_BitArray
   'IsBitArray'         : IsBitArray
   %%
   %% ForeignPointer
   %%
   'Boot_ForeignPointer': Boot_ForeignPointer
   'IsForeignPointer'   : IsForeignPointer
   %%
   %% Thread
   %%
   'Boot_Thread'        : Boot_Thread
   'IsThread'           : IsThread
   %%
   %% Exception
   %%
   'Boot_Exception'     : Boot_Exception
   'Raise'              : Raise
   '`Raise`'            : `Raise`
   '`RaiseError`'       : `RaiseError`
   %%
   %% Time
   %%
   'Boot_Time'          : Boot_Time
   'Alarm'              : Alarm
   'Delay'              : Delay
   %%%
   %%% BitString ByteString
   %%%
   'Boot_BitString'     : Boot_BitString
   'Boot_ByteString'    : Boot_ByteString
   'IsBitString'        : IsBitString
   'IsByteString'       : IsByteString
define
   %%
   %% Value
   %%
   Wait         = Boot_Value.wait
   WaitOr       = Boot_Value.waitOr
   IsFree       = Boot_Value.isFree
   IsKinded     = Boot_Value.isKinded
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
   Exchange     = Boot_Cell.exchange
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
   IsObject     = Boot_Object.is
   New          = Boot_Object.new
   `ooMeth`     = {NewUniqueName 'ooMeth'}
   `ooAttr`     = {NewUniqueName 'ooAttr'}
   `ooLocking`  = {NewUniqueName 'ooLocking'}
   `ooNative`   = {NewUniqueName 'ooNative'}
   `ooParents`  = {NewUniqueName 'ooParents'}
   `ooFreeFlag` = {NewUniqueName 'ooFreeFlag'}
   `ooPrintName`= {NewUniqueName 'ooPrintName'}
   `ooUnFreeFeat`= {NewUniqueName 'ooUnFreeFeat'}
   `ooFreeFeatR`= {NewUniqueName 'ooFreeFeatR'}
   `ooNewAttr`  = {NewUniqueName 'ooNewAttr'}
   `ooNewFeat`  = {NewUniqueName 'ooNewFeat'}
   `ooFastMeth` = {NewUniqueName 'ooFastMeth'}
   `ooNewMeth`  = {NewUniqueName 'ooNewMeth'}
   `ooDefaults` = {NewUniqueName 'ooDefaults'}
   `ooFallback` = {NewUniqueName 'ooFallback'}
   `ooId`       = {NewUniqueName 'ooId'}
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
   `Raise`      = Boot_Exception.'raise'
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
end
