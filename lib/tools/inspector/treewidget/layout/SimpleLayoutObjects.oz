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
            XDim = case String of 39|_ then 2 else 0 end +
            {VirtualString.length LengthStr}
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
         PrintStr  = {Int.toString @value}
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

   class ProcedureLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         Value = @value
         Arity = {Procedure.arity Value}
      in
         PrintStr =case {System.printName Value}
                   of ''   then '<P/'#Arity#'>'
                   [] Name then '<P/'#Arity#' '#Name#'>'
                   end
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
         fun {IsPrefix P S}
            case P
            of P|Pr then
               case S
               of S|Sr then S == P andthen {IsPrefix Pr Sr}
               [] _    then false
               end
            [] nil  then true
            end
         end

         class FutureRep
            meth checkFutureType(V $)
               ValS    = {Value.toVirtualString V 0 0}
               SearchS = {String.token ValS &< _}
            in
               if {IsPrefix "future>" SearchS}                     then '<Fut>'
               elseif {IsPrefix "future byNeed: \'fail\'" SearchS} then '<Failed>'
               else '<ByNeed>'
               end
            end
            meth createRep(PrintStr LengthStr)
               Value = @value
            in
               PrintStr  = {System.printName Value}#FutureRep, checkFutureType(Value $)
               LengthStr = PrintStr
            end
         end
      in
         class FutureLayoutObject from SimpleLayoutObject FutureRep end
         class FutureGrLayoutObject from SimpleGrLayoutObject FutureRep end
      end
   end

   local
      %% Reduce to visible part of a String and add end quotes
      fun {BuildString Ss W}
         case Ss
         of S|Sr then
            if W == 0
            then "..."
            else S|{BuildString Sr (W - 1)}
            end
         [] nil then nil
         end
      end

      %% QuoteString Taken from Browser
      local
         fun {OctString I Ir}
            ((I div 64) mod 8 + &0) |
            ((I div 8)  mod 8 + &0) |
            (I mod 8 + &0         ) | Ir
         end
      in
         fun {QuoteString Is}
            case Is of nil then nil
            [] I|Ir then
               case {Char.type I}
               of space then
                  case I
                  of &\n then &\\|&n|{QuoteString Ir}
                  [] &\f then &\\|&f|{QuoteString Ir}
                  [] &\r then &\\|&r|{QuoteString Ir}
                  [] &\t then &\\|&t|{QuoteString Ir}
                  [] &\v then &\\|&v|{QuoteString Ir}
                  else I|{QuoteString Ir}
                  end
               [] other then
                  case I
                  of &\a then &\\|&a|{QuoteString Ir}
                  [] &\b then &\\|&b|{QuoteString Ir}
                  else &\\|{OctString I {QuoteString Ir}}
                  end
               [] punct then
                  case I
                  of &\" then &\\|&\"|{QuoteString Ir}
                  [] &\\ then &\\|&\\|{QuoteString Ir}
                  else I|{QuoteString Ir}
                  end
               else I|{QuoteString Ir}
               end
            end
         end
      end
   in
      class StringLayoutObject from SimpleLayoutObject
         meth createRep(PrintStr LengthStr)
            VisibleString = {BuildString @value {@visual getWidth($)}}
         in
            LengthStr = {Append "\""
                         {Append {QuoteString VisibleString} "\""}}
            PrintStr  = {Helper.tkQuoteStr LengthStr}
         end
      end
   end

   class ByteStringLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         {Helper.convert @value PrintStr LengthStr}
      end
   end

   class GenericLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         Val    = @value
         Type   = {Value.status Val}.1
         ValStr = {String.toAtom {Value.toVirtualString Val 1 1}}
      in
         type <- Type
         {Helper.convert ValStr PrintStr LengthStr}
      end
   end

   class VariableRefLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         PrintStr  = {@value getStr($)}
         LengthStr = PrintStr
      end
   end
end
