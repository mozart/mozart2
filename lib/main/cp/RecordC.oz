%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1999
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
   BootRecordC(is:           Is
               width:        Width
               tell:         Tell
               tellSize:     TellSize
               '^':          `^`
               hasLabel:     HasLabel
               monitorArity: MonArity)
   at 'x-oz://boot/RecordC'
   Space(is)

export
   Is Width
   Tell TellSize
   HasLabel MonitorArity ReflectArity
   '^': `^`

define

   {Wait Space.is}

   proc {MonitorArity R P S}
      U
   in
      {MonArity R U S}
      proc {P} U=unit end
   end

   proc {ReflectArity R S}
      {MonArity R unit S}
   end

end
