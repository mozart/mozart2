%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 1997
%%%   Christian Schulte, 1997
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

\ifndef DumpIntroLoaded

\switch -threadedqueries

\define DumpIntroLoaded

declare
  Base Standard Dump
in

declare
   \insert 'Base.env'
   = Base
in

declare
   \insert 'Standard.env'
   = Standard
in

local
   \insert 'DumpSettings.oz'
   Load = {`Builtin` load 2}
in
   Base     = {Load ComDIR#'Base'#ComEXT}
   Standard = {Load ComDIR#'Standard'#ComEXT}
end

local
   \insert 'DumpSettings.oz'
   SmartSave = {`Builtin` smartSave          6}
   SPI       = {`Builtin` 'System.printInfo' 1}
   `unit`    = {{`Builtin` 'NewUniqueName' 2} 'unit'}
   proc {ALL Xs P}
      case Xs of X|Xr then {P X} {ALL Xr P}
      [] nil then skip
      else skip
      end
   end
in
   proc {Dump X Name}
      {{`Builtin` 'SystemSetPrint'  1} print(depth: 100 width: 100)}
      {{`Builtin` 'SystemSetErrors' 1} print(depth: 100 width: 100)}

      ExtNAME = Name   # ComEXT
      ExtURL  = ComURL # ExtNAME
      ExtPATH = ComDIR # ExtNAME
   in
      case {SmartSave X ExtPATH ExtURL unit _} of nil then skip
      elseof Xs then
         {ALL Xs {`Builtin` 'Wait' 1}}
         {SmartSave X ExtPATH ExtURL unit _ nil}
      end
      {SPI 'Saved: '#ExtURL#'\n'}
   end
end

\endif
