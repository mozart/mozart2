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

functor
export
   is: IsPrintName
   downcase: DowncasePrintName
define
   fun {IsIDChar C}
      {Char.isAlNum C} orelse C == &_
   end

   fun {IsQuotedVariable S}
      case S of C1|Cr then
         if C1 == &` andthen Cr == nil then true
         elseif C1 == 0 then false
         else {IsQuotedVariable Cr}
         end
      [] nil then false
      end
   end

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

   fun {DowncasePrintName X} S in
      S = {Atom.toString X}
      case S of C|Cr then
         if {Char.isUpper C} then {String.toAtom {Char.toLower C}|Cr}
         else
            case C of &` then X end
         end
      [] nil then X
      end
   end
end
