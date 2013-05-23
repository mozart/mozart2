functor

import

   FD

   Search

export
   Return
define

   Multiply = 
   proc {$ Sol}
      A B C D E F G H I J K L M N O P Q R S T
      N1 N2 R1 R2 R3
   in
   % the solution consists of digits
      Sol = [A B C D E F G H I J K L M N O P Q R S T]
      Sol ::: 0#9
   % each digit occurs exactly twice
      {ForAll {List.number 0 9 1}
       proc {$ I} {FD.exactly 2 Sol I} end}
   % no leading zeros
      [A D G J M P] ::: compl(0)
   % the 2 operands and 3 intermediate results
      [N1 N2 R1 R2 R3]:::1#999
      N1 =: 100*A+10*B+C
      N2 =: 100*D+10*E+F
      R1 =: 100*G+10*H+I
      R2 =: 100*J+10*K+L
      R3 =: 100*M+10*N+O
   % compute intermediate results (method 1)
      F*N1 =: R1
      E*N1 =: R2
      D*N1 =: R3
   % compute intermediate results (method 2)
      local
	 proc {Mul I [X1 X2 X3] [Y1 Y2 Y3]}
	    C1 C2
	 in
	    [C1 C2]:::0#9
	    I*X3      =: Y3 + 10*C1
	    I*X2 + C1 =: Y2 + 10*C2
	    I*X1 + C2 =: Y1
	 end
      in
	 {Mul F [A B C] [G H I]}
	 {Mul E [A B C] [J K L]}
	 {Mul D [A B C] [M N O]}
      end
   % add up intermediate results (method 1)
      100*R3+10*R2+R1 =: 10000*P+1000*Q+100*R+10*S+T
   % add up intermediate results (method 2)
      local C1 C2 C3 in
	 [C1 C2 C3] ::: [0 1 2]
	 I=T
	 H+L      =: S + 10*C1
	 G+K+O+C1 =: R + 10*C2
	 J+N  +C2 =: Q + 10*C3
	 M    +C3 =: P
      end
   % break symmetry
      N1 =<: N2
   % reduce search space
      F\=:1 %else C=I=T
      F\=:0 %else F=I=T=0
      C\=:1 %else F=I=T
      C\=:0 %else C=I=T=0
   % distribution strategy
      {FD.distribute ff Sol}
   end

   MultiplySol = [[1 7 9 2 2 4 7 1 6 3 5 8 3 5 8 4 0 0 9 6]]

   Return=
   fd([multiply([
		 all(equal(fun {$} {Search.base.all Multiply} end
			   MultiplySol)
		     keys: [fd])
		 all_entailed(entailed(proc {$} {Search.base.all Multiply _} end)
			      keys: [fd entailed])
		])
      ])
   
end
