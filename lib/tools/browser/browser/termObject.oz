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
%%%  Term objects;
%%%
%%%


local
   BaseMetaTermObject
   MetaTermObject
   MetaCompoundTermObject
   MetaTupleTermObject
   MetaListTermObject
   MetaRecordTermObject
   I_MetaVariableTermObject

   %%
   StripName
   StripBQuotes
   GenVSPrintName
   GenAtomPrintName
   GenNamePrintName
   GenForeignPointerPrintName
   GenLitPrintName
   GenChunkPrintName
   GenDictionaryPrintName
   GenArrayPrintName
   GenBitArrayPrintName
   GenPortPrintName
   GenLockPrintName
   GenThreadPrintName
   GenSpacePrintName
   GenObjPrintName
   GenClassPrintName
   GenProcPrintName
   GenCellPrintName

   %%
   IsCyclicListDepth

   %%
   AtomicFilter

   %%
   LimitedTermSize

   %%
   %% various "description procedures" and "descriptions;
   CommasDP
   CommasDesc
   DBarDP
   DBarDesc
   EllipsesDP
   EllipsesDesc

   %%  ... and now, there are some local methods & attributes;
   GetName          = {NewName} %  records (at the moment);
   GetElement       = {NewName} %  compound objects only;
   CanBeExpanded    = {NewName} %     --- / --- / ---
   GetLastElNum     = {NewName} %     --- / --- / ---
   DrawSubterms     = {NewName} %     --- / --- / ---
   DrawElement      = {NewName} %     --- / --- / ---
   RebrowseSubterm  = {NewName} %     --- / --- / ---
   GetWatchFun      = {NewName} %  variables only;
   SetWatchPoint    = {NewName} %  variables only;
   ListInit         = {NewName} %  after MetaList"s;
   GetLastElements  = {NewName} %     --- / --- / ---
   CreateLTG        = {NewName} %     --- / --- / ---
   HasLTG           = {NewName} %     --- / --- / ---
   RemoveLTG        = {NewName} %     --- / --- / ---

   %%
   Elements         = {NewName}
   NotShownElements = {NewName}
   ShownWidth       = {NewName}
in

%%%
%%%
%%%  Various local auxiliary procedures;
%%%
   %%
   %%  ... There were also hand-made versions of these functions
   %%  (to be found among "retired modern browsers" ;-));
   %%
   fun {GenAtomPrintName Atom}
      {Value.toVirtualString Atom 1 1}
   end

   %%
   %%
   local
      fun {OctString I Ir}
         ((I div 64) mod 8 + &0) |
         ((I div 8)  mod 8 + &0) |
         (I mod 8 + &0         ) | Ir
      end

      fun {QuoteString Is}
         case Is of nil then nil
         [] I|Ir then
            case {Char.type I}
            of space then
               case I
               of &\n then &\\|&n|{QuoteString Ir}
               [] &\f then &\\|&f|{QuoteString Ir}
               [] &\r then &\\|&r|{QuoteString Ir}
               [] &\t then &\\|&t|{QuoteString Ir}
               [] &\v then &\\|&v|{QuoteString Ir}
               else I|{QuoteString Ir}
               end
            [] other then
               case I
               of &\a then &\\|&a|{QuoteString Ir}
               [] &\b then &\\|&b|{QuoteString Ir}
               else &\\|{OctString I {QuoteString Ir}}
               end
            [] punct then
               case I
               of &\" then &\\|&\"|{QuoteString Ir}
               [] &\\ then &\\|&\\|{QuoteString Ir}
               else I|{QuoteString Ir}
               end
            else I|{QuoteString Ir}
            end
         end
      end

      %%
      proc {HashVS I V1 V2}
         V2.I={GenVS V1.I}
         if I>1 then {HashVS I-1 V1 V2} end
      end

      %%
      fun {GenVS V}
         case {Value.type V}
         of int then V
         [] float then V
         [] atom then
            case V
            of nil then ''
            [] '#' then ''
            [] '' then ''
            else {QuoteString {AtomToString V}}
            end
         [] tuple then
            case {Label V}
            of '|' then {QuoteString V}
            [] '#' then W={Width V} V2={Tuple.make '#' W} in
               {HashVS W V V2} V2
            end
         [] byteString then
            {QuoteString {ByteString.toString V}}
         end
      end
   in
      %%
      fun {GenVSPrintName V}
         '"'#{GenVS V}#'"'
      end
   end

   %%
   %%
   %% Extract a 'meaningful' part out of a temporary name;
   local ParseFun in
      fun {ParseFun I CI E}
         case E of &: then I else CI end
      end

      %%
      %% 'IStr' may not be the empty list (because of 'List.take');
      fun {StripName IStr}
         local Pos in
            Pos = {List.foldLInd IStr ParseFun 0}

            %%
            case Pos of 0 then IStr else {List.take IStr Pos-1} end
         end
      end
   end

   %%
   %%
   fun {StripBQuotes IStr}
      case IStr of nil then nil
      [] I1|I2 then
         if I1==&` then {StripBQuotes I2}
         else I1|{StripBQuotes I2}
         end
      end
   end

   %%
   %% Generate a printname for a name;
   %% TODO : Currently optimized toplevel names are not optimized;
   fun {GenNamePrintName Term Store}
      local AreSmallNames PN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         PN = {System.printName Term}

         %%
         if AreSmallNames then
            case PN
            of '' then '<N>'
            [] '_' then '<N>'
            else SPNS SSPNS in
               SPNS = {StripName {Atom.toString PN}}

               %%
               SSPNS =
               {StripName case SPNS.1 of &` then {StripBQuotes SPNS}
                          else SPNS
                          end}

               %%
               case SSPNS of nil then '<N>'
               else '<N: ' # SSPNS # '>'
               end
            end
         else
            %%
            case PN of '' then '<Name @ ' # {AddrOf Term} # '>'
            else '<Name: ' # PN # ' @ ' # {AddrOf Term} # '>'
            end
         end
      end
   end

   %%
   fun {GenForeignPointerPrintName Term Store}
      if {Store read(StoreSmallNames $)} then
         '<Foreign Pointer>'
      else
         '<Foreign Pointer: ' # {ForeignPointer.toInt Term} # ' @ ' #
         {AddrOf Term} # '>'
      end
   end

   %%
   fun {GenLitPrintName FN Store}
      if {IsAtom FN} then {GenAtomPrintName FN}
      elseif {IsName FN} then {GenNamePrintName FN Store}
         %%
         %% Note that special names (true, false and unit) are not
         %% treated specially here!
      elseif {IsInt FN} then {VirtualString.changeSign FN '~'}
      else FN
      end
   end

   %%
   %%
   %% Generate a chunk's print name;
   %%

   fun {GenThreadPrintName Term Store}
      if {Store read(StoreSmallNames $)} then '<Thr>'
      else '<Thread: ' # {Debug.getId Term} # '>'
      end
   end

   local
      fun {GenGenName TypeName}
         ShortName = {VirtualString.toAtom '<'#TypeName#'>'}
         LongName  = {VirtualString.toAtom '<'#TypeName#' @ '}
      in
         fun {$ Term Store}
            if {Store read(StoreSmallNames $)} then ShortName
            else LongName#{AddrOf Term}#'>'
            end
         end
      end
   in
      GenChunkPrintName      = {GenGenName 'Chunk'}
      GenDictionaryPrintName = {GenGenName 'Dict'}
      GenArrayPrintName      = {GenGenName 'Array'}
      GenBitArrayPrintName   = {GenGenName 'BitArray'}
      GenPortPrintName       = {GenGenName 'Port'}
      GenLockPrintName       = {GenGenName 'Lock'}
      GenSpacePrintName      = {GenGenName 'Space'}
      GenCellPrintName       = {GenGenName 'Cell'}
   end

   %%
   %%
   %% Generate an object's print name;
   fun {GenObjPrintName Term Store}
      local AreSmallNames PN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         PN = {System.printName {BootObject.getClass Term}}

         %%
         if AreSmallNames then
            case PN
            of '' then '<O>'
            [] '_' then '<O>'
            else PNS SN in
               PNS = {Atom.toString PN}

               %%
               %%  I don't know what could here be at all.
               %%  And i'm not keen on it, to be honest.
               SN =
               {StripName case PNS.1 of &` then {StripBQuotes PNS}
                          else PNS
                          end}

               %%
               case SN of nil then '<O>'
               else '<O: ' # SN # '>'
               end
            end
         else
            %%
            case PN of '_' then '<Object @ ' # {AddrOf Term} # '>'
            else '<Object: ' # PN # ' @ ' # {AddrOf Term} # '>'
            end
         end
      end
   end

   %%
   %%
   %% Generate an class's print name;
   fun {GenClassPrintName Term Store}
      local AreSmallNames PN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         PN = {System.printName Term}

         %%
         if AreSmallNames then
            case PN
            of '' then '<C>'
            [] '_' then '<C>'
            else PNS SN in
               PNS = {Atom.toString PN}

               %%
               SN =
               {StripName case PNS.1 of &` then {StripBQuotes PNS}
                          else PNS
                          end}

               %%
               case SN of nil then '<C>'
               else '<C: ' # SN # '>'
               end
            end
         else
            %%
            case PN of '_' then '<Class @ ' # {AddrOf Term} # '>'
            else '<Class: ' # PN # ' @ ' # {AddrOf Term} # '>'
            end
         end
      end
   end

   %%
   %%
   %% Generate a procedure's print name;
   fun {GenProcPrintName Term Store}
      local AreSmallNames PN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         PN = {System.printName Term}

         %%
         if AreSmallNames then
            case PN
            of '' then '<P/' # {Procedure.arity Term} # '>'
            [] '_' then '<P/' # {Procedure.arity Term} # '>'
            else PNS SN in
               PNS = {Atom.toString PN}

               %%
               SN =
               {StripName case PNS.1 of &` then {StripBQuotes PNS}
                          else PNS
                          end}

               %%
               case SN of nil then
                  '<P/' # {Procedure.arity Term} # '>'
               else
                  '<P/' # {Procedure.arity Term} # ' ' # SN # '>'
               end
            end
         else F L C in
            {ProcLoc Term F L C}
            %%
            '<Procedure: ' # PN # '/' # {Procedure.arity Term} #
            ' @ ' # {AddrOf Term} #
            '>(file:' # F # ', line:' # L # ', column:' # C # ')'
         end
      end
   end

   %%
   local DoInfList in
      %%
      %% 'IsCyclicListDepth' have to find *only* cycles over the
      %% first list's element (though there are algorithms which
      %% allow to find arbitrary cycles with similar complexity);
      %%
      %% 'Xs' must be a non-empty list, and, if the list is cyclic,
      %% 'NNonCyclic' is the number of "non-cyclic" elements;

      %%
      fun {DoInfList L Xs NIn Depth}
         if NIn > Depth then NIn
         elseif {IsVar Xs} then Depth + 1
         else
            case Xs of _|Ts then NN in
               NN = NIn + 1
               %%
               if {EQ L Ts} then NN
               else {DoInfList L Ts NN Depth}
               end
            else Depth + 1
            end
         end
      end

      %%
      fun {IsCyclicListDepth Xs Depth ?NNonCyclic}
         NNonCyclic = {DoInfList Xs Xs 0 Depth}
         NNonCyclic =< Depth
      end
   end

   %%
   %% Filter for chunks arity;
   fun {AtomicFilter In}
      case In
      of E|R then
         if {IsAtom E} then E|{AtomicFilter R}
         else {AtomicFilter R}
         end
      else nil
      end
   end

   %%
   %% That's an interesting stuff.
   %%
   %% The 'LimitedTermSize' function yields a maximum of an estimated
   %% term representation's size and a given number.
   %%
   %% Bascially, 'LimitedTermSize' traverses recursively subterms of a
   %% compound term. But only as many as would "fit" within 'SMax'
   %% characters. That is, it's worst-case complexity is O(SMax) and
   %% does NOT depend on the size of a term.
   %%
   local FullTermSize ChLabelSize AuxTupleSize AuxRecordSize in
      %% take a full size of it - though we'll supply to it only
      %% primitive terms;
      fun {FullTermSize T} {TermSize T DInfinite DInfinite} end
      ChLabelSize = {VirtualString.length '<Ch>'}

      %%
      %% There are functions that traverse arguments of tuples and
      %% records:
      fun {AuxTupleSize T CN MN SIn SMax}
         if SIn < SMax andthen CN =< MN then
            {AuxTupleSize T (CN + 1) MN
             {LimitedTermSize T.CN (SIn + DSpace) SMax} SMax}    % ' '
         else SIn
         end
      end
      fun {AuxRecordSize Term Arity SIn SMax}
         if SIn >= SMax then SIn
         else
            case Arity
            of H|T then
               {AuxRecordSize Term T
                {LimitedTermSize H
                 ({LimitedTermSize Term.H (SIn + DDSpace) SMax})    % ':',' '
                 SMax}
                SMax}
            else SIn
            end
         end
      end

      %%
      %% Take an estimated (by the 'TermSize') size of primitive
      %% (sub)terms as it is, and traverse (recursively) subterms of
      %% compound subterms until the accumulated size becomes equal
      %% or greater than 'SMax';
      %%
      fun {LimitedTermSize Term SIn SMax}
         if SIn >= SMax then SIn                % that's all;
            %%
            %% Note that 'SIn' may not be just added to a size of
            %% (sub)term in order to get the new size: we have to
            %% start at that value;
         elseif {IsVar Term} then
            if {IsRecordCVar Term} then RArity KillP RLabel in
               %% we can see some structure in there;
               %%
               %% we don't care about non-monotonic changes that could
               %% happen "in-between". To be precise, between
               %% estimating of the size of an OFS (by means of
               %% 'LimitedTermSize') and building up its
               %% representation: the later can be bigger because it's
               %% performed later. Anyway, 'LimitedTermSize' can only
               %% *approximate* a size of a term's representation;
               RArity = {RecordC.monitorArity Term KillP}
               {KillP}
               if {HasLabel Term}
               then RLabel = {Label Term}
               end

               %%
               %% <label> '(' <subterms> ' ...', where <subterms> due to
               %% 'AuxRecordSize';
               {AuxRecordSize Term RArity
                (SIn + {FullTermSize RLabel} + DSpace + DQSpace) SMax}
            else SIn + {FullTermSize Term}     % primitive;
            end
         else
            case {Value.type Term}
            of tuple  then
               %%
               case Term
               of H|T then
                  {LimitedTermSize T
                   {LimitedTermSize H (SIn + DSpace) SMax} SMax}         % '|'
               else
                  {AuxTupleSize Term 1 {Width Term}
                   (SIn + {FullTermSize {Label Term}} + DSpace) SMax}    % '('
               end

            [] record then
               %%
               {AuxRecordSize Term {Record.arity Term}
                (SIn + {FullTermSize {Label Term}} + DSpace) SMax}  % '('

            [] chunk then
               %%
               {AuxRecordSize Term {ChunkArity Term}
                (SIn + ChLabelSize + DSpace) SMax}                  % '('

            [] 'class' then
               %%
               {AuxRecordSize Term {ChunkArity Term}
                (SIn + ChLabelSize + DSpace) SMax}                  % '('

            else
               %%
               %% Sizes of primitive values are taken as they are;
               SIn + {FullTermSize Term}
            end
         end
      end
   end

   %%
   %% "Glue descriptions" (have a look at 'Desc.txt');
   %%
   %% ",,,"
   CommasDP  = fun {$ _ CP LS} DTSpace >= LS-CP end
   CommasDesc = '>'('+'(current 3) line_size)

   %%
   %% "||"
   DBarDP = fun {$ _ CP LS} DDSpace >= LS-CP end
   DBarDesc = '>'('+'(current DDSpace) line_size)

   %%
   %% "..."
   EllipsesDP = !CommasDP
   EllipsesDesc = !CommasDesc

%%%
%%%
%%% All objects - 'meta-term';
%%%
%%%

   %%
   class BaseMetaTermObject

         %%
         %% generic "dummy" closeTerm (which is normally sufficient,
         %% except variable-like objects);
         %%  'makeTerm' methods are to be provided by specific
         %% erm objects (as one would expect);
         %%
      meth closeTerm skip end

      %%
      %% ... whether there are more subterms than currently shown
      %% (that is false for primitive terms);
      meth !CanBeExpanded($) false end

      %%
      %% ... whether it has been "width" - restrained, that is,
      %% there is a ",,," group;
      %%
      %% Note that if a term object has commas, it can be expanded,
      %% but not vice versa. This is the reason why the contorl
      %% object uses 'hasCommas' in order to tell the browser manager
      %% about whether a term object has the 'expand' operation
      %% defined on;
      meth hasCommas($) false end

      %%
      %% The default action - just rebrowse myself (though for some
      %% term objects this method is not necessary).
      %%
      %% This default action has to be replaced for records (if a
      %% record is an open one, further subterms are awaited, etc.);
      %%
      meth checkTerm
\ifdef DEBUG_TO
         {Show 'MetaTermObject::checkTerm: ...'}
\endif
         %%
         ControlObject , rebrowse
      end


   end

   class MetaTermObject
      from
         ControlObject
         RepManagerObject
         BaseMetaTermObject
   end

%%%
%%%
%%%   There is a really "sparse" part - term classes for primitive
%%%  objects;
%%%
%%%

   %%
   %%
   %% Atoms;
   %%
   class AtomTermObject from MetaTermObject
                           %%
      feat
         type: T_Atom

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'AtomTermObject::makeTerm is applied' # self.term}
\endif
         local Name in
            Name = if
                      {self.store read(StoreAreVSs $)} orelse
                      ({self.store read(StoreAreStrings $)} andthen
                       {Value.status self.term} == det(tuple))
                   then {GenVSPrintName self.term}
                   else {GenAtomPrintName self.term}
                   end

            %%
            %%  we don't have to keep track of the print name;
            RepManagerObject , insert(str: Name)
         end
      end

      meth otherwise(Message)
         ControlObject , processOtherwise('AtomObject::' Message)
      end

   end

   %%
   %%
   %% ByteString
   %%
   class ByteStringTermObject from MetaTermObject

      feat
         type: T_ByteString

      meth makeTerm
         Name = if {self.store read(StoreAreVSs $)} then
                   {GenVSPrintName self.term}
                else
                   {Value.toVirtualString self.term 1 1}
                end
      in
         RepManagerObject , insert(str: Name)
      end

      meth otherwise(Message)
         ControlObject , processOtherwise('ByteStringObject::' Message)
      end

   end

   %%
   %%
   %% BitString
   %%
   class BitStringTermObject from MetaTermObject
      feat
         type: T_BitString

      meth makeTerm
         RepManagerObject ,insert(str:{Value.toVirtualString self.term 1 1})
      end

      meth otherwise(Message)
         ControlObject , processOtherwise('BitStringObject::' Message)
      end

   end

   %%
   %%
   %% Integers;
   %%
   class IntTermObject from MetaTermObject
                          %%
      feat
         type: T_Int

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'IntTermTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            %%
            Name = if {self.store read(StoreAreVSs $)}
                   then {GenVSPrintName self.term}
                   else {VirtualString.changeSign self.term '~'}
                   end

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('IntObject::' Message)
      end

      %%
   end

   %%
   %% Floats;
   %%
   class FloatTermObject from MetaTermObject
                            %%
      feat
         type: T_Float

         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'FloatTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            %%
            Name = if {self.store read(StoreAreVSs $)}
                   then {GenVSPrintName self.term}
                   else {VirtualString.changeSign self.term '~'}
                   end

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('FloatObject::' Message)
      end

      %%
   end

   %%
   %%
   %% Names;
   %%
   class NameTermObject from MetaTermObject
                           %%
      feat
         type: T_Name

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'NameTermObject::makeTerm is applied'#self.term}
\endif
         local Term Name in
            Term = self.term
            %%
            Name = if {Bool.is Term} then
                      if Term then 'true' else 'false' end
                   elseif Term == unit then 'unit'
                   else {GenNamePrintName Term self.store}
                   end

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('NameObject::' Message)
      end

      %%
   end

   %%
   %%
   %% Foreign Pointers;
   %%
   class ForeignPointerTermObject from MetaTermObject
                                     %%
      feat
         type: T_ForeignPointer

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'ForeignPointerTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name = {GenForeignPointerPrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('ForeignPointerObject::' Message)
      end

      %%
   end

   %%
   %%
   %% Procedures;
   %%
   class ProcedureTermObject from MetaTermObject
                                %%
      feat
         type: T_Procedure

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'ProcedureTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name = {GenProcPrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('ProcedureObject::' Message)
      end

      %%
   end

   %%
   %%
   %% Cells;
   %%
   class CellTermObject from MetaTermObject
                           %%
      feat
         type: T_Cell

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'CellTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name = {GenCellPrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('CellObject::' Message)
      end

      %%
   end

   %%
   %%
   %%
   %% Primitive chunks;
   %%
   class PrimChunkTermObject from MetaTermObject
                                %%
      feat
         type: T_PrimChunk

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'PrimChunkTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name = {GenChunkPrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('PrimChunkObject::' Message)
      end

      %%
   end

   %%
   %%
   %% Primitive objects;
   %%
   class PrimObjectTermObject from MetaTermObject
                                 %%
      feat
         type: T_PrimObject

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'PrimObjectTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name =  {GenObjPrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('ObjectObject::' Message)
      end

      %%
   end

   %%
   %%
   %% Primitive classes;
   %%
   class PrimClassTermObject from MetaTermObject
                                %%
      feat
         type: T_PrimClass

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'PrimClassTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name = {GenClassPrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('ClassObject::' Message)
      end

      %%
   end

   %%
   %% Dictionaries;
   %%
   class DictionaryTermObject from MetaTermObject
                                 %%
      feat
         type: T_Dictionary

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'DictionaryTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name = {GenDictionaryPrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('DictionaryObject::' Message)
      end

      %%
   end

   %%
   %% Arrays;
   %%
   class ArrayTermObject from MetaTermObject
                            %%
      feat
         type: T_Array

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'ArrayTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name = {GenArrayPrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('ArrayObject::' Message)
      end

      %%
   end

   %%
   %%
   %% Bit Arrays;
   %%
   class BitArrayTermObject from MetaTermObject
                               %%
      feat
         type: T_BitArray

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'BitArrayTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name = {GenBitArrayPrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('BitArrayObject::' Message)
      end

      %%
   end

   %%
   %% Ports;
   %%
   class PortTermObject from MetaTermObject
                           %%
      feat
         type: T_Port

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'PortTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name = {GenPortPrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('PortObject::' Message)
      end

      %%
   end

   %%
   %% Locks;
   %%
   class LockTermObject from MetaTermObject
                           %%
      feat
         type: T_Lock

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'LockTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name = {GenLockPrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('LockObject::' Message)
      end

      %%
   end

   %%
   %% First-class threads;
   %%
   class ThreadTermObject from MetaTermObject
                             %%
      feat
         type: T_Thread

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'ThreadTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name = {GenThreadPrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('ThreadObject::' Message)
      end

      %%
   end

   %%
   %% First-class computation spaces;
   %%
   class SpaceTermObject from MetaTermObject
                            %%
      feat
         type: T_Space

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'SpaceTermObject::makeTerm is applied'#self.term}
\endif
         local Name in
            Name = {GenSpacePrintName self.term self.store}

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('SpaceObject::' Message)
      end

      %%
   end

%%%
%%%
%%%  'Generic' compound object;
%%%
%%%  There are methods that provide for "intrinsic" compound term
%%% objects functionality, and are not specific to particular term
%%% types;
%%%
%%%

   %%
   class MetaCompoundTermObject
      from
         BaseMetaTermObject
         CompoundControlObject
         CompoundRepManagerObject

         %%
      attr
         %%
         %% A list of term "elements" (It can be incomplete, but is never
         %% malformed). In a simplest case that's just a (complete) list
         %% of subterms (e.g. of a tuple). In the more sophisticated case
         %% of records its elements are feature names (that is, NOT
         %% subterms!);
         %%
         %% The idea behind this abstraction is that sometimes it's more
         %% convenient to see subterms organised into entities that are
         %% larger than a group. For instance, (feature, subterm) is an
         %% "element" in a record;
         !Elements
         %% This list can be constructed either right at the beginning
         %% ('makeTerm'), or "lazily" by means of the 'GetElement'
         %% method: every time a new element is required, this method is
         %% called;
         %%
         %% There is an implicit notion of the "element number".
         %% Elements are numbered from 1 (just per definition :-))
         %%
         %% This attribute isn't changed now (i.e. it could be just a
         %% feature), but one can imagine a case when e.g. some subterms
         %% are hidden etc.;

         %%
         %% ... a tail list of it (may be a variable when it's (yet)
         %% incomplete) which contains its elements that are not shown;
         !NotShownElements
         %%
         %% Note that the 'NotShownElements' attribute is used in a
         %% non-monotonic fashion, but it's still safe because it cannot
         %% be changed somehow else than via certain object methods!
         %%
         %% Note also that each time the 'Elements' list is replaced
         %% (it's an attribute), the 'NotShownElements' and 'ShownWidth'
         %% attributes must be updated correspondingly;

         %%
         %% a number of currently shown subterms, that is, the length of
         %% the 'Elements'\'NotShownElements' list;
         !ShownWidth
         %% Note that this is NOT the same as a number of all subterms:
         %% lists, for instance, can have also a "list tail" group which
         %% contain a subterm, but is not counted here;

         %%
      meth getShownWidth($)
         @ShownWidth
      end
      %%
      %% '0' if there are none so far;
      meth !GetLastElNum($)
         @ShownWidth
      end

      %%
      %% It tries to get (instantiate into a 'Elements' list) a new
      %% subterm. Note that nothing is said here about how it
      %% can/will be implemented - obviously, a caller object must
      %% keep track of an uninstantiated tail list by itself, etc.;
      %%
      %% ... by default - for "fixed-width" terms, there is no need
      %% for 'GetElement', since all the subterms are got once (e.g.
      %% as by means of the 'Record.arity' for fixed records);
      %%
      meth !GetElement skip end

      %%
      %% ... it just checks whether there is a (just one!) further
      %% element in a 'NotShownElements' list; Note that this is NOT
      %% a "public" method;
      meth !CanBeExpanded($)
         local NotShownElementsHere in
            NotShownElementsHere = @NotShownElements

            %%
            if {IsVar NotShownElementsHere}
            then NotShownElementsHereAgain in
               %%
               %% as a last resort we have to lookup for one;
               {self  GetElement}
               NotShownElementsHereAgain = @NotShownElements

               %%
               if {IsVar NotShownElementsHereAgain} then false
               else NotShownElementsHereAgain \= nil
               end
            else
               %%
               NotShownElementsHere \= nil
            end
         end
      end

      %%
      %% an obvious invariant is "hasCommas => CanBeExpanded" (but
      %% not other way around);
      meth hasCommas($)
\ifdef DEBUG_TO
         {Show 'MetaCompoundTermObject::hasCommas is applied'}
\endif
         %%
         CompoundRepManagerObject
         , isGroup(b:DCommasBlock ln:DCommasGroup is:$)
      end

      %%
      %% Draws 'N' subterms (or as many as available) from the
      %% 'NotShownElements' marker (which can also point at the
      %% begging of the list). If 'N' is zero or negative, does not
      %% draw anything. Drawing is performed within 'main' block;
      %%
      %% If the last of suberms is getting shown, a tail ",,," group
      %% is removed. If any subterm(s) are left, but there is (still)
      %% no ",,," group, it's created. The ',,,' group is created in
      %% the 'commas' block;
      %%
      %% 'main' and 'commas' blocks are created even if no groups are
      %% put;
      %%
      %% Note that it can happen that 'DrawSubterms' has put less than
      %% 'N' subterms, but has put a ",,," group! Note that this is
      %% still correct, but in some sense "incomplete" - and must be
      %% handled by a caller method;
      %%
      %% Moreover, this method cannot be made complete (from the point
      %% of view of a external observer): there is always a gap
      %% between a last test in the method and a point at the "caller"
      %% site where the completeness is observed. Basically, this is a
      %% very general observation: if some method/procedure/whatever
      %% is non-monotonic, it cannot be made "complete" in that sense;
      %%
      meth !DrawSubterms(N)
\ifdef DEBUG_TO
         {Show 'MetaCompoundTermObject::DrawSubterms is applied'
          # self.term # N}
\endif
         %%
         %% create/jump to the main block anyway (but it could be
         %% optimized);
         CompoundRepManagerObject , block(DMainBlock)

         %%
         %% An optimisation: don't try to set the cursor if no
         %% subterms will be drawn;
         if N > 0 andthen MetaCompoundTermObject , CanBeExpanded($)
         then
            %%
            %% Invariant: the cursor is set already at a right
            %% position;

            %%
            %% That's a local method wrt the 'MetaCompoundTermObject'
            %% class (it is recursive - that's the reason why it's
            %% here at all);
            MetaCompoundTermObject , DrawElementsLoop(N)
         end

         %%
         %% Check the 'ltg' group;
         CompoundRepManagerObject , block(DCommasBlock)

         %%
         %% Note that new terms can arrive between leaving the
         %% 'DrawElements' and this point - see the comment above;
         if MetaCompoundTermObject , CanBeExpanded($) then
            %%
            %% there are still terms that can be shown, but probably
            %% there is still no ",,," group;
            if MetaCompoundTermObject , hasCommas($) then skip
            else
               CompoundRepManagerObject
               , putG_SGS(ln:   DCommasGroup
                          str:  self.delimiter
                          str2: DNameUnshown
                          dp:   CommasDP
                          desc: CommasDesc)
            end
         else
            %%
            %% ... and vice versa;
            if MetaCompoundTermObject , hasCommas($)
            then CompoundRepManagerObject , removeG(ln:DCommasGroup)
            end
         end

         %%
      end

      %%
      %% ... a local, recursive method (doesn't care about the cursor
      %% location);
      meth DrawElementsLoop(N)
         if
            N > 0 andthen
            MetaCompoundTermObject , CanBeExpanded($) andthen
            CompoundControlObject , mayContinue($)
         then
            %%
            %% this is in some sense a "complementary" method for the
            %% 'GetElement'. Note it also updates the 'ShownWidth'
            %% counter;
            {self  DrawElement}

            %%
            MetaCompoundTermObject , DrawElementsLoop(N - 1)
         end
      end

      %%
      meth !RebrowseSubterm(N)
\ifdef DEBUG_TO
         {Show 'MetaCompoundTermObject::RebrowseSubterm: ' # N}
\endif
         local Term in
            Term = CompoundRepManagerObject , getTermG(fn:N term:$)

            %%
            CompoundRepManagerObject , replaceTermG(fn:N term:Term)
         end
      end

      %%
      %% This is a general, the simplest case: just rebrowse it;
      %% (It has to be overloaded now only for lists;)
      %%
      meth subtermChanged(N)
\ifdef DEBUG_TO
         {Show 'MetaCompoundTermObject::subtermChanged, self.term&N : '
          # self.term # N}
\endif
         %%
         MetaCompoundTermObject , RebrowseSubterm(N)
      end

      %%
   end

   %%
   %% A common property is that 'elements' are just (sub)terms.
   %%
   class MetaTupleTermObject from MetaCompoundTermObject
                                %%

                                %%
                                %% An invariant is that there is one;
      meth !DrawElement
\ifdef DEBUG_TO
         {Show 'MetaTupleTermObject::DrawElement'}
\endif
         local NewWidth ST NewNotShownElements DP Desc in
            @NotShownElements = ST|NewNotShownElements
            NewWidth = @ShownWidth + 1

            %%
            %% ... this is really a higher-order stuff;
            DP = fun {$ _ CP LS} {LimitedTermSize ST CP LS} >= LS end
            Desc = '>'('+'(current st_size(DMainBlock#NewWidth)) line_size)

            %%
            if NewWidth == 1 then
               %%
               CompoundRepManagerObject
               , putG_GT(ln:       1
                         dp:       DP
                         desc:     Desc
                         term:     ST)
            else
               %%
               CompoundRepManagerObject
               , putG_SGT(ln:       NewWidth
                          str:      self.delimiter
                          dp:       DP
                          desc:     Desc
                          term:     ST)
            end

            %%
            NotShownElements <- NewNotShownElements
            ShownWidth <- NewWidth
         end
      end

      %%
   end

   %%
   %%
   %% List-like structures.
   %%
   class MetaListTermObject from MetaTupleTermObject
                               %%
      attr
         %%
         %% a "tail" list which is not yet seen. That's the whole list
         %% when it's not yet shown; nil when the list is well-formend and
         %% completely scanned. Note that a list may be malformed, of
         %% course;
         TailList
         %% a tail list of 'Elements' which is not yet instantiated. It
         %% gets bound when more list elements "arrives" at the
         %% 'TailList';
         TailElements
         %%
         %% Note that these attributes are updated only by means of the
         %% 'GetElement', and can be used non-monotonically everywhere
         %% else;
         %%

         %%
      meth !ListInit
         local EList in
            %%
            %% originally, there are no "seen" subterms, all of them
            %% are "not yet got";
            Elements <- EList
            NotShownElements <- EList
            ShownWidth <- 0

            %%
            TailElements <- EList
            TailList <- self.term
         end
      end

      %%
      %% It must be redefined because subterms are got from the list
      %% in a "lazy" fashion;
      meth !GetElement
\ifdef DEBUG_TO
         {Show 'MetaListTermObject::makeTerm: GetElement'
          # @Elements # @NotShownElements # @ShownWidth
          # @TailElements # @TailList}
\endif
         %%
         %% Do something only if further subtrems are expected.
         %%
         %% Further subterms are NOT expected if either:
         %% (a) it's a closed list (well- or malformed one);
         %% (b) it's a cyclic list ('X=[a b c d || X]');
         %% (c) its tail is a cyclic list. For instance,
         %%     'a|b|c|(X=d|X)', which is represented like
         %%     '[a b c || X=[d || X]]'
         %%
         %% Obviously, no further subterms are expected iff the
         %% 'Elements' list is determined:
         if {IsVar @TailElements} then TL in
            TL = @TailList

            %%
            if {IsVar TL} then skip
               %% no new subterms (but they are still expected);
            else
               case TL
               of _|_ then RepMode = {self.store read(StoreRepMode $)} in
                  %%
                  %% There are three interesting cases when searching
                  %% for cycles is switched on:
                  %% (a) there is a cyclie over the new element, and
                  %%     that element is the first one - then pull all
                  %%     the elements before that "cyclic" one and close
                  %%     the list: the reference must be drawn in its
                  %%     tail;
                  %% (b) ... but the current element is not the first
                  %%     one - then just close the list: we need a new
                  %%     list;
                  %%
                  %% Note that the 'show minimal graph' mode is not
                  %% implemented here. That is, what is done is really
                  %% the list "cyclicity" based on the pointer equality;

                  %%
                  %% So, we have probably to check whether a tail list
                  %% is cyclic
                  if RepMode == GraphRep orelse RepMode == MinGraphRep
                  then MW NNonCyclic in
                     MW = {self.store read(StoreWidth $)}

                     %%
                     if {IsCyclicListDepth TL MW NNonCyclic} then
                        if {EQ @TailElements @Elements} then
                           %% over the first element - pull elements
                           %% up to the "cyclic" one. This must be done
                           %% since there are other cycles - over
                           %% all subsequent elements;
                           MetaListTermObject , PullElements(NNonCyclic)
                        else skip
                           %% not the first element - a new list is
                           %% necessary;
                        end

                        %%
                        %% in both cases, close up the list - a cyclie
                        %% is detected;
                        @TailElements = nil
                     else
                        %% there is no cycle going over this list
                        %% constructor.
                        MetaListTermObject , PullElement
                     end
                  else
                     %% the (a) case;
                     MetaListTermObject , PullElement
                  end
               else
                  %% has got either a closed well-formed list, or a
                  %% malformed one;
                  @TailElements = {self  GetLastElements(TL $)}
               end
            end
         else skip
            %%
            %% Nothing to do.
            %% In particular, the 'TailList' keeps its value;
         end

         %%
\ifdef DEBUG_TO
         {Show 'MetaListTermObject::makeTerm: GetElement is finisehd'
          # @Elements # @NotShownElements # @ShownWidth
          # @TailElements # @TailList}
\endif
      end

      %%
      %% there must be one when called;
      meth PullElement
         local E T NewTailElements in
            %%
            @TailList = E|T

            %%
            @TailElements = E|NewTailElements
            TailElements <- NewTailElements

            %%
            TailList <- T
         end
      end

      %%
      meth PullElements(N)
         if N > 0 then
            MetaListTermObject , PullElement
            MetaListTermObject , PullElements(N-1)
         end
      end

      %%
      %% Approximates the "is a well-formed list" property. That is,
      %% if the (term object's) list is wel-formed and completely
      %% scanned ("got") then it yields 'true'; if it is not or not
      %% yet - then it yields 'false';
      %%
      %% (that's a local method;)
      meth IsWFList($)
         %%
         local TL in
            TL = @TailList

            %%
            if {IsVar TL} then false
            else TL == nil
            end
         end
      end

      %%
      %% It puts 'WidthInc' subterms, or as much as possible, and
      %% after that it puts/removes tail groups ("|" and a tail
      %% variable/term);
      %%
      %% Note that recursion must be handled with care: if no new
      %% subterms are allowed to create, than 'DrawSubterms' will
      %% not create any. That is, 'expand' must break such an endless
      %% loop by itself;
      %%
      %% (that's a local method;)
      meth expand(WidthInc)
\ifdef DEBUG_TO
         {Show 'MetaListTermObject::expand is applied' # self.term}
\endif
         %%
         local CurrentSWidth NewSWidth RestInc in
            %%
            CurrentSWidth = MetaCompoundTermObject , getShownWidth($)

            %%
            %% draw new subterms (God knows (here) how many!) while
            %% respecting the 'width' constraint (a ",,," group at the
            %% end is put/removed whenever necessary);
            MetaCompoundTermObject , DrawSubterms(WidthInc)

            %%
            NewSWidth = MetaCompoundTermObject , getShownWidth($)
            RestInc = WidthInc - (NewSWidth - CurrentSWidth)

            %%
            %% Note that there is a criticall section: first, we draw
            %% all of *currently* available subterms, and after that
            %% probably draw a "list tail" group. There is an
            %% assumption that a tail drawn is not a sublist which (in
            %% part?) must be used for expanding a list's
            %% representation. This cannot be guaranteed, however
            %% ... (since the list can grow between drawing of
            %% subterms and drawing of its tail);
            %%
            %% As a solution of the problem, *after* an 'ltg' is
            %% touched (whenever needed), we check again whether the
            %% list can be expanded ('canBeExpanded'!), and if so a
            %% new 'expand' iteration is initiated;
            %%

            %%
            %% ... Now, we have to put "bar" and "list tail" (e.g. for
            %% a list like 'a|b|c|_' which looks like '[a b c || _]')
            %% groups if necessary. The 'if necessary' condition means
            %% actually that these groups are put only when the list
            %% is (currently) not complete or it's malformed, that is,
            %% it cannot be expanded;
            %%
            CompoundRepManagerObject , block(DSpecialBlock)

            %%
            if
               MetaCompoundTermObject , hasCommas($) orelse
               MetaListTermObject , IsWFList($)
            then
               %%
               %% In addition to the case above, there is also a case
               %% when 'DrawSubterms' has put a ",,," group, but more
               %% subterms can be shown now (see the comment for the
               %% 'MetaCompoundTermObject::DrawSubterms');
               if
                  RestInc > 0 andthen
                  MetaCompoundTermObject , CanBeExpanded($) andthen
                  CompoundControlObject , mayContinue($)
               then
                  %% (Assertion: has commas!)
                  %%
                  %% Iterate. This iteration terminates because at
                  %% every step at least one further subterm is
                  %% added;
                  MetaListTermObject , expand(RestInc)
               else
                  %%
                  %% in both cases (there is a ",,," group *or* the
                  %% list is a well-formed one) there can be no
                  %% 'ltg';
                  if {self  HasLTG($)}
                  then
                     %% i.e. it was an incomplete list before;
                     {self  RemoveLTG}
                  end
               end

               %%
            else                % has no commas *and* is not well-formed;
               %%
               %% otherwise, we have to place an 'ltg';
               if {self  HasLTG($)}
               then
                  %%
                  %% if it is still an incomplete list, we replace the
                  %% "tail" term object *unconditionally*. This can be
                  %% an overkill when e.g. a tail variable is an open
                  %% record (but that's brain dead anyway, isn't it?)
                  CompoundRepManagerObject
                  , replaceTermG(fn:DSpecialBlock#DLTGroup term:@TailList)
               else
                  %% i.e. it was either shown partially (with a ",,,"
                  %% group), or it has to be shown the first time;
                  {self  CreateLTG(@TailList)}
               end
               %%
               %% ***** 'LTG' is created/updated *****

               %%
               %% ... and now, if the list *became* meanwhile expandable
               %% or well-formed:
               if
                  (MetaListTermObject , IsWFList($) orelse
                   MetaCompoundTermObject , CanBeExpanded($)) andthen
                  CompoundControlObject , mayContinue($)
               then
                  %%
                  %% ... just iterate again;
                  MetaListTermObject , expand(RestInc)
               end
            end

            %%
         end
      end

      %%
      %% 'MetaListTermObject' expects that the special block consists
      %% of these two groups - 'DDBarGroup' and 'DLTGroup';
      %%
      meth !RemoveLTG
         %%
         CompoundRepManagerObject
         , removeG(ln: DLTGroup)
         CompoundRepManagerObject
         , removeG(ln: DDBarGroup)
      end

      %%
      meth !HasLTG($)
\ifdef DEBUG_TO
         if CompoundRepManagerObject , getBlock($) \= DSpecialBlock
            {BrowserError 'MetaListTermObject::HasLTG: wrong block!'}
         end
\endif
         %%
         CompoundRepManagerObject
         , isGroup(b:DSpecialBlock ln:DLTGroup is:$)
      end

      %%
      %% ... probably, we have got it from the last 'var' subterm --
      %% so, the representation should be expanded instead of
      %% modifying that subterm;
      %%
      %% An assumption here is that if this is an "LTGroup", it is a
      %% variable, and will be just rebrowsed;
      meth subtermChanged(N)
\ifdef DEBUG_TO
         {Show 'MetaListTermObject::subtermChanged, self.term&N '
          # self.term # N}
\endif
         %%
         if N == DSpecialBlock#DLTGroup then MaxWidth CurrentSWidth in
            %%
            %% presumably we face a growth of the list;
            MaxWidth = {self.store read(StoreWidth $)}
            CurrentSWidth = MetaCompoundTermObject , getShownWidth($)

            %%
            %% either to draw new elements, or just replace 'ltg'
            %% by an ',,,' group (the difference can be negative,
            %% of course);
            MetaListTermObject , expand(MaxWidth - CurrentSWidth)
         else
            %%  fallback;
            MetaCompoundTermObject , subtermChanged(N)
         end
      end

      %%
   end

   %%
   %%
   %% Lists.
   %%
   %% These guys also support Prolog-notation (for "historical"
   %% reasons), but whenever they are applied they are checked to be
   %% well-formed (and complete).
   %%
   class ListTermObject from MetaListTermObject
                           %%
      feat
         type: T_List
         delimiter:  DSpaceGlue
         %% this indentation implies that there can be no glue in a first
         %% group (otherwise, if the representation manager subobject
         %% decides to make a compound glue, its size will be infinity -
         %% that's an error;);
         indentDesc: min('-'(st_indent(DMainBlock#1) self_indent) 5)

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'ListTermObject::makeTerm is applied' # self.term}
\endif
         %%
         MetaListTermObject , ListInit

         %%
         CompoundRepManagerObject , block(DLeadingBlock)
         CompoundRepManagerObject , putG_S(ln:DLSBraceGroup str:DLSBraceS)

         %%
         %% Expand the list "from scratch" :-)
         MetaListTermObject , expand({self.store read(StoreWidth $)})

         %%
         CompoundRepManagerObject , block(DTailBlock)
         CompoundRepManagerObject , putG_S(ln:DBraceGroup str:DRSBraceS)

         %%
      end

      %%
      %% It must yield a last element to be shown when a non-cons is
      %% found. Obviously, for well-formed lists there none;
      meth !GetLastElements(TL $) nil end

      %%
      %% Make a " || _" tail of an incomplete/malformed(cyclic) list;
      %%
      %% Note (again): That's not used now;
      %%
      meth !CreateLTG(TL)
         local DP Desc in
            %%
            DP = fun {$ _ CP LS} {LimitedTermSize TL CP LS} >= LS end
            Desc = '>'('+'(current st_size(DSpecialBlock#DLTGroup))
                       line_size)

            %%
            %% note that the insertion cursor is located at a right
            %% position now;
            CompoundRepManagerObject
            , putG_SGS(ln:   DDBarGroup
                       str:  self.delimiter
                       dp:   DBarDP
                       desc: DBarDesc
                       str2: DDBar)
            CompoundRepManagerObject
            , putG_SGT(ln:   DLTGroup
                       str:  self.delimiter
                       dp:   DP
                       desc: Desc
                       term: TL)

            %%
         end
      end

      %%
   end

   %%
   %%
   %% "Flat" cons cells.
   %% (also referred as ill-formed lists).
   %%
   %% The code is basically "replicated" from lists;
   %%
   class FConsTermObject from MetaListTermObject
                            %%
      feat
         type: T_List
         delimiter:  DVBarGlue
         indentDesc: min('-'(st_indent(DMainBlock#1) self_indent) 5)

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'FConsTermObject::makeTerm is applied' # self.term}
\endif
         %%
         MetaListTermObject , ListInit

         %%
         CompoundRepManagerObject , block(DLeadingBlock)

         %%
         FConsTermObject , expand({self.store read(StoreWidth $)})

         %%
         CompoundRepManagerObject , block(DTailBlock)

         %%
      end

      %%
      meth !GetLastElements(TL $)
         if TL == nil then ['nil'] else nil end
      end

      %%
      %% Make a "|{Var,Non-Var}" tail;
      meth !CreateLTG(TL)
         local DP Desc in
            %%
            DP = fun {$ _ CP LS} {LimitedTermSize TL CP LS} >= LS end
            Desc = '>'('+'(current st_size(DSpecialBlock#DLTGroup))
                       line_size)

            %%
            CompoundRepManagerObject
            , putG_E(ln:     DDBarGroup)     % just empty;
            CompoundRepManagerObject
            , putG_SGT(ln:   DLTGroup
                       str:  self.delimiter
                       dp:   DP
                       desc: Desc
                       term: TL)
         end
      end

      %%
   end

   %%
   %%
   %% Tuples;
   %%
   class TupleTermObject from MetaTupleTermObject
                            %%
      feat
         type: T_Tuple
         delimiter:  DSpaceGlue
         indentDesc: min('-'(st_indent(DMainBlock#1) self_indent) 3)

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'TupleTermObject::makeTerm is applied' # self.term}
\endif
         local Term SWidth TWidth in
            Term = self.term

            %%
            Elements <- {Record.toList Term}
            NotShownElements <- @Elements
            ShownWidth <- 0

            %%
            SWidth = {self.store read(StoreWidth $)}
            TWidth = {Width Term}

            %%
            %% put label and a leading '(', and go into the second block;
            CompoundRepManagerObject
            , block(DLeadingBlock)
            CompoundRepManagerObject
            , putG_S(ln:  DLabelGroup
                     str: {GenLitPrintName {Label Term} self.store})
            CompoundRepManagerObject
            , putG_S(ln:DLRBraceGroup str:DLRBraceS)

            %%
            TupleTermObject , expand({Max SWidth TWidth})

            %%
            CompoundRepManagerObject
            , block(DTailBlock)
            CompoundRepManagerObject
            , putG_S(ln:DBraceGroup str:DRRBraceS)

            %%
         end
      end

      %%
      meth expand(WidthInc)
         MetaCompoundTermObject , DrawSubterms(WidthInc)

         %%
         %% create an empty special block;
         CompoundRepManagerObject , block(DSpecialBlock)
      end

      %%
   end

   %%
   %%
   %% Hash tuples;
   %%
   %% Note that hash tuples cannot have a ",,," group (since a hash
   %% tuple is represented by Browser as a hash tuple only if it
   %% "fits" within the 'width' constraint);
   %%
   class HashTupleTermObject from MetaTupleTermObject
                                %%
      feat
         type: T_HashTuple
         delimiter:  DHashGlue
         indentDesc: min('-'(st_indent(DMainBlock#1) self_indent) 5)

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'HashTupleTermObject::makeTerm is applied' # self.term}
\endif
         local Term in
            Term = self.term

            %%
            Elements <- {Record.toList Term}
            NotShownElements <- @Elements
            ShownWidth <- 0

            %%
            CompoundRepManagerObject , block(DLeadingBlock)

            %%
            HashTupleTermObject , expand({Width Term})

            %%
            CompoundRepManagerObject , block(DTailBlock)

            %%
         end
      end

      %%
      meth expand(WidthInc)
         MetaCompoundTermObject , DrawSubterms(WidthInc)

         %%
         CompoundRepManagerObject , block(DSpecialBlock)
      end

      %%
   end

%%%
%%%
%%%  Records in various flavours;
%%%
%%%

   %%
   %% These things are "record"-generic, that is, they are common for
   %% both records and chunks.
   %%
   %% An invariant is that 'elements' are feature names;
   %%
   class MetaRecordTermObject from MetaCompoundTermObject
                                 %%
      feat
         delimiter:  DSpaceGlue
         indentDesc: min('-'(st_indent(DMainBlock#2)
                             '+'(gr_size(DMainBlock#1) self_indent))
                         3)

         %%
         %% It draws both a feature name and a subterm under it;
      meth !DrawElement
         local
            T Store NewWidth CurrentLastGroup FN PrFN PrFNSize
            ST NewNotShownElements DP Desc
         in
            T = self.term
            Store = self.store
            @NotShownElements = FN|NewNotShownElements
            ST = T.FN
            NewWidth = @ShownWidth + 1
            CurrentLastGroup = @ShownWidth * 2

            %%
            PrFN = {GenLitPrintName FN Store}
            PrFNSize = {VirtualString.length PrFN}

            %%
            %% there are two styles of record filling:
            %% (a) a solid one, - similar to tuples, and
            %% (b) an 'expanded' one, called 'record fields aligned'.
            %%
            if
               case {Store read(StoreFillStyle $)}
               of !Expanded then true
               [] !Filled then false
               else
                  {BrowserError 'invalid fill style!'}
                  false
               end
            then                % expanded (the default);
               %%
               %% ... just check either the whole term fits;
               DP = fun {$ SI _ LS} {LimitedTermSize T SI LS} >= LS end
               Desc = '>'('+'(self_indent self_size) line_size)
            else                % filled;
               %%
               %%
               %% That's a ~hack: the size of an "fn:st" is replaced
               %% by the size of a hash-tuple "fn#st" :-))
               local RT in
                  RT = FN#ST
                  DP = fun {$ _ CP LS} {LimitedTermSize RT CP LS} >= LS end
               end

               %%
               Desc = '>'('+'('+'(current (DSpace + PrFNSize))
                              st_size(DMainBlock#(CurrentLastGroup+2)))
                          line_size)
            end

            %%
            %% first - a group containing a feature name and a glue,
            %% and after that - a glueless group with a subtree. Of
            %% course, it's also possible to make the second group
            %% "glueful", but i don't know whether it's necessary;
            CompoundRepManagerObject
            , if NewWidth == 1 then
                 putG_GS(ln:       (CurrentLastGroup + 1)
                         dp:       DP
                         desc:     Desc
                         str:      PrFN#DColonS)
              else
                 putG_SGS(ln:       (CurrentLastGroup + 1)
                          str:      self.delimiter
                          dp:       DP
                          desc:     Desc
                          str2:     PrFN#DColonS)
              end
            CompoundRepManagerObject
            , putG_T(ln:       (CurrentLastGroup + 2)
                     term:     ST)

            %%
            NotShownElements <- NewNotShownElements
            ShownWidth <- NewWidth
         end
      end

      %%
   end

   %%
   %%
   %% Records;
   %%
   class RecordTermObject from MetaRecordTermObject
                             %%
      feat
         type:  T_Record
         RLabel

         %%
      attr
         HasDetLabel: false

         %%
         %% this is the "simplest" case - no transformations;
      meth !GetName($)
         local L in
            L = self.RLabel

            %%
            %% Note that this can be also OFS (yet) without a label -
            %% reflect it non-monotonically;
            if {IsVar L} then {System.printName L}
            else
               HasDetLabel <- true
               {GenLitPrintName L self.store}
            end
         end
      end

      %%
      %%
      meth IsProperOFS($)
         %%
         %%  the point here is that it it's a variable, it can be
         %% only an OFS (due to the construction principle);
         {IsVar self.term}
      end

      %%
      %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'RecordTermObject::makeTerm is applied' # self.term}
\endif
         local Term Store in
            %%
            Term = self.term
            Store = self.store

            %%
            %% *First* set a watchpoint!
            %%
            %% It must "watch" all changes that happen while a
            %% representation is build up;
            RecordTermObject , SetWatchPoint

            %%
            self.RLabel = if {HasLabel Term} then {Label Term}
                          else thread {Label Term} end
                          end

            %%
            %% a label;
            CompoundRepManagerObject
            , block(DLeadingBlock)
            CompoundRepManagerObject
            , putG_S(ln:DLabelGroup str:{self GetName($)})
            CompoundRepManagerObject
            , putG_S(ln:DLRBraceGroup str: DLRBraceS)

            %%
            %% 'MonitorArity' yields a closed list if the record is
            %% closed;
            local KillP
            in
               Elements <- {RecordC.monitorArity Term KillP}
               thread {Wait self.closed} {KillP} end
            end
            NotShownElements <- @Elements
            ShownWidth <- 0

            %% ... "from scratch";
            RecordTermObject , expand({Store read(StoreWidth $)})

            %%
            CompoundRepManagerObject
            , block(DTailBlock)
            CompoundRepManagerObject
            , putG_S(ln:DBraceGroup str:DRRBraceS)

            %%
         end
      end

      %%
      %% Note that 'GetElement' is not redefined here since that's
      %% just a 'MonitorArity' output, and it cannot be malformed;

      %%
      %% Approximates the property (see the comments for the
      %% 'ListTermObject::IsWFList');
      meth IsClosedRecord($)
         %%
         if {IsVar @NotShownElements} then false
         else @NotShownElements == nil
         end
      end

      %%
      meth HasEllipses($)
\ifdef DEBUG_TO
         if CompoundRepManagerObject , getBlock($) \= DSpecialBlock
            {BrowserError
             'MetaCompoundTermObject::hasEllipses: wrong block!'}
         end
\endif
         %%
         CompoundRepManagerObject
         , isGroup(b:DSpecialBlock ln:DEllipsesGroup is:$)
      end

      %%
      %% It draws further subterms, and after that it checks whether
      %% a '...' group must be here;
      %%
      %% This is very similar to the 'ListTermObject::expand', so it
      %% does make sense to look at that and read comments there;
      %%
      meth expand(WidthInc)
\ifdef DEBUG_TO
         {Show 'RecordTermObject::expand is applied' # self.term}
\endif
         %%
         MetaCompoundTermObject , DrawSubterms(WidthInc)

         %%
         %% now, check the '...' group;
         CompoundRepManagerObject , block(DSpecialBlock)

         %%
         if
            MetaCompoundTermObject , hasCommas($) orelse
            RecordTermObject , IsClosedRecord($)
         then
            %%
            %% no '...' group;
            if RecordTermObject , HasEllipses($) then
               %%
               CompoundRepManagerObject , removeG(ln: DEllipsesGroup)
            end

            %%
         else           % has no commas *and* is not yet closed;
            %%
            if RecordTermObject , HasEllipses($) then skip
            else
               %%
               %% note that the insertion cursor is located at a
               %% right position now;
               CompoundRepManagerObject
               , putG_SGS(ln:   DEllipsesGroup
                          str:  DSpaceGlue
                          dp:   EllipsesDP
                          desc: EllipsesDesc
                          str2: DOpenFS)

               %%
            end
            %%
            %% ***** Ellipses have been created if necessary *****

            %%
            %% ... but now, all the changes that could take place
            %% "inbetween", are covered by a (new!) watchpoint
            %% already sitting on the (OFS) term!
            %%
            %% Note that the same trick does not work for lists since
            %% their "tail" element is not known at the beginning
            %% (therefore, one cannot set a watchpoint on it!);
            %%
         end
      end

      %%
      %% Set a 'watchpoint';
      %% Two things can basically happen: it gets further subterms,
      %% or it gets bound to some other record (probably an open
      %% one). Note that both can be watched just by means of the
      %% 'GetsToched';
      %%
      %% A "first" watchpoint is set by the 'makeTerm', and "further"
      %% ones - by the code placed in 'SetWatchPoint' itself;
      %%
      meth !SetWatchPoint
\ifdef DEBUG_TO
         {Show 'RecordTermObject::SetWatchPoint: ' # self.term}
\endif
         %%
         if RecordTermObject , IsProperOFS($) then ObjClosed ChVar in
            %%
            ObjClosed = self.closed
            ChVar = {GetsTouched self.term}

            %%
            %% Note that this conditional may not block the state;
            thread
               {WaitOr ChVar ObjClosed}
               if {IsDet ChVar} then {self checkTermReq}
               end
            end

            %%
            if @HasDetLabel then skip
            else ObjClosed GotLabel in
               ObjClosed = self.closed

               %%
               thread
                  {WaitOr self.RLabel ObjClosed}
                  if {IsDet GotLabel} then {self checkTermReq}
                  end
               end
            end
         else skip              % nothing to do - it's a proper record;
         end
      end

      %%
      %% A local method which checks whether something has happend
      %% with it *meanwhile*;
      meth checkTerm
\ifdef DEBUG_TO
         {Show 'RecordTermObject::checkTerm: ' # self.term}
\endif
         %%
         %% "Zeroth": set a new watchpoint.  Note that setting a new
         %% watchpoint is going ahead (like in the 'makeTerm' too). Of
         %% course, some overhead can arise when the 'self' will be
         %% closed soon, but: who cares?
         RecordTermObject , SetWatchPoint

         %%
         %% First, check the label:
         if @HasDetLabel orelse {IsVar self.RLabel} then skip
         else
            CompoundRepManagerObject
            , block(DLeadingBlock)
            CompoundRepManagerObject
            , removeG(ln:DLRBraceGroup)
            CompoundRepManagerObject
            , removeG(ln:DLabelGroup)
            CompoundRepManagerObject
            , putG_S(ln:DLabelGroup str:{self GetName($)})
            CompoundRepManagerObject
            , putG_S(ln:DLRBraceGroup str: DLRBraceS)
         end

         %%
         %% First, take a shortcut: if there is a ',,,' group,
         %% nothing must be done here (except setting up a new
         %% watchpoint, what is done in 'SetWatchPoint');
         if MetaCompoundTermObject , hasCommas($) then skip
         else
            %%
            %% The term could get coreferenced by some other term;
            if {self  isCoreferenced($)}
            then
               %%
               %% This method enqueues a request for the 'checkTerm'
               %% method - which will be (eventually, if object is not
               %% closed until then) processed later;
               ControlObject , rebrowse
            else MaxWidth CurrentSWidth in
               %%
               %% otherwise, just try to expand it;
               MaxWidth = {self.store read(StoreWidth $)}
               CurrentSWidth = MetaCompoundTermObject , getShownWidth($)

               %%
               RecordTermObject , expand(MaxWidth - CurrentSWidth)
            end
         end

         %%
         %% Note that 'expand' does not handle the case when an OFS
         %% "looses" features. This a non-monotonic, meta-kernel
         %% functionality which is not available for "typical" Oz
         %% programmers. In order to cope with this possibility, one
         %% could try to access all the feature names already
         %% instantiated in a MonitorArity's output, and if there are
         %% ones that are *not* feature names any more - just rebrowse
         %% everything, or what else ...
         %%
         %% %% Key-syllables:
         %% %%   featur loos remov delet throw eras
      end

      %%
   end

%%%
%%%
%%% Chunks;
%%%
%%%

   %%
   class CompChunkTermObject from MetaRecordTermObject
                                %%
      feat
         type: T_CompChunk

         %%
         %% ... can be overloaded;
      meth !GetName($)
         {GenChunkPrintName self.term self.store}
      end

      %%
      %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'CompChunkTermObject::makeTerm is applied' # self.term}
\endif
         local Term Store NF FullArity in
            %%
            Term = self.term
            Store = self.store
            NF = {Store read(StoreArityType $)} == NoArity

            %%
            FullArity = {ChunkArity Term}
            Elements <- if NF then nil else FullArity end
            NotShownElements <- @Elements
            ShownWidth <- 0

            %%
            %% a label;
            CompoundRepManagerObject
            , block(DLeadingBlock)
            CompoundRepManagerObject
            , putG_S(ln:DLabelGroup str:{self GetName($)})
            CompoundRepManagerObject
            , putG_S(ln:DLRBraceGroup str: DLRBraceS)

            %% ... "from scratch";
            CompChunkTermObject , expand({Store read(StoreWidth $)})

            %%
            %% The presense of the '?' is decided once, and here:
            CompoundRepManagerObject
            , block(DTailBlock)
            CompoundRepManagerObject
            , putG_S(ln:  DBraceGroup
                     str: if
                             NF andthen
                             {Length @Elements} \= {Length FullArity}
                          then DUnshownPFs#DRRBraceS
                          else DRRBraceS
                          end)

            %%
         end
      end

      %%
      %% there is nothing else to do except to draw elements :-)
      meth expand(WidthInc)
\ifdef DEBUG_TO
         {Show 'CompChunkTermObject::expand is applied' # self.term}
\endif
         %%
         MetaCompoundTermObject , DrawSubterms(WidthInc)

         %%
         CompoundRepManagerObject , block(DSpecialBlock)
      end

      %%
   end

   %%
   %%
   %% Compound objects;
   %%
   class CompObjectTermObject from CompChunkTermObject
                                 %%
      feat
         type: T_CompObject

         %%
      meth !GetName($)
         {GenObjPrintName self.term self.store}
      end

      %%
   end

   %%
   %%
   %% Compoumd classes;
   %%
   class CompClassTermObject from CompChunkTermObject
                                %%
      feat
         type: T_CompClass

         %%
      meth !GetName($)
         {GenClassPrintName self.term self.store}
      end

      %%
   end

%%%
%%%
%%%  Special terms;
%%%
%%%

   %%
   %%
   class I_MetaVariableTermObject from MetaTermObject
                                     %%

                                     %%
                                     %% can be overloaded, if necessary;
      meth !GetName($)
         AreExpVarNames = {self.store read(StoreExpVarNames $)}
         PN = {System.printName self.term}
      in
         if AreExpVarNames then
            PN # if {Value.isNeeded self.term} then '<needed>'
                 else '<quiet>'
                 end
         else PN
         end
      end

      %%
      %%  ... can be also overloaded;
      meth !GetWatchFun($) GetsTouched end

      %%
      %% The default 'checkTerm' is kept (rebrowsing). Note that no
      %% new watchpoint is ever needed in this case;
      %%

      %%
      %% Set a 'watchpoint';
      %%
      %% Note that it should be installed before building a
      %% representation has begun;
      %%
      meth !SetWatchPoint
\ifdef DEBUG_TO
         {Show 'I_MetaVariableTermObject::SetWatchPoint: ' # self.term}
\endif
         local WatchFun ObjClosed ChVar in
            %%
            WatchFun = {self  GetWatchFun($)}

            %%
            ObjClosed = self.closed
            ChVar = {WatchFun self.term}

            %%
            %% Note that this conditional may not block the state;
            thread
               {WaitOr ChVar ObjClosed}
               if {IsDet ChVar} then
                  {self checkTermReq}
               end
            end

         end
      end

      %%
   end

   %%
   %% Variables;
   %%
   class VariableTermObject from I_MetaVariableTermObject
                               %%
      feat
         type: T_Variable

         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'VariableTermObject::makeTerm is applied' # self.term}
\endif
         %%
         %% *First*, set a watchpoint;
         I_MetaVariableTermObject , SetWatchPoint

         %%
         RepManagerObject , insert(str: {self GetName($)})
      end

      %%
   end

   %%
   %% Futures
   %%
   class FutureTermObject from I_MetaVariableTermObject
                               %%
      feat
         type: T_Future


      meth !GetName($)
         {System.printName self.term}#'<Future>'
      end

      meth !GetWatchFun($)
         proc {$ F ?U}
            thread
               {Value.waitQuiet F}
               U=unit
            end
         end
      end

      meth makeTerm
\ifdef DEBUG_TO
         {Show 'FutureTermObject::makeTerm is applied' # self.term}
\endif
         %%
         %% *First*, set a watchpoint;
         I_MetaVariableTermObject , SetWatchPoint

         %%
         RepManagerObject , insert(str: {self GetName($)})
      end

      %%
   end

   %%
   %% Failed values
   %%
   class FailedTermObject from I_MetaVariableTermObject
                               %%
      feat
         type: T_Failed


      meth !GetName($)
         {System.printName self.term}#'<Failed value>'
      end

      meth makeTerm
\ifdef DEBUG_TO
         {Show 'FailedTermObject::makeTerm is applied' # self.term}
\endif
         %% raph: no watchpoint needed here

         %%
         RepManagerObject , insert(str: {self GetName($)})
      end

      %%
   end

   %%
   %%
   %% Finite domain variables;
   %%
   class FDVariableTermObject from I_MetaVariableTermObject
                                 %%
      feat
         type: T_FDVariable

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'FDVariableTermObject::makeTerm is applied' # self.term}
\endif
         %%
         I_MetaVariableTermObject , SetWatchPoint

         %%
         local Term SubInts Le DomComp Name in
            Term = self.term

            %%
            DomComp = {FD.reflect.dom Term}
            Le = {Length DomComp}
            SubInts = {Tuple.make '#' Le}

            %%
            {List.forAllInd DomComp
             %%
             proc {$ Num Interval}
                local Tmp in
                   Tmp = case Interval of L#H then L#"#"#H
                         else Interval
                         end

                   %%
                   if Num == 1 then SubInts.1 = Tmp
                   else SubInts.Num = " "#Tmp
                   end
                end
             end}

            %%
            Name = {self GetName($)} # DLCBraceS # SubInts # DRCBraceS

            %%
            RepManagerObject , insert(str: Name)
         end
      end

      %%
   end

   %%
   %%
   %% Finite set variables;
   %%
   class FSetTermObject from I_MetaVariableTermObject
                           %%
      feat
         type: T_FSet

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'FSetTermObject::makeTerm is applied' # self.term}
\endif
         %%
         if {IsDet self.term}
         then % FSetValue
            Term Comp Le SubInts Name
         in
            Term = self.term

            %%
            Comp = {FSetGetGlb Term}
            Le = {Length Comp}
            SubInts = {Tuple.make '#' Le}

            %%
            {List.forAllInd Comp
             %%
             proc {$ Num Interval}
                local Tmp in
                   Tmp = case Interval of L#H then L#"#"#H
                         else Interval
                         end

                   %%
                   if Num == 1 then SubInts.1 = Tmp
                   else SubInts.Num = " "#Tmp
                   end
                end
             end}

            %%
            Name = (DLCBraceS # SubInts # DRCBraceS # "#" # {FSetGetCard Term})

            %%
            RepManagerObject , insert(str: Name)
         else
            I_MetaVariableTermObject , SetWatchPoint

            %%
            local
               Term GlbComp LubComp GlbLe LubLe GlbSubInts LubSubInts Name Card
            in
               Term = self.term

               %%
               GlbComp = {FSetGetGlb Term}
               LubComp = {FSetGetLub Term}
               GlbLe = {Length GlbComp}
               LubLe = {Length LubComp}
               GlbSubInts = {Tuple.make '#' GlbLe}
               LubSubInts = {Tuple.make '#' LubLe}

               %%
               {List.forAllInd GlbComp
                %%
                proc {$ Num Interval}
                   local Tmp in
                      Tmp = case Interval of L#H then L#"#"#H
                            else Interval
                            end

                      %%
                      if Num == 1 then GlbSubInts.1 = Tmp
                      else GlbSubInts.Num = " "#Tmp
                      end
                   end
                end}
               {List.forAllInd LubComp
                %%
                proc {$ Num Interval}
                   local Tmp in
                      Tmp = case Interval of L#H then L#"#"#H
                            else Interval
                            end

                      %%
                      if Num == 1 then LubSubInts.1 = Tmp
                      else LubSubInts.Num = " "#Tmp
                      end
                   end
                end}

               %%
               Card = case {FSetGetCard Term}
                      of L#U then DLCBraceS # L # "#" # U # DRCBraceS
                      [] C then C
                      end

               Name = ({self GetName($)} # DLCBraceS # DLCBraceS #
                       GlbSubInts # DRCBraceS # DDblPeriod # DLCBraceS #
                       LubSubInts # DRCBraceS # DRCBraceS # "#" # Card)

               %%
               RepManagerObject , insert(str: Name)
            end
         end
      end
      %%
   end

   %%
   %%
   %% generic constraint variables;
   %%
   class CtVariableTermObject from I_MetaVariableTermObject
                                 %%
      feat
         type: T_CtVariable

         %%
         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'CtVariabelTermObject::makeTerm is applied' # self.term}
\endif
         %%
         I_MetaVariableTermObject , SetWatchPoint

         %%
         local
            Constraint ConstraintName Name Term
         in
            Term = self.term

            %%
            Constraint = {GetCtVarConstraintAsAtom Term}

            %%
            ConstraintName = {GetCtVarNameAsAtom Term}

            %%
            Name =
            {self GetName($)} #
            DLABraceS # ConstraintName # DColonS # Constraint # DRABraceS

            %%
            RepManagerObject , insert(str: Name)
         end
      end
      %%
   end

%%%
%%%
%%%  Unknown terms;
%%%
%%%

   %%
   class UnknownTermObject from MetaTermObject
                              %%
      feat
         type: T_Unknown

         %%
      meth makeTerm
\ifdef DEBUG_TO
         {Show 'UnknownTermObject::makeTerm is applied' # self.term}
\endif
         %%
         RepManagerObject , insert(str: '<UNKNOWN TERM>')
      end

      %%
   end

   %%
end
