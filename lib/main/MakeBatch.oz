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

functor prop once
import
   Module.load
   Property.{get}
   System.{printInfo printError}
   Error.{msg formatLine}
   OS.{putEnv getEnv system unlink tmpnam}
   Open.file
   Pickle.save
   Compiler.{engine quietInterface}
   Syslet.{spec args exit}
body
   Syslet.spec = plain
   \insert BatchCompile
   {Syslet.exit {BatchCompile Syslet.args}}
end
