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

local
   class SimpleCreateObject from CreateObject
      meth gcr(Entry Value Parent Index Visual Depth)
         {self create(Value Parent Index Visual Depth)}
      end
   end

   class GraphCreate
      attr
         entry   %% RelEntry Reference
         mode    %% Mode Variable
         contTag %% Container Tag

      meth handleMode(RefStr Visual)
         PrintStr = 'R'#RefStr
      in
         @mode = {New Helper.marker create(PrintStr '=' self Visual)}
      end
   end
in
   class IntCreateObject from SimpleCreateObject
      meth create(Value Parent Index Visual Depth)
         @type = int
         CreateObject, create(Value Parent Index Visual Depth)
      end
   end

   class FloatCreateObject from SimpleCreateObject
      meth create(Value Parent Index Visual Depth)
         @type = float
         CreateObject, create(Value Parent Index Visual Depth)
      end
   end

   class AtomCreateObject from SimpleCreateObject
      meth create(Value Parent Index Visual Depth)
         @type = atom
         CreateObject, create(Value Parent Index Visual Depth)
      end
   end

   class NameCreateObject from SimpleCreateObject
      meth create(Value Parent Index Visual Depth)
         @type = name
         CreateObject, create(Value Parent Index Visual Depth)
      end
   end

   class ProcedureCreateObject from SimpleCreateObject
      meth create(Value Parent Index Visual Depth)
         @type = procedure
         CreateObject, create(Value Parent Index Visual Depth)
      end
   end

   class FreeCreateObject from SimpleCreateObject
      meth create(Value Parent Index Visual Depth)
         @type = free
         CreateObject, create(Value Parent Index Visual Depth)
         {Visual logVar(self Value false)}
      end
   end

   class FreeGrCreateObject from FreeCreateObject GraphCreate
      meth gcr(Entry Value Parent Index Visual Depth)
         @type    = free
         @entry   = Entry
         @contTag = {Visual newTag($)}
         {self handleMode({Entry getEqualStr($)} Visual)}
         {Entry awake(self)}
         CreateObject, create(Value Parent Index Visual Depth)
         {Visual logVar(self Value false)}
      end
   end

   class FutureCreateObject from SimpleCreateObject
      meth create(Value Parent Index Visual Depth)
         @type = future
         CreateObject, create(Value Parent Index Visual Depth)
         {Visual logVar(self Value true)}
      end
   end

   class FutureGrCreateObject from FutureCreateObject GraphCreate
      meth gcr(Entry Value Parent Index Visual Depth)
         @type  = future
         @entry = Entry
         @contTag = {Visual newTag($)}
         {self handleMode({Entry getEqualStr($)} Visual)}
         {Entry awake(self)}
         CreateObject, create(Value Parent Index Visual Depth)
         {Visual logVar(self Value true)}
      end
   end

   class FailedCreateObject from SimpleCreateObject
      meth create(Value Parent Index Visual Depth)
         @type = failed
         CreateObject, create(Value Parent Index Visual Depth)
      end
   end

   class StringCreateObject from SimpleCreateObject
      meth create(Value Parent Index Visual Depth)
         @type = string
         CreateObject, create(Value Parent Index Visual Depth)
      end
   end

   class ByteStringCreateObject from SimpleCreateObject
      meth create(Value Parent Index Visual Depth)
         @type = bytestring
         CreateObject, create(Value Parent Index Visual Depth)
      end
   end

   class GenericCreateObject from SimpleCreateObject
      meth create(Val Parent Index Visual Depth)
         @type = generic
         if {Value.isKinded Val}
         then {Visual logVar(self Val false)}
         end
         CreateObject, create(Val Parent Index Visual Depth)
      end
   end

   class VariableRefCreateObject from SimpleCreateObject
      attr
         prev %% Previous Node
         next %% Next Node
      meth create(Value Parent Index Visual Depth)
         @type = variableref
         CreateObject, create(Value Parent Index Visual Depth)
         {Value addRef(self)} %% Value is Entry Object
      end
      meth linkRef(Prev Next)
         prev <- Prev
         next <- Next
         {Prev setNext(self)}
         {Next setPrev(self)}
         {@value refUpdate}
      end
      meth unlinkRef
         Prev = @prev
         Next = @next
      in
         {Prev setNext(Next)}
         {Next setPrev(Prev)}
         {@value refUpdate}
      end
      meth setPrev(Node)
         prev <- Node
      end
      meth setNext(Node)
         next <- Node
      end
   end
end
