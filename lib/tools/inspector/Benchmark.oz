declare

local
   fun {DiffTime T1 T2}
      {Record.zip T2 T1 Number.'-'}
   end

   fun {TakeTime P}
      T1 T2
   in
      {System.gcDo}
      {System.gcDo}
      {System.gcDo}
      {System.gcDo}
      T1 = {OS.localTime}
      {P}
      T2 = {OS.localTime}
      {DiffTime T1 T2}
   end
in
   class Bench
      from
         BaseObject

      meth perform(B $)
         {TakeTime proc {$}
                      {self B}
                   end}
      end

      meth diff(B1 B2 $)
         T1 = Bench, perform(B1 $)
         T2 = Bench, perform(B2 $)
      in
         {DiffTime T1 T2}
      end

      meth staticCall(I)
         case I
         of 0 then skip
         else Bench, staticCall((I - 1))
         end
      end

      meth dynCall(I)
         case I
         of 0 then skip
         else {self dynCall((I - 1))}
         end
      end

      meth argCheck(IT)
         A|I = IT
      in
         case A
         of 1 then
            Bench, performSArg(I)
         [] 2 then
            Bench, performDArg(1 I)
         end
      end

      meth gargelCall(A B C)
         skip
      end

      meth performSArg(I)
         case I
         of 0 then skip
         else
            {self gargelCall(1 2 3)}
            Bench, performSArg((I - 1))
         end
      end

      meth performDArg(A I)
         case I
         of 0 then skip
         else
            {self gargelCall(1 2 3)}
            Bench, performDArg(A (I - 1))
         end
      end
   end

   BO = {New Bench noop}
end

{System.gcDo}{System.gcDo}{System.gcDo}{System.gcDo}

{BO performSArg(100000)}
{BO performDArg(0 100000)}
