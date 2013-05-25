% What it does:
%
% A manager creates a circle of workers knowing the port of its neighbour.
% The manager then creates a cell#variable#port#lock#object and sends it out
% in the circle. This structure then circulates a number of rounds.
%
% Why:
%
% If the circle is big enough this should cause secondary credits to be
% created and used.

%\define DBG
functor
import
   TestMisc
\ifdef DBG
   System
\endif
   OS(getPID:GetPID)
   Property
export
   Return
define
   Sites=15
   Rounds=3
\ifdef DBG
   PrintPort
   thread {ForAll {NewPort $ PrintPort} System.show} end
   proc {Show X}
      {Send PrintPort X}
   end
\else
   proc {Show _} skip end
\endif

   class Obj
      meth init skip end
   end

   class TcpPropMonitor
      prop locking
      attr n:0 hard weak
      meth init skip end
      meth enter
	 lock
	    if @n==0 then
	       hard <- {Property.get 'dp.tcpHardLimit'}
	       weak <- {Property.get 'dp.tcpWeakLimit'}
	       {Property.put 'dp.tcpHardLimit' 100}
	       {Property.put 'dp.tcpWeakLimit' 99}
	    end
	    n <- @n+1
	 end
      end
      meth leave
	 lock
	    if @n==1 then
	       {Property.put 'dp.tcpHardLimit' @hard}
	       {Property.put 'dp.tcpWeakLimit' @weak}
	    end
	    n <- @n-1
	 end
      end
   end

   Monitor = {New TcpPropMonitor init}
   
   proc {Start}
      Dones={MakeList Sites}
      Ports={MakeList Sites}
      Managers
      InP InS={NewPort $ InP}
   in
      try
	 {Monitor enter}
	 try Hosts C={NewCell 0}#_#{NewPort _}#{NewLock}#{New Obj init} in
	    {Show manager({GetPID})}
	    {TestMisc.getHostNames Hosts}
	    {TestMisc.getRemoteManagers Sites Hosts Managers}
	    {List.forAllInd Managers proc {$ I RemMan}
					{StartRemSite RemMan InP {Nth Dones I} I}
				     end}
	    {List.forAllInd Ports proc {$ I P} P={Nth InS I} end}
	    {List.forAllInd Ports proc {$ I P} RP Ack in
				     RP={Nth Ports (I mod Sites)+1}
				     {Send P RP#Ack}
				     {Wait Ack}
				  end}
	    {Send Ports.1 C}
	    {ForAll Dones Wait}
	 catch X then
	    raise X end
	 end
	 {Show bef_gcAll}
	 {TestMisc.gcAll Managers}
	 {Show aft_gcAll}
	 {TestMisc.listApply Managers close}
	 {Show aft_close}
      finally {Monitor leave} end
   end

   proc {StartRemSite Manager ManP Done I}
      {Manager apply(url:'' functor
			    import
			       OS(getPID:GetPID)
			    define
			       proc {Check C#V#P#L#O}
				  if {Not {IsCell C}} then
				     raise no_cell(C) end
				  elseif {Not {IsFree V}} then
				     raise no_var(V) end
				  elseif {Not {IsPort P}} then
				     raise no_port(P) end
				  elseif {Not {IsLock L}} then
				     raise no_lock(L) end
				  elseif {Not {IsObject O}} then
				     raise no_object(O) end
				  end
			       end
			       
			       RP
			       proc {Run S Rounds}
				  {Show running(I Rounds {GetPID})}
				  if Rounds > 0 then
				     {Check S.1}
				     {Send RP S.1}
				     {Run S.2 Rounds-1}
				  else
				     Done=unit
				  end
			       end
			       S P={NewPort S}
			    in
			       {Send ManP P}
			       thread Ack in
				  RP#Ack=S.1
				  Ack=unit
				  {Run S.2 Rounds}
				  {Show done(I {GetPID})}
			       end
			    end)}
   end

   Return = dp([credit_circle(Start keys:[remote])])
end



