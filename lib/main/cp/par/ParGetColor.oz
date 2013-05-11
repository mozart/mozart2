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
%%%    http://www.mozart-oz.org/
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor
export
   get: GetColor
prepare
   ColorTab = colors(c(106 90 205) c(46 139 87) c(205 133 63) c(176 48 96)
                     c(250 235 215) c(154 205 50) c(173 216 230) c(70 130 180)
                     c(139 69 19) c(143 188 143) c(188 143 143) c(189 183 107)
                     c(100 149 237) c(233 150 122) c(255 127 80) c(184 134 11)
                     c(178 34 34) c(0 100 0) c(222 184 135) c(95 158 160)
                     c(255 228 196))

   NoColors = {Width ColorTab}

   fun {GetColor N}
      ColorTab.((N mod NoColors) + 1)
   end

end
