%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


declare
   Char IsChar
in


%%
%% Global
%%
IsChar = {`Builtin` 'Char.is' 2}


%%
%% Modules
%%
Char = char(is:       IsChar
            isAlpha:  {`Builtin` 'Char.isAlpha'  2}
            isUpper:  {`Builtin` 'Char.isUpper'  2}
            isLower:  {`Builtin` 'Char.isLower'  2}
            isDigit:  {`Builtin` 'Char.isDigit'  2}
            isXDigit: {`Builtin` 'Char.isXDigit' 2}
            isAlNum:  {`Builtin` 'Char.isAlNum'  2}
            isSpace:  {`Builtin` 'Char.isSpace'  2}
            isGraph:  {`Builtin` 'Char.isGraph'  2}
            isPrint:  {`Builtin` 'Char.isPrint'  2}
            isPunct:  {`Builtin` 'Char.isPunct'  2}
            isCntrl:  {`Builtin` 'Char.isCntrl'  2}
            toUpper:  {`Builtin` 'Char.toUpper'  2}
            toLower:  {`Builtin` 'Char.toLower'  2}
            toAtom:   {`Builtin` 'Char.toAtom'   2}
            type:     {`Builtin` 'Char.type'     2})
