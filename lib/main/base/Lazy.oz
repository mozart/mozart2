%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

declare
   Lazy
   IsLazy
in

local

   LazyNew = {`Builtin` 'Lazy.new' 2}

   proc {LazyApply P X}
      {LazyNew 1#P X}
   end

   proc {LazyRequest Y X}
      {LazyNew 2#Y X}
   end

   proc {LazyLoad URL X}
      {LazyNew 3#URL X}
   end

   proc {LazyCall T X}
      {LazyNew 4#T X}
   end

in

   IsLazy = {`Builtin` 'Lazy.is'  2}
   Lazy   = lazy(new     : LazyNew
                 is      : IsLazy
                 apply   : LazyApply
                 request : LazyRequest
                 load    : LazyLoad
                 call    : LazyCall
                )
end
