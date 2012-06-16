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

IsString = Boot_String.is
StringToAtom = Boot_String.toAtom
%StringToInt = Boot_String.toInt
%StringToFloat = Boot_String.toFloat

String = string(
   is: IsString
   toAtom: StringToAtom
   %isAtom: Boot_String.isAtom
   %toInt: StringToInt
   %isInt: Boot_String.isInt
   %toFloat: StringToFloat
   %isFloat: Boot_String.isFloat
   %token: Boot_String.token
   %tokens: fun {$ S X} ... end
)

