%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Contributor:
%%%   Christian Schulte <schulte@dfki.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
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

functor
import
   Debug                         at 'x-oz://boot/Debug'
   Parser                        at 'x-oz://boot/Parser'
   CompilerSupport(nameVariable) at 'x-oz://boot/CompilerSupport'
   Property(get condGet)
   System(valueToVirtualString)
   Error   %--**(formatPos formatExc dispatch format formatGeneric)
   ErrorRegistry(put)
   Type   %--**(ask)
   Narrator('class')
   Listener('class')
   ErrorListener('class')
   PrintName(is)
   Builtins   %--**(getInfo)
   Unnester   %--**(makeExpressionQuery unnestQuery)
   Core.variable
   Assembler   %--**(internalAssemble assemble)
   RunTime   %--**

\ifndef NO_GUMP
   Gump(makeProductionTemplates)
   ProductionTemplates(default)
\endif
export
   Engine
   ParseOzFile
   ParseOzVirtualString
   GenericInterface
   QuietInterface
   EvalExpression
   VirtualStringToValue
   Assemble
define
   local
      \insert FormatStrings
      \insert CheckTupleSyntax
   in
      \insert CompilerClass
      \insert ParseOz
      \insert GenericInterface
      \insert QuietInterface
      \insert Abstractions
      \insert Errors
   end
   Assemble = Assembler.assemble
end
