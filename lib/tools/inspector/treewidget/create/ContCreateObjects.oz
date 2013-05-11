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
   class ContainerCreateObject from CreateObject
      attr
         items    %% Container Items
         width    %% Current Displayed Width
         maxWidth %% Maximal Width
         depth    %% Local Depth
      meth create(Value Parent Index Visual Depth)
         CreateObject, create(Value Parent Index Visual Depth)
         @items  = {Dictionary.new}
         @depth  = (Depth + 1)
         {self createContainer}
      end
      meth adjustWidth(CurWidth I)
         width <- {Min CurWidth @maxWidth}
         {self performInsertion(I @value {@visual getStopVar($)})}
      end
      meth seekPos(I Xs $)
         case I
         of 1 then Xs
         elsecase Xs
         of _|Xr then ContainerCreateObject, seekPos((I - 1) Xr $)
         end
      end
      meth addSeparators(I Width)
         skip
      end
   end

   class LabelContainerCreateObject from ContainerCreateObject
      attr
         label %% Label
         brace %% Closing Brace
   end

   class GraphCreate
      attr
         entry %% RelEntry Reference
         mode  %% Mode List (Ref vs Ref|OB|CB)
      meth gcr(Entry Value Parent Index Visual Depth)
         @entry = Entry {Entry awake(self)}
         ContainerCreateObject, create(Value Parent Index Visual Depth)
         {self handleMode({Entry getEqualStr($)} Visual)}
      end
   end

   class LabelModeShare
      meth handleMode(RefStr Visual)
         PrintStr = {VirtualString.toString 'R'#RefStr}
      in
         @mode = {New Helper.marker create(PrintStr '=' self Visual)}
      end
   end

   class InfixModeShare
      meth handleMode(RefStr Visual)
         PrintStr = {VirtualString.toString 'R'#RefStr}
      in
         @mode = {New Helper.marker create(PrintStr '=' self Visual)}|
         {New Helper.atom create('(' self 0 Visual internal)}|
         {New Helper.atom create(')' self 0 Visual internal)}
      end
   end
in
   class HashTupleCreateObject from ContainerCreateObject
      meth createContainer
         @type     = hashtuple
         @maxWidth = {Width @value}
         ContainerCreateObject, adjustWidth({@visual getWidth($)} 1)
      end
      meth performInsertion(I Value Stop)
         Items  = @items
         Visual = @visual
         Depth  = @depth
         Width  = @width
      in
         if I > Width orelse {IsDet Stop}
         then
            width <- I
            {Dictionary.put Items I {New Helper.bitmap create(width self I Visual)}}
         else
            Node = {Visual treeCreate(Value.I self I Depth $)}
         in
            if I < Width
            then
               {Dictionary.put Items I {New Helper.separator create("#" Visual Node)}}
               HashTupleCreateObject, performInsertion((I + 1) Value Stop)
            elseif Width < @maxWidth
            then
               NI = (I + 1)
            in
               width <- NI
               {Dictionary.put Items I {New Helper.separator create("#" Visual Node)}}
               {Dictionary.put Items NI {New Helper.bitmap create(width self NI Visual)}}
            else
               width <- I
               {Dictionary.put Items I Node}
            end
         end
      end
      meth isInfix($)
         true
      end
   end

   class HashTupleGrCreateObject from HashTupleCreateObject GraphCreate InfixModeShare end

   local
      class PipeShare
         meth finalInsert(I Node)
            type  <- pipetuple
            width <- I
            {Dictionary.put @items I Node}
         end
      end
      fun {IsUnbound V}
         {Value.isFree V} orelse {Value.isFuture V}
      end
   in
      class PipeTupleCreateObject from LabelContainerCreateObject PipeShare
         meth createContainer
            MaxWidth = @maxWidth
         in
            @type    = pipetuple
            MaxWidth = {@visual getWidth($)}
            PipeTupleCreateObject, adjustWidth(MaxWidth 1)
         end
         meth isNormalList($)
            true
         end
         meth adjustWidth(CurWidth I)
            NewValue = ContainerCreateObject, seekPos(I @value $)
         in
            width <- CurWidth
            {self performInsertion(I NewValue {@visual getStopVar($)})}
         end
         meth performInsertion(I Vs Stop)
            Visual = @visual
            Depth  = @depth
         in
            if I > @width orelse {IsDet Stop}
            then PipeShare, finalInsert(I {New Helper.bitmap treeCreate(width self I Visual Vs)})
            elseif {IsUnbound Vs}
            then PipeShare, finalInsert(I {Visual treeCreate(Vs self I Depth $)})
            elsecase Vs
            of V|Vr then
               Node = {Visual treeCreate(V self I Depth $)}
            in
               {Dictionary.put @items I {New Helper.separator create('|' Visual Node)}}
               PipeTupleCreateObject, performInsertion((I + 1) Vr Stop)
            [] nil  then
               width <- (I - 1)
               case @type
               of pipetuple then
                  type  <- list
                  label <- {New Helper.atom create('[' self 0 Visual internal)}
                  brace <- {New Helper.atom create(']' self 0 Visual internal)}
                  PipeTupleCreateObject, removeSeparators(1)
               else skip
               end
            else PipeShare, finalInsert(I {Visual treeCreate(Vs self I Depth $)})
            end
         end
         meth isInfix($)
            @type == pipetuple
         end
         meth removeSeparators(I)
            Items = @items
         in
            {Dictionary.put Items I {{Dictionary.get Items I} remove($)}}
            if I < @width
            then PipeTupleCreateObject, removeSeparators((I + 1))
            end
         end
         meth addSeparators(I Width)
            if I =< Width
            then
               Items = @items
               Node  = {Dictionary.get Items I}
            in
               if {Node isSep($)}
               then skip
               else
                  {Dictionary.put Items I {New Helper.separator create('|' @visual Node)}}
                  PipeTupleCreateObject, addSeparators((I + 1) Width)
               end
            end
         end
      end

      class PipeTupleGrCreateObject from CreateObject InfixModeShare PipeShare
         attr
            depth  %% Current Depth
            items  %% Container Items
            width  %% Current Displayed Width
            entry  %% RelEntry Reference
            mode   %% Mode List (Ref|OB|CB)
            rIndex %% Real Index
         meth gcr(Entry Value Parent Index Visual Depth)
            Width = {Visual getWidth($)}
            Stop  = {Visual getStopVar($)}
         in
            PipeTupleGrCreateObject,create(Entry Value Parent Index 1 Visual Depth Width Stop)
         end
         meth create(Entry Value Parent Index RIndex Visual Depth Width Stop)
            CreateObject, create(Value Parent Index Visual Depth)
            @depth  = (Depth + 1)
            @items  = {Dictionary.new}
            @entry  = Entry {Entry awake(self)}
            @rIndex = RIndex
            {self handleMode({Entry getEqualStr($)} Visual)}
            {self performInsertion(Value 1 RIndex Width Stop)}
         end
         meth performInsertion(Vs I RI Width Stop)
            Visual = @visual
            Depth  = @depth
         in
            if RI > Width orelse {IsDet Stop}
            then PipeShare, finalInsert(I {New Helper.bitmap create(width self I Visual)})
            elsecase Vs
            of V|Vr then
               NewI  = (I + 1)
               NewRI = (RI + 1)
               Node NewNode
            in
               PipeShare, finalInsert(NewI NewNode) %% Order is significant (!)
               Node = {Visual treeCreate(V self I Depth $)}
               {Dictionary.put @items I {New Helper.separator create('|' Visual Node)}}
               NewNode = {Visual listCreate(Vr self NewI NewRI (Depth - 1) Width Stop $)}
            end
         end
         meth isInfix($)
            true
         end
      end
   end

   class LabelTupleCreateObject from LabelContainerCreateObject
      meth createContainer
         Visual = @visual
         Value  = @value
      in
         @maxWidth = {Width Value}
         @type     = labeltuple
         @label    = {New Helper.label create({Label Value} '(' self Visual)}
         @brace    = {New Helper.atom create(')' self 0 Visual internal)}
         ContainerCreateObject, adjustWidth({Visual getWidth($)} 1)
      end
      meth performInsertion(I Value Stop)
         Visual = @visual
         Depth  = @depth
         Width  = @width
      in
         if {IsFree Stop}
         then
            if I =< Width
            then
               {Dictionary.put @items I {Visual treeCreate(Value.I self I Depth $)}}
               LabelTupleCreateObject, performInsertion((I + 1) Value Stop)
            elseif Width < @maxWidth
            then
               width <- I
               {Dictionary.put @items I {New Helper.bitmap create(width self I Visual)}}
            end
         else
            width <- I
            {Dictionary.put @items I {New Helper.bitmap create(width self I Visual)}}
         end
      end
   end

   class LabelTupleGrCreateObject from LabelTupleCreateObject GraphCreate LabelModeShare end

   class RecordCreateObject from LabelContainerCreateObject
      attr
         arity                    %% Record Arity
         auxfeat : Helper.feature %% Aux Separator Class
      meth createContainer
         Visual = @visual
         Value  = @value
      in
         @type     = record
         @maxWidth = {Width Value}
         @arity    = {Record.arity Value}
         @label    = {New Helper.label create({Label Value} '(' self Visual)}
         @brace    = {New Helper.atom create(')' self 0 Visual internal)}
         RecordCreateObject, adjustWidth({Visual getWidth($)} 1)
      end
      meth adjustWidth(CurWidth I)
         NewAs = ContainerCreateObject, seekPos(I @arity $)
         Stop  = {@visual getStopVar($)}
      in
         width <- {Min CurWidth @maxWidth}
         {self performInsertion(I NewAs Stop)}
      end
      meth performInsertion(I As Stop)
         Visual = @visual
         Depth  = @depth
         Width  = @width
      in
         if {IsFree Stop}
         then
            if I =< Width
            then
               case As
               of A|Ar then
                  {Dictionary.put @items I
                   {New @auxfeat create(A Visual {Visual treeCreate((@value).A self I Depth $)})}}
                  RecordCreateObject, performInsertion((I + 1) Ar Stop)
               end
            elseif Width < @maxWidth
            then
               width <- I
               {Dictionary.put @items I {New Helper.bitmap create(width self I Visual)}}
            end
         else
            width <- I
            {Dictionary.put @items I {New Helper.bitmap create(width self I Visual)}}
         end
      end
      meth isLast(Node $)
         {Node getIndex($)} == @width %% Needed for SML-like "Features"
      end
   end

   class RecordIndCreateObject from RecordCreateObject
      attr
         auxfeat : Helper.featureInd
   end

   class RecordGrCreateObject from RecordCreateObject GraphCreate LabelModeShare end
   class RecordGrIndCreateObject from RecordIndCreateObject GraphCreate LabelModeShare end

   class KindedRecordCreateObject from RecordCreateObject
      attr
         monitorValue %% Monitor Value
         hasLabel     %% LabelFlag
      meth createContainer
         Arity    = @arity
         Visual   = @visual
         Value    = @value
         HasLabel = @hasLabel
      in
         @type    = kindedrecord
         HasLabel = {RecordC.hasLabel Value}
         @label   = if HasLabel
                    then {New Helper.label create({Label Value} '(' self Visual)}
                    else {New Helper.label create('_' '(' self Visual)}
                    end
         @brace   = {New Helper.atom create(')' self 0 Visual internal)}
         {RecordC.monitorArity Value _ Arity}
         KindedRecordCreateObject, computeArityLength(Arity 1)
         RecordCreateObject, adjustWidth({Visual getWidth($)} 1)
      end
      meth computeArityLength(As I)
         if {IsFree As}
         then maxWidth <- I
         elsecase As
         of nil then maxWidth <- (I - 1)
         else KindedRecordCreateObject, computeArityLength(As.2 (I + 1))
         end
      end
      meth performInsertion(I As Stop)
         Visual = @visual
         Depth  = @depth
         Width  = @width
      in
         if {IsFree Stop}
         then
            if I =< Width
            then
               if {IsFree As}
               then
                  monitorValue <- As
                  width        <- I
                  {Dictionary.put @items I {New Helper.atom create('...' self I Visual internal)}}
               elsecase As
               of A|Ar then
                  {Dictionary.put @items I
                   {New Helper.feature
                    create(A Visual {Visual treeCreate(@value.A self I Depth $)})}}
                  KindedRecordCreateObject, performInsertion((I + 1) Ar Stop)
               [] nil then
                  monitorValue <- nil
                  width        <- (I - 1)
                  type         <- record
               end
            elseif Width < @maxWidth
            then
               width <- I
               {Dictionary.put @items I {New Helper.bitmap create(width self I Visual)}}
            end
         else
            width <- I
            {Dictionary.put @items I {New Helper.bitmap create(width self I Visual)}}
         end
      end
   end

   class KindedRecordIndCreateObject from KindedRecordCreateObject
      attr
         auxfeat : Helper.featureInd
   end

   class KindedRecordGrCreateObject from KindedRecordCreateObject GraphCreate LabelModeShare end
   class KindedRecordGrIndCreateObject from KindedRecordIndCreateObject GraphCreate LabelModeShare
   end

   class FDIntCreateObject from RecordCreateObject
      meth createContainer
         Arity  = @arity
         Visual = @visual
         Value  = @value
      in
         depth <- (@depth - 1)
         Arity     = {FD.reflect.dom Value}
         @type     = fdint
         @maxWidth = {Length Arity}
         @label    = {New Helper.label create({System.printName Value} '{' self Visual)}
         @brace    = {New Helper.atom create('}' self 0 Visual internal)}
         {Visual logVar(self Value false)}
         RecordCreateObject, adjustWidth({Visual getWidth($)} 1)
      end
      meth performInsertion(I As Stop)
         Visual = @visual
         Depth  = @depth
         Width  = @width
      in
         if {IsFree Stop}
         then
            if I =< @width
            then
               case As
               of A|Ar then
                  {Dictionary.put @items I {Visual coreCreate(A self I Depth $)}}
                  FDIntCreateObject, performInsertion((I + 1) Ar Stop)
               end
            elseif Width < @maxWidth
            then
               width <- I
               {Dictionary.put @items I {New Helper.bitmap create(width self I Visual)}}
            elseif Width == 0
            then
               width <- 1
               {Dictionary.put @items 1 {New Helper.empty create(self)}}
            end
         else
            width <- I
            {Dictionary.put @items I {New Helper.bitmap create(width self I Visual)}}
         end
      end
   end

   class FDIntGrCreateObject from FDIntCreateObject GraphCreate LabelModeShare end

   class FSValCreateObject from FDIntCreateObject
      meth createContainer
         Arity  = @arity
         Visual = @visual
         Value  = @value
      in
         depth <- (@depth - 1)
         Arity     = {FS.reflect.lowerBound Value}
         @type     = fsval
         @maxWidth = {Length Arity}
         @label    = {New Helper.atom create('{' self 0 Visual internal)}
         @brace    = {New Helper.atom create('}'#"#"#{FS.reflect.card Value} self 0 Visual internal)}
         {Visual logVar(self Value false)}
         RecordCreateObject, adjustWidth({Visual getWidth($)} 1)
      end
   end

   class FSValGrCreateObject from FSValCreateObject GraphCreate LabelModeShare end

   class FSHelperCreateObject from FDIntCreateObject
      meth createContainer
         Visual = @visual
         Arity  = @arity
      in
         depth <- (@depth - 1)
         Arity     = @value
         @type     = fshelp
         @maxWidth = {Length Arity}
         @label    = {New Helper.atom create('{' self 0 Visual internal)}
         @brace    = {New Helper.atom create('}' self 0 Visual internal)}
         RecordCreateObject, adjustWidth({Visual getWidth($)} 1)
      end
   end

   class FSVarCreateObject from LabelContainerCreateObject
      meth createContainer
         Visual  = @visual
         Value   = @value
         Ls      = {FS.reflect.lowerBound Value}
         Us      = {FS.reflect.upperBound Value}
         Cs      = {FS.reflect.card Value}
         HVArC   = {Visual getFSVHelperNode($)}
         Depth   = (@depth - 1)
         Items   = @items
         CardVal = case Cs of L#H then '}'#"#"#'{'#L#"#"#H#'}' [] C then '}'#"#"#'{'#C#'}' end
      in
         depth <- Depth
         @type     = fsvar
         @maxWidth = 3
         @label    = {New Helper.label create({System.printName Value} '{' self Visual)}
         @brace    = {New Helper.atom create(CardVal self 0 Visual internal)}
         width <- 3
         {Dictionary.put Items 1 {New HVArC create(Ls self 1 Visual Depth)}}
         {Dictionary.put Items 2 {New Helper.atom create('..' self 0 Visual internal)}}
         {Dictionary.put Items 3 {New HVArC create(Us self 3 Visual Depth)}}
         {@visual logVar(self Value false)}
      end
   end

   class FSVarGrCreateObject from FSVarCreateObject GraphCreate LabelModeShare end
end
