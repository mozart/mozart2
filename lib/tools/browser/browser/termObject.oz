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
%%%  'generic' term classes;
%%%
%%%
%%%
%%%

local
   %%  'meta' objects in various flavors;
   MetaTupleGenericTermObject
   MetaRecordGenericTermObject
   MetaChunkGenericTermObject

   %%  Generator of reference names;
   NewRefNameGen

   %%
   DiffRest
in
   %%
   %%   Main philosophy: the browser should be *event-driven*.
   %%  Simultaneously most common places for browser's operations are *terms*.
   %%  So, every (sub)term is represented via some object which is bound
   %%  with a tag (Tcl/Tk notion);
   %%
   %%   These objects build a structure that (weakly) corresponds to a term's
   %%  structure; e.g. tree-like. Every object represents corresponding
   %%  subterm;
   %%
   %%   Note that this structure is *always* tree-like despite rational tree
   %%  constraint system. Recursive terms are whether considered as
   %%  non-recursive (util predefined depth), or all "secondary entries" are
   %%  detected and represented in a special way;
   %%
   %%   Each term can be shown or not. This is reflected by the value of
   %%  an attribute 'shown'. Its values are 'True' or 'False';
   %%
   %%   Operation of every object can be devided in two phases: init and draw;
   %%  During the 'init' phase the internal (tree of objects) representation is
   %%  created; during the second one - a corresponding textual one;
   %%
   %%   Each term object carries number of attributes and features ('shown' is
   %%  one of the attributes). Their semantic is clear (hopefully!) from their
   %%  names;
   %%
   %%   Each term class inherits at least from three classes.
   %%  These are 'generic' part, 'type' part and widget-specific part
   %%  (currently only for text widgets). This file contains 'generic' part;
   %%  This splitting is necessary to be able to encode other external
   %%  representations and/or their medias (i.e., not in text widgets);
   %%
   %%   Note that there are different term classes for terms of different types.
   %%  I.e., we have 'generic', 'type' and 'textWidget' classes separtely for
   %%  atoms, integers, ... . We achieve this way
   %%  - simplicity and orthogonality of design
   %%    (you can add simply new term types if needed);
   %%  - efficiency, because there is no need now to switch every time
   %%    on a particular type of term;
   %%  - memory efficiency, because every object carries only attributes/features
   %%    which are necessary for terms of that type.
   %%

   %%
   %%  GenericTermObject
   %%  It defines the features/attributes which are common for all types of
   %% generic term classes;
   %%
   class MetaGenericTermObject from UrObject
      %%
      feat
         term                   % browsed term itself;
      %% type field is added to particular objects (e.g. AtomObject);
      %% type                   % type of;
         numberOf               % sequential number in compound parent term;
         parentObj              %
         widgetObj              %
         store                  % reference to the global store;
         termsStore             % ... to 'terms' store (cyclic terms, etc.);
         browserObj             % reference to 'browser' object;

      %%
      attr
         depth: InitValue

      %%
      %%
      %%  STATELESS METHOD;
      meth getObjClass(Type ?ObjClass)
\ifdef DEBUG_TO
         {Show 'MetaGenericTermObject::getObjClass is applied: '#Type}
\endif
         ObjClass = case Type
                    of !T_Atom       then AtomTermObject
                    [] !T_Int        then IntTermObject
                    [] !T_Float      then FloatTermObject
                    [] !T_Name       then NameTermObject
                    [] !T_Procedure  then ProcedureTermObject
                    [] !T_Cell       then CellTermObject
                    [] !T_Object     then ObjectTermObject
                    [] !T_Class      then ClassTermObject
                    [] !T_WFList     then WFListTermObject
                    [] !T_Tuple      then TupleTermObject
                    [] !T_Record     then RecordTermObject
                    [] !T_ORecord    then ORecordTermObject
                    [] !T_List       then ListTermObject
                    [] !T_FList      then FListTermObject
                    [] !T_HashTuple  then HashTupleTermObject
                    [] !T_Variable   then VariableTermObject
                    [] !T_FDVariable then FDVariableTermObject
                    [] !T_MetaVariable then MetaVariableTermObject
                    [] !T_Shrunken   then ShrunkenTermObject
                    [] !T_Reference  then ReferenceTermObject
                    [] !T_Unknown    then UnknownTermObject
                    [] !T_PSTerm     then
                       {BrowserError
                        ['T_PSTerm is met in TermObject::getObjClass.']}
                       UnknownTermObject
                    else
                       {BrowserError
                        ['Unknown type in TermObject::getObjClass: ']}
                       UnknownTermObject
                    end
         %%
      end

      %%
      %%  Generic 'init' method;
      %%
      meth init(term: Term
                depth: Depth
                numberOf: NumberOf
                parentObj: ParentObj
                widgetObj: WidgetObj
                store: Store
                termsStore: TermsStore
                browserObj: BrowserObj)
         %%
         self.term = Term
         self.numberOf = NumberOf
         self.parentObj = ParentObj
         self.widgetObj = WidgetObj
         self.store = Store
         self.termsStore = TermsStore
         self.browserObj = BrowserObj

         %%
         depth <- Depth
\ifdef DEBUG_TO
         {Show 'GenericTermObject::init for the subterm '#self.term}
\endif

         %%
         shown <- False

         %%
         <<initTerm>>
         <<initOut>>
      end

      %%
      %%
      meth isShown(?IsShown)
         IsShown = @shown
      end

      %%
      %%
      meth destroy
\ifdef DEBUG_TO
         {Show 'MetaGenericObject::destroy method for the term '#self.term}
\endif
         {self.termsStore decNumberOfNodes}

         %%
         <<closeOut>>
         <<UrObject close>>

         %%
         %%  Note that no term object can close itself, but only on
         %% request from the parent;
         %%  It means that the parent object has the complete control over
         %% closing process, and may not ask its child for something after
         %% its closing;
      end

      %%
      %%  for atomic term objects;
      meth updateSizes(Depth)
         depth <- Depth
      end

      %%
      %%  Handler for key-press events;
      %%
      meth keysHandler(St)
         local Char in
            Char = {String.toAtom St}
            %%
            case Char
\ifdef DEBUG_SHOW
            of '?'         then <<debugShow>>
            [] '>'         then <<expand>>
\else
            of '>'         then <<expand>>
\endif DEBUG_SHOW
            [] '<'         then <<shrink>>
            [] '.'         then <<expand>>
            [] ','         then <<shrink>>
            [] 'e'         then <<expand>>
            [] 's'         then <<shrink>>
            [] 'z'         then {self.browserObj SelectAndZoom(self)}
            [] 'd'         then <<deref>>
            [] 'u'         then true    % tcl-interface: unzoom;
            [] 't'         then true    % tcl-interface: top;
            [] 'f'         then true    % tcl-interface: first;
            [] 'l'         then true    % tcl-interface: last;
            [] 'p'         then true    % tcl-interface: previous;
            [] 'n'         then true    % tcl-interface: next;
            [] 'a'         then true    % tcl-interface: all;
               %%
               %% ignore all non-printable symbols;
               %% (aka control, shift, mod, etc.);
            [] '{}'        then true
               %%
               %% all 'control-' actions processed by tk/tcl interface;
               %% Note: there proper control characters in atom names;
            [] ''        then true
            [] ''        then true
            [] ''        then true
            [] ''        then true
            [] ''        then true
            [] ''        then true
            [] '\\f'       then true    % '^L'
            [] ''        then true
            [] ''        then true
            [] '\r'        then true    % control-mod-m;
            else {BrowserWarning ['"' Char '": Undefined action for a term']}
            end
         end
      end

      %%
      %%  Handler for buttons click events;
      %%
      meth buttonsHandler(NS)
         local NA in
            NA = {String.toAtom NS}
            %%
            case NA
            of '1' then
               {self.widgetObj tagHighlight(self.tag)}
               {self.browserObj SetSelected(self <<areCommas($)>>)}
            [] '3' then true    % handled by tcl-interface directly;
            [] '2' then true
            end
         end
      end

      %%
      %%  Handler for buttons double-click events;
      %%
      meth dButtonsHandler(NS)
         local NA in
            NA = {String.toAtom NS}
            %%
            case NA
            of '1' then <<expand>>
            [] '2' then <<deref>>
            [] '3' then <<shrink>>
            end
         end
      end

      %%
      %%
      meth show
         {Show self.term}
      end

      %%
      %%
      meth expand
         true
         %% differs for shrunken and partially shrunken objects;
      end

      %%
      %%
      meth shrink
\ifdef DEBUG_TO
         {Show 'MetaGenericObject::shrink method for the term '#self.term#self.type}
\endif
         job
            {self.parentObj renewNum(self 0)}
         end
      end

      %%
      %%
      meth deref
         true
      end
      %%

   end

   %%
   %%  NOTE
   %%  Actually, we could have a more elaborated hierarchy, for instance -
   %% 'proto' classes for each group of types. But I think it's better
   %% for debugging and possible further modifications;
   %%
   %%  Atoms;
   %%
   class AtomGenericTermObject
      from MetaGenericTermObject
      %%
      feat
         type: T_Atom

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['AtomObject::' Message '???']}
      end
      %%
   end

   %%
   %%  Integers;
   %%
   class IntGenericTermObject
      from MetaGenericTermObject
      %%
      feat
         type: T_Int

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['IntObject::' Message '???']}
      end

      %%
      %%
      meth checkTag
         true
      end
      %%
   end

   %%
   %%  Floats;
   %%
   class FloatGenericTermObject
      from MetaGenericTermObject
      %%
      feat
         type: T_Float

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['FloatObject::' Message '???']}
      end
      %%
   end

   %%
   %%  Names;
   %%
   class NameGenericTermObject
      from MetaGenericTermObject
      %%
      feat
         type: T_Name
      %%
      %%
      attr
         refVarName:   ''       % prefix;

      %%
      %%  Send to the 'Obj' a name of a reference (refVar);
      %%  If none is yet defined, generate one via the NewRefNameGen;
      %%
      meth getRefVar(Obj)
\ifdef DEBUG_TO
         {Show 'NameGenericTermObject::getRefVar: term '#self.term}
\endif
         case @refVarName == '' then
            RefNumber Ref OldSize NeedBraces
         in
            RefNumber = {NewRefNameGen gen($)}
            Ref = self.termsStore.refType#RefNumber
            refVarName <- Ref

            %%
            {Obj setRefVar(self Ref)}

            %%
            <<insertRefVar>>
         else
            {Obj setRefVar(self @refVarName)}
         end
         %%
      end

      %%
      %%  perform 'retract' in addition;
      meth destroy
         %%
         <<MetaGenericTermObject destroy>>

         %%  Note: proper 'destroy' should go first, since
         %% now the object (self) must be already closed;
         <<retract>>
      end

      %%
      %%
      meth retract
\ifdef DEBUG_TO
         {Show
          'NameGenericObject::retract method for the term '#self.term}
\endif
         {self.termsStore retract(self)}

         %%
         refVarName <- ''
      end

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['NameObject::' Message '???']}
      end
      %%
   end

   %%
   %%
   %%  'Meta' object for compound (tuple-like) term objects;
   %%
   class MetaTupleGenericTermObject
      from MetaGenericTermObject
      %%
      attr
         refVarName:   ''       % prefix;

      %%
      %%
      meth createSubtermObjs(N Max Subterms)
\ifdef DEBUG_TO
         {Show 'MetaTupleGenericObject::createSubtermObjs method for the term '
          #self.term#N#Max}
\endif
         case N =< Max then
            ST RSubterms STType ObjClass Obj EQCheck RefObj
         in
            %%
            Subterms = ST|RSubterms

            %%
            <<getTermType(ST N STType)>>

            %%
            {self.termsStore needsCheck(STType EQCheck)}
            case EQCheck then
               {self.termsStore checkANDStore(self ST Obj RefObj)}

               %%
               case RefObj == InitValue then
                  %% none found -- proceed;
                  <<getObjClass(STType ObjClass)>>
               else
                  ObjClass = ReferenceTermObject
               end
            else
               <<getObjClass(STType ObjClass)>>
            end

            %%
            Obj = {New ObjClass init(term: ST
                                     depth: @depth - 1
                                     numberOf: N
                                     parentObj: self
                                        widgetObj: self.widgetObj
                                     store: self.store
                                     termsStore: self.termsStore
                                     browserObj: self.browserObj)}

            %%
            case ObjClass == ReferenceTermObject then
               thread
                  {RefObj getRefVar(Obj)}

                  %%  Note: 'RefObj' could get closed already.
                  %% Let's check it;
                  {Obj watchMaster(RefObj)}
               end
            else true
            end

            %%
            <<setSubtermObj(N Obj)>>

            %%
            <<createSubtermObjs((N+1) Max RSubterms)>>
         else true
         end
      end

      %%
      %%
      meth destroy
\ifdef DEBUG_TO
         {Show
          'MetaTupleGenericObject::destroy method for the term '#self.term}
\endif
         {self.termsStore decNumberOfNodes}

         %%
         <<[destroyChilds(_) closeOut]>>
         <<UrObject close>>

         %%
         <<retract>>
      end

      %%
      %%
      meth retract
\ifdef DEBUG_TO
         {Show
          'MetaTupleGenericObject::retract method for the term '#self.term}
\endif
         {self.termsStore retract(self)}

         %%
         refVarName <- ''
      end

      %%
      %%  Destroy all childs of this object;
      %%
      meth destroyChilds(Sync)
\ifdef DEBUG_TO
         {Show
          'MetaTupleTermTermObject::destroyChilds method for the term '#
          self.term#<<getTotalWidth($)>>}
\endif
         %%
         <<sendMessages(destroy)>>

         %%  sets 'totalWidth' to zero;
         <<removeAllSubterms>>
      end

      %%
      %%
      %%  Send to the 'Obj' a name of a reference (refVar);
      %%  If none is yet defined, generate one via the NewRefNameGen;
      %%
      meth getRefVar(Obj)
\ifdef DEBUG_TO
         {Show 'MetaTupleGenericTermObject::getRefVar: term '#self.term}
\endif
         case @refVarName == '' then
            RefNumber Ref OldSize NeedBraces
         in
            RefNumber = {NewRefNameGen gen($)}
            Ref = self.termsStore.refType#RefNumber
            refVarName <- Ref

            %%
            {Obj setRefVar(self Ref)}

            %%
            <<insertRefVar>>
         else
            {Obj setRefVar(self @refVarName)}
         end
      end

      %%
      %%  Create a new subterm object for the Nth subterm (Obj.numberOf),
      %% with the depth of 'Depth';
      %%  Perform also 'checkSize' "from" just created object;
      %%
      meth renewNum(Obj Depth)
\ifdef DEBUG_TO
         {Show 'MetaTupleGenericTermObject::renewNum: term '#Obj.term}
\endif
         local
            N StoredObj WasShown OldSize NewSize ActualDepth NewObj
         in
            N = Obj.numberOf
            StoredObj = <<getSubtermObj(N $)>>

            %%
            case Obj == StoredObj then
               {Obj [isShown(WasShown) getSize(OldSize) undraw destroy]}

               %%
               ActualDepth = @depth
               depth <- Depth + 1

               %%
               <<createSubtermObjs(N N [Obj.term])>>

               %%
               NewObj  = <<getSubtermObj(N $)>>
               NewSize = {NewObj getSize($)}

               %%
               case WasShown then
                  <<drawSubterm(N)>>
               else true
               end

               %%
               depth <- ActualDepth

               %%
               <<checkSize(NewObj OldSize NewSize)>>
            else true           % ignore - 'garbage' message;
            end
         end
      end

      %%
      %%  'redraw' + 'checkSize' from 'Obj';
      %%
      meth redrawNum(Obj)
\ifdef DEBUG_TO
         {Show 'MetaTupleGenericTermObject::redrawNum: term '#self.term}
\endif
         local N StoredObj OutInfo WasShown OldSize NewSize in
            N = Obj.numberOf
            %%
            <<getSubtermObjOutInfo(N StoredObj OutInfo)>>
            OldSize = OutInfo.size

            %%
            case Obj == StoredObj then
               {Obj [isShown(WasShown) getSize(NewSize) undraw]}

               %%
               case WasShown then
                  <<drawSubterm(N)>>
               else true
               end

               %%
               <<checkSize(Obj OldSize NewSize)>>
            else true           % ignore - 'garbage' message;
            end
         end
      end

      %%
      %%
      meth expand
\ifdef DEBUG_TO
         {Show 'MetaTupleGenericTermObject::expand: term '#self.term}
\endif
         local WidthInc in
            WidthInc = {self.store read(StoreWidthInc $)}

            %%
            <<ExpandWidthLoop(WidthInc)>>
         end
      end

      %%
      meth ExpandWidthLoop(N)
         case N >= 1 then
            <<expandWidthOne>>

            %%
            <<ExpandWidthLoop(N - 1)>>
         else true
         end
      end

      %%
      %%  insert one further subterm (and remove commas if needed);
      meth expandWidthOne
\ifdef DEBUG_TO
         {Show 'MetaTupleGenericTermObject::expandWidthOne: term '#self.term}
\endif
         case @shown andthen <<areCommas($)>> then
            Subterms RestOf ActWidth NewWidth OldSize NewSize
         in
            Subterms = <<getSubterms($)>>
            ActWidth = @width
            NewWidth = ActWidth + 1

            %%
            RestOf = {List.drop Subterms ActWidth}

            %%
            case RestOf == nil then true
            else
               OldSize = <<getSize($)>>
               %%  insert a slot for a new subterm;
               case {Length RestOf} == 1 then
                  local CommasObj in
                     <<makeLastSubterm(CommasObj)>>

                     %%
                     {CommasObj [undraw destroy]}

                     %%  create a subterm;
                     <<createSubtermObjs(NewWidth NewWidth RestOf)>>
                  end
               else
                  <<addSubterm>>

                  %%  create a subterm;
                  <<createSubtermObjs(NewWidth NewWidth RestOf)>>

                  %%  We have to init 'outInfoRec';
                  <<initMoreOutInfo(NewWidth NewWidth)>>
               end

               %%  Draw it (and produce new glue, if needed);
               %%  Updates also metasizes;
               <<drawNewSubterm(NewWidth)>>

               %%
               NewSize = <<getSize($)>>

               %%
               thread
                  {self.parentObj checkSize(self OldSize NewSize)}
               end
            end
         else true              % nothing to do;
         end
      end

      %%
      %%  for compound objects;
      meth updateSizes(Depth)
\ifdef DEBUG_TO
         {Show 'MetaTupleGenericTermObject::updateSizes: term '#self.term#Depth}
\endif
         case Depth == 0 then
            <<shrink>>
         else
            Width ActWidth ObjsList NewDepth ToRenewFlag
         in
            %%
            depth <- Depth

            %%  first phase: update width;
            Width = {Min
                     {self.store read(StoreWidth $)}
                     ({Length <<getSubterms($)>>} + 1)}
            ActWidth = @width

            %%
            case <<areCommas($)>> andthen ActWidth < Width then
               %%
               %%  kost@  22.11.95;
               %%  Now, since Tcl/Tk process (wish) behaves suspiciously
               %% under heavy loads (its performance depends *substantially*
               %% from the frequence of commands issued by the user!!!),
               %% i introduce *yet another hack*: :
               %%  If the difference between actual and shown sizes is
               %% bigger than the shown width, let's rebrowse!!!
               case Width - ActWidth > ActWidth then
                  ToRenewFlag = True
               else
                  <<ExpandWidthLoop(Width - ActWidth)>>
                  ToRenewFlag = False
               end
            else
               ToRenewFlag = False
            end

            %%
            case ToRenewFlag then
               %%
               thread
                  {self.parentObj renewNum(self Depth)}
               end
            else
               %% second phase: update depth of subterms;
               NewDepth = Depth - 1

               %%
               ObjsList = <<getObjsList($)>>
               {ForAll ObjsList
                proc {$ Obj}
                   {Obj updateSizes(NewDepth)}
                end}

               %%
               <<nil>>
            end
         end
      end
      %%
   end

   %%
   %%
   %%  Well-formed lists;
   %%
   class WFListGenericTermObject
      from MetaTupleGenericTermObject
      %%
      feat
         type: T_WFList
      %%
      %%
      meth otherwise(Message)
         {BrowserError ['WFListObject::' Message ' ???']}
      end
      %%
   end
   %%
   %%
   %%  Tuples;
   %%
   class TupleGenericTermObject
      from MetaTupleGenericTermObject
      %%
      feat
         type: T_Tuple
      %%
      %%
      %%
      meth otherwise(Message)
         {BrowserError ['TupleObject::' Message '???']}
      end
      %%
      %%
   end
   %%
   %%
   %%  Lists;
   %%
   class ListGenericTermObject
      from MetaTupleGenericTermObject
      %%
      feat
         type: T_List
      %%
      %%
      %%
      meth otherwise(Message)
         {BrowserError ['ListObject::' Message '???']}
      end
      %%
      %%
   end
   %%
   %%
   %%  Hash tuples;
   %%
   class HashTupleGenericTermObject
      from MetaTupleGenericTermObject
      %%
      feat
         type: T_HashTuple
      %%
      %%
      %%
      meth otherwise(Message)
         {BrowserError ['HashTupleObject::' Message '???']}
      end
      %%
      %%
   end
   %%
   %%
   %%  Flat Lists;
   %%
   class FListGenericTermObject
      from MetaTupleGenericTermObject
      %%
      feat
         type: T_FList
      %%
      %%
      %%  ... probably, we have got it from the last 'var' subterm --
      %% so, the flat list should be extended instead of modifying that
      %% subterm;
      meth renewNum(Obj Depth)
\ifdef DEBUG_TO
         {Show 'FListGenericTermObject::renewNum: term '#Obj.term#Obj.numberOf}
\endif
         local TailVarNum StoredObj ObjTerm CanBeExt in
            StoredObj = <<getSubtermObj(Obj.numberOf $)>>
            %%
            case Obj == StoredObj then
               TailVarNum = @tailVarNum
               ObjTerm = Obj.term
               CanBeExt = case {IsVar ObjTerm} then False
                          elsecase  {IsTuple ObjTerm} then
                             L
                          in
                             L = {Label ObjTerm} % no suspension;
                             case L == '|' orelse L == nil then True
                             else False
                             end
                          else False
                          end
               %%
               %%
               case
                  TailVarNum == Obj.numberOf andthen CanBeExt
               then
                  <<extend>>
               else
                  <<MetaTupleGenericTermObject renewNum(Obj Depth)>>
               end
            else true           % ignore irrelevant message;
            end
         end
      end
      %%
      %%  replace the tail variable with something;
      meth extend
\ifdef DEBUG_TO
         {Show 'FListGenericTermObject::extend: term '#self.term}
\endif
         case @shown then
            OldSubs OldSize NewSize NewSubs OldRest NewRest
            ActWidth NewWidth RemovedObj Depth
         in
            OldSubs = <<getSubterms($)>>
            Depth = @depth
            %%
            %% updates 'subterms' attribute in place;
            NewSubs = <<reGetSubterms($)>>
            %%
            case <<areCommas($)>> then
               case <<isFWList($)>> then
                  job
                     {self.parentObj renewNum(self Depth)}
                  end
               else
                  %%  width is already exceeded - nothing to do;
                  true
               end
            else
               ActWidth = @width
               %%
               {DiffRest OldSubs NewSubs OldRest NewRest}
               %%
               case {Length OldRest}
               of 1 then
                  %%
                  %%  first case: variable -> many (>1) subterms;
                  RemovedObj = <<getSubtermObj(ActWidth $)>>
                  %%
                  case <<isWFList($)>> then
                     job
                        {self.parentObj renewNum(self Depth)}
                     end
                  else
                     {RemovedObj [undraw destroy]}
                     %% remove the (former) tail variable's representation;

                     %%
                     OldSize = <<getSize($)>>

                     %%  ('1' is the number of subterms which slots
                     %% should be reused;)
                     %%  ('NewWidth' is an output argument;)
                     <<initMoreSubterms(ActWidth 1 NewRest NewWidth)>>

                     %%  ('NewWidth' is an input argument here;)
                     <<initMoreOutInfo((ActWidth + 1) NewWidth)>>

                     %%
                     <<drawNewSubterms(ActWidth NewWidth)>>

                     %%
                     case
                        NewWidth - ActWidth + 1 < {Length NewRest}
                        %% less subterms as available are shown;
                     then <<drawCommas>>
                     else true
                     end

                     %%
                     NewSize = <<getSize($)>>

                     %%
                     job
                        {self.parentObj checkSize(self OldSize NewSize)}
                     end
                  end
               [] 0 then
                  %%
                  %% second case: variable --> value (not another variable!);
                  %%
                  case <<isWFList($)>> then
                     job
                        {self.parentObj renewNum(self Depth)}
                     end
                  else
                     <<noTailVar>>

                     %%  Actually incorrect - it forces subterm's depth
                     %% to (@depth - 1);
                     <<MetaTupleGenericTermObject
                     renewNum(<<getSubtermObj(ActWidth $)>> (@depth - 1))>>
                  end
               else
                  %%
                  %%  Not optimized.
                  %% It could mean, for instance, that we have feeded
                  %% the following lines
                  %%   declare X in
                  %%   X = _|_|_
                  %%   X.2 = X.2.2
                  %%  This list is recursive, but not 'from the first cons';
                  %%
                  job
                     {self.parentObj renewNum(self Depth)}
                  end
               end
            end
         else
            Depth
         in
            Depth = @depth

            %%  if it's not shown - just create a new one;
            job
               {self.parentObj renewNum(self Depth)}
            end
         end
      end

      %%
      %%  Special op for expand: set the 'tailVar' and
      %% 'tailVarNum' attributes;
      meth expandWidthOne
         <<MetaTupleGenericTermObject expandWidthOne>>

         %%
         <<setTailVarNum(@width)>>
      end

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['FListObject::' Message '???']}
      end

      %%
   end

   %%
   %%
   %%  'Meta' object for compound (record-like) term objects;
   %%
   class MetaRecordGenericTermObject
      from MetaTupleGenericTermObject
      %%
      %%  inherited from 'MetaTupleGenericTermObject';
      %% attr
      %% refVarName:   ''       % prefix;
      %%
      %%  'createSubtermObjs', 'destroy', 'destroyChilds', 'getRefVar,'
      %% 'renewNum' and 'updateSizes' are inherited from
      %% 'MetaTupleGenericTermObject';
      %%
      %%
   end

   %%
   %%
   %%  Records;
   %%
   class RecordGenericTermObject
      from MetaRecordGenericTermObject
      %%
      feat
         type: T_Record

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['RecordObject::' Message '???']}
      end
      %%
      %%
   end

   %%
   %%
   %%  Open feature structures;
   %%
   class ORecordGenericTermObject
      from MetaRecordGenericTermObject
      %%
      feat
         type: T_ORecord

      %%
      %%  add new features;
      meth extend
\ifdef DEBUG_TO
         {Show 'ORecordGenericTermObject::extend: term '#self.term}
\endif
         case @shown then
            OldSubs OldSize NewSize NewSubs OldRest NewRest
            ActWidth NewStart NewWidth RemovedObj Depth
         in
            OldSubs = <<getSubterms($)>>
            Depth = @depth

            %% updates 'subterms' attribute in place;
            NewSubs = <<reGetSubterms($)>>

            %%
            case <<areCommas($)>> then
               case <<isProperOFS($)>> then
                  %%  width is already exceeded - nothing to do;
                  true
               else
                  case @width > 0 then
                     <<removeDots>>
                  else
                     {BrowserError
                      ['ORecordGenericTermObject::extend: error!']}
                  end
               end
            else
               ActWidth = @width

               %%
               {DiffRest OldSubs NewSubs OldRest NewRest}

               %%
\ifdef DEBUG_TO
               case {Length OldRest} == 0 then true
               else
                  {BrowserWarning ['ORecordGenericTermObject::extend: warning: OldRest != 0 !']}
                  %%  see beneath;
               end
\endif

               %%
               case {Length NewRest}
               of 0 then
                  %% OFS gets a proper record;

                  %%
                  case <<isProperOFS($)>> then
                     {BrowserError
                      ['ORecordGenericTermObject::extend: error #3!']}
                  else
                     case @width > 0 then
                        <<removeDots>>
                     else
                        %% should be simply a literal;

                        %%
                        job
                           {self.parentObj renewNum(self Depth)}
                        end
                     end
                  end
               else
                  %%

                  %%
                  case
                     @width > 0 andthen {Length OldRest} == 0
                     %%
                     %%  An interesting point:
                     %%  OldRest could be non-zero if somebody has
                     %% used 'SetC' (destructive modification on
                     %% records). That thing should not accessible to
                     %% anyone else except Peter Van Roy and
                     %% Martin Henz from PSL at DFKI;
                  then
                     OldSize = <<getSize($)>>

                     %%  additional features;
                     NewStart = ActWidth + 1

                     %%  ('0' is the number of subterms which slots
                     %% should be reused;)
                     %%  ('NewWidth' is an output argument;)
                     <<initMoreSubterms(NewStart 0 NewRest NewWidth)>>

                     %%  ('NewWidth' is an input argument here;)
                     <<initMoreOutInfo(NewStart NewWidth)>>

                     %%
                     <<drawNewSubterms(NewStart NewWidth)>>

                     %%
                     case
                        NewWidth - ActWidth < {Length NewRest}
                        %% less subterms as available are shown;
                     then <<drawCommas>>
                     else true
                     end

                     %%
                     NewSize = <<getSize($)>>

                     %%
                     job
                        {self.parentObj checkSize(self OldSize NewSize)}
                     end

                     %%  Actually, OFS could get proper record meanwhile;
                     case <<isProperOFS($)>> then true
                     else
                        <<removeDots>>
                        %% it update size by itself;
                     end
                  else
                     %%

                     %%
                     job
                        {self.parentObj renewNum(self Depth)}
                     end
                  end
               end
            end

            %%
            <<stopTypeWatching>>
            <<initTypeWatching>>
            %%
         else
            Depth
         in
            Depth = @depth

            %%  if it's not shown - just create new one;
            job
               {self.parentObj renewNum(self Depth)}
            end
         end
      end

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['ORecordObject::' Message '???']}
      end
      %%
   end

   %%
   %%
   %%  Meta-objects for chunks (not only, though) in various flavors;
   %%
   %%
   class MetaChunkGenericTermObject
      from NameGenericTermObject RecordGenericTermObject
      %%
      %%  'getObjClass' from MetaGenericTermObject;
      %%  'init' ...
      %%  'isShown' ...

      %%
      meth destroy
         case self.isCompound then
            <<RecordGenericTermObject destroy>>
         else
            <<NameGenericTermObject destroy>>
         end
      end

      %%
      meth retract
         case self.isCompound then
            <<RecordGenericTermObject retract>>
         else
            <<NameGenericTermObject retract>>
         end
      end

      %%
      %%
      meth updateSizes(Depth)
         case self.isCompound then
            <<RecordGenericTermObject updateSizes(Depth)>>
         else
            <<NameGenericTermObject updateSizes(Depth)>>
         end
      end

      %%
      %%  event handlers from 'MetaGenericTermObject';
      %%  'show' ...
      %%
      meth expand
         case self.isCompound then
            <<RecordGenericTermObject expand>>
         else
            <<NameGenericTermObject expand>>
         end
      end
      %%
      %%  'shrink' from 'MetaGenericTermObject';
      %%  'deref' ...
      %%
      meth getRefVar(Obj)
         case self.isCompound then
            <<RecordGenericTermObject getRefVar(Obj)>>
         else
            <<NameGenericTermObject getRefVar(Obj)>>
         end
      end
      %%
   end
   %%
   %%
   %%
   %%  Procedures;
   %%
   class ProcedureGenericTermObject
      from MetaChunkGenericTermObject
      %%
      feat
         type: T_Procedure
      %%
      %%
      %%
      meth otherwise(Message)
         {BrowserError ['ProcedureObject::' Message '???']}
      end
      %%
      %%
   end
   %%
   %%
   %%
   %%  Cells;
   %%
   class CellGenericTermObject
      from MetaChunkGenericTermObject
      %%
      feat
         type: T_Cell
      %%
      %%
      %%
      meth otherwise(Message)
         {BrowserError ['CellObject::' Message '???']}
      end
      %%
      %%
   end
   %%
   %%
   %%
   %%  Objects;
   %%
   class ObjectGenericTermObject
      from MetaChunkGenericTermObject
      %%
      feat
         type: T_Object
      %%
      %%
      %%
      meth otherwise(Message)
         {BrowserError ['ObjectObject::' Message '???']}
      end
      %%
      %%
   end
   %%
   %%
   %%
   %%  Classes;
   %%
   class ClassGenericTermObject
      from MetaChunkGenericTermObject
      %%
      feat
         type: T_Class
      %%
      %%
      %%
      meth otherwise(Message)
         {BrowserError ['ClassObject::' Message '???']}
      end
      %%
      %%
   end
   %%
   %%
   %%
   %%  Various special term objects;
   %%
   %%
   %%  Variables;
   %%
   class VariableGenericTermObject
      from MetaGenericTermObject
      %%
      %%
      feat
         type: T_Variable
      %%
      attr
         refVarName:   ''       % prefix;
      %%
      %%
      meth getRefVar(Obj)
\ifdef DEBUG_TO
         {Show 'VariableGenericTermObject::getRefVar: term '#self.term}
\endif
         case @refVarName == '' then
            local RefNumber Ref OldSize NeedBraces in
               RefNumber = {NewRefNameGen gen($)}
               Ref = self.termsStore.refType#RefNumber
               refVarName <- Ref
               %%
               {Obj setRefVar(self Ref)}
               %%
               <<insertRefVar>>
            end
         else
            {Obj setRefVar(self @refVarName)}
         end
         %%
      end

      %%
      %%  perform 'retract' in addition;
      meth destroy
         <<MetaGenericTermObject destroy>>

         %%
         <<retract>>
      end

      %%
      %%
      meth retract
\ifdef DEBUG_TO
         {Show
          'VariableGenericObject::retract method for the term '#self.term}
\endif
         {self.termsStore retract(self)}

         %%
         refVarName <- ''
      end

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['VariableObject::' Message '???']}
      end

      %%
   end

   %%
   %%
   %%  Finite domain variables;
   %%
   class FDVariableGenericTermObject
      from MetaGenericTermObject
      %%
      %%
      feat
         type: T_FDVariable

      %%
      attr
         refVarName:   ''       % prefix;

      %%
      %%
      meth getRefVar(Obj)
\ifdef DEBUG_TO
         {Show 'FDVariableGenericTermObject::getRefVar: term '#self.term}
\endif
         case @refVarName == '' then
            RefNumber Ref OldSize NeedBraces
         in
            RefNumber = {NewRefNameGen gen($)}
            Ref = self.termsStore.refType#RefNumber
            refVarName <- Ref

            %%
            {Obj setRefVar(self Ref)}

            %%
            <<insertRefVar>>
         else
            {Obj setRefVar(self @refVarName)}
         end
      end

      %%
      %%  perform 'retract' in addition;
      meth destroy
         <<MetaGenericTermObject destroy>>

         %%
         <<retract>>
      end

      %%
      %%
      meth retract
\ifdef DEBUG_TO
         {Show
          'FDVariableGenericObject::retract method for the term '#self.term}
\endif
         {self.termsStore retract(self)}
         %%
         refVarName <- ''
      end

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['FDVariableObject::' Message '???']}
      end

      %%
   end

   %%
   %%
   %%  Meta variables;
   %%
   class MetaVariableGenericTermObject
      from MetaGenericTermObject
      %%
      %%
      feat
         type: T_MetaVariable

      %%
      attr
         refVarName:   ''       % prefix;

      %%
      %%
      meth getRefVar(Obj)
\ifdef DEBUG_TO
         {Show 'MetaVariableGenericTermObject::getRefVar: term '#self.term}
\endif
         case @refVarName == '' then
            RefNumber Ref OldSize NeedBraces
         in
            RefNumber = {NewRefNameGen gen($)}
            Ref = self.termsStore.refType#RefNumber
            refVarName <- Ref

            %%
            {Obj setRefVar(self Ref)}

            %%
            <<insertRefVar>>
         else
            {Obj setRefVar(self @refVarName)}
         end
      end

      %%
      %%  perform 'retract' in addition;
      meth destroy
         <<MetaGenericTermObject destroy>>

         %%
         <<retract>>
      end

      %%
      %%
      meth retract
\ifdef DEBUG_TO
         {Show
          'MetaVariableGenericObject::retract method for the term '#self.term}
\endif
         {self.termsStore retract(self)}

         %%
         refVarName <- ''
      end

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['MetaVariableObject::' Message '???']}
      end
      %%
   end

   %%
   %%
   %%  References;
   %%
   class ReferenceGenericTermObject
      from MetaGenericTermObject
      %%
      %%
      feat
         type: T_Reference

      %%
      attr
         master: InitValue      % reference to a 'master' copy;

      %%
      %%
      meth shrink
         true                   % cannot be shrunken;
      end

      %%
      %%
      meth deref
         local Master in
            Master = @master

            %%
            case Master == InitValue then true
               %% i.e. cannot yet deref - simply ignore it;
            else
               {Master pickPlace}
            end
         end
      end

      %%
      %%
      meth checkRef
\ifdef DEBUG_TO
         {Show 'ReferenceGenericTermObject::checkRef for ref term '#self.term}
\endif
         Depth
      in
         Depth = @depth

         %%
         job
            {self.parentObj renewNum(self Depth)}
         end
      end

      %%
      %%  STATELESS METHOD !!!
      meth watchMaster(MasterObj)
         case {Object.closed MasterObj} then
            {self checkRef}
         end
      end

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['ReferenceObject::' Message ' ???']}
      end

      %%
   end

   %%
   %%
   %%  Shrunken subterms (because of 'Depth' limit);
   %%
   class ShrunkenGenericTermObject
      from MetaGenericTermObject
      %%
      feat
         type: T_Shrunken

      %%
      %%  for shrunken subterms;
      meth updateSizes(Depth)
         %%
         thread
            {self.parentObj renewNum(self Depth)}
         end
      end

      %%
      %%
      meth expand
         local DepthInc in
            DepthInc = {self.store read(StoreDepthInc $)}

            %%
            job
               {self.parentObj renewNum(self DepthInc)}
            end
         end
      end

      %%
      %%
      meth shrink
         true                   % overwrite proper 'shrink';
      end

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['ShrunkenObject::' Message '???']}
      end
      %%
   end

   %%
   %%
   %%  Unknown term;
   %%
   class UnknownGenericTermObject
      from MetaGenericTermObject
      %%
      feat
         type: T_Unknown

      %%
      %%
      meth otherwise(Message)
         {BrowserError ['UnknownObject::' Message '???']}
      end
      %%
   end

   %%
   %%
   %% Compare two lists and yield their different tail lists;
   %%
   proc {DiffRest L1 L2 ?LOut1 ?LOut2}
      %%
      %% relational;
      if {Subtree L1 1} = {Subtree L2 1} then
         {DiffRest L1.2 L2.2 LOut1 LOut2}
      [] true then
         LOut1 = L1
         LOut2 = L2
      fi
   end
   %%
   %%

%%%
%%%
%%%  Object classes declarations;
%%%
   %%
   class AtomTermObject
      from
         AtomGenericTermObject AtomTermTermObject AtomTWTermObject
\ifdef FEGRAMED
         FE_AtomObject
\endif
   end

   %%
   class IntTermObject
      from
         IntGenericTermObject IntTermTermObject IntTWTermObject
\ifdef FEGRAMED
         FE_IntObject
\endif
   end

   %%
   class FloatTermObject
      from
         FloatGenericTermObject FloatTermTermObject FloatTWTermObject
\ifdef FEGRAMED
         FE_FloatObject
\endif
   end

   %%
   class NameTermObject
      from
         NameGenericTermObject NameTermTermObject NameTWTermObject
\ifdef FEGRAMED
         FE_NameObject
\endif
   end

   %%
   class ProcedureTermObject
      from
         ProcedureGenericTermObject ProcedureTermTermObject ProcedureTWTermObject
\ifdef FEGRAMED
         FE_ProcedureObject
\endif
   end

   %%
   class CellTermObject
      from
         CellGenericTermObject CellTermTermObject CellTWTermObject
\ifdef FEGRAMED
         FE_CellObject
\endif
   end

   %%
   class ObjectTermObject
      from
         ObjectGenericTermObject ObjectTermTermObject ObjectTWTermObject
\ifdef FEGRAMED
         FE_ObjectObject
\endif
   end

   %%
   class ClassTermObject
      from
         ClassGenericTermObject ClassTermTermObject ClassTWTermObject
\ifdef FEGRAMED
         FE_ClassObject
\endif
   end

   %%
   class WFListTermObject
      from
         WFListGenericTermObject WFListTermTermObject WFListTWTermObject
\ifdef FEGRAMED
         FE_WFlistObject
\endif
   end

   %%
   class TupleTermObject
      from
         TupleGenericTermObject TupleTermTermObject TupleTWTermObject
\ifdef FEGRAMED
         FE_TupleObject
\endif
   end

   %%
   class RecordTermObject
      from
         RecordGenericTermObject RecordTermTermObject RecordTWTermObject
\ifdef FEGRAMED
         FE_RecordObject
\endif
   end

   %%
   class ORecordTermObject
      from
         ORecordGenericTermObject ORecordTermTermObject ORecordTWTermObject
\ifdef FEGRAMED
         FE_ORecord
\endif
   end

   %%
   class ListTermObject
      from
         ListGenericTermObject ListTermTermObject ListTWTermObject
\ifdef FEGRAMED
         FE_ListObject
\endif
   end

   %%
   class FListTermObject
      from
         FListGenericTermObject FListTermTermObject FListTWTermObject
\ifdef FEGRAMED
         FE_FListObject
\endif
   end

   %%
   class HashTupleTermObject
      from
         HashTupleGenericTermObject HashTupleTermTermObject HashTupleTWTermObject
\ifdef FEGRAMED
         FE_HashTupleObject
\endif
   end

   %%
   class VariableTermObject
      from
         VariableGenericTermObject VariableTermTermObject VariableTWTermObject
\ifdef FEGRAMED
         FE_VariableObject
\endif
   end

   %%
   class FDVariableTermObject
      from
         FDVariableGenericTermObject FDVariableTermTermObject FDVariableTWTermObject
\ifdef FEGRAMED
         FE_FDVariableObject
\endif
   end

   %%
   class MetaVariableTermObject
      from
         MetaVariableGenericTermObject MetaVariableTermTermObject MetaVariableTWTermObject
\ifdef FEGRAMED
         FE_FDVariableObject
\endif
   end

   %%
   class ShrunkenTermObject
      from
         ShrunkenGenericTermObject ShrunkenTermTermObject ShrunkenTWTermObject
\ifdef FEGRAMED
         FE_ShrunkenObject
\endif
   end

   %%
   class ReferenceTermObject
      from
         ReferenceGenericTermObject ReferenceTermTermObject ReferenceTWTermObject
\ifdef FEGRAMED
         FE_ReferenceObject
\endif
   end

   %%
   class UnknownTermObject
      from
         UnknownGenericTermObject UnknownTermTermObject UnknownTWTermObject
\ifdef FEGRAMED
         FE_UnknownObject
\endif
   end

%%%
%%%
%%%  Local auxiliary stuff;
%%%
   %%
   %%
   %%
   %%  Generator of new reference names;
   %%
   create NewRefNameGen from UrObject
      %%
      attr number: 1

      %%
      %%
      meth gen(?Number)
         Number = @number
         number <- @number + 1
      end

      %%
      %%  Special method: get the length of the current reference;
      %%  We use it by the calculating of MetaSize;
      meth getLen(?Len)
         Len = {VSLength @number}
      end
   end

   %%
end
