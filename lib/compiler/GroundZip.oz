%%%
%%% Author:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1999
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%% This is an extremely poor compression module for Oz data structures.
%%% It makes sharing in ground data structures explicit

functor
export Zip
define

   local
      fun {IsIn KXs K}
         case KXs of nil then false
         [] KX|KXr then
            KX.1==K orelse {IsIn KXr K}
         end
      end
      fun {Get (K1|X)|KXr K2}
         if K1==K2 then X else {Get KXr K2} end
      end
   in
      class AnyTab
         attr kxs:nil
         meth init skip end
         meth isIn(K $)
            {IsIn @kxs K}
         end
         meth put(K X)
            kxs <- (K|X)|@kxs
         end
         meth get(K $)
            {Get @kxs K}
         end
      end
   end

   RecordTab = {New AnyTab init}
   IntTab = {Dictionary.new}

   fun {Zip X}
      if {IsInt X} then
         if {Not {Dictionary.member IntTab X}} then
            {Dictionary.put IntTab X X}
         end
         {Dictionary.get IntTab X}
      elseif {IsLiteral X} then X
      elseif {IsRecord X} then
         if {RecordTab isIn(X $)} then skip else T in
            {RecordTab put(X T)}
            T={Record.map X Zip}
         end
         {RecordTab get(X $)}
      else X
      end
   end
end
