functor

import

   FD

   Search

export
   Return
define

   GetSize = FD.reflect.size
   GetMax = FD.reflect.max

   fun {Choose Min MinSize Xs}
      case Xs
      of X|Xr then 
	 local XSize in
	    XSize = {GetSize X}
	    if MinSize=<XSize then {Choose Min MinSize Xr}
	    else {Choose X XSize Xr}
	    end
	 end
      [] nil then Min
      end
   end
   
   proc {Enum L}
      choice
	 case {Filter L fun {$ X} {GetSize X} > 1 end}
	 of nil then skip
	 [] F|_ = L then
	    local
	       Next = {Choose F {GetSize F} L}
	       M = {GetMax Next}
	    in
	       dis Next=M then {Enum L} 
	       [] Next \=: M then {Enum L} 
	       end
	    end
	 end
      end
   end

% {Badness P#G} returns the number of items in G which are
% constrained to 0.
   proc {Badness P R}
      if {IsList P} then 
	 {FoldL
	  P
	  proc {$ X Y Z}
	     local B in
		B :: 0#1
		thread
		   or B=0 Y>:0
		   [] B=1 Y=0
		   end
		end
		Z :: 0#255
		Y :: 0#255
		Z=:B+X
	     end
	  end
	  0
	  R
	 }
      end
   end


   proc {StudentsProblem NumberOfGroups 
	 PeoplePerGroup Preferences Solution}

      local
	 NumberOfPossibleGroups = {FoldL Preferences
				   fun{$ I X} {Max I {FoldL X fun{$ I X} {Max I X} end 0}} end 0} 
	 NumberOfPeople ={Length Preferences} 

      % {Initialize Ds Ls} constrains the elements of the list Ds
      % to the domain given by the respective element of the list Ls,
      % extended by the value 0.


	 proc {Initialize Ds Ls}
	    case Ds of nil then skip
	    [] D|Dr
	    then
	       local L Lr in
		  Ls=L|Lr
		  D :: 0|L
		  {Initialize Dr Lr}
	       end
	    end
	 end


	 proc {Legal Ls O}
	    {For 1 NumberOfPossibleGroups 1
	     proc{$ C} {FD.atMost PeoplePerGroup Ls C} 
	     end}

	    O={MakeTuple o NumberOfPossibleGroups}
	    {Record.forAll O proc {$ X} X :: 0#1 end} 

	    {Record.foldL O proc{$ In X Out} Out :: 0#FD.sup Out=:In+X end 0} =<: NumberOfGroups
	    {ForAll Ls proc{$ L} thread
				    if {IsInt L}
				    then if L>0 then O.L=1 else skip end 
				    end
				 end
		       end}
         % redundant constraint:
	    {For 1 NumberOfPossibleGroups 1 
	     proc{$ G}
		thread
		   cond O.G=:0
		   then {ForAll Ls proc{$ L} L\=:G end}
		   else skip
		   end
		end
	     end}

	 end

	 proc {Loesung P}
	    local O in
	    %P =  1|1|1|1|3|0|3|3|3|3|1|nil
%	    P =  _|_|_|_|_|_|_|_|_|_|_|nil
	       {List.make NumberOfPeople P}
	       {Initialize P Preferences}
	       {Legal P O}
	       {Enum P}
	       {FD.distribute ff O} 
	    end
	 end

      in
	 Solution = Loesung
      end
   end

   proc {Cmp Old New} {Badness New} <:  {Badness Old}

   end

   P4 = [ [1] [1] [1 2] [1 2] [2] ]
   P5 = [ [1 3] [1 3] [1 3] [1 3 6] [3 4 7] [4 7] [3] [1 2 3 ] [3] [3] [1] [3 6]
	  [1 2 4 6] [3 5] [3 5] [1] [2 7] [3 7] [3 7] [2] [8] ]
   P6 = [ [1 3] [1 3] [1 3] [1 3 6] [3 4 7] [4 7] [3] [1 2 3 ] [3] [3] [1] ]

   StudentsSol1 = [[1 1 2 2 2]]
   StudentsSol2 = [[3 3 1 1 3 0 3 1 3 3 1 3 1 3 3 1 0 3 3 0 0]]
   StudentsSol3 = [[3 1 1 1 3 0 3 1 3 3 1]]

   Return=
   fd([
       students([
		 best1(equal(fun {$}
				{Search.base.best {StudentsProblem 2 3 P4} Cmp} 
			     end
			     StudentsSol1)
		       keys: [fd])
		 best2(equal(fun {$}
				{Search.base.best {StudentsProblem 2 11 P5} Cmp}
			     end
			     StudentsSol2)
		       keys: [fd])
		 best3(equal(fun {$}
				{Search.base.best {StudentsProblem 2 5 P6} Cmp}
			     end
			     StudentsSol3)
		       keys: [fd])
		 best1_entailed(entailed(proc {$}
					    {Search.base.best {StudentsProblem 2 3 P4} Cmp _} 
					 end)
		       keys: [fd entailed])
		 best2_entailed(entailed(proc {$}
					    {Search.base.best {StudentsProblem 2 11 P5} Cmp _}
			     end)
		       keys: [fd entailed])
		 best3_entailed(entailed(proc {$}
					    {Search.base.best {StudentsProblem 2 5 P6} Cmp _}
					 end)
		       keys: [fd entailed])
		])
      ])

end

