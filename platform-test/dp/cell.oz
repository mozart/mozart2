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
      proc {$}
	 Managers in
	 try
	    local
	       proc {Loop Ms I Ss Cell Ps}
		  case Ms
		  of M|Mr then S Sr Pr in
		     Ss = S|Sr
		     Ps = proc {$} {StartSite M Cell I S} end | Pr
		     {Loop Mr I+1 Sr Cell Pr}
		  [] nil then
		     Ss = Ps = nil
		  end
	       end
	       Cell = {NewCell initial}
	       {DP.annotate Cell EntityProtocol}
	       Stats Hosts Procs
	    in
	       {TestMisc.getHostNames Hosts}
	       {TestMisc.getRemoteManagers Sites Hosts Managers}
	       {Loop Managers 1 Stats Cell Procs}
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
			      if Sum \= Times then
				 raise dp_cell_test_failed end
			      else
				 skip
			      end
			   end}
   end

   proc {StartSite Manager Cell SiteNr Statistics} Error in
      {Manager apply(url:'' functor
			    import
			       Property(put)
			    define
			       {Property.put 'close.time' 1000}

			       fun {MakeKey I J}
				  {StringToAtom
				   {VirtualString.toString I#x#J}}
			       end
			       
			       proc {StartThreads Cell SiteNr Statistics}
				  List = {MakeList Threads}
				  Dict = {NewDictionary}
				  Lock = {NewLock}
				  Old 
			       in
				  {For 1 Threads 1
				   proc {$ I}
				      {Nth List I
				       proc {$}
					  {CellUpDater Cell 1 SiteNr
					   I Dict Lock}
				       end}
				   end}
				  {BarrierSync List}
				  Statistics = {MakeList Threads*Sites}
				  {Exchange Cell Old done}
				  if Old \= done then
				     {UpdateDict Old Dict Lock}
				  else skip end
				  {Loop.multiFor [1#Sites#1 1#Threads#1]
				   proc {$ [I J]} Elem in
				      {Dictionary.condGet Dict
				       {MakeKey I J} 0 Elem}
				      {Nth Statistics (I-1)*Threads+J Elem}
				   end}
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
			       
			       proc {UpdateDict X Dict Lock} Old in
				  case X
				  of initial then
				     skip
				  [] done then
				     skip
				  [] SiteNr#ThreadNr then
				     lock Lock then
					{Dictionary.condGet Dict
					 {MakeKey SiteNr ThreadNr} 0 Old}
					{Dictionary.put Dict
					 {MakeKey SiteNr ThreadNr} Old+1}
				     end
				  end
			       end
			       
			       proc {CellUpDater Cell Nr SiteNr
				     ThreadNr Dict Lock} Old in
				  {Exchange Cell Old SiteNr#ThreadNr}
				  {Wait Old}
				  {UpdateDict Old Dict Lock}
				  if Nr == Times then
				     skip
				  else
				     {CellUpDater Cell Nr+1 SiteNr
				      ThreadNr Dict Lock}
				  end
			       end

			       proc {Start Cell SiteNr Statistics Error} 
				  MemCell = {NewCell ok} in
				  try
				     {StartThreads Cell SiteNr Statistics}
				  catch X then
				     {Assign MemCell X} 
				  end
				  Error = {Access MemCell}
			       end
			       
			       {Start Cell SiteNr Statistics Error}
			    end)}
      {TestMisc.raiseError Error}
   end

   Return = dp([cell({Map [stationary migratory pilgrim replicated]
		      fun {$ Prot}
			 Prot({Start Prot} keys:[remote Prot])
		      end})])
end
