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
   fun {FCreate Value Visual Depth}
      case {IsAtom Value}
      then {New TreeNodes.atomTreeNode create(Value Visual Depth)}
      else {New TreeNodes.intTreeNode  create(Value Visual Depth)}
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


      meth create(Value Visual Depth)
         RecLabel  = {Label Value}
         Arity     = @arity
         RDepth    = (Depth + 1)
         LabelNode = {FCreate RecLabel Visual RDepth}
         CurWidth  = @curWidth
      in
         CreateObject, create(Value Visual RDepth)
         @type       = record
         @label      = LabelNode
         {LabelNode initMenu(@type)}
         @items      = {Dictionary.new}
         Arity       = {Record.arity Value}
         @arityLen   = {Width Value}
         @brace      = {New InternalAtomNode create(')' Visual Depth)}
         CurWidth    = {Visual getWidth($)}
         @curDepth   = {Visual getDepth($)}
         {LabelNode setLayoutType(tuple)}
         {LabelNode setParentData(self 0)}
         {LabelNode setRescueValue(Value)}
         RecordCreateObject, adjustWidth(CurWidth 1)
      end

      meth adjustWidth(CurWidth I)
         ArityLen = @arityLen
         NewAs
      in
         case CurWidth < ArityLen
         then
            Visual   = @visual
            Depth    = @depth
            Bitmap   = {New BitmapTreeNode create(width Visual Depth)}
            NullObj  = {New NullNode create(nil Visual Depth)}
            NewWidth = (CurWidth + 1)
         in
            {Bitmap setParentData(self NewWidth)}
            {Dictionary.put @items NewWidth NullObj|Bitmap}
            width <- CurWidth
            NewAs = RecordCreateObject, seekStartPos(I @arity $)
            RecordCreateObject, performInsertion(I NewAs)
            width <- NewWidth
         else
            width <- ArityLen
            NewAs = RecordCreateObject, seekStartPos(I @arity $)
            RecordCreateObject, performInsertion(I NewAs)
         end
         {@label setParentData(self @width)}
      end

      meth seekStartPos(I As $)
         case I
         of 1 then As
         else RecordCreateObject, seekStartPos((I - 1) As.2 $)
         end
      end

      meth performInsertion(I As)
         case I =< @width
         then
            A|Ar   = As
            Visual = @visual
            Depth  = @depth
            Label  = {FCreate A Visual Depth}
            Node   = {Create @value.A Visual Depth}
         in
            {Label setLayoutType(record)}
            {Node setParentData(self I)}
            {Dictionary.put @items I Label|Node}
            RecordCreateObject, performInsertion((I + 1) Ar)
         else skip
         end
      end
   end

   %% KindedRecordCreateObject

   class KindedRecordCreateObject
      from
         RecordCreateObject

      attr
         maxWidth     %% Current Max Width
         monitorValue %% Monitor Value

      meth create(Value Visual Depth)
         Label    = {FCreate '_' Visual Depth}
         Arity    = @arity
         CurWidth = @curWidth
      in
         CreateObject, create(Value Visual (Depth + 1))
         @type     = kindedRecord
         @label    = Label
         {Label initMenu(@type)}
         @items    = {Dictionary.new}
         @brace    = {New InternalAtomNode create(')' Visual Depth)}
         CurWidth  = {Visual getWidth($)}
         @curDepth = {Visual getDepth($)}
         {Record.monitorArity Value _ Arity}
         {Label setLayoutType(tuple)}
         {Label setParentData(self 0)}
         {Label setRescueValue(Value)}
         KindedRecordCreateObject, adjustWidth(CurWidth 1)
      end

      meth adjustWidth(CurWidth I)
         NewArity = KindedRecordCreateObject, seekStartPos(I @arity $)
      in
         maxWidth <- CurWidth
         KindedRecordCreateObject, performInsertion(I NewArity)
      end

      meth seekStartPos(I As $)
         case I
         of 1 then As
         else KindedRecordCreateObject, seekStartPos((I - 1) As.2 $)
         end
      end

      meth performInsertion(I As)
         case I =< @maxWidth
         then
            case {IsFree As}
            then
               Visual = @visual
               Depth  = @depth
               Label  = {New NullNode create(nil Visual Depth)}
               Node   = {New InternalAtomNode create('...' Visual Depth)}
            in
               monitorValue <- As
               width        <- I
               {Node setParentData(self I)}
               {Dictionary.put @items I Label|Node}
            else
               case As
               of A|Ar then
                  Visual = @visual
                  Depth  = @depth
                  Label  = {FCreate A Visual Depth}
                  Node   = {Create @value.A Visual Depth}
               in
                  {Label setLayoutType(record)}
                  {Node setParentData(self I)}
                  {Dictionary.put @items I Label|Node}
                  KindedRecordCreateObject, performInsertion((I + 1) Ar)
               [] nil then
                  width <- (I - 1)
               end
            end
         else
            Visual = @visual
            Depth  = @depth
            Label  = {New NullNode create(nil Visual Depth)}
            Bitmap = {New BitmapTreeNode create(width Visual Depth)}
         in
            {Bitmap setParentData(self I)}
            {Dictionary.put @items I Label|Bitmap}
            width <- I
         end
         {@label setParentData(self @width)}
      end
   end

   %% RecordCycleCreateObject

   class RecordCycleCreateObject
      from
         RecordCreateObject

      attr
         cycleMan  %% Record Cycle Manager
         cycleNode %% Record Cycle Node


      meth create(Value Visual CycleMan Depth)
         RecLabel  = {Label Value}
         Arity     = @arity
         LabelNode = {FCreate RecLabel Visual Depth}
         CurWidth  = @curWidth
      in
         CreateObject, create(Value Visual (Depth + 1))
         @type      = record
         @label     = LabelNode
         {LabelNode initMenu(@type)}
         @items     = {Dictionary.new}
         Arity      = {Record.arity Value}
         @arityLen  = {Width Value}
         @brace     = {New InternalAtomNode create(')' Visual Depth)}
         @cycleMan  = CycleMan
         @cycleNode = {New InternalAtomNode
                       create({CycleMan register(Value self $)}#'='
                              Visual Depth)}
         CurWidth   = {Visual getWidth($)}
         @curDepth  = {Visual getDepth($)}
         {LabelNode setLayoutType(tuple)}
         {LabelNode setParentData(self 0)}
         {LabelNode setRescueValue(Value)}
         RecordCycleCreateObject, adjustWidth(CurWidth 1)
      end

      meth adjustWidth(CurWidth I)
         ArityLen = @arityLen
         NewAs
      in
         case CurWidth < ArityLen
         then
            Visual   = @visual
            Depth    = @depth
            Bitmap   = {New BitmapTreeNode create(width Visual Depth)}
            NullObj  = {New NullNode create(nil Visual Depth)}
            NewWidth = (CurWidth + 1)
         in
            {Bitmap setParentData(self I)}
            {Dictionary.put @items NewWidth NullObj|Bitmap}
            width <- CurWidth
            NewAs = RecordCreateObject, seekStartPos(I @arity $)
            RecordCycleCreateObject, performInsertion(I NewAs)
            width <- NewWidth
         else
            width <- ArityLen
            NewAs = RecordCreateObject, seekStartPos(I @arity $)
            RecordCycleCreateObject, performInsertion(I NewAs)
         end
         {@label setParentData(self @width)}
      end

      meth performInsertion(I As)
         case I =< @width
         then
            A|Ar     = As
            Visual   = @visual
            Depth    = @depth
            Label    = {FCreate A Visual Depth}
            CycleMan = @cycleMan
            Node
         in
            {CycleMan push}
            Node = {CycleCreate @value.A Visual CycleMan Depth}
            {CycleMan pop}
            {CycleMan getStack(Node)}
            {Label setLayoutType(record)}
            {Node setParentData(self I)}
            {Dictionary.put @items I Label|Node}
            RecordCycleCreateObject, performInsertion((I + 1) Ar)
         else skip
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

      meth create(Value Visual CycleMan Depth)
         Label    = {FCreate '_' Visual Depth}
         Arity    = @arity
         CurWidth = @curWidth
      in
         CreateObject, create(Value Visual (Depth + 1))
         @type      = kindedRecord
         @label     = Label
         {Label initMenu(@type)}
         @items     = {Dictionary.new}
         @brace     = {New InternalAtomNode create(')' Visual Depth)}
         @cycleMan  = CycleMan
         @cycleNode = {New InternalAtomNode
                       create({CycleMan register(Value self $)}#'='
                              Visual Depth)}
         CurWidth   = {Visual getWidth($)}
         @curDepth  = {Visual getDepth($)}
         {Record.monitorArity Value _ Arity}
         {Label setLayoutType(tuple)}
         {Label setParentData(self 0)}
         {Label setRescueValue(Value)}
         KindedRecordCycleCreateObject, adjustWidth(CurWidth 1)
      end

      meth adjustWidth(CurWidth I)
         NewArity = KindedRecordCreateObject, seekStartPos(I @arity $)
      in
         maxWidth <- CurWidth
         KindedRecordCycleCreateObject, performInsertion(I NewArity)
      end

      meth performInsertion(I As)
         case I =< @maxWidth
         then
            case {IsFree As}
            then
               Visual = @visual
               Depth  = @depth
               Label  = {New NullNode create(nil Visual Depth)}
               Node   = {New InternalAtomNode create('...' Visual Depth)}
            in
               {@cycleMan getStack(Node)}
               monitorValue <- As
               width        <- I
               {Node setParentData(self I)}
               {Dictionary.put @items I Label|Node}
            else
               case As
               of A|Ar then
                  Visual   = @visual
                  Depth    = @depth
                  Label    = {FCreate A Visual Depth}
                  CycleMan = @cycleMan
                  Node
               in
                  {CycleMan push}
                  Node = {CycleCreate @value.A Visual CycleMan Depth}
                  {CycleMan pop}
                  {CycleMan getStack(Node)}
                  {Label setLayoutType(record)}
                  {Node setParentData(self I)}
                  {Dictionary.put @items I Label|Node}
                  KindedRecordCycleCreateObject, performInsertion((I + 1) Ar)
               [] nil then
                  width <- (I - 1)
               end
            end
         else
            Visual = @visual
            Depth  = @depth
            Label  = {New NullNode create(nil Visual Depth)}
            Bitmap = {New BitmapTreeNode create(width Visual Depth)}
         in
            {Bitmap setParentData(self I)}
            {@cycleMan getStack(Bitmap)}
            {Dictionary.put @items I Label|Bitmap}
            width <- I
         end
         {@label setParentData(self @width)}
      end
   end
end
