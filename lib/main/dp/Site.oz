%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1997
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

\insert server

\insert agenda

Gate = gate(id:    {`Builtin` 'GateId'    1}
            open:  {`Builtin` 'OpenGate'  1}
            close: {`Builtin` 'CloseGate' 0}
            send:  {`Builtin` 'SendGate'  2})

local
   Wget = {`Builtin` 'Wget' 2}
in

   Site = site(server:          Server
               newServer:       NewServer
               wget:            Wget
               gate:            Gate)
end
