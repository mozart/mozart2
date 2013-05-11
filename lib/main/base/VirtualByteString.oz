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

VirtualByteString = virtualByteString(
   is: IsVirtualByteString
   toCompactByteString: Boot_VirtualByteString.toCompactByteString
   toList: fun {$ VBS}
              {Boot_VirtualByteString.toByteList VBS nil}
           end
   toListWithTail: Boot_VirtualByteString.toByteList
   length: Boot_VirtualByteString.length
)
