%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997, 1998
%%%   Denys Duchier, 1997
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

%\define INTERACTIVE
\ifdef INTERACTIVE
declare
AF =
\endif

local

   \insert ../lilo/LILO.oz

in

   functor $ prop once

   import
      OS.{tmpnam
          system
          unlink}

      System.{get
              show
              property}

      Open.{file}

      Component.{save}

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
         functor ErrorHandler prop once
         import LILO.{loadEager}
         body
            {{`Builtin` setDefaultExceptionHandler 1}
             proc {$ E}
                %% cause Error to be instantiated, which installs
                %% a new error handler as a side effect
                {Wait {LILO.loadEager 'Error'}}
                %% invoke this new error handler
                {{{`Builtin` getDefaultExceptionHandler 1}} E}
                %% this whole procedure is invoked at most once
                %% since instantiatingError causes the handler
                %% to be replaced with a better one.
             end}
         end

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
            catch E then
               raise E end
            finally
               {OS.unlink TmpFile}
            end
         end

         fun {MakeBody Functor LetKey LetFunctor}
            proc {$}
               LILO = {NewLILO}
            in
               {LILO.link unit   ErrorHandler '.' _}
               {LILO.link LetKey LetFunctor   '.' _}
               {LILO.link unit   Functor      '.' _}
            end
         end

      in
         %%
         %% Creating application procedures
         %%

         proc {Syslet File Functor Arg}
            ArgParser = {Parser.cmd Arg}

            functor Syslet prop once
            export Args Exit
            body
               Args = {ArgParser}
               Exit = {`Builtin` shutdown 1}
            end

         in
            {WriteApp File {MakeBody Functor 'Syslet' Syslet}}
         end

         proc {Servlet File Functor Arg}
            ArgParser = {Parser.servlet Arg}

            functor Servlet prop once
            import OS Open
            export Args Exit
            body
               Args = {ArgParser OS Open}
               Exit = {`Builtin` shutdown 1}
            end

         in
            {WriteApp File {MakeBody Functor 'Servlet' Servlet}}
         end

         proc {Applet File Functor Arg}
            ArgParser = {Parser.applet Arg}

            functor Applet prop once
            import Tk
            export Args Exit Toplevel
            body
               Args     = {ArgParser}
               Exit     = {`Builtin` shutdown 1}
               Toplevel = {New Tk.toplevel tkInit(withdraw: true
                                                  title:    Args.title
                                                  delete:   proc {$}
                                                               {Exit 0}
                                                            end)}
            in
               {Tk.batch
                case Args.width>0 andthen Args.height>0 then
                   [wm(geometry  Toplevel Args.width#x#Args.height)
                    wm(resizable Toplevel false false)
                    update(idletasks)
                    wm(deiconify Toplevel)]
                else
                   [update(idletasks)
                    wm(deiconify Toplevel)]
                end}
            end

         in
            {WriteApp File {MakeBody Functor 'Applet' Applet}}
         end

      end

   end

end


\ifdef INTERACTIVE

declare
Application = {AF.apply 'import'('OS':        OS
                                 'System':    System
                                 'Open':      Open
                                 'Component': Component)}

\endif
