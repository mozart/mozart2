%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


%%
%% Module
%%
fun {FloatToCompactString F}
   if {IsFloat F} then
      {VirtualString.toCompactString F}
   else
      {Exception.raiseError kernel(type 'Float.toCompactString' [F] 'Float' 1)}
      unit
   end
end

fun {FloatToString F}
   if {IsFloat F} then
      {VirtualString.toString F}
   else
      {Exception.raiseError kernel(type 'Float.toString' [F] 'Float' 1)}
      unit
   end
end

Float = float(is:              IsFloat
              '/':             Boot_Float.'/'
              /*'mod':           Boot_Float.fMod
              exp:             Exp
              log:             Log
              sqrt:            Sqrt
              ceil:            Ceil
              floor:           Floor
              round:           Round
              sin:             Sin
              cos:             Cos
              tan:             Tan
              asin:            Asin
              acos:            Acos
              atan:            Atan
              atan2:           Atan2
              sinh:            Boot_Float.sinh
              cosh:            Boot_Float.cosh
              tanh:            Boot_Float.tanh
              asinh:           Boot_Float.asinh
              acosh:           Boot_Float.acosh
              atanh:           Boot_Float.atanh
              toInt:           FloatToInt*/
              toCompactString: FloatToCompactString
              toString:        FloatToString)
