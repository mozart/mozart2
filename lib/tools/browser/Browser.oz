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
%%%  very main browser's module;
%%%
%%%
%%%
%%%

%%
%\define    DEBUG_OPEN
\undef     DEBUG_OPEN

%\define FEGRAMED



declare
Browse
BrowserModule
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
\insert 'browser/setParameter.oz'

   %%
\ifdef FEGRAMED
   \insert  'browser/fegramed_Vars.oz'
\endif

   %%
   %%
   %%  Various local procedures and modules;
   %%
   %%
   %%  from 'core.oz';
   IntToAtom      %
   IsVar          %
   IsFdVar        %  is a FD variable?
   IsRecordCVar   %  is an OFS?
   WatchDomain    %  fires when the variable's domain is changed;
   IsMetaVar      %  is a Meta variable?
   WatchMetaVar   %  fires when the variable's constraint is strengthened
   MetaGetDataAsAtom %  get the constraint data of the meta variable
   MetaGetNameAsAtom %  get the name of the constraint system of the meta var
   TestC          %  does it has a feature?
   MetaGetStrength   %  get some measure of the informartion of meta var
   EQ             %  pointers equality;
   GetsBound      %  fires iff its argument is bound to something;
   DeepFeed       %  'feed', but also from local computation spaces;
   GenericSet     %  destructive {tuple,record} modification;

   %%
   %%  from 'atoms&strings.oz';
   AtomConcat
   VSLength
   AtomConcatAll
   FindChar
   Tail
   Head
   GetStrs
   DiffStrs

   %%
   %%  'tcl-interface.oz';
   ProtoBrowserWindow
   TermTag
   ProtoMessageWindow
   ProtoHelpWindow

   %%
   %%  'termsStore.oz';
   ProtoTermsStore

   %%
   %%  'store.oz';
   ProtoStore

   %%
   %%  'errors.oz';
   BrowserMessagesInit
   BrowserMessagesExit
   BrowserMessagesFocus
   BrowserMessagesNoFocus
   BrowserError
   BrowserWarning

   %%
   %%  reflection;
   IsDeepGuard
   Reflect

   %%
   %%  local -- channel;
   BrowserStream
   BrowserCell

   %%
   %%  internal (after the stream) browser;
   InternalBrowse

   %%
   %%  (local) sub-classes for BrowserClass - from 'browserObject.oz';
   BasicBrowser
   WindowPrimary

   %%
   %%  from 'subterms.oz';
   TupleSubtermsStore
   RecordSubtermsStore

   %%
   %%  Term sub- and classes;
   %%
   %%  ... used by 'PseudoTermGenericObject';
   MetaGenericTermObject
   MetaTermTermObject

   %%
   %%  generic subclasses;
   AtomGenericTermObject
   IntGenericTermObject
   FloatGenericTermObject
   NameGenericTermObject
   ProcedureGenericTermObject
   CellGenericTermObject
   ChunkGenericTermObject
   ObjectGenericTermObject
   ClassGenericTermObject
   WFListGenericTermObject
   TupleGenericTermObject
   RecordGenericTermObject
   ORecordGenericTermObject
   ListGenericTermObject
   FListGenericTermObject
   HashTupleGenericTermObject
   VariableGenericTermObject
   FDVariableGenericTermObject
   MetaVariableGenericTermObject
   ShrunkenGenericTermObject
   ReferenceGenericTermObject
   UnknownGenericTermObject

   %%  'in text widget' subclasses;
   AtomTermTermObject
   IntTermTermObject
   FloatTermTermObject
   NameTermTermObject
   ProcedureTermTermObject
   CellTermTermObject
   ChunkTermTermObject
   ObjectTermTermObject
   ClassTermTermObject
   WFListTermTermObject
   TupleTermTermObject
   RecordTermTermObject
   ORecordTermTermObject
   ListTermTermObject
   FListTermTermObject
   HashTupleTermTermObject
   VariableTermTermObject
   FDVariableTermTermObject
   MetaVariableTermTermObject
   ShrunkenTermTermObject
   ReferenceTermTermObject
   UnknownTermTermObject

   %%  'term' subclasses;
   AtomTWTermObject
   IntTWTermObject
   FloatTWTermObject
   NameTWTermObject
   ProcedureTWTermObject
   CellTWTermObject
   ChunkTWTermObject
   ObjectTWTermObject
   ClassTWTermObject
   WFListTWTermObject
   TupleTWTermObject
   RecordTWTermObject
   ORecordTWTermObject
   ListTWTermObject
   FListTWTermObject
   HashTupleTWTermObject
   VariableTWTermObject
   FDVariableTWTermObject
   MetaVariableTWTermObject
   ShrunkenTWTermObject
   ReferenceTWTermObject
   UnknownTWTermObject

   %%
   %%  'full' classes;
   AtomTermObject
   IntTermObject
   FloatTermObject
   NameTermObject
   ProcedureTermObject
   CellTermObject
   ChunkTermObject
   ObjectTermObject
   ClassTermObject
   WFListTermObject
   TupleTermObject
   RecordTermObject
   ORecordTermObject
   ListTermObject
   FListTermObject
   HashTupleTermObject
   VariableTermObject
   FDVariableTermObject
   MetaVariableTermObject
   ShrunkenTermObject
   ReferenceTermObject
   UnknownTermObject

   %%
   %%  'Pseudo' term;
   PseudoTermObject
   PseudoTermGenericObject
   PseudoTermTWObject

   %%
   %%  local;
   BrowsersPool

   %%
   %%  "(semi) protected" methods, mainly defined for BrowserClass;
   CreateMenus = {NewName}
   CreateButtons = {NewName}
   SetTWWidth = {NewName}
   Iconify = {NewName}
   ResetWindowSize = {NewName}

   %%
   Bbrowse = {NewName}
   Bundraw = {NewName}
   Bdestroy = {NewName}

   %%
   UpdateSizes = {NewName}
   HistoryButtonsUpdate = {NewName}
   ClearHistory = {NewName}
   CheckHistory = {NewName}
   GetHistory = {NewName}
   SetHistory = {NewName}
   SelExpand = {NewName}
   SelShrink = {NewName}
   SelShow = {NewName}
   Deref = {NewName}
   Help = {NewName}
   Zoom = {NewName}
   Unzoom = {NewName}
   Top = {NewName}
   SetSelected = {NewName}
   UnsetSelected = {NewName}
   SelectAndZoom = {NewName}
   SetActiveState = {NewName}

   %%
   %%  non-public attributes and features;
   DefaultBrowser = {NewName}
   IsView = {NewName}

   %%
   %%  for tcl, #$@#$% !!!!!
   %%  (Oz Names can NOT be passed to wish;)
   TclFalse = 'tcl_False'
   TclTrue = 'tcl_True'
   TclExpanded = 'tcl_Expanded'
   TclFilled = 'tcl_Filled'
   TclAtomicArity = 'tcl_AtomicArity'
   TclTrueArity = 'tcl_TrueArity'

   %%
   %%
   BrowserClass
   %%
   DoEquate
   DoSetParameter
   DoGetParameter
   DoCreateWindow
   %%
   %%  Undocumented;
   DoThrowBrowser
   %%
in

   %%
   %%  Various builtins to support meta-(oz)kernel browser's functionality;
\insert 'browser/core.oz'

   %%  $%ck!
\insert 'browser/atoms&strings.oz'

   %%
\insert 'browser/errors.oz'

   %%
   %%  Local components:
\insert 'browser/store.oz'
\insert 'browser/termsStore.oz'
\insert 'browser/subterms.oz'
\insert 'browser/terms.oz'

   %%
   %%  Tcl/Tk interface;
\insert 'browser/tcl-interface.oz'

   %%
   %%  In_Text_Widget
\insert 'browser/textWidget.oz'

   %%
   %%  ProtoTermObject;
\insert 'browser/termObject.oz'

   %%
   %%  PseudoTermObject;
\insert 'browser/pseudoObject.oz'

   %%
\ifdef FEGRAMED
  \insert 'browser/fegramed.oz'
\endif

   %%  BrowserClass;
\insert 'browser/browserObject.oz'

   %%  Reflection (deep browsing;)
\insert 'browser/reflect.oz'

   %%
   %%
   %%  BrowsersPool: provides the passing of terms to be browsed;
   %%
   create BrowsersPool from UrObject
      attr
         listOf: nil

      %%
      %%
      meth browse(Term)
         %%
         case @listOf == nil then
            local Browser in
               create Browser from BrowserClass
                  %% i.e. create the own one;
                  with init(areMenus: IAreMenus
                            areButtons: IAreButtons
                            standAlone: True       % may be omitted == True
                            DefaultBrowser: True   % 'protected' feature;
                           )
               end

               %%
               listOf <- [Browser]
            end
         else true
         end

         %%
         %%  Actually, "for historical reasons";
         %%  Right now there can be only one "default" browser;
         {ForAll @listOf
          proc {$ BO}
             %%
             %%  Primarily, for the case if something goes wrong there
             %% (suspends, etc.), and we can kill that browser;
             %%  Note that the object state is released here!!!
             job
                {BO browse(Term)}
             end
          end}
      end

      %%
      %%
      meth equate(Term)
         case @listOf == nil then true
         else
            {ForAll @listOf proc {$ BO} {BO equate(Term)} end}
         end
      end

      %%
      %%
      meth setPar(Par Val)
         case @listOf == nil then true
         else
            {ForAll @listOf proc {$ BO} {BO setParameter(Par Val)} end}
         end
      end

      %%
      %%
      meth getPar(Par ?Val)
         case @listOf == nil then Val = False
         else
            {@listOf.1 getParameter(Par Val)}  % from a first one;
         end
      end

      %%
      %%
      meth addNewBrowser(BO)
         listOf <- BO|@listOf
      end

      %%
      %%
      meth removeBrowser(BO)
         listOf <- {Filter @listOf fun {$ BOInList} BOInList \= BO end}
      end
      %%
      meth removeAllBrowsers
         listOf <- nil
      end

      %%
      %%
      meth createWindows
         case @listOf == nil then
            local Browser in
               Browser =
               {New BrowserClass
                init(areMenus: IAreMenus
                     areButtons: IAreButtons
                     standAlone: True       % may be omitted == True
                     DefaultBrowser: True   % 'protected' feature;
                    )}

               %%
               listOf <- [Browser]
            end
         else true
         end

         %%
         {ForAll @listOf proc {$ BO} {BO createWindow(_)} end}
         %%
         <<nil>>
      end

      %%
   end

   %%
   %%
   %%  Browser's cell;
   %%
   BrowserCell = {NewCell BrowserStream}

   %%
   %%  "Internal" browser;
   %%
   proc {InternalBrowse S}
      case S
      of Cmd|Tail then
         local Proc Handle in
            %%
            Proc = proc {$} {BrowsersPool Cmd} end
            Handle = proc {$ E}
                        {Show '*********************************************'}
                        {Show 'Exception occured in browser:'#E}
                     end

            %%
            {System.catch Proc Handle}
         end

         %%
         {InternalBrowse Tail}
      else
         {BrowserError ['Browser channel is closed?']}
      end
   end

   %%
   %%  always running;
   thread {InternalBrowse BrowserStream} end

   %%
   %%
   %% pre-defined 'Browse' procedure;
   proc {Browse Term}
      {DeepFeed BrowserCell
       browse(case {IsDeepGuard} then {Reflect Term} else Term end)}
   end

   %%
   proc {DoEquate Term}
      case {IsDeepGuard} then
         {Show 'Browse.equate from a deep guard?'}
      else
         {DeepFeed BrowserCell equate(Term)}
      end
   end

   %%
   proc {DoSetParameter Par Val}
      case {IsDeepGuard} then
         {Show 'Browse.setParameter from a deep guard?'}
      else
         {DeepFeed BrowserCell setPar(Par Val)}
      end
   end

   %% bogus ???
   proc {DoGetParameter Par ?Val}
      case {IsDeepGuard} then
         {Show 'Browse.getParameter from a deep guard?'}
      else
         {DeepFeed BrowserCell getPar(Par Val)}
      end
   end

   %%
   proc {DoCreateWindow}
      case {IsDeepGuard} then
         {Show 'Browse.createWindow from a deep guard?'}
      else
         {DeepFeed BrowserCell createWindows}
      end
   end

   %%
   proc {DoThrowBrowser}
      case {IsDeepGuard} then
         {Show 'Browse.createWindow from a deep guard?'}
      else
         {DeepFeed BrowserCell removeAllBrowsers}
      end
   end

   %%
   %% 'Browse' module;
   BrowserModule = browse(equate:       DoEquate
                          setParameter: DoSetParameter
                          getParameter: DoGetParameter
                          createWindow: DoCreateWindow
                          browserClass: BrowserClass
                          throwBrowser: DoThrowBrowser
                          browse:       Browse)

   %%
   %%
\ifndef DEBUG_OPEN
end
\endif

\insert 'browser/undefs.oz'
