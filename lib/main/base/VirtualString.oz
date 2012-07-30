%%%
%%% Authors:
%%%   Kenny Chan <kennytm@gmail.com>
%%%
%%% Copyright:
%%%   Kenny Chan, 2012
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

VirtualString = virtualString(
   is: IsVirtualString
   toUnicodeString: Boot_VirtualString.toString
   toString: fun {$ V}
                {UnicodeString.toString {Boot_VirtualString.toString V}}
             end
   toAtom: fun {$ V} {UnicodeStringToAtom {Boot_VirtualString.toString V}} end
   toByteString: fun {$ V} {ByteString.make V} end
   length: Boot_VirtualString.length
   %changeSign: ChangeSign
)
