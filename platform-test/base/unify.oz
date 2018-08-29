functor
import
   VM
export
   Return
define
   Return = unify([vmlist(proc {$}
			     try
				{VM.list} = unit
				fail
			     catch failure(debug:d(info:[eq(unit _)] ...) ...) then
				skip
			     end
			  end
			  keys:[unify])
                   order(proc {$}
			    fun {Const X} [1 2 X] end
			 in
			    try
			       {Const 1} = {Const 2}
			       fail
			    catch failure(debug:d(info:[eq(1 2)] ...) ...) then
			       skip
			    end
			 end
			 keys:[unify])
		  ])
end
