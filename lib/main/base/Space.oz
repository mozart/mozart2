%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
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


declare
   Space
   IsSpace
in

IsSpace = {`Builtin` 'IsSpace' 2}

Space = space(is:         IsSpace
              new:        {`Builtin` 'Space.new'        2}
              ask:        {`Builtin` 'Space.ask'        2}
              askVerbose: {`Builtin` 'Space.askVerbose' 2}
              clone:      {`Builtin` 'Space.clone'      2}
              merge:      {`Builtin` 'Space.merge'      2}
              inject:     {`Builtin` 'Space.inject'     2}
              commit:     {`Builtin` 'Space.commit'     2})
