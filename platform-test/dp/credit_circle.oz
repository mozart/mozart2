% What it does:
%
% A manager creates a circle of workers knowing the port of its neighbour.
% The manager then creates a cell and sends it out in the circle. This cell
% then circulates a number of rounds.
%
% Why:
%
% If the circle is big enough this should cause secondary credits to be
% created and used.

\define DBG
functor
import
   TestMisc
\ifdef DBG
   System
\endif
   OS(getPID:GetPID)
export
   Return
define
   Sites=15
   Rounds=3
   Dones={MakeList Sites}
   Ports={MakeList Sites}

\ifdef DBG
   PrintPort
   thread {ForAll {NewPort $ PrintPort} System.show} end
   proc {Show X}
      {Send PrintPort X}
   end
\else
   proc {Show _} skip end
\endif

   proc {Start}
      Managers
      InP InS={NewPort $ InP}
   in
      try Hosts C={NewCell 0} in
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
   end

   proc {StartRemSite Manager ManP Done I}
      {Manager apply(url:'' functor
                            import
                               OS(getPID:GetPID)
                            define
                               RP
                               proc {Run S Rounds}
                                  {Show running(I Rounds {GetPID})}
                                  if Rounds > 0 then
                                     if {Not {IsCell S.1}} then
                                        raise no_cell(S.1) end
                                     end
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
