%%%
%%% Authors:
%%%   Per Brand (perbrand@sics.se)
%%%
%%% Copyright:
%%%   Per Brand, 1998
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


functor

import
   Fault(installHW
         deInstallHW
         getEntityCond)
   at 'x-oz://boot/Fault'

export
   install:           Install
   deinstall:         Deinstall
   getEntityCond:     GetEntityCond

define
   Install       = Fault.installHW
   Deinstall     = Fault.deInstallHW
   GetEntityCond = Fault.getEntityCond

end
