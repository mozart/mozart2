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
         case {IsVar X} then False
         elsecase {Type.ofValue X}
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
      end
   end

   %%
   %% Returns a type of a given term;
   %%
   %% 'Term' is a term to be investigated;
   %%
   fun {GetTermType Term Store}
      %%
      case {IsVar Term} then
         %%
         case {IsRecordCVar Term}  then T_Record
         elsecase {IsFdVar Term}   then T_FDVariable
         elsecase {IsMetaVar Term} then T_MetaVariable
         else T_Variable
         end
      elsecase {Type.ofValue Term}
      of atom    then T_Atom
      [] int     then T_Int
      [] float   then T_Float
      [] name    then T_Name
      [] tuple   then
         %%
         case {Store read(StoreAreVSs $)} andthen {IsVirtualString Term}
         then T_Atom
         elsecase Term of _|_ then T_List
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

      [] procedure then T_Procedure
      [] cell then T_Cell
      [] record then T_Record

      [] chunk then CW in
         CW = {ChunkWidth Term}
         case {Object.is Term} then
            case CW of 0 then T_PrimObject else T_CompObject end
         elsecase {Class.is Term} then
            case CW of 0 then T_PrimClass else T_CompClass end
         elsecase {Dictionary.is Term} then T_Dictionary
         elsecase {Array.is Term} then T_Array
         elsecase CW of 0 then T_PrimChunk else T_CompChunk
         end

      [] 'thread' then T_Thread
             /*
          end           % "Oz" emacs mode problems;
         */

      [] 'space' then T_Space

      else
         %% 'of' is a keyword ;-)
         {BrowserWarning 'Oz Term _o_f an unknown type '
          # {System.valueToVirtualString Term DInfinite DInfinite}}
         T_Unknown
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
%    local SpaceTab HashTab EQTab Tab in
%       SpaceTab = tab(DSpaceGlue: False
%                      DHashGlue:  False
%                      DEqualS:    False)
%       HashTab =  tab(DSpaceGlue: False
%                      DHashGlue:  True
%                      DEqualS:    False)
%       EQTab =    tab(DSpaceGlue: False
%                      DHashGlue:  True
%                      DEqualS:    True)
%       %%
%       Tab =  tab(DSpaceGlue: SpaceTab
%                  DHashGlue:  HasTab
%                  DEqualS:    EQTab)
%
%       %%
%       fun {DelimiterLEQ Del1 Del2}
%          Tab.Del1.Del2
%       end
%    end
%%%
%%% This works under the assumption that glues are atoms, but
%%% 'DHashGlue' is a string (otherwise a lot of things must be
%%% re-written in the Tcl/Tk interface);
%%%

   %%
   %%
   fun {DelimiterLEQ Del1 Del2}
        %%
        case Del1
        of !DSpaceGlue then False
        [] !DHashGlue  then
           case Del2
           of !DHashGlue  then True
           else False
           end
        [] !DEqualS    then
           case Del2
           of !DSpaceGlue then False
           else True            % but 'Del2' should not be '=';
           end
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
