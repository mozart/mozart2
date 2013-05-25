functor

import

   FD

   Search


export
   Return
define


% see Sidebottom page 63
% diagnosis of a n-bit adder

   % N: Number of bits
   % X,Y,Z: Input values in decimal
   % C1: Bit for input carry
   % C: Bit for output carry
   % Ds: Diagnosis vector
   % F: Number of faults in decimal
   proc {DiagnosisProblem N X Y Z C1 C Ds F}
      F :: 0#5*N
      {Nadder N X Y Z C1 C Ds}       %N-bit adder
      X + Y + C1 \=: Z + {Pow 2 N}
      {FoldL Ds proc{$ I X O} O :: 0#FD.sup I+X=:O end 0 F}  % Sum of failures must be F
   end

   proc {Nadder N X Y Z C1 C Ds}
      [X Y Z] = {FD.dom 0#{Pow 2 N}-1}
      [C1 C] = {FD.dom 0#1}
      % transform X,Y,Z in bit vectors or vice versa. 
      % Observe: list starts with less valued bit, eg. 6= 011
      local Xs Ys Zs in
	 {Bits N X Xs}
	 {Bits N Y Ys}
	 {Bits N Z Zs}
	 {List.make 5*N Ds}
	 Ds = {FD.dom  0#1}
	 {Adder Xs Ys Zs C1 C Ds nil}   % Adding with bit vectors
      end
   end

   proc {Bits N X Xs}
      {List.make N Xs}
      Xs = {FD.dom  0#1}
      {List.foldLInd Xs proc{$ Ind In X Out} 
			   Out :: 0#FD.sup
			   Out =: X*{Pow 2 Ind-1}+In
			end 0 X}
   end


   proc {Adder Xs Ys Zs Cin Cout Ds Dss}
      % retrieve bits from vectors and call the fulladder
      case Xs
      of X|Xr
      then
	 Y Yr
	 Z Zr
	 D0 D1 D2 D3 D4 DS1
	 CtmpOut
      in
	 Ys=Y|Yr
	 Zs=Z|Zr
	 Ds=D0|D1|D2|D3|D4|DS1
	 CtmpOut :: 0#1
	 {FullAdder X Y Cin Z CtmpOut D0 D1 D2 D3 D4}
	 {Adder Xr Yr Zr CtmpOut Cout DS1 Dss}
      [] nil then Cin=Cout 
	 Ds=Dss
      end
   end

   local
      And = !FD.conj
      Or = !FD.disj
      Not = !FD.nega
      Xor = !FD.exor
      %
      Equiv = FD.equi
   
   in
      proc {FullAdder X Y Cin Z Cout D0 D1 D2 D3 D4}
	 % logical description of a fulladder and the diagnosistic variables
	 local U1 U2 U3 in
	    [U1 U2 U3] = {FD.dom 0#1}
	    {Equiv {Not D0} {Equiv U1 {And X Y}} 1}
	    {Equiv {Not D1} {Equiv U2 {And U3 Cin}} 1}
	    {Equiv {Not D2} {Equiv Cout {Or U1 U2}} 1}
	    {Equiv {Not D3} {Equiv U3 {Xor X Y}} 1}
	    {Equiv {Not D4} {Equiv Z {Xor U3 Cin}} 1}
	    /*
	    {Implies {Not D0} {Equiv U1 {And X Y}} 1}
	    {Implies {Not D1} {Equiv U2 {And U3 Cin}} 1}
	    {Implies {Not D2} {Equiv Cout {Or U1 U2}} 1}
	    {Implies {Not D3} {Equiv U3 {Xor X Y}} 1}
	    {Implies {Not D4} {Equiv Z {Xor U3 Cin}} 1}
	    */
	    {FD.distribute ff [U1 U2 U3]}
	 end
      end
   end

   DiagSol1 =
   [[0 0 0 1 0 0 0 0 0 0]]

   DiagSol2 =
   [[0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1]]

   DiagSol3 =
   [[0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 
     0 0 0 0 1]]

   DiagSol4 =
   [[0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 
     0 0 0 0 1 0 0 0 0 1]]


   Return=

   fd([diagnosis([
		  test1(equal(fun {$}
				 {Search.base.one
				  proc {$ X}
				     {DiagnosisProblem 2 0 0 2 1 0 X 1}
				     {FD.distribute ff X}
				  end}
			      end
			      DiagSol1)
			keys: [fd])
		  test2(equal(fun {$}
				 {Search.base.one
				  proc {$ X}
				     {DiagnosisProblem 5 0 0 31 0 0 X 5}
				     {FD.distribute ff X}
				  end}
			      end
			      DiagSol2)
			keys: [fd])
		  test3(equal(fun {$}
				 {Search.base.one
				  proc {$ X}
				     {DiagnosisProblem 6 0 0 63 0 0 X 6}
				     {FD.distribute ff X}
				  end}
			      end
			      DiagSol3)
			keys: [fd])
		  test4(equal(fun {$}
				 {Search.base.one
				  proc {$ X}
				     {DiagnosisProblem 7 0 0 127 0 0 X 7}
				     {FD.distribute ff X}
				  end}
			      end
			      DiagSol4)
			keys: [fd])

		  test1_entailed(entailed(proc {$}
				 {Search.base.one
				  proc {$ X}
				     {DiagnosisProblem 2 0 0 2 1 0 X 1}
				     {FD.distribute ff X}
				  end _}
			      end)
			keys: [fd entailed])
		  test2_entailed(entailed(proc {$}
				 {Search.base.one
				  proc {$ X}
				     {DiagnosisProblem 5 0 0 31 0 0 X 5}
				     {FD.distribute ff X}
				  end _}
			      end)
			keys: [fd entailed])
		  test3_entailed(entailed(proc {$}
				 {Search.base.one
				  proc {$ X}
				     {DiagnosisProblem 6 0 0 63 0 0 X 6}
				     {FD.distribute ff X}
				  end _}
			      end)
			keys: [fd entailed])
		  test4_entailed(entailed(proc {$}
				 {Search.base.one
				  proc {$ X}
				     {DiagnosisProblem 7 0 0 127 0 0 X 7}
				     {FD.distribute ff X}
				  end _}
					  end)
			keys: [fd entailed])
		 ])
      ])
   
end
