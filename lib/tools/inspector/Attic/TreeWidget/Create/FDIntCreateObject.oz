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
%%% FDIntCreateObject
%%%

class FDIntCreateObject
   from
      CreateObject

   attr
      varName   %% Var Name
      separator %% Hash Separator
      obrace    %% Open Brace
      cbrace    %% Close Brace
      items     %% Item Container
      width     %% Item Index
      domain    %% FD Domain

   meth create(Value Visual Depth)
      PName  = {System.printName Value}
      Domain = @domain
   in
      CreateObject, create(Value Visual Depth)
      @type      = fdInt
      @varName   = {New InternalAtomNode create(PName Visual Depth)}
      @separator = {New InternalAtomNode create('#' Visual Depth)}
      @obrace    = {New InternalAtomNode create('{' Visual Depth)}
      @cbrace    = {New InternalAtomNode create('}' Visual Depth)}
      @items     = {Dictionary.new}
      Domain     = {FD.reflect.dom Value}
      FDIntCreateObject, performInsertion(1 Domain)
   end

   meth performInsertion(I Ds)
      case Ds
      of Entry|Dr then
         Node = {Create Entry @visual @depth}
      in
         {Dictionary.put @items I Node}
         FDIntCreateObject, performInsertion((I + 1) Dr)
      [] nil      then
         width <- (I - 1)
      end
   end
end
