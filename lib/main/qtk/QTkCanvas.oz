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
            execTk:             ExecTk
            returnTk:           ReturnTk
            mapLabelToObject:   MapLabelToObject
            qTkClass:           QTkClass
            qTkAction:          QTkAction
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget)

export
   WidgetType
   Feature
   QTkCanvas

define

   WidgetType=canvas
   Feature=scroll

   class QTkCanvas

      feat
         widgetType:WidgetType
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(background:color bg:color
                           borderwidth:pixel
                           cursor:cursor
                           highlightbackground:color
                           highlightcolor:color
                           highlightthickness:pixel
                           insertbackground:color
                           insertborderwidth:pixel
                           insertofftime:natural
                           insertontime:natural
                           insertwidth:pixel
                           relief:relief
                           selectbackground:color
                           selectborderwidth:pixel
                           selectforeground:color
                           takefocus:boolean
                           closeenough:float
                           confine:boolean
                           height:pixel
                           scrollregion:scrollregion
                           width:pixel
                           xscrollincrement:pixel
                           yscrollincrement:pixel
                           lrscrollbar:boolean
                           tdscrollbar:boolean
                           scrollwidth:pixel)}
                    uninit:r
                    unset:{Record.adjoin GlobalUnsetType
                           r(lrscrollbar:unit
                             tdscrollbar:unit
                             scrollwidth:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(lrscrollbar:unit
                             tdscrollbar:unit
                             scrollwidth:unit)}
                   )

      from Tk.canvas QTkClass

      meth canvas(...)=M
         lock
            A
         in
            QTkClass,{Record.adjoin M init}
            {SplitParams M [lrscrollbar tdscrollbar scrollwidth] A _}
            Tk.canvas,{TkInit A}
         end
      end

      meth Bind(What M)
         if {HasFeature M event}==false then
            {Exception.raiseError qtk(missingParameter event canvas M)}
         else skip end
         {What tkBind(event:M.event
                      args:{CondFeat M args nil}
                      action:{{New QTkAction init(parent:self
                                                  action:{CondFeat M action proc{$} skip end})} action($)})}
      end

      meth bind(...)=M
         lock
            {self Bind(self M)}
         end
      end

      meth newTag(Tag)
         lock
            Self=self
            fun{TAdd M}
               {List.toRecord
                {Label M}
                1#Tag|{List.map
                       {Record.toListInd M}
                       fun{$ R}
                          case R of I#V then if {IsInt I} then I+1#V else I#V end end
                       end}}
            end
            proc{TExecTk M}
               {ExecTk Self {TAdd M}}
            end
            proc{TReturnTk M Type}
               {ReturnTk Self {TAdd M} Type}
            end
            class CanvasTag
               from Tk.canvasTag QTkClass
               feat
                  cvtType:r(extent:natural
                            fill:color
                            outline:color
                            outlinestipple:bitmap
                            start:natural
                            stipple:bitmap
                            style:atom
                            width:natural
                            anchor:nswe
                            background:color
                            bitmap:bitmap
                            foreground:color
                            image:image
                            arrow:atom
                            arrowshape:listInt
                            capstyle:atom
                            joinstyle:atom
                            smooth:boolean
                            splinesteps:natural
                            justify:atom
                            text:vs
                            height:natural)
                  widgetType:canvasTag
               meth init(...)=M
                  lock
                     QTkClass,M
                     Tk.canvasTag,{Record.adjoin M tkInit}
                  end
               end
               meth set(...)=M
                  lock
                     if {Record.someInd M
                         fun{$ I _}
                            {Int.is I}
                         end}
                     then
                        {Exception.raiseError qtk(badParameter 1 canvasTag M)}
                     else
                        {ExecTk Self{Record.adjoin M itemconfigure(self)}}
                     end
                  end
               end
               meth get(...)=M
                  lock
                     {Record.forAllInd M
                      proc{$ I R}
                         if {HasFeature self.cvtType I} then
                            R={ReturnTk Self itemcget(self "-"#I $) self.cvtType.I}
                         else
                            {Exception.raiseError qtk(ungettableParameter I canvasTag M)}
                         end
                      end}
                  end
               end
               meth addtag(...)=M
                  lock
                     {TExecTk M}
                  end
               end
               meth bbox(...)=M
                  lock
                     {TReturnTk M listInt}
                  end
               end
               meth bind(...)=M
                  lock
                     {Self Bind(self M)}
                  end
               end
               meth delete(...)=M
                  lock
                     {TExecTk M}
                  end
               end
               %% coords split in two to reflect whether we want to get or to set the coords
               meth getCoords(...)=M
                  lock
                     {TReturnTk {Record.adjoin M coords} listInt}
                  end
               end
               meth setCoords(...)=M
                  lock
                     {TExecTk {Record.adjoin M coords}}
                  end
               end
               meth dchars(...)=M
                  lock
                     {TExecTk M}
                  end
               end
               meth focus=M
                  lock
                     {TExecTk M}
                  end
               end
               meth icursor(...)=M
                  lock
                     {TExecTk M}
                  end
               end
               meth index(...)=M
                  lock
                     {TReturnTk M int}
                  end
               end
               meth insert(...)=M
                  lock
                     {TExecTk M}
                  end
               end
               meth lower(...)=M
                  lock
                     {TExecTk M}
                  end
               end
               meth move(...)=M
                  lock
                     {TExecTk M}
                  end
               end
               meth 'raise'(...)=M
                  lock
                     {TExecTk M}
                  end
               end
               meth scale(...)=M
                  lock
                     {TExecTk M}
                  end
               end
               meth type(...)=M
                  lock
                     {TReturnTk M atom}
                  end
               end
            end
         in
            Tag={New CanvasTag init(parent:self)}
         end
      end

      %% interface toward tk commands

      meth canvasx(...)=M
         lock
            {ReturnTk self M natural}
         end
      end

      meth canvasy(...)=M
         lock
            {ReturnTk self M natural}
         end
      end

      meth create(...)=M
         lock
            if {HasFeature M 1} andthen M.1==window andthen
               {HasFeature M 2} andthen {HasFeature M 3} andthen
               {HasFeature M window} then
               %% window creation is a bit different
               {ExecTk self {Record.adjoinAt M window {MapLabelToObject {Record.adjoinAt M.window parent self}}}}
            else
               {ExecTk self M}
            end
         end
      end

      % find not supplied : it returns Tk tags and they can't be transformed into the corresponding Oz objects

      meth focus=M
         lock
            {ExecTk self M}
         end
      end

      % gettags not supplied : same reason as find

      % itemcget and itemconfigure are included in the tag object

      meth postscript(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth scan(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth select(...)=M
         lock
            {ExecTk self M}
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:Feature
                     qTkCanvas:QTkCanvas)}

end
