%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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


%%
%% Modules
%%
Char = char(is:       IsChar
            isAlpha:  Boot_Char.isAlpha
            isUpper:  Boot_Char.isUpper
            isLower:  Boot_Char.isLower
            isDigit:  Boot_Char.isDigit
            isXDigit: Boot_Char.isXDigit
            isAlNum:  Boot_Char.isAlNum
            isSpace:  Boot_Char.isSpace
            isGraph:  Boot_Char.isGraph
            isPrint:  Boot_Char.isPrint
            isPunct:  Boot_Char.isPunct
            isCntrl:  Boot_Char.isCntrl
            toUpper:  Boot_Char.toUpper
            toLower:  Boot_Char.toLower
            toAtom:   Boot_Char.toAtom
            type:     Boot_Char.type)
