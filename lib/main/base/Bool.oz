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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


declare
   Bool IsBool And Or Not
   `true` `false`
in


%%
%% Compiler Expansion
%%
local
   NewUniqueName = {`Builtin` 'NewUniqueName' 2}
in
   `true`  = {NewUniqueName 'true'}
   `false` = {NewUniqueName 'false'}
end

%%
%% Global
%%
IsBool = {`Builtin` 'IsBool' 2}
Not    = {`Builtin` 'Not'    2}
And    = {`Builtin` 'And'    3}
Or     = {`Builtin` 'Or'     3}


%%
%% Module
%%
Bool = bool(is:      IsBool
            and:     And
            'or':    Or
            'not':   Not
            'true':  true
            'false': false)
