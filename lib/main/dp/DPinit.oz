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
   proc{StartDP}
      AccMod = AcceptFunctor
      AccFunc = functor $ export Init define proc{Init} skip end end
      ConnFunc = ConnectionFunctor.connectionfunctor
   in
\ifdef DBG
      {System.show {DPMisc.initIPConnection r(acceptProc:AccFunc
                                              connectProc:ConnFunc)}}
\else
      _={DPMisc.initIPConnection r(acceptProc:AccFunc
                                   connectProc:ConnFunc)}
\endif
\ifdef DBG
      try
         {AccMod.accept}
      catch X then {System.show accept_ex(X)}end
\else
      {AccMod.accept}
\endif
      thread
         {ConnectAcceptModule.initConnection {DPMisc.getConnectWstream}}
      end
   end

   proc{Init} N in
      case {Exchange ConnectState $ N} of
         notStarted then
         {StartDP}
         N =  started
      elseof started then skip end
   end
end
