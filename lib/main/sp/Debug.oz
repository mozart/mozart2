%%%
%%% Authors:
%%%   Ralf Scheidhauer (scheidhr@ps.uni-sb.de)
%%%
%%% Contributors:
%%%   Benjamin Lorenz (lorenz@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
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
   proc {Dummy}
      skip
   end
in
   functor $ prop once

   import
      System.{gcDo}

      Debug.{dumpThreads
             prepareDumpThreads
             listThreads
             breakpointAt
             breakpoint
             procedureCoord
            }
         from 'x-oz://boot/Debug'

   export
      dumpThreads:    DumpThreads
      listThreads:    ListThreads
      breakpointAt:   BreakpointAt
      breakpoint:     Breakpoint
      procedureCoord: ProcedureCoord

   body

      proc {DumpThreads}
         {Debug.prepareDumpThreads}
         {System.gcDo}
         {Dummy} % force GC
         {Debug.dumpThreads}
      end

      fun {ListThreads}
         {Debug.prepareDumpThreads}
         {System.gcDo}
         {Dummy} % force GC
         {Debug.listThreads}
      end

      BreakpointAt =   Debug.breakpointAt
      Breakpoint =     Debug.breakpoint
      ProcedureCoord = Debug.procedureCoord

   end

end
