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
            qTkClass:           QTkClass
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget)

export
   WidgetType
   Feature
   QTkScale

define

   WidgetType=scale
   Feature=false

   class QTkScale

      feat
         Return TkVar
         widgetType:WidgetType
         action
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(1:float
                           init:float
                           return:free
                           activebackground:color
                           background:color bg:color
                           borderwidth:pixel
                           cursor:cursor
                           font:font
                           foreground:color fg:color
                           highlightbackground:color
                           highlightcolor:color
                           highlightthickness:pixel
                           relief:relief
                           repeatdelay:natural
                           repeatinterval:natural
                           takefocus:boolean
                           troughcolor:color
                           bigincrement:float
                           digits:natural
                           'from':float
                           label:vs
                           length:pixel
                           resolution:float
                           showvalue:boolean
                           sliderlength:pixel
                           sliderrelief:relief
                           state:[normal active disabled]
                           tickinterval:float
                           to:float
                           width:pixel
                           action:action
                          )}
                    uninit:r(1:unit)
                    unset:{Record.adjoin GlobalUnsetType
                           r(init:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(init:unit
                             bitmap:bitmap
                             font:font)}
                   )

      from Tk.scale QTkClass

      meth Scale(M Orient)
         lock
            A B P
         in
            QTkClass,{Record.adjoin M init}
            P={self.action get($)}
            {self.action set(proc{$} skip end)}
            self.Return={CondFeat M return _}
            {SplitParams M [init] A B}
            self.TkVar={New Tk.variable tkInit({CondFeat B init 0.0})}
            Tk.scale,{Record.adjoin {TkInit A} tkInit(action:self.toplevel.port#r(self Execute)
                                                      variable:self.TkVar
                                                      orient:Orient
                                                     )}
            {self.action set(P)}
         end
      end

      meth tdscale(...)=M
         lock
            {self Scale(M vert)}
         end
      end

      meth lrscale(...)=M
         lock
            {self Scale(M horiz)}
         end
      end

      meth Execute(...)
         lock
            {self.action execute}
         end
      end

      meth destroy
         lock
            {self get(self.Return)}
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {Record.forAllInd B
             proc{$ I V}
                case I
                of 1 then {self.TkVar tkSet(V)}
                end
             end}
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {Record.forAllInd B
             proc{$ I V}
                case I
                of 1 then
                   {self.TkVar tkReturnFloat(V)}
                   {Wait V}
                end
             end}
         end
      end

   end

   {RegisterWidget r(widgetType:tdscale
                     feature:false
                     qTkTdscale:QTkScale)}

   {RegisterWidget r(widgetType:lrscale
                     feature:false
                     qTkLrscale:QTkScale)}

end
