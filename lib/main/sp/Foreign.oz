%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1997
%%%   Christian Schulte, 1997
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


functor $ prop once

import
   Property.{get condGet}

   Error.{formatGeneric
          format
          dispatch}

   ErrorRegistry.{put}

   Foreign.{dlOpen dlClose findFunction dlLoad}
      from 'x-oz-boot:Foreign'

   OS

export
   dload:      DLoad
   require:    Require
   resolver:   Resolver
   load:       ForeignLoad
   loadBI:     ForeignLoadBI

body
   DlOpen         = Foreign.dlOpen
   DlClose        = Foreign.dlClose
   FindFunction   = Foreign.findFunction
   DlLoad         = Foreign.dlLoad
   Unlink         = OS.unlink
   %%
   %% If the URL service is available, then use it to create a
   %% localizer parametrized by environment variable OZ_DL_LOAD,
   %% otherwise use the `identity' localizer.  The localizer
   %% is given a URL denoting a dynamic library and endeavors
   %% to make this library available as a local file.  It returns
   %% either old(FILE) or new(FILE): it returns new(FILE) iff
   %% it just created FILE locally, e.g. by downloading it.  In
   %% that case, the application should take care to unlink the
   %% file (i.e. clean up).  The identity localizer always returns
   %% old(FILE) without checking if the FILE actually exists.
   %%
   Resolver
   Localize

   case {Property.condGet url false}
   of false then
      !Resolver = unit
      fun{!Localize PATH} old(PATH) end
   elseof URL then
      !Resolver = {URL.makeResolver foreign
                   vs({Property.get 'oz.search.dload'})}
      !Localize = Resolver.localize
   end

   proc {LoadFromHandle Spec Handle Module}
      ModuleLabel  = {Label Spec}
      All          = {Arity Spec}
   in
      {MakeRecord ModuleLabel All Module}
      {ForAll All
       proc {$ AName}
          D = Spec.AName
          N = ModuleLabel#'_'#AName
       in
          {FindFunction N D Handle}
          Module.AName = {`Builtin` N D}
       end}
   end

   proc {Link File Spec Module Handle}
      case {Localize File}
      of     old(FILE) then
         {DlOpen FILE Handle}
         {LoadFromHandle Spec Handle Module}
      elseof new(FILE) then
         try
            {DlOpen FILE Handle}
            {LoadFromHandle Spec Handle Module}
         finally {Unlink FILE} end
      end
   end

   proc {Require File Spec Module}
      {Link File Spec Module _}
   end

   proc {DLoad   File Spec CloseF Module} Handle in
      {Link File Spec Module Handle}
      proc {!CloseF} {DlClose Handle} end
   end

   fun {ForeignLoadBI File}
      Local = {Localize File}
   in
      try {DlLoad Local.1}
      finally
         case {Label Local}==old then skip else
            {Unlink Local.1}
         end
      end
   end

   fun {ForeignLoad File}
      _#Module = {ForeignLoadBI File}
   in Module
   end


   {ErrorRegistry.put

    foreign

    fun {$ Exc}
      E = {Error.dispatch Exc}
      T = 'Error: Foreign'
   in

      case E
      of foreign(cannotFindFunction F A H) then

         % expected F: atom, A: int, H: int

         {Error.format T
          'Cannot find foreign function'
          [hint(l:'Function name' m:F)
           hint(l:'Arity' m:A)
           hint(l:'Handle' m:H)]
          Exc}

      elseof foreign(dlOpen F S) then

         % expected F: virtualString

         {Error.format T
          'Cannot load foreign function file'
          [hint(l:'File name' m:F)
           hint(l:'Error number' m:S)]
          Exc}

      elseof foreign(dlClose N) then

         {Error.format T
          'Cannot unload foreign function file'
          [hint(l:'File handle' m:oz(N))]
          Exc}

      elseof foreign(linkFiles As) then

         {Error.format T
          'Cannot link object files'
          [hint(l:'File names' m:list(As ' '))]
          Exc}

      else
         {Error.formatGeneric T Exc}
      end
   end}

end
