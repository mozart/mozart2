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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local

   \insert 'init/Module.oz'

   local
      UrlDefaults = \insert '../url-defaults.oz'
   in
      FunExt      = UrlDefaults.'functor'
      MozartUrl   = UrlDefaults.'home'
   end

in

   functor prop once
   import
      Boot
   body

      BootManager = Boot.manager

      BURL     = {BootManager 'URL'}

      OS       = {BootManager 'OS'}
      Pickle   = {BootManager 'Pickle'}
      Property = {BootManager 'Property'}
      System   = {BootManager 'System'}


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
         Module = {NewModule.apply 'import'('System': System
                                            'Pickle': Pickle
                                            'OS':     OS
                                            'Boot':   Boot)}

         %% Register some volatile modules

         {Module.enter 'x-oz://boot/URL' BURL}

         {Module.enter MozartUrl#'OS'#FunExt       OS}
         {Module.enter MozartUrl#'Property'#FunExt Property}
         {Module.enter MozartUrl#'Pickle'#FunExt   Pickle}
         {Module.enter MozartUrl#'System'#FunExt   System}
         {Module.enter MozartUrl#'Module'#FunExt   Module}
         {Module.enter MozartUrl#'Resolve'#FunExt  Resolve}

         %% create and install ErrorHandler module
         functor ErrorHandler prop once
         import
            Error
         body
            {Property.put 'errors.handler'
             proc {$ E}
                %% cause Error to be instantiated, which installs
                %% a new error handler as a side effect
                {Wait Error}
                %% invoke this new error handler
                {Property.get 'errors.handler' E}
                %% this whole procedure is invoked at most once
                %% since instantiatingError causes the handler
                %% to be replaced with a better one.
             end}
         end

         {Module.link MozartUrl#'ErrorHandler'#FunExt ErrorHandler _}
      in

         %% load and install (i.e. execute) root functor (i.e. application)
         {Wait {Module.load unit {GET 'root.url'}}}
      end
   end
end
