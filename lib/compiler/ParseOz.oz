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

local
   ParseFile          = Parser.'file'
   ParseVirtualString = Parser.'virtualString'
in
   fun {ParseOzFile FileName Reporter GetSwitch Defines}
      Res#Messages = {ParseFile FileName
                      options(gumpSyntax: {GetSwitch gump}
                              systemVariables: {GetSwitch system}
                              defines: Defines)}
   in
      {ForAll {Reverse Messages} Reporter}
      case Res of fileNotFound then
         {Reporter error(kind: 'compiler directive error'
                         msg: ('could not open file "'#FileName#
                               '" for reading'))}
      else skip
      end
      Res
   end

   fun {ParseOzVirtualString VS Reporter GetSwitch Defines}
      Res#Messages = {ParseVirtualString VS
                      options(gumpSyntax: {GetSwitch gump}
                              systemVariables: {GetSwitch system}
                              defines: Defines)}
   in
      {ForAll {Reverse Messages} Reporter}
      Res
   end
end
