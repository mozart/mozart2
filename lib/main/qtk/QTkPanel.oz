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
   QTkDevel(subtracts:          Subtracts
            condFeat:           CondFeat
            assert:             Assert
            tkInit:             TkInit
            qTkClass:           QTkClass
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget
            getWidget:          GetWidget
            propagateLook:      PropagateLook)

export
   WidgetType
   Feature
   QTkPanel

define

   WidgetType=panel
   Feature=true

   class QTkPanel

      from Tk.frame QTkClass

      prop locking

      feat
         widgetType:WidgetType
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(borderwidth:pixel
                           action:action
                           cursor:cursor
                           highlightbackground:color
                           highlightcolor:color
                           highlightthickness:pixel
                           relief:relief
                           takefocus:boolean
                           background:color bg:color
                           'class':atom
                           colormap:no
                           height:pixel
                           width:pixel
                           visual:no
                           font:font)}
                    uninit:r
                    unset:{Record.adjoin GlobalUnsetType
                           r('class':unit
                             colormap:unit
                             visual:unit
                             font:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(bitmap:unit
                             font:unit)})
         Dummy
         Canvas
         Place
         Scroll
         LineTag
         MarkerTag
         action

      attr Children
         TitleFont
         TitleHeight
         ShowScroll
         Frames

      meth panel(...)=M
         lock
            Features={Record.toList
                      {Record.map
                       {Record.filter M
                        fun{$ V}
                           {IsDet V} andthen {IsRecord V} andthen {HasFeature V feature}
                        end}
                       fun{$ V}
                          V.feature
                       end}}
            fun{MakeClass C}
               {Class.new [C] q
                Features
                [locking]}
            end
            A B1 B
            QTkPlaceHolder={GetWidget placeholder}
         in
            {Record.partitionInd {Record.adjoin M init}
             fun{$ I _} {Int.is I} end B1 A}
            B={PropagateLook B1}
            QTkClass,{Record.adjoin A init}
            Tk.frame,{TkInit {Subtracts A [font]}}
            %% B contains the structure of
            %% creates the children
            Children<-nil
            TitleFont<-{CondFeat A font courier}
            TitleHeight<-{Tk.returnInt font(metrics @TitleFont "-linespace")}
            self.Place={New {MakeClass QTkPlaceHolder}
                             placeholder(parent:self
                                         relief:raised
                                         bg:{self get(bg:$)}
                                         borderwidth:2
                                        )}
            {ForAll Features proc{$ F} self.F=self.Place.F end}
            self.Dummy={New Tk.canvas tkInit(parent:self
                                             bg:{self get(bg:$)}
                                             height:@TitleHeight+6)}
            local
               F={New Tk.frame tkInit(parent:self borderwidth:0 highlightthickness:0)}
               self.Canvas={New Tk.canvas tkInit(parent:F bg:{self.Place get(bg:$)}
                                                 highlightthickness:0 borderwidth:0)}
               self.Scroll={New Tk.scrollbar tkInit(parent:F
                                                    bg:{self get(bg:$)}
                                                    orient:horiz)}
               {Tk.addXScrollbar self.Canvas self.Scroll}
            in
               {Tk.batch [grid(self.Dummy row:0 column:0 sticky:we)
                          grid(self.Place row:1 column:0 padx:0 pady:0 sticky:nswe)
                          grid(rowconfigure self 1 weight:1)
                          grid(columnconfigure self 0 weight:1)
                          place(F x:0 y:0 height:@TitleHeight+10 relwidth:1.0)
                          grid(self.Canvas row:0 column:0 sticky:nswe)
                          grid(rowconfigure F 0 weight:1)
                          grid(columnconfigure F 0 weight:1)]}
            end
            ShowScroll<-false
            Frames<-nil
            self.LineTag={New Tk.canvasTag tkInit(parent:self.Canvas)}
            self.MarkerTag={New Tk.canvasTag tkInit(parent:self.Canvas)}
            {ForAll {Record.toList B}
             proc{$ D}
                {self addPanel(D)}
             end}
            if @Frames\=nil then {self Select({List.nth @Frames 1})} end
            {self.Canvas tkBind(event:"<Configure>"
                                action:self#Resize)}
         end
      end

      meth DrawTitle(X Title Tag XX)
         lock
            {self.Canvas tk(delete Tag)}
            Len={Tk.returnInt font(measure @TitleFont Title)}+6
            Coords=[X @TitleHeight+10
                    (@TitleHeight div 2)+X 2
                    (@TitleHeight div 2)+X+Len 2
                    @TitleHeight+X+Len @TitleHeight+10]
            Bg={self.Canvas tkReturn(cget("-bg") $)}
         in
            {self.Canvas tk(create poly b(Coords) fill:Bg tags:Tag)}
            {self.Canvas tk(create line b({List.take Coords 6}) fill:white tags:Tag)}
            {self.Canvas tk(create line b({List.drop Coords 4}) fill:black tags:Tag)}
            {self.Canvas tk(create text X+(@TitleHeight div 2)+5 6
                                font:@TitleFont anchor:nw fill:black tags:Tag text:Title)}
            XX=X+Len+8
         end
      end

      meth DrawTitles
         lock
            {self.Canvas tk(delete all)}
            {self.Canvas tk(create line 0 @TitleHeight+9 100000 @TitleHeight+9 fill:white tags:self.LineTag)}
            _={List.foldL @Frames
               fun{$ X F}
                  {self DrawTitle(X F.title F.tag $)}
               end
               0}
            {self Resize}
         end
      end

      meth Bind(F)
         lock
            {F.tag tkBind(event:"<1>" action:self#MouseSelect(F))}
         end
      end

      meth MouseSelect(F)
         lock
            {self Select(F)}
            {self execute}
         end
      end

      meth Select(F)
         lock
            {self.Canvas tk('raise' self.LineTag)}
            {self.Canvas tk('raise' F.tag)}
            {self.Canvas tk(delete self.MarkerTag)}
            local
               X1 Y1 X2 Y2
            in
               [X1 Y1 X2 Y2]={self.Canvas tkReturnListInt(bbox(F.tag) $)}
               {self.Canvas tk(create rect X1+10 Y1+5 X2-10 Y2-5 outline:gray50 tags:self.MarkerTag)}
            end
            {self.Place set(F.object)}
         end
      end

      meth Resize
         lock
            if @Frames==nil then skip else
               Max
               [_ _ Max _]={self.Canvas tkReturnListInt(bbox({List.last @Frames}.tag) $)}
               Width={Tk.returnInt winfo(width self.Canvas)}
            in
               {self.Canvas tk(configure scrollregion:"0 0 "#Max#" 1")}
               if @ShowScroll then
                  if Max=<{Tk.returnInt winfo(width self.Scroll)}+Width then
                     ShowScroll<-false
                     {Tk.send grid(forget self.Scroll)}
                     {self.Canvas tk(xview moveto 0.0)}
                  else skip end
               else
                  if Max>Width then
                     ShowScroll<-true
                     {Tk.send grid(self.Scroll row:0 column:1 sticky:s)}
                  else skip end
               end
            end
         end
      end

      meth addPanel(...)=M
         lock
            TypeInfo=r(all:r(1:no
%                            title:vs
                             after:no
                             before:no)
                       uninit:r
                       unset:r
                       unget:r)
            D=M.1
            O
            Pos Rec
         in
            {Assert panel TypeInfo {Record.adjoin M init}}
            if {HasFeature M after} then
               if M.after==all then Pos={Length @Frames}+1
               else
                  _={List.takeWhileInd @Frames
                     fun{$ I F}
                        if F.object==M.after then
                           Pos=I+1
                           false
                        else true end
                     end}
                  if {IsFree Pos} then
                     {Exception.raiseError qtk(panelObject M.after M)}
                  end
               end
            elseif {HasFeature M before} then
               if M.before==all then Pos=0
               else
                  _={List.takeWhileInd @Frames
                     fun{$ I F}
                        if F.object==M.before then
                           Pos=I-1
                           false
                        else true end
                     end}
                  if {IsFree Pos} then
                     {Exception.raiseError qtk(panelObject M.before M)}
                  end
               end
            else
               Pos={Length @Frames}+1
            end
            {self.Place set({Record.adjoinAt
                             {Subtracts D [title]}
                             handle O})}
            {CondFeat M.1 handle _}=O
            Rec=r(object:O
                  title:D.title
                  tag:{New Tk.canvasTag tkInit(parent:self.Canvas)})
            Frames<-{List.append
                     {List.append
                      {List.take @Frames Pos}
                      [Rec]}
                     {List.drop @Frames Pos}
                    }
            {self Bind(Rec)}
            {self DrawTitles}
            try {self selectPanel(O)} catch _ then skip end
         end
      end

      meth selectPanel(O ...)=M
         lock
            Z={List.filter @Frames fun{$ F} F.object==O end}
         in
            if Z==nil then
               {Exception.raiseError qtk(panelObject O M)}
            end
            {self Select({List.nth Z 1})}
         end
      end

      meth deletePanel(O ...)=M
         lock
            Z={List.filter @Frames fun{$ F} F.object==O end}
         in
            if Z==nil then
               {Exception.raiseError qtk(panelObject O M)}
            end
            if {self.Place get($)}=={List.nth Z 1} then {self.Place set(empty)} end
            Frames<-{List.filter @Frames fun{$ F} F.object\=O end}
            {self DrawTitles}
            try {self selectPanel({self.Place get($)})} catch _ then
               if @Frames==nil then
                  {self.Place set(empty)}
               else
                  {self selectPanel({List.nth @Frames 1}.object)}
               end
            end
         end
      end

      meth destroy
         lock
            {ForAll @Frames
             proc{$ R}
                {R.object destroy}
             end}
         end
      end

      meth execute
         lock
            skip
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:Feature
                     qTkPanel:QTkPanel)}

end
