%%%
%%% Authors:
%%%   kennytm
%%%
%%% Copyright:
%%%   Kenny Chan, 2014
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
    System(gcDo)

export
    Return

define
    Return = gcDebug([
        gcDebugTest(proc {$}
            {System.gcDo}
            {System.gcDo}   % <-- should not crash at this point.
        end)
    ])

end

