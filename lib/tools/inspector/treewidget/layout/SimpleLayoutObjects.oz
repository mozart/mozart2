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
            LengthStr
         in
            {self createRep(String LengthStr)}
            XDim = case String of 39|_ then 2 else 0 end + {VirtualString.length LengthStr}
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
      meth createRep(PrintStr LengthStr)
         PrintStr  = @value
         LengthStr = PrintStr
      end
   end

   class WordSMLLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         Value = @value
      in
         PrintStr  = {Word.toInt Value} %% More to be determined
         LengthStr = PrintStr
      end
   end

   class FloatLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         PrintStr  = {Float.toString @value}
         LengthStr = PrintStr
      end
   end

   class AtomLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         {Helper.convert @value PrintStr LengthStr}
      end
   end

   class NameLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         Value = @value
      in
         PrintStr  = case Value
                     of false then type <- bool   'false'
                     [] true  then type <- bool   'true'
                     [] unit  then type <- 'unit' 'unit'
                     else '<N:'#{System.printName Value}#'>'
                     end
         LengthStr = PrintStr
      end
   end

   class NameSMLLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         Value = @value
      in
         PrintStr  = case Value
                     of false then type <- bool   'false'
                     [] true  then type <- bool   'true'
                     [] unit  then type <- 'unit' '()'
                     else '<N:'#{System.printName Value}#'>'
                     end
         LengthStr = PrintStr
      end
   end

   class ProcedureLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         Value = @value
      in
         PrintStr  = '<P/'#{Procedure.arity Value}#' '#{System.printName Value}#'>'
         LengthStr = PrintStr
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
               RepStr RepLen
            in
               {self createRep(RepStr _)}
               RepLen = {VirtualString.length RepStr}
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
            meth createRep(PrintStr LengthStr)
               PrintStr  = {System.printName @value}
               LengthStr = PrintStr
            end
         end
      in
         class FreeLayoutObject from SimpleLayoutObject FreeRep end
         class FreeGrLayoutObject from SimpleGrLayoutObject FreeRep end
      end

      local
         class FutureRep
            meth createRep(PrintStr LengthStr)
               PrintStr  = {System.printName @value}#'<Fut>'
               LengthStr = PrintStr
            end
         end
      in
         class FutureLayoutObject from SimpleLayoutObject FutureRep end
         class FutureGrLayoutObject from SimpleGrLayoutObject FutureRep end
      end
   end

   class ByteStringLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         LengthStr = {ByteString.toString @value}
         PrintStr  = {Helper.quoteString LengthStr}
      end
   end

   class GenericLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         Type = {Value.status @value}.1
      in
         type <- Type
         PrintStr  = '<'#Type#'>'
         LengthStr = PrintStr
      end
   end

   class AtomRefLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         PrintStr  = {@value getStr($)}
         LengthStr = PrintStr
      end
   end
end
