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
   OS(uName)
   Remote(manager)
   System(gcDo show)
   Property(get)
export
   getHostNames:GetHostNames
   localHost:LocalHost
   getRemoteManagers:GetRemoteManagers
   gcAll:GCAll
   listApply:ListApply
   barrierSync:BarrierSync
   raiseError:RaiseError
   watcher:Watcher
   deinstallWatchers:DeinstallWatchers
   win32: Win32
define
   Win32 = ({Property.get 'platform.os'} == win32)
   LocalHost = if Win32 then localhost else {OS.uName}.nodename end

   fun {GetHostNames}
      [localhost LocalHost]
   end

   proc {GetRemoteManagers Number Hosts Managers}
      proc {Loop Number Hosts Hs Ms}
	 if Number == 0 then
	    Ms = nil
	 else Mr H Hr1 Hr2 in
	    Hs = H|Hr1
	    try
	       Ms = {New Remote.manager init(host:H)}|Mr
	    catch X then
	       {System.show remote(X)}
	       raise X end
	    end
	    if Hr1 == nil then
	       Hr2 = Hosts
	    else
	       Hr2 = Hr1
	    end
	    {Loop Number-1 Hosts Hr2 Mr}
	 end
      end
   in
      {Loop Number Hosts Hosts Managers}
   end

   proc {GCAll Managers}
      {System.gcDo}
      {ListApply Managers apply(url:'' functor
						  import System(gcDo)
						  define
						     {System.gcDo}
						  end)}
      {System.gcDo}
      {ListApply Managers apply(url:'' functor
						  import System(gcDo)
						  define
						     {System.gcDo}
						  end)}
      {System.gcDo}
   end
   
   proc {ListApply Xs Application}
      case Xs
      of X|Xr then
	 {X Application}
	 {ListApply Xr Application}
      [] nil then
	 skip
      end
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

   proc {RaiseError Error}
      if Error \= ok then
	 raise Error end
      else
	 skip
      end
   end

   proc {Watcher _ _}
      raise site_down end
   end
   
   proc {DeinstallWatchers Ws}
      case Ws
%     of W|Wr then
%	 {Fault.deinstall W watcher('cond':permHome) Watcher}
      of _|Wr then
	 {DeinstallWatchers Wr}
      [] nil then skip
      end
   end

end
