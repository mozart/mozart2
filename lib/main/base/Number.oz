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
   Number IsNumber Pow Abs
in


%%
%% Run time library
%%
{`runTimePut` '+' {`Builtin` 'Number.\'+\'' 3}}
{`runTimePut` '-' {`Builtin` 'Number.\'-\'' 3}}
{`runTimePut` '*' {`Builtin` 'Number.\'*\'' 3}}
{`runTimePut` '~' {`Builtin` 'Number.\'~\'' 2}}


%%
%% Global
%%
IsNumber = {`Builtin` 'Number.is' 2}
Abs      = {`Builtin` 'Number.abs'      2}
local
   FloatPow = {`Builtin` 'Float.fPow' 3}
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
                '+': {`Builtin` 'Number.\'+\'' 3}
                '-': {`Builtin` 'Number.\'-\'' 3}
                '*': {`Builtin` 'Number.\'*\'' 3}
                '~': {`Builtin` 'Number.\'~\'' 2}
                pow: Pow
                abs: Abs)
