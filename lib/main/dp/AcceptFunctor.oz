%%%
%%% Authors:
%%%   Erik Klintskog (erik@sics.se)
%%%   Anna Neiderud (annan@sics.se)
%%%
%%% Copyright:
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
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

%\define DBG
functor
export
   Accept
import
   OS
\ifdef DBG
   System
\endif
   DPMisc at 'x-oz://boot/DPMisc'
define
   class ResourceHandler
      prop
         locking
      attr
         r
         q
      meth init(I)
         r<-I
         q<-nil
      end
      meth getResource
         skip/*
         lock W in
            if @r>0 then
               r<-@r-1
               W=unit
            else
               q<-{Append @q [W]}
            end
            {Wait W}
         end*/
      end
      meth returnResource
         skip/*
         lock
            if @q==nil then
               r<-@r+1
            else
               Q1|QR=@q
            in
               @r=0 % Check
               q<-QR
               Q1=unit
            end
         end*/
      end
   end

   MaxRead = 1000

   FDHandler = {New ResourceHandler init(5)}
   fun{BindSocket FD PortNum}
      try
\ifdef DBG
         {System.showInfo 'BindSocket '#FD#' '#PortNum}
\endif
         {OS.bind FD PortNum}
         PortNum
      catch _ then
         {BindSocket FD PortNum + 1}
      end
   end

   proc{AcceptSelect FD}
      NewFD in
      try
\ifdef DBG
         {System.showInfo 'AcceptedSelect on '#FD#' '#{OS.getPID}}
\endif
         {FDHandler getResource}
\ifdef DBG
         {System.showInfo 'Got resource'#' '#{OS.getPID}}
\endif
         {OS.acceptSelect FD}
\ifdef DBG
         {System.showInfo 'After acceptSelect '#FD#' '#{OS.getPID}}
\endif
         {OS.acceptNonblocking_noDnsLookup FD _ _ NewFD} %InAddress InIPPort NewFD}
\ifdef DBG
         {System.showInfo 'Accepted channel (old '#FD#' new '#NewFD#')'#' '#{OS.getPID}}
\endif
         thread
            {AcceptProc NewFD}
            {FDHandler returnResource}
         end
\ifdef DBG
      % If there is an exception here we can't do much but return the
      % resources and close the socket. The most likely exception is
      % a EPIPE on the new FD.
      catch X then
         {System.show exception_AcceptSelect(X {OS.getPID})}
\else
      catch _ then
         skip
\endif
         {FDHandler returnResource}
         try {OS.close NewFD} catch _ then skip end
      end
      {AcceptSelect FD}
   end

   proc{Accept ListenPortNum}
%      InAddress InIPPort
      FD
      CPortNum
   in
      /* Create socket */
      FD={OS.socket 'PF_INET' 'SOCK_STREAM' "tcp"}
      if ListenPortNum==default then
         CPortNum = {BindSocket FD 9000}
      else
         try
            {OS.bind FD ListenPortNum}
            CPortNum=ListenPortNum
         catch _ then raise unable_to_listen_to(ListenPortNum) end end
      end
\ifdef DBG
      {System.showInfo 'Bound '#CPortNum}
\endif
      {OS.listen FD 5}
      {DPMisc.setListenPort CPortNum {OS.uName}.nodename}
\ifdef DBG
      {System.showInfo 'Listening on port '#CPortNum#' using fd '#FD#' '#{OS.getPID}}
\endif
      thread
         {AcceptSelect FD}
\ifdef DBG
         % This should never be reached
         {System.show accept_loop_finished}
         raise accept_loop_finished end
\endif
      end
   end

   proc{AcceptProc FD}
      Read InString
   in
      try
         {OS.readSelect FD}
         {OS.read FD MaxRead ?InString nil ?Read}

         if Read>0 then
            case InString of "tcp" then
               Grant = {DPMisc.getConnGrant accept tcp false}
            in
               case Grant of grant(...) then
\ifdef DBG
                  {System.showInfo accepted#' '#{OS.getPID}}
\endif
                  _={OS.write FD "ok"}
                  {DPMisc.handover accept Grant settings(fd:FD)}
               else % could be busy or no tcp, wait for anoter try
\ifdef DBG
                  {System.showInfo busy#' '#{OS.getPID}}
\endif
                  _={OS.write FD "no"}
%                 {AcceptProc FD} What?
               end
            [] "give_up" then
               {OS.close FD}
            else
               {OS.close FD}
            end
         else
            % AN! can this happen or will there allways be an exception?
            {OS.close FD}
         end
      catch X then
\ifdef DBG
         {System.show acceptProc_caught(X {OS.getPID})}
\endif
         case X of system(os(_ _ _ "Try again") ...) then % EAGAIN => try again
            {AcceptProc FD}
         else % Other fault conditions AN! should some others be treated?
\ifdef DBG
            {System.show acceptProc_caught}
            {System.printError X}
\endif
            try {OS.close FD} catch _ then skip end
         end
      end
   end
end
