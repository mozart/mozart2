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

functor $
import
   CreateObjects(recordCreateObject kindedRecordCreateObject)
   System(eq show)
   Tk(send)
   Aux
export
   drawObject               : DrawObject
   recordDrawObject         : RecordDrawObject
   recordGrDrawObject       : RecordGrDrawObject
   kindedRecordDrawObject   : KindedRecordDrawObject
   kindedRecordGrDrawObject : KindedRecordGrDrawObject
   hashTupleDrawObject      : HashTupleDrawObject
   hashTupleGrDrawObject    : HashTupleGrDrawObject
   pipeTupleDrawObject      : PipeTupleDrawObject
   pipeTupleGrSDrawObject   : PipeTupleGrSDrawObject
   pipeTupleGrMDrawObject   : PipeTupleGrMDrawObject
   labelTupleDrawObject     : LabelTupleDrawObject
   labelTupleGrDrawObject   : LabelTupleGrDrawObject
   futureDrawObject         : FutureDrawObject
   futureGrDrawObject       : FutureGrDrawObject
   freeDrawObject           : FreeDrawObject
   freeGrDrawObject         : FreeGrDrawObject
   fDIntDrawObject          : FDIntDrawObject
   fDIntGrDrawObject        : FDIntGrDrawObject
   atomRefDrawObject        : AtomRefDrawObject
define
   RecordCreateObject       = CreateObjects.recordCreateObject
   KindedRecordCreateObject = CreateObjects.kindedRecordCreateObject

   class DrawObject
      attr
         dirty : true %% Draw Flag
      meth getRootIndex(I $) %% Relocated from CreateObject to DrawObject due to class conflict
         xDim <- _
         {@parent getRootIndex(@index $)} %% Combines notify and getSimpleRootIndex
      end
      meth draw(X Y)
         if @dirty
         then dirty <- false {@visual printXY(X Y @string @tag @type)}
         else {@visual place(X Y @tag)}
         end
      end
      meth drawX(X Y $)
         DrawObject, draw(X Y) (X + @xDim)
      end
      meth drawY(X Y $)
         DrawObject, draw(X Y) (Y + 1)
      end
      meth getFirstItem($)
         @tag
      end
      meth eliminateFresh(I)
         skip
      end
      meth isFresh($)
         false
      end
      meth undraw
         if @dirty then skip else dirty <- true {@visual delete(@tag)} end
      end
      meth searchNode(XA YA X Y $)
         if X >= XA andthen X < (XA + @xDim) andthen YA == Y then self else nil end
      end
      meth getMenuType($)
         @type|self
      end
      meth isMapped(Index $)
         {@parent isMapped(@index $)}
      end
      meth seekEnd($)
         @parent
      end
      meth downNotify
         skip
      end
      meth makeDirty
         dirty <- true
      end
      meth map(Index F)
         Val      = @value
         NewValue = try {F Val}
                    catch X then
                       mapping_failed(ex:{Value.byNeed fun {$} X end} val:Val)
                    end
      in
         {@parent link(@index NewValue)}
      end
      meth unmap
         {@parent unlink(@index)}
      end
      meth action(Index P)
         try {P @value} catch _ then skip end
      end
   end

   \insert 'draw/SimpleDrawObjects.oz'
   \insert 'draw/ContDrawObjects.oz'
end
