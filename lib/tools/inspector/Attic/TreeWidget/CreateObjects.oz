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
%%% CreateObjects Functor
%%%

functor $

import
   SupportNodes
   TreeNodes
   FD(reflect)
   FS(reflect)
   System(printName eq)

export
   intCreateObject               : IntCreateObject
   floatCreateObject             : FloatCreateObject
   atomCreateObject              : AtomCreateObject
   boolCreateObject              : BoolCreateObject
   nameCreateObject              : NameCreateObject
   procedureCreateObject         : ProcedureCreateObject
   recordCreateObject            : RecordCreateObject
   kindedRecordCreateObject      : KindedRecordCreateObject
   recordCycleCreateObject       : RecordCycleCreateObject
   kindedRecordCycleCreateObject : KindedRecordCycleCreateObject
   hashTupleCreateObject         : HashTupleCreateObject
   pipeTupleCreateObject         : PipeTupleCreateObject
   hashTupleCycleCreateObject    : HashTupleCycleCreateObject
   pipeTupleCycleCreateObject    : PipeTupleCycleCreateObject
   labelTupleCreateObject        : LabelTupleCreateObject
   labelTupleCycleCreateObject   : LabelTupleCycleCreateObject
   classCreateObject             : ClassCreateObject
   objectCreateObject            : ObjectCreateObject
   arrayCreateObject             : ArrayCreateObject
   dictionaryCreateObject        : DictionaryCreateObject
   portCreateObject              : PortCreateObject
   spaceCreateObject             : SpaceCreateObject
   chunkCreateObject             : ChunkCreateObject
   freeCreateObject              : FreeCreateObject
   fDIntCreateObject             : FDIntCreateObject
   fSSetCreateObject             : FSSetCreateObject

define
   NullNode         = SupportNodes.nullNode
   BitmapTreeNode   = SupportNodes.bitmapTreeNode
   InternalAtomNode = SupportNodes.internalAtomNode
   GenericNode      = SupportNodes.genericNode

   \insert 'Create/CreateProcs.oz'

   \insert 'Create/BaseCreateObject.oz'
   \insert 'Create/SimpleCreateObjects.oz'
   \insert 'Create/RecordCreateObjects.oz'
   \insert 'Create/TupleCreateObjects.oz'
   \insert 'Create/ChunkCreateObjects.oz'
   \insert 'Create/FreeCreateObject.oz'
   \insert 'Create/FDIntCreateObject.oz'
   \insert 'Create/FSSetCreateObject.oz'
end
