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
%%%  Subterms store (for compound terms);
%%%
%%%
%%%
%%%

local
   ResizableArray               % low-level primitives; used instead of
                                % DataStructure.automaticArray;

   %%
   EmptySubtermRec = subterm(obj:     !InitValue
                             outInfo: !InitValue)

   %%
   MetaSubtermsStore            % meta class;

   %%
   RAInit           = {NewName}
   RAInitFixed      = {NewName}
   RASize           = {NewName}
   RAPut            = {NewName}
   RAGet            = {NewName}
   RAForAll         = {NewName}
   RAResize         = {NewName}
   RAInsert         = {NewName}
   RAShrink         = {NewName}

   %%
   GetSubtermRec    = {NewName}
   GetAnySubtermRec = {NewName}
   SetAnySubtermRec = {NewName}
   SetSubtermRec    = {NewName}

   %%
   %%  Example: how to replace '+' from the Oz Prelude;
   %% `+` = proc {$ X Y Z}
   %%   case {IsNumber X} andthen {IsNumber Y} then
   %%          Z = {Number.'+' X Y}
   %%       else
   %%          {Show '+: bullshit!!! '#X#Y}
   %%          Z = 0
   %%       end
   %%    end

in
   %%
   %%  Local 'resizable' array;
   %%  Its indexes are 1,@TotalWidth, and internally it can be bigger -
   %% 1,@High;
   %%  There are the following operations
   %%  - RAInit
   %%  - RAInitFixed   % "semifixed": initially realsize == size;
   %%  - RASize
   %%  - RAPut
   %%  - RAGet
   %%  - RAForAll      % with unary method;
   %%  - RAResize      % add new element beyond the last element;
   %%  - RAInsert      % insert new element at first position, and move the
   %%                  % rest one slot forward;
   %%  - RAShrink
   %%
   class ResizableArray
      %%
      attr
         Array                  % tuple of width '@High';
         TotalWidth             % "visible" width
         High                   % real width (>= TotalWidth);

      %%
      meth !RAInit(Width)
         %%
         %%  Array must be there, since we apply
         %% destructive modificator (GenericSet)!
         %%
         TotalWidth <- Width
         High <- Width + {`div` (Width * RArrayRRatio) 100}

         %%
         Array <- {MakeTuple array @High}
      end

      %%
      %%
      meth !RAInitFixed(Width)
         %%
         TotalWidth <- Width
         High <- Width

         %%
         Array <- {MakeTuple array Width}
      end

      %%
      %%
      meth !RASize(H)
         H = @TotalWidth
      end

      %%
      %%
      meth getTotalWidth(H)
         H = @TotalWidth
      end

      %%
      %%
      meth removeAllSubterms
         TotalWidth <- 0
      end

      %%
      %%
      meth !RAGet(I X)
         case I >= 1 andthen I =< @TotalWidth then
            X = @Array.I
         else
            {BrowserError ['ResizableArray::RAGet: invalid index']}
         end
      end

      %%
      %%
      meth !RAPut(I X)
         case I >= 1 andthen I =< @TotalWidth then
            {GenericSet @Array I X}
         else
            {BrowserError ['ResizableArray::RAPut: invalid index']}
         end
      end

      %%
      %%
      meth !RAForAll(Method)
         <<ForIndxs(1 @High Method)>>
      end

      %%
      %%
      meth ForIndxs(N Max Method)
         case N =< Max then
            <<Method(@Array.N)>>

            %%
            <<ForIndxs((N + 1) Max Method)>>
         else true
         end
      end

      %%
      %%  Add 'Inc' undefined elements at the end;
      meth !RAResize(Inc)
         local Width RWidth in
            Width = @TotalWidth
            RWidth = @High

            %%
            case RWidth >= Width + Inc then true
            else
               OldArray NewArray NewRWidth
            in
               OldArray = @Array

               %%
               NewRWidth =
               RWidth + Inc + {`div` (RWidth * RArrayRRatio) 100}
               High <- NewRWidth

               %%
               NewArray = {MakeTuple array NewRWidth}

               %%
               {Loop.for 1 Width 1
                proc {$ N} NewArray.N = OldArray.N end}

               %%
               Array <- NewArray
            end

            %%
            TotalWidth <- Width + Inc
         end
      end

      %%
      %%  Insert one undefined element at the first position;
      meth !RAInsert
         local Width RWidth NewRWidth OldArray NewArray in
            Width = @TotalWidth
            RWidth = @High
            OldArray = @Array

            %%
            %%
            NewRWidth = RWidth + 1 + {`div` (RWidth * RArrayRRatio) 100}
            High <- NewRWidth

            %%
            NewArray = {MakeTuple array NewRWidth}

            %%
            {Loop.for 1 Width 1 proc {$ N} NewArray.(N+1) = OldArray.N end}

            %%
            Array <- NewArray

            %%
            TotalWidth <- Width + 1
         end
      end

      %%
      %%  Remove one element at the last position;
      meth !RAShrink
         TotalWidth <- @TotalWidth - 1
      end

      %%
      %%
      meth debugGetArray(?A)
         A = @Array
      end

      %%
   end

   %%
   %%
   %%
   %%  'Meta' subterms store;
   %%  Common methods;
   %%
   class MetaSubtermsStore from ResizableArray
      %%
      attr
         width                  % number of proper subterms;

      %%
      %%
      meth setSubtermObj(Number Obj)
         local SRec NewSRec in
            <<GetSubtermRec(Number SRec)>>

            %%
            NewSRec = {AdjoinAt SRec obj Obj}
            <<SetSubtermRec(Number NewSRec)>>
         end
      end

      %%
      %%
      meth getSubtermObj(Number ?Obj)
         local SRec in
            <<GetSubtermRec(Number SRec)>>

            %%
            Obj = SRec.obj
         end
      end

      %%
      %%
      meth getObjsList(?List)
         <<GetObjsList(1 @width List)>>
      end

      %%
      %%
      meth GetObjsList(Low High List)
         case Low =< High then
            Obj NList
         in
            Obj = <<getSubtermObj(Low $)>>
            List = Obj|NList

            %%
            <<GetObjsList((Low + 1) High NList)>>
         else List = nil
         end
      end

      %%
      %%
      meth setSubtermOutInfo(Number OutInfo)
         local SRec NewSRec in
            <<GetSubtermRec(Number SRec)>>

            %%
            NewSRec = {AdjoinAt SRec outInfo OutInfo}
            <<SetSubtermRec(Number NewSRec)>>
         end
      end

      %%
      %%
      meth setAnySubtermOutInfo(Number OutInfo)
         local SRec NewSRec in
            <<GetAnySubtermRec(Number SRec)>>

            %%
            NewSRec = {AdjoinAt SRec outInfo OutInfo}
            <<SetAnySubtermRec(Number NewSRec)>>
         end
      end

      %%
      %%
      meth getSubtermOutInfo(Number ?OutInfo)
         local SRec in
            <<GetSubtermRec(Number SRec)>>

            %%
            OutInfo = SRec.outInfo
         end
      end

      %%
      %%
      meth getAnySubtermObj(Number ?Obj)
         local SRec in
            <<GetAnySubtermRec(Number SRec)>>

            %%
            Obj = SRec.obj
         end
      end

      %%
      %%
      meth getAnySubtermOutInfo(Number ?OutInfo)
         local SRec in
            <<GetAnySubtermRec(Number SRec)>>

            %%
            OutInfo = SRec.outInfo
         end
      end

      %%
      %%
      meth getSubtermObjOutInfo(Number ?Obj ?OutInfo)
         local SRec in
            <<GetSubtermRec(Number SRec)>>

            %%
            Obj = SRec.obj
            OutInfo = SRec.outInfo
         end
      end

      %%
      %%
      meth getAnySubtermObjOutInfo(Number ?Obj ?OutInfo)
         local SRec in
            <<GetAnySubtermRec(Number SRec)>>

            %%
            Obj = SRec.obj
            OutInfo = SRec.outInfo
         end
      end

      %%
      %%
      meth isFirstAny(Number ?IsFirst)
         IsFirst = Number == 1
      end

      %%
      %%
      meth isLastAny(Number ?IsLast)
         IsLast = Number == <<RASize($)>>
      end

      %%
      %%
      %%  Send a message 'Message' to all subterms;
      %%  We ignore all the 'empty' records;
      meth sendMessages(Message)
         <<MetaSubtermsStore ForAllSend(1 <<RASize($)>> Message)>>
      end

      %%
      %%
      meth ForAllSend(Low High Message)
         case Low =< High then
            SRec
         in
            <<RAGet(Low SRec)>>

            %%
            case SRec == EmptySubtermRec then
               {BrowserError ['MetaSubtermsStore::ForAllSend: error?']}
            else {SRec.obj Message}
            end

            %%
            <<MetaSubtermsStore ForAllSend(Low+1 High Message)>>
         else true
         end
      end

      %%
      %%  Apply method 'Message' to all subterms;
      %%  Message format is 'Message(OutInfo N SObj)';
      %%  We ignore all the 'empty' records;
      meth applyMessage(Message)
         <<MetaSubtermsStore ForAllApply(1 <<RASize($)>> Message)>>
      end

      %%
      %%
      meth ForAllApply(Low High Message)
         case Low =< High then
            SRec
         in
            <<RAGet(Low SRec)>>

            %%
            case SRec == EmptySubtermRec then
               {BrowserError ['MetaSubtermsStore::ForAllAply: error?']}
            else <<Message(SRec.outInfo Low SRec.obj)>>
            end

            %%
            <<MetaSubtermsStore ForAllApply(Low+1 High Message)>>
         else true
         end
      end

      %%
      %%  Send a message 'Message(Arg)' to all subterms and
      %% collect 'Arg's in the 'List';
      %%  We ignore all the 'empty' records;
      %%  Note that 'List' is actually reversed;
      meth sendMessagesArg(Message ?List)
         <<MetaSubtermsStore FoldLSend(1 <<RASize($)>> nil List Message)>>
      end

      %%
      %%
      meth FoldLSend(Low High LIn LOut Message)
         case Low =< High then
            SRec Method Arg NewLIn
         in
            <<RAGet(Low SRec)>>

            %%
            case SRec == EmptySubtermRec then
               {BrowserError ['MetaSubtermsStore::FoldLSend: error?']}
               Arg = InitValue
            else
               Method = Message(Arg)
               {SRec.obj Method}
            end

            %%
            NewLIn = Arg|LIn
            <<MetaSubtermsStore FoldLSend(Low+1 High NewLIn LOut Message)>>
         else LIn = LOut
         end
      end

      %%
      %%  Apply the message 'Message'/4 to all subterm objects;
      %%  Message format is 'Message(OutInfoIn N SubtermObj ?OutInfoOut)';
      %%
      %%  We ignore all the 'empty' records;
      %%  Note that 'List' is actually reversed;
      meth mapObjInd(Message)
         <<MetaSubtermsStore MapInd(1 <<RASize($)>> Message)>>
      end

      %%
      %%
      meth MapInd(Low High Message)
         case Low =< High then
            SRec Method NewOutInfo NewSRec
         in
            <<RAGet(Low SRec)>>

            %%
            case SRec == EmptySubtermRec then
               %%
               {BrowserError ['MetaSubtermsStore::MapInd: error?']}
            else
               Method = Message(SRec.outInfo Low SRec.obj NewOutInfo)

               %%
               <<Method>>

               %%
               % {Wait NewOutInfo}
               %%
               NewSRec = {AdjoinAt SRec outInfo NewOutInfo}
               <<RAPut(Low NewSRec)>>
            end

            %%
            <<MetaSubtermsStore MapInd(Low+1 High Message)>>
         else true
         end
      end

      %%
      %%  ... almost the same as above, but the message format is
      %%  'Message(OutInfoIn N SubtermObj ArgIn ?ArgOut ?OutInfoOut)';
      %%
      meth mapObjIndArg(Message ArgIn ?ArgOut)
         <<MetaSubtermsStore
         MapIndArg(1 <<RASize($)>> ArgIn ArgOut Message)>>
      end

      %%
      %%
      meth MapIndArg(Low High ArgIn ArgOut Message)
         case Low =< High then
            SRec Method NewOutInfo NewSRec NewArgIn
         in
            <<RAGet(Low SRec)>>

            %%
            case SRec == EmptySubtermRec then
               {BrowserError ['MetaSubtermsStore::MapIndArg: error?']}
            else
               Method = Message(SRec.outInfo Low SRec.obj ArgIn
                                NewArgIn NewOutInfo)

               %%
               <<Method>>

               %%
               {Wait NewOutInfo}

               %%
               NewSRec = {AdjoinAt SRec outInfo NewOutInfo}
               <<RAPut(Low NewSRec)>>
            end

            %%
            <<MetaSubtermsStore
            MapIndArg(Low+1 High NewArgIn ArgOut Message)>>
         else ArgIn = ArgOut
         end
      end

      %%
   end

   %%
   %%
   %%  Array of subterms for compound terms (but not records with
   %% their ',,, ?' or ',,, ...' or ',,, ...?' at the end);
   %%
   %%  Array is indexed (internally) from 1 to width (total one), and
   %% contains following records
   %%  subterm(obj:     SubtermObj
   %%          outInfo: OutInfo)
   %% where 'OutInfo' can be arbitrary data structure;
   %% (currently, - for text widgets - it's record with features 'mark',
   %% 'size' and 'glueSize');
   %%
   %%  Note that different access methods use different indexes;
   %%
   class TupleSubtermsStore from MetaSubtermsStore
      %%
      %%
      meth subtermsStoreInit(Width AreCommas)
\ifdef DEBUG_TT
         {Show 'TupleSubtermsStore::subtermsStoreInit: '#Width#AreCommas}
\endif
         %%
         case AreCommas then
            <<RAInit(Width + 1)>>
         else
            <<RAInitFixed(Width)>>
         end

         %%
         width <- Width

         %%
         <<RAForAll(ZeroSubtermRec)>>
      end

      %%
      %%  auxiliary - from subtermsStoreInit;
      meth ZeroSubtermRec(E)
         E = EmptySubtermRec
      end

      %%
      %%
      meth areCommas(?AreCommas)
         AreCommas = @width \= <<RASize($)>>
      end

      %%
      %%  (internal) replacement of proper ones;
      meth !SetSubtermRec(Number SRec)
         %%
         case Number > @width then
            {BrowserError
             ['TupleSubtermsStore::SetSubtermRec: invalid subterm']}
         else
            <<RAPut(Number SRec)>>
         end
      end

      %%
      %%  Every 'set' for a new subterm must be preceded with
      %% 'addSubterm';
      meth addSubterm
\ifdef DEBUG_TT
         {Show 'TupleSubtermsStore::addSubterm'}
\endif
         local Width TotalWidth in
            Width = @width
            TotalWidth = <<RASize($)>>

            %%
            case Width == TotalWidth then
               <<RAResize(1)>>
               <<RAPut((Width + 1) <<ZeroSubtermRec($)>>)>>
            else
               CommasObj
            in
               <<RAGet(TotalWidth CommasObj)>>
               <<RAResize(1)>>
               <<RAPut((TotalWidth + 1) CommasObj)>>
               <<RAPut(TotalWidth <<ZeroSubtermRec($)>>)>>

            end
            %%
            width <- Width + 1
         end
      end

      %%
      %%  ... is used actually by 'extend' in flat list objects;
      meth addSubterms(NumOf)
\ifdef DEBUG_TT
         {Show 'TupleSubtermsStore::addSubterms'#NumOf}
\endif
         local Width TotalWidth in
            Width = @width
            TotalWidth = <<RASize($)>>

            %%
            case Width == TotalWidth then
               <<RAResize(NumOf)>>
               %%
               <<ZeroSRecIndxs((Width + 1) (Width + NumOf))>>
            else
               CommasObj
            in
               <<RAGet(TotalWidth CommasObj)>>
               <<RAResize(NumOf)>>
               <<RAPut((TotalWidth + NumOf) CommasObj)>>

               %%
               <<ZeroSRecIndxs(TotalWidth (TotalWidth + NumOf - 1))>>
            end

            %%
            width <- Width + NumOf
         end
      end

      %%
      %%  local method;
      meth ZeroSRecIndxs(Low High)
         case Low =< High then
            <<RAPut(Low <<ZeroSubtermRec($)>>)>>

            %%
            <<ZeroSRecIndxs((Low + 1) High)>>
         else true
         end
      end

      %%
      %%  replace commas with a (last) subterm;
      meth makeLastSubterm(?CommasObj)
         local TotalWidth in
            TotalWidth = <<RASize($)>>

            %%
            case @width == TotalWidth then
               {BrowserError ['TupleSubtermsStore::makeLastSubterm: error']}

               %%
               CommasObj = InitValue
            else
               %% 'outInfo' is preserved;
               width <- TotalWidth

               %%
               CommasObj = <<RAGet(TotalWidth $)>>.obj
            end
         end
      end

      %%
      %%  proper ones;
      meth !GetSubtermRec(Number ?SRec)
         case Number > @width then
            {BrowserError
             ['TupleSubtermsStore::getSubtermObj: invalid subterm']}
         else
            <<RAGet(Number SRec)>>
         end
      end

      %%
      %%
      meth !GetAnySubtermRec(Number ?SRec)
         <<RAGet(Number SRec)>>
      end

      %%
      %%
      meth addCommasRec
         case <<areCommas($)>> then
            {BrowserError ['TupleSubtermsStore::addCommasRec: error']}
         else
            <<RAResize(1)>>

            %%
            <<RAPut(<<RASize($)>> <<ZeroSubtermRec($)>>)>>
         end
      end

      %%
      %%
      meth getCommasNum(?Num)
         Num = <<RASize($)>>
      end

      %%
      %%
      meth setCommasObj(Obj)
         local Width TotalWidth in
            Width = @width
            TotalWidth = <<RASize($)>>

            %%
            case Width == TotalWidth then
               {BrowserError
                ['TupleSubtermsStore::setCommasObj: not implemented']}
            else
               CommasRec NewCommasRec
            in
               <<RAGet(TotalWidth CommasRec)>>
               NewCommasRec = {AdjoinAt CommasRec obj Obj}
               <<RAPut(TotalWidth NewCommasRec)>>
            end
         end
      end

      %%
      %%
      meth setCommasOutInfo(OutInfo)
         local Width TotalWidth in
            Width = @width
            TotalWidth = <<RASize($)>>

            %%
            case Width == TotalWidth then
               {BrowserError
                ['TupleSubtermsStore::setCommasOutInfo: not implemented']}
            else
               CommasRec NewCommasRec
            in
               <<RAGet(TotalWidth CommasRec)>>
               NewCommasRec = {AdjoinAt CommasRec outInfo OutInfo}
               <<RAPut(TotalWidth NewCommasRec)>>
            end
         end
      end

      %%
      %%  Bogus?
      meth removeCommasRec
         local TotalWidth Width in
            TotalWidth = <<RASize($)>>
            Width = @width

            %%
            case Width == TotalWidth then
               {BrowserError
                ['TupleSubtermsStore::removeCommasRec: there are no commas?']}
            else
               <<RAShrink>>
            end
         end
      end

      %%
   end

   %%
   %%
   %%  Array of subterms for RecordTermObject;
   %%
   %%
   class RecordSubtermsStore
      from TupleSubtermsStore
      %%
      attr
         AreSpecs               % is 'True' if there is '?' or '...'
                                % or '... ?' at the tail;

      %%
      %%
      %%
      meth subtermsStoreInit(Width AreCommas AreThereSpecs)
\ifdef DEBUG_TT
         {Show 'RecordSubtermsStore::subtermsStoreInit: '#
          Width#AreCommas#AreThereSpecs}
\endif
         local TotalWidth in
            %%
            TotalWidth = Width +
            case AreCommas then 1 else 0 end +
            case AreThereSpecs then 1 else 0 end

            %%
            width <- Width
            AreSpecs <- AreThereSpecs

            %%
            case AreCommas then
               <<RAInit(TotalWidth)>>
            else
               <<RAInitFixed(TotalWidth)>>
            end

            %%
            <<RAForAll(ZeroSubtermRec)>>
         end
      end

      %%
      %%  auxiliary - from subtermsStoreInit;
      meth ZeroSubtermRec(E)
         E = EmptySubtermRec
      end

      %%
      %%
      meth areCommas(?AreCommas)
         local Diff in
            Diff = <<RASize($)>> - @width

            %%
            AreCommas = case Diff
                        of 0 then False
                        [] 1 then
                           case @AreSpecs then False
                           else True
                           end
                        [] 2 then True
                        else
                           {BrowserError
                            ['RecordSubtermsStore::areCommas: error']}
                           False
                        end
         end
      end

      %%
      %%
      meth areSpecs(?Are)
         Are = @AreSpecs
      end

      %%
      %%  Yields a number of proper subterm on a number of "any" one,
      %% and zero if 'NIn' is not a number of proper subterm;
      meth getProperNum(NIn ?NOut)
         NOut = case NIn =< @width then NIn
                else 0
                end
      end

      %%
      %%  (internal) replacement of proper ones;
      meth !SetSubtermRec(Number SRec)
         case Number > @width then
            {BrowserError
             ['RecordSubtermsStore::SetSubtermRec: invalid subterm']}
         else
            <<RAPut(Number SRec)>>
         end
      end

      %%
      %%
      meth addSubterm
\ifdef DEBUG_TT
         {Show 'RecordSubtermsStore::addSubterm'}
\endif
         local Width TotalWidth Diff in
            Width = @width
            TotalWidth = <<RASize($)>>
            Diff = TotalWidth - Width

            %%
            case Diff
            of 0 then
               <<RAResize(1)>>
               <<RAPut((Width + 1) <<ZeroSubtermRec($)>>)>>

               %%
               width <- Width + 1
            [] 1 then AnyObj in
               <<RAGet(TotalWidth AnyObj)>>
               <<RAResize(1)>>
               <<RAPut((TotalWidth + 1) AnyObj)>>
               <<RAPut(TotalWidth <<ZeroSubtermRec($)>>)>>

               %%
               width <- Width + 1
            [] 2 then CommasObj SpecsObj in
               <<RAGet(TotalWidth SpecsObj)>>
               <<RAGet((TotalWidth - 1) CommasObj)>>

               %%
               <<RAResize(1)>>

               %%
               <<RAPut((TotalWidth + 1) SpecsObj)>>
               <<RAPut(TotalWidth CommasObj)>>
               <<RAPut((TotalWidth - 1) <<ZeroSubtermRec($)>>)>>

               %%
               width <- Width + 1
            else
               {BrowserError ['RecordSubtermsStore::addSubterm: error']}
            end
         end
      end

      %%
      %%  ... is used actually by 'extend' in open feature structures;
      meth addSubterms(NumOf)
\ifdef DEBUG_TT
         {Show 'RecordSubtermsStore::addSubterms'#NumOf}
\endif
         local Width TotalWidth Diff in
            Width = @width
            TotalWidth = <<RASize($)>>
            Diff = TotalWidth - Width

            %%
            case Diff
            of 0 then
               <<RAResize(NumOf)>>

               %%
               <<ZeroSRecIndxs((Width + 1) (Width + NumOf))>>

               %%
               width <- Width + NumOf
            [] 1 then AnyObj in
               <<RAGet(TotalWidth AnyObj)>>
               <<RAResize(NumOf)>>
               <<RAPut((TotalWidth + NumOf) AnyObj)>>

               %%
               <<ZeroSRecIndxs(TotalWidth (TotalWidth + NumOf - 1))>>

               %%
               width <- Width + NumOf
            [] 2 then CommasObj SpecsObj in
               <<RAGet(TotalWidth SpecsObj)>>
               <<RAGet((TotalWidth - 1) CommasObj)>>

               %%
               <<RAResize(NumOf)>>

               %%
               <<RAPut((TotalWidth + 1) SpecsObj)>>
               <<RAPut(TotalWidth CommasObj)>>

               %%
               <<ZeroSRecIndxs((TotalWidth - 1) (TotalWidth + NumOf - 2))>>

               %%
               width <- Width + NumOf
            else
               {BrowserError ['RecordSubtermsStore::addSubterms: error']}
            end
         end
      end

      %%
      %%  local method;
      meth ZeroSRecIndxs(Low High)
         case Low =< High then
            <<RAPut(Low <<ZeroSubtermRec($)>>)>>

            %%
            <<ZeroSRecIndxs((Low + 1) High)>>
         else true
         end
      end

      %%
      %%
      meth makeLastSubterm(?CommasObj)
         local Width TotalWidth Diff in
            Width = @width
            TotalWidth = <<RASize($)>>
            Diff = TotalWidth - Width

            %%
            case Diff
            of 0 then
               {BrowserError ['RecordSubtermsStore::makeLastSubterm: error']}

               %%
               CommasObj = InitValue
            [] 1 then
               case <<areCommas($)>> then
                  %% 'outInfo' is preserved;
                  width <- Width + 1

                  %%
                  CommasObj = <<RAGet(TotalWidth $)>>.obj
               else
                  {BrowserError
                   ['RecordSubtermsStore::makeLastSubterm: error N2']}

                  %%
                  CommasObj = InitValue
               end
            [] 2 then
               %% 'outInfo' is preserved;
               width <- Width + 1

               %%
               CommasObj = <<RAGet((TotalWidth - 1) $)>>.obj
            else
               {BrowserError ['RecordSubtermsStore::makeLastSubterm: error N3']}

               %%
               CommasObj = InitValue
            end
         end
      end

      %%
      %%  proper ones;
      meth !GetSubtermRec(Number ?SRec)
         case Number > @width then
            {BrowserError
             ['RecordSubtermsStore::getSubtermRec: invalid subterm']}
         else
            <<RAGet(Number SRec)>>
         end
      end

      %%
      %%
      meth !GetAnySubtermRec(Number ?SRec)
         <<RAGet(Number SRec)>>
      end

      %%
      %%
      meth !SetAnySubtermRec(Number ?SRec)
         <<RAPut(Number SRec)>>
      end

      %%
      %%
      meth addCommasRec
         local Width TotalWidth Diff in
            Width = @width
            TotalWidth = <<RASize($)>>
            Diff = TotalWidth - Width

            %%
            case Diff
            of 0 then
               %% neither commas nor specials;
               <<RAResize(1)>>

               %%
               <<RAPut(<<RASize($)>> <<ZeroSubtermRec($)>>)>>
            [] 1 then
               case <<areCommas($)>> then
                  {BrowserError
                   ['RecordTermObject::addCommasRec: error N1']}
               else
                  TotalWidth SpecsRec
               in
                  TotalWidth = <<RASize($)>>
                  SpecsRec = <<RAGet(TotalWidth $)>>

                  %%
                  <<RAResize(1)>>

                  %%
                  <<RAPut((TotalWidth + 1) SpecsRec)>>
                  <<RAPut(TotalWidth <<ZeroSubtermRec($)>>)>>
               end
            [] 2 then
               {BrowserError ['RecordTermObject::addCommasRec: error N2']}
            end
         end
      end

      %%
      %%
      meth getCommasNum(?Num)
         Num = <<RASize($)>> - case <<areSpecs($)>> then 1 else 0 end
      end

      %%
      %%
      meth setCommasObj(Obj)
         case <<areCommas($)>> then
            CommasRec NewCommasRec CommasRecNum
         in
            CommasRecNum = <<getCommasNum($)>>

            %%
            <<RAGet(CommasRecNum CommasRec)>>
            NewCommasRec = {AdjoinAt CommasRec obj Obj}
            <<RAPut(CommasRecNum NewCommasRec)>>
         else
            {BrowserError
             ['TupleSubtermsStore::setCommasObj: not implemented']}
         end
      end

      %%
      %%
      meth setCommasOutInfo(OutInfo)
         case <<areCommas($)>> then
            CommasRec NewCommasRec CommasRecNum
         in
            CommasRecNum = <<getCommasNum($)>>

            %%
            <<RAGet(CommasRecNum CommasRec)>>
            NewCommasRec = {AdjoinAt CommasRec outInfo OutInfo}
            <<RAPut(CommasRecNum NewCommasRec)>>
         else
            {BrowserError
             ['TupleSubtermsStore::setCommasOutInfo: not implemented']}
         end
      end

      %%
      %%
      meth addSpecs
         case <<areSpecs($)>> then
            {BrowserError ['RecordSubtermStore::addSpecs: error']}
         else
            <<RAResize(1)>>

            %%
            <<RAPut(<<RASize($)>> <<ZeroSubtermRec($)>>)>>
            AreSpecs <- True
         end
      end

      %%
      %%
      meth getSpecsObjOutInfo(?Obj ?OutInfo)
         case <<areSpecs($)>> then
            SpecsRec NewSpecsRec TotalWidth
         in
            TotalWidth = <<RASize($)>>

            %%
            <<RAGet(TotalWidth SpecsRec)>>

            %%
            Obj = SpecsRec.obj
            OutInfo = SpecsRec.outInfo
         else
            {BrowserError
             ['RecordSubtermsStore::getSpecsObjOutInfo: not implemented']}
         end
      end

      %%
      %%
      meth setSpecsObj(Obj)
         case <<areSpecs($)>> then
            SpecsRec NewSpecsRec TotalWidth
         in
            TotalWidth = <<RASize($)>>

            %%
            <<RAGet(TotalWidth SpecsRec)>>
            NewSpecsRec = {AdjoinAt SpecsRec obj Obj}
            <<RAPut(TotalWidth NewSpecsRec)>>
         else
            {BrowserError
             ['RecordSubtermsStore::setSpecsObj: not implemented']}
         end
      end

      %%
      %%
      meth removeSpecs
         case <<areSpecs($)>> then
            <<RAShrink>>
            AreSpecs <- False
         else
            {BrowserError
             ['RecordSubtermsStore::removeSpecs: there were no specs']}
         end
      end

      %%
      %%
      %%  Bogus?
      meth removeCommasRec
         local TotalWidth Diff in
            TotalWidth = <<RASize($)>>
            Diff = TotalWidth - @width

            %%
            case Diff
            of 0 then
               {BrowserError
                ['RecordSubtermsStore::removeCommasRec: there are no commas?']}
            [] 1 then
               case <<areCommas($)>> then
                  <<RAShrink>>
               else
                  {BrowserError
                   ['RecordSubtermsStore::removeCommasRec: there are no commas?']}
               end
            [] 2 then SpecsRec in
               <<RAGet(TotalWidth SpecsRec)>>
               <<RAPut((TotalWidth - 1) SpecsRec)>>
               <<RAShrink>>
            else
               {BrowserError
                ['RecordSubtermsStore::removeCommasRec: error']}
            end
         end
      end

      %%
   end

   %%
end
