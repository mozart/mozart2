%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                                                      %%
%% QTk                                                                  %%
%%                                                                      %%
%%  (c) 2000 Université catholique de Louvain. All Rights Reserved.     %%
%%  The development of QTk is supported by the PIRATES project at       %%
%%  the Université catholique de Louvain.  This file is subject to the  %%
%%  general Mozart license.                                             %%
%%                                                                      %%
%%  Author: Donatien Grolaux                                            %%
%%                                                                      %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

functor

import
   Tk
   QTkDevel(splitParams:        SplitParams
            condFeat:           CondFeat
            tkInit:             TkInit
            assert:             Assert
            execTk:             ExecTk
            returnTk:           ReturnTk
            qTkClass:           QTkClass
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget)

export
   WidgetType
   Feature
   QTkShared


define

   WidgetType=label
   Feature=false


   class QTkLabel

      feat
         Return
         widgetType:label
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(1:free
                           coordinator:free)}
                    uninit:r(1:unit)
                    unset:{Record.adjoin GlobalUnsetType
                           r(init:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(init:unit
                             bitmap:unit
                             image:unit
                             font:unit)}
                   )
         Description
         Coordinator

      from Tk.frame QTkClass

      meth shared(...)=M
         lock
            A B
         in
            QTkClass,{Record.adjoin M init}
            self.Return={CondFeat M return _}
            {SplitParams M [coordinator] A B}
            Tk.frame,{Record.adjoin {TkInit A}}
            self.Descriptor=1
            if
            self.Coordinator=M.coordinator
         end
      end

      meth getDescription($)
         self.Descriptor
      end

      meth getCoordinator($)
         self.Coordinator
      end

   end

   {RegisterWidget r(widgetType:shared
                     feature:false
                     qTkShared:QTkShared)}

   class SyncPolicy
      feat
         Handle
         Synchronizator

      meth init(handle:H)
         self.Handle=H
         if self.
         skip
      end

      meth call(M)
         {self M}
      end

      meth set(...)=M
         skip
      end

      meth otherwise(M)
         {self.Handle M}
      end

   end

   class TokenPolicy
      feat Handle
      meth init(handle:Handle)
         skip
      end
   end


   %%   {QTk.build td(shared(button(text:"Hello world")
   %%                        coordinator:SyncPolicy
   %%                        globalhandle:SharedButton))}

   %%   {QTk.build td(shared({SharedButton getDescription($)}
   %%                        globalhandle:SharedButton)))}

   class GlobalHandle

      feat Coordinator

      meth init(coordinator:C)
         skip
      end

      meth addLocalHandle(H)
         skip
      end

      meth getHandleList(M)
         skip
      end

      meth otherwise(M)
         {self.Coordinator call(M)}
      end

   end

end
