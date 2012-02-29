local
   fun {Fibonacci N}
      if N == 0 then
         0
      elseif N == 1 then
         1
      else
         thread {Fibonacci N-1} end + {Fibonacci N-2}
      end
   end
in
   {Show {Fibonacci 10}}
end
