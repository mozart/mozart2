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
%%% DrawObjects Functor
%%%

functor $

import
   SupportNodes
   CreateObjects(kindedRecordCreateObject kindedRecordCycleCreateObject)
   TreeNodes
   Tk(canvasTag menu menuentry)

export
   intDrawObject               : IntDrawObject
   floatDrawObject             : FloatDrawObject
   atomDrawObject              : AtomDrawObject
   boolDrawObject              : BoolDrawObject
   nameDrawObject              : NameDrawObject
   procedureDrawObject         : ProcedureDrawObject
   recordDrawObject            : RecordDrawObject
   kindedRecordDrawObject      : KindedRecordDrawObject
   recordCycleDrawObject       : RecordCycleDrawObject
   kindedRecordCycleDrawObject : KindedRecordCycleDrawObject
   hashTupleDrawObject         : HashTupleDrawObject
   pipeTupleDrawObject         : PipeTupleDrawObject
   hashTupleCycleDrawObject    : HashTupleCycleDrawObject
   pipeTupleCycleDrawObject    : PipeTupleCycleDrawObject
   labelTupleDrawObject        : LabelTupleDrawObject
   labelTupleCycleDrawObject   : LabelTupleCycleDrawObject
   classDrawObject             : ClassDrawObject
   objectDrawObject            : ObjectDrawObject
   arrayDrawObject             : ArrayDrawObject
   dictionaryDrawObject        : DictionaryDrawObject
   portDrawObject              : PortDrawObject
   spaceDrawObject             : SpaceDrawObject
   chunkDrawObject             : ChunkDrawObject
   freeDrawObject              : FreeDrawObject
   fDIntDrawObject             : FDIntDrawObject
   fSSetDrawObject             : FSSetDrawObject

define
   OpMan                         = SupportNodes.options
   ProxyNode                     = SupportNodes.proxyNode
   BitmapTreeNode                = SupportNodes.bitmapTreeNode
   InternalAtomNode              = SupportNodes.internalAtomNode
   KindedRecordCreateObject      = CreateObjects.kindedRecordCreateObject
   KindedRecordCycleCreateObject = CreateObjects.kindedRecordCycleCreateObject

   \insert 'Create/CreateProcs.oz'

   \insert 'Draw/BaseDrawObject.oz'
   \insert 'Draw/SimpleDrawObjects.oz'
   \insert 'Draw/RecordDrawObjects.oz'
   \insert 'Draw/TupleDrawObjects.oz'
   \insert 'Draw/ChunkDrawObjects.oz'
   \insert 'Draw/FreeDrawObject.oz'
   \insert 'Draw/FDIntDrawObject.oz'
   \insert 'Draw/FSSetDrawObject.oz'
end
