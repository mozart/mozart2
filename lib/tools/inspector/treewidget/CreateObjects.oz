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
   FD(reflect)
   FS(reflect)
   RecordC(hasLabel monitorArity)
   System(printName show)
   Helper
export
   createObject                  : CreateObject
   intCreateObject               : IntCreateObject
   floatCreateObject             : FloatCreateObject
   atomCreateObject              : AtomCreateObject
   nameCreateObject              : NameCreateObject
   procedureCreateObject         : ProcedureCreateObject
   recordCreateObject            : RecordCreateObject
   recordIndCreateObject         : RecordIndCreateObject
   recordGrCreateObject          : RecordGrCreateObject
   recordGrIndCreateObject       : RecordGrIndCreateObject
   kindedRecordCreateObject      : KindedRecordCreateObject
   kindedRecordIndCreateObject   : KindedRecordIndCreateObject
   kindedRecordGrCreateObject    : KindedRecordGrCreateObject
   kindedRecordGrIndCreateObject : KindedRecordGrIndCreateObject
   hashTupleCreateObject         : HashTupleCreateObject
   hashTupleGrCreateObject       : HashTupleGrCreateObject
   pipeTupleCreateObject         : PipeTupleCreateObject
   pipeTupleGrCreateObject       : PipeTupleGrCreateObject
   labelTupleCreateObject        : LabelTupleCreateObject
   labelTupleGrCreateObject      : LabelTupleGrCreateObject
   futureCreateObject            : FutureCreateObject
   futureGrCreateObject          : FutureGrCreateObject
   byteStringCreateObject        : ByteStringCreateObject
   freeCreateObject              : FreeCreateObject
   freeGrCreateObject            : FreeGrCreateObject
   fDIntCreateObject             : FDIntCreateObject
   fDIntGrCreateObject           : FDIntGrCreateObject
   fSValCreateObject             : FSValCreateObject
   fSValGrCreateObject           : FSValGrCreateObject
   fSHelperCreateObject          : FSHelperCreateObject
   fSVarCreateObject             : FSVarCreateObject
   fSVarGrCreateObject           : FSVarGrCreateObject
   genericCreateObject           : GenericCreateObject
   atomRefCreateObject           : AtomRefCreateObject
   tupleSMLCreateObject          : TupleSMLCreateObject
   vectorSMLCreateObject         : VectorSMLCreateObject
   listSMLCreateObject           : ListSMLCreateObject
   recordSMLCreateObject         : RecordSMLCreateObject
   recordSMLIndCreateObject      : RecordSMLIndCreateObject
   cellSMLCreateObject           : CellSMLCreateObject
   wordSMLCreateObject           : WordSMLCreateObject
define
   class CreateObject
      attr
         value  %% Store Reference
         type   %% Node Type
         parent %% Parent Object
         index  %% Parent Entry Index
         visual %% Visual Reference
         tag    %% Objects own Tag
      meth create(Value Parent Index Visual Depth)
         @value  = Value
         @parent = Parent
         @index  = Index
         @visual = Visual
         @tag    = {Visual newTag($)}
      end
      meth getType($)
         @type
      end
      meth getParent($)
         @parent
      end
      meth getIndex($)
         @index
      end
      meth getSimpleRootIndex(I $)
         {@parent getSimpleRootIndex(@index $)}
      end
      meth collectTags(I Ts $)
         {@parent collectTags(@index @tag|Ts $)}
      end
      meth getValue($)
         @value
      end
      meth mustChange($)
         false
      end
      meth getInnerNode($)
         self
      end
      meth isSep($)
         false
      end
      meth isProxy($)
         false
      end
      meth isRef($)
         false
      end
      meth isInfix($)
         false
      end
      meth addSeps(I)
         skip
      end
   end

   \insert 'create/SimpleCreateObjects.oz'
   \insert 'create/ContCreateObjects.oz'
end
