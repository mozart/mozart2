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
   Float IsFloat Exp Log Sqrt Ceil Floor Round Sin Cos Tan Asin Acos Atan Atan2
   FloatToInt FloatToString
in


%%
%% Run time library
%%
{`runTimePut` '/' {`Builtin` '/' 3}}


%%
%% Global
%%
IsFloat       = {`Builtin` 'IsFloat'       2}
Exp           = {`Builtin` 'Exp'           2}
Log           = {`Builtin` 'Log'           2}
Sqrt          = {`Builtin` 'Sqrt'          2}
Ceil          = {`Builtin` 'Ceil'          2}
Floor         = {`Builtin` 'Floor'         2}
Sin           = {`Builtin` 'Sin'           2}
Cos           = {`Builtin` 'Cos'           2}
Tan           = {`Builtin` 'Tan'           2}
Asin          = {`Builtin` 'Asin'          2}
Acos          = {`Builtin` 'Acos'          2}
Atan          = {`Builtin` 'Atan'          2}
Atan2         = {`Builtin` 'Atan2'         3}
Round         = {`Builtin` 'Round'         2}
FloatToInt    = {`Builtin` 'FloatToInt'    2}
FloatToString = {`Builtin` 'FloatToString' 2}

%%
%% Module
%%
Float = float(is:       IsFloat
              '/':      {`Builtin` '/' 3}
              exp:      Exp
              log:      Log
              sqrt:     Sqrt
              ceil:     Ceil
              floor:    Floor
              round:    Round
              sin:      Sin
              cos:      Cos
              tan:      Tan
              asin:     Asin
              acos:     Acos
              atan:     Atan
              atan2:    Atan2
              toInt:    FloatToInt
              toString: FloatToString)
