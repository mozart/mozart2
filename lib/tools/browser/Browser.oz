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
%%%  very main browser's module;
%%%
%%%
%%%
%%%

%%
%\define    DEBUG_OPEN
\undef     DEBUG_OPEN

declare
BrowserClass
Browser
Browse
in

%%
\ifdef DEBUG_OPEN
declare

\else
local
\endif

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
   IsFdVar        % is a FD variable?
   IsRecordCVar   % is an OFS?
   IsMetaVar      % is a Meta variable?
   WatchMetaVar   %
   MetaGetDataAsAtom % get the constraint data of the meta variable
   MetaGetNameAsAtom % get the name of the constraint system of a meta var
   MetaGetStrength   % get some measure of the informartion of meta var
   HasLabel       % non-monotonic test;
   EQ             % pointers equality;
   TermSize       % size of a term's representation;
   GetsTouched    % fires when its argument is ever touched;
   DeepFeed       % 'feed', but also from local computation spaces;
   ChunkArity     % yields chunk arity;
   ChunkWidth     % ... its width;
   AddrOf         %
   OnToplevel     %

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
   ProcedureTermObject
   CellTermObject
   PrimChunkTermObject
   DictionaryTermObject
   ArrayTermObject
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
   FDVariableTermObject
   MetaVariableTermObject
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
      ShowInOPI = {NewName}
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
      [Reset SetBufferSize ChangeBufferSize SetSelected UnsetSelected
       SelExpand SelShrink Process SelDeref About SetDepth
       SetWidth ChangeWidth SetDInc ChangeDInc SetWInc ChangeWInc
       UpdateSizes SetTWWidth ScrollTo] = {ForAll $ NewName}

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
\insert 'browser/bufs&streams.oz'

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
      case {Cond} then {Body} {While Cond Body} else skip end
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
         proc {CrashProc E T D}
            {Show '*********************************************'}
            {Show 'Exception occured in browser:'#E#T#D}
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
         case {IsVar HasCrashed} then skip
         else Pl Hl in
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
   class BrowserClass
      from Object.base
      feat
         RealBrowser            %
         BrowserStream          % used for "deep" browsing;
         BrowserCell            % ...

      %%
      %%
      meth init(...)=M
         local InternalBrowserLoop in
            self.RealBrowser = {New FBrowserClass M}
            self.BrowserCell = {NewCell self.BrowserStream}

            %%
            %% Spawn off the internal browsing loop picking up browser
            %% commands issued in local computation spaces;
            proc {InternalBrowserLoop S}
               case S
               of Cmd|Tail then
                  {ApplyBrowser self.RealBrowser Cmd}
                  {InternalBrowserLoop Tail}
               else {BrowserError 'Browser channel is closed???'}
               end
            end
            thread
               {InternalBrowserLoop self.BrowserStream}
            end
         end
      end

      %%
      meth otherwise(M)
         case {IsDeepGuard} then {DeepFeed self.BrowserCell {Reflect M}}
         else {ApplyBrowser self.RealBrowser M}   % be transparent;
         end
      end

      %%
   end

   %%
   %%
   Browser = {New BrowserClass init}
   Browse = proc {$ X} {Browser browse(X)} end

   %%
   %%
\ifndef DEBUG_OPEN
end
\endif

\insert 'browser/undefs.oz'
