%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 1998
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

functor prop once
body
   Getenv = {`Builtin` 'OS.getEnv'   2}
   SET    = {`Builtin` 'PutProperty' 2}
   GET    = {`Builtin` 'GetProperty' 2}
   %% usual system initialization
   local
      \insert 'init/Prop.oz'
      \insert 'init/URL.oz'
   in
      {SET url URL}
      {SET load URL.load}
   end
   %% execute application
   local
      %% create module manager
      \insert 'init/Module.oz'
      Module = {NewModule}
      UrlDefaults = \insert '../url-defaults.oz'
      FunExt      = UrlDefaults.'functor'
      MozartUrl   = UrlDefaults.'home'
      %% create and install ErrorHandler module
      functor ErrorHandler prop once
      import
         Error
      body
         {{`Builtin` setDefaultExceptionHandler 1}
          proc {$ E}
             %% cause Error to be instantiated, which installs
             %% a new error handler as a side effect
             {Wait Error}
             %% invoke this new error handler
             {{{`Builtin` getDefaultExceptionHandler 1}} E}
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
