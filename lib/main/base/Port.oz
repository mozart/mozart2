%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
%%%   Christian Schulte, 1997
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


declare
   Port IsPort NewPort Send
in

%%
%% Global
%%
IsPort  = {`Builtin` 'IsPort'  2}
NewPort = {`Builtin` 'NewPort' 2}
Send    = {`Builtin` 'Send'    2}

%%
%% Module
%%
Port = port(is:    IsPort
            new:   NewPort
            send:  Send)
