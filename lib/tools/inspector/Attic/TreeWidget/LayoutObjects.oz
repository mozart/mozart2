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
%%% LayoutObjects Functor
%%%

functor $
   prop
      once

import
   SupportNodes
   System.{printName}

export
   intLayoutObject               : IntLayoutObject
   floatLayoutObject             : FloatLayoutObject
   atomLayoutObject              : AtomLayoutObject
   boolLayoutObject              : BoolLayoutObject
   nameLayoutObject              : NameLayoutObject
   procedureLayoutObject         : ProcedureLayoutObject
   recordLayoutObject            : RecordLayoutObject
   kindedRecordLayoutObject      : KindedRecordLayoutObject
   recordCycleLayoutObject       : RecordCycleLayoutObject
   kindedRecordCycleLayoutObject : KindedRecordCycleLayoutObject
   hashTupleLayoutObject         : HashTupleLayoutObject
   pipeTupleLayoutObject         : PipeTupleLayoutObject
   hashTupleCycleLayoutObject    : HashTupleCycleLayoutObject
   pipeTupleCycleLayoutObject    : PipeTupleCycleLayoutObject
   labelTupleLayoutObject        : LabelTupleLayoutObject
   labelTupleCycleLayoutObject   : LabelTupleCycleLayoutObject
   classLayoutObject             : ClassLayoutObject
   objectLayoutObject            : ObjectLayoutObject
   arrayLayoutObject             : ArrayLayoutObject
   dictionaryLayoutObject        : DictionaryLayoutObject
   portLayoutObject              : PortLayoutObject
   spaceLayoutObject             : SpaceLayoutObject
   chunkLayoutObject             : ChunkLayoutObject
   freeLayoutObject              : FreeLayoutObject
   fDIntLayoutObject             : FDIntLayoutObject
   fSSetLayoutObject             : FSSetLayoutObject

body
   OpMan       = SupportNodes.options
   EmbraceNode = SupportNodes.embraceNode

   \insert 'Layout/BaseLayoutObject.oz'
   \insert 'Layout/SimpleLayoutObjects.oz'
   \insert 'Layout/RecordLayoutObjects.oz'
   \insert 'Layout/TupleLayoutObjects.oz'
   \insert 'Layout/ChunkLayoutObjects.oz'
   \insert 'Layout/FreeLayoutObject.oz'
   \insert 'Layout/FDIntLayoutObject.oz'
   \insert 'Layout/FSSetLayoutObject.oz'
end
