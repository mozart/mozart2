%%%
%%% Authors:
%%%   Martin Mueller (mmueller@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Martin Mueller, 1997
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

declare
   Exception Raise
in


Raise = `Raise`

local
   fun {FailureX D}
      failure(debug:failure(info:D))
   end

   fun {PredefX E}
      system(E debug:{Label E})
   end

   fun {PredefXD E D}
      K
   in
      K = {Label E}
      system(E debug:K(info:D))
   end

   fun {ErrorXD E D}
      K
   in
      K = {Label E}
      error(E debug:K(info:D))
   end

   fun {ErrorX E}
      error(E debug:{Label E})
   end

in

   Exception = exception('raise':       Raise
                         raiseError:    `RaiseError`
                         %%
                         %% wrapper functions
                         %%
                         error:         ErrorX
                         failure:       FailureX
                         system:        PredefX
                         errorDebug:    ErrorXD
                         systemDebug:   PredefXD)

end
