%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1997
%%%   Christian Schulte, 1997
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
   String IsString StringToAtom StringToInt StringToFloat
in


%%
%% Global
%%
IsString      = {`Builtin` 'IsString'      2}
StringToAtom  = {`Builtin` 'StringToAtom'  2}
StringToInt   = {`Builtin` 'StringToInt'   2}
StringToFloat = {`Builtin` 'StringToFloat' 2}


%%
%% Module
%%
String = string(is:      IsString
                isAtom:  {`Builtin` 'String.isAtom'  2}
                toAtom:  StringToAtom
                isInt:   {`Builtin` 'String.isInt'   2}
                toInt:   StringToInt
                isFloat: {`Builtin` 'String.isFloat' 2}
                toFloat: StringToFloat)
