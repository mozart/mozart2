functor

import

   FD

   FS

   Search

   System(show: Show)

export
   Return
define


   MkFSetVar =
   proc {$ L U IN NIN V}
      {FS.var.bounds IN {FS.reflect.lowerBound {FS.compl {FS.value.make NIN}}} V}
      {FS.cardRange L U V}
   end

   MiscTest =
   fun {$ N T}
      L = {StringToAtom {VirtualString.toString N}}
   in
      L(entailed(proc {$} {T} = 1 end) keys: [fs])
   end
   
   Return=
   fs([misc([{MiscTest 1
	      fun {$} 
		 cond {FS.intersect
		     {FS.value.make [1]} {FS.value.make [2]}}
		    = FS.value.empty then 1 else 0 end
	      end}
	     
	     {MiscTest 2
	      fun {$} 
		 FSVar1 = {MkFSetVar 5 5 [1 3 5] [10 12 14]}
		 FSVar2 = {MkFSetVar 5 5 [5 7 9] [10 12 14]}
		 R
	      in
		 R = thread
			cond FSVar1 = {FS.value.make [1 3 5 7 9]}
			then 1 else {Show no} 0 end
		     end
		 FSVar1 = FSVar2
		 R
	      end}

	     {MiscTest 3
	      fun {$}
		 FSVar1 = {MkFSetVar 6 6 [1 3 5] [10 12 14]}
		 FSVar2 = {MkFSetVar 6 6 [5 7 9] [10 12 14 15]}
		 R
	      in
		 R = thread
			cond FSVar1 = {MkFSetVar 6 6 [1 3 5 7 9] [10 12 14 15]}
			then 1 else 0 end
		     end
		 FSVar1 = FSVar2
		 R
	      end}
	     
	     {MiscTest 4
	      fun {$}
		 FSVar = {MkFSetVar 5 5 [1 3 5] [10 12 14]}
		 R
	      in
		 R = thread 
			cond FSVal = {FS.value.make [1 3 5 7 9]} in FSVal = FSVar
			then 1 else 0 end
		     end
		 FSVar = {FS.value.make [1 3 5 7 9]}
		 R
	      end}
	     
	     {MiscTest 5
	      fun {$}
		 cond {FS.value.make [1 3 5 7 9]} = {FS.value.make [1 3 5 7 9]}
		 then 1 else 0 end
	      end}
	     
	     {MiscTest 6
	      fun {$} cond {FS.value.make [1 3 5 7 9]} = 1
		      then 0 else 1 end
	      end}
	     
	     {MiscTest 7
	      fun {$}
		 FSVar1 = {MkFSetVar 5 5 [1 3 5] [10 12 14]}
		 R
	      in
		 R = thread
			cond FSVar2 = {MkFSetVar 5 5 [5 7 9] [10 12 14]}
			in FSVar1 = FSVar2 
			then 1 else 0 end
		     end
		 FSVar1 = {FS.value.make [1 3 5 7 9]}
		 R
	      end}
	     
	     {MiscTest 8
	      fun {$}
		 FSVar1 = {MkFSetVar 7 7 [1 3 5] [10 12 14]}
		 R
	      in
		 R = thread 
			cond FSVar2 = {MkFSetVar 7 7 [5 7 9 11] [10 12 14]}
			in FSVar1 = FSVar2 
			then 1 else 0 end
		     end
		 FSVar1 = {MkFSetVar 7 7 [1 3 5 7 9 11] nil}
		 R 
	      end}

	     {MiscTest 9
	      fun {$}
		 FSVar1 = {MkFSetVar 7 7 [1 3 5] [10 12 14]}
		 R 
	      in
		 R = thread 
			cond FSVar2 = {MkFSetVar 7 7 [1 3 5] [14 16 18]}
			in FSVar1 = FSVar2 
			then 1 else 0 end
		     end
		 FSVar1 = {MkFSetVar 7 7 nil [10 12 14 16 18]}
		 R
	      end}
	     
	     {MiscTest 10
	      fun {$}
		 cond {MkFSetVar 2 2 nil [1]}={MkFSetVar 2 2 [1] nil}
		 then 0 else 1 end
	      end}
	     
	     {MiscTest 11
	      fun {$} 
		 X = {FS.var.bounds [1#3] [1#7]} 
		 R
	      in
		 R = thread cond {FS.reified.isIn 5 X 1} then 1 else 0 end end
		 
		 X = {FS.var.bounds [1#5] [1#5]}
		 R
	      end}

	     {MiscTest 12
	      fun {$}
		 X = {FS.var.bounds [1#3] [1#7]}
		 R
	      in
		 R = thread cond {FS.reified.isIn 6 X 0} then 1 else 0 end end
		 
		 X = {FS.var.bounds [1#5] [1#5]}
		 R
	      end}
	     
	     {MiscTest 13
	      fun {$} X in
		 X = {FS.var.bounds [1#5] [1#7]}
		 cond {FS.reflect.lowerBound X} = [1#5] then 1 else 0 end 
	      end}
	     
	     {MiscTest 14
	      fun {$} X in
		 X = {FS.var.bounds [1#5] [1#7]}
		 cond {FS.reflect.unknown X} = [6#7] then 1 else 0 end 
	      end}

	     {MiscTest 15
	      fun {$} Y in
		 Y = {FS.var.bounds [1#7] [1#7]}
		 cond {FS.reflect.unknown Y} = nil then 1 else 0 end 
	      end}
	     
	     {MiscTest 16
	      fun {$} Y in
		 Y = {FS.var.bounds [1#7] [1#7]}
		 cond {FS.reflect.lowerBound Y} = [1#7] then 1 else 0 end 
	      end}
	     
	     {MiscTest 17
	      fun {$} X R in
		 X = {FS.var.bounds [1#5] [1#7]}
		 R = thread cond X = {FS.value.make [1#6]} then 1 else 0 end end
		 {FS.include 6 X}
		 {FS.exclude 7 X}
		 R
	      end}
	     
	     {MiscTest 18
	      fun {$} X R in
		 X = {FS.var.bounds [1#5] [1#7]}
		 R = thread cond {FS.exclude 7 X} then 1 else 0 end end
		 
		 {FS.include 6 X}
		 {FS.exclude 7 X}
		 R
	      end}
	     
	     {MiscTest 19
	      fun {$} X R
	      in
		 X = {FS.var.bounds [1#5] [1#7]}
		 R = thread cond {FS.include 6 X} then 1 else 0 end end
		 
		 {FS.include 6 X}
		 {FS.exclude 7 X}
		 R
	      end}

	     {MiscTest 20
	      fun {$}
		 fun {SetPart N}
		    proc {$ Root}
		       Root = {MakeList N}
		       {ForAll Root proc {$ E}
				       {FS.var.bounds nil [1#N] E}
				  %{FS.cardRange 1 1 E}
				    end}
		       
		       {FS.disjointN Root}
		       
		       {FS.distribute naive Root}
		    end
		 end
		 Sol SolLen
	      in
		 /*
		                                        N       / N \
		 the length of the list is: (N+1)^N = sigma N^I |   |
		                                      I = 1     \ I /
		 */
		 Sol = {Search.base.all {SetPart 3}}
		 SolLen = {Length Sol}
		 if SolLen  == 64 then 1 else 0 end
	      end}
	     
	     {MiscTest '20a'
	      fun {$}
		 proc {SetPart Root}
		    {FS.var.list.upperBound 3 1#3 Root}
		    {ForAll Root
		     proc{$ S}
			{FS.cardRange 1 3 S}
		     end}
		    
		    {FS.disjointN Root}
		    
		    {FS.distribute naive Root}
		 end
		 Sol SolLen
	      in
		 Sol = {Search.base.all SetPart}
		 SolLen = {Length Sol}
		 if SolLen  == 6 then 1 else 0 end
	      end}
	     
	     {MiscTest 21
	      fun {$}
		 fun {SetPart N}
		    proc {$ Root}
		       Root = {MakeList N}
		       {ForAll Root proc {$ E}
				       {FS.var.bounds nil [1#N] E}
				       {FS.cardRange 1 1 E}
				    end}
		       
		       {FS.disjointN Root}
		       
		       {FS.distribute naive Root}
		    end
		 end
		 Sol SolLen
	      in
		 /*
		 the length of the list is: N!
		 */
		 Sol = {Search.base.all {SetPart 5}}
		 SolLen = {Length Sol}
		 if SolLen  == 120 then 1 else 0 end
	      end}
	     
	     {MiscTest 22
	      fun {$} 
		 cond {FS.union {FS.var.upperBound [1#5]} FS.value.empty}
		    = {FS.var.upperBound [1#5]}
		 then 1 else 0 end
	      end}
	     
	     {MiscTest 23
	      fun {$} 
		 cond {FS.union FS.value.empty {FS.var.upperBound [1#5]}}
		    = {FS.var.upperBound [1#5]}
		 then 1 else 0 end
	      end}

	     {MiscTest 24
	      fun {$} 
		 cond {FS.intersect FS.value.universal {FS.var.upperBound [1#5]}}
		    = {FS.var.upperBound [1#5]}
		 then 1 else 0 end
	      end}
	     
	     {MiscTest 25
	      fun {$}
		 cond {FS.intersect {FS.var.upperBound [1#5]} FS.value.universal}
		    = {FS.var.upperBound [1#5]}
		 then 1 else 0 end
	      end}
	     
	     {MiscTest 26
	      fun {$}
		 X = {FS.var.decl} {FS.card X 3}
		 Y = {FS.var.decl} {FS.card Y 3}
		 Z = {FS.union X Y}
		 CX = {FS.card X} 
		 CY = {FS.card Y} 
		 CZ = {FS.card Z}
		 R
	      in
		 R = if {FD.reflect.min CZ} ==
			{Max {FD.reflect.min CX} {FD.reflect.min CY}}
		     then 1 else 0 end
		 {Wait R}
		 {ForAll [X Y] proc {$ E} {FS.value.make [1 2 3] E} end}
		 R
	      end}
	     
	     {MiscTest 27
	      fun {$}
		 X = {FS.var.decl} {FS.card X 3}
		 Y = {FS.var.decl} {FS.card Y 3}
		 Z = {FS.union X Y}
		 CX = {FS.card X} 
		 CY = {FS.card Y} 
		 CZ = {FS.card Z}
		 R
	      in
		 R = if {FD.reflect.max CZ} ==
			{FD.reflect.max CX}+{FD.reflect.max CY}
		     then 1 else 0 end
		 
		 {Wait R}
		 {ForAll [X Y] proc {$ E} {FS.value.make [1 2 3] E} end}
		 R
	      end}
	
	     {MiscTest 28
	      fun {$} 
		 X = {FS.var.decl} {FS.card X 3}
		 Y = {FS.var.decl} {FS.card Y 3}
		 Z = {FS.intersect X Y}
		 CX = {FS.card X} 
		 CY = {FS.card Y} 
		 CZ = {FS.card Z}
		 R
	      in
		 R = if {FD.reflect.max CZ} ==
			{Min {FD.reflect.max CX} {FD.reflect.max CY}}
		     then 1 else 0 end
		 {Wait R}
		 {ForAll [X Y] proc {$ E} {FS.value.make [1 2 3] E} end}
		 R
	      end}
	     
	     
	     {MiscTest 29
	      fun {$}  X Y R 
	      in
		 X = {FS.var.upperBound [1#10]} Y = {FS.var.upperBound [1#10]}
		 R = thread cond {FS.distinct X Y} then 1 else 0 end end
		 {FS.include 1 X}
		 {FS.exclude 1 Y}
		 R
	      end}
	     
	     {MiscTest 30
	      fun {$} X Y R
	      in
		 X = {FS.var.upperBound [1#10]} Y = {FS.var.upperBound [1#10]}
		 R = thread cond {FS.distinct X Y} then 0 else 1 end end
		 X = {FS.value.make [1#10]} Y = {FS.value.make [1#10]}
		 R
	      end}
	     
	     {MiscTest 31
	      fun {$} X = {FS.var.decl} Y = {FS.var.decl} R 
	      in
		 R = thread cond {FS.subset X Y} then 1 else 0 end end
		 
		 {FS.include 1 Y} 
		 {FS.include 2 Y}
		 
		 X = {FS.value.make [1#2]}
		 
		 R
	      end}
	     
	     {MiscTest 32
	      fun {$} S SV={FS.var.decl} E R
	      in
		 R = thread cond SV = {FS.value.make [1 2 3 4 5]}
			    then 1 else 0 end
		     end
		 {FS.monitorIn SV S}
		 S = 1|2|3|4|5|E
		 E = nil
		 R
	      end}

	     {MiscTest 33
	      fun {$} S SV={FS.var.decl} R
	      in 
		 R = thread cond S = [_ _ _ _ _] then 1 else 0 end end
		 {FS.monitorIn SV S}
		 {FS.include 1 SV}
		 {FS.include 2 SV}
		 {FS.include 3 SV}
		 {FS.include 4 SV}
		 {FS.include 5 SV}
		 {FS.card SV 5}
		 R
	      end}
	     
	     {MiscTest 34
	      fun {$} D={FD.decl}  S={FS.var.decl} R= {FD.int 0#1} R 
	      in 
		 R = thread cond R = 1 then 1 else 0 end end
		 {FS.reified.include D S R}
		 
		 D :: 1#2
		 {FS.include 1 S}
		 {FS.include 2 S}
		 R
	      end}
	     
	     {MiscTest 35
	      fun {$} D={FD.decl}  S={FS.var.decl} C= {FD.int 0#1} R
	      in
		 R = thread cond C = 1 then 0 else 1 end end
		 {FS.reified.include D S C}
		 
		 D :: 1#2
		 {FS.exclude 1 S}
		 {FS.exclude 2 S}
		 R
	      end}
	     
	     {MiscTest 36
	      fun {$} D={FD.decl}  S={FS.var.decl} R
	      in
		 R = thread cond {FS.include D S} then 1 else 0 end end
		 
		 D :: 1#2
		 {FS.include 1 S}
		 {FS.include 2 S}
		 R
	      end}
	     
	     
	     {MiscTest 37
	      fun {$}
		 D={FD.decl}  S={FS.var.decl} R
	      in
		 R = thread cond {FS.exclude D S} then 1 else 0 end end
		 
		 D :: 1#2
		 {FS.exclude 1 S}
		 {FS.exclude 2 S}
		 R
	      end}
	     
	     {MiscTest 38
	      fun {$}
		 if {FS.int.min {FS.value.make [1 2 3]}} == 1 then 1 else 0 end
	      end}
	     
	     {MiscTest 39
	      fun {$}
		 if {FS.int.max {FS.value.make [1 2 3]}} == 3 then 1 else 0 end
	      end}
	     
	     {MiscTest 40
	      fun {$}
		 if {FS.int.min {FS.value.make [2]}} == 2 then 1 else 0 end
	      end}
	     
	     {MiscTest 41
	      fun {$}
		 if {FS.int.max {FS.value.make [2]}} == 2 then 1 else 0 end
	      end}
	     
	     {MiscTest 42
	      fun {$}
		 cond {FS.int.convex {FS.value.make [1 2]}}  then 1 else 0 end
	      end}

	     {MiscTest 43
	      fun {$}
		 cond {FS.int.convex {FS.value.make [1 2 4]}} then 0 else 1 end
	      end}

	     {MiscTest 44
	      fun {$}
		 cond {FS.int.convex {FS.value.make nil}}  then 1 else 0 end
	      end}

	     {MiscTest 45
	      fun {$}
		 cond
		    S = {FS.var.upperBound [1#5]}
		 in
		    {FS.int.convex S} S = {FS.value.make nil}
		 then 1 else 0 end
	      end}

	     {MiscTest 46
	      fun {$} S SV={FS.var.decl} E R
	      in
		 R = thread cond SV = {FS.value.make [6#FS.sup]}
			    then 1 else 0 end
		     end
		 {FS.monitorOut SV S}
		 S = 0|1|2|3|4|5|E
		 E = nil
		 R
	      end}

	     {MiscTest 47
	      fun {$} S SV={FS.var.decl} R MaxCard = (FS.sup - FS.inf + 1)
	      in 
		 R = thread cond S = [_ _ _ _ _] then 1 else 0 end end
		 {FS.monitorOut SV S}
		 {FS.exclude 1 SV}
		 {FS.exclude 2 SV}
		 {FS.exclude 3 SV}
		 {FS.exclude 4 SV}
		 {FS.exclude 5 SV}
		 {FS.card SV MaxCard - 5}
		 R
	      end}
	     {MiscTest 48
	      fun {$}
		 
		 {FS.value.make nil _}
		 {FS.value.make 1 _}
		 {FS.value.make 1#5 _}
		 {FS.value.make [1] _}
		 {FS.value.make [1#5] _}
		 {FS.value.make [1#5 10 20#30] _}
		 {FS.value.make compl(1) _}
		 {FS.value.make compl(1#5) _}
		 {FS.value.make compl([1]) _}
		 {FS.value.make compl([1#5]) _}
		 {FS.value.make compl([1#5 10 20#30]) _}
		 
		 {FS.var.bounds nil nil _}
		 {FS.var.bounds nil 1 _}
		 {FS.var.bounds 1 1#5 _}
		 {FS.var.bounds 1 [1] _}
		 {FS.var.bounds 1#4 [1#5] _}
		 {FS.var.bounds [1#3] [1#5 10 20#30] _}
		 {FS.var.bounds compl(1#2) compl(1) _}
		 {FS.var.bounds nil compl(1#5) _}
		 {FS.var.bounds nil compl([1]) _}
		 {FS.var.bounds compl(1#10) compl([1#5]) _}
		 {FS.var.bounds nil compl([1#5 10 20#30]) _}

		 1
	      end}

	     {MiscTest 49
	      fun {$}
		 S1 = {FS.var.upperBound [1 2]}
		 S2 = {FS.var.upperBound [2]}
		 R
	      in
		 R = thread
			cond S2 = {FS.value.make 2} then 1 else 0 end
		     end
		 {FS.distinct S1 S2}
		 S1 = {FS.var.upperBound nil}
		 R
	      end}

	     {MiscTest 50
	      fun {$}
		 S1 = {FS.var.upperBound [1]}
		 S2 = {FS.var.upperBound [1]}
		 R
	      in
		 R = thread
			cond S2 = {FS.value.make nil} then 1 else 0 end
		     end
		 {FS.distinct S1 S2}
		 {FS.include 1 S1}
		 R
	      end}

	     {MiscTest 51
	      fun {$}
		 R L [S1 _ S3]=L
	      in
		 {FS.var.list.upperBound 3 1#3 L}
		 {FS.disjointN L}
		 R = thread cond S1=FS.value.empty then 1 else 0 end end
		 S1=S3
		 R
	      end}

	     {MiscTest 52
	      fun {$}
		 R L [S1 _ S3]=L
	      in
		 {FS.var.list.upperBound 3 1#3 L}
		 R = thread cond {FS.disjointN L} then 0 else 1 end end
		 {FS.include 1 S1}
		 {FS.include 1 S3}
		 R
	      end}

	     {MiscTest 53
	      fun {$}
		 R L [S1 S2]=L
	      in
		 {FS.var.list.upperBound 2 0#10 L}
		 R = thread cond {FS.disjointN L} then 1 else 0 end end
		 {FS.var.upperBound [0#5] S1}
		 {FS.var.upperBound [6#10] S2}
		 R
	      end}
	     {MiscTest 54
	      fun {$} Z Xs [X1 X2 X3 X4] = Xs R
	      in
		 {ForAll Xs proc {$ E} {FS.var.upperBound 1#4 E} end}
		 {FS.var.upperBound 1#4 Z}
		 {FS.intersectN Xs Z}
		 R = thread cond {FS.include 2 X4}
			    then 0 else
			       % entail FS.intersectN to make test succeed
			       {FS.value.make 2 X1}
			       {FS.value.make 2 X2}
			       {FS.value.make 2 X3}
			       {FS.value.make 1 X4}
			       1
			    end
		     end
		 {FS.include 2 X1}
		 {FS.include 2 X2}
		 {FS.include 2 X3}
		 {FS.exclude 2 Z}
		 R
	      end}
	     {MiscTest 55
	      fun {$} Z X2 Xs=[_ X2 _ _] R
	      in
		 {ForAll Xs proc {$ E} {FS.var.upperBound 1#4 E} end}
		 {FS.intersectN Xs Z}
		 R = thread cond Z = {FS.value.make nil} then 1 else 0 end end
		 {FS.var.upperBound nil X2}
		 R
	      end}
	     {MiscTest 56
	      fun {$} Z Xs [X1 X2 X3 X4] = Xs R
	      in
		 {ForAll Xs proc {$ E} {FS.var.decl  E} end}
		 {FS.intersectN Xs Z}
		 R = thread cond
			       X1 = {FS.value.make 1}
			       X2 = FS.value.universal
			       X3 = {FS.value.make 1}
			       X4 = {FS.value.make 1}
			       Z = {FS.value.make 1}
			    then 1 else 0 end end
		 FS.value.universal = X2
		 X1 = X4
		 {FS.include 1 Z}
		 {FS.cardRange 1 1 X4}
		 {FS.cardRange 1 1 X3}
		 R
	      end}
	    ])
      ])
end
