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

%%
%% Auxiliary procedures used throughout the compiler.
%%

local
   fun {IsIDChar C}
      {Char.isAlNum C} orelse C == &_
   end

   fun {IsQuotedVariable S}
      case S of C1|Cr then
         case C1 == &` andthen Cr == nil then true
         elsecase C1 == 0 then false
         else {IsQuotedVariable Cr}
         end
      [] nil then false
      end
   end
in
   fun {IsPrintName X}
      {IsAtom X} andthen
      local
         S = {Atom.toString X}
      in
         case S of C|Cr then
            case C of &` then
               {IsQuotedVariable Cr}
            else
               {Char.isUpper C} andthen {All Cr IsIDChar}
            end
         [] nil then false
         end
      end
   end
end

fun {DowncasePrintName X} S in
   S = {Atom.toString X}
   case S of C|Cr then
      case {Char.isUpper C} then {String.toAtom {Char.toLower C}|Cr}
      elsecase C == &` then X
      end
   [] nil then X
   end
end

NameVariable = CompilerSupport.nameVariable

IsBuiltin    = CompilerSupport.isBuiltin
