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
   Int IsInt IsNat IsOdd IsEven IntToFloat IntToString
in


%%
%% Run time library
%%
{`runTimePut` 'div' {`Builtin` 'Int.div' 3}}
{`runTimePut` 'mod' {`Builtin` 'Int.mod' 3}}


%%
%% Global
%%
IsInt       = {`Builtin` 'Int.is'       2}
IntToFloat  = {`Builtin` 'Int.toFloat'  2}
IntToString = {`Builtin` 'Int.toString' 2}
fun {IsNat X}  0=<X         end
fun {IsOdd X}  X mod 2 == 1 end
fun {IsEven X} X mod 2 == 0 end


%%
%% Module
%%
Int = int(is:       IsInt
          isNat:    IsNat
          isOdd:    IsOdd
          isEven:   IsEven
          'div':    {`Builtin` 'Int.div' 3}
          'mod':    {`Builtin` 'Int.mod' 3}
          toFloat:  IntToFloat
          toString: IntToString)
