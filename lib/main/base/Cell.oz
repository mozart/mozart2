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
   Cell IsCell NewCell Exchange Assign Access
in

%%
%% Global
%%
IsCell   = {`Builtin` 'Cell.is'   2}
NewCell  = {`Builtin` 'Cell.new'  2}
Exchange = {`Builtin` 'Cell.exchange' 3}
Assign   = {`Builtin` 'Cell.assign'   2}
Access   = {`Builtin` 'Cell.access'   2}

%%
%% Module
%%
Cell = cell(is:       IsCell
            new:      NewCell
            exchange: Exchange
            assign:   Assign
            access:   Access)
