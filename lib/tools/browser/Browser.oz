%%%
%%% Authors:
%%%   Kostantin Popov (popov@ps.uni-sb.de)
%%%
%%% Contributors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
%%%  very main browser's module;
%%%
%%%
%%%
%%%

functor

require
   DefaultURL(homeUrl)
   URL(make resolve toAtom)

prepare
   BitmapUrl = {URL.toAtom {URL.resolve DefaultURL.homeUrl
                            {URL.make 'images/'}}}

import
   Space RecordC

   CTB(isB getConstraintAsAtom getNameAsAtom) at 'x-oz://boot/CTB'

   FDB(isVarB) at 'x-oz://boot/FDB'

   FSB('reflect.lowerBound'
       'reflect.upperBound'
       'reflect.card'
       'var.is')
   at 'x-oz://boot/FSB'

   BrowserSupport(recordCIsVarB
                  getTermSize
                  getsBoundB
                  chunkArity
                  chunkWidth
                  addr
                  procLoc)
   at 'x-oz://boot/Browser'

   Debug at 'x-oz://boot/Debug'

   FD(reflect)

   Search(one)

   Property(get)

   System(show
          printName
          eq
          onToplevel)

   Tk

   TkTools

   BootObject(getClass)
   at 'x-oz://boot/Object'

export
   'class':  BrowserClass
   'object': Browser

   'browse': Browse
   'close':  CloseBrowser

define

   %%
   %%
   %%  Local initial constants;
\insert 'browser/constants.oz'

   %%
   %%
   %%  Various local procedures and modules;
   %%

   %%
   %%  from 'core.oz';
   IntToAtom      %
   IsVar          %
   IsFdVar        % is a finite domain variable?
   IsFSetVar      % is a finite set variable?
   IsRecordCVar   % is an OFS?

   GetCtVarNameAsAtom       % name of the constraint system
   GetCtVarConstraintAsAtom % textual representation of the constraint
   IsCtVar                  % test variable for generic constraint variable

   HasLabel       % non-monotonic test;
   EQ             % pointers equality;
   TermSize       % size of a term's representation;
   GetsTouched    % fires when its argument is ever touched;
   ChunkArity     % yields chunk arity;
   ChunkHasFeatures % ... its width;
   AddrOf         %
   ProcLoc        %
   OnToplevel     %

   %% reflectives for finite sets
   FSetGetGlb
   FSetGetLub
   FSetGetCard

   %%
   %%  'XResources.oz';
   X11ResourceCacheClass

   %%
   %% The persistent X11 resources cache (an object);
   X11ResourceCache

   %%
   %%  'tcl-interface.oz';
   BrowserWindowClass
   MessageWindowClass
   AboutDialogClass
   BufferDialog
   RepresentationDialog
   DisplayDialog
   LayoutDialog

   %%
   %%  'termsStore.oz';
   TermsStoreClass

   %%
   %%  'store.oz';
   StoreClass

   %%
   %%  'errors.oz';
   BrowserMessagesFocus
   BrowserMessagesNoFocus
   BrowserError
   BrowserWarning

   %%
   %%  'reflect.oz';
   IsDeepGuard
   Reflect

   %%
   %% browser's buffers & streams;
   BrowserStreamClass
   BrowserBufferClass

   %%
   %% local - a "flat" browser that does not work in lcs"s;
   FBrowserClass

   %%
   %% "Browser term" module;
   BrowserTerm

   %%
   %% control part;
   MyClosableObject
   ControlObject
   CompoundControlObject
   %%
   GetRootTermObject

   %%
   %% representation manager;
   GetTargetObj
   RepManagerObject
   CompoundRepManagerObject

   %%
   %% Term object classes;
   AtomTermObject
   IntTermObject
   FloatTermObject
   NameTermObject
   ForeignPointerTermObject
   ProcedureTermObject
   CellTermObject
   PrimChunkTermObject
   DictionaryTermObject
   ArrayTermObject
   BitStringTermObject
   ByteStringTermObject
   BitArrayTermObject
   PortTermObject
   LockTermObject
   ThreadTermObject
   SpaceTermObject
   PrimObjectTermObject
   PrimClassTermObject
   ListTermObject
   FConsTermObject
   TupleTermObject
   HashTupleTermObject
   RecordTermObject
   CompChunkTermObject
   CompObjectTermObject
   CompClassTermObject
   VariableTermObject
   FutureTermObject
   FDVariableTermObject
   FSetTermObject
   CtVariableTermObject
   UnknownTermObject

   %%
   %% special term objects;
   RootTermObject
   ShrunkenTermObject
   ReferenceTermObject

   %%
   %%  (local) sub-classes for BrowserClass - from 'browserObject.oz';
   WindowManagerClass
   BrowserManagerClass

   %%
   %% Browser's exception type;
   BEx = {NewName}

   %%
   %% local emulation of job...end;
   While
   JobEnd
   ApplyBrowser

   %%

   Browse Browser BrowserClass CloseBrowser

in

   %%
   %% Various builtins to support meta-(oz)kernel browser's
   %% functionality;
\insert 'browser/core.oz'

   %%
\insert 'browser/errors.oz'

   %%
\insert 'browser/XResources.oz'

   %%
   %% The persistent X11 resources cache (an object);
   X11ResourceCache = {New X11ResourceCacheClass init}

   %%
\insert 'browser/browserTerm.oz'

   %%
   %% "protected" methods, features and attributes - which may not be
   %% used within slave term object sub-classes;
   local
      %% unfortunately, we have to write assignments explicitly
      %% because this case is optimized;
      %%
      %% control object:
      ParentObj = {NewName}
      IsPrimitive = {NewName}
      %%
      Make = {NewName}
      Close = {NewName}
      FastClose = {NewName}
      CheckTerm = {NewName}
      SizeChanged = {NewName}
      GenRefName = {NewName}
      UpdateSize = {NewName}
      ButtonsHandler = {NewName}
      DButtonsHandler = {NewName}
      Rebrowse = {NewName}
      Shrink = {NewName}
      Expand = {NewName}
      ExpandWidth = {NewName}
      Deref = {NewName}
      PutSubterm = {NewName}
      ChangeDepth = {NewName}
      SubtermChanged = {NewName}
      SetRefName = {NewName}

      %%
      %% representation manager;
      WidgetObj = {NewName}
      %%
      MakeRep = {NewName}
      CloseRep = {NewName}
      FastCloseRep = {NewName}
      BeginUpdateSubterm = {NewName}
      EndUpdateSubterm = {NewName}
      CheckLayoutReq = {NewName}
      BeginUpdate = {NewName}
      EndUpdate = {NewName}
      IsEnc = {NewName}
      GetRefName = {NewName}
      PutRefName = {NewName}
      PutEncRefName = {NewName}
      SetCursorAt = {NewName}
      Highlight = {NewName}
      CheckLayout = {NewName}
      SubtermSizeChanged = {NewName}
      GetObjG = {NewName}
      ApplySubtermObjs = {NewName}

      %%
      %% browser object - hidden methods, to be used by Browser's
      %% window manager and tcl/tk interface;
      SetBufferSize = {NewName}
      ChangeBufferSize = {NewName}
      SetSelected = {NewName}
      UnsetSelected = {NewName}
      SelExpand = {NewName}
      SelShrink = {NewName}
      Process = {NewName}
      SelDeref = {NewName}
      About = {NewName}
      SetDepth = {NewName}
      SetWidth = {NewName}
      ChangeWidth = {NewName}
      SetDInc = {NewName}
      ChangeDInc = {NewName}
      SetWInc = {NewName}
      ChangeWInc = {NewName}
      UpdateSizes = {NewName}
      SetTWWidth = {NewName}
      ScrollTo = {NewName}

      %%
   in

      %%
\insert 'browser/store.oz'

      %%
      %% Representation manager (for text widgets);
\insert 'browser/repManager.oz'

      %%
      %% Control object;
\insert 'browser/termsStore.oz'
\insert 'browser/controlObject.oz'

      %%
      %%  Tcl/Tk interface;
\insert 'browser/tcl-interface.oz'

      %%
\insert 'browser/bufsAndStreams.oz'

      %%
      %% Browser manager;
\insert 'browser/windowManager.oz'
\insert 'browser/managerObject.oz'

      %%
      %% Browser itself;
\insert 'browser/browserObject.oz'

      %%  Reflection (deep browsing;)
\insert 'browser/reflect.oz'
   end

   %%
   %% Term objects - on the top of that;
\insert 'browser/termObject.oz'

   %%
   %% Auxiliary - emulation of former job..end constructor;
   proc {While Cond Body}
      if {Cond} then {Body} {While Cond Body} else skip end
   end
   proc {JobEnd Proc}
      local MyThr JobThr in
         MyThr = {Thread.this}

         %%
         thread
            JobThr = {Thread.this}
            {Proc}
         end

         %%
         {While
          fun {$} {Thread.state JobThr} == 'runnable' end
          proc {$} {Thread.preempt MyThr} end}
         %% now, the 'JobThr' is either terminated or blocked;
      end
   end

   %%
   %% Applies the 'Browser' to the 'Cmd' in a (slightly) more robust
   %% way;
   proc {ApplyBrowser Browser Cmd}
      local HasCrashed CrashProc in
         %%
         proc {CrashProc _ _ _}
            HasCrashed = unit
         end

         %%
         try
            %%  Actually, this might block the thread
            %% (for instance, if the browser's buffer is full);
            {Browser Cmd}
         catch failure(debug:D) then {CrashProc failure unit D}
         [] error(T debug:D) then {CrashProc error T D}
         [] system(T debug:D) then {CrashProc system T D}
         end

         %%
         %% Fairly to say, there are few things that can be caught
         %% this way: a browser object has an internal
         %% asynchronous worker which does the actual job ...
         if {IsVar HasCrashed} then skip
         else
            %%
            try
               %%
               %% try to give up gracefully ...
               %% Note that this can block forever;
               {JobEnd proc {$} {Browser close} end}

               %%
               %% ignore faults in the current thread;
            catch failure(debug:_) then skip
            [] error(_ debug:_) then skip
            [] system(_ debug:_) then skip
            end
         end
      end
   end

   %%
   %%
   %% Actual browser - it handles also browsing from local spaces;
   %%
   %% Moreover, this browser is a highlander - it cannot die :-)))
   %%
   class BrowserClass
      from Object.base
      prop
         locking
      attr
         BrowserStream: InitValue % used for "deep" browsing;
         BrowserPort:   InitValue % ...
         InitMeth:      InitValue %
         RealBrowser:   InitValue %
         Options:       nil       %

      %%
      %% A real make which does the work;
      meth Make
         lock
            if @RealBrowser == InitValue then
               BS RB InternalBrowserLoop
            in
               BrowserStream <- BS
               BrowserPort   <- {NewPort @BrowserStream}
               RB = {New FBrowserClass @InitMeth}
               {List.forAll @Options proc {$ M} {RB M} end}
               RealBrowser <- RB

               %%
               %% Spawn off the internal browsing loop picking up browser
               %% commands issued in local computation spaces;
               proc {InternalBrowserLoop S}
                  case S
                  of Cmd|Tail then
                     {self CheckAndDo(Cmd)}
                     {InternalBrowserLoop Tail}
                  else {BrowserError 'Browser channel is closed???'}
                  end
               end
               thread
                  {InternalBrowserLoop BS}
               end

               %%
               %% Watch the real object - and drop it.
               %% Actually, some requests can fall out - but apparently
               %% we cannot do anything here;
               thread
                  {Wait RB.closed}
                  Options <- {RB saveOptions($)}
                  RealBrowser <- InitValue
               end
            end
         end
      end

      %%
      %% It checks the browser's presence, and performs a command;
      meth CheckAndDo(Cmd)
         {self Make}
         {ApplyBrowser @RealBrowser Cmd}
      end

      %%
      %%
      meth init(...)=M
         if @InitMeth == InitValue then
            InitMeth <- M
            %% the first one *must* be created because of deep
            %% browsing - that requires the presence of a cell;
            {self Make}
         else {BrowserError 'Cannot init a browser object twice!'}
         end
      end

      %%
      meth otherwise(M)
         if {IsDeepGuard} then
            {Port.send @BrowserPort {Reflect M}}
         else
            {self CheckAndDo(M)}   % be transparent;
         end
      end

      %%
   end

   %%
   %%
   Browser = {New BrowserClass init}
   Browse = proc {$ X} {Browser browse(X)} end

   proc {CloseBrowser}
      {Browser close}
   end

end
