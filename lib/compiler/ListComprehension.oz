%%% Copyright © 2014, Université catholique de Louvain
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%
%%% *  Redistributions of source code must retain the above copyright notice,
%%%    this list of conditions and the following disclaimer.
%%% *  Redistributions in binary form must reproduce the above copyright notice,
%%%    this list of conditions and the following disclaimer in the documentation
%%%    and/or other materials provided with the distribution.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%%% POSSIBILITY OF SUCH DAMAGE.

%% Explanations related to this file are in
%% https://github.com/francoisfonteyn/thesis_public/blob/master/Thesis.pdf
%% Complete syntax
%% https://github.com/francoisfonteyn/thesis_public/blob/master/Syntax.pdf

functor
import
   BootName(newNamed:NewNamedName) at 'x-oz://boot/Name'

export
   Compile

define
   %% create a new variable named Name
   fun {MakeVar Name}
      fVar({NewNamedName Name} unit)
   end
   %% create a new variable named by the concatenation of Name and Index
   %% Name : atom
   %% Index : positive int
   fun {MakeVarIndex Name Index}
      fVar({NewNamedName {VirtualString.toAtom Name#Index}} unit)
   end
   %% create a new variable named by the concatenation of Name1, Index1, Name2 and Index2
   %% Name_ : atom
   %% Index_ : positive int
   fun {MakeVarIndexIndex Name1 Index1 Name2 Index2}
      fVar({NewNamedName {VirtualString.toAtom Name1#Index1#Name2#Index2}} unit)
   end
   %% efficiently puts all the elements in the list List into fAnd's (no fSkip execpt if nil)
   %% returns an AST rooted at fAnd(...) if at least 2 elements
   %% returns first element is only one
   %% returns fSkip(unit) if none
   fun {List2fAnds List}
      case List
      of nil   then fSkip(unit)
      [] H|nil then H
      [] H|T   then fAnd(H {List2fAnds T})
      end
   end
   %% returns a fLocal AST node with
   %% Decls as declarations
   %% Body as body
   %% EXCEPTION: if Decls is empty then returns only Body
   fun {LocalsIn Decls Body}
      if Decls == nil then
         Body
      else
         fLocal({List2fAnds Decls} Body unit)
      end
   end
   %% transforms a non-empty list: [e1 ... e2]
   %% into an AST list: fRecord(...)
   fun {LogicList2ASTList Fields}
      case Fields
      of nil then NIL
      [] H|T then fRecord(fAtom('|' unit) [H {LogicList2ASTList T}])
      end
   end
   %% --> assigns 3 lists in the same order
   %% - Fields:        the fields features
   %% - Expressions:   the fields values
   %% - Conditions:    the conditions
   %% --> assigns ReturnList to true iff a list must be returned and not a record
   %% --> assigns Outputs to the number of expressions
   proc {ParseExpressions EXPR_LIST ?Fields ?Expressions ?Conditions ?ReturnList ?Outputs}
      %% creates a dict of Ints
      %% each element is a feature explicitly given by user
      fun {CreateIntIndexDict EXPR_LIST}
         Dict = {NewDictionary}
      in
         for forExpression(H _) in EXPR_LIST do
            if {Label H} == fColon andthen {Label H.1} == fInt then
               {Dictionary.put Dict H.1.1 unit}
            end
         end
         Dict
      end
      %% Finds the next Int that is not in Dict
      %% starting from Wanted
      %% Returns the Int that can be used (Int not in Dict)
      %% The latter Int has been put in the Dict
      fun {FindNextInt Dict Wanted}
         if {Dictionary.member Dict Wanted} then
            {FindNextInt Dict Wanted+1}
         else
            {Dictionary.put Dict Wanted unit}
            Wanted
         end
      end
      %% Body of ParseExpressions
      proc {Aux List Fs Es Cs I N}
         case List
         of nil then
            Fs = nil
            Es = nil
            Cs = nil
            ReturnList = N == 1 andthen {Label EXPR_LIST.1.1} \= fColon
            andthen {Label EXPR_LIST.1} \= forFeature
            Outputs = N
         [] forExpression(Colon C)|T then NF NE NC in
            case Colon of fColon(F E) then
               Fs = F|NF
               Es = E|NE
               Cs = C|NC
               {Aux T NF NE NC I N+1}
            else W in
               W = {FindNextInt Dict I}
               Fs = fInt(W unit)|NF
               Es = Colon|NE
               Cs = C|NC
               {Aux T NF NE NC W+1 N+1}
            end
         end
      end
      Dict = {CreateIntIndexDict EXPR_LIST}
   in
      {Aux EXPR_LIST Fields Expressions Conditions 1 0}
   end
   %% same as List.map but with more lists
   %% 4 lists as input
   %% Fun is the function to apply with 4 arguments
   fun {Map4 Fields Expressions Conditions NextVars Fun}
      proc {Aux Fs Es Ns Cs ?R}
         case Fs#Es#Ns#Cs
         of nil#nil#nil#nil then
            R = nil
         [] (F|TF)#(E|TE)#(N|TN)#(C|TC) then NR in
            R = {Fun F E N C}|NR
            {Aux TF TE TN TC NR}
         end
      end
   in
      {Aux Fields Expressions Conditions NextVars}
   end
   %% creates a list with all the outputs
   %% NextsVar = [fVar('Next1' unit) ... fVar('NextN' unit)]
   %% NextsRecord is bound to the same list but with
   %%    each element put inside a fColon with its feature
   proc {CreateNextsForLastLevel Fields ?NextsRecord ?NextsVar}
      proc {Unzip XYs ?Xs ?Ys}
         case XYs
         of nil then
            Xs = nil
            Ys = nil
         [] (X#Y)|XYr then Xr Yr in
            Xs = X|Xr
            Ys = Y|Yr
            {Unzip XYr ?Xr ?Yr}
         end
      end
   in
      {Unzip {List.mapInd Fields fun {$ I Field}
                                    Var = {MakeVarIndex 'Next' I}
                                 in
                                    fColon(Field Var)#Var
                                 end}
       ?NextsRecord ?NextsVar}
   end
   %% Initiators = the next level initiators as a list
   %% Decls = the declarations to make before using Initiators
   %% used to initiate the next level (the first in Levels)
   %% Levels cannot be empty ! (this should never be needed because checked elsewhere)
   %% e.g. [fVar(...)]    if forGeneratorInt
   %% e.g. [fInt(...)]    if forGeneratorInt
   %% e.g. [fVar(...)]    if forGeneratorC
   %% e.g. [fInt(...)]    if forGeneratorC
   %% e.g. [fVar(...)]    if forGeneratorList
   %% e.g. [fRecord(...)] if forGeneratorList
   %% e.g. unit if no next level
   proc {NextLevelInitiators Levels Index ?Initiators ?Decls}
      %% Levels.1 == fForComprehensionLevel(...)
      %% Levels.1.1 == List of (forPattern(...) orelse forFrom(...) orelse forRecord(...) orelse forFlag(...))
      %% Levels.1.1.X.2 == (forGeneratorInt(...) orelse forGeneratorList(...) orelse forGeneratorC(...))
      proc {Aux Lvls ?Ini ?Dcl I}
         case Lvls
         of nil then
            Dcl = nil
            Ini = nil
         [] H|T then NI ND in
            case H
            of forFlag(_) then % lazy
               Ini = NI
               Dcl = ND
            [] forFrom(_ F) then % for I in {Fun}
               Ini = fApply(F nil unit)|NI
               Dcl = ND
            [] forRecord(_ _ F) then RecVar Feq Init in % for F:I in Record
               RecVar = {MakeVarIndexIndex 'Record' I 'At' Index+1}
               Feq = fEq(RecVar F unit)
               Init = fRecord(fAtom(record unit)
                              [fApply(fVar('Arity' unit) [RecVar] unit) RecVar])
               Ini = Init|NI
               Dcl = Feq|ND
            [] forPattern(_ F) then
               Dcl = ND
               case F
               of forGeneratorInt(L _ _) then Ini = L|NI % for I in L..H ; S
               [] forGeneratorList(L)    then Ini = L|NI % for I in L
               [] forGeneratorC(B _ _)   then Ini = B|NI % for I in B ; C ; S
               end
            end
            {Aux T NI ND I+1}
         end
      end
   in
      {Aux Levels.1.1 ?Initiators ?Decls 1}
   end
   %% WHERE A LOT HAPPENS -----------------------------------------
   %% creates all the range for the level containing the RangesList
   %% assigns Lazy to [fAtom(lazy pos(...))] if lazy, nil if not
   %% RangesList           : e.g. [forPattern forFlag forFrom ...]
   %% Index                : the index of this level
   %% Lazy                 : true if lazy, otherwise false
   %% RangesDeeper         : all the ranges to declare in signature of deeper levels. Assigned at next instruction
   %% RangeListDecl        : the declarations needed before testing the condition given by user
   %% NewExtraArgsForLists : returns all the ranges of this level generated as list
   %% RangesDeclCallNext   : all the ranges to call this level
   %% RangesConditionList  : the list of all conditions to fullfill to keep iterating this level
   %% --> for   I1 in R1   A in 1..2   I2 in R3   B in 1;B+1   C in 1..3   lazy
   %% Ranges               : [fVar(C unit)  fVar(B unit)  fVar(Range3At1 unit)  fVar(A unit)
   %%                        fVar(Range1At1 unit)]
   %% Lazy                 : true
   %% RangesDeeper         : [fVar(C unit)  fVar(B unit)  fVar(I3 unit)  fVar(A unit)  fVar(I1 unit)]
   %% RangeListDecl        : fAnd(fEq(fVar(I2 pos) fVar(Range3AtX.1 unit) unit)
   %%                             fEq(fVar(I1 pos) fVar(Range1AtX.1 unit) unit))
   %% NewExtraArgsForLists : [fVar(Range3AtX unit) fVar(Range1AtX unit)]
   %% RangesDeclCallNext   : [fOpApply('+'  [fVar('C' pos) INT1] unit)  ...]
   %% RangesConditionList  : [fOpApply('=<' [fVar('C' pos) fInt(3 unit)] unit)  ...}
   proc {MakeRanges RangesList Index Result
        ?Ranges ?Lazy ?RangesDeeper ?RangeListDecl ?NewExtraArgsForLists ?RangesDeclCallNext ?RangesConditionList}
      proc {Aux RList ?Ranges ?RangesDeeper IsLazy I ?RangeListDecl
            ?NewExtraArgsForLists ?RangesDeclCallNext ?RangesConditionList}
         %% Acc        : arguments of this level
         %% AccD       : arguments for next levels
         %% ListDecl   : declarations just after range condition and before user condition
         %% ExtraArgs  : extra arguments for next levels
         %% CallItself : how to call next iteration for this all the ranges of this level
         %% Conditions : user conditions
         case RList
         of nil then
            %% end of ranges for this level
            %% assign all unbounded variables
            Lazy                 = IsLazy
            RangesDeeper         = nil
            RangeListDecl        = nil
            NewExtraArgsForLists = nil
            RangesDeclCallNext   = nil
            RangesConditionList  = nil
            Ranges               = nil
         [] H|T then
            case H
            of forPattern(V P) then
               case P
               of forGeneratorList(_) then Var NR NRD NExtra Dcl Call Cond in
                  %% A in [1 2 3]
                  %% ------------
                  %% Ranges: RangeXatY
                  %% RangesDeeper: A
                  %% RangeListDecl: A = RangeXAtY.1
                  %% NewExtraArgsForLists: RangeXAtY
                  %% RangeDeclCallNext: RangeXAtY.2
                  %% RangesConditionList: RangeXAtY \= nil
                  %% IsLazy: no (keep old value)
                  Var = {MakeVarIndexIndex 'Range' I 'At' Index}
                  Ranges = Var|NR
                  RangesDeeper = V|NRD
                  NewExtraArgsForLists = Var|NExtra
                  RangesConditionList = fOpApply('\\='
                                                 [Var NIL]
                                                 unit)|Cond
                  RangeListDecl = fEq(V
                                      fOpApply('.' [Var INT1] unit)
                                      unit)|Dcl
                  RangesDeclCallNext = fOpApply('.'
                                                [Var INT2]
                                                unit)|Call
                  {Aux T NR NRD IsLazy I+1 Dcl NExtra Call Cond}
               [] forGeneratorInt(_ Hi St) then NR NRD Call Cond Var in
                  %% A in 1..11 ; 2
                  %% --------------
                  %% Ranges: A (create a variable if '_' instead of 'A')
                  %% RangesDeeper: same as Ranges
                  %% RangeListDecl: ---
                  %% NewExtraArgsForLists: ---
                  %% RangeDeclCallNext: A+2 (A+1 is no step given)
                  %% RangesConditionList: A =< 11
                  %% IsLazy: no (keep old value)
                  case V
                  of fWildcard(_) then Var = {MakeVar 'Wildcard'}
                  else Var = V
                  end
                  Ranges = Var|NR
                  RangesDeeper = Var|NRD
                  RangesDeclCallNext = fOpApply('+'
                                                [Var if St == unit then INT1 else St end]
                                                unit)|Call
                  RangesConditionList = fOpApply('=<' [Var Hi] unit)|Cond
                  {Aux T NR NRD IsLazy I+1 RangeListDecl NewExtraArgsForLists Call Cond}
               [] forGeneratorC(_ Cd St) then NR NRD Call Cond in
                  %% A in 1 ; A < 12 ; A+2
                  %% ---------------------
                  %% Ranges: A
                  %% RangesDeeper: same as Ranges
                  %% RangeListDecl: ---
                  %% NewExtraArgsForLists: ---
                  %% RangeDeclCallNext: A+2
                  %% RangesConditionList: A < 12 (nothing if no given)
                  %% IsLazy: no (keep old value)
                  RangesDeclCallNext = if St == unit then Cd else St end|Call
                  Ranges = V|NR
                  RangesDeeper = V|NRD
                  RangesConditionList = if St == unit then Cond else Cd|Cond end
                  {Aux T NR NRD IsLazy I+1 RangeListDecl NewExtraArgsForLists Call Cond}
               end
            [] forRecord(F V _) then Cond NewDeeper NewListDecl RecordVar ArityVar BRec Call NExtra NR in
               %% F:A in 1#2#3
               %% ------------
               %% Ranges: ArityXAtY#RecordXAtY
               %% RangesDeeper: F and A (omit if '_')
               %% RangeListDecl: F = ArityXAtY.1 and A = RecordXAtY.F (adapted if '_')
               %% NewExtraArgsForLists: ArityXAtY#RecordXAtY
               %% RangeDeclCallNext: ArityXAtY.2#RecordXAtY
               %% RangesConditionList: ArityXAtY \= nil
               %% IsLazy: no (keep old value)
               RecordVar = {MakeVarIndexIndex 'Record' I 'At' Index}
               ArityVar = {MakeVarIndexIndex 'Arity' I 'At' Index}
               BRec = fRecord(fAtom(record unit) [ArityVar RecordVar])
               Ranges = BRec|NR
               NewExtraArgsForLists = BRec|NExtra
               if {Label F} == fWildcard then
                  if {Label V} == fWildcard then
                     NewListDecl = RangeListDecl
                     NewDeeper = RangesDeeper
                  else
                     RangeListDecl = fEq(V
                                         fOpApply('.'
                                                  [RecordVar
                                                   fOpApply('.' [ArityVar INT1] unit)]
                                                  unit)
                                         unit)|NewListDecl
                     RangesDeeper = V|NewDeeper
                  end
               else
                  if {Label V} == fWildcard then
                     RangeListDecl = fEq(F fOpApply('.' [ArityVar INT1] unit) unit)|NewListDecl
                     RangesDeeper = F|NewDeeper
                  else
                     RangeListDecl= fEq(F fOpApply('.' [ArityVar INT1] unit) unit)
                                    |fEq(V fOpApply('.' [RecordVar F] unit) unit)|NewListDecl
                     RangesDeeper = F|V|NewDeeper
                  end
               end
               RangesDeclCallNext = fRecord(fAtom(record unit)
                                            [fOpApply('.' [ArityVar INT2] unit) RecordVar])|Call
               RangesConditionList = fOpApply('\\=' [ArityVar NIL] unit)|Cond
               {Aux T NR NewDeeper IsLazy I+1 NewListDecl NExtra Call Cond}
            [] forFrom(V F) then NRDCN NR NRD in
               %% A from Fun
               %% ----------
               %% Ranges: A
               %% RangesDeeper: A
               %% RangeListDecl: ---
               %% NewExtraArgsForLists: ---
               %% RangeDeclCallNext: {Fun}
               %% RangesConditionList: ---
               %% IsLazy: no (keep old value)
               RangesDeclCallNext = fApply(F nil unit)|NRDCN
               Ranges = V|NR
               RangesDeeper = V|NRD
               {Aux T NR NRD IsLazy I+1 RangeListDecl NewExtraArgsForLists NRDCN RangesConditionList}
            [] forFlag(F) then
               %% lazy
               %% ----
               %% nothing changes except
               %% IsLazy: true if was false before, error otherwise
               case F
               of fAtom(lazy C) then
                  %% is flag already there ?
                  if IsLazy then
                     {Exception.raiseError 'list comprehension'(doubleFlag(lazy C))}
                  else
                     {Aux T Ranges RangesDeeper true I+1 RangeListDecl
                      NewExtraArgsForLists RangesDeclCallNext RangesConditionList}
                  end
               else
                  {Exception.raiseError 'list comprehension'(unknownFlag(F.1 F.2))}
               end
            end
         end
      end
   in
      {Aux RangesList ?Ranges ?RangesDeeper false 1
       ?RangeListDecl ?NewExtraArgsForLists ?RangesDeclCallNext ?RangesConditionList}
   end
   %% creates the call to make for the next iteration on this level
   %% RangesDeclCallNext   : all the ranges to call  this level
   %% PreviousIds          : previous ids to put in call
   %% Name                 : name of the current level
   %% OldExtraArgsForLists : all the ranges of previous level generated as list
   %% ----> for A in _.._ ; 2 for B in _;_;B+1
   %% > {Level1 A+2}   at level 1
   %% > {Level2 B+1 A} at level 2
   %% ----> for A in R1 for B in R2
   %% > {Level1 Range1At1.2} at level 1 (Old = nil, New = [fVar('Range1At1' unit)])
   %% > {Level2 Range1At2.2 A Range1At1} at level 2 (Old = [fVar('Range1At1' unit)],
   %%                                                New = [fVar('Range1At2' unit)])
   fun {MakeNextCallItself RangesDeclCallNext PreviousIds NameVar OldExtraArgsForLists ResultVar}
      fApply(NameVar
             {List.append RangesDeclCallNext
              {List.append PreviousIds {List.append OldExtraArgsForLists [ResultVar]}}}
             unit)
   end
   %% RangesDeeper         : all the ranges to call
   %% PreviousIds          : previous ids to put in call
   %% {LevelX {NextLevelInitiators Levels} RangesDeeper PreviousIds ExtraArgsForLists}
   fun {MakeNextLevelCall RangesDeeper Levels NextLevelName PreviousIds ExtraArgsForLists ResultVar Index}
      Decls
      NextInitiators
      {NextLevelInitiators Levels Index ?NextInitiators ?Decls}
      Apply = fApply(%% function name
                     NextLevelName
                     %% args
                     {List.append NextInitiators
                      {List.append RangesDeeper
                       {List.append PreviousIds
                        {List.append ExtraArgsForLists [ResultVar]}}}}
                     %% position
                     unit)
   in
      {LocalsIn Decls Apply}
   end
   %% returns a big condition which is conjunction (andthen)
   %% of all the conditions that each range requires
   %% --> for   I1 in R1   A in 1..2   I2 in R3   B in 1;B<5;B+1   C in 1..3
   %% gives
   %% Range1\=nil andthen A=<2 andthen Range3\=nil andthen B<5 andthen C=<3
   fun {MakeRangesCondition RangesConditionList}
      case RangesConditionList
      of nil   then fAtom(true unit)
      [] H|nil then H
      [] H|T   then
         case H
         of fAtom(true _) then {MakeRangesCondition T}
         else fAndThen(H {MakeRangesCondition T} unit)
         end
      end
   end
   %% Replaces the last argument of the call (fApply) in the first argument
   %% by the new result (the one from this level) because it was the result
   %% of the previous level !
   fun {SwitchResultInPreviousLevelCall fApply(Name List unit) Result}
      Tmp1 = {Reverse List}
      Tmp2 = {Reverse Result|Tmp1.2}
   in
      fApply(Name Tmp2 unit)
   end
   %%=========================================
   %% last level: generates the following code
   %%
   %% local Next in
   %%    if {{ This_Level_Condition }} then
   %%       local {{ Next_1 ... Next_N }} in
   %%          Next = {{ '#'(field1:Next1 ... fieldN:NextN) }}
   %%          if {{ Is_Body }} then {{ Body }} end
   %%          {{ Forall I in Fields_Name }}
   %%             Result.I = if {{ Condition.I }} then Expression.I|Next_I
   %%                        else Next_I end
   %%          {{ end Forall }}
   %%       end
   %%    else
   %%       Next = Result
   %%    end
   %%    {LevelIndex %% current level
   %%     {{ Next_Iteration_For_The_Ranges_Of_This_Level }}
   %%     {{ Previous_Levels_Arguments }}
   %%     {{ Previous_List_Ranges }}
   %%     Next}
   %% end
   fun {CreateLastLevelNextCall Fields Expressions Conditions ResultVar BODY
        Condition RangesDeclCallNext PreviousIds NameVar OldExtraArgsForLists}
      NextLastVar = {MakeVar 'Next'}
      NextsRecord NextVars
      {CreateNextsForLastLevel Fields ?NextsRecord ?NextVars}
      NextAssignTrue  = fEq(NextLastVar fRecord(HASH NextsRecord) unit)
      NextAssignFalse = fEq(NextLastVar ResultVar                 unit)
      NextCall = {MakeNextCallItself RangesDeclCallNext PreviousIds NameVar
                  OldExtraArgsForLists NextLastVar}
      Assigns = {Map4 Fields Expressions Conditions NextVars
                 fun{$ F E C N}
                    TrueStat = fEq(fOpApply('.' [ResultVar F] unit)
                                   fRecord(fAtom('|' unit) [E N])
                                   unit)
                 in
                    if C == unit then %% no condition
                       TrueStat
                    else
                       fBoolCase(C
                                 TrueStat
                                 fEq(fOpApply('.' [ResultVar F] unit) N unit)
                                 unit)
                    end
                 end}
      TrueStat = fLocal({List2fAnds NextVars}
                        if BODY == unit then
                           {List2fAnds {List.append Assigns [NextAssignTrue]}}
                        else
                           {List2fAnds {List.append BODY|Assigns [NextAssignTrue]}}
                        end
                        unit)
      ThisLevelConditionStat = if Condition == unit then
                                  %% no level condition: consider it always true
                                  TrueStat
                               else
                                  fBoolCase(Condition TrueStat NextAssignFalse unit)
                               end
   in
      fLocal(NextLastVar fAnd(ThisLevelConditionStat NextCall) unit)
   end
   %% returns the next level call
   fun {CreateNotLastLevelNextCall NextLevelName Levels Index RangesDeeper
        PreviousIds ExtraArgsForLists ResultVar Condition NextCallItself}
      NextLevelCallNotLast = {MakeNextLevelCall RangesDeeper Levels NextLevelName
                              PreviousIds ExtraArgsForLists ResultVar Index}
   in
      if Condition == unit then NextLevelCallNotLast
      else fBoolCase(Condition NextLevelCallNotLast NextCallItself unit)
      end
   end
   %% usefull constants
   NIL = fAtom(nil unit)
   HASH = fAtom('#' unit)
   INT1 = fInt(1 unit)
   INT2 = fInt(2 unit)
   %%==================================================
   %%==================================================
   %% the actual exported function called by Unnester
   %% returns the AST with the mode fListComprehensions
   %% replaced by its transformation
   %% Argument : the fListComprehension node
   fun {Compile fListComprehension(EXPR_LIST FOR_COMPREHENSION_LIST BODY COORDS)}
      %% used to keep track of all the (level) procedures to declare
      TopLevelDeclsBuffer = {NewCell nil}
      proc {AddTopLevelDecl Value}
         TopLevelDeclsBuffer := Value|@TopLevelDeclsBuffer
      end
      %% returns an AST rooted at fAnd(...)
      %% to declare everything inside TopLevelDeclsBuffer (levels, ...)
      fun {GetTopLevelDecls}
         {List2fAnds @TopLevelDeclsBuffer}
      end
      %% generates all the levels of the list comprehension recursively
      %% starting from a 'fake' level called PreLevel
      %% each levels launch the generation the next level if exists
      fun {LevelsGenerator}
         %%====================================================================================
         %% generates the procedure AST for Level numbered Index (name is <Name/'Level'#Index>)
         %% puts it in the cell TopLevelDeclsBuffer at key 'Level'#Index
         %% returns the name (fVar) of the procedure generated
         %% Level               : fForComprehensionLevel([...] ... ...)
         %% Index               : int in [0, infinity]
         %% Levels              : the list of next levels
         %% PreviousIds         : list of the previous ranges name in the reverse order
         %% CallToPreviousLevel : how this level should call back the previous when done with range --> fApply(...)
         fun {LevelGenerator Level Index Levels PreviousIds CallToPreviousLevel OldExtraArgsForLists}
            %% the name of the function of this level
            NameVar           = {MakeVarIndex 'Level' Index}
            %% result
            ResultVar         = {MakeVar 'Result'}
            %% nil if not lazy, [fAtom(lazy pos(...))] if lazy
            Lazy
            %% all the ranges to declare in signature of deeper levels
            RangesDeeper
            %% the declarations needed before testing the condition given by user
            RangeListDecl
            %% arguments to add at next level because generator is a list and because of call back to previous level
            NewExtraArgsForLists
            %% the arguments of this level, with the transformation for next iteration
            RangesDeclCallNext
            %% the list of all conditions to fulfill to keep iterating this level
            RangesConditionList
            %% all the ranges to declare in signature of this level
            RangesDecl
            {MakeRanges Level.1 Index ResultVar ?RangesDecl ?Lazy ?RangesDeeper ?RangeListDecl
             ?NewExtraArgsForLists ?RangesDeclCallNext ?RangesConditionList}
            %% the call (fApply) to this level, one step forward
            NextCallItself    = {MakeNextCallItself RangesDeclCallNext PreviousIds
                                 NameVar OldExtraArgsForLists ResultVar}
            %% concatenation of NewExtraArgsForLists and OldExtraArgsForLists
            ExtraArgsForLists = {List.append NewExtraArgsForLists OldExtraArgsForLists}
            %% all the conditions to fulfill to keep iterating on this level
            RangesCondition   = {MakeRangesCondition RangesConditionList}
            %% the condition given by the user if any, unit otherwise
            Condition         = Level.2
            %% call to make for next if exists, EXPR|NextCallItself if not
            NextLevelCall     = if Levels == nil then
                                   {CreateLastLevelNextCall Fields Expressions Conditions ResultVar BODY
                                    Condition RangesDeclCallNext PreviousIds NameVar OldExtraArgsForLists}
                                else NextLevelName in
                                   NextLevelName = {LevelGenerator Levels.1 Index+1 Levels.2
                                                    {List.append RangesDeeper PreviousIds}
                                                    NextCallItself ExtraArgsForLists}
                                   {CreateNotLastLevelNextCall NextLevelName Levels Index RangesDeeper
                                    PreviousIds ExtraArgsForLists ResultVar Condition NextCallItself}
                                end
            Procedure =
            fProc(
               %% name
               NameVar
               %% arguments
               {List.append RangesDecl {List.append PreviousIds {List.append OldExtraArgsForLists [ResultVar]}}}
               %% body
               local
                  BodyStat =
                  local
                     TrueStat = {LocalsIn RangeListDecl NextLevelCall}
                  in
                     case RangesCondition
                     of fAtom(true _) then TrueStat
                     else fBoolCase(%% condition of ranges
                                    RangesCondition
                                    %% true
                                    TrueStat
                                    %% false
                                    if Index == 1 then
                                       %% first level so assign Result to nil
                                       {List2fAnds {Map Fields
                                        fun{$ F}
                                           fEq(fOpApply('.' [ResultVar F] unit)
                                               NIL
                                               unit)
                                        end}}
                                    else
                                       %% call previous level
                                       {SwitchResultInPreviousLevelCall CallToPreviousLevel ResultVar}
                                    end
                                    %% position
                                    unit)
                     end
                  end
                  LazyAndBodyStat =
                  if Lazy then
                     %% LAZY --------------------
                     fAnd(if Outputs == 1 then
                             %%=====================
                             %% lazy with one output
                             fApply(fVar('WaitNeeded' unit)
                                    [fOpApply('.' [ResultVar Fields.1] unit)]
                                    unit)
                          else
                             %%==========================
                             %% lazy with several outputs
                             fOpApplyStatement('Record.waitNeededFirst' [ResultVar] unit)
                          end
                          BodyStat) % end of fAnd (because of lazy...)
                  else
                     %% not lazy, just body, no waiting
                     BodyStat
                  end
               in
                  LazyAndBodyStat
               end
               %% flags
               nil
               %% position
               COORDS)
         in
            {AddTopLevelDecl Procedure}
            NameVar
         end %% end of LevelGenerator
         NameVar = {MakeVar 'PreLevel'}
         ResultVar = {MakeVar 'Result'}
         Level1Var  = {LevelGenerator FOR_COMPREHENSION_LIST.1 1 FOR_COMPREHENSION_LIST.2 nil unit nil}
      in
         %% put PreLevel in TopLevelDeclsBuffer
         {AddTopLevelDecl fProc(%% name
                                NameVar
                                %% arguments
                                [ResultVar]
                                %% body
                                local
                                   Decls
                                   Initiators
                                   {NextLevelInitiators FOR_COMPREHENSION_LIST 0 ?Initiators ?Decls}
                                   ResultArg = if ReturnList then
                                                  [fRecord(HASH [fColon(INT1 ResultVar)])]
                                               else
                                                  [ResultVar]
                                               end
                                   ApplyStat = fApply(Level1Var {List.append Initiators ResultArg} unit)
                                   BodyStat = {LocalsIn Decls ApplyStat}
                                in
                                   if ReturnList then
                                      BodyStat
                                   else RecordMake in
                                      RecordMake = fEq(ResultVar
                                                       fApply(fOpApply('.'
                                                                       [fVar('Record' unit) fAtom('make' unit)]
                                                                       unit)
                                                              [HASH {LogicList2ASTList Fields}]
                                                              unit)
                                                       unit)
                                      fAnd(RecordMake BodyStat)
                                   end
                                end
                                %% flags
                                nil
                                %% position
                                COORDS)
         }
         %% return name
         NameVar
      end %% end of LevelsGenerator
      %% true iff return list instead of record
      ReturnList
      %% the fields name of the outputs
      Fields
      %% the expressions to output (same order as Fields)
      Expressions
      %% the output-specific conditons (same order as Fields)
      Conditions
      %% number of outputs
      Outputs
      {ParseExpressions EXPR_LIST ?Fields ?Expressions ?Conditions ?ReturnList ?Outputs}
      %% launch the chain of level generation
      PreLevelVar = {LevelsGenerator}
   in
      %% return the actual tree rooted at fStepPoint
      fStepPoint(
         fLocal(
            %% all the declarations (levels and bounds)
            {GetTopLevelDecls}
            %% return the resulting list(s)
            fApply(PreLevelVar nil COORDS)
            %% LC position
            COORDS)
         %% list comprehension tag
         listComprehension
         %% keep position of list comprehension
         COORDS)
   end
end
