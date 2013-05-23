fun {ComputeTests Argv}
   Keys =  case Argv.keys of nil then AllKeys else
	      {Filter
	       {Map Argv.keys String.toAtom}
	       fun {$ K}
		  {Member K AllKeys}
	       end}
	   end
   Tests = case Argv.tests of nil then AllTests
	   elseof TestTests then
	      {Filter AllTests
	       fun {$ T}
		  S1={Atom.toString {Label T}}
	       in
		  {Some TestTests
		   fun {$ S2}
		      {IsIn S2 S1}
		   end}
	       end}
	   end
   Tests1 = case Argv.ignores of nil then Tests
	    elseof TestTests then
	       {Filter Tests
		fun {$ T}
		   S1={Atom.toString {Label T}}
		in
		   {All TestTests
		    fun {$ S2}
		       {IsNotIn S2 S1}
		    end}
		end}
	    end
   RunTests = {Filter Tests1
	       fun {$ T}
		  {Some T.keys fun {$ K1}
				  {Member K1 Keys}
			       end}
	       end}
   local
      TestDict = {Dictionary.new}

      fun {GetIt T|Tr I}
	 if {Label T}==I then T else {GetIt Tr I} end
      end
      fun {FindTest I|Is S}
	 {Label S}=I
	 case Is of nil then S
	 [] I|_ then {FindTest Is {GetIt S.1 I}}
	 end
      end
	 
      ModMan = {New Module.manager init}

   in
      fun {GetTest TD}
	 TL = {Label TD}
	 T  = {ModMan link(url:TD.url $)}.return
      in
	 if {Dictionary.member TestDict TL} then skip
	 else {Dictionary.put TestDict TL {FindTest TD.id T}}
	 end
	 {Dictionary.get TestDict TL}
      end
   end
in
   {Map RunTests
    fun lazy {$ T}
       S={GetTest T}.1
    in
       {Adjoin
	{Adjoin o(script: S)
	 {Debug.procedureCoord
	  if {IsProcedure S} then S else S.1 end}}
	T}
    end}
end
