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
%%%   FBrowserClass - this is class which is given to users and which
%%%  instance is used for the default Oz browser;
%%%
%%%
%%%

%%%
%%%
%%% FBrowserClass;
%%%
%%% Non-local methods which are denoted by names are used primarily
%%% as event handlers in window manager (aka e.g. 'Help');
%%%
%%%
class FBrowserClass
   from MyClosableObject
   prop locking
   feat
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

   %%
   %%
   %%
   meth init(origWindow:       OrigWindow         <= InitValue
             screen:           Screen             <= InitValue)
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::init is applied'}
\endif
      lock
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
           store(StoreExpVarNames IExpVarNames)
           store(StoreAreStrings IAreStrings)
           store(StoreAreVSs IAreVSs)
           store(StoreDepthInc IDepthInc)
           store(StoreWidthInc IWidthInc)
           store(StoreAreSeparators ISeparators)
           store(StoreRepMode IRepMode)
           store(StoreTWFont ITWFont1)           % first approximation;
           store(StoreBufferSize IBufferSize)
           store(StoreWithMenus true)            % hardwired;
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
         local Stream in
            %%
            %% only 'getContent' functionality is delegated to the
            %% manager object. A list of term objects is necessary in
            %% order to perform 'check layout' step when idle;
            self.GetTermObjs = fun {$} {self.BrowserBuffer getContent($)} end

            %%
            Stream = self.BrowserStream = {New BrowserStreamClass init}

            %%
            _ =
            {New BrowserManagerClass init(store:          self.Store
                                          getTermObjsFun: self.GetTermObjs)}
         end

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::init is finished'}
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
      {System.show 'FBrowserClass::break is applied'}
\endif
      %%
      {self.Store store(StoreBreak true)}
   end

   %%
   %% Break + purge unprocessed suspensions + undraw everything;
   meth clear
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::clear is applied'}
\endif
      lock
         %%
         FBrowserClass , break

         %%
         FBrowserClass , UnsetSelected

         %% everything pending is cancelled;
         {self.BrowserBuffer purgeSusps}

         %%  'FBrowserClass::Undraw' is an "in-thread" method;
         FBrowserClass , Undraw({self.BrowserBuffer getSize($)})

         %%
         {Wait {self.BrowserStream enq(sync($))}}

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::clear is finished'}
\endif
      end
   end

   %%
   %%  ... and close the window;
   meth closeWindow
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::closeWindow is applied'}
\endif
      lock
         %%
         FBrowserClass , clear
         if {self.Store read(StoreOrigWindow $)} == InitValue
         then {self.BrowserStream enq(closeWindow)}
         end

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::closeWindow is finished'}
\endif
      end
   end

   %%
   meth closeMenus
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::closeMenus is applied'}
\endif
      %%
      {self.BrowserStream enq(closeMenus)}

      %%
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::closeMenus is finished'}
\endif
   end

   %%
   meth close
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::close is applied'}
\endif
      %%
      lock
         FBrowserClass , break

         %%
         {self.BrowserBuffer purgeSusps}

         %%
         {Wait {self.BrowserStream [enq(sync($)) enq(close)]}}

         %%
         {self.BrowserStream close}
         {self.BrowserBuffer close}
         {self.Store close}

         %%
         %% simply throw away everything else;
         %% That's not my problem if somebody will send messages here ;-)
         MyClosableObject , close
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::close is finished'}
\endif
      end
   end

   %%
   meth createWindow
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::createWindow is applied'}
\endif
      %%
      lock
         if {self.Store read(StoreIsWindow $)} then skip
         else
            {self.BrowserStream enq(createWindow)}

            %%
            if {self.Store read(StoreWithMenus $)} then
               FBrowserClass , createMenus
            end
         end

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::createWindow is finished'}
\endif
      end
   end

   %%
   meth createMenus
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::createMenus is applied'}
\endif
      %%
      lock
         if {self.Store read(StoreAreMenus $)} then skip
         else
            {self.BrowserStream
             [enq(createMenus)
              enq(entriesDisable([%%
                                  unselect break rebrowse
                                  process clear clearAllButLast
                                  refineLayout expand shrink deref]))
              enq(entriesEnable([%%
                                 break
                                 %% should be on since that's a
                                 %% request itself;
                                 if {self.BrowserBuffer getSize($)} > 0
                                 then clear else InitValue
                                 end
                                 if {self.BrowserBuffer getSize($)} > 1
                                 then clearAllButLast else InitValue
                                 end
                                 if {self.BrowserBuffer getSize($)} > 0
                                 then refineLayout else InitValue
                                 end]))]}
         end

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::createMenus is finished'}
\endif
      end
   end

   %%
   meth toggleMenus
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::toggleMenus is applied'}
\endif
      %%
      lock
         FBrowserClass ,
         if {self.Store read(StoreAreMenus $)} then closeMenus
         else createMenus
         end
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::toggleMenus is finished'}
\endif
      end
   end

   %%
   meth focusIn
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::focusIn is applied'}
\endif
      {self.BrowserStream enq(focusIn)}

      %%
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::focusIn is finished'}
\endif
   end

   %%
   meth !ScrollTo(Obj Kind)
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::ScrollTo is applied'}
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
            {System.show 'FBrowserClass::ScrollTo is finished'}
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
      {System.show 'FBrowserClass::browse is applied'#Term}
\endif
      local RootTermObj Sync ProceedProc DiscardProc in
         lock
            %%
            FBrowserClass , createWindow    % check it;

            %%
            if
               {self.BrowserBuffer getSize($)} >=
               {self.Store read(StoreBufferSize $)}
            then
               %% Startup a thread which eventually cleans up some place
               %% in the buffer;
               thread
                  {self UndrawWait}
               end
            else skip           % just put a new one;
            end

            %%
            proc {ProceedProc}
               %%  spawns drawing work;
               {self.BrowserStream [enq(browse(Term RootTermObj))
                                    enq(entriesEnable([clear refineLayout]))]}

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
            if {self.BrowserBuffer getSize($)} > 1 then
               {self.BrowserStream
                enq(entriesEnable([clearAllButLast refineLayout]))}
            end

            %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::browse is finished'}
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
      {System.show 'FBrowserClass::SetBufferSize is applied'}
\endif
      %%
      lock
         if {IsInt NewSize} andthen NewSize > 0 then CurrentSize in
            {self.Store store(StoreBufferSize NewSize)}
            CurrentSize = {self.BrowserBuffer getSize($)}

            %%
            {self.BrowserBuffer resize(NewSize)}

            %%
            if NewSize < CurrentSize then
               %%
               FBrowserClass , Undraw(CurrentSize - NewSize)
            end
         else {BrowserError 'Illegal size of the browser buffer'}
         end

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::SetBufferSize is finished'}
\endif
      end
   end

   %%
   meth !ChangeBufferSize(Inc)
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::ChangeBufferSize is applied'}
\endif
      FBrowserClass
      , SetBufferSize({self.Store read(StoreBufferSize $)} + Inc)
   end

   %%
   %%
   meth rebrowse
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::rebrowse is applied'}
\endif
      %%
      lock
         if @selected \= InitValue then Obj in
            Obj = @selected

            %%
            {self.BrowserStream enq(subtermChanged(Obj.ParentObj Obj))}
            FBrowserClass , UnsetSelected
         end

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::rebrowse is finished'}
\endif
      end
   end

   %%
   %%
   meth clearAllButLast
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::ClearAllButLast is applied'}
\endif
      lock
         local CurrentSize in
            %%
            CurrentSize = {self.BrowserBuffer getSize($)}

            %%
            if CurrentSize > 1 then
               FBrowserClass , Undraw(CurrentSize - 1)
            end

            %%
            {self.BrowserStream enq(entriesDisable([clearAllButLast]))}

            %%
\ifdef DEBUG_BO
            {System.show 'FBrowserClass::ClearAllButLast is finished'}
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
      {System.show 'FBrowserClass::Undraw is applied'}
\endif
      %%
      if N > 0 andthen {self.BrowserBuffer getSize($)} > 0 then
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
                       enq(entriesDisable([clear clearAllButLast
                                           refineLayout]))}
            [] 1 then {self.BrowserStream
                       enq(entriesDisable([clearAllButLast]))}
            else skip
            end

            %%
            %% Unselect it if it was;
            if {GetRootTermObject @selected} == RootTermObj
            then FBrowserClass , UnsetSelected
            end

            %%
            FBrowserClass , Undraw(N-1)
         end
      end

      %%
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::Undraw is finished'}
\endif
   end

   %%
   %% Undraw a term when it becomes unselected (if it was at all);
   meth UndrawWait
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::UndrawWait is applied'}
\endif
      %%
      lock
         if {self.BrowserBuffer getSize($)} > 0 then
            %%
            %% state is free already;
            {self Undraw(1)}
         else
            %% No errors since it could happen when e.g. user issues
            %% "clear" and new browse requests, so that "clear" has
            %% not become processed before browse requests;
            skip
         end

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::UndrawWait is finished'}
\endif
      end
   end

   %%
   %%
   meth option(...)=M
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::option is applied'#M}
\endif
      %%
      case M.1
      of !SpecialON                        then
         %%
         %% These are options that are not accessible through
         %% menus;
         {ForAll {Filter {Arity M} fun {$ F} F \= 1 end}
          proc {$ F}
             case F
             of !BrowserXSize                  then
                if {IsInt M.F} andthen M.F > 1 then
                   {self.Store store(StoreXSize M.F)}
                   {self.BrowserStream enq(resetWindowSize)}
                else {BrowserError 'Illegal value for browser\'s "xSize"'}
                end

             [] !BrowserYSize                  then
                if {IsInt M.F} andthen M.F > 1 then
                   {self.Store store(StoreYSize M.F)}
                   {self.BrowserStream enq(resetWindowSize)}
                else
                   {BrowserError 'Illegal value for browser\'s "ySize"'}
                end

             [] !BrowserXMinSize               then
                if {IsInt M.F} andthen M.F >= IXMinSize then
                   {self.Store store(StoreXMinSize M.F)}
                   {self.BrowserStream enq(resetWindowSize)}
                else {BrowserError
                      'Illegal value for browser\'s "xMinSize"'}
                end

             [] !BrowserYMinSize               then
                if {IsInt M.F} andthen M.F >= IYMinSize then
                   {self.Store store(StoreYMinSize M.F)}
                   {self.BrowserStream enq(resetWindowSize)}
                else {BrowserError
                      'Illegal value for browser\'s "yMinSize"'}
                end

             else
                {BrowserError 'Unknown "special" option: ' #
                 {String.toAtom {Value.toVirtualString F 0 0}}}
             end
          end}

         %%
      [] !BufferON                         then
         %%
         {ForAll {Filter {Arity M} fun {$ F} F \= 1 end}
          proc {$ F}
             case F
             of !BrowserBufferSize             then
                {self SetBufferSize(M.F)}

             [] !BrowserSeparators             then
                case M.F of true then
                   %%
                   {self.Store store(StoreAreSeparators true)}
                elseof false then
                   %%
                   {self.Store store(StoreAreSeparators false)}
                else {BrowserError
                      'Illegal value of browser\'s "separators" option'}
                end

             else {BrowserError 'Unknown "buffer" option: ' #
                   {String.toAtom {Value.toVirtualString F 0 0}}}
             end
          end}

      [] !RepresentationON                 then
         %%
         {ForAll {Filter {Arity M} fun {$ F} F \= 1 end}
          proc {$ F}
             case F
             of !BrowserRepMode                then
                {self.Store
                 store(StoreRepMode
                       case M.F
                       of tree     then TreeRep
                       [] graph    then GraphRep
                       [] minGraph then MinGraphRep
                       else
                          {BrowserError
                           'Illegal value of browser\'s (representation) mode'}
                          {self.Store read(StoreRepMode $)}
                       end)}

             [] !BrowserChunkFields            then
                case M.F of true then
                   %%
                   {self.Store store(StoreArityType TrueArity)}
                elseof false then
                   %%
                   {self.Store store(StoreArityType NoArity)}
                else
                   {BrowserError
                    'Illegal value of browser\'s "privateChunkFields" option'}
                end

             [] !BrowserNamesAndProcs          then
                case M.F of false then
                   %%
                   {self.Store store(StoreSmallNames true)}
                elseof true then
                   %%
                   {self.Store store(StoreSmallNames false)}
                else
                   {BrowserError
                    'Illegal value of parameter browser\'s "detailedNamesAndProcedurs" option'}
                end

             [] !BrowserExpVarNames            then
                case M.F of true then
                   %%
                   {self.Store store(StoreExpVarNames true)}
                elseof false then
                   %%
                   {self.Store store(StoreExpVarNames false)}
                else
                   {BrowserError
                    'Illegal value of parameter browser\'s "detailedVarStatus" option'}
                end

             [] !BrowserStrings                then
                case M.F of true then
                   %%
                   {self.Store store(StoreAreStrings true)}
                elseof false then
                   %%
                   {self.Store store(StoreAreStrings false)}
                else
                   {BrowserError
                    'Illegal value of parameter BrowserStrings'}
                end

             [] !BrowserVirtualStrings         then
                case M.F of true then
                   %%
                   {self.Store store(StoreAreVSs true)}
                elseof false then
                   %%
                   {self.Store store(StoreAreVSs false)}
                else
                   {BrowserError
                    'Illegal value of parameter BrowserVirtualStrings'}
                end

             else {BrowserError 'Unknown "representation" option: ' #
                   {String.toAtom {Value.toVirtualString F 0 0}}}
             end
          end}

      [] !DisplayON                        then
         %%
         {ForAll {Filter {Arity M} fun {$ F} F \= 1 end}
          proc {$ F}
             case F
             of !BrowserDepth                  then
                {self SetDepth(M.F)}
                {self UpdateSizes}

             [] !BrowserWidth                  then
                {self SetWidth(M.F)}
                {self UpdateSizes}

             [] !BrowserDepthInc               then
                {self SetDInc(M.F)}

             [] !BrowserWidthInc               then
                {self SetWInc(M.F)}

             else {BrowserError 'Unknown "display parameters" option: ' #
                   {String.toAtom {Value.toVirtualString F 0 0}}}
             end
          end}

      [] !LayoutON                         then
         %%
         {ForAll {Filter {Arity M} fun {$ F} F \= 1 end}
          proc {$ F}
             case F
             of !BrowserFontSize               then StoredFN Fonts in
                StoredFN = {self.Store read(StoreTWFont $)}
                Fonts = {Filter IKnownCourFonts
                         fun {$ Font}
                            Font.size == M.F andthen
                            Font.wght == StoredFN.wght
                         end}

                %%
                case Fonts
                of [Font] then
                   %%
                   %%  must leave the object's state!
                   if {self.BrowserStream enq(setTWFont(Font $))}
                   then skip
                   else {BrowserError
                         'Illegal value of browser\'s "fontSize" option'}
                   end
                else {BrowserError
                      'Illegal value of browser\'s "fontSize" option'}
                end

             [] !BrowserBold                   then StoredFN Wght Fonts in
                StoredFN = {self.Store read(StoreTWFont $)}
                Wght = if M.F then bold else medium end
                Fonts = {Filter IKnownCourFonts
                         fun {$ F}
                            F.wght == Wght andthen
                            F.size == StoredFN.size
                         end}

                %%
                case Fonts
                of [Font] then
                   %%
                   if {self.BrowserStream enq(setTWFont(Font $))}
                   then skip
                   else {BrowserError
                         'Illegal value of browser\'s "fontSize" option'}
                   end
                else {BrowserError
                      'Illegal value of browser\'s "fontSize" option'}
                end

             [] !BrowserRecordFieldsAligned    then
                case M.F of true then
                   %%
                   {self.Store store(StoreFillStyle Expanded)}
                elseof false then
                   %%
                   {self.Store store(StoreFillStyle Filled)}
                else
                   {BrowserError
                    'Illegal value of browser\'s "allignRecordFields" option'}
                end

             else {BrowserError 'Unknown "layout" option: ' #
                   {String.toAtom {Value.toVirtualString F 0 0}}}
             end
          end}

      else {BrowserError 'Unknown option group: ' #
            {String.toAtom {Value.toVirtualString M.1 0 0}}}
      end

      %%
   end

   %%
   meth saveOptions($)
\ifdef DEBUG_BO
      {System.show 'FBrowserClass:: getOptions is applied'}
      {self.Store read( $)}
\endif
      [option(SpecialON BrowserXSize:{self.Store read(StoreXSize $)})
       option(SpecialON BrowserYSize:{self.Store read(StoreYSize $)})
       option(SpecialON BrowserXMinSize:{self.Store read(StoreXMinSize $)})
       option(SpecialON BrowserYMinSize:{self.Store read(StoreYMinSize $)})
       option(BufferON BrowserBufferSize:
          {self.Store read(StoreBufferSize $)} )
       option(BufferON BrowserSeparators:
          {self.Store read(StoreAreSeparators $)})
       option(RepresentationON BrowserRepMode:
          case {self.Store read(StoreRepMode $)}
          of !TreeRep then tree
          [] !GraphRep then graph
          [] !MinGraphRep then minGraph
          else
             {BrowserError
              'Illegal value of browser\'s (representation) mode'}
             unit
          end)
       option(RepresentationON BrowserChunkFields:
          {self.Store read(StoreArityType $)} == TrueArity)
       option(RepresentationON BrowserNamesAndProcs:
          {self.Store read(StoreSmallNames $)} == false)
       option(RepresentationON BrowserExpVarNames:
          {self.Store read(StoreExpVarNames $)})
       option(RepresentationON BrowserStrings:
          {self.Store read(StoreAreStrings $)})
       option(RepresentationON BrowserVirtualStrings:
          {self.Store read(StoreAreVSs $)})
       option(DisplayON BrowserDepth:{self.Store read(StoreDepth $)})
       option(DisplayON BrowserWidth:{self.Store read(StoreWidth $)})
       option(DisplayON BrowserWidthInc:{self.Store read(StoreWidthInc $)})
       option(DisplayON BrowserWidthInc:{self.Store read(StoreWidthInc $)})
       option(LayoutON BrowserFontSize:
          {self.Store read(StoreTWFont $)}.size)
       option(LayoutON BrowserBold:
          {self.Store read(StoreTWFont $)}.wght == bold)
       option(LayoutON BrowserRecordFieldsAligned:
          {self.Store read(StoreFillStyle $)} == Expanded)]
   end

   %%
   %%
   meth add(Action
            label:Label <= local N = {System.printName Action} in
                              case N of '' then 'NoLabel' else N end
                           end)
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::add is applied'}
\endif
      {self.BrowserStream enq(addAction(Action Label))}
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::addProcessAction is finished'}
\endif
   end

   %%
   %%
   meth set(Action)
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::setProcessAction is applied'}
\endif
      {self.BrowserStream enq(setAction(Action))}
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::set is finished'}
\endif
   end

   %%
   %%  Acepts 'all' as a special keyword;
   meth delete(Action)
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::delete is applied'}
\endif
      {self.BrowserStream enq(removeAction(Action))}
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::removeProcessAction is finished'}
\endif
   end

   %%
   %% SetSelected ('<1>' event for a term);
   %% The 'AreCommas' argument means whether the term that is selected
   %% have been "width"-constrained;
   %%
   meth !SetSelected(Obj AreCommas)
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::SetSelected is applied'#Obj.term#Obj.type}
\endif
      %%
      lock
         FBrowserClass , UnsetSelected

         %%
         selected <- Obj
         {self.BrowserStream enq(highlight(Obj))}

         %%
         {self.BrowserStream
          enq(entriesEnable([unselect rebrowse process]))}

         %%
         case Obj.type of !T_Shrunken then
            {self.BrowserStream [enq(entriesDisable([deref shrink]))
                                 enq(entriesEnable([expand]))]}
         elseof !T_Reference then
            {self.BrowserStream [enq(entriesDisable([expand shrink]))
                                 enq(entriesEnable([deref]))]}
         else
            if AreCommas then
               {self.BrowserStream [enq(entriesDisable([deref]))
                                    enq(entriesEnable([expand shrink]))]}
            else
               {self.BrowserStream [enq(entriesDisable([expand deref]))
                                    enq(entriesEnable([shrink]))]}
            end
         end

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::SetSelected is finished'}
\endif
      end
   end

   %%
   %%
   meth !UnsetSelected
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::UnsetSelected is applied'}
\endif
      lock
         selected <- InitValue

         %%
         {self.BrowserStream
          [enq(unHighlightTerm)
           enq(entriesDisable([unselect rebrowse process
                               expand shrink deref]))]}

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::UnsetSelected is finished'}
\endif
      end
   end

   %%
   %%
   meth !SelExpand
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::SelExpand is applied'}
\endif
      %%
      lock
         if @selected \= InitValue then
            %%
            {self.BrowserStream enq(expand(@selected))}

            %%
            FBrowserClass , UnsetSelected
         end

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::SelExpand is finished'}
\endif
      end
   end

   %%
   %%
   meth !SelShrink
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::SelShrink is applied'}
\endif
      %%
      lock
         if @selected \= InitValue then
            %%
            {self.BrowserStream enq(shrink(@selected))}

            %%
            FBrowserClass , UnsetSelected
         end

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::SelShrink is finished'}
\endif
      end
   end

   %%
   %%
   meth !Process
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::Process is applied'}
\endif
      %%
      local Selected in
         Selected = @selected   % a snapshot;

         %%
         if Selected \= InitValue then
            Action = {self.Store read(StoreProcessAction $)}
            proc {CrashProc _ _ _}
               skip
            end
         in
            %%
            try {Action Selected.term}
            catch failure(debug:D) then {CrashProc failure unit D}
            [] error(T debug:D) then {CrashProc error T D}
            [] system(T debug:D) then {CrashProc system T D}
            end
\ifdef DEBUG_RM
            {Selected debugShow}
\endif
         end
      end

      %%
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::Process is finished'}
\endif
   end

   %%
   %%
   meth !SelDeref
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::SelDeref is applied'}
\endif
      %%
      lock
         if @selected \= InitValue then
            %%
            {self.BrowserStream enq(deref(@selected))}

            %%
            FBrowserClass , UnsetSelected
         end

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::SelDeref is finished'}
\endif
      end
   end

   %%
   meth !About
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::About is applied'}
\endif
      %%
      {self.BrowserStream enq(makeAbout)}
      %%
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::About is finished'}
\endif
   end

   %%
   meth !SetDepth(Depth)
      lock
         if {IsInt Depth} andthen Depth > 0 then
            {self.Store store(StoreDepth Depth)}
         else {BrowserError 'Illegal value of parameter BrowserDepth'}
         end
      end
   end

   %%
   meth !ChangeDepth(Inc)
      lock
         FBrowserClass , SetDepth({self.Store read(StoreDepth $)} + Inc)
         FBrowserClass , UpdateSizes
      end
   end

   %%
   meth !SetWidth(Width)
      lock
         if {IsInt Width} andthen Width > 1 then
            {self.Store store(StoreWidth Width)}
         else {BrowserError 'Illegal value of parameter BrowserWidth'}
         end
      end
   end

   %%
   meth !ChangeWidth(Inc)
      lock
         FBrowserClass , SetWidth({self.Store read(StoreWidth $)} + Inc)
         FBrowserClass , UpdateSizes
      end
   end

   %%
   meth !SetDInc(DI)
      lock
         if {IsInt DI} andthen DI > 0 then
            {self.Store store(StoreDepthInc DI)}
         else {BrowserError 'Illegal value of parameter BrowserDepthInc'}
         end
      end
   end

   %%
   meth !ChangeDInc(Inc)
      lock
         FBrowserClass , SetDInc({self.Store read(StoreDepthInc $)} + Inc)
      end
   end

   %%
   meth !SetWInc(WI)
      lock
         if {IsInt WI} andthen WI > 0 then
            {self.Store store(StoreWidthInc WI)}
         else {BrowserError 'Illegal value of parameter BrowserWidthInc'}
         end
      end
   end

   %%
   meth !ChangeWInc(Inc)
      lock
         FBrowserClass , SetWInc({self.Store read(StoreWidthInc $)} + Inc)
      end
   end

   %%
   %% Updates (increases) depth&width of terms actually shown;
   meth !UpdateSizes
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::UpdateSizes is applied'}
\endif
      %%
      lock
         {ForAll {self.BrowserBuffer getContent($)}
          proc {$ RootTermObj}
             {self.BrowserStream enq(updateSize(RootTermObj))}
          end}

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::UpdateSizes is finished'}
\endif
      end
   end

   %%
   %% Check the layout;
   meth refineLayout
\ifdef DEBUG_BO
      {System.show 'FBrowserClass::checkLayt is applied'}
\endif
      lock
         local CLProc in
            %%
            proc {CLProc RootTermObj}
               {self.BrowserStream enq(refineLayoutReq(RootTermObj))}
            end

            %%
            {ForAll {self.BrowserBuffer getContent($)} CLProc}
\ifdef DEBUG_BO
            {System.show 'FBrowserClass::checkLayt is finished'}
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
      {System.show 'FBrowserClass::SetTWWidth is applied'}
      thread {Wait Width} {System.show '... Width = '#Width} end
\endif
      %%
      {Wait Width}
      lock
         {self.Store store(StoreTWWidth Width)}

         %%
         {self  refineLayout}

         %%
\ifdef DEBUG_BO
         {System.show 'FBrowserClass::SetTWWidth is finished'}
\endif
      end
   end

   %%
end
