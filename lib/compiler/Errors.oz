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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

{ErrorRegistry.put compiler
 fun {$ Exc}
    E = {Error.dispatch Exc}
    T = 'compiler engine error'
 in
    case E of compiler(internal X) then
       {Error.format T
        'Internal compiler error'
        [hint(l: 'Additional information' m: oz(X))
         line('please send a bug report to oz-bugs@ps.uni-sb.de')]
        Exc}
    elseof compiler(invalidQuery M) then
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
    elseof compiler(evalExpression VS Ms) then
       {Error.format T
        'Erroneous expression in Compiler.evalExpression'
        hint(l: 'Expression' m: VS)|
        {Map Ms
         fun {$ M}
            case M of error(kind: Kind msg: Msg ...) then line(Kind#': '#Msg)
            elseof warn(kind: Kind msg: Msg ...) then line(Kind#': '#Msg)
            else unit
            end
         end}
        Exc}
    elseof compiler(malformedSyntaxTree) then
       {Error.format T
        'Malformed syntax tree'
        nil
        Exc}
    elseof compiler(malformedSyntaxTree X) then
       {Error.format T
        'Malformed syntax tree'
        [hint(l: 'Matching' m: oz(X))]
        Exc}
    else
       {Error.formatGeneric T Exc}
    end
 end}
