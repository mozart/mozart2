%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1997-1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% CycleManager Functor
%%%

functor $

import
   System(eq)

export
   cycleManager : CycleManager

define
   class CycleManager
      from
         BaseObject

      attr
         items  %% Items List
         index  %% Current Items Count
         stack  %% Stack

      meth create
         @items = nil
         @index = 0
         @stack = nil
      end

      meth push
         stack <- @items#@index#@stack
      end

      meth pop
         Items#Index#NStack = @stack
      in
         items <- Items
         index <- Index
         stack <- NStack
      end

      meth register(Value Node $)
         Index = (@index + 1)
         RAtom = 'R'#Index
      in
         index <- Index
         items <- (Value|Node|RAtom)|@items
         RAtom
      end

      meth get(Value $)
         CycleManager, seek(Value @items $)
      end

      meth seek(Value Is $)
         case Is
         of (IVal|Node|IR)|Ir then
            if {System.eq Value IVal}
            then Node|IR
            else CycleManager, seek(Value Ir $)
            end
         [] nil          then nil
         end
      end

      meth tellStack(Node)
         StackVal = @items#@index
      in
         {Node setStack(StackVal)}
      end

      meth getStack(Node)
         StackVal = @items#@index
      in
         {Node setStack(StackVal)}
      end

      meth setStack(Stack)
         Items#Index = Stack
      in
         items <- Items
         index <- Index
         stack <- nil
      end
   end
end
