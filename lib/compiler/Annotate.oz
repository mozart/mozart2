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
%% General Notes:
%%
%% meth annotateGlobalVars(Ls VsHd VsTl)
%%    A recursive descent starting with the node is done.
%%    The values of 'globalVars' attributes are determined and set.
%%    Ls is a list of variables that are to be considered local,
%%    i.e., when a variable is encountered, it is first checked
%%    whether it is contained in Ls.  If it is, it is a reference
%%    to a local variable, if it isn't, it's a reference to a
%%    global (or rather: nonlocal) variable.  All global variables
%%    referenced by the node are placed in the difference list
%%    VsHd-VsTl.
%%
%% meth markFirst(WarnFormals Rep)
%%    A recursive descent starting with the node is done.
%%    The 'use' attribute of each variable is set.
%%    In case of unused and single-occurrence variables,
%%    warnings are emitted to the Reporter object Rep.
%%

local
   BindingAnalysisWarning = 'binding analysis warning'

   fun {VariableUnion Vs Ws}
      % Adjoins all variables of Vs to Ws.  Specifically, if Ws is nil,
      % then this function returns Vs with all duplicates removed.
      case Vs of V|Vr then
         case {Member V Ws} then {VariableUnion Vr Ws}
         else {VariableUnion Vr V|Ws}
         end
      [] nil then Ws
      end
   end

   proc {AnnotateGlobalVarsList Nodes Ls VsHd VsTl}
      case Nodes of Node|Noder then VsInter in
         {Node annotateGlobalVars(Ls VsHd VsInter)}
         {AnnotateGlobalVarsList Noder Ls VsInter VsTl}
      [] nil then
         VsHd = VsTl
      end
   end

   proc {GetExpansionVars Node VsHd VsTl}
      {Record.foldL Node.expansionOccs
       proc {$ VsHd VO VsTl}
          case VO of undeclared then VsHd = VsTl
          else VsHd = {VO getVariable($)}|VsTl
          end
       end VsHd VsTl}
   end

   proc {MarkFirstList Nodes WarnFormals Rep}
      case Nodes of Node|Noder then
         {Node markFirst(WarnFormals Rep)}
         {MarkFirstList Noder WarnFormals Rep}
      [] nil then skip
      end
   end

   proc {MarkFirstClauses Clauses GlobalVars OldUses ?NewUses WarnFormals Rep}
      Clause1|Clauser = Clauses NewUses1 in
      {Clause1 markFirstClause(GlobalVars OldUses ?NewUses1 WarnFormals Rep)}
      NewUses = {FoldL Clauser
                 fun {$ NewUses1 Clause} NewUses2 in
                    {Clause markFirstClause(GlobalVars OldUses ?NewUses2
                                            WarnFormals Rep)}
                    {UsesMax NewUses1 NewUses2}
                 end NewUses1}
   end

   proc {MarkFirstExpansionOccs Node WarnFormals Rep}
      {Record.forAll Node.expansionOccs
       proc {$ VO}
          case VO of undeclared then skip
          else {VO markFirst(WarnFormals Rep)}
          end
       end}
   end

   proc {SetUninitVars GlobalVars}
      {ForAll GlobalVars
       proc {$ V}
          case {V getUse($)} == unused then {V setUse(wildcard)}
          else skip
          end
       end}
   end

   fun {GetUses Vs}
      {Map Vs fun {$ V} {V getUse($)} end}
   end

   proc {SetUses Vs Uses}
      case Vs of V|Vr then U|Ur = Uses in
         {V setUse(U)}
         {SetUses Vr Ur}
      [] nil then
         Uses = nil
      end
   end

   local
      U = unused
      W = wildcard
      L = linear
      M = multiple
      UseMaxTable = use(U: use(U: U W: W L: L M: M)
                        W: use(U: W W: W L: L M: M)
                        L: use(U: L W: L L: L M: M)
                        M: use(U: M W: M L: M M: M))
   in
      fun {UsesMax Uses1 Uses2}
         % returns the pairwise maximum of Uses1 and Uses2
         {List.zip Uses1 Uses2 fun {$ Use1 Use2} UseMaxTable.Use1.Use2 end}
      end
   end

   proc {CheckUses Vs Kind Rep}
      {ForAll Vs proc {$ V} {V checkUse(Kind Rep)} end}
   end

   local
      fun {IsEnvCoordSub S}
         case S == ".env" then true
         elsecase S of _|R then {IsEnvCoordSub R}
         [] nil then false
         end
      end
   in
      fun {IsEnvCoord Coord}
         case Coord of posNoDebug(F _ _) then {IsEnvCoordSub {Atom.toString F}}
         [] pos(F _ _) then {IsEnvCoordSub {Atom.toString F}}
         [] pos(F _ _ _ _ _) then {IsEnvCoordSub {Atom.toString F}}
         [] unit then false
         end
      end
   end

   class AnnotateDefaults
      meth annotateGlobalVars(_ VsHd VsTl)
         VsHd = VsTl
      end
      meth markFirst(WarnFormals Rep)
         skip
      end
   end

   class AnnotateStatement
   end

   class AnnotateDeclaration
      meth annotateGlobalVars(Ls VsHd VsTl)
         {AnnotateGlobalVarsList @body {Append @localVars Ls} VsHd VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {ForAll @localVars proc {$ V} {V setUse(unused)} end}
         {MarkFirstList @body WarnFormals Rep}
         {CheckUses @localVars 'local variable' Rep}
      end
   end

   class AnnotateSkipNode from AnnotateDefaults
   end

   class AnnotateEquation
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter in
         {@left annotateGlobalVars(Ls VsHd VsInter)}
         {@right annotateGlobalVars(Ls VsInter VsTl)}
      end
      meth markFirst(WarnFormals Rep)
         {@left markFirst(WarnFormals Rep)}
         {@right markFirst(WarnFormals Rep)}
      end
   end

   class AnnotateConstruction
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter1 VsInter2 in
         {GetExpansionVars self VsHd VsInter1}
         {@label annotateGlobalVars(Ls VsInter1 VsInter2)}
         {FoldL @args
          proc {$ VsHd Arg VsTl}
             case Arg of F#T then VsInter in
                {F annotateGlobalVars(Ls VsHd VsInter)}
                {T annotateGlobalVars(Ls VsInter VsTl)}
             else
                {Arg annotateGlobalVars(Ls VsHd VsTl)}
             end
          end VsInter2 VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {MarkFirstExpansionOccs self WarnFormals Rep}
         {@label markFirst(WarnFormals Rep)}
         {ForAll @args
          proc {$ Arg}
             case Arg of F#T then
                {F markFirst(WarnFormals Rep)}
                {T markFirst(WarnFormals Rep)}
             else
                {Arg markFirst(WarnFormals Rep)}
             end
          end}
      end
   end

   class AnnotateDefinition
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter Vs in
         {@designator annotateGlobalVars(Ls VsHd VsInter)}
         {AnnotateGlobalVarsList @body @formalArgs ?Vs nil}
         globalVars <- {VariableUnion Vs nil}
         {FoldL Vs
          proc {$ VsHd V VsTl}
             case {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsInter VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {SetUninitVars @globalVars}
         {@designator markFirst(WarnFormals Rep)}
         {ForAll @formalArgs proc {$ V} {V setUse(wildcard)} end}
         {MarkFirstList @body WarnFormals Rep}
         case WarnFormals then
            {CheckUses @formalArgs 'formal parameter' Rep}
         else skip
         end
      end
   end
   class AnnotateFunctionDefinition
   end
   class AnnotateClauseBody
   end

   class AnnotateApplication
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter in
         {@designator annotateGlobalVars(Ls VsHd VsInter)}
         {AnnotateGlobalVarsList @actualArgs Ls VsInter VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {@designator markFirst(WarnFormals Rep)}
         {MarkFirstList @actualArgs WarnFormals Rep}
      end
   end

   class AnnotateBoolCase
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter1 VsInter2 VsInter3 in
         {GetExpansionVars self VsHd VsInter1}
         {@arbiter annotateGlobalVars(Ls VsInter1 VsInter2)}
         {@consequent annotateGlobalVars(Ls VsInter2 VsInter3)}
         {@alternative annotateGlobalVars(Ls VsInter3 VsTl)}
         globalVars <- {VariableUnion
                        {@consequent getGlobalVars($)}
                        {@alternative getGlobalVars($)}}
      end
      meth markFirst(WarnFormals Rep) OldUses NewUses1 NewUses2 in
         {SetUninitVars @globalVars}
         {MarkFirstExpansionOccs self WarnFormals Rep}
         {@arbiter markFirst(WarnFormals Rep)}
         OldUses = {GetUses @globalVars}
         {@consequent markFirstClause(@globalVars OldUses ?NewUses1
                                      WarnFormals Rep)}
         {@alternative markFirstClause(@globalVars OldUses ?NewUses2
                                       WarnFormals Rep)}
         {SetUses @globalVars {UsesMax NewUses1 NewUses2}}
      end
   end

   class AnnotateBoolClause
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) Vs in
         {AnnotateGlobalVarsList @body nil ?Vs nil}
         globalVars <- {VariableUnion Vs nil}
         {FoldL Vs
          proc {$ VsHd V VsTl}
             case {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth getGlobalVars($)
         @globalVars
      end
      meth markFirstClause(GlobalVars OldUses ?NewUses WarnFormals Rep)
         {MarkFirstList @body WarnFormals Rep}
         NewUses = {GetUses GlobalVars}
         {SetUses GlobalVars OldUses}
      end
   end

   class AnnotatePatternCase
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter1 VsInter2 in
         {@arbiter annotateGlobalVars(Ls VsHd VsInter1)}
         {FoldL @clauses
          proc {$ VsHd Clause VsTl}
             {Clause annotateGlobalVars(Ls VsHd VsTl)}
          end VsInter1 VsInter2}
         {@alternative annotateGlobalVars(Ls VsInter2 VsTl)}
         globalVars <- {FoldL @clauses
                        fun {$ Vs Clause}
                           {VariableUnion {Clause getGlobalVars($)} Vs}
                        end {@alternative getGlobalVars($)}}
      end
      meth markFirst(WarnFormals Rep) GlobalVars OldUses NewUses1 NewUses2 in
         GlobalVars = @globalVars
         {SetUninitVars GlobalVars}
         {@arbiter markFirst(WarnFormals Rep)}
         OldUses = {GetUses GlobalVars}
         {MarkFirstClauses @clauses GlobalVars OldUses ?NewUses1
          WarnFormals Rep}
         {@alternative markFirstClause(GlobalVars OldUses ?NewUses2
                                       WarnFormals Rep)}
         {SetUses GlobalVars {UsesMax NewUses1 NewUses2}}
      end
   end

   class AnnotatePatternClause
      attr globalVars: unit patternGlobalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) PatternVs Vs in
         {@pattern annotateGlobalVars(@localVars PatternVs nil)}
         patternGlobalVars <- {VariableUnion PatternVs nil}
         {AnnotateGlobalVarsList @body @localVars Vs nil}
         globalVars <- {VariableUnion Vs PatternVs}
         {FoldL Vs
          proc {$ VsHd V VsTl}
             case {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth getGlobalVars($)
         @globalVars
      end
      meth getPatternGlobalVars($)
         @patternGlobalVars
      end
      meth markFirstClause(GlobalVars OldUses ?NewUses WarnFormals Rep)
         {ForAll @localVars proc {$ V} {V setUse(wildcard)} end}
         {@pattern markFirst(WarnFormals Rep)}
         {MarkFirstList @body WarnFormals Rep}
         {CheckUses @localVars 'local variable' Rep}
         NewUses = {GetUses GlobalVars}
         {SetUses GlobalVars OldUses}
      end
   end

   class AnnotateRecordPattern
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter1 VsInter2 in
         {GetExpansionVars self VsHd VsInter1}
         {@label annotateGlobalVars(Ls VsInter1 VsInter2)}
         {FoldL @args
          proc {$ VsHd Arg VsTl}
             case Arg of F#P then VsInter in
                {F annotateGlobalVars(Ls VsHd VsInter)}
                {P annotateGlobalVars(Ls VsInter VsTl)}
             else
                {Arg annotateGlobalVars(Ls VsHd VsTl)}
             end
          end VsInter2 VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {MarkFirstExpansionOccs self WarnFormals Rep}
         {@label markFirst(WarnFormals Rep)}
         {ForAll @args
          proc {$ Arg}
             case Arg of F#P then
                {F markFirst(WarnFormals Rep)}
                {P markFirst(WarnFormals Rep)}
             else
                {Arg markFirst(WarnFormals Rep)}
             end
          end}
      end
   end

   class AnnotateEquationPattern
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter in
         {@left annotateGlobalVars(Ls VsHd VsInter)}
         {@right annotateGlobalVars(Ls VsInter VsTl)}
      end
      meth markFirst(WarnFormals Rep)
         {@left markFirst(WarnFormals Rep)}
         {@right markFirst(WarnFormals Rep)}
      end
   end

   class AnnotateAbstractElse
   end
   class AnnotateElseNode
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) Vs in
         {AnnotateGlobalVarsList @body nil ?Vs nil}
         globalVars <- {VariableUnion Vs nil}
         {FoldL Vs
          proc {$ VsHd V VsTl}
             case {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth getGlobalVars($)
         @globalVars
      end
      meth markFirstClause(GlobalVars OldUses ?NewUses WarnFormals Rep)
         {MarkFirstList @body WarnFormals Rep}
         NewUses = {GetUses GlobalVars}
         {SetUses GlobalVars OldUses}
      end
   end
   class AnnotateNoElse
      meth annotateGlobalVars(_ VsHd VsTl)
         {GetExpansionVars self VsHd VsTl}
      end
      meth getGlobalVars($)
         nil
      end
      meth markFirstClause(GlobalVars OldUses ?NewUses WarnFormals Rep)
         {MarkFirstExpansionOccs self WarnFormals Rep}
         NewUses = {GetUses GlobalVars}
         {SetUses GlobalVars OldUses}
      end
   end

   class AnnotateThreadNode
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) Vs in
         {AnnotateGlobalVarsList @body nil ?Vs nil}
         globalVars <- {VariableUnion Vs nil}
         {FoldL Vs
          proc {$ VsHd V VsTl}
             case {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {SetUninitVars @globalVars}
         {MarkFirstList @body WarnFormals Rep}
      end
   end

   class AnnotateTryNode
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter Vs in
         {AnnotateGlobalVarsList @tryBody nil Vs VsInter}
         {AnnotateGlobalVarsList @catchBody [@exception] VsInter nil}
         globalVars <- {VariableUnion Vs nil}
         {FoldL Vs
          proc {$ VsHd V VsTl}
             case {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {SetUninitVars @globalVars}
         {MarkFirstList @tryBody WarnFormals Rep}
         {@exception setUse(wildcard)}
         {MarkFirstList @catchBody WarnFormals Rep}
         {@exception checkUse('exception variable' Rep)}
      end
   end

   class AnnotateLockNode
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter in
         {@lockVar annotateGlobalVars(Ls VsHd VsInter)}
         {AnnotateGlobalVarsList @body Ls VsInter VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {@lockVar markFirst(WarnFormals Rep)}
         {MarkFirstList @body WarnFormals Rep}
      end
   end

   class AnnotateClassNode
      meth annotateGlobalVars(Ls VsHd VsTl)
         VsInter1 VsInter2 VsInter3 VsInter4 VsInter5 VsInter6 in
         {GetExpansionVars self VsHd VsInter1}
         {@designator annotateGlobalVars(Ls VsInter1 VsInter2)}
         {FoldL @parents
          proc {$ VsHd Parent VsTl}
             {Parent annotateGlobalVars(Ls VsHd VsTl)}
          end VsInter2 VsInter3}
         {FoldL @properties
          proc {$ VsHd Property VsTl}
             {Property annotateGlobalVars(Ls VsHd VsTl)}
          end VsInter3 VsInter4}
         {FoldL @attributes
          proc {$ VsHd I VsTl}
             case I of T1#T2 then VsInter in
                {T1 annotateGlobalVars(Ls VsHd VsInter)}
                {T2 annotateGlobalVars(Ls VsInter VsTl)}
             else
                {I annotateGlobalVars(Ls VsHd VsTl)}
             end
          end VsInter4 VsInter5}
         {FoldL @features
          proc {$ VsHd I VsTl}
             case I of T1#T2 then VsInter in
                {T1 annotateGlobalVars(Ls VsHd VsInter)}
                {T2 annotateGlobalVars(Ls VsInter VsTl)}
             else
                {I annotateGlobalVars(Ls VsHd VsTl)}
             end
          end VsInter5 VsInter6}
         {FoldL @methods
          proc {$ VsHd Method VsTl}
             {Method annotateGlobalVars(Ls VsHd VsTl)}
          end VsInter6 VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {MarkFirstExpansionOccs self WarnFormals Rep}
         {@designator markFirst(WarnFormals Rep)}
         {MarkFirstList @parents WarnFormals Rep}
         {MarkFirstList @properties WarnFormals Rep}
         {ForAll @attributes
          proc {$ T}
             case T of T1#T2 then
                {T1 markFirst(WarnFormals Rep)}
                {T2 markFirst(WarnFormals Rep)}
             else
                {T markFirst(WarnFormals Rep)}
             end
          end}
         {ForAll @features
          proc {$ T}
             case T of T1#T2 then
                {T1 markFirst(WarnFormals Rep)}
                {T2 markFirst(WarnFormals Rep)}
             else
                {T markFirst(WarnFormals Rep)}
             end
          end}
         {MarkFirstList @methods WarnFormals Rep}
      end
   end

   class AnnotateMethod
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl)
         Vs VsInter1 VsInter2 VsInter3 NewLs Vs1 in
         {GetExpansionVars self Vs VsInter1}
         {@label annotateGlobalVars(Ls VsInter1 VsInter2)}
         {FoldL @formalArgs
          proc {$ VsHd Arg VsTl}
             {{Arg getFeature($)} annotateGlobalVars(Ls VsHd VsTl)}
          end VsInter2 VsInter3}
         NewLs = {Map @formalArgs fun {$ Arg} {Arg getVariable($)} end}
         {AnnotateGlobalVarsList @body NewLs VsInter3 nil}
         Vs1 = {VariableUnion Vs nil}
         globalVars <- Vs1
         {FoldL Vs1
          proc {$ VsHd V VsTl}
             case {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {ForAll @formalArgs
          proc {$ A} {{A getVariable($)} setUse(wildcard)} end}
         {SetUninitVars @globalVars}
         {MarkFirstExpansionOccs self WarnFormals Rep}
         {@label markFirst(WarnFormals Rep)}
         {MarkFirstList @formalArgs WarnFormals Rep}
         {MarkFirstList @body WarnFormals Rep}
      end
   end
   class AnnotateMethodWithDesignator
      meth annotateGlobalVars(Ls VsHd VsTl)
         Vs VsInter1 VsInter2 VsInter3 NewLs Vs1 in
         {GetExpansionVars self Vs VsInter1}
         {@label annotateGlobalVars(Ls VsInter1 VsInter2)}
         {FoldL @formalArgs
          proc {$ VsHd Arg VsTl}
             {{Arg getFeature($)} annotateGlobalVars(Ls VsHd VsTl)}
          end VsInter2 VsInter3}
         NewLs = @messageDesignator|
                 {Map @formalArgs fun {$ Arg} {Arg getVariable($)} end}
         {AnnotateGlobalVarsList @body NewLs VsInter3 nil}
         Vs1 = {VariableUnion Vs nil}
         globalVars <- Vs1
         {FoldL Vs1
          proc {$ VsHd V VsTl}
             case {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {ForAll @formalArgs
          proc {$ A} {{A getVariable($)} setUse(wildcard)} end}
         {@messageDesignator setUse(wildcard)}
         {SetUninitVars @globalVars}
         {@label markFirst(WarnFormals Rep)}
         {MarkFirstList @formalArgs WarnFormals Rep}
         {MarkFirstList @body WarnFormals Rep}
         case WarnFormals then
            {@messageDesignator checkUse('message designator' Rep)}
         else skip
         end
      end
   end

   class AnnotateMethFormal
      meth markFirst(WarnFormals Rep)
         {@feature markFirst(WarnFormals Rep)}
      end
   end
   class AnnotateMethFormalOptional
   end
   class AnnotateMethFormalWithDefault
   end

   class AnnotateObjectLockNode
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter in
         {GetExpansionVars self VsHd VsInter}
         {AnnotateGlobalVarsList @body Ls VsInter VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {MarkFirstExpansionOccs self WarnFormals Rep}
         {MarkFirstList @body WarnFormals Rep}
      end
   end

   class AnnotateGetSelf
      meth annotateGlobalVars(Ls VsHd VsTl)
         {@destination annotateGlobalVars(Ls VsHd VsTl)}
      end
      meth markFirst(WarnFormals Rep)
         {@destination markFirst(WarnFormals Rep)}
      end
   end

   class AnnotateFailNode from AnnotateDefaults
   end

   class AnnotateIfNode
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter in
         {FoldL @clauses
          proc {$ VsHd Clause VsTl}
             {Clause annotateGlobalVars(Ls VsHd VsTl)}
          end VsHd VsInter}
         {@alternative annotateGlobalVars(Ls VsInter VsTl)}
         globalVars <- {FoldL @clauses
                        fun {$ Vs Clause}
                           {VariableUnion {Clause getGlobalVars($)} Vs}
                        end {@alternative getGlobalVars($)}}
      end
      meth markFirst(WarnFormals Rep) GlobalVars OldUses NewUses1 NewUses2 in
         GlobalVars = @globalVars
         {SetUninitVars GlobalVars}
         OldUses = {GetUses GlobalVars}
         {MarkFirstClauses @clauses GlobalVars OldUses ?NewUses1
          WarnFormals Rep}
         {@alternative markFirstClause(GlobalVars OldUses ?NewUses2
                                       WarnFormals Rep)}
         {SetUses GlobalVars {UsesMax NewUses1 NewUses2}}
      end
   end

   class AnnotateChoicesAndDisjunctions
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl)
         {FoldL @clauses
          proc {$ VsHd Clause VsTl}
             {Clause annotateGlobalVars(Ls VsHd VsTl)}
          end VsHd VsTl}
         globalVars <- {FoldL @clauses
                        fun {$ Vs Clause}
                           {VariableUnion {Clause getGlobalVars($)} Vs}
                        end nil}
      end
      meth markFirst(WarnFormals Rep) GlobalVars OldUses NewUses in
         GlobalVars = @globalVars
         {SetUninitVars GlobalVars}
         OldUses = {GetUses GlobalVars}
         {MarkFirstClauses @clauses GlobalVars OldUses ?NewUses
          WarnFormals Rep}
         {SetUses GlobalVars NewUses}
      end
   end
   class AnnotateOrNode
   end
   class AnnotateDisNode
   end
   class AnnotateChoiceNode
   end

   class AnnotateClause
      attr globalVars: unit guardGlobalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) VsGuard Vs in
         {AnnotateGlobalVarsList @guard @localVars VsGuard nil}
         guardGlobalVars <- {VariableUnion VsGuard nil}
         {AnnotateGlobalVarsList @body @localVars Vs nil}
         globalVars <- {VariableUnion Vs @guardGlobalVars}
         {FoldL Vs
          proc {$ VsHd V VsTl}
             case {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth getGlobalVars($)
         @globalVars
      end
      meth getGuardGlobalVars($)
         @guardGlobalVars
      end
      meth markFirstClause(GlobalVars OldUses ?NewUses WarnFormals Rep)
         {ForAll @localVars proc {$ V} {V setUse(unused)} end}
         {MarkFirstList @guard WarnFormals Rep}
         {MarkFirstList @body WarnFormals Rep}
         {CheckUses @localVars 'local clause variable' Rep}
         NewUses = {GetUses GlobalVars}
         {SetUses GlobalVars OldUses}
      end
   end

   class AnnotateValueNode from AnnotateDefaults
   end

   class AnnotateAtomNode from AnnotateDefaults
   end

   class AnnotateIntNode from AnnotateDefaults
   end

   class AnnotateFloatNode from AnnotateDefaults
   end

   class AnnotateVariable
      attr use: unit
      meth setUse(Use)
         use <- Use
      end
      meth getUse($)
         @use
      end
      meth checkUse(Kind Rep)
         case @origin == user then
            case {IsEnvCoord @coord} then skip
            elsecase @use of unused then
               {Rep warn(coord: @coord kind: BindingAnalysisWarning
                         msg: 'unused '#Kind#' '#pn(@printName))}
            [] wildcard then
               {Rep warn(coord: @coord kind: BindingAnalysisWarning
                         msg: Kind#' '#pn(@printName)#' used only once')}
            else skip
            end
         else skip
         end
      end
   end

   class AnnotateVariableOccurrence
      meth annotateGlobalVars(Ls VsHd VsTl) V = @variable in
         case {Member V Ls} then VsHd = VsTl
         else VsHd = V|VsTl
         end
      end
      meth markFirst(WarnFormals Rep)
         case {@variable getUse($)} of unused then
            {@variable setUse(wildcard)}
         [] wildcard then
            {@variable setUse(linear)}
         else   % linear or multiple
            {@variable setUse(multiple)}
         end
      end
   end

   class AnnotatePatternVariableOccurrence
   end
in
   Annotate = annotate(statement: AnnotateStatement
                       declaration: AnnotateDeclaration
                       skipNode: AnnotateSkipNode
                       equation: AnnotateEquation
                       construction: AnnotateConstruction
                       definition: AnnotateDefinition
                       functionDefinition: AnnotateFunctionDefinition
                       clauseBody: AnnotateClauseBody
                       application: AnnotateApplication
                       boolCase: AnnotateBoolCase
                       boolClause: AnnotateBoolClause
                       patternCase: AnnotatePatternCase
                       patternClause: AnnotatePatternClause
                       recordPattern: AnnotateRecordPattern
                       equationPattern: AnnotateEquationPattern
                       abstractElse: AnnotateAbstractElse
                       elseNode: AnnotateElseNode
                       noElse: AnnotateNoElse
                       threadNode: AnnotateThreadNode
                       tryNode: AnnotateTryNode
                       lockNode: AnnotateLockNode
                       classNode: AnnotateClassNode
                       method: AnnotateMethod
                       methodWithDesignator: AnnotateMethodWithDesignator
                       methFormal: AnnotateMethFormal
                       methFormalOptional: AnnotateMethFormalOptional
                       methFormalWithDefault: AnnotateMethFormalWithDefault
                       objectLockNode: AnnotateObjectLockNode
                       getSelf: AnnotateGetSelf
                       failNode: AnnotateFailNode
                       ifNode: AnnotateIfNode
                       choicesAndDisjunctions: AnnotateChoicesAndDisjunctions
                       orNode: AnnotateOrNode
                       disNode: AnnotateDisNode
                       choiceNode: AnnotateChoiceNode
                       clause: AnnotateClause
                       valueNode: AnnotateValueNode
                       atomNode: AnnotateAtomNode
                       intNode: AnnotateIntNode
                       floatNode: AnnotateFloatNode
                       variable: AnnotateVariable
                       variableOccurrence: AnnotateVariableOccurrence
                       patternVariableOccurrence:
                          AnnotatePatternVariableOccurrence)
end
