%%%
%%% Authors:
%%%   Denys Duchier     (duchier@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
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
      Error Property

   define
      {Property.put 'errors.handler'
       proc {$ E}
          %% cause Error to be instantiated, which installs
          %% a new error handler as a side effect
          {Wait Error}
          %% invoke this new error handler
          {{Property.get 'errors.handler'} E}
          %% this whole procedure is invoked at most once
          %% since instantiatingError causes the handler
          %% to be replaced with a better one.
       end}
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

      %% Execute error handler that will replace itself by real
      %% error handler on need
      {RM apply(ErrorHandler)}

      %% Link root functor (i.e. application)
      {RM link(url:{GET 'application.url'})}
   end
end
