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
   QTkImage
   QTkDevel(splitParams:        SplitParams
            condFeat:           CondFeat
            convertToType:      ConvertToType
            qTkClass:           QTkClass
            subtracts:          Subtracts
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget
            getWidget:          GetWidget)

export
   WidgetType
   Feature
   QTkNumberentry


require QTkNumberentry_bitmap

prepare BL=QTkNumberentry_bitmap.buildLibrary

define

   WidgetType=numberentry
   Feature=false
   Lib={QTkImage.buildImageLibrary BL}
%   IncStep     = 10
%   IncTime     = 100
   IncWait     = 500
%   Border      = 1

   class QTkNumberentry

      feat
         widgetType:WidgetType
         action Return
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(1:natural
                           init:natural
                           return:free
                           background:color bg:color
                           borderwidth:pixel
                           cursor:cursor
                           exportselection:boolean
                           font:font
                           foreground:color fg:color
                           highlightbackground:color
                           highlightcolor:color
                           highlightthickness:pixel
                           insertbackground:color
                           insertborderwidth:pixel
                           insertofftime:natural
                           insertontime:natural
                           insertwidth:pixel
                           justify:[left center right]
                           relief:relief
                           selectbackground:color
                           selectborderwidth:pixel
                           selectforeground:color
                           takefocus:boolean
                           show:vs
                           state:[normal disabled]
                           width:natural
                           action:action
                           min:natural max:natural
                          )}
                    uninit:r(1:unit)
                    unset:{Record.adjoin GlobalUnsetType
                           r(init:unit
                             min:unit
                             max:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(init:unit
                             min:unit
                             max:unit
                             font:unit)}
                   )
         Entry Inc Dec EReturn

      attr Min Max LastVal ID:nil

      from Tk.frame QTkClass

      meth numberentry(...)=M
         lock
            QButton={GetWidget button}
            QEntry={GetWidget entry}
         in
            QTkClass,{Record.adjoin M init}
            Min<-{CondFeat M min 1}
            Max<-{CondFeat M max 100}
            LastVal<-""
            self.Return={CondFeat M return _}
            Tk.frame,tkInit(parent:M.parent)
            self.Entry={New QEntry {Record.adjoin
                                    {Subtracts M [feature handle min max]}
                                    entry(parent:self
                                          action:self#Assert
                                          return:self.EReturn)}}
            self.Inc={New QButton button(parent:self
                                         image:{Lib get(name:'mini-inc.xbm' image:$)})}
            self.Dec={New QButton button(parent:self
                                         image:{Lib get(name:'mini-dec.xbm' image:$)})}
            {Tk.batch [grid(self.Entry row:0 colum:0 rowspan:2 sticky:nswe)
                       grid(self.Inc   row:0 column:1 sticky:ns)
                       grid(self.Dec   row:1 column:1 sticky:ns)
                       grid(rowconfigure self 0 weight:1)
                       grid(rowconfigure self 1 weight:1)
                       grid(columnconfigure self 0 weight:1)]}
            {self.Entry bind(event:  '<KeyPress-Up>'
                             action: self # Inc(1))}
            {self.Entry bind(event:  '<KeyPress-Down>'
                             action: self # Inc(~1))}
            {self.Entry bind(event:  '<Shift-KeyPress-Up>'
                             action: self # Inc(10))}
            {self.Entry bind(event:  '<Shift-KeyPress-Down>'
                             action: self # Inc(~10))}
            {self.Entry bind(event:  '<KeyRelease-Up>'
                             action: self # IncStop)}
            {self.Entry bind(event:  '<KeyRelease-Down>'
                             action: self # IncStop)}
            {self.Inc bind(event:  '<ButtonPress-1>'
                           action: self # Inc(1))}
            {self.Inc bind(event:  '<ButtonRelease-1>'
                           action: self # IncStop)}
            {self.Dec bind(event:  '<ButtonPress-1>'
                           action: self # Inc(~1))}
            {self.Dec bind(event:  '<ButtonRelease-1>'
                           action: self # IncStop)}
%           {self.Entry set({CondFeat M init @Min})}
            {self Assert(exec:false)}
         end
      end

      meth destroy
         lock
            {self get(self.Return)}
            {self.Entry destroy}
         end
      end

      meth Assert(exec:E<=true)
         lock
            V={self.Entry get($)}
            N
         in
            if V=="" then
               LastVal<-""
            else
               if {List.all V fun{$ C} C>=48 andthen C=<57 end} then
                  try
                     N={ConvertToType V natural}
                  catch _ then skip end
               end
               if {IsDet N} andthen N>=@Min andthen N=<@Max then
                  LastVal<-V
               else
                  {Tk.send bell}
                  {self.Entry set(@LastVal)}
               end
            end
            if E then {self.action execute} end
         end
      end

      meth Add(I)
         lock
            V={ConvertToType {self.Entry get($)} natural}
            N0=if V==false then
                  if I>0 then @Min else @Max end
               else
                  V+I
               end
            N1=if N0<@Min then @Min else N0 end
            N=if N1>@Max then @Max else N1 end
         in
            {self.Entry set(N)}
            LastVal<-N
            {self.action execute}
         end
      end

      meth Inc(I)
         lock
            THID
            proc{Loop}
               {Delay IncWait}
               {self Add(I)}
               {Loop}
            end
         in
            {self IncStop}
            {self Add(I)}
            thread
               THID={Thread.this}
               {Loop}
            end
            {Wait THID}
            ID<-THID
         end
      end

      meth IncStop
         lock
            try
               {Thread.terminate @ID}
            catch _ then skip end
         end
      end

      meth set(...)=M
         lock
            {self.Entry M}
            {self Assert(exec:false)}
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            {self.Entry A}
            if {HasFeature B 1} then
               R={ConvertToType {self.Entry get($)} natural}
            in
               B.1=if R==false then @Min else R end
            end
         end
      end

      meth otherwise(M)
         lock
            {self.Entry M}
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:Feature
                     qTkNumberentry:QTkNumberentry)}

end
