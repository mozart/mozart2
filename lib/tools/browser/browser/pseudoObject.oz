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
%%%  'pseudo' objects;
%%%
%%%
%%%
%%%

%%
%%  Pseudo-term object (generic part);
%%  They are used by the 'browser' objects, i.e.
%% they encapsulate all internal 'checkType' and 'checkSize' transactions;
class PseudoTermGenericObject
   from MetaGenericTermObject MetaTermTermObject
\ifdef FEGRAMED
      FE_PseudoTermObject
\endif
   %%
   %%
   %%
   feat
      repType                   %
      type:   T_PSTerm          %
   %%
   %%
   attr
      mark: InitValue           % probably compound structure;
      termObj: InitValue
   %%
   %%
   meth init(repType: RepType
             widgetObj: WidgetObj
             depth: Depth
             term: Term
             store: Store
             termsStore: TermsStore
             browserObj: BrowserObj)
\ifdef DEBUG_TO
      {Show 'PTO::init: is applied: '#Term}
\endif
      %%
      case
         {IsValue RepType} andthen
         {IsValue WidgetObj} andthen
         {IsValue Depth} andthen
         {IsValue Store} andthen
         {IsValue TermsStore} andthen
         {IsValue BrowserObj}
      then
         %%  These values must be already instantiated!
         %%  We avoid this way such checking in term object's methods;
         %%
         self.repType = RepType
         %%
         self.term = Term
         self.numberOf = InitValue
         self.parentObj = InitValue
         self.widgetObj = WidgetObj
         self.store = Store
         self.termsStore = TermsStore
         self.browserObj = BrowserObj
         %%
         shown <- False
         depth <- Depth + 1     % meta-depth;
         %%
         <<InitObj(repType: RepType
                   widgetObj: WidgetObj
                   depth: Depth
                   term: Term
                   store: Store
                   termsStore: TermsStore
                   browserObj: BrowserObj)>>
         %%
      else
         {BrowserError ['PseudoTermObject::init: not In_Text_Widget?']}
      end
   end
   %%
   %%
   meth InitObj(repType: RepType
                widgetObj: WidgetObj
                depth: Depth
                term: Term
                store: Store
                termsStore: TermsStore
                browserObj: BrowserObj)
      %%
\ifdef DEBUG_TO
      {Show '... PTO::InitObj: is applied'}
\endif
      case RepType
      of !In_Text_Widget then
         local TermType EQCheck ObjClass TermObj RefObj in
            %%
            <<getTermType(Term 1 TermType)>>
            %%
            {self.termsStore needsCheck(TermType EQCheck)}
            case EQCheck then
               {self.termsStore checkANDStore(self Term TermObj RefObj)}
               %%
               case RefObj == InitValue then
                  %% none found -- proceed;
                  <<getObjClass(TermType ObjClass)>>
                  %%
               else
                  {BrowserError
                   ['PseudoTermObject::init: terms store is not empty?']}
                  ObjClass = UnknownTermObject
               end
            else
               <<getObjClass(TermType ObjClass)>>
            end
            %%
            TermObj = {New ObjClass init(term: Term
                                         depth: Depth
                                         numberOf: 1
                                         parentObj: self
                                         widgetObj: WidgetObj
                                         store: Store
                                         termsStore: TermsStore
                                         browserObj: BrowserObj)}
            %%
            termObj <- TermObj
         end
      end
   end
   %%
   %%
   meth destroy(?Sync)
      local TermObj in
         TermObj = @termObj
         %%
         case
            TermObj \= InitValue andthen
            {IsValue {@termObj destroy($)}}
         then
            %%
            <<MetaGenericTermObject destroy(Sync)>>
         end
      end
   end
   %%
   %%
   meth draw(?Sync)
\ifdef DEBUG_TO
      {Show 'PTO::draw: is applied: '#self.term}
\endif
      %%
      case self.repType
      of !In_Text_Widget then
         local Mark IsScrolling in
            case @mark == InitValue then
               %%  in a text widget a '\n' character is inserted after
               %% the term's representation;
               <<putNL(Mark)>>
            else
               Mark = @mark
            end
            %%
            {@termObj draw(Mark Sync)}
            case {IsValue Sync} then
               %%
               shown <- True
               %%
               IsScrolling = {self.store read(StoreScrolling $)}
               case IsScrolling then
                  <<scrollToTag(@termObj.tag)>>
               else true
               end
            end
         end
      else
         {BrowserError ['PseudoObject::draw: unknown representation type']}
         Sync = True
      end
   end
   %%
   %%
   meth undraw(?Sync)
\ifdef DEBUG_TO
      {Show 'PTO::undraw: is applied: '#self.term}
\endif
      %%
      case self.repType
      of !In_Text_Widget then
         %%
         {@termObj undraw(Sync)}
         case {IsValue Sync} then
            shown <- False
            <<delNL>>
         end
      else
         {BrowserError ['PseudoObject::undraw: unknown representation type']}
         Sync = True
      end
   end
   %%
   %%
   meth updateSizes(Depth Sync)
\ifdef DEBUG_TO
      {Show 'PTO::updateSizes: is applied: '#self.term}
\endif
      %%
      case self.repType
      of !In_Text_Widget then
         case {IsValue {@termObj updateSizes(Depth $)}}
         then
            Sync = True
            <<nil>>
         end
      else
         {BrowserError ['PseudoObject::updateSizes: unknown representation type']}
         Sync = True
      end
   end
   %%
   %%
   meth checkLayout(Sync)
\ifdef DEBUG_TO
      {Show 'PTO::checkLayout: is applied: '#self.term}
\endif
      %%
      case self.repType
      of !In_Text_Widget then
         case {IsValue {@termObj checkLayout($)}} then
            Sync = True
            <<nil>>
         end
      else
         {BrowserError ['PseudoObject::checkLayout: unknown representation type']}
         Sync = True
      end
   end
   %%
   %%
   %%   ... and now - method(s), acepted from term objects;
   %%
   meth renewNum(Obj Depth)
\ifdef DEBUG_TO
      {Show 'PTO::renewNum: is applied, subterm# '#
       Obj.numberOf#': '#self.term}
\endif
      %%
      case Obj == @termObj then
         local IsScrolling WasShown in
            %%
            case
               {IsValue {@termObj [isShown(WasShown)
                                    undraw(_)
                                    destroy($)]}}
            then
               %%
               depth <- Depth + 1
               %%
               <<InitObj(repType: self.repType
                         widgetObj: self.widgetObj
                         depth: Depth
                         term: self.term
                         store: self.store
                         termsStore: self.termsStore
                         browserObj: self.browserObj)>>
               %%
               %%  new '@termObj';
               case WasShown then
                  case {IsValue {@termObj draw(@mark $)}} then
                     %%
                     IsScrolling = {self.store read(StoreScrolling $)}
                     case IsScrolling then
                        <<scrollToTag(@termObj.tag)>>
                     else true
                     end
                  end
               else true
               end
            end
         end
      else true                 % ignore - garbage;
      end
   end
   %%
end
%%
%%
class PseudoTermObject
   from PseudoTermGenericObject PseudoTermTWObject
end
%%
%%
