%%% Copyright 2014, Université Catholique de Louvain
%%%   All rights reserved.
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
prepare
   skip
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
   %%================================================
   %%================================================
   %% the actual exported function called by Unnester
   fun {Compile fRecordComprehension(EXPR_LIST RANGER RECORD FILTER CONDITION BODY COORDS)}
      %% used to keep track of all the (level) procedures to declare (see DeclareAll)
      %% used to keep trakc of all the bounds of range to declare e.g. Low..High (see DeclareAll)
      DeclarationsDictionary = {Dictionary.new}
      proc {Push Name Value}
         {Dictionary.put DeclarationsDictionary Name Value}
      end
      %% returns an AST rooted at fAnd(...)
      %% to declare everything inside DeclarationsDictionary (levels, ...)
      fun {DeclareAllDico}
         Decls = {Map {Dictionary.entries DeclarationsDictionary} fun{$ _#V} V end}
      in
         {DeclareAll Decls}
      end
      %% efficiently declare all the elements in the list List (no fSkip execpt if nil)
      %% returns an AST rooted at fAnd(...) if at least 2 elements
      %% returns first element is only one
      %% returns fSkip(unit) if none
      fun {DeclareAll List}
         proc {Aux Xs A}
            case Xs
            of H|nil then
               A = H
            [] H|T then B in
               A = fAnd(H B)
               {Aux T B}
            end
         end
         Next And
      in
         case List
         of nil then
            fSkip(unit)
         [] H|nil then
            H
         [] H|T then
            And = fAnd(H Next)
            {Aux T Next}
            And
         end
      end
      %% --> assigns 3 lists in the same order
      %% - Fields:      the fields features
      %% - Expressions: the fields values
      %% --> assigns ReturnOneRecord to true iff one record must be returned and not a record of records
      %% --> returns the number of expressions
      fun {ParseExpressions EXPR_LIST ?Fields ?Expressions ?ReturnList}
         %% inserts I inside List, keeping it sorted
         %% no duplicates are in this list before and after
         %% List : sorted List of Ints
         %% I    : Int to insert
         proc {InsertSortNoDuplicate List I ?Result}
            case List of nil then
               if I == unit then Result = nil
               else Result = I|nil
               end
            [] H|T then N in
               if I == unit orelse I > H then
                  Result = H|N
                  {InsertSortNoDuplicate T I N}
               elseif I == H then
                  Result = H|N
                  {InsertSortNoDuplicate T unit N}
               else
                  Result = I|H|N
                  {InsertSortNoDuplicate T unit N}
               end
            end
         end
         %% creates the list of Ints (no duplicate)
         %% each element is a feature explicitly given by user
         fun {CreateIntIndexList EXPR_LIST Acc}
            case EXPR_LIST
            of nil then Acc
            [] H|T then
               if {Label H} == fColon andthen {Label H.1} == fInt then
                  {CreateIntIndexList T {InsertSortNoDuplicate Acc H.1.1}}
               else
                  {CreateIntIndexList T Acc}
               end
            end
         end
         %% List : a sorted list of Ints
         %% E    : an Int
         %% return a tuple or unit
         %% - unit: if E < every element of List
         %%         this sould never happen with our use here
         %% - tuple: otherwise
         %%          first element of tuple is
         %%                the resulting list of removing E from List if exists
         %%          second element of tuple is
         %%                a boolean, true iff E is in List, false otherwise
         fun {ContainsSubtracts List E}
            case List
            of nil then List#false
            [] H|T then
               if H == E then T#true
               elseif H > E then List#false
               else unit
               end
            end
         end
         %% Finds the next Int that is not in List
         %% starting from Wanted
         %% -List:   list of sorted Ints
         %% -Wanted: an Int
         %% Returns a tuple of 2 elements
         %% -1st: List with first elements < Wanted removed
         %% -2nd: the Int that can be used (Int not in List)
         fun {FindNextInt List Wanted}
            local L B in
               L#B = {ContainsSubtracts List Wanted}
               if B then {FindNextInt L Wanted+1}
               else L#Wanted
               end
            end
         end
         %% Body of ParseExpressions
         fun {Aux List Fs Es Li I N}
            case List
            of nil then
               Fields = Fs
               Expressions = Es
               ReturnList = N == 1 andthen {Label EXPR_LIST.1} \= fColon
               N
            [] Colon|T then
               case Colon of fColon(F E) then
                  {Aux T F|Fs E|Es Li I N+1}
               else L W in
                  L#W = {FindNextInt Li I}
                  {Aux T fInt(W unit)|Fs Colon|Es L W+1 N+1}
               end
            end
         end
         Li = {CreateIntIndexList EXPR_LIST nil}
      in
         {Aux EXPR_LIST nil nil Li 1 0}
      end
      %% creates a list with all the outputs
      %% returns [fVar('Next1' unit) ... fVar('NextN' unit)]
      %% NextsRecord is bound to the same list but with
      %%    each element put inside a fColon with its feature
      fun {CreateNexts Outputs Fields ?NextsRecord}
         fun {Aux I Fs Acc1 Acc2}
            if I == 0 then
               NextsRecord = Acc2
               Acc1
            else Var in
               Var = {MakeVarIndex 'Next' I}
               {Aux I-1 Fs.2 Var|Acc1 fColon(Fs.1 Var)|Acc2}
            end
         end
      in
         {Aux Outputs Fields nil nil}
      end
      %% return the whole body of Level
      %% Fields : the list of features
      %% Rec    : the record
      %% Result : the result
      %% For1   : the fVar of the first for loop
      %% For2   : the fVar of the second for loop
      fun {LevelLocal Fields Rec Result For1 For2}
         fun {Aux Fs}
            case Fs
            of nil then CallFor2|nil
            [] H|T then
               fEq(fOpApply('.'
                            [Result H]
                            unit)
                   fApply(fOpApply('.' [fVar('Record' unit) fAtom(make unit)] unit)
                          [Lbl AriFull]
                          unit)
                   unit)|{Aux T}
            end
         end
         Lbl = {MakeVar 'Lbl'}
         Ari = {MakeVar 'Ari'}
         AriFull = {MakeVar 'AriFull'}
         AriBool = {MakeVar 'AriBool'}
         DeclLbl = fEq(Lbl fApply(fVar('Label' unit) [Rec] unit) unit)
         DeclAri = fEq(Ari fApply(fVar('Arity' unit) [Rec] unit) unit)
         CallFor1 = fApply(For1 [Ari Rec AriFull AriBool] unit)
         CallFor2 = fApply(For2 [Rec AriFull AriBool Result] unit)
      in
         fLocal(fAnd(DeclLbl fAnd(DeclAri fAnd(AriFull AriBool)))
                {DeclareAll CallFor1|{Aux Fields}}
                unit)
      end
      %% returns the fAnd(...) of all the assignments of Result.X.Feat
      %% for all X in Fields to Expressions.X
      %% Fields and Expressions have the same length, they are lists
      fun {AssignToExpression Result Feat Fields Expressions}
         fun {Aux Fs Es}
            case Fs#Es
            of nil#nil then nil
            [] (F|Ft)#(E|Et) then
               fEq(fOpApply('.'
                            [fOpApply('.' [Result F] unit)
                             Feat]
                            unit)
                   E
                   unit)|{Aux Ft Et}
            end
         end
      in
         {DeclareAll {Aux Fields Expressions}}
      end
      %% returns the record of outputs:
      %% each element is X:Result.X.Feat for all X in Fields
      fun {MakeCallBackRecord Result Feat Fields}
         fun {Aux Fs}
            case Fs
            of nil then nil
            [] F|Ft then
               fColon(F
                      fOpApply('.'
                               [fOpApply('.' [Result F] unit)
                                Feat]
                               unit))|{Aux Ft}
            end
         end
      in
         fRecord(fAtom('#' unit) {Aux Fields})
      end
      %% returns the feature and the value of the ranger given by user
      %% handles wildcards and absence of fields
      %% --> Feat#Ranger
      fun {GetFeatRanger}
         Feat
         Ranger
      in
         case RANGER
         of fColon(F V) then
            Feat = if {Label F} == fWildcard then {MakeVar 'Feat'}
                   else F
                   end
            Ranger = if {Label V} == fWildcard then {MakeVar 'Ranger'}
                     else V
                     end
         else
            Feat = {MakeVar 'Feat'}
            Ranger = if {Label RANGER} == fWildcard then {MakeVar 'Ranger'}
                     else RANGER
                     end
         end
         Feat#Ranger
      end
      %%====================================================================================
      %% generates the PreLevel
      fun {Generator}
         %% generates the first for loop procedure
         fun {For1Generator}
            %% the name of the function of the for1
            Name = {MakeVar 'For1'}
            %% arguments of the level
            AriArg = {MakeVar 'Ari'}
            RecArg = {MakeVar 'Rec'}
            AriFull = {MakeVar 'AriFull'}
            AriBool = {MakeVar 'AriBool'}
         in
            {Push 'For1'
             fProc(%% name
                   Name
                   %% arguments
                   [AriArg RecArg AriFull AriBool]
                   %% body
                   fBoolCase(%% condition
                             fOpApply('\\=' [AriArg fAtom(nil unit)] unit)
                             %% true
                             local
                                NextFull = {MakeVar 'NextFull'}
                                NextBool = {MakeVar 'NextBool'}
                                Feat#Ranger = {GetFeatRanger}
                                Filter = if FILTER == unit then fApply(fVar('IsDet' unit) [Ranger] unit)
                                         else fAndThen(FILTER fApply(fVar('IsDet' unit) [Ranger] unit) unit)
                                         end
                                AssignBool = fRecord(fAtom('|' unit) [Filter NextBool])
                                AssignFull = fBoolCase(%% condition
                                                       fOpApply('.' [AriBool fInt(1 unit)] unit)
                                                       %% true
                                                       fRecord(fAtom('|' unit) [Feat NextFull])
                                                       %% false
                                                       NextFull
                                                       %% position
                                                       unit)
                                CallFor1 = fApply(Name [fOpApply('.' [AriArg fInt(2 unit)] unit) RecArg NextFull NextBool] unit)
                             in
                                fLocal(%% decl
                                       fAnd(fEq(Feat fOpApply('.' [AriArg fInt(1 unit)] unit) unit)
                                            fAnd(fEq(Ranger fOpApply('.' [RecArg Feat] unit) unit)
                                                 fAnd(NextFull
                                                      NextBool)))
                                       %% body
                                       fAnd(fEq(AriBool AssignBool unit)
                                            fAnd(fEq(AriFull AssignFull unit)
                                                 CallFor1))
                                       %% position
                                       unit)
                             end
                             %% false
                             fAnd(fEq(AriFull fAtom(nil unit) unit)
                                  fEq(AriBool fAtom(nil unit) unit))
                             %% position
                             unit)
                   %% flag
                   nil
                   %% position
                   unit)}
            Name
         end
         %% generates the second for loop procedure
         fun {For2Generator Father}
            %% the name of the function of the for2
            Name = {MakeVar 'For2'}
            %% arguments of the level
            RecArg = {MakeVar 'Rec'}
            AriFull = {MakeVar 'AriFull'}
            AriBool = {MakeVar 'AriBool'}
            Result = {MakeVar 'Result'}
         in
            {Push 'For2'
             fProc(
                %% name
                Name
                %% arguments
                [RecArg AriFull AriBool Result]
                %% body
                fBoolCase(%% condition
                          fOpApply('\\=' [AriFull fAtom(nil unit)] unit)
                          %% true
                          local
                             Feat#Ranger = {GetFeatRanger}
                             TrueLocal = fLocal(%% decl
                                                fAnd(fEq(Feat fOpApply('.' [AriFull fInt(1 unit)] unit) unit)
                                                     fEq(Ranger fOpApply('.' [RecArg Feat] unit) unit))
                                                %% body
                                                fBoolCase(%% condition
                                                          local
                                                             IsRec = fApply(fVar('IsRecord' unit) [Ranger] unit)
                                                          in
                                                             if CONDITION == unit then IsRec
                                                             else fAndThen(IsRec CONDITION unit)
                                                             end
                                                          end
                                                          %% true: call Level
                                                          fApply(Father [Ranger
                                                                         {MakeCallBackRecord Result Feat Fields}]
                                                                 unit)
                                                          %% false: assign to expression and body
                                                          local
                                                             Asgns = {AssignToExpression Result Feat Fields Expressions}
                                                          in
                                                             if BODY == unit then Asgns
                                                             else fAnd(BODY Asgns)
                                                             end
                                                          end
                                                          %% position
                                                          unit)
                                                %% position
                                                unit)
                          in
                             fBoolCase(%% condition
                                       fOpApply('.' [AriBool fInt(1 unit)] unit)
                                       %% true
                                       fAnd(TrueLocal
                                            fApply(Name
                                                   [RecArg fOpApply('.' [AriFull fInt(2 unit)] unit)
                                                    fOpApply('.' [AriBool fInt(2 unit)] unit) Result]
                                                   unit))
                                       %% false
                                       fApply(Name
                                              [RecArg AriFull fOpApply('.' [AriBool fInt(2 unit)] unit) Result]
                                              unit)
                                       %% position
                                       unit)
                          end
                          %% false
                          fSkip(unit)
                          %% position
                          unit)
                %% flag
                nil
                %% position
                unit)}
            Name
         end %% end of For2Generator
         %% generates the procedure AST for the level (name is <Name/'Level'>)
         %% puts it in the dictionary DeclarationsDictionary at key 'Level'
         %% returns the name (fVar) of the procedure generated
         fun {LevelGenerator}
            %% the name of the function of the level
            Name = {MakeVar 'Level'}
            %% result
            Result = {MakeVar 'Result'}
            %% arguments of the level
            RecArg = {MakeVar 'Rec'}
            %% the procedure for the first for loop
            For1 = {For1Generator}
            %% the procedure for the second for loop
            For2 = {For2Generator Name}
         in
            {Push 'Level'
             fProc(
                %% name
                Name
                %% arguments
                [RecArg Result]
                %% body
                {LevelLocal Fields RecArg Result For1 For2}
                %% flags
                nil
                %% position
                unit)}
            Name
         end %% end of LevelGenerator
         Name = {MakeVar 'PreLevel'}
         Result = {MakeVar 'Result'}
         Level  = {LevelGenerator}
      in
         %% put PreLevel in dico at key 'PreLevel'
         {Push 'PreLevel' fProc(
                             %% name
                             Name
                             %% arguments
                             [Result]
                             %% body
                             local
                                NextsRecord
                                NextsToDecl = {CreateNexts Outputs Fields NextsRecord}
                                Body = if ReturnOneRecord then
                                          fApply(Level
                                                 [RECORD fRecord(fAtom('#' unit) [fColon(fInt(1 unit) Result)])]
                                                 unit)
                                       else
                                          fApply(Level
                                                 [RECORD fRecord(fAtom('#' unit) NextsRecord)]
                                                 unit)
                                       end
                             in
                                if ReturnOneRecord then
                                   Body
                                else
                                   fLocal(
                                      {DeclareAll NextsToDecl}
                                      fAnd(
                                         fEq(Result fRecord(fAtom('#' unit) NextsRecord) unit)
                                         Body)
                                      unit)
                                end
                             end
                             %% flags
                             nil
                             %% position
                             unit)
         }
         %% return name
         Name
      end %% end of Generator
      Fields
      Expressions
      ReturnOneRecord
      Outputs = {ParseExpressions EXPR_LIST Fields Expressions ReturnOneRecord}
      %% launch the generation
      PreLevel = {Generator}
   in
      %% return the actual tree rooted at fStepPoint
      fStepPoint(
         fLocal(
            %% all the declarations (levels and bounds)
            {DeclareAllDico}
            %% return the resulting record
            fApply(PreLevel nil unit)
            %% no position
            unit)
         %% record comprehension tag
         recordComprehension
         %% keep position of record comprehension
         COORDS)
   end %% end of Compile
end