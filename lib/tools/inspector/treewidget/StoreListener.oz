%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1999
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%   http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

functor $
import
   BrowserSupport(getsBoundB) at 'x-oz://boot/Browser'
   System(eq show)
   Property(get)
export
   'class' : StoreListener
define
   GetsBoundB = BrowserSupport.getsBoundB

   local
      Prev     = {NewName}
      Next     = {NewName}
      SetPrev  = {NewName}
      SetNext  = {NewName}

      Search   = {NewName}
      HasEntry = {NewName}
   in
      class ListNode
         attr
            !Prev %% Prev Ptr
            !Next %% Next Ptr
         meth !SetPrev(MyPrev)
            Prev <- MyPrev
         end
         meth !SetNext(MyNext)
            Next <- MyNext
         end
      end

      class StoreEntry from ListNode
         attr
            value %% Store Value
            nodes %% Reference Nodes
         prop
            final
         meth create(Value Node MyPrev MyNext)
            @value = Value
            @nodes = Node|nil
            @Prev  = MyPrev
            @Next  = MyNext
            {MyNext SetPrev(self)}
         end
         meth !Search(Value $)
            if {System.eq @value Value} then self else {@Next Search(Value $)} end
         end
         meth !HasEntry(Value Entry $)
            ({System.eq @value Value} andthen {Not {System.eq self Entry}})
            orelse {@Next HasEntry(Value Entry $)}
         end
         meth append(Node)
            nodes <- (Node|@nodes)
         end
         meth getNodes($)
            Nodes = @nodes
         in
            nodes <- nil
            if {IsDet @value}
            then
               MyPrev = @Prev
               MyNext = @Next
            in
               {MyPrev SetNext(MyNext)}
               {MyNext SetPrev(MyPrev)}
            end
            Nodes
         end
      end

      class StoreListener from ListNode
         meth create
            @Prev = self
            @Next = self
         end
         meth resetAll
            Prev <- self
            Next <- self
         end
         meth !Search(Value $)
            nil
         end
         meth !HasEntry(Value Entry $)
            false
         end
         meth logVar(Node Value FutMode)
            case {@Next Search(Value $)}
            of nil then
               EntryObj = {New StoreEntry create(Value Node self @Next)}
               WidPort  = @widPort %% Known from TreeWidget
            in
               Next <- EntryObj
               thread StoreListener, listen(FutMode WidPort Value EntryObj) end
            [] Entry then {Entry append(Node)}
            end
         end
         meth listen(FutMode WidPort CurValue EntryObj)
            if FutMode
            then {Value.waitQuiet CurValue}
            else {Wait {GetsBoundB CurValue}}
            end
            {Port.send WidPort notifyNodes(EntryObj)} %% Re-enter sync barrier
            if {IsDet CurValue} orelse {IsFailed CurValue}
            then skip
            else StoreListener, listen(FutMode WidPort CurValue EntryObj)
            end
         end
         meth notifyNodes(EntryObj)
            case {EntryObj getNodes($)}
            of nil   then skip
            [] Nodes then
               StopVar
            in
               stopPVar <- StopVar %% Known from TreeWidget
               stopOVar <- StopVar %% Known from TreeWidget
               {self enableStop}
               StoreListener, performNotifyNodes(nil Nodes)
            end
         end
         meth performNotifyNodes(RIs Nodes)
            case Nodes
            of Node|Nr then
               RI     = {Node tell($)}
               NewRIs = case RI of true then RIs elseif {Member RI RIs} then RIs else RI|RIs end
            in
               StoreListener, performNotifyNodes(NewRIs Nr)
            elsecase RIs
            of nil then skip
            else {self update(RIs RIs.1)}
            end
         end
         meth updateCell(Node)
            StopVar RI
         in
            stopPVar <- StopVar
            stopOVar <- StopVar
            {self enableStop}
            case {Node tell($)}
            of true then {self adjustCanvasView}
            [] RI   then {self update([RI] RI)}
            end
         end
      end
   end
end
