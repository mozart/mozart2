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

local
   ParseFile          = {`Builtin` ozparser_parseFile          3}
   ParseVirtualString = {`Builtin` ozparser_parseVirtualString 3}
in
   fun {ParseOzFile FileName Reporter CompilerState}
      Res VS
   in
      Res = {ParseFile FileName
             options(showInsert: {CompilerState getSwitch(showinsert $)}
                     gumpSyntax: {CompilerState getSwitch(gump $)}
                     systemVariables: {CompilerState getSwitch(system $)}
                     defines: {CompilerState getDefines($)}
                     errorOutput: ?VS)}
      case Res of fileNotFound then
         {Reporter userInfo(VS)}
         {Reporter error(kind: 'compiler directive error'
                         msg: ('could not open file "'#FileName#
                               '" for reading'))}
      [] parseErrors(N) then
         {Reporter addErrors(N)}
         {Reporter userInfo(VS)}
      else
         {Reporter userInfo(VS)}
      end
      Res
   end

   fun {ParseOzVirtualString VS Reporter CompilerState}
      Res VS2
   in
      Res = {ParseVirtualString VS
             options(showInsert: {CompilerState getSwitch(showinsert $)}
                     gumpSyntax: {CompilerState getSwitch(gump $)}
                     systemVariables: {CompilerState getSwitch(system $)}
                     defines: {CompilerState getDefines($)}
                     errorOutput: ?VS2)}
      case Res of parseErrors(N) then
         {Reporter addErrors(N)}
      else skip
      end
      {Reporter userInfo(VS2)}
      Res
   end
end
