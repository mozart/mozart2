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

   meth create(Value Parent Index Visual Depth)
      PName     = {System.printName Value}
      Domain    = @domain
      StopValue = {Visual getStop($)}
   in
      CreateObject, create(Value Parent Index Visual Depth)
      @type      = fdInt
      @varName   = {New InternalAtomNode
                    create(PName Parent Index Visual Depth)}
      @separator = {New InternalAtomNode
                    create('#' Parent Index Visual Depth)}
      @obrace    = {New InternalAtomNode
                    create('{' Parent Index Visual Depth)}
      @cbrace    = {New InternalAtomNode
                    create('}' Parent Index Visual Depth)}
      @items     = {Dictionary.new}
      Domain     = {FD.reflect.dom Value}
      FDIntCreateObject, performInsertion(1 Domain StopValue)
   end

   meth performInsertion(I Ds StopValue)
      if {IsFree StopValue} then
         case Ds
         of Entry|Dr then
            Node = {Create Entry self I @visual @depth}
         in
            {Dictionary.put @items I Node}
            FDIntCreateObject, performInsertion((I + 1) Dr StopValue)
         [] nil      then
            width <- (I - 1)
         end
      end
   end
end
