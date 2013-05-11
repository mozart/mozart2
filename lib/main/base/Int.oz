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
%% Global
%%

fun {IsNat X}  0 =< X       end
fun {IsOdd X}  X mod 2 \= 0 end
fun {IsEven X} X mod 2 == 0 end

%%
%% Module
%%
fun {IntToFloat I}
   {StringToFloat {IntToCompactString I}}
end

fun {IntToCompactString I}
   if {IsInt I} then
      {VirtualString.toCompactString I}
   else
      {Exception.raiseError kernel(type 'Int.toCompactString' [I] 'Integer' 1)}
      unit
   end
end

fun {IntToString I}
   if {IsInt I} then
      {VirtualString.toString I}
   else
      {Exception.raiseError kernel(type 'Int.toString' [I] 'Integer' 1)}
      unit
   end
end

Int = int(is:              IsInt
          isNat:           IsNat
          isOdd:           IsOdd
          isEven:          IsEven
          'div':           Boot_Int.'div'
          'mod':           Boot_Int.'mod'
          '+1':            Boot_Int.'+1'
          '-1':            Boot_Int.'-1'
          toFloat:         IntToFloat
          toCompactString: IntToCompactString
          toString:        IntToString)
