%%%
%%% Authors:
%%%   Erik Klintskog (erik@sics.se)
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
import
   DPB     at 'x-oz://boot/DPB'
   ConnectAcceptModule
   ConnectionFunctor
   AcceptFunctor
   DPMisc at 'x-oz://boot/DPMisc'
   DPStatistics
\ifdef DBG
   System
\endif
export
   Init
   GetSettings
define
   {Wait DPB}
   ConnectState = {NewCell notStarted}

   proc{CheckSettings R}
      if {Value.hasFeature R ip} then
         try
            {List.foldL {String.tokens R.ip &.}
             fun{$ Acc In}
                I = {String.toInt In} in
                if I>256 orelse I<0 then raise toLarge end end
                Acc - 1
             end
             4 0}
         catch _ then
            raise badFormatedIpNo(R.ip) end
         end
      end
   end

   fun{StartDP Settings}
      %% Here an AccMod is needed to start distribution.
      %% For c level a connection functor is also needed and has to be
      %% added to settings if not specified.
      AccMod = {CondSelect Settings acceptProc AcceptFunctor}
      IntSettings = if {HasFeature Settings connectProc} then
                       Settings
                    else
                       {AdjoinAt Settings connectProc
                        ConnectionFunctor.connectionfunctor}
                    end
   in
      {CheckSettings IntSettings}
\ifdef DBG
      {System.show {DPMisc.initIPConnection IntSettings}}
\else
      _={DPMisc.initIPConnection IntSettings}
\endif
\ifdef DBG
      try
         {AccMod.accept {CondSelect Settings port default}}
      catch X then {System.show accept_ex(X)}end
\else
      {AccMod.accept {CondSelect Settings port default}}
\endif
      thread
         {ConnectAcceptModule.initConnection {DPMisc.getConnectWstream}}
      end
      Settings
   end

   fun{Init Settings} O N in
      {Exchange ConnectState O N}
      case O of
         notStarted then
         N={StartDP Settings}
         true
      else
         N=O
         false
      end
   end

   fun{GetSettings}
      S={Access ConnectState}
   in
      case S of notStarted then
         S
      else
         MySite={Filter {DPStatistics.siteStatistics}
                 fun{$ X} X.state==mine end}.1
      in
         init(ip:MySite.ip
              port:MySite.port
              firewall:{CondSelect S firewall false}
              address:MySite.addr
              connectProc:{CondSelect S connectProc default}
              acceptProc:{CondSelect S acceptProc default})
      end
   end
end
