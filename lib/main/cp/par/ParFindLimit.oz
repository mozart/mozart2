%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de/
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

export
   find: FindLimit

prepare

   fun {NextPower N M}
      if N=<{Pow 10.0 M} then {Pow 10.0 M} else {NextPower N M+1.0} end
   end

   fun {NextIntegral N P I}
      if N=<P*I then P*I#I else {NextIntegral N P I+1} end
   end

   Scalings = [0.1  # 5
               0.15 # 6
               0.2  # 4
               0.25 # 5
               0.3  # 6
               0.4  # 4
               0.5  # 5
               0.6  # 6
               0.7  # 7
               0.75 # 5
               0.8  # 4
               1.0  # 5]

   fun {FindScale V SV#ST|Sr}
      if V=<SV then SV#ST
      else {FindScale V Sr}
      end
   end

   fun {FindLimit MaxVal}
      Power = {NextPower MaxVal 1.0}
      Val#T = {FindScale MaxVal / Power Scalings}
   in
      Val*Power # T
   end

end
