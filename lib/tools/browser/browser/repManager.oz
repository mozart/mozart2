%  Programming Systems Lab, University of Saarland,
%  Geb. 45, Postfach 15 11 50, D-66041 Saarbruecken.
%  Author: Konstantin Popov & Co.
%  (i.e. all people who make proposals, advices and other rats at all:))
%  Last modified: $Date$ by $Author$
%  Version: $Revision$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%
%%%  Representation manager
%%%
%%%  - keeps track of a term's representation structure;
%%%  - performs all the "draw" work;
%%%
%%%
%%%

local
   %%
   MetaRepManagerObject         % some generic functionality;

   %%
   %% Local features & attributes;
   HeadMark         = {NewName}
   TailMark         = {NewName}
   HaveBraces       = {NewName}
   Size             = {NewName}
   SavedSize        = {NewName}
   UsedIndentIn     = {NewName}
   UsedIndentOut    = {NewName}
   RefName          = {NewName}
   RefNameSize      = {NewName}
   Subterms         = {NewName}

   %%
   %% ... methods;
   OpenRep          = {NewName}
   ShutRep          = {NewName}
   %%
   PutHeadMark      = {NewName}
   PutTailMark      = {NewName}
   %%
   LayoutOK         = {NewName}
   LayoutWrong      = {NewName}
   %%
   AnchorLB         = {NewName}
   AnchorGroup      = {NewName}
   %%
   NeedsLineBreak   = {NewName}
   %% 'SetCursorAt' has global extent - it has to be used by
   %% 'RootTermObject';
   SetCursorAfter   = {NewName}
   %%
   SkipAuxBegin     = {NewName}
   SkipAuxEnd       = {NewName}
   GetAuxSize       = {NewName}
   GetAuxSizeB      = {NewName}
   GetAuxSizeE      = {NewName}
   %%
   PutOP            = {NewName}
   PutCP            = {NewName}
   %%
   GetSize          = {NewName}
   GetIndentIn      = {NewName}
   GetIndentOut     = {NewName}
   IsMultiLined     = {NewName}

   %%
   %% Auxiliary procedures & objects;
   CreateSpaces
   ScanToken
in

%%%
%%%
%%% Diverse local auxiliary procedures;
%%%
%%%

   %%
   %% 'CreateSpaces';
   %% Generates a VS consisting of 'N' blanks (and the code itself
   %% could be considered as my (K.P.) joke:);
   %%
   %% The curious thing is that Tcl interpreter (wish) is damn slow,
   %% so it pays off to generate strings etc. at the Oz side and
   %% transmit it to the wish, compared to an iterative "space
   %% maker" written in Tcl and executed directly by wish!
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
      [] 31 then '                               '
      [] 32 then '                                '
      [] 33 then '                                 '
      [] 34 then '                                  '
      [] 35 then '                                   '
      [] 36 then '                                    '
      [] 37 then '                                     '
      [] 38 then '                                      '
      [] 39 then '                                       '
      [] 40 then '                                        '
      [] 41 then '                                         '
      [] 42 then '                                          '
      [] 43 then '                                           '
      [] 44 then '                                            '
      [] 45 then '                                             '
      [] 46 then '                                              '
      [] 47 then '                                               '
      [] 48 then '                                                '
      [] 49 then '                                                 '
      [] 50 then '                                                  '
      else
         H V
      in
         H = {`div` N 2}
         case H + H == N then
            V = {CreateSpaces H}
            V # V
         else
            V = {CreateSpaces H}
            ' ' # V # V
         end
      end
   end

   %%
   %% An object which helps to implement iteration over groups in
   %% 'AnchorGroup': a virtual token (marker) moving backward from
   %% the position we are interested in. So, offsets & indents are
   %% accumulated "backwards", i.e. from larger groups to smaller
   %% ones;
   class ScanToken from Object.base
      attr
         mark:      InitValue   % none at the begin;
         offset:    0           % originallt - 0;
         gotIndent: false       % ... originally;
         indent:    0           %

      %%
      meth init skip end

      %%
      meth gotMark($) @mark \= InitValue end
      meth setMark(Mark)
         mark <- Mark
      end
      meth incOffset(Inc)
         offset <- @offset + Inc
      end
      meth setMarkIncOffset(Mark Inc)
         mark <- Mark
         offset <- @offset + Inc
      end

      %%
      meth gotIndent($) @gotIndent end
      meth incIndent(Inc)
         indent <- @indent + Inc
      end
      meth setIndent(Inc)
         indent <- @indent + Inc
         gotIndent <- true
      end

      %%
      %% use our results ...
      meth setCursorAt(WO)
         {WO setCursorOffset(@mark @offset @indent)}
\ifdef DEBUG_RM
         % Object.closable , close
\endif
      end

      %%
   end

   %%
   %% This guy is used by the Browser's manager object, in order to
   %% figure out which term object has to handle an event.
   %%
   %% 'Pairs' is a list of '(Type,Obj)' pairs;
   %%
   local SplitPairs GetInnerMostObj GetOuterMostObj in
      fun {GetTargetObj Pairs}
         local LObjs RObjs in
            %%
            {SplitPairs Pairs LObjs RObjs}

            %%
            case LObjs \= nil then {GetInnerMostObj LObjs}
            elsecase RObjs \= nil then {GetOuterMostObj RObjs}.ParentObj
            else
\ifdef DEBUG_RM
               {BrowserWarning 'GetTargetObj: no objects??!'}
\endif
               InitValue
            end
         end
      end

      %%
      proc {SplitPairs Pairs ?LeftObjs ?RightObjs}
         case Pairs
         of nil then LeftObjs = RightObjs = nil
         [] E|T then NewLeftObjs NewRightObjs Type Obj in
            E = Type#Obj
            case Type
            of left then
               LeftObjs = Obj|NewLeftObjs
               RightObjs = NewRightObjs
            [] right then
               LeftObjs = NewLeftObjs
               RightObjs = Obj|NewRightObjs
            else
               {BrowserError 'GetTargetObj: unknown type of a object!'}
               LeftObjs = NewLeftObjs
               RightObjs = NewRightObjs
            end

            %%
            {SplitPairs T NewLeftObjs NewRightObjs}
         else {BrowserError 'GetTargetObj: a list of pairs??!'}
         end
      end

      %%
      %% These algorithms are quadratic, but the length of lists is
      %% limited by the number of different term infix constructors;
      %%
      %% 'Objs' is a non-empty list, for both functions;
      %%
      fun {GetOuterMostObj Objs}
         case
            {Filter Objs
             fun {$ Obj}        % 'has no parent';
                {Some Objs fun {$ CmpObj} Obj.ParentObj == CmpObj end}
                == false
             end}
         of nil then
            {BrowserError 'GetTargetObj: no outer-most object??!'}
            InitValue
         [] Obj|R then
\ifdef DEBUG_RM
            case R \= nil then
               {BrowserWarning 'GetTargetObj: multiple outer-most objects?'}
            else skip
            end
\endif
            Obj
         end
      end

      %%
      fun {GetInnerMostObj Objs}
         case
            {Filter Objs
             fun {$ Obj}        % 'has no child(ren)';
                {Some Objs fun {$ CmpObj} CmpObj.ParentObj == Obj end}
                == false
             end}
         of nil then
            {BrowserError 'GetTargetObj: no inner-most object??!'}
            InitValue
         [] Obj|R then
\ifdef DEBUG_RM
            case R \= nil then
               {BrowserWarning 'GetTargetObj: multiple inner-most objects?'}
            else skip
            end
\endif
            Obj
         end
      end

      %%
   end

%%%
%%%
%%%
%%%
%%%

   %%
   %% Generic;
   %%
   class MetaRepManagerObject from Object.base
      %%
      feat
         !WidgetObj             %
         !HeadMark              %
         !TailMark              %

      %%
      attr
         !HaveBraces:   false
         !Size:         0
         !SavedSize:    0
         !UsedIndentIn: InitValue
      %%
         !RefName:      ''
         !RefNameSize:  0       % ... and its size together with '=';

\ifdef DEBUG_RM
      meth debugShow
         {Show 'DEBUG: RM::debugShow'}
         {Show 'Size, SavedSize, UsedIndentIn'
          # @Size # @SavedSize # @UsedIndentIn}
      end
\endif

      %%
      %% This is "enough" for pritivie term objects, and could be
      %% extended for compound ones;
      %%
      %% Note that drawing starts at the current cursor's position,
      %% and after 'MakeRep' the cursor stay just at the end of a
      %% representation built up;
      %%
      meth !MakeRep(isEnc:IsEncRep)
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::MakeRep is applied'}
\endif
         %%
         local WidgetObjIn in
            WidgetObjIn = self.WidgetObj = self.ParentObj.WidgetObj

            %%
            UsedIndentIn <- {WidgetObjIn getCursorCol($)}

            %%
            %% they can be implemented differently for
            %% primitive/compound term objects;
            {self  PutHeadMark}

            %%
            %% 'Size'/'SavedSize' are initialized already;

            %%
            case IsEncRep then MetaRepManagerObject , PutOP
            else skip
            end

            %%
            {self makeTerm}
            {self AnchorLB}

            %%
            case IsEncRep then MetaRepManagerObject , PutCP
            else skip
            end

            %%
            {self  PutTailMark}

            {self  LayoutOK}
         end
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::MakeRep is finished'}
         {self  debugShow}
         {self.WidgetObj debugShowIndices(self.HeadMark self.TailMark)}
\endif
      end

      %%
      %% remove a representation (everything between 'head' and
      %% 'tail' marks), and unset marks;
      meth !CloseRep
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::CloseRep is applied'}
\endif
         %%
         local HM TM in
            HM = self.HeadMark
            TM = self.TailMark

            %%
            {self.WidgetObj [deleteRegion(HM TM)
                             unsetMark(HM) unsetMark(TM)
                             flushUnsetMarks]}
         end
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::CloseRep is finished'}
\endif
      end

      %%
      %% ... unset marks only. This is to be used by an object that
      %% is a child of another closed object;
      meth !FastCloseRep
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::FastCloseRep is applied'}
\endif
         %%
         {self.WidgetObj
          [unsetMark(self.HeadMark) unsetMark(self.TailMark)]}
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::FastCloseRep is finished'}
\endif
      end

      %%
      %% 'BeginUpdate'/'EndUpdate' group.
      %%

      %%
      %% Basic '{Begin,End}Update': swapping marks gravity;
      meth !OpenRep
         %%
         {self.WidgetObj [setMarkGravity(self.HeadMark left)
                          setMarkGravity(self.TailMark right)]}
      end
      meth !ShutRep
         %%
         {self.WidgetObj [setMarkGravity(self.HeadMark right)
                          setMarkGravity(self.TailMark left)]}
      end

      %%
      %% Toggle the mark gravities, and save the current size;
      meth !BeginUpdate
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::BeginUpdate is applied'}
\endif
         local WO in
            WO = self.WidgetObj

            %%
            SavedSize <- @Size

            %%
            {self.ParentObj BeginUpdateSubterm(self.numberOf)}

            %%
            MetaRepManagerObject , OpenRep
         end

         %%
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::BeginUpdate is finished'}
\endif
      end

      %%
      %% ... toggle gravities back, and apply 'SizeChanged' whenever
      %% size has changed;
      meth !EndUpdate
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::EndUpdate is applied'}
\endif
         %%
         local WO OldSize NewSize in
            WO = self.WidgetObj
            OldSize = @SavedSize
            NewSize = @Size

            %%
            {self.ParentObj EndUpdateSubterm(self.numberOf)}

            %%
            MetaRepManagerObject , ShutRep

            %%
            ControlObject , SizeChanged(OldSize NewSize)

            %%
            MetaRepManagerObject , LayoutWrong
         end
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::EndUpdate is finished'}
         {self  debugShow}
         {self.WidgetObj debugShowIndices(self.HeadMark self.TailMark)}
\endif
      end

      %%
      %% per definition;
      meth !IsMultiLined($) false end

      %%
      %%
      %% Parentheses & reference names;
      %%

      %%
      meth !IsEnc(are:$) @HaveBraces end
      meth !GetRefName($) @RefName end

      %%
      %%
      meth !PutRefName(refName: RefNameIn)
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::PutRefName is applied '}
         case @RefName \= '' then
            {BrowserError 'RepManagerObject::PutRefName: error!'}
         else skip
         end
\endif
         %%
         {self SetCursorAt}
         {self SkipAuxBegin}

         %%
         RefName <- RefNameIn
         RefNameSize <- {self.WidgetObj insert((RefNameIn # DEqualS) $)}
         Size <- @Size + @RefNameSize

         %%
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::PutRefName is finished '}
\endif
      end

      %%
      %%
      meth !PutEncRefName(refName: RefNameIn)
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::PutEncRefName is applied'}
         case @RefName \= '' then
            {BrowserError 'RepManagerObject::PutEncRefName: error!'}
         else skip
         end
\endif
         %%
         {self SetCursorAt}
         {self PutOP}

         %%
         RefName <- RefNameIn
         RefNameSize <- {self.WidgetObj insert((RefNameIn # DEqualS) $)}
         Size <- @Size + @RefNameSize

         %%
         {self  SetCursorAfter}
         {self  PutCP}
\ifdef DEBUG_RM
         {Show 'MetaRepManagerObject::PutEncRefName is finished'}
\endif
      end

      %%
      %% Local methods (for the representation manager);
      %%

      %%
      %% Declares the term's layout to be a correct one (when starting
      %% at 'UsedIndentIn', of course);
      meth !LayoutOK
         SavedSize <- @Size
      end

      %%
      meth !LayoutWrong
         SavedSize <- 0
      end

      %%
      %% Forces subsequent 'CheckLayout' to perform the check;
      meth !CheckLayoutReq skip end

      %%
      meth !GetSize($) @Size end
      meth !GetIndentIn($) @UsedIndentIn end
      meth !GetIndentOut($) @UsedIndentIn + @Size end

      %%
      %%
      meth !PutOP
\ifdef DEBUG_RM
         {Show 'RepManagerObject::PutOP is applied'}
         case @HaveBraces then
            {BrowserError 'RepManagerObject::PutOP: error!'}
         else skip
         end
\endif
         %%
         Size <- @Size + {self.WidgetObj insert(DLRBraceS $)}

         %%
         HaveBraces <- true
\ifdef DEBUG_RM
         {Show 'RepManagerObject::PutOP is finished'}
\endif
      end

      %%
      %%
      meth !PutCP
\ifdef DEBUG_RM
         {Show 'RepManagerObject::PutCP is applied'}
\endif
         %%
         Size <- @Size + {self.WidgetObj insert(DRRBraceS $)}
\ifdef DEBUG_RM
         {Show 'RepManagerObject::PutCP is finished'}
\endif
      end

      %%
      %% Skip open parenthesis and reference name, if any;
      meth !SkipAuxBegin
         local WO RNSize in
            WO = self.WidgetObj
            RNSize = @RefNameSize

            %%
            case @HaveBraces then
               {WO advanceCursor(RNSize + DSpace)} % at least DSpace;
            elsecase RNSize == 0 then skip         % no parentheses;
            else {WO advanceCursor(RNSize)}
            end
         end
      end

      %%
      %% Skip a closing parenthesis, if any;
      meth !SkipAuxEnd
         %%
         case @HaveBraces then {self.WidgetObj advanceCursor(DSpace)}
         else skip              % no parentheses;
         end
      end

      %%
      meth !GetAuxSize($)
         @RefNameSize + case @HaveBraces then DDSpace else 0 end
      end

      %%
      meth !GetAuxSizeB($)
         @RefNameSize + case @HaveBraces then DSpace else 0 end
      end

      %%
      meth !GetAuxSizeE($)
         case @HaveBraces then DSpace else 0 end
      end

      %%
      %% jump(view) to a first character of a representation;
      meth pickPlace(Where How)
         {self.WidgetObj
          pickMark(case Where of 'begin' then self.HeadMark
                   else self.TailMark
                   end
                   How)}
      end
      %%
      meth scrollTo
         {self.WidgetObj scrollToMark(self.TailMark)}
      end

      %%
      meth !SetCursorAt
         {self.WidgetObj setCursor(self.HeadMark @UsedIndentIn)}
      end

      %%
      meth !Highlight
         {self.WidgetObj highlightRegion(self.HeadMark self.TailMark)}
      end

      %%
   end

   %%
   %% ... for primitive objects;
   %%
   class RepManagerObject from MetaRepManagerObject
      %%

      %%
      %% Note that there is no need for 'UsedIndentOut' since it is a
      %% sum of 'UsedIndentIn' and 'Size';
      %%

      %%
      %%
      meth !PutHeadMark
         %%
         %% Originally, nothing is put at all: we can place it every
         %% time later (but before 'MakeRep' completes, of course);
         skip
      end

      %%
      meth !PutTailMark
         local WO in
            WO = self.WidgetObj

            %%
            %% Now, put both: the leading one with the default right
            %% gravity, and the tail one - with the left one:
            self.HeadMark = {WO putMarkBefore(@Size left#self $)}
            self.TailMark = {WO putMark(left right#self $)}
         end
      end

      %%
      %%
      meth insert(str:Str)
\ifdef DEBUG_RM
         {Show 'RepManagerObject::insert is applied'}
\endif
         %%
         Size <- @Size + {self.WidgetObj insert(Str $)}

         %%
\ifdef DEBUG_RM
         {Show 'RepManagerObject::insert is finished'}
\endif
      end

      %%
      %%
      meth replace(str:Str)
\ifdef DEBUG_RM
         {Show 'RepManagerObject::replace is applied'}
\endif
         %%
         local WO AuxSize in
            WO = self.WidgetObj

            %%
            %% 'AuxSize' is the total size of prefixes and suffixes;
            AuxSize = MetaRepManagerObject , GetAuxSize($)

            %%
            %% remove everything else, i.e. the proper representation;
            Size <-
            AuxSize + {WO [deleteBackward(@Size - AuxSize) insert(Str $)]}
         end

         %%
\ifdef DEBUG_RM
         {Show 'RepManagerObject::replace is finished'}
\endif
      end

      %%
      meth !BeginUpdate
         %%
         %% this is to do anyway;
         MetaRepManagerObject , BeginUpdate

         %%
         %% ... and now, set the cursor at the begin: a kind of
         %% 'block(0)' emulation:
         {self SetCursorAt}
         {self SkipAuxBegin}
         {self.WidgetObj advanceCursor(@Size)}
      end

      %%
      %% So, 'Size' attribute should carry a right value;
      meth !SetCursorAfter
         {self.WidgetObj setCursor(self.TailMark (@UsedIndentIn + @Size))}
      end

      %%
      %% Its semantic is to move after the last group in the last
      %% block. But we have only one :-))
      meth !AnchorLB
\ifdef DEBUG_RM
         case MetaRepManagerObject , GetAuxSize($) == @Size then
            {BrowserError
             'RepManagerObject: a primitive term cannot be empty!!!'}
         else skip
         end
\endif
         skip
      end

      %%
      %% Basically, there is nothing to do except to set a new
      %% 'indent-in' value. 'IndentOut' is a sum of 'IndentIn' and a
      %% term's size per definition of the term size;
      %%
      %% Note that this is correct only for primitive terms. For
      %% compound terms, 'IndentOut' is different from that sum, of
      %% course.
      meth !CheckLayout(IndentIn ?IndentOut)
         UsedIndentIn <- IndentIn
         IndentOut = IndentIn + @Size
      end

      %%
   end

   %%
   %% ... for compound objects;
   %%
   class CompoundRepManagerObject from MetaRepManagerObject
      %%

      %%
      feat
      %% subterm objects;
         Subterms               %

      %%
      attr
         !UsedIndentOut: InitValue
         CurrentBlock: 0        % 'MakeRep' make an empty zeroth group;
         MaxBlock: 0            %

      %%
      %%
      meth !MakeRep(isEnc:IsEncRep)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::MakeRep is applied'}
\endif
         %%
         self.Subterms = {Dictionary.new}

         %%
         %% the zeroth block will be created anyway;
         {Dictionary.put self.Subterms 0 0}

         %%
         MetaRepManagerObject , MakeRep(isEnc:IsEncRep)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::MakeRep is finished'}
\endif
      end

      %%
      %%
      meth !PutHeadMark
         %%
         %% originally (while drawing first time) it has left
         %% gravity, aka inside 'BeginUpdate'/'EndUpdate';
         self.HeadMark = {self.WidgetObj putMark(left left#self $)}
      end

      %%
      meth !PutTailMark
         %%
         %% Note that this is essential that the tail mark is put
         %% at the end. Otherwise, multiple (O(term depth)) tail
         %% marks must be moved by the wish process each time some
         %% new strings is inserted in, what is inefficient.
         self.TailMark =
         {self.WidgetObj [setMarkGravity(self.HeadMark right)
                          putMark(left right#self $)]}
      end

      %%
      %% 'GetSize'/'GetIndentIn' are inherited;
      meth !GetIndentOut($) @UsedIndentOut end

      %%
      meth !SetCursorAt
         MetaRepManagerObject , SetCursorAt
         CurrentBlock <- InitValue
      end

      %%
      %% [local;]
      meth !SetCursorAfter
         {self.WidgetObj setCursor(self.TailMark @UsedIndentOut)}
         CurrentBlock <- InitValue
      end

      %%
      meth !CloseRep
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::CloseRep is applied'}
\endif
         %%
         CompoundRepManagerObject , UnsetMarks

         %%
         %% This way around - unset glue marks, after that - subterm'
         %% and self marks, and flush them;
         MetaRepManagerObject , CloseRep

         %%
         %% Note: don't drop the subterms dictionary, because it's
         %% still needed!
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::CloseRep is finished'}
\endif
      end

      %%
      meth !FastCloseRep
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::FastCloseRep is applied'}
\endif
         %%
         CompoundRepManagerObject , UnsetMarks

         %%
         MetaRepManagerObject , FastCloseRep
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::FastCloseRep is applied'}
\endif
      end

      %%
      meth !CheckLayoutReq
         CompoundRepManagerObject
         , LayoutWrong
         CompoundRepManagerObject
         , ApplySubtermObjs(message:CheckLayoutReq)
      end

      %%
      meth !BeginUpdate
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::BeginUpdate is applied'}
\endif
         %%
         MetaRepManagerObject , BeginUpdate
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::BeginUpdate is finished'}
\endif
      end

      %%
      %% {Begin,End}UpdateSubterm groups - for recursive preparing
      %% for updating;
      meth !BeginUpdateSubterm(N)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::BeginUpdateSubterm is applied'
          # N}
\endif
         %%
         {self.ParentObj BeginUpdateSubterm(self.numberOf)}

         %%
         MetaRepManagerObject , OpenRep

         %%
         CompoundRepManagerObject , XXXUpdateSubterm(N left)

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::BeginUpdateSubterm is finished'}
\endif
      end

      %%
      meth !EndUpdateSubterm(N)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::EndUpdateSubterm is applied'
          # N}
\endif
         %%
         {self.ParentObj EndUpdateSubterm(self.numberOf)}

         %%
         MetaRepManagerObject , ShutRep

         %%
         CompoundRepManagerObject , XXXUpdateSubterm(N right)

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::EndUpdateSubterm is finished'}
\endif
      end

      %%
      %% It's available internally because whenever updating is going
      %% recursively ('UpdateSize'), then each of subterms must be
      %% prepared for that;
      meth XXXUpdateSubterm(FN Gravity)
         local Group B N in
            FN = B#N
            %%
            Group = CompoundRepManagerObject , GetGroup(b:B ln:N group:$)

            %%
            case
               case {Label Group}
               of e   then false
               [] t   then false
               [] s   then false
               [] st  then false
               [] sgs then true
               [] sgt then true
               [] gs  then true
               [] gt  then true
               else
                  {BrowserError '...::*UpdateSubterm: group type??!'}
                  false
               end
            then {self.WidgetObj setMarkGravity(Group.mark Gravity)}
            else skip
            end
         end
      end

      %%
      meth !EndUpdate
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::EndUpdate is applied'}
\endif
         MetaRepManagerObject , EndUpdate

         %%
         %% after 'BeginUpdate' one has to specify a block again;
         CurrentBlock <- InitValue
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::EndUpdate is finished'}
\endif
      end

      %%
      %% ... that is, it would not fit within a single line;
      meth !IsMultiLined($)
         @Size > @UsedIndentOut - @UsedIndentIn
      end

      %%
      %% ... when a term's representation has been built up (by
      %% 'makeTerm'), it's not guaranteed that cursor stays after the
      %% last group;
      meth !AnchorLB
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::AnchorLB is applied'}
\endif
         %%
         %% there are two cases:
         %% (a) the current block is the last one, then this is ok.
         %% (b) the current block is not a last one, then we use the
         %%     'AnchorGroup' method (see comments in the 'block'
         %%     method);
         %%
         case @CurrentBlock == @MaxBlock then skip
         else B N in
            %%
            case CompoundRepManagerObject , GetLastGroup(b:B ln:N found:$)
            then CompoundRepManagerObject , AnchorGroup(b:B ln:N)
            else
               {BrowserError
                'CompoundRepManagerObject: There must be a group!!!'}
            end
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::AnchorLB is finished'}
\endif
      end

      %%
      meth !LayoutOK
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::LayoutOK is applied'}
\endif
         MetaRepManagerObject , LayoutOK

         %%
         %% Trust it. It's updated during 'CheckLayout' (if ever
         %% necessary);
         %%
         %% 'UsedIndentOut' must either contain a correct value, or
         %% the term's layout must be checked in the futher (when a
         %% correct value will be recomputed).
         %%
         %% This is essential for making 'CheckLayout' correct: if a
         %% 'self's layout is NOT checked, and a wrong 'indent-out'
         %% is returned, this will lead to a wrong layout of all
         %% subsequent subterms in a parent term object.
         UsedIndentOut <- {self.WidgetObj getCursorCol($)}
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::LayoutOK is finished'}
\endif
      end

%%%
%%% Basic "subterms" primitives - create a block, add a group,
%%% read/add/update a group, etc.
%%%
%%%

      %%
      %% Declares a block - that is,
      %% (a) sets the 'CurrentBlock' attribute,
      %% (b) initializes it if it's a new one,
      %% (c) sets the cursor so that subsequent groups created by
      %%     'putG' appear at a right place;
      %%
      %% Note that this is the only way to set the 'CurrentBlock', and
      %% this *must* be the case because 'block' uses the previous
      %% value for deciding whether the cursor should be moved, and
      %% how it should be moved. On the other hand, each time the
      %% cursor is touched by some other primitives, the 'CurretBlock'
      %% must be dropped (and set by 'block' again later, if
      %% necessary). Of course, the 'CurrentBlock' is also dropped
      %% when 'EndUpdate';
      %%
      %% Basically, there are four cases in setting the cursor:
      %% 1. The same block is entered again. From the user's
      %%    perspective, that's bogus, but not forbidden. Internally,
      %%    this is heavely used - since 'MakeRep' sets the current
      %%    block# to zero - to avoid subsequent cursor movements;
      %% 2. A new, non-zeroth block is declared, and a previously
      %%    used one is a direct predecessor of it - then a new block
      %%    is created, but cursor is not touched;
      %% 3. A new, non-zeroth block is declared, but a previous one
      %%    is NOT a direct predecessor of it - then a nearest smaller
      %%    group (that might be of other than a direct predecessor
      %%    block!)  should be taken, and cursor set after it). A new
      %%    block is created as ususal.
      %% 4. A used, non-zeroth block is declared. There are three
      %%    further subcases:
      %%    (a) if a previous used block is a direct predecessor
      %%        and the block itself is empty, then the cursor is not
      %%        touched;
      %%    (b) ... in general - the cursor is set after the nearest
      %%        smaller group;
      %%    (c) ... and if there is none, anchor to the leading mark;
      %%
      meth block(N)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::block: ' # N}
         local NoBlock CM in
            NoBlock = {NewName}
            CM = {Dictionary.condGet self.Subterms N * DInfinite NoBlock}

            %%
            %% that is, a new block cannot be created after a
            %% non-existing one;
            case
               N < 0 orelse
               CM == NoBlock andthen N \= @MaxBlock + 1
            then
               {BrowserError
                'CompoundRepManagerObject::block: out of order!'}
            else skip           % ok
            end
         end
\endif
         %%
         local PrevBlock Base in
            PrevBlock = @CurrentBlock
            Base = N * DInfinite

            %%
            case N == PrevBlock then skip
               %% #1: stay at the place;
            elsecase N > @MaxBlock then          % N > 0;
               %% #2 & #3: a new block to be created;
               %%
               case PrevBlock == N - 1 then skip
                  %% #2': don't touch the cursor;
               else PB in                         % N > 0;
                  %% #3': some other block - move cursor?

                  %%
                  case
                     CompoundRepManagerObject
                     , GetPrevBlock(sb:N-1 b:PB found:$)
                  then PLN in
                     %%
                     PLN = {Dictionary.get self.Subterms PB*DInfinite}

                     %%
                     %% We have to anchor to a rightmost position of a
                     %% nearest previous group. ... oops, we use here
                     %% that beast:
                     %%    step backward through blocks and groups
                     %%    until some mark is found. Accumulated
                     %%    'Offset' (i.e. the distance from a mark
                     %%    found to a place we refer) and 'Indent'
                     %%    (i.e. the column number of a place we
                     %%    refer) are collected. As a result, the
                     %%    position we want to refer is "<Mark> +
                     %%    <Offset> chars", and 'Indent' is its
                     %%    column#;
                     CompoundRepManagerObject , AnchorGroup(b:PB ln:PLN)
                  else
                     %%
                     %% still empty - can occur only when the
                     %% representation is drawn the first time -
                     %% after that there *must* be some group;
                     {BrowserError
                      'CompoundRepManagerObject::block: no groups??!'}
                  end
               end

               %%
               %% #2'' & #3'': ... in any case, a new block is created;
               {Dictionary.put self.Subterms Base 0}
               MaxBlock <- N
            else                                       % @MaxBlock >= N > 0
               %% #4: a used block;
               %%
               %% Do we enter a (still) empty block after a direct
               %% predecessor? This is a frequent case where cursor
               %% movement can be avoided;
               case
                  PrevBlock == N - 1 andthen
                  {Dictionary.get self.Subterms Base} == 0
               then skip
               else PB in
                  %%
                  case
                     CompoundRepManagerObject
                     , GetPrevBlock(sb:N b:PB found:$)
                  then PLN in
                     %%
                     %% ... the general case: step backwards, but from
                     %% the given block itself:
                     PLN = {Dictionary.get self.Subterms PB*DInfinite}

                     %%
                     CompoundRepManagerObject , AnchorGroup(b:PB ln:PLN)
                  else
                     %%
                     %% still empty but since it's a used block -
                     %% i.e. not the last one - then it can happen
                     %% that there are no groups before. Anchor to
                     %% the begin;
                     {self  SetCursorAt}
                     {self SkipAuxBegin}
                  end
               end
            end

            %%
            CurrentBlock <- N
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::block is finished'}
\endif
      end

      %%
      meth getBlock($) @CurrentBlock end

      %%
      %% yields 'true' if there is a group 'FN';
      meth isGroup(b:B ln:LN is:$)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::isGroup: ' # B#LN}
\endif
         %%
         {Dictionary.member self.Subterms (B*DInfinite + LN)}
      end

      %%
      %% Stores a new group within a last declared block. 'N' must be
      %% a next "free slot" in that block;
      meth StoreNewGroup(ln:LN group:Group)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::StoreNewGroup: '
          # @CurrentBlock # LN # Group}
         local NoBlock CB Base CM in
            NoBlock = {NewName}
            CB = @CurrentBlock
            Base = case {Int.is CB} then (CB * DInfinite) else NoBlock end
            CM = {Dictionary.condGet self.Subterms Base NoBlock}

            %%
            case CB == InitValue orelse CM == NoBlock then
               {BrowserError
                'CompoundRepManagerObject::StoreNewGroup: no block!'}
            elsecase CM + 1 \= LN then
               {BrowserError
                'CompoundRepManagerObject::StoreNewGroup: out of order!'}
            else skip           % ok
            end
         end
\endif
         local Base in
            Base = @CurrentBlock * DInfinite

            %%
            %% Currently, all groups - of all blocks - are stored in a
            %% single dictionary, with offsets DInfinite from each
            %% other (that's the source for the 'width' limitation).
            %% Since groups are numbered from 1 up, the "zeroth" slot
            %% is used to keep the highest group number within a
            %% block;
            {Dictionary.put self.Subterms (Base + LN) Group}
            {Dictionary.put self.Subterms Base LN}
         end
      end

      %%
      meth ReplaceGroup(b:B ln:LN group:Group)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::ReplaceGroup: ' # B # LN # Group}
         local NoBlock Base CM in
            NoBlock = {NewName}
            Base = case {Int.is B} then (B * DInfinite) else NoBlock end
            CM = {Dictionary.condGet self.Subterms Base NoBlock}

            %%
            case B < 0 orelse B > @MaxBlock orelse CM == NoBlock then
               {BrowserError
                'CompoundRepManagerObject::ReplaceGroup: no block!'}
            elsecase LN < 1 orelse LN > CM then
               {BrowserError
                'CompoundRepManagerObject::ReplaceGroup: no group!'}
            else skip           % ok
            end
         end
\endif
         %%
         {Dictionary.put self.Subterms (B*DInfinite + LN) Group}
      end

      %%
      meth GetGroup(b:B ln:LN group:$)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::GetGroup: ' # B # LN}
         local NoBlock Base CM in
            NoBlock = {NewName}
            Base = case {Int.is B} then (B * DInfinite) else NoBlock end
            CM = {Dictionary.condGet self.Subterms Base NoBlock}

            %%
            case B < 0 orelse B > @MaxBlock orelse CM == NoBlock then
               {BrowserError
                'CompoundRepManagerObject::GetGroup: no block!'}
            elsecase LN < 1 orelse LN > CM then
               {BrowserError
                'CompoundRepManagerObject::GetGroup: no group!'}
            else skip           % ok
            end
         end
\endif
         %%
         {Dictionary.get self.Subterms (B*DInfinite + LN) $}
      end

      %%
      meth RemoveLastGroup
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::RemoveLastGroup: '}
         local NoBlock CB Base CM in
            NoBlock = {NewName}
            CB = @CurrentBlock
            Base = case {Int.is CB} then (CB * DInfinite) else NoBlock end
            CM = {Dictionary.condGet self.Subterms Base NoBlock}

            %%
            case CB == InitValue orelse CM == NoBlock then
               {BrowserError
                'CompoundRepManagerObject::RemoveLastGroup: no block!'}
            elsecase CM < 1 then
               {BrowserError
                'CompoundRepManagerObject::RemoveLastGroup: no group!'}
            else skip           % ok
            end
         end
\endif
         local Base CM in
            Base = @CurrentBlock * DInfinite
            CM = {Dictionary.get self.Subterms Base}

            %%
            {Dictionary.remove self.Subterms (Base + CM)}
            {Dictionary.put self.Subterms Base (CM - 1)}
         end
      end

      %%
      meth !GetObjG(b:B ln:LN obj:$)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::GetObjG' # (B#LN)}
\endif
         %%
         (CompoundRepManagerObject , GetGroup(b:B ln:LN group:$)).obj
      end

      %%
      meth getTermG(fn:FN term:$)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::getTermG' # FN}
\endif
         %%
         local B N in
            FN = B#N
            (CompoundRepManagerObject , GetObjG(b:B ln:N obj:$)).term
         end
      end

%%%
%%% Looping machinery - first/last groups, increment/decrement group
%%% numbers, "for" constructors of useful types ...
%%%

      %%
      %% Yield a nearest greater/smaller or equal non-empty block.
      %% 'Found' says whether it was found at all;
      %%
      meth GetNextBlock(sb:SB b:?B found:$)
         case SB > @MaxBlock then false
         elsecase {Dictionary.get self.Subterms SB*DInfinite} > 0
         then
            B = SB
            true
         else
            CompoundRepManagerObject
            , GetNextBlock(sb:(SB+1) b:?B found:$)
         end
      end
      meth GetPrevBlock(sb:SB b:?B found:$)
         case SB < 0 then false
         elsecase {Dictionary.get self.Subterms SB*DInfinite} > 0
         then
            B = SB
            true
         else
            CompoundRepManagerObject
            , GetPrevBlock(sb:(SB-1) b:?B found:$)
         end
      end

      %%
      %% Get number of the first/last group. 'Found' says whether
      %% they were found at all;
      %%
      meth GetFirstGroup(b:?B ln:?N found:Found)
         CompoundRepManagerObject
         , GetNextBlock(sb:0 b:B found:Found)
         N = 1
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::GetFirstGroup' # Found # B#N}
\endif
      end
      meth GetLastGroup(b:?B ln:?N found:Found)
         CompoundRepManagerObject
         , GetPrevBlock(sb:@MaxBlock b:B found:Found)
         case Found then N = {Dictionary.get self.Subterms B*DInfinite}
         else skip
         end
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::GetLastGroup' # Found # (B#N)}
\endif
      end

      %%
      %% These two functions yield a previous/next (valid!) group
      %% number, provided the start number is a valid one.
      %% 'Found' says whether there is one;
      %%
      meth DecNumber(sb:B sln:N b:?PB ln:?PN found:$)
\ifdef DEBUG_RM
         local Out in Out =
\endif
            %%
            case N > 1 then
               PB = B  PN = N-1
               true
            elsecase
               B > 0 andthen
               CompoundRepManagerObject , GetPrevBlock(sb:(B-1) b:PB found:$)
            then
               PN = {Dictionary.get self.Subterms PB*DInfinite}
               true
            else false
            end

            %%
\ifdef DEBUG_RM
            {Show 'CompoundRepManagerObject::DecNumber'
             # (B#N) # (PB#PN) # Out}
            Out
         end
\endif
      end
      meth IncNumber(sb:B sln:N b:?NB ln:?NN found:$)
\ifdef DEBUG_RM
         local Out in Out =
\endif
            %%
            case N >= {Dictionary.get self.Subterms B*DInfinite} then
               %%
               case
                  CompoundRepManagerObject
                  , GetNextBlock(sb:(B+1) b:NB found:$)
               then
                  NN = 1
                  true
               else false
               end
            else
               NB = B  NN = N + 1
               true
            end

            %%
\ifdef DEBUG_RM
            {Show 'CompoundRepManagerObject::IncNumber'
             # (B#N) # (NB#NN) # Out}
            Out
         end
\endif
      end

      %%
      %% Loops over groups in blocks - any directions and steps;
      %%
      %% 'B' and 'N' are starting group numbers;
      %% 'NextMeth' is a method which search for a next group number,
      %% and yields Found=false if there are none;
      %%
      %% 'LM' is a rep' manager's method, which is applied as
      %%   LM(Group Arg ToContinue)
      %% that is, 'Arg' is passed as a second argument;
      %%
      %% A boolean value returned stating whether all groups have
      %% been applied or not;
      %%
      meth ApplyGroups(b:B ln:N next:NextMeth lm:LM arg:Arg cont:Cont)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::ApplyGroups: '
          # B # N # NextMeth # LM # Arg}
\endif
         %%
         local Group in
            Group = CompoundRepManagerObject , GetGroup(b:B ln:N group:$)

            %%
            Cont =
            case {self  LM(group:Group b:B ln:N arg:Arg cont:$)}
            then NB NN in
               case {self  NextMeth(sb:B sln:N b:NB ln:NN found:$)}
               then
                  CompoundRepManagerObject
                  , ApplyGroups(b:NB ln:NN next:NextMeth
                                lm:LM arg:Arg cont:$)
               else true        % all done;
               end
            else false
            end
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::ApplyGroups is finished'}
\endif
      end

      %%
      %% a common case - apply all groups;
      %%
      meth ApplyAllGroups(lm:LM arg:Arg cont:$)
         local B N in
            case CompoundRepManagerObject , GetFirstGroup(b:B ln:N found:$)
            then
               CompoundRepManagerObject ,
               ApplyGroups(b:B ln:N next:IncNumber lm:LM arg:Arg cont:$)
            else true
            end
         end
      end
      meth ApplyAllGroupsRev(lm:LM arg:Arg cont:$)
         local B N in
            case CompoundRepManagerObject , GetLastGroup(b:B ln:N found:$)
            then
               CompoundRepManagerObject ,
               ApplyGroups(b:B ln:N next:DecNumber lm:LM arg:Arg cont:$)
            else true
            end
         end
      end

      %%
      %%
      meth !ApplySubtermObjs(message:Message)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::ApplySubtermObjs' # Message}
\endif
         CompoundRepManagerObject
         , ApplyAllGroups(lm:ApplyObj arg:Message cont:_)
      end

      %%
      meth ApplyObj(group:Group b:_ ln:_ arg:Message cont:$)
         %%
         case
            case {Label Group}
            of e   then false
            [] t   then true
            [] s   then false
            [] st  then true
            [] sgs then false
            [] sgt then true
            [] gs  then false
            [] gt  then true
            else
               {BrowserError
                'CompoundRepManagerObject::ApplyObj: unkown group type!'}
               false
            end
         then
            %% found a subterm object:
            {Group.obj Message}
         else skip
         end

         %%
         true                   % always continue;
      end

      %%
      %% Internal method - that's the code that should appear twice,
      %% in both 'CloseRep' and 'FastCloseRep';
      meth UnsetMarks
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::UnsetMarks'}
\endif
         %%
         %% there is no message - only local method.
         %%
         %% BTW, that's a place where dynamic, highr-order methods
         %% would be really nice;
         CompoundRepManagerObject
         , ApplyAllGroups(lm:UnsetMark arg:InitValue cont:_)
      end

      %%
      meth UnsetMark(group:Group b:B ln:LN arg:Arg cont:$)
         %%
         case
            case {Label Group}
            of e   then false
            [] t   then false
            [] s   then false
            [] st  then false
            [] sgs then true
            [] sgt then true
            [] gs  then true
            [] gt  then true
            else
               {BrowserError
                'CompoundRepManagerObject::UnsetMark: unkown group type!'}
               false
            end
         then
            %% found a mark:
            {self.WidgetObj unsetMark(Group.mark)}
         else skip
         end

         %%
         true                   % always continue;
      end

      %%
      %% Set the cursor just after a given group in a given block.
      %% This is implemented by scanning groups backwards with the
      %% goal to find a mark, and to find a place which indentation
      %% is known. Simultaneously, distances to a mark found and that
      %% place with known indentation are obtained (see also the
      %% comment for the 'ScanToken' class);
      %%
      %% The main question is whether a found indentation is a right
      %% one, and what would happen if it is not. There are the
      %% following cases (note - they are ordered):
      %% 1.  if there are no subterms, then it can be computed
      %%     from a 'UsedIndentIn' value, and either
      %%     (a) it's correct, then a value obtained is also
      %%         correct.
      %%     (b) it's not correct, then obviously  a value
      %%         obtained is not correct too, but this can happen
      %%         only if at least a parent object is requested to
      %%         be checked (some its subterms, before the 'self'
      %%         one, have been changed what have lead to other
      %%         indentation of a 'self's representation). So,
      %%         everything will be corrected anyway.
      %% 2.  if there is a subterm, then the necessary value is
      %%     its 'UsedIndentOut' plus a sum of string sizes after
      %%     it. 'UsedIndentOut' of a subterm may be either
      %%     correct or not, leading to a correct or a wrong value
      %%     of the 'self's 'UsedIndentOut':
      %%     (a) it's correct - then everything is fine;
      %%     (b) it's not - but this can happen only if that
      %%         subter's, and, therefore, 'self's layout will be
      %%         checked too (because it is a father of that
      %%         subterm;)
      %% 3.  if a glue with a line break was found, then an
      %%     indent-out value obtained this way is always correct.
      %%
      meth AnchorGroup(b:B ln:LN)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::AnchorGroup' # B # LN}
\endif
         %%
         local Token in
            Token = {New ScanToken init}

            %%
            %% If we still have not succeeded in getting of something,
            %% use 'HeadMark' and 'UsedIndentIn':
            case
               CompoundRepManagerObject
               , ApplyGroups(b:B ln:LN next:DecNumber
                             lm:AnchorGroupRec arg:Token cont:$)
            then
               %% is something still missing?
               %%
               case {Token gotMark($)} then skip
               else
                  AuxSizeB = CompoundRepManagerObject , GetAuxSizeB($)
               in
                  {Token setMarkIncOffset(self.HeadMark AuxSizeB)}
               end

               %%
               case {Token gotIndent($)} then skip
               else
                  AuxSizeB = CompoundRepManagerObject , GetAuxSizeB($)
               in
                  {Token setIndent(@UsedIndentIn + AuxSizeB)}
               end
            else skip           % both anchor and its offset are here;
            end

            %%
            {Token setCursorAt(self.WidgetObj)}
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::AnchorGroup is finished'}
\endif
      end

      %%
      meth AnchorGroupRec(group:Group b:_ ln:_ arg:Token cont:$)
         local GrType in
            GrType = {Label Group}
            %% two tasks: to find a mark, and to determine the
            %% indentation;

            %%
            case {Token gotMark($)} then skip
            elsecase GrType
            of e   then skip
            [] t   then
               %% tail mark;
               {Token setMark(Group.obj.TailMark)}
            [] s   then
               {Token incOffset(Group.strSize)}
            [] st  then
               %% tail mark;
               {Token setMark(Group.obj.TailMark)}
            [] sgs then
               %% glue mark;
               {Token setMarkIncOffset(Group.mark
                                       (Group.str2Size + Group.glueSize))}
            [] sgt then
               %% tail mark;
               {Token setMark(Group.obj.TailMark)}
            [] gs  then
               %% glue mark;
               {Token setMarkIncOffset(Group.mark
                                       (Group.strSize + Group.glueSize))}
            [] gt  then
               %% tail mark;
               {Token setMark(Group.obj.TailMark)}
            else
               {BrowserError
                'CompoundRepManagerObject::AnchorGroupRec: group type??!'}
            end

            %%
            case {Token gotIndent($)} then skip
            elsecase GrType
            of e   then skip
            [] t   then
               %% fetch 'UsedIndentOut' - and that's all;
               {Token setIndent({Group.obj GetIndentOut($)})}
            [] s   then
               {Token incIndent(Group.strSize)}
            [] st  then
               %% 'UsedIndentOut' ...
               {Token setIndent({Group.obj GetIndentOut($)})}
            [] sgs then
               {Token
                incIndent(Group.strSize + Group.glueSize + Group.str2Size)}
            [] sgt then
               %% 'UsedIndentOut' ...
               {Token setIndent({Group.obj GetIndentOut($)})}
            [] gs  then
               {Token incIndent(Group.strSize + Group.glueSize)}
            [] gt  then
               %% 'UsedIndentOut' ...
               {Token setIndent({Group.obj GetIndentOut($)})}
            else fail           % will fail ever before;
            end

            %%
            %% Now, if both the mark and indent came here, terminate
            %% the loop:
            case {Token gotMark($)} andthen {Token gotIndent($)}
            then false else true
            end
         end
      end

      %%
      %% It yields 'true' if a line break in a group (within
      %% the current block) would allow to surround some previous
      %% subterm's representation by a rectanlge.
      %%
      %% In order to find out this, groups scanned backwards from a
      %% given one (excluding it), and either:
      %% 1.  a group with a subterm object was found, then:
      %%     (a) it does fit within the same line - then it can be
      %%         surrounded by a rectange anyway,
      %%     (b) it does NOT fit - then a line break would help to
      %%         do that.
      %% 2.  a glue was found - then nothing has to be done (that
      %%     glue was checked before by itself);
      %% 3.  otherwise (no groups matching properties 1 or 2 were
      %%     found) - no line break is needed;
      %%
      %% Note that the fact that subterm objects are last group
      %% elements (if ever) is used here;
      %%
      meth NeedsLineBreak(b:B ln:N needs:Needs)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::NeedsLineBreak' # B # N}
\endif
         %%
         local LNeeds PB PN in
            %%

            %%
            Needs =
            case
               CompoundRepManagerObject
               , DecNumber(sb:B sln:N b:?PB ln:?PN found:$) == false orelse
               CompoundRepManagerObject
               , ApplyGroups(b:PB ln:PN next:DecNumber
                             lm:SearchMLSubterms arg:?LNeeds cont:$)
            then
               %% have not decided: searched through all available
               %% groups - case 3.
               false
            else
               %% decided something - return that value;
               LNeeds
            end
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::NeedsLineBreak is finished'}
\endif
      end

      %%
      %% The method's name stays for "search for a multi-lined
      %% subterm";
      meth SearchMLSubterms(group:Group b:_ ln:_ arg:Needs cont:$)
         local GrType in
            GrType = {Label Group}

            %%
            %% first, check the case 1.
            case
               case GrType
               of e   then false
               [] t   then true
               [] s   then false
               [] st  then true
               [] sgs then false
               [] sgt then true
               [] gs  then false
               [] gt  then true
               else
                  {BrowserError
                   'CompoundRepManagerObject::SarchMLSubterms: group type??!'}
                  false
               end
            then
               %% found a subterm:
               Needs = {Group.obj IsMultiLined($)}
               false

               %%
               %% now, look at the case 2.:
            elsecase
               case GrType
               of e   then false
               [] t   then false
               [] s   then false
               [] st  then false
               [] sgs then true
               [] sgt then true
               [] gs  then true
               [] gt  then true
               else
                  {BrowserError
                   'CompoundRepManagerObject::SarchMLSubterms: group type??!'}
                  false
               end
            then
               %% found a glue:
               Needs = false
               false
            else
               true             % continue;
            end
         end
      end

      %%
      %% First, we check whether the 'check layout' step must be
      %% performed at all. After that, we walk sequentially through
      %% all groups, and the final cursor# is the new 'indent-out';
      %%
      %% A cursor positions, both before- and after-, are indefinite
      %% (but, of course, not the same in general - it can move it);
      %%
      meth !CheckLayout(IndentIn ?IndentOut)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::CheckLayout '
          # IndentIn # self.term}
\endif
         %%
         case
            IndentIn == @UsedIndentIn andthen
            @Size == @SavedSize
         then IndentOut = @UsedIndentOut
         else
            %%
            UsedIndentIn <- IndentIn

            %%
            %% Note that nobody else can access 'UsedIndentOut' while
            %% it "runs" through all the groups - so, it's safe (and
            %% isn't completely senseless - one can say that it
            %% "approximates" a right value);
            UsedIndentOut <-
            IndentIn + MetaRepManagerObject , GetAuxSizeB($)

            %%
            CompoundRepManagerObject
            , ApplyAllGroups(lm:CheckLayoutGroup arg:InitValue cont:_)

            %%
            IndentOut =
            @UsedIndentOut + MetaRepManagerObject , GetAuxSizeE($)
            UsedIndentOut <- IndentOut

            %%
            %% Note that 'LayoutOK' used here is taken from the
            %% 'MetaRepManagerobject' - this is because we don't have
            %% to set 'UsedIndentOut' anymore, and, on the other
            %% side, we don't know we cursor stays right now;
            MetaRepManagerObject , LayoutOK
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::CheckLayout is finished '
          # IndentOut}
\endif
      end

      %%
      %% so, 'UsedIndentOut' keeps 'indent-in', and after that -
      %% 'indent-out' (which is 'indent-in' for the next group);
      meth CheckLayoutGroup(group:Group b:B ln:N arg:_ cont:$)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::CheckLayoutGroup: '
          # B # N # @UsedIndentOut}
\endif
         %%
         UsedIndentOut <-
         case {Label Group}
         of e   then @UsedIndentOut     % rare case?
         [] t   then {Group.obj CheckLayout(@UsedIndentOut $)}
         [] s   then @UsedIndentOut + Group.strSize
         [] st  then
            UsedIndentOut <- @UsedIndentOut + Group.strSize

            %%
            {Group.obj CheckLayout(@UsedIndentOut $)}
         [] sgs then
            UsedIndentOut <- @UsedIndentOut + Group.strSize

            %%
            CompoundRepManagerObject , CheckGlue(group:Group b:B ln:N)

            %%
            %% Now, 'UsedIndentOut' carries new indentation -
            %% after the glue;
            @UsedIndentOut + Group.str2Size
         [] sgt then
            UsedIndentOut <- @UsedIndentOut + Group.strSize

            %%
            CompoundRepManagerObject , CheckGlue(group:Group b:B ln:N)

            %%
            {Group.obj CheckLayout(@UsedIndentOut $)}
         [] gs  then
            %%
            CompoundRepManagerObject , CheckGlue(group:Group b:B ln:N)

            %%
            @UsedIndentOut + Group.strSize
         [] gt  then
            %%
            CompoundRepManagerObject , CheckGlue(group:Group b:B ln:N)

            %%
            {Group.obj CheckLayout(@UsedIndentOut $)}
         else
            {BrowserError
             'CompoundRepManagerObject::CheckLayoutGroup: group type??!'}
            @UsedIndentOut
         end

         %%
         true
      end

      %%
      %% 'UsedIndentOut' keeps the glue's indentation (that is,
      %% indentation of its mark);
      meth CheckGlue(group:Group b:B ln:N)
         local WO ReqNL ReqIndent ReqGlueSize in
            WO = self.WidgetObj
            ReqNL = CompoundRepManagerObject , EvalDesc(Group.desc $)

            %%
            ReqGlueSize =
            case
               ReqNL orelse
               CompoundRepManagerObject , NeedsLineBreak(b:B ln:N needs:$)
            then
               %% requested to be expanded;
               %%
               ReqIndent = @UsedIndentIn +
               {Max
                CompoundRepManagerObject , EvalDesc(self.indentDesc $)
                0}       % it cannot be less than 0. Per definition :-)
\ifdef DEBUG_RM
               case ReqIndent >= DInfinite then
                  {BrowserError '... infinity indentation!!!'}
               else skip
               end
\endif

               %%
               case ReqIndent < @UsedIndentOut then
                  %%
                  %% that is, it makes sense to break the line here;
                  ReqIndent + DSpace   % + '\n';
               else 0                  % no line break;
               end
            else 0
            end
\ifdef DEBUG_RM
            {Show '...CheckGlue: '#(B#N)#ReqNL#Group.glueSize#ReqGlueSize}
\endif

            %%
            case ReqGlueSize == Group.glueSize then
               %% either no glue, or of the same size;
               %%
               case ReqGlueSize > 0 then
                  UsedIndentOut <- ReqIndent
               else skip
               end
            elsecase ReqGlueSize > 0 then NewGroup in
               %% expanded!;
               %%
               %% two subcases - either it was a zero glue, or its
               %% size is different:
               %%
               {WO setCursor(Group.mark @UsedIndentOut)}

               %%
               case Group.glueSize == 0 then Spaces in
                  %%
                  %% there were no glue - we have to take care about
                  %% the mark's gravity:
                  Spaces = {CreateSpaces ReqIndent}
                  {WO [setMarkGravity(Group.mark left)
                       insertNL insert(Spaces _)
                       setMarkGravity(Group.mark right)]}

                  %%
               else GS in
                  GS = Group.glueSize
                  case GS > ReqGlueSize then
                     %% remove something;
                     {WO [advanceCursor(DSpace)
                          deleteForward(GS - ReqGlueSize)]}
                  else SubSpaces in       % ReqGlueSize > GS
                     SubSpaces = {CreateSpaces (ReqGlueSize - GS)}

                     %%
                     {WO [advanceCursor(DSpace) insert(SubSpaces _)]}
                  end
               end

               %%
               NewGroup = {AdjoinAt Group glueSize ReqGlueSize}
               CompoundRepManagerObject
               , ReplaceGroup(b:B ln:N group:NewGroup)

               %%
               UsedIndentOut <- ReqIndent
            else NewGroup in    % ReqGlueSize == 0 and Group.glueSize \= 0
               %% that is, there may be no glue but there is one -
               %% remove it;
               %%
               {WO [setCursor(Group.mark @UsedIndentOut)
                    deleteForward(Group.glueSize)]}

               %%
               NewGroup = {AdjoinAt Group glueSize 0}
               CompoundRepManagerObject
               , ReplaceGroup(b:B ln:N group:NewGroup)

               %%
               %% 'UsedIndentOut' keeps its value;
            end
         end
      end

      %%
      %% Checks whether 'STObj' is still a subterm object, and if so -
      %% updates the size;
      meth !SubtermSizeChanged(STObj OldSize NewSize)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::SubtermSizeChanged'
          # STObj.numberOf # OldSize # NewSize}
\endif
         %%
         local FN B N in
            FN = STObj.numberOf
            FN = B#N

            %%
            case
               CompoundRepManagerObject , isGroup(b:B ln:N is:$) andthen
               STObj == CompoundRepManagerObject , GetObjG(b:B ln:N obj:$)
            then MyOldSize MyNewSize in
               MyOldSize = @Size

               %%
               %% 'SavedSize' is unequal to 'Size' - 'CheckLayout' is
               %% requested;
               MyNewSize = MyOldSize - OldSize + NewSize
               Size <- MyNewSize
               MetaRepManagerObject , LayoutWrong

               %%
               %% up to a root term object;
               ControlObject , SizeChanged(MyOldSize MyNewSize)
            else skip
            end
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::SubtermSizeChanged is finished'}
\endif
      end

      %%
      %% 'Draw' primitives;
      %%

      %%
      meth putG_E(ln:LN)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_E'}
\endif
         %%
         CompoundRepManagerObject , StoreNewGroup(ln:LN group:e)
      end

      %%
      meth putG_S(ln:LN str:Str)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_S' # LN}
\endif
         %%
         local StrSize Group in
            %%
            StrSize = {self.WidgetObj insert(Str $)}
            Size <- @Size + StrSize

            %%
            Group = s(strSize: StrSize)
            CompoundRepManagerObject , StoreNewGroup(ln:LN group:Group)
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_S is finished'}
\endif
      end

      %%
      meth putG_T(ln:LN term:Term)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_T' # LN}
\endif
         %%
         local Obj ObjSize Group in
            %%

            %%
            Obj =
            CompoundControlObject
            , PutSubterm(n:        @CurrentBlock # LN
                         st:       Term
                         obj:      $)

            %%
            ObjSize = {Obj GetSize($)}
            Size <- @Size + ObjSize

            %%
            Group = t(obj: Obj)
            CompoundRepManagerObject , StoreNewGroup(ln:LN group:Group)
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_T is finished'}
\endif
      end

      %%
      meth putG_ST(ln:LN str:Str term:Term)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_ST' # LN}
\endif
         %%
         local StrSize Obj ObjSize Group in
            %%

            %%
            StrSize = {self.WidgetObj insert(Str $)}

            %%
            Obj =
            CompoundControlObject
            , PutSubterm(n:        @CurrentBlock # LN
                         st:       Term
                         obj:      $)

            %%
            ObjSize = {Obj GetSize($)}
            Size <- @Size + StrSize + ObjSize

            %%
            Group = st(strSize:StrSize obj:Obj)
            CompoundRepManagerObject , StoreNewGroup(ln:LN group:Group)
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_ST is finished'}
\endif
      end

      %%
      %% 'GlueMark' is a (new) glue mark, and 'GlueSize' - the size
      %% of the glue being put. Note that the 'glue' mark is
      %% temporarily set with the left gravity - this has to be
      %% toggled later;
      meth PutGlue(ln:LN dp:DP gm:?GlueMark gs:?GlueSize)
         local WO LineSize GlueIndent in
            WO = self.WidgetObj
            LineSize = {self.store read(StoreTWWidth $)}

            %%
            %% Set the glue's mark;
            GlueMark = {WO putMark(left left#self $)}
            GlueIndent = {WO getCursorCol($)}

            %%
            %% Decide whether this glue should be extended or not,
            %% what is done using the 'decision procedure'.
            GlueSize =
            case
               {DP @UsedIndentIn GlueIndent LineSize} orelse
               CompoundRepManagerObject
               , NeedsLineBreak(b:@CurrentBlock ln:LN needs:$)
            then ReqIndent in
               %% line break is requested;

               %%
               ReqIndent = @UsedIndentIn +
               {Max
                CompoundRepManagerObject , EvalDesc(self.indentDesc $)
                0}       % it cannot be less than 0. Per definition :-)
\ifdef DEBUG_RM
               case ReqIndent >= DInfinite then
                  {BrowserError '... infinity indentation!!!'}
               else skip
               end
\endif

               %%
               case ReqIndent < GlueIndent then Spaces in
                  %%
                  %% ... it makes sense to break the line here;
                  Spaces = {CreateSpaces ReqIndent}
                  {WO [insertNL insert(Spaces _)]}
                  %% the (Browser) Tcl/Tk interface keeps now new
                  %% column#;
                  ReqIndent + DSpace    % i.e. + '\n';
               else 0           % no line break - an empty glue;
               end
            else 0              % no line break has been ever requested;
            end
         end
      end

      %%
      meth putG_SGT(ln:LN str:Str dp:DP desc:Desc term:Term)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_SGT' # LN}
\endif
         %%
         local WO StrSize GlueMark GlueSize Obj ObjSize Group in
            WO = self.WidgetObj

            %%
            StrSize = {WO insert(Str $)}

            %%
            CompoundRepManagerObject
            , PutGlue(ln:LN dp:DP gm:GlueMark gs:GlueSize)

            %%
            Obj =
            CompoundControlObject
            , PutSubterm(n:        @CurrentBlock # LN
                         st:       Term
                         obj:      $)

            %%
            {WO setMarkGravity(GlueMark right)}

            %%
            ObjSize = {Obj GetSize($)}
            Size <- @Size + StrSize + ObjSize

            %%
            Group = sgt(strSize:  StrSize
                        mark:     GlueMark
                        desc:     Desc
                        glueSize: GlueSize
                        obj:      Obj)

            %%
            CompoundRepManagerObject , StoreNewGroup(ln:LN group:Group)
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_SGT is finished'}
\endif
      end

      %%
      meth putG_SGS(ln:LN str:Str dp:DP desc:Desc str2:Str2)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_SGS' # LN}
\endif
         %%
         local WO StrSize GlueMark GlueSize Str2Size Group in
            WO = self.WidgetObj

            %%
            StrSize = {WO insert(Str $)}

            %%
            CompoundRepManagerObject
            , PutGlue(ln:LN dp:DP gm:GlueMark gs:GlueSize)

            %%
            Str2Size = {WO [insert(Str2 $) setMarkGravity(GlueMark right)]}

            %%
            Size <- @Size + StrSize + Str2Size

            %%
            Group = sgs(strSize:  StrSize
                        mark:     GlueMark
                        desc:     Desc
                        glueSize: GlueSize
                        str2Size: Str2Size)
            %%
            CompoundRepManagerObject , StoreNewGroup(ln:LN group:Group)
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_SGS is finished'}
\endif
      end

      %%
      meth putG_GS(ln:LN dp:DP desc:Desc str:Str)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_GS' # LN}
\endif
         %%
         local WO StrSize GlueMark GlueSize Group in
            WO = self.WidgetObj

            %%
            CompoundRepManagerObject
            , PutGlue(ln:LN dp:DP gm:GlueMark gs:GlueSize)

            %%
            StrSize = {WO [insert(Str $) setMarkGravity(GlueMark right)]}

            %%
            Size <- @Size + StrSize

            %%
            Group = gs(mark:     GlueMark
                       desc:     Desc
                       glueSize: GlueSize
                       strSize:  StrSize)
            %%
            CompoundRepManagerObject , StoreNewGroup(ln:LN group:Group)
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_GS is finished'}
\endif
      end

      %%
      meth putG_GT(ln:LN dp:DP desc:Desc term:Term)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_GT' # LN}
\endif
         %%
         local WO Obj ObjSize GlueMark GlueSize Group in
            WO = self.WidgetObj

            %%
            CompoundRepManagerObject
            , PutGlue(ln:LN dp:DP gm:GlueMark gs:GlueSize)

            %%
            Obj =
            CompoundControlObject
            , PutSubterm(n:        @CurrentBlock # LN
                         st:       Term
                         obj:      $)

            %%
            {WO setMarkGravity(GlueMark right)}

            %%
            ObjSize = {Obj GetSize($)}
            Size <- @Size + ObjSize

            %%
            Group = gt(mark:     GlueMark
                       desc:     Desc
                       glueSize: GlueSize
                       obj:      Obj)
            %%
            CompoundRepManagerObject , StoreNewGroup(ln:LN group:Group)
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::putG_GT is finished'}
\endif
      end

      %%
      %%
      meth EvalDesc(IndExpr $)
         %%
         case {Int.is IndExpr} then IndExpr
         elsecase IndExpr
         of st_size(N) then B LN in
            N = B#LN
            %%
            case CompoundRepManagerObject , isGroup(b:B ln:LN is:$)
            then Group in
               Group =
               CompoundRepManagerObject , GetGroup(b:B ln:LN group:$)

               %%
\ifdef DEBUG_RM
               case
                  case {Label Group}
                  of e   then false
                  [] t   then true
                  [] s   then false
                  [] st  then true
                  [] sgs then false
                  [] sgt then true
                  [] gs  then false
                  [] gt  then true
                  else
                     {BrowserError
                      'CompoundRepManagerObject::EvalDesc: group type??!'}
                     false
                  end
               then skip        % fine - there is an object;
               else
                  {BrowserError
                   'CompoundRepManagerObject::EvalDesc: no object in a group!'}
               end
\endif

               %%
               {Group.obj GetSize($)}
            else 0
            end

         [] gr_size(N) then B LN in
            N = B#LN
            %%
            case CompoundRepManagerObject , isGroup(b:B ln:LN is:$)
            then Group in
               Group =
               CompoundRepManagerObject , GetGroup(b:B ln:LN group:$)

               %%
               case {Label Group}
               of e   then 0
               [] t   then {Group.obj GetSize($)}
               [] s   then Group.strSize
               [] st  then {Group.obj GetSize($)} + Group.strSize
               [] sgs then Group.strSize + Group.str2Size
               [] sgt then {Group.obj GetSize($)} + Group.strSize
               [] gs  then Group.strSize
               [] gt  then {Group.obj GetSize($)}
               else
                  {BrowserError
                   'CompoundRepManagerObject::EvalDesc: group type??!'}
                  0
               end
            else 0
            end

         [] self_size then @Size

         [] line_size then {self.store read(StoreTWWidth $)}

            %%
            %% Note that 'UsedIndentOut' contains the current
            %% position in a line in the 'checkLayout' context, where
            %% 'EvalDesc' is used!
         [] current then @UsedIndentOut

         [] st_indent(N) then B LN in
            N = B#LN
            %%
            case CompoundRepManagerObject , isGroup(b:B ln:LN is:$)
            then Group in
               Group =
               CompoundRepManagerObject , GetGroup(b:B ln:LN group:$)

               %%
\ifdef DEBUG_RM
               case
                  case {Label Group}
                  of e   then false
                  [] t   then true
                  [] s   then false
                  [] st  then true
                  [] sgs then false
                  [] sgt then true
                  [] gs  then false
                  [] gt  then true
                  else
                     {BrowserError
                      'CompoundRepManagerObject::EvalDesc: group type??!'}
                     false
                  end
               then skip        % fine - there is an object;
               else
                  {BrowserError
                   'CompoundRepManagerObject::EvalDesc: no object in a group!'}
               end
\endif

               %%
               {Group.obj GetIndentIn($)}
            else DInfinite
            end

         [] self_indent then @UsedIndentIn

         [] '+'(A1 A2) then R1 R2 in
            %%
            CompoundRepManagerObject , EvalDesc(A1 R1)
            CompoundRepManagerObject , EvalDesc(A2 R2)

            %%
            R1 + R2

         [] '-'(A1 A2) then R1 R2 in
            %%
            CompoundRepManagerObject , EvalDesc(A1 R1)
            CompoundRepManagerObject , EvalDesc(A2 R2)

            %%
            R1 - R2

         [] 'min'(A1 A2) then R1 R2 in
            %%
            CompoundRepManagerObject , EvalDesc(A1 R1)
            CompoundRepManagerObject , EvalDesc(A2 R2)

            %%
            {Min R1 R2}

         [] 'max'(A1 A2) then R1 R2 in
            %%
            CompoundRepManagerObject , EvalDesc(A1 R1)
            CompoundRepManagerObject , EvalDesc(A2 R2)

            %%
            {Max R1 R2}

         [] '>'(A1 A2) then R1 R2 in
            %%
            CompoundRepManagerObject , EvalDesc(A1 R1)
            CompoundRepManagerObject , EvalDesc(A2 R2)

            %%
            R1 > R2

         [] '<'(A1 A2) then R1 R2 in
            %%
            CompoundRepManagerObject , EvalDesc(A1 R1)
            CompoundRepManagerObject , EvalDesc(A2 R2)

            %%
            R1 < R2

         else
            {BrowserError
             'CompoundRepManagerObject::EvalDesc: expression??!'}
            DInfinite
         end
      end

      %%
      %%
      meth replaceTermG(fn:FN term:Term)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::replaceTermG' # FN}
\endif
         %%
         local
            WO SwapGravity B LN OldGroup OldSize NewObj NewSize NewGroup
         in
            WO = self.WidgetObj
            FN = B#LN

            %%
            OldGroup =
            CompoundRepManagerObject , GetGroup(b:B ln:LN group:$)

            %%
            %% It is true whenever a glue's mark (which normally has
            %% the right gravity) can escape its location;
            SwapGravity =
            case {Label OldGroup}
            of e   then false
            [] t   then false
            [] s   then false
            [] st  then false
            [] sgs then true
            [] sgt then true
            [] gs  then true
            [] gt  then true
            else
               {BrowserError
                'CompoundRepManagerObject::ApplyObj: unkown group type!'}
               false
            end
            andthen OldGroup.glueSize == 0

            %%
            case SwapGravity then {WO setMarkGravity(OldGroup.mark left)}
            else skip
            end

            %%
            %% ... but before, set the cursor at a right position;
            local OGObj = OldGroup.obj in
               OldSize = {OGObj GetSize($)}
               {OGObj SetCursorAt}
               {OGObj Close}
            end

            %%
            %% the cursor has been moved - the 'CurrentBlock' is
            %% lost. Note that this must be the case since otherwise
            %% 'block' and 'AnchorLB' primitives will be misleaded;
            CurrentBlock <- InitValue

            %%
            NewObj =
            CompoundControlObject
            , PutSubterm(n:        FN
                         st:       Term
                         obj:      $)

            %%
            case SwapGravity then {WO setMarkGravity(OldGroup.mark right)}
            else skip
            end

            %%
            %% and now, modify own size;
            NewSize = {NewObj GetSize($)}
            Size <- @Size - OldSize + NewSize

            %%
            %% don't know what else is stored in there;
            NewGroup = {AdjoinAt OldGroup obj NewObj}
            CompoundRepManagerObject
            , ReplaceGroup(b:B ln:LN group:NewGroup)
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::replaceTermG is finished'}
\endif
      end

      %%
      %% Currently only the removing of a last group in a block is
      %% implemented. Basically, one have to use 'AnchorGroup' in
      %% order a "starting" point ('CurrentBlock' is going lost), and
      %% after that - as one would expect ...
      %%
      %% Note that the cursor is located just after that group;
      %%
      meth removeG(ln:LN)
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::removeG' # LN}

         %%
         case
            LN == {Dictionary.get self.Subterms (@CurrentBlock*DInfinite)}
         then skip              % ok;
         else
            {BrowserError
             'CompoundRepManagerObject::removeG: not the last group!!!'}
         end
\endif
         %%
         local WO Group in
            WO = self.WidgetObj
            Group =
            CompoundRepManagerObject
            , GetGroup(b:@CurrentBlock ln:LN group:$)
            CompoundRepManagerObject , RemoveLastGroup

            %%
            Size <- @Size -
            case {Label Group}
            of e   then 0

            [] t   then Size GObj = Group.obj in
               Size = {GObj GetSize($)}
               {GObj Close}
               Size

            [] s   then
               {WO deleteBackward(Group.strSize)}
               Group.strSize

            [] st  then GObj = Group.obj ObjSize in
               ObjSize = {GObj GetSize($)}
               {GObj Close}
               {WO deleteBackward(Group.strSize)}
               ObjSize + Group.strSize

            [] sgs then Size in
               Size = Group.strSize + Group.str2Size
               {WO deleteBackward(Size + Group.glueSize)}
               Size

            [] sgt then GObj = Group.obj ObjSize in
               ObjSize = {GObj GetSize($)}
               {GObj Close}
               {WO deleteBackward(Group.glueSize + Group.strSize)}
               ObjSize + Group.strSize

            [] gs  then
               {WO deleteBackward(Group.glueSize + Group.strSize)}
               Group.strSize

            [] gt  then GObj = Group.obj ObjSize in
               ObjSize = {GObj GetSize($)}
               {GObj Close}
               {WO deleteBackward(Group.glueSize)}
               ObjSize

            else
               {BrowserError
                'CompoundRepManagerObject::removeG: unkown group type!'}
               0
            end
         end

         %%
\ifdef DEBUG_RM
         {Show 'CompoundRepManagerObject::removeG is finished'}
\endif
      end

      %%
   end

   %%
end
