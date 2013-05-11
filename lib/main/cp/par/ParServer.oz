%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org/
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

export
   new:     NewServer
   newPort: NewServerPort

define

   fun {NewServer C M}
      S P={Port.new S} PS
   in
      thread
         {ForAll S {New {Class.new [C] 'attr' 'feat'(server:PS) nil} M}}
      end
      proc {PS M}
         {Port.send P M}
      end
      PS
   end

   fun {NewServerPort C M}
      S P={Port.new S}
   in
      thread
         {ForAll S {New {Class.new [C] 'attr' 'feat'(server:P) nil} M}}
      end
      P
   end

end
