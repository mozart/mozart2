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
   System(show printName)
   Aux
export
   layoutObject               : LayoutObject
   intLayoutObject            : IntLayoutObject
   floatLayoutObject          : FloatLayoutObject
   atomLayoutObject           : AtomLayoutObject
   nameLayoutObject           : NameLayoutObject
   procedureLayoutObject      : ProcedureLayoutObject
   recordLayoutObject         : RecordLayoutObject
   recordGrLayoutObject       : RecordGrLayoutObject
   hashTupleLayoutObject      : HashTupleLayoutObject
   hashTupleGrLayoutObject    : HashTupleGrLayoutObject
   pipeTupleLayoutObject      : PipeTupleLayoutObject
   pipeTupleGrLayoutObject    : PipeTupleGrLayoutObject
   labelTupleLayoutObject     : LabelTupleLayoutObject
   labelTupleGrLayoutObject   : LabelTupleGrLayoutObject
   futureLayoutObject         : FutureLayoutObject
   futureGrLayoutObject       : FutureGrLayoutObject
   byteStringLayoutObject     : ByteStringLayoutObject
   freeLayoutObject           : FreeLayoutObject
   freeGrLayoutObject         : FreeGrLayoutObject
   fDIntLayoutObject          : FDIntLayoutObject
   fDIntGrLayoutObject        : FDIntGrLayoutObject
   fSVarLayoutObject          : FSVarLayoutObject
   fSVarGrLayoutObject        : FSVarGrLayoutObject
   genericLayoutObject        : GenericLayoutObject
   atomRefLayoutObject        : AtomRefLayoutObject
define
   class LayoutObject
      attr
         xDim %% X Dimension in Characters
      meth getXDim($)
         @xDim
      end
      meth getYDim($)
         1
      end
      meth getXYDim($)
         @xDim|1
      end
      meth getLastXDim($)
         @xDim
      end
      meth notEmbraced($)
         true
      end
      meth isVert($)
         false
      end
   end

   \insert 'layout/SimpleLayoutObjects.oz'
   \insert 'layout/ContLayoutObjects.oz'
end
