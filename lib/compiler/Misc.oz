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

%%
%% Auxiliary procedures used throughout the compiler.
%%

local
   proc {EscapeVariableChar Hd C|Cr Tl}
      case Cr of nil then Hd = C|Tl   % terminating quote
      elsecase C == &` orelse C == &\\ then Hd = &\\|C|Tl
      elsecase C < 10 then Hd = &\\|&x|&0|(&0 + C)|Tl
      elsecase C < 16 then Hd = &\\|&x|&0|(&A + C - 10)|Tl
      elsecase C < 26 then Hd = &\\|&x|&1|(&0 + C - 16)|Tl
      elsecase C < 32 then Hd = &\\|&x|&1|(&A + C - 26)|Tl
      else Hd = C|Tl
      end
   end
in
   fun {PrintNameToVirtualString PrintName}
      case {Atom.toString PrintName} of &`|Sr then
         &`|{FoldLTail Sr EscapeVariableChar $ nil}
      else PrintName
      end
   end
end

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
   fun {IsPrintName X} S in
      S = {Atom.toString X}
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

NameVariable = {`Builtin` 'nameVariable' 2}
NewNamedName = {`Builtin` 'newNamedName' 2}
IsUniqueName = {`Builtin` 'isUniqueName' 2}

GetProcInfo = {`Builtin` 'getProcInfo' 2}
SetProcInfo = {`Builtin` 'setProcInfo' 2}

IsBuiltin = {`Builtin` 'isBuiltin' 2}
GetBuiltinName = {`Builtin` 'getBuiltinName' 2}
GenerateAbstractionTableID = {`Builtin` 'generateAbstractionTableID' 2}

ConcatenateAtomAndInt = {`Builtin` 'concatenateAtomAndInt' 3}
