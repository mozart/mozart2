functor
export Return
define
   Iterations = 1000000
   proc {Producer P N}
      if N>0 then {Port.send P unit} {Producer P N-1} end
   end
   proc {PortBench}
      {Producer {Port.new _} Iterations}
   end
   Return = port(PortBench
		 keys:[port]
		 bench:1)
end
