%  Programming Systems Lab, University of Saarland,
%  Geb. 45, Postfach 15 11 50, D-66041 Saarbruecken.
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Checking whether the current blackboard is a deep one, and if yes,
%%% reflect a term (i.e. replace all free vairables with atoms);
%%%
%%% Note: the equality of variables in reflected term is not detected!
%%%
%%%

local
   AtomConcat
   AtomConcatAll
   %%
   IsSeen
   TupleSubterms
   TupleReflectLoop
   RecordReflectLoop
   GetWFList
   %%
   ReflectTerm

   %%
in

   %%
   fun {AtomConcat A1 A2}
      {String.toAtom {Append {Atom.toString A1} {Atom.toString A2}}}
   end

   %%
   local
      fun {All As}
         case As of nil then nil
         [] A|Ar then {Append {All A} {All Ar}}
         else {Atom.toString As}
         end
      end
   in
      fun {AtomConcatAll As}
         case {IsAtom As} then As else {String.toAtom {All As}} end
      end
   end

   %%
   %% Aux: check whether the actual blackboard is a deep one;
   %%
   fun {IsDeepGuard}
      {Not {OnToplevel}}
   end

   %%
   %% Check whether the given term (Term) was already seen.
   %% Otherwise insert it list of seen terms;
   %%
   fun {IsSeen Term ReflectedTerm ListOfSeen ?NewList}
      %%
      %% ReflectedTerm is in/out both;
      case {Some ListOfSeen fun {$ X} {EQ X.1 Term} end} then
         %%

         %%
         {ForAll ListOfSeen
          proc {$ X}
             case {EQ X.1 Term} then X.2 = ReflectedTerm
             else skip
             end
          end}

         %%
         NewList = ListOfSeen
         true
      else
         NewList = Term#ReflectedTerm | ListOfSeen
         false
      end
   end

   %%
   %%
   fun {TupleSubterms T}
      local ListOf in
         ListOf = {List.make {Width T}}
         {FoldL ListOf fun {$ Num E}
                          E = T.Num
                          Num + 1
                       end
          1 _}
         ListOf
      end
   end

   %%
   %%
   %% HO: run over the tuple subterms with a list of already seen subterms;
   %%
   fun {TupleReflectLoop Subterms Num ListIn RFun}
      %%
      case Subterms
      of T|R then TmpList in
         {TupleReflectLoop R {RFun Num T ListIn TmpList} TmpList RFun}
      else ListIn
      end
   end

   %%
   %% HO: ... for records;
   fun {RecordReflectLoop RArity ListIn RFun}
      %%
      case RArity
      of F|R then {RecordReflectLoop R {RFun F ListIn} RFun}
      else ListIn
      end
   end

   %%
   %% Convert an incomplete list to the wf-list (non-monotonically);
   fun {GetWFList LIn}
      %%
      case {Value.status LIn}
      of det(_) then
         case LIn
         of E|R then E|{GetWFList R}
         else nil
         end
      else nil
      end
   end

   %%
   %% The reflect function itself;
   fun {ReflectTerm TermIn ListIn ?TermOut}
      local Status TmpList in
         Status = {IsSeen TermIn TermOut ListIn TmpList}

         %%
         case Status then TmpList
         elsecase {IsVar TermIn} then
            %%
            %%
            case {IsRecordCVar TermIn} then
               RArity KillP KnownRArity KnownRefRArity RLabel L
            in
               %%
               %%  convert an OFS to the proper record non-monotonically;
               %%
               %%  'RLabel' will be determined later!
               RArity = {Record.monitorArity TermIn KillP}
               {KillP}
               KnownRArity = {GetWFList RArity}
               KnownRefRArity = {Map KnownRArity
                                 fun {$ FN} {ReflectTerm FN nil $ _} end}

               %%
               %% TODO! there must be either a non-monotonic
               %% primitive saying whether an OFS has a label
               %% already, or - even better? - a non-monotonic
               %% version of 'Label' which never suspends;
               case {HasLabel TermIn}
               then L = {Label TermIn}
               else skip
               end

               %%
               RLabel =
               case {IsVar L} then '_...'
               else {String.toAtom
                     {VirtualString.toString
                      {ReflectTerm L nil $ _}#'...'}}
               end

               %%
               TermOut = {Record.make RLabel KnownRefRArity}
               {RecordReflectLoop KnownRArity TmpList
                fun {$ F ListIn} RF in
                   RF = {ReflectTerm F nil $ _}
                   {ReflectTerm TermIn.F ListIn TermOut.RF}
                end}
            else
               %%  a variable;
               case {IsFdVar TermIn} then
                  %%
                  TermOut =
                  {String.toAtom {System.valueToVirtualString TermIn 1 1}}
               elsecase {IsFSetVar TermIn} then
                  %%
                  TermOut =
                  {String.toAtom {System.valueToVirtualString TermIn 1 1}}
               elsecase {IsMetaVar TermIn} then
                  %%
                  TermOut = {AtomConcatAll [{System.printName TermIn}
                                            '<' {MetaGetNameAsAtom TermIn}
                                            ':' {MetaGetDataAsAtom TermIn}
                                            '>']}
               else TermOut = {System.printName TermIn }
               end

               %%
               TmpList
            end
         else
            case {Type.ofValue TermIn}
            of name then
               TermOut =
               case {IsBool TermIn} then
                  case TermIn then 'true' else 'false' end
               elsecase TermIn == unit then 'unit'
               else
                  {AtomConcatAll
                   ['<Name: ' {System.printName TermIn } ' @ '
                    {IntToAtom {AddrOf TermIn}} '>']}
               end

               %%
               TmpList
            [] procedure then
               %%

               %%
               TermOut = {AtomConcatAll
                          ['<Procedure: '
                           {System.printName TermIn } '/'
                           {IntToAtom {Procedure.arity TermIn}} ' @ '
                           {IntToAtom {AddrOf TermIn}} '>']}
               TmpList
            [] cell then
               %%

               %%
               TermOut =
               {AtomConcatAll ['<Cell @ ' {IntToAtom {AddrOf TermIn}} '>']}
               TmpList
            [] record then RArity RefRArity L LabelOf in
               RArity = {Arity TermIn}
               RefRArity = {Map RArity
                            fun {$ FN} {ReflectTerm FN nil $ _} end}

               %%
               L = {Label TermIn}
               LabelOf = {ReflectTerm L nil $ _}

               %%
               %%
               TermOut = {Record.make LabelOf RefRArity}
               {RecordReflectLoop RArity TmpList
                fun {$ F ListIn} RF in
                   RF = {ReflectTerm F nil $ _}
                   {ReflectTerm TermIn.F ListIn TermOut.RF}
                end}
            [] chunk then RArity RefRArity LabelOf in
               RArity = {ChunkArity TermIn} % all features;
               RefRArity = {Map RArity
                            fun {$ FN} {ReflectTerm FN nil $ _} end}

               %%
               %%  convert the chunk to a record...
               LabelOf =
               case {IsObject TermIn} then
                  {AtomConcatAll
                   ['<Object: '
                    {System.printName TermIn} ' @ '
                    {IntToAtom {AddrOf TermIn}} '>']}
               elsecase {IsClass TermIn} then
                  {AtomConcatAll
                   ['<Class: '
                    {System.printName TermIn} ' @ '
                    {IntToAtom {AddrOf TermIn}} '>']}
               elsecase {IsArray TermIn} then
                  {AtomConcatAll
                   ['<Array: @ '
                    {IntToAtom {AddrOf TermIn}} '>']}
               elsecase {IsDictionary TermIn} then
                  {AtomConcatAll
                   ['<Dictionary: @ '
                    {IntToAtom {AddrOf TermIn}} '>']}
               else {System.printName TermIn}
               end

               %%
               TermOut = {Record.make LabelOf RefRArity}
               {RecordReflectLoop RArity TmpList
                fun {$ F ListIn} RF in
                   RF = {ReflectTerm F nil $ _}
                   {ReflectTerm TermIn.F ListIn TermOut.RF}
                end}
            [] tuple then Subterms in
               Subterms = {TupleSubterms TermIn}

               %%
               TermOut = {Tuple.make {Label TermIn} {Length Subterms}}
               {TupleReflectLoop Subterms 1 TmpList
                fun {$ Num ST ListIn ListOut}
                   TermOut.Num = {ReflectTerm ST ListIn $ ListOut}
                   Num + 1
                end}
            else
               TermOut = TermIn
               TmpList
            end
         end
      end
   end

   %%
   %% The 'final' reflect procedure;
   %% Should be used in a deep guard only;
   %%
   fun {Reflect Term}
      local IsDeep S ReflectedTerm in
         IsDeep = {IsDeepGuard}

         %%
         case IsDeep then
            {ReflectTerm Term nil ReflectedTerm _}
            S = {Search.one.depth proc {$ X} X = ReflectedTerm end 1 _}

            %%
            case S of [T] then T
            else 'error by the reflection'
            end
         else Term
         end
      end
   end

   %%
end
