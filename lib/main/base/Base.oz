%% Copyright © 2012, Université catholique de Louvain
%% All rights reserved.
%%
%% Redistribution and use in source and binary forms, with or without
%% modification, are permitted provided that the following conditions are met:
%%
%% *  Redistributions of source code must retain the above copyright notice,
%%    this list of conditions and the following disclaimer.
%% *  Redistributions in binary form must reproduce the above copyright notice,
%%    this list of conditions and the following disclaimer in the documentation
%%    and/or other materials provided with the distribution.
%%
%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%% POSSIBILITY OF SUCH DAMAGE.


functor

require
   Boot_Value              at 'x-oz://boot/Value'
   Boot_Literal            at 'x-oz://boot/Literal'
   Boot_Cell               at 'x-oz://boot/Cell'
   Boot_Port               at 'x-oz://boot/Port'
   Boot_Atom               at 'x-oz://boot/Atom'
   Boot_Name               at 'x-oz://boot/Name'
   Boot_Int                at 'x-oz://boot/Int'
   Boot_Float              at 'x-oz://boot/Float'
   Boot_Number             at 'x-oz://boot/Number'
   Boot_Tuple              at 'x-oz://boot/Tuple'
   Boot_Procedure          at 'x-oz://boot/Procedure'
   Boot_Dictionary         at 'x-oz://boot/Dictionary'
   Boot_Record             at 'x-oz://boot/Record'
   Boot_Chunk              at 'x-oz://boot/Chunk'
   Boot_VirtualString      at 'x-oz://boot/VirtualString'
   Boot_VirtualByteString  at 'x-oz://boot/VirtualByteString'
   Boot_Coders             at 'x-oz://boot/Coders'
   Boot_Array              at 'x-oz://boot/Array'
   Boot_Object             at 'x-oz://boot/Object'
   Boot_Thread             at 'x-oz://boot/Thread'
   Boot_Exception          at 'x-oz://boot/Exception'
   Boot_Time               at 'x-oz://boot/Time'
   Boot_ForeignPointer     at 'x-oz://boot/ForeignPointer'
   Boot_CompactString      at 'x-oz://boot/CompactString'
   Boot_System             at 'x-oz://boot/System'
   Boot_Property           at 'x-oz://boot/Property'
   Boot_WeakRef            at 'x-oz://boot/WeakReference'

prepare

   %%
   %% Value
   %%
   Wait         = Boot_Value.wait
   WaitOr       = proc {$ X Y} {Boot_Record.waitOr X#Y _} end
   WaitQuiet    = Boot_Value.waitQuiet
   WaitNeeded   = Boot_Value.waitNeeded
   MakeNeeded   = Boot_Value.makeNeeded
   IsFree       = Boot_Value.isFree
   IsKinded     = Boot_Value.isKinded
   IsFuture     = Boot_Value.isFuture
   IsFailed     = Boot_Value.isFailed
   IsDet        = Boot_Value.isDet
   IsNeeded     = Boot_Value.isNeeded
   Max          = fun {$ A B} if A < B then B else A end end
   Min          = fun {$ A B} if A < B then A else B end end
   CondSelect   = Boot_Value.condSelect
   HasFeature   = Boot_Value.hasFeature
   FailedValue  = Boot_Value.failedValue
   NewReadOnly  = Boot_Value.newReadOnly
   BindReadOnly = Boot_Value.bindReadOnly
   ByNeed       = proc {$ P X} thread {WaitNeeded X} {P X} end end
   ByNeedFuture = proc {$ P X}
                     R = {NewReadOnly}
                  in
                     thread
                        {WaitNeeded R}
                        try Y in
                           {MakeNeeded Y}
                           {P Y}
                           {WaitQuiet Y}
                           {BindReadOnly R Y}
                        catch E then
                           {BindReadOnly R {FailedValue E}}
                        end
                     end
                     X = R
                  end
   ByNeedDot    = fun {$ X F}
                     if {IsDet X} andthen {IsDet F}
                     then try X.F catch E then {FailedValue E} end
                     else {ByNeedFuture fun {$} X.F end}
                     end
                  end

   %%
   %% Literal
   %%
   IsLiteral = Boot_Literal.is

   %%
   %% Unit
   %%
   IsUnit = fun {$ X} X == unit end

   %%
   %% Lock
   %%
   IsLock  % Defined in Lock.oz
   NewLock % Defined in Lock.oz
   LockIn  % Defined in Lock.oz

   %%
   %% Cell
   %%
   IsCell   = Boot_Cell.is
   NewCell  = Boot_Cell.new
   Exchange = proc {$ C Old New} Old = {Boot_Cell.exchangeFun C New} end
   Assign   = Boot_Cell.assign
   Access   = Boot_Cell.access

   %%
   %% Port
   %%
   IsPort   = Boot_Port.is
   NewPort  = Boot_Port.new
   Send     = Boot_Port.send
   SendRecv = Boot_Port.sendReceive

   %%
   %% Atom
   %%
   IsAtom              = Boot_Atom.is
   AtomToCompactString % Defined in Atom.oz
   AtomToString        % Defined in Atom.oz

   %%
   %% Name
   %%
   IsName        = Boot_Name.is
   NewName       = Boot_Name.new
   NewUniqueName = Boot_Name.newUnique % not exported

   %%
   %% Bool
   %%
   IsBool = fun {$ X} X == true orelse X == false end
   Not    = fun {$ X} if X then false else true end end
   And    = fun {$ X Y} X andthen Y end
   Or     = fun {$ X Y} X orelse Y end

   %%
   %% String
   %%
   IsString      % Defined in String.oz
   StringToAtom  % Defined in String.oz
   StringToInt   % Defined in String.oz
   StringToFloat % Defined in String.oz

   %%
   %% Char
   %%
   IsChar % Defined in Char.oz

   %%
   %% Int
   %%
   IsInt              = Boot_Int.is
   IntToFloat         % Defined in Int.oz
   IntToCompactString % Defined in Int.oz
   IntToString        % Defined in Int.oz

   %%
   %% Float
   %%
   IsFloat              = Boot_Float.is
   Exp                  = Boot_Float.exp
   Log                  = Boot_Float.log
   Sqrt                 = Boot_Float.sqrt
   Ceil                 = Boot_Float.ceil
   Floor                = Boot_Float.floor
   Sin                  = Boot_Float.sin
   Cos                  = Boot_Float.cos
   Tan                  = Boot_Float.tan
   Asin                 = Boot_Float.asin
   Acos                 = Boot_Float.acos
   Atan                 = Boot_Float.atan
   Atan2                = Boot_Float.atan2
   Round                = Boot_Float.round
   FloatToInt           = Boot_Float.toInt
   FloatToCompactString % Defined in Float.oz
   FloatToString        % Defined in Float.oz

   %%
   %% Number
   %%
   IsNumber = Boot_Number.is
   Pow      = Boot_Number.pow
   Abs      = Boot_Number.abs

   %%
   %% Tuple
   %%
   IsTuple   = Boot_Tuple.is
   MakeTuple = Boot_Tuple.make

   %%
   %% Procedure
   %%
   IsProcedure    = Boot_Procedure.is
   ProcedureArity = Boot_Procedure.arity

   %%
   %% Weak Dictionary
   %%
   IsWeakDictionary  % Defined in WeakDictionary.oz
   NewWeakDictionary % Defined in WeakDictionary.oz

   %%
   %% Dictionary
   %%
   IsDictionary  = Boot_Dictionary.is
   NewDictionary = Boot_Dictionary.new

   %%
   %% Record
   %%
   IsRecord   = Boot_Record.is
   Arity      = Boot_Record.arity
   Label      = Boot_Record.label
   Width      = Boot_Record.width
   Adjoin     % Defined in Record.oz
   AdjoinAt   % Defined in Record.oz
   AdjoinList % Defined in Record.oz

   %%
   %% Chunk
   %%
   IsChunk  = Boot_Chunk.is
   NewChunk = Boot_Chunk.new

   %%
   %% VirtualString
   %%
   IsVirtualString = Boot_VirtualString.is

   %%
   %% VirtualByteString
   %%
   IsVirtualByteString = Boot_VirtualByteString.is

   %%
   %% Array
   %%
   NewArray = Boot_Array.new
   IsArray  = Boot_Array.is
   Put      = Boot_Array.put
   Get      = Boot_Array.get

   %%
   %% Object, Class, and OoExtensions
   %%
   IsObject      = Boot_Object.is
   New           % defined in Object.oz
   IsClass       % defined in Object.oz
   BaseObject    % defined in Object.oz
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
   %% Object lock
   `ooObjLock`   = {NewUniqueName 'ooObjLock'}

   %%
   %% BitArray
   %%
   IsBitArray % Defined in BitArray.oz

   %%
   %% ForeignPointer
   %%
   IsForeignPointer = Boot_ForeignPointer.is

   %%
   %% Thread
   %%
   IsThread = Boot_Thread.is

   %%
   %% Exception
   %%
   Raise = Boot_Exception.'raise'

   %%
   %% Time
   %%
   Alarm = Boot_Time.alarm
   Delay = proc {$ T} {Wait {Alarm T}} end

   %%
   %% CompactString BitString ByteString
   %%
   IsCompactString     = Boot_CompactString.isCompactString
   IsCompactByteString = Boot_CompactString.isCompactByteString
   IsBitString         % Defined in BitString.oz
   IsByteString        = Boot_CompactString.isCompactByteString

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
   \insert 'VirtualByteString.oz'
   \insert 'Coders.oz'
   \insert 'Array.oz'
   \insert 'Object.oz'
   \insert 'BitArray.oz'
   \insert 'ForeignPointer.oz'
   \insert 'Thread.oz'
   \insert 'Time.oz'
   \insert 'Functor.oz'
   \insert 'CompactString.oz'
   \insert 'CompactByteString.oz'
   \insert 'BitString.oz'
   \insert 'ByteString.oz'

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
   %% VirtualByteString
   'VirtualByteString'  : VirtualByteString
   'IsVirtualByteString': IsVirtualByteString
   %% Coders
   'Coders'             : Coders
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
   %% CompactString
   'CompactString'      : CompactString
   'IsCompactString'    : IsCompactString
   %% CompactByteString
   'CompactByteString'  : CompactByteString
   'IsCompactByteString': IsCompactByteString
   %% BitString
   'BitString'          : BitString
   'IsBitString'        : IsBitString
   %% ByteString
   'ByteString'         : ByteString
   'IsByteString'       : IsByteString

   %% Will be removed by the compiler
   'ByNeedDot'          : ByNeedDot
   'LockIn'             : LockIn
   'OoExtensions'       : OoExtensions
   '`ooFreeFlag`'       : `ooFreeFlag`
   '`ooFallback`'       : `ooFallback`

end
