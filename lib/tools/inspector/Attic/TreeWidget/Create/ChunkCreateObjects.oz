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
%%% ChunkCreateObjects
%%%

%% ClassCreateObject

class ClassCreateObject
   from
      CreateObject

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = classChunk
   end
end

%% ObjectCreateObject

class ObjectCreateObject
   from
      CreateObject

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = objectChunk
   end
end

%% ArrayCreateObject

class ArrayCreateObject
   from
      CreateObject

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = arrayChunk
   end
end

%% DictionaryCreateObject

class DictionaryCreateObject
   from
      CreateObject

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = dictionaryChunk
   end
end

%% PortCreateObject

class PortCreateObject
   from
      CreateObject

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = portChunk
   end
end

%% SpaceCreateObject

class SpaceCreateObject
   from
      CreateObject

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = spaceChunk
   end
end

%% Generic Chunk Object

class ChunkCreateObject
   from
      CreateObject

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = genericChunk
   end
end
