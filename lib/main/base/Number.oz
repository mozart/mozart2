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
%% Global
%%

local
   FloatPow = Boot_Float.fPow
   fun {IntPow X N A}
      case N==0 then A
      elsecase N mod 2==0 then {IntPow X*X (N div 2) A}
      else {IntPow X (N-1) A*X}
      end
   end
in
   fun {Pow X Y}
      case {IsInt X} andthen {IsInt Y} then
         case Y>0 then {IntPow X Y 1} else Y=0 1 end
      elsecase {IsFloat X} andthen {IsFloat Y} then {FloatPow X Y}
      end
   end
end


%%
%% Module
%%
Number = number(is:  IsNumber
                '+': Boot_Number.'+'
                '-': Boot_Number.'-'
                '*': Boot_Number.'*'
                '~': Boot_Number.'~'
                pow: Pow
                abs: Abs)
