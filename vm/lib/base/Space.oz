%%%
%%% Authors:
%%%   Sébastien Doeraene <sjrdoeraene@gmail.com>
%%%
%%% Copyright:
%%%   Sébastien Doeraene, 2012
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
Space = space(
   new: Boot_Space.new
   is: Boot_Space.is
   ask: Boot_Space.ask
   askVerbose: Boot_Space.askVerbose
   merge: Boot_Space.merge
   clone: Boot_Space.clone
   commit: Boot_Space.commit
   choose: Boot_Space.choose
)
