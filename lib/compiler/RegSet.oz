%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

RegSet = regSet(new:              {`Builtin` 'RegSet.new'              3}
                copy:             {`Builtin` 'RegSet.copy'             2}
                adjoin:           {`Builtin` 'RegSet.adjoin'           2}
                remove:           {`Builtin` 'RegSet.remove'           2}
                member:           {`Builtin` 'RegSet.member'           3}
                union:            {`Builtin` 'RegSet.union'            2}
                intersect:        {`Builtin` 'RegSet.intersect'        2}
                subtract:         {`Builtin` 'RegSet.subtract'         2}
                toList:           {`Builtin` 'RegSet.toList'           2}
                complementToList: {`Builtin` 'RegSet.complementToList' 2})
