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


%%
%% Module
%%
Float = float(is:       IsFloat
              '/':      Boot_Float.'/'
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
