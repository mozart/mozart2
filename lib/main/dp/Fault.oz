%%%
%%% Authors:
%%%   Per Brand (perbrand@sics.se)
%%%   Erik Klintskog (erik@sics.se)
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
   Fault(getEntityCond
         distHandlerInstall
         distHandlerDeInstall)
   at 'x-oz://boot/Fault'

export
   install:           Install
   deinstall:         Deinstall
   getEntityCond:     GetEntityCond
   eInstall:          EInstall
   eDeinstall:        EDeinstall


   injector:          Injector
   removeInjector:    RmInjector

   siteWatcher:       SiteWatcher
   removeSiteWatcher: RmSiteWatcher
define
   local
      proc{ExceptionHandler Entity Cond}
         {Exception.raiseError distribution(entity:Entity condition:Cond)}
      end

      proc{InjectorH T  E P}
         TT in
         if T == install then   TT = Fault.distHandlerInstall
         else TT = Fault.distHandlerDeInstall end
         {TT injector('cond':[permBlocked]
                      'thread':this
                      entityType:single
                      entity:E)  P}
      end

      proc{SiteWH T E P}
         TT in
         if T == install then   TT = Fault.distHandlerInstall
         else TT = Fault.distHandlerDeInstall end
         {TT siteWatcher('cond':[permWillBlock]
                         entity:E) P}
      end

   in
      {Wait DPB}

      GetEntityCond  = Fault.getEntityCond
      Install        = Fault.distHandlerInstall
      Deinstall      = Fault.distHandlerDeInstall

      EInstall      = proc{$ Cond}
                         {Fault.distHandlerInstall Cond ExceptionHandler}

                      end

      EDeinstall    = proc{$ Cond}
                         {Fault.distHandlerDeInstall Cond ExceptionHandler}
                      end

      Injector      = proc{$ E P} {InjectorH install E P} end
      RmInjector    = proc{$ E P} {InjectorH denstall E P} end

      SiteWatcher   = proc{$ E P} {SiteWH install E P} end
      RmSiteWatcher = proc{$ E P} {SiteWH deinstall E P} end

   end
end
