functor
export
   Mkoptimize
   Mkcount
   Mksum
   Mkmultiply
   Mklist
   %%
   Maximize
   Minimize
   Count
   Collect
   Append
   Prepend
prepare
   RaiseError=Exception.raiseError
   %%
   NONE={NewName}
   %%
   fun {Mkoptimize}
      {NewCell NONE}
   end
   fun {Mkcount}
      {NewCell 0}
   end
   fun {Mklist} L in
      {NewCell L|L}
   end
   fun {Mksum}
      {NewCell 0}
   end
   fun {Mkmultiply}
      {NewCell 1}
   end
   %%
   proc {Maximize C N}
      Old New
   in
      {Exchange C Old New}
      if Old==NONE orelse N>Old then New=N end
   end
   %%
   proc {Minimize C N}
      Old New
   in
      {Exchange C Old New}
      if Old==NONE orelse N<Old then New=N end
   end
   %%
   proc {Count C B}
      if B then Old New in
         {Exchange C Old New}
         New=Old+1
      else skip end
   end
   %%
   proc {Sum C N}
      Old New
   in
      {Exchange C Old New}
      New=Old+N
   end
   %%
   proc {Multiply C N}
      Old New
   in
      {Exchange C Old New}
      New=Old*N
   end
   %%
   proc {Collect C X}
      Head OldTail NewTail
   in
      {Exchange C Head|OldTail Head|NewTail}
      OldTail=X|NewTail
   end
   %%
   proc {Append C X}
      Head OldTail NewTail
   in
      {Exchange C Head|OldTail Head|NewTail}
      {Append X NewTail OldTail}
   end
   %%
   proc {Prepend C X}
      Head Tail
   in
      {Exchange C Head|Tail {Append X Head}|Tail}
   end
   %%
   fun {ReturnIntDefault C D} V in
      {Exchange C V unit}
      if V==NONE then D else V end
   end
   fun {ReturnInt C} V in
      {Exchange C V unit}
      if V==NONE then
         {RaiseError 'for'(noDefaultValue)}
      else V end
   end
   fun {ReturnList C}
      {Exchange $|nil unit}
   end
   %%
   fun {Return C} V in
      {Exchange C V unit}
      if V==NONE then
         {RaiseError 'for'(noDefaultValue)}
         unit
      else V end
   end
end
