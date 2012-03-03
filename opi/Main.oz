local
   proc {ShowList L}
      if nil \= L then
         {Show L.1}
         {ShowList L.2}
      end
   end

   fun {FibList N}
      fun {FibListEx N Acc1 Acc2}
         if N == 0 then
            nil
         else
            Acc1 | {FibListEx N-1 Acc2 Acc1+Acc2}
         end
      end
   in
      {FibListEx N 0 1}
   end

   List = {FibList 10}
in
   {ShowList List}
end
