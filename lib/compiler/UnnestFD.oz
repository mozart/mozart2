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

%%
%% The functions in this file do the normalizing of finite domain
%% statements and expressions ('=:' etc.) as well as the `condis'
%% construct.  They transform Oz code in tuple representation into
%% other Oz code in tuple representation.
%%

local
   %--------------------------------------------------------------------
   % Common Procedures for FD Compare and `condis' expansion

   proc {NormalizeFdCompare Op E1 E2 C ?NewOp ?NewE} TmpE in
      % Transform E1 Op E2 into E1 - E2 Op 0;
      % eliminate '<:', '>:', '>=:' by replacing them by '=<:'.
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
      % Checks whether all terms in the sum E are products
      % of the form c*v (i.e., with a single variable).
      case E of fOpApply('+' [E1 E2] _) then
         {AreLinearConstraints E1} andthen {AreLinearConstraints E2}
      [] fOpApply('*' [_ E2] _) then
         % since all applications of '*' are right-associative,
         % this simple test suffices:
         case E2 of fVar(_ _) then true
         else false
         end
      end
   end

   proc {MakeTuples E CsHd CsTl VsHd VsTl}
      % Let E be a linear normalized FD expression of the form:
      %    C1*V1 + ... + Cn*Vn
      % (i.e., {AllLinearConstraints E} == true).
      % This procedure extracts all constant/variable pairs:
      %    CsHd = C1|...|Cn|CsTl
      %    VsHd = V1|...|Vn|VsTl
      case E of fOpApply('+' [E1 E2] _) then CsInter VsInter in
         {MakeTuples E1 CsHd CsInter VsHd VsInter}
         {MakeTuples E2 CsInter CsTl VsInter VsTl}
      [] fOpApply('*' [E1 E2] _) then   % E1 = fInt(...), E2 = fVar(...)
         CsHd = E1|CsTl
         VsHd = E2|VsTl
      end
   end

   local
      fun {ProductToVariableList E}
         % Input:
         %    E == V1*(...*(...*Vn)...)
         % Returns:
         %    V1|...|Vn
         case E of fOpApply('*' [E1 E2] _) then   % E1 = fVar(...)
            E1|{ProductToVariableList E2}
         [] fVar(_ _) then
            [E]
         end
      end
   in
      proc {MakeTupleTuples E CsHd CsTl VsHd VsTl}
         % Let E be a normalized FD expression of the form:
         %    C1*V[1,1]*...*V[1,n1] + ... + Cn*V[m,1]*...*V[m,nm]
         % This procedure extracts all constants/variables:
         %    CsHd = C1|...|Cn|CsTl
         %    VsHd = (V[1,1]#...#V[1,n1])|...|(V[m,1]#...#V[m,nm])|VsTl
         case E of fOpApply('+' [E1 E2] _) then CsInter VsInter in
            {MakeTupleTuples E1 CsHd CsInter VsHd VsInter}
            {MakeTupleTuples E2 CsInter CsTl VsInter VsTl}
         [] fOpApply('*' [E1 E2] _) then   % E1 = fInt(...)
            CsHd = E1|CsTl
            VsHd = fRecord(fAtom('#' E1.2) {ProductToVariableList E2})|VsTl
         end
      end
   end

   %--------------------------------------------------------------------
   % Normalization and simplification of FD expressions:

   local
      fun {NegDNF E C}
         % Let E be in DNF.  Return the expression ~E in DNF.
         case E of fOpApply('+' [E1 E2] C2) then
            % ~(E1 + E2) => ~E1 + ~E2
            fOpApply('+' [{NegDNF E1 C} {NegDNF E2 C}] C2)
         [] fOpApply('*' [E1 E2] C2) then
            % ~(E1 * E2) => ~E1 * E2
            fOpApply('*' [{NegDNF E1 C} E2] C2)
         [] fInt(I C2) then
            % ~(I) => ~I
            fInt(~I C2)
         [] fVar(_ _) then
            % ~V => ~1 * V
            fOpApply('*' [fInt(~1 C) E] C)
         end
      end

      fun {MulDNF E1 E2 C}
         % Let E1, E2 be in DNF.  Return the expression E1 * E2 in DNF.
         case E1 of fOpApply('+' [E11 E12] C2) then
            % (E11 + E12) * E2 => E11*E2 + E12*E2
            fOpApply('+' [{MulDNF E11 E2 C}
                          {MulDNF E12 E2 C}] C2)
         elsecase E2 of fOpApply('+' [E21 E22] C2) then
            % E1 * (E21 + E22) => E1*E21 + E1*E22
            fOpApply('+' [{MulDNF E1 E21 C}
                          {MulDNF E1 E22 C}] C2)
         else
            fOpApply('*' [E1 E2] C)
         end
      end
   in
      fun {MakeDNF E}
         % Transform an FD term E into its disjunctive normal form:
         %    s, t ::= s + t | p     sums
         %    p, q ::= p * q | f     products
         %    f ::= v | c            factor (variable or constant)
         % Precondition: E must be the result of an UnnestFDExpression.
         case E of fOpApply('+' [E1 E2] C) then
            fOpApply('+' [{MakeDNF E1} {MakeDNF E2}] C)
         [] fOpApply('-' [E1 E2] C) then
            fOpApply('+' [{MakeDNF E1} {MakeDNF fOpApply('~' [E2] C)}] C)
         [] fOpApply('~' [E] C) then
            {NegDNF {MakeDNF E} C}
         [] fOpApply('*' [E1 E2] C) then
            {MulDNF {MakeDNF E1} {MakeDNF E2} C}
         [] fInt(_ _) then E
         [] fVar(_ _) then E
         end
      end
   end

   local
      proc {NormalizeProduct E ?Const ?NewE}
         % Multiplies all constants in a product and makes all
         % applications of '*' right-associative.
         % The result consists of a constant factor `Const' and a
         % normalized product in `NewE' with the following structure:
         %    p ::= m | 1
         %    m ::= v * m | v
         % The product 1 is represented by 'fOne'.
         case E of fOpApply('*' [E1 E2] C) then
            case E1 of fOpApply('*' [E11 E12] C1) then TmpE in
               % all applications of '*' should be right-associative:
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
            end
         [] fInt(N _) then
            Const = N
            NewE = fOne
         [] fVar(_ _) then
            Const = 1
            NewE = E
         end
      end
   in
      proc {Normalize E ?Const ?NewE}
         % Normalizes an FD expression E given in its DNF.
         % The result consists of a constant `Const' and a normalized
         % form in NewE with the following structure:
         %    t ::= s | 0
         %    s ::= p + s | p
         %    p ::= c * m
         %    m ::= v * m | v
         % Note that all applications of '+' and '*' are right-associative.
         % The constant 0 is represented by 'fZero(Coordinates)'.
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
         [] fOpApply('*' _ C) then C0 NewE0 in
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
         end
      end
   end

   local
      proc {SimplifyRest E V ?M ?NewE}
         % Look for terms I*V in E, add all I and return their sum in M.
         % Return the remaining terms in NewE.
         case E of fOpApply('+' [E1 E2] C) then
            case E1 of fOpApply('*' [fInt(N1 _) fVar(!V _)] _) then N2 in
               {SimplifyRest E2 V ?N2 ?NewE}
               M = N1 + N2
            else NewE2 in
               {SimplifyRest E2 V ?M ?NewE2}
               case NewE2 of fZero(_) then
                  NewE = E1
               else
                  NewE = fOpApply('+' [E1 NewE2] C)
               end
            end
         [] fOpApply('*' [fInt(N _) fVar(!V _)] C) then
            M = N
            NewE = fZero(C)
         else
            M = 0
            NewE = E
         end
      end
   in
      fun {Simplify E}
         % Simplify the normalized FD term E, e. g.:
         %    2*A + 1*A + ~3*B => 3*A + ~3*B
         % (This step may in principle be omitted.)
         % Only products with a single variable are considered.
         % The result is again a normalized FD term.
         case E of fOpApply('+' [E1 E2] C) then
            case E1 of fOpApply('*' [fInt(N C1) fVar(V C2)] C3) then M NewE2 in
               {SimplifyRest E2 V ?M ?NewE2}
               case NewE2 of fZero(_) then
                  % even if N + M is zero, check that V is an FD/int variable
                  fOpApply('*' [fInt(N + M C1) fVar(V C2)] C3)
               else
                  fOpApply('+' [fOpApply('*' [fInt(N + M C1) fVar(V C2)] C3)
                                {Simplify NewE2}] C)
               end
            else
               fOpApply('+' [E1 {Simplify E2}] C)
            end
         else E
         end
      end
   end
in
   %--------------------------------------------------------------------
   % Expansion of FD Compare Statements and Expressions

   fun {MakeFdCompareStatement Op E1 E2 C} NewOp TmpE NewE Const in
      % This function normalizes the FD expression
      %    E1 Op E2
      % where E1, E2 are unnested FD expressions of the form:
      %    s, t ::= s + t | s - t | s * t | ~s | o
      %    o ::= v | c
      % It returns an application of the corresponding propagator.
      {NormalizeFdCompare Op E1 E2 C ?NewOp ?TmpE}
      NewE = {Simplify {Normalize {MakeDNF TmpE} ?Const}}
      case NewE of fZero(C2) then
         case NewOp of '=:' then
            fEq(fInt(Const C2) fInt(0 C) C)
         [] '=<:' then
            fEq(fOpApply('==' [fInt(Const C2) fInt(0 C)] C)
                fEscape(fVar('`true`' C) C) C)
         [] '\\=:' then
            fEq(fOpApply('==' [fInt(Const C2) fInt(0 C)] C)
                fEscape(fVar('`false`' C) C) C)
         end
      elsecase {AreLinearConstraints NewE} then Cs Vs in
         {MakeTuples NewE ?Cs nil ?Vs nil}
         case {FD.is ~Const} then X O D in
            X = fRecord(fAtom('#' C) Vs)
            O = fAtom(NewOp C)
            D = fInt(~Const C)
            case {All Cs fun {$ fInt(I _)} I == 1 end} then
               fApply(fVar('`GenSum`' C) [X O D] C)
            else A in
               A = fRecord(fAtom('#' C) Cs)
               fApply(fVar('`GenSumC`' C) [A X O D] C)
            end
         else A X O D in
            A = fRecord(fAtom('#' C) fInt(Const C)|Cs)
            X = fRecord(fAtom('#' C) fInt(1 C)|Vs)
            O = fAtom(NewOp C)
            D = fInt(0 C)
            fApply(fVar('`GenSumC`' C) [A X O D] C)
         end
      else Cs Vs A X O D in
         {MakeTupleTuples NewE ?Cs nil ?Vs nil}
         case {FD.is ~Const} then
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
         fApply(fVar('`GenSumCN`' C) [A X O D] C)
      end
   end

   fun {MakeFdCompareExpression Op E1 E2 C V} NewOp TmpE NewE Const in
      % This function normalizes the reified FD expression
      %    V = (E1 Op E2)
      % where E1, E2 are unnested FD expressions of the form:
      %    s, t ::= s + t | s - t | s * t | ~s | o
      %    o ::= v | c
      % It returns an application of the corresponding reified propagator.
      {NormalizeFdCompare Op E1 E2 C ?NewOp ?TmpE}
      NewE = {Simplify {Normalize {MakeDNF TmpE} ?Const}}
      case NewE of fZero(C2) then X O D in
         X = fRecord(fAtom('#' C2) [fInt(Const C2)])
         O = fAtom(NewOp C)
         D = fInt(0 C2)
         fApply(fVar('`GenSumR`' C) [X O D V] C)
      elsecase {AreLinearConstraints NewE} then Cs Vs in
         {MakeTuples NewE ?Cs nil ?Vs nil}
         case {FD.is ~Const} then X O D in
            X = fRecord(fAtom('#' C) Vs)
            O = fAtom(NewOp C)
            D = fInt(~Const C)
            case {All Cs fun {$ fInt(I _)} I == 1 end} then
               fApply(fVar('`GenSumR`' C) [X O D V] C)
            else A in
               A = fRecord(fAtom('#' C) Cs)
               fApply(fVar('`GenSumCR`' C) [A X O D V] C)
            end
         else A X O D in
            A = fRecord(fAtom('#' C) fInt(Const C)|Cs)
            X = fRecord(fAtom('#' C) fInt(1 C)|Vs)
            O = fAtom(NewOp C)
            D = fInt(0 C)
            fApply(fVar('`GenSumCR`' C) [A X O D V] C)
         end
      else Cs Vs A X O D in
         {MakeTupleTuples NewE ?Cs nil ?Vs nil}
         case {FD.is ~Const} then
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
         fApply(fVar('`GenSumCNR`' C) [A X O D V] C)
      end
   end

   %--------------------------------------------------------------------
   % Expansion of `condis'

   local
      local
         proc {GetVarsFromFdCompare E VsHd VsTl}
            case E of fOpApply('+' [E1 E2] _) then VsInter in
               {GetVarsFromFdCompare E1 VsHd VsInter}
               {GetVarsFromFdCompare E2 VsInter VsTl}
            [] fOpApply('*' [E1 E2] _) then VsInter in
               {GetVarsFromFdCompare E1 VsHd VsInter}
               {GetVarsFromFdCompare E2 VsInter VsTl}
            [] fInt(_ _) then
               VsHd = VsTl
            [] fVar(_ _) then
               VsHd = E|VsTl
            [] fZero(_) then
               VsHd = VsTl
            end
         end

         proc {GetVarsFromFdIn E VsHd VsTl ?NPropagators}
            case E of fRecord(_ Args) then [E1 E2] = Args VsInter NProp1 in
               VsHd = E1|VsInter
               {GetVarsFromFdIn E2 VsInter VsTl ?NProp1}
               NPropagators = NProp1 + 1
            else
               VsHd = VsTl
               NPropagators = 0
            end
         end

         proc {NormalizeCondisExpression S VsHd VsTl ?NPropagators ?NewS}
            case S of fFdCompare(Op E1 E2 C) then NewOp TmpE Const NewE in
               {NormalizeFdCompare Op E1 E2 C ?NewOp ?TmpE}
               NewE = {Simplify {Normalize {MakeDNF TmpE} ?Const}}
               {GetVarsFromFdCompare NewE VsHd VsTl}
               NPropagators = 1
               NewS = fFdCompare(NewOp NewE fInt(~Const C) C)
            [] fFdIn(Op E _ _) then
               case Op of '::' then
                  VsHd = E|VsTl
                  NPropagators = 1
               [] ':::' then
                  {GetVarsFromFdIn E VsHd VsTl ?NPropagators}
               end
               NewS = S
            end
         end
      in
         proc {NormalizeCondisClause Ss VsHd VsTl ?NPropagators ?NewSs}
            % This procedure takes a list Ss of unnested FD expressions in a
            % condis clause.  Its FD variables are put into the difference list
            % VsHd-VsTl.  The propagators the expressions create are counted
            % and returned in NPropagators.  Finally, the normalized
            % list of expressions is returned in NewSs.
            case Ss of S1|Sr then VsInter NewS1 NewSr NProp1 NPropr in
               {NormalizeCondisExpression S1 VsHd VsInter ?NProp1 ?NewS1}
               {NormalizeCondisClause Sr VsInter VsTl ?NPropr ?NewSr}
               NPropagators = NProp1 + NPropr
               NewSs = NewS1|NewSr
            [] nil then
               VsHd = VsTl
               NPropagators = 0
               NewSs = nil
            end
         end
      end

      local
         proc {RenameFdCompare E D ?NewE}
            % Rename all variables in an FD expression.
            case E of fOpApply('+' [E1 E2] C) then NewE1 NewE2 in
               NewE = fOpApply('+' [NewE1 NewE2] C)
               {RenameFdCompare E1 D ?NewE1}
               {RenameFdCompare E2 D ?NewE2}
            [] fOpApply('*' [E1 E2] C) then NewE1 NewE2 in
               NewE = fOpApply('*' [NewE1 NewE2] C)
               {RenameFdCompare E1 D ?NewE1}
               {RenameFdCompare E2 D ?NewE2}
            [] fInt(_ _) then
               NewE = E
            [] fVar(X C) then
               NewE = fVar({Dictionary.get D X} C)
            [] fZero(_) then
               NewE = E
            end
         end

         proc {RenameFdIn E D ?NewE}
            % Rename all variables in an Oz list of FD variables
            % (occurring to the left of ':::').
            case E of fRecord(Label Args) then [fVar(X C) E2] = Args NewE2 in
               NewE = fRecord(Label [fVar({Dictionary.get D X} C) NewE2])
               {RenameFdIn E2 D ?NewE2}
            else   % fAtom('nil' _)
               NewE = E
            end
         end

         fun {GenerateCondisExpression S D B}
            % Generate an application of a propagator for the FD expression S,
            % renaming the variables according to the dictionary D, connecting
            % the propagator to the control variable B.
            case S of fFdCompare(Op E fInt(Const _) C) then NewE in
               NewE = {RenameFdCompare E D}
               case NewE of fZero(C2) then A X O D in
                  A = fRecord(fAtom('#' C) [fInt(~Const C)])
                  X = fRecord(fAtom('#' C) [fInt(1 C)])
                  O = fAtom(Op C)
                  D = fInt(0 C2)
                  fApply(fVar('`GenSumCCD`' C) [A X O D B] C)
               elsecase {AreLinearConstraints NewE} then Cs Vs X O D in
                  {MakeTuples NewE ?Cs nil ?Vs nil}
                  case {FD.is Const} then X O D in
                     X = fRecord(fAtom('#' C) Vs)
                     O = fAtom(Op C)
                     D = fInt(Const C)
                     case {All Cs fun {$ fInt(I _)} I == 1 end} then
                        fApply(fVar('`GenSumCD`' C) [X O D B] C)
                     else A in
                        A = fRecord(fAtom('#' C) Cs)
                        fApply(fVar('`GenSumCCD`' C) [A X O D B] C)
                     end
                  else A X O D in
                     A = fRecord(fAtom('#' C) fInt(~Const C)|Cs)
                     X = fRecord(fAtom('#' C) fInt(1 C)|Vs)
                     O = fAtom(Op C)
                     D = fInt(0 C)
                     fApply(fVar('`GenSumCCD`' C) [A X O D B] C)
                  end
               else Cs Vs A X O D in
                  {MakeTupleTuples NewE ?Cs nil ?Vs nil}
                  case {FD.is Const} then
                     A = fRecord(fAtom('#' C) Cs)
                     X = fRecord(fAtom('#' C) Vs)
                     O = fAtom(Op C)
                     D = fInt(Const C)
                  else
                     A = fRecord(fAtom('#' C) fInt(~Const C)|Cs)
                     X = fRecord(fAtom('#' C)
                                 fRecord(fAtom('#' C) [fInt(1 C)])|Vs)
                     O = fAtom(Op C)
                     D = fInt(0 C)
                  end
                  fApply(fVar('`GenSumCNCD`' C) [A X O D B] C)
               end
            [] fFdIn(Op E1 E2 C) then NewE1 in
               case Op of '::' then fVar(X C) = E1 in
                  NewE1 = fVar({Dictionary.get D X} C)
                  fApply(fVar('`::CD`' C) [E2 NewE1 B] C)
               [] ':::' then
                  NewE1 = {RenameFdIn E1 D}
                  fApply(fVar('`:::CD`' C) [E2 NewE1 B] C)
               end
            end
         end

         fun {OccursVar Vs PrintName}
            case Vs of V|Vr then
               case V of fVar(X _) then
                  X == PrintName orelse {OccursVar Vr PrintName}
               else
                  {OccursVar Vr PrintName}
               end
            [] nil then false
            end
         end
      in
         proc {GenerateCondisClause Ss BA AllVs CVs B ?FreshCVs ?NewSs} D in
            % Generate applications for all propagators in a list of
            % FD expressions Ss.  AllVs is the list of the whole `condis'
            % statement's FD variables, CVs is the list of those variables
            % occurring in Ss.  The variables in CVs are renamed for each
            % clause to fresh variables.  All propagators are attached to
            % the control variable B.  The list of propagator applications
            % is returned in NewSs; FreshCVs are the generated variables.
            % They are given in the same order as AllVs, with 'unit'
            % marking variables that do not occur in Ss.
            D = {NewDictionary}
            FreshCVs = {Map AllVs
                        fun {$ V} fVar(X C) = V in
                           case {OccursVar CVs X} then GV PrintName in
                              {BA generate('CDVar' C ?GV)}
                              PrintName = {GV getPrintName($)}
                              {Dictionary.put D X PrintName}
                              fVar(PrintName C)
                           else
                              fAtom('void' C)
                           end
                        end}
            NewSs = {Map Ss fun {$ S} {GenerateCondisExpression S D B} end}
         end
      end

      local
         fun {OccursIn X Vs}
            case Vs of V|Vr then
               X == V.1 orelse {OccursIn X Vr}
            else false
            end
         end
      in
         fun {VariableUnion Vs Ws}
            % Adds the variables in Vs to Ws.
            % Even if a variable occurs multiple times in Vs, it is only
            % added once to Ws.
            case Vs of V1|Vr then fVar(X _) = V1 in
               case {OccursIn X Ws} then {VariableUnion Vr Ws}
               else {VariableUnion Vr V1|Ws}
               end
            [] nil then Ws
            end
         end
      end
   in
      fun {MakeCondis Clauses BA C}
         % Generate the corresponding applications for the `condis'
         % statement with clauses given in Clauses at source coordinates C.
         % The BA object is required to generate fresh variables for each
         % clause's local variables and the global control variables.
         % The statements in the clauses must already have been unnested,
         % i.e., each statement must be of the form:
         %    st ::= compare | fdin
         %    compare ::= s op t
         %    op ::= '=:' | '<:' | '>:' | '=<:' | '>=:' | '\\=:'
         %    s, t ::= s + t | s - t | s * t | ~s | o
         %    o ::= c | v
         %    fdin ::= v1 :: v2 | vlist ::: v
         %    vlist ::= '|'(v vlist) | nil
         % where c is a constant (integer) and v, v1, v2 are variables.
         NewClauses AllVs Res PropCalls NRec BRec VRec CVRec in
         NewClauses = {Map Clauses
                       fun {$ Ss} CVs NProp NewSs in
                          {NormalizeCondisClause Ss ?CVs nil ?NProp ?NewSs}
                          CVs#NProp#NewSs
                       end}
         AllVs = {Reverse {FoldL NewClauses
                           fun {$ In Vs#_#_} {VariableUnion Vs In} end nil}}
         Res = {Map NewClauses
                fun {$ CVs#_#Ss} GV FV NewSs NewCVs in
                   {BA generate('CDControlVar' C ?GV)}
                   FV = fVar({GV getPrintName($)} C)
                   {GenerateCondisClause Ss BA AllVs CVs FV ?NewCVs ?NewSs}
                   FV#NewCVs#NewSs
                end}
         NRec = fRecord(fAtom('#' C)
                        {Map NewClauses fun {$ _#N#_} fInt(N C) end})
         BRec = fRecord(fAtom('#' C) {Map Res fun {$ B#_#_} B end})
         VRec = fRecord(fAtom('#' C) AllVs)
         CVRec = fRecord(fAtom('#' C)
                         {Map Res
                          fun {$ _#CVs#_} fRecord(fAtom('#' C) CVs) end})
         PropCalls = {FoldL Res
                      fun {$ In _#_#Ss}
                         {FoldL Ss fun {$ In S} fAnd(In S) end In}
                      end fSkip(C)}
         fAnd(fApply(fVar('`CDHeader`' C) [NRec BRec VRec CVRec] C)
              fAnd(PropCalls fApply(fVar('`CDBody`' C) [BRec VRec CVRec] C)))
      end
   end
end
