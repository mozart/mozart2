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
   class ContainerLayoutObject from LayoutObject
      attr
         lastXDim %% X Dimension (last Entry)
         yDim     %% Y Dimension
         horzMode %% Horizontal Mode
      meth getYDim($)
         @yDim
      end
      meth getXYDim($)
         @xDim|@yDim
      end
      meth getLastXDim($)
         @lastXDim
      end
      meth getHorzMode($)
         @horzMode
      end
      meth layout
         {self checkHorzMode(1)}
         case @dirty of fresh then skip else dirty <- true end
         if @horzMode
         then ContainerLayoutObject, horizontalLayout(1 0)
         else ContainerLayoutObject, verticalLayout(1 0 0)
         end
      end
      meth horizontalLayout(I XDim)
         Node    = {Dictionary.get @items I}
         NewXDim = (XDim + {Node layoutX($)})
      in
         if I < @width
         then ContainerLayoutObject, horizontalLayout((I + 1) NewXDim)
         else
            EndXDim = if {self noSep($)} then NewXDim else (NewXDim + (I - 1)) end
         in
            @xDim    =  EndXDim
            lastXDim <- EndXDim
            yDim     <- 1
         end
      end
      meth verticalLayout(I XDim YDim)
         Node = {Dictionary.get @items I}
      in
         case {Node layoutY($)}
         of IXDim|IYDim then
            NewYDim = (YDim + IYDim)
            NewXDim = {Max XDim IXDim}
         in
            if I < @width
            then ContainerLayoutObject, verticalLayout((I + 1) NewXDim NewYDim)
            else
               @xDim    =  NewXDim
               lastXDim <- {Node getLastXDim($)}
               yDim     <- NewYDim
            end
         end
      end
      meth isVert($)
         true
      end
   end

   class NormalAdjust
      meth adjustLayout(LXDim BXDim)
         NLastXDim = (@lastXDim + BXDim)
         NewXDim   = {Max NLastXDim @xDim}
      in
         xDim     <- (LXDim + NewXDim)
         lastXDim <- (LXDim + NLastXDim)
      end
   end

   class IndentAdjust
      meth adjustLayout(LXDim BXDim)
         NLastXDim = (@lastXDim + BXDim)
         NewXDim   = {Max NLastXDim @xDim}
      in
         if @horzMode
         then
            xDim     <- (LXDim + NewXDim)
            lastXDim <- (LXDim + NLastXDim)
         else
            RealXDim = {Max (LXDim - 3) NewXDim}
         in
            xDim     <- (3 + RealXDim)
            yDim     <- (@yDim + 1)
            lastXDim <- (3 + NLastXDim)
         end
      end
   end

   class LabelShareObject
      meth checkHorzMode(I)
         if {{Dictionary.get @items I} isVert($)}
         then horzMode <- false
         elseif I < @width
         then LabelShareObject, checkHorzMode((I + 1))
         else horzMode <- true
         end
      end
   end

   class InfixShareObject
      meth checkHorzMode(I)
         InfixShareObject, infixCheckHorzMode(I false)
      end
      meth infixCheckHorzMode(I Mode)
         Items   = @items
         Node    = {Dictionary.get Items I}
         NewMode = ({Node isVert($)} orelse Mode)
      in
         if {Node isInfix($)} andthen {Node notEmbraced($)}
         then
            if {Node mustChange($)}
            then {Node
                  change({New Helper.embraced create({Node getNode($)} self I @visual round)})}
            else {Dictionary.put Items I {New Helper.embraced create(Node self I @visual round)}}
            end
         end
         if I < @width
         then InfixShareObject, infixCheckHorzMode((I + 1) NewMode)
         else horzMode <- {Not NewMode}
         end
      end
   end

   class GraphShare
      meth graphHorzMode(I Mode NewMode)
         NewMode = false
      end
   end
in
   class HashTupleLayoutObject from ContainerLayoutObject InfixShareObject
      meth layout
         if {IsFree @xDim} then ContainerLayoutObject, layout end
      end
      meth layoutX($)
         HashTupleLayoutObject, layout @xDim
      end
      meth layoutY($)
         HashTupleLayoutObject, layout @xDim|@yDim
      end
      meth noSep($)
         true
      end
   end

   class HashTupleGrLayoutObject from HashTupleLayoutObject NormalAdjust GraphShare
      meth layout
         if {IsFree @xDim}
         then
            ContainerLayoutObject, layout
            if {@entry hasRefs($)}
            then
               case @mode
               of Ref|OB|CB then
                  {OB layout} {CB layout}
                  NormalAdjust, adjustLayout(({Ref layoutX($)} + 1) 1)
               end
            end
         end
      end
      meth layoutX($)
         HashTupleLayoutObject, layout @xDim
      end
      meth layoutY($)
         HashTupleGrLayoutObject, layout @xDim|@yDim
      end
   end

   class PipeTupleLayoutObject from ContainerLayoutObject NormalAdjust
                                  LabelShareObject InfixShareObject
      meth checkHorzMode(I)
         case @type
         of pipetuple then InfixShareObject, infixCheckHorzMode(I false)
         [] list      then LabelShareObject, checkHorzMode(I)
         end
      end
      meth layout
         if {IsFree @xDim}
         then
            case @type
            of pipetuple then ContainerLayoutObject, layout
            [] list then
               ContainerLayoutObject, layout
               NormalAdjust, adjustLayout({@label layoutX($)} {@brace layoutX($)})
            end
         end
      end
      meth layoutX($)
         PipeTupleLayoutObject, layout @xDim
      end
      meth layoutY($)
         PipeTupleLayoutObject, layout @xDim|@yDim
      end
      meth noSep($)
         @type == pipetuple
      end
   end

   class PipeTupleGrLayoutObject from ContainerLayoutObject NormalAdjust
      meth layout
         if {IsFree @xDim}
         then
            HorzMode = @horzMode
         in
            PipeTupleGrLayoutObject, graphHorzMode(1 false HorzMode)
            case @dirty of fresh then skip else dirty <- true end
            if HorzMode
            then ContainerLayoutObject, horizontalLayout(1 0)
            else ContainerLayoutObject, verticalLayout(1 0 0)
            end
            if {@entry hasRefs($)}
            then
               case @mode
               of Ref|OB|CB then
                  {OB layout} {CB layout}
                  NormalAdjust, adjustLayout(({Ref layoutX($)} + 1) 1)
               end
            end
         end
      end
      meth layoutX($)
         PipeTupleGrLayoutObject, layout @xDim
      end
      meth layoutY($)
         PipeTupleGrLayoutObject, layout @xDim|@yDim
      end
      meth graphHorzMode(I Mode HorzMode)
         if {IsFree HorzMode}
         then
            Items   = @items
            Node    = {Dictionary.get @items I}
            NewMode = ({Node isVert($)} orelse Mode)
         in
            if {Node isInfix($)} andthen {Node notEmbraced($)}
            then
               if {Node mustChange($)}
               then {Node change({New Helper.embraced create({Node getNode($)}
                                                          self I @visual round)})}
               else {Dictionary.put Items I
                     {New Helper.embraced create(Node self I @visual round)}}
               end
            end
            if I < @width
            then
               horzMode <- HorzMode
               {{Dictionary.get Items (I + 1)} graphHorzMode(1 NewMode HorzMode)}
            else HorzMode = {Not NewMode}
            end
         end
      end
      meth noSep($)
         true
      end
   end

   local
      class LabelTupleCoreLayoutObject from ContainerLayoutObject LabelShareObject
         meth layout
            if {IsFree @xDim}
            then
               ContainerLayoutObject, layout
               {self adjustLayout({@label layoutX($)} {@brace layoutX($)})}
            end
         end
         meth layoutX($)
            LabelTupleCoreLayoutObject, layout @xDim
         end
         meth layoutY($)
            LabelTupleCoreLayoutObject, layout @xDim|@yDim
         end
         meth noSep($)
            false
         end
      end

      class LabelTupleGrCoreLayoutObject from LabelTupleCoreLayoutObject GraphShare
         meth layout
            if {IsFree @xDim}
            then
               BX = {@brace layoutX($)}
            in
               ContainerLayoutObject, layout
               if {@entry hasRefs($)}
               then {self adjustLayout(({@mode layoutX($)} + {@label layoutX($)}) BX)}
               else {self adjustLayout({@label layoutX($)} BX)}
               end
            end
         end
         meth layoutX($)
            LabelTupleGrCoreLayoutObject, layout @xDim
         end
         meth layoutY($)
            LabelTupleGrCoreLayoutObject, layout @xDim|@yDim
         end
      end
   in
      class LabelTupleLayoutObject from LabelTupleCoreLayoutObject NormalAdjust end
      class LabelTupleIndLayoutObject from LabelTupleCoreLayoutObject IndentAdjust end
      class LabelTupleGrLayoutObject from LabelTupleGrCoreLayoutObject NormalAdjust end
      class LabelTupleGrIndLayoutObject from LabelTupleGrCoreLayoutObject IndentAdjust end
   end

   class RecordLayoutObject from LabelTupleLayoutObject end
   class RecordIndLayoutObject from LabelTupleIndLayoutObject end
   class RecordGrLayoutObject from LabelTupleGrLayoutObject end
   class RecordGrIndLayoutObject from LabelTupleGrIndLayoutObject end

   class FDIntLayoutObject from LabelTupleLayoutObject
      meth checkHorzMode(I)
         horzMode <- true
      end
   end

   class FDIntGrLayoutObject from LabelTupleGrLayoutObject
      meth checkHorzMode(I)
         horzMode <- true
      end
   end

   class FSVarLayoutObject from FDIntLayoutObject
      meth noSep($)
         true
      end
   end

   class FSVarGrLayoutObject from FDIntGrLayoutObject
      meth noSep($)
         true
      end
   end
end
