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
   Connectionfunctor
define
   functor Connectionfunctor
   export
      Connect
   import
      ConnectionWrapper
\ifdef DBG
      System(show:Show showInfo showError)
      Property
\endif
   define
      RetryTimes=10
      RetryWaitTime=100

      proc {Parse P ?Address ?IPPort}
      % Get Address and Port to connect to out of P
         ip_addr(addr:Address port:IPPort)=P
      end

      proc{Connect P}
\ifdef DBG
         {Show connect(P)}
         T0 = {Property.get 'time.total'}
\endif
         FD
         Address IPPort
         Done
         proc{GetNegChannel Time}
            if Time>0 then
               try
                  FD={ConnectionWrapper.socket 'PF_INET' 'SOCK_STREAM' "tcp"}
                  if FD==~1 then raise no_fd end end
                  {ConnectionWrapper.connect FD Address IPPort}
               catch X then
                  case X of system(os(_ _ 111 _) ...) then
                     Done=failed
                     {ConnectionWrapper.close FD}
\ifdef DBG
                     {System.show discovered_perm(FD Address IPPort)}
\endif
                     {ConnectionWrapper.connFailed perm}
                  [] system(os(_ _ 115 _) ...) then
                     % only tells that the socket is in progress
                     skip
                  else
\ifdef DBG
                     {System.show caught(X)}
                     {System.show retrying}
\endif
                     % Delay for a while and retry
                     {Delay RetryWaitTime}
                     {GetNegChannel Time-1}
                  end
               end
            else
               Done=failed
               {ConnectionWrapper.connFailed temp}
            end
         end
      in
         {Parse P ?Address ?IPPort}
         {GetNegChannel RetryTimes}

         if {Not {IsDet Done}} then
         % Try tcp
            Grant = {ConnectionWrapper.getConnGrant tcp true}
            ReadS
         in
\ifdef DBG
            {System.show grant_response(Grant)}
\endif
            case Grant of grant(...) then
               try
\ifdef DBG
                  {System.show writeSelect}
\endif
                  {ConnectionWrapper.writeSelect FD}
\ifdef DBG
            {System.show write}
\endif
                  try
                     _={ConnectionWrapper.write FD "tcp"}
                  catch X then
                     case X of system(os(_ _ 32 _) ...) then
                        % This is EPIPE. It can be discussed wether this
                        % is perm or not, but in the old system, an EPIPE
                        % at this early stage was interpreted as such.
                        Done=failed
                        {ConnectionWrapper.close FD}
\ifdef DBG
                        {System.show discovered_perm_2(FD Address IPPort)}
\endif
                        {ConnectionWrapper.freeConnGrant Grant}
                        {ConnectionWrapper.connFailed perm}
                        raise perm end
                     end
                  end
\ifdef DBG
                  {System.show readSelect}
\endif

                  {ConnectionWrapper.readSelect FD}
                  _ = {ConnectionWrapper.read FD 2 ReadS nil}
                  case ReadS of "ok" then
                     {ConnectionWrapper.handover Grant settings(fd:FD)}
                     Done=connected
                  else
                     {ConnectionWrapper.freeConnGrant Grant}
                  end
               % If we catch an exception here (other than perm, se above)
               % it means the connection
               % was somehow corrupted. Report this as a temp error and let
               % the requestor try again.
               catch X then
\ifdef DBG
                  {System.show connect_caught(X)}
\endif
                  case X of perm then skip
                  else
                     Done=failed
                     {ConnectionWrapper.freeConnGrant Grant}
                     {ConnectionWrapper.connFailed temp}
                  end
               end
            else
               skip
            end
         end

         /*
         if {Not {IsDet Done}} then
         % Go ahead and try some other transport media
         end
         */

      % Either we have a connection or
      % we figured out that the remote site was perm or
      % we are out of ConnectionWrappersible transport medias
         if {Not {IsDet Done}} then
            try
               _={ConnectionWrapper.write FD "give_up"}
               {ConnectionWrapper.close FD}
            catch _ then skip end

            {ConnectionWrapper.connFailed 'No transport or not accepted'}
\ifdef DBG
         elseif Done==connected then
            {System.show connectDone({Property.get 'time.total'} -T0)}
\endif
         end
      end
   end
end
