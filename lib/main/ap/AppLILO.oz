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

   \insert ../lilo/LILO.oz

in

   functor

   import
      OS.{tmpnam
          system
          unlink}
      System.{get}
      Open.{file}
      Component.{load
                 save}

   export
      Syslet
      Applet
      Servlet

   body

      %%
      %% ArgParser
      %%
      \insert ArgParser.oz

      %%
      %% Creation of an executable component
      %%

      local
         proc {WriteApp File App}
            TmpFile = {OS.tmpnam}
            Script  = {New Open.file
                       init(name:File flags:[create write truncate])}
         in
            try
               {Script write(vs:'#!/bin/sh\n')}
               {Script write(vs:'exec ozengine $0 "$@"\n')}
               {Script close}
               {Component.save App TmpFile}
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
            fun {RootLink Functor ?LILO}
               LILO = {NewLILO Component.load}

               local
                  EXPORT = {LILO.link Functor BaseURL}
                  FEAT   = {Arity Functor.'export'}.1
               in
                  EXPORT.FEAT
               end
            end
         end

      in
         %%
         %% Creating application procedures
         %%

         local
            fun {MkSyslet ArgSpec Functor}
               ArgParser = {Parser.cmd ArgSpec}
            in
               proc {$}
                  Exit   = {`Builtin` shutdown 1}
                  Script = {RootLink Functor _}
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
         in
            proc {Syslet File Functor Arg}
               {WriteApp File
                {MkSyslet Arg Functor}}
            end
         end

         local
            fun {MkServlet ArgSpec Functor}
               ArgParser = {Parser.servlet ArgSpec}
            in
               proc {$}
                  Exit   = {`Builtin` shutdown 1}
                  LILO
                  Script = {RootLink Functor ?LILO}
               in
                  try
                     OP   = {LILO.load 'OP'}
                     Args = {ArgParser OP.'Open' OP.'OS'}
                  in
                     {Exit {Script Args}}
               % provide some error message
                  catch E then
                     {{{`Builtin` getDefaultExceptionHandler 1}} E}
                  finally
                     {Exit 1}
                  end
               end
            end
         in
            proc {Servlet File Functor Arg}
               {WriteApp File
                {MkServlet Arg Functor}}
            end
         end

         local
            fun {MkApplet ArgSpec Functor}
               ArgParser = {Parser.applet ArgSpec}
            in
               proc {$}
                  Exit   = {`Builtin` shutdown 1}
                  LILO
                  Script = {RootLink Functor ?LILO}
                  Status
               in
                  try
                     Tk     = {LILO.load 'WP'}.'Tk'

                     Args   = {ArgParser}

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

                     {Script Top Args}

                     {Exit Status}

                  catch E then
                     {{{`Builtin` getDefaultExceptionHandler 1}} E}
                  finally
                     {Exit 1}
                  end
               end
            end
         in
            proc {Applet File Functor Arg}
               {WriteApp File
                {MkApplet Arg Functor}}
            end
         end


      end

   end

end
