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
%%% ChunkLayoutObjects
%%%

%% ClassLayoutObject

class ClassLayoutObject
   from
      LayoutObject

   meth layout
      if @dazzle
      then
         String = @string
      in
         String = '<C:'#{System.printName @value}#'>'
         @xDim  = {VirtualString.length String}
         yDim <- 1
         @color = {OpMan get(classChunkColor $)}
         dazzle <- false
         dirty  <- true
      end
   end
end

%% ObjectLayoutObject

class ObjectLayoutObject
   from
      LayoutObject

   meth layout
      if @dazzle
      then
         String = @string
      in
         String = '<O:'#'>'
         @xDim  = {VirtualString.length String}
         yDim <- 1
         @color = {OpMan get(objectChunkColor $)}
         dazzle <- false
         dirty  <- true
      end
   end
end

%% ArrayLayoutObject

class ArrayLayoutObject
   from
      LayoutObject

   meth layout
      if @dazzle
      then
         String = @string
      in
         String = '<Array>'
         @xDim  = {VirtualString.length String}
         yDim <- 1
         @color = {OpMan get(arrayChunkColor $)}
         dazzle <- false
         dirty  <- true
      end
   end
end

%% DictionaryLayoutObject

class DictionaryLayoutObject
   from
      LayoutObject
   meth layout
      if @dazzle
      then
         String = @string
      in
         String = '<Dictionary>'
         @xDim  = {VirtualString.length String}
         yDim <- 1
         @color = {OpMan get(dictionaryChunkColor $)}
         dazzle <- false
         dirty  <- true
      end
   end
end

%% PortLayoutObject

class PortLayoutObject
   from
      LayoutObject

   meth layout
      if @dazzle
      then
         String = @string
      in
         String = '<Port>'
         @xDim  = {VirtualString.length String}
         yDim <- 1
         @color = {OpMan get(portChunkColor $)}
         dazzle <- false
         dirty  <- true
      end
   end
end

%% SpaceLayoutObject

class SpaceLayoutObject
   from
      LayoutObject

   meth layout
      if @dazzle
      then
         String = @string
      in
         String = '<Space>'
         @xDim  = {VirtualString.length String}
         yDim <- 1
         @color = {OpMan get(spaceChunkColor $)}
         dazzle <- false
         dirty  <- true
      end
   end
end

%% ChunkLayoutObject

class ChunkLayoutObject
   from
      LayoutObject

   meth layout
      if @dazzle
      then
         String = @string
      in
         String = '<Chunk>'
         @xDim  = {VirtualString.length String}
         yDim <- 1
         @color = {OpMan get(genericChunkColor $)}
         dazzle <- false
         dirty  <- true
      end
   end
end
