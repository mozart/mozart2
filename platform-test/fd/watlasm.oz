functor

import

   FD

   System(show: Show)

export
   Return
define

   I = 10
   B = {FD.int 0#1}
   FI = {FD.int [10#30]}
   FB = {FD.int [2 4 6 20#30]}
   FL = {FD.int [2000 4000 6000 20000#30000]}
   
   MiscTest =
   fun {$ N T}
      L = {StringToAtom {VirtualString.toString N}}
   in
      L(equal(T 1) keys: [fd])
   end
   
   Return=
   fd([watlasm([
		
		{MiscTest 1
		 fun {$}
		    cond {FD.reflect.nextSmaller I 100} = 10
		    then 1 else {Show f#1} 0 end
		 end}
		
		{MiscTest 2
		 fun {$}
		    cond {FD.reflect.nextSmaller I 10} = _
		    then {Show f#2} 0 else 1 end
     		 end}

		{MiscTest 3
		 fun {$}
		    cond {FD.reflect.nextSmaller B 100} = 1
		    then 1 else {Show f#3} 0 end
		 end}

		{MiscTest 4
		 fun {$}
		    cond {FD.reflect.nextSmaller B 1} = 0
		    then 1 else {Show f#4} 0 end
		 end}

		{MiscTest 5
		 fun {$}
		    cond {FD.reflect.nextSmaller B 0} = _
		    then {Show f#5} 0 else  1 end
		 end}

		{MiscTest 6
		 fun {$}
		    cond {FD.reflect.nextSmaller B ~10} = _
		    then {Show f#27} 0 else 1 end
		 end}
     
		{MiscTest 7
		 fun {$}
		    cond {FD.reflect.nextSmaller FI 100} = 30
		    then 1 else {Show f#6} 0 end
		 end}
		    
		{MiscTest 8
		 fun {$}
		    cond {FD.reflect.nextSmaller FI 30} = 29
		    then  1 else {Show f#7} 0 end
		 end}
		    
		{MiscTest 9
		 fun {$}
		    cond {FD.reflect.nextSmaller FI 11} = 10
		    then  1 else {Show f#8} 0 end
		 end}

		{MiscTest 10
		 fun {$}
		    cond {FD.reflect.nextSmaller FI 10} = _
		    then {Show f#9} 0 else  1 end
		 end}

		{MiscTest 11
		 fun {$}
		    cond {FD.reflect.nextSmaller FI 1} = _
		    then {Show f#10} 0 else  1 end
     		 end}

		{MiscTest 12
		 fun {$}
		    cond {FD.reflect.nextSmaller FB 100} = 30
		    then 1 else {Show f#11} 0 end
		 end}

		{MiscTest 13
		 fun {$}
		    cond {FD.reflect.nextSmaller FB 31} = 30
		    then 1 else {Show f#12} 0 end
		 end}

		{MiscTest 14
		 fun {$}
		    cond {FD.reflect.nextSmaller FB 30} = 29
		    then 1 else {Show f#13} 0 end
		 end}

		{MiscTest 15
		 fun {$}
		    cond {FD.reflect.nextSmaller FB 21} = 20
		    then 1 else {Show f#14} 0 end
		 end}

		{MiscTest 16
		 fun {$}
		    cond {FD.reflect.nextSmaller FB 20} = 6
		    then 1 else {Show f#15} 0 end
		 end}

		{MiscTest 17
		 fun {$}
		    cond {FD.reflect.nextSmaller FB 10} = 6
		    then 1 else {Show f#16} 0 end
		 end}

		{MiscTest 18
		 fun {$}
		    cond {FD.reflect.nextSmaller FB 4} = 2
		    then 1 else {Show f#17} 0 end
		 end}

		{MiscTest 19
		 fun {$}
		    cond {FD.reflect.nextSmaller FB 2} = _
		    then {Show f#18} 0 else 1 end
		 end}

		{MiscTest 20
		 fun {$}
		    cond {FD.reflect.nextSmaller FL 100000} = 30000
		    then 1 else {Show f#19} 0 end
		 end}


		{MiscTest 21
		 fun {$}
		    cond {FD.reflect.nextSmaller FL 30001} = 30000
		    then 1 else {Show f#20} 0 end
		 end}

		{MiscTest 22
		 fun {$}
		    cond {FD.reflect.nextSmaller FL 30000} = 29999
		    then 1 else {Show f#21} 0 end
		 end}


		{MiscTest 23 
		 fun {$}
		    cond {FD.reflect.nextSmaller FL 20001} = 20000
		    then  1 else {Show f#22} 0 end
		 end}

		{MiscTest 24
		 fun {$}
		    cond {FD.reflect.nextSmaller FL 20000} = 6000
		    then  1 else {Show f#23} 0 end
		 end}
		    
		{MiscTest 25
		 fun {$}
		    cond {FD.reflect.nextSmaller FL 10000} = 6000
		    then  1 else {Show f#24} 0 end
		 end}

		{MiscTest 26
		 fun {$}
		    cond {FD.reflect.nextSmaller FL 4000} = 2000
		    then  1 else {Show f#25} 0 end
		 end}

		{MiscTest 27
		 fun {$}
		    cond {FD.reflect.nextSmaller FL 2000} = _
		    then {Show f#26} 0 else  1 end
		 end}
     
     %% nextLarger
		{MiscTest 28
		 fun {$}
		    cond {FD.reflect.nextLarger I 1} = 10
		    then 1 else {Show f#101} 0 end
		 end}

		{MiscTest 29
		 fun {$}
		    cond {FD.reflect.nextLarger I 10} = _
		    then {Show f#102} 0 else  1 end
		 end}
     
		{MiscTest 30
		 fun {$}
		    cond {FD.reflect.nextLarger B ~100} = 0
		    then 1 else {Show f#103} 0 end
		 end}

		{MiscTest 31
		 fun {$}
		    cond {FD.reflect.nextLarger B 0} = 1
		    then  1 else {Show f#104} 0 end
		 end}

		{MiscTest 32
		 fun {$}
		    cond {FD.reflect.nextLarger B 1} = _
		    then {Show f#105} 0 else 1 end
		 end}

		{MiscTest 33
		 fun {$}
		    cond {FD.reflect.nextLarger B 100} = _
		    then {Show f#1027} 0 else 1 end
		 end}
     
		{MiscTest 34
		 fun {$}
		    cond {FD.reflect.nextLarger FI 1} = 10
		    then  1 else {Show f#106} 0 end
		 end}

		{MiscTest 35
		 fun {$}
		    cond {FD.reflect.nextLarger FI 10} = 11
		    then  1 else {Show f#107} 0 end
		 end}

		{MiscTest 36
		 fun {$}
		    cond {FD.reflect.nextLarger FI 29} = 30
		    then 1 else {Show f#108} 0 end
		 end}

		{MiscTest 37
		 fun {$}
		    cond {FD.reflect.nextLarger FI 30} = _
		    then {Show f#109} 0 else 1 end
		 end}

		{MiscTest 38
		 fun {$} 
		    cond {FD.reflect.nextLarger FI 100} = _
		    then {Show f#110} 0 else 1 end
		 end}
     
		{MiscTest 39
		 fun {$}
		    cond {FD.reflect.nextLarger FB 1} = 2
		    then  1 else {Show f#111} 0 end
		 end}

		{MiscTest 40
		 fun {$}
		    cond {FD.reflect.nextLarger FB 2} = 4
		    then  1 else {Show f#112} 0 end
		 end}

		{MiscTest 41
		 fun {$}
		    cond {FD.reflect.nextLarger FB 10} = 20
		    then  1 else {Show f#113} 0 end
		 end}

		{MiscTest 42
		 fun {$}
		    cond {FD.reflect.nextLarger FB 19} = 20
		    then 1 else {Show f#114} 0 end
		 end}

		{MiscTest 43 
		 fun {$}
		    cond {FD.reflect.nextLarger FB 20} = 21
		    then 1 else {Show f#115} 0 end
		 end}

		{MiscTest 44
		 fun {$}
		    cond {FD.reflect.nextLarger FB 29} = 30
		    then  1 else {Show f#116} 0 end
		 end}

		{MiscTest 45
		 fun {$}
		    cond {FD.reflect.nextLarger FB 30} = _
		    then {Show f#117} 0 else  1 end
		 end}

		{MiscTest 46
		 fun {$}
		    cond {FD.reflect.nextLarger FB 200} = _
		    then {Show f#118} 0 else  1 end
		 end}
		
		{MiscTest 47
		 fun {$} F = {FD.int [10#40 45 50#100]}
		    FS = {FD.reflect.size F} R in
		    thread
		       if {FD.watch.size F FS}
		       then F = 40 else {Show f200a} R=0 end
		    end
		    cond FS = {FD.reflect.size F}
		    then skip else {Show f200b} R=0 end
		    F \=: 45
		    thread
		       cond F = 40 then R=1 else {Show f200c} R=0 end
		    end
		    R
		 end}
     
		{MiscTest 48
		 fun {$}
		    F = {FD.int [10#40 45 50#100]}
		    FMin = {FD.reflect.min F} R in
		    thread
		       if {FD.watch.min F FMin}
		       then F = 40 else {Show f201a} R=0 end
		    end
		    cond FMin = {FD.reflect.min F}
		    then skip else {Show f201b} R=0 end
		    F >: 10
		    thread
		       cond F = 40 then  R=1 else {Show f201c} R=0 end
		    end
		    R
		 end}
     
		{MiscTest 49
		 fun {$}
		    F = {FD.int [10#40 45 50#100]}
		    FMax = {FD.reflect.max F} R in
		    thread
		       if {FD.watch.max F FMax}
		       then F = 40 else {Show f202a} R=0 end
		    end
		    cond FMax = {FD.reflect.max F}
		    then skip else {Show f202b} R=0 end
		    F <: 100
		    thread
		       cond F = 40 then  R=1 else {Show f202c} R=0 end
		    end
		    R
		 end}
		
		{MiscTest 50
		 fun {$} F = {FD.int 0#10} R in
		    thread
		       R = if {FD.watch.size F 0} then 0 else 1 end
		    end
		    R
		 end}
		
		{MiscTest 51
		 fun {$} F = {FD.int 0#10} R in
		    thread
		       R = if {FD.watch.size F 1} then 0 else 1 end
		    end
		    F=1
		    R
		 end}
		
		{MiscTest 52
		 fun {$} F = {FD.int 0#10} R in
		    thread
		       R = if {FD.watch.min F ~1} then 0 else 1 end
		    end
		    R
		 end}
		
		{MiscTest 53
		 fun {$} F = {FD.int 0#10} R in
		    thread
		       R = if {FD.watch.max F ~1} then 0 else 1 end
		    end
		    R
		 end}
		
		{MiscTest 54
		 fun {$} X = {FD.int 0#10} R in
		    thread
		       R = if {FD.watch.min X 5} then 0 else 1 end
		    end
		    X <: 5
		    R
		 end}
	       ])
      ])
   
end
