%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Michael Mehl (mehl@dfki.de)
%%%   Ralf Scheidhauer (scheidhr@dfki.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
%%%   Michael Mehl, 1997
%%%   Ralf Scheidhauer, 1997
%%%   Christian Schulte, 1997
%%%   Denys Duchier, 1998
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

export
   printError:           PrintError
   printInfo:            PrintInfo
   showError:            ShowError
   showInfo:             ShowInfo
   print:                Print
   show:                 Show
   eq:                   SystemEq
   nbSusps:              SystemNbSusps
   printName:            PrintName
   gcDo:                 GcDo
   apply:                Apply
   tellRecordSize:       TellRecordSize
   valueToVirtualString: ValueToVirtualString
   exit:                 Exit

   %%
   %% Only relevant for OPI, direct use is deprecated
   %%

   'Show':            Show
   'Print':           Print
   'Exit':            Exit

body

   Show            = {`Builtin` 'Show'            1}
   Print           = {`Builtin` 'Print'           1}
   Exit            = {`Builtin` shutdown          1}

   %%
   %% Printing
   %%
   PrintInfo  = {`Builtin` 'System.printInfo'  1}
   proc {ShowInfo V}
      {PrintInfo V # '\n'}
   end
   PrintError = {`Builtin` 'System.printError' 1}
   proc {ShowError V}
      {PrintError V # '\n'}
   end

   SystemEq             = {`Builtin` 'System.eq' 3}
   SystemNbSusps        = {`Builtin` 'System.nbSusps' 2}
   PrintName            = {`Builtin` 'System.printName' 2}
   GcDo                 = {`Builtin` 'System.gcDo' 0}
   Apply                = {`Builtin` 'System.apply' 2}
   TellRecordSize       = `tellRecordSize`
   ValueToVirtualString = {`Builtin` 'System.valueToVirtualString' 4}

end
