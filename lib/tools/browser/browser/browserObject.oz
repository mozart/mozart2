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
%%%   BrowserClass - this is class which is given to users and which
%%%  instance is used for the default Oz browser;
%%%
%%%
%%%

%%%
%%%
%%% BrowserClass;
%%%
%%% Non-local methods which are denoted by names are used primarily
%%% as event handlers in window manager (aka e.g. 'Help');
%%%
%%%
class BrowserClass from Object.base
   %%
   feat
   %% some constants;
      !IsDefaultBrowser         %
      !IsView                   %  tcl-interface.oz;
   %%
   %% some (internal) objects;
      Store                     %  parameters store;
      BrowserBuffer             %  currently browsed terms (queue);
      BrowserStream             %  draw requests (queue);
   %%
      GetTermObjs               %  a function;

   %%
   attr
      selected: InitValue       %  selected term's object;
      UnselectSync: unit        %  gets bound when selection goes away;

   %%
   %%
   %%
   meth init(withMenus:        WithMenus          <= true
             origWindow:       OrigWindow         <= InitValue
             screen:           Screen             <= InitValue
             IsDefaultBrowser: IsIsDefaultBrowser <= false
             IsView:           IsIsView           <= false)
\ifdef DEBUG_BO
      {Show 'BrowserClass::init is applied'}
\endif
      %%
      %% additional security because fools (like me);
      self.IsDefaultBrowser = IsIsDefaultBrowser
      self.IsView = IsIsView

      %%
      self.Store =
      {New StoreClass
       [init
        store(StoreXSize IXSize)
        store(StoreYSize IYSize)
        store(StoreXMinSize IXMinSize)
        store(StoreYMinSize IYMinSize)
        store(StoreTWWidth 0)
        store(StoreDepth IDepth)
        store(StoreWidth IWidth)
        store(StoreFillStyle IFillStyle)
        store(StoreArityType IArityType)
        store(StoreSmallNames ISmallNames)
        store(StoreAreVSs IAreVSs)
        store(StoreDepthInc IDepthInc)
        store(StoreWidthInc IWidthInc)
%       store(StoreSmoothScrolling ISmoothScrolling)
        store(StoreShowGraph IShowGraph)
        store(StoreShowMinGraph IShowMinGraph)
        store(StoreTWFont ITWFontUnknown)     % first approximation;
        store(StoreBufferSize IBufferSize)
        store(StoreWithMenus case WithMenus == true
                             then true else false
                             end)
        store(StoreIsWindow false)
        store(StoreAreMenus false)
        store(StoreBrowserObj self)
        store(StoreStreamObj self.BrowserStream)
        store(StoreOrigWindow OrigWindow)
        store(StoreScreen Screen)
        store(StoreBreak false)
        store(StoreSeqNum 0)]}

      %%
      self.BrowserBuffer = {New BrowserBufferClass init(IBufferSize)}

      %%
      %% 'ManagerObject' is not directly accessible - but it can be
      %% closed by means of queuing of 'close' message;
      local Stream ManagerObject in
         %%
         %% only 'getContent' functionality is delegated to the
         %% manager object. A list of term objects is necessary in
         %% order to perform 'check layout' step when idle;
         self.GetTermObjs = fun {$} {self.BrowserBuffer getContent($)} end

         %%
         Stream = self.BrowserStream = {New BrowserStreamClass init}

         %%
         ManagerObject =
         {New BrowserManagerClass init(store:          self.Store
                                       getTermObjsFun: self.GetTermObjs)}
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::init is finished'}
\endif
      touch
   end

   %%
   %% Terminate browsing ASAP - by means of setting of
   %% a global flag ('StoreBreak') which is respected when new
   %% term objects are created;
   %% This flag must be reset by the drawing process (sitting
   %% behind the 'BrowserStream') when a currently last entry
   %% has been processed;
   meth break
\ifdef DEBUG_BO
      {Show 'BrowserClass::break is applied'}
\endif
      %%
      {self.Store store(StoreBreak true)}
   end

   %%
   %% Break + purge unprocessed suspensions + undraw everything;
   meth !Reset
\ifdef DEBUG_BO
      {Show 'BrowserClass::Reset is applied'}
\endif
      %%
      BrowserClass , break

      %%
      BrowserClass , UnsetSelected

      %% everything pending is cancelled;
      {self.BrowserBuffer purgeSusps}

      %%  'BrowserClass::Undraw' is an "in-thread" method;
      BrowserClass , Undraw({self.BrowserBuffer getSize($)})

      %%
      {Wait {self.BrowserStream enq(sync($))}}

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::Reset is finished'}
\endif
      touch
   end

   %%
   %%  ... and close the window;
   meth closeWindow
\ifdef DEBUG_BO
      {Show 'BrowserClass::closeWindow is applied'}
\endif
      %%
      BrowserClass , Reset
      {self.BrowserStream enq(closeWindow)}

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::closeWindow is finished'}
\endif
      touch
   end

   %%
   meth closeMenus
\ifdef DEBUG_BO
      {Show 'BrowserClass::closeMenus is applied'}
\endif
      %%
      {self.BrowserStream enq(closeMenus)}

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::closeMenus is finished'}
\endif
      touch
   end

   %%
   meth close
\ifdef DEBUG_BO
      {Show 'BrowserClass::close is applied'}
\endif
      %%
      BrowserClass , break

      %%
      {Wait {self.BrowserStream [enq(sync($)) enq(close)]}}

      %%
      {self.BrowserBuffer purgeSusps}

      %%
      {self.BrowserStream close}
      {self.BrowserBuffer close}
      {self.Store close}

      %%
      %%  'DefaultBrowser' is an object from the 'Browser.oz';
      %% That's the only occurence of it in browser/*.oz !
      case self.IsDefaultBrowser then {DefaultBrowser removeBrowser}
      else skip
      end

      %% simply throw away everything else;
      %%
      Object.closable , close
\ifdef DEBUG_BO
      {Show 'BrowserClass::close is finished'}
\endif
   end

   %%
   meth createWindow
\ifdef DEBUG_BO
      {Show 'BrowserClass::createWindow is applied'}
\endif
      %%
      case {self.Store read(StoreIsWindow $)} then skip
      else
         {self.BrowserStream enq(createWindow)}

         %%
         case {self.Store read(StoreWithMenus $)} then
            BrowserClass , createMenus
         else skip
         end
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::createWindow is finished'}
\endif
      touch
   end

   %%
   meth createMenus
\ifdef DEBUG_BO
      {Show 'BrowserClass::createMenus is applied'}
\endif
      %%
      case {self.Store read(StoreAreMenus $)} then skip
      else
         {self.BrowserStream
          [enq(createMenus)
           enq(entriesDisable([unselect rebrowse showOPI newView
                               clear clearAllButLast
                               expand shrink zoom deref]))]}
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::createMenus is finished'}
\endif
      touch
   end

   %%
   meth toggleMenus
\ifdef DEBUG_BO
      {Show 'BrowserClass::toggleMenus is applied'}
\endif
      %%
      BrowserClass ,
      case {self.Store read(StoreAreMenus $)} then closeMenus
      else createMenus
      end
\ifdef DEBUG_BO
      {Show 'BrowserClass::toggleMenus is finished'}
\endif
   end

   %%
   meth focusIn
\ifdef DEBUG_BO
      {Show 'BrowserClass::focusIn is applied'}
\endif
      {self.BrowserStream enq(focusIn)}

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::focusIn is finished'}
\endif
      touch
   end

   %%
   meth !ScrollTo(Obj Kind)
\ifdef DEBUG_BO
      {Show 'BrowserClass::ScrollTo is applied'}
\endif
      %%
      local RootTermObj NN in
         RootTermObj = {GetRootTermObject Obj}
         NN =
         RootTermObj.seqNumber + case Kind of 'forward' then 1 else ~1 end

         %%
         case {Filter {self.GetTermObjs} fun {$ TO} TO.seqNumber == NN end}
         of [NewRootTO] then
            %%
            {self.BrowserStream enq(pick(NewRootTO 'begin' 'top'))}
         else
            %% there is none - move to the top/bottom;
            {self.BrowserStream
             enq(pick(RootTermObj
                      case Kind of 'forward' then 'end'
                      else 'begin'
                      end 'any'))}
         end
      end
\ifdef DEBUG_BO
      {Show 'BrowserClass::ScrollTo is finished'}
\endif
   end

   %%
   %%  'browse' method (+ buffer maintaining);
   %% This method may suspend the caller thread if the buffer is full
   %% (but the object state is released);
   %%
   meth browse(Term)
\ifdef DEBUG_BO
      {Show 'BrowserClass::browse is applied'#Term}
\endif
      local RootTermObj Sync ProceedProc DiscardProc ToEnable in
         %%
         BrowserClass , createWindow    % check it;

         %%
         ToEnable = case self.IsView then noop
                    else enq(entriesEnable([clear]))
                    end

         %%
         case
            {self.BrowserBuffer getSize($)} >=
            {self.Store read(StoreBufferSize $)}
         then
            %% Startup a thread which eventually cleans up some place
            %% in the buffer;
            thread
               {self UndrawWait}
            end
         else skip              % just put a new one;
         end

         %%
         proc {ProceedProc}
            %%  spawns drawing work;
            {self.BrowserStream [enq(browse(Term RootTermObj)) ToEnable]}

            %%
            Sync = unit
         end
         %%
         proc {DiscardProc}
            Sync = unit
         end

         %%
         %%  allocate a slot inside of the buffer;
         %%  RootTermObj is yet a variable;
         {self.BrowserBuffer enq(RootTermObj ProceedProc DiscardProc)}

         %%
         %% it might be a little bit too early, but it *must* be
         %% inside the "touched" region (since e.g. 'BrowserBuffer'
         %% can be closed already when it's applied);
         case {self.BrowserBuffer getSize($)} > 1 then
            {self.BrowserStream enq(entriesEnable([clearAllButLast]))}
         else skip
         end

         %%
         touch
\ifdef DEBUG_BO
      {Show 'BrowserClass::browse is finished'}
\endif

         %%
         %% the object state is free;
         {Wait Sync}
      end
   end

   %%
   %% update the size of a buffer, and if necessary -
   %% wakeup suspended 'Browse' threads;
   meth !SetBufferSize(NewSize)
\ifdef DEBUG_BO
      {Show 'BrowserClass::SetBufferSize is applied'}
\endif
      %%
      case {IsInt NewSize} andthen NewSize > 0 then CurrentSize in
         {self.Store store(StoreBufferSize NewSize)}
         CurrentSize = {self.BrowserBuffer getSize($)}

         %%
         {self.BrowserBuffer resize(NewSize)}

         %%
         case NewSize < CurrentSize then
            %%
            BrowserClass , Undraw(CurrentSize - NewSize)
         else skip
         end
      else {BrowserError 'Illegal size of the browser buffer'}
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::SetBufferSize is finished'}
\endif
      touch
   end

   %%
   meth !ChangeBufferSize(Inc)
\ifdef DEBUG_BO
      {Show 'BrowserClass::ChangeBufferSize is applied'}
\endif
      BrowserClass
      , SetBufferSize({self.Store read(StoreBufferSize $)} + Inc)
   end

   %%
   %%
   meth createNewView
\ifdef DEBUG_BO
      {Show 'BrowserClass::createNewView is applied'}
\endif
      case @selected == InitValue then skip
      else NewBrowser Selection in
         %%
         NewBrowser =
         {New BrowserClass
          init(withMenus:  {self.Store read(StoreWithMenus $)}
               IsView:     true)}       % protected feature;

         %%
         {NewBrowser browse(@selected.term)}
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::createNewView is finished'}
\endif
      touch
   end

   %%
   %%
   meth rebrowse
\ifdef DEBUG_BO
      {Show 'BrowserClass::rebrowse is applied'}
\endif
      case @selected == InitValue then skip
      else Obj in
         Obj = @selected

         %%
         {self.BrowserStream enq(subtermChanged(Obj.ParentObj Obj))}
         BrowserClass , UnsetSelected
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::rebrowse is finished'}
\endif
      touch
   end

   %%
   %% clear method;
   %%
   meth clear
\ifdef DEBUG_BO
      {Show 'BrowserClass::clear is applied'}
\endif
      %%
      case self.IsView then skip
      else CurrentSize in
         CurrentSize = {self.BrowserBuffer getSize($)}

         %%
         BrowserClass , Undraw(CurrentSize)

         %%
         {self.BrowserStream enq(entriesDisable([clear clearAllButLast]))}
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::clear is finished'}
\endif
      touch
   end

   %%
   %%
   meth clearAllButLast
\ifdef DEBUG_BO
      {Show 'BrowserClass::ClearAllButLast is applied'}
\endif
      local CurrentSize in
         %%
         CurrentSize = {self.BrowserBuffer getSize($)}

         %%
         case CurrentSize > 1 then
            BrowserClass , Undraw(CurrentSize - 1)
         else skip
         end

         %%
         {self.BrowserStream enq(entriesDisable([clearAllButLast]))}
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::ClearAllButLast is finished'}
\endif
      touch
   end

   %%
   %% Undraw some terms - forking off an undrawing work if
   %% he term is not selected;
   %% (synchronous method - "in thread");
   %%
   meth Undraw(N)
\ifdef DEBUG_BO
      {Show 'BrowserClass::Undraw is applied'}
\endif
      %%
      case N > 0 andthen {self.BrowserBuffer getSize($)} > 0 then
         RootTermObj Sync ProceedProc DiscardProc
      in
         %%
         proc {ProceedProc}
            %%  fork off an "undraw" job;
            {self.BrowserStream enq(undraw(RootTermObj))}

            %%
            Sync = unit
         end
         %%
         proc {DiscardProc}
            Sync = unit
         end

         %%
         {self.BrowserBuffer deq(RootTermObj ProceedProc DiscardProc)}

         %%
         {Wait Sync}

         %%
         %% becomes empty...
         case {self.BrowserBuffer getSize($)}
         of 0 then {self.BrowserStream
                    enq(entriesDisable([clear clearAllButLast]))}
         [] 1 then {self.BrowserStream
                    enq(entriesDisable([clearAllButLast]))}
         else skip
         end

         %%
         %% Unselect it if it was;
         case {GetRootTermObject @selected} == RootTermObj
         then BrowserClass , UnsetSelected
         else skip
         end

         %%
         BrowserClass , Undraw(N-1)
      else skip
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::Undraw is finished'}
\endif
   end

   %%
   %% Undraw a term when it becomes unselected (if it was at all);
   meth UndrawWait
\ifdef DEBUG_BO
      {Show 'BrowserClass::UndrawWait is applied'}
\endif
      %%
      case {self.BrowserBuffer getSize($)} > 0 then RootTermObj in
         %%
         case
            {self.BrowserBuffer getFirstEl(RootTermObj $)} andthen
            {GetRootTermObject @selected} == RootTermObj
         then {Wait @UnselectSync}
         else skip
         end

         %%
         %% state is free already;
         {self Undraw(1)}
      else {BrowserError 'BrowserClass::UndrawWait: no terms??!'}
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::UndrawWait is finished'}
\endif
   end

   %%
   %%
   meth setParameter(NameOf ValueOf)
\ifdef DEBUG_BO
      {Show 'BrowserClass::setParameter is applied'#NameOf#ValueOf}
\endif
      case NameOf
      of !BrowserXSize                  then
         case {IsInt ValueOf} andthen ValueOf > 1 then
            {self.Store store(StoreXSize ValueOf)}
            {self.BrowserStream enq(resetWindowSize)}
         else {BrowserError 'Illegal value of parameter BrowserXSize'}
         end

      [] !BrowserYSize                  then
         case {IsInt ValueOf} andthen ValueOf > 1 then
            {self.Store store(StoreYSize ValueOf)}
            {self.BrowserStream enq(resetWindowSize)}
         else {BrowserError 'Illegal value of parameter BrowserYSize'}
         end

      [] !BrowserXMinSize               then
         case {IsInt ValueOf} andthen ValueOf > 1 then
            {self.Store store(StoreXMinSize ValueOf)}
         else {BrowserError 'Illegal value of parameter BrowserXMinSize'}
         end

      [] !BrowserYMinSize               then
         case {IsInt ValueOf} andthen ValueOf > 1 then
            {self.Store store(StoreYMinSize ValueOf)}
         else {BrowserError 'Illegal value of parameter BrowserYMinSize'}
         end

       [] !BrowserDepth                  then
         BrowserClass , SetDepth(ValueOf)

      [] !BrowserWidth                  then
         BrowserClass , SetWidth(ValueOf)

      [] !BrowserDepthInc               then
         BrowserClass , SetDInc(ValueOf)

      [] !BrowserWidthInc               then
         BrowserClass , SetWInc(ValueOf)

%      [] !BrowserSmoothScrolling        then
%        case ValueOf of true then
%           {self.Store store(StoreSmoothScrolling true)}
%           {self.BrowserStream enq(setVarValue(smoothScrolling true))}
%        elseof false then
%           {self.Store store(StoreSmoothScrolling false)}
%           {self.BrowserStream enq(setVarValue(smoothScrolling false))}
%        else
%           {BrowserError
%            'Illegal value of parameter BrowserSmoothScrolling'}
%        end

      [] !BrowserShowGraph              then
         case ValueOf of true then
            %%
            {self.Store store(StoreShowGraph true)}
            {self.BrowserStream enq(setVarValue(showGraph true))}
         elseof false then
            %%
            {self.Store store(StoreShowGraph false)}
            {self.BrowserStream enq(setVarValue(showGraph false))}
         else
            {BrowserError
             'Illegal value of parameter BrowserCoreferences'}
         end

      [] !BrowserShowMinGraph           then
         case ValueOf of true then
            %%
            {self.Store store(StoreShowMinGraph true)}
            {self.BrowserStream enq(setVarValue(showMinGraph true))}
         elseof false then
            %%
            {self.Store store(StoreShowMinGraph false)}
            {self.BrowserStream enq(setVarValue(showMinGraph false))}
         else
            {BrowserError 'Illegal value of parameter BrowserCycles'}
         end

      [] !BrowserChunkFields            then
         case ValueOf of true then
            %%
            {self.Store store(StoreArityType TrueArity)}
            {self.BrowserStream enq(setVarValue(arityType TrueArity))}
         elseof false then
            %%
            {self.Store store(StoreArityType AtomicArity)}
            {self.BrowserStream enq(setVarValue(arityType AtomicArity))}
         else
            {BrowserError
             'Illegal value of parameter BrowserPrivateFields'}
         end

      [] !BrowserVirtualStrings         then
         case ValueOf of true then
            %%
            {self.Store store(StoreAreVSs true)}
            {self.BrowserStream enq(setVarValue(areVSs true))}
         elseof false then
            %%
            {self.Store store(StoreAreVSs false)}
            {self.BrowserStream enq(setVarValue(areVSs false))}
         else
            {BrowserError
             'Illegal value of parameter BrowserVirtualStrings'}
         end

      [] !BrowserRecordFieldsAligned    then
         case ValueOf of true then
            %%
            {self.Store store(StoreFillStyle Expanded)}
            {self.BrowserStream enq(setVarValue(fillStyle Expanded))}
         elseof false then
            %%
            {self.Store store(StoreFillStyle Filled)}
            {self.BrowserStream enq(setVarValue(fillStyle Filled))}
         else
            {BrowserError
             'Illegal value of parameter BrowserRecordFieldsAligned'}
         end

      [] !BrowserNamesAndProcsShort     then
         case ValueOf of true then
            %%
            {self.Store store(StoreSmallNames true)}
            {self.BrowserStream enq(setVarValue(smallNams true))}
         elseof false then
            %%
            {self.Store store(StoreSmallNames false)}
            {self.BrowserStream enq(setVarValue(smallNames false))}
         else
            {BrowserError
             'Illegal value of parameter BrowserNamesAndProcsShort'}
         end

      [] !BrowserFont                   then Fonts in
         Fonts = {Filter
                  {Append IKnownMiscFonts IKnownCourFonts}
                  fun {$ F} F.name == ValueOf end}

         %%
         case Fonts
         of [Font] then
            %%
            %%  must leave the object's state!
            thread
               case {self.BrowserStream enq(setTWFont(Font $))}
               then {self.BrowserStream enq(setFont(Font))}
               else {BrowserError 'Illegal value of parameter BrowserFont'}
               end
            end
         else {BrowserError 'Illegal value of parameter BrowserFont'}
         end

      [] !BrowserBufferSize             then
         BrowserClass , SetBufferSize(ValueOf)

      else
         {BrowserError 'Unknown parameter in setParameter'}
      end

      %%
      touch
   end

   %%
   %%
   meth getParameter(NameOf $)
\ifdef DEBUG_BO
      {Show 'BrowserClass::getParameter is applied'#NameOf}
\endif
      case NameOf
      of !BrowserXSize                  then
         {self.Store read(StoreXSize $)}
      [] !BrowserYSize                  then
         {self.Store read(StoreYSize $)}
      [] !BrowserXMinSize               then
         {self.Store read(StoreXMinSize $)}
      [] !BrowserYMinSize               then
         {self.Store read(StoreYMinSize $)}
      [] !BrowserDepth                  then
         {self.Store read(StoreDepth $)}
      [] !BrowserWidth                  then
         {self.Store read(StoreWidth $)}
      [] !BrowserDepthInc               then
         {self.Store read(StoreDepthInc $)}
      [] !BrowserWidthInc               then
         {self.Store read(StoreWidthInc $)}
%      [] !BrowserSmoothScrolling        then
%        {self.Store read(StoreSmoothScrolling $)}
      [] !BrowserShowGraph              then
         {self.Store read(StoreShowGraph $)}
      [] !BrowserShowMinGraph           then
         {self.Store read(StoreShowMinGraph $)}
      [] !BrowserChunkFields            then
         {self.Store read(StoreArityType $)} == TrueArity
      [] !BrowserVirtualStrings         then
         {self.Store read(StoreAreVSs $)}
      [] !BrowserRecordFieldsAligned    then
         {self.Store read(StoreFillStyle $)} == Expanded
      [] !BrowserNamesAndProcsShort     then
         {self.Store read(StoreSmallNames $)}
      [] !BrowserFont                   then
         {self.Store read(StoreTWFont $)}.name
      [] !BrowserBufferSize             then
         {self.Store read(StoreBufferSize $)}
      else
         {BrowserError 'Unknown parameter in setParameter'}
         {NewName}
      end
   end

   %%
   %% SetSelected ('<1>' event for a term);
   %% The 'AreCommas' argument means whether the term that is selected
   %% have been "width"-constrained;
   %%
   meth !SetSelected(Obj AreCommas)
\ifdef DEBUG_BO
      {Show 'BrowserClass::SetSelected is applied'#Obj.term#Obj.type}
\endif
      %%
      BrowserClass , UnsetSelected

      %%
      selected <- Obj
      UnselectSync <- _
      thread {Obj Highlight} end

      %%
      {self.BrowserStream
       enq(entriesEnable([unselect rebrowse showOPI newView zoom]))}

      %%
      case Obj.type of !T_Shrunken then
         {self.BrowserStream [enq(entriesDisable([deref shrink]))
                              enq(entriesEnable([expand]))]}
      elseof !T_Reference then
         {self.BrowserStream [enq(entriesDisable([expand shrink]))
                              enq(entriesEnable([deref]))]}
      elsecase AreCommas then
         {self.BrowserStream [enq(entriesDisable([deref]))
                              enq(entriesEnable([expand shrink]))]}
      else
         {self.BrowserStream [enq(entriesDisable([expand deref]))
                              enq(entriesEnable([shrink]))]}
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::SetSelected is finished'}
\endif
      touch
   end

   %%
   %%
   meth !UnsetSelected
\ifdef DEBUG_BO
      {Show 'BrowserClass::UnsetSelected is applied'}
\endif
      selected <- InitValue
      @UnselectSync = unit

      %%
      {self.BrowserStream
       [enq(unHighlightTerm)
        enq(entriesDisable([unselect rebrowse showOPI newView
                            expand shrink zoom deref]))]}

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::UnsetSelected is finished'}
\endif
      touch
   end

   %%
   %%
   meth !SelExpand
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelExpand is applied'}
\endif
      case @selected == InitValue then skip
      else
         %%
         {self.BrowserStream enq(expand(@selected))}

         %%
         BrowserClass , UnsetSelected
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelExpand is finished'}
\endif
   end

   %%
   %%
   meth !SelShrink
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelShrink is applied'}
\endif
      case @selected == InitValue then skip
      else
         %%
         {self.BrowserStream enq(shrink(@selected))}

         %%
         BrowserClass , UnsetSelected
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelShrink is finished'}
\endif
   end

   %%
   %%
   meth !SelShow
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelShow is applied'}
\endif
      case @selected == InitValue then skip
      else {Show @selected.term}
\ifdef DEBUG_RM
         {@selected debugShow}
\endif
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelShow is finished'}
\endif
   end

   %%
   %% Zoom, i.e. browse a selection as were browsed by the 'Browse';
   %%
   meth !SelZoom
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelZoom is applied'}
\endif
      %%
      case @selected == InitValue then skip
      else BrowserClass , browse(@selected.term)
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelZoom is finished'}
\endif
   end

   %%
   %%
   meth !SelDeref
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelDeref is applied'}
\endif
      case @selected == InitValue then skip
      else
         %%
         {self.BrowserStream enq(deref(@selected))}

         %%
         BrowserClass , UnsetSelected
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelDeref is finished'}
\endif
   end

   %%
   %%
   meth equate(Term)
\ifdef DEBUG_BO
      {Show 'BrowserClass::equate is applied'#Term}
\endif
      %%
      case @selected == InitValue then skip
      else ArityType SelectedTerm in
         ArityType = {self.Store read(StoreArityType $)}

         %%
         case ArityType == AtomicArity then
            SelectedTerm = @selected.term
            %%
            try SelectedTerm = Term
            catch failure(...) then
               {Show '**************************************************'}
               {Show 'Failure occured while Browse.equate.'}
               {Show '... was trying to equate '#Term#' and '#SelectedTerm}
               {Show '**************************************************'}
            end
         else
            {BrowserWarning 'May not equate: the private fields are shown!'}
         end
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::equate is finished'}
\endif
      touch
   end

   %%
   meth !Help
\ifdef DEBUG_BO
      {Show 'BrowserClass::Help is applied'}
\endif
      %%
      local HF Desc HelpWindow in
         HF = {New Open.file init(name: IHelpFile flags: [read])}

         %%
         Desc = {HF [read(list: $ size: all) close]}

         %%
         HelpWindow =
         {New HelpWindowClass
          createHelpWindow(screen: {self.Store read(StoreScreen $)})}

         %%
         case {VirtualString.is Desc} then
            {HelpWindow showIn(Desc)}
         else
            {BrowserError 'Non-virtual-string is read from a help.txt file?'}
         end
      end

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::Help is finished'}
\endif
      touch
   end

   %%
   meth !SetDepth(Depth)
      case {IsInt Depth} andthen Depth > 0 then
         {self.Store store(StoreDepth Depth)}
         BrowserClass , UpdateSizes
      else {BrowserError 'Illegal value of parameter BrowserDepth'}
      end
   end

   %%
   meth !ChangeDepth(Inc)
      BrowserClass , SetDepth({self.Store read(StoreDepth $)} + Inc)
   end

   %%
   meth !SetWidth(Width)
      case {IsInt Width} andthen Width > 1 then
         {self.Store store(StoreWidth Width)}
         BrowserClass , UpdateSizes
      else {BrowserError 'Illegal value of parameter BrowserWidth'}
      end
   end

   %%
   meth !ChangeWidth(Inc)
      BrowserClass , SetWidth({self.Store read(StoreWidth $)} + Inc)
   end

   %%
   meth !SetDInc(DI)
      case {IsInt DI} andthen DI > 0 then
         {self.Store store(StoreDepthInc DI)}
      else {BrowserError 'Illegal value of parameter BrowserDepthInc'}
      end
   end

   %%
   meth !ChangeDInc(Inc)
      BrowserClass , SetDInc({self.Store read(StoreDepthInc $)} + Inc)
   end

   %%
   meth !SetWInc(WI)
      case {IsInt WI} andthen WI > 0 then
         {self.Store store(StoreWidthInc WI)}
      else {BrowserError 'Illegal value of parameter BrowserWidthInc'}
      end
   end

   %%
   meth !ChangeWInc(Inc)
      BrowserClass , SetWInc({self.Store read(StoreWidthInc $)} + Inc)
   end

   %%
   %% Updates (increases) depth&width of terms actually shown;
   meth !UpdateSizes
\ifdef DEBUG_BO
      {Show 'BrowserClass::UpdateSizes is applied'}
\endif
      %%
      {ForAll {self.BrowserBuffer getContent($)}
       proc {$ RootTermObj}
          {self.BrowserStream enq(updateSize(RootTermObj))}
       end}

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::UpdateSizes is finished'}
\endif
      touch
   end

   %%
   %% Check the layout;
   meth checkLayout
\ifdef DEBUG_BO
      {Show 'BrowserClass::checkLayt is applied'}
\endif
      local CLProc in
         %%
         proc {CLProc RootTermObj}
            {self.BrowserStream enq(checkLayoutReq(RootTermObj))}
         end

         %%
         {ForAll {self.BrowserBuffer getContent($)} CLProc}
      end
\ifdef DEBUG_BO
      {Show 'BrowserClass::checkLayt is finished'}
\endif
   end

   %%
   %% In fact, this is the 'ConfigureNotify' (X11 event) handler;
   %% It's here 'cause browser buffer's content is necessary;
   %%
   meth !SetTWWidth(Width)
\ifdef DEBUG_BO
      {Show 'BrowserClass::SetTWWidth is applied'}
      thread {Wait Width} {Show '... Width = '#Width} end
\endif
      %%
      {Wait Width}
      {self.Store store(StoreTWWidth Width)}

      %%
      self , checkLayout

      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::SetTWWidth is finished'}
\endif
      touch
   end

   %%
end
