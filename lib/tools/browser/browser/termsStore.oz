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
%%%  ProtoTermsStore;
%%%
%%%
%%%
%%%

local
   %%
   CheckProc
   SearchProc
   CheckCycleProc
   GCProc
in

%%%
%%%  Local auxiliary stuff;
%%%
   %%
   %%  For efficiency reasons this is the procedure on top level;
   %%  It is being used in 'Check' to perform check recursively;
   fun {CheckProc Term List}
      %%
      case {IsVar List}
      of !True then InitValue
      else
         Obj IsEQ R IsAway
      in
         %%
         List = Obj|R

         %%
         job
            IsEQ = Obj.term == Term
         end

         %%> alternative, but only 'proper' coreferences (incl. cycles);
         %%> case {EQ Obj.term Term} then ...
         case
            case {IsVar IsEQ}
            of !True then False
            else IsEQ
            end
         of !True then
            %%
            job
               IsAway = {Object.closed Obj}
            end

            %%
            case {IsVar IsAway}
            of !True then Obj
            else {CheckProc Term R}
            end
         else {CheckProc Term R}  %  both - monotonic and non-monotonic;
         end
      end
   end

   %%
   %%  Almost the same as above, but excluding 'self' (and it yields bool);
   fun {SearchProc Self List}
      %%
      case {IsVar List}
      of !True then False
      else
         Obj R IsAway
      in
         %%
         List = Obj|R

         %%
         case Obj == Self then {SearchProc Self R}
         else
            IsEQ
         in
            job
               IsEQ = Obj.term == Self.term
            end

            %%
            case
               case {IsVar IsEQ}
               of !True then False
               else IsEQ
               end
            of !True then
               %%
               job
                  IsAway = {Object.closed}
               end

               %%
               case {IsVar IsAway}
               of !True then True
               else {SearchProc Self R}
               end
            else
               {SearchProc Self R}
            end
         end
      end
   end

   %%
   %%  Check for a cycle;
   %%  Goes bottom-up from an Object till a "root" object;
   fun {CheckCycleProc Term SelfObject}
      local IsEQ in
         %%
         %% faster, but if you write 'declare T = a(a(T)) in {Browse T}'
         %% the representation 'C1=a(a(C1))' will be shown
         %% (instead 'C1=a(C1)')!
         %%< case {EQ SelfObject.term Term} then FoundObj = SelfObject

         %%
         job
            IsEQ = SelfObject.term == Term
         end

         %%
         case
            case {IsVar IsEQ}
            of !True then False
            else IsEQ
            end
         then
            %%
            case SelfObject.type
            of !T_PSTerm then InitValue
            else
               IsAway
            in
               %%
               job
                  IsAway = {Object.closed SelfObject}
               end

               %%
               case {IsVar IsAway}
               of !True then SelfObject
               else
                  PO
               in
                  %% i.e., this is garbage (or lack of synchronization);
                  PO = SelfObject.parentObj

                  %%
                  case PO
                  of !InitValue then InitValue
                  else {CheckCycleProc Term PO}
                  end
               end
            end
         else
            PO
         in
            PO = SelfObject.parentObj

            %%
            case PO
            of !InitValue then InitValue
            else {CheckCycleProc Term PO}
            end
         end
      end
   end

   %%
   %%
   proc {GCProc List Length ?NewList ?NewLength}
      %%
      case {IsVar List} then
         List = NewList         % keep the tail unchanged;
         NewLength = Length
      else
         Obj R IsAway
      in
         %%
         List = Obj|R

         %%
         job
            IsAway = {Object.closed Obj}
         end

         %%
         case {IsVar IsAway}
         of !True then
            NewTail in
            %%
            NewList = Obj|NewTail
            {GCProc R (Length + 1) NewTail NewLength}
         else
            {GCProc R Length NewList NewLength}
         end
      end
   end

   %%
   %%  There are the two purposes of the terms store:
   %%
   %%  First;
   %%  If we have to find equal subterms, we save references to all
   %% already created objects, and by the checking try to ~unify already
   %% saved references with an actual (subterm).
   %%
   %%  This store allow us to find an equal term among already processed
   %% ones and to get a corresponding object.
   %%
   %%  By success special message will be send (not from termsStore!)
   %% to such object, that causes to draw its representation with a leading
   %% variable name and a '=' sign (for instance, instead of
   %% "<Channel Ch @ 0x5688a0>" something like
   %% "R12=<Channel Ch @ 0x5688a0>");
   %%
   %%  Note that a first stored term will be returned among all equal
   %% (suitable) which were stored;
   %%
   %%  The search for cycles is performed in another way, however: all
   %% parents of an object are considered bottom-up for equal terms;
   %%
   %%  Second;
   %%  We have to implement 'the-number-of-nodes' restriction by browsing
   %% of terms; So, terms store carry the actual number of already created
   %% term objects, the permition to create another one is granted or not
   %% granted via the method 'canCreateObject';
   %%
   %%  Note
   %%  It works properly under assumption that there are two adjuncted
   %% features in each termObject: 'term' and 'parentObject';

   %%
   class ProtoTermsStore from UrObject
      %%
      %%
      feat
         isChecking
         onlyCycles
         refType
         store

      %%
      attr
         list: InitValue
         tail: InitValue
         length: 0              % # of (instantiated) elements in list;
         pruned: 0              % # of removed elements;
         currentNumber: 0       % number of nodes;

      %%
      %%
      meth init(isChecking: IsChecking
                onlyCycles: OnlyCycles
                store:      Store)
         local List in
            %%
            self.isChecking = IsChecking
            self.onlyCycles = OnlyCycles
            self.store = Store

            %%
            case OnlyCycles then self.refType = 'C'
            else self.refType = 'R'
            end

            %%
            tail <- List
            list <- List
         end
      end

      %%
      %%  Yields 'True' if checking should be performed;
      %%  Note that this case should be complaint with the 'draw' methods;
      %%  Note also that generally this procedure should be a class method;
      %%
      meth needsCheck(Type ?Needs)
\ifdef DEBUG_TO
         {Show 'TermsStore::needsCheck method is applied'#Type}
\endif
         case self.isChecking then
            case Type
            of !T_Atom       then Needs = False
            [] !T_Int        then Needs = False
            [] !T_Float      then Needs = False
            [] !T_Name       then Needs = True
            [] !T_Procedure  then Needs = True
            [] !T_Cell       then Needs = True
            [] !T_Object     then Needs = True
            [] !T_Class      then Needs = True
            [] !T_WFList     then Needs = True
            [] !T_Tuple      then Needs = True
            [] !T_Record     then Needs = True
            [] !T_ORecord    then Needs = True
            [] !T_List       then Needs = True
            [] !T_FList      then Needs = True
            [] !T_HashTuple  then Needs = True
            [] !T_Variable   then Needs = True
            [] !T_FDVariable then Needs = True
            [] !T_MetaVariable then Needs = True
            [] !T_Shrunken   then Needs = False
               %%  never search for equal shrunken subterms :)))
            [] !T_Reference  then Needs = False
               {BrowserWarning
                ['Reference type is met in TermsStore::needsCheck']}
            [] !T_Unknown    then Needs = False
            else
               {BrowserWarning
                ['Unknown type is met in TermsStore::needsCheck: ' Type]}
            end
         else
            Needs = False
         end
      end

      %%
      %%  'check' method;
      %%  If there is already such a term, gives the corresponding
      %% object out, else binds InitValue;
      %%
      %%  Note that 'Obj' may be a variable at the call time
      %% (that is, _it_is_ a variable - since the term object
      %% is not yet created;)
      %%
      meth checkANDStore(SelfObj Term Obj ?RefObj)
         %%
         case self.onlyCycles then
            %%
            RefObj = {CheckCycleProc Term SelfObj}
         else
            %%
            RefObj = {CheckProc Term @list}
            case RefObj
            of !InitValue then
               local NewTail in
                  @tail = Obj|NewTail   % transaction;
                  tail <- NewTail
                  length <- @length + 1
               end
            else true
            end
         end
      end

      %%
      %%  Check whether there is another object stored in there;
      %%
      meth checkCorefs(SelfObj ?IsThere)
         IsThere = case self.onlyCycles then False
                   else {SearchProc SelfObj @list}
                   end
      end

      %%
      %%  'Retract' method;
      %%  This method is necessary when an object is destroyed
      %% (for instance, if the list goes to a well-formed list, or when
      %% "unzoom" is performed);
      %%
      meth retract(Object)
\ifdef DEBUG_TO
         {Show 'TermsStore::retract method is applied'#Object.type}
\endif
         local WasChecked in
            <<needsCheck(Object.type WasChecked)>>

            %%
            case WasChecked then
               case self.onlyCycles then true
               else
                  pruned <- @pruned + 1

                  %%
                  %%  never zero in divide;
                  case {`div` @length @pruned} < TermsStoreGCRatio
                  of !True then
                     local NewList NewLength in
                        {GCProc @list 0 NewList NewLength}

                        %%
                        list <- NewList
                        length <- NewLength
                        pruned <- 0
                     end
                  else true
                  end
               end
            else true
            end
         end
      end

      %%
      %%
      meth debugShowStore
         {Show 'TermsStore: '}
         case self.isChecking then
            {Show '  checking is enabled.'}
            case self.cyclesOnly then
               {Show '  Only cycles.'}
            else
               {Show '  Coreferences.'}
               {Show '  There are '#@length#' entries,'}
               {Show '  '#@prunded#' of them are probably dead.'}
            end
         else
            {Show '  checking is disabled.'}
         end
         %%
         {Show '   There are '#@currentNumber#'registered nodes.'}
      end

      %%
      %%
      %%  'Number-of-nodes' limitation;
      %%
      meth canCreateObject(?Permition)
         local CurrentLimit CurrentNumber in
            CurrentLimit = {self.store read(StoreNodeNumber $)}
            CurrentNumber = @currentNumber

            %%
            case CurrentNumber < CurrentLimit
            of !True then
               Permition = True
            else
               case CurrentNumber
               of !CurrentLimit then
                  {BrowserWarning
                   ['Cannot create more nodes, bound ('
                                                      CurrentLimit
                                                      ') is reached']}
               else true
               end

               %%
               Permition = False
            end

            %% ... since the object T_Shrunken is created anyway;
            currentNumber <- CurrentNumber + 1
         end
      end

      %%
      %%
      %%  Decrease the number of objects (if one is destroyed);
      meth decNumberOfNodes
         currentNumber <- @currentNumber - 1
      end

      %%
   end

   %%
end
