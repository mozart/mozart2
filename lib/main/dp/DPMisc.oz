%%%
%%% Authors:
%%%   Andreas Sundstom (perbrand@sics.se)
%%%
%%% Copyright:
%%%   Andreas Sundstom, 1999
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


functor

import
   DPB at 'x-oz://boot/DPB'
   Misc at 'x-oz://boot/DPMisc'

export
   initIPConnection:  InitIP
   GetConnGrant
   FreeConnGrant
   Handover
   messageCounter:    MsgCntr
   GetConnectWstream
   SetListenPort
   ConnFailed
   CreateLogFile
define
   %%
   %% Force linking of base library
   %%
   {Wait DPB}



   InitIP = fun{$ R}
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
               {Misc.initIPConnection R}
            end
   MsgCntr = fun{$}{Misc.getMsgCntr}end
   GetConnGrant = Misc.getConnGrant
   FreeConnGrant = Misc.freeConnGrant
   Handover = Misc.handover
   GetConnectWstream = Misc.getConnectWstream
   SetListenPort = Misc.setListenPort
   ConnFailed = Misc.connFailed
   CreateLogFile = Misc.createLogFile
end
