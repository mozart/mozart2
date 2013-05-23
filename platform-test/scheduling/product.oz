functor

import

   FD

   Search

export
   Return
define

% Data divided by 10. No consideration of Uebergangsmengen.
% Version with realtimes, uebergaenge are included.
% Predecessors are made explicit
% SC is a redundant but very useful constraint


   Limit=50  %24*7*3 div 10
   NoPred=10
   % mapping from predecessors to job names
   NameTab=nameTab(n430 n730 l430 e464 e564 h764 h864 d464 d780)
   % mapping from names to predecessors
   PredTab=predTab(n430:1 n730:2 l430:3 e464:4 e564:5
		   h764:6 h864:7 d464:8 d780:9)
   % durations of jobs
   Durs= dur(n430:12#7 n730:10#6 l430:13#8 e464:5#5
	     e564:3#3 h764:15#9 h864:8#5 d464:11#13 d780:10#10)

   local
      proc {Help From Tos Ueb Acc NewUeb NewAcc}
	 case Tos of nil then NewUeb=Ueb NewAcc=Acc
	 [] To|Tor
	 then {Help From Tor Ueb.2 {AdjoinAt Acc From
				    {AdjoinAt Acc.From To Ueb.1}}
	       NewUeb NewAcc}
	 end
      end
   in 
      fun {Accumulate Ls T Ueb Acc}
	 case Ls of nil then Acc
	 [] From|Lr
	 then NUeb NAcc in
	    {Help From {Append T Lr} Ueb Acc NUeb NAcc}
	    {Accumulate Lr {Append T [From]} NUeb NAcc}
	 end
      end
   end
   
   % Tables with uebergaengen 
   M1Uebergaenge = {Accumulate [n430 n730 l430 e464 e564 h764 h864 d464 d780]
		    nil
		    {Reverse
		     2|5|5|4|4|5|6|6|
		     2|1|1|0|0|4|3|3|
		     3|0|0|0|0|4|3|3|
		     3|0|0|0|0|4|3|3|
		     2|0|1|1|0|4|3|3|
		     2|0|1|1|0|4|3|3|
		     2|4|3|3|4|4|3|3|
		     5|4|3|3|4|4|3|0|
		     5|4|3|3|4|4|3|0|nil}
		    ueb(n430:to n730:to l430:to e464:to e564:to h764:to
			h864:to d464:to d780:to)}
   M2Uebergaenge = {Accumulate [n430 n730 l430 e464 e564 h764 h864 d464 d780]
		    nil
		    {Reverse
		     2|5|5|4|4|5|6|6|
		     2|1|1|0|0|5|4|4|
		     3|0|0|0|0|5|4|4|
		     3|0|0|0|0|5|4|4|
		     2|0|1|1|0|5|4|4|
		     2|0|1|1|0|5|4|4|
		     2|5|4|4|5|5|4|4|
		     6|5|4|4|5|5|4|0|
		     6|5|4|4|5|5|4|0|nil}	    
		    ueb(n430:to n730:to l430:to e464:to e564:to h764:to
			h864:to d464:to d780:to)}
   
   

   % Initialize domains of jobs
   proc{DeclareVariables Jobs NamesToJobs}
      Jobs={FoldL [n430 n730 l430 e464 e564 h764 h864 d464 d780]
	    fun{$ In JobName}
	       Machine Start Dur Uebergang Pred in
	       Machine :: 1#2 
	       Start :: 1#Limit
	       Dur :: 3#15  
	       Uebergang :: 0#6  
	       Pred :: 1#NoPred 
	       jobb(name:JobName start:Start machine:Machine dur:Dur
		    ueb:Uebergang pred:Pred)|In
	    end nil}
      % mapping from names to jobs
      NamesToJobs = {FoldL Jobs fun{$ I J} {AdjoinAt I J.name J} end jobs}
   end

   % Duration of a job depends on its machine
   proc {DurConstraints Jobs NamesToJobs}
      {ForAll [n430 n730 l430 e464 e564 h764 h864 d464 d780]
       proc{$ Job}
	  J=NamesToJobs.Job in
	  thread
	     or J.machine=1 J.dur=Durs.Job.1
	     [] J.machine=2 J.dur=Durs.Job.2
	     end
	  end
       end}
   end

   % Jobs must be scheduled continually
   proc {SC Jobs}
      thread 
	 M1={FoldL Jobs fun{$ I J} cond J.machine=1 then J|I else I end end nil}
	 M2={FoldL Jobs fun{$ I J} cond J.machine=2 then J|I else I end end nil}
      in
	 {FoldL M1 fun{$ I M} {FD.min M.start I} end FD.sup}
	 + {FoldL M1 fun{$ I M} {FD.plus I {FD.plus M.dur M.ueb}} end 0}
	 =: {FoldL M1 fun{$ I M} {FD.max {FD.plus M.start {FD.plus M.ueb M.dur}} I} end 0}

	 {FoldL M2 fun{$ I M} {FD.min M.start I} end FD.sup}
	 + {FoldL M2 fun{$ I M} {FD.plus I {FD.plus M.ueb M.dur}} end 0}
	 =: {FoldL M2 fun{$ I M} {FD.max {FD.plus M.start {FD.plus M.ueb M.dur}} I} end 0}
      end

   end
   
   % Jobs must be finished at most at Limit
   proc {EndConstraints Jobs}
      {ForAll Jobs proc{$ Job} Job.start=<:Limit-Job.dur-Job.ueb end}
   end
   
   local
      % Take only possible Uebergaenge into account
      proc {ReduceDomains Uebergaenge Jobs}
	 thread
	    {ForAll Jobs proc{$ J}
			    J.ueb ::{FoldL {Arity Uebergaenge.(J.name)}
				     fun{$ I N} Uebergaenge.(J.name).N|I end
				     nil}
			 end}
	 end
      end
      % Reduce predecessors dependening on jobs scheduled on machine
      proc {ReducePreds Jobs}
	 thread 
	    {ForAll Jobs proc{$ J}
			    J.pred\=:PredTab.(J.name)
			    J.pred:: {FoldL Jobs fun{$ I J}
						    PredTab.(J.name)|I
						 end [NoPred]}
			 end}
	 end
      end
      % Set predecesor if task precedes directly the other or vice cersa
      proc {Continually Ls Acc}
	 thread 
	    case Ls of nil then skip
	    [] L|Lr
	    then {Do L {Append Lr Acc}} 
	       {Continually Lr L|Acc}
	    end
	 end
      end
      proc {Do Job Js}
	 case Js of nil then skip
	 [] J|Jr then
	    thread
	       or J.start+J.dur+J.ueb=:Job.start
		  Job.pred=PredTab.(J.name)
	       [] J.start+J.dur+J.ueb\=:Job.start
		  Job.pred\=:PredTab.(J.name)
	       end
	    end
	    {Do Job Jr}
	 end
      end
      % Determine Uebergaenge depending on machine
      proc {DefineUebergaenge Uebergaenge Jobs}
	 thread 
	    {ForAll Jobs proc{$ J}
			    thread
			       or J.pred=NoPred J.ueb=0
			       [] J.pred\=:NoPred
				  J.ueb=Uebergaenge.(NameTab.(J.pred)).(J.name)
			       end
			    end
			 end}
	 end
      end
      % Use element constraint to further reduce Uebergaenge
      proc {Elements Jobs Ueb}
	 thread
	    {ForAll Jobs proc{$ Job}
			    {FD.element Job.pred 
			     {Reverse 0|{FoldL [n430 n730 l430 e464 e564 h764 h864 d464 d780]
					 fun{$ I J} cond J=Job.name then NoPred|I
						    else Ueb.J.(Job.name)|I
						    end
					 end
					 nil}}
			     Job.ueb}
			 end}
	 end
      end
   in
      % Deals with predecesors and resulting Uebergaenge
      proc {UebergangsConstraints Jobs}
	 M1Jobs M2Jobs
      in 
	 thread
	    M1Jobs = {FoldL Jobs fun{$ I J} cond J.machine=1 then J|I else I end
				 end nil}
	 end
	 thread 
	    M2Jobs = {FoldL Jobs fun{$ I J} cond J.machine=2 then J|I else I end
				 end nil}
	 end 
	 {ReduceDomains M1Uebergaenge M1Jobs}
	 {ReduceDomains M2Uebergaenge M2Jobs}
	 {ForAll Jobs proc{$ Job} Job.ueb\=:PredTab.(Job.name) end}
	 % instead of reducing domains one can state that the
	 % predecessors must run on the same machine (but more expensive!).
	 {ReducePreds M1Jobs}
	 {ReducePreds M2Jobs}
	 % Predecessors must be different
	 thread {FD.distinct {FoldL M1Jobs fun{$ I J} J.pred|I end nil}} end
	 thread {FD.distinct {FoldL M2Jobs fun{$ I J} J.pred|I end nil}} end
	 % On one machine only one task with no predecessor
	 thread
	    {FD.sum {FoldL M1Jobs fun{$ I J} (J.pred=:NoPred)|I end nil} '=:' 1}
	 end
	 thread 
	    {FD.sum {FoldL M2Jobs fun{$ I J} (J.pred=:NoPred)|I end nil} '=:' 1}
	 end
	 {Continually M1Jobs nil}
	 {Continually M2Jobs nil}
	 {DefineUebergaenge M1Uebergaenge M1Jobs}
	 {DefineUebergaenge M2Uebergaenge M2Jobs}
	 {Elements M1Jobs M1Uebergaenge}
	 {Elements M2Jobs M2Uebergaenge}
      end
   end
   
   % Additional production constraints
   proc {AdditionalConstraints Jobs NamesToJobs}
      N430=NamesToJobs.n430
      E564=NamesToJobs.e564
      D780=NamesToJobs.d780
      D464=NamesToJobs.d464
   in
      % 200 t n430 until third day
      thread
	 or N430.machine=1 N430.start+N430.ueb =<: (48-11) div 10
	 [] N430.machine=2 N430.start+N430.ueb =<: (48-7) div 10
	 end
      end
      % 100 t e564 until 4th day
      E564.start+E564.ueb =<: (72-6) div 10
      % 200 t d780 until 5th day
      thread
	 or D780.machine=1 D780.start+D780.ueb =<: (96-14) div 10
	 [] D780.machine=2 D780.start+D780.ueb =<: (96-13) div 10
	 end
      end
      % 600 t d464 between 8th and 11th day
      thread
	 or D464.machine=1 D464.start+D464.ueb =<: (240-35) div 10
	    D464.start+D464.ueb >=: (168-82) div 10
	 [] D464.machine=2 D464.start+D464.ueb =<: (240-40) div 10
	    D464.start+D464.ueb >=: (168-93) div 10
	 end
      end
      D464.machine=1
      D780.machine=1
   end
   
   proc {Product Jobs}
      NamesToJobs 
   in

      {DeclareVariables Jobs NamesToJobs}
      %   {ResourceConstraints Jobs}  %redundant and inefficient
      {DurConstraints Jobs NamesToJobs}
      {SC Jobs}    %redundant but speedup of five
      {EndConstraints Jobs}
      {UebergangsConstraints Jobs}
      {AdditionalConstraints Jobs NamesToJobs}
      {FD.distribute ff {FoldL Jobs fun{$ I J} J.machine|I end nil}}
      {FD.distribute ff {FoldL Jobs fun{$ I J} J.pred|I end nil}}
      {FD.distribute ff {FoldL Jobs fun{$ I J} J.start|I end nil}}
   end

   ProductSol =
   [[jobb(dur:10 machine:1 name:d780 pred:5 start:4 ueb:2) 
     jobb(dur:11 machine:1 name:d464 pred:9 start:16 ueb:2) 
     jobb(dur:5 machine:2 name:h864 pred:6 start:27 ueb:0) 
     jobb(dur:9 machine:2 name:h764 pred:2 start:14 ueb:4) 
     jobb(dur:3 machine:1 name:e564 pred:10 start:1 ueb:0) 
     jobb(dur:5 machine:2 name:e464 pred:7 start:32 ueb:0) 
     jobb(dur:13 machine:1 name:l430 pred:8 start:29 ueb:4) 
     jobb(dur:6 machine:2 name:n730 pred:1 start:8 ueb:0) 
     jobb(dur:7 machine:2 name:n430 pred:10 start:1 ueb:0)]]

   Return=
   schedule([product([
		      best(equal(fun {$}
				    {Search.base.best
				     Product
				     proc{$ Old New}
					local N O in
					   N = {FoldL New
						fun{$ I J} {FD.plus I J.ueb}
						end 0}
					   O = {FoldL Old
						fun{$ I J} {FD.plus I J.ueb}
						end 0}
					   N <: O
					end
				     end}
				 end
				 ProductSol)
			   keys: [fd scheduling])
		      best_entailed(entailed(proc {$}
						{Search.base.best
						 Product
						 proc{$ Old New}
						    local N O in
						       N = {FoldL New
							    fun{$ I J} {FD.plus I J.ueb}
							    end 0}
						       O = {FoldL Old
							    fun{$ I J} {FD.plus I J.ueb}
							    end 0}
						       N <: O
						    end
						 end _}
					     end)
				    keys: [fd scheduling entailed])
		     ])
	    ])
   
end



