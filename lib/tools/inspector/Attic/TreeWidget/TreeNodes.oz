%%%
%%% Author:
%%%   Thorsten Brunklaus <bruni@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Thorsten Brunklaus, 1998
%%%
%%% Last Change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%

%%%
%%% TreeNodes Functor
%%%

functor $
   prop
      once

import
   CreateObjects
   LayoutObjects
   DrawObjects

export
   intTreeNode               : IntTreeNode
   floatTreeNode             : FloatTreeNode
   atomTreeNode              : AtomTreeNode
   boolTreeNode              : BoolTreeNode
   nameTreeNode              : NameTreeNode
   procedureTreeNode         : ProcedureTreeNode
   recordTreeNode            : RecordTreeNode
   kindedRecordTreeNode      : KindedRecordTreeNode
   recordCycleTreeNode       : RecordCycleTreeNode
   kindedRecordCycleTreeNode : KindedRecordCycleTreeNode
   hashTupleTreeNode         : HashTupleTreeNode
   pipeTupleTreeNode         : PipeTupleTreeNode
   labelTupleTreeNode        : LabelTupleTreeNode
   hashTupleCycleTreeNode    : HashTupleCycleTreeNode
   pipeTupleCycleTreeNode    : PipeTupleCycleTreeNode
   labelTupleCycleTreeNode   : LabelTupleCycleTreeNode
   classTreeNode             : ClassTreeNode
   objectTreeNode            : ObjectTreeNode
   arrayTreeNode             : ArrayTreeNode
   dictionaryTreeNode        : DictionaryTreeNode
   portTreeNode              : PortTreeNode
   spaceTreeNode             : SpaceTreeNode
   chunkTreeNode             : ChunkTreeNode
   freeTreeNode              : FreeTreeNode
   fDIntTreeNode             : FDIntTreeNode
   fSSetTreeNode             : FSSetTreeNode

body
   %% Simple Types

   class IntTreeNode
      from
         CreateObjects.intCreateObject
         LayoutObjects.intLayoutObject
         DrawObjects.intDrawObject

      prop
         final
   end

   class FloatTreeNode
      from
         CreateObjects.floatCreateObject
         LayoutObjects.floatLayoutObject
         DrawObjects.floatDrawObject

      prop
         final
   end

   class AtomTreeNode
      from
         CreateObjects.atomCreateObject
         LayoutObjects.atomLayoutObject
         DrawObjects.atomDrawObject

      prop
         final
   end

   class BoolTreeNode
      from
         CreateObjects.boolCreateObject
         LayoutObjects.boolLayoutObject
         DrawObjects.boolDrawObject

      prop
         final
   end

   class NameTreeNode
      from
         CreateObjects.nameCreateObject
         LayoutObjects.nameLayoutObject
         DrawObjects.nameDrawObject

      prop
         final
   end

   class ProcedureTreeNode
      from
         CreateObjects.procedureCreateObject
         LayoutObjects.procedureLayoutObject
         DrawObjects.procedureDrawObject

      prop
         final
   end

   %% Record Types

   class RecordTreeNode
      from
         CreateObjects.recordCreateObject
         LayoutObjects.recordLayoutObject
         DrawObjects.recordDrawObject

      prop
         final
   end

   class KindedRecordTreeNode
      from
         CreateObjects.kindedRecordCreateObject
         LayoutObjects.kindedRecordLayoutObject
         DrawObjects.kindedRecordDrawObject

      prop
         final
   end

   class RecordCycleTreeNode
      from
         CreateObjects.recordCycleCreateObject
         LayoutObjects.recordCycleLayoutObject
         DrawObjects.recordCycleDrawObject

      prop
         final
   end

   class KindedRecordCycleTreeNode
      from
         CreateObjects.kindedRecordCycleCreateObject
         LayoutObjects.kindedRecordCycleLayoutObject
         DrawObjects.kindedRecordCycleDrawObject

      prop
         final
   end

   %% "Tuple" Types

   class HashTupleTreeNode
      from
         CreateObjects.hashTupleCreateObject
         LayoutObjects.hashTupleLayoutObject
         DrawObjects.hashTupleDrawObject

      prop
         final
   end

   class PipeTupleTreeNode
      from
         CreateObjects.pipeTupleCreateObject
         LayoutObjects.pipeTupleLayoutObject
         DrawObjects.pipeTupleDrawObject

      prop
         final
   end

   class LabelTupleTreeNode
      from
         CreateObjects.labelTupleCreateObject
         LayoutObjects.labelTupleLayoutObject
         DrawObjects.labelTupleDrawObject

      prop
         final
   end

   class HashTupleCycleTreeNode
      from
         CreateObjects.hashTupleCycleCreateObject
         LayoutObjects.hashTupleCycleLayoutObject
         DrawObjects.hashTupleCycleDrawObject

      prop
         final
   end

   class PipeTupleCycleTreeNode
      from
         CreateObjects.pipeTupleCycleCreateObject
         LayoutObjects.pipeTupleCycleLayoutObject
         DrawObjects.pipeTupleCycleDrawObject

      prop
         final
   end

   class LabelTupleCycleTreeNode
      from
         CreateObjects.labelTupleCycleCreateObject
         LayoutObjects.labelTupleCycleLayoutObject
         DrawObjects.labelTupleCycleDrawObject

      prop
         final
   end

   %% Chunk Types

   class ClassTreeNode
      from
         CreateObjects.classCreateObject
         LayoutObjects.classLayoutObject
         DrawObjects.classDrawObject

      prop
         final
   end

   class ObjectTreeNode
      from
         CreateObjects.objectCreateObject
         LayoutObjects.objectLayoutObject
         DrawObjects.objectDrawObject

      prop
         final
   end

   class ArrayTreeNode
      from
         CreateObjects.arrayCreateObject
         LayoutObjects.arrayLayoutObject
         DrawObjects.arrayDrawObject

      prop
         final
   end

   class DictionaryTreeNode
      from
         CreateObjects.dictionaryCreateObject
         LayoutObjects.dictionaryLayoutObject
         DrawObjects.dictionaryDrawObject

      prop
         final
   end

   class PortTreeNode
      from
         CreateObjects.portCreateObject
         LayoutObjects.portLayoutObject
         DrawObjects.portDrawObject

      prop
         final
   end

   class SpaceTreeNode
      from
         CreateObjects.spaceCreateObject
         LayoutObjects.spaceLayoutObject
         DrawObjects.spaceDrawObject

      prop
         final
   end

   class ChunkTreeNode
      from
         CreateObjects.chunkCreateObject
         LayoutObjects.chunkLayoutObject
         DrawObjects.chunkDrawObject

      prop
         final
   end

   %% Free Variable Type

   class FreeTreeNode
      from
         CreateObjects.freeCreateObject
         LayoutObjects.freeLayoutObject
         DrawObjects.freeDrawObject

      prop
         final
   end

   %% FD Int Type

   class FDIntTreeNode
      from
         CreateObjects.fDIntCreateObject
         LayoutObjects.fDIntLayoutObject
         DrawObjects.fDIntDrawObject

      prop
         final
   end

   %% FS Set Type

   class FSSetTreeNode
      from
         CreateObjects.fSSetCreateObject
         LayoutObjects.fSSetLayoutObject
         DrawObjects.fSSetDrawObject

      prop
         final
   end
end
