%  Programming Systems Lab, DFKI Saarbruecken,
%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5337
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%   Checking whether the current blackboard is a deep one,
%%%  and if yes, reflect a term (i.e. replace all free vairables with atoms);
%%%
%%%   Note: the equality of variables in reflected term is not detected!
%%%
%%%

local
   IsSeen
   TupleSubterms
   TupleReflectLoop
   RecordReflectLoop
   GetWFList
   %%
   ReflectTerm
in
   %%

   %%
   %%  Aux: check whether the actual blackboard is a deep one;
   %%
   fun {IsDeepGuard}
      local RootCluster CurrentCluster in
         RootCluster = {System.getValue 0 root}
         CurrentCluster = {System.getValue 0 currentBlackboard}

         %%
         RootCluster \= CurrentCluster
      end
   end

   %%
   %%  Check whether the given term (Term) was already seen.
   %%  Otherwise insert it list of seen terms;
   %%
   proc {IsSeen Term ReflectedTerm ListOfSeen ?NewList ?Status}
      %% ReflectedTerm is in/out both;
      %% relational;
      case {Some ListOfSeen
            fun {$ X}
               {EQ X.1 Term}

               %%
               %%< relational!
               %%< if X.1 = Term then true
               %%< [] true then False
               %%< fi
            end}
      then
         {ForAll ListOfSeen
          proc {$ X}
             case {EQ X.1 Term} then X.2 = ReflectedTerm
             else true
             end

             %%
             %% relational!
             %%< if X.1 = Term then X.2 = ReflectedTerm
             %%< [] true then true
             %%< fi
          end}

         %%
         Status = True
         NewList = ListOfSeen
      else
         Status = False
         NewList = (Term#ReflectedTerm)|ListOfSeen
      end
   end

   %%
   %%
   %%
   fun {TupleSubterms T}
      local ListOf in
         ListOf = {MakeList {Width T}}
         {FoldL ListOf
          fun {$ Num E}
             E = T.Num
             Num + 1
          end
          1 _}
         ListOf
      end
   end

   %%
   %%
   %%  HO: run over the tuple subterms with a list of already seen subterms;
   %%
   proc {TupleReflectLoop Subterms Num ListIn RProc ?ListOut}
      %%
      %% relational;
      case Subterms
      of T|R then
         TmpList NextNum in
         NextNum = {RProc Num T ListIn TmpList}
         {TupleReflectLoop R NextNum TmpList RProc ListOut}
      else
         ListOut = ListIn
      end
   end

   %%
   %%  HO: ... for records;
   %%
   proc {RecordReflectLoop RArity ListIn RProc ?ListOut}
      %%
      %% relational;
      case RArity
      of F|R then
         TmpList in
         {RProc F ListIn TmpList}
         {RecordReflectLoop R TmpList RProc ListOut}
      else
         ListOut = ListIn
      end
   end

   %%
   %%  Convert an incomplete list to the wf-list (non-monotonically);
   fun {GetWFList LIn}
      %%
      %% relational;
      case LIn
      of E|R then E|{GetWFList R}
      [] _ then nil
      end
   end

   %%
   %%  The reflect function itself;
   %%
   proc {ReflectTerm TermIn ListIn ?TermOut ?ListOut}
      local Status TmpList in
         Status = {IsSeen TermIn TermOut ListIn TmpList}
         case Status then
            ListOut = TmpList
         else
            case {IsVar TermIn} then
               %%
               %%
               case {IsRecordCVar TermIn} then
                  RArity KnownRArity RLabel L
               in
                  %%
                  %%  convert an OFS to the proper record non-monotonically;
                  %%
                  %%  'RLabel' will be determined later!
                  RArity = {Record.monitorArity TermIn True}
                  KnownRArity = {Map {GetWFList RArity}
                                 fun {$ FN} {ReflectTerm FN nil $ _} end}

                  %%
                  %% TODO!!!
                  job
                     L = {LabelC TermIn}
                  end

                  %%
                  RLabel =
                  case {IsVar L} then '_...'
                  else {String.toAtom
                        {VirtualString.toString
                         {ReflectTerm L nil $ _}#'...'}}
                  end

                  %%
                  TermOut = {MakeRecord RLabel KnownRArity}
                  {RecordReflectLoop KnownRArity TmpList
                   proc {$ F ListIn ListOut}
                      TermOut.F = {ReflectTerm
                                   {SubtreeC TermIn F}
                                   ListIn $ ListOut}
                   end
                   ListOut}
                  %%
               else
                  %%  a variable;
                  case {IsFdVar TermIn} then
                     SubInts
                  in
                     {Map
                      {FD.reflect.dom TermIn}
                      proc {$ Interval Atom}
                         Atom = case Interval
                                of L#H then
                                   {AtomConcatAll
                                    [' ' {IntToAtom L} '..' {IntToAtom H}]}
                                else
                                   {AtomConcat ' ' {IntToAtom Interval}}
                                end
                      end
                      SubInts}

                     %%
                     TermOut =
                     {AtomConcatAll [{System.getPrintName TermIn}
                                     '{' SubInts ' }']}
                  elsecase {IsMetaVar TermIn} then
                     ThPrio = {Thread.getPriority} in

                     %%  critical section!
                     {Thread.setHighIntPri}
                     %%
                     TermOut = {AtomConcatAll [{System.getPrintName TermIn}
                                               '<' {MetaGetNameAsAtom TermIn}
                                               ':' {MetaGetDataAsAtom TermIn}
                                               '>']}
                     %%
                     {Thread.setPriority ThPrio}
                     %%  end of critical section;
                  else
                     TermOut = {System.getPrintName TermIn }
                  end

                  %%
                  ListOut = TmpList
               end
            else
               case {Value.type TermIn}
               of name then
                  TermOut =
                  case {IsBool TermIn} then
                     case TermIn then '<Bool: true>'
                     else '<Bool: false>'
                     end
                  else
                     {AtomConcatAll
                      ['<Name: ' {System.getPrintName TermIn } ' @ '
                       {IntToAtom {System.getValue TermIn addr}} '>']}
                  end

                  %%
                  ListOut = TmpList
               [] procedure then
                  %%

                  %%
                  TermOut = {AtomConcatAll
                             ['<Procedure: '
                              {System.getPrintName TermIn } '/'
                              {IntToAtom {Procedure.arity TermIn}} ' @ '
                              {IntToAtom {System.getValue TermIn addr}} '>']}
                   ListOut = TmpList
               [] cell then
                  %%

                  %%
                  TermOut = {AtomConcatAll
                             ['<Cell: ' {System.getValue TermIn name} '>']}
                  ListOut = TmpList
               [] record then RArity L LabelOf in
                  RArity = {Map {Arity TermIn}
                            fun {$ FN} {ReflectTerm FN nil $ _} end}

                  %%
                  L = {Label TermIn}
                  LabelOf = {ReflectTerm L nil $ _}

                  %%
                  %%
                  TermOut = {MakeRecord LabelOf RArity}
                  {RecordReflectLoop RArity TmpList
                   proc {$ F ListIn ListOut}
                      TermOut.F = {ReflectTerm TermIn.F ListIn $ ListOut}
                   end
                  ListOut}
               [] chunk then RArity LabelOf in
                  RArity = {Map {ChunkArity TermIn} % all features;
                            fun {$ FN} {ReflectTerm FN nil $ _} end}

                  %%
                  %%  convert the chunk to a record...
                  LabelOf =
                  case {IsObject TermIn} then
                     {AtomConcatAll
                      ['<Object: '
                       {Class.printName {Class.get TermIn}} ' @ '
                       {IntToAtom {System.getValue TermIn addr}} '>']}
                  elsecase {IsClass TermIn} then
                     {AtomConcatAll
                      ['<Class: '
                       {Class.printName TermIn} ' @ '
                       {IntToAtom {System.getValue TermIn addr}} '>']}
                  elsecase {IsArray TermIn} then
                     {AtomConcatAll
                      ['<Array: @ '
                       {IntToAtom {System.getValue TermIn addr}} '>']}
                  elsecase {IsDictionary TermIn} then
                     {AtomConcatAll
                      ['<Dictionary: @ '
                       {IntToAtom {System.getValue TermIn addr}} '>']}
                  else
                     {System.getPrintName TermIn}
                  end

                  %%
                  TermOut = {MakeRecord LabelOf RArity}
                  {RecordReflectLoop RArity TmpList
                   proc {$ F ListIn ListOut}
                      TermOut.F = {ReflectTerm TermIn.F ListIn $ ListOut}
                   end
                  ListOut}
               [] tuple then Subterms in
                  Subterms = {TupleSubterms TermIn}

                  %%
                  TermOut = {MakeTuple {Label TermIn} {Length Subterms}}
                  {TupleReflectLoop Subterms 1 TmpList
                   fun {$ Num ST ListIn ListOut}
                      TermOut.Num = {ReflectTerm ST ListIn $ ListOut}
                      Num + 1
                   end
                   ListOut}
               else
                  TermOut = TermIn
                  ListOut = TmpList
               end
            end
         end
      end
   end

   %%
   %%  The 'final' reflect procedure;
   %%  Should be used in a deep guard only;
   %%
   fun {Reflect Term}
      local IsDeep S ReflectedTerm in
         IsDeep = {IsDeepGuard}

         %%
         case IsDeep then
            {ReflectTerm Term nil ReflectedTerm _}
            S = {SearchOne proc {$ X} X = ReflectedTerm end}

            %% relational;
            case S of [T] then T
            else 'error by the reflection'
            end
         else Term
         end
      end
   end

   %%
end
