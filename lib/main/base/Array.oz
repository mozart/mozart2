%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
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
   Array NewArray IsArray Put Get
in

NewArray = {`Builtin` 'NewArray' 4}
IsArray  = {`Builtin` 'IsArray'  2}
Put      = {`Builtin` 'Put'      3}
Get      = {`Builtin` 'Get'      3}

Array = array(new:  NewArray
              is:   IsArray
              put:  Put
              get:  Get
              low:  {`Builtin` 'Array.low'  2}
              high: {`Builtin` 'Array.high' 2})
