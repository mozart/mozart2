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
   Fault at 'x-oz://boot/Fault'

require
   InterFault at 'x-oz://boot/InterFault'

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
   local
      proc{WrongFormat}
         {Exception.raiseError
          type(dp('incorrect fault format'))}
      end

      proc{NotImplemented}
         {Exception.raiseError
          dp('not implemented')}
      end

      proc{Except Entity Cond Op}
         {Exception.raiseError
          system(dp(entity:Entity conditions:Cond op:Op))}
      end

      fun{DConvertToInj Cond}
         injector(entityType:all 'thread':all 'cond':Cond)
      end

      fun{SConvertToInj Entity Cond}
         injector(entityType:single entity:Entity 'thread':all 'cond':Cond)
      end

      fun{TConvertToInj Entity Cond Thread}
         safeInjector(entityType:single entity:Entity
                      'thread':Thread 'cond':Cond)
      end

      fun{GConvertToInj Entity Cond}
         {NotImplemented}
         false
      end

      fun{I_Impl Level Entity Cond Proc}
         case Level of global then
            {Fault.distHandlerInstall {GConvertToInj Entity Cond} Proc}
         elseof site then
            {Fault.distHandlerInstall {SConvertToInj Entity Cond} Proc}
         elseof 'thread'(Th) then
            {InterFault.interDistHandlerInstall
             {TConvertToInj Entity Cond Th} Proc}
         else
            {WrongFormat}
            false
         end
      end

      fun{D_Impl Level Entity Cond Proc}
         case Level of global then
            {Fault.distHandlerDeInstall {GConvertToInj Entity any} Proc}
         elseof site then
            {Fault.distHandlerDeInstall {SConvertToInj Entity any} Proc}
         elseof 'thread'(Th) then
            {InterFault.interDistHandlerDeInstall
             {TConvertToInj Entity any Th} Proc}
         else
            {WrongFormat}
            false
         end
      end

      fun{DefaultEnableImpl Cond}
         {Fault.distHandlerInstall {DConvertToInj Cond} Except}
      end

      fun{DefaultDisableImpl}
         {Fault.distHandlerDeInstall {DConvertToInj any} any}
      end

      fun{EnableImpl Entity Level Cond}
         {I_Impl Level Entity Cond Except}
      end

      fun{InstallImpl Entity Level Cond Proc}
         {I_Impl Level Entity Cond Proc}
      end

      fun{DisableImpl Entity Level}
         {D_Impl Level Entity any any}
      end

      fun{DeInstallImpl Entity Level}
         {D_Impl Level Entity any any}
      end

      fun{InstallWImpl Entity Cond Proc}
         {InterFault.interDistHandlerInstall
          watcher(entity:Entity 'cond':Cond) Proc}
      end

      fun{DeInstallWImpl Entity Proc}
         {InterFault.interDistHandlerDeInstall
          watcher(entity:Entity 'cond':any) Proc}
      end

   in
      {Wait DPB}

      GetEntityCond  = Fault.getEntityCond

      Enable        = fun{$ Entity Level Cond}
                         {EnableImpl Entity Level Cond}
                      end
      Disable       = fun{$ Entity Level}
                         {DisableImpl Entity Level}
                      end
      Install      = fun{$ Entity Level Cond Proc}
                         {InstallImpl Entity Level Cond Proc}
                      end
      DeInstall    = fun{$ Entity Level}
                         {DeInstallImpl Entity Level}
                      end
      DefaultEnable = fun{$ Cond}
                         {DefaultEnableImpl Cond}
                      end
      DefaultDisable= fun{$}
                         {DefaultDisableImpl}
                      end
      InstallWatcher= fun{$ Entity Cond Proc}
                         {InstallWImpl Entity Cond Proc}
                      end
      DeInstallWatcher=fun{$ Entity Proc}
                         {DeInstallWImpl Entity Proc}
                       end
    end
end
