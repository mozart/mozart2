functor

import

   FD

   Search

export
   Return
define



   Family =
   proc {$ Root}
      proc {FamilyC Name F}
	 Coeffs = [1 1 1 ~1 ~1 ~1]
	 Ages
      in
	 F = Name(boys:{AgeList} girls:{AgeList})
	 Ages = {Append F.boys F.girls}
	 {FD.distinct Ages}
	 {FD.sumC Coeffs Ages '=:' 0}
	 {FD.sumCN Coeffs {Map Ages fun {$ A} [A A] end} '=:' 0}
      end
      proc {AgeList L}
	 {FD.list 3 0#9 L}
	 {Nth L 1} >: {Nth L 2}
	 {Nth L 2} >: {Nth L 3}
      end
      Maria = {FamilyC maria}
      Clara = {FamilyC clara}
      AgeOfMariasYoungestGirl = {Nth Maria.girls 3}
      AgeOfClarasYoungestGirl = {Nth Clara.girls 3}
      Ages = {FoldR [Clara.girls Clara.boys Maria.girls Maria.boys] Append nil}
   in
      Root = Maria#Clara
      {ForAll Maria.boys proc {$ A} A >: AgeOfMariasYoungestGirl end}
      AgeOfClarasYoungestGirl = 0
      {FD.sum Ages '=:' 60}
      {FD.distribute split Ages}
   end

   FamilySol =
   [maria(boys:[9 5 4] girls:[8 7 3])#
    clara(boys:[8 3 1] girls:[7 5 0])]
	   
   Return=
   fd([family([
	       all(equal(fun {$} {Search.base.all Family} end
			 FamilySol)
		   keys: [fd])
	       all_entailed(entailed(proc {$} {Search.base.all Family _} end)
		   keys: [fd entailed])
	      ])
      ])
   
end
