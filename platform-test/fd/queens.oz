functor

import

   FD

   Search

export
   Return
define

   Queens =
   proc {$ N Board}
      {List.make N Board}
      Board = {FD.dom 1#N}
      {List.forAllTail Board 
       proc {$ Q|Qs}
	  {FoldL Qs
	   fun {$ I R}
	      R\=:Q Q-I\=:R Q+I\=: R 
	   %R\=:Q {NEPC Q R I} {NEPC Q R ~I}
	      I+1
	   end
	   1 _}
       end
      }
      {FD.distribute ff Board}
   end

   QueensSol = [[1 3 5 12 9 4 13 11 14 7 2 6 8 10]]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% queen with middle-out heuristcs

   GetSize=FD.reflect.size
   GetMid = FD.reflect.mid
   
   fun {SkipDet Xs}
      %% Skip all integers
      case Xs
      of X|Xr then cond {GetSize X}=1 then {SkipDet Xr} else Xs end
      [] nil then nil
      end
   end
      
   proc {Choose Xs HoleTail HoleHead MinYet SizeYet ?Min ?Ys}
      %% Choose the minimal sized variable in a stable manner, i.e.
      %% never permute the order between variables
      case Xs
      of X|Xr then 
	 local SizeX={GetSize X} in
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
      
   proc {EnumMid Xs}
      choice
	 case {SkipDet Xs}
	 of nil then skip
	 [] X|Xr then
	    local Y Yr Hole Mid in
	       {Choose Xr Yr Hole X {GetSize X} Y Hole}
	       Mid={GetMid Y}
	       choice Y=Mid {EnumMid Yr}
	       []  Y\=:Mid {EnumMid Y|Yr}
	       end
	    end
	 end
      end
   end


   %% Here comes the N-Queens formulation

   proc {NoAttack OtherS Here Diag}
      case OtherS
      of Other|OtherR then 
	 Other\=:Here Other\=:Here+Diag Other\=:Here-Diag 
	 {NoAttack OtherR Here Diag+1}
      [] nil then skip
      end
   end
   proc {Consistent LowS UpS}
      case LowS
      of Here|LowR then
	 thread
	    {Wait Here} 
	    {NoAttack LowR Here 1} 
	    {NoAttack UpS Here 1}
	 end
	 {Consistent LowR Here|UpS}
      [] nil then skip
      end
   end


   %% Reorder a list such that most centered elements are first

   proc {SplitHalf Xs N As Bs}
      cond N=0 then As={Reverse Xs} Bs=nil
      else
	 local X Xr in
	    Xs=X|Xr 
	    Bs=X|{SplitHalf Xr N-1 As} end
      end
   end

   fun {MergeHalves As Bs Cs}
      case As
      of A|Ar then
	 case Bs of nil then A|Cs
	 [] B|Br then {MergeHalves Ar Br A|B|Cs}
	 end
      [] nil then case Bs of [B] then B|Cs [] nil then Cs end
      end
   end

   fun {MkMiddle Xs}
      local As Bs N={Length Xs} in
	 {SplitHalf Xs N div 2 As Bs}
	 {MergeHalves As Bs nil}
      end
   end

   proc {QueensMiddleOut N Board}
      {List.make N Board}
      Board = {FD.dom 1#N}
      {Consistent Board nil}
      {EnumMid {MkMiddle Board}}
   end

   QueensMiddleOutSol = [[6 3 7 2 4 8 1 5]]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% queens from the constraint primer
   QueensPrimer =
   fun {$ N}
      proc {$ X}
	 L1N = {List.number 1 N 1}  % [1 2 3 ... N]
	 LN1 = {List.number N 1 ~1} % [N ... 3 2 1]
      in
	 X = {FD.tuple queens N 1#N}
	 {FD.distinct X}
	 {FD.distinctOffset X L1N}
	 {FD.distinctOffset X LN1}
	 {FD.distribute generic(order:size value:mid) X}
      end
   end
   
   QueensPrimerSol =
   [queens(117 115 80 155 116 84 119 81 91 145 153 118 
	   162 85 147 120 163 70 82 99 165 113 133 62 78 
	   166 66 76 134 114 160 97 75 103 92 44 112 139 63 
	   47 126 185 49 191 94 122 140 102 187 203 31 12 
	   221 232 129 231 121 1 230 9 108 3 227 136 10 4 
	   123 233 5 225 101 226 6 2 98 212 208 7 110 131 
	   229 215 228 209 125 23 106 214 211 8 218 13 111 
	   18 213 15 141 219 223 14 220 217 138 224 222 109 
	   124 216 11 107 17 127 105 128 142 104 130 154 
	   100 132 137 25 93 210 96 135 95 86 22 24 26 143 
	   90 144 89 156 16 27 46 206 41 88 148 35 195 30 
	   87 146 150 193 32 152 73 149 151 69 83 157 74 77 
	   189 207 197 190 36 159 79 37 34 161 192 201 39 
	   71 158 72 164 200 64 169 175 68 168 67 167 172 
	   21 61 65 19 170 176 20 38 171 33 199 173 57 28 
	   205 58 60 194 54 184 59 177 174 55 178 52 56 180 
	   53 179 50 182 51 181 183 40 48 196 198 29 204 
	   202 188 186 42 45 43)]

   Return=
   fd([queens([
	       std(equal(fun {$} {Search.base.one proc {$ X} {Queens 14 X} end}
			 end
			 QueensSol)
		   keys: [fd]
		   bench:10)

	       middle_out(equal(fun {$}
				   {Search.base.one proc {$ X}
						 {QueensMiddleOut 8 X}
					      end}
				end
				QueensMiddleOutSol)
			  keys: [fd]
			  bench:40)

	       primer(equal(fun {$}
			       {Search.base.one {QueensPrimer 233}}
			    end
			    QueensPrimerSol)
		      keys: [fd])

	       std(equal(fun {$} {Search.base.one proc {$ X} {Queens 14 X} end}
			 end
			 QueensSol)
		   keys: [fd])

	       middle_out(equal(fun {$}
				   {Search.base.one proc {$ X}
						 {QueensMiddleOut 8 X}
					      end}
				end
				QueensMiddleOutSol)
			  keys: [fd])

	       primer(equal(fun {$}
			       {Search.base.one {QueensPrimer 233}}
			    end
			    QueensPrimerSol)
		      keys: [fd])

	       std_entailed(entailed(proc {$}
					{Search.base.one proc {$ X} {Queens 14 X} end _}
				     end)
			    keys: [fd entailed])
	       
	       middle_out_entailed(entailed(proc {$}
					       {Search.base.one proc {$ X}
							     {QueensMiddleOut 8 X}
							  end _}
					    end)
				   keys: [fd entailed])

	       primer_entailed(entailed(proc {$}
					   {Search.base.one {QueensPrimer 233} _}
					end)
			       keys: [fd entailed])
	      ])
      ])

end
