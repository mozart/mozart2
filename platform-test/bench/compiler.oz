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
   Compiler
export
   Return

body
   Return = compiler([
                      simple(proc {$}
                                E = {New Compiler.engine init()}
                             in
                                {For 1 100 1
                                 proc {$ I}
                                    {E enqueue(feedVirtualString('declare X='#I))}
                                 end}
                                {Wait {E enqueue(ping($))}}
                             end
                             keys:[bench compiler]
                             bench:1)
                     ])
end
