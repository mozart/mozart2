%  Programming Systems Lab, University of Saarland,
%  Geb. 45, Postfach 15 11 50, D-66041 Saarbruecken.
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date by $Author$
%  Version: $Revision$

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
            else false
            end
         else false
         end
      end
   end

   %%
   %%  Note: that's not a function!
   fun {IsListDepth L D}
      case D > 0 then
         %%
         case {Value.status L}
         of free      then false
         [] kinded(_) then false
         elsecase L
         of _|Xr then {IsListDepth Xr (D-1)}
         else L == nil
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
            case {IsMetaVar Term} then T_MetaVariable % TODO
            else T_Variable     % don't know;
            end
         else T_Unknown
         end

      [] det(DT)    then
         case DT
         of atom       then T_Atom
         [] int        then T_Int
         [] fset       then T_FSet
         [] float      then T_Float
         [] name       then T_Name

         [] tuple      then
            %%
            case
               {Store read(StoreAreStrings $)} andthen {LocalIsString Term}
               orelse
               {Store read(StoreAreVSs $)} andthen {IsVirtualString Term}
            then T_Atom
            elsecase Term of _|_ then
               case {IsListDepth Term ({Store read(StoreWidth $)} * 2)}
               then T_List
               else T_FCons
               end
            elsecase
               case {Label Term}
               of '#' then TW in TW = {Width Term}
                  %%  must fit into width constraint;
                  TW > 1 andthen TW =< {Store read(StoreWidth $)}
               else false
               end
            then T_HashTuple
            else T_Tuple
            end

         [] procedure  then T_Procedure
         [] cell       then T_Cell
         [] record     then T_Record

         [] chunk      then CW in
            CW = {ChunkWidth Term}
            case {Object.is Term} then
               case CW of 0 then T_PrimObject else T_CompObject end
            elsecase {Class.is Term} then
               case CW of 0 then T_PrimClass else T_CompClass end
            elsecase {Dictionary.is Term} then T_Dictionary
            elsecase {Array.is Term} then T_Array
            elsecase {Port.is Term} then T_Port
            elsecase {Lock.is Term} then T_Lock
            elsecase CW of 0 then T_PrimChunk else T_CompChunk
            end

         [] 'thread'  then T_Thread
                /*
             end
            */
         [] 'space'   then T_Space

         else
            %% 'of' is a keyword ;-)
            {BrowserWarning 'Oz Term _o_f an unknown type '
             # {System.valueToVirtualString Term DInfinite DInfinite}}
            T_Unknown
         end
      else T_Unknown
      end
   end

   %%
   %%
   fun {GetObjClass Type}
      %%
      case Type
      of !T_Atom         then AtomTermObject
      [] !T_Int          then IntTermObject
      [] !T_Float        then FloatTermObject
      [] !T_Name         then NameTermObject
      [] !T_Procedure    then ProcedureTermObject
      [] !T_Cell         then CellTermObject
      [] !T_PrimChunk    then PrimChunkTermObject
      [] !T_Dictionary   then DictionaryTermObject
      [] !T_Array        then ArrayTermObject
      [] !T_Port         then PortTermObject
      [] !T_Lock         then LockTermObject
      [] !T_Thread       then ThreadTermObject
      [] !T_Space        then SpaceTermObject
      [] !T_CompChunk    then CompChunkTermObject
      [] !T_PrimObject   then PrimObjectTermObject
      [] !T_CompObject   then CompObjectTermObject
      [] !T_PrimClass    then PrimClassTermObject
      [] !T_CompClass    then CompClassTermObject
      [] !T_List         then ListTermObject
      [] !T_FCons        then FConsTermObject
      [] !T_Tuple        then TupleTermObject
      [] !T_Record       then RecordTermObject
      [] !T_HashTuple    then HashTupleTermObject
      [] !T_Variable     then VariableTermObject
      [] !T_FDVariable   then FDVariableTermObject
      [] !T_FSet         then FSetTermObject
      [] !T_MetaVariable then MetaVariableTermObject
      [] !T_Unknown      then UnknownTermObject
      else
         {BrowserError 'Unknown type in BrowserTerm.getObjClass: '}
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
      of !T_Atom         then false
      [] !T_Int          then false
      [] !T_Float        then false
      [] !T_Name         then false
      [] !T_Procedure    then false
      [] !T_Cell         then false
      [] !T_PrimChunk    then false
      [] !T_Dictionary   then false
      [] !T_Array        then false
      [] !T_Lock         then false
      [] !T_Thread       then false
      [] !T_Space        then false
      [] !T_CompChunk    then true
      [] !T_PrimObject   then false
      [] !T_CompObject   then true
      [] !T_PrimClass    then false
      [] !T_CompClass    then true
      [] !T_List         then true
      [] !T_FCons        then true
         %% when changed, check the 'ListTermObject::GetElement';
      [] !T_Tuple        then true
      [] !T_Record       then true
      [] !T_HashTuple    then true
      [] !T_Variable     then false
      [] !T_FDVariable   then false
      [] !T_FSet         then false
      [] !T_MetaVariable then false
      [] !T_Unknown      then false
      else
         {BrowserWarning
          'Unknown type in BrowserTerm.checkGraph' # STType}
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
      of !T_Atom         then false
      [] !T_Int          then false
      [] !T_Float        then false
      [] !T_Name         then true
      [] !T_Procedure    then true
      [] !T_Cell         then true
      [] !T_PrimChunk    then true
      [] !T_Dictionary   then true
      [] !T_Array        then true
      [] !T_Lock         then true
      [] !T_Thread       then true
      [] !T_Space        then true
      [] !T_CompChunk    then true
      [] !T_PrimObject   then true
      [] !T_CompObject   then true
      [] !T_PrimClass    then true
      [] !T_CompClass    then true
      [] !T_List         then true
      [] !T_FCons        then true
         %% when changed, check the 'ListTermObject::GetElement';
      [] !T_Tuple        then true
      [] !T_Record       then true
      [] !T_HashTuple    then true
      [] !T_Variable     then true
      [] !T_FDVariable   then true
      [] !T_FSet         then true
      [] !T_MetaVariable then true
      [] !T_Unknown      then false
      else
         {BrowserWarning
          'Unknown type in BrowserTerm.checkMinGraph' # STType}
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
