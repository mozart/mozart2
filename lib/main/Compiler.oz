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
%%%   $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%   $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

\ifdef LILO

functor $

import
   SP.{System  = 'System'
       Show    = 'Show'
       Foreign = 'Foreign'
       Error   = 'Error'}

   CP.{FS        = 'FS'
       FD        = 'FD'
       SearchOne = 'SearchOne'
       `GenSumC` = '`GenSumC`'}

   Gump

export
   'Compiler': Compiler

body
   \insert 'compiler/InsertAll.oz'
in
   Compiler = compiler(engine: CompilerEngine
                       compilerClass: CompilerEngine   %--** deprecated
                       genericInterface: GenericInterface
                       quietInterface: QuietInterface
                       evalExpression: EvalExpression
                       virtualStringToValue: VirtualStringToValue
                       assemble: DoAssemble)
end

\else

fun instantiate {$ IMPORT}
   \insert 'SP.env'
   = IMPORT.'SP'
   \insert 'CP.env'
   = IMPORT.'CP'
\ifndef OZM
   \insert '../tools/Gump.env'
   = IMPORT.'Gump'
\endif
in
   local
      \insert 'compiler/InsertAll.oz'

      Compiler = compiler(engine: CompilerEngine
                          compilerClass: CompilerEngine   %--** deprecated
                          genericInterface: GenericInterface
                          quietInterface: QuietInterface
                          evalExpression: EvalExpression
                          virtualStringToValue: VirtualStringToValue
                          assemble: DoAssemble)
   in
      \insert 'Compiler.env'
   end
end

\endif
