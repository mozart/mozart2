functor

import

   FD Space Search

export
   Return
define


   MiscTest =
   fun {$ N T}
      L = {StringToAtom {VirtualString.toString N}}
   in
      L(equal(T 1) keys: [fd])
   end


Return=
   fd([dsum([

             {MiscTest 1
              fun {$} A B C in [A B C]:::0#10
                 {FD.sumC [1 2] [A B] '<:' 10}
                 {FD.sumCD [~1 1] [A C] '=:' 0}
                 {FD.sumC [1 1] [C B] '>=:' 9}
                 thread cond A#C:::9 B::0 then 1 else 0 end end
              end
             }

% Equality with simplification

             {MiscTest 2
              fun {$} A B C in [A B C]:::0#10
                 {FD.sumCD [999 3 ~999 60 2] [A A A B C] '=:' 5}
                 thread cond A#C:::1 B::0 then 1 else 0 end end
              end
             }

% Inequality

             {MiscTest 3
              fun {$} A B C in [A B C]:::0#3

                 {FD.sumCD [1 2 1] [A B C] '\\=:' 6}
                 A=:2
                 B=:2
                 C=:2
                 thread cond C::2 then 1 else 0 end end
              end
             }


% Large Numbers, two intervals

             {MiscTest 4
              fun {$} A B C in [A B C] ::: 0#FD.sup
                 A\=:1000 B\=:1000 C\=:1000
                 {FD.sumC [1 2 3] [A B C] '<:' 10}
                 thread cond A::0#9 B::0#4 C::0#3 then 1 else 0 end end
              end
             }


% Test if SEND MORE MONEY gets to the first choice point

             {MiscTest 5
              fun {$} S E N D M O R Y in [S E N D M O R Y] ::: 0#9
                 {FD.distinct [S E N D M O R Y]}
                 {FD.sumCD [1] [S] '\\=:' 0}
                 {FD.sumCD [1] [M] '\\=:' 0}
                 M \=: 0
                 S \=: 0
                 {FD.sumCD [1000 100 10 1 1000 100 10 1 ~10000 ~1000 ~100 ~10 ~1]
                  [S    E   N  D M    O   R  E  M      O     N    E   Y]
                  '=:'
                  0}
                 thread cond S::9 [E N D R Y]:::0#8 M::1#2 O::0#1 then 1 else 0 end end
              end
             }

% test that sumD actually wakes up when holes appear in the domains of its parameters

             {MiscTest 6
              fun {$}
                 case {Search.base.all
                       proc {$ D}
                          L X1 X2 X3 Y
                       in
                          L = [X1 X2 X3]
                          L:::1#3
                          Y::0#9
                          {FD.sumD L '=:' Y}
                          X1\=:2
                          X2\=:2
                          X3\=:2
                          {Space.waitStable}
                          D={FD.reflect.domList Y}
                       end}
                 of [[3 5 7 9]] then 1 else 0 end
              end}

% test that sumCD actually wakes up when holes appear in the domains of its parameters

             {MiscTest 7
              fun {$}
                 case {Search.base.all
                       proc {$ D}
                          L X1 X2 X3 Y
                       in
                          L = [X1 X2 X3]
                          L:::1#3
                          Y::0#100
                          {FD.sumCD [1 2 4] L '=:' Y}
                          X1\=:2
                          X2\=:2
                          X3\=:2
                          {Space.waitStable}
                          D={FD.reflect.domList Y}
                       end}
                 of [[7 9 11 13 15 17 19 21]] then 1 else 0 end
              end}

            ])
      ])

end
