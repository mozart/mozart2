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
%%% FreeCreateObject
%%%

class FreeCreateObject
   from
      CreateObject

   meth create(Value Parent Index Visual Depth)
      CreateObject, create(Value Parent Index Visual Depth)
      @type = freeVar
   end
end
