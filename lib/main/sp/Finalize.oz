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
   Finalize at 'x-oz://boot/Finalize'

export
   register:   Register
   setHandler: SetHandler
   everyGC:    EveryGC

define

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
