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
%%%   Internal browser process, which actually does the work;
%%%
%%%
%%%

local
   DoCheckLayout
in
   %%
   proc {DoCheckLayout TermObj}
      {TermObj CheckLayout}
   end

   %%
   %%
   %%
   class BrowserManagerClass from WindowManagerClass
      %%

      %%
      feat
         store         %
         browserObj    %
         Stream        % requests stream that is served;
         GetTermObjs   % yields a current list of (shown) term objects;

      %%
      %% 'close' is inherited from Object.base;
      meth init(store:          StoreIn
                getTermObjsFun: GetTermObjsIn)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::init is applied'}
\endif
         %%
         self.store = StoreIn
         self.browserObj = {StoreIn read(StoreBrowserObj $)}
         self.Stream = {StoreIn read(StoreStreamObj $)}
         self.GetTermObjs = GetTermObjsIn

         %%
         WindowManagerClass , initWindow

         %%
         %% Start up;
         thread
            {self ServeRequest}
         end
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::init is finished'}
\endif
      end

      %%
      meth close
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::close is applied'}
\endif
         WindowManagerClass , closeWindow
         Object.base , close
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::close is finished'}
\endif
      end

      %%
      %%
      meth ServeRequest
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::ServeRequest ...'}
\endif
         %%
         local Req in
            %%
            case {self.Stream deq(Req $)} then
               %% Got one - process it.
\ifdef DEBUG_MO
               {Show 'BrowserManagerClass::ServeRequest: got it!'}
\endif
               %%
               %% The convension is that a request is just a manager
               %% object's method;
               BrowserManagerClass , Req
            else
               %% is empty at the moment - do 'idle' step and sleep for
               %% a while;
               BrowserManagerClass , DoIdle

               %%
               WindowManagerClass , entriesDisable([break])
               {self.Stream waitElement}

               %%
               %% new request;
               WindowManagerClass , entriesEnable([break])
               {self.store store(StoreBreak False)}
            end

            %%
            %% either a new request, or nothing if the last one was
            %% 'close';
            BrowserManagerClass , ServeRequest
         end
      end

      %%
      %% Currently two things are to do during idle:
      %% (a) check layouts
      %% (b) drop the 'break' mode;
      meth DoIdle
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::DoIdle ...'}
\endif
         %%
         {ForAll {self.GetTermObjs} DoCheckLayout}
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::DoIdle ... done!'}
\endif
      end

      %%
      %% Window-specific operations from the 'WindowManagerClass' (But
      %% not only, if necessary);
      meth sync($) Unit end

      %%
      %% "Proper" browse method;
      %%
      %% Don't care ubout undraw, history, etc. - just draw it at the
      %% end of the text widget;
      meth browse(TermIn ?TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::browse is applied'#TermIn}
\endif
         local SeqNum in
            %% check whether we still have to create it;
            WindowManagerClass , createWindow

            %%
            SeqNum = {self.store read(StoreSeqNum $)}
            {self.store store(StoreSeqNum (SeqNum + 1))}

            %%
            TermObj = {New RootTermObject
                       Make(widgetObj:  @window
                            term:       TermIn
                            store:      self.store
                            seqNumber:  SeqNum)}
         end

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::browse is finished'}
\endif
         touch
      end

      %%
      meth checkTerm(Obj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::checkTerm is applied'}
\endif
         {Obj CheckTerm}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::checkTerm is finished'}
\endif
         touch
      end

      %%
      meth subtermSizeChanged(Obj ChildObj OldSize NewSize)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::subtermSizeChanged is applied'}
\endif
         {Obj SubtermSizeChanged(ChildObj OldSize NewSize)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::subtermSizeChanged is finished'}
\endif
         touch
      end

      %%
      meth setRefName(ReferenceObj MasterObj RefName)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::setRefName is applied'}
\endif
         {ReferenceObj SetRefName(MasterObj RefName)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::setRefName is finished'}
\endif
         touch
      end

      %%
      meth genRefName(Obj ReferenceObj Type)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::genRefName is applied'}
\endif
         {Obj GenRefName(ReferenceObj Type)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::genRefName is finished'}
\endif
         touch
      end

      %%
      meth subtermChanged(Obj ChildObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::subtermChanged is applied'}
\endif
         {Obj SubtermChanged(ChildObj)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::subtermChanged is finished'}
\endif
         touch
      end

      %%
      meth changeDepth(Obj ChildObj NewDepth)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::changedDepth is applied'}
\endif
         {Obj ChangeDepth(ChildObj NewDepth)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::changedDepth is finished'}
\endif
         touch
      end

      %%
      %%
      meth undraw(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::undraw is applied'}
\endif
         {TermObj Close}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::undraw is finished'}
\endif
         touch
      end

      %%
      %%
      meth expandWidth(TermObj WidthInc)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::expandWidth is applied'}
\endif
         {TermObj ExpandWidth(WidthInc)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::expandWidth is finished'}
\endif
         touch
      end

      %%
      %%
      meth expand(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::expand is applied'}
\endif
         {TermObj Expand}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::expand is finished'}
\endif
         touch
      end

      %%
      %%
      meth shrink(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::shrink is applied'}
\endif
         {TermObj Shrink}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::shrink is finished'}
\endif
         touch
      end

      %%
      %%
      meth deref(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::deref is applied'}
\endif
         {TermObj Deref}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::deref is finished'}
\endif
         touch
      end

      %%
      %%
      meth updateSize(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::updateSize is applied'}
\endif
         {TermObj UpdateSize}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::updateSize is finished'}
\endif
         touch
      end

      %%
      %%
      meth checkLayout(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::checkLayout is applied'}
\endif
         {DoCheckLayout TermObj}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::checkLayout is finished'}
\endif
         touch
      end

      %%
      %%
      meth checkLayoutReq(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::checkLayoutReq is applied'}
\endif
         {TermObj CheckLayoutReq}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::checkLayoutReq is finished'}
\endif
         touch
      end

      %%
      %% 'Obj' is a term object which is supposed to be the target.
      %% 'Handler' is a term object's method which has to handle the
      %% event;
      %% 'Arg' is an atom - '1','2','3' (button number);
      %%
      meth processEvent(Obj Handler Arg)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::processEvent is applied'
          # Obj # Handler # Arg}
\endif
         %%
         case Obj == InitValue then true
\ifdef DEBUG_MO
            {BrowserWarning 'BrowserManagerClass::processEvent: no handler?'}
\endif
         else {Obj Handler(Arg)}
         end

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::processEvent is finished'}
\endif
         touch
      end

      %%
   end

   %%
end
