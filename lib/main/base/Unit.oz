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


declare
   Unit IsUnit
   `unit`
in


%%
%% Compiler Expansion
%%
local
   NewUniqueName = {`Builtin` 'NewUniqueName' 2}
in
   `unit` = {NewUniqueName 'unit'}
end

%%
%% Global
%%
IsUnit = {`Builtin` 'IsUnit'  2}


%%
%% Module
%%
Unit = 'unit'(is:     IsUnit
              'unit': unit)
