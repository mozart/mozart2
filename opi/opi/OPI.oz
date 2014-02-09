%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%   Christian Schulte, 1998
%%%   Denys Duchier, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
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
   %Debug at 'x-oz://boot/Debug'
   Application(getCmdArgs)
   System(printError)
   Property(get put)
   OS(getEnv)
   Open(file)
   Compiler(engine)
   Emacs(interface attentionPrefix)
   OPIEnv(full)
export
   compiler: OPICompiler
   interface: CompilerUI
prepare
   Spec = record(host(single type: string default: unit))
define
   %{Debug.setRaiseOnBlock {Thread.this} true}
   Args = {Application.getCmdArgs Spec}

   local
      OZVERSION = {Property.get 'oz.version'}
      OZDATE    = {Property.get 'oz.date'}
   in
      {System.printError
       'Mozart Engine '#OZVERSION#' ('#OZDATE#') playing Oz 3\n\n'}
   end

   {Property.put 'oz.standalone' false}
   {Property.put 'errors.prefix' Emacs.attentionPrefix}

   OPICompiler = {New Compiler.engine init()}
   {OPICompiler enqueue(mergeEnv(OPIEnv.full))}

   CompilerUI = {New Emacs.interface init(OPICompiler Args.host)}
   {Property.put 'opi.compiler' CompilerUI}

   %% Make the error handler non-halting
   {Property.put 'errors.toplevel'    proc {$} skip end}
   {Property.put 'errors.subordinate' proc {$} fail end}

   %% Try to load some ozrc file
   local
      fun {FileExists FileName}
         try F in
            F = {New Open.file init(name: FileName flags: [read])}
            {F close()}
            true
         catch _ then false
         end
      end
   in
      case {OS.getEnv 'HOME'} of false then skip
      elseof HOME then
         OZRC = {OS.getEnv 'OZRC'}
      in
         if OZRC \= false andthen {FileExists OZRC} then
            {OPICompiler enqueue(feedFile(OZRC))}
         elseif {FileExists {Property.get 'oz.dotoz'}#'/ozrc'} then
            {OPICompiler enqueue(feedFile({Property.get 'oz.dotoz'}#'/ozrc'))}
         elseif {FileExists HOME#'/.oz/ozrc'} then
            {OPICompiler enqueue(feedFile(HOME#'/.oz/ozrc'))}
         elseif {FileExists HOME#'/.ozrc'} then   % note: deprecated
            {OPICompiler enqueue(feedFile(HOME#'/.ozrc'))}
         end
      end
   end

   thread {CompilerUI readQueries()} end
end
