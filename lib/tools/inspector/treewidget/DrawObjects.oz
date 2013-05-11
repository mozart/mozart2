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

functor $
import
   CreateObjects(recordCreateObject kindedRecordCreateObject)
   RecordC(hasLabel)
   System(eq show)
   Tk(send)
   HelperComponent('nodes' : Helper) at 'Helper.ozf'
export
   drawObject                  : DrawObject
   genericDrawObject           : GenericDrawObject
   recordDrawObject            : RecordDrawObject
   recordIndDrawObject         : RecordIndDrawObject
   recordGrDrawObject          : RecordGrDrawObject
   recordGrIndDrawObject       : RecordGrIndDrawObject
   kindedRecordDrawObject      : KindedRecordDrawObject
   kindedRecordIndDrawObject   : KindedRecordIndDrawObject
   kindedRecordGrDrawObject    : KindedRecordGrDrawObject
   kindedRecordGrIndDrawObject : KindedRecordGrIndDrawObject
   hashTupleDrawObject         : HashTupleDrawObject
   hashTupleGrDrawObject       : HashTupleGrDrawObject
   pipeTupleDrawObject         : PipeTupleDrawObject
   pipeTupleGrSDrawObject      : PipeTupleGrSDrawObject
   pipeTupleGrMDrawObject      : PipeTupleGrMDrawObject
   labelTupleDrawObject        : LabelTupleDrawObject
   labelTupleIndDrawObject     : LabelTupleIndDrawObject
   labelTupleGrDrawObject      : LabelTupleGrDrawObject
   labelTupleGrIndDrawObject   : LabelTupleGrIndDrawObject
   futureDrawObject            : FutureDrawObject
   futureGrDrawObject          : FutureGrDrawObject
   freeDrawObject              : FreeDrawObject
   freeGrDrawObject            : FreeGrDrawObject
   failedDrawObject            : FailedDrawObject
   fdIntDrawObject             : FDIntDrawObject
   fdIntGrDrawObject           : FDIntGrDrawObject
   variableRefDrawObject       : VariableRefDrawObject
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
      meth getTag($)
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
      meth isDirty($)
         @dirty
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
         Visual   = @visual
         NewValue = try {F Val {Visual getWidth($)} {Visual getDepth($)}}
                    catch X then
                       mapping_failed(ex:{Value.byNeedFuture fun {$} X end}
                                      val:Val)
                    end
      in
         {@parent link(@index NewValue)}
      end
      meth unmap
         {@parent unlink(@index)}
      end
      meth action(Index P)
         if {IsTuple P}
         then {self P}
         else thread {P @value} end
         end
      end
      meth getSelectionNode($)
         self
      end
      meth modifyDepth(Index N)
         {@parent up((N + 1) Index)}
      end
      meth modifyWidth(Index N)
         skip
      end
      meth reinspect
         {@parent notify}
         {@parent replace(@index @value replaceNormal)}
      end
   end

   \insert 'draw/SimpleDrawObjects.oz'
   \insert 'draw/ContDrawObjects.oz'
end
