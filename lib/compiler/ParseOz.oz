%%%
%%% Authors:
%%%   Author's name (Author's email address)
%%%
%%% Contributors:
%%%   optional, Contributor's name (Contributor's email address)
%%%
%%% Copyright:
%%%   Organization or Person (Year(s))
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
%%%  Programming Systems Lab, Universitaet des Saarlandes,
%%%  Postfach 15 11 50, D-66041 Saarbruecken, Phone (+49) 681 302-5609
%%%  Author: Leif Kornstaedt <kornstae@ps.uni-sb.de>

\define CFRONTEND

\ifdef CFRONTEND
local
   ParseFile          = {`Builtin` ozparser_parseFile          3}
   ParseVirtualString = {`Builtin` ozparser_parseVirtualString 3}
in
   fun {ParseOzFile FileName Reporter ShowInsert SystemVariables} Res VS in
      Res = {ParseFile FileName options(showInsert: ShowInsert
                                        gumpSyntax: false
                                        systemVariables: SystemVariables
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

   fun {ParseOzVirtualString VS Reporter ShowInsert SystemVariables} Res VS2 in
      Res = {ParseVirtualString VS options(showInsert: ShowInsert
                                           gumpSyntax: false
                                           systemVariables: SystemVariables
                                           errorOutput: ?VS2)}
      case Res of parseErrors(N) then
         {Reporter addErrors(N)}
      else skip
      end
      {Reporter userInfo(VS2)}
      Res
   end
end
\else
local
   \insert OzScanner
   \insert OzParser

   class OzFrontEnd from OzScanner OzParser
      prop final
      feat MyReporter
      meth init(Reporter ShowInsert)
         OzScanner, init(ShowInsert false)
         OzParser, init(self)
         self.MyReporter = Reporter
      end
      meth parseFile(FileName ?Result)
         filename <- {String.toAtom {VirtualString.toString FileName}}
         try Status in
            OzScanner, scanFile(FileName)
            OzParser, parse(file(?Result) ?Status)
            OzScanner, close()
            case Status then skip
            else Result = parseErrors(unit)
            end
         catch gump(fileNotFound _) then
            Result = fileNotFound
         end
      end
      meth parseVirtualString(VS ?Result) Status in
         filename <- 'nofile'
         OzScanner, scanVirtualString(VS)
         OzParser, parse(file(?Result) ?Status)
         case Status then skip
         else Result = parseErrors(unit)
         end
         OzScanner, close()
      end
      meth reportError(C K M)
         {self.MyReporter error(coord: C kind: K msg: M.1)}
      end
      meth warn(C K M)
         {self.MyReporter warn(coord: C kind: K msg: M.1)}
      end
   end
in
   fun {ParseOzFile FileName Reporter ShowInsert} FrontEnd Res in
      FrontEnd = {New OzFrontEnd init(Reporter ShowInsert)}
      Res = {FrontEnd parseFile(FileName $)}
      case Res of fileNotFound then
         {Reporter error(kind: 'compiler directive error'
                         msg: 'could not open file "'#FileName#
                              '" for reading')}
      else skip
      end
      Res
   end

   fun {ParseOzVirtualString VS Reporter ShowInsert} FrontEnd in
      FrontEnd = {New OzFrontEnd init(Reporter ShowInsert)}
      {FrontEnd parseVirtualString(VS $)}
   end
end
\endif
