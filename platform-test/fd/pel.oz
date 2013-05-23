functor

import

   FD

export
   Return
define

   PelTest =
   fun {$ N T}
      L = {StringToAtom {VirtualString.toString N}}
   in
      L(equal(T 1) keys: [fd pel])
   end

   Return=
   prop_engine_lib(
      [tasksOverlap([
		     {PelTest 1
                         % testing constructive disjunction part
                         % expected result: X{0#2 8#10} /\ Y{0#2 8#10}
		      fun {$}
			 X Y
		      in
			 [X Y] ::: 0#10
			 {FD.tasksOverlap X 8 Y 8 0}
			 cond X :: [0#2 8#10] Y :: [0#2 8#10] then 1 else 0 end
		      end}
		     {PelTest 2
                         % testing top commit
                         % expected result: B = 0
		      fun {$}
			 X Y B
		      in
			 [X Y B] ::: 0#10
			 {FD.tasksOverlap X 8 Y 8 B}
			 X =<: 1
			 Y >=: 9
			 if B == 0 then 1 else 0 end
		      end}
		     {PelTest 3
                         % testing top commit
                         % expected result: B = 0
		      fun {$}
			 X Y B in [X Y B] ::: 0#10
			 {FD.tasksOverlap X 8 Y 8 B}
			 Y =<: 1
			 X >=: 9
			 if B == 0 then 1 else 0 end
		      end}
		     {PelTest 4
                         % testing propagation of overlap clause and
                         % verifying by top commit
                         % expected result: B = 1
		      fun {$}
			 X Y B
		      in
			 [X Y B] ::: 0#10
			 {FD.tasksOverlap X 2 Y 2 B}

			 X >: 4
			 Y <: 5

			 X = 5
			 Y = 4
			 B
		      end}
		     {PelTest 5
                         % testing unit commit of first clause
                         % expected result: X = 5 /\ Y = 4
		      fun {$}
			 X Y in [X Y] ::: 0#10
			 {FD.tasksOverlap X 2 Y 2 1}

			 X >: 4
			 Y <: 5

			 cond X = 5 Y = 4 then 1 else 0 end
		      end}
		    ])
      ])
end

