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
   %%
   proc {DoCheckLayout TermObj}
      {TermObj CheckLayout}
   end

   %%
   %% Waits until the 'Thr' becomes blocked;
   proc {ThreadSync Thr}
      case {Thread.state Thr} == blocked then skip
      else
         {Thread.preempt {Thread.this}} % yet delay?
         {ThreadSync Thr}
      end
   end
in

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
         % Object.closable , close
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
         case MyClosableObject , isClosed($) then skip
         else Req in
            %%
            case {self.Stream deq(Req $)} then
               %% Got one - process it.
\ifdef DEBUG_MO
               {Show 'BrowserManagerClass::ServeRequest: got it!'}
\endif
               %%
               try
                  %%
                  %% The convension is that a request is just a manager
                  %% object's method;
                  BrowserManagerClass , Req
               catch BEx(_) then skip
               end
            else ManagerThr in
               ManagerThr = {Thread.this}
               %% is empty at the moment - do 'idle' step and sleep for
               %% a while;
               BrowserManagerClass , DoIdle

               %%
               WindowManagerClass , entriesDisable([break pause])

               %%
               %% Now, spawn off a thread which will check whether
               %% we really don't have any elements in the stream!
               thread
                  %%
                  {ThreadSync ManagerThr}

                  %%
                  %% Now, the 'manager' thread at least *was* blocked
                  %% (or it is still blocked). So, bombing it with the
                  %% 'noop' can be redundant but seems to be the only
                  %% way to make things really working;
                  case {self.Stream getSize($)} > 0
                  then {self.Stream enq(noop)} % my kludge ;-)
                  else skip
                  end
               end
               {self.Stream waitElement}

               %%
               %% new request;
               WindowManagerClass , entriesEnable([break])
               {self.store store(StoreBreak false)}
            end

            %%
            %% either a new request, or nothing if the last one was
            %% 'close';
            BrowserManagerClass , ServeRequest
         end
      end

      %%
      meth CheckObj(Obj)
         case
            MyClosableObject , isClosed($) orelse  % discard everthing!
            {Obj isClosed($)}
         then {Raise BEx(general)}
         else skip
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
      meth sync($) unit end

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
      end

      %%
      meth noop skip end

      %%
      meth pick(Obj Where How)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::pick is applied'}
\endif
         %% 'Obj' is a root term object;
         BrowserManagerClass , CheckObj(Obj)
         {Obj pickPlace(Where How)}
      end

      %%
      meth checkTerm(Obj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::checkTerm is applied'}
\endif
         BrowserManagerClass , CheckObj(Obj)
         {Obj CheckTerm}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::checkTerm is finished'}
\endif
      end

      %%
      meth subtermSizeChanged(Obj ChildObj OldSize NewSize)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::subtermSizeChanged is applied'}
\endif
         BrowserManagerClass , CheckObj(Obj)
         {Obj SubtermSizeChanged(ChildObj OldSize NewSize)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::subtermSizeChanged is finished'}
\endif
      end

      %%
      meth setRefName(ReferenceObj MasterObj RefName)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::setRefName is applied'}
\endif
         BrowserManagerClass , CheckObj(ReferenceObj)
         {ReferenceObj SetRefName(MasterObj RefName)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::setRefName is finished'}
\endif
      end

      %%
      meth genRefName(Obj ReferenceObj Type)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::genRefName is applied'}
\endif
         BrowserManagerClass , CheckObj(Obj)
         {Obj GenRefName(ReferenceObj Type)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::genRefName is finished'}
\endif
      end

      %%
      meth subtermChanged(Obj ChildObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::subtermChanged is applied'}
\endif
         BrowserManagerClass , CheckObj(Obj)
         {Obj SubtermChanged(ChildObj)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::subtermChanged is finished'}
\endif
      end

      %%
      meth changeDepth(Obj ChildObj NewDepth)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::changedDepth is applied'}
\endif
         BrowserManagerClass , CheckObj(Obj)
         {Obj ChangeDepth(ChildObj NewDepth)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::changedDepth is finished'}
\endif
      end

      %%
      %%
      meth undraw(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::undraw is applied'}
\endif
         BrowserManagerClass , CheckObj(TermObj)
         {TermObj Close}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::undraw is finished'}
\endif
      end

      %%
      %%
      meth expandWidth(TermObj WidthInc)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::expandWidth is applied'}
\endif
         BrowserManagerClass , CheckObj(TermObj)
         {TermObj ExpandWidth(WidthInc)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::expandWidth is finished'}
\endif
      end

      %%
      %%
      meth expand(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::expand is applied'}
\endif
         BrowserManagerClass , CheckObj(TermObj)
         {TermObj Expand}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::expand is finished'}
\endif
      end

      %%
      %%
      meth shrink(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::shrink is applied'}
\endif
         BrowserManagerClass , CheckObj(TermObj)
         {TermObj Shrink}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::shrink is finished'}
\endif
      end

      %%
      %%
      meth deref(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::deref is applied'}
\endif
         BrowserManagerClass , CheckObj(TermObj)
         {TermObj Deref}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::deref is finished'}
\endif
      end

      %%
      %%
      meth updateSize(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::updateSize is applied'}
\endif
         BrowserManagerClass , CheckObj(TermObj)
         {TermObj UpdateSize}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::updateSize is finished'}
\endif
      end

      %%
      %%
      meth checkLayout(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::checkLayout is applied'}
\endif
         BrowserManagerClass , CheckObj(TermObj)
         {DoCheckLayout TermObj}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::checkLayout is finished'}
\endif
      end

      %%
      %%
      meth checkLayoutReq(TermObj)
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::checkLayoutReq is applied'}
\endif
         BrowserManagerClass , CheckObj(TermObj)
         {TermObj CheckLayoutReq}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::checkLayoutReq is finished'}
\endif
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
         BrowserManagerClass , CheckObj(Obj)
         {Obj Handler(Arg)}

         %%
\ifdef DEBUG_MO
         {Show 'BrowserManagerClass::processEvent is finished'}
\endif
      end

      %%
   end

   %%
end
