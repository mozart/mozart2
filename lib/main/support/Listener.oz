%%%
%%% Author:
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
%%%   http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%   http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
export
   'class': Listener
define
   class Listener
      prop locking
      attr Port: unit Narrator: unit ServerThread: unit
      meth init(NarratorObject Serve)
         lock Ms in
            Port <- {NewPort Ms}
            {NarratorObject register(@Port)}
            Narrator <- NarratorObject
            thread
               ServerThread <- {Thread.this}
               {self Serve(Ms)}
            end
         end
      end
      meth close()
         lock
            case @Narrator of unit then skip
            else
               {Thread.terminate @ServerThread}
               {Send @Port close()}
               {@Narrator unregister(@Port)}
               Narrator <- unit
               Port <- unit
               ServerThread <- unit
            end
         end
      end
      meth getNarrator($)
         @Narrator
      end
      meth getPort($)
         @Port
      end
   end
end
