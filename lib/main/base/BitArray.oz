%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%   $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

declare
BitArray IsBitArray
in

IsBitArray = {`Builtin` 'BitArray.is' 2}

BitArray =
bitArray(new:              {`Builtin` 'BitArray.new'              3}
         is:               IsBitArray
         set:              {`Builtin` 'BitArray.set'              2}
         clear:            {`Builtin` 'BitArray.clear'            2}
         test:             {`Builtin` 'BitArray.test'             3}
         low:              {`Builtin` 'BitArray.low'              2}
         high:             {`Builtin` 'BitArray.high'             2}
         clone:            {`Builtin` 'BitArray.clone'            2}
         'or':             {`Builtin` 'BitArray.or'               2}
         and:              {`Builtin` 'BitArray.and'              2}
         nimpl:            {`Builtin` 'BitArray.nimpl'            2}
         disjoint:         {`Builtin` 'BitArray.disjoint'         3}
         card:             {`Builtin` 'BitArray.card'             2}
         toList:           {`Builtin` 'BitArray.toList'           2}
         complementToList: {`Builtin` 'BitArray.complementToList' 2})
