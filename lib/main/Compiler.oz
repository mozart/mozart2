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

      Compiler = compiler(compilerClass: CompilerClass
                          genericInterface: GenericInterface
                          quietInterface: QuietInterface)
   in
      \insert 'Compiler.env'
   end
end
