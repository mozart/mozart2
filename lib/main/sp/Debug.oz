%%%
%%% Authors:
%%%   Ralf Scheidhauer (scheidhr@ps.uni-sb.de)
%%%
%%% Contributors:
%%%   Benjamin Lorenz (lorenz@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Ralf Scheidhauer, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local

   BIdumpThreads = {`Builtin` 'Debug.dumpThreads' 0}
   BIlistThreads = {`Builtin` 'Debug.listThreads' 1}

   local
      proc {Dummy} skip end
   in
      proc {DumpThreads}
         {System.gcDo}
         {Dummy} % force GC
         {BIdumpThreads}
      end
      proc {ListThreads ?Ts}
         {System.gcDo}
         {Dummy} % force GC
         {BIlistThreads ?Ts}
      end
   end

in

   Debug = debug(dumpThreads:  DumpThreads
                 listThreads:  ListThreads
                 breakpointAt: {`Builtin` 'Debug.breakpointAt' 4}
                 breakpoint:   {`Builtin` 'Debug.breakpoint'   0}
                 displayCode:  {`Builtin` 'Debug.displayCode'  2})

end
