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
   \insert 'Gump.env'
   = IMPORT.'Gump'
in
   local
      \insert 'compiler/InsertAll.oz'

      GetOPICompiler = {`Builtin` 'getOPICompiler' 1}

      Compiler = compiler(compilerClass: CompilerClass
                          genericInterface: CompilerInterfaceGeneric
                          quietInterface: CompilerInterfaceQuiet
                          getOPICompiler: GetOPICompiler)
   in
      \insert 'Compiler.env'
   end
end
