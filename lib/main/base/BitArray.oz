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
%%%   http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%   http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

BitArray =
bitArray(new:              Boot_BitArray.new
         is:               IsBitArray
         set:              Boot_BitArray.set
         clear:            Boot_BitArray.clear
         test:             Boot_BitArray.test
         low:              Boot_BitArray.low
         high:             Boot_BitArray.high
         clone:            Boot_BitArray.clone
         disj:             Boot_BitArray.disj
         conj:             Boot_BitArray.conj
         nimpl:            Boot_BitArray.nimpl
         disjoint:         Boot_BitArray.disjoint
         card:             Boot_BitArray.card
         toList:           Boot_BitArray.toList
         complementToList: Boot_BitArray.complementToList)
