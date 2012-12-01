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

fun {AtomToCompactString A}
   if {IsAtom A} then
      {VirtualString.toCompactString A}
   else
      {Exception.raiseError kernel(type 'Atom.toCompactString' [A] 'Atom' 1)}
      unit
   end
end

fun {AtomToString A}
   if {IsAtom A} then
      {VirtualString.toString A}
   else
      {Exception.raiseError kernel(type 'Atom.toString' [A] 'Atom' 1)}
      unit
   end
end

Atom = atom(is:              IsAtom
            toCompactString: AtomToCompactString
            toString:        AtomToString)
