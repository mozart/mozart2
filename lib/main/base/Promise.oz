%%%
%%% Authors:
%%%   Michael Mehl     (mehl@dfki.de)
%%%   Ralf Scheidhauer (scheidhrdfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl
%%%   Ralf Scheidhauer
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
Promise = promise(new:         {`Builtin` 'Promise.new'         1}
                  is:          {`Builtin` 'Promise.is'          2}
                  waitRequest: {`Builtin` 'Promise.waitRequest' 1}
                  assign:      {`Builtin` 'Promise.assign'      2}
                  access:      {`Builtin` 'Promise.access'      2})

`!!` = Promise.access
`:=` = Promise.assign
