functor
import
   TestMisc
export
   Return
define
   Threads = 30
   Times = 50
   Sites = 3
   Lock = {NewLock}

   class MsgHandler
      attr msg:initial

      feat makeKey: fun {$ I J}
                       {StringToAtom
                        {VirtualString.toString I#x#J}}
                    end

      meth init skip end

      meth updateDict(X Dict Lock) Old in
         case X
         of initial then
            skip
         [] done then
            skip
         [] SiteNr#ThreadNr then
            lock Lock then
               {Dictionary.condGet Dict
                {self.makeKey SiteNr ThreadNr} 0 Old}
               {Dictionary.put Dict
                {self.makeKey SiteNr ThreadNr} Old+1}
            end
         end
      end

      meth updater(Nr SiteNr ThreadNr Dict Lock) Old in
         lock Lock then
            Old = @msg
            msg <- SiteNr#ThreadNr
         end
         MsgHandler, updateDict(Old Dict Lock)
         case Nr == Times then
            skip
         else
            MsgHandler, updater(Nr+1 SiteNr ThreadNr Dict Lock)
         end
      end

      meth computeStatistics(Statistics Dict Lock) Old in
         Statistics = {MakeList Threads*Sites}
         Old = @msg
         msg <- done
         if Old \= done then
            MsgHandler, updateDict(Old Dict Lock)
         else skip end
         {Loop.multiFor [1#Sites#1 1#Threads#1]
          proc {$ [I J]} Elem in
             {Dictionary.condGet Dict
              {self.makeKey I J} 0 Elem}
             {Nth Statistics (I-1)*Threads+J Elem}
          end}
      end
   end

   proc {Start} Managers in
      try
         local
            proc {Loop Ms I Ss Object Ps}
               case Ms
               of M|Mr then S Sr Pr in
                  Ss = S|Sr
                  Ps = proc {$} {StartSite M Object I S} end | Pr
                  {Loop Mr I+1 Sr Object Pr}
               [] nil then
                  Ss = Ps = nil
               end
            end
            Object = {New MsgHandler init}
            Stats Hosts Procs
         in
            {TestMisc.getHostNames Hosts}
            {TestMisc.getRemoteManagers Sites Hosts Managers}
            {Loop Managers 1 Stats Object Procs}
            {TestMisc.barrierSync Procs}
            {CheckStatistics Stats}
         end
      catch X then
         {TestMisc.gcAll Managers}
         raise X end
      end
      {TestMisc.gcAll Managers}
      {TestMisc.listApply Managers close}
   end

   proc {CheckStatistics Lists}
      proc {SumListsHelper Xs Sum Rs}
         case Xs
         of X|Xr then
            F R Rr in
            Rs = R|Rr
            F|R = X
            Sum = {SumListsHelper Xr $ Rr}+F
         [] nil then
            Sum = 0
            Rs = nil
         end
      end

      proc {SumLists All Ys} Rest in
         case All of  nil|_ then
            Ys = nil
         else
            Y Yr in
            Ys = Y|Yr
            {SumListsHelper All Y Rest}
            {SumLists Rest Yr}
         end
      end

      SumList
   in
      {SumLists Lists SumList}
      {List.forAll SumList proc {$ Sum}
                         case Sum \= Times then
                            raise dp_object_test_failed end
                         else
                            skip
                         end
                      end}
   end

   proc {StartSite RMan Object SiteNr Statistics} Error in
      {RMan apply(url:'' functor
                         define
                            proc {StartThreads Object SiteNr Statistics}
                               List = {MakeList Threads}
                               Dict = {NewDictionary}
                            in
                               {For 1 Threads 1
                                proc {$ I}
                                   {Nth List I
                                    proc {$}
                                       {Object updater(1 SiteNr I Dict Lock)}
                                    end}
                                end}
                               {BarrierSync List}
                               {Object computeStatistics(Statistics
                                                         Dict Lock)}
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

                            proc {Start Object SiteNr Statistics Error}
                               MemCell = {NewCell ok} in
                               try
                                  {StartThreads Object SiteNr Statistics}
                               catch X then
                                  {Assign MemCell X}
                               end
                               Error = {Access MemCell}
                            end

                            {Start Object SiteNr Statistics Error}
                         end)}
      {TestMisc.raiseError Error}
   end

   Return = dp([object(Start keys:[remote])])
end
