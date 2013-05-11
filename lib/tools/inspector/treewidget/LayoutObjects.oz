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
   System(show printName)
   Word(toInt) at 'x-oz://boot/Word.ozf'
   HelperComponent('nodes' : Helper) at 'Helper.ozf'
export
   layoutObject                : LayoutObject
   intLayoutObject             : IntLayoutObject
   floatLayoutObject           : FloatLayoutObject
   atomLayoutObject            : AtomLayoutObject
   nameLayoutObject            : NameLayoutObject
   procedureLayoutObject       : ProcedureLayoutObject
   recordLayoutObject          : RecordLayoutObject
   recordIndLayoutObject       : RecordIndLayoutObject
   recordGrLayoutObject        : RecordGrLayoutObject
   recordGrIndLayoutObject     : RecordGrIndLayoutObject
   hashTupleLayoutObject       : HashTupleLayoutObject
   hashTupleGrLayoutObject     : HashTupleGrLayoutObject
   pipeTupleLayoutObject       : PipeTupleLayoutObject
   pipeTupleGrLayoutObject     : PipeTupleGrLayoutObject
   labelTupleLayoutObject      : LabelTupleLayoutObject
   labelTupleIndLayoutObject   : LabelTupleIndLayoutObject
   labelTupleGrLayoutObject    : LabelTupleGrLayoutObject
   labelTupleGrIndLayoutObject : LabelTupleGrIndLayoutObject
   futureLayoutObject          : FutureLayoutObject
   futureGrLayoutObject        : FutureGrLayoutObject
   failedLayoutObject          : FailedLayoutObject
   stringLayoutObject          : StringLayoutObject
   byteStringLayoutObject      : ByteStringLayoutObject
   freeLayoutObject            : FreeLayoutObject
   freeGrLayoutObject          : FreeGrLayoutObject
   fdIntLayoutObject           : FDIntLayoutObject
   fdIntGrLayoutObject         : FDIntGrLayoutObject
   fsVarLayoutObject           : FSVarLayoutObject
   fsVarGrLayoutObject         : FSVarGrLayoutObject
   genericLayoutObject         : GenericLayoutObject
   variableRefLayoutObject     : VariableRefLayoutObject
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
