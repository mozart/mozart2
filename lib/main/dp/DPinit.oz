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
   DPMisc
%   Pickle
%   Module
\ifdef DBG
   System
\endif
export
   Init
define
   {Wait DPB}
   ConnectState = {NewCell notStarted}
   proc{StartDP Settings}
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
   end

   proc{Init Settings} N in
      case {Exchange ConnectState $ N} of
         notStarted then
         {StartDP Settings}
         N =  started
      elseof started then
         if Settings == connection_settings then
            skip
         else
            thread
               raise 'Warning distribution already initialized - settings will have no effect' end
            end
         end
      end
   end
end
