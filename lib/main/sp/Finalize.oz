%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Contributor:
%%%   Christian Schulte, 1998
%%%
%%% Copyright:
%%%   Denys Duchier, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor $ prop once

import
   Finalize from 'x-oz://boot/Finalize'

export
   register:   Register
   setHandler: SetHandler
   everyGC:    EveryGC

body

   Register   = Finalize.register
   SetHandler = Finalize.setHandler

   local
      proc {FinalizeEntry Value|Handler}
         {Handler Value}
      end
      proc {FinalizeHandler L}
         {ForAll L FinalizeEntry}
      end
   in
      {SetHandler FinalizeHandler}
   end

   proc {EveryGC P}
      proc {DO _}
         {P}
         {Register DO DO}
      end
   in {Register DO DO} end
end
