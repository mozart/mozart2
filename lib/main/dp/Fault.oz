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
         TT Res in
         if T == install then   TT = Install0
         else TT = DeInstall0 end
         Res={TT safeInjector('cond':[permBlocked]
                      'thread':this
                      entityType:single
                          entity:E)  P}
         if Res==false then
            raise distribution('connection') end
         end
      end

      proc{SiteWH T E P}
         TT Res in
         if T == install then   TT = Install0
         else TT = DeInstall0 end
         Res={TT siteWatcher('cond':[permWillBlock]
                             entity:E) P}
         if Res==false then
            raise distribution('connection') end
         end
      end

      proc{IsUnsafe Cond Out}
        if {Record.is Cond} then
           if {Record.hasLabel Cond}==injector then
              Out=true
           else
              Out=false
           end
        else
           Out=false
        end
      end

      fun{Install0 Cond Proc}
        if{IsUnsafe Cond} then
            {Fault.distHandlerInstall Cond Proc}
        else
            {InterFault.interDistHandlerInstall Cond Proc}
        end
      end

      fun{DeInstall0 Cond Proc}
        if{IsUnsafe Cond} then
            {Fault.distHandlerDeInstall Cond Proc}
        else
            {InterFault.interDistHandlerDeInstall Cond Proc}
        end
      end

   in
      {Wait DPB}

      GetEntityCond  = Fault.getEntityCond
      Install        = Install0
      Deinstall      = DeInstall0

      EInstall      = fun{$ Cond}
                         {Install0 Cond ExceptionHandler}
                      end

      EDeinstall    = fun{$ Cond}
                         {DeInstall0 Cond ExceptionHandler}
                      end

      Injector      = proc{$ E P} {InjectorH install E P} end
      RmInjector    = proc{$ E P} {InjectorH denstall E P} end

      SiteWatcher   = proc{$ E P} {SiteWH install E P} end
      RmSiteWatcher = proc{$ E P} {SiteWH deinstall E P} end

   end
end
