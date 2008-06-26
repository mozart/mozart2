%%%
%%% Authors:
%%%   Andreas Sundstroem (andreas@sics.se)
%%%
%%% Copyright:
%%%   Andreas Sundstroem (andreas@sics.se)
%%%
%%% Last change:
%%%   $Date$Author:
%%%   $Revision:
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
import
   TestMisc
   DP
export
   Return
define
   Threads = 30
   Times = 50
   Sites = 3

   fun {Start EntityProtocol}
      proc {$} Managers in
         try
            local
               proc {Loop Ms Ctr Lock Ps}
                  case Ms
                  of M|Mr then Pr in
                     Ps = proc {$} {StartSite M Ctr Lock} end | Pr
                     {Loop Mr Ctr Lock Pr}
                  [] nil then
                     Ps = nil
                  end
               end
               Ctr = {NewCell 0}
               Lock = {NewLock}
               {DP.annotate Lock EntityProtocol}
               Old Hosts Procs
            in
               {TestMisc.getHostNames Hosts}
               {TestMisc.getRemoteManagers Sites Hosts Managers}
               {Loop Managers Ctr Lock Procs}
               {TestMisc.barrierSync Procs}
               {Exchange Ctr Old done}
               if Old \= Threads * Times * Sites then
                  raise dp_cellAndLock_test_failed end
               else skip end
            end
         catch X then
            {TestMisc.gcAll Managers}
            raise X end
         end
         {TestMisc.gcAll Managers}
         {TestMisc.listApply Managers close}
      end
   end

   proc {StartSite RMan Ctr Lock} Error in
      {RMan apply(url:'' functor
                         import
                            Property(put)
                         define
                            {Property.put 'close.time' 1000}

                            proc {StartThreads Ctr Lock}
                               List = {MakeList Threads}
                            in
                               {For 1 Threads 1
                                proc {$ I}
                                   {Nth List I
                                    proc {$}
                                       {CtrUpDater Ctr Times 0 Lock}
                                    end}
                                end}
                               {BarrierSync List}
                            end

                            proc {BarrierSync Ps}
                               proc {Conc Ps L}
                                  case Ps of P|Pr then X Ls in
                                     L = X|Ls
                                     thread {P} X=unit end
                                     {Conc Pr Ls}
                                  else
                                     L = nil
                                  end
                               end
                               L
                            in
                               {Conc Ps L}
                               {List.forAll L proc {$ X} {Wait X} end}
                            end

                            proc {CtrUpDater Ctr TimesLeft LastSeenNr Lock}
                               Old New in
                               if TimesLeft == 0 then
                                  skip
                               else
                                  lock Lock then
                                     {Exchange Ctr Old New}
                                     New = Old+1
                                  end
                                  if LastSeenNr > New then
                                     raise dp_cellAndLock_test_failed end
                                  else skip end
                                  {CtrUpDater Ctr TimesLeft-1 New Lock}
                               end
                            end

                            proc {Start Ctr Lock Error}
                               MemCell = {NewCell ok} in
                               try
                                  {StartThreads Ctr Lock}
                               catch X then
                                  {Assign MemCell X}
                               end
                               Error = {Access MemCell}
                            end

                            {Start Ctr Lock Error}
                         end)}
      {TestMisc.raiseError Error}
   end

   Return = dp([cell(['lock'({Map [stationary migratory pilgrim replicated]
                              fun {$ Prot}
                                 Prot({Start Prot} keys:[remote Prot])
                              end})])])
end
