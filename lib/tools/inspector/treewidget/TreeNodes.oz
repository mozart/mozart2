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
   CreateObjects
   LayoutObjects
   DrawObjects
export
   int               : Int
   float             : Float
   atom              : Atom
   name              : Name
   nameSML           : NameSML
   procedure         : Procedure
   record            : Record
   recordInd         : RecordInd
   recordGr          : RecordGr
   recordGrInd       : RecordGrInd
   kindedrecord      : KindedRecord
   kindedrecordInd   : KindedRecordInd
   kindedrecordGr    : KindedRecordGr
   kindedrecordGrInd : KindedRecordGrInd
   hashtuple         : HashTuple
   hashtupleGr       : HashTupleGr
   pipetuple         : PipeTuple
   pipetupleGrS      : PipeTupleGrS
   pipetupleGrM      : PipeTupleGrM
   labeltuple        : LabelTuple
   labeltupleInd     : LabelTupleInd
   labeltupleGr      : LabelTupleGr
   labeltupleGrInd   : LabelTupleGrInd
   future            : Future
   futureGr          : FutureGr
   bytestring        : ByteString
   free              : Free
   freeGr            : FreeGr
   fdint             : FDInt
   fdintGr           : FDIntGr
   fsval             : FSVal
   fsvalGr           : FSValGr
   fshelper          : FSHelper
   fsvar             : FSVar
   fsvarGr           : FSVarGr
   tupleSML          : TupleSML
   vectorSML         : VectorSML
   listSML           : ListSML
   recordSML         : RecordSML
   cellSML           : CellSML
   wordSML           : WordSML
   generic           : Generic
   atomRef           : AtomRef
define
   class Int
      from
         CreateObjects.intCreateObject
         LayoutObjects.intLayoutObject
         DrawObjects.drawObject
      prop
         final
   end

   class Float
      from
         CreateObjects.floatCreateObject
         LayoutObjects.floatLayoutObject
         DrawObjects.drawObject
      prop
         final
   end

   class Atom
      from
         CreateObjects.atomCreateObject
         LayoutObjects.atomLayoutObject
         DrawObjects.drawObject
      prop
         final
   end

   class Name
      from
         CreateObjects.nameCreateObject
         LayoutObjects.nameLayoutObject
         DrawObjects.drawObject
      prop
         final
   end

   class NameSML
      from
         CreateObjects.nameCreateObject
         LayoutObjects.nameSMLLayoutObject
         DrawObjects.drawObject
      prop
         final
   end

   class Procedure
      from
         CreateObjects.procedureCreateObject
         LayoutObjects.procedureLayoutObject
         DrawObjects.drawObject
      prop
         final
   end

   class Record
      from
         CreateObjects.recordCreateObject
         LayoutObjects.recordLayoutObject
         DrawObjects.recordDrawObject
      prop
         final
   end

   class RecordInd
      from
         CreateObjects.recordIndCreateObject
         LayoutObjects.recordIndLayoutObject
         DrawObjects.recordIndDrawObject
      prop
         final
   end

   class RecordGr
      from
         CreateObjects.recordGrCreateObject
         LayoutObjects.recordGrLayoutObject
         DrawObjects.recordGrDrawObject
      prop
         final
   end

   class RecordGrInd
      from
         CreateObjects.recordGrIndCreateObject
         LayoutObjects.recordGrIndLayoutObject
         DrawObjects.recordGrIndDrawObject
      prop
         final
   end

   class KindedRecord
      from
         CreateObjects.kindedRecordCreateObject
         LayoutObjects.recordLayoutObject
         DrawObjects.kindedRecordDrawObject
      prop
         final
   end

   class KindedRecordInd
      from
         CreateObjects.kindedRecordIndCreateObject
         LayoutObjects.recordIndLayoutObject
         DrawObjects.kindedRecordIndDrawObject
      prop
         final
   end

   class KindedRecordGr
      from
         CreateObjects.kindedRecordGrCreateObject
         LayoutObjects.recordGrLayoutObject
         DrawObjects.kindedRecordGrDrawObject
      prop
         final
   end

   class KindedRecordGrInd
      from
         CreateObjects.kindedRecordGrCreateObject
         LayoutObjects.recordGrLayoutObject
         DrawObjects.kindedRecordGrIndDrawObject
      prop
         final
   end

   class HashTuple
      from
         CreateObjects.hashTupleCreateObject
         LayoutObjects.hashTupleLayoutObject
         DrawObjects.hashTupleDrawObject
      prop
         final
   end

   class HashTupleGr
      from
         CreateObjects.hashTupleGrCreateObject
         LayoutObjects.hashTupleGrLayoutObject
         DrawObjects.hashTupleGrDrawObject
      prop
         final
   end

   class PipeTuple
      from
         CreateObjects.pipeTupleCreateObject
         LayoutObjects.pipeTupleLayoutObject
         DrawObjects.pipeTupleDrawObject
      prop
         final
   end

   class PipeTupleGrS
      from
         CreateObjects.pipeTupleGrCreateObject
         LayoutObjects.pipeTupleGrLayoutObject
         DrawObjects.pipeTupleGrSDrawObject
      prop
         final
   end

   class PipeTupleGrM
      from
         CreateObjects.pipeTupleGrCreateObject
         LayoutObjects.pipeTupleGrLayoutObject
         DrawObjects.pipeTupleGrMDrawObject
      prop
         final
   end

   class LabelTuple
      from
         CreateObjects.labelTupleCreateObject
         LayoutObjects.labelTupleLayoutObject
         DrawObjects.labelTupleDrawObject
      prop
         final
   end

   class LabelTupleInd
      from
         CreateObjects.labelTupleCreateObject
         LayoutObjects.labelTupleIndLayoutObject
         DrawObjects.labelTupleIndDrawObject
      prop
         final
   end

   class LabelTupleGr
      from
         CreateObjects.labelTupleGrCreateObject
         LayoutObjects.labelTupleGrLayoutObject
         DrawObjects.labelTupleGrDrawObject
      prop
         final
   end

   class LabelTupleGrInd
      from
         CreateObjects.labelTupleGrCreateObject
         LayoutObjects.labelTupleGrIndLayoutObject
         DrawObjects.labelTupleGrIndDrawObject
      prop
         final
   end

   class Future
      from
         CreateObjects.futureCreateObject
         LayoutObjects.futureLayoutObject
         DrawObjects.futureDrawObject
      prop
         final
   end

   class FutureGr
      from
         CreateObjects.futureGrCreateObject
         LayoutObjects.futureGrLayoutObject
         DrawObjects.futureGrDrawObject
      prop
         final
   end

   class ByteString
      from
         CreateObjects.byteStringCreateObject
         LayoutObjects.byteStringLayoutObject
         DrawObjects.drawObject
      prop
         final
   end

   class Free
      from
         CreateObjects.freeCreateObject
         LayoutObjects.freeLayoutObject
         DrawObjects.freeDrawObject
      prop
         final
   end

   class FreeGr
      from
         CreateObjects.freeGrCreateObject
         LayoutObjects.freeGrLayoutObject
         DrawObjects.freeGrDrawObject
      prop
         final
   end

   class FDInt
      from
         CreateObjects.fDIntCreateObject
         LayoutObjects.fDIntLayoutObject
         DrawObjects.fDIntDrawObject
      prop
         final
   end

   class FDIntGr
      from
         CreateObjects.fDIntGrCreateObject
         LayoutObjects.fDIntGrLayoutObject
         DrawObjects.fDIntGrDrawObject
      prop
         final
   end

   class FSVal
      from
         CreateObjects.fSValCreateObject
         LayoutObjects.fDIntLayoutObject
         DrawObjects.fDIntDrawObject
      prop
         final
   end

   class FSValGr
      from
         CreateObjects.fSValGrCreateObject
         LayoutObjects.fDIntGrLayoutObject
         DrawObjects.fDIntGrDrawObject
      prop
         final
   end

   class FSHelper
      from
         CreateObjects.fSHelperCreateObject
         LayoutObjects.fDIntLayoutObject
         DrawObjects.fDIntDrawObject
      prop
         final
   end

   class FSVar
      from
         CreateObjects.fSVarCreateObject
         LayoutObjects.fSVarLayoutObject
         DrawObjects.fDIntDrawObject
      prop
         final
   end

   class FSVarGr
      from
         CreateObjects.fSVarGrCreateObject
         LayoutObjects.fSVarGrLayoutObject
         DrawObjects.fDIntGrDrawObject
      prop
         final
   end

   class TupleSML
      from
         CreateObjects.tupleSMLCreateObject
         LayoutObjects.tupleSMLLayoutObject
         DrawObjects.labelTupleDrawObject
      prop
         final
   end

   class VectorSML
      from
         CreateObjects.vectorSMLCreateObject
         LayoutObjects.tupleSMLLayoutObject
         DrawObjects.labelTupleDrawObject
      prop
         final
   end

   class ListSML
      from
         CreateObjects.listSMLCreateObject
         LayoutObjects.listSMLLayoutObject
         DrawObjects.pipeTupleDrawObject
      prop
         final
   end

   class RecordSML
      from
         CreateObjects.recordSMLCreateObject
         LayoutObjects.tupleSMLLayoutObject
         DrawObjects.labelTupleDrawObject
      prop
         final
   end

   class CellSML
      from
         CreateObjects.cellSMLCreateObject
         LayoutObjects.labelTupleLayoutObject
         DrawObjects.labelTupleDrawObject
      prop
         final
   end

   class WordSML
      from
         CreateObjects.wordSMLCreateObject
         LayoutObjects.wordSMLLayoutObject
         DrawObjects.drawObject
      prop
         final
   end

   class Generic
      from
         CreateObjects.genericCreateObject
         LayoutObjects.genericLayoutObject
         DrawObjects.drawObject
      prop
         final
   end

   class AtomRef
      from
         CreateObjects.atomRefCreateObject
         LayoutObjects.atomRefLayoutObject
         DrawObjects.atomRefDrawObject
      prop
         final
   end
end
