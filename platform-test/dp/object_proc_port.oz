/*
   This test sends a number of large data structures to remote managers and
   expects them to be returned.
   The goal is to test the suspendable marshaler.
   If the size is set large enough gc of continuations will happen and cause
   more problems than using just fragmented messages
*/

functor
import
   TestMisc
   System
export
   Return
define
   Sites=1

   proc {Start}
      Managers
      InP InS={NewPort $ InP}
      OutS % OutP={NewPort OutS}
   in
      try Hosts In in
	 {TestMisc.getHostNames Hosts}
	 {TestMisc.getRemoteManagers Sites Hosts Managers}
	 {ForAll Managers proc {$ RemMan}
			     {StartRemSite RemMan OutS InP}
			  end}
	 In=InS.1
	 {Wait In}
	 {In.proC ok}
	 {Delay 100}
	 {System.gcDo}
	 {Delay 100}
	 {In.proC In}
      catch X then
	 raise X end
      end
      {TestMisc.gcAll Managers}
      {TestMisc.listApply Managers close}
   end
   
   proc {StartRemSite Manager InS OutP}
      {Manager apply(url:'' functor
			    define
			       class Tester
				  feat
				     proC
				  meth init(MyP)
				     self.proC=proc{$ X}
						  {Send MyP X}
					       end
				  end
			       end

			       proc {Start InS OutP}
				  S MyP={NewPort S} in
				  {Send OutP {New Tester init(MyP)}}
				  {Wait S}
			       end
			       
			       thread {Start InS OutP} end
			    end)}
   end

   Return = dp([object_proc_port(Start keys:[remote])])
end



