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
%%%  'text widget' term classes;
%%%
%%%
%%%
%%%

local
   %%  'meta' text widget term object;
   MetaTWTermObject
   MetaTupleTWTermObject
   MetaListTWTermObject
   MetaRecordTWTermObject
   MetaChunkTWTermObject

   %% could be extended if necessary;
   ZeroOutTupleInfo = twInfo(mark:     !InitValue   % subterms' mark;
                             size:     !InitValue   % subterms' size;
                             glueSize: !InitValue)  % size of glue just after;
   ZeroOutRecInfo = twInfo(mark:     !InitValue
                           prfxSize: !InitValue  % size of subterm's prefix
                                                 % (feature name);
                           size:     !InitValue
                           glueSize: !InitValue)

   %%  Local features & methods;
   ReferenceGlue    = {NewName}
   ReferenceGSize   = {NewName}
   FirstInc         = {NewName}
   NewOutInfo       = {NewName}
   InitOutInfoRec   = {NewName}
   CreateSimpleGlue = {NewName}
   AddSimpleGlue    = {NewName}
   DrawSubterm      = {NewName}
   AdjustGlue       = {NewName} % actually, there are two methods -
                                % for ~tuples and ~records;
   GetRightMostMarks = {NewName}
   GetTags = {NewName}

   %%  'Pseudo' terms (in text widget);
   %%
   %%  TW object which draws DOpenFS ('...') and has the width of 3;
   PseudoTermTWDots
   %%  DUnshownPFs ('?') with the width 1;
   PseudoTermTWQuestion
   %%  '... ?' with the width 5;
   PseudoTermTWDotsQuestion
   %%  DNameUnshown (',,,') with the width 3;
   PseudoTermTWCommas

   %%  Auxiliary procedures;
   %%
   CreateGlue
   CreateSpaces
in

%%%
%%%  Diverse local auxiliary procedures;
%%%
   %%
   %%  'CreateSpaces';
   %%  Generates an VS consisting of 'N' blanks;
   %%  After all this code could be considered as my (K.P.) joke:}
   fun {CreateSpaces N}
      case N
      of 0  then ''
      [] 1  then ' '
      [] 2  then '  '
      [] 3  then '   '
      [] 4  then '    '
      [] 5  then '     '
      [] 6  then '      '
      [] 7  then '       '
      [] 8  then '        '
      [] 9  then '         '
      [] 10 then '          '
      [] 11 then '           '
      [] 12 then '            '
      [] 13 then '             '
      [] 14 then '              '
      [] 15 then '               '
      [] 16 then '                '
      [] 17 then '                 '
      [] 18 then '                  '
      [] 19 then '                   '
      [] 20 then '                    '
      [] 21 then '                     '
      [] 22 then '                      '
      [] 23 then '                       '
      [] 24 then '                        '
      [] 25 then '                         '
      [] 26 then '                          '
      [] 27 then '                           '
      [] 28 then '                            '
      [] 29 then '                             '
      [] 30 then '                              '
      else
         H V
      in
         H = {`div` N 2}
         case H + H == N then
            V = {CreateSpaces H}
            V#V
         else
               V = {CreateSpaces H}
            ' '#V#V
         end
      end
   end

   %%
   %%  'CreateSpaces';
   %%  Creates a glue for the given offset
   %% (i.e. a VS containing blanks and a return character);
   %%
   fun {CreateGlue Offset}
      '\n'#{CreateSpaces Offset}
   end


   %%
   %%
   class PseudoTermTWObject
      from UrObject
      %%
      feat
         isEnclosed: fun {$ Self} True end
         !GetTags: fun {$ Self} nil end

      %%
      attr
         shown: InitValue

      %%
      %%
      meth putNL(?Mark)
         {self.widgetObj [genTkName(Mark)
                          insertWithMark(insert '\n' Mark)]}

         %% mark will be set in text widget *first*;
         mark <- Mark
      end

      %%
      %%  scroll to tag;
      meth scrollToTag(Tag)
         {Wait Tag}

         %%
         {self.widgetObj pickTagLast(Tag)}
         <<UrObject nil>>
      end

      %%
      %%  delete '\n' and its mark;
      meth delNL
         local Mark in
            %%  should be (already) here;
            Mark = @mark

            %%
            {self.widgetObj [deleteAfterMark(Mark 0 1) unsetMark(Mark)]}
            mark <- InitValue
         end
      end

      %%
      %%
      meth checkSize(Obj _ _)
\ifdef DEBUG_TW
         {Show 'PseudoTermTWObject::checkSize is applied'}
\endif
         case Obj == @termObj then
            {@termObj checkLayout}

            %%
            <<UrObject nil>>
         else true              % ignore irrelevant message;
         end
      end
   end

   %%
   %%
   %%
   %%  Pseudo objects for various filling character sequences;
   %%
   class PseudoTermTWDots
      from UrObject TermTag
      %%
      feat
         widgetObj
         parentObj
         term: InitValue        % unique value;

      %%
      attr
         shown: False
         sync                   % bound to true when it gets shown;
         name: DOpenFS
         num: ''
         size: {VSLength DOpenFS}

      %%
      %%
      meth init(parentObj: ParentObj)
         self.widgetObj = ParentObj.widgetObj
         self.parentObj = ParentObj

         %%
         <<tagInit>>
      end

      %%
      meth destroy
         <<close>>
      end

      %%
      meth getSize(?Size)
         Size = @size
      end

      %%
      meth checkLayout
         true
      end

      %%
      %%  For OFS records - show the width of it;
      %%  it might be used only if the term is shown;
      meth drawOFSWidth(Num)
         case @shown then
            TmpMark
         in
            num <- Num
            size <- {VSLength @name#@num}

            %%
            TmpMark = {self.widgetObj genTkName($)}
            {self.widgetObj setMarkOnTag(self TmpMark)}

            %%
            {self.widgetObj delete(self)}
            {self.widgetObj insertWithTag(TmpMark @name#@num [self])}

            %%
            {self.widgetObj unsetMark(TmpMark)}
         else
            SyncVar
         in
            SyncVar = @sync

            %%
            case {IsValue SyncVar} then
               {self drawOFSWidth(Num)}
            end
         end
      end

      %%
      meth draw(Mark ?Sync)
         %%
         %%  Note: we don't need to stretch parent's tag explicitly,
         %% since records are "enclosed" structures;
         {self.widgetObj insertWithTag(Mark @name#@num [self])}

         %%
         shown <- True
         @sync = True
         Sync = True
      end

      %%
      %%
      meth undraw
         {self.widgetObj [delete(self) deleteTag(self)]}

         %%
         sync <- _
         shown <- False
      end

      %%
      meth setUndrawn
         {self.widgetObj deleteTag(self)}

         %%
         sync <- _
         shown <- False
      end

      %%
      meth !GetRightMostMarks(?Marks)
         Marks = nil
      end

      %%
   end

   %%
   %%
   %%
   class PseudoTermTWQuestion
      from UrObject
      %%
      feat
         widgetObj
         parentObj
         term: InitValue        % unique value;
         name: DUnshownPFs
         size: {VSLength DUnshownPFs}

      %%
      %%
      meth init(parentObj: ParentObj)
         self.widgetObj = ParentObj.widgetObj
         self.parentObj = ParentObj
      end

      %%
      meth destroy
         <<close>>
      end

      %%
      meth getSize(?Size)
         Size = self.size
      end

      %%
      meth checkLayout
         true
      end

      %%
      meth setNum(_)
         {BrowserError ['PseudoTermTWQuestion::setNum ???']}
      end

      %%
      meth draw(Mark ?Sync)
         %%
         %%  Note: we don't need to stretch parent's tag explicitly,
         %% since records are "enclosed" structures;
         {self.widgetObj insert(Mark self.name)}

         %%
         Sync = True
      end

      %%
      %%  Note: leave question for responsibility of parent object;
      meth undraw
         true
      end

      %%
      meth setUndrawn
         true
      end

      %%
      meth !GetRightMostMarks(?Marks)
         Marks = nil
      end

      %%
   end

   %%
   %%
   %%
   class PseudoTermTWDotsQuestion
      from UrObject TermTag
      %%
      feat
         widgetObj
         parentObj
         term: InitValue        % unique value;
         name: DOpenFS#DUnshownPFs
         size: {VSLength DOpenFS#DUnshownPFs}

      %%
      %%
      meth init(parentObj: ParentObj)
         self.widgetObj = ParentObj.widgetObj
         self.parentObj = ParentObj
         %%
         <<tagInit>>
      end

      %%
      meth destroy
         <<close>>
      end

      %%
      meth getSize(?Size)
         Size = self.size
      end

      %%
      meth checkLayout
         true
      end

      %%
      meth setNum(_)
         {BrowserError ['PseudoTermTWDotsQuestion::setNum ???']}
      end

      %%
      meth draw(Mark ?Sync)
         %%
         %%  Note: we don't need to stretch parent's tag explicitly,
         %% since records are "enclosed" structures;
         {self.widgetObj insertWithTag(Mark self.name [self])}

         %%
         Sync = True
      end

      %%
      %%
      meth undraw
         %%
         {self.widgetObj [delete(self) deleteTag(self)]}
      end

      %%
      meth setUndrawn
         {self.widgetObj deleteTag(self)}
      end

      %%
      meth !GetRightMostMarks(?Marks)
         Marks = nil
      end

      %%
   end

   %%
   %%
   %%
   class PseudoTermTWCommas
      from UrObject TermTag
      %%
      feat
         widgetObj
         parentObj
         term: InitValue        % unique value;
         name: DNameUnshown
         size: {VSLength DOpenFS}
         !GetTags: fun {$ Self}
                      Self|{Self.parentObj.GetTags Self.parentObj}
                   end

      %%
      %%
      meth init(parentObj: ParentObj)
         local WidgetObj in
            WidgetObj = ParentObj.widgetObj

            %%
            self.widgetObj = WidgetObj
            self.parentObj = ParentObj
            <<tagInit>>
         end
      end

      %%
      meth destroy
         %%
         <<close>>
      end

      %%
      meth getSize(?Size)
         Size = self.size
      end

      %%
      meth checkLayout
         true
      end

      %%
      meth draw(Mark ?Sync)
         %%
         %%  Note: In this case (',,,') it's possible that commas don't get
         %% tagged by all necessary tags. So, we have to stretch them
         %% explicitly.
         local ParentObj IsEnclosed in
            %%
            ParentObj = self.parentObj
            IsEnclosed = {ParentObj.isEnclosed ParentObj}
            case IsEnclosed then
               %% no problems;
               {self.widgetObj insertWithTag(Mark self.name [self])}

               %%
               Sync = True
            else
               Tags
            in
               %%
               Tags = {self.GetTags self}

               %%
               {self.widgetObj insertWithTag(Mark self.name Tags)}

               %%
               Sync = True
            end

            %%  init bindings;
            <<[keysBind(keysHandlerPC)
               buttonsBind(buttonsHandlerPC)
               dButtonsBind(dButtonsHandlerPC)]>>
         end
      end

      %%
      %%
      meth keysHandlerPC(InStr)
         %%
         {Wait {String.is InStr}}

         %%
         thread
            %%
            %%  just forward the message to the parent...
            {self.parentObj keysHandler(InStr)}
         end
      end

      %%
      %%
      meth buttonsHandlerPC(InStr)
         %%
         {Wait {String.is InStr}}

         %%
         thread
            {self.parentObj buttonsHandler(InStr)}
         end
      end

      %%
      %%
      meth dButtonsHandlerPC(InStr)
         %%
         {Wait {String.is InStr}}

         %%
         thread
            {self.parentObj dButtonsHandler(InStr)}
         end
      end

      %%
      %%
      meth undraw
         %%
         {self.widgetObj [delete(self) deleteTag(self)]}
      end

      %%
      %%
      meth setUndrawn
         {self.widgetObj deleteTag(self)}
      end

      %%
      %%
      meth !GetRightMostMarks(?Marks)
         Marks = nil
      end

      %%
   end

   %%
   %%
   %%  'Meta' text widget object;
   %%  Note that both tag and tag identification (tagId) are *permanent*,
   %% and, therefore, they are saved as features;
   %%
   class MetaTWTermObject
      from UrObject TermTag
      %%
      feat
         !GetTags: fun {$ Self}
                      Self|{Self.parentObj.GetTags Self.parentObj}
                   end

      %%
      attr
         shown: InitValue
         size:  InitValue

      %%
      %%   Default methods;
      %%
      meth getSize(?Size)
         Size = @size
      end

      %%
      meth checkLayout
         true
      end

      %%
      meth pickPlace
         case @shown then
            {self.widgetObj pickTagFirst(self)}
            %% ... just simulate the first mouse button's click;
            <<buttonsHandler("1")>>
         else
            {BrowserWarning ['pickPlace for unshown term?']}
         end
      end

      %%
      %%
      meth isActive($)
         True
      end

      %%
      %%
      meth initBindings
         case <<isActive($)>> then
            %%
            case self.parentObj.type == T_PSTerm then true
            else
               {self.widgetObj lowerTag(self self.parentObj)}
            end

            %%
            <<[keysBind(keysHandler)
               buttonsBind(buttonsHandler)
               dButtonsBind(dButtonsHandler)]>>
         else true
         end
      end

      %%
      %%  Idea:
      %%  If the 'PseudoTag' is of then form '[Tag]', then characters
      %% inserted by e.g. 'insertWithTag' are added to 'Tag'; otherwise
      %% it's assumed that the 'PseudoTag' is a complete list of all
      %% necessary tags;
      meth getTagInfo(?PseudoTag)
         local ParentObj in
            ParentObj = self.parentObj

            %%
            PseudoTag = case {ParentObj.isEnclosed ParentObj} then
                           [self]
                        else
                           {self.GetTags self}
                        end
         end
      end

      %%
      %%
      meth closeOut
\ifdef DEBUG_TW
         case @shown then
            {Show 'MetaTWTermObject::closeOut: still shown??? '#self.type}
         else true
         end
\endif
         <<closeItself>>
      end

      %%
      %%
      meth undraw
         case @shown then
            %%
            {self.widgetObj [delete(self) deleteTag(self)]}

            %%
            shown <- False
         else true
         end
      end

      %%
      %%
      meth setUndrawn
         {self.widgetObj deleteTag(self)}

         %%
         shown <- False
      end

      %%
      %%
      %%  Very special stuff: get a list of all marks which
      %% could move 'aside' the term by inserting parentheses
      %% (of course, it could happen only for non-enclosed structures;)
      meth !GetRightMostMarks(?Marks)
         Marks = nil
      end
      %%
      %%
   end

   %%
   %%
   class AtomTWTermObject
      from MetaTWTermObject

      %%
      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'AtomObject::initOut method for the term '#self.term}
\endif
         %%
         <<tagInit>>

         %%
         size <- {VSLength self.name}
         shown <- False
      end

      %%
      %%
      meth isActive($)
         {self.store read(StoreAreInactive $)} == False
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'AtomObject::draw method for the term '#self.term#Mark}
\endif
         local PTag in
            PTag = <<getTagInfo($)>>

            %%
            {self.widgetObj insertWithTag(Mark self.name PTag)}

            %%
            shown <- True
            Sync = True

            %%
            <<initBindings>>
         end
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%
   %%
   class IntTWTermObject
      from MetaTWTermObject
      %%
      %%
      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'IntObject::initOut method for the term '#self.term}
\endif
         %%
         <<tagInit>>

         %%
         size <- {VSLength self.name}
         shown <- False
      end

      %%
      %%
      meth isActive($)
         {self.store read(StoreAreInactive $)} == False
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'IntObject::draw method for the term '#self.term#Mark}
\endif
         local PTag in
            PTag = <<getTagInfo($)>>

            %%
            {self.widgetObj insertWithTag(Mark self.name PTag)}

            %%
            shown <- True
            Sync = True

            %%
            <<initBindings>>
         end
      end

      %%
      %%  False 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%
   class FloatTWTermObject
      from MetaTWTermObject

      %%
      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'FloatObject::initOut method for the term '#self.term}
\endif
         %%
         <<tagInit>>

         %%
         size <- {VSLength self.name}
         shown <- False
      end

      %%
      %%
      meth isActive($)
         {self.store read(StoreAreInactive $)} == False
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'FloatObject::draw method for the term '#self.term#Mark}
\endif
         local PTag in
            PTag = <<getTagInfo($)>>

            %%
            {self.widgetObj insertWithTag(Mark self.name PTag)}

            %%
            shown <- True
            Sync = True

            %%
            <<initBindings>>
         end
      end

      %%
      %%  False 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%
   class NameTWTermObject
      from MetaTWTermObject

      %%
      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'NameObject::initOut method for the term '#self.term}
\endif
         %%
         <<tagInit>>

         %%
         size <- {VSLength self.name}
         shown <- False

         %%
         case @refVarName of '' then true
         else
            size <- @size + DSpace + {VSLength @refVarName} +
            case <<needsBracesRef($)>> then DDSpace else 0 end
         end
      end

      %%
      %%
      meth isActive($)
         {self.store read(StoreAreInactive $)} == False
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'NameObject::draw method for the term '#self.term#Mark}
\endif
         local PTag in
            PTag = <<getTagInfo($)>>

            %%
            case @refVarName == '' then
               {self.widgetObj insertWithTag(Mark self.name PTag)}
            else
               case <<needsBracesRef($)>> then
                  %%
                  {self.widgetObj
                   insertWithTag(Mark
                                 DLRBraceS#@refVarName#DEqualS#self.name#DRRBraceS
                                 PTag)}
               else
                  %%
                  {self.widgetObj
                   insertWithTag(Mark
                                 @refVarName#DEqualS#self.name
                                 PTag)}
               end
            end

            %%
            shown <- True
            Sync = True

            %%
            <<initBindings>>
         end
      end

      %%
      %%
      meth insertRefVar
\ifdef DEBUG_TW
         {Show 'NameObject::insertRefVar method for the term '#self.term}
\endif
         case @shown then
            Tags RefVarName RefVarNameLen Size NewSize PrfxSize SfxSize
         in
            %%
            Tags = {self.GetTags self}
            RefVarName = @refVarName
            RefVarNameLen = {VSLength RefVarName}
            Size = @size

            %%
            case <<needsBracesRef($)>> then
               {self.widgetObj [insertBeforeTag(self Tags
                                                DLRBraceS#RefVarName#DEqualS)
                                insertAfterTag(self Tags DRRBraceS)]}

               %%
               PrfxSize = DDSpace + RefVarNameLen
               SfxSize = DSpace
            else
               {self.widgetObj insertBeforeTag(self Tags RefVarName#DEqualS)}

               %%
               PrfxSize = DSpace + RefVarNameLen
               SfxSize = 0
            end

            %%
            NewSize =  Size + PrfxSize + SfxSize
            size <- NewSize

            %%
            job
               {self.parentObj checkSize(self Size NewSize)}
            end
         else
            RefVarName RefVarNameLen Size NewSize PrfxSize SfxSize
         in
            %%
            RefVarName = @refVarName
            RefVarNameLen = {VSLength RefVarName}
            Size = @size

            %%
            case <<needsBracesRef($)>> then
               %%
               PrfxSize = DDSpace + RefVarNameLen
               SfxSize = DSpace
            else
               %%
               PrfxSize = DSpace + RefVarNameLen
               SfxSize = 0
            end

            %%
            NewSize =  Size + PrfxSize + SfxSize
            size <- NewSize

            %%
            job
               {self.parentObj checkSize(self Size NewSize)}
            end
         end
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%  Procedures;
   %%
   class ProcedureTWTermObject
      from NameTWTermObject
      %%
   end

   %%
   %%
   %%  Cells;
   %%
   class CellTWTermObject
      from NameTWTermObject
      %%
   end

   %%
   %%
   %%  'Meta' class for tuple-like compound terms
   %% (i.e., currently, all compound terms but records);
   %%
   class MetaTupleTWTermObject
      from MetaTWTermObject
      %%
      attr
         shownStartOffset: InitValue       % offset;
         shownTWWidth:     InitValue       % used text widget width;
         shownMetaSize:    InitValue       % used metasize;
         !ReferenceGlue:   InitValue       % used 'subterm' glue (VS);
         !ReferenceGSize:  InitValue       % ... and its size;
         !FirstInc:        InitValue       % offset to subterms from
                                           % 'startOffset';

      %%
      %%
      meth !NewOutInfo(?Info)
         Info = ZeroOutTupleInfo
      end

      %%
      %%
      meth !InitOutInfoRec(_ N SObj ?OutInfo)
         local Size in
            Size  = {SObj getSize($)}
            %%
            size <- @size + Size

            %%
            OutInfo = {AdjoinAt <<NewOutInfo($)>> size Size}
         end
      end

      %%
      %%  Set the empty 'outInfo' records;
      meth initMoreOutInfo(Low High)
\ifdef DEBUG_TW
         {Show 'MetaTupleTWTermObject::initMoreOutInfo: '#self.term#Low#High}
\endif
         case Low =< High then
            Obj NewOutInfoRec
         in
            Obj = <<getSubtermObj(Low $)>>

            %%
            <<InitOutInfoRec(_ Low Obj NewOutInfoRec)>>
            <<setSubtermOutInfo(Low NewOutInfoRec)>>

            %%
            <<initMoreOutInfo((Low + 1) High)>>
         else true
         end
      end

      %%
      %%  Generic 'checkSize';
      %%
      meth checkSize(Obj OldSize NewSize)
\ifdef DEBUG_TW
         {Show 'MetaTupleTWTermObject::checkSize for '#self.term#OldSize#NewSize}
\endif
         local NumberOf StoredObj OutInfo in
            NumberOf = Obj.numberOf
            <<getSubtermObjOutInfo(NumberOf StoredObj OutInfo)>>

            %%
            case Obj == StoredObj then
               case OldSize == NewSize then true
               else
                  MyOldSize MyNewSize NewOutInfo
               in
                  MyOldSize = @size

                  %%
                  MyNewSize = MyOldSize - OldSize + NewSize
                  size <- MyNewSize

                  %%
                  NewOutInfo = {AdjoinAt OutInfo size NewSize}
                  <<setSubtermOutInfo(NumberOf NewOutInfo)>>

                  %%
                  job
                     {self.parentObj checkSize(self MyOldSize MyNewSize)}
                  end
               end
            else true           % ignore irrelevant message;
            end
         end
      end

      %%
      %%  Generic 'checkLayout';
      %%
      meth checkLayout
         case @shown then
            ActualTWWidth StartOffset MetaSize
         in
            ActualTWWidth = {self.store read(StoreTWWidth $)}
            StartOffset = {self.widgetObj getTagFirst(self $)}
            MetaSize = @size

            %%
            %%  Attention!
            %%  These conditions seem to be a ***reasonable***
            %% approximation for a "term's layout need not to be
            %% changed" test, but nothing more;
            %%  This is obviously that corresponding contra-
            %% examples can be constructed, but the *correct*
            %% implementation needs complex control structures,
            %% much more memory and execution time;
            %%  Practically these conditions seem to be enough;
            %%
\ifdef DEBUG_TW
            job
               {Wait StartOffset}
               {Wait MetaSize}
               {Wait ActualTWWidth}

               %%
               {Show 'MetaTupleTWTermObject::checkLayout is applied '#
                self.term}
               {Show StartOffset#MetaSize#ActualTWWidth}
            end
\endif
            case
               @shownStartOffset == StartOffset andthen
               @shownMetaSize == MetaSize andthen
               @shownTWWidth == ActualTWWidth
            then
               <<UrObject nil>>
            else
               StartSubOffset SubsOffset OutOffset
            in
               shownStartOffset <- StartOffset
               shownMetaSize <- MetaSize
               shownTWWidth <- ActualTWWidth

               %%
               case ActualTWWidth - StartOffset > MetaSize then
                  %% in one row;
                  StartSubOffset = ~1
                  ReferenceGlue <- DSpaceGlue
                  ReferenceGSize <- DSpace

                  %%  we don't need resulting offset
                  %% (actually, it should be the same!);
                  <<adjustNameGlue((StartOffset + @FirstInc) _)>>
               else
                  %% in many rows;
                  %%
                  SubsOffset = StartOffset + {Min @FirstInc DOffset}
                  ReferenceGlue <- {CreateGlue SubsOffset}
                  ReferenceGSize <- SubsOffset + DSpace + 1

                  %%  Note: 'adjustNameGlue' requires 'ReferenceGlue'
                  %% and 'ReferenceGSize' attributes!
                  StartSubOffset =
                  <<adjustNameGlue((StartOffset + @FirstInc) $)>>
               end

               %%  Resulting offset (the third arg)
               %% is not actually interesting - only sync;
               <<mapObjIndArg(AdjustGlue StartSubOffset OutOffset)>>

               %%
               {Wait OutOffset}

               %%
               <<UrObject nil>>
            end
         else
            true                % ignore;
         end
      end

      %%
      %%
      %%  Generic 'adjustNameGlue' - nothing to do;
      meth adjustNameGlue(OffsetIn ?OffsetOut)
         OffsetOut = OffsetIn
      end

      %%
      %%  Generic 'AdjustGlue'. Should be used with 'mapObjIndArg';
      %%
      meth !AdjustGlue(OutInfoIn N SObj SubsOffset ?NewSubsOffset ?OutInfoOut)
         %% \ifdef DEBUG_TW
         %% {Show 'MetaTupleTWTermObject::AdjustGlue is applied: '#
         %%  self.term#N#SubsOffset}
         %% \endif
         {SObj checkLayout}

         %%  two cases - last object (glueSize == 0) or not;
         case <<isLastAny(N $)>> then
            %% nothing more to do;
            NewSubsOffset = SubsOffset
            OutInfoOut = OutInfoIn
         else
            case SubsOffset == ~1 then
               %%  "One row" representation -
               %%  remove compound glues;

               %%
               case OutInfoIn.glueSize
               of 0 then
                  {BrowserError ['...::AdjustTupleGlue: gluesSize = 0']}
                  OutInfoOut = OutInfoIn
               [] !DSpace then
                  OutInfoOut = OutInfoIn
               else
                  {self.widgetObj
                   deleteAfterMark(OutInfoIn.mark DSpace
                                   (OutInfoIn.glueSize - DSpace))}

                  %%
                  OutInfoOut = {AdjoinAt OutInfoIn glueSize DSpace}
               end

               %%
               NewSubsOffset = SubsOffset
            else
               %%  'Multirow' representation - there could be
               %% compound glues;
               NextOutInfo RefSize GlueSize
            in
               <<getAnySubtermOutInfo((N + 1) NextOutInfo)>>
               GlueSize = OutInfoIn.glueSize
               RefSize = @ReferenceGSize

               %%
               case
                  SubsOffset + OutInfoIn.size + NextOutInfo.size +
                  DDSpace < @shownTWWidth
               then
                  %%
                  %%  Next one in the same row;
                  NewSubsOffset = SubsOffset + OutInfoIn.size + DSpace

                  %%
                  case GlueSize == DSpace then
                     OutInfoOut = OutInfoIn
                  else
                     %% truncate;
                     {self.widgetObj
                      deleteAfterMark(OutInfoIn.mark DSpace
                                      (OutInfoIn.glueSize - DSpace))}

                     %%
                     OutInfoOut = {AdjoinAt OutInfoIn glueSize DSpace}
                  end
               else
                  %%
                  %%  Next one on the next row;
                  %%
                  NewSubsOffset = RefSize - DSpace - 1

                  %%
                  case GlueSize == RefSize then
                     %% offset, 'glue char' (DSpace) and '\n' (1);
                     OutInfoOut = OutInfoIn
                  else
                     %%  adjust the glue;;
                     case GlueSize > DSpace then
                        case GlueSize < RefSize then
                           Spaces
                        in
                           Spaces = {CreateSpaces (RefSize - GlueSize)}

                           %%
                           {self.widgetObj
                            insertAfterMark(OutInfoIn.mark
                                            GlueSize
                                            Spaces)}
                        else
                           {self.widgetObj
                            deleteAfterMark(OutInfoIn.mark
                                            RefSize
                                            (GlueSize - RefSize))}
                        end
                     else
                        %%  GlueSize == DSpace -
                        %% insert exactly '@ReferenceGlue';
                        %% (it seems to be a very frequent case;)
                        {self.widgetObj
                         insertAfterMark(OutInfoIn.mark
                                         GlueSize
                                         @ReferenceGlue)}
                     end

                     %%
                     OutInfoOut = {AdjoinAt OutInfoIn glueSize RefSize}
                  end
               end
            end
         end
      end

      %%
      %%
      meth insertRefVar
\ifdef DEBUG_TW
         {Show 'MetaTupleTWTermObject::insertRefVar: '#self.term}
\endif
         case @shown then
            Tags RefVarName RefVarNameLen Size NewSize PrfxSize SfxSize
         in
            %%
            Tags = {self.GetTags self}
            RefVarName = @refVarName
            RefVarNameLen = {VSLength RefVarName}
            Size = @size

            %%
            case <<needsBracesRef($)>> then
               {self.widgetObj [insertBeforeTag(self Tags
                                                DLRBraceS#RefVarName#DEqualS)
                                insertAfterTag(self Tags DRRBraceS)]}

               %%
               PrfxSize = DDSpace + RefVarNameLen
               SfxSize = DSpace
            else
               {self.widgetObj insertBeforeTag(self Tags RefVarName#DEqualS)}

               %%
               PrfxSize = DSpace + RefVarNameLen
               SfxSize = 0
            end

            %%
            FirstInc <- @FirstInc + PrfxSize
            NewSize =  Size + PrfxSize + SfxSize
            size <- NewSize

            %%
            job
               {self.parentObj checkSize(self Size NewSize)}
            end
         else
            RefVarName RefVarNameLen Size NewSize PrfxSize SfxSize
         in
            %%
            RefVarName = @refVarName
            RefVarNameLen = {VSLength RefVarName}
            Size = @size

            %%
            case <<needsBracesRef($)>> then
               %%
               PrfxSize = DDSpace + RefVarNameLen
               SfxSize = DSpace
            else
               %%
               PrfxSize = DSpace + RefVarNameLen
               SfxSize = 0
            end

            %%
            NewSize =  Size + PrfxSize + SfxSize
            size <- NewSize

            %%
            job
               {self.parentObj checkSize(self Size NewSize)}
            end
         end
      end

      %%
      %%
      meth undraw
         case @shown then
            TmpTag
         in
            %%
            {self.widgetObj [genTag(TmpTag) duplicateTag(self TmpTag)]}

            %%
            <<setUndrawn>>

            %%
            %%  closeTag both deletes the tag and closes the object;
            {self.widgetObj [delete(TmpTag)
                             closeTag(TmpTag)]}

            %%
            <<UrObject nil>>
         else true
         end
      end

      %%
      %%
      meth setUndrawn
         %%
         <<sendMessages(setUndrawn)>>

         %%
         <<mapObjInd(RemoveMark)>>

         %%
         {self.widgetObj deleteTag(self)}

         %%
         shown <- False
      end

      %%
      %%
      meth RemoveMark(OutInfoIn _ _ OutInfoOut)
         local Mark in
            Mark = OutInfoIn.mark

            %%
            case Mark == InitValue then true
               %% actually, it looks quite suspicious;
            else
               {self.widgetObj unsetMark(Mark)}
            end

            %%
            OutInfoOut = {AdjoinAt OutInfoIn mark InitValue}
         end
      end

      %%
      %%
      meth drawSubterm(N)
         local Obj OutInfo Syncs in
            <<getSubtermObjOutInfo(N Obj OutInfo)>>

            %%
            <<DrawSubterm(OutInfo N Obj nil Syncs _)>>

            %%
            {Wait Syncs.1}

            %%
            <<UrObject nil>>
         end
      end

      %%
      %%  ... almost the same as 'drawSubterm', but a new glue is produced,
      %% if needed, and term's metasize is updated (also if needed);
      meth drawNewSubterm(N)
\ifdef DEBUG_TW
         {Show 'MetaTupleTWTermObject::drawNewSubterm: '#self.term#N}
\endif
         local Obj OutInfo NewOutInfo in
            <<getSubtermObjOutInfo(N Obj OutInfo)>>

            %%
            case OutInfo.mark == InitValue then
               %%  so, there is not yet subterm's glue;
               %%  Let us make it from
               PreNum PreObj PreOutInfo NewPreOutInfo OldMark NewMark
               RightMostMarks WidgetObj
            in
               PreNum = N - 1
               <<getSubtermObjOutInfo(PreNum PreObj PreOutInfo)>>

               %%
               case PreOutInfo == InitValue then
                  {BrowserError
                   ['MetaTupleTWTermObj::drawNewSubterm: not implemented']}
               else
                  %%
                  RightMostMarks = {PreObj GetRightMostMarks($)}
                  WidgetObj = self.widgetObj

                  %%
                  OldMark = PreOutInfo.mark

                  %%
                  case {All RightMostMarks IsValue} then
                     %%
                     %%  Note that 'CreateSimpleGlue' handles non-enclosed
                     %% structures properly (i.e. extends (sub)term's
                     %% tag(s));
                     <<CreateSimpleGlue(OldMark NewMark)>>

                     %%  NOTE !!!
                     %%  Actually, this is not correct as well.
                     %% The potential problem is that those non-enclosed
                     %% objects may be replaced between generating a new glue
                     %% (previous lines) and this point. So, a really
                     %% correct solution would be either (a) produce a glue
                     %% and move "rightmost" marks in _atomic_ fashion,
                     %% or (b) block corresponding subterm objects (all of
                     %% them, not only direct one!);
                     {ForAll RightMostMarks
                      proc {$ MarkMoved}
                         %% actually, not duplicate, - but just reset it;
                         {WidgetObj duplicateMark(NewMark MarkMoved)}
                      end}

                     %%
                     %%  Update 'OutInfo' for previous subterm -
                     %% set the newly created mark in it;
                     NewPreOutInfo = {Adjoin PreOutInfo
                                      twInfo(mark:     NewMark
                                             glueSize: DSpace)}
                     <<setSubtermOutInfo(PreNum NewPreOutInfo)>>

                     %%  ... and now, 'OldMark' is our new mark;
                     %%  Note that 'size' is already in there;
                     NewOutInfo = {Adjoin OutInfo
                                   twInfo(mark:     OldMark
                                          glueSize: PreOutInfo.glueSize)}
                     <<setSubtermOutInfo(N NewOutInfo)>>

                     %%
                     %%  The 'checkLayout' method should be applied later;
                     {Wait {Obj draw(OldMark $)}}

                     %%
                     %%  'meta' size of the subterm just added should
                     %% be already there (by 'InitOutInfoRec');
                     size <- @size + DSpace
                  end
               end
            else
               ObjSize
            in
               %%
               %%  there were a subterm before;
               %%  Note that that subterm should be undrawn
               %% (and, actually, destroyed) already;
               %%
               ObjSize = {Obj getSize($)}

               %%
               % {Wait ObjSize}
               %%
               NewOutInfo = {AdjoinAt OutInfo size ObjSize}
               <<setSubtermOutInfo(N NewOutInfo)>>

               %%
               {Wait {Obj draw(OutInfo.mark $)}}

               %%
               %%  subtract old subterm's 'meta' size and add
               %% it from the new one;
               size <- @size - OutInfo.size + ObjSize
            end
         end
      end

      %%
      %%
      %%  Perform 'drawSubterm' for all numbers >= Low && =< High;
      meth drawNewSubterms(Low High)
         case Low =< High then
            %%
            <<drawNewSubterm(Low)>>

            %%
            <<drawNewSubterms((Low + 1) High)>>
         else true
         end
      end

      %%
      %%  *** Async ***
      %%
      %%  Generic 'draw subterm';
      meth !DrawSubterm(OutInfoIn N SObj SListIn ?SListOut ?OutInfoOut)
         local Sync in
            job
               {SObj draw(OutInfoIn.mark Sync)}
            end

            %%
            SListOut = Sync|SListIn
            OutInfoOut = OutInfoIn
         end
      end

      %%
      %%
      meth !AddSimpleGlue(OutInfoIn N _ TmpMark ?NewTmpMark ?OutInfoOut)
         case OutInfoIn.mark == InitValue then
            case <<isLastAny(N $)>> then
               %%
               OutInfoOut = {Adjoin OutInfoIn
                             twInfo(mark: TmpMark glueSize: 0)}
               NewTmpMark = InitValue   % consumed;
            else
               Mark
            in
               %%  'CreateSimpleGlue' is taken from appropriate class;
               <<CreateSimpleGlue(TmpMark Mark)>>

               %%
               OutInfoOut = {Adjoin OutInfoIn
                             twInfo(mark:     Mark
                                    glueSize: DSpace)}
               NewTmpMark = TmpMark
            end
         else
            {BrowserError ['MetaTupleTWTermObject::AddSimpleGlue: error!']}
         end
      end

      %%
      %%  not a problem for enclosed structures (and all it's childs);
      meth !GetRightMostMarks(?Marks)
         Marks = nil
      end

      %%
   end

   %%
   %%
   %%  WFList Text Widget Term Object;
   %%
   class WFListTWTermObject
      from MetaTupleTWTermObject
      %%
      feat
         isEnclosed: fun {$ Self} True end

      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'WFListObject::initOut method for the term '#self.term}
\endif
         %%
         <<tagInit>>

         %%
         shown <- False

         %%
         case <<areCommas($)>> then
            %%
            %% commas;
            Obj
            in
            Obj = {New PseudoTermTWCommas init(parentObj: self)}

            %%
            <<setCommasObj(Obj)>>
         else true
         end

         %% '[]' + (TotalWidth - DSpace), i.e. without subterms so far;
         size <- DSpace + <<getTotalWidth($)>>

         %%
         case @refVarName == '' then true
            else
            size <- @size + DSpace + {VSLength @refVarName} +
            case <<needsBracesRef($)>> then DSpace else 0 end
         end

         %%  sets both subterm sizes and global size ('@size');
         <<mapObjInd(InitOutInfoRec)>>
         %%
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'WFListObject::draw method for the term '#self.term#Mark}
\endif
\ifdef DEBUG_TW
         case @shown then
            {BrowserError ['...:draw for shown term?']}
         else true
         end
\endif
         local ActualTWWidth StartOffset TmpMark SyncList PTag in
            %%
            %% Force subsequent 'adjustGlues';
            shownStartOffset <- 0
            shownTWWidth <- DInfinite
            shownMetaSize <- 0

            %%
            PTag = <<getTagInfo($)>>

            %%
            case @refVarName == '' then
               {self.widgetObj [insertWithTag(Mark DLSBraceS PTag)
                                genTkName(TmpMark)
                                insertWithBoth(Mark DRSBraceS TmpMark PTag)]}
               FirstInc <- DSpace
            else
               case <<needsBracesRef($)>> then
                  {self.widgetObj
                   [insertWithTag(Mark
                                  DLRBraceS#@refVarName#DEqualS#DLSBraceS
                                  PTag)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRSBraceS#DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DTSpace + {VSLength @refVarName}
                  %% '(', '=', '[' and '@refVarName' itself;
               else
                  {self.widgetObj
                   [insertWithTag(Mark @refVarName#DEqualS#DLSBraceS PTag)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRSBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DDSpace + {VSLength @refVarName}
                  %% '=', '[' and '@refVarName' itself;
               end
            end

            %%  Resulting mark is consumed ('_' for third arg);
            <<mapObjIndArg(AddSimpleGlue TmpMark _)>>
            %%
            shown <- True

            %%
            <<checkLayout>>

            %%
            <<initBindings>>

            %%  Draw the subterms;
            %%
            %%  NOTE
            %%  All the subterms are drawn concurrently, but after
            %% finishing the 'checkLayout' for the term itself.
            %% It means that some 'checkLayout' of subterms may use
            %% invalid actual subterm offset (because its
            %% predecessor is not yet drawn completely), but this is
            %% not a problem: if there is more than one subterm in a
            %% row, they fit altogether in this line (and, in turn,
            %% all their glues are simple).
            %%
            <<mapObjIndArg(DrawSubterm nil SyncList)>>
            case {All SyncList IsValue} then
               Sync = True
               <<UrObject nil>>
            end
         end
      end

      %%
      %%
      meth getGlueChar(?GlueChar)
         GlueChar = DSpaceGlue
      end

      %%
      %%  (it is class-depended because glue character;)
      meth !CreateSimpleGlue(Mark NewMark)
         {self.widgetObj [genTkName(NewMark)
                          insertWithMark(Mark DSpaceGlue NewMark)]}
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%
   %%  Tuple Text Widget Term Object;
   %%
   class TupleTWTermObject
      from MetaTupleTWTermObject
      %%
      %%
      feat
         nameGlueMark           % mark after "<label>(' with left gravity;
         isEnclosed: fun {$ Self} True end

      %%
      attr
         nameGlueSize           % (full) size of that glue;

      %%
      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'TupleObject::initOut method for the term '#self.term}
\endif
         local Name NameLen in
            Name = self.name
            NameLen = {VSLength Name}

            %%
            <<tagInit>>

            %%
            self.nameGlueMark = {self.widgetObj genTkName($)}

            %%
            shown <- False

            %%
            case <<areCommas($)>> then
               Obj
            in
               %%
               %% commas;
               Obj = {New PseudoTermTWCommas init(parentObj: self)}

               %%
               <<setCommasObj(Obj)>>
            else true
            end

            %% name, '(' and ')';
            size <- NameLen + DSpace + <<getTotalWidth($)>>

            %%
            case @refVarName == '' then true
            else
               size <- @size + DSpace + {VSLength @refVarName} +
               case <<needsBracesRef($)>> then DSpace else 0 end
            end

            %%
            nameGlueSize <- 0   % no 'name glue' initially;

            %%  sets both subterm sizes and global size ('@size');
            <<mapObjInd(InitOutInfoRec)>>
         end
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'TupleObject::draw method for the term '#self.term#Mark}
\endif
\ifdef DEBUG_TW
         case @shown then
            {BrowserError ['...:draw for shown term?']}
         else true
         end
\endif
         local ActualTWWidth StartOffset TmpMark SyncList PTag in
            %%
            %% Force subsequent 'adjustGlues';
            shownStartOffset <- 0
            shownTWWidth <- DInfinite
            shownMetaSize <- 0

            %%
            PTag = <<getTagInfo($)>>

            %%
            case @refVarName == '' then
               {self.widgetObj [insertWithTag(Mark self.name#DLRBraceS PTag)
                                duplicateMarkLG(Mark self.nameGlueMark)
                                genTkName(TmpMark)
                                insertWithBoth(Mark DRRBraceS TmpMark PTag)]}
               FirstInc <- {VSLength self.name} + DSpace
            else
               case <<needsBracesRef($)>> then
                  {self.widgetObj
                   [insertWithTag(Mark
                                  DLRBraceS#@refVarName#DEqualS#self.name#DLRBraceS
                                  PTag)
                    duplicateMarkLG(Mark self.nameGlueMark)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRRBraceS#DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DTSpace +
                  {VSLength self.name} + {VSLength @refVarName}
                  %% '(', '=', 'self.name', '('and '@refVarName' itself;
               else
                  {self.widgetObj
                   [insertWithTag(Mark @refVarName#DEqualS#self.name#DLRBraceS PTag)
                    duplicateMarkLG(Mark self.nameGlueMark)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DDSpace +
                  {VSLength self.name} + {VSLength @refVarName}
                  %% '=', 'self.name', '(' and '@refVarName' itself;
               end
            end

            %%  Resulting mark is consumed ('_' for third arg);
            <<mapObjIndArg(AddSimpleGlue TmpMark _)>>
            %%
            shown <- True

            %%
            <<checkLayout>>

            %%
            <<initBindings>>

            %%
            <<mapObjIndArg(DrawSubterm nil SyncList)>>
            case {All SyncList IsValue} then
               Sync = True
               <<UrObject nil>>
            end
         end
      end

      %%
      %%
      meth getGlueChar(?GlueChar)
         GlueChar = DSpaceGlue
      end

      %%
      %%  (it is class-depended because glue character;)
      meth !CreateSimpleGlue(Mark NewMark)
         {self.widgetObj [genTkName(NewMark)
                          insertWithMark(Mark DSpaceGlue NewMark)]}
      end

      %%
      %%
      %%  replacement for empty 'adjustNameGlue' (generic one);
      meth adjustNameGlue(OffsetIn ?OffsetOut)
         local FirstSTOutInfo ReferenceGlueSize NameGlueSize in
            FirstSTOutInfo = <<getAnySubtermOutInfo(1 $)>>
            ReferenceGlueSize = @ReferenceGSize
            NameGlueSize = @nameGlueSize

            %%
            case
               OffsetIn + FirstSTOutInfo.size + DSpace > @shownTWWidth andthen
               @FirstInc > DOffset
            then
               %%
               %% 'name glue' should be there;
               case NameGlueSize == ReferenceGlueSize then true
               elsecase NameGlueSize > ReferenceGlueSize then
                  %%
                  %% truncate the 'name glue';
                  {self.widgetObj
                   deleteAfterMark(self.nameGlueMark ReferenceGlueSize
                                   (NameGlueSize - ReferenceGlueSize))}

                  %%
                  nameGlueSize <- ReferenceGlueSize
               else
                  %%
                  %% extend it (ReferenceGlueSize > NameGlueSize);
                  case NameGlueSize == 0 then
                     %%
                     %%  optimization - just insert '@ReferenceGlue';
                     %%  Note that where should be also a blank
                     %% (because reference glue is " "#"\n"#<spaces>;
                     {self.widgetObj
                      insertAfterMark(self.nameGlueMark 0
                                      DSpaceGlue#@ReferenceGlue)}
                  else
                     Spaces
                  in
                     Spaces =
                     {CreateSpaces (ReferenceGlueSize - NameGlueSize)}

                     %%
                     {self.widgetObj
                      insertAfterMark(self.nameGlueMark NameGlueSize Spaces)}
                  end

                  %%
                  nameGlueSize <- ReferenceGlueSize
               end

               %%
               OffsetOut = ReferenceGlueSize - DSpace - 1
            else
               %%
               %% there should be no 'name glue';
               case NameGlueSize == 0 then true
               else
                  %%
                  %%  remove everything;
                  {self.widgetObj
                   deleteAfterMark(self.nameGlueMark 0 NameGlueSize)}

                  %%
                  nameGlueSize <- 0
               end

               %%
               OffsetOut = OffsetIn
            end
         end
      end

      %%
      %%  ... remove also the 'name glue' mark;
      %%
      meth setUndrawn
         %%
         {self.widgetObj unsetMark(self.nameGlueMark)}
         nameGlueSize <- 0

         %%
         <<MetaTupleTWTermObject setUndrawn>>
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%  'Meta list' text widget term object;
   %%  Contains methods which are specific for non-enclosed
   %% structures;
   %%
   class MetaListTWTermObject
      from MetaTupleTWTermObject
      %%
      %%
      %%
      %%  special edition (since we should insert probable parentheses);
      meth insertRefVar
\ifdef DEBUG_TW
         {Show 'MetaListTWTermObject::insertRefVar: '#self.term}
\endif
         case @shown then
            Tags RefVarName RefVarNameLen Size NewSize PrfxSize SfxSize
         in
            %%
            Tags = {self.GetTags self}
            RefVarName = @refVarName
            RefVarNameLen = {VSLength RefVarName}
            Size = @size

            %%
            case <<needsBracesRef($)>> then
               case <<needsBracesGen($)>> then
                  %%
                  %%  we have already '(<E1>|...|<En>)';
                  {self.widgetObj
                   [insertBeforeTag(self Tags
                                    DLRBraceS#RefVarName#DEqualS)
                    insertAfterTag(self Tags DRRBraceS)]}

                  %%
                  PrfxSize = DDSpace + RefVarNameLen
                  SfxSize = DSpace
               else
                  %%
                  %%  '(RN=(<E1>|...|<En>))';
                  RightMostMarks
               in
                  %%
                  %%  Note that we have to preserve the last subterm's
                  %% mark 'inside' the parentheses;
                  RightMostMarks = <<GetRightMostMarks($)>>

                  %%
                  case {All RightMostMarks IsValue} then
                     {self.widgetObj
                      [setMarksGravity(RightMostMarks left)
                       insertBeforeTag(self Tags
                                       DLRBraceS#RefVarName#DEqualS#DLRBraceS)
                       insertAfterTag(self Tags DRRBraceS)
                       setMarksGravity(RightMostMarks right)]}

                     %%
                     PrfxSize = DTSpace + RefVarNameLen
                     SfxSize = DDSpace

                     %%
                     <<UrObject nil>>
                  end
               end
            else
               case <<needsBracesGen($)>> then
                  %%
                  {self.widgetObj insertBeforeTag(self Tags RefVarName#DEqualS)}

                  %%
                  PrfxSize = DSpace + RefVarNameLen
                  SfxSize = 0
               else
                  %%
                  %%  insert also inner parentheses -
                  %% 'RN=(<E1>#...#<En>)';
                  RightMostMarks
               in
                  %%
                  RightMostMarks = <<GetRightMostMarks($)>>

                  %%
                  case {All RightMostMarks IsValue} then
                     {self.widgetObj
                      [setMarksGravity(RightMostMarks left)
                       insertBeforeTag(self Tags RefVarName#DEqualS#DLRBraceS)
                       insertAfterTag(self Tags DRRBraceS)
                       setMarksGravity(RightMostMarks right)]}

                     %%
                     PrfxSize = DDSpace + RefVarNameLen
                     SfxSize = DSpace

                     %%
                     <<UrObject nil>>
                  end
               end
            end

            %%
            FirstInc <- @FirstInc + PrfxSize
            NewSize =  Size + PrfxSize + SfxSize
            size <- NewSize

            %%
            job
               {self.parentObj checkSize(self Size NewSize)}
            end
         else
            RefVarName RefVarNameLen Size NewSize PrfxSize SfxSize
         in
            %%
            RefVarName = @refVarName
            RefVarNameLen = {VSLength RefVarName}
            Size = @size

            %%
            case <<needsBracesRef($)>> then
               case <<needsBracesGen($)>> then
                  %%
                  PrfxSize = DDSpace + RefVarNameLen
                  SfxSize = DSpace
               else
                  %%
                  PrfxSize = DTSpace + RefVarNameLen
                  SfxSize = DDSpace
               end
            else
               case <<needsBracesGen($)>> then
                  %%
                  PrfxSize = DSpace + RefVarNameLen
                  SfxSize = 0
               else
                  %%
                  PrfxSize = DDSpace + RefVarNameLen
                  SfxSize = DSpace
               end
            end

            %%
            NewSize =  Size + PrfxSize + SfxSize
            size <- NewSize

            %%
            job
               {self.parentObj checkSize(self Size NewSize)}
            end
         end
      end

      %%
      %%
      meth !GetRightMostMarks(?Marks)
         case {self.isEnclosed self} then
            %%  that's all - it behaves as an enclosed structure;
            Marks = nil
         else
            TotalWidth LastObj LastOutInfo NewMarks
         in
            TotalWidth = <<getTotalWidth($)>>
            %%
            <<getAnySubtermObjOutInfo(TotalWidth LastObj LastOutInfo)>>

            %%
            Marks = LastOutInfo.mark|NewMarks
            {LastObj GetRightMostMarks(NewMarks)}
         end
      end

      %%
   end

   %%
   %%
   %%  List Text Widget Term Object;
   %%
   class ListTWTermObject
      from MetaListTWTermObject
      %%
      feat
         isEnclosed: fun {$ Self} {Self.needsBracesGen Self} end
         needsBracesGen: fun {$ Self}
                            %%
                            case Self.parentObj.type
                            of !T_List then
                               case Self.numberOf == 1 then True
                                  %%  i.e. something like (1|2|3)|c;
                               else False
                               end
                            [] !T_FList then True
                               %%  all lists in flat lists are enclosed;
                            [] !T_HashTuple then True
                            else False
                            end
                         end

      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'ListObject::initOut method for the term '#self.term}
\endif
         %%
         <<tagInit>>

         %%
         shown <- False

         %%  single '|';
         size <- DSpace

         %%
         case @refVarName == '' then
            case <<needsBracesGen($)>> then
               size <- @size + DDSpace
            else true
            end
         else
            size <- @size + DSpace + {VSLength @refVarName} +
            case <<needsBracesRef($)>> then DQSpace else DDSpace end
         end

         %%  sets both subterm sizes and global size ('@size');
         <<mapObjInd(InitOutInfoRec)>>
      end

      %%
      %%  Yields 'True' if 'self' should be always enclosed in braces;
      %%  Note that two pairs of them could be produced - one 'generic',
      %% and the second - because reference name tag ('RN=');
      meth needsBracesGen($)
         %%
         {self.needsBracesGen self}
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'ListObject::draw method for the term '#self.term#Mark}
\endif
\ifdef DEBUG_TW
         case @shown then
            {BrowserError ['...:draw for shown term?']}
         else true
         end
\endif
         local ActualTWWidth StartOffset TmpMark SyncList PTag in
            %%
            %% Force subsequent 'adjustGlues';
            shownStartOffset <- 0
            shownTWWidth <- DInfinite
            shownMetaSize <- 0

            %%
            PTag = <<getTagInfo($)>>

            %%
            case @refVarName == '' then
               case <<needsBracesGen($)>> then
                  %% enclosed structure;
                  {self.widgetObj [insertWithTag(Mark DLRBraceS PTag)
                                   genTkName(TmpMark)
                                   insertWithBoth(Mark DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DSpace
               else
                  %% not-enclosed structure!
                  {self.widgetObj [genTkName(TmpMark)
                                   duplicateMark(Mark TmpMark)]}

                  %%
                  FirstInc <- 0
               end
            else
               %%  With refVarName prefix;
               %%  Note that though such a structure is enclosed, it could be
               %% considered as an open one (since 'isEnclosed' yields weaker
               %% information);
               case <<needsBracesRef($)>> then
                  %%
                  %%  Note: in this case we draw *always*
                  %% '(RN=(<CAR>|<CDR>))';
                  {self.widgetObj
                   [insertWithTag(Mark
                                  DLRBraceS#@refVarName#DEqualS#DLRBraceS
                                  PTag)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRRBraceS#DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DTSpace + {VSLength @refVarName}
                  %% '(', '=', '(' and '@refVarName' itself;
               else
                  %%
                  %%  Note: we draw *always* 'RN=(<CAR>|<CDR>)';
                  {self.widgetObj
                   [insertWithTag(Mark @refVarName#DEqualS#DLRBraceS PTag)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DDSpace + {VSLength @refVarName}
                  %% '=', '(' and '@refVarName' itself;
               end
            end

            %%  Resulting mark is consumed ('_' for third arg);
            <<mapObjIndArg(AddSimpleGlue TmpMark _)>>
            %%
            shown <- True

            %%
            <<checkLayout>>

            %%
            <<initBindings>>

            %%
            <<mapObjIndArg(DrawSubterm nil SyncList)>>
            case {All SyncList IsValue} then
               Sync = True
               <<UrObject nil>>
            end
         end
      end

      %%
      %%
      meth getGlueChar(?GlueChar)
         GlueChar = DVBarGlue
      end

      %%
      %%  (it is class-depended because glue character;)
      meth !CreateSimpleGlue(Mark NewMark)
         %%
         %%  Special: if 'first subterm' offset is zero,
         %% the vertical bar should be equipped with tags;
         case @FirstInc == 0 then
            PTag
         in
            PTag = <<getTagInfo($)>>

            %%
            {self.widgetObj [genTkName(NewMark)
                             insertWithBoth(Mark DVBarGlue NewMark PTag)]}
         else
            {self.widgetObj [genTkName(NewMark)
                             insertWithMark(Mark DVBarGlue NewMark)]}
         end
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%  Hash Tuple Text Widget Term Object;
   %%
   class HashTupleTWTermObject
      from MetaListTWTermObject
      %%
      feat
         isEnclosed: fun {$ Self} {Self.needsBracesGen Self} end
         needsBracesGen: fun {$ Self}
                            %%
                            case Self.parentObj.type
                            of !T_HashTuple then True
                               %%  nested hash tuples are enclosed;
                            else False
                            end
                         end

      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'HashTupleObject::initOut method for the term '#self.term}
\endif
         %%
         <<tagInit>>

         %%
         shown <- False

         %%
         case <<areCommas($)>> then
            Obj
         in
            %%
            %% commas;
            Obj = {New PseudoTermTWCommas init(parentObj: self)}

            %%
            <<setCommasObj(Obj)>>
         else true
         end

         %%  (simple) glues _between_ subterms;
         size <- <<getTotalWidth($)>> - DSpace

         %%
         case @refVarName == '' then
            case <<needsBracesGen($)>> then
               size <- @size + DDSpace
            else true
            end
         else
            size <- @size + DSpace + {VSLength @refVarName} +
            case <<needsBracesRef($)>> then DQSpace else DDSpace end
         end

         %%  sets both subterm sizes and global size ('@size');
         <<mapObjInd(InitOutInfoRec)>>
      end

      %%
      %%  Yields 'True' if 'self' should be always enclosed in braces;
      %%  Note that two pairs of them could be produced - one 'generic',
      %% and the second - because reference name tag ('RN=');
      meth needsBracesGen($)
         %%
         {self.needsBracesGen self}
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'HashTupleObject::draw method for the term '#self.term#Mark}
\endif
\ifdef DEBUG_TW
         case @shown then
            {BrowserError ['...:draw for shown term?']}
         else true
         end
\endif
         local ActualTWWidth StartOffset TmpMark SyncList PTag in
            %%
            %% Force subsequent 'adjustGlues';
            shownStartOffset <- 0
            shownTWWidth <- DInfinite
            shownMetaSize <- 0

            %%
            PTag = <<getTagInfo($)>>

            %%
            case @refVarName == '' then
               case <<needsBracesGen($)>> then
                  %% enclosed;
                  {self.widgetObj [insertWithTag(Mark DLRBraceS PTag)
                                   genTkName(TmpMark)
                                   insertWithBoth(Mark DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DSpace
               else
                  %% not enclosed;
                  {self.widgetObj [genTkName(TmpMark)
                                   duplicateMark(Mark TmpMark)]}

                  %%
                  FirstInc <- 0
               end
            else
               %%  With 'refVarName' prefix;
               %%  Note that such a structure could be considered as
               %% non-enclosed as well as (not well-formed) lists;
               case <<needsBracesRef($)>> then
                  %%
                  %% '(RN=(<E1>#...#<En>))';
                  {self.widgetObj
                   [insertWithTag(Mark
                                  DLRBraceS#@refVarName#DEqualS#DLRBraceS
                                  PTag)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRRBraceS#DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DTSpace + {VSLength @refVarName}
                  %% '(', '=', '(' and '@refVarName' itself;
               else
                  %%
                  %% 'RN=(<E1>#...#<En>)';
                  {self.widgetObj
                   [insertWithTag(Mark @refVarName#DEqualS#DLRBraceS PTag)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DDSpace + {VSLength @refVarName}
                  %% '=', '(' and '@refVarName' itself;
               end
            end

            %%  Resulting mark is consumed ('_' for third arg);
            <<mapObjIndArg(AddSimpleGlue TmpMark _)>>
            %%
            shown <- True

            %%
            <<checkLayout>>

            %%
            <<initBindings>>

            %%
            <<mapObjIndArg(DrawSubterm nil SyncList)>>
            case {All SyncList IsValue} then
               Sync = True
               <<UrObject nil>>
            end
         end
      end

      %%
      %%
      meth getGlueChar(?GlueChar)
         GlueChar = DHashGlue
      end

      %%
      %%  (it is class-depended because glue character;)
      meth !CreateSimpleGlue(Mark NewMark)
         %%
         %%  Special: if 'first subterm' offset is zero,
         %% the hash symbol should be equipped with tags;
         case @FirstInc == 0 then
            PTag
         in
            PTag = <<getTagInfo($)>>

            %%
            {self.widgetObj [genTkName(NewMark)
                             insertWithBoth(Mark DHashGlue NewMark PTag)]}
         else
            {self.widgetObj [genTkName(NewMark)
                             insertWithMark(Mark DHashGlue NewMark)]}
         end
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%  Flat List Text Widget Term Object;
   %%
   class FListTWTermObject
      from MetaListTWTermObject
      %%
      feat
         isEnclosed: fun {$ Self} {Self.needsBracesGen Self} end
         needsBracesGen: fun {$ Self}
                            %%
                            case Self.parentObj.type
                            of !T_List then
                               case Self.numberOf == 1 then True
                               else False
                               end
                            [] !T_FList then True
                               %%  always, though at the last position
                               %% they could ommitted;
                            [] !T_HashTuple then True
                            else False
                            end
                         end

      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'HashTupleObject::initOut method for the term '#self.term}
\endif
         %%
         <<tagInit>>

         %%
         shown <- False

         %%
         case <<areCommas($)>> then
            Obj
         in
            %%
            %% commas;
            Obj = {New PseudoTermTWCommas init(parentObj: self)}

            %%
            <<setCommasObj(Obj)>>
         else true
         end

         %%  (simple) glues _between_ subterms;
         size <- <<getTotalWidth($)>> - DSpace

         %%
         case @refVarName == '' then
            case <<needsBracesGen($)>> then
               size <- @size + DDSpace
            else true
            end
         else
            size <- @size + DSpace + {VSLength @refVarName} +
            case <<needsBracesRef($)>> then DQSpace else DDSpace end
         end

         %%  sets both subterm sizes and global size ('@size');
         <<mapObjInd(InitOutInfoRec)>>
      end

      %%
      %%  Yields 'True' if 'self' should be always enclosed in braces;
      %%  Note that two pairs of them could be produced - one 'generic',
      %% and the second - because reference name tag ('RN=');
      meth needsBracesGen($)
         %%
         {self.needsBracesGen self}
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'FListTupleObject::draw method for the term '#self.term#Mark}
\endif
\ifdef DEBUG_TW
         case @shown then
            {BrowserError ['...:draw for shown term?']}
         else true
         end
\endif
         local ActualTWWidth StartOffset TmpMark SyncList PTag in
            %%
            %% Force subsequent 'adjustGlues';
            shownStartOffset <- 0
            shownTWWidth <- DInfinite
            shownMetaSize <- 0

            %%
            PTag = <<getTagInfo($)>>

            %%
            case @refVarName == '' then
               case <<needsBracesGen($)>> then
                  %% enclosed;
                  {self.widgetObj [insertWithTag(Mark DLRBraceS PTag)
                                   genTkName(TmpMark)
                                   insertWithBoth(Mark DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DSpace
               else
                  %% not enclosed;
                  {self.widgetObj [genTkName(TmpMark)
                                   duplicateMark(Mark TmpMark)]}

                  %%
                  FirstInc <- 0
               end
            else
               %%  With 'refVarName' prefix;
               %%  Note that such a structure could be considered as
               %% non-enclosed as well as (not well-formed) lists;
               case <<needsBracesRef($)>> then
                  %%
                  %% '(RN=(<E1>|...|<En>))';
                  {self.widgetObj
                   [insertWithTag(Mark
                                  DLRBraceS#@refVarName#DEqualS#DLRBraceS
                                  PTag)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRRBraceS#DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DTSpace + {VSLength @refVarName}
                  %% '(', '=', '(' and '@refVarName' itself;
               else
                  %%
                  %% 'RN=(<E1>|...|<En>)';
                  {self.widgetObj
                   [insertWithTag(Mark @refVarName#DEqualS#DLRBraceS PTag)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DDSpace + {VSLength @refVarName}
                  %% '=', '(' and '@refVarName' itself;
               end
            end

            %%  Resulting mark is consumed ('_' for third arg);
            <<mapObjIndArg(AddSimpleGlue TmpMark _)>>

            %%
            shown <- True

            %%
            <<checkLayout>>

            %%
            <<initBindings>>

            %%
            <<mapObjIndArg(DrawSubterm nil SyncList)>>
            case {All SyncList IsValue} then
               Sync = True
               <<UrObject nil>>
            end
         end
      end

      %%
      %%  specially for flat lists;
      meth drawCommas
         local
            Width LastSTOutInfo NewLastSTOutInfo Obj
            OutInfo NewOutInfo NewMark OldMark
         in
            Width = @width

            %%
            <<addCommasRec>>

            %%
            Obj = {New PseudoTermTWCommas init(parentObj: self)}
            <<setCommasObj(Obj)>>

            %%
            <<InitOutInfoRec(_ <<getCommasNum($)>> Obj OutInfo)>>

            %%
            LastSTOutInfo = <<getSubtermOutInfo(Width $)>>
            OldMark = LastSTOutInfo.mark

            %%
            <<CreateSimpleGlue(OldMark NewMark)>>

            %%  General rule: 'new' and 'old' glues exchange their marks
            %% and (glue) sizes;
            NewLastSTOutInfo = {Adjoin LastSTOutInfo
                                twInfo(mark:     NewMark
                                       glueSize: DSpace)}
            <<setSubtermOutInfo(Width NewLastSTOutInfo)>>

            %%
            {Wait {Obj draw(OldMark $)}}

            %%
            NewOutInfo = {Adjoin OutInfo
                             twInfo(glueSize: LastSTOutInfo.glueSize
                                    mark:     OldMark)}

            %%
            <<setCommasOutInfo(NewOutInfo)>>

            %%
            size <- @size + DSpace   % new simple glue;
         end
      end

      %%
      %%
      meth getGlueChar(?GlueChar)
         GlueChar = DVBarGlue
      end

      %%
      %%  (it is class-depended because glue character;)
      meth !CreateSimpleGlue(Mark NewMark)
         %%
         %%  Special: if 'first subterm' offset is zero,
         %% the vertical bar should be equipped with tags;
         case @FirstInc == 0 then
            PTag
         in
            PTag = <<getTagInfo($)>>

            %%
            {self.widgetObj [genTkName(NewMark)
                             insertWithBoth(Mark DVBarGlue NewMark PTag)]}
         else
            {self.widgetObj [genTkName(NewMark)
                             insertWithMark(Mark DVBarGlue NewMark)]}
         end
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%  'Meta' class for record-like compound terms
   %%
   class MetaRecordTWTermObject
      from MetaTupleTWTermObject
      %%
      %% inherited from 'MetaTupleTWTermObject';
      %% shownStartOffset: InitValue       % (wf)list's offset;
      %% shownTWWidth:     InitValue       % used text widget width;
      %% shownMetaSize:    InitValue       % used metasize;
      %% !ReferenceGlue:   InitValue       % used 'subterm' glue (VS);
      %% !ReferenceGSize:  InitValue       % ... and its size;
      %% !FirstInc:        InitValue       % offset to subterms from
      %%                                   % 'startOffset';
      %%
      feat
         nameGlueMark           % becomes common for records;
         isEnclosed: fun {$ Self} True end

      %%
      attr
         nameGlueSize           % ...
         recordsAligned         % is 'True' if they should be aligned;

      %%
      %%
      meth !NewOutInfo(?Info)
         Info = ZeroOutRecInfo
      end

      %%
      %%  ... 'meta' size should be extended with prefix sizes too;
      meth !InitOutInfoRec(_ N SObj ?OutInfo)
         local Size PrfxSize PNum PrfxSize in
            PNum = <<getProperNum(N $)>>
            Size  = {SObj getSize($)}

            %%
            case PNum == 0 then
               %%
               PrfxSize = 0
            else
               %%
               PrfxSize =
               {VSLength <<genLitPrintName(@recFeatures.PNum $)>>} +
               DDSpace
               %% <<getFeatDelSize($)>>
               %% ': ' is of size DDSpace
            end

            %%
            size <- @size + Size + PrfxSize

            %%
            OutInfo = {Adjoin <<NewOutInfo($)>>
                       twInfo(size:     Size
                              prfxSize: PrfxSize)}
         end
      end

      %%
      %%  'initMoreOutInfo' is inherited from 'MetaTupleTWTermObject';
      %%
      %%  'checkSize' and 'checkLayout' are is inherited from
      %% 'MetaTupleTWTermObject';
      %%
      %%
      %%  Record-specific 'adjustNameGlue';
      %%
      meth adjustNameGlue(OffsetIn ?OffsetOut)
         local
            FirstSTOutInfo ReferenceGlueSize NameGlueSize
            RecordsAligned ForcedOneRow
         in
            FirstSTOutInfo = <<getAnySubtermOutInfo(1 $)>>
            ReferenceGlueSize = @ReferenceGSize
            NameGlueSize = @nameGlueSize

            %%
            RecordsAligned = case {self.store read(StoreFillStyle $)}
                             of !Expanded then True
                             [] !Filled then False
                             else
                                {BrowserError ['invalid fill style!']}
                                False
                             end
            recordsAligned <- RecordsAligned

            %%
            ForcedOneRow =
            case RecordsAligned then
               %%  if the 'reference' glue is a blank, it's one-row
               %% representation;
               case @ReferenceGSize == DSpace then False
               else True
               end
            else False
            end

            %%
            case
               (ForcedOneRow orelse
                OffsetIn + FirstSTOutInfo.size + FirstSTOutInfo.prfxSize +
                DSpace > @shownTWWidth) andthen
               @FirstInc > DOffset
            then
               %%
               %% 'name glue' should be there;
               case NameGlueSize == ReferenceGlueSize then true
               elsecase NameGlueSize > ReferenceGlueSize then
                  %%
                  %% truncate the 'name glue';
                  {self.widgetObj
                   deleteAfterMark(self.nameGlueMark ReferenceGlueSize
                                   (NameGlueSize - ReferenceGlueSize))}

                  %%
                  nameGlueSize <- ReferenceGlueSize
               else
                  %%
                  %% extend it (ReferenceGlueSize > NameGlueSize);
                  case NameGlueSize == 0 then
                     %%
                     %%  optimization - just insert '@ReferenceGlue';
                     %%  Note that where should be also a blank
                     %% (because reference glue is " "#"\n"#<spaces>;
                     {self.widgetObj
                      insertAfterMark(self.nameGlueMark 0
                                      DSpaceGlue#@ReferenceGlue)}
                  else
                     Spaces
                  in
                     Spaces = {CreateSpaces (ReferenceGlueSize - NameGlueSize)}

                     %%
                     {self.widgetObj
                      insertAfterMark(self.nameGlueMark NameGlueSize Spaces)}
                  end

                  %%
                  nameGlueSize <- ReferenceGlueSize
               end

               %%
               OffsetOut = ReferenceGlueSize - DSpace - 1
            else
               %%
               %% there should be no 'name glue';
               case NameGlueSize == 0 then true
               else
                  %%  remove everything;
                  {self.widgetObj
                   deleteAfterMark(self.nameGlueMark 0 NameGlueSize)}

                  %%
                  nameGlueSize <- 0
               end

               %%
               OffsetOut = OffsetIn
            end
         end
      end

      %%
      %%  Generic (record) 'AdjustGlue'. Should be used with 'mapObjIndArg';
      %%
      meth !AdjustGlue(OutInfoIn N SObj SubsOffset ?NewSubsOffset ?OutInfoOut)
         %%
         {SObj checkLayout}

         %%
         %%  two cases - last object (glueSize == 0) or not;
         case <<isLastAny(N $)>> then
            %% nothing more to do;
            NewSubsOffset = SubsOffset
            OutInfoOut = OutInfoIn
         else
            case SubsOffset == ~1 then
               %%  "One row" representation -
               %%  remove compound glues;
               case OutInfoIn.glueSize
               of 0 then
                  {BrowserError ['...::AdjustRecordGlue: gluesSize = 0']}
                  OutInfoOut = OutInfoIn
               [] !DSpace then
                  OutInfoOut = OutInfoIn
               else
                  {self.widgetObj
                   deleteAfterMark(OutInfoIn.mark DSpace
                                   (OutInfoIn.glueSize - DSpace))}

                  %%
                  OutInfoOut = {AdjoinAt OutInfoIn glueSize DSpace}
               end

               %%
               NewSubsOffset = SubsOffset
            else
               %%  'Multirow' representation - there could be
               %% compound glues;
               NextOutInfo RefSize GlueSize
            in
               <<getAnySubtermOutInfo((N + 1) NextOutInfo)>>
               GlueSize = OutInfoIn.glueSize
               RefSize = @ReferenceGSize

               %%
               case
                  @recordsAligned orelse
                  SubsOffset + OutInfoIn.size + NextOutInfo.size +
                  OutInfoIn.prfxSize + NextOutInfo.prfxSize +
                  DDSpace >= @shownTWWidth
               then
                  %%
                  %%  Next one on the next row;
                  %%
                  NewSubsOffset = RefSize - DSpace - 1

                  %%
                  case GlueSize == RefSize then
                     %% offset, 'glue char' (DSpace) and '\n' (1);
                     OutInfoOut = OutInfoIn
                  else
                     %%  adjust the glue;;
                     case GlueSize > DSpace then
                        case GlueSize < RefSize then
                           Spaces
                        in
                           Spaces = {CreateSpaces (RefSize - GlueSize)}

                           %%
                           {self.widgetObj
                            insertAfterMark(OutInfoIn.mark
                                            GlueSize
                                            Spaces)}
                        else
                           {self.widgetObj
                               deleteAfterMark(OutInfoIn.mark
                                               RefSize
                                               (GlueSize - RefSize))}
                        end
                     else
                        %%  GlueSize == DSpace -
                        %% insert exactly '@ReferenceGlue';
                        %% (it seems to be a very frequent case;)
                        {self.widgetObj
                         insertAfterMark(OutInfoIn.mark
                                            GlueSize
                                         @ReferenceGlue)}
                     end

                     %%
                     OutInfoOut = {AdjoinAt OutInfoIn glueSize RefSize}
                  end
               else
                  %%
                  %%  Next one in the same row;
                  NewSubsOffset =
                  SubsOffset + OutInfoIn.size + OutInfoIn.prfxSize +
                  DSpace

                  %%
                  case GlueSize == DSpace then
                     OutInfoOut = OutInfoIn
                  else
                     %% truncate;
                     {self.widgetObj
                      deleteAfterMark(OutInfoIn.mark DSpace
                                      (OutInfoIn.glueSize - DSpace))}

                     %%
                     OutInfoOut = {AdjoinAt OutInfoIn glueSize DSpace}
                  end
               end
            end
         end
      end

      %%
      %%  'insertRefVar' is inherited from 'MetaTupleTWTermObject';
      %%  'undraw' is inherited from 'MetaTupleTWTermObject';
      %%  'setUndrawn' is inherited from 'MetaTupleTWTermObject';
      %%  'drawSubterm' is inherited from 'MetaTupleTWTermObject';
      %%  'DrawSubterm' is inherited from 'MetaTupleTWTermObject';
      %%
      %%
      %%  'AddSimpleGlue' must be replaced since subterm prefixes
      %% (i.e. feature names) should be inserted too;
      %%
      meth !AddSimpleGlue(OutInfoIn N _ TmpMark ?NewTmpMark ?OutInfoOut)
         case OutInfoIn.mark == InitValue then
            case <<isLastAny(N $)>> then
               PNum
            in
               PNum = <<getProperNum(N $)>>

               %%
               case PNum
               of 0 then true
                  %% no prefix;
               else
                  FName
               in
                  FName =
                  <<genLitPrintName(@recFeatures.PNum $)>>

                  %%
                  case {VirtualString.is FName} then
                     {self.widgetObj
                      insert(TmpMark FName#DColonS#DSpaceGlue)}
                     %% insert(TmpMark FName#<<getFeatDel($)>>)}

                     %%
                     <<UrObject nil>>
                  end
               end

               %%
               OutInfoOut = {Adjoin OutInfoIn
                             twInfo(mark: TmpMark
                                    glueSize: 0)}
               NewTmpMark = InitValue   % consumed;
            else
               PNum Mark
            in
               PNum = <<getProperNum(N $)>>

               %%
               case PNum
               of 0 then
                  %%
                  %% 'pseudo' subterm - no prefix;
                  <<CreateSimpleGlue(TmpMark Mark)>>
                  %%
               else
                  %%
                  %% 'proper' subterm - insert a feature name;
                  FName
               in
                  %%
                  <<CreateSimpleGlue(TmpMark Mark)>>

                  %%
                  FName =
                  <<genLitPrintName(@recFeatures.PNum $)>>

                  %%
                  case {VirtualString.is FName} then
                     {self.widgetObj
                      insert(Mark FName#DColonS#DSpaceGlue)}
                     %% insert(Mark FName#<<getFeatDel($)>>)}

                     %%
                     <<UrObject nil>>
                  end
               end

               %%
               OutInfoOut = {Adjoin OutInfoIn
                             twInfo(mark: Mark
                                    glueSize: DSpace)}
               NewTmpMark = TmpMark
            end
         else
            {BrowserError ['MetaRecordTWTermObject::AddSimpleGlue: error!']}
         end
      end

      %%
      %%
      %%  ... very similar to the 'drawNewSubterm' from 'MetaTupleTWTermObject',
      %% but we have to insert also feature names;
      meth drawNewSubterm(N)
\ifdef DEBUG_TW
         {Show 'MetaRecordTWTermObject::drawNewSubterm: '#self.term#N}
\endif
         local Obj OutInfo NewOutInfo in
            <<getSubtermObjOutInfo(N Obj OutInfo)>>

            %%
            case OutInfo.mark == InitValue then
               %%  so, there is not yet subterm's glue;
               %%
               PreNum PreObj PreOutInfo NewPreOutInfo OldMark NewMark
               FName RightMostMarks WidgetObj
            in
               PreNum = N - 1
               <<getSubtermObjOutInfo(PreNum PreObj PreOutInfo)>>

               %%
               case PreOutInfo == InitValue then
                  {BrowserError
                   ['MetaTupleTWTermObj::drawNewSubterm: not implemented']}
               else
                  %%
                  RightMostMarks = {PreObj GetRightMostMarks($)}
                  WidgetObj = self.widgetObj

                  %%
                  OldMark = PreOutInfo.mark

                  %%
                  case {All RightMostMarks IsValue} then
                     %%
                     %%  Note that 'CreateSimpleGlue' handles non-enclosed
                     %% structures properly (i.e. extends (sub)term's
                     %% tag(s));
                     <<CreateSimpleGlue(OldMark NewMark)>>

                     %%  NOTE !!!
                     %%  See the comment in
                     %% 'MetaTupleTWTermObject::drawNewSubterm'
                     {ForAll RightMostMarks
                      proc {$ MarkMoved}
                         {WidgetObj duplicateMark(NewMark MarkMoved)}
                      end}

                     %%  Update 'OutInfo' for previous subterm -
                     %% set the newly created mark in it;
                     NewPreOutInfo = {Adjoin PreOutInfo
                                      twInfo(mark:     NewMark
                                             glueSize: DSpace)}
                     <<setSubtermOutInfo(PreNum NewPreOutInfo)>>

                     %%  ... and now, 'OldMark' is our new mark;
                     %%  Note that 'size' is already in there;
                     %%
                     %%  Insert the prefix (feature name);
                     FName = <<genLitPrintName(@recFeatures.N $)>>

                     %%
                     case {VirtualString.is FName} then
                        {self.widgetObj
                         insert(OldMark FName#DColonS#DSpaceGlue)}
                        %% insert(OldMark FName#<<getFeatDel($)>>)}

                        %%
                        NewOutInfo = {Adjoin OutInfo
                                      twInfo(mark:     OldMark
                                             glueSize: PreOutInfo.glueSize)}
                        <<setSubtermOutInfo(N NewOutInfo)>>
                        %%
                     end

                     %%
                     {Wait {Obj draw(OldMark $)}}

                     %%
                     size <- @size + DSpace
                  end
               end
            else
               %%
               %%  Note: in this case we have to update 'prfxSize'
               %% field, since it was 0 (should be - we only extend records);
               %%
               Mark FName PrfxSize ObjSize
            in
               Mark = OutInfo.mark

               %%
               case OutInfo.prfxSize \= 0 then
                  {BrowserError
                   ['MetaRecordTWTermObject::drawNewSubterm: not implemented']}
                  else true
               end

               %%  Insert the prefix (feature name);
               FName = <<genLitPrintName(@recFeatures.N $)>>
               PrfxSize = {VSLength FName} + DDSpace

               %%
               case {VirtualString.is FName} then
                  {self.widgetObj
                   insert(Mark FName#DColonS#DSpaceGlue)}
                  %% insert(Mark FName#<<getFeatDel($)>>)}
               end

               %%  there were a subterm before;
               %%  Note that that subterm should be undrawn
               %% (and, actually, destroyed) already;
               {Wait {Obj [getSize(ObjSize) draw(Mark $)]}}

               %%
\ifdef DEBUG_TW
               case OutInfo.prfxSize \= 0 then
                  {BrowserError
                   ['MetaRecordTWTermObj::drawNewSubterm: error']}
               else true
               end
\endif

               %%  Preserve the 'glueSize' fields' value!
               NewOutInfo = {Adjoin OutInfo
                             twInfo(size: ObjSize
                                    prfxSize: PrfxSize)}
               <<setSubtermOutInfo(N NewOutInfo)>>

               %%  subtract old subterm's 'meta' size and add
               %% it from the new one;
               size <- @size - OutInfo.size + ObjSize + PrfxSize
            end
         end
      end

      %%
      %%  ... remove also the 'name glue' mark;
      %%
      meth setUndrawn
         %%
         {self.widgetObj unsetMark(self.nameGlueMark)}
         nameGlueSize <- 0

         %%
         <<MetaTupleTWTermObject setUndrawn>>
      end

      %%
      %%
      %%  specially for records (actually, for open feature structures);
      meth drawCommas
         local
            Width LastSTOutInfo NewLastSTOutInfo Obj
            OutInfo NewOutInfo NewMark OldMark
         in
            Width = @width

            %%
            <<addCommasRec>>

            %%
            Obj = {New PseudoTermTWCommas init(parentObj: self)}
            <<setCommasObj(Obj)>>

            %%
            <<InitOutInfoRec(_ <<getCommasNum($)>> Obj OutInfo)>>

            %%
            LastSTOutInfo = <<getSubtermOutInfo(Width $)>>
            OldMark = LastSTOutInfo.mark

            %%
            <<CreateSimpleGlue(OldMark NewMark)>>

            %%
            NewLastSTOutInfo = {Adjoin LastSTOutInfo
                                twInfo(mark:     NewMark
                                       glueSize: DSpace)}
            <<setSubtermOutInfo(Width NewLastSTOutInfo)>>

            %%
            {Wait {Obj draw(OldMark $)}}

            %%
            NewOutInfo = {Adjoin OutInfo
                          twInfo(glueSize: LastSTOutInfo.glueSize
                                 mark:     OldMark
                                 prfxSize: 0)}

            %%
            <<setCommasOutInfo(NewOutInfo)>>

            %%
            size <- @size + DSpace
         end
      end

      %%
   end

   %%
   %%
   %%
   %%  Record Text Widget Term Object;
   %%
   class RecordTWTermObject
      from MetaRecordTWTermObject
      %%
      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'RecordObject::initOut method for the term '#self.term}
\endif
         local Name NameLen in
            Name = self.name
            NameLen = {VSLength Name}

            %%
            <<tagInit>>

            %%
            self.nameGlueMark = {self.widgetObj genTkName($)}

            %%
            shown <- False

            %%
            case <<areCommas($)>> then
               Obj
            in
               %%
               %% commas;
               Obj = {New PseudoTermTWCommas init(parentObj: self)}

               %%
               <<setCommasObj(Obj)>>
            else true
            end

            %%
            case <<areSpecs($)>> then
               %%
               %% '?';
               Obj
            in
               Obj = {New PseudoTermTWQuestion init(parentObj: self)}

               %%
               <<setSpecsObj(Obj)>>
            else true
            end

            %% name, '(' and ')';
            size <- NameLen + DSpace + <<getTotalWidth($)>>

            %%
            case @refVarName == '' then true
            else
               size <- @size + DSpace + {VSLength @refVarName} +
               case <<needsBracesRef($)>> then DSpace else 0 end
            end

            %%
            nameGlueSize <- 0

            %%
            %%  'recordsAligned' should be initialized before the first
            %% 'AdjustGlue';
            %%
            %%  sets both subterm sizes and global size ('@size');
            <<mapObjInd(InitOutInfoRec)>>
         end
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'RecordObject::draw method for the term '#self.term#Mark}
\endif
\ifdef DEBUG_TW
         case @shown then
            {BrowserError ['...:draw for shown term?']}
         else true
         end
\endif
         local ActualTWWidth StartOffset TmpMark SyncList PTag in
            %%
            %% Force subsequent 'adjustGlues';
            shownStartOffset <- 0
            shownTWWidth <- DInfinite
            shownMetaSize <- 0

            %%
            PTag = <<getTagInfo($)>>

            %%
            case @refVarName == '' then
               {self.widgetObj [insertWithTag(Mark self.name#DLRBraceS PTag)
                                duplicateMarkLG(Mark self.nameGlueMark)
                                genTkName(TmpMark)
                                insertWithBoth(Mark DRRBraceS TmpMark PTag)]}
               FirstInc <- {VSLength self.name} + DSpace
            else
               case <<needsBracesRef($)>> then
                  {self.widgetObj
                   [insertWithTag(Mark
                                  DLRBraceS#@refVarName#DEqualS#self.name#DLRBraceS
                                  PTag)
                    duplicateMarkLG(Mark self.nameGlueMark)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRRBraceS#DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DTSpace +
                  {VSLength self.name} + {VSLength @refVarName}
                  %% '(', '=', 'self.name', '('and '@refVarName' itself;
               else
                  {self.widgetObj
                   [insertWithTag(Mark @refVarName#DEqualS#self.name#DLRBraceS PTag)
                    duplicateMarkLG(Mark self.nameGlueMark)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DDSpace +
                  {VSLength self.name} + {VSLength @refVarName}
                  %% '=', 'self.name', '(' and '@refVarName' itself;
               end
            end

            %%  Resulting mark is consumed ('_' for third arg);
            <<mapObjIndArg(AddSimpleGlue TmpMark _)>>
            %%
            shown <- True

            %%
            <<checkLayout>>

            %%
            <<initBindings>>

            %%
            <<mapObjIndArg(DrawSubterm nil SyncList)>>
            case {All SyncList IsValue} then
               Sync = True
               <<UrObject nil>>
            end
         end
      end

      %%
      %%
      meth getGlueChar(?GlueChar)
         GlueChar = DSpaceGlue
      end

      %%
      %%
      %% meth getFeatDel(?Del)
      %% Del = DColonS#DSpaceGlue
      %% end

      %%
      %%
      %% meth getFeatDelSize(?Size)
      %% Size = DDSpace
      %% end

      %%
      %%  (it is class-depended because glue character;)
      meth !CreateSimpleGlue(Mark NewMark)
         {self.widgetObj [genTkName(NewMark)
                          insertWithMark(Mark DSpaceGlue NewMark)]}
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%
   %%  Open feature structures in text widget;
   %%
   class ORecordTWTermObject
      from MetaRecordTWTermObject
      %%
      %%
      feat
         labelMark              % mark just after the label;

      %%
      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'ORecordObject::initOut method for the term '#self.term}
\endif
         local Name NameLen in
            Name = @name
            NameLen = {VSLength Name}

            %%
            <<tagInit>>

            %%
            self.labelMark = {self.widgetObj genTkName($)}

            %%
            self.nameGlueMark = {self.widgetObj genTkName($)}

            %%
            shown <- False

            %%
            case <<areCommas($)>> then
               Obj
            in
               %%
               %% commas;
               Obj = {New PseudoTermTWCommas init(parentObj: self)}

               %%
               <<setCommasObj(Obj)>>
            else true
            end

            %%
            case <<areSpecs($)>> then
               %%
               %% '...' if any (it could happen since this OFS could
               %% become proper record meanwhile;)
               Obj
            in
               Obj = {New PseudoTermTWDots init(parentObj: self)}

               %%
               <<setSpecsObj(Obj)>>
            else true
            end

            %% name, '(' and ')';
            size <- NameLen + DSpace + <<getTotalWidth($)>>

            %%
            case @refVarName == '' then true
            else
               size <- @size + DSpace + {VSLength @refVarName} +
               case <<needsBracesRef($)>> then DSpace else 0 end
            end

            %%
            nameGlueSize <- 0

            %%
            %%  'recordsAligned' should be initialized before the first
            %% 'AdjustGlue';
            %%
            %%  sets both subterm sizes and global size ('@size');
            <<mapObjInd(InitOutInfoRec)>>
         end
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'ORecordObject::draw method for the term '#self.term#Mark}
\endif
\ifdef DEBUG_TW
         case @shown then
            {BrowserError ['...:draw for shown term?']}
         else true
         end
\endif
         %%
         local ActualTWWidth StartOffset TmpMark SyncList PTag Name in
            %%
            %% Force subsequent 'adjustGlues';
            shownStartOffset <- 0
            shownTWWidth <- DInfinite
            shownMetaSize <- 0

            %%
            PTag = <<getTagInfo($)>>
            Name = @name

            %%
            case @refVarName == '' then
               {self.widgetObj [insertWithTag(Mark Name PTag)
                                insertWithBoth(Mark DLRBraceS self.labelMark PTag)
                                duplicateMarkLG(Mark self.nameGlueMark)
                                genTkName(TmpMark)
                                insertWithBoth(Mark DRRBraceS TmpMark PTag)]}

               %%
               FirstInc <- {VSLength Name} + DSpace
            else
               case <<needsBracesRef($)>> then
                  {self.widgetObj
                   [insertWithTag(Mark
                                  DLRBraceS#@refVarName#DEqualS#Name
                                  PTag)
                    insertWithBoth(Mark DLRBraceS self.labelMark PTag)
                    duplicateMarkLG(Mark self.nameGlueMark)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRRBraceS#DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DTSpace +
                  {VSLength Name} + {VSLength @refVarName}
                  %% '(', '=', 'self.name', '('and '@refVarName' itself;
               else
                  {self.widgetObj
                   [insertWithTag(Mark @refVarName#DEqualS#Name PTag)
                    insertWithBoth(Mark DLRBraceS self.labelMark PTag)
                    duplicateMarkLG(Mark self.nameGlueMark)
                    genTkName(TmpMark)
                    insertWithBoth(Mark DRRBraceS TmpMark PTag)]}

                  %%
                  FirstInc <- DDSpace +
                  {VSLength Name} + {VSLength @refVarName}
                  %% '=', 'self.name', '(' and '@refVarName' itself;
               end
            end

            %%  Resulting mark is consumed ('_' for third arg);
            <<mapObjIndArg(AddSimpleGlue TmpMark _)>>
            %%
            shown <- True

            %%
            <<checkLayout>>

            %%
            <<initBindings>>

            %%
            <<mapObjIndArg(DrawSubterm nil SyncList)>>
            case {All SyncList IsValue} then
               Sync = True
               %%
               <<initTypeWatching>>
            end
         end
      end

      %%
      %%
      meth replaceLabel
\ifdef DEBUG_TW
         {Show 'ORecordTWTermObject::replaceLabel is applied'}
\endif
         local PTag OldLabSize NewLabSize OldSize NewSize in
            OldSize = @size
            OldLabSize = {VSLength @name}

            %%
            <<setName>>
            NewLabSize = {VSLength @name}
            NewSize = OldSize + NewLabSize - OldLabSize

            %%
            case @shown then
               PTag = <<getTagInfo($)>>

               %%
               {self.widgetObj [deleteBeforeMark(self.labelMark OldLabSize)
                                insertWithTag(self.labelMark @name PTag)]}
            else true
            end

            %%
            size <- NewSize
            FirstInc <- @FirstInc + NewLabSize - OldLabSize

            %%
            job
               {self.parentObj checkSize(self OldSize NewSize)}
            end
         end
      end

      %%
      %%
      meth removeDots
\ifdef DEBUG_TW
         {Show 'ORecordTWTermObject::removeDots is applied'}
\endif
         case @shown == False then
            {BrowserWarning ['ORecordTWTermObject::removeDots: not shown']}
         elsecase <<areSpecs($)>> then
            TotalWidth SpecsOutInfo SpecsObj SpecsSize
            PreOutInfo NewPreOutInfo OldSize NewSize
         in
            TotalWidth = <<getTotalWidth($)>>
            OldSize = @size

            %%
            %%  Note: it should contain at least one visible feature;
            <<getAnySubtermObjOutInfo(TotalWidth SpecsObj SpecsOutInfo)>>
            <<getAnySubtermOutInfo((TotalWidth - 1) PreOutInfo)>>

            %%
            {SpecsObj [getSize(SpecsSize) undraw destroy]}

            %%
            {self.widgetObj
             [deleteBeforeMark(SpecsOutInfo.mark PreOutInfo.glueSize)
              unsetMark(SpecsOutInfo.mark)]}

            %%
            NewPreOutInfo = {AdjoinAt PreOutInfo glueSize 0}

            %%
            <<setAnySubtermOutInfo((TotalWidth - 1) NewPreOutInfo)>>
            <<removeSpecs>>

            %%
            NewSize = OldSize - SpecsSize - PreOutInfo.glueSize
            size <- NewSize

            %%
            job
               {self.parentObj checkSize(self OldSize NewSize)}
            end
         else
            {BrowserError
             ['ORecordTWTermObject::removeDots: there were no specs!']}
         end
      end

      %%
      %%
      meth addQuestion
         case <<areSpecs($)>> then
            OldSpecsObj SpecsOutInfo OldSize
            NewSpecsObj NewSize
            UndrawMeth DrawMeth
         in
            <<getSpecsObjOutInfo(OldSpecsObj SpecsOutInfo)>>

            %%
            NewSpecsObj = {New PseudoTermTWDotsQuestion
                           init(parentObj: self)}
            NewSize = {NewSpecsObj getSize($)}

            %%
            case @shown then
               UndrawMeth = undraw
               DrawMeth = draw(SpecsOutInfo.mark _)
            else
               UndrawMeth = nil
               DrawMeth = nil
            end

            %%
            {OldSpecsObj [getSize(OldSize) UndrawMeth destroy]}

            %% don't care about termination;
            {NewSpecsObj DrawMeth}

            %%
            <<setSpecsObj(NewSpecsObj)>>

            %%
            job
               {self.parentObj checkSize(self OldSize NewSize)}
            end
         else
            {BrowserError ['ORecordTWTermObject::addQuestion: error!']}
         end
      end

      %%
      %%
      meth getGlueChar(?GlueChar)
         GlueChar = DSpaceGlue
      end

      %%
      %%
      %% meth getFeatDel(?Del)
      %% Del = DHatS#DSpaceGlue
      %% end

      %%
      %%
      %% meth getFeatDelSize(?Size)
      %% Size = DDSpace
      %% end

      %%
      %%  (it is class-depended because glue character;)
      meth !CreateSimpleGlue(Mark NewMark)
         {self.widgetObj [genTkName(NewMark)
                          insertWithMark(Mark DSpaceGlue NewMark)]}
      end

      %%
      %%
      meth undraw
         <<stopTypeWatching>>
         %%
         {self.widgetObj unsetMark(self.labelMark)}

         %%
         <<MetaRecordTWTermObject undraw>>
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%
   %%  Meta-chunks (not only, though) in text widet;
   %%
   %%
   class MetaChunkTWTermObject
      from RecordTWTermObject
      %%

      %%
      %%  'getSize' ...
      %%  'checkLayout' ...
      %%
      %%  'pickPlace' ...
      %%  'isActive' ...
      %%
      %%  'initBindings' ... (and all the 'TW' handlers;)
      %%  'getTags' ...
      %%  'getTagInfo' ...
      %%  'closeOut' ...
      %%  'undraw' ...
      %%
      %%  'setUndrawn' ...
      %%
      %%  'initOut' ...
      %%  'GetRightMostMarks' from from records;
      %%
      %%  'draw' ...
      %%
      %%  'insertRefVar' ...
      %%
      %%  'NewOutInfo' from MetaRecordTWTermObject;
      %%  'AdjustGlue' ...
      %%  'isEnclosed' ...
      %%
   end

   %%
   %%
   %%  Chunks;
   %%
   class ChunkTWTermObject
      from MetaChunkTWTermObject
      %%
   end


   %%
   %%
   %%  Objects;
   %%
   class ObjectTWTermObject
      from MetaChunkTWTermObject
      %%
   end

   %%
   %%
   %%  Classes;
   %%
   class ClassTWTermObject
      from MetaChunkTWTermObject
      %%
   end

   %%
   %%
   %%  Various special (sub)terms;
   %%
   %%  Variables;
   %%
   class VariableTWTermObject
      from MetaTWTermObject
      %%
      %%
      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'VariableObject::initOut method for the term '#self.term}
\endif
         %%
         <<tagInit>>

         %%
         size <- {VSLength self.name}
         shown <- False

         %%
         case {self.store read(StoreHeavyVars $)} then
            size <- DInfinite   % heavy enough ;)))))
         else
            case @refVarName == '' then true
            else
               size <- @size + DSpace + {VSLength @refVarName} +
               case <<needsBracesRef($)>> then DDSpace else 0 end
            end
         end
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'VariableObject::draw method for the term '#self.term#Mark}
\endif
         local PTag in
            PTag = <<getTagInfo($)>>

            %%
            case @refVarName == '' then
               {self.widgetObj insertWithTag(Mark self.name PTag)}
            else
               case <<needsBracesRef($)>> then
                  %%
                  {self.widgetObj
                   insertWithTag(Mark
                                 DLRBraceS#@refVarName#DEqualS#self.name#DRRBraceS
                                 PTag)}
               else
                  %%
                  {self.widgetObj
                   insertWithTag(Mark
                                 @refVarName#DEqualS#self.name
                                 PTag)}
               end
            end

            %%
            <<initTypeWatching>>

            %%
            shown <- True
            Sync = True

            %%
            <<initBindings>>
         end
      end

      %%
      %%
      meth insertRefVar
\ifdef DEBUG_TW
         {Show 'VariableObject::insertRefVar method for the term '#self.term}
\endif
         case @shown then
            Tags RefVarName RefVarNameLen Size NewSize PrfxSize SfxSize
         in
            %%
            Tags = {self.GetTags self}
            RefVarName = @refVarName
            RefVarNameLen = {VSLength RefVarName}
            Size = @size

            %%
            case <<needsBracesRef($)>> then
               {self.widgetObj [insertBeforeTag(self Tags
                                                DLRBraceS#RefVarName#DEqualS)
                                insertAfterTag(self Tags DRRBraceS)]}

               %%
               PrfxSize = DDSpace + RefVarNameLen
               SfxSize = DSpace
            else
               {self.widgetObj insertBeforeTag(self Tags RefVarName#DEqualS)}

               %%
               PrfxSize = DSpace + RefVarNameLen
               SfxSize = 0
            end

            %%
            NewSize =  Size + PrfxSize + SfxSize
            size <- NewSize

            %%
            job
               {self.parentObj checkSize(self Size NewSize)}
            end
         else
            RefVarName RefVarNameLen Size NewSize PrfxSize SfxSize
         in
            %%
            RefVarName = @refVarName
            RefVarNameLen = {VSLength RefVarName}
            Size = @size

            %%
            case <<needsBracesRef($)>> then
               %%
               PrfxSize = DDSpace + RefVarNameLen
               SfxSize = DSpace
            else
               %%
               PrfxSize = DSpace + RefVarNameLen
               SfxSize = 0
            end

            %%
            NewSize =  Size + PrfxSize + SfxSize
            size <- NewSize

            %%
            job
               {self.parentObj checkSize(self Size NewSize)}
            end
         end
      end

      %%
      %%  'type watch' should be removed;
      meth undraw
         <<stopTypeWatching>>
         %%
         <<MetaTWTermObject undraw>>
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%  Finite domain variables;
   %%
   class FDVariableTWTermObject
      from VariableTWTermObject
   end

   %%
   %%  Finite domain variables;
   %%
   class MetaVariableTWTermObject
      from VariableTWTermObject
   end

   %%
   %%
   %%  Referneces;
   %%
   class ReferenceTWTermObject
      from MetaTWTermObject
      %%
      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'ReferenceObject::initOut method for the term '#self.term}
\endif
         %%
         <<tagInit>>

         %%
         size <- {VSLength @name}
         shown <- False
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'ReferenceObject::draw method for the term '#self.term#Mark}
\endif
         local PTag in
            PTag = <<getTagInfo($)>>

            %%
            {self.widgetObj insertWithTag(Mark @name PTag)}
            shown <- True
            Sync = True

            %%
            <<initBindings>>
         end
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%  Shrunken (sub)term objects;
   %%
   class ShrunkenTWTermObject
      from MetaTWTermObject
      %%
      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'ShrunkenObject::initOut method for the term '#self.term}
\endif
         %%
         <<tagInit>>

         %%
         size <- DTSpace
         shown <- False
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'ShrunkenObject::draw method for the term '#self.term#Mark}
\endif
         local PTag in
            PTag = <<getTagInfo($)>>

            %%
            {self.widgetObj insertWithTag(Mark DNameUnshown PTag)}
            shown <- True
            Sync = True

            %%
            <<initBindings>>
         end
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
   %%
   class UnknownTWTermObject
      from MetaTWTermObject
      %%

      %%
      %%
      meth initOut
\ifdef DEBUG_TW
         {Show 'UnknownObject::initOut method for the term '#self.term}
\endif
         %%
         <<tagInit>>

         %%
         size <- {VSLength self.name}
         shown <- False
      end

      %%
      %%
      meth draw(Mark ?Sync)
\ifdef DEBUG_TW
         {Show 'UnknownObject::draw method for the term '#self.term#Mark}
\endif
         local PTag in
            PTag = <<getTagInfo($)>>

            %%
            {self.widgetObj insertWithTag(Mark self.name PTag)}
            shown <- True
            Sync = True

            %%
            <<initBindings>>
         end
      end

      %%
      %%  No 'otherwise' method, since it's defined in 'generic' class;
      %%
   end

   %%
   %%
end
