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
%%%  Control term classes;
%%%
%%%
%%%
%%%

local
   %% Generator of reference names;
   NewRefNameGen

   %%
   CheckCycleFun

   %%
   TDepth = {NewName}
   TermsStore = {NewName}
in

   %%
   %% Check for a cycle - and yield an equal object if found,
   %% and 'InitValue' otherwise;
   %% Goes bottom-up from an 'Obj' till a "root" object;
   %%
   fun {CheckCycleFun Term Obj}
      %%
      %% We could use also the logical equality between terms
      %% (in order to find "shortest" cycles), but it would not
      %% reflect the constraint store contents;

      %%
      if {EQ Obj.term Term} then
         %%
         if Obj.type == T_RootTerm then InitValue
         elseif {IsFree Obj.closed} then Obj
         else PO in
            %% i.e., this is garbage (or lack of synchronization);
            PO = Obj.ParentObj

            %%
            case PO
            of !InitValue then InitValue
            else {CheckCycleFun Term PO}
            end
         end
      else PO in
         PO = Obj.ParentObj

         %%
         case PO
         of !InitValue then InitValue
         else {CheckCycleFun Term PO}
         end
      end
   end

   %%
   %%
   fun {GetRootTermObject Obj}
      if Obj == InitValue orelse Obj.ParentObj == InitValue
      then Obj
      else {GetRootTermObject Obj.ParentObj}
      end
   end

%%%
%%%
%%%
   class MyClosableObject
      from Object.base
      feat closed
      meth close
         self.closed = unit
      end
      meth isClosed($)
         {IsDet self.closed}
      end
   end

%%%
%%%   "Generic" part of "master" term objects.
%%%
%%%
   class ControlObject from MyClosableObject
      %%
      feat
         term                   % browsed term itself;
         numberOf               % a number of its group;
         store                  % a global store;
         !TermsStore            % a 'terms' store (co-references);
         !ParentObj             %
         !IsPrimitive: true     %
      %% the type field is added to particular objects (e.g.
      %% AtomObject);

      %%
      attr
         !TDepth:     InitValue

      %%
      %% Generic 'make' method;
      %%
      meth !Make(term:       Term
                 depth:      Depth
                 numberOf:   NumberOf
                 parentObj:  ParentObjIn
                 store:      Store
                 iTermsStore: TermsStoreIn)
\ifdef DEBUG_CO
         {Show 'ControlObject::Make for the subterm '
          # Term # Depth # NumberOf # ParentObjIn
          # Store # TermsStoreIn}
\endif
         %%
         self.term = Term
         self.numberOf = NumberOf
         self.ParentObj = ParentObjIn
         self.store = Store
         self.TermsStore = TermsStoreIn

         %%
         TDepth <- Depth

         %%
         %% either with parentheses or not;
         {self  MakeRep(isEnc:  if self.IsPrimitive then false
                                else {BrowserTerm.delimiterLEQ
                                      self.delimiter ParentObjIn.delimiter}
                                end)}
      end

      %%
      %%  "undraw" + close;
      meth !Close
\ifdef DEBUG_CO
         {Show 'ControlObject::Close method for the term ' # self.term}
\endif
         %%
         MyClosableObject , close

         %%  overloaded depending on the "primitiveness" :-)
         %%
         {self  closeTerm}

         %%
         {self  CloseRep}
      end

      %%
      %%  ... the same, but leaves the representation itself where it is;
      meth !FastClose
\ifdef DEBUG_CO
         {Show 'ControlObject::FastClose method for the term '
          # self.term}
\endif
         %%
         MyClosableObject , close
         %%
         {self  closeTerm}

         %%
         {self  FastCloseRep}
      end

      %%
      meth isCoreferenced($)
\ifdef DEBUG_CO
         {Show 'ControlObject::isCoreferenced method for the term '
          # self.term # self.type}
\endif
         %%
         local RepMode in
            RepMode = {self.store read(StoreRepMode $)}

            %%
            (RepMode == GraphRep andthen
             {BrowserTerm.checkGraph self.type} andthen
             {CheckCycleFun self.term self.ParentObj} \= InitValue)
            orelse
            (RepMode == MinGraphRep andthen
             {BrowserTerm.checkMinGraph self.type} andthen
             {self.TermsStore checkCorefs(self $)})
         end
      end

      %%
      %% "replace me now!"
      %%
      %% There is no difference between a 'rebrowse' command issued
      %% by a term object and by a user;
      %%
      meth rebrowse
\ifdef DEBUG_CO
         {Show 'ControlObject::rebrowse method for the term '
          # self.term # self.type}
\endif
         %%
         ControlObject , Rebrowse
      end

      %%
      %% To be used when a watch point hits - it just queues
      %% a request in order to execute '{self checkTerm}'.
      %%
      %% Note that one *may not* queue a "direct" request for it,
      %% because it should be enclosed by a 'BeginUpdate'/'EndUpdate'
      %% pair;
      meth checkTermReq
\ifdef DEBUG_CO
         {Show 'ControlObject::checkTermReq method for the term '
          # self.term # self.type}
\endif
         %%
         local StreamObj in
            StreamObj = {self.store read(StoreStreamObj $)}

            %%
            {StreamObj enq(checkTerm(self))}
         end
      end

      %%
      %% A 'BeginUpdate'/'EndUpdate' wrapper for the 'checkTerm' (see
      %% above);
      meth !CheckTerm
         %%
         {self BeginUpdate}
         {self checkTerm}
         {self EndUpdate}
      end

      %%
      meth !SizeChanged(OldSize NewSize)
\ifdef DEBUG_CO
         {Show 'ControlObject::SizeChanged method for the term '
          # self.term # self.type # OldSize # NewSize}
\endif
         %%
         local StreamObj in
            StreamObj = {self.store read(StoreStreamObj $)}

            %%
            {StreamObj
             enq(subtermSizeChanged(self.ParentObj self OldSize NewSize))}
         end
      end

      %%
      %% Send to the 'RefObj' its name (a name of a reference
      %% (refVar)). If none is yet defined, generate one via the
      %% NewRefNameGen;
      %%
      meth !GenRefName(ReferenceObj Type)
\ifdef DEBUG_CO
         {Show 'ControlObject::GenRefName: term ' # self.term}
\endif
         %%
         local StreamObj StoredRefName RefName in
            StreamObj = {self.store read(StoreStreamObj $)}
            StoredRefName = RepManagerObject , GetRefName($)

            %%
            if StoredRefName == '' then NeedBraces in
               %%
               RefName = Type # {NewRefNameGen gen($)}
               %%
               %% So, we have to compare '=' and a parent's constructor;
               NeedBraces =
               {BrowserTerm.delimiterLEQ DEqualS self.ParentObj.delimiter}

               %%
               {self BeginUpdate}
               {self if {self IsEnc(are:$)} orelse NeedBraces == false
                     then PutRefName(refName: RefName)
                     else PutEncRefName(refName: RefName)
                     end}
               {self EndUpdate}
            else
               RefName = StoredRefName     % that's already here;
            end

            %%
            %% Note that a 'reference' term object does
            %% 'BeginUpdate'/'EndUpdate' by itself;
            {StreamObj enq(setRefName(ReferenceObj self RefName))}

            %%
         end
      end

      %%
      %% For atomic term objects - ignore the message, that is,
      %% don't shrink even if it should be. This is of course not
      %% correct, but who cares?
      meth !UpdateSize(_) skip end

      %%
      meth !SetSelected
         {{self.store read(StoreBrowserObj $)}
          SetSelected(self ({self hasCommas($)}))}
      end

      %%
      meth !Process
         ControlObject , SetSelected
         {{self.store read(StoreBrowserObj $)} Process}
      end

      %%
      %% General comment: event processing should be done sequentially
      %% with all other actions on terms, i.e. it has to be controlloed
      %% by a manager object too.
      %%
      %% Handler for button click events;
      meth !ButtonsHandler(Button)
         %%
         {self  case Button
                of '1' then SetSelected
                [] '2' then Process
                [] '3' then noop   % 'UnsetSelected';
                else noop
                end}
      end

      %%
      %% Handler for buttons double-click events;
      meth !DButtonsHandler(Button)
         %%
         {self  case Button
                of '1' then Expand
                [] '2' then Deref
                [] '3' then Shrink
                else noop
                end}
      end

      %%
      %%  A control primitive. It is used when
      %% (a) a user says "ok, re-browse this (sub)term!", and
      %% (b) a term object says "ok, re-browse me!" - by means of
      %%     'rebrowse' which finally leads to application of this
      %%     method;
      %%
      meth !Rebrowse
\ifdef DEBUG_CO
         {Show 'ControlObject::Rebrowse method ... '}
\endif
         %%
         local StreamObj in
            StreamObj = {self.store read(StoreStreamObj $)}

            %%
            {StreamObj enq(subtermChanged(self.ParentObj self))}
         end
      end

      %%
      meth !Shrink
\ifdef DEBUG_CO
         {Show 'ControlObject::shrink method for the term '
          # self.term # self.type}
\endif
         %%
         local StreamObj in
            StreamObj = {self.store read(StoreStreamObj $)}

            %%
            {StreamObj enq(changeDepth(self.ParentObj self 0))}
         end
      end

      %%
      %%  'Shrunken' and compound objects redefine this method;
      meth !Expand skip end
      meth !Deref skip end

      %%
      meth processOtherwise(Type Message)
         local PM in
            PM = case {Type.ofValue Message}
                 of atom then Message
                 [] name then {System.printName Message}
                 [] tuple then L in
                    L = {Label Message}
                    if {IsAtom L} then L
                    else {System.printName L}
                    end
                 [] record then L in
                    L = {Label Message}
                    if {IsAtom L} then L
                    else {System.printName L}
                    end
                 else
                    {BrowserError 'ControlObject::processOtherwise?'}
                    '???'
                 end

            %%
            {BrowserError Type # PM # '???'}
         end
      end

      %%
   end

   %%
   %%
   %%  'Meta' object for compound term objects;
   %%
   class CompoundControlObject from ControlObject
      %%
      feat
         !IsPrimitive: false    % override the control object's value;

      %%
      %%
      meth !Close
\ifdef DEBUG_CO
         {Show
          'CompoundControlObject::Close method for the term '
          # self.term}
\endif
         %%
         %% First, close subterms - because of the representation;
         CompoundRepManagerObject , ApplySubtermObjs(message:FastClose)

         %%
         ControlObject , Close
      end

      %%
      meth !FastClose
\ifdef DEBUG_CO
         {Show
          'CompoundControlObject::FastClose method for the term '
          # self.term}
\endif
         %%
         CompoundRepManagerObject , ApplySubtermObjs(message:FastClose)

         %%
         ControlObject , FastClose
      end

      %%
      %% Yields 'true' if a new subterm may be fully (with
      %% depth/width constraints) exposed;
      meth mayContinue($)
         {self.store read(StoreBreak $)} == false
      end

      %%
      %% places a subterm at a current position;
      %% This method is an internal one and used by the representation
      %% manager (sub-)object and by the "root term" object;
      %%
      %% Note that in some sense it does not manipulate the 'self' -
      %% it just puts a subterm. So, the presence of surrounding
      %% 'BeginUpdate'/'EndUpdate' cannot be (is not!) checked inside;
      meth !PutSubterm(n:N st:ST obj:?Obj)
\ifdef DEBUG_CO
         {Show
          'CompoundControlObject::PutSubterm method for the term '
          # self.term # N # ST}
\endif
         %%
         local Store RepMode ObjClass RefObj STDepth in
            %%
            Store = self.store
            RepMode = {Store read(StoreRepMode $)}
            STDepth = @TDepth - 1

            %%
            %% A shrunken object is generated in two cases -
            %% either the depth limit is exceeded, or the browser
            %% is working in 'break' mode;
            ObjClass =
            if
               STDepth > 0 andthen CompoundControlObject , mayContinue($)
            then STType in
               STType = {BrowserTerm.getTermType ST Store}

               %%
               RefObj =
               if
                  RepMode == GraphRep andthen
                  {BrowserTerm.checkGraph STType}
               then {CheckCycleFun ST self}
               elseif
                  RepMode == MinGraphRep andthen
                  {BrowserTerm.checkMinGraph STType}
               then {self.TermsStore checkANDStore(self ST Obj $)}
               else InitValue
               end

               %%
               if RefObj == InitValue then
                  %% none found -- proceed;
                  {BrowserTerm.getObjClass STType}
               else ReferenceTermObject
               end
            else ShrunkenTermObject
            end

            %%
            %% it's going to be browsed just at the current cursor
            %% position;
            Obj = {New ObjClass noop}
            {Obj Make(term:       ST
                      depth:      STDepth
                      numberOf:   N
                      parentObj:  self
                      store:      Store
                      iTermsStore: self.TermsStore)}

            %%
            if ObjClass == ReferenceTermObject then StreamObj RefType in
               StreamObj = {Store read(StoreStreamObj $)}
               RefType = if RepMode == GraphRep then 'C' else 'R' end

               %%
               %% 'RefObj' can lie on the same path with 'Obj'. This
               %% implies that we cannot just apply it right here.
               %% Therefore, we write:
               {StreamObj enq(genRefName(RefObj Obj RefType))}

               %%
               %% Note that 'RefObj' could get closed even before it
               %% processes the 'genRefName' message - let's check
               %% that;
               thread
                  {Wait RefObj.closed}
                  {Obj rebrowse}
               end
            end
         end
      end

      %%
      %% That's a "brute force" approach. There could be something
      %% smarter than just rebrowsing - but it's used for either
      %% shrinking or expanding only. So, that's ok;
      meth !ChangeDepth(Obj Depth)
\ifdef DEBUG_CO
         {Show 'CompoundControlObject::ChangeDepth method for the term '
          # self.term # self.type}
\endif
         %%
         local FN B N in
            FN = Obj.numberOf
            FN = B#N

            %%
            if
               CompoundRepManagerObject , isGroup(b:B ln:N is:$) andthen
               Obj == CompoundRepManagerObject , GetObjG(b:B ln:N obj:$)
            then CurDepth in
               %%
               %% ok, that's still a subterm object;
               CurDepth = @TDepth
               TDepth <- Depth + 1      % because it's "my" depth;

               %%
               CompoundRepManagerObject , BeginUpdate
               CompoundRepManagerObject , replaceTermG(fn:FN term:Obj.term)
               CompoundRepManagerObject , EndUpdate

               %%
               TDepth <- CurDepth
            else skip           % junk - ignore;
            end
         end
      end

      %%
      %% The internal counterpart for the 'subtermChanged' wich does
      %% enclosing and so forth;
      meth !SubtermChanged(Obj)
\ifdef DEBUG_CO
         {Show 'CompoundControlObject::SubtermChanged method for the term '
          # self.term # self.type}
\endif
         %%
         local FN B N in
            FN = Obj.numberOf
            FN = B#N

            %%
            if
               CompoundRepManagerObject , isGroup(b:B ln:N is:$) andthen
               Obj == CompoundRepManagerObject , GetObjG(b:B ln:N obj:$)
            then
               %%
               {self BeginUpdate}
               {self subtermChanged(FN)}
               {self EndUpdate}
            end
         end
      end

      %%
      %%
      meth !Expand
\ifdef DEBUG_CO
         {Show 'CompoundControlObject::Expand: term ' # self.term}
\endif
         local WidthInc in
            WidthInc = {self.store read(StoreWidthInc $)}

            %%
            CompoundRepManagerObject , BeginUpdate
            {self expand(WidthInc)}
            CompoundRepManagerObject , EndUpdate
         end
      end

      %%
      %%
      meth !ExpandWidth(WidthInc)
\ifdef DEBUG_CO
         {Show 'CompoundControlObject::ExpandWidth: term ' # self.term}
\endif
         %%
         CompoundRepManagerObject , BeginUpdate
         {self  expand(WidthInc)}
         CompoundRepManagerObject , EndUpdate
      end

      %%
      %% for compound objects;
      meth !UpdateSize(Depth)
\ifdef DEBUG_CO
         {Show 'CompoundControlObject::UpdateSize: term '
          # self.term # Depth}
\endif
         %%
         if Depth == 0 then {self  Shrink}
         else MaxWidth ActWidth NewDepth in
            %%
            TDepth <- Depth

            %%  first phase: update width;
            ActWidth = {self getShownWidth($)}
            MaxWidth = {self.store read(StoreWidth $)}

            %%
            %%  ... check whether we are allowed to show more subterms
            %% than actually shown;
            if {self  hasCommas($)} andthen ActWidth < MaxWidth
            then
               {{self.store read(StoreStreamObj $)}
                enq(expandWidth(self (MaxWidth-ActWidth)))}
            end

            %% second phase: update depth of subterms;
            NewDepth = Depth - 1

            %%
            CompoundRepManagerObject
            , ApplySubtermObjs(message: UpdateSize(NewDepth))
         end
      end

      %%
   end

%%%
%%%
%%% There is a group of special term objects;
%%%
%%% Note that these are complete, "self-contained" term objects (not
%%% control- or whichever subobjects);
%%%

   %%
   %% Root term object;
   %%
   %% They are used by the 'browser' objects, i.e.  they hide all
   %% internal 'rebrowse' and 'CheckSize' transactions;
   %%
   %% Basically, almost everything is redefined here - the only thing
   %% preserved is 'CompoundControlObject::PutSubterm';
   %%

   %%
   %% No representation manager subobject is ever needed;
   %%
   class RootTermObject from CompoundControlObject
      %%

      %%
      %% Additional features&attributes:
      feat
      %% 'type' and 'delimiter' are necesary since there is no proper
      %% "slave subobject;
         type: T_RootTerm       %  ... of the term object;
         delimiter: DSpaceGlue  %  per definition;
      %%
         !WidgetObj             %
         seqNumber              %  sequential number;
         underline              %  ... a (dotted) line after a term;

      %%
      %%  ... in additin to the "control" object;
      attr
         termObj:       InitValue

      %%
      %%  All these methods except the last couple can be used
      %% by a manager object *only*. There are few of them:
      %%  make/close
      %%  update depth/width
      %%  check layout
      %%

      %%
      %% we provide for a special 'make' method here;
      meth !Make(widgetObj:  WidgetObjIn
                 term:       Term
                 store:      Store
                 seqNumber:  SeqNumber)
\ifdef DEBUG_CO
         {Show 'RootTermObject::Make: is applied: ' # Term}
\endif
         %%
         %% These values must be already instantiated!
         %% We avoid this way such checking in term object's methods;
         self.numberOf = InitValue              % ...
         self.store = Store
         self.term = Term                       % ever used?
         self.TermsStore = {New TermsStoreClass init}
         self.ParentObj = InitValue             % must be 'InitValue';

         %%
         self.WidgetObj = WidgetObjIn
         self.seqNumber = SeqNumber

         %%
         TDepth <- {Store read(StoreDepth $)} + 1

         %%
         %% jump to the end of the text widget;
         {WidgetObjIn jumpEnd}

         %%
         termObj <-
         CompoundControlObject
         , PutSubterm(n:        DRootGroup
                      st:       Term
                      obj:      $)

         %%
         {WidgetObjIn insertNL}
         self.underline =
         if {Store read(StoreAreSeparators $)} then
            %%
            %% Note that 'makeUnderline' inserts yet another '\n'. The
            %% general convention is that outside the
            %% 'RootTermObject::Make' scope the 'end' index in the text
            %% widget has zero indentation;
            {WidgetObjIn makeUnderline($)}
         else InitValue
         end

         %%
         {@termObj scrollTo}
      end

      %%
      %%
      meth !Close
\ifdef DEBUG_CO
         {Show 'RootTermObject::Close is applied: ' # self.term}
\endif
         %%
         MyClosableObject , close

         %% ... + removes a representation;
         {@termObj SetCursorAt}
         {@termObj Close}

         %%
         {self.WidgetObj removeNL}
         if self.underline \= InitValue then
            {self.WidgetObj removeUnderline(self.underline)}
         end
\ifdef DEBUG_CO
         {Show 'RootTermObject::Close is finished'}
\endif
      end

      %%
      %% This message arrives from a manager object only;
      meth !UpdateSize
\ifdef DEBUG_CO
         {Show 'RootTermObject::UpdateSize: is applied: ' # self.term}
\endif
         %%
         {@termObj UpdateSize({self.store read(StoreDepth $)})}
      end

      %%
      %% Note that there is no "instant" update-the-layout processing
      %% (Like as in the Tcl/Tk "wish"), so the browser manager
      %% object has to apply this *sometimes*. Currently, this is
      %% done when a browser is idle;
      meth !CheckLayout
\ifdef DEBUG_CO
         {Show 'RootTermObject::CheckLayout: is applied: ' # self.term}
\endif
         %%
         {@termObj CheckLayout(0 _)}
      end

      %%
      %% These are necessary for the representation manager - to
      %% terminate the recursion;
      meth !BeginUpdateSubterm(_) skip end
      meth !EndUpdateSubterm(_) skip end

      %%
      meth !CheckLayoutReq
\ifdef DEBUG_CO
         {Show 'RootTermObject::CheckLayoutReq: is applied: ' # self.term}
\endif
         %%
         {@termObj CheckLayoutReq}
      end

      %%
      %% An attempt to perform a "user action" is an error: these
      %% actions are not defined on root term objects;
      %%

      %%
      %% ... and now - method(s) used by a term object (below) *only*;
      %%
      %% The fact that the parent object reference is internal is used
      %% here - a term object cannot apply its parent to an arbitrary
      %% message, but to only these ones:
      %%

      %%
      %% There is no "slave" object, so the subterm is replaced right
      %% here;
      meth !SubtermChanged(Obj)
\ifdef DEBUG_CO
         {Show 'RootTermObject::SubtermChanged method for the term '
          # self.term # self.type}
\endif
         %%
         if Obj.numberOf == DRootGroup andthen Obj == @termObj then
            %%
            {@termObj SetCursorAt}
            {@termObj Close}

            %%
            %% purge everything - it must be already empty anyway;
            {self.TermsStore init}

            %%
            termObj <-
            CompoundControlObject
            , PutSubterm(n:        DRootGroup
                         st:       self.term
                         obj:      $)

            %%
            %%  leave an underline in place;
         end
      end

      %%
      %%
      meth !ChangeDepth(Obj Depth)
\ifdef DEBUG_CO
         {Show 'RootTermObject::ChangeDepth: is applied, subterm# '
          # self.term # Depth}
\endif
         %%
         if Obj.numberOf == DRootGroup andthen Obj == @termObj
         then CurDepth in
            %%
            CurDepth = @TDepth
            TDepth <- Depth + 1

            %%
            %% that is, it is replaced by a new one;
            RootTermObject , SubtermChanged(Obj)

            %%
            TDepth <- CurDepth
         end
      end

      %%
      %% The 'SubtermSizeChanged' method is necessary here since
      %% there is no representation manager subobject;
      %%
      %% Root objects don't collect sizes, so the size arguments
      %% are ignored. So, it is basically just noop;
      meth !SubtermSizeChanged(_ _ _)
\ifdef DEBUG_CO
         {Show 'RootTermTWObject::SubtermSizeChanged is applied'}
\endif
         %%
         skip
      end

      %%
      %% empty event handlers.
      meth !ButtonsHandler(_) skip end
      meth !DButtonsHandler(_) skip end

      %%
      meth pickPlace(Where How)
         {@termObj pickPlace(Where How)}
      end

      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('RootTermObject::' Message)
      end

      %%
   end

   %%
   %%
   %% References;
   %%
   class ReferenceTermObject
      from
         ControlObject
         RepManagerObject

      %%
      %%
      feat
         type: T_Reference

      %%
      attr
         master: InitValue      % reference to a 'master' copy;

      %%
      meth makeTerm
\ifdef DEBUG_CO
         {Show 'ReferenceTermObject::makeTerm is applied' # self.term}
\endif
         %%
         %% start with ',,,';
         RepManagerObject , insert(str: DNameUnshown)
      end

      %%
      meth closeTerm skip end
      meth !Shrink skip end
      meth hasCommas($) false end

      %%
      %% Jump to a master's representation;
      meth !Deref
\ifdef DEBUG_CO
         {Show 'ReferenceTermObject::makeTerm is applied' # self.term}
\endif
         local Master in
            Master = @master

            %%
            if Master == InitValue then skip
               %% i.e. cannot yet deref - simply ignore it;
            else
               {Master pickPlace('begin' 'any')}
               {Master SetSelected}
            end
         end
      end

      %%
      %% Note that it does 'BeginUpdate'/'EndUpdate' by itself - in that
      %% sense, this is also a control method;
      %%
      meth !SetRefName(Master Name)
\ifdef DEBUG_CO
         {Show 'ReferenceTermObject::SetRefName is applied'#self.term}
\endif
         %%
         master <- Master

         %%
         RepManagerObject , BeginUpdate
         RepManagerObject , replace(str:Name)
         RepManagerObject , EndUpdate

         %%
\ifdef DEBUG_CO
         {Show 'ReferenceTermObject::SetRefName is finished'#self.term}
\endif
      end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('ReferenceTermObject::' Message)
      end

      %%
   end

   %%
   %%
   %% Shrunken subterms (because of 'Depth' limit);
   %%
   class ShrunkenTermObject
      from
         ControlObject
         RepManagerObject

      %%
      feat
         type: T_Shrunken

      %%
      meth makeTerm
\ifdef DEBUG_CO
         {Show 'ShrunkenTermObject::makeTerm is applied' # self.term}
\endif
         %%
         RepManagerObject , insert(str: DNameUnshown)
      end

      %%
      meth closeTerm skip end

      %%
      %%
      meth !Expand
         local DepthInc StreamObj in
            {self.store [read(StoreDepthInc DepthInc)
                         read(StoreStreamObj StreamObj)]}

            %%
            {StreamObj enq(changeDepth(self.ParentObj self DepthInc))}
         end
      end

      %%
      meth !UpdateSize(Depth)
         {{self.store read(StoreStreamObj $)}
          enq(changeDepth(self.ParentObj self Depth))}
      end

      %%
      meth !Shrink skip end
      meth hasCommas($) false end

      %%
      %%
      meth otherwise(Message)
         ControlObject , processOtherwise('ShrunkenTermObject::' Message)
      end

      %%
   end

%%%
%%%
%%%  Local auxiliary stuff;
%%%
%%%

   %%
   %%
   %% Generator of new reference names;
   %%
   NewRefNameGen = {New class $ from Object.base
                           prop final
                           %%
                           attr number: 1

                           %%
                           %%
                           meth gen(?Number)
                              Number = @number
                              number <- @number + 1
                           end

                           %%
                           %% Special method: get the length of the current
                           %% reference;
                           %% We use it by the calculating of MetaSize;
                           meth getLen($)
                              {VirtualString.length @number}
                           end
                        end
                    noop}

   %%
end
