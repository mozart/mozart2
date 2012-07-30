%%%
%%% Authors:
%%%   Kenny Chan <kennytm@gmail.com>
%%%
%%% Copyright:
%%%   Kenny Chan, 2012
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


%%
%% Module
%%

local
   /* It used to be that atoms could not contain '\0' (the null character).
    * So this function tested against any 0 in the string.
    * As of Mozart 2.0, any string can be converted to an atom, so this
    * function always returns true.
    */
   fun {UnicodeStringIsAtom Is}
      true
   end

   fun {UnicodeStringToString UStr}
      BS = {ByteString.encode [latin1] UStr}
   in
      {ByteString.toString BS}
   end
in
   UnicodeString = unicodeString(
      is: IsUnicodeString
      toAtom: UnicodeStringToAtom
      isAtom: UnicodeStringIsAtom
      %toInt: UnicodeStringToInt
      %isInt: Boot_String.isInt
      %toFloat: UnicodeStringToFloat
      %isFloat: Boot_String.isFloat
      toString: UnicodeStringToString

      charAt: Boot_String.charAt
      append: Boot_String.append
      slice: Boot_String.slice
      search: Boot_String.search
      isPrefix: fun {$ X Y} {Boot_String.hasPrefix Y X} end
      isSuffix: fun {$ X Y} {Boot_String.hasSuffix Y X} end

      length: Boot_VirtualString.length
   )
end
