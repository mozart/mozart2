%  Programming Systems Lab, DFKI Saarbruecken,
%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5337
%  Author: Frank Essig
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%
% local variables for graphical representation of browsed terms in Fegramed
%
% $ID$

%%%


Disj = '{'
Lst  = '}'
Fkt  = ']'
Impl = '|'
Conj = '['


         FE_InitValue      = {NewName}
         FE_CloseFE        = {NewName}
         FE_StartFE        = {NewName}
         FE_CloseAllFE     = {NewName}
         FE_SetShowCurrent = {NewName}
         FE_Browse         = {NewName}

         FE_BrowserClass
         FE_Application
         FE_GenSym
         FE_PseudoTermObject
         FE_AtomObject  FE_IntObject  FE_FloatObject  FE_NameObject
         FE_ProcedureObject  FE_CellObject FE_ObjectObject
         FE_ClassObject  FE_WFlistObject  FE_TupleObject
         FE_GenericRecord
         FE_RecordObject
         FE_ORecord  FE_ListObject  FE_FListObject  FE_HashTupleObject
         FE_VariableObject  FE_FDVariableObject  FE_ShrunkenObject
         FE_ReferenceObject FE_UnknownObject
         FE_Generic FE_GenericRecord
         FE_GenericChunk

         V2S = VirtualString.toString
         S2A = String.toAtom
