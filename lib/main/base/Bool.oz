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
   Bool IsBool And Or Not
   `true` `false`
in


%%
%% Compiler Expansion
%%
local
   NewUniqueName = {`Builtin` 'Name.newUnique' 2}
in
   `true`  = {NewUniqueName 'true'}
   `false` = {NewUniqueName 'false'}
end

%%
%% Global
%%
IsBool = {`Builtin` 'Bool.is' 2}
Not    = {`Builtin` 'Bool.not'    2}
And    = {`Builtin` 'Bool.and'    3}
Or     = {`Builtin` 'Bool.or'     3}


%%
%% Module
%%
Bool = bool(is:      IsBool
            and:     And
            'or':    Or
            'not':   Not
            'true':  true
            'false': false)
