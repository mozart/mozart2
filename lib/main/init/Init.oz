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

require
   URL(make:                    UrlMake
       is:                      UrlIs
       normalizePath:           UrlNormalizePath
       resolve:                 UrlResolve
       toVirtualString:         UrlToVs
       toAtom:                  UrlToAtom
       toBase:                  UrlToBase
       toString:                UrlToString
       isRelative:              UrlIsRelative
       toVirtualStringExtended: UrlToVsExtended)

   DefaultURL(ozScheme
              functorExt:  FunctorExt
              homeUrl:     MozartHome
              contribUrl:  ContribHome
              nameToUrl:   ModNameToUrl)

prepare

   DotUrl         = {UrlMake './'}
   SystemHomeUrl  = {UrlToBase MozartHome}
   ContribHomeUrl = {UrlToBase ContribHome}
   OzScheme       = {VirtualString.toString DefaultURL.ozScheme}

   functor ErrorHandler
   import
      Debug(setRaiseOnBlock) at 'x-oz://boot/Debug'
      Property(put condGet)
      System(onToplevel)
      Application(exit)
      Error(printException)
   define
      proc {ExitError}
         {Application.exit 1}
      end

      proc {ErrorHandler Exc}
         %% ignore thread termination exception
         case Exc of system(kernel(terminate) ...) then skip
         else
            {Thread.setThisPriority high}
            {Debug.setRaiseOnBlock {Thread.this} true}
            {Error.printException Exc}
            {Debug.setRaiseOnBlock {Thread.this} false}
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

   \insert 'init/Module.oz'

import
   Boot at 'x-oz://boot/Boot'

define

   %% The mechanism with which builtin modules can be accessed
   ObtainNative = Boot.obtain

   fun {BootManager Name}
      {ObtainNative true Name}
   end

   %% Retrieve modules needed to get things started
   BURL     = {BootManager 'URL'}

   OS       = {BootManager 'OS'}
   Pickle   = {BootManager 'Pickle'}
   Property = {BootManager 'Property'}
   System   = {BootManager 'System'}

   %% Shortcuts
   Getenv = OS.getEnv
   SET    = Property.put
   GET    = Property.get

   %% usual system initialization
   \insert 'init/Prop.oz'
   \insert 'init/Resolve.oz'

   {SET load Resolve.load}

   %% execute application

   local

      %% create module manager
      Module = {NewModule.apply 'import'('System':   System
                                         'OS':       OS
                                         'Boot':     Boot
                                         'Property': Property
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
      {RM enter(name:'OS'       OS)}
      {RM enter(name:'Property' Property)}
      {RM enter(name:'Pickle'   Pickle)}
      {RM enter(name:'System'   System)}
      {RM enter(name:'Resolve'  Resolve)}
      {RM enter(name:'Module'   RealModule)}

      %% Install error handler
      {RM apply(ErrorHandler)}

      %% Link root functor (i.e. application)
      {RM link(url:{GET 'application.url'})}
   end
end
