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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   ParseFile          = Parser.'file'
   ParseVirtualString = Parser.'virtualString'

   local
      Prefixes = ["`SWITCHNAME'"#"switch name"
                  "`OZATOM'"#"atom"
                  "`ATOM_LABEL'"#"atom label"
                  "`OZFLOAT'"#"float"
                  "`OZINT'"#"integer"
                  "`STRING'"#"string"
                  "`AMPER'"#"`&'"
                  "`VARIABLE'"#"variable"
                  "`VARIABLE_LABEL'"#"variable label"
                  "`DEFAULT'"#"`<='"
                  "`CHOICE'"#"`[]'"
                  "`LDOTS'"#"`...'"
                  "`OOASSIGN'"#"`<-'"
                  "`COMPARE'"#"comparison operator"
                  "`FDCOMPARE'"#"finite domain comparison operator"
                  "`FDIN'"#"finite domain inclusion operator"
                  "`ADD'"#"`+' or `-'"
                  "`FDMUL'"#"`*' or `/'"
                  "`OTHERMUL'"#"`div' or `mod'"
                  "`FALSE_LABEL'"#"`false' as label"
                  "`TRUE_LABEL'"#"`true' as label"
                  "`UNIT_LABEL'"#"`unit' as label"
                  "`DOTINT'"#"`.' followed by an integer"
                  "`DEREFF'"#"`!!'"
                  "`ENDOFFILE'"#"end-of-file"
                  "`REGEX'"#"regular expression"
                  "`REDUCE'"#"`=>'"
                  "`SEP'"#"`//'"]

      fun {DetachPrefix P S}
         case P of C|Cr then
            case S of !C|Sr then {DetachPrefix Cr Sr}
            else false
            end
         [] nil then
            S
         end
      end

      fun {BeautifyPrefix Ps S}
         case Ps of X|Pr then P#R = X in
            case {DetachPrefix P S} of false then {BeautifyPrefix Pr S}
            elseof Rest then {Append R {Beautify Rest}}
            end
         [] nil then S
         end
      end

      fun {Beautify S}
         case S of nil then ""
         [] C|Cr then
            case C of &` then
               case Cr of &_|Crr then KW Rest in   % e.g., "`_case_'"
                  {List.takeDropWhile Crr fun {$ C} C \= &_ end ?KW ?Rest}
                  case Rest of &_|&'|NewRest then
                     &`|{Append KW &'|{Beautify NewRest}}
                  else
                     C|{Beautify Cr}
                  end
               elseof &'|Crr then Op Rest in   % e.g., "`'+''"
                  {List.takeDropWhile Crr fun {$ C} C \= &' end ?Op ?Rest}
                  case Rest of &'|&'|NewRest then
                     &`|{Append Op &'|{Beautify NewRest}}
                  else
                     C|{Beautify Cr}
                  end
               else {BeautifyPrefix Prefixes S}
               end
            else C|{Beautify Cr}
            end
         end
      end
   in
      proc {Output Messages Reporter ShowInsert}
         {ForAll {Reverse Messages}
          proc {$ M}
             case {Label M} of error then
                case {CondSelect M kind unit} of 'parse error' then
                   {Reporter {AdjoinAt M msg {Beautify {Atom.toString M.msg}}}}
                else
                   {Reporter M}
                end
             [] warn then
                {Reporter M}
             [] logInsert then FileName Coord in
                FileName = M.1
                Coord = {CondSelect M 2 unit}
                {Reporter tell(insert(FileName Coord))}
                if ShowInsert then
                   {Reporter tell(info('%%%         inserted file "'#
                                       FileName#'"\n' Coord))}
                end
             end
          end}
      end
   end
in
   fun {ParseOzFile FileName Reporter GetSwitch Defines}
      Res#Messages = {ParseFile FileName
                      options(gump: {GetSwitch gump}
                              allowdeprecated: {GetSwitch allowdeprecated}
                              defines: Defines)}
   in
      {Output Messages Reporter {GetSwitch showinsert}}
      case Res of fileNotFound then
         {Reporter error(kind: 'compiler directive error'
                         msg: ('could not open file "'#FileName#
                               '" for reading'))}
         parseError
      else
         Res
      end
   end

   fun {ParseOzVirtualString VS Reporter GetSwitch Defines}
      Res#Messages = {ParseVirtualString VS
                      options(gump: {GetSwitch gump}
                              allowdeprecated: {GetSwitch allowdeprecated}
                              defines: Defines)}
   in
      {Output Messages Reporter {GetSwitch showinsert}}
      Res
   end
end
