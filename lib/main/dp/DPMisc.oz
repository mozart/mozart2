%%%
%%% Authors:
%%%   Andreas Sundstom (perbrand@sics.se)
%%%
%%% Copyright:
%%%   Andreas Sundstom, 1999
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


functor

import
   DPB at 'x-oz://boot/DPB'
   Misc at 'x-oz://boot/DPMisc'

export
   initIPConnection:  InitIP

define
   %%
   %% Force linking of base library
   %%
   {Wait DPB}

   InitIP = Misc.initIPConnection
end
