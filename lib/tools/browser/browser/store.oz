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
%%%
%%%  (Global) store for global parameters;
%%%
%%%
%%%
%%%

%%
%%  An object of this class is used for storing of all common
%% parameters for the Browser (such as actual sizes of windows, user
%% preferences and so on).

class StoreClass from Object.base BatchObject
   %%
   feat
      SDict

   %%
   meth init
      self.SDict = {Dictionary.new}
   end

   %%
   %% Add (or replace) some value to store;
   %%
   meth store(What Value)
      %%
      {Dictionary.put self.SDict What Value}
   end

   %%
   %% Extract some value from store;
   %%
   meth read(What $)
\ifdef DEBUG_BO
      local DefValue in
         DefValue = {NewName}

         %%
         case {Dictionary.condGet self.SDict What DefValue}
         of !DefValue then
            {BrowserError 'Attempt to read undefined parameter in store'}
         else skip
         end
      end
\endif

      %%
      {Dictionary.get self.SDict What}
   end

   %%
   meth close skip end

   %%
end
