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
%%%  (Global) store for global parameters
%%%
%%%
%%%
%%%

%%
%%  An object of this class is used for storing of all common parameters for the
%% Browser (such as actual sizes of windows, user preferences and so on).
%%

class ProtoStore from UrObject
   %%
   attr
      store: store

   %%
   %%  Add (or replace) some value to store;
   %%
   meth store(What Value)
      local Store in
         Store = @store

         %%
         store <- {AdjoinAt Store What Value}
      end
   end

   %%
   %%  Extract some value from store;
   %%
   meth read(What Value)
      Store
   in
      Store = @store

      %% relational!
      if V in V = Store.What then Value = V
      else {BrowserError
            ['Attempt to read undefined parameter in store: ' What]}
      fi
   end

   %%
   %%  Is there such parameter?
   %%
   meth test(What Result)
      Store
   in
      Store = @store

      %% relational!
      if _ = Store.What then Result = True
      else Result = False
      fi
   end

   %%
   %%  Some debug methods;
   %%
   meth dShow(What)
      Store
   in
      Store = @store

      %% replational!
      if V in V = Store.What then {Show V}
      else {Show '*** undefined parameter ***'}
      fi
   end

   %%
   meth dShowAll
      local Store in
         Store = @store

         %%
         {ForAll {Arity Store} proc {$ Feature} {Show Store.Feature} end}
      end
   end

   %%
end
