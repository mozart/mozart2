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
{`runTimePut` '/' {`Builtin` 'Number.\'/\'' 3}}


%%
%% Global
%%
IsFloat       = {`Builtin` 'Float.is'       2}
Exp           = {`Builtin` 'Float.exp'           2}
Log           = {`Builtin` 'Float.log'           2}
Sqrt          = {`Builtin` 'Float.sqrt'          2}
Ceil          = {`Builtin` 'Float.ceil'          2}
Floor         = {`Builtin` 'Float.floor'         2}
Sin           = {`Builtin` 'Float.sin'           2}
Cos           = {`Builtin` 'Float.cos'           2}
Tan           = {`Builtin` 'Float.tan'           2}
Asin          = {`Builtin` 'Float.asin'          2}
Acos          = {`Builtin` 'Float.acos'          2}
Atan          = {`Builtin` 'Float.atan'          2}
Atan2         = {`Builtin` 'Float.atan2'         3}
Round         = {`Builtin` 'Float.round'         2}
FloatToInt    = {`Builtin` 'Float.toInt'    2}
FloatToString = {`Builtin` 'Float.toString' 2}

%%
%% Module
%%
Float = float(is:       IsFloat
              '/':      {`Builtin` 'Number.\'/\'' 3}
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
