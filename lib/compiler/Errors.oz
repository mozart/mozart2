%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
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

{ErrorRegistry.put

 compiler

 fun {$ Exc}
    E = {Error.dispatch Exc}
    T = 'compiler engine error'
 in
    case E
    of compiler(invalidQuery M) then
       {Error.format T
        'Invalid query'
        [hint(l: 'Query' m: oz(M))]
        Exc}
    elseof compiler(invalidQuery M I A) then
       {Error.format T
        'Ill-typed query argument'
        [hint(l: 'Query' m: oz(M))
         hint(l: 'At argument' m: I)
         hint(l: 'Expected type' m: A)]
        Exc}
    elseof compiler(register P) then
       {Error.format T
        'Trying to register a non-port'
        [hint(l: 'Argument' m: oz(P))]
        Exc}
    else
       {Error.formatGeneric T Exc}
    end
 end}
