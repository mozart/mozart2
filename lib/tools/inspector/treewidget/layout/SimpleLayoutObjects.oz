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
            XDim =
\ifndef INSPECTOR_GTK_GUI
            case String of 39|_ then 2 else 0 end +
\endif
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
         MaxLen = {@visual get(widgetInternalAtomSize $)}
      in
         {Helper.convert MaxLen @value PrintStr LengthStr}
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
               Suffix = if {IsNeeded @value} then '<Needed>' else '' end
            in
               PrintStr  = {System.printName @value}#Suffix
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
               Suffix = if {IsNeeded @value} then
                           '<Future Needed>' else '<Future>' end
            in
               PrintStr  = {System.printName @value}#Suffix
               LengthStr = PrintStr
            end
         end
      in
         class FutureLayoutObject from SimpleLayoutObject FutureRep end
         class FutureGrLayoutObject from SimpleGrLayoutObject FutureRep end
      end

      local
         class FailedRep
            meth createRep(PrintStr LengthStr)
               PrintStr  = '<Failed Value>'
               LengthStr = PrintStr
            end
         end
      in
         class FailedLayoutObject from SimpleLayoutObject FailedRep end
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
         MaxLen = {@visual get(widgetInternalAtomSize $)}
      in
         {Helper.convert MaxLen @value PrintStr LengthStr}
      end
   end

   class GenericLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         Val    = @value
         Type   = {Value.status Val}.1
         MaxLen = {@visual get(widgetInternalAtomSize $)}
      in
         type <- Type
         {Helper.convert MaxLen Val PrintStr LengthStr}
      end
   end

   class VariableRefLayoutObject from SimpleLayoutObject
      meth createRep(PrintStr LengthStr)
         PrintStr  = {@value getStr($)}
         LengthStr = PrintStr
      end
   end
end
