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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor prop once
import
   Module
   Property(get)
   System(printInfo printError)
   Error(msg formatLine printExc)
   OS(putEnv getEnv system)
   Open(file)
   Pickle(saveWithHeader)
   Compiler(engine quietInterface)
   Application(getCmdArgs exit)
define
   \insert 'Compile.oz'
   {Application.exit {BatchCompile {Application.getCmdArgs plain}}}
end
