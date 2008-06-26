%%%
%%% Authors:
%%%   Per Brand (perbrand@sics.se)
%%%   Erik Klintskog (erik@sics.se)
%%%
%%% Contributor:
%%%   Raphael Collet (raphael.collet@uclouvain.be)
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
   System(showError: ShowError)
   DP

export
   getEntityCond:     GetEntityCond
   enable:            Enable
   disable:           Disable
   install:           Install
   deInstall:         DeInstall
   installWatcher:    InstallWatcher
   deInstallWatcher:  DeInstallWatcher
   defaultEnable:     DefaultEnable
   defaultDisable:    DefaultDisable

define
   proc {Defunct S}
      {ShowError '*** Warning: '#S#' disabled; check new module DP ***'}
   end

   proc {GetEntityCond _ _}
      {Defunct 'Fault.getEntityCond'}
   end

   fun {Enable _ _ _}
      {Defunct 'Fault.enable'} true
   end
   fun {Disable _ _}
      {Defunct 'Fault.disable'} true
   end

   fun {Install _ _ _ _}
      {Defunct 'Fault.install'} true
   end
   fun {DeInstall _ _}
      {Defunct 'Fault.deInstall'} true
   end

   fun {InstallWatcher Entity FStates WatcherProc}
      if {List.all FStates
          fun {$ S} {Member S [tempFail permFail]} end}
      then
         proc {Loop FS}
            case FS of F|Fr then
               if {Member F FStates} then
                  thread {WatcherProc Entity F(info:state)} end
               else
                  {Loop Fr}
               end
            else skip end
         end
      in
         {DP.getFaultStream Entity thread {Loop} end}
         true
      else
         false
      end
   end
   fun {DeInstallWatcher _ _ _}
      {Defunct 'Fault.deInstallWatcher'} true
   end

   fun {DefaultEnable _}
      {Defunct 'Fault.defaultEnable'} true
   end
   fun {DefaultDisable}
      {Defunct 'Fault.defaultDisable'} true
   end
end
