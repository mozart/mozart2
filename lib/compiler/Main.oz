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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor
import
   Debug                         at 'x-oz://boot/Debug'
   Parser                        at 'x-oz://boot/Parser'
   CompilerSupport(nameVariable) at 'x-oz://boot/CompilerSupport'
   Property(get condGet)
   Error(extendedVSToVS exceptionToMessage registerFormatter printException)
   Type(ask)
   Narrator('class')
   ErrorListener('class')
   PrintName(is)
   Unnester(makeExpressionQuery unnestQuery)
   Core(userVariable output)
   CodeStore('class')
   Assembler(internalAssemble assemble)
\ifndef NO_GUMP
   Gump(makeProductionTemplates)
   ProductionTemplates(default)
\endif
export
   Engine
   Interface
   ParseOzFile
   ParseOzVirtualString
   Assemble
   CodeStoreClass
   EvalExpression
   VirtualStringToValue
define
   local
      \insert FormatStrings
      \insert CheckTupleSyntax
   in
      \insert CompilerClass
      \insert ParseOz
      \insert Interface
      \insert Abstractions
      \insert Errors
   end
   CodeStoreClass = CodeStore.'class'
   Assemble = Assembler.assemble
end
