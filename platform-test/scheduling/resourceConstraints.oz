%%%
%%% Authors:
%%%   Joerg Wuertz (wuertz@dfki.de)
%%%
%%% Copyright:
%%%   Joerg Wuertz, 1997, 1998
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

proc {ResourceConstraintEF Start Dur ExclusiveTasks}
   {Schedule.serialized ExclusiveTasks Start Dur}
end
