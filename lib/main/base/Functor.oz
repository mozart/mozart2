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

declare Functor in
local
   proc {TypeCheck Info Value}
      case Info.type of Fs=_|_ then
         {Type.ask.recordC Value}
         {ForAll Fs proc {$ F} Value.F = _ end}
      [] nil then skip
      [] value then skip
      elseof T then
         {Type.ask.T Value}
      end
   end

   fun {GetFeatures Info}
      case Info.type of Fs=_|_ then Fs
      else nil
      end
   end
in
   Functor = 'functor'(typeCheck: TypeCheck
                       getFeatures: GetFeatures)
end
