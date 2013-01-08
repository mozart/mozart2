%%%
%%% Authors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Contributor:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Denys Duchier, 1998
%%%   Christian Schulte, 1998
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

prepare

   %% Functors that must be pickled within Init.ozf

   Functor_URL =
   \insert '../dp/URL.oz'

   Functor_DefaultURL =
   \insert '../support/DefaultURL.oz'

   Functor_System =
   \insert '../sys/System.oz'

   %% Apply manually URL and DefaultURL

   URL = {Functor_URL.apply 'import'}
   UrlMake = URL.make
   UrlIs = URL.is
   UrlNormalizePath = URL.normalizePath
   UrlResolve = URL.resolve
   UrlToVs = URL.toVirtualString
   UrlToAtom = URL.toAtom
   UrlToBase = URL.toBase
   UrlToString = URL.toString
   UrlIsRelative = URL.isRelative
   UrlToVsExtended = URL.toVirtualStringExtended

   DefaultURL = {Functor_DefaultURL.apply 'import'('URL':URL)}
   FunctorExt = DefaultURL.functorExt
   ModNameToUrl = DefaultURL.nameToUrl
   IsNatSystemName = DefaultURL.isNatLibName

   %% Now start our things

   DotUrl   = {UrlMake './'}
   OzScheme = {VirtualString.toString DefaultURL.ozScheme}

   functor ErrorHandler
   import
      Debug(setRaiseOnBlock) at 'x-oz://boot/Debug'
      Property(put condGet)
      System(onToplevel showError show)
      BootSystem(exit) at 'x-oz://boot/System'
      Error(printException)
   define
      proc {ExitError}
         {BootSystem.exit 1}
      end

      proc {ErrorHandler Exc}
         %% ignore thread termination exception
         case Exc of system(kernel(terminate) ...) then skip
         else
            try
               {Thread.setThisPriority high}
               {Debug.setRaiseOnBlock {Thread.this} true}
               {Error.printException Exc}
               {Debug.setRaiseOnBlock {Thread.this} false}
            catch _ then
               {System.showError
                '*** error while reporting error ***\noriginal exception:'}
               {System.show Exc}
               {BootSystem.exit 1}
            end
            %% terminate local computation
            if {System.onToplevel} then
               {{Property.condGet 'errors.toplevel' ExitError}}
            elsecase Exc of failure(...) then fail
            else
               {{Property.condGet 'errors.subordinate' ExitError}}
            end
         end
      end

      {Property.put 'errors.handler' ErrorHandler}
   end

   \insert 'Module.oz'

\ifdef DENYS_EVENTS
   functor Event
   import
      Event(getStream) at 'x-oz://boot/Event'
      Error(registerFormatter)
      EventSIGCHLD(handler) at 'x-oz://system/EventSIGCHLD'
      Timer(timerHandler delayHandler)
      OS(ioHandler) Perdio(handler)
   export
      put            : PutEventHandler
      get            : GetEventHandler
      condGet        : CondGetEventHandler
   define
      Handlers = {Dictionary.new}
      proc {PutEventHandler Label P}
         {Dictionary.put Handlers Label P}
      end
      fun {GetEventHandler Label}
         {Dictionary.get Handlers Label}
      end
      fun {CondGetEventHandler Label Default}
         {Dictionary.condGet Handlers Label Default}
      end

      %% default handler raises an exception in a new thread

      proc {DefaultHandler E}
         thread {Exception.raiseError event(noHandler E)} end
      end

      %% to handle an event, look up the handler using the
      %% event label

      proc {HandleEvent E}
         if {IsDet E} andthen {IsRecord E} then
            try
               {{Dictionary.condGet Handlers {Label E} DefaultHandler} E}
            catch Exc then
               thread {Raise Exc} end
            end
         else
            thread {Exception.raiseError event(noEvent E)} end
         end
      end

      %% print out nice error messages

      {Error.registerFormatter event
       fun {$ E}
          T = 'error in Event module'
       in
          case E
          of event(noHandler E) then
             error(kind : T
                   msg  : 'no handler for event'
                   items: [hint(l:'event: ' m:oz(E))])
          [] event(noEvent E) then
             error(kind : T
                   msg  : 'not an event value'
                   items: [hint(l:'event: ' m:oz(E))])
          end
       end}

      %% register some handlers

      {PutEventHandler 'SIGCHLD' EventSIGCHLD.handler}
      {PutEventHandler 'timer'   Timer       .timerHandler}
      {PutEventHandler 'delay'   Timer       .delayHandler}
      {PutEventHandler 'io'      OS          .ioHandler}
      {PutEventHandler 'dp.init' Perdio      .handler}

      %% start a high priority thread to process the event stream

      thread
         {Thread.setPriority {Thread.this} 'high'}
         {ForAll {Event.getStream} HandleEvent}
      end
   end
\endif

import
   Boot at 'x-oz://boot/Boot'

define

   %% The mechanism with which builtin modules can be accessed
   GetInternal = Boot.getInternal
   GetNative = Boot.getNative

   %% Properties
   local
      Boot_Property = {GetInternal 'Property'}
   in
      proc {SET Property Value}
         if {Boot_Property.put Property Value} then skip else
            {Boot_Property.registerValue Property Value}
         end
      end

      fun {GET Property}
         {Boot_Property.get Property $ true}
      end
   end

   %% OS related stuff
   local
      Boot_OS = {GetInternal 'OS'}
   in
      Getenv = Boot_OS.getEnv
      GetCWD = Boot_OS.getCWD
   end

   /** Loads a functor located at a given URL
    *  This never goes to the file system, but looks up functors in the
    *  BootVirtualFS above instead.
    */
   fun {BootURLLoad URL}
      BootVirtualFS = {GET 'internal.boot.virtualfs'}
      URLAtom = {VirtualString.toAtom URL}
   in
      try
         {Dictionary.get BootVirtualFS URLAtom}
      catch dictKeyNotFound(_ _) then
         raise system(module(notFound load URLAtom)) end
      end
   end

   %% Boot BURL
   BURL = 'export'(
      localize: fun {$ U}
                   raise error(kernel(stub 'BURL.localize') debug:unit) end
                end
      open:     fun {$ U}
                   raise error(kernel(stub 'BURL.open') debug:unit) end
                end
      load:     BootURLLoad
   )

   %% Apply manually the System module
   System = {Functor_System.apply 'import'('Boot_System':{GetInternal 'System'})}

   %% Make a stub OS module for our bootstrapping purpose
   OS = 'export'(
      getEnv:Getenv
      getCWD:GetCWD
      getpwname:fun {$ U}
                   raise error(kernel(stub 'OS.getpwname') debug:unit) end
                end
   )

   %% usual system initialization
   \insert 'Prop.oz'
   \insert 'Resolve.oz'

   {SET load Resolve.load}

   %% execute application

   local

      %% stubs of OS and Property for the application of NewModule
      StubProperty = 'export'(put:SET get:GET)

      %% create module manager
      Module = {NewModule.apply 'import'('System':   System
                                         'OS':       OS
                                         'Boot':     Boot
                                         'Property': StubProperty
                                         'Resolve':  Resolve)}

      %% The root module manager
      RM = Module.root

      %% The real Module module
      local
         \insert 'ModuleAbstractions.oz'
      in
         RealModule = 'export'(manager: Module.manager
                               trace:   Module.trace
                               link:    Link
                               apply:   Apply)
      end

   in
      %% Register boot modules
      {RM enter(url:'x-oz://boot/URL'  BURL)}
      {RM enter(url:'x-oz://boot/Boot' Boot)}

      %% Register volatile system modules
      {RM enter(url:'x-oz://system/URL.ozf'        URL)}
      {RM enter(url:'x-oz://system/DefaultURL.ozf' DefaultURL)}
      {RM enter(url:'x-oz://system/System.ozf'     System)}
      {RM enter(url:'x-oz://system/Resolve.ozf'    Resolve)}
      {RM enter(url:'x-oz://system/Module.ozf'     RealModule)}

      %% Install error handler
      {RM apply(ErrorHandler)}

\ifdef DENYS_EVENTS
      %% Start event handling
      local M = {RM apply(name:'Event' Event $)} in
         {RM enter(name:'Event' M)}
      end
\endif

      %% Link the real OS module, which should set up a proper BURL
      {Wait {RM link(url:'x-oz://system/OS.ozf' $)}}

      %% Link root functor (i.e. application)
      {Wait {RM link(url:{GET 'application.url'} $)}}
   end
end
