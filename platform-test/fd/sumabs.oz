functor

import

   FD

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
   fd([sumabs([	     

	       %% tests for sumAC with '=:'
     
	       {MiscTest 1
		fun {$}
		   cond {FD.sumAC [1 ~1] [3 4] '=:' 1} then 1 else 0 end 
		end}

	       {MiscTest 2
		fun {$}
		   cond {FD.sumAC [1 ~1] [3 4] '=:' 2} then 0 else 1 end 
		end}

	       {MiscTest 3
		fun {$} D in
		   {FD.decl D}
		   {FD.sumAC [1 ~1] [3 4] '=:' D}
		   if D==1 then 1 else 0 end
		end}

	       {MiscTest 4
		fun {$} D in
		   {FD.decl D}
		   {FD.sumAC [3 ~4] [1 1] '=:' D}
		   if D==1 then 1 else 0 end
		end}

	       {MiscTest 5
		fun {$} X in X :: 17#37
		   {FD.sumAC [1] [X] '=:' X}
		   cond {FD.reflect.dom X} = [17#37] then 1 else 0 end 
		end}

	       {MiscTest 6
		fun {$} X in X :: 1#100
		   cond {FD.sumAC [3] [X] '=:' X} then 0 else 1 end 
		end}

	       {MiscTest 7
		fun {$} X D in [X D]:::0#10
		   {FD.sumAC [1 ~1] [X X] '=:' D}
		   if D==0 then 1 else 0 end 
		end}

	       {MiscTest 8
		fun {$} X Y D in [X Y D]:::0#10
		   {FD.sumAC [1 ~1] [X Y] '=:' D}
		   X = Y
		   if D==0 then 1 else 0 end 
		end}

	       {MiscTest 9
		fun {$} X D in
		   X :: 10#20
		   {FD.decl D}
		   {FD.sumAC [1 100] [X 1] '=:' D}
		   cond {FD.reflect.dom D} = [110#120] then 1 else 0 end 
		end}    

	       {MiscTest 10
		fun {$} X Y in
		   {FD.decl X}
		   {FD.decl Y}
		   {FD.sumAC [3 1] [X Y] '=:' X}
		   if X==0 andthen Y==0 then 1 else 0 end 
		end}

	       {MiscTest 11
		fun {$} X Y D in
		   {FD.decl X}
		   {FD.decl Y}
		   {FD.decl D}
		   {FD.sumAC [3 1] [X Y] '=:' D}
		   X = D
		   if X==0 andthen Y==0 andthen D==0 then 1 else 0 end 
		end}

	       {MiscTest 12
		fun {$} X Y D in
		   {FD.decl X}
		   Y :: 10#20
		   {FD.decl D}
		   {FD.sumAC [3 ~3 1] [X X Y] '=:' D}
		   cond {FD.reflect.dom D} = [10#20] then 1 else 0 end
		end}

	       {MiscTest 13
		fun {$} X Y Z D in 
		   X :: [60#85]
		   Y :: [30#38]
		   Z :: [7#9 86#87]
		   D :: [93#99]
		   {FD.sumAC [1 2 ~3] [X Y Z] '=:' D}
		   cond {FD.reflect.dom X} = [60#66 83#85]
		      {FD.reflect.dom Y} = [30#33 37#38]
		      {FD.reflect.dom Z} = [7#9 86]
		      {FD.reflect.dom D} = [93#99]
		   then 1 else 0 end
		end}

	       {MiscTest 14
		fun {$} X Y Z D in
		   {FD.decl X}
		   {FD.decl Y}
		   Z :: 10#20
		   {FD.decl D}
		   {FD.sumAC [3 ~3 1] [X Y Z] '=:' D}
		   X = Y
		   cond {FD.reflect.dom D} = [10#20] then 1 else 0 end
		end}

	       {MiscTest 15
		fun {$} X Y Z D in
		   {FD.decl X}
		   {FD.decl Y}
		   Z :: 10#20
		   {FD.decl D}
		   {FD.sumAC [3 ~3 1 1] [X Y Z 100] '=:' D}
		   X = Y
		   cond {FD.reflect.dom D} = [110#120] then 1 else 0 end 
		end}

	       {MiscTest 16
		fun {$} R X Y Z D in
		   {FD.decl X}
		   {FD.decl Y} 
		   Z :: 10#30 
		   D :: 0#100 
		   R =
		   thread
		      cond {FD.sumAC [3 ~3 1 1] [X Y Z 100] '=:' D}
		      then 0 else 1 end
		   end 
		   X = Y
		   R
		end}
     
	       {MiscTest 17
		fun {$} X Y Z in
		   {FD.decl X}
		   Y :: 1#10
		   Z :: 10#20
		   {FD.sumAC [1 ~4 3] [X Y Z] '=:' X}
		   cond {FD.reflect.dom X} = [0#FD.sup]
		      {FD.reflect.dom Y} = [8#10]
		      {FD.reflect.dom Z} = [10#13]
		   then 1 else 0 end
		end}

	       {MiscTest 18
		fun {$} X Y Z D in
		   X :: [4#7 45]
		   Y :: [4#10]
		   Z :: [2#5]
		   D :: [16#23]
		   {FD.sumAC [~1 3 ~4] [X Y Z] '=:' D}
		   cond {FD.reflect.dom X} = [4#6 45] 
		      Y = 10 
		      Z = 2 
		      {FD.reflect.dom D} = [16#18 23]
		   then 1 else 0 end
		end}

	       {MiscTest 19
		fun {$} X Y Z D in
		   X :: [4 45]
		   Y :: [4#10]
		   Z :: [2#5]
		   D :: [16#23]
		   {FD.sumAC [~1 3 ~4] [X Y Z] '=:' D}
		   cond {FD.reflect.dom X} = [4 45] 
		      Y = 10 
		      Z = 2 
		      {FD.reflect.dom D} = [18 23]
		   then 1 else 0 end
		end}
     
	       %% 19 tests up to here
     
	       %% tests for sumAC with '=<:'
     
	       {MiscTest 20
		fun {$}
		   cond {FD.sumAC [1 ~1] [3 4] '=<:' 1} then 1 else 0 end 
		end}
     
	       {MiscTest 21
		fun {$}
		   cond {FD.sumAC [1 ~1] [3 5] '=<:' 1} then 0 else 1 end 
		end}

	       {MiscTest 22
		fun {$}
		   cond {FD.sumAC [1 1] [1 1] '=<:' 1} then 0 else 1 end 
		end}

	       {MiscTest 23
		fun {$} D in
		   {FD.decl D}
		   {FD.sumAC [1 ~1] [3 4] '=<:' D}
		   cond {FD.reflect.min D} = 1 then 1 else 0 end
		end}

	       {MiscTest 24
		fun {$} D in
		   D :: 0#10
		   {FD.sumAC [3 ~7] [1 1] '=<:' D}
		   cond {FD.reflect.dom D} = [4#10] then 1 else 0 end
		end}

	       {MiscTest 25
		fun {$} X in
		   X :: 0#10
		   {FD.sumAC [1] [X] '=<:' 7}
		   cond {FD.reflect.dom X} = [0#7] then 1 else 0 end
		end}

	       {MiscTest 26
		fun {$} X in
		   {FD.decl X}
		   {FD.sumAC [1] [X] '=<:' X}
		   cond {FD.reflect.dom X} = [0#FD.sup] then 1 else 0 end
		end}

	       {MiscTest 27
		fun {$} X in
		   {FD.decl X}
		   {FD.sumAC [2] [X] '=<:' X}
		   cond {FD.reflect.dom X} = [0] then 1 else 0 end
		end}

	       {MiscTest 28
		fun {$} X in
		   {FD.decl X}
		   {FD.sumAC [~1] [X] '=<:' X}
		   cond {FD.reflect.dom X} = [0#FD.sup] then 1 else 0 end
		end}

	       {MiscTest 29
		fun {$} X in
		   {FD.decl X}
		   {FD.sumAC [~2] [X] '=<:' X}
		   cond {FD.reflect.dom X} = [0] then 1 else 0 end
		end}

	       {MiscTest 30
		fun {$} X D in
		   X :: 2#10
		   D :: 0#10
		   {FD.sumAC [1] [X] '=<:' D}
		   cond {FD.reflect.dom D} = [2#10]
		      {FD.reflect.dom X} = [2#10]
		   then 1 else 0 end
		end}
     
	       {MiscTest 31
		fun {$} X D in
		   X :: 0#20
		   D :: 0#10
		   {FD.sumAC [1] [X] '=<:' D}
		   cond {FD.reflect.dom D} = [0#10]
		      {FD.reflect.dom X} = [0#10]
		   then 1 else 0 end
		end}

	       {MiscTest 32
		fun {$} X D in
		   X :: 2#20
		   D :: 0#10
		   {FD.sumAC [1] [X] '=<:' D}
		   cond {FD.reflect.dom D} = [2#10]
		      {FD.reflect.dom X} = [2#10]
		   then 1 else 0 end
		end}

	       {MiscTest 33
		fun {$} X D in             
		   X :: 2#20
		   D :: 0#10
		   {FD.sumAC [5] [X] '=<:' D}
		   cond {FD.reflect.dom D} = [10]
		      {FD.reflect.dom X} = [2]
		   then 1 else 0 end
		end}

	       {MiscTest 34
		fun {$} X D in
		   X :: 2#20
		   D :: 0#10
		   {FD.sumAC [~1] [X] '=<:' D}
		   cond {FD.reflect.dom D} = [2#10]
		      {FD.reflect.dom X} = [2#10]
		   then 1 else 0 end
		end}

	       {MiscTest 35
		fun {$} X D in
		   X :: 2#20
		   D :: 0#10
		   {FD.sumAC [~3] [X] '=<:' D}
		   cond {FD.reflect.dom D} = [6#10]
		      {FD.reflect.dom X} = [2#3]
		   then 1 else 0 end
		end}
      
	       {MiscTest 36
		fun {$} X D in
		   X :: 2#20
		   D :: 0#10
		   {FD.sumAC [~5] [X] '=<:' D}
		   cond {FD.reflect.dom D} = [10]
		      {FD.reflect.dom X} = [2]
		   then 1 else 0 end
		end}

	       {MiscTest 37
		fun {$} X Y D in            
		   X :: 0#10
		   Y :: 0#10
		   D :: 0#10
		   {FD.sumAC [1 ~1] [X Y] '=<:' D}
		   cond {FD.reflect.dom D} = [0#10]
		      {FD.reflect.dom X} = [0#10]
		      {FD.reflect.dom Y} = [0#10]
		   then 1 else 0 end
		end}

	       {MiscTest 38
		fun {$} X Y D in            
		   X :: 2#5
		   Y :: 3#7
		   D :: 0#100
		   {FD.sumAC [1 1] [X Y] '=<:' D}
		   cond {FD.reflect.dom D} = [5#100]
		      {FD.reflect.dom X} = [2#5]
		      {FD.reflect.dom Y} = [3#7]
		   then 1 else 0 end
		end}

	       {MiscTest 39
		fun {$} X Y D in            
		   X :: 5#7
		   Y :: 1#19
		   D :: 0#3
		   {FD.sumAC [1 ~1] [X Y] '=<:' D}
		   cond {FD.reflect.dom D} = [0#3]
		      {FD.reflect.dom X} = [5#7]
		      {FD.reflect.dom Y} = [2#10]
		   then 1 else 0 end
		end}

	       {MiscTest 40
		fun {$} X Y D in            
		   X :: 1#19
		   Y :: 5#7
		   D :: 0#3
		   {FD.sumAC [1 ~1] [X Y] '=<:' D}
		   cond {FD.reflect.dom D} = [0#3]
		      {FD.reflect.dom X} = [2#10]
		      {FD.reflect.dom Y} = [5#7]
		   then 1 else 0 end
		end}

	       {MiscTest 41
		fun {$} X in            
		   X :: 0#10
		   {FD.sumAC [2] [X] '=<:' X}
		   cond X=0 
		   then 1 else 0 end
		end}

	       {MiscTest 42
		fun {$} X in            
		   X :: 0#10
		   cond {FD.sumAC [2 1] [X 1] '=<:' X}
		   then 0 else 1 end
		end}

	       {MiscTest 43
		fun {$} X D in            
		   X :: 0#10
		   D :: 0#10
		   {FD.sumAC [2] [X] '=<:' D}
		   D = X
		   cond {FD.reflect.dom D} = [0]
		      {FD.reflect.dom X} = [0]
		   then 1 else 0 end
		end}

	       {MiscTest 44
		fun {$} X D in
		   X :: 0#10
		   D :: 0#10
		   X = D
		   cond {FD.sumAC [1 1] [X 1] '=<:' D}
		   then 0 else 1 end
		end}

	       {MiscTest 45
		fun {$} X D in            
		   X :: 0#10
		   D :: 0#10
		   {FD.sumAC [2 1] [X 5] '=<:' D}
		   cond X = D
		   then 0 else 1 end
		end}

	       {MiscTest 46
		fun {$} X Y in
		   X :: 0#10
		   Y :: 0#10
		   {FD.sumAC [1 ~2 1] [X Y 10] '=<:' X}
		   cond {FD.reflect.dom X} = [0#10]
		      {FD.reflect.dom Y} = [5#10]
		   then 1 else 0 end
		end}

	       {MiscTest 47
		fun {$} X Y in
		   X :: 0#10
		   Y :: 0#10
		   {FD.sumAC [~1 2 ~1] [X Y 10] '=<:' X}
		   cond {FD.reflect.dom X} = [0#10]
		      {FD.reflect.dom Y} = [5#10]
		   then 1 else 0 end
		end}
     
	       %% 47 tests up to here

	       %% tests for sumAC with '\\=:'
	       {MiscTest 48
		fun {$}
		   cond {FD.sumAC [1 ~1] [3 4] '\\=:' 2} then 1 else 0 end 
		end}
     
	       {MiscTest 49
		fun {$}
		   cond {FD.sumAC [1 ~1] [3 4] '\\=:' 1} then 0 else 1 end 
		end}

	       {MiscTest 50
		fun {$}
		   cond {FD.sumAC [1 1] [1 1] '\\=:' 1} then 1 else 0 end 
		end}

	       {MiscTest 51
		fun {$} D in
		   {FD.decl D}
		   {FD.sumAC [1 ~1] [3 4] '\\=:' D}
		   cond {FD.reflect.dom D} = [0 2#FD.sup] then 1 else 0 end
		end}
	     
	      ])
      ])
   
end
