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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


declare
   Unit IsUnit
   `unit`
in


%%
%% Compiler Expansion
%%
local
   NewUniqueName = {`Builtin` 'Name.newUnique' 2}
in
   `unit` = {NewUniqueName 'unit'}
end

%%
%% Global
%%
IsUnit = {`Builtin` 'Unit.is'  2}


%%
%% Module
%%
Unit = 'unit'(is:     IsUnit
              'unit': unit)
