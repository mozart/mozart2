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
   /*
   BootRecordC(is:           Is
               width:        Width
               tell:         Tell
               tellSize:     TellSize
               '^':          `^`
               hasLabel:     HasLabel
               monitorArity: MonArity)
   at 'x-oz://boot/RecordC'
   */
   Space(is)

export
   Is Width
   Tell TellSize
   HasLabel MonitorArity ReflectArity
   '^': `^`

define

   {Wait Space.is}

/*
   proc {MonitorArity R P S}
      U
   in
      {MonArity R U S}
      proc {P} U=unit end
   end

   proc {ReflectArity R S}
      {MonArity R unit S}
   end
*/

   % Temporary implementation that works for Records

   fun {Is X}
      {IsRecord X}
   end

   fun {Width R}
      {Record.width R}
   end

   proc {Tell L ?R}
      {Exception.raiseError kernel(notImplemented 'RecordC.tell')}
   end

   proc {TellSize L ?R}
      {Exception.raiseError kernel(notImplemented 'RecordC.tellSize')}
   end

   fun {HasLabel R}
      if {IsDet R} then
         {Label R _} % for the type error
         true
      else
         false
      end
   end

   proc {MonitorArity R ?P ?S}
      S = {ReflectArity R}
      proc {P} skip end
   end

   fun {ReflectArity R}
      {Record.arity R}
   end

   fun {`^` R F}
      R.F
   end

end
