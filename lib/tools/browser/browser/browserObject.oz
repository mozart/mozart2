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
class BrowserClass
   from Object.base
   prop locking
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
      ContinueSync: unit        %

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
      lock
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
           store(StoreAreSeparators ISeparators)
           store(StoreRepMode IRepMode)
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
      end
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
      lock
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
      end
   end

   %%
   %%  ... and close the window;
   meth closeWindow
\ifdef DEBUG_BO
      {Show 'BrowserClass::closeWindow is applied'}
\endif
      lock
         %%
         BrowserClass , Reset
         {self.BrowserStream enq(closeWindow)}

         %%
\ifdef DEBUG_BO
         {Show 'BrowserClass::closeWindow is finished'}
\endif
      end
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
   end

   %%
   meth close
\ifdef DEBUG_BO
      {Show 'BrowserClass::close is applied'}
\endif
      %%
      lock
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
         %% That's not my problem if somebody will send messages here ;-)
         % Object.closable , close
\ifdef DEBUG_BO
         {Show 'BrowserClass::close is finished'}
\endif
      end
   end

   %%
   meth createWindow
\ifdef DEBUG_BO
      {Show 'BrowserClass::createWindow is applied'}
\endif
      %%
      lock
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
      end
   end

   %%
   meth createMenus
\ifdef DEBUG_BO
      {Show 'BrowserClass::createMenus is applied'}
\endif
      %%
      lock
         case {self.Store read(StoreAreMenus $)} then skip
         else
            {self.BrowserStream
             [enq(createMenus)
              enq(entriesDisable([unselect continue pause break rebrowse
                                  process newView clear clearAllButLast
                                  expand shrink zoom deref]))]}
         end

         %%
\ifdef DEBUG_BO
         {Show 'BrowserClass::createMenus is finished'}
\endif
      end
   end

   %%
   meth toggleMenus
\ifdef DEBUG_BO
      {Show 'BrowserClass::toggleMenus is applied'}
\endif
      %%
      lock
         BrowserClass ,
         case {self.Store read(StoreAreMenus $)} then closeMenus
         else createMenus
         end
\ifdef DEBUG_BO
         {Show 'BrowserClass::toggleMenus is finished'}
\endif
      end
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
   end

   %%
   meth !ScrollTo(Obj Kind)
\ifdef DEBUG_BO
      {Show 'BrowserClass::ScrollTo is applied'}
\endif
      %%
      lock
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
\ifdef DEBUG_BO
            {Show 'BrowserClass::ScrollTo is finished'}
\endif
         end
      end
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
         lock
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
               {self.BrowserStream [enq(entriesEnable([pause]))]}
               thread
                  {self UndrawWait}
               end
            else skip           % just put a new one;
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
\ifdef DEBUG_BO
         {Show 'BrowserClass::browse is finished'}
\endif
         end

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
      lock
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
      end
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
      %%
      lock
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
      end
   end

   %%
   %%
   meth rebrowse
\ifdef DEBUG_BO
      {Show 'BrowserClass::rebrowse is applied'}
\endif
      %%
      lock
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
      end
   end

   %%
   %% clear method;
   %%
   meth clear
\ifdef DEBUG_BO
      {Show 'BrowserClass::clear is applied'}
\endif
      %%
      lock
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
      end
   end

   %%
   %%
   meth clearAllButLast
\ifdef DEBUG_BO
      {Show 'BrowserClass::ClearAllButLast is applied'}
\endif
      lock
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

            %%
\ifdef DEBUG_BO
            {Show 'BrowserClass::ClearAllButLast is finished'}
\endif
         end
      end
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

         lock
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
         end
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
      lock
         case {self.BrowserBuffer getSize($)} > 0 then RootTermObj in
            %%
            {Wait @ContinueSync}

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
   end

   %%
   %%
   meth setParameter(name:NameOf value:ValueOf)
\ifdef DEBUG_BO
      {Show 'BrowserClass::setParameter is applied'#NameOf#ValueOf}
\endif
      lock
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
            BrowserClass , UpdateSizes

         [] !BrowserWidth                  then
            BrowserClass , SetWidth(ValueOf)
            BrowserClass , UpdateSizes

         [] !BrowserDepthInc               then
            BrowserClass , SetDInc(ValueOf)

         [] !BrowserWidthInc               then
            BrowserClass , SetWInc(ValueOf)

         [] !BrowserRepMode                then
            {self.Store store(StoreRepMode
                              case ValueOf
                              of tree     then TreeRep
                              [] grapth   then GraphRep
                              [] minGraph then MinGraphRep
                              else
                                 {BrowserError
                                  'Illegal value of parameter BrowserCoreferences'}
                                 {self.Store read(StoreRepMode $)}
                              end)}

         [] !BrowserChunkFields            then
            case ValueOf of true then
               %%
               {self.Store store(StoreArityType TrueArity)}
            elseof false then
               %%
               {self.Store store(StoreArityType AtomicArity)}
            else
               {BrowserError
                'Illegal value of parameter BrowserPrivateFields'}
            end

         [] !BrowserVirtualStrings         then
            case ValueOf of true then
               %%
               {self.Store store(StoreAreVSs true)}
            elseof false then
               %%
               {self.Store store(StoreAreVSs false)}
            else
               {BrowserError
                'Illegal value of parameter BrowserVirtualStrings'}
            end

         [] !BrowserRecordFieldsAligned    then
            case ValueOf of true then
               %%
               {self.Store store(StoreFillStyle Expanded)}
            elseof false then
               %%
               {self.Store store(StoreFillStyle Filled)}
            else
               {BrowserError
                'Illegal value of parameter BrowserRecordFieldsAligned'}
            end

         [] !BrowserNamesAndProcsShort     then
            case ValueOf of true then
               %%
               {self.Store store(StoreSmallNames true)}
            elseof false then
               %%
               {self.Store store(StoreSmallNames false)}
            else
               {BrowserError
                'Illegal value of parameter BrowserNamesAndProcsShort'}
            end

         [] !BrowserFont                   then Fonts in
            Fonts = {Filter IKnownCourFonts
                     fun {$ F} font(size:F.size wght:F.wght) == ValueOf end}

            %%
            case Fonts
            of [Font] then
               %%
               %%  must leave the object's state!
               thread
                  case {self.BrowserStream enq(setTWFont(Font $))}
                  then skip
                  else {BrowserError
                        'Illegal value of parameter BrowserFont'}
                  end
               end
            else {BrowserError 'Illegal value of parameter BrowserFont'}
            end

         [] !BrowserBufferSize             then
            BrowserClass , SetBufferSize(ValueOf)

         [] !BrowserSeparators             then
            case ValueOf of true then
               %%
               {self.Store store(StoreAreSeparators true)}
            elseof false then
               %%
               {self.Store store(StoreAreSeparators false)}
            else
               {BrowserError
                'Illegal value of parameter BrowserSeparators'}
            end

         else
            {BrowserError 'Unknown parameter in setParameter'}
         end

         %%
      end
   end

   %%
   %%
   meth getParameter(name:NameOf value:$)
\ifdef DEBUG_BO
      {Show 'BrowserClass::getParameter is applied'#NameOf}
\endif
      %%
      lock
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
         [] !BrowserRepMode                then
            case {self.Store read(StoreRepMode $)}
            of !TreeRep     then tree
            [] !GraphRep    then grapth
            [] !MinGraphRep then minGraph
            else
               {BrowserError 'Unknown representation type!'}
               {NewName}
            end
         [] !BrowserChunkFields            then
            {self.Store read(StoreArityType $)} == TrueArity
         [] !BrowserVirtualStrings         then
            {self.Store read(StoreAreVSs $)}
         [] !BrowserRecordFieldsAligned    then
            {self.Store read(StoreFillStyle $)} == Expanded
         [] !BrowserNamesAndProcsShort     then
            {self.Store read(StoreSmallNames $)}
         [] !BrowserFont                   then
            F = {self.Store read(StoreTWFont $)}
         in
            font(size:F.size wght:F.wght)
         [] !BrowserBufferSize             then
            {self.Store read(StoreBufferSize $)}
         [] !BrowserSeparators             then
            {self.Store read(StoreAreSeparators $)}
         else
            {BrowserError 'Unknown parameter in getParameter'}
            {NewName}
         end
      end
   end

   %%
   %%
   meth addProcessAction(action:Action label:Label)
\ifdef DEBUG_BO
      {Show 'BrowserClass::addProcessAction is applied'}
\endif
      {self.BrowserStream enq(addAction(Action Label))}
\ifdef DEBUG_BO
      {Show 'BrowserClass::addProcessAction is finished'}
\endif
   end

   %%
   %%
   meth setProcessAction(action:Action)
\ifdef DEBUG_BO
      {Show 'BrowserClass::setProcessAction is applied'}
\endif
      {self.BrowserStream enq(setAction(Action))}
\ifdef DEBUG_BO
      {Show 'BrowserClass::setProcessAction is finished'}
\endif
   end

   %%
   %%  Acepts 'all' as a special keyword;
   meth removeProcessAction(action:Action)
\ifdef DEBUG_BO
      {Show 'BrowserClass::removeProcessAction is applied'}
\endif
      {self.BrowserStream enq(removeAction(Action))}
\ifdef DEBUG_BO
      {Show 'BrowserClass::removeProcessAction is finished'}
\endif
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
      lock
         BrowserClass , UnsetSelected

         %%
         selected <- Obj
         thread {Obj Highlight} end

         %%
         {self.BrowserStream
          enq(entriesEnable([unselect rebrowse process newView zoom]))}

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
      end
   end

   %%
   %%
   meth !UnsetSelected
\ifdef DEBUG_BO
      {Show 'BrowserClass::UnsetSelected is applied'}
\endif
      lock
         selected <- InitValue

         %%
         {self.BrowserStream
          [enq(unHighlightTerm)
           enq(entriesDisable([unselect rebrowse process newView
                               expand shrink zoom deref]))]}

         %%
\ifdef DEBUG_BO
         {Show 'BrowserClass::UnsetSelected is finished'}
\endif
      end
   end

   %%
   meth !Pause
      ContinueSync <- _
      {self.BrowserStream
       [enq(entriesDisable([pause])) enq(entriesEnable([continue]))]}
   end
   meth !Continue
      @ContinueSync = unit
      {self.BrowserStream enq(entriesDisable([continue]))}
   end

   %%
   %%
   meth !SelExpand
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelExpand is applied'}
\endif
      %%
      lock
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
   end

   %%
   %%
   meth !SelShrink
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelShrink is applied'}
\endif
      %%
      lock
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
   end

   %%
   %%
   meth !Process
\ifdef DEBUG_BO
      {Show 'BrowserClass::Process is applied'}
\endif
      %%
      lock
         case @selected == InitValue then skip
         else
            Action = {self.Store read(StoreProcessAction $)}
            proc {CrashProc E T D}
               {Show '*********************************************'}
               {Show 'Exception occured in ProcessAction:'#E}
               {Show 'ProcessAction was '#Action}
            end
         in
            %%
            try {Action @selected.term}
            catch failure(debug:D) then {CrashProc failure unit D}
            [] error(T debug:D) then {CrashProc error T D}
            [] system(T debug:D) then {CrashProc system T D}
            end
\ifdef DEBUG_RM
            {@selected debugShow}
\endif
         end

         %%
\ifdef DEBUG_BO
         {Show 'BrowserClass::Process is finished'}
\endif
      end
   end

   %%
   %% Zoom, i.e. browse a selection as were browsed by the 'Browse';
   %%
   meth !SelZoom
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelZoom is applied'}
\endif
      %%
      lock
         case @selected == InitValue then skip
         else BrowserClass , browse(@selected.term)
         end

         %%
\ifdef DEBUG_BO
         {Show 'BrowserClass::SelZoom is finished'}
\endif
      end
   end

   %%
   %%
   meth !SelDeref
\ifdef DEBUG_BO
      {Show 'BrowserClass::SelDeref is applied'}
\endif
      %%
      lock
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
   end

   %%
   %%
   meth equate(Term)
\ifdef DEBUG_BO
      {Show 'BrowserClass::equate is applied'#Term}
\endif
      %%
      lock
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
                  {Show
                   '... was trying to equate '#Term#' and '#SelectedTerm}
                  {Show '**************************************************'}
               end
            else
               {BrowserWarning
                'May not equate: the private fields are shown!'}
            end
         end

         %%
\ifdef DEBUG_BO
         {Show 'BrowserClass::equate is finished'}
\endif
      end
   end

   %%
   meth !About
\ifdef DEBUG_BO
      {Show 'BrowserClass::About is applied'}
\endif
      %%
      {self.BrowserStream enq(makeAbout)}
      %%
\ifdef DEBUG_BO
      {Show 'BrowserClass::About is finished'}
\endif
   end

   %%
   meth !SetDepth(Depth)
      lock
         case {IsInt Depth} andthen Depth > 0 then
            {self.Store store(StoreDepth Depth)}
         else {BrowserError 'Illegal value of parameter BrowserDepth'}
         end
      end
   end

   %%
   meth !ChangeDepth(Inc)
      lock
         BrowserClass , SetDepth({self.Store read(StoreDepth $)} + Inc)
         BrowserClass , UpdateSizes
      end
   end

   %%
   meth !SetWidth(Width)
      lock
         case {IsInt Width} andthen Width > 1 then
            {self.Store store(StoreWidth Width)}
         else {BrowserError 'Illegal value of parameter BrowserWidth'}
         end
      end
   end

   %%
   meth !ChangeWidth(Inc)
      lock
         BrowserClass , SetWidth({self.Store read(StoreWidth $)} + Inc)
         BrowserClass , UpdateSizes
      end
   end

   %%
   meth !SetDInc(DI)
      lock
         case {IsInt DI} andthen DI > 0 then
            {self.Store store(StoreDepthInc DI)}
         else {BrowserError 'Illegal value of parameter BrowserDepthInc'}
         end
      end
   end

   %%
   meth !ChangeDInc(Inc)
      lock
         BrowserClass , SetDInc({self.Store read(StoreDepthInc $)} + Inc)
      end
   end

   %%
   meth !SetWInc(WI)
      lock
         case {IsInt WI} andthen WI > 0 then
            {self.Store store(StoreWidthInc WI)}
         else {BrowserError 'Illegal value of parameter BrowserWidthInc'}
         end
      end
   end

   %%
   meth !ChangeWInc(Inc)
      lock
         BrowserClass , SetWInc({self.Store read(StoreWidthInc $)} + Inc)
      end
   end

   %%
   %% Updates (increases) depth&width of terms actually shown;
   meth !UpdateSizes
\ifdef DEBUG_BO
      {Show 'BrowserClass::UpdateSizes is applied'}
\endif
      %%
      lock
         {ForAll {self.BrowserBuffer getContent($)}
          proc {$ RootTermObj}
             {self.BrowserStream enq(updateSize(RootTermObj))}
          end}

         %%
\ifdef DEBUG_BO
         {Show 'BrowserClass::UpdateSizes is finished'}
\endif
      end
   end

   %%
   %% Check the layout;
   meth checkLayout
\ifdef DEBUG_BO
      {Show 'BrowserClass::checkLayt is applied'}
\endif
      lock
         local CLProc in
            %%
            proc {CLProc RootTermObj}
               {self.BrowserStream enq(checkLayoutReq(RootTermObj))}
            end

            %%
            {ForAll {self.BrowserBuffer getContent($)} CLProc}
\ifdef DEBUG_BO
            {Show 'BrowserClass::checkLayt is finished'}
\endif
         end
      end
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
      lock
         {self.Store store(StoreTWWidth Width)}

         %%
         {self  checkLayout}

         %%
\ifdef DEBUG_BO
         {Show 'BrowserClass::SetTWWidth is finished'}
\endif
      end
   end

   %%
end
