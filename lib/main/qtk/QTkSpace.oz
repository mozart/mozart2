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
   QTkSpace

define

   WidgetType=space
   Feature=false

   class QTkSpace

      feat
         Return
         widgetType:space
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(background:color
                           bg:color
                           width:pixel)}
                    uninit:r
                    unset:GlobalUnsetType
                    unget:GlobalUngetType
                   )
         Horiz
         Line

      from Tk.canvas QTkClass

      meth init(M)
         lock
            A
            W={CondFeat M width 5}
         in
            QTkClass,{Record.adjoin M init}
            {SplitParams M [width] A _}
            self.Horiz#self.Line=case {Label M}
                                 of lrspace then true#false
                                 [] tdspace then false#false
                                 [] lrline then true#true
                                 else false#true
                                 end
            Tk.canvas,{Record.adjoin {TkInit A}
                       tkInit(borderwidth:0
                              selectborderwidth:0
                              highlightthickness:0
                              width:if self.Horiz then 1 else W end
                              height:if self.Horiz then W else 1 end)}
            {ExecTk unit update}
            {self DrawLine}
         end
      end

      meth DrawLine
         lock
            if self.Line then
               S
            in
%              {Tk.returnInt winfo(if self.Horiz then
%                                     height
%                                  else
%                                     width
%                                  end self) S}
               {self tkReturnInt(cget(if self.Horiz then "-height" else "-width" end) S)}
               Tk.canvas,tk(delete all)
               Tk.canvas,if self.Horiz then
                            tk(crea line
                               0       (S div 2)
                               1000000 (S div 2)
                               fill:white)
                         else
                            tk(crea line
                               (S div 2) 0
                               (S div 2) 1000000
                               fill:white)
                         end
               Tk.canvas,if self.Horiz then
                            tk(crea line
                               0       (S div 2)+1
                               1000000 (S div 2)+1
                               fill:black)
                         else
                            tk(crea line
                               (S div 2)+1 0
                               (S div 2)+1 1000000
                               fill:black)
                         end
            end
         end
      end

      meth tdspace(...)=M
         lock
            {self init(M)}
         end
      end

      meth lrspace(...)=M
         lock
            {self init(M)}
         end
      end

      meth tdline(...)=M
         lock
            {self init(M)}
         end
      end

      meth lrline(...)=M
         lock
            {self init(M)}
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [width] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {Record.forAllInd B
             proc{$ I V}
                case I
                of width then
                   if self.Horiz then
                      {ExecTk self configure(height:V)}
                   else
                      {ExecTk self configure(width:V)}
                   end
                   {self DrawLine}
                else skip end
             end}
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M [width] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {Record.forAllInd B
             proc{$ I V}
                case I
                of width then if self.Horiz then
                                 {ReturnTk self cget("-height" V) pixel}
                              else
                                 {ReturnTk self cget("-width" V) pixel}
                              end
                end
             end}
         end
      end

   end

   {RegisterWidget r(widgetType:tdspace
                     feature:false
                     qTkTdspace:QTkSpace)}
   {RegisterWidget r(widgetType:lrspace
                     feature:false
                     qTkLrspace:QTkSpace)}
   {RegisterWidget r(widgetType:tdline
                     feature:false
                     qTkTdline:QTkSpace)}
   {RegisterWidget r(widgetType:lrline
                     feature:false
                     qTkLrline:QTkSpace)}

end
