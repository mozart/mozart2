%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1999
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%   http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%   http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   class SimpleLayoutObject from LayoutObject
      attr
         string %% Graphical Representation
      meth layout
         XDim = @xDim
      in
         if {IsFree XDim}
         then
            String = @string
         in
            String = {self createRep($)}
            XDim   = {VirtualString.length String}
         end
      end
      meth layoutX($)
         SimpleLayoutObject, layout @xDim
      end
      meth layoutY($)
         SimpleLayoutObject, layout @xDim|1
      end
      meth graphHorzMode(I Mode HorzMode)
         HorzMode = {Not Mode}
      end
   end
in
   class IntLayoutObject from SimpleLayoutObject
      meth createRep($)
         @value
      end
   end

   class FloatLayoutObject from SimpleLayoutObject
      meth createRep($)
         {Float.toString @value}
      end
   end

   class AtomLayoutObject from SimpleLayoutObject
      meth createRep($)
         {Aux.convert @value}
      end
   end

   class NameLayoutObject from SimpleLayoutObject
      meth createRep($)
         Value = @value
      in
         case Value
         of false then type <- bool   'false'
         [] true  then type <- bool   'true'
         [] unit  then type <- 'unit' 'unit'
         else '<N: '#{System.printName Value}#'>'
         end
      end
   end

   class ProcedureLayoutObject from SimpleLayoutObject
      meth createRep($)
         Value = @value
      in
         '<P/'#{Procedure.arity Value}#' '#{System.printName Value}#'>'
      end
      meth isVert($)
         true
      end
   end

   local
      class SimpleGrLayoutObject from SimpleLayoutObject
         meth layout
            XDim = @xDim
         in
            if {IsFree XDim}
            then
               RepStr = {self createRep($)}
               RepLen = {VirtualString.length RepStr}
            in
               string <- RepStr
               XDim    = if {@entry hasRefs($)}
                         then {@mode layoutX($)} + RepLen
                         else RepLen
                         end
            end
         end
         meth layoutX($)
            SimpleGrLayoutObject, layout @xDim
         end
         meth layoutY($)
            SimpleGrLayoutObject, layout @xDim|1
         end
      end
   in
      local
         class FreeRep
            meth createRep($)
               {System.printName @value}
            end
         end
      in
         class FreeLayoutObject from SimpleLayoutObject FreeRep end
         class FreeGrLayoutObject from SimpleGrLayoutObject FreeRep end
      end

      local
         class FutureRep
            meth createRep($)
               {System.printName @value}#'<Fut>'
            end
         end
      in
         class FutureLayoutObject from SimpleLayoutObject FutureRep end
         class FutureGrLayoutObject from SimpleGrLayoutObject FutureRep end
      end
   end

   class ByteStringLayoutObject from SimpleLayoutObject
      meth createRep($)
         {ByteString.toString @value}
      end
   end

   class GenericLayoutObject from SimpleLayoutObject
      meth createRep($)
         Type = {Value.status @value}.1
      in
         type <- Type
         '<'#Type#'>'
      end
   end

   class AtomRefLayoutObject from SimpleLayoutObject
      meth createRep($)
         {@value getStr($)}
      end
   end
end
