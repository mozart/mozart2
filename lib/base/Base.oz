functor

require
   Boot_Value     at 'x-oz://boot/Value'
   Boot_Cell      at 'x-oz://boot/Cell'
   Boot_Int       at 'x-oz://boot/Int'
   Boot_Float     at 'x-oz://boot/Float'
   Boot_Number    at 'x-oz://boot/Number'
   Boot_Tuple     at 'x-oz://boot/Tuple'
   Boot_Record    at 'x-oz://boot/Record'
   Boot_Thread    at 'x-oz://boot/Thread'
   Boot_Exception at 'x-oz://boot/Exception'

   Boot_System    at 'x-oz://boot/System'
   Boot_Space     at 'x-oz://boot/Space'

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
   ByNeed       = proc {$ P X} thread {WaitNeeded X} {P X} end end
   ByNeedFuture = fun {$ P}
                     !!{ByNeed fun {$}
                                  try {P}
                                  catch E then {FailedValue E}
                                  end
                               end}
                  end

   %%
   %% Unit
   %%
   IsUnit = fun {$ X} X == unit end

   %%
   %% Cell
   %%
   NewCell  = Boot_Cell.new
   Exchange = proc {$ C Old New} Old = {Boot_Cell.exchangeFun C New} end
   Assign = Boot_Cell.assign
   Access = Boot_Cell.access

   %%
   %% Lock
   %%
   local
      LockUUID = '2435687f-b0e9-47aa-bbfc-7a05e5a95d2b'
   in
      fun {IsLock X}
         case X
         of 'lock'(1:_ 2:ID) then
            ID == LockUUID
         else
            false
         end
      end

      fun {NewLock}
         CurrentThread = {NewCell unit}
         Token = {NewCell unit}
         proc {Lock P}
            ThisThread = {Boot_Thread.this}
         in
            if ThisThread == @CurrentThread then
               {P}
            else
               NewToken
            in
               try
                  {Wait Token := NewToken}
                  CurrentThread := ThisThread
                  {P}
               finally
                  CurrentThread := unit
                  NewToken = unit
               end
            end
         end
      in
         'lock'(1:Lock 2:LockUUID)
      end
   end

   %%
   %% Port
   %%
   local
      PortUUID = '3732bd80-df5d-482a-9d95-8662cbfcd234'
   in
      fun {IsPort X}
         case X
         of port(1:_ 2:ID) then
            ID == PortUUID
         else
            false
         end
      end

      fun {NewPort ?S}
         Head
         Tail = {NewCell Head}
         proc {Send X}
            NewTail
         in
            {Exchange Tail X|!!NewTail NewTail}
         end
      in
         S = !!Head
         port(1:Send 2:PortUUID)
      end

      proc {Send P X}
         if {IsPort P} then
            {P.1 X}
         else
            raise typeError('port' P) end
         end
      end

      proc {SendRecv P X Y}
         {Send P X#Y}
      end
   end

   %%
   %% Bool
   %%
   IsBool = fun {$ X} X == true orelse X == false end
   Not    = fun {$ X} if X then false else true end end
   And    = fun {$ X Y} X andthen Y end
   Or     = fun {$ X Y} X orelse Y end

   %%
   %% Tuple
   %%
   MakeTuple = Boot_Tuple.make

   %%
   %% Record
   %%
   Arity  = Boot_Record.arity
   Label  = Boot_Record.label
   Width  = Boot_Record.width

   %%
   %% Thread
   %%
   IsThread = Boot_Thread.is

   %%
   %% Exception
   %%
   Raise = Boot_Exception.'raise'

   %%
   %% System
   %%
   Show = Boot_System.show

#include "Exception.oz"
#include "Value.oz"
%#include "Literal.oz"
#include "Unit.oz"
#include "Lock.oz"
#include "Cell.oz"
#include "Port.oz"
%#include "Atom.oz"
%#include "Name.oz"
#include "Bool.oz"
%#include "String.oz"
%#include "Char.oz"
#include "Int.oz"
#include "Float.oz"
#include "Number.oz"
#include "Tuple.oz"
#include "List.oz"
%#include "Procedure.oz"
%#include "Loop.oz"
%#include "WeakDictionary.oz"
%#include "Dictionary.oz"
#include "Record.oz"
%#include "Chunk.oz"
%#include "VirtualString.oz"
%#include "Array.oz"
%#include "Object.oz"
%#include "BitArray.oz"
%#include "ForeignPointer.oz"
#include "Thread.oz"

#include "Space.oz"
#include "System.oz"

end
