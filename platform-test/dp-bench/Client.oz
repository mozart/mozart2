functor
import
   System
   Connection
   Application
   Pickle
   DPStatistics
   Property
   Module
define
   proc{LFTW I P}
      {Wait {Loop.forThread  1 I 1 fun{$ Ind _} {P Ind} end unit}}
   end
   
   
   
   Tests = [t(proc{$ Th I P}
		 {LFTW Th
		  proc{$ Ind  Ans}
		     thread
			{For 1 I 1
			 proc{$ _} 
			    S Np in
				  Np = {NewPort S}
			    {Send P new_port(Np)}
			    {Wait S}
			 end}
			Ind = Ans
		     end
		  end}
	      end
	      threadImportExportEntity)

	    t(proc{$ Th I P}
		  {LFTW Th
		   proc{$ Ind  Ans}
		      thread
			 {For 1 I 1
			  proc{$ _} 
			     {Wait {Send P bind($)}    }
			       end}
			 Ind = Ans
		      end
		   end}
	      end
	      threadBindVar)
	    
	    t(proc{$ Th I P}
		  {LFTW Th
		   proc{$ Ind  Ans}
		      thread
			 {For 1 I 1
			  proc{$ _} 
			     S Np in
			     Np = {NewPort S}
			     {Send P no_port(Np)}
			     {Wait S}
			  end}
			 Ind = Ans
		      end
		   end }
	      end
	      threadExportEntity)
	    
	    t(proc{$ Th I P}
		  {LFTW Th
		   proc{$ Ind  Ans}
		      Np 
		   in
		      thread 
			 {List.forAllInd {NewPort $ Np}
			  proc{$ In _}
			     if In == I then
				Ind = Ans
			     else
				{Send P old_port(Np)}
			     end
			  end}
		      end
		      {Send P old_port(Np)}
		   end}
	      end
	      threadReuseEntity)
	    

	    t(proc{$ Th I P}
		 {Wait {Loop.forThread 1 Th 1
			proc{$ Ind Id  Ans}
			   Np 
			in
			   thread 
			      {List.forAllInd {NewPort $ Np}
			       proc{$ In _}
				  if In == I then
				     Ind = Ans
				  else
				     {Send P send_port(Id)}
				  end
			       end}
			   end
			   {Send P register(Np Id)}
			   {Send P send_port(Id)}
			end unit}}
	      end
	      threadImportEntity)

	    t(proc{$ Th I P}
		 {Wait {Loop.forThread 1 Th 1
			proc{$ Ind Id  Ans}
			   Np 
			in
			   thread 
			      {List.forAllInd {NewPort $ Np}
			       proc{$ In _}
				  if In == I then
				     Ind = Ans
				  else
				     {Send P send(Id)}
				  end
			       end}
			   end
			   {Send P register(Np Id)}
			   {Send P send(Id)}
			end unit}}
	      end
	      threadNoEntity)
	    
	    

	    t(proc{$ Th I P}
		 {LFTW Th
		  proc{$ Ind Ans}
		     thread
			{For 1 I 1
			 proc{$ _}
			    {DS.sendcp Site.ip Site.port
			     Site.timestamp Site.pid 1}
			 end}
			Ind = Ans
		     end
		  end}
	      end
	      threadComPing)


	    t(proc{$ Th I P}
		 {LFTW Th
		  proc{$ Ind Ans}
		     thread
			{For 1 I 1
			 proc{$ _}
			    {DS.sendmpp Site.ip Site.port
			     Site.timestamp Site.pid 1}
			 end}
			Ind = Ans
		     end
		  end}
	      end
	      threadProtPing)
	    
	    t(proc{$ Th I P}
		 {LFTW Th
		  proc{$ Ind Ans}
		     thread
			{For 1 I 1
			 proc{$ _}
			    {DS.sendmpt Site.ip Site.port
			     Site.timestamp Site.pid 1 [a b c d e f g h i]}
			 end}
			Ind = Ans
		     end
		  end}
	      end
	      threadListPing)
	    

	    t(proc{$ Th I P}
		 {LFTW Th
		  proc{$ Ind  Ans}
		     thread
			{For 1 I 1
			 proc{$ _}
			    {DS.sendmpt Site.ip Site.port
			     Site.timestamp Site.pid 1 P}
			 end}
			Ind = Ans
		     end
		  end}
	      end
	      threadImportEntityPing)

	    t(proc{$ Th I _}
		 NP = {NewPort _}
	      in
		 {LFTW Th
		  proc{$ Ind  Ans}
		     thread
			{For 1 I 1
			 proc{$ _}
			    {DS.sendmpt Site.ip Site.port
			     Site.timestamp Site.pid 1 NP}
			 end}
			Ind = Ans
		     end
		  end}
	      end
	      threadExportEntityPing)

	    t(proc{$ Th I P}
		 Np
		 CC = {NewCell {NewPort $ Np}}
	      in
		 {Send P register(Np 1)}
		 {For 1 Th 1 proc{$ _} {Send P send(1)} end}
		 {For  (I-1)*Th 1 ~1
		  proc{$ Ind}
		     {Wait {Access CC}}
		     {Assign CC {Access CC}.2}
		     if Ind > Th then {Send P send(1)} end
		  end}
	      end
	      sequentialNoEntity)
	    
	    t(proc{$ Th I P}
		 {LFTW Th
		  proc{$ Ind Ans}
		     thread 
			{DS.sendcp Site.ip Site.port
			 Site.timestamp Site.pid I}
			Ind = Ans
		     end
		  end}
	      end
	      sequentialComPing)


	    t(proc{$ Th I P}
		 {LFTW Th
		  proc{$ Ind Ans}
		     thread 
			{DS.sendmpp Site.ip Site.port
			 Site.timestamp Site.pid I}
			Ind = Ans
		     end
		  end}
	      end
	      sequentialProtPing)

	    t(proc{$ Th I P}
		 {LFTW Th
		  proc{$ Ind Ans}
		     thread 
			{DS.sendmpt Site.ip Site.port
			 Site.timestamp Site.pid I [a b c d e f g h i]}
			Ind = Ans
		     end
		  end}
	      end
	      sequentialListPing)


	    t(proc{$ Th I P}
		 {LFTW Th
		  proc{$ Ind Ans}
		     thread 
			{DS.sendmpt Site.ip Site.port
			 Site.timestamp Site.pid I P}
			Ind = Ans
		     end
		  end}
	      end
	      sequentialImportPing)

	    t(proc{$ Th I _}
		 Np = {NewPort _}
	      in
		 {LFTW Th
		  proc{$ Ind Ans}
		     thread 
			{DS.sendmpt Site.ip Site.port
			 Site.timestamp Site.pid I Np}
			Ind = Ans
		     end
		  end}
	      end
	      sequentialExportPing)
	   ]
   Args 
   Help
   TestNames
   ArgsSpec

   DS = {{New Module.manager init} link(url:'x-oz://boot/DPMisc' $)}

   P
   Site
   
in
   TestNames = {Map Tests fun{$ R} R.2 end}

   ArgsSpec = record('ticket'(single type:string)
		     'iterations'(single type:int)
		     'jobs'(single type:list(int))
		     'linear'(single type:bool default:false)
		     'help'(   single   type:bool default:false)
		     'tests'(single type:list(atom) default:TestNames))
   
   
   try 
      Args={Application.getCmdArgs ArgsSpec}
      Args.ticket = _
      Args.iterations = _ 
      Help = false 
   catch _ then
      Help = true
   end
   
   if Args.help orelse Help then
      {System.showInfo '--ticket\n'#
       '\tThe file that contains the ticket saved from the server\n'#
       '--iterations\n'#
       '\tSets the number of messages\n'#
       '\n--jobs'#
       '\tThe degree of paralellism\n'#
       '\n--linear'#
       '\tIf set the all the parallel jobs will send iterations messages.\n'#
       '\tOtherwise, iteration messages will be evenly spread among the jobs,\n'#
       '\tresulting in fewer iterations per job when jobs increase\n' #
       '\n--tests'#
       '\tDefault value is all tests, if specified it must be one or more of\n'#
       '\tthe following:\n'#
       {FoldL TestNames fun{$ Ind V}Ind#'\t\t'#V#'\n' end " "}
      }
      {Application.exit 0}
   end


   P = {Connection.take {Pickle.load Args.ticket}}

   Site = {Filter {DPStatistics.siteStatistics} fun{$ S} S.state \= mine end}.1
   
   {Property.put 'print.depth' 100}
   {Property.put 'print.width' 100}
   {ForAll  Args.jobs
    proc{$ Th}
       {ForAll {Filter Tests fun{$ t(_ A)}  {List.member A Args.tests} end}
	proc{$ M}
	   I T0 M0 
	in
	   if Args.linear then
	      I = Args.iterations
	   else
	      I = Args.iterations div Th
	   end
	   
	   {Wait {Send P start($)}}{System.gcDo}
	   {Wait {Send P start($)}}{System.gcDo}
	   {Wait {Send P start($)}}{System.gcDo}
	   T0 = {Property.get 'time'}
	   M0 = {DPStatistics.messageCounter}
	   {M.1 Th I P}
	   {System.gcDo}
	   {Wait {Send P start($)}}
	   {System.show
	    {Record.adjoin {Record.adjoin
			    {Record.adjoin
			     {Record.zip {DPStatistics.messageCounter} M0 Number.'-'}
			     r(concurency: Th iterations:I)}
			    {Record.zip {Record.filter {Property.get time} IsInt} {Record.filter T0 IsInt} Number.'-'}}
	     M.2}
	   }
	end}
    end}
   {Send P kill}
   {Delay 100}
   {Application.exit 0}
end







