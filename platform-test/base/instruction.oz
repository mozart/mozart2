%%%
%%% Authors:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%   http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor $ prop once

export Return

body

   Return =
   instruction([testList(suspended(proc {$}
                                      {proc {$ X}
                                          case X of '|'(_ _) then skip
                                          [] f then skip
                                          else skip
                                          end
                                       end '|'(_ _ ...)}
                                   end)
                         keys: [instruction ofs])
                match(equal(fun {$}
                               {fun {$ X}
                                   case X of '|'(_ _) then a
                                   else b
                                   end
                                end '#'(...)}
                            end b)
                      keys: [instruction ofs])])
end
