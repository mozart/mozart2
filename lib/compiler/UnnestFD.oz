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

%%
%% The functions in this file do the normalizing of finite domain
%% statements and expressions ('=:' etc.).  They transform Oz code
%% in tuple representation into other Oz code in tuple representation.
%%

local
   %%-------------------------------------------------------------------
   %% Auxiliary Procedures for FD Compare Expansion

   proc {NormalizeFdCompare Op E1 E2 C ?NewOp ?NewE} TmpE in
      %% Transform E1 Op E2 into E1 - E2 Op 0;
      %% eliminate '<:', '>:', '>=:' by replacing them by '=<:'.
      TmpE = fOpApply('-' [E1 E2] C)
      case Op of '=:' then
         NewOp = '=:'
         NewE = TmpE
      [] '<:' then   % E <: 0 <=> E + 1 =<: 0
         NewOp = '=<:'
         NewE = fOpApply('+' [TmpE fInt(1 C)] C)
      [] '>:' then   % E >: 0 <=> 1 - E =<: 0
         NewOp = '=<:'
         NewE = fOpApply('-' [fInt(1 C) TmpE] C)
      [] '=<:' then
         NewOp = '=<:'
         NewE = TmpE
      [] '>=:' then   % E >=: 0 <=> ~E =<: 0
         NewOp = '=<:'
         NewE = fOpApply('~' [TmpE] C)
      [] '\\=:' then
         NewOp = '\\=:'
         NewE = TmpE
      end
   end

   fun {AreLinearConstraints E}
      %% Checks whether all terms in the sum E are products
      %% of the form c*v (i.e., with a single variable).
      case E of fOpApply('+' [E1 E2] _) then
         {AreLinearConstraints E1} andthen {AreLinearConstraints E2}
      elseof fOpApply('*' [_ E2] _) then
         %% since all applications of '*' are right-associative,
         %% this simple test suffices:
         case E2 of fVar(_ _) then true
         [] fOcc(_) then true
         else false
         end
      end
   end

   proc {MakeTuples E CsHd CsTl VsHd VsTl}
      %% Let E be a linear normalized FD expression of the form:
      %%    C1*V1 + ... + Cn*Vn
      %% (i.e., {AllLinearConstraints E} == true).
      %% This procedure extracts all constant/variable pairs:
      %%    CsHd = C1|...|Cn|CsTl
      %%    VsHd = V1|...|Vn|VsTl
      case E of fOpApply('+' [E1 E2] _) then CsInter VsInter in
         {MakeTuples E1 CsHd CsInter VsHd VsInter}
         {MakeTuples E2 CsInter CsTl VsInter VsTl}
      elseof fOpApply('*' [E1 E2] _) then   % E1 = fInt(...), E2 = fVar(...)
         CsHd = E1|CsTl
         VsHd = E2|VsTl
      end
   end

   local
      fun {ProductToVariableList E}
         %% Input:
         %%    E == V1*(...*(...*Vn)...)
         %% Returns:
         %%    V1|...|Vn
         case E of fOpApply('*' [E1 E2] _) then   % E1 = fVar(...)
            E1|{ProductToVariableList E2}
         [] fVar(_ _) then
            [E]
         [] fOcc(_) then
            [E]
         end
      end
   in
      proc {MakeTupleTuples E CsHd CsTl VsHd VsTl}
         %% Let E be a normalized FD expression of the form:
         %%    C1*V[1,1]*...*V[1,n1] + ... + Cn*V[m,1]*...*V[m,nm]
         %% This procedure extracts all constants/variables:
         %%    CsHd = C1|...|Cn|CsTl
         %%    VsHd = (V[1,1]#...#V[1,n1])|...|(V[m,1]#...#V[m,nm])|VsTl
         case E of fOpApply('+' [E1 E2] _) then CsInter VsInter in
            {MakeTupleTuples E1 CsHd CsInter VsHd VsInter}
            {MakeTupleTuples E2 CsInter CsTl VsInter VsTl}
         elseof fOpApply('*' [E1 E2] _) then   % E1 = fInt(...)
            CsHd = E1|CsTl
            VsHd = fRecord(fAtom('#' E1.2) {ProductToVariableList E2})|VsTl
         end
      end
   end

   %%-------------------------------------------------------------------
   %% Normalization and simplification of FD expressions:

   local
      fun {NegDNF E C}
         %% Let E be in DNF.  Return the expression ~E in DNF.
         case E of fOpApply('+' [E1 E2] C2) then
            %% ~(E1 + E2) => ~E1 + ~E2
            fOpApply('+' [{NegDNF E1 C} {NegDNF E2 C}] C2)
         elseof fOpApply('*' [E1 E2] C2) then
            %% ~(E1 * E2) => ~E1 * E2
            fOpApply('*' [{NegDNF E1 C} E2] C2)
         [] fInt(I C2) then
            %% ~(I) => ~I
            fInt(~I C2)
         [] fVar(_ _) then
            %% ~V => ~1 * V
            fOpApply('*' [fInt(~1 C) E] C)
         [] fOcc(_) then
            %% ~V => ~1 * V
            fOpApply('*' [fInt(~1 C) E] C)
         end
      end

      fun {MulDNF E1 E2 C}
         %% Let E1, E2 be in DNF.  Return the expression E1 * E2 in DNF.
         case E1 of fOpApply('+' [E11 E12] C2) then
            %% (E11 + E12) * E2 => E11*E2 + E12*E2
            fOpApply('+' [{MulDNF E11 E2 C}
                          {MulDNF E12 E2 C}] C2)
         elsecase E2 of fOpApply('+' [E21 E22] C2) then
            %% E1 * (E21 + E22) => E1*E21 + E1*E22
            fOpApply('+' [{MulDNF E1 E21 C}
                          {MulDNF E1 E22 C}] C2)
         else
            fOpApply('*' [E1 E2] C)
         end
      end
   in
      fun {MakeDNF E}
         %% Transform an FD term E into its disjunctive normal form:
         %%    s, t ::= s + t | p     sums
         %%    p, q ::= p * q | f     products
         %%    f ::= v | c            factor (variable or constant)
         %% Precondition: E must be the result of an UnnestFDExpression.
         case E of fOpApply('+' [E1 E2] C) then
            fOpApply('+' [{MakeDNF E1} {MakeDNF E2}] C)
         elseof fOpApply('-' [E1 E2] C) then
            fOpApply('+' [{MakeDNF E1} {MakeDNF fOpApply('~' [E2] C)}] C)
         elseof fOpApply('~' [E] C) then
            {NegDNF {MakeDNF E} C}
         elseof fOpApply('*' [E1 E2] C) then
            {MulDNF {MakeDNF E1} {MakeDNF E2} C}
         [] fInt(_ _) then E
         [] fVar(_ _) then E
         [] fOcc(_) then E
         end
      end
   end

   local
      proc {NormalizeProduct E ?Const ?NewE}
         %% Multiplies all constants in a product and makes all
         %% applications of '*' right-associative.
         %% The result consists of a constant factor `Const' and a
         %% normalized product in `NewE' with the following structure:
         %%    p ::= m | 1
         %%    m ::= v * m | v
         %% The product 1 is represented by 'fOne'.
         case E of fOpApply('*' [E1 E2] C) then
            case E1 of fOpApply('*' [E11 E12] C1) then TmpE in
               %% all applications of '*' should be right-associative:
               TmpE = fOpApply('*' [E11 fOpApply('*' [E12 E2] C)] C1)
               {NormalizeProduct TmpE ?Const ?NewE}
            [] fInt(N _) then Const2 in
               {NormalizeProduct E2 ?Const2 ?NewE}
               Const = N * Const2
            [] fVar(_ _) then NewE2 in
               {NormalizeProduct E2 ?Const ?NewE2}
               case NewE2 of fOne then
                  NewE = E1
               else
                  NewE = fOpApply('*' [E1 NewE2] C)
               end
            [] fOcc(_) then NewE2 in
               {NormalizeProduct E2 ?Const ?NewE2}
               case NewE2 of fOne then
                  NewE = E1
               else
                  NewE = fOpApply('*' [E1 NewE2] C)
               end
            end
         [] fInt(N _) then
            Const = N
            NewE = fOne
         [] fVar(_ _) then
            Const = 1
            NewE = E
         [] fOcc(_) then
            Const = 1
            NewE = E
         end
      end
   in
      proc {Normalize E ?Const ?NewE}
         %% Normalizes an FD expression E given in its DNF.
         %% The result consists of a constant `Const' and a normalized
         %% form in NewE with the following structure:
         %%    t ::= s | 0
         %%    s ::= p + s | p
         %%    p ::= c * m
         %%    m ::= v * m | v
         %% Note that all applications of '+' and '*' are right-associative.
         %% The constant 0 is represented by 'fZero(Coordinates)'.
         case E of fOpApply('+' [E1 E2] C) then Const1 NewE1 Const2 NewE2 in
            {Normalize E1 ?Const1 ?NewE1}
            {Normalize E2 ?Const2 ?NewE2}
            Const = Const1 + Const2
            case NewE2 of fZero(_) then
               NewE = NewE1
            elsecase NewE1 of fZero(_) then
               NewE = NewE2
            [] fOpApply('+' [E11 E12] C1) then
               NewE = fOpApply('+' [E11 fOpApply('+' [E12 NewE2] C1)] C)
            else
               NewE = fOpApply('+' [NewE1 NewE2] C)
            end
         elseof fOpApply('*' _ C) then C0 NewE0 in
            {NormalizeProduct E ?C0 ?NewE0}
            case NewE0 of fOne then
               Const = C0
               NewE = fZero(C)
            else
               Const = 0
               NewE = fOpApply('*' [fInt(C0 C) NewE0] C)
            end
         [] fInt(N C) then
            Const = N
            NewE = fZero(C)
         [] fVar(_ C) then
            Const = 0
            NewE = fOpApply('*' [fInt(1 C) E] C)
         [] fOcc(X) then C in
            {X getCoord(?C)}
            Const = 0
            NewE = fOpApply('*' [fInt(1 C) E] C)
         end
      end
   end
in
   %%-------------------------------------------------------------------
   %% Expansion of FD Compare Statements and Expressions

   fun {Apply X Ys Args C}
      case X of unit then
         fOpApplyStatement({VirtualString.toAtom
                            {FoldL Ys
                             fun {$ A Y}
                                A#'.'#{Value.toVirtualString Y 0 0}
                             end 'FD'}} Args C)
      else
         fApply({FoldL Ys fun {$ FE Y} fOpApply('.' [FE fAtom(Y C)] C) end X}
                Args C)
      end
   end

   fun {MakeFdCompareStatement Op E1 E2 C FD} NewOp TmpE NewE Const in
      %% This function normalizes the FD expression
      %%    E1 Op E2
      %% where E1, E2 are unnested FD expressions of the form:
      %%    s, t ::= s + t | s - t | s * t | ~s | o
      %%    o ::= v | c
      %% It returns an application of the corresponding propagator.
      {NormalizeFdCompare Op E1 E2 C ?NewOp ?TmpE}
      NewE = {Normalize {MakeDNF TmpE} ?Const}
      case NewE of fZero(C2) then
         case NewOp of '=:' then
            fEq(fInt(Const C2) fInt(0 C) C)
         [] '=<:' then
            fEq(fOpApply('==' [fInt(Const C2) fInt(0 C)] C) fAtom(true C) C)
         [] '\\=:' then
            fEq(fOpApply('==' [fInt(Const C2) fInt(0 C)] C) fAtom(false C) C)
         end
      else
         if {AreLinearConstraints NewE} then Cs Vs in
            {MakeTuples NewE ?Cs nil ?Vs nil}
            if {IsFd ~Const} then X O D in
               X = fRecord(fAtom('#' C) Vs)
               O = fAtom(NewOp C)
               D = fInt(~Const C)
               if {All Cs fun {$ fInt(I _)} I == 1 end} then
                  {Apply FD ['sum'] [X O D] C}
               else A in
                  A = fRecord(fAtom('#' C) Cs)
                  {Apply FD ['sumC'] [A X O D] C}
               end
            else A X O D in
               A = fRecord(fAtom('#' C) fInt(Const C)|Cs)
               X = fRecord(fAtom('#' C) fInt(1 C)|Vs)
               O = fAtom(NewOp C)
               D = fInt(0 C)
               {Apply FD ['sumC'] [A X O D] C}
            end
         else Cs Vs A X O D in
            {MakeTupleTuples NewE ?Cs nil ?Vs nil}
            if {IsFd ~Const} then
               A = fRecord(fAtom('#' C) Cs)
               X = fRecord(fAtom('#' C) Vs)
               O = fAtom(NewOp C)
               D = fInt(~Const C)
            else
               A = fRecord(fAtom('#' C) fInt(Const C)|Cs)
               X = fRecord(fAtom('#' C) fRecord(fAtom('#' C) [fInt(1 C)])|Vs)
               O = fAtom(NewOp C)
               D = fInt(0 C)
            end
            {Apply FD ['sumCN'] [A X O D] C}
         end
      end
   end

   fun {MakeFdCompareExpression Op E1 E2 C V FD} NewOp TmpE NewE Const in
      %% This function normalizes the reified FD expression
      %%    V = (E1 Op E2)
      %% where E1, E2 are unnested FD expressions of the form:
      %%    s, t ::= s + t | s - t | s * t | ~s | o
      %%    o ::= v | c
      %% It returns an application of the corresponding reified propagator.
      {NormalizeFdCompare Op E1 E2 C ?NewOp ?TmpE}
      NewE = {Normalize {MakeDNF TmpE} ?Const}
      case NewE of fZero(C2) then A X O D in
         A = fRecord(fAtom('#' C2) [fInt(Const C2)])
         X = fRecord(fAtom('#' C2) [fInt(1 C2)])
         O = fAtom(NewOp C)
         D = fInt(0 C2)
         {Apply FD ['reified' 'sumC'] [A X O D V] C}
      else
         if {AreLinearConstraints NewE} then Cs Vs in
            {MakeTuples NewE ?Cs nil ?Vs nil}
            if {IsFd ~Const} then X O D in
               X = fRecord(fAtom('#' C) Vs)
               O = fAtom(NewOp C)
               D = fInt(~Const C)
               if {All Cs fun {$ fInt(I _)} I == 1 end} then
                  {Apply FD ['reified' 'sum'] [X O D V] C}
               else A in
                  A = fRecord(fAtom('#' C) Cs)
                  {Apply FD ['reified' 'sumC'] [A X O D V] C}
               end
            else A X O D in
               A = fRecord(fAtom('#' C) fInt(Const C)|Cs)
               X = fRecord(fAtom('#' C) fInt(1 C)|Vs)
               O = fAtom(NewOp C)
               D = fInt(0 C)
               {Apply FD ['reified' 'sumC'] [A X O D V] C}
            end
         else Cs Vs A X O D in
            {MakeTupleTuples NewE ?Cs nil ?Vs nil}
            if {IsFd ~Const} then
               A = fRecord(fAtom('#' C) Cs)
               X = fRecord(fAtom('#' C) Vs)
               O = fAtom(NewOp C)
               D = fInt(~Const C)
            else
               A = fRecord(fAtom('#' C) fInt(Const C)|Cs)
               X = fRecord(fAtom('#' C) fRecord(fAtom('#' C) [fInt(1 C)])|Vs)
               O = fAtom(NewOp C)
               D = fInt(0 C)
            end
            {Apply FD ['reified' 'sumCN'] [A X O D V] C}
         end
      end
   end
end
