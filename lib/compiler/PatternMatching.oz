%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%
%% Clause = Pattern#Statement
%% Pattern = [Pos#Test]
%% Pos = [FeatureV]
%% Test = scalar(Scalar)
%%      | record(Label Arity)
%%      | get([Feature#Reg])
%%      | nonbasic(LabelV ArityV)
%%      | label(LabelV)
%%      | feature(FeatureV)
%%      | equal(Pos)
%%      | constant(VariableOccurrence)
%%
%% Scalar = number
%%        | literal
%%
%% Label = literal
%% Arity = int
%%       | [Feature]   % must be sorted
%% Feature = int
%%         | literal
%%
%% LabelV = Label | VariableOccurrence
%% ArityV = [FeatureV]   % variables to the back, sorted by printname
%% FeatureV = Feature | VariableOccurrence
%%
%% Tree = node(Pos Test Tree Tree)
%%      | leaf(Statement)
%%      | default
%%      | shared(Tree Shared)
%%

local
   fun {PosSmaller Pos1 Pos2}
      case Pos1 of I|Ir then
         case Pos2 of J|Jr then
            I < J orelse I == J andthen {PosSmaller Ir Jr}
         [] nil then false
         end
      [] nil then true
      end
   end

   fun {MayMoveOver Test1 Test2}
      case Test1 of scalar(L1) then
         case Test2 of scalar(L2) then L1 \= L2
         [] record(_ _) then true
         [] nonbasic(_ _) then true
         [] label(L2) then {IsLiteral L2} andthen L1 \= L2
         else false
         end
      [] record(L1 _) then
         case Test2 of scalar(_) then true
         [] record(_ _) then Test1 \= Test2
         [] nonbasic(_ _) then
            %--** this approximation could be improved
            false
         [] label(L2) then
            {IsLiteral L1} andthen {IsLiteral L2} andthen L1 \= L2
         else false
         end
      [] nonbasic(_ _) then
         %--** this approximation could be improved
         false
      [] label(L1) then
         {IsLiteral L1} andthen
         case Test2 of scalar(L2) then L1 \= L2
         [] record(L2 _) then L1 \= L2
         [] nonbasic(L2 _) then {IsLiteral L2} andthen L1 \= L2
         [] label(L2) then
            %--** this could be more fine-grained by considering features
            {IsLiteral L2} andthen L1 \= L2
         else false
         end
      else false
      end
   end

   fun {FindPos Tree Pos0 ?NewTree ?Hole ?RestTree}
      case Tree of node(Pos Test ThenTree ElseTree) then
         if Pos == Pos0 then
            NewTree = Hole
            RestTree = Tree
            true
         elseif {PosSmaller Pos Pos0} then NewElseTree in
            NewTree = node(Pos Test ThenTree NewElseTree)
            {FindPos ElseTree Pos0 ?NewElseTree ?Hole ?RestTree}
         else
            NewTree = Hole
            RestTree = Tree
            false
         end
      else
         NewTree = Hole
         RestTree = Tree
         false
      end
   end

   fun {FindTest Tree Pos0 Test0 ?NewTree ?Hole ?RestTree}
      case Tree of node(Pos Test ThenTree ElseTree) then
         if Pos \= Pos0 then false
         elseif Test == Test0 then
            NewTree = node(Pos Test Hole ElseTree)
            RestTree = ThenTree
            true
         elseif {MayMoveOver Test0 Test} then NewElseTree in
            if {FindTest ElseTree Pos0 Test0 ?NewElseTree ?Hole ?RestTree} then
               NewTree = node(Pos Test ThenTree NewElseTree)
               true
            else false
            end
         else false
         end
      else false
      end
   end

   fun {PatternToTree Pattern Then}
      case Pattern of nil then
         leaf(Then)
      [] Pos#Test|Rest then
         node(Pos Test {PatternToTree Rest Then} default)
      end
   end

   proc {MergeSub Pattern Then Tree ?NewTree}
      case Pattern of nil then
         %% Tree is unreachable
         NewTree = leaf(Then)
      [] Pos#Test|Rest then Hole1 RestTree1 Hole RestTree in
         if {FindPos Tree Pos ?NewTree ?Hole1 ?RestTree1}
            andthen {FindTest RestTree1 Pos Test ?Hole1 ?Hole ?RestTree}
         then
            Hole = {MergeSub Rest Then RestTree}
         else
            Hole1 = node(Pos Test {PatternToTree Rest Then} RestTree1)
         end
      end
   end

   fun {MergePatternIntoTree Pattern#Then Tree}
      {MergeSub Pattern Then Tree}
   end

   fun {ClipTree Pos0 Test0 Tree ?NewTree ?Hole ?RestTree}
      case Tree of node(Pos Test ThenTree ElseTree) then
         if Pos == Pos0 andthen {MayMoveOver Test0 Test} then NewElseTree in
            NewTree = node(Pos Test ThenTree NewElseTree)
            _ = {ClipTree Pos0 Test0 ElseTree ?NewElseTree ?Hole ?RestTree}
            true
         else
            NewTree = Hole
            RestTree = Tree
            false
         end
      [] leaf(_) then
         NewTree = Hole
         RestTree = Tree
         false
      [] shared(Tree1 Shared) then RestTree1 in
         if {ClipTree Pos0 Test0 Tree1 ?NewTree ?Hole ?RestTree1} then
            RestTree = RestTree1
         else
            RestTree = shared(RestTree1 Shared)
         end
         false
      end
   end

   proc {PropagateElses Tree DefaultTree ?NewTree ?NewDefaultTree}
      case Tree of node(Pos Test ThenTree ElseTree) then
         NewThenTree NewElseTree NewElseTree1 Hole DefaultTree1
      in
         NewTree = node(Pos Test NewThenTree NewElseTree)
         {PropagateElses ElseTree DefaultTree ?NewElseTree1 ?NewDefaultTree}
         _ = {ClipTree Pos Test NewElseTree1 ?NewElseTree ?Hole ?DefaultTree1}
         {PropagateElses ThenTree DefaultTree1 ?NewThenTree ?Hole}
      [] leaf(_) then
         NewTree = Tree
         NewDefaultTree = DefaultTree
      [] default then
         NewTree = case DefaultTree of shared(_ _) then DefaultTree
                   else shared(DefaultTree _)
                   end
         NewDefaultTree = NewTree
      [] shared(Tree1 Shared) then NewTree1 in
         NewTree = shared(NewTree1 Shared)
         {PropagateElses Tree1 DefaultTree ?NewTree1 ?NewDefaultTree}
      end
   end
in
   proc {BuildTree Clauses Else ?Tree}
      Tree = {PropagateElses
              {FoldR Clauses MergePatternIntoTree default}
              leaf(Else) $ _}
   end
end

fun {PosToReg Pos0 Mapping}
   case Mapping of Pos#Reg|Mr then
      if Pos == Pos0 then Reg
      else {PosToReg Pos0 Mr}
      end
   end
end

local
   fun {IsIndexable Test}
      case Test of scalar(_) then true
      [] record(_ _) then true
      else false
      end
   end

   local
      proc {MakeMatchSub Tree Mapping Pos0 CS ?VHashTableEntries ?VElse}
         case Tree of node(Pos Test ThenTree ElseTree) then
            if Pos == Pos0 andthen {IsIndexable Test} then
               VThen Rest NewMapping
            in
               case Test of scalar(X) then
                  VHashTableEntries = onScalar(X VThen)|Rest
                  NewMapping = Mapping
               [] record(Label Arity) then Regs VGet in
                  if {IsInt Arity} then
                     Regs = {ForThread Arity 1 ~1
                             fun {$ In Feature}
                                {Append Pos [Feature]}#{CS newReg($)}|In
                             end nil}
                  else
                     Regs = {Map Arity
                             fun {$ Feature}
                                {Append Pos [Feature]}#{CS newReg($)}
                             end}
                  end
                  {FoldL Regs
                   proc {$ VHd _#Reg VTl}
                      VHd = vGetVariable(_ Reg VTl)
                   end VGet VThen}
                  VHashTableEntries = onRecord(Label Arity VGet)|Rest
                  NewMapping = {Append Regs Mapping}
               end
               {CodeGen ThenTree NewMapping VThen nil CS}
               {MakeMatchSub ElseTree Mapping Pos0 CS ?Rest ?VElse}
            else
               VHashTableEntries = nil
               {CodeGen Tree Mapping VElse nil CS}
            end
         else
            VHashTableEntries = nil
            {CodeGen Tree Mapping VElse nil CS}
         end
      end
   in
      proc {MakeMatch Reg Tree Mapping Pos0 VHd VTl CS}
         VHashTableEntries VElse
      in
         {MakeMatchSub Tree Mapping Pos0 CS ?VHashTableEntries ?VElse}
         VHd = vMatch(_ Reg VElse VHashTableEntries unit VTl _)
      end
   end

   fun {MakeRecordArgument Feature}
      if {IsObject Feature} then value({Feature reg($)})
      elseif {IsInt Feature} then number(Feature)
      else literal(Feature)
      end
   end

   fun {MakeArityList Fs VHd VTl CS}
      case Fs of F|Fr then ArgIn VInter1 ConsReg NewArg in
         ArgIn = {MakeArityList Fr VHd VInter1 CS}
         {CS newReg(?ConsReg)}
         NewArg = {MakeRecordArgument F}
         VInter1 = vEquateRecord(_ '|' 2 ConsReg [NewArg ArgIn] VTl)
         value(ConsReg)
      [] nil then
         VHd = VTl
         literal(nil)
      end
   end

   proc {MakeEquation Feature VHd VTl CS ?Reg}
      if {IsObject Feature} then
         VHd = VTl
         {Feature reg(?Reg)}
      else
         {CS newReg(?Reg)}
         VHd = if {IsInt Feature} then vEquateNumber(_ Feature Reg VTl)
               else vEquateLiteral(_ Feature Reg VTl)
               end
      end
   end

   proc {CodeGen Tree Mapping VHd VTl CS}
      case Tree of node(Pos Test ThenTree ElseTree) then Reg in
         Reg = {PosToReg Pos Mapping}
         case Test of scalar(_) then
            {MakeMatch Reg Tree Mapping Pos VHd VTl CS}
         [] record(_ _) then
            {MakeMatch Reg Tree Mapping Pos VHd VTl CS}
         [] get(Regs0) then
            {CodeGen ThenTree
             {FoldR Regs0 fun {$ F#Reg In} {Append Pos [F]}#Reg|In end Mapping}
             VHd VTl CS}
         else
            TestReg TestVInstr TestProc TestArgs TestVInter
            VInstr1 VInstr2 Regs ElseVInstr
         in
            {CS newReg(?TestReg)}
            case Test of nonbasic(LabelV ArityV) then
               F|Fr = ArityV Arg1 Argr ArityReg VInter1 VInter2 LabelReg
            in
               Arg1 = {MakeRecordArgument F}
               Argr = {MakeArityList Fr VHd VInter1 CS}
               {CS newReg(?ArityReg)}
               VInter1 = vEquateRecord(_ '|' 2 ArityReg [Arg1 Argr] VInter2)
               LabelReg = {MakeEquation LabelV VInter2 TestVInstr CS}
               TestProc = 'Record.test'
               TestArgs = [Reg LabelReg ArityReg TestReg]
               Regs = {Map ArityV
                       fun {$ FeatureV}
                          {Append Pos [FeatureV]}#{CS newReg($)}
                       end}
            [] label(LabelV) then LabelReg in
               %--** perhaps we could use indexing for the label
               LabelReg = {MakeEquation LabelV VHd TestVInstr CS}
               TestProc = 'Record.testLabel'
               TestArgs = [Reg LabelReg TestReg]
               Regs = nil
            [] feature(FeatureV) then FeatureReg ResultReg in
               {CS newReg(?ResultReg)}
               FeatureReg = {MakeEquation FeatureV VHd TestVInstr CS}
               TestProc = 'Record.testFeature'
               TestArgs = [Reg FeatureReg TestReg ResultReg]
               Regs = [{Append Pos [FeatureV]}#ResultReg]
            [] equal(Pos0) then Reg0 in
               Reg0 = {PosToReg Pos0 Mapping}
               VHd = TestVInstr
               TestProc = '=='
               TestArgs = [Reg Reg0 TestReg]
               Regs = nil
            [] constant(VO) then Reg0 in
               {VO reg(?Reg0)}
               VHd = TestVInstr
               TestProc = '=='
               TestArgs = [Reg Reg0 TestReg]
               Regs = nil
            end
            {MakeRunTimeProcApplication TestProc unit
             {Map TestArgs
              fun {$ Reg} {New PseudoVariableOccurrence init(Reg)} end}
             CS TestVInstr TestVInter}
            {MakeException boolCaseType unit nil CS ElseVInstr nil}
            TestVInter = vTestBool(_ TestReg VInstr1 VInstr2 ElseVInstr
                                   unit VTl _)
            {CodeGen ThenTree {Append Regs Mapping} VInstr1 nil CS}
            {CodeGen ElseTree Mapping VInstr2 nil CS}
         end
      [] leaf(Statement) then
         {Statement codeGenPattern(Mapping VHd CS)}
         VTl = nil
      [] shared(Tree Shared) then
         VHd = Shared
         VTl = nil
         if {IsFree Shared} then Label VInstr in
            {CS newLabel(?Label)}
            Shared = vShared(_ Label {NewCell 0} VInstr)
            {CodeGen Tree Mapping VInstr nil CS}
         end
      end
   end
in
   proc {OptimizePatterns ArbiterReg Clauses Else VHd VTl CS} Tree in
      {BuildTree Clauses Else ?Tree}
      {CodeGen Tree [nil#ArbiterReg] VHd VTl CS}
   end
end
