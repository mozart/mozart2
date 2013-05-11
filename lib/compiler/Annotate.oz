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

functor
export
   typeOf: AnnotateTypeOf
   stepPoint: AnnotateStepPoint
   declaration: AnnotateDeclaration
   skipNode: AnnotateDefaults
   equation: AnnotateEquation
   construction: AnnotateConstruction
   definition: AnnotateDefinition
   application: AnnotateApplication
   ifNode: AnnotateIfNode
   ifClause: AnnotateIfClause
   patternCase: AnnotatePatternCase
   patternClause: AnnotatePatternClause
   sideCondition: AnnotateSideCondition
   recordPattern: AnnotateRecordPattern
   equationPattern: AnnotateEquationPattern
   elseNode: AnnotateElseNode
   noElse: AnnotateNoElse
   tryNode: AnnotateTryNode
   lockNode: AnnotateLockNode
   classNode: AnnotateClassNode
   method: AnnotateMethod
   methFormal: AnnotateMethFormal
   methFormalOptional: AnnotateMethFormal
   methFormalWithDefault: AnnotateMethFormalWithDefault
   objectLockNode: AnnotateObjectLockNode
   getSelf: AnnotateGetSelf
   exceptionNode: AnnotateDefaults
   valueNode: AnnotateValueNode
   userVariable: AnnotateUserVariable
   generatedVariable: AnnotateGeneratedVariable
   restrictedVariable: AnnotateRestrictedVariable
   variableOccurrence: AnnotateVariableOccurrence
define
   BindingAnalysisWarning = 'binding analysis warning'

   fun {VariableUnion Vs Ws}
      %% Adjoins all variables of Vs to Ws.  Specifically, if Ws is nil,
      %% then this function returns Vs with all duplicates removed.
      case Vs of V|Vr then
         if {Member V Ws} then {VariableUnion Vr Ws}
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

   proc {SetUninitVars GlobalVars}
      {ForAll GlobalVars
       proc {$ V}
          if {V getUse($)} == unused then {V setUse(wildcard)} end
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
         %% Returns the pairwise maximum of Uses1 and Uses2.
         {List.zip Uses1 Uses2 fun {$ Use1 Use2} UseMaxTable.Use1.Use2 end}
      end
   end

   proc {CheckUses Vs Kind Rep}
      {ForAll Vs proc {$ V} {V checkUse(Kind Rep)} end}
   end

   class AnnotateDefaults
      meth annotateGlobalVars(_ VsHd VsTl)
         VsHd = VsTl
      end
      meth markFirst(WarnFormals Rep)
         skip
      end
   end

   class AnnotateTypeOf
      meth annotateGlobalVars(Ls VsHd VsTl)
         {@res annotateGlobalVars(Ls VsHd VsTl)}
      end
      meth markFirst(WarnFormals Rep)
         {@res markFirst(WarnFormals Rep)}
      end
   end

   class AnnotateStepPoint
      meth annotateGlobalVars(Ls VsHd VsTl)
         {AnnotateGlobalVarsList @statements Ls VsHd VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {MarkFirstList @statements WarnFormals Rep}
      end
   end

   class AnnotateDeclaration
      meth annotateGlobalVars(Ls VsHd VsTl)
         {AnnotateGlobalVarsList @statements {Append @localVars Ls} VsHd VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {ForAll @localVars proc {$ V} {V setUse(unused)} end}
         {MarkFirstList @statements WarnFormals Rep}
         {CheckUses @localVars 'local variable' Rep}
      end
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
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter in
         {@label annotateGlobalVars(Ls VsHd VsInter)}
         {FoldL @args
          proc {$ VsHd Arg VsTl}
             case Arg of F#T then VsInter in
                {F annotateGlobalVars(Ls VsHd VsInter)}
                {T annotateGlobalVars(Ls VsInter VsTl)}
             else
                {Arg annotateGlobalVars(Ls VsHd VsTl)}
             end
          end VsInter VsTl}
      end
      meth markFirst(WarnFormals Rep)
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
         {AnnotateGlobalVarsList @statements @formalArgs ?Vs nil}
         globalVars <- {VariableUnion Vs nil}
         {FoldL Vs
          proc {$ VsHd V VsTl}
             if {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsInter VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {SetUninitVars @globalVars}
         {@designator markFirst(WarnFormals Rep)}
         {ForAll @formalArgs proc {$ V} {V setUse(wildcard)} end}
         {MarkFirstList @statements WarnFormals Rep}
         if WarnFormals then
            {CheckUses @formalArgs 'formal parameter' Rep}
         end
      end
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

   class AnnotateIfNode
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter1 VsInter2 in
         {@arbiter annotateGlobalVars(Ls VsHd VsInter1)}
         {@consequent annotateGlobalVars(Ls VsInter1 VsInter2)}
         {@alternative annotateGlobalVars(Ls VsInter2 VsTl)}
         globalVars <- {VariableUnion
                        {@consequent getGlobalVars($)}
                        {@alternative getGlobalVars($)}}
      end
      meth markFirst(WarnFormals Rep) OldUses NewUses1 NewUses2 in
         {SetUninitVars @globalVars}
         {@arbiter markFirst(WarnFormals Rep)}
         OldUses = {GetUses @globalVars}
         {@consequent markFirstClause(@globalVars OldUses ?NewUses1
                                      WarnFormals Rep)}
         {@alternative markFirstClause(@globalVars OldUses ?NewUses2
                                       WarnFormals Rep)}
         {SetUses @globalVars {UsesMax NewUses1 NewUses2}}
      end
   end

   class AnnotateIfClause
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) Vs in
         {AnnotateGlobalVarsList @statements nil ?Vs nil}
         globalVars <- {VariableUnion Vs nil}
         {FoldL Vs
          proc {$ VsHd V VsTl}
             if {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth getGlobalVars($)
         @globalVars
      end
      meth markFirstClause(GlobalVars OldUses ?NewUses WarnFormals Rep)
         {MarkFirstList @statements WarnFormals Rep}
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
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) Vs VsInter Ls1 in
         {@pattern annotateGlobalVars(@localVars Vs VsInter)}
         Ls1 = {Append {@pattern getLocalVars($)} @localVars}
         {AnnotateGlobalVarsList @statements Ls1 VsInter nil}
         globalVars <- {VariableUnion Vs nil}
         {FoldL Vs
          proc {$ VsHd V VsTl}
             if {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth getGlobalVars($)
         @globalVars
      end
      meth markFirstClause(GlobalVars OldUses ?NewUses WarnFormals Rep)
         {ForAll @localVars proc {$ V} {V setUse(unused)} end}
         {@pattern markFirst(WarnFormals Rep)}
         {MarkFirstList @statements WarnFormals Rep}
         {CheckUses @localVars 'pattern variable' Rep}
         NewUses = {GetUses GlobalVars}
         {SetUses GlobalVars OldUses}
      end
   end

   class AnnotateSideCondition
      meth annotateGlobalVars(Ls VsHd VsTl) Ls1 VsInter1 VsInter2 in
         Ls1 = {Append @localVars Ls}
         {@pattern annotateGlobalVars(Ls1 VsHd VsInter1)}
         {AnnotateGlobalVarsList @statements Ls1 VsInter1 VsInter2}
         {@arbiter annotateGlobalVars(Ls1 VsInter2 VsTl)}
      end
      meth getLocalVars($)
         @localVars
      end
      meth markFirst(WarnFormals Rep)
         {@pattern markFirst(WarnFormals Rep)}
         {ForAll @localVars proc {$ V} {V setUse(wildcard)} end}
         {MarkFirstList @statements WarnFormals Rep}
         {@arbiter markFirst(WarnFormals Rep)}
         {CheckUses @localVars 'local variable' Rep}
      end
   end

   class AnnotateRecordPattern
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter in
         {@label annotateGlobalVars(Ls VsHd VsInter)}
         {FoldL @args
          proc {$ VsHd Arg VsTl}
             case Arg of F#P then VsInter in
                {F annotateGlobalVars(Ls VsHd VsInter)}
                {P annotateGlobalVars(Ls VsInter VsTl)}
             else
                {Arg annotateGlobalVars(Ls VsHd VsTl)}
             end
          end VsInter VsTl}
      end
      meth getLocalVars($)
         nil
      end
      meth markFirst(WarnFormals Rep)
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
      meth getLocalVars($)
         nil
      end
      meth markFirst(WarnFormals Rep)
         {@left markFirst(WarnFormals Rep)}
         {@right markFirst(WarnFormals Rep)}
      end
   end

   class AnnotateElseNode
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) Vs in
         {AnnotateGlobalVarsList @statements nil ?Vs nil}
         globalVars <- {VariableUnion Vs nil}
         {FoldL Vs
          proc {$ VsHd V VsTl}
             if {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth getGlobalVars($)
         @globalVars
      end
      meth markFirstClause(GlobalVars OldUses ?NewUses WarnFormals Rep)
         {MarkFirstList @statements WarnFormals Rep}
         NewUses = {GetUses GlobalVars}
         {SetUses GlobalVars OldUses}
      end
   end
   class AnnotateNoElse
      meth annotateGlobalVars(_ VsHd VsTl)
         VsHd = VsTl
      end
      meth getGlobalVars($)
         nil
      end
      meth markFirstClause(GlobalVars OldUses ?NewUses WarnFormals Rep)
         NewUses = {GetUses GlobalVars}
         {SetUses GlobalVars OldUses}
      end
   end

   class AnnotateTryNode
      attr globalVars: unit
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter Vs in
         {AnnotateGlobalVarsList @tryStatements nil Vs VsInter}
         {AnnotateGlobalVarsList @catchStatements [@exception] VsInter nil}
         globalVars <- {VariableUnion Vs nil}
         {FoldL Vs
          proc {$ VsHd V VsTl}
             if {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {SetUninitVars @globalVars}
         {MarkFirstList @tryStatements WarnFormals Rep}
         {@exception setUse(wildcard)}
         {MarkFirstList @catchStatements WarnFormals Rep}
         {@exception checkUse('exception variable' Rep)}
      end
   end

   class AnnotateLockNode
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter in
         {@lockVar annotateGlobalVars(Ls VsHd VsInter)}
         {AnnotateGlobalVarsList @statements Ls VsInter VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {@lockVar markFirst(WarnFormals Rep)}
         {MarkFirstList @statements WarnFormals Rep}
      end
   end

   class AnnotateClassNode
      meth annotateGlobalVars(Ls VsHd VsTl)
         VsInter1 VsInter2 VsInter3 VsInter4 VsInter5 in
         {@designator annotateGlobalVars(Ls VsHd VsInter1)}
         {FoldL @parents
          proc {$ VsHd Parent VsTl}
             {Parent annotateGlobalVars(Ls VsHd VsTl)}
          end VsInter1 VsInter2}
         {FoldL @properties
          proc {$ VsHd Property VsTl}
             {Property annotateGlobalVars(Ls VsHd VsTl)}
          end VsInter2 VsInter3}
         {FoldL @attributes
          proc {$ VsHd I VsTl}
             case I of T1#T2 then VsInter in
                {T1 annotateGlobalVars(Ls VsHd VsInter)}
                {T2 annotateGlobalVars(Ls VsInter VsTl)}
             else
                {I annotateGlobalVars(Ls VsHd VsTl)}
             end
          end VsInter3 VsInter4}
         {FoldL @features
          proc {$ VsHd I VsTl}
             case I of T1#T2 then VsInter in
                {T1 annotateGlobalVars(Ls VsHd VsInter)}
                {T2 annotateGlobalVars(Ls VsInter VsTl)}
             else
                {I annotateGlobalVars(Ls VsHd VsTl)}
             end
          end VsInter4 VsInter5}
         {FoldL @methods
          proc {$ VsHd Method VsTl}
             {Method annotateGlobalVars(Ls VsHd VsTl)}
          end VsInter5 VsTl}
      end
      meth markFirst(WarnFormals Rep)
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
         Vs VsInter1 VsInter2 NewLs0 NewLs Vs1
      in
         {@'self' setUse(multiple)}
         {@label annotateGlobalVars(Ls Vs VsInter1)}
         {FoldL @formalArgs
          proc {$ VsHd Arg VsTl}
             {Arg annotateGlobalVars(Ls VsHd VsTl)}
          end VsInter1 VsInter2}
         NewLs0 = {Map @formalArgs fun {$ Arg} {Arg getVariable($)} end}
         NewLs = case @messageDesignator of unit then NewLs0
                 elseof V then V|NewLs0
                 end
         {AnnotateGlobalVarsList @statements NewLs VsInter2 nil}
         Vs1 = {VariableUnion Vs nil}
         globalVars <- Vs1
         {FoldL Vs1
          proc {$ VsHd V VsTl}
             if {Member V Ls} then VsHd = VsTl
             else VsHd = V|VsTl
             end
          end VsHd VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {ForAll @formalArgs
          proc {$ A} {{A getVariable($)} setUse(wildcard)} end}
         case @messageDesignator of unit then skip
         elseof V then {V setUse(wildcard)}
         end
         {SetUninitVars @globalVars}
         {@label markFirst(WarnFormals Rep)}
         {MarkFirstList @formalArgs WarnFormals Rep}
         {MarkFirstList @statements WarnFormals Rep}
         if WarnFormals andthen @messageDesignator \= unit then
            {@messageDesignator checkUse('message designator' Rep)}
         end
      end
   end

   class AnnotateMethFormal
      meth markFirst(WarnFormals Rep)
         {@feature markFirst(WarnFormals Rep)}
      end
      meth annotateGlobalVars(Ls VsHd VsTl)
         {@feature annotateGlobalVars(Ls VsHd VsTl)}
      end
   end
   class AnnotateMethFormalWithDefault
      meth markFirst(WarnFormals Rep)
         {@feature markFirst(WarnFormals Rep)}
         case @default of unit then skip
         elseof VO then {VO markFirst(WarnFormals Rep)}
         end
      end
      meth annotateGlobalVars(Ls VsHd VsTl) VsInter in
         {@feature annotateGlobalVars(Ls VsHd VsInter)}
         case @default of unit then VsInter = VsTl
         elseof VO then {VO annotateGlobalVars(Ls VsInter VsTl)}
         end
      end
   end

   class AnnotateObjectLockNode
      meth annotateGlobalVars(Ls VsHd VsTl)
         {AnnotateGlobalVarsList @statements Ls VsHd VsTl}
      end
      meth markFirst(WarnFormals Rep)
         {MarkFirstList @statements WarnFormals Rep}
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

   class AnnotateValueNode from AnnotateDefaults
      meth getLocalVars($)
         nil
      end
   end

   class AnnotateUserVariable
      attr use: unit
      meth setUse(Use)
         use <- Use
      end
      meth getUse($)
         @use
      end
      meth checkUse(Kind Rep)
         case @use of unused then
            {Rep warn(coord: @coord kind: BindingAnalysisWarning
                      msg: 'unused '#Kind#' '#pn(@printName))}
         [] wildcard then
            {Rep warn(coord: @coord kind: BindingAnalysisWarning
                      msg: Kind#' '#pn(@printName)#' used only once')}
         else skip
         end
      end
   end

   class AnnotateRestrictedVariable from AnnotateUserVariable
      meth checkUse(Kind Rep)
         case @use of unused then
            {Rep warn(coord: @coord kind: BindingAnalysisWarning
                      msg: 'unused '#Kind#' '#pn(@printName))}
         [] wildcard then
            {Rep warn(coord: @coord kind: BindingAnalysisWarning
                      msg: Kind#' '#pn(@printName)#' used only once')}
         else
            AnnotateRestrictedVariable, CheckUse(@features Rep)
         end
      end
      meth CheckUse(Fs Rep)
         case Fs of X|Fr then
            case X of F#C#B then
               if {IsFree B} then
                  {Rep warn(coord: C kind: BindingAnalysisWarning
                            msg: ('feature '#pn(@printName)#'.'#oz(F)#
                                  ' imported but never used'))}
               end
            [] _#_#_#_ then skip
            end
            AnnotateRestrictedVariable, CheckUse(Fr Rep)
         [] nil then skip
         end
      end
   end

   class AnnotateGeneratedVariable
      meth setUse(Use)
         skip
      end
      meth getUse($)
         multiple
      end
      meth checkUse(Kind Rep)
         skip
      end
   end

   class AnnotateVariableOccurrence
      meth annotateGlobalVars(Ls VsHd VsTl) V = @variable in
         if {Member V Ls} then VsHd = VsTl
         else VsHd = V|VsTl
         end
      end
      meth getLocalVars($)
         nil
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
end
