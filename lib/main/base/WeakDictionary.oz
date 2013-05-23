%%% Copyright © 2013, Université catholique de Louvain
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without
%%% modification, are permitted provided that the following conditions are met:
%%%
%%% *  Redistributions of source code must retain the above copyright notice,
%%%    this list of conditions and the following disclaimer.
%%% *  Redistributions in binary form must reproduce the above copyright notice,
%%%    this list of conditions and the following disclaimer in the documentation
%%%    and/or other materials provided with the distribution.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%%% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%%% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%%% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
%%% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%%% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%%% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%%% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%%% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%%% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%%% POSSIBILITY OF SUCH DAMAGE.

local
   WeakDictionaryID = {NewUniqueName weakDictionaryID}

   fun {GetUnderlying WD}
      if {IsWeakDictionary WD} then
         WD.WeakDictionaryID
      else
         raise typeError('WeakDictionary' WD) end
      end
   end

   fun {GetUnderDict WD}
      {GetUnderlying WD}.1
   end

   fun {WeakRefIsDead WR}
      {Boot_WeakRef.get WR} == none
   end

   proc {WeakDictPut WD Key Value}
      weakDict(Dict Lock _) = {GetUnderlying WD}
      WeakValue = {Boot_WeakRef.new Value}
   in
      lock Lock then
         {Dictionary.put Dict Key WeakValue}
      end
      {Wait WD} % keep WD alive at least until after the writing operation
   end

   proc {WeakDictHandleCondGetResult CondGetResult ?Result ?Found}
      if CondGetResult == false then
         Found = false
      elsecase {Boot_WeakRef.get CondGetResult}
      of none then
         Found = false
      [] some(V) then
         Result = V
         Found = true
      end
   end

   proc {WeakDictLookup WD Key ?Result ?Found}
      % No need to lock
      CondGetResult = {Dictionary.condGet {GetUnderDict WD} Key false}
   in
      {WeakDictHandleCondGetResult CondGetResult ?Result ?Found}
   end

   proc {WeakDictExchange WD Key ?OldValue NewValue}
      weakDict(Dict Lock _) = {GetUnderlying WD}
      WeakNewValue = {Boot_WeakRef.new NewValue}
   in
      lock Lock then
         if {WeakDictLookup WD Key ?OldValue} then
            {Dictionary.put Dict Key WeakNewValue}
         else
            {Exception.raiseError dictKeyNotFound(WD Key)}
         end
      end
      {Wait WD} % keep WD alive at least until after the writing operation
   end

   proc {WeakDictCondExchange WD Key Default ?OldValue NewValue}
      weakDict(Dict Lock _) = {GetUnderlying WD}
      WeakNewValue = {Boot_WeakRef.new NewValue}
      CondExchResult
   in
      lock Lock then
         CondExchResult = {Dictionary.condExchange Dict Key false $ WeakNewValue}
      end
      {Wait WD} % keep WD alive at least until after the writing operation
      if {Not {WeakDictHandleCondGetResult CondExchResult ?OldValue}} then
         OldValue = Default
      end
   end

   proc {WeakDictGet WD Key ?Result}
      if {Not {WeakDictLookup WD Key ?Result}} then
         {Exception.raiseError dictKeyNotFound(WD Key)}
      end
   end

   proc {WeakDictCondGet WD Key Default ?Result}
      if {Not {WeakDictLookup WD Key ?Result}} then
         Result = Default
      end
   end

   proc {WeakDictClose WD}
      weakDict(_ _ NotifyPort) = {GetUnderlying WD}
   in
      NotifyPort := unit
   end

   fun {WeakDictEntriesLoop RawEntries}
      case RawEntries
      of (Key#RawItem)|Tail then Item in
         if {WeakDictHandleCondGetResult RawItem ?Item} then
            (Key#Item)|{WeakDictEntriesLoop Tail}
         else
            {WeakDictEntriesLoop Tail}
         end
      [] nil then
         nil
      end
   end

   fun {WeakDictEntries WD}
      {WeakDictEntriesLoop {Dictionary.entries {GetUnderDict WD}}}
   end

   fun {WeakDictKeys WD}
      {Map {WeakDictEntries WD} fun {$ E} E.1 end}
   end

   fun {WeakDictItems WD}
      {Map {WeakDictEntries WD} fun {$ E} E.2 end}
   end

   fun {WeakDictIsEmpty WD}
      {All {Dictionary.items {GetUnderDict WD}} WeakRefIsDead}
   end

   fun {WeakDictToRecord L WD}
      {List.toRecord L {WeakDictEntries WD}}
   end

   proc {WeakDictRemove WD Key}
      weakDict(Dict Lock _) = {GetUnderlying WD}
   in
      lock Lock then
         {Dictionary.remove Dict Key}
      end
   end

   proc {WeakDictRemoveAll WD}
      weakDict(Dict Lock _) = {GetUnderlying WD}
   in
      lock Lock then
         {Dictionary.removeAll Dict}
      end
   end

   fun {WeakDictMember WD Key}
      {WeakDictLookup WD Key _ $}
   end
in
   fun {NewWeakDictionary ?S}
      % Create the WeakDict and its components
      Dict = {NewDictionary}
      Lock = {NewLock}
      NotifyPort = {NewCell {NewPort ?S}} % assigned unit when closed
      WeakDict = {NewChunk weakDict(WeakDictionaryID:weakDict(Dict Lock NotifyPort))}

      % Define a watcher thread that will wake up after each GC to remove dead
      % entries from the dictionary, and send notifications on the stream.
      WeakWeakDict = {Boot_WeakRef.new WeakDict}
      proc {Watch}
         % Wait for the next GC
         {Wait {Boot_Property.get 'gc.watcher' $ true}}

         % Test whether my WeakDict is still alive
         StillAlive = {Not {WeakRefIsDead WeakWeakDict}}

         P = @NotifyPort
         IsEmptyAfterPurge
      in
         % If the WeakDict is dead and P == unit, nothing to do anymore
         if StillAlive orelse P \= unit then
            % Remove dead entries from the Dict and send things on the NotifyPort
            lock Lock then
               {ForAll {Dictionary.entries Dict}
                proc {$ Key#WeakValue}
                   if {WeakRefIsDead WeakValue} then
                      {Dictionary.remove Dict Key}
                      if P \= unit then
                         {Send P Key#unit}
                      end
                   end
                end}
               IsEmptyAfterPurge = {Dictionary.isEmpty Dict}
            end

            if StillAlive orelse {Not IsEmptyAfterPurge} then
               {Watch}
            end
         end
      end
   in
      % Start the watcher thread and return the WeakDict
      thread {Watch} end
      WeakDict
   end

   fun {IsWeakDictionary X}
      {IsChunk X} andthen {HasFeature X WeakDictionaryID}
   end

   WeakDictionary = weakDictionary(
      new:          NewWeakDictionary
      is:           IsWeakDictionary
      put:          WeakDictPut
      exchange:     WeakDictExchange
      condExchange: WeakDictCondExchange
      get:          WeakDictGet
      condGet:      WeakDictCondGet
      close:        WeakDictClose
      keys:         WeakDictKeys
      entries:      WeakDictEntries
      items:        WeakDictItems
      isEmpty:      WeakDictIsEmpty
      toRecord:     WeakDictToRecord
      remove:       WeakDictRemove
      removeAll:    WeakDictRemoveAll
      member:       WeakDictMember
   )
end
