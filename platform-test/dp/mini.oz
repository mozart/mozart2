%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1998
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

functor $

import
   Remote(manager)
   OS(uName)
export
   Return

body
   Return=
   dp([
       mini(
            proc {$}
               S={New Remote.manager init(host:{OS.uName}.nodename)}
            in
               {S ping}
               {S apply(url:'' functor
                               export
                                  Hallo
                               define
                                  Hallo=hallo
                               end $)}.hallo=hallo
               {S ping}
               {S close}
            end
            keys:[remote])
      ])
end
