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

functor $ prop once

import
   System.{gcDo}

export
   dumpThreads:    DumpThreads
   listThreads:    ListThreads
   breakpointAt:   BreakpointAt
   breakpoint:     Breakpoint
   displayDef:     DisplayDef
   displayCode:    DisplayCode
   print:          Print
   printLong:      PrintLong
   procedureCode:  ProcedureCode
   procedureCoord: ProcedureCoord

body

   local
      BIdumpThreads        = {`Builtin` 'Debug.dumpThreads' 0}
      BIprepareDumpThreads = {`Builtin` 'Debug.prepareDumpThreads' 0}
      BIlistThreads        = {`Builtin` 'Debug.listThreads' 1}
      proc {Dummy}
         skip
      end
   in
      proc {DumpThreads}
         {BIprepareDumpThreads}
         {System.gcDo}
         {Dummy} % force GC
         {BIdumpThreads}
      end
      fun {ListThreads}
         {BIprepareDumpThreads}
         {System.gcDo}
         {Dummy} % force GC
         {BIlistThreads}
      end
   end

   BreakpointAt =   {`Builtin` 'Debug.breakpointAt'   4}
   Breakpoint =     {`Builtin` 'Debug.breakpoint'     0}
   DisplayDef =     {`Builtin` 'Debug.displayDef'     2}
   DisplayCode =    {`Builtin` 'Debug.displayCode'    2}
   Print =          {`Builtin` 'Debug.print'          2}
   PrintLong =      {`Builtin` 'Debug.printLong'      2}
   ProcedureCode =  {`Builtin` 'Debug.procedureCode'  2}
   ProcedureCoord = {`Builtin` 'Debug.procedureCoord' 2}

end
