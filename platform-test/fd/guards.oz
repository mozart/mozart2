fun {$ IMPORT}
   \insert '../lib/import.oz'

   MiscTest =
   fun {$ N T}
      L = {StringToAtom {VirtualString.toString N}}
   in
      L(equal(T 1) keys: [fd])
   end


in
   fd([guards([
               {MiscTest 1
                fun {$} X Y R in
                   X::0#10 Y::0#10
                   R = thread if X=<:Y then 1 else 0 end end
                   X<:4
                   Y>:4
                   R
                end}
% yes

               {MiscTest 2
                fun {$} X Y R in
                   X::0#10 Y::0#10
                   R = thread if X=<:Y then 0 else 1 end end
                   X>:6
                   Y<:4
                   R
%no
                end}

               {MiscTest 3
                fun {$} R X in
                   X :: 0#6
                   R = thread if Y in Y::6#10 X<:Y then 1 else 0 end end
                   X<:6
                   R
% yes
                end}


               {MiscTest 4
                fun {$} R X in
                   X :: 0#6
                   R = if Y in Y::8#10 X<:Y then 1 else 0 end
                   R
% yes
                end}

               {MiscTest 5
                fun {$} R X in
                   X :: 6#10
                   R = if Y in Y::0#4 X<:Y then 0 else 1 end
%no
                   R
                end}

               {MiscTest 6
                fun {$}
                   if X Y in X::0#4 Y::8#10 X+2=<:Y then 1 else 0 end
                end}
% yes

               {MiscTest 7
                fun {$} R X Y Z in
                   [X Y Z] = {FD.dom 0#10}
                   R = thread if X+Y =: Z then 0 else 1 end end
                   [X Y] = {FD.dom 0#2}
                   Z>:6
                   R
% no
                end}

               {MiscTest 8
                fun {$} R X Y Z in
                   [X Y Z] = {FD.dom 0#10}
                   R = thread if X+Y =: Z then 1 else 0 end end
                   [X Y] = {FD.dom 0#2}
                   Z=4
                   X=2
                   Y=2
                   R
% yes
                end}

               {MiscTest 9
                fun {$} R X Y in
                   [X Y] = {FD.dom 0#10}
                   R = thread if X*X =: Y then 1 else 0 end end
                   Y=9
                   X=3
                   R
% yes
                end}

               {MiscTest 10
                fun {$} R X Y in
                   [X Y] = {FD.dom 0#10}
                   R = thread if {FD.times X X Y} then 0  else 1 end end
                   X::1#2
                   Y>:5
                   R
% no
                end}

               {MiscTest 11
                fun {$} R X Y Z in
                   {ForAll [X Y Z] proc {$ X} X :: 0#FD.sup end}
                   R = thread if X+Y+2 =<: Z then 1 else 0 end end
                   [X Y] = {FD.dom 3#5}
                   Z>:15
                   R
% yes
                end}

               {MiscTest 12
                fun {$} R X Y Z in
                   [X Y Z] = {FD.dom  0#10}
                   R = thread if {FD.atMost 2 [X Y Z] 5} then 1 else 0 end end
                   Z=5 Y=5
                   X\=:5
                   R
% yes
                end}

               {MiscTest 13
                fun {$} R X L in X::0#10 L=4
                   R = thread if X\=:L then 1 else 0 end end
                   X \=: 4
                   R
                end}

               {MiscTest 14
                fun {$} R X Y in
                   X::[1 2 10 19 20] Y::[5 6 15 25]
                   or X+3>:Y
                      Y+3>:X  then 0
                   [] skip then 1
                   end
                end}

               {MiscTest 15
                fun {$} R X Y in
                   X::[1 2 10 17 19 20] Y::[5 6 15 25]
                   R = thread if X+3>:Y Y+3>:X then 1 else 0 end end
                   X = 17
                   Y = 15
                   R
                end}

               {MiscTest 16
                fun {$}
                   if {FD.reflect.domList
                       {FD.list 1 [2000#3000 1#1000 2500#4000 500#1500 600#700]}.1}
                      =
                      {FD.reflect.domList
                       {FD.list 1 [2500#4000 500#1500 600#700 2000#3000 1#1000]}.1}
                      {Length {FD.reflect.dom {FD.list 1 [0 1#3 2#5 100#3030 3031]}.1}} = 2
                   then 1 else 0 end
                end}

               {MiscTest 17
                fun {$} R X Y in
                   X :: [0#1 10#20]
                   Y :: [0#1 30#40]
                   R = thread if X = Y then 1 else 0 end end
                   X = Y
                   R
                end}

              ])
      ])

end
