functor

import

   FD

   Search

export
   Return
define
% See Hentenryck page 152
% Vector = 458192637
% VMon = 11010101     1 if f(i+1)>f(i)
% Vadv= 11110110      1 if f(i)+1 is on the right of f(i)


   fun {SkipDet Xs}
      case Xs
      of X|Xr then cond {FD.reflect.size X}=1 then {SkipDet Xr}
		   else Xs end
      [] nil then nil
      end
   end

   proc {Choose Xs HoleTail HoleHead MinYet SizeYet ?Min ?Ys}
      case Xs
      of X|Xr then 
	 local SizeX={FD.reflect.size X} in
	    cond SizeX=1 then 
	       {Choose Xr HoleTail HoleHead MinYet SizeYet Min Ys}
	    else
	       if (SizeX<SizeYet) then
		  local NewHole in
		     HoleTail=MinYet|HoleHead
		     {Choose Xr Ys NewHole X SizeX Min NewHole}
		  end
	       else
		  Ys=X|{Choose Xr HoleTail HoleHead MinYet SizeYet Min}
	       end
	    end
	 end
      [] nil then Min=MinYet Ys=nil HoleTail=HoleHead
      end
   end

   proc {EnumSplit Xs}
      choice
	 case {SkipDet Xs}
	 of nil then skip
	 [] X|Xr then
	    /*{Show skipDet#(X|Xr)}*/
	    local Y Yr Hole Min Max Diff in
	       {Choose Xr Yr Hole X {FD.reflect.size X} Y Hole}
	       /*{Show enumSplit#Y#Yr}*/
	       Min={FD.reflect.min Y} Max={FD.reflect.max Y} Diff=Max-Min
	       case Diff
	       of 0 then /*{Show Yr}*/ skip
	       [] 1 then 
		  dis Y=Min then {EnumSplit Yr}
		  [] Y=Max then {EnumSplit Yr}
		  end
	       else 
		  local Mid = Min + (Diff div 2) in
		     dis Y  =<: Mid then {EnumSplit Y|Yr}
		     []  Y  >=: Mid+1 then {EnumSplit Y|Yr}
		     end
		  end
	       end
	    end
	 end
      end
   end

   proc {Permutation Vmon Vadv N Vector}
      {List.make N Vector}
      {List.make N-1 Vmon}
      {List.make N-1 Vadv}
      Vector = {FD.dom 1#N}
      {FD.distinct Vector}
      {Advances Vector Vadv N}
      {Monotonie Vector Vmon}
      {EnumSplit Vector}
   end

   proc {Advances Vector Vadv N}
      {Adv Vector Vadv nil N}
   end

   proc {Adv Vector Vadv Previous N}
      case Vector
      of X|XX|Xr
      then
	 dis Y Radv in %{Show a}
	    %{FD.fd Y}
	    Vadv = 1|Radv %{Show aa}
	    %X \=: N Y =: X + 1
	    %{Distinct Y Previous}
	 then
	    Y :: 0#FD.sup
	    {Distinct Y Previous}
	    X \=: N Y =: X + 1
	    {Adv XX|Xr Radv X|Previous N}
	 []  Radv Y in %{Show b}
	    %{FD.fd Y}
	    Vadv = 0|Radv %{Show bb}
	    %Y =: X + 1
	    %{Distinct Y Xr}
	 then
	    Y :: 0#FD.sup
	    {Distinct Y Xr}
	    Y =: X + 1
	    {Adv XX|Xr Radv X|Previous N}
	 end
      [] [_] then Vadv = nil 
      end
   end

   proc {Distinct Var List}
      {ForAll List proc {$ X} Var \=: X end}
   end

   proc {Monotonie Vector Vmon}
      case Vector 
      of H|HH|R 
      then
	 dis  Rmon in
	    Vmon = 0|Rmon
	    %HH =<: H
	 then
	    HH =<: H
	    {Monotonie HH|R Rmon}
	 []  X Rmon in
	    %{FD.fd X}
	    Vmon = 1|Rmon
	    %X =: HH - 1 H =<: X
	 then
	    X :: 0#FD.sup
	    X =: HH - 1 H =<: X
	    {Monotonie HH|R Rmon}
	 end
      else
	 Vector=[_]
	 Vmon=nil
      end
   end

   PermutationSol = 
   [[1 2 7 5 6 3 8 4 9] [1 2 8 5 9 3 6 4 7] 
    [1 2 6 3 9 4 7 5 8] [1 2 7 3 6 4 8 5 9] 
    [1 2 8 3 9 4 6 5 7] [1 2 8 4 9 5 6 3 7] 
    [1 2 8 3 9 5 6 4 7] [1 2 5 3 9 6 7 4 8] 
    [1 3 8 4 9 5 6 2 7] [1 4 5 2 9 6 7 3 8] 
    [1 4 7 5 6 2 8 3 9] [1 4 8 2 9 5 6 3 7] 
    [1 4 8 5 9 2 6 3 7] [1 5 6 2 9 3 7 4 8] 
    [1 5 7 2 6 3 8 4 9] [1 5 8 2 9 3 6 4 7] 
    [1 6 7 2 5 3 8 4 9] [1 6 7 4 5 2 8 3 9] 
    [1 7 8 4 9 2 5 3 6] [1 7 8 2 9 3 5 4 6] 
    [1 7 8 2 9 4 5 3 6] [1 7 8 3 9 4 5 2 6] 
    [2 3 8 4 9 5 6 1 7] [2 7 8 3 9 4 5 1 6] 
    [3 4 5 1 9 6 7 2 8] [3 4 7 5 6 1 8 2 9] 
    [3 4 8 1 9 5 6 2 7] [3 4 8 5 9 1 6 2 7] 
    [3 6 7 4 5 1 8 2 9] [3 7 8 1 9 4 5 2 6] 
    [3 7 8 4 9 1 5 2 6] [4 5 6 1 9 2 7 3 8] 
    [4 5 7 1 6 2 8 3 9] [4 5 8 1 9 2 6 3 7] 
    [4 6 7 1 5 2 8 3 9] [4 7 8 1 9 2 5 3 6] 
    [5 6 7 1 4 2 8 3 9] [5 6 7 3 4 1 8 2 9] 
    [6 7 8 3 9 1 4 2 5] [6 7 8 1 9 2 4 3 5] 
    [6 7 8 1 9 3 4 2 5] [6 7 8 2 9 3 4 1 5]]

   Return=
   fd([permutation([
		    all(equal(fun {$}
				 {Search.base.all
				  proc{$ X}
				     {Permutation [1 1 0 1 0 1 0 1]
				      [1 1 1 1 0 1 1 0] 9 X}
				  end}
			      end
			      PermutationSol)
			keys: [fd])
		    all_entailed(entailed(proc {$}
					     {Search.base.all
					      proc{$ X}
						 {Permutation [1 1 0 1 0 1 0 1]
						  [1 1 1 1 0 1 1 0] 9 X}
					      end _}
					  end)
				 keys: [fd entailed])
		   ])
      ])


end


