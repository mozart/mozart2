%%%
%%% Authors:
%%%   Per Brand (perbrand@sics.se)
%%%
%%% Copyright:
%%%   Per Brand, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

import
   DPB
   at 'x-oz://boot/DPB'
   Fault(installHW
         deInstallHW
         getEntityCond)
   at 'x-oz://boot/Fault'

export
   install:           Install
   deinstall:         Deinstall
   getEntityCond:     GetEntityCond

define
   local
      proc{DecodeConds Cond Rec}
         case Cond of
            handler('cond':perm) then
            Rec = handler(
                     'cond':      [permBlocked]
                     once_only:   yes
                     retry:       no
                     basis:       perSite
                     )
         elseof
            seifHandler then
            Rec = handler(
                     'cond':      [permBlocked permTerm]
                     once_only:   no
                     retry:       no
                     basis:       perSite
                     )
         elseof permHandler then
            Rec = handler(
                     'cond':      [permBlocked]
                     once_only:   yes
                     retry:       no
                     basis:       perSite
                     )
         elseof watcher('cond':permHome) then
            Rec = watcher(
                     'cond':      [permHome]
                     once_only:   yes
                     retry:       no
                     basis:       perSite
                     )
         elseof permWatcher  then
            Rec = watcher(
                     'cond':      [permHome]
                     once_only:   yes
                     retry:       no
                     basis:       perSite
                     )

         else raise unknownHandlerSpec(Cond) end
         end
      end
      %%
      %% Force linking of base library
      %%
   in
      {Wait DPB}

      Install       = proc{$ Entity Cond Proc}
                         Rec = {DecodeConds Cond}
                      in
                         if {IsLock Entity} orelse
                            {IsCell Entity} orelse
                            {IsPort Entity} orelse
                            Entity == seif
                         then
                            {Fault.installHW Entity Rec Proc}
                         else skip end
                      end

      Deinstall     = proc{$ Entity Cond Proc}
                         Rec = {DecodeConds Cond}
                      in
                         {Fault.deInstallHW Entity Rec Proc}
                      end
      GetEntityCond = Fault.getEntityCond
   end
end
