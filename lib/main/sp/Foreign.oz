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
   Property.get

   Error.{formatGeneric
          format
          dispatch}

   ErrorRegistry.{put}

   Foreign.{dlLoad}
      from 'x-oz://boot/Foreign'

   OS

   URL

export
   resolver:   Resolver
   load:       ForeignLoad
   loadBI:     ForeignLoadBI

body
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
   Resolver = {URL.makeResolver foreign
               vs({Property.get 'oz.search.dload'})}

   Localize = Resolver.localize

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
       of foreign(cannotFindInterface F) then
          {Error.format T
           'Cannot find interface'
           [hint(l:'File name' m:F)]
           Exc}
       else
          {Error.formatGeneric T Exc}
       end
    end}

end
