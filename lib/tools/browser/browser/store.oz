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
      %%
      store <- {AdjoinAt @store What Value}
   end

   %%
   %%  Extract some value from store;
   %%
   meth read(What ?OutValue)
      local DefValue in
         DefValue = {NewName}

         %%
         OutValue = {SubtreeIf @store What DefValue}

         %%
         case OutValue
         of !DefValue then
            {BrowserError
             ['Attempt to read undefined parameter in store']}
         else true
         end
      end
   end

   %%
   %%  Is there such parameter?
   %%
   meth test(What ?Result)
      Result = {Value.hasSubtreeAt @tore What}
   end

   %%
   %%  Some debug methods;
   %%
   meth dShow(What)
      {Show <<read(What $)>>}
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
