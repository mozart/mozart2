%%%
%%% Authors:
%%%   Konstantin Popov
%%%
%%% Copyright:
%%%   Konstantin Popov, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%% "Browser term" module. It is constraint system dependent.
%%%
%%% There are the following components:
%%%   GetTermType:     term, store -> type
%%%   GetObjClass:     type -> class
%%%   CheckGraph:      (subterm) type -> {true, false}
%%%   CheckMinGraph:   (subterm) type -> {true, false}
%%%   DelimiterLEQ:    delimiter, delimiter -> {true, false}
%%%
%%%

local
   GetTermType
   GetObjClass
   CheckGraph
   CheckMinGraph
   DelimiterLEQ

   %%
   LocalIsString
   IsVirtualString
   IsListDepth
in

   %%
   %%
   %% Specialized, non-monotonic versions - which are basically the
   %% same as a standard, monotonic one except the case of variables;
   fun {LocalIsString X}
      case {Value.status X}
      of det(DT) then
         case DT
         of atom then X == nil
         [] tuple then
            case X
            of E|T then
               case {Value.status E}
               of det(int) then
                  E >= 0 andthen E =< 255 andthen {LocalIsString T}
               else false
               end
            else false
            end
         else false
         end
      else false
      end
   end

   %%
   local
      fun {IsAll I V}
         I==0 orelse ({IsVirtualString V.I} andthen {IsAll I-1 V})
      end
   in
      fun {IsVirtualString X}
         case {Value.status X}
         of det(DT) then
            case DT
            of atom  then true
            [] int   then true
            [] float then true
            [] tuple then
               case {Label X}
               of '#' then {IsAll {Width X} X}
               [] '|' then {LocalIsString X}
               else false
               end
            [] byteString then true
            else false
            end
         else false
         end
      end
   end

   %%
   %%  Note: that's not a function!
   fun {IsListDepth L D}
      if D > 0 then
         %%
         if {IsDet L} then
            case L
            of _|Xr then {IsListDepth Xr (D-1)}
            else L == nil
            end
         else false
         end
      else
         {Value.status L} == det(atom) andthen L == nil
      end
   end

   %%
   %% Returns a type of a given term;
   %%
   %% 'Term' is a term to be investigated;
   %%
   fun {GetTermType Term Store}
      %%
      case {Value.status Term}
      of free       then T_Variable

      [] kinded(KT) then
         case KT
         of record  then T_Record
         [] int     then T_FDVariable
         [] fset    then T_FSet
         [] other   then
            if {IsCtVar Term} then T_CtVariable % TODO TMUELLER
            else T_Variable     % don't know;
            end
         else T_Unknown
         end

      [] det(DT)    then
         case DT
         of atom            then T_Atom
         [] int             then T_Int
         [] fset            then T_FSet
         [] float           then T_Float
         [] name            then T_Name
         [] foreign_pointer then T_ForeignPointer

         [] tuple      then
            %%
            if
               {Store read(StoreAreStrings $)} andthen {LocalIsString Term}
               orelse
               {Store read(StoreAreVSs $)} andthen {IsVirtualString Term}
            then T_Atom
            else
               case Term of _|_ then
                  if {IsListDepth Term ({Store read(StoreWidth $)} * 2)}
                  then T_List
                  else T_FCons
                  end
               else
                  if
                     case {Label Term}
                     of '#' then TW in TW = {Width Term}
                        %%  must fit into width constraint;
                        TW > 1 andthen TW =< {Store read(StoreWidth $)}
                     else false
                     end
                  then T_HashTuple
                  else T_Tuple
                  end
               end
            end

         [] procedure  then T_Procedure
         [] cell       then T_Cell
         [] record     then T_Record

         [] 'thread'  then T_Thread
         [] 'space'   then T_Space

         % everything else is a chunk
         [] object  then
            if {ChunkHasFeatures Term} then T_CompObject else T_PrimObject end
         [] 'class' then
            if {ChunkHasFeatures Term} then T_CompClass else T_PrimClass end
         [] dictionary then T_Dictionary
         [] array then T_Array
         [] bitArray then T_BitArray
         [] 'lock' then T_Lock
         [] port then T_Port
         [] bitString then T_BitString
         [] byteString then T_ByteString
         [] chunk then
            if {ChunkHasFeatures Term} then T_CompChunk else T_PrimChunk end
         else
            T_Unknown
         end
      [] future then T_Future
      [] failed then T_Failed
      else T_Unknown
      end
   end

   %%
   %%
   fun {GetObjClass Type}
      %%
      case Type
      of !T_Atom           then AtomTermObject
      [] !T_Int            then IntTermObject
      [] !T_Float          then FloatTermObject
      [] !T_Name           then NameTermObject
      [] !T_ForeignPointer then ForeignPointerTermObject
      [] !T_Procedure      then ProcedureTermObject
      [] !T_Cell           then CellTermObject
      [] !T_PrimChunk      then PrimChunkTermObject
      [] !T_Dictionary     then DictionaryTermObject
      [] !T_Array          then ArrayTermObject
      [] !T_BitArray       then BitArrayTermObject
      [] !T_Port           then PortTermObject
      [] !T_Lock           then LockTermObject
      [] !T_Thread         then ThreadTermObject
      [] !T_Space          then SpaceTermObject
      [] !T_CompChunk      then CompChunkTermObject
      [] !T_PrimObject     then PrimObjectTermObject
      [] !T_CompObject     then CompObjectTermObject
      [] !T_PrimClass      then PrimClassTermObject
      [] !T_CompClass      then CompClassTermObject
      [] !T_List           then ListTermObject
      [] !T_FCons          then FConsTermObject
      [] !T_Tuple          then TupleTermObject
      [] !T_Record         then RecordTermObject
      [] !T_HashTuple      then HashTupleTermObject
      [] !T_Variable       then VariableTermObject
      [] !T_FDVariable     then FDVariableTermObject
      [] !T_FSet           then FSetTermObject
      [] !T_CtVariable     then CtVariableTermObject
      [] !T_Future         then FutureTermObject
      [] !T_Failed         then FailedTermObject
      [] !T_Unknown        then UnknownTermObject
      [] !T_BitString      then BitStringTermObject
      [] !T_ByteString     then ByteStringTermObject
      else
         UnknownTermObject
      end
   end

   %%
   %% Yields 'true' if a subterm of a given type ('STType')
   %% could already appear on a path from the tree's root upto 'self';
   %% Basically, it should mean whether a term is compound in the
   %% sense of Oz;
   fun {CheckGraph STType}
      %%
      case STType
      of !T_CompChunk      then true
      [] !T_CompObject     then true
      [] !T_CompClass      then true
      [] !T_List           then true
      [] !T_FCons          then true
         %% when changed,   check the 'ListTermObject::GetElement';
      [] !T_Tuple          then true
      [] !T_Record         then true
      [] !T_HashTuple      then true
      else
         false
      end
   end

   %%
   %% Yields 'true' if equality between (sub)terms of a given type
   %% is necessary for the 'minimal graph' representation;
   %%
   fun {CheckMinGraph STType}
      %%
      case STType
      of !T_Name           then true
      [] !T_ForeignPointer then true
      [] !T_Procedure      then true
      [] !T_Cell           then true
      [] !T_PrimChunk      then true
      [] !T_Dictionary     then true
      [] !T_Array          then true
      [] !T_BitArray       then true
      [] !T_Lock           then true
      [] !T_Thread         then true
      [] !T_Space          then true
      [] !T_CompChunk      then true
      [] !T_PrimObject     then true
      [] !T_CompObject     then true
      [] !T_PrimClass      then true
      [] !T_CompClass      then true
      [] !T_List           then true
      [] !T_FCons          then true
      [] !T_Tuple          then true
      [] !T_Record         then true
      [] !T_HashTuple      then true
      [] !T_Variable       then true
      [] !T_FDVariable     then true
      [] !T_FSet           then true
      [] !T_CtVariable     then true
      [] !T_Future         then false
      [] !T_Failed         then false
      [] !T_BitString      then true
      [] !T_ByteString     then true
      else
         false
      end
   end

   %%
   %%
   fun {DelimiterLEQ Del1 Del2}
        %%
        case Del1
        of !DSpaceGlue then false
        [] !DVBarGlue  then
           case Del2 of !DHashGlue then true
           elseof       !DVBarGlue then true
           else false
           end
        [] !DEqualS    then
           case Del2
           of !DSpaceGlue then false
           else true            % but 'Del2' should not be '=';
           end
        elseof !DHashGlue  then Del2 == DHashGlue
        else {BrowserError 'Unknown delimiter!'} false
        end
   end

   %%
   %%
   BrowserTerm = browserTerm(getTermType:   GetTermType
                             getObjClass:   GetObjClass
                             checkGraph:    CheckGraph
                             checkMinGraph: CheckMinGraph
                             delimiterLEQ:  DelimiterLEQ)

   %%
end
