functor

import

   FD

   Search

export
   Return
define

   SRAT = 
   proc {$ Q}
      proc {Vector V}  
	 {FD.tuple v 10 0#1 V} 
      end
      proc {Sum V S}  
	 {FD.decl S} 
	 {FD.sum V '=:' S} 
      end
      proc {Assert I [U V W X Y]}  
	 A.I=U  B.I=V  C.I=W  D.I=X  E.I=Y 
      end
      A      = {Vector}              B    = {Vector}
      C      = {Vector}              D    = {Vector}        E    = {Vector}
      SumA   = {Sum A}               SumB = {Sum B}         SumC = {Sum C}  
      SumD   = {Sum D}               SumE = {Sum E}
      SumAE  = {Sum [SumA SumE]}     
      SumBCD = {Sum [SumB SumC SumD]}
   in
      {FD.tuple q 10 1#5 Q}
      {For 1 10 1
       proc {$ I} {Assert I [Q.I=:1  Q.I=:2  Q.I=:3  Q.I=:4  Q.I=:5]} end}
%1
      {Assert 1 [ B.2
		  {FD.conj B.3 (B.2=:0)}
		  {FD.conj B.4 (B.2+B.3=:0)}
		  {FD.conj B.5 (B.2+B.3+B.4=:0)}
		  {FD.conj B.6 (B.2+B.3+B.4+B.5=:0)} ]}
%2
      {Assert 2 [Q.2=:Q.3  Q.3=:Q.4  Q.4=:Q.5  Q.5=:Q.6  Q.6=:Q.7]}
      Q.1\=:Q.2  Q.7\=:Q.8  Q.8\=:Q.9  Q.9\=:Q.10
%3
      {Assert 3 [Q.1=:Q.3  Q.2=:Q.3  Q.4=:Q.3  Q.7=:Q.3  Q.6=:Q.3]}
%4
      {FD.element Q.4 [0 1 2 3 4] SumA}
%5
      {Assert 5 [Q.10=:Q.5  Q.9=:Q.5  Q.8=:Q.5  Q.7=:Q.5  Q.6=:Q.5]}
%6
      {Assert 6 [SumA=:SumB  SumA=:SumC  SumA=:SumD  SumA=:SumE  _]}
%7
      {FD.element Q.7 [4 3 2 1 0] {FD.decl}={FD.distance Q.7 Q.8 '=:'}}
%8
      {FD.element Q.8 [2 3 4 5 6] SumAE}
%9
      {Assert 9 [{FD.reified.int [2 3 5 7] SumBCD }
		 {FD.reified.int [1 2 6] SumBCD }
		 {FD.reified.int [0 1 4 9] SumBCD }
		 {FD.reified.int [0 1 8] SumBCD }
		 {FD.reified.int [0 5 10] SumBCD }
		]}
%10
      skip
      {FD.distribute ff Q}
   end

   SRATSol = [q(3 4 5 2 5 5 4 3 2 1)]

   Return=
   fd([srat([
	     all(equal(fun {$} {Search.base.all SRAT} end
		       SRATSol)
		 keys: [fd])
	     all_entailed(entailed(proc {$} {Search.base.all SRAT _} end)
		 keys: [fd entailed])
	    ])
      ])

end
