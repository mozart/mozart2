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
   System(show:Show)
   Tk
   QTkDevel(tkInit:             TkInit
            mapLabelToObject:   MapLabelToObject
            subtracts:          Subtracts
            condFeat:           CondFeat
            setGet:             SetGet
            execTk:             ExecTk
            returnTk:           ReturnTk
            qTkClass:           QTkClass
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget
            splitParams:        SplitParams)

export
   WidgetType
   Feature
   QTkMdiwindow

define

   WidgetType=mdiwindow
   Feature=false

   fun {Min A B}
      if A>B then B else A end
   end

   fun {Max A B}
      if A>B then A else B end
   end

   class QTkMdiwindow

      from Tk.frame QTkClass

      prop locking

      feat
         widgetType:WidgetType
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(borderwidth:pixel
                           cursor:cursor
                           highlightbackground:color
                           highlightcolor:color
                           highlightthickness:pixel
                           relief:relief
                           takefocus:boolean
                           background:color bg:color
                           'class':atom
                           colormap:no
                           container:boolean
                           height:pixel
                           width:pixel
                           visual:no)}
                    uninit:r
                    unset:{Record.adjoin GlobalUnsetType
                           r('class':unit
                             colormap:unit
                             container:unit
                             visual:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r('class':unit
                             colormap:unit
                             container:unit
                             visual:unit)})
         ChildClass
         Canvas VScroll HScroll
      attr Children VScroll HScroll Canvas
      meth mdiwindow(...)=M
         lock
            Self=self
            SelfCanvas=self.Canvas
         in
            Children<-nil
            QTkClass,{Record.adjoin M init}
            Tk.frame,{TkInit M}
            self.Canvas={New Tk.canvas tkInit(parent:self
                                              bg:{self get(bg:$)}
                                              confine:true
                                              width:100
                                              height:100)}
            self.VScroll={New Tk.scrollbar tkInit(parent:self
                                                  orient:vert)}
            {Tk.addYScrollbar self.Canvas self.VScroll}
            self.HScroll={New Tk.scrollbar tkInit(parent:self
                                                  orient:horiz)}
            {Tk.addXScrollbar self.Canvas self.HScroll}
            VScroll<-false
            HScroll<-false
            {Tk.batch [grid(self.Canvas row:0 column:0 sticky:nswe)
                       grid(rowconfigure self 0 weight:1)
                       grid(columnconfigure self 0 weight:1)]}
            self.ChildClass=class $
                               from SetGet Tk.frame
                               feat
                                  toplevel
                                  widgetType:mdiwindow
                                  WM:[borderwidth cursor highlightbackground highlightcolor highlightthickness
                                      relief takefocus background bg 'class' colormap container height visual width]
                                  typeInfo:r(all:r(borderwidth:pixel
                                                   cursor:cursor
                                                   highlightbackground:color
                                                   highlightcolor:color
                                                   highlightthickness:pixel
                                                   relief:relief
                                                   takefocus:boolean
                                                   background:color bg:color
                                                   'class':atom
                                                   colormap:no
                                                   container:boolean
                                                   height:pixel
                                                   visual:no
                                                   width:pixel
                                                   %% parameters taken into account here
                                                   action:action  % action is called when the user tries to close the window
                                                   %% wm parameters
                                                   title:vs
                                                   geometry:no
                                                   iconbitmap:bitmap
                                                   iconmask:bitmap
                                                   iconname:vs
                                                   iconposition:no
                                                   maxsize:no
                                                   minsize:no
                                                   overrideredirect:boolean
                                                   resizable:no)
                                             uninit:r
                                             unset:r(return:unit visual:unit use:unit screen:unit container:unit
                                                     colormap:unit 'class':unit)
                                             unget:r(return:unit group:unit iconbitmap:unit iconmask:unit
                                                     iconwindow:unit transient:unit))
                                  action
                                  TitleFrame
                                  TitleLabel
                                  TitleMenu
                                  TitleHeight
                                  IconBitmap
                                  IconLabel
                                  Window
                                  ResizeFrame
                                  ResizeCanvas
                                  ResizeHeight
                                  Tag
                               attr State Active OX OY Mode
                               meth init(M)
                                  lock
                                     A B
                                  in
                                     self.toplevel=Self.toplevel
                                     Tk.frame,tkInit(parent:SelfCanvas)
                                     Mode<-unit
                                     self.TitleFrame={New Tk.frame tkInit(parent:self
                                                                          bg:blue
                                                                         relief:raised borderwidth:1)}
                                     local
                                        I1={New Tk.button tkInit(parent:self.TitleFrame
                                                                 text:"R" padx:0 pady:0
                                                                 highlightbackground:blue
                                                                 action:self#Reduce)}
                                        I2={New Tk.button tkInit(parent:self.TitleFrame
                                                                 text:"M" padx:0 pady:0
                                                                 highlightbackground:blue
                                                                 action:self#Maximize)}
                                        I3={New Tk.button tkInit(parent:self.TitleFrame
                                                                 text:"C" padx:0 pady:0
                                                                 highlightbackground:blue
                                                                 action:self#Close)}
                                     in
                                        self.TitleMenu={New Tk.menubutton tkInit(parent:self.TitleFrame
                                                                                 text:"M"
                                                                                 relief:raised
                                                                                 borderwidth:2
                                                                                 padx:0 pady:0)}
                                        self.TitleLabel={New Tk.label tkInit(parent:self.TitleFrame
                                                                             bg:blue
                                                                             fg:white
                                                                             text:{CondFeat M title "Window"})}
                                        {self.TitleLabel tkBind(event:"<1>"
                                                                args:[int(x) int(y)]
                                                                action:self#Click)}
                                        {self.TitleLabel tkBind(event:"<B1-Motion>"
                                                                args:[int(x) int(y)]
                                                                action:self#MotionMove)}
                                        {Tk.batch [grid(self.TitleMenu  row:0 column:0)
                                                   grid(self.TitleLabel row:0 column:1 sticky:we)
                                                   grid(I1              row:0 column:2)
                                                   grid(I2              row:0 column:3)
                                                   grid(I3              row:0 column:4)
                                                   grid(columnconfigure self.TitleFrame 1 weight:1)]}
                                     end
                                     {SplitParams M parent|self.WM A B}
                                     self.Window={MapLabelToObject {Record.adjoin r(parent:self
                                                                                    borderwidth:1
                                                                                    relief:solid)
                                                                                    A}}
                                     self.ResizeFrame={New Tk.frame tkInit(parent:self bg:gray)}
                                     local
                                        I1={New Tk.canvas tkInit(parent:self.ResizeFrame
                                                                 width:20 height:3 relief:raised
                                                                 cursor:bottom_left_corner
                                                                 borderwidth:1)}
                                        I2={New Tk.canvas tkInit(parent:self.ResizeFrame
                                                                 width:0 height:3 relief:raised
                                                                 cursor:bottom_side
                                                                 borderwidth:1)}
                                        I3={New Tk.canvas tkInit(parent:self.ResizeFrame
                                                                 width:20 height:3 relief:raised
                                                                 cursor:bottom_right_corner
                                                                 borderwidth:1)}
                                     in
                                        self.ResizeCanvas=I2
                                        {Tk.batch [grid(I1 row:0 column:0)
                                                   grid(I2 row:0 column:1 sticky:we)
                                                   grid(I3 row:0 column:2)
                                                   grid(columnconfigure self.ResizeFrame 1 weight:1)]}
                                        {I1 tkBind(event:"<1>"
                                                   args:[int(x) int(y)]
                                                   action:self#Click)}
                                        {I1 tkBind(event:"<B1-Motion>"
                                                   args:[int(x) int(y)]
                                                   action:self#MotionResize(left))}
                                        {I2 tkBind(event:"<1>"
                                                   args:[int(x) int(y)]
                                                   action:self#Click)}
                                        {I2 tkBind(event:"<B1-Motion>"
                                                   args:[int(x) int(y)]
                                                   action:self#MotionResize(down))}
                                        {I2 tkBind(event:"<3>"
                                                   args:[int(x) int(y)]
                                                   action:self#Click)}
                                        {I2 tkBind(event:"<B3-Motion>"
                                                   args:[int(x) int(y)]
                                                   action:self#MotionMove)}
                                        {I3 tkBind(event:"<1>"
                                                   args:[int(x) int(y)]
                                                   action:self#Click)}
                                        {I3 tkBind(event:"<B1-Motion>"
                                                   args:[int(x) int(y)]
                                                   action:self#MotionResize(right))}
                                     end

                                     {Tk.batch [place(self.TitleFrame x:0 y:0 relwidth:1.0 anchor:nw)
                                                place(self.ResizeFrame x:0 rely:1.0 relwidth:1.0 anchor:sw)
                                                place(self.Window      x:0 y:0 anchor:w)]}
                                     {ExecTk unit update}
                                     self.TitleHeight={Tk.returnInt winfo(height self.TitleFrame)}
                                     self.ResizeHeight={Tk.returnInt winfo(height self.ResizeFrame)}

                                     local
                                        W={Tk.returnInt winfo(width self.Window)}
                                        H={Tk.returnInt winfo(height self.Window)}
                                     in
                                        {Wait H}
                                        {self tk(configure width:W height:H+self.TitleHeight+self.ResizeHeight)}
                                        {self Replace}
                                     end

%                                    {Tk.batch [grid(self.TitleFrame  row:0 column:0 sticky:we)
%                                               grid(self.Window      row:1 column:0 sticky:nswe)
%                                               grid(self.ResizeFrame row:2 column:0 sticky:we)
%                                               grid(rowconfigure    self 1 weight:1)
%                                               grid(columnconfigure self 0 weight:1)]}

                                     State<-hidden
                                     Active<-false
                                     {Self UnSetActive}
                                     Active<-true
                                     {self {Record.adjoin {Subtracts B [parent]} set}}
                                     self.Tag={New Tk.canvasTag tkInit(parent:SelfCanvas)}
                                     {SelfCanvas tk(crea window 10 10
                                                    anchor:nw
                                                    tags:self.Tag
                                                    window:self)}
                                  end
                               end
                               meth td(...)=M
                                  lock
                                     {self init(M)}
                                  end
                               end
                               meth lr(...)=M
                                  lock
                                     {self init(M)}
                                  end
                               end
                               meth set(...)=M
                                  lock
                                     skip
                                  end
                               end
                               meth get(...)=M
                                  lock
                                     skip
                                  end
                               end
                               meth Replace
                                  lock
                                     W={self tkReturnInt(cget("-width") $)}
                                     H={self tkReturnInt(cget("-height") $)}
                                  in
                                     {Wait H}
                                     {Tk.send place(self.Window
                                                    x:0
                                                    y:self.TitleHeight
                                                    width:W
                                                    height:H-self.TitleHeight-self.ResizeHeight
                                                    anchor:nw)}
                                     {Tk.send 'raise'(self.Window)}
                                  end
                               end
                               meth Reduce
                                  skip
                               end
                               meth Maximize
                                  skip
                               end
                               meth Close
                                  skip
                               end
                               meth Click(X Y)
                                  lock
                                     OX<-X OY<-Y
                                  end
                               end
                               meth MotionMove(X Y)
                                  lock
                                     {SelfCanvas tk(move self.Tag X-@OX Y-@OY)}
                                  end
                               end
                               meth MotionResize(C X Y)
                                  lock
                                     W={self tkReturnInt(cget("-width") $)}
                                     H={self tkReturnInt(cget("-height") $)}
                                  in
                                     case C
                                     of left then
                                        {self tk(configure
                                                 width:{Max W+@OX-X 40}
                                                 height:{Max H+Y-@OY 40})}
                                        {SelfCanvas tk(move self.Tag X-@OX 0)}
                                        {self Replace}
%                                       OX<-X
%                                       OY<-Y
                                     [] down then
                                        {self tk(configure
                                                 height:{Max H+Y-@OY 40})}
                                        {self Replace}
                                     [] right then
                                        {self tk(configure
                                                 width:{Max W+X-@OX 40}
                                                 height:{Max H+Y-@OY 40})}
                                        {self Replace}
                                     end
                                  end
                               end
                               meth destroy
                                  skip
                               end
                            end
            {self.Canvas tkBind(event:"<Configure>"
                                action:self#Resize)}
         end
      end
      meth UnSetActive
         skip
      end
      meth newWindow(W)
         lock
            Child={New self.ChildClass W}
         in
            Children<-Child|@Children
            {Child tkBind(event:"<Configure>"
                          action:self#Resize)}
         end
      end

      meth SetScrollbar(W B)
         lock
            if W==h then
               if B==@HScroll then skip
               else
                  if B then {Tk.send grid(self.HScroll row:1 column:0 sticky:we)}
                  else {Tk.send grid(forget self.HScroll)}
                  end
                  HScroll<-B
               end
            else
               if B==@VScroll then skip
               else
                  if B then {Tk.send grid(self.VScroll row:0 column:1 sticky:ns)}
                  else {Tk.send grid(forget self.VScroll)}
                  end
                  VScroll<-B
               end
            end
         end
      end

      meth Resize
         lock
            W H CX CY
            X1 Y1 X2 Y2
         in
            {self winfo(width:W height:H)} %% request the width and height of the window
            {self.Canvas tkReturnInt(canvasx(1) CX)} %% X and Y is the top left pixel
            {self.Canvas tkReturnInt(canvasy(1) CY)}
            if {self.Canvas tkReturn(bbox(all) $)}=="" then
               X1#Y1#X2#Y2=0#0#0#0
            else
               [X1 Y1 X2 Y2]={self.Canvas tkReturnListInt(bbox(all) $)}
            end
            if X1>=CX andthen X2=<CX+W andthen
               Y1>=CY andthen Y2=<CY+H then %% all windows are viewable
               {self SetScrollbar(v false)}
               {self SetScrollbar(h false)}
               {self.Canvas tk(configure scrollregion:q(CX
                                                        CY
                                                        CX+W
                                                        CY+H))}
            elseif X1<CX orelse X2>CX+W then %% not horizontally viewable
               CH
            in
               {self SetScrollbar(h true)}
               {ExecTk unit update} %% synchronisation
               CH={Tk.returnInt winfo(height self.Canvas)}
               %{self.Canvas tkReturnInt(cget("-height") CH)}
               {Wait CH}
               {self SetScrollbar(v (Y1<CY orelse Y2>CY+CH))}
               {self.Canvas tk(configure scrollregion:q({Min X1 CX}
                                                        {Min Y1 CY}
                                                        X2
                                                        Y2))}
            else %% not vertically viewable
               CW
            in
               {self SetScrollbar(v true)}
               {ExecTk unit update} %% synchronisation
               CW={Tk.returnInt winfo(width self.Canvas)}
%              {self.Canvas tkReturnInt(cget("-width") CW)}
               {self SetScrollbar(h X2>CX+CW)} %% not vertically viewable
               {self.Canvas tk(configure scrollregion:q({Min X1 CX}
                                                        {Min Y1 CY}
                                                        X2
                                                        Y2))}
            end
         end
      end

      meth destroy
         lock
            {ForAll @Children
             proc{$ Child}
                {Child destroy}
             end}
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:Feature
                     qTkMdiwindow:QTkMdiwindow)}

end
