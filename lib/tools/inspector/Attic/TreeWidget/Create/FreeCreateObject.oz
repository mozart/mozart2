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

   meth create(Value Visual Depth)
      CreateObject, create(Value Visual Depth)
      @type = freeVar
   end
end
