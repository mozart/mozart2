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
   class ContainerDrawObject from DrawObject
      attr
         dirty : fresh %% Dirty Flag (enhanced to fresh/true/false)
      meth draw(X Y)
         case @dirty
         of false then {@visual move(X Y @tag {self getFirstItem($)})}
         else
            Visual = @visual
         in
            dirty <- false
            {Visual tagTreeDown(@tag)}
            {self performDraw(X Y)}
            {Visual tagTreeUp}
         end
      end
      meth drawX(X Y $)
         ContainerDrawObject, draw(X Y) (X + @xDim)
      end
      meth drawY(X Y $)
         ContainerDrawObject, draw(X Y) (Y + @yDim)
      end
      meth performDraw(X Y)
         Stop = {@visual getStopVar($)}
      in
         if @horzMode
         then
            if {self noSep($)}
            then ContainerDrawObject, horizontalNoSepDraw(1 X Y Stop)
            else ContainerDrawObject, horizontalSepDraw(1 X Y Stop)
            end
         else ContainerDrawObject, verticalDraw(1 X Y Stop)
         end
      end
      meth horizontalSepDraw(I X Y Stop)
         Node = {Dictionary.get @items I}
         NewX = ({Node drawX(X Y $)} + 1)
      in
         if I < @width
         then
            if {IsFree Stop}
            then ContainerDrawObject, horizontalSepDraw((I + 1) NewX Y Stop)
            else {@visual handleStop({@parent getSimpleRootIndex(@index $)})}
            end
         end
      end
      meth horizontalNoSepDraw(I X Y Stop)
         Node = {Dictionary.get @items I}
         NewX = {Node drawX(X Y $)}
      in
         if I < @width
         then
            if {IsFree Stop}
            then ContainerDrawObject, horizontalNoSepDraw((I + 1) NewX Y Stop)
            else {@visual handleStop({@parent getSimpleRootIndex(@index $)})}
            end
         end
      end
      meth verticalDraw(I X Y Stop)
         Node = {Dictionary.get @items I}
         NewY = {Node drawY(X Y $)}
      in
         if I < @width
         then
            if {IsFree Stop}
            then ContainerDrawObject, verticalDraw((I + 1) X NewY Stop)
            else {@visual handleStop({@parent getSimpleRootIndex(@index $)})}
            end
         end
      end
      meth eliminateFresh(I)
         if I =< @width
         then
            Items = @items
            Node  = {Dictionary.get Items I}
         in
            if {Node isFresh($)}
            then
               NewNode = {New Helper.bitmap create(depth self I @visual)}
            in
               {NewNode setRescueValue({Node getValue($)})}
               {Dictionary.put Items I NewNode}
            else {Node eliminateFresh(1)}
            end
            ContainerDrawObject, eliminateFresh((I + 1))
         end
      end
      meth isFresh($)
         @dirty == fresh
      end
      meth undraw
         case @dirty of false then {@visual delete(@tag)} {self makeDirty}
         else skip
         end
      end
      meth performMakeDirty(I)
         {{Dictionary.get @items I} makeDirty}
         if I < @width
         then ContainerDrawObject, performMakeDirty((I + 1))
         end
      end
      meth eraseNodes(Index N)
         Items = @items
      in
         {{Dictionary.get Items Index} undraw}
         {Dictionary.remove Items Index}
         if N > 1 then ContainerDrawObject, eraseNodes((Index - 1) (N - 1)) end
      end
      meth searchNode(XA YA X Y $)
         if @horzMode
         then ContainerDrawObject, horizontalSearch(1 XA YA X Y $)
         else ContainerDrawObject, verticalSearch(1 XA YA X Y $)
         end
      end
      meth horizontalSearch(I XA YA X Y $)
         Node = {Dictionary.get @items I}
         XM   = (XA + {Node getXDim($)})
      in
         if X >= XA andthen X < XM
         then {Node searchNode(XA YA X Y $)}
         elseif I < @width
         then
            NewXM = if {self noSep($)} then XM else (XM + 1) end
         in
            ContainerDrawObject, horizontalSearch((I + 1) NewXM YA X Y $)
         else nil
         end
      end
      meth verticalSearch(I XA YA X Y $)
         Node = {Dictionary.get @items I}
      in
         case {Node getXYDim($)}
         of XDim|YDim then
            YM = (YA + YDim)
         in
            if Y >= YA andthen Y < YM andthen X >= XA andthen X < (XA + XDim)
            then {Node searchNode(XA YA X Y $)}
            elseif I < @width
            then ContainerDrawObject, verticalSearch((I + 1) XA YM X Y $)
            else nil
            end
         end
      end
   end

   class InteractionDrawObject from ContainerDrawObject
      meth modifyWidth(Index N)
         Width    = @width %% former Index
         MaxWidth = {self getMaxWidth(N $)}
      in
         if N > 0
         then
            Node = {Dictionary.get @items Width}
         in
            case {Node getType($)}
            of widthbitmap then
               NewWidth = {Min ((Width - 1) + N) MaxWidth}
            in
               {Node undraw}
               {self adjustWidth(NewWidth Width)}
               InteractionDrawObject, notify
            else skip
            end
         elsecase N
         of 0 then skip
         else
            Node = {Dictionary.get @items Width}
            DelCount NewWidth NewIndex
         in
            case {Node getType($)}
            of widthbitmap then
               NewWidth = {Max (Width - 1 + N) 0}
               DelCount = {Min ({Abs N} + 1) Width}
            else
               NewWidth = {Max (Width + N) 0}
               DelCount = {Min {Abs N} MaxWidth}
            end
            NewIndex = {Max (Width - DelCount + 1) 1}
            {self eraseNodes(Width DelCount)}
            {self addSeparators(1 NewWidth)}
            {self adjustWidth(NewWidth NewIndex)}
            InteractionDrawObject, notify
         end
      end
      meth modifyDepth(Index N)
         if N < 0
         then {@parent up((N + 1) @index)}
         elsecase N
         of 0 then skip
         elsecase Index
         of 0 then {@parent modifyDepth(@index N)}
         else InteractionDrawObject, showMoreDepth(Index N)
         end
      end
      meth showMoreDepth(Index N)
         Items    = @items
         Node     = {Dictionary.get Items Index}
         Value    = {Node getValue($)}
         Visual   = @visual
         OldDepth = {Visual getDepth($)}
         CurDepth = @depth
         NewDepth = (CurDepth + N - 1)
         NewNode
      in
         {Node undraw}
         {Visual setDepth(NewDepth)}
         NewNode = {Visual treeCreate(Value self Index CurDepth $)}
         {Visual setDepth(OldDepth)}
         if {Node mustChange($)}
         then {Node change(NewNode)}
         else {Dictionary.put Items Index NewNode}
         end
         {self notify}
      end
      meth notify
         xDim <- _
         {@parent notify}
      end
      meth doNotify %% Necessary for atomic Replace Optimization
         xDim <- _
         {@parent notify}
      end
      meth up(N I)
         if N < 0
         then {@parent up((N + 1) @index)}
         else {self replace(I @value replaceDepth)}
         end
      end
      meth replace(I Value Call)
         Items   = @items
         OldNode = {Dictionary.get Items I}
         NewNode
      in
         {OldNode undraw}
         NewNode = case Call
                   of replaceNormal then {@visual treeCreate(Value self I @depth $)}
                   [] replaceDepth  then
                      Node = {New Helper.bitmap create(depth self I @visual)}
                   in
                      {self notify}
                      {Node setRescueValue({OldNode getValue($)})} Node
                   end
         if {OldNode mustChange($)}
         then {OldNode change(NewNode)}
         else {Dictionary.put Items I NewNode}
         end
      end
      meth link(I Value)
         Items     = @items
         OldNode   = {Dictionary.get Items I}
         InnerNode = {OldNode getInnerNode($)}
         Visual    = @visual
         NewNode Proxy
      in
         {OldNode undraw}
         NewNode = {Visual treeCreate(Value self I @depth $)}
         Proxy   = {New Helper.proxy create(InnerNode NewNode I Visual 0)}
         if {OldNode isSep($)}
         then {OldNode change(Proxy)}
         else {Dictionary.put Items I Proxy}
         end
         {self notify}
      end
      meth unlink(I)
         Items     = @items
         OldNode   = {Dictionary.get Items I}
         InnerNode = {OldNode getInnerNode($)}
         Node      = {InnerNode unbox($)}
         Value     = {Node getValue($)}
         NewNode
      in
         {OldNode undraw}
         NewNode = {@visual treeCreate(Value self I @depth $)}
         if {OldNode isSep($)}
         then {OldNode change(
                          if {Node isProxy($)} then {Node change(NewNode)} Node else NewNode end)}
         else {Dictionary.put Items I
               if {Node mustChange($)} then {Node change(NewNode)} Node else NewNode end}
         end
         {self notify}
      end
      meth isMapped(Index $)
         case Index
         of 0 then {@parent isMapped(@index $)}
         else {{Dictionary.get @items Index} isProxy($)}
         end
      end
   end
in
   class HashTupleDrawObject from InteractionDrawObject
      meth getFirstItem($)
         {{Dictionary.get @items 1} getFirstItem($)}
      end
      meth makeDirty
         dirty <- true ContainerDrawObject, performMakeDirty(1)
      end
      meth getMaxWidth(N $)
         @maxWidth
      end
   end

   class HashTupleGrDrawObject from HashTupleDrawObject
      meth draw(X Y)
         case @dirty
         of false then {@visual move(X Y @tag {self getFirstItem($)})}
         elsecase @mode
         of Ref|OB|CB then
            Visual = @visual
         in
            dirty <- false
            {Visual tagTreeDown(@tag)}
            if {@entry hasRefs($)}
            then
               ContainerDrawObject, performDraw({OB drawX({Ref drawX(X Y $)} Y $)} Y)
               {CB draw((X + @lastXDim - 1) (Y + @yDim - 1))}
            else
               {Ref dirtyUndraw} {OB dirtyUndraw} {CB dirtyUndraw}
               ContainerDrawObject, performDraw(X Y)
            end
            {Visual tagTreeUp}
         end
      end
      meth drawX(X Y $)
         HashTupleGrDrawObject, draw(X Y) (X + @xDim)
      end
      meth drawY(X Y $)
         HashTupleGrDrawObject, draw(X Y) (Y + @yDim)
      end
      meth getFirstItem($)
         if {@entry hasRefs($)}
         then case @mode of Ref|_|_ then {Ref getFirstItem($)} end
         else {{Dictionary.get @items 1} getFirstItem($)}
         end
      end
      meth makeDirty
         case @mode of Ref|OB|CB then
            {@entry sleep} {Ref makeDirty} {OB makeDirty} {CB makeDirty} dirty <- true
            ContainerDrawObject, performMakeDirty(1)
         end
      end
      meth searchNode(XA YA X Y $)
         NewXA = if {@entry hasRefs($)}
                 then case @mode of Ref|_|_ then (XA + {Ref getXDim($)} + 1) end
                 else XA
                 end
      in
         ContainerDrawObject, searchNode(NewXA YA X Y $)
      end
   end

   class PipeTupleDrawObject from HashTupleDrawObject
      meth performDraw(X Y)
         case @type
         of list then
            {@label draw(X Y)}
            ContainerDrawObject, performDraw((X + 1) Y)
            {@brace draw((X + @lastXDim - 1) (Y + @yDim - 1))}
         else ContainerDrawObject, performDraw(X Y)
         end
      end
      meth getFirstItem($)
         case @type
         of list then {@label getFirstItem($)}
         else {{Dictionary.get @items 1} getFirstItem($)}
         end
      end
      meth makeDirty
         case @type
         of list then {@label makeDirty} {@brace makeDirty}
         else skip
         end
         dirty <- true
         ContainerDrawObject, performMakeDirty(1)
      end
      meth searchNode(XA YA X Y $)
         case @type
         of list then
            case {@label searchNode(XA YA X Y $)}
            of nil then
               case ContainerDrawObject, searchNode((XA + 1) YA X Y $)
               of nil then {@brace searchNode((XA + @lastXDim - 1) (YA + @yDim - 1) X Y $)}
               [] Res then Res
               end
            [] Res then Res
            end
         else ContainerDrawObject, searchNode(XA YA X Y $)
         end
      end
      meth getMaxWidth(N $)
         Width = @width
      in
         if N > 0 then (Width + N) else Width end
      end
      meth eraseNodes(Index N)
         if @type == list andthen N > 0
         then {@label undraw} {@brace undraw}
         end
         ContainerDrawObject, eraseNodes(Index N)
      end
      meth replace(I Value Call)
         if @type == pipetuple andthen I == @width
         then
            Items = @items
            Node  = {Dictionary.get Items I}
         in
            if {Node isProxy($)}
            then InteractionDrawObject, replace(I Value Call)
            else
               {Node undraw}
               case Call
               of replaceNormal then {self adjustWidth(@maxWidth I)}
               else
                  NewNode = {New Helper.bitmap create(depth self I @visual)}
               in
                  {NewNode setRescueValue({Node getValue($)})}
                  {Dictionary.put Items I NewNode}
                  InteractionDrawObject, notify
               end
            end
         else InteractionDrawObject, replace(I Value Call)
         end
      end
   end

   local
      class PipeTupleGrDrawObject from HashTupleGrDrawObject
         meth modifyWidth(Index N)
            EndNode = PipeTupleGrDrawObject, seekEnd($)
         in
            {EndNode doModifyWidth(N)}
         end
         meth doModifyWidth(N)
            Items  = @items
            Width  = @width
            RWidth = (@rIndex + Width - 1)
         in
            if N > 0
            then
               Node = {Dictionary.get Items Width}
            in
               case {Node getType($)}
               of widthbitmap then
                  Visual   = @visual
                  NewWidth = ((RWidth - 1) + N) NewNode
                  Stop     = {Visual getStopVar($)}
               in
                  {Node undraw}
                  case Width
                  of 2 then
                     {Dictionary.put Items Width NewNode}
                     NewNode = {Visual listCreate(@value.2 self Width (@rIndex + 1)
                                                  (@depth - 1) NewWidth Stop $)}
                  else {self performInsertion(@value 1 @rIndex NewWidth Stop)}
                  end
                  PipeTupleGrDrawObject, notify
               else skip
               end
            elsecase N
            of 0 then skip
            else
               Node = {Dictionary.get @items Width}
               NewWidth
            in
               case {Node getType($)}
               of widthbitmap then NewWidth = {Max ((RWidth - 1) + N) 0}
               else NewWidth = {Max (RWidth + N) 0}
               end
               {self goUp(NewWidth)}
            end
         end
         meth modifyDepth(Index N)
            if Index == 0 orelse N < 0
            then {{self seekStart($)} doModifyDepth(Index N)}
            else PipeTupleGrDrawObject, showMoreDepth(Index N)
            end
         end
         meth doModifyDepth(Index N)
            if N < 0
            then {@parent up((N + 1) @index)}
            elsecase N
            of 0 then skip
            elsecase Index
            of 0 then {@parent modifyDepth(@index N)}
            else InteractionDrawObject, showMoreDepth(Index N)
            end
         end
         meth map(Index F)
            {{self seekStart($)} doMap(F)}
         end
         meth doMap(F)
            DrawObject, map(0 F)
         end
         meth seekEnd($)
            Width = @width
         in
            case Width of 2 then
               Node = {Dictionary.get @items Width}
            in
               if {IsFree Node} then self else {Node seekEnd($)} end
            else self
            end
         end
         meth notify
            PipeTupleGrDrawObject, downNotify
            {self doNotify}
         end
         meth downNotify
            Width = @width
         in
            xDim     <- _
            horzMode <- _
            case Width of 2 then
               Node = {Dictionary.get @items Width}
            in
               if {IsFree Node} then skip else {Node downNotify} end
            end
         end
         meth goUp(NewWidth)
            if @rIndex == NewWidth
            then
               Items = @items
               Width = @width
               Node  = {Dictionary.get Items Width}
            in
               {Node undraw}
               {Dictionary.put Items Width {New Helper.bitmap create(width self Width @visual)}}
               {self doNotify}
            elseif {self isMaster($)}
            then
               {self undraw}
               width <- 1
               {Dictionary.put @items 1 {New Helper.bitmap create(width self 1 @visual)}}
               {self doNotify}
            else {@parent goUp(NewWidth)}
            end
         end
         meth replace(I Value Call)
            if I == @width andthen {System.eq {self seekEnd($)} self}
            then
               Items = @items
               Node  = {Dictionary.get Items I}
            in
               if {Node isProxy($)}
               then InteractionDrawObject, replace(I Value Call)
               else
                  {Node undraw}
                  case Call
                  of replaceNormal then
                     Visual = @visual
                     Stop   = {Visual getStopVar($)}
                     Width  = {Visual getWidth($)}
                     NewNode
                  in
                     {Dictionary.put Items I NewNode}
                     NewNode = {Visual listCreate(Value self I (@rIndex + 1)
                                                  (@depth - 1) Width Stop $)}
                  else
                     NewNode = {New Helper.bitmap create(depth self I @visual)}
                  in
                     {NewNode setRescueValue({Node getValue($)})}
                     {Dictionary.put Items I NewNode}
                     {self doNotify}
                  end
               end
            else InteractionDrawObject, replace(I Value Call)
            end
         end
         meth isMapped(Index $)
            case Index
            of 0 then {{self seekStart($)} doIsMapped($)}
            else {{Dictionary.get @items Index} isProxy($)}
            end
         end
      end
   in
      class PipeTupleGrSDrawObject from PipeTupleGrDrawObject
         meth seekStart($)
            {@parent seekStart($)}
         end
         meth doNotify
            xDim     <- _
            horzMode <- _
            {@parent doNotify}
         end
         meth getRootIndex(I $)
            PipeTupleGrDrawObject, downNotify
            PipeTupleGrSDrawObject, doGetRootIndex(I $)
         end
         meth doGetRootIndex(I $)
            xDim     <- _
            horzMode <- _
            {@parent doGetRootIndex(@index $)}
         end
         meth isMaster($)
            false
         end
      end

      class PipeTupleGrMDrawObject from PipeTupleGrDrawObject
         meth seekStart($)
            self
         end
         meth doNotify
            xDim     <- _
            horzMode <- _
            {@parent notify}
         end
         meth getRootIndex(I $)
            PipeTupleGrDrawObject, downNotify
            PipeTupleGrMDrawObject, doGetRootIndex(I $)
         end
         meth doGetRootIndex(I $)
            xDim     <- _
            horzMode <- _
            {@parent getRootIndex(@index $)}
         end
         meth isMaster($)
            true
         end
         meth doIsMapped($)
            {@parent isMapped(@index $)}
         end
      end
   end

   local
      class LabelTupleCoreDrawObject from InteractionDrawObject
         meth performDraw(X Y)
            Brace = @brace
         in
            {self drawBody(X Y)}
            {Brace draw((X + @lastXDim - {Brace getXDim($)}) (Y + @yDim - 1))}
         end
         meth getFirstItem($)
            {@label getFirstItem($)}
         end
         meth makeDirty
            dirty <- true {@label makeDirty} {@brace makeDirty}
            ContainerDrawObject, performMakeDirty(1)
         end
         meth getMaxWidth(N $)
            @maxWidth
         end
         meth searchNode(XA YA X Y $)
            case {self searchBody(XA YA X Y $)}
            of nil then
               Brace = @brace
               BX    = {Brace getXDim($)}
            in
               {Brace searchNode((XA + @lastXDim - BX) (YA + @yDim - 1) X Y $)}
            [] Res then Res
            end
         end
      end

      class LabelTupleGrCoreDrawObject from LabelTupleCoreDrawObject
         meth getFirstItem($)
            if {@entry hasRefs($)} then {@mode getFirstItem($)} else {@label getFirstItem($)} end
         end
         meth makeDirty
            {@entry sleep}
            {@mode makeDirty}
            LabelTupleDrawObject, makeDirty
         end
      end
   in
      class LabelTupleDrawObject from LabelTupleCoreDrawObject
         meth drawBody(X Y)
            ContainerDrawObject, performDraw({@label drawX(X Y $)} Y)
         end
         meth searchBody(XA YA X Y $)
            Label = @label
         in
            case {Label searchNode(XA YA X Y $)}
            of nil then ContainerDrawObject, searchNode((XA + {Label getXDim($)}) YA X Y $)
            [] Res then Res
            end
         end
      end

      class LabelTupleIndDrawObject from LabelTupleCoreDrawObject
         meth drawBody(X Y)
            if @horzMode
            then ContainerDrawObject, performDraw({@label drawX(X Y $)} Y)
            else
               {@label drawX(X Y _)}
               ContainerDrawObject, performDraw((X + 3) (Y + 1))
            end
         end
         meth searchBody(XA YA X Y $)
            Label = @label
         in
            case {Label searchNode(XA YA X Y $)}
            of nil then
               if @horzMode
               then ContainerDrawObject, searchNode((XA + {Label getXDim($)}) YA X Y $)
               else ContainerDrawObject, searchNode((XA + 3) (YA + 1) X Y $)
               end
            [] Res then Res
            end
         end
      end

      class LabelTupleGrDrawObject from LabelTupleGrCoreDrawObject
         meth drawBody(X Y)
            NewX = if {@entry hasRefs($)} then {@mode drawX(X Y $)} else {@mode dirtyUndraw} X end
         in
            ContainerDrawObject, performDraw({@label drawX(NewX Y $)} Y)
         end
         meth searchBody(XA YA X Y $)
            NewXA = if {@entry hasRefs($)} then (XA + {@mode getXDim($)}) else XA end
            Label = @label
         in
            case {Label searchNode(NewXA YA X Y $)}
            of nil then ContainerDrawObject, searchNode((NewXA + {Label getXDim($)}) YA X Y $)
            [] Res then Res
            end
         end
      end

      class LabelTupleGrIndDrawObject from LabelTupleGrCoreDrawObject
         meth drawBody(X Y)
            NewX = if {@entry hasRefs($)} then {@mode drawX(X Y $)} else {@mode dirtyUndraw} X end
         in
            if @horzMode
            then ContainerDrawObject, performDraw({@label drawX(NewX Y $)} Y)
            else {@label drawX(NewX Y _)} ContainerDrawObject, performDraw((X + 3) (Y + 1))
            end
         end
         meth searchBody(XA YA X Y $)
            NewXA = if {@entry hasRefs($)} then (XA + {@mode getXDim($)}) else XA end
            Label = @label
         in
            case {Label searchNode(NewXA YA X Y $)}
            of nil then
               if @horzMode
               then ContainerDrawObject, searchNode((NewXA + {Label getXDim($)}) YA X Y $)
               else ContainerDrawObject, searchNode((XA + 3) (YA + 1) X Y $)
               end
            [] Res then Res
            end
         end
      end
   end

   class RecordDrawObject from LabelTupleDrawObject end
   class RecordIndDrawObject from LabelTupleIndDrawObject end
   class RecordGrDrawObject from LabelTupleGrDrawObject end
   class RecordGrIndDrawObject from LabelTupleGrIndDrawObject end

   local
      class KindedRecordShare
         meth tell($)
            case @dirty
            of false then
               MyValue = @value
            in
               if {IsDet @monitorValue} %% Arity changed
               then
                  Index    = @width
                  Node     = {Dictionary.get @items Index}
                  CurWidth = {@visual getWidth($)}
               in
                  {Node undraw}
                  KindedRecordCreateObject, computeArityLength(@arity 1)
                  RecordCreateObject, adjustWidth(CurWidth Index)
                  case {Value.status MyValue}
                  of det(record) then type <- record
                  else skip
                  end
               end
               if @hasLabel
               then skip
               elseif {RecordC.hasLabel MyValue}
               then
                  {@label undraw}
                  hasLabel <- true
                  label    <- {New Helper.label create({Label MyValue} '(' self @visual)}
               end
               xDim <- _
               {@parent getRootIndex(@index $)}
            else true
            end
         end
      end
   in
      class KindedRecordDrawObject from LabelTupleDrawObject KindedRecordShare
         meth performDraw(X Y)
            Value = @value
         in
            LabelTupleDrawObject, performDraw(X Y)
            if {IsKinded Value} then {@visual logVar(self Value false)} end
         end
      end

      class KindedRecordIndDrawObject from LabelTupleIndDrawObject KindedRecordShare
         meth performDraw(X Y)
            Value = @value
         in
            LabelTupleIndDrawObject, performDraw(X Y)
            if {IsKinded Value} then {@visual logVar(self Value false)} end
         end
      end

      class KindedRecordGrDrawObject from LabelTupleGrDrawObject KindedRecordShare
         meth performDraw(X Y)
            Value = @value
         in
            LabelTupleGrDrawObject, performDraw(X Y)
            if {IsKinded Value} then {@visual logVar(self Value false)} end
         end
      end

      class KindedRecordGrIndDrawObject from LabelTupleGrIndDrawObject KindedRecordShare
         meth performDraw(X Y)
            Value = @value
         in
            LabelTupleGrIndDrawObject, performDraw(X Y)
            if {IsKinded Value} then {@visual logVar(self Value false)} end
         end
      end
   end

   class FDIntDrawObject from LabelTupleDrawObject
      meth tell($)
         case @dirty
         of false then
            Parent = @parent
            Index  = @index
            RI     = {Parent getRootIndex(Index $)}
         in
            {Parent replace(Index @value replaceNormal)} RI
         else true
         end
      end
   end

   class FDIntGrDrawObject from LabelTupleGrDrawObject
      meth tell($)
         case @dirty
         of false then
            Parent = @parent
            Index  = @index
            RI     = {Parent getRootIndex(Index $)}
         in
            {@entry checkReplace}
            {Parent replace(Index @value replaceNormal)} RI
         else true
         end
      end
   end
end
