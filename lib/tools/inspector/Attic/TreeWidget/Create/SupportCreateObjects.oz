%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1997-1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% SupportCreateObjects
%%%

%% EmbraceCreateObject

class EmbraceCreateObject
   from
      CreateObject

   attr
      obrace %% Open Brace
      cbrace %% Closed Brace
      node   %% Embraced Node

   meth create(Node Parent Index Visual Type)
      @node = Node
      case Type
      of round  then
         @obrace = {New InternalAtomNode create('(' self 0 Visual 0)}
         @cbrace = {New InternalAtomNode create(')' self 0 Visual 0)}
      [] braces then
         @obrace = {New InternalAtomNode create('{' self 0 Visual 0)}
         @cbrace = {New InternalAtomNode create('}' self 0 Visual 0)}
      end
   end

   meth setRootIndex(Index)
      {@node setRootIndex(Index)}
   end

   meth getRootIndex(Index $)
      {@node getRootIndex(Index $)}
   end

   meth setParentData(Parent Index)
      {@node setParentData(Parent Index)}
   end

   meth getType($)
      {@node getType($)}
   end

   meth setType(Type)
      {@node setType(Type)}
   end

   meth getValue($)
      {@node getValue($)}
   end

   meth setValue(Value)
      {@node setValue(Value)}
   end

   meth isProxy($)
      {@node isProxy($)}
   end
end

%% NullCreateObject

class NullCreateObject
   from
      CreateObject
end

%% ProxyCreateObject

class ProxyCreateObject
   from
      BaseObject

   attr
      securedNode %% Secured Node
      currentNode %% Active Node
      expanded    %% Expansion Flag

   meth create(Passive Active)
      @securedNode = Passive
      @currentNode = Active
      @expanded    = true
   end

   meth getCurrentNode($)
      @currentNode
   end

   meth alter(Node)
      currentNode <- Node
   end

   meth delete($)
      @securedNode
   end

   meth setRootIndex(Index)
      {@currentNode setRootIndex(Index)}
   end

   meth getRootIndex(I $)
      {@currentNode getRootIndex(I $)}
   end

   meth setParentData(Parent Index)
      {@currentNode setParentData(Parent Index)}
   end

   meth getType($)
      {@currentNode getType($)}
   end

   meth setType(Type)
      {@currentNode setType(Type)}
   end

   meth getValue($)
      {@currentNode getValue($)}
   end

   meth setValue(Value)
      {@currentNode setValue(Value)}
   end

   meth setStack(Stack)
      {@currentNode setStack(Stack)}
   end

   meth getStack($)
      {@currentNode getStack($)}
   end

   meth isProxy($)
      true
   end
end

%% InternalAtomCreateObject

class InternalAtomCreateObject
   from
      CreateObject

   attr
      expValue %% Value saved for the expansion

   meth create(Value Parent Index Visual Depth)
      MakeStr = InternalAtomCreateObject, fixTKBug(Value $)
   in
      CreateObject, create(MakeStr Parent Index Visual Depth)
      @type = atom
   end

   meth setExpValue(Value)
      @expValue = Value
   end

   meth fixTKBug(Value $)
      case Value
      of nil then {Atom.toString Value}
      [] '#' then {Atom.toString Value}
      [] ''  then "\'\'"
      else Value
      end
   end
end

%% BitmapCreateObject

class BitmapCreateObject
   from
      CreateObject

   attr
      bitmapMode %% Bitmap Mode
      buffer     %% Rescue Value

   meth create(Value Parent Index Visual Depth)
      NewValue
   in
      CreateObject, create(NewValue Parent Index Visual Depth)
      @bitmapMode = Value
      case Value
      of width then
         NewValue = '@'#{OpMan get(canvasWidthBitmap $)}
         @type    = widthBitmap
      [] depth then
         NewValue = '@'#{OpMan get(canvasDepthBitmap $)}
         @type    = depthBitmap
      end
   end

   meth setRescueValue(Value)
      @buffer = Value
   end

   meth getRescueValue($)
      @buffer
   end
end

%% GenericCreateObject

class GenericCreateObject
   from
      ProxyCreateObject

   meth create(Value Parent Index Visual Depth Type)
      NewValue = '<generic:'#Type#'>'
      OldNode NewNode
      Auto Fun
   in
      ProxyCreateObject, create(OldNode NewNode)
      if {OpMan isKey(Type $)}
      then Auto#Fun#_ = {OpMan get(Type $)}
      else Auto = false
      end
      if Auto
      then
         NewNode = {Visual performCreation({Fun Value} Parent
                                           Index Depth $)}
      else
         NewNode = OldNode
         expanded <- false
      end
      OldNode = {New InternalAtomNode
                 create(NewValue Parent Index Visual Depth)}
      {OldNode initMenu(Type)}
      {OldNode setExpValue(Value)}
   end
end
