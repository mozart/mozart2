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
   Procedure IsProcedure ProcedureArity
in


%%
%% Global
%%
IsProcedure    = {`Builtin` 'IsProcedure'    2}
ProcedureArity = {`Builtin` 'ProcedureArity' 2}


%%
%% Module
%%
Procedure = procedure(is:    IsProcedure
                      arity: ProcedureArity)
