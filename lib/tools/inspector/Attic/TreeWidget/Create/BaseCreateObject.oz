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
%%% CreateBaseObject
%%%

class CreateObject
   from
      BaseObject

   attr
      parent    %% Parent Object
      index     %% Parent entry index
      type      %% Object Type
      value     %% Store Reference
      visual    %% Inspector Reference
      depth     %% Inspector Depth
      canvas    %% Inspector Canvas
      xf        %% Font Size (Width)
      yf        %% Font Size (Height)
      stack     %% Graph Stack

   meth create(Value Parent Index Visual Depth)
      @value          = Value
      @visual         = Visual
      @depth          = Depth
      @canvas|@xf|@yf = {Visual getVisualData($)}
      @parent         = Parent
      @index          = Index
   end

   meth getRootIndex(I $)
      {@parent getRootIndex(@index $)}
   end

   meth setParentData(Parent Index)
      parent <- Parent
      index  <- Index
   end

   meth getType($)
      @type
   end

   meth setType(Type)
      type <- Type
   end

   meth getValue($)
      @value
   end

   meth setValue(Value)
      value <- Value
   end

   meth setStack(Stack)
      stack <- Stack
   end

   meth getStack($)
      @stack
   end

   meth isProxy($)
      false
   end

   meth getCurrentNode($)
      self
   end

   meth ignoreStop($)
      true
   end
end
