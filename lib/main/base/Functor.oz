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

local
   FunctorID = {Boot_Name.newUnique functorID}

   fun {IsFunctor X}
      {IsChunk X} andthen {HasFeature X FunctorID}
   end

   fun {NewFunctor Import Export Apply}
      %--** assert that the arguments have the expected types
      {NewChunk f(FunctorID: unit
                  'import': Import
                  'export': Export
                  'apply': Apply)}
   end

   fun {GetFeatures Info}
      case Info.type of Fs=_|_ then Fs
      else nil
      end
   end
in
   Functor = 'functor'(is:          IsFunctor
                       new:         NewFunctor
                       getFeatures: GetFeatures)
end
