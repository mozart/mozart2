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

   Boot_System    at 'x-oz://boot/System'
   Boot_Space     at 'x-oz://boot/Space'

prepare

   %%
   %% Value
   %%
   Wait   = Boot_Value.wait
   IsDet  = Boot_Value.isDet
   Max    = fun {$ A B} if A < B then B else A end end
   Min    = fun {$ A B} if A < B then A else B end end

   %%
   %% Cell
   %%
   NewCell  = Boot_Cell.new
   Exchange = proc {$ C Old New} Old = {Boot_Cell.exchangeFun C New} end
   Assign = Boot_Cell.assign
   Access = Boot_Cell.access

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
   %% System
   %%
   Show = Boot_System.show

   %%
   %% Modules
   %%

   Value = value(
      wait:            Wait

      '==':            Boot_Value.'=='
      '=':             proc {$ L R} L = R end
      '\\=':           Boot_Value.'\\='

      '.':             Boot_Value.'.'

      isDet:           IsDet

      '=<':            Boot_Value.'=<'
      '<':             Boot_Value.'<'
      '>=':            Boot_Value.'>='
      '>':             Boot_Value.'>'
      max:             Max
      min:             Min
   )

   Cell = cell(
      new:      NewCell
      exchange: Exchange
      assign:   Assign
      access:   Access
   )

   fun {IsOdd X}  X mod 2 \= 0 end
   fun {IsEven X} X mod 2 == 0 end

   Int = int(
      isOdd:    IsOdd
      isEven:   IsEven
      'div':    Boot_Int.'div'
      'mod':    Boot_Int.'mod'
   )

   Float = float(
      '/':      Boot_Float.'/'
   )

   Number = number(
      '+': Boot_Number.'+'
      '-': Boot_Number.'-'
      '*': Boot_Number.'*'
   )

   Tuple = tuple(
      make: Boot_Tuple.make
   )

   Record = record(
      label: Boot_Record.label
      width: Boot_Record.width
      arity: Boot_Record.arity
      clone: Boot_Record.clone
      waitOr: Boot_Record.waitOr
      makeDynamic: Boot_Record.makeDynamic
   )

   System = system(
      show: Boot_System.show
   )

   Space = space(
      new: Boot_Space.new
      ask: Boot_Space.ask
      askVerbose: Boot_Space.askVerbose
      merge: Boot_Space.merge
      clone: Boot_Space.clone
      commit: Boot_Space.commit
      choose: Boot_Space.choose
   )

#include "List.oz"

end
