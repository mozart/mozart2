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
%%%   CheckGraph:      (subterm) type -> {True, False}
%%%   CheckMinGraph:   (subterm) type -> {True, False}
%%%   DelimiterLEQ:    delimiter, delimiter -> {True, False}
%%%
%%%

local
   GetTermType
   GetObjClass
   CheckGraph
   CheckMinGraph
   DelimiterLEQ

   %%
   IsVirtualString
   IsListDepth
in

   %%
   %% Specialized, a non-monotonic version - which is basically the
   %% same as a standard, monotonic one except the case of a variable;
   local
      fun {IsAll I V}
         I==0 orelse ({IsVirtualString V.I} andthen {IsAll I-1 V})
      end
   in
      fun {IsVirtualString X}
         case {Value.status X}
         of det(DT) then
            case DT
            of atom  then True
            [] int   then True
            [] float then True
            [] tuple then
               case {Label X}
               of '#' then {IsAll {Width X} X}
               [] '|' then {IsString X}
               else False
               end
            else False
            end
         else False
         end
      end
   end

   %%
   %%  Note: that's not a function!
   fun {IsListDepth L D}
      case D > 0 then
         %%
         case {Value.status L}
         of free      then False
         [] kinded(_) then False
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
         [] float      then T_Float
         [] name       then T_Name

         [] tuple      then
            %%
            case {Store read(StoreAreVSs $)} andthen {IsVirtualString Term}
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
               else False
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
      [] !T_MetaVariable then MetaVariableTermObject
      [] !T_Unknown      then UnknownTermObject
      else
         {BrowserError 'Unknown type in BrowserTerm.getObjClass: '}
         UnknownTermObject
      end
   end

   %%
   %% Yields 'True' if a subterm of a given type ('STType')
   %% could already appear on a path from the tree's root upto 'self';
   %% Basically, it should mean whether a term is compound in the
   %% sense of Oz;
   fun {CheckGraph STType}
      %%
      case STType
      of !T_Atom         then False
      [] !T_Int          then False
      [] !T_Float        then False
      [] !T_Name         then False
      [] !T_Procedure    then False
      [] !T_Cell         then False
      [] !T_PrimChunk    then False
      [] !T_Dictionary   then False
      [] !T_Array        then False
      [] !T_Thread       then False
      [] !T_Space        then False
      [] !T_CompChunk    then True
      [] !T_PrimObject   then False
      [] !T_CompObject   then True
      [] !T_PrimClass    then False
      [] !T_CompClass    then True
      [] !T_List         then True
      [] !T_FCons        then True
         %% when changed, check the 'ListTermObject::GetElement';
      [] !T_Tuple        then True
      [] !T_Record       then True
      [] !T_HashTuple    then True
      [] !T_Variable     then False
      [] !T_FDVariable   then False
      [] !T_MetaVariable then False
      [] !T_Unknown      then False
      else
         {BrowserWarning
          'Unknown type in BrowserTerm.checkGraph' # STType}
         False
      end
   end

   %%
   %% Yields 'True' if equality between (sub)terms of a given type
   %% is necessary for the 'minimal graph' representation;
   %%
   fun {CheckMinGraph STType}
      %%
      case STType
      of !T_Atom         then False
      [] !T_Int          then False
      [] !T_Float        then False
      [] !T_Name         then True
      [] !T_Procedure    then True
      [] !T_Cell         then True
      [] !T_PrimChunk    then True
      [] !T_Dictionary   then True
      [] !T_Array        then True
      [] !T_Thread       then True
      [] !T_Space        then True
      [] !T_CompChunk    then True
      [] !T_PrimObject   then True
      [] !T_CompObject   then True
      [] !T_PrimClass    then True
      [] !T_CompClass    then True
      [] !T_List         then True
      [] !T_FCons        then True
         %% when changed, check the 'ListTermObject::GetElement';
      [] !T_Tuple        then True
      [] !T_Record       then True
      [] !T_HashTuple    then True
      [] !T_Variable     then True
      [] !T_FDVariable   then True
      [] !T_MetaVariable then True
      [] !T_Unknown      then False
      else
         {BrowserWarning
          'Unknown type in BrowserTerm.checkMinGraph' # STType}
         False
      end
   end

   %%
   %%
   fun {DelimiterLEQ Del1 Del2}
        %%
        case Del1
        of !DSpaceGlue then False
        [] !DVBarGlue  then
           case Del2     of !DHashGlue then True
           elsecase Del2 of !DVBarGlue then True
           else False
           end
        [] !DEqualS    then
           case Del2
           of !DSpaceGlue then False
           else True            % but 'Del2' should not be '=';
           end
        elsecase Del1
        of !DHashGlue  then Del2 == DHashGlue
        else {BrowserError 'Unknown delimiter!'} False
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
