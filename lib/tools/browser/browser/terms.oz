%  Programming Systems Lab, DFKI Saarbruecken,
%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5337
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  'term' term classes;
%%%  I.e. here all constraint system- depended things are performed
%%  (like 'get a type of a given term', 'parse a term', etc.);
%%%
%%%


local
   MetaTupleTermTermObject
   MetaRecordTermTermObject
   MetaChunkTermTermObject

   %%
   GetListType

   %%
   IsVirtualString

   %%
   StripName
   StripBQuotes
   GenVSPrintName
   GenAtomPrintName
   GenNamePrintName
   GenVarPrintName
   GenChunkPrintName
   GenObjPrintName
   GenClassPrintName
   GenProcPrintName
   GenCellPrintName

   %%
   SelSubTerms
   IsListDepth

   %%
   TestVarFun
   TestFDVarFun
   TestMetaVarFun

   %%
   GetWFListVar

   %%
   AtomicFilter

   %%
   IsThereAName
in

%%%
%%%
%%%  Various local auxiliary procedures;
%%%
   %%
   local
      %%
      %%
      [ZeroChar] = "0"
      %%
      fun {OctString I}
         [(I div 64) mod 8 + ZeroChar
          (I div 8)  mod 8 + ZeroChar
          I mod 8 + ZeroChar]
      end
   in
      %%
      local
         SetTab       = {MakeTuple tab 255}
         ScanTab      = {MakeTuple tab 255}
         SubstTab     = {MakeTuple tab 255}

         %%
         {Record.forAllInd SetTab
          fun {$ I}
             case {Char.isAlNum I} then legal
             elsecase [I] of "_"   then legal
             elsecase {Char.isCntrl I} then
                subst(case [I]
                      of "\a" then "\\a"
                      [] "\b" then "\\b"
                      [] "\f" then "\\f"
                      [] "\n" then "\\n"
                      [] "\r" then "\\r"
                      [] "\t" then "\\t"
                      [] "\v" then "\\v"
                      else {Append "\\" {OctString I}}
                      end)
             elsecase I =< 255 andthen 127 =< I then
                subst({Append "\\" {OctString I}})
             elsecase [I] of "'" then
                subst("\\\'")
             elsecase [I] of "\\" then
                subst("\\\\")
             else illegal
             end
          end}

         %%
         ScanTab  = {Record.map SetTab fun {$ T} {Label T} end}
         SubstTab = {Record.map SetTab
                     fun {$ T}
                        case {IsAtom T} then nil else T.1 end
                     end}

         %%
         %% Check whether atom needs to be quoted and expand quotes in string
         fun {Check Is NeedsQuoteYet ?NeedsQuote}
            case Is of nil then
               NeedsQuote = NeedsQuoteYet
               nil
            [] I|Ir then
               case ScanTab.I
               of legal   then I|{Check Ir NeedsQuoteYet ?NeedsQuote}
               [] illegal then I|{Check Ir True ?NeedsQuote}
               [] subst   then
                  {Append SubstTab.I {Check Ir True ?NeedsQuote}}
               end
            end
         end
         %%
      in
         %%
         fun {GenAtomPrintName Atom}
            case Atom of '' then "\'\'"
            else
               Is={AtomToString Atom}
               NeedsQuote
               Js={Check Is {Bool.'not' {Char.isLower Is.1}} ?NeedsQuote}
            in
               case NeedsQuote then "'"#Js#"'" else Js end
            end
         end

         %%
         fun {GenVarPrintName Atom}
            case Atom
            of '\`\`' then "\`\`"
            [] nil then '_'     % ad'hoc;
            else
               Is = {AtomToString Atom}
            in
               {Check Is {Bool.'not' {Char.isUpper Is.1}} _}
            end
         end
      end

      %%
      %%
      local
         SetTab       = {MakeTuple tab 256}
         SubstTab     = {MakeTuple tab 256}
         ScanTab      = {MakeTuple tab 256}

         %%
         {Record.forAllInd SetTab
          fun {$ J} I=J-1 in
             case {Char.isCntrl I} then
                subst(case [I]
                      of "\a" then "\\a"
                      [] "\b" then "\\b"
                      [] "\f" then "\\f"
                      [] "\n" then "\\n"
                      [] "\r" then "\\r"
                      [] "\t" then "\\t"
                      [] "\v" then "\\v"
                      else {Append "\\" {OctString I}}
                      end)
             elsecase I =< 255 andthen 127 =< I then
                subst({Append "\\" {OctString I}})
             else
                case [I] of "\"" then subst("\\\"")
                elsecase [I] of "\\" then subst("\\\\")
                else legal
                end
             end
          end}

         %%
         ScanTab  = {Record.map SetTab fun {$ T} {Label T} end}
         SubstTab = {Record.map SetTab
                     fun {$ T}
                        case {IsAtom T} then "" else T.1 end
                     end}

         %%
         fun {QuoteString Is}
            case Is of nil then nil
            [] I|Ir then J=I+1 in
               case ScanTab.J
               of legal   then I|{QuoteString Ir}
               [] subst   then {Append SubstTab.J {QuoteString Ir}}
               end
            end
         end

         %%
         proc {HashVS I V1 V2}
            V2.I={GenVS V1.I}
            case I>1 then {HashVS I-1 V1 V2} else true end
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
               [] '#' then W={Width V} V2={MakeTuple '#' W} in
                  {HashVS W V V2} V2
               end
            end
         end
      in
         %%
         fun {GenVSPrintName V}
            '"'#{GenVS V}#'"'
         end
      end
   end

   %%
   %%
   %%  Extract a 'meaningful' part of a temporary name;
   local ParseFun in
      fun {ParseFun I CI E}
         case E of !CNameDelimiter then I else CI end
      end

      %%
      fun {StripName IStr}
         local Pos in
            Pos = {List.foldLInd IStr ParseFun 0}

            %%
            case Pos of 0 then IStr else {Head IStr Pos-1} end
         end
      end
   end

   %%
   %%
   fun {StripBQuotes IStr}
      case IStr of nil then nil
      else
         case IStr.1 of !BQuote then {StripBQuotes IStr.2}
         else IStr.1|{StripBQuotes IStr.2}
         end
      end
   end

   %%
   %%  Generate a printname for a name;
   proc {GenNamePrintName Term Store ?Name}
      local AreSmallNames PN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         PN = {System.getPrintName Term}

         %%
         Name =
         case AreSmallNames then
            case PN
            of '' then '<N>'
            [] '_' then '<N>'
            else
               SPNS SSPNS
            in
               SPNS = {StripName {Atom.toString PN}}

               %%
               case SPNS.1 of !BQuote then
                  SSPNS = {StripName {StripBQuotes SPNS}}

                  %%
                  case SSPNS of nil then '<N>'
                  else '<N: `' # SSPNS # '`>'
                  end
               else '<N: ' # SPNS # '>'
               end
            end
         else
            %%
            case PN of '' then
               '<Name @ ' # {System.getValue Term addr} # '>'
            else
               '<Name: ' # PN # ' @ ' # {System.getValue Term addr} # '>'
            end
         end
      end
   end

   %%
   %%
   %%  Generate a chunk's print name;
   proc {GenChunkPrintName Term Store ?Name}
      local AreSmallNames in
         AreSmallNames = {Store read(StoreSmallNames $)}

         %%
         Name = case AreSmallNames then '<Ch>'
                else '<' # {System.getPrintName Term} # '>'
                end
      end
   end

   %%
   %%
   %%  Generate an object's print name;
   proc {GenObjPrintName Term Store ?Name}
      local AreSmallNames PN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         PN = {Class.printName {Class.get Term}}

         %%
         Name =
         case AreSmallNames then
            case PN
            of '' then '<O>'
            [] '_' then '<O>'
            else
               PNS SN
            in
               PNS = {Atom.toString PN}

               %%
               case PNS.1 of !BQuote then
                  SN = {StripName {StripBQuotes PNS}}

                  %%
                  case SN of nil then '<O>'
                  else '<O: `' # SN # '`>'
                  end
               else '<O: ' # PN # '>'
               end
            end
         else
            %%
            case PN of '_' then
               '<Object @ ' # {System.getValue Term addr} # '>'
            else
               '<Object: ' # PN # ' @ ' # {System.getValue Term addr} # '>'
            end
         end
      end
   end

   %%
   %%
   %%  Generate an class's print name;
   proc {GenClassPrintName Term Store ?Name}
      local AreSmallNames PN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         PN = {Class.printName Term}

         %%
         Name =
         case AreSmallNames then
            case PN
            of '' then '<C>'
            [] '_' then '<C>'
            else
               PNS SN
            in
               PNS = {Atom.toString PN}

               %%
               case PNS.1 of !BQuote then
                  SN = {StripName {StripBQuotes PNS}}

                  %%
                  case SN of nil then '<C>'
                  else '<C: `' # SN # '`>'
                  end
               else '<C: ' # PN # '>'
               end
            end
         else
            %%
            case PN of '_' then
               '<Class @ ' # {System.getValue Term addr} # '>'
            else
               '<Class: ' # PN # ' @ ' # {System.getValue Term addr} # '>'
            end
         end
      end
   end

   %%
   %%
   %%  Generate a procedure's print name;
   proc {GenProcPrintName Term Store ?Name}
      local AreSmallNames PN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         PN = {Procedure.printName Term}

         %%
         Name =
         case AreSmallNames then
            case PN
            of '' then '<P/' # {Procedure.arity Term} # '>'
            [] '_' then '<P/' # {Procedure.arity Term} # '>'
            else
               PNS SN
            in
               PNS = {Atom.toString PN}

               %%
               case PNS.1 of !BQuote then
                  SN = {StripName {StripBQuotes PNS}}

                  %%
                  case SN of nil then
                     '<P/' # {Procedure.arity Term} # '>'
                  else
                     '<P/' # {Procedure.arity Term} # ' `' # SN # '`>'
                  end
               else
                  '<P/' # {Procedure.arity Term} # ' ' # PN # '>'
               end
            end
         else
            %%
            '<Procedure: ' # PN # '/' # {Procedure.arity Term} #
            ' @ ' # {System.getValue Term addr} # '>'
         end
      end
   end

   %%
   %%
   %%  Generate a cell's print name;
   proc {GenCellPrintName Term Store ?Name}
      local AreSmallNames CN in
         AreSmallNames = {Store read(StoreSmallNames $)}
         CN = {System.getPrintName Term}

         %%
         Name =
         case AreSmallNames then
            case CN
            of '' then '<Cell>'
            [] '_' then '<Cell>'
            else
               PNS SN
            in
               PNS = {Atom.toString CN}

               %%
               case PNS.1 of !BQuote then
                  SN = {StripName {StripBQuotes PNS}}

                  %%
                  case SN of nil then '<C>'
                  else '<Cell: `' # SN # '`>'
                  end
               else '<Cell: ' # CN # '>'
               end
            end
         else
            %%
            '<Cell: ' # {System.getValue Term name} # '>'
         end
      end
   end

   %%
   %%
   %%  'Watch' procedures;
   %%
   fun {TestVarFun Var}
      {GetsBound Var}
   end

   %%
   %%
   fun {TestFDVarFun FDVar Card}
      local ChFDDom GotBound in
         job
            ChFDDom = {WatchDomain FDVar Card}
         end
         %%
         job
            GotBound = {GetsBound FDVar}
         end

         %%
         if ChFDDom = True then True
         [] GotBound = True then True
         end
      end
   end

   %%
   %%
   fun {TestMetaVarFun MetaVar Strength}
      local ChMetaVar GotBound in
         job
            ChMetaVar = {WatchMetaVar MetaVar Strength}
         end
         %%
         job
            GotBound = {GetsBound MetaVar}
         end

         %%
         if ChMetaVar = True then True
         [] GotBound = True then True
         end
      end
   end

   %%
   %%
   %%  GetListType;
   %%  'Store' is the parameters store, 'AreBraces' says whether this list
   %% should be exposed in braces or not, 'Attr' gets the 'InitValue' or the
   %% tail variable if the type is T_FList or T_BFList;
   fun {GetListType List Store}
      local Depth IsLD in
         Depth = {Store read(StoreNodeNumber $)}

         %%
         job
            IsLD = {IsListDepth List Depth}
         end

         %%
         case
            case {IsVar IsLD} then False
            else IsLD
            end
         then T_WFList
         else
            AreFLists
         in
            AreFLists = {Store read(StoreFlatLists $)}

            %%
            case AreFLists then T_FList
            else T_List
            end
         end
      end
   end

   %%
   %%  Note: that's not a function!
   fun {IsListDepth L D}
      case D > 0 then
         %% 'List.is' exactly;

         %%
         case L
         of _|Xr then {IsListDepth Xr (D-1)}
         else L == nil
         end
      else L == nil
      end
   end

   %%
   %%
   %%  Flat representation of incomplete lists;
   %%  Extract subterms and a trailing variable from given list;
   %%
   local
      DoInfList IsCyclicListDepth DoCyclicList
      GetBaseList GetListAndVar
   in
      %%
      %%  A 'new edition' of the 'IsCyclicList';
      %%  We consider simply the limited number of list constructors;

      %%
      fun {DoInfList Xs Ys Depth}
         case Depth > 0 then
            %% more efficient in one flat guard;
            if Xr Yr in Xs=_|Xr Ys=_|_|Yr then
               %%
               case {EQ Xr Yr} then True
               else {DoInfList Xr Yr (Depth-1)}
               end
            else False
            end
         else False
         end
      end

      %%
      fun {IsCyclicListDepth Xs Depth}
         case Xs of X|Xr then
            {DoInfList Xs Xr (Depth + Depth + 1)}
         end
      end

      %%
      proc {SelSubTerms List Store ?Subterms ?Var}
         local Depth Corefs Cycles in
            {Store [read(StoreNodeNumber Depth)
                    read(StoreCheckStyle Corefs)
                    read(StoreOnlyCycles Cycles)]}

            %%
            case Corefs orelse Cycles then
               IsCLD
            in
               job
                  IsCLD = {IsCyclicListDepth List Depth}
               end

               %%
               case
                  case {IsVar IsCLD} then False
                  else IsCLD
                  end
               then
                  {DoCyclicList List nil ?Subterms}
                  Var = InitValue
               else             % non-cyclic OR not yet instantiated;
                  {GetListAndVar List Depth Subterms Var}
               end
            else {GetListAndVar List Depth Subterms Var}
            end
         end
      end

      %%
      proc {DoCyclicList List Stack ?Subterms}
         local LS in
            %%
            case {GetBaseList List Stack Stack LS}
            then Subterms = LS
            else {DoCyclicList List.2 List|Stack ?Subterms}
            end
         end
      end

      %%
      proc {GetListAndVar List Depth ?Subterms ?Var}
         case Depth > 0 then
            case {IsVar List} then
               Subterms = [List]
               Var = List
            elsecase List
            of H|R then
               NS in
               Subterms = H|NS
               {GetListAndVar R (Depth - 1) NS Var}
            else
               Subterms = [List]
               Var = InitValue
            end
         else
            Subterms = [List]
            Var = InitValue
         end
      end

      %%
      %% 'False' if no recursion was detected;
      fun {GetBaseList List Stack SavedStack ?BaseList}
         case Stack
         of nil then False
         else
            %%
            case {EQ List {Subtree Stack 1}} then
               case Stack.2
               of nil then
                  %% i.e. the cycle begins from the first list constructor;
                  BaseList = {Append {Map {Reverse SavedStack}
                                      fun {$ E} E.1 end} [List]}
                  True
               else
                  BaseList = {Append {Map {Reverse Stack.2}
                                      fun {$ E} E.1 end} [List]}
                  True
               end
            else
               {GetBaseList List Stack.2 SavedStack ?BaseList}
            end
         end
      end

      %%
   end

   %%
   %%
   %%  ... used for open feature constraints browsing;
   proc {GetWFListVar LIn ?WFL ?Var}
      %%
      %%
      case {IsVar LIn} then
         WFL = nil
         Var = LIn
      elsecase LIn
      of E|R then
         WFL = E|{GetWFListVar R $ Var}
      [] nil then
         WFL = nil
         Var = InitValue
      else                      % ???
         {BrowserWarning ['Error in "GetWFListVar"?']}
         %%
         WFL = nil
         Var = LIn
      end
   end

   %%
   %%  Filter for chunks arity;
   fun {AtomicFilter In}
      case In
      of E|R then
         case {IsAtom E} then E|{AtomicFilter R}
         else {AtomicFilter R}
         end
      else nil
      end
   end

   %%
   %%  Yields 'True' if there is a name;
   fun {IsThereAName In}
      case In
      of E|R then
         case {IsName E} then True
         else {IsThereAName R}
         end
      else False
      end
   end

   %%
   %%  cut&paste ;-[
   local
      fun {IsAllB I V}
         I==0 orelse ({IsVirtualString V.I} andthen {IsAllB I-1 V})
      end
   in
      fun {IsVirtualString X}
         case {IsVar X} then False
         elsecase {Value.type X}
         of atom then True
         [] int then True
         [] float then True
         [] tuple then
            case {Label X}
            of '#' then {IsAllB {Width X} X}
            [] '|' then {IsString X}
            else False
            end
         else False
         end
      end
   end

   %%
   %%  'Meta' 'term' term object;
   %%
   class MetaTermTermObject
      from UrObject
      %%

      %%
      %%  Returns a type of given term;
      %%  'Term' is a term to be investigated, 'Self' is 'self' of
      %% calling object, and 'NumberOf' is the sequential number of a given
      %% subterm (our types are not context-free);
      %%
      meth getTermType(Term NumberOf ?Type)
\ifdef DEBUG_TT
         {Show 'MetaTermTermObject::getTermType: ...'}
\endif
         Type =
         case
            @depth > 1 andthen {self.termsStore canCreateObject($)}
         then
            case {IsVar Term} then
               IsCVar
            in
               %% non-monotonic operation;
               job
                  IsCVar = {RecordC.is Term}
               end

               %%
               case {IsRecordCVar Term}  then T_ORecord
               elsecase {IsFdVar Term}   then T_FDVariable
               elsecase {IsMetaVar Term} then T_MetaVariable
               else T_Variable
               end
            else
               case {Value.type Term}
               of atom    then T_Atom
               [] int     then T_Int
               [] float   then T_Float
               [] name    then T_Name
               [] tuple   then AreVSs in
                  AreVSs = {self.store read(StoreAreVSs $)}

                  %%
                  case AreVSs == True andthen {IsVirtualString Term}
                  then T_Atom
                  else
                     case Term
                     of _|_ then
                        case self.type
                        of !T_List then
                           case NumberOf
                           of 2 then T_List
                              %%  i.e. this is not-well-formed list;
                           else {GetListType Term self.store}
                           end
                        else {GetListType Term self.store}
                        end
                     else
                        case
                           case {Label Term}
                           of '#' then {Width Term} > 1
                           else False
                           end
                        then T_HashTuple
                        else T_Tuple
                        end
                     end
                  end

               [] procedure then T_Procedure
               [] cell then T_Cell
               [] record then T_Record

               [] chunk then
                  case {Object.is Term} then T_Object
                  elsecase {Class.is Term} then T_Class
                  else T_Chunk  % TODO! arrays and dictionaries;
                  end

               else
                  {BrowserWarning ['Oz Term of unknown type: ' Term]}
                  T_Unknown
               end
            end
         else
            T_Shrunken
         end
      end

      %%
      %%  Yields 'True' if referenced 'self' (i.e. 'RN=<term>')
      %% should be enclosed in (round) braces (i.e. '(RN=<term>)');
      meth needsBracesRef(?Needs)
\ifdef DEBUG_TT
         {Show 'MetaTermTermObject::needsBracesRef: ...'}
\endif
         Needs = case self.parentObj.type
                 of !T_PSTerm     then False
                 [] !T_Atom       then False
                 [] !T_Int        then False
                 [] !T_Float      then False
                 [] !T_Name       then False
                 [] !T_Procedure  then False
                 [] !T_Cell       then False
                 [] !T_Chunk      then False
                 [] !T_Object     then False
                 [] !T_Class      then False
                 [] !T_WFList     then False
                 [] !T_Tuple      then False
                 [] !T_Record     then False
                 [] !T_ORecord    then False
                 [] !T_List       then True
                 [] !T_FList      then True
                 [] !T_HashTuple  then True
                 [] !T_Variable   then False
                 [] !T_FDVariable then False
                 [] !T_MetaVariable then False
                 [] !T_Shrunken   then False
                 [] !T_Reference  then False
                 [] !T_Unknown    then False
                 else
                    {BrowserWarning
                     ['Unknown type in TermObject::needsBracesRef: '
                        self.parentObj.type]}
                    False
                 end
      end

      %%
      %%
      meth genLitPrintName(Lit ?PName)
         PName = case {IsAtom Lit} then {GenAtomPrintName Lit}
                 else {GenNamePrintName Lit self.store}
                 end
      end

      %%
      %%
      meth genFeatPrintName(FN ?PName)
         PName = case {IsAtom FN} then {GenAtomPrintName FN}
                 elsecase {IsName FN} then {GenNamePrintName FN self.store}
                 else FN
                 end
      end

      %%
      %%  default 'areCommas' - there are no commas;
      meth areCommas(?AreCommas)
         AreCommas = False
      end

      %%
   end

   %%
   %%
   %%  Atoms;
   %%
   class AtomTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;

      %%
      %%  We need 'setName' here and for 'RecordTermTermObject', since
      %% it's redefined for chunk objects;
      %%
      meth setName
         local AreVSs Name in
            AreVSs = {self.store read(StoreAreVSs $)}
            %%
            Name = case AreVSs then {GenVSPrintName self.term}
                   else {GenAtomPrintName self.term}
                   end

            %%
            % {Wait Name}
            %%
            self.name = Name
            <<UrObject nil>>
         end
      end

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'AtomTermTermObject::initTerm is applied'#self.term}
\endif
         <<setName>>
      end
   end

   %%
   %%
   %%  Procedures;
   %%
   class ProcedureTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;

      %%
      %%
      meth setName
         self.name = {GenProcPrintName self.term self.store}
      end

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'ProcedureTermTermObject::initTerm is applied'#self.term}
\endif
         <<setName>>
      end

      %%
   end

   %%
   %%
   %%  Cells;
   %%
   class CellTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;

      %%
      %%
      meth setName
         self.name = {GenCellPrintName self.term self.store}
      end

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'CellTermTermObject::initTerm is applied'#self.term}
\endif
         <<setName>>
      end

      %%
   end

   %%
   %%
   %%  Integers;
   %%
   class IntTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'IntTermTermObject::initTerm is applied'#self.term}
\endif
         local AreVSs Name in
            AreVSs = {self.store read(StoreAreVSs $)}
            %%
            Name = case AreVSs then {GenVSPrintName self.term}
                   else {VirtualString.changeSign self.term "~"}
                   end

            %%
            % {Wait Name}
            %%
            self.name = Name
            <<UrObject nil>>
         end
      end
   end

   %%
   %%
   %%  Floats;
   %%
   class FloatTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'FloatTermTermObject::initTerm is applied'#self.term}
\endif
         local AreVSs Name in
            AreVSs = {self.store read(StoreAreVSs $)}
            %%
            Name = case AreVSs then {GenVSPrintName self.term}
                        else {VirtualString.changeSign self.term "~"}
                        end

            %%
            % {Wait Name}
            %%
            self.name = Name
            <<UrObject nil>>
         end
      end
   end

   %%
   %%
   %%  Names;
   %%
   class NameTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'NameTermTermObject::initTerm is applied'#self.term}
\endif
         local Term Name in
            Term = self.term
            %%
            Name = case {Bool.is Term} then
                      case Term then "<B: true>" else "<B: false>" end
                   else {GenNamePrintName Term self.store}
                   end

            %%
            % {Wait Name}
            %%
            self.name = Name
            <<UrObject nil>>
         end
      end
   end

   %%
   %%
   %%  Generic compound (tuple-like) objects;
   %%
   class MetaTupleTermTermObject
      from MetaTermTermObject
      %%
      %%
      %%  Create additional subterm objects from the number StartNum;
      %%  This is implemented for flat lists and open feature structures;
      %%
      %%  'StartNum' is the number of the first new subterm;
      %%  'NumReuse' is the number of subterms those slots (subterm records)
      %% can be reused (typically one, since by extension we remove only
      %% a tail variable);
      %%
      meth initMoreSubterms(StartNum NumReuse SubsList ?EndNum)
\ifdef DEBUG_TT
         {Show 'MetaTupleTermTermObject::initMoreSubterms '#
          self.term#StartNum#NumReuse#SubsList}
\endif
         local SWidth TWidth NumOfNew in
            SWidth = {self.store read(StoreWidth $)}
            TWidth = {Length SubsList} + StartNum - 1

            %%
            case SWidth < TWidth then
               %%
               NumOfNew = SWidth - StartNum + 1 - NumReuse

               %%
               case NumOfNew > 0 then
                  %% we have really to add something;
                  EndNum = SWidth

                  %%
                  <<addSubterms(NumOfNew)>>
               else
                  %%  actual width is bigger than initially allowed
                  %% (because manual expansions);
                  EndNum = StartNum - 1 + NumReuse

                  %%
                  %%  Note that this covers both cases
                  %% -  no subterms should be created
                  %%      (from StartNum-1 to startNum);
                  %% -  'NumReuse' subterms should be re-created;
                  %%
               end

               %%
               <<createSubtermObjs(StartNum EndNum SubsList)>>
            else
               EndNum = TWidth

               %%
               NumOfNew = TWidth - StartNum + 1 - NumReuse
               case NumOfNew > 0 then <<addSubterms(NumOfNew)>>
               else true
               end

               %%
               <<createSubtermObjs(StartNum TWidth SubsList)>>
            end
         end
      end
   end

   %%
   %%
   %%  Well-formed lists;
   %%
   class WFListTermTermObject
      from MetaTupleTermTermObject TupleSubtermsStore
      %%
      feat
         name                   % print name;

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'WFListTermTermObject::initTerm is applied'#self.term}
\endif
         %%
         self.name = ''

         %%
         local SWidth TWidth in
            SWidth = {self.store read(StoreWidth $)}
            TWidth = {Length self.term}

            %%
            case SWidth < TWidth then
               <<subtermsStoreInit(SWidth True)>>

               %% commas;
               <<createSubtermObjs(1 SWidth self.term)>>
            else
               <<subtermsStoreInit(TWidth False)>>

               %%
               <<createSubtermObjs(1 TWidth self.term)>>
            end
         end
      end

      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = self.term
      end

      %%
      %%
      meth reGetSubterms(?Subterms)
         Subterms = self.term
      end

      %%
   end

   %%
   %%
   %%  Tuples;
   %%
   class TupleTermTermObject
      from MetaTupleTermTermObject TupleSubtermsStore
      %%
      feat
         name                   % print name;
         subterms               % list of subterms;

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'TupleTermTermObject::initTerm is applied'#self.term}
\endif
         local Term Store Subterms SWidth TWidth in
            Term = self.term
            Store = self.store

            %%
            self.name = <<genLitPrintName({Label Term} $)>>
            Subterms = {Record.toList Term}
            self.subterms = Subterms

            %%
            SWidth = {Store read(StoreWidth $)}
            TWidth = {Width Term}

            %%
            case SWidth < TWidth then
               <<subtermsStoreInit(SWidth True)>>

               %% commas;
               <<createSubtermObjs(1 SWidth Subterms)>>
            else
               <<subtermsStoreInit(TWidth False)>>

               %%
               <<createSubtermObjs(1 TWidth Subterms)>>
            end
         end
      end

      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = self.subterms
      end

      %%
      %%
      meth reGetSubterms(?Subterms)
         Subterms = self.subterms
      end

      %%
   end

   %%
   %%
   %%  Lists;
   %%
   class ListTermTermObject
      %%
      %%  Actually, it could be implemented more efficiently -
      %% when the functionality of 'TupleSubtermsStore' is encoded
      %% directly in this class;
      from MetaTupleTermTermObject TupleSubtermsStore
      %%
      feat
         subterms               % list of subterms;

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'ListTermTermObject::initTerm is applied'#self.term}
\endif
         local Term Subterms  in
            Term = self.term

            %%
            Subterms = [Term.1 Term.2]
            self.subterms = Subterms

            %%  the width is always 2;
            <<subtermsStoreInit(2 False)>>

            %%
            <<createSubtermObjs(1 2 Subterms)>>
         end
      end

      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = self.subterms
      end

      %%
      %%
      meth reGetSubterms(?Subterms)
         Subterms = self.subterms
      end

      %%
   end

   %%
   %%
   %%  Hash tuples;
   %%
   class HashTupleTermTermObject
      from MetaTupleTermTermObject TupleSubtermsStore
      %%
      feat
         subterms               % list of subterms;

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'HashTupleTermTermObject::initTerm is applied'#self.term}
\endif
         local Term Subterms SWidth TWidth in
            Term = self.term

            %%
            Subterms = {Record.toList Term}
            self.subterms = Subterms

            %%
            SWidth = {self.store read(StoreWidth $)}
            TWidth = {Width Term}

            %%
            case SWidth < TWidth then
               <<subtermsStoreInit(SWidth True)>>

               %% commas;
               <<createSubtermObjs(1 SWidth Subterms)>>
            else
               <<subtermsStoreInit(TWidth False)>>

               %%
               <<createSubtermObjs(1 TWidth Subterms)>>
            end
         end
      end

      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = self.subterms
      end

      %%
      %%
      meth reGetSubterms(?Subterms)
         Subterms = self.subterms
      end

      %%
   end

   %%
   %%
   %%  Flat lists;
   %%
   class FListTermTermObject
      from MetaTupleTermTermObject TupleSubtermsStore
      %%
      %%
      attr
         subterms               % list of subterms;
         tailVar                % 'tail' variable, if any;
                                % it contains *always* it, even if it's currently
                                % not shown!
         tailVarNum             % number of 'tail' variable subterm, if any -
                                % in the case when it's currently shown;
      %%  Note that 'subterms' is an *attribute* here;

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'FListTermTermObject::initTerm is applied'#self.term}
\endif
         local Term Store Subterms TailVar SWidth TWidth in
            Term = self.term
            Store = self.store

            %%
            %%  get subterms and a tail variable, if any;
            {SelSubTerms Term Store Subterms TailVar}
            subterms <- Subterms
            tailVar <- TailVar

            %%
            SWidth = {Store read(StoreWidth $)}
            TWidth = {Length Subterms}

            %%
            case SWidth < TWidth then
               <<subtermsStoreInit(SWidth True)>>

               %% commas;
               <<createSubtermObjs(1 SWidth Subterms)>>

               %%
               tailVarNum <- ~1
            else
               <<subtermsStoreInit(TWidth False)>>

               %%
               <<createSubtermObjs(1 TWidth Subterms)>>

               %%
               %% relational;
               case TailVar
               of !InitValue then
                  tailVarNum <- ~1
               [] _ then
                  tailVarNum <- TWidth
               end
            end
         end
      end

      %%
      %%  special: set the 'tailVarNum' attribute;
      %% ('reGetSubterms' should be already called;)
      meth initMoreSubterms(StartNum NumReuse SubsList ?EndNum)
         <<MetaTupleTermTermObject
         initMoreSubterms(StartNum NumReuse SubsList EndNum)>>

         %%
         <<setTailVarNum(EndNum)>>
      end

      %%
      %%  Sets 'tailVarNum' properly;
      meth setTailVarNum(OccNum)
         local TailVar in
            TailVar = @tailVar

            %% relational;
            case TailVar
            of !InitValue then
               tailVarNum <- ~1
            [] _ then
               local Obj in
                  Obj = <<getSubtermObj(OccNum $)>>

                  %% relational;
                  case Obj.term
                  of !TailVar then
                     tailVarNum <- OccNum
                  [] _ then
                     tailVarNum <- ~1
                  end
               end
            end
         end
      end

      %%
      %%
      meth noTailVar
         tailVarNum <- ~1
         %%
\ifdef DEBUG_TT
         case @tailVar
         of !InitValue then true
         [] _ then
            {BrowserError ['FListTermTermObject::noTailVar: error!']}
         end
\endif
      end

      %%
      %%
      meth isWFList(?IsWF)
\ifdef DEBUG_TT
         {Show 'FListTermTermObject::isFWList is applied'#self.term}
\endif
         local Depth IsWFInt in
            Depth = {self.store read(StoreNodeNumber $)}

            %%
            job
               IsWFInt = {IsListDepth self.term Depth}
            end

            %%
            IsWF = case {IsVar IsWFInt} then False
                   else IsWFInt
                   end
         end
      end

      %%
      %%
      meth getSubterms(?Subterms)
\ifdef DEBUG_TT
         {Show 'FListTermTermObject::getSubterms is applied'#self.term}
\endif
         Subterms = @subterms
      end

      %%
      %%  updates 'subterms' and 'tailVar' in place;
      meth reGetSubterms(?Subterms)
\ifdef DEBUG_TT
         {Show 'FListTermTermObject::reGetSubterms is applied'#self.term}
\endif
         local TailVar in
            {SelSubTerms self.term self.store Subterms TailVar}

            %%
            subterms <- Subterms
            tailVar <- TailVar
         end
      end

      %%
   end

   %%
   %%
   %%  Generic compound (record-like) objects;
   %%
   class MetaRecordTermTermObject
      from MetaTupleTermTermObject
      %%
      feat
         name                   % print name;
         recArity               % list of features;
      %%  Note that 'recArity' is an incomplete list for open feature
      %% structures;

      %%
      %%
      attr
         subterms               % list of subterms;
         recFeatures            % tuple of the same arity which contains
                                % record's features;
      %%  'subterms' and 'recFeatures' is an attribute, since the number
      %% of features change over time for open feature structures;
      %%
   end

   %%
   %%
   %%  Records;
   %%
   class RecordTermTermObject
      from MetaRecordTermTermObject RecordSubtermsStore
      %%
      %%  We need 'setName' here and for 'AtomTermTermObject',
      %% since it is redefined for chunks (see further);

      %%
      %%
      meth setName
         self.name = <<genLitPrintName({Label self.term} $)>>
      end

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'RecordTermTermObject::initTerm is applied'#self.term}
\endif
         local
            AF AreSpecs Term Subterms Store RecArity
            RecFeatures SWidth TWidth
         in
            %%
            Store = self.store
            Term = self.term

            %%
            AF = case {Store read(StoreArityType $)}
                 of !AtomicArity then True
                 [] !TrueArity then False
                 else
                    {BrowserError
                     ['RecordTermTermObject::initTerm: invalid type of ArityType']}
                    False
                 end

            %%
            <<setName>>

            %%
            RecArity = case {Chunk.is Term} then
                          TmpArity
                       in
                          TmpArity = {`ChunkArity` Term}
                          %%
                          case AF then {AtomicFilter TmpArity}
                          else TmpArity
                          end
                       else {Arity Term}
                       end
            self.recArity = RecArity

            %%  'Subtree' is used because `.` behavior for cells;
            Subterms = {Map RecArity proc {$ F S} {Subtree Term F S} end}
            subterms <- Subterms

            %%
            TWidth = {Length RecArity}
            RecFeatures = {MakeTuple recFeatures TWidth}
            {FoldL RecArity fun {$ I E} RecFeatures.I = E (I + 1) end 1 _}

            %%
            recFeatures <- RecFeatures

            %%
            SWidth = {Store read(StoreWidth $)}

            %%
            AreSpecs = case {Chunk.is Term} then
                          case AF then
                             %% suboptimal - get the arity again...
                             TWidth \= {Length {`ChunkArity` Term}}
                             %% only atomic features;
                          else False
                          end
                       else False
                       end

            %%
            case SWidth < TWidth then
               <<subtermsStoreInit(SWidth True AreSpecs)>>
               %%
               <<createSubtermObjs(1 SWidth Subterms)>>
            else
               <<subtermsStoreInit(TWidth False AreSpecs)>>
               %%
               <<createSubtermObjs(1 TWidth Subterms)>>
            end
         end
      end

      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = @subterms
      end

      %%
      %%
      meth reGetSubterms(?Subterms)
         Subterms = @subterms
      end

      %%
   end

   %%
   %%
   %%  Open feature structures;
   %%
   class ORecordTermTermObject
      from MetaRecordTermTermObject RecordSubtermsStore
      %%
      feat
         label                  % == {LabelC self.term $}

      %%
      attr
         name                   % for '_';
         tailVar                % tail variable in the list of features;
         CancelReq              %
         PrivateFeature         % == True if there is a private feature;

      %%
      %%
      meth setName
         name <- <<genLitPrintName({System.getPrintName self.label} $)>>
      end

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'ORecordTermTermObject::initTerm is applied'#self.term}
\endif
         local
            RecArity Term OFSLab Subterms Store SWidth TWidth AreSpecs
            SelfClosed
         in
            %%
            Store = self.store
            Term = self.term

            %%
            %%  This *must* be a job, and *not* a thread!
            job
               OFSLab = {LabelC self.term}
            end
            self.label = OFSLab

            %%
            SelfClosed = self.closed

            %%
            case {IsVar OFSLab} then
               %%
               thread
                  GotLabel GotClosed
               in
                  job
                     GotLabel = {IsValue OFSLab}
                  end
                  %%
                  job
                     GotClosed = {IsValue SelfClosed}
                  end

                  %%
                  if GotLabel = True then {self replaceLabel}
                  [] GotClosed = True then true
                     %% cancel watching;
                  end
               end
            else true
            end

            %%
            <<setName>>
            self.name = @name   % just some value - it should not be used here;
            %%
            %%  incomplete list;
            %% {RecordC.monitorArity X K L}
            %%
            %% Constrains X to a record.  "Eagerly" constrains L to a list of all
            %% features of X, in some order. The order of the features will be "the
            %% order in which they arrive", as far as this is determined.  The list
            %% will contain an unbound tail as long as X is undetermined, and a nil
            %% tail when X is determined.
            %%
            %% The above definition is correct if K is undetermined.  Operationally,
            %% determining K removes the propagator and closes the list L.  The list
            %% then contains all features in X at the moment K is determined.  If
            %% called with K determined, the propagator returns a sorted list of the
            %% features existing in X at the moment of the call.  L is unaffected by
            %% any changes to X that occur after K becomes determined.
            %%
            %% Peter
            %%
            %%  This *must* be a job, and *not* a thread!
            job
               RecArity = {RecordC.monitorArity Term SelfClosed}
            end

            %%
            PrivateFeature <- False

            %%
            self.recArity = RecArity

            %%
            <<reGetSubterms(Subterms)>>

            %%
            TWidth = {Width @recFeatures}
            SWidth = {Store read(StoreWidth $)}

            %%
            AreSpecs = <<isProperOFS($)>>

            %%
            case SWidth < TWidth then
               <<subtermsStoreInit(SWidth True AreSpecs)>>
               %%
               <<createSubtermObjs(1 SWidth Subterms)>>
            else
               <<subtermsStoreInit(TWidth False AreSpecs)>>
               %%
               <<createSubtermObjs(1 TWidth Subterms)>>
            end
         end
      end

      %%
      %%
      meth isProperOFS(?Is)
         %% relational;
         Is = case @tailVar
              of !InitValue then False
              [] _ then True
              end
\ifdef DEBUG_TT
         {Show 'ORecordTermTermObject::isProperOFS: '#Is}
\endif
      end

      %%
      %%
      meth getSubterms(?Subterms)
         Subterms = @subterms
      end

      %%
      %%
      meth reGetSubterms(?Subterms)
         local Term TmpArity KnownArity TailVar RecFeatures in
            Term = self.term

            %%
            {GetWFListVar self.recArity TmpArity TailVar}

            %%  filter out already non-existing features -
            %%  cheers, Peter! ;-)
            {FoldL TmpArity
             fun {$ I E}
                %% PIC;
                if Vp in {SubtreeC Term E _} then
                   I = E|Vp Vp
                [] true then I
                end
             end
%  The following doesn't work because 'TestC' fails if
% the record is determined (why ??!);
%            fun {$ I E}
%               case {TestC Term E} then
%                  Vp
%               in
%                  I = E|Vp Vp
%               else I
             KnownArity nil}

            %%
            %%  it could be 'InitValue' (if OFS has become a proper record
            %% already;)
            tailVar <- TailVar

            %%
            Subterms = {Map KnownArity proc {$ F S} {SubtreeC Term F S} end}
            subterms <- Subterms

            %%
            RecFeatures = {MakeTuple recFeatures {Length KnownArity}}
            {FoldL KnownArity fun {$ I E} RecFeatures.I = E (I + 1) end 1 _}
            recFeatures <- RecFeatures
         end
      end

      %%
      %%  Set a 'watchpoint';
      %%  It should be used when the (sub)term is actually drawn;
      meth initTypeWatching
\ifdef DEBUG_TT
         {Show 'ORecordTermTermObject::initTypeWatching: '#self.term}
\endif
         %%
         %%  Note that it covers also the case when 'tailVar' gets bound
         %% meanwhile;
         case <<isProperOFS($)>> then
            Term Depth TailVar CancelVar SpecsObj
            GotValue ChVar OFSWidth ChWidth
         in
            %%
            Term = self.term
            Depth = @depth
            TailVar = @tailVar
            CancelReq <- CancelVar
            SpecsObj = <<getSpecsObjOutInfo($ _)>>

            %%
            job
               GotValue = {IsValue TailVar}
            end
            %%
            job
               ChVar = {TestVarFun Term}
            end
            %%  should work without job...end too;
            job
               OFSWidth = {WidthC Term}
            end
            job
               ChWidth = {IsValue OFSWidth}
            end

            %% Note that this conditional should not block the state;
            %% relational;
            job
               %%
               %% test: {SpecsObj drawOFSWidth(5)}
               if GotValue = True then
                  %%
                  {self extend}
               [] ChVar = True then
                  %%
                  case {self.termsStore checkCorefs(self $)} then
                     %% gets bound somehow;
                     {self.parentObj renewNum(self Depth)}
                  else
                     %%  wait for a 'TailVar';
                     {self initTypeWatching}
                  end
               [] ChWidth = True then
                  {SpecsObj drawOFSWidth(OFSWidth)}

                  %%
                  %%  it has got a record probably...
                  {self extend}
               [] CancelVar = True then true
               end
            end
         else true              % nothing to do - it's a proper record;
         end
      end

      %%
      %%  ... it should be used by 'undraw';
      meth stopTypeWatching
\ifdef DEBUG_TT
         {Show 'ORecordTermTermObject::stopTypeWatching: '#self.term}
\endif
         %%
         @CancelReq = True
      end

      %%
      %%
      meth setHiddenPFs
         Depth
      in
         PrivateFeature <- True
         Depth = @depth

         %%
         case <<isProperOFS($)>> then
            <<addQuestion>>
         else
            %%  I'm lazy - I tell you :))
            job
               {self.parentObj renewNum(self Depth)}
            end
         end
      end

      %%
   end

   %%
   %%  Generic chunks (not only, though) objects;
   %%
   class MetaChunkTermTermObject
      from AtomTermTermObject RecordTermTermObject
      %%
      feat
         isCompound             % 'True' if there are any subterms;
      %%

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'MetaChunkTermTermObject::initTerm is applied'#self.term}
\endif
         case {Length {`ChunkArity` self.term}} == 0 then
            self.isCompound = False
            <<AtomTermTermObject initTerm>>
         else
            self.isCompound = True
            <<RecordTermTermObject initTerm>>
         end
      end

      %%
      %%
      meth getSubterms(?Subterms)
         case self.isCompound then
            <<RecordTermTermObject getSubterms(Subterms)>>
         else
            %% should produce an error message;
            <<AtomTermTermObject getSubterms(Subterms)>>
         end
      end

      %%
      %%
      meth reGetSubterms(?Subterms)
         case self.isCompound then
            <<RecordTermTermObject reGetSubterms(Subterms)>>
         else
            %% should produce an error message;
            <<AtomTermTermObject reGetSubterms(Subterms)>>
         end
      end

      %%
      %%
      meth areCommas(?Are)
         case self.isCompound then
            <<RecordTermTermObject areCommas(Are)>>
         else
            <<AtomTermTermObject areCommas(Are)>>
         end
      end
      %%
      %%
   end

   %%
   %%
   %%
   %%  Generic Chunks;
   %%
   class ChunkTermTermObject
      from MetaChunkTermTermObject
      %%

      %%
      meth setName
         self.name = {GenChunkPrintName self.term self.store}
      end

      %%
   end

   %%
   %%
   %%  Objects;
   %%
   class ObjectTermTermObject
      from MetaChunkTermTermObject
      %%

      %%
      %%
      meth setName
         self.name = {GenObjPrintName self.term self.store}
      end

      %%
   end

   %%
   %%  Classes;
   %%
   class ClassTermTermObject
      from MetaChunkTermTermObject
      %%

      %%
      %%
      meth setName
         self.name = {GenClassPrintName self.term self.store}
      end

      %%
   end

   %%
   %%
   %%  Special terms;
   %%
   %%  Variables;
   %%
   class VariableTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;

      %%
      attr
         CancelReq              % watching is cancelled when it gets bound;

      %%
      %%
      meth getVarName(?Name)
         Name = {GenVarPrintName {System.getPrintName self.term}}
      end

      %%
      %%  Yields 'True' if it is still an (unconstrained!) variable;
      %%
      meth checkIsVar(?Is)
         local Term in
            Term = self.term
            %%
            %%  There could happen just everything: gets a value or
            %% some other (derived) type of variables;

            Is = case {IsVar Term} then
                    case {IsRecordCVar Term} then False
                    elsecase {IsFdVar Term} then False
                    elsecase {IsMetaVar Term} then False
                    else True
                    end
                 else False
                 end
         end
      end

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'VariableTermTermObject::initTerm is applied'#self.term}
\endif
         local Name in
            %%
            Name = <<getVarName($)>>

            %%
            % {Wait Name}
            %%
            self.name = Name
            <<UrObject nil>>
         end
      end

      %%
      %%  Set a 'watchpoint';
      %%  It should be used when the (sub)term is actually drawn;
      meth initTypeWatching
\ifdef DEBUG_TT
         {Show 'VariableTermTermObject::initTypeWatching: '#self.term}
\endif
         local
            CancelVar Depth NewName OldNameStr NewNameStr ChVar
         in
            %%
            Depth = @depth
            CancelReq <- CancelVar

            %%
            job
               ChVar = {TestVarFun self.term}
            end

            %% Note that this conditional may not block the state;
            %% relational;
            job
               if ChVar = True then
                  {self.parentObj renewNum(self Depth)}
               [] CancelVar = True then true
               end
            end

            %%
            %%  Check #1: is it still an (unconstrained) variable at all??
            case <<checkIsVar($)>> then
               %%
               %%  Check #2: the printname (for the case when one variable
               %% is bound to another one);
               NewName = <<getVarName($)>>
               OldNameStr = {VirtualString.toString self.name}
               NewNameStr = {VirtualString.toString NewName}

               %%
               case {DiffStrs OldNameStr NewNameStr} then
                  %%
                  job
                     {self.parentObj renewNum(self Depth)}
                  end
               else true
               end
            else
               %%
               job
                  {self.parentObj renewNum(self Depth)}
               end
            end
         end
      end

      %%
      %%  ... it should be used by 'undraw';
      meth stopTypeWatching
\ifdef DEBUG_TT
         {Show 'VariableTermTermObject::stopTypeWatching: '#self.term}
\endif
         %%
         @CancelReq = True
      end

      %%
   end

   %%
   %%
   %%  Finite domain variables;
   %%
   class FDVariableTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;
         card                   % actual domain size;

      %%
      attr
         CancelReq              % watching is cancelled when it gets bound;

      %%
      %%
      meth getVarName(?Name)
         Name = {GenVarPrintName {System.getPrintName self.term}}
      end

      %%
      %%  Yields 'True' if it is still a FD variable;
      %%
      meth checkIsVar(?Is)
         %%
         %%  There could happen only one thing: it can get a value;
         %%
         Is = {IsVar self.term}
      end

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'FDVariableTermTermObject::initTerm is applied'#self.term}
\endif
         local Term ThPrio SubIntsL SubInts Le DomComp Name in
            Term = self.term

            %%
            ThPrio = {Thread.getPriority}

            %%
            %%  Since the watchpoint on an FD variable is set currently
            %% on its cardinality, getting the cardinality must go ahead!
            self.card = {FD.reflect.size Term}

            %%
            DomComp = {FD.reflect.dom Term}

            %%
            {List.mapInd DomComp
             %%
             fun {$ Num Interval}
                local Tmp in
                   Tmp = case Interval of L#H then L#"#"#H
                         else Interval
                         end

                   %%
                   case Num
                   of 1 then Tmp
                   else " "#Tmp
                   end
                end
             end
             SubIntsL}

            %%
            Le = {Length SubIntsL}
            SubInts = {MakeTuple '#' Le}
            {Loop.for 1 Le 1 proc {$ I} SubInts.I = {Nth SubIntsL I} end}

            %%
            %%  first subterm in hash-tuple must be a variable name!
            %% (see beneath in :initTypeWatching;)
            Name = <<getVarName($)>>#DLCBraceS#SubInts#DRCBraceS

            %%
            % {Wait Name}
            %%
            self.name = Name
            <<UrObject nil>>
         end
      end

      %%
      %%  Set a 'watchpoint';
      %%  It should be used when the (sub)term is actually drawn;
      meth initTypeWatching
\ifdef DEBUG_TT
         {Show 'FDVariableTermTermObject::initTypeWatching: '#self.term}
\endif
         local
            CancelVar Depth NewName OldNameStr NewNameStr ChFDVar
         in
            %%
            Depth = @depth
            CancelReq <- CancelVar

            %%
            job
               ChFDVar = {TestFDVarFun self.term self.card}
            end

            %%
            %% Note that this conditional may not block the state;
            job
               if ChFDVar = True then
                  {self.parentObj renewNum(self Depth)}
               [] CancelVar = True then true
               end
            end

            %%  Check #1: is it still a FD variable at all??
            case <<checkIsVar($)>> then
               %%
               %%  Check #2: the printname (for the case when one variable
               %% is bound to another one);
               NewName = <<getVarName($)>>
               OldNameStr = {VirtualString.toString self.name.1}
               NewNameStr = {VirtualString.toString NewName}

               %%
               case {DiffStrs OldNameStr NewNameStr} then
                  %%
                  job
                     {self.parentObj renewNum(self Depth)}
                  end
               else true
               end
               %%
            else
               %%
               job
                  {self.parentObj renewNum(self Depth)}
               end
            end
         end
      end

      %%
      %%  ... it should be used by 'undraw';
      meth stopTypeWatching
\ifdef DEBUG_TT
         {Show 'FDVariableTermTermObject::stopTypeWatching: '#self.term}
\endif
         %%
         @CancelReq = True
      end

      %%
   end

   %%
   %%
   %%  Meta variables;
   %%
   class MetaVariableTermTermObject
      from MetaTermTermObject
      %%
      feat
         name                   % print name;
         strength               % actual strength of constraint at this var;

      %%
      attr
         CancelReq              % watching is cancelled when it gets bound;

      %%
      %%
      meth getVarName(?Name)
         Name = {GenVarPrintName {System.getPrintName self.term}}
      end

      %%
      %%  Yields 'True' if it is still a metavariable;
      %%
      meth checkIsVar(?Is)
         %%
         %%  There could happen only one thing: it can get a value;
         %%
         IsVar = {IsVar self.term}
      end

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'MetaVariableTermTermObject::initTerm is applied'#self.term}
\endif
         local Term ThPrio Data MetaName Name in
            Term = self.term

            %%
            ThPrio = {Thread.getPriority}

            %%
            %%  Must go ahead ... see the comment for FD variables;
            self.strength = {MetaGetStrength Term}

            %%
            Data = {MetaGetDataAsAtom Term}

            %%
            MetaName = {MetaGetNameAsAtom Term}

            %%
            %%  first subterm in hash-tuple must be a variable name!
            %% (see beneath in :initTypeWatching;)
            Name = <<getVarName($)>>#'<'#MetaName#':'#Data#'>'
\ifdef DEBUG_METAVAR
            {Show ['Data'#Data 'MetaName'#MetaName
                   'self.strength'#self.strength 'Name'#Name]}
\endif

            %%
            % {Wait Name}
            %%
            self.name = Name
            <<UrObject nil>>

            %%
\ifdef DEBUG_METAVAR
            {Show 'self.name'#self.name}
\endif
         end
      end

      %%
      %%  Set a 'watchpoint';
      %%  It should be used when the (sub)term is actually drawn;
      meth initTypeWatching
\ifdef DEBUG_TT
         {Show 'MetaVariableTermTermObject::initTypeWatching: '#self.term}
\endif
         local
            CancelVar Depth NewName OldNameStr NewNameStr ChMetaVar
         in
            %%
            Depth = @depth
            CancelReq <- CancelVar

            %%
            job
               ChMetaVar = {TestMetaVarFun self.term self.strength}
            end

            %%
            %% Note that this conditional may not block the state;
            job
               if ChMetaVar = True then
                  {self.parentObj renewNum(self Depth)}
               [] CancelVar = True then true
               end
            end

            %%  Check #1: is it still a FD variable at all??
            case <<checkIsVar($)>> then
               %%
               %%  Check #2: the printname (for the case when one variable
               %% is bound to another one);
               NewName = <<getVarName($)>>
               OldNameStr = {VirtualString.toString self.name.1}
               NewNameStr = {VirtualString.toString NewName}

               %%
               case {DiffStrs OldNameStr NewNameStr} then
                  %%
                  job
                     {self.parentObj renewNum(self Depth)}
                  end
               else true
               end
               %%
            else
               %%
               job
                  {self.parentObj renewNum(self Depth)}
               end
            end
         end
      end

      %%
      %%  ... it should be used by 'undraw';
      meth stopTypeWatching
\ifdef DEBUG_TT
         {Show 'MetaVariableTermTermObject::stopTypeWatching: '#self.term}
\endif
         %%
         @CancelReq = True
      end

      %%
   end

   %%
   %%
   %%  References;
   %%
   class ReferenceTermTermObject
      from MetaTermTermObject
      %%
      %%  Note that 'name' is an *attribute* here!
      attr
         name                   % print name;

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'ReferenceTermTermObject::initTerm is applied'#self.term}
\endif
         name <- '?'
      end

      %%
      %%
      meth setRefVar(Master Name)
\ifdef DEBUG_TT
         {Show 'ReferenceTermTermObject::setRefVar is applied'#self.term}
\endif
         master <- Master
         name <- Name
         size <- {VSLength Name}

         %%
         job
            {self.parentObj redrawNum(self)}
         end
      end

      %%
   end

   %%
   %%
   %%  Shrunken (sub)terms;
   %%
   class ShrunkenTermTermObject
      from MetaTermTermObject
      %%

      %%
      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'ShrunkenTermTermObject::initTerm is applied'#self.term}
\endif
         true
      end

      %%
   end

   %%
   %%
   %%  Unknown terms;
   %%
   class UnknownTermTermObject
      from MetaTermTermObject
      %%
      feat
         name: '<UNKNOWN TERM>'         % print name;

      %%
      %%  We need 'setName' here and for 'RecordTermTermObject', since
      %% it's redefined for chunk objects;

      %%
      meth initTerm
\ifdef DEBUG_TT
         {Show 'UnknownTermTermObject::initTerm is applied'#self.term}
\endif
         true
      end

      %%
   end

   %%
end
