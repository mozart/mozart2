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

\ifndef NODECLARE

declare
Browse
in

\endif % NODECLARE

%%
\ifdef DEBUG_OPEN
declare

\else
local
\endif
   %%
   %%
   %%
   %%  Local initial constants;
\insert 'browser/constants.oz'
\insert 'browser/setParameter.oz'


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
   RealArity      %  'real' record arity;
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
   Width          %  special 'Width': {Width X} == {Length {RealArity X}};
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
   %%  (no (Oz) Names can be passed to wish;)
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
   DoBrowse
   %%
   %%
   %% `.` = proc {$ X Y ?Z}
   %%    case {IsRecord X} then
   %%       case {IsAtom X} then
   %%     {Show '***** .: bullshit!!! '#X#Y}
   %%     Z = InitValue
   %%       else
   %%     case {IsLiteral Y} then
   %%        {Subtree X Y Z}
   %%     else
   %%        {Show '***** .: bullshit!!! '#X#Y}
   %%        Z = InitValue
   %%     end
   %%       end
   %%    elsecase {IsTuple X} then
   %%       case {IsAtom X} then
   %%     {Show '***** .: bullshit!!! '#X#Y}
   %%     Z = InitValue
   %%       else
   %%     case {IsNumber Y} then
   %%        {Subtree X Y Z}
   %%     else
   %%        {Show '***** .: bullshit!!! '#X#Y}
   %%        Z = InitValue
   %%     end
   %%       end
   %%    else
   %%       {Show '***** .: bullshit!!! '#X#Y}
   %%       Z = InitValue
   %%    end
   %% end
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
   %%  BrowserClass;
\insert 'browser/browserObject.oz'
   %%
\insert 'browser/reflect.oz'

\ifdef FEGRAMED
  \insert 'browser/fegramed.oz'
\endif

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
\ifdef FEGRAMED
                                 FE_BrowserClass
\endif
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
         %%  actually, "for historical reasons";
         {ForAll @listOf proc {$ BO} {BO browse(Term)} end}
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
         listOf <- {Filter
                    @listOf
                    fun {$ BOInList}
                       case BOInList == BO then False else True end
                    end}
      end
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
         local Syncs in
            {Map @listOf fun {$ BO} {BO createWindow($)} end Syncs}
            %%
            case {All Syncs IsValue} then <<nil>> end
         end
      end
      %%
   end
   %%
   %%
   %%  Browser's cell;
   %%
   BrowserCell = {NewCell BrowserStream}
   %%
   %%
   proc {InternalBrowse S}
      if Term Tail in S = Term|Tail then
         {BrowsersPool browse(Term)}
         {InternalBrowse Tail}
      else
         {BrowserError ['Browser channel is closed?']}
      fi
   end
   %%
   %%  always running;
   job {InternalBrowse BrowserStream} end
   %%
   %% pre-defined 'Browse' procedure;
   proc {DoBrowse Term}
      {DeepFeed BrowserCell {Reflect Term}}
   end
   %%
   %% 'Browse' module;
   Browse = {Adjoin
             browse(equate:
                       proc {$ Term} {BrowsersPool equate(Term)} end
                    setParameter:
                       proc {$ Par Val} {BrowsersPool setPar(Par Val)} end
                    getParameter:   % bogus ???
                       proc {$ Par ?Val} {BrowsersPool getPar(Par Val)} end
                    createWindow:
                       proc {$} {BrowsersPool createWindows} end
                    browserClass: class $ from BrowserClass
\ifdef FEGRAMED
                                             FE_BrowserClass
\endif
                                  end
                    browse: DoBrowse)
             DoBrowse}
   %%
   %%
   %%
\ifndef DEBUG_OPEN
end
\endif

\insert 'browser/undefs.oz'
