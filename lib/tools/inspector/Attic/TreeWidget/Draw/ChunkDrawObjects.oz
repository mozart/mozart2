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
%%% ChunkDrawObjects
%%%

%% ClassDrawObject

class ClassDrawObject
   from
      DrawObject

   meth draw(X Y)
      if @dirty then
         DrawObject, initMenu(@type)
         DrawObject, draw(X Y)
      end
   end

   meth reDraw(X Y)
      if @dirty then
         DrawObject, initMenu(@type)
         DrawObject, reDraw(X Y)
      else
         DrawObject, reDraw(X Y)
      end
   end
end

%% ObjectDrawObject

class ObjectDrawObject
   from
      DrawObject
end

%% ArrayDrawObject

class ArrayDrawObject
   from
      DrawObject

   meth draw(X Y)
      if @dirty then
         DrawObject, initMenu(@type)
         DrawObject, draw(X Y)
      end
   end

   meth reDraw(X Y)
      if @dirty then
         DrawObject, initMenu(@type)
         DrawObject, reDraw(X Y)
      else
         DrawObject, reDraw(X Y)
      end
   end
end

%% DictionaryDrawObject

class DictionaryDrawObject
   from
      DrawObject

   meth draw(X Y)
      if @dirty then
         DrawObject, initMenu(@type)
         DrawObject, draw(X Y)
      end
   end

   meth reDraw(X Y)
      if @dirty then
         DrawObject, initMenu(@type)
         DrawObject, reDraw(X Y)
      else
         DrawObject, reDraw(X Y)
      end
   end
end

%% PortDrawObject

class PortDrawObject
   from
      DrawObject
end

%% SpaceDrawObject

class SpaceDrawObject
   from
      DrawObject
end

%% ChunkDrawObject

class ChunkDrawObject
   from
      DrawObject
end
