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
%%% SimpleDrawObjects
%%%

%% IntDrawObject

class IntDrawObject
   from
      DrawObject
end

%% FloatDrawObject

class FloatDrawObject
   from
      DrawObject
end

%% AtomDrawObject

class AtomDrawObject
   from
      DrawObject

   meth expandWidth(N)
      case @index
      of 0 then {@parent handleLabelWidthExpansion(N)}
      else {@parent handleWidthExpansion(N @index)}
      end
   end

   meth expandDepth(N)
      {@parent handleDepthExpansion(N @buffer @index)}
   end
end

%% BoolDrawObject

class BoolDrawObject
   from
      DrawObject
end

%% NameDrawObject

class NameDrawObject
   from
      DrawObject
end

%% ProcedureDrawObject

class ProcedureDrawObject
   from
      DrawObject
end
