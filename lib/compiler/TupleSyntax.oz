%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1996, 1997
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

%%
%% This file defines some auxiliary functions operating on the tuple
%% representation of Oz programs (described in Doc/TupleSyntax).
%%

fun {CoordinatesOf P}
   % Returns the coordinates of the outermost leftmost construct
   % in a given phrase P.
   case P of fAnd(S _) then {CoordinatesOf S}
   [] fEq(E _ _) then {CoordinatesOf E}
   [] fAssign(E _ _) then {CoordinatesOf E}
   [] fOrElse(E _ _) then {CoordinatesOf E}
   [] fAndThen(E _ _) then {CoordinatesOf E}
   [] fOpApply(Op Es C) then
      case Op of '~' then C   % prefix operator
      else {CoordinatesOf Es.1}   % infix operator
      end
   [] fFdCompare(_ E _ _) then {CoordinatesOf E}
   [] fFdIn(_ E _ _) then {CoordinatesOf E}
   [] fObjApply(E _ _) then {CoordinatesOf E}
   [] fAt(_ C) then C
   [] fAtom(_ C) then C
   [] fVar(_ C) then C
   [] fWildcard(C) then C
   [] fEscape(_ C) then C
   [] fSelf(C) then C
   [] fDollar(C) then C
   [] fInt(_ C) then C
   [] fFloat(_ C) then C
   [] fRecord(L _) then {CoordinatesOf L}
   [] fOpenRecord(L _) then {CoordinatesOf L}
   [] fApply(_ _ C) then C
   [] fProc(_ _ _ _ C) then C
   [] fFun(_ _ _ _ C) then C
   [] fClass(_ _ _ C) then C
   [] fLocal(_ _ C) then C
   [] fBoolCase(_ _ _ C) then C
   [] fCase(_ _ _ C) then C
   [] fLockThen(_ _ C) then C
   [] fLock(_ C) then C
   [] fThread(_ C) then C
   [] fTry(_ _ _ C) then C
   [] fRaise(_ C) then C
   [] fRaiseWith(_ _ C) then C
   [] fSkip(C) then C
   [] fFail(C) then C
   [] fNot(_ C) then C
   [] fIf(_ _ C) then C
   [] fOr(_ _ C) then C
   [] fCondis(_ C) then C
   end
end

proc {VarListSub Vs1 Vs2 VsHd VsTl}
   % Place those elements from Vs2 that are not containted in Vs1
   % in the difference list VsHd-VsTl (i. e. Vs2 \setminus Vs1).
   case Vs2 of V|Vr then fVar(X _) = V VsInter in
      case {Some Vs1 fun {$ fVar(Y _)} X == Y end} then VsHd = VsInter
      else VsHd = V|VsInter
      end
      {VarListSub Vs1 Vr VsInter VsTl}
   [] nil then
      VsHd = VsTl
   end
end

%% The following procedures compute the pattern variables of a
%% statement or an expression, respectively.  They differ in a
%% subtle way; consider an equation P1 = P2:
%% -- In statement position, only P1 is considered to be a
%%    pattern position.
%% -- In expression position, both P1 and P2 are considered
%%    pattern positions.
%% Erroneous inputs are ignored in GetPatternVariablesStatement
%% (i. e., expression at statement position) since it is used
%% by GetPatternVariablesExpression as the default case.
%%
%% All variables are represented in tuple syntax.

proc {GetPatternVariablesStatement S VsHd VsTl}
   % Place the pattern variables of statement S in the difference list
   % VsHd-VsTl.
   case S of fVar(_ _) then
      VsHd = S|VsTl
   [] fEq(E _ _) then
      {GetPatternVariablesExpression E VsHd VsTl}
   [] fClass(E _ _ _) then
      {GetPatternVariablesExpression E VsHd VsTl}
   [] fProc(E _ _ _ _) then
      {GetPatternVariablesExpression E VsHd VsTl}
   [] fFun(E _ _ _ _) then
      {GetPatternVariablesExpression E VsHd VsTl}
   [] fLocal(S1 S2 _) then Vs1 Vs2 in
      {GetPatternVariablesStatement S1 ?Vs1 nil}
      {GetPatternVariablesStatement S2 ?Vs2 nil}
      {VarListSub Vs1 Vs2 VsHd VsTl}
   [] fAnd(S1 S2) then VsInter in
      {GetPatternVariablesStatement S1 VsHd VsInter}
      {GetPatternVariablesStatement S2 VsInter VsTl}
   [] fRecord(_ As) then
      {FoldL As proc {$ VsHd A VsTl}
                   {GetPatternVariablesExpression A VsHd VsTl}
                end VsHd VsTl}
   [] fOpenRecord(_ As) then
      {FoldL As proc {$ VsHd A VsTl}
                   {GetPatternVariablesExpression A VsHd VsTl}
                end VsHd VsTl}
   [] fColon(_ E) then
      {GetPatternVariablesExpression E VsHd VsTl}
   else
      VsHd = VsTl
   end
end

proc {GetPatternVariablesExpression E VsHd VsTl}
   % Place the pattern variables of expression E in the difference list
   % VsHd-VsTl.
   case E of fEq(E1 E2 _) then VsInter in
      {GetPatternVariablesExpression E1 VsHd VsInter}
      {GetPatternVariablesExpression E2 VsInter VsTl}
   [] fLocal(_ _ _) then VsHd = VsTl
   [] fAnd(_ _) then VsHd = VsTl
   else
      {GetPatternVariablesStatement E VsHd VsTl}
   end
end

local
   fun {Contains Vs X}
      case Vs of V|Vr then
         X == V.1 orelse {Contains Vr X}
      else false
      end
   end
in
   fun {UniqueVariables Vs}
      case Vs of V|Vr then fVar(X _) = V in
         case {Contains Vr X} then {UniqueVariables Vr}
         else V|{UniqueVariables Vr}
         end
      [] nil then nil
      end
   end
end

fun {PrivateAttrFeat FAttrFeat In} FF in
   case FAttrFeat of F#_ then FF = F
   else FF = FAttrFeat
   end
   case FF of fVar(_ _) then FF|In
   else In
   end
end

fun {PrivateMeth fMeth(FHead _ _) In} NewFHead in
   case FHead of fEq(RealFHead _ _) then NewFHead = RealFHead
   else NewFHead = FHead
   end
   case NewFHead of fVar(_ _) then NewFHead|In
   [] fRecord(L _) then
      case L of fVar(_ _) then L|In
      else In
      end
   [] fOpenRecord(L _) then
      case L of fVar(_ _) then L|In
      else In
      end
   else In
   end
end
