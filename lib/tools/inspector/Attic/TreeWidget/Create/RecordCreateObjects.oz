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
%%% RecordCreateObjects
%%%

local
   fun {FCreate Value Parent Index Visual Depth}
      if {IsAtom Value}
      then {New TreeNodes.atomTreeNode create(Value Parent Index Visual Depth)}
      elseif {IsName Value}
      then {New TreeNodes.nameTreeNode create(Value Parent Index Visual Depth)}
      else {New TreeNodes.intTreeNode  create(Value Parent Index Visual Depth)}
      end
   end
in

   %% RecordCreateObject

   class RecordCreateObject
      from
         CreateObject

      attr
         label    %% Record Label
         items    %% Record Core Container
         width    %% Record Width
         arity    %% Record Arity
         arityLen %% Record Arity Length
         brace    %% Closing Brace
         curWidth %% Current Width
         curDepth %% Current Depth

      meth create(Value Parent Index Visual Depth)
         RecLabel  = {Label Value}
         Arity     = @arity
         RDepth    = (Depth + 1)
         LabelNode = {FCreate RecLabel self 0 Visual RDepth}
         CurWidth  = @curWidth
      in
         CreateObject, create(Value Parent Index Visual RDepth)
         @type       = record
         @label      = LabelNode
         {LabelNode initMenu(@type)}
         @items      = {Dictionary.new}
         Arity       = {Record.arity Value}
         @arityLen   = {Width Value}
         @brace      = {New InternalAtomNode create(')' self 0 Visual Depth)}
         CurWidth    = {Visual getWidth($)}
         @curDepth   = {Visual getDepth($)}
         {LabelNode setLayoutType(tuple)}
         {LabelNode setRescueValue(Value)}
         RecordCreateObject, adjustWidth(CurWidth 1)
      end

      meth adjustWidth(CurWidth I)
         NewAs     = RecordCreateObject, seekStartPos(I @arity $)
         StopValue = {@visual getStop($)}
      in
         width <- {Min CurWidth @arityLen}
         {self performInsertion(I NewAs StopValue)}
      end

      meth seekStartPos(I As $)
         case I
         of 1 then As
         else RecordCreateObject, seekStartPos((I - 1) As.2 $)
         end
      end

      meth performInsertion(I As StopValue)
         Width = @width
      in
         if {IsFree StopValue}
         then
            if I =< Width
            then
               A|Ar   = As
               Visual = @visual
               Depth  = @depth
               Label  = {FCreate A self I Visual Depth}
               Node   = {Create @value.A self I Visual Depth}
            in
               {Label setLayoutType(record)}
               {Dictionary.put @items I Label|Node}
               RecordCreateObject, performInsertion((I + 1) Ar StopValue)
            elseif Width < @arityLen
            then
               Visual  = @visual
               Depth   = @depth
               Bitmap  = {New BitmapTreeNode create(width self I Visual Depth)}
               NullObj = {New NullNode create(nil self I Visual Depth)}
            in
               {Dictionary.put @items I NullObj|Bitmap}
               width <- I
            else skip
            end
         else
            {self stopCreation}
         end
      end

      meth ignoreStop($)
         false
      end
   end

   %% KindedRecordCreateObject

   class KindedRecordCreateObject
      from
         RecordCreateObject

      attr
         monitorValue %% Monitor Value

      meth create(Value Parent Index Visual Depth)
         Label    = {FCreate '_' self 0 Visual Depth}
         Arity    = @arity
         CurWidth = @curWidth
      in
         CreateObject, create(Value Parent Index Visual (Depth + 1))
         @type     = kindedRecord
         @label    = Label
         {Label initMenu(@type)}
         @items    = {Dictionary.new}
         @brace    = {New InternalAtomNode create(')' self 0 Visual Depth)}
         CurWidth  = {Visual getWidth($)}
         @curDepth = {Visual getDepth($)}
         {Record.monitorArity Value _ Arity}
         {Label setLayoutType(tuple)}
         {Label setRescueValue(Value)}
         KindedRecordCreateObject, computeArityLen(Arity 1)
         RecordCreateObject, adjustWidth(CurWidth 1)
      end

      meth computeArityLen(As I)
         if {IsFree As}
         then arityLen <- I
         elsecase As
         of nil then arityLen <- (I - 1)
         else KindedRecordCreateObject, computeArityLen(As.2 (I + 1))
         end
      end

      meth performInsertion(I As StopValue)
         Width = @width
      in
         if {IsFree StopValue}
         then
            if I =< Width
            then
               if {IsFree As}
               then
                  Visual = @visual
                  Depth  = @depth
                  Label  = {New NullNode create(nil self I Visual Depth)}
                  Node   = {New InternalAtomNode
                            create('...' self I Visual Depth)}
               in
                  monitorValue <- As
                  width        <- I
                  {Dictionary.put @items I Label|Node}
               elsecase As
               of A|Ar then
                  Visual = @visual
                  Depth  = @depth
                  Label  = {FCreate A self I Visual Depth}
                  Node   = {Create @value.A self I Visual Depth}
               in
                  {Label setLayoutType(record)}
                  {Dictionary.put @items I Label|Node}
                  KindedRecordCreateObject,
                  performInsertion((I + 1) Ar StopValue)
               [] nil then
                  width <- (I - 1)
               end
            elseif Width < @arityLen
            then
               Visual = @visual
               Depth  = @depth
               Label  = {New NullNode create(nil self I Visual Depth)}
               Bitmap = {New BitmapTreeNode create(width self I Visual Depth)}
            in
               {Dictionary.put @items I Label|Bitmap}
               width <- I
            else skip
            end
         else
            {self stopCreation}
         end
      end
   end

   %% RecordCycleCreateObject

   class RecordCycleCreateObject
      from
         RecordCreateObject

      attr
         cycleMan  %% Record Cycle Manager
         cycleNode %% Record Cycle Node


      meth create(Value Parent Index Visual CycleMan Depth)
         RecLabel  = {Label Value}
         Arity     = @arity
         LabelNode = {FCreate RecLabel self 0 Visual Depth}
         CurWidth  = @curWidth
      in
         CreateObject, create(Value Parent Index Visual (Depth + 1))
         @type      = record
         @label     = LabelNode
         {LabelNode initMenu(@type)}
         @items     = {Dictionary.new}
         Arity      = {Record.arity Value}
         @arityLen  = {Width Value}
         @brace     = {New InternalAtomNode create(')' self 0 Visual Depth)}
         @cycleMan  = CycleMan
         @cycleNode = {New InternalAtomNode
                       create({CycleMan register(Value self $)}#'='
                              self 0 Visual Depth)}
         CurWidth   = {Visual getWidth($)}
         @curDepth  = {Visual getDepth($)}
         {LabelNode setLayoutType(tuple)}
         {LabelNode setRescueValue(Value)}
         RecordCreateObject, adjustWidth(CurWidth 1)
      end

      meth performInsertion(I As StopValue)
         Width = @width
      in
         if {IsFree StopValue}
         then
            if I =< Width
            then
               A|Ar     = As
               Visual   = @visual
               Depth    = @depth
               Label    = {FCreate A self I Visual Depth}
               CycleMan = @cycleMan
               Node
            in
               {CycleMan push}
               Node = {CycleCreate @value.A self I Visual CycleMan Depth}
               {CycleMan pop}
               {CycleMan getStack(Node)}
               {Label setLayoutType(record)}
               {Dictionary.put @items I Label|Node}
               RecordCycleCreateObject,
               performInsertion((I + 1) Ar StopValue)
            elseif Width < @arityLen
            then
               Visual  = @visual
               Depth   = @depth
               Bitmap  = {New BitmapTreeNode create(width self I Visual Depth)}
               NullObj = {New NullNode create(nil self I Visual Depth)}
            in
               {Dictionary.put @items I NullObj|Bitmap}
               width <- I
            else skip
            end
         else
            {self stopCreation}
         end
      end
   end

   %% KindedRecordCycleCreateObject

   class KindedRecordCycleCreateObject
      from
         KindedRecordCreateObject

      attr
         cycleMan  %% Record Cycle Manager
         cycleNode %% Record Cycle Node

      meth create(Value Parent Index Visual CycleMan Depth)
         Label    = {FCreate '_' self 0 Visual Depth}
         Arity    = @arity
         CurWidth = @curWidth
      in
         CreateObject, create(Value Parent Index Visual (Depth + 1))
         @type      = kindedRecord
         @label     = Label
         {Label initMenu(@type)}
         @items     = {Dictionary.new}
         @brace     = {New InternalAtomNode create(')' self 0 Visual Depth)}
         @cycleMan  = CycleMan
         @cycleNode = {New InternalAtomNode
                       create({CycleMan register(Value self $)}#'='
                              self 0 Visual Depth)}
         CurWidth   = {Visual getWidth($)}
         @curDepth  = {Visual getDepth($)}
         {Record.monitorArity Value _ Arity}
         {Label setLayoutType(tuple)}
         {Label setRescueValue(Value)}
         KindedRecordCreateObject, computeArityLen(Arity 1)
         RecordCreateObject, adjustWidth(CurWidth 1)
      end

      meth performInsertion(I As StopValue)
         Width = @width
      in
         if {IsFree StopValue}
         then
            if I =< Width
            then
               if {IsFree As}
               then
                  Visual = @visual
                  Depth  = @depth
                  Label  = {New NullNode create(nil self I Visual Depth)}
                  Node   = {New InternalAtomNode
                            create('...' self I Visual Depth)}
               in
                  {@cycleMan getStack(Node)}
                  monitorValue <- As
                  width        <- I
                  {Dictionary.put @items I Label|Node}
               elsecase As
               of A|Ar then
                  Visual   = @visual
                  Depth    = @depth
                  Label    = {FCreate A self I Visual Depth}
                  CycleMan = @cycleMan
                  Node
               in
                  {CycleMan push}
                  Node = {CycleCreate @value.A self I Visual CycleMan Depth}
                  {CycleMan pop}
                  {CycleMan getStack(Node)}
                  {Label setLayoutType(record)}
                  {Dictionary.put @items I Label|Node}
                  KindedRecordCycleCreateObject,
                  performInsertion((I + 1) Ar StopValue)
               [] nil then
                  width <- (I - 1)
               end
            elseif Width < @arityLen
            then
               Visual = @visual
               Depth  = @depth
               Label  = {New NullNode create(nil self I Visual Depth)}
               Bitmap = {New BitmapTreeNode create(width self I Visual Depth)}
            in
               {@cycleMan getStack(Bitmap)}
               {Dictionary.put @items I Label|Bitmap}
               width <- I
            end
         else
            {self stopCreation}
         end
      end
   end
end
