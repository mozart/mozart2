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
   System.{get
           property}

export
   pointer:    ForeignPointer
   dload:      DLoad
   require:    Require
   resolver:   Resolver
   load:       ForeignLoad
   staticLoad: ForeignStaticLoad
   loadBI:     ForeignLoadBI

body
   DlOpen         = {`Builtin` dlOpen        2}
   DlClose        = {`Builtin` dlClose       1}
   FindFunction   = {`Builtin` findFunction  3}
   DlLoad         = {`Builtin` dlLoad        2}
   DlStaticLoad   = {`Builtin` dlStaticLoad  2}
   Unlink         = {`Builtin` 'OS.unlink'   1}
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

   case {System.property.condGet url false}
   of false then
      !Resolver = unit
      fun{!Localize PATH} old(PATH) end
   elseof URL then
      !Resolver = {URL.makeResolver foreign
                   vs({System.property.get 'oz.search.dload'})}
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

   fun {ForeignStaticLoad Base}
      Static = {DlStaticLoad Base}
   in
      case Static==unit then
         %% Not available in the emulator, go and load it
         %% DENYS: this all needs improvement! CS
         HOME    = {System.get home}
         OS#ARCH = {System.get platform}
      in
         {ForeignLoad HOME#'/platform/'#OS#'-'#ARCH#'/'#Base}
      else Static
      end
   end

   ForeignPointer = foreignPointer(is: {`Builtin` 'isForeignPointer' 2})

end
