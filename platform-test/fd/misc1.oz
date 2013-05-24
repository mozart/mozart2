functor

import

   FD

   Search


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
   fd([misc1([
	     
	     {MiscTest 1
	      fun {$}
		 cond X Y in [X Y]:::1#1000
		    Y<:X 
		    X<:Y
		 then 0 else 1 end
	      end}
	     
	     {MiscTest 3
	      fun{$}
		 N = 20 L = {List.make N} S R in
		 L ::: 0#FD.sup
		 S :: 0#FD.sup
		 R = thread cond {FD.sum L '=:' S} then 1 else 0 end end
		 {ForAll L proc {$ X} X = 1 end}
		 S = N
		 R
	      end}

	     {MiscTest 4
	      fun {$}
		 cond X in X::0#1 X::1#2 then 1 else 0 end
	      end}

	     {MiscTest 5
	      fun {$}
		 cond X in X::0#1 X::2#3 then 0 else 1 end
	      end}
     
	     {MiscTest 6
	      fun {$}
		 cond X in X::0#1 X::1 then 1 else 0 end
	      end}
     
	     {MiscTest 7
	      fun {$}
		 cond X in X::0#10 X::20#25 then 0 else 1 end
	      end}
	     
	     {MiscTest 8
	      fun {$} X Y in
		 thread X :: 1#Y end
		 Y=9
		 thread cond X :: [1#9] then 1 else 0 end end
	      end}
	     
	     {MiscTest 9
	      fun {$}  X in [X]:::0#10
		 thread cond {FD.atMost X nil 3} then 1 else 0 end end
	      end}
	     
	     {MiscTest 10
	      fun {$} L X Y Z in L=[X Y Z] L:::0#10
		 {FD.atMost 2 r(a:X b:Y c:Z) 1}
		 X=1
		 Z=1
		 thread cond Y :: [0 2#10] then 1 else 0 end end 
	      end}
     
	     {MiscTest 11
	      fun {$} L X Y Z R in  L=[X Y Z] L:::0#10
		 thread R = cond {FD.atMost 2 r(a:X b:Y c:Z) 1}
			    then 1 else 0 end end
		 X\=:1
		 R
	      end}

	     {MiscTest 12
	      fun {$} L X Y Z R in L=[X Y Z] L:::0#10
		 thread R = cond {FD.atMost 2 r(a:X b:Y c:Z) 1}
			    then 0 else 1 end end
		 Z=1
		 Y=1
		 X=1
		 R
	      end}

	     {MiscTest 13
	      fun {$} X in X::0#10
		 {FD.atLeast X '#' 2}
		 thread cond X=0 then 1 else 0 end end
	      end}
		
	     {MiscTest 14
	      fun {$} R L X Y Z V in L=[X Y Z] L:::0#10 V::0#10
		 {FD.atLeast V r(a:X b:Y c:Z) 1}
		 thread R = cond Y = 1 then 1 else 0 end end
                    % V in 0#3	
		 X=1
                    % V in 0#3 
		 Z\=:1
                    % V in 0#2
		 V=2
                    % Y=1
		 R
	      end}
	     
	     {MiscTest 15
	      fun {$} X R in X::1#4 
		 thread R = cond {FD.element X 1#0#0#1 1} then 0 else 1 end end
		 X::2#3
		 R
	      end}
	     
	     {MiscTest 16
	      fun {$} X Y R in [X Y] ::: 0#10
		 {FD.sumAC [1 ~1] [X Y] '>=:' 8}
		 thread R = cond Y::[9#10] then 1 else 0 end end
                    % X,Y in [0#2 8#10]
		 X=1
                    %Y in 9#10
		 R
	      end}

	     {MiscTest 17
	      fun {$} X Y R in [X Y] ::: 0#10
		 {FD.sumAC [1 ~1] [X Y] '=:' 8}
		 thread R = cond 9 = Y then 1 else 0 end end
                    % X,Y in [0#2 8#10]
		 X=1
                    % Y=9
		 R
	      end}
	     
	     {MiscTest 18
	      fun {$} X Y R in [X Y] ::: 0#10
		 {FD.sumAC [1 ~1] [X Y] '>:' 8}
		 thread R = cond 10 = Y then 1 else 0 end end
                    % X,Y in [0#1 9#10]
		 X=1
                    %Y = 10
		 R
	      end}
	     
	     {MiscTest 19
	      fun {$} X Y in [X Y] ::: 0#10
		 {FD.sumAC [1 1] [X Y] '=<:' 3}
		 thread cond [X Y] ::: 0#3 then 1 else 0 end end
	      end}
	     
	     {MiscTest 20
	      fun {$} X Y in [X Y] ::: 0#10
		 {FD.sumAC [1 1] [X Y] '<:' 3}
		 thread cond [X Y] ::: 0#2 then 1 else 0 end end
	      end}
	     
	     {MiscTest 21
	      fun {$} X Y B in [X Y] ::: 0#10 B::0#1
		 B = {FD.reified.sumAC [1 ~1] [X Y] '>:' 5}
		 X<:2 Y>:8
		 thread cond  B = 1 then 1 else 0 end end
	      end}
	     
	     {MiscTest 22
	      fun {$} X Y B in [X Y] ::: 0#10 B::0#1
		 B = {FD.reified.sumAC [1 ~1] [X Y] '<:' 5}
		 X<:2 Y<:5
		 thread cond B = 1 then 1 else 0 end end
	      end}
	     
	     {MiscTest 23
	      fun {$} X Y B in [X Y] ::: 0#10 B::0#1
		 B = {FD.reified.sumAC [1 ~1] [X Y] '>:' 5}
		 X>:7 Y>:7
		 thread cond B = 0 then 1 else 0 end end
	      end}

	      /*
	     {MiscTest 24
	      fun {$} R X Y Z in [X Y Z]:::0#10
		 {FD.sumACN [1 ~1] [[X Y] [Z]] '>:' 8}
		 thread R = cond X :: [0#1 9#10]
			       Z :: [0#1 9#10]
			    then 1 else 0 end
		 end
		 Y=1
                    % X,Z in  [0#1 9#10]
		 R
	      end}

	     {MiscTest 25
	      fun {$} X Y Z in [X Y Z ] ::: 1#10
		 {FD.sumACN [1 1] [[X Y] [Z]] '=<:' 3}
		 thread cond X :: [1#2]
			   Y :: [1#2]
			   Z :: [1#2] then 1 else 0 end end
                    % X,Y,Z in 1#2
	      end}
	     
	     {MiscTest 26
	      fun {$} X Y Z B in [X Y Z] ::: 0#10 B::0#1
		 B = {FD.reified.sumACN [1 ~1] [[X Y]  [Z]] '>:' 5}
		 X>:7 Z>:7
		 Y=1
		 thread cond B = 0 then 1 else 0 end end
	      end}

	      */
	      
	     {MiscTest 27
	      fun {$} X Y in [X Y] ::: 0#10
		 {FD.sum [X Y] '<:' 3}
                    % X,Y in 0#2
		 thread cond [X Y] ::: 0#2 
			then 1 else 0 end end
	      end}
	     
	     {MiscTest 28
	      fun {$}
		 thread cond {FD.sum nil '<:' 3} then 1 else 0 end end
	      end}
	     
	     {MiscTest 29
	      fun {$} R X Y in [X Y]:::0#10
		 {FD.sumCN 1#1 '#'([X X] a(a:Y b:Y)) '=:' 25}
		 thread R = cond Y :: 3#7 then 1 else 0 end end 
		 X=2
                    % Y in 3#7
		 R
	      end}
	     
	     {MiscTest 30
	      fun {$} X Y in [X Y]:::0#10
		 {FD.sumCN a(1) [a(a:X b:Y)] '>:' 15}
		 thread cond [X Y] ::: 2#10 then 1 else 0 end end
	      end}
	     
	     {MiscTest 31
	      fun {$} X Y in [X Y]:::0#10
		 {FD.sumCN 1#1 '#'([X] a(a:Y b:Y)) '>:' 25}
		 thread cond X::0#10 Y::2#10 then 1 else 0 end end
	      end}
	     
	     {MiscTest 32
	      fun {$}  X Y Z in [X Y Z]:::0#10
		 {FD.sumCN 1#1 '#'([X] a(a:Y b:Z)) '>:' 25}
		 thread cond X :: 0#10 [Y Z] ::: 2#10 then 1 else 0  end end
	      end}
	     
	     {MiscTest 33
	      fun {$} X Y in [X Y]:::0#10
		 {FD.sumC 1#4 [X Y] '<:' 5}
                    % X in 0#4, Y in 0#1
		 thread cond X ::0#4 Y::0#1 then 1 else 0 end end
	      end}
	     
	     {MiscTest 34
	      fun {$} X Y in [X Y]:::0#10
		 {FD.distance X Y '>:' 8}
                    % X,Y in [0#1 9#10]}
		 thread cond [X Y] ::: [0#1 9#10] then 1 else 0 end end
	      end}

	     {MiscTest 35
	      fun {$}  X in [X]:::0#10
		 thread cond {FD.distance X X '>:' 8} then 0 else 1 end end
	      end}
	     
	     {MiscTest 36
	      fun {$}  X in [X]:::0#10
		 thread cond {FD.distance X X '=:' 0} then 1 else 0 end end
	      end}
	     
	     {MiscTest 37
	      fun {$} X in [X]:::0#10
		 thread cond {FD.distance X X '\\=:' 0} then 0 else 1 end end
	      end}

	     {MiscTest 40
	      fun {$} X Y R in [X Y]:::0#10
		 thread R = cond {FD.distance X Y '\\=:' 3} then 0 else 1 end end
		 X=1 Y=4
		 R
	      end}
	     
	     {MiscTest 41
	      fun {$} X Y in [X Y] ::: 1#FD.sup
		 {FD.times X X} + {FD.times Y Y} =: 25
		 X <: Y
		 thread cond X = 3 Y = 4 then 1 else 0 end end 
	      end}
	     
	     {MiscTest 42
	      fun {$} Z = {FD.int 0#1} in
		 {FD.conj 0 Z Z}
		 thread cond Z = 0 then 1 else 0 end end 
	      end}
	     
	     {MiscTest 43
	      fun {$} R L X Y Z in [X Y Z] = L L ::: 0#1
		 thread R = cond L ::: 0 then 1 else 0 end end
		 Z = X+Y=:2
		 X=Z
                    %X{0#1}|Y{0#1}|X{0#1}|nil
		 Y = 0
		 R
	      end}
	     
	     {MiscTest 44
	      fun {$} 
		 cond X={FD.decl} in {FD.distinctOffset [X X] [100 100]}
		 then 0 else 1 end
	      end}
	     
	     {MiscTest 45
	      fun {$} X = {FD.decl} Y = {FD.decl} in
		 {FD.distinctOffset [X Y]  [100 100]} 
		 1
	      end}
	     
	     {MiscTest 46
	      fun {$} X = {FD.decl} in
		 {FD.distinctOffset [X X]  [100 101]} 
		 1
	      end}
	     
	     {MiscTest 47
	      fun {$}
		 cond (1 =: 0) = 0 then 1 else 0 end 
	      end}
	     
	     {MiscTest 48
	      fun {$}
		 1 =: 1
	      end}
	     
	     {MiscTest 49
	      fun {$}
		 1 \=: 0
	      end}
	     
	     {MiscTest 50
	      fun {$}
		 cond (1 \=: 1) = 0 then 1 else 0 end
	      end}

	     {MiscTest 51
	      fun {$} Test X R in
		 X :: 0#10
		 proc {Test R} [A B C D] = R in
		    R ::: 0#10
		    A*B + C*D + X*10 =<: 100
            %A + B + X =<: 10
		    {FD.distribute naive R}
		 end
		 R = thread cond {Wait {Search.base.one Test}} then 1 else 0 end end
		 X = 0
		 R
	      end}

	      {MiscTest 52
	       fun {$} 
		  cond {FD.int nil _} then 0 else 1 end
	       end}

	      {MiscTest 53
	       fun {$}
		  X in X = {FD.decl}
		  {FD.exactly X [0 1 2] 0}
		  X
	       end}
	     ])
      ])

end
