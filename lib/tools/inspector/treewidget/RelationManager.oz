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
   System(eq)
export
   'class' : RelationManager
define
   class RelEntry
      attr
         parent  %% RelManager Ref
         key     %% Reference Key
         value   %% Store Reference
         node    %% ValueNode
         nodes   %% Reference List
         oldRefs %% Old HasRefs Value
      prop
         final
      meth create(Parent Key Value)
         @parent  = Parent
         @key     = Key
         @value   = Value
         @nodes   = self
         @oldRefs = false
      end
      meth hasRefs($)
         @nodes \= self
      end
      meth getStr($)
         'R'#@key
      end
      meth getEqualStr($)
         @key
      end
      meth getValue($)
         @value
      end
      meth addRef(Node)
         Next = @nodes
      in
         {Node linkRef(self Next)}
      end
      meth refUpdate
         HasRefs = (@nodes \= self)
      in
         if HasRefs \= @oldRefs
         then
            Node = @node
         in
            oldRefs <- HasRefs
            if {IsDet Node} then {Node notify} end %% enforce layout update on master tree
         end
      end
      meth setPrev(Node)
         nodes <- Node
      end
      meth setNext(Node)
         nodes <- Node
      end
      meth isActive($)
         {IsDet @node}
      end
      meth awake(Node)
         @node = Node
      end
      meth sleep
         node <- _
      end
      meth checkReplace
         Val    = @value
         Atomic = case {Value.status Val}
                  of det(Type) then
                     case Type
                     of tuple  then false
                     [] record then false
                     else true
                     end
                  else false
                  end
         Parent = @parent
      in
         if Atomic orelse {Parent isKnown(self Val $)}
         then
            {Parent unlink(@key)}
            {@nodes atomicReplace(Val)}
         else skip
         end
      end
      meth atomicReplace(Val)
         skip
      end
      meth getSelectionNode($)
         @node
      end
   end

   class RelationManager
      attr
         entries %% Entry Dictionary
         maxKey  %% Max Key
         charFun %% Characteristic Funktion of Relation
      prop
         final
      meth create(CharFun)
         @entries = {Dictionary.new}
         @maxKey  = 0
         @charFun = CharFun
      end
      meth query(Value $)
         RelationManager, performQuery({Dictionary.items @entries} Value $)
      end
      meth performQuery(Es Value $)
         case Es
         of Entry|Er then
            if {@charFun Value {Entry getValue($)}}
            then Entry
            else RelationManager, performQuery(Er Value $)
            end
         else
            MaxKey = (@maxKey + 1)
            Entry  = {New RelEntry create(self MaxKey Value)}
         in
            maxKey <- MaxKey
            {Dictionary.put @entries MaxKey Entry} Entry
         end
      end
      meth isKnown(Entry Value $)
         RelationManager, performIsKnown({Dictionary.items @entries} Entry Value $)
      end
      meth performIsKnown(Es Entry Value $)
         case Es
         of CurEntry|Er then
            if {System.eq Entry CurEntry}
            then RelationManager, performIsKnown(Er Entry Value $)
            elseif {@charFun Value {CurEntry getValue($)}}
            then true
            else RelationManager, performIsKnown(Er Entry Value $)
            end
         else false
         end
      end
      meth unlink(Key)
         {Dictionary.remove @entries Key}
      end
      meth setCharFun(Fun)
         charFun <- Fun
      end
   end
end
