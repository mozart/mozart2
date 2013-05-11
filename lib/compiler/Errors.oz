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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

{Error.registerFormatter compiler
 fun {$ E}
    BugReport = 'Please send bug report to bugs@mozart-oz.org'
    T = 'compiler engine error'
 in
    case E of compiler(internal X) then
       error(kind: T
             msg: 'Internal compiler error'
             items: [hint(l: 'Additional information' m: oz(X))
                     line(BugReport)])
    elseof compiler(invalidQuery M) then
       error(kind: T
             msg: 'Invalid query'
             items: [hint(l: 'Query' m: oz(M))])
    elseof compiler(invalidQuery M I A) then
       error(kind: T
             msg: 'Ill-typed query argument'
             items: [hint(l: 'Query' m: oz(M))
                     hint(l: 'At argument' m: I)
                     hint(l: 'Expected type' m: A)])
    elseof compiler(evalExpression VS Ms) then
       error(kind: T
             msg: 'Erroneous expression in Compiler.evalExpression'
             items: (hint(l: 'Expression' m: VS)|
                     {Map Ms
                      fun {$ M}
                         case M of error(kind: Kind msg: Msg ...) then
                            line(Kind#': '#Msg)
                         elseof warn(kind: Kind msg: Msg ...) then
                            line(Kind#': '#Msg)
                         else unit
                         end
                      end}))
    elseof compiler(malformedSyntaxTree) then
       error(kind: T
             msg: 'Malformed syntax tree')
    elseof compiler(malformedSyntaxTree X) then
       error(kind: T
             msg: 'Malformed syntax tree'
             items: [hint(l: 'Matching' m: oz(X))])
    else
       error(kind: T
             items: [line(oz(E))])
    end
 end}
