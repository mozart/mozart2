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
%%%   $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%   $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

declare Functor `NewFunctor` in
local
   local
      NewUniqueName = {`Builtin` 'NewUniqueName' 2}
   in
      `functorID` = {NewUniqueName 'functorID'}
   end

   fun {IsFunctor X}
      {IsChunk X} andthen {HasFeature X `functorID`}
   end

   fun {NewFunctor Import Export Apply}
      %--** assert that the arguments have the expected types
      {NewChunk f(`functorID`: unit
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
   `NewFunctor` = NewFunctor

   Functor = 'functor'(is:          IsFunctor
                       new:         NewFunctor
                       getFeatures: GetFeatures)
end
