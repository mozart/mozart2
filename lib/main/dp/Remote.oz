%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
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

local

   proc {StartRemote Host Cmd Ticket}
      try
         0={OS.system 'rsh '#Host#' '#Cmd#' --ticket='#Ticket#[&&]}
      catch _ then
         raise error end
      end
   end

   class ComputeServer
      feat RP
      meth init(Host ...) = M
         Cmd = case {HasFeature M 2} then M.2
               else {OS.getEnv 'OZHOME'}#'/bin/ozserver'
               end
      in
         {StartRemote Host Cmd {Connection.offer self.RP}}
      end
      meth Remote(M)
         {Port.send self.RP M}
      end
      meth idle(_) = M
         ComputeServer,Remote(M)
      end
      meth ping(_) = M
         ComputeServer,Remote(M)
      end
      meth run(P Ack<=_)
         ComputeServer,Remote(run(P Ack))
      end
      meth close
         ComputeServer,Remote(close)
      end
   end

in

   Remote = remote(server: ComputeServer
                   farm:   unit)

end
