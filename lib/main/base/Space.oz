%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
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


Space = space(is:         IsSpace
              new:        Boot_Space.new
              ask:        Boot_Space.ask
              askVerbose: Boot_Space.askVerbose
              clone:      Boot_Space.clone
              merge:      Boot_Space.merge
              inject:     Boot_Space.inject
              commit:     Boot_Space.commit)
