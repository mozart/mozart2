%%%
%%% Authors:
%%%   Author's name (Author's email address)
%%%
%%% Contributors:
%%%   optional, Contributor's name (Contributor's email address)
%%%
%%% Copyright:
%%%   Organization or Person (Year(s))
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%
%  Programming Systems Lab, University of Saarland,
%  Geb. 45, Postfach 15 11 50, D-66041 Saarbruecken.
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  TermsStoreClass;
%%%
%%%
%%%
%%%

local
   %%
   GCProc
   NMTest
in

%%%
%%%  Local auxiliary stuff;
%%%

   %%
   %%
   proc {GCProc List Length ?NewList ?NewLength}
      %%
      case {IsFree List} then
         List = NewList         % keep the tail unchanged;
         NewLength = Length
      else Obj R in
         %%
         List = Obj|R

         %%
         case {IsFree Obj.closed} then NewTail in
            %%
            NewList = Obj|NewTail
            {GCProc R (Length + 1) NewTail NewLength}
         else {GCProc R Length NewList NewLength}
         end
      end
   end

   %%
   %% Due to Denys;
   %%
   %% 'P' must a unary procedure doing something. If it blocks or
   %% fails, 'false' is returned, and if it's entailed - 'true';
   fun {NMTest P}
      S={Space.new P}
      W
   in
      thread {Space.askVerbose S W} end
      W == succeeded(entailed)
   end

   %%
   %% If we have to find equal subterms, we save references to
   %% already created objects, and by the checking try to ~unify already
   %% saved references with an actual (subterm).
   %%
   %% This store allow us to find an equal term among already processed
   %% ones and to get a corresponding object.
   %%
   %% By success special message will be send (not from TermsStore!)
   %% o such object, that causes to draw its representation with a leading
   %% variable name and a '=' sign (for instance, instead of
   %% "<Channel Ch @ 0x5688a0>" something like
   %% "R12=<Channel Ch @ 0x5688a0>");
   %%
   %% Note that a first stored term will be returned among all equal
   %% (suitable) which were stored;
   %%
   %% Note:
   %% It works properly under assumption that each term object has
   %% features 'term' and 'closed';
   %%

   %%
   class TermsStoreClass from Object.base
      %%
      attr
         list: InitValue
         tail: InitValue
         length: 0              % # of (instantiated) elements in list;
         fails:  0              % # of dead objects detected during search;

      %%
      %%
      meth init
         local List in
            %%
            tail <- List
            list <- List

            %%
            length <- 0
            fails <- 0
         end
      end

      %%
      meth Check(Term List $)
         %%
         case {IsFree List} then InitValue
         else Obj R in
            %%
            List = Obj|R

            %%
            case {NMTest proc {$ _} Obj.term = Term end} then
               %%
               case {IsFree Obj.closed} then Obj
               else
                  fails <- @fails + 1
                  TermsStoreClass , Check(Term R $)
               end
            else                % not or not yet;
               %%  both - monotonic and non-monotonic;
               TermsStoreClass , Check(Term R $)
            end
         end
      end

      %%
      %% Almost the same as above, but excluding 'self'
      %% (and it yields bool);
      meth Search(Self List $)
         %%
         case {IsFree List} then false
         else Obj R in
            %%
            List = Obj|R

            %%
            case Obj == Self then
               %% skip itself;
               TermsStoreClass , Search(Self R $)
            else
               %%
               case {NMTest proc {$ _} Obj.term = Self.term end} then
                  %%
                  case {IsFree Obj.closed} then true
                  else
                     fails <- @fails + 1
                     TermsStoreClass , Search(Self R $)
                  end
               else TermsStoreClass , Search(Self R $)
               end
            end
         end
      end

      %%
      %%  'check' method;
      %% If there is already such a term, gives the corresponding
      %% object out, else binds InitValue;
      %%
      %% Note that 'Obj' may be a variable at the call time
      %% (that is, _it_is_ a variable - since the term object
      %% is not yet created;)
      %%
      meth checkANDStore(SelfObj Term Obj ?RefObj)
         %%
         RefObj = TermsStoreClass , Check(Term @list $)

         %%
         %% Note that GC is done now during 'checkANDStore', and NOT
         %% during deleting a term object, how it was done bedore.
         %% This optimizes the most probable case of "browse
         %% sequentially, no modifications, remove it!";
         case @fails * TermsStoreGCRatio > @length + TermsStoreGCBase
         then NewList NewLength in
            {GCProc @list 0 NewList NewLength}

            %%
            list <- NewList
            length <- NewLength
            fails <- 0          %  per definition :-))
         else skip
         end

         %%
         case RefObj
         of !InitValue then NewTail in
            @tail = Obj|NewTail   % transaction;
            tail <- NewTail
            length <- @length + 1
         else skip
         end
      end

      %%
      %% Check whether there is another object stored in there;
      %%
      meth checkCorefs(SelfObj $)
         TermsStoreClass , Search(SelfObj @list $)
      end

      %%
   end

   %%
end
