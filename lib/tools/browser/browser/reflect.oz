%%%
%%% Authors:
%%%   Konstantin Popov
%%%
%%% Copyright:
%%%   Konstantin Popov, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

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
   local
      fun {All As}
         case As of nil then nil
         [] A|Ar then {Append {All A} {All Ar}}
         else {Atom.toString As}
         end
      end
   in
      fun {AtomConcatAll As}
         if {IsAtom As} then As else {String.toAtom {All As}} end
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
      if {Some ListOfSeen fun {$ X} {EQ X.1 Term} end} then
         %%

         %%
         {ForAll ListOfSeen
          proc {$ X}
             if {EQ X.1 Term} then X.2 = ReflectedTerm
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
         if Status then TmpList
         elseif {IsVar TermIn} then
            %%
            %%
            if {IsRecordCVar TermIn} then
               RArity KillP KnownRArity KnownRefRArity RLabel L
            in
               %%
               %%  convert an OFS to the proper record non-monotonically;
               %%
               %%  'RLabel' will be determined later!
               RArity = {RecordC.monitorArity TermIn KillP}
               {KillP}
               KnownRArity = {GetWFList RArity}
               KnownRefRArity = {Map KnownRArity
                                 fun {$ FN} {ReflectTerm FN nil $ _} end}

               %%
               %% TODO! there must be either a non-monotonic
               %% primitive saying whether an OFS has a label
               %% already, or - even better? - a non-monotonic
               %% version of 'Label' which never suspends;
               if {HasLabel TermIn}
               then L = {Label TermIn}
               end

               %%
               RLabel =
               if {IsVar L} then '_...'
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
               if {IsFdVar TermIn} then
                  %%
                  TermOut =
                  {VirtualString.toAtom {Value.toVirtualString TermIn 1 1}}
               elseif {IsFSetVar TermIn} then
                  %%
                  TermOut =
                  {VirtualString.toAtom {Value.toVirtualString TermIn 1 1}}
               elseif {IsCtVar TermIn} then
                  %%
                  TermOut = {AtomConcatAll
                             [{System.printName TermIn}
                              '<' {GetCtVarNameAsAtom TermIn}
                              ':' {GetCtVarConstraintAsAtom TermIn}
                              '>']}
               else TermOut = {System.printName TermIn }
               end

               %%
               TmpList
            end
         else
            case {Value.type TermIn}
            of name then
               TermOut =
               if {IsBool TermIn} then
                  if TermIn then 'true' else 'false' end
               elseif TermIn == unit then 'unit'
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
            [] port then
               %%

               %%
               TermOut =
               {AtomConcatAll ['<Port @ ' {IntToAtom {AddrOf TermIn}} '>']}
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
               LabelOf ={System.printName TermIn}

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
            [] 'class' then
               TermOut =
               {AtomConcatAll ['<Class @ ' {IntToAtom {AddrOf TermIn}} '>']}
               TmpList
            [] 'object' then
               TermOut =
               {AtomConcatAll ['<Object @ ' {IntToAtom {AddrOf TermIn}} '>']}
               TmpList
            [] 'bitArray' then
               TermOut =
               {AtomConcatAll ['<BitArray @ ' {IntToAtom {AddrOf TermIn}} '>']}
               TmpList
            [] 'array' then
               TermOut =
               {AtomConcatAll ['<Array @ ' {IntToAtom {AddrOf TermIn}} '>']}
               TmpList
            [] 'dictionary' then
               TermOut =
               {AtomConcatAll ['<Dictionary @ ' {IntToAtom {AddrOf TermIn}} '>']}
               TmpList
            [] 'lock' then
               TermOut =
               {AtomConcatAll ['<Lock @ ' {IntToAtom {AddrOf TermIn}} '>']}
               TmpList
            [] 'space' then
               TermOut =
               {AtomConcatAll ['<Space @ ' {IntToAtom {AddrOf TermIn}} '>']}
               TmpList
            [] 'thread' then
               TermOut =
               {AtomConcatAll ['<Thread @ ' {IntToAtom {AddrOf TermIn}} '>']}
               TmpList
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
         if IsDeep then
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
