%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Contributor:
%%%   Christian Schulte, 1998
%%%
%%% Copyright:
%%%   Denys Duchier, 1997
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

functor

export
   register:   Register
   everyGC:    EveryGC
   guardian:   Guardian

define

   proc {Guardian Finalizer ?Register}
      Table
      proc {FinalizeEntry _#Value}
         {Finalizer Value}
      end
   in
      thread {ForAll {NewWeakDictionary $ Table} FinalizeEntry} end
      proc {Register Value}
         {WeakDictionary.put Table {NewName} Value}
      end
   end

   local
      HandlerTable = {NewDictionary}
      ValueTable
   in
      proc {Register Value Handler}
         Key = {NewName}
         WDKey = {NewName}
      in
         {Wait Handler}
         {Dictionary.put HandlerTable Key Handler}
         %% we must do this 2nd so that the value doesn't
         %% become garbage before the handler has been registered
         %% The key used in the ValueTable must be different from the
         %% one used for the HandlerTable, since the handler table
         %% is a regular dictionary and will keep the weakdictionary-entry
         %% alive otherwise.
         {WeakDictionary.put ValueTable WDKey Key#Value}
      end
      thread
         {ForAll {NewWeakDictionary $ ValueTable}
          proc {$ _#(Key#Value)}
             try
                Handler = {Dictionary.get HandlerTable Key}
             in
                {Dictionary.remove HandlerTable Key}
                {Handler Value}
             catch E then
                %% if we catch an exception, we raise it again
                %% in a brand new thread so that the user may see
                %% the corresponding error message, but the
                %% finalization thread is not affected
                thread raise E end end
             end
          end}
      end
   end

   proc {EveryGC P}
      proc {DO _}
         {P}
         {Register DO DO}
      end
   in
      {Register DO DO}
   end
end
