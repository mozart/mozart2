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
%%% SimpleLayoutObjects
%%%

%% IntLayoutObject

class IntLayoutObject
   from
      LayoutObject

   attr
      layoutType : normal %% Layout Type

   meth layout
      if @dazzle
      then
         String = @string
      in
         case @layoutType
         of normal then
            String = @value
            @color = {OpMan get(intColor $)}
         [] tuple  then
            String = @value#'('
            @color = black
         [] record then
            String = @value#':'
            @color = black
         end
         @xDim = {VirtualString.length @string}
         yDim <- 1
         dazzle <- false
         dirty  <- true
      end
   end

   meth setLayoutType(Type)
      layoutType <- Type
   end
end

%% FloatLayoutObject

class FloatLayoutObject
   from
      LayoutObject

   meth layout
      if @dazzle
      then
         String = @string
      in
         String = {Float.toString @value}
         @xDim  = {Length @string}
         yDim <- 1
         @color = {OpMan get(floatColor $)}
         dazzle <- false
         dirty  <- true
      end
   end
end

%% AtomLayoutObject

class AtomLayoutObject
   from
      LayoutObject

   attr
      layoutType : normal %% Layout Type

   meth layout
      if @dazzle
      then
         String = @string
      in
         case @layoutType
         of normal then
            String = @value
            @color = {OpMan get(atomColor $)}
         [] tuple  then
            String = @value#'('
            @color = black
         [] record then
            String = @value#':'
            @color = black
         end
         @xDim = {VirtualString.length String}
         yDim <- 1
         dazzle <- false
         dirty  <- true
      end
   end

   meth setLayoutType(Type)
      layoutType <- Type
   end
end

%% BoolLayoutObject

class BoolLayoutObject
   from
      LayoutObject

   meth layout
      if @dazzle
      then
         String = @string
      in
         case @value
         of true  then String = 'true'
         [] false then String = 'false'
         end
         @xDim  = {VirtualString.length String}
         yDim <- 1
         @color = {OpMan get(boolColor $)}
         dazzle <- false
         dirty  <- true
      end
   end
end

%% NameLayoutObject

class NameLayoutObject
   from
      LayoutObject

   attr
      layoutType : normal %% LayoutType

   meth layout
      if @dazzle
      then
         String = @string
      in
         case @layoutType
         of normal then
            String = NameLayoutObject, calcValue($)
            @color = {OpMan get(nameColor $)}
         [] tuple  then
            String = NameLayoutObject, calcValue($)#'('
            @color = black
         [] record then
            String = NameLayoutObject, calcValue($)#':'
            @color = black
         end
         @xDim  = {VirtualString.length String}
         yDim <- 1
         dazzle <- false
         dirty  <- true
      end
   end

   meth calcValue($)
      case @value
      of unit then 'unit'
      else '<N>'
      end
   end

   meth setLayoutType(Type)
      layoutType <- Type
   end
end

%% ProcedureLayoutObject

class ProcedureLayoutObject
   from
      LayoutObject

   meth layout
      if @dazzle
      then
         String = @string
         Arity  = {Procedure.arity @value}
      in
         String = '<P/'#Arity#'>'
         @xDim  = {VirtualString.length String}
         yDim <- 1
         @color = {OpMan get(procedureColor $)}
         dazzle <- false
         dirty  <- true
      end
   end
end
