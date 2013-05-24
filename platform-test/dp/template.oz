functor
import
   TestMisc
export
   Return
define
   Sites=1

   proc {Start}
      Managers
      InP InS={NewPort $ InP}
      OutS OutP={NewPort OutS}
   in
      try Hosts in
	 {TestMisc.getHostNames Hosts}
	 {TestMisc.getRemoteManagers Sites Hosts Managers}
	 {ForAll Managers proc {$ RemMan}
			     {StartRemSite RemMan OutS InP}
			  end}
	 % Local test runner
      catch X then
	 raise X end
      end
      {TestMisc.gcAll Managers}
      {TestMisc.listApply Managers close}
   end
   
   proc {StartRemSite Manager InS OutP}
      {Manager apply(url:'' functor
			    define
			       proc {Start InS OutP}
				  % Remote test runner
			       end
			       
			       thread {Start InS OutP} end
			    end)}
   end

   Return = dp([<name>(Start keys:[remote])])
end



