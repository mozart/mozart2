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
%% https://github.com/francoisfonteyn/thesis_public/blob/master/OzComprehensionsThesis.pdf
%% Complete syntax
%% https://github.com/francoisfonteyn/thesis_public/blob/master/Tutorial.pdf

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
   NIL = fAtom(nil unit)
   HASH = fAtom('#' unit)
   INT1 = fInt(1 unit)
   INT2 = fInt(2 unit)
   %% transforms a non-empty list: [e1 ... e2]
   %% into an AST list: fRecord(...)
   fun {LogicList2ASTList Fields}
      case Fields
      of nil then NIL
      [] H|T then fRecord(fAtom('|' unit) [H {LogicList2ASTList T}])
      end
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
   %% --> assigns 3 lists in the same order
   %% - Fields:        the fields features
   %% - Expressions:   the fields values
   %% - Conditions:    the conditions
   %% --> assigns ReturnList to true iff a list must be returned and not a record
   proc {ParseExpressions EXPR_LIST ?Fields ?Expressions ?Conditions ?ReturnList}
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
   %% creates a list with all the outputs
   %% NextsVar = [fVar(Name unit) ... fVar(Name unit)]
   %% NextsRecord is bound to the same list but with
   %%    each element put inside a fColon with its feature
   proc {CreateNexts Fields Name ?NextsRecord ?NextsVar}
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
                                    Var = {MakeVarIndex Name I}
                                 in
                                    fColon(Field Var)#Var
                                 end}
       ?NextsRecord ?NextsVar}
   end
   %% List.map with 2 lists
   fun {Map2 L1 L2 Fun}
      proc {Aux L1 L2 ?R}
         case L1#L2
         of nil#nil then R = nil
         [] (H1|T1)#(H2|T2) then NR in
            R = {Fun H1 H2}|NR
            {Aux T1 T2 NR}
         end
      end
   in
      {Aux L1 L2}
   end
   %% return the creations of all the output records of Level
   %% Fields    : the fields of Result
   %% LblArg    : the label
   %% NextsVar  : the arities
   %% ResultVar : the result
   fun {CreateRecords LblArg NextsVar ResultVar Fields}
      {Map2 NextsVar Fields fun{$ N F}
                               fApply(fOpApply('.' [fVar('Record' unit) fAtom('make' unit)] unit)
                                      [LblArg N fOpApply('.' [ResultVar F] unit)]
                                      unit)
                            end}
   end
   %% returns a list of L1.I = L2.I
   %% for recursively all I
   fun {Map2Eq L1 L2}
      {Map2 L1 L2 fun{$ A B}fEq(A B unit)end}
   end
   %% returns a list of ArisArg.I = if Conditions.I then FeatVar|NextsVar.I else |NextsVar.I end
   %% for recursively all I
   fun {Map31Cond ArisArg Conditions NextsVar FeatVar}
      proc {Aux L1 L2 L3 ?R}
         case L1#L2#L3
         of nil#nil#nil then R = nil
         [] (H1|T1)#(H2|T2)#(H3|T3) then TrueStat LeftStat NR in
            TrueStat = fRecord(fAtom('|' unit) [FeatVar H3])
            LeftStat = if H2 == unit then TrueStat
                       else fBoolCase(H2 TrueStat H3 unit)
                       end
            R = fEq(H1 LeftStat unit)|NR
            {Aux T1 T2 T3 NR}
         end
      end
   in
      {Aux ArisArg Conditions NextsVar}
   end
   %% returns a list of
   %%
   %% if ArisArg.I \= nil andthen FeatVar == ArisArg.I.1 then
   %%    ResultArg.(Fields.I).FeatVar = ValVar
   %%    NextsVar.I = ArisArg.I.2
   %% else
   %%    NextsVar.I = ArisArg.I
   %% end
   %%
   %% for recursively all I
   fun {Map42if ArisArg Fields NextsVar Expressions FeatVar ResultArg}
      proc {Aux L1 L2 L3 L4 ?R}
         case L1#L2#L3#L4
         of nil#nil#nil#nil then R = nil
         [] (H1|T1)#(H2|T2)#(H3|T3)#(H4|T4) then Cond1 Cond2 TrueStat FalseStat NR in
            Cond1 = fOpApply('\\=' [H1 NIL] unit)
            Cond2 = fOpApply('==' [FeatVar fOpApply('.' [H1 INT1] unit)] unit)
            TrueStat = fAnd(fEq(fOpApply('.' [fOpApply('.' [ResultArg H2] unit) FeatVar] unit) H4 unit)
                            fEq(H3 fOpApply('.' [H1 INT2] unit) unit))
            FalseStat = fEq(H3 H1 unit)
            R = fBoolCase(fAndThen(Cond1 Cond2 unit) TrueStat FalseStat unit)|NR
            {Aux T1 T2 T3 T4 NR}
         end
      end
   in
      {Aux ArisArg Fields NextsVar Expressions}
   end
   %% returns the feature and the value of the ranger given by user
   %% handles wildcards
   %% --> Feat # WhetherFeatGivenByUser # Val # WhetherValGivenByUser
   fun {GetRanger Ranger}
      fun {Aux A B}
         if {Label A} == fWildcard then {MakeVar B}#false
         else A#true
         end
      end
      F#GF = {Aux Ranger.1 'Feat'}
      V#GV = {Aux Ranger.2 'Val'}
   in
      F#GF#V#GV
   end
   %%==================================================
   %%==================================================
   %% the actual exported function called by Unnester
   %% returns the AST with the mode fListComprehensions
   %% replaced by its transformation
   %% Argument : the fListComprehension node
   fun {Compile fRecordComprehension(EXPR_LIST RANGER RECORD FILTER BODY COORDS)}
      %% used to keep track of all the procedures to declare
      TopLevelDeclsBuffer = {NewCell nil}
      proc {AddTopLevelDecl Value}
         TopLevelDeclsBuffer := Value|@TopLevelDeclsBuffer
      end
      %% returns an AST rooted at fAnd(...)
      %% to declare everything inside TopLevelDeclsBuffer (levels, ...)
      fun {GetTopLevelDecls}
         {List2fAnds @TopLevelDeclsBuffer}
      end
      %% generates the PreLevel
      fun {Generator}
         %% generates the first for loop procedure
         fun {For1Generator}
            %% the name of the function of the for1
            NameVar = {MakeVar 'For1'}
            %% arguments of the level
            AriArg = {MakeVar 'Ari'}
            RecArg = {MakeVar 'Rec'}
            NewAriArg = {MakeVar 'NewAri'}
            ArisRec ArisArg
            {CreateNexts Fields 'Ari' ArisRec ArisArg}
         in
            {AddTopLevelDecl
             fProc(%% name
                   NameVar
                   %% arguments
                   [AriArg RecArg NewAriArg fRecord(fAtom('arities' unit) ArisRec)]
                   %% body
                   fBoolCase(%% condition
                             fOpApply('\\=' [AriArg NIL] unit)
                             %% true
                             local
                                FeatVar#_#ValVar#GivenVal = {GetRanger RANGER}
                                FeatDecl = fEq(FeatVar fOpApply('.' [AriArg INT1] unit) unit)
                                ValDecl = fEq(ValVar fOpApply('.' [RecArg FeatVar] unit) unit)
                                NextVar = {MakeVar 'Next'}
                                NextsRec NextsVar
                                {CreateNexts Fields 'Next' NextsRec NextsVar}
                                CallFor1 = fApply(NameVar
                                                  [fOpApply('.' [AriArg INT2] unit)
                                                   RecArg NextVar fRecord(fAtom('arities' unit) NextsRec)]
                                                  unit)
                                TrueStat = {List2fAnds
                                            fEq(NewAriArg fRecord(fAtom('|' unit) [FeatVar NextVar]) unit)
                                            |{Map31Cond ArisArg Conditions NextsVar FeatVar}}
                                IfStat = if FILTER == unit then
                                            TrueStat
                                         else
                                            FalseStat = {List2fAnds
                                                         fEq(NewAriArg NextVar unit)|{Map2Eq ArisArg NextsVar}}
                                         in
                                            fBoolCase(FILTER TrueStat FalseStat unit)
                                         end
                                NoWarning
                                AllDecls = if GivenVal then
                                              %% because we cannot know if ValVar is used, we have to declare it
                                              %% to avoid any warning (unused variable), we do {IsDet ValVar _}
                                              NoWarning = fAnd(fApply(fVar('IsDet' unit)
                                                                      [ValVar fWildcard(unit)]
                                                                      unit)
                                                               CallFor1)
                                              FeatDecl|ValDecl|NextVar|NextsVar
                                           else
                                              NoWarning = CallFor1
                                              FeatDecl|NextVar|NextsVar
                                           end
                             in
                                fLocal(%% decl
                                       {List2fAnds AllDecls}
                                       %% body
                                       fAnd(IfStat NoWarning)
                                       %% position
                                       unit)
                             end
                             %% false
                             {List2fAnds {Map NewAriArg|ArisArg fun{$ X} fEq(X NIL unit) end}}
                             %% position
                             unit)
                   %% flag
                   nil
                   %% position
                   COORDS)}
            NameVar
         end
         %%-------------------------------------------------------------------
         %% generates the second for loop procedure
         fun {For2Generator}
            %% the name of the function of the for2
            NameVar = {MakeVar 'For2'}
            %% arguments of the level
            AriArg = {MakeVar 'Ari'}
            RecArg = {MakeVar 'Rec'}
            ArisRec ArisArg
            {CreateNexts Fields 'Ari' ArisRec ArisArg}
            ResultArg = {MakeVar 'Result'}
         in
            {AddTopLevelDecl
             fProc(%% name
                   NameVar
                   %% arguments
                   [AriArg RecArg fRecord(fAtom('arities' unit) ArisRec) ResultArg]
                   %% body
                   fBoolCase(%% condition
                             fOpApply('\\=' [AriArg NIL] unit)
                             %% true
                             local
                                FeatVar#_#ValVar#GivenVal = {GetRanger RANGER}
                                FeatDecl = fEq(FeatVar fOpApply('.' [AriArg INT1] unit) unit)
                                ValDecl = fEq(ValVar fOpApply('.' [RecArg FeatVar] unit) unit)
                                NextsRec NextsVar
                                {CreateNexts Fields 'Next' NextsRec NextsVar}
                                CallFor2 = fApply(NameVar
                                                  [fOpApply('.' [AriArg INT2] unit)
                                                   RecArg fRecord(fAtom('arities' unit) NextsRec) ResultArg]
                                                  unit)
                                AllFieldsDef = {List2fAnds
                                                {Map42if ArisArg Fields NextsVar Expressions FeatVar ResultArg}}
                                AllExceptBody = fAnd(AllFieldsDef CallFor2)
                                NoWarning
                                AllDecls = if GivenVal then
                                              %% because we cannot know if ValVar is used, we have to declare it
                                              %% to avoid any warning (unused variable), we do {IsDet ValVar _}
                                              NoWarning = fAnd(fApply(fVar('IsDet' unit)
                                                                      [ValVar fWildcard(unit)]
                                                                      unit)
                                                               AllExceptBody)
                                              FeatDecl|ValDecl|NextsVar
                                           else
                                              NoWarning = AllExceptBody
                                              FeatDecl|NextsVar
                                           end
                             in
                                fLocal(%% decl
                                       {List2fAnds AllDecls}
                                       %% body
                                       if BODY == unit then NoWarning
                                       else fAnd(BODY NoWarning)
                                       end
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
                   COORDS)}
            NameVar
         end %% end of For2Generator
         %%-------------------------------------------------------------------
         %% generates the procedure AST for the level (name is <Name/'Level'>)
         %% puts it in the cell TopLevelDeclsBuffer at key 'Level'
         %% returns the name (fVar) of the procedure generated
         fun {LevelGenerator}
            %% the name of the function of the level
            NameVar = {MakeVar 'Level'}
            %% result
            ResultVar = {MakeVar 'Result'}
            %% label argument of the level
            LblArg = {MakeVar 'Lbl'}
            %% record argument of the level
            AriArg = {MakeVar 'Ari'}
            %% record argument of the level
            RecArg = {MakeVar 'Rec'}
         in
            {AddTopLevelDecl
             fProc(
                %% name
                NameVar
                %% arguments
                [LblArg AriArg RecArg ResultVar]
                %% body
                local
                   %% the procedure for the first for loop
                   For1 = {For1Generator}
                   %% the procedure for the second for loop
                   For2 = {For2Generator}
                   %% new arity
                   NewAriVar = {MakeVar 'NewAri'}
                   %% Arities
                   ArisVar = {MakeVar 'Aris'}
                   %% nexts record
                   NextsRecord
                   %% nexts var
                   NextsVar
                   {CreateNexts Fields 'Next' ?NextsRecord ?NextsVar}
                   %% Aris definition
                   ArisDef = fEq(ArisVar fRecord(fAtom('arities' unit) NextsRecord) unit)
                   %% for1 call
                   For1Call = fApply(For1 [AriArg RecArg NewAriVar ArisVar] unit)
                   %% for2 call
                   For2Call = fApply(For2 [NewAriVar RecArg ArisVar ResultVar] unit)
                   %% records creation
                   RecordCreations = {CreateRecords LblArg NextsVar ResultVar Fields}
                in
                   fLocal(%% decls
                          {List2fAnds NewAriVar|ArisVar|NextsVar}
                          %% body
                          {List2fAnds ArisDef|For1Call|{List.append RecordCreations [For2Call]}}
                          %% position
                          unit)
                end
                %% flags
                nil
                %% position
                COORDS)}
            NameVar
         end %% end of LevelGenerator
         %%-------------------------------------------------------------------
         NameVar   = {MakeVar 'PreLevel'}
         ResultVar = {MakeVar 'Result'}
         LevelVar  = {LevelGenerator}
      in
         %% put PreLevel in TopLevelDeclsBuffer
         {AddTopLevelDecl fProc(%% name
                                NameVar
                                %% arguments
                                [ResultVar]
                                %% body
                                local
                                   RecVar = {MakeVar 'Rec'}
                                   Decl = fEq(RecVar RECORD unit)
                                   ResultArg = if ReturnOneRecord then
                                                  [fRecord(HASH [fColon(INT1 ResultVar)])]
                                               else
                                                  [ResultVar]
                                               end
                                   Lbl = fApply(fVar('Label' unit) [RecVar] unit)
                                   Ari = fApply(fVar('Arity' unit) [RecVar] unit)
                                   ApplyStat = fApply(LevelVar  Lbl|Ari|RecVar|ResultArg unit)
                                   BodyStat = fLocal(Decl ApplyStat unit)
                                in
                                   if ReturnOneRecord then
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
                                COORDS)}
         %% return name
         NameVar
      end %% end of Generator
      %% true iff return one non-nested record instead of record of records
      ReturnOneRecord
      %% the fields name of the outputs
      Fields
      %% the expressions to output (same order as Fields)
      Expressions
      %% the output-specific conditons (same order as Fields)
      Conditions
      %% number of outputs
      {ParseExpressions EXPR_LIST ?Fields ?Expressions ?Conditions ?ReturnOneRecord}
      %% launch the generation
      PreLevelVar = {Generator}
   in
      %% return the actual tree rooted at fStepPoint
      fStepPoint(
         fLocal(
            %% all the declarations (levels and bounds)
            {GetTopLevelDecls}
            %% return the resulting record
            fApply(PreLevelVar nil COORDS)
            %% no position
            COORDS)
         %% record comprehension tag
         recordComprehension
         %% keep position of record comprehension
         COORDS)
   end %% end of Compile
end
