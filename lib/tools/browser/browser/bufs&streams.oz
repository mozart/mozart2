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
%%% Buffers & Streams;
%%%
%%%

%%%
%%%
%%%
local
   GetHead GetTail Take CoreBufferClass NumBufferClass LimitedBufferClass
in
   %%

   %%
   GetHead = {NewName}
   GetTail = {NewName}

   %%
   %% My version of 'List.take' - yields the empty list if N=0.
   %% (It accepts also malformed lists, but i don't care;)
   fun {Take Xs N}
      case N>0 then
         case Xs of X|Xr then X|{Take Xr N-1}
         else nil
         end
      else nil
      end
   end

   %%
   %% Core buffer. No limits and no suspensions - "pure logical";
   class CoreBufferClass
      from MyClosableObject BatchObject
      prop locking
      %%
      attr
         Tail                   %  where to put in;
         Head                   %  where to discard;

      %%  ... as "reinit" too;
      meth init
         local Start in
            lock
               Tail <- Start
               Head <- Start
            end
         end
      end
      meth close
         local T in
            T = @Tail

            MyClosableObject , close
            Head <- T
            T = nil
         end
      end

      %%
      meth enq(El)
         local NewTail in
            lock
               case MyClosableObject , isClosed($) then skip
               else
                  @Tail = El|NewTail
                  Tail <- NewTail
               end
            end
         end
      end
      meth deq(?El)
         local NewHead in
            lock
               @Head = El|NewHead
               Head <- NewHead
            end
         end
      end

      %%
      meth getFirstEl(?El)
         @Head = El|_
      end

      %%
      meth !GetHead($) @Head end
      meth !GetTail($) @Tail end

      %%
   end

   %%
   %% The only addition is that its elements are numbered;
   class NumBufferClass
      from CoreBufferClass
      %%
      attr
         Size                   %

      %%  ... as "reinit" too;
      meth init
         lock
            Size <- 0
            CoreBufferClass , init
         end
      end
      meth close
         CoreBufferClass , close
         Size <- 0
      end

      %%
      meth enq(El)
         lock
            CoreBufferClass , enq(El)
            Size <- @Size + 1
         end
      end
      meth deq(?El)
         lock
            CoreBufferClass , deq(El)
            Size <- @Size - 1
         end
      end

      %%
      meth getSize($) @Size end

      %%
      %%  Yields a list of enqueued entries;
      meth getContent($)
         lock
            {Take (CoreBufferClass , GetHead($)) @Size}
         end
      end

      %%
   end

   %%
   %% This one can store only a limited number of elements. Requests
   %% that cannot be server at the moment are rejected;
   class LimitedBufferClass
      from NumBufferClass
      %%
      attr
         MaxSize                %

      %%  ... as "reinit" too;
      meth init(SizeIn)
         lock
            MaxSize <- SizeIn
            NumBufferClass , init
         end
      end

      %%
      meth getMaxSize($) @MaxSize end

      %%
      meth hasPlace($)
         lock
            NumBufferClass , getSize($) < @MaxSize
         end
      end

      %%
      meth isNotEmpty($)
         lock
            NumBufferClass , getSize($) > 0
         end
      end

      %%
      meth enq(El $)
         lock
            case LimitedBufferClass , hasPlace($) then
               NumBufferClass , enq(El)
               true
            else false
            end
         end
      end

      %%
      meth getFirstEl(?El $)
         lock
            case LimitedBufferClass , isNotEmpty($) then
               CoreBufferClass , getFirstEl(El)
               true
            else false
            end
         end
      end

      %%
      %%  Note that it can hold more elements than the MaxSize
      %% (because of 'resize');
      meth deq(?El $)
         lock
            case LimitedBufferClass , isNotEmpty($) then
               NumBufferClass , deq(El)
               true
            else false
            end
         end
      end

      %%
      meth resize(NewMaxSize)
         MaxSize <- NewMaxSize
      end

      %%
   end

   %%
   %% Non-monotonic 'enq'/'deq' operations, plus 'waitElement':
   %% suspends until the stream becomes non-empty.  Note that a
   %% subsequent 'deq' needs not to yield some element: it can be,
   %% e.g., already dequeued by some other agent.
   class BrowserStreamClass
      from NumBufferClass
      %%
      %% 'init'/'close' are inherited from 'NumBufferClass';

      %%
      %% 'enq' is inherited from 'NumBufferClass' without changes.
      %% There is also 'getSize', but it does not seem to be
      %% necessary.
      %%
      meth deq(?Req $)
         lock
            case NumBufferClass , getSize($) > 0 then
               NumBufferClass , deq(Req)
               true
            else
               Req = InitValue
               false
            end
         end
      end

      %%
      %% Note that it does not block the object state;
      meth waitElement
         {Wait
          case MyClosableObject , isClosed($) then _   % forever;
          else CoreBufferClass , GetTail($)
          end}
      end

      %%
   end

   %%
   %%
   %%
   class BrowserBufferClass
      from Object.base
      prop locking
      %%
      feat
         CoreBuffer             %  carries enqueued entries;
         ToEnqueue              %  not-yet enqueued;
         ToDequeue              %  not-yet dequeued;

      %%
      meth init(MaxSizeIn)
         self.CoreBuffer = {New LimitedBufferClass init(MaxSizeIn)}
         self.ToEnqueue = {New NumBufferClass init}
         self.ToDequeue = {New NumBufferClass init}
      end

      %%
      meth close
         lock
            %%  there are probably some suspended enq"s;
            case {self.ToEnqueue getSize($)} > 0 then L in
               L = {self.ToEnqueue getContent($)}
               {ForAll L proc {$ E} {E.discardAction} end}
            else skip
            end

            %%  ... deq"s?
            case {self.ToDequeue getSize($)} > 0 then L in
               L = {self.ToDequeue getContent($)}
               {ForAll L proc {$ E} {E.discardAction} end}
            else skip
            end

            %%
         end
      end

      %%
      meth CheckDequeue
         lock
            case
               {self.CoreBuffer isNotEmpty($)} andthen
               {self.ToDequeue getSize($)} > 0
            then Entry in
               %%  process the first of them;
               Entry = {self.ToDequeue deq($)}
               Entry.elem = {self.CoreBuffer deq($ _)}
               {Entry.proceedAction}

               %%
               BrowserBufferClass , CheckDequeue
            else skip
            end
         end
      end

      %%
      meth CheckEnqueue
         lock
            case
               {self.CoreBuffer hasPlace($)} andthen
               {self.ToEnqueue getSize($)} > 0
            then Entry in
               Entry = {self.ToEnqueue deq($)}
               {self.CoreBuffer enq(Entry.elem _)}
               {Entry.proceedAction}

               %%
               BrowserBufferClass , CheckEnqueue
            else skip
            end
         end
      end

      %%
      meth enq(El ProceedAction DiscardAction)
         lock
            case {self.CoreBuffer enq(El $)} then
               {ProceedAction}

               %%  check whether we have some pending deq"s;
               BrowserBufferClass , CheckDequeue
            else ToEnqueueEntry in
               ToEnqueueEntry =
               toEnqueueEntry(elem: El
                              proceedAction: ProceedAction
                              discardAction: DiscardAction)

               %%
               {self.ToEnqueue enq(ToEnqueueEntry)}
            end
         end
      end

      %%
      meth getFirstEl(?El $)
         {self.CoreBuffer getFirstEl(El $)}
      end

      %%
      %% This is a kind of interesting: the 'ProceedAction' procedure
      %% may refer 'El', and when it is applied 'El' is instantiated
      %% too! This is similar to 'enq' but with the difference where
      %% 'El' comes from;
      %%
      %% The limitation is that "actions" cannot apply the 'self'
      %% (buffer) directly, i.e. without thread...end - this will
      %% lead to a deadlock.
      %%
      meth deq(?El ProceedAction DiscardAction)
         lock
            case {self.CoreBuffer deq(El $)} then
               {ProceedAction}

               %%
               BrowserBufferClass , CheckEnqueue
            else ToDequeueEntry in
               ToDequeueEntry =
               toDequeueEntry(elem: El
                              proceedAction: ProceedAction
                              discardAction: DiscardAction)

               %%
               {self.ToDequeue enq(ToDequeueEntry)}
            end
         end
      end

      %%
      meth getSize($)
         {self.CoreBuffer getSize($)}
      end

      %%
      meth resize(NewMaxSize)
         local CurrentMaxSize in
            lock
               CurrentMaxSize = {self.CoreBuffer getMaxSize($)}
               {self.CoreBuffer resize(NewMaxSize)}

               %%
               case NewMaxSize > CurrentMaxSize then
                  BrowserBufferClass , CheckEnqueue
               else skip
                  %% no special action when getting smaller;
               end
            end
         end
      end

      %%
      %%  Throws away "to-be-{en,de}queued" requests;
      meth purgeSusps
         local P in
            lock
               %%
               P = proc {$ Entry} {Entry.discardAction} end
               {ForAll {self.ToDequeue getContent($)} P}
               {ForAll {self.ToEnqueue getContent($)} P}

               %%
               {self.ToDequeue init}
               {self.ToEnqueue init}
            end
         end
      end

      %%
      meth getContent($)
         {self.CoreBuffer getContent($)}
      end

      %%
   end

   %%
end
