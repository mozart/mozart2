%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997, 1998
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

   %%
   %% Creation of an executable component
   %%

   proc {WriteApp File App}
      TmpFile = {OS.tmpnam}
      Script  = {New Open.file
                 init(name:File flags:[create write truncate])}
   in
      try
         {Script write(vs:'#!/bin/sh\n')}
         {Script write(vs:'exec ozengine $0 "$@"\n')}
         {Script close}
         {Save Proc TmpFile}
         {OS.system 'cat '#TmpFile#' >> '#File#'; chmod +x '#File _}
      finally
         {OS.unlink TmpFile}
      end
   end

   %%
   %% Starting the business: link the root functor
   %%

   local
      BaseURL = '.'
   in
      fun {RootLink Functor}
         LILO   = {NewLILO Load}
         EXPORT = {LILO.link Functor BaseURL}
         FEAT   = {Arity Functor.'export'}.1
      in
         EXPORT.FEAT
      end
   end

   %%
   %% Creating application procedures
   %%

   fun {MkSyslet ArgSpec Functor}
      ArgParser = {Parser.cmd ArgSpec}
   in
      proc {$}
         Exit   = {`Builtin` shutdown 1}
         Script = {RootLink Functor}
      in
         try
            {Exit {Script {ArgParser}}}
         catch E then
            {{{`Builtin` getDefaultExceptionHandler 1}} E}
         finally
            {Exit 1}
         end
      end
   end

   fun {MkServlet ArgSpec Functor}
      ArgParser = {Parser.cmd ArgSpec}
   in
      Loader  = {RegistryGetLoader R
                 {Adjoin c('OP': eager) CompSpec}}
      ArgProc = {Parser.servlet ArgSpec}
   in
      proc {$}
         Exit = {`Builtin` shutdown 1}
      in
         try
            Loaded = {Loader}
            OP     = Loaded.'OP'
            Args   = {ArgProc OP.'Open' OP.'OS'}
         in
            {Exit {{Functor Loaded} Args}}
               % provide some error message
         catch E then
            {{{`Builtin` getDefaultExceptionHandler 1}} E}
         finally {Exit 1} end
      end
   end
   %%
   fun {RegistryMakeAppletProc R CompSpec ArgSpec Functor}
      Loader    = {RegistryGetLoader R
                   {Adjoin CompSpec c('WP': eager)}}
      ArgProc   = {Parser.applet ArgSpec}
   in
      proc {$}
         Exit   = {`Builtin` shutdown 1}
         Status
      in
         try
            Loaded = {Loader}
            Tk     = Loaded.'WP'.'Tk'

            Args   = {ArgProc}

            Top    = {New Tk.toplevel tkInit(withdraw: true
                                             title:    Args.title
                                             delete:   proc {$}
                                                          Status = 0
                                                       end)}
         in
            {Tk.batch
             case Args.width>0 andthen Args.height>0 then
                [wm(geometry  Top Args.width#x#Args.height)
                 wm(resizable Top false false)
                 update(idletasks)
                 wm(deiconify Top)]
             else
                [update(idletasks)
                 wm(deiconify Top)]
             end}

            {{Functor Loaded} Top Args}

            {Exit Status}
            % provide some error message
         catch E then
            {{{`Builtin` getDefaultExceptionHandler 1}} E}
         finally {Exit 1}
         end
      end
   end
   proc {FixErrorHandler EXPORT}
      %% This very smart idea has been taken over from Denys Duchier
      %%        [I am stealing it back! -- Denys]
      {{`Builtin` setDefaultExceptionHandler 1}
       proc {$ E}
          %% cause Error to be instantiated, which installs
          %% a new error handler as a side effect
          {Wait EXPORT.'SP'.'Error'}
          %% invoke this new error handler
          {{{`Builtin` getDefaultExceptionHandler 1}} E}
          %% this whole procedure is invoked at most once
          %% since instantiating base causes the handler
          %% to be replaced with a better one.
       end}
   end
   %%
   proc {Dummy _} skip end
   %%
   %% ArgParser
   %%
   \insert ArgParser.oz
   %%
in

   Application = application(syslet:   MkSyslet
                             servlet:  MkServlet
                             applet:   MkApplet)

end
