%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
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
   ForeignPointer IsForeignPointer
in

%%
%% Global
%%
IsForeignPointer = {`Builtin` 'IsForeignPointer' 2}

%%
%% Module
%%
ForeignPointer = foreignPointer(is:    IsForeignPointer
                                toInt: {`Builtin` 'ForeignPointer.toInt' 2})
