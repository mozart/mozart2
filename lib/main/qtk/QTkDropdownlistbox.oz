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
   QTkBare
   QTkImage
   QTkDevel(condFeat:           CondFeat
            assert:             Assert
            splitParams:        SplitParams
            subtracts:          Subtracts
            qTkClass:           QTkClass
            setGet:             SetGet
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget)


export
   WidgetType
   Feature
   QTkDropdownlistbox

require QTkDropdownbutton_bitmap

prepare BL=QTkDropdownbutton_bitmap.buildLibrary

define
   QTk=QTkBare
   WidgetType=dropdownlistbox
   Feature=false
   Lib={QTkImage.buildImageLibrary BL}

   fun{FilterButton Rec}
      %% pre : record with features whose name begin with button and other features
      %% post : a pair of record where all features that begin with button are in the
      %% second record and are removed the first 6 letters (i.e. button). The first
      %% record contains the remaining features
      A B
   in
      {Record.partitionInd Rec fun{$ I _}
                                  {List.take {VirtualString.toString I} 6}=="button"
                               end B A}
      A#{List.toRecord {Label B}
         {List.map {Record.toListInd B}
          fun{$ I}
             A B
          in
             A#B=I
             {VirtualString.toAtom {List.drop {VirtualString.toString A} 6}}#B
          end}}
   end

   class QTkDropdownlistbox

      feat
         Return
         widgetType:WidgetType
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(1:listVs      %% parameters specific to the listbox
                           init:listVs   %% copy/paste from QTkListbox.oz :-)
                           return:free
                           reload:listVs
                           firstselection:natural
                           background:color bg:color
                           borderwidth:pixel
                           cursor:cursor
                           exportselection:boolean
                           font:font
                           height:natural
                           highlightbackground:color
                           highlightcolor:color
                           highlightthickness:pixel
                           relief:relief
                           selectbackground:color
                           selectborderwidth:pixel
                           selectforeground:color
                           setgrid:boolean
                           takefocus:boolean
                           width:natural
                           selectmode:[single browse multiple extended]
                           action:action
                           lrscrollbar:boolean
                           tdscrollbar:boolean
                           scrollwidth:pixel
                           %% parameters specific to the button
                           buttonactivebackground:color
                           buttonactiveforeground:color
                           buttonbackground:color
                           buttonforeground:color
                           buttondisabledforeground:color
                           buttonhighlightbackground:color
                           buttonhighlightcolor:color
                           buttonhighlightthickness:pixel
                           buttontakefocus:boolean
                           buttondefault:[normal disabled active]
                           buttonstate:[normal disabled active])}
                    uninit:r(1:unit
                             reload:unit
                             firstselection:unit)
                    unset:{Record.adjoin GlobalUnsetType
                           r(lrscrollbar:unit
                             tdscrollbar:unit
                             scrollwidth:unit
                             init:unit
                             reload:unit
                             firstselection:unit
                             )}
                    unget:{Record.adjoin GlobalUngetType
                           r(lrscrollbar:unit
                             tdscrollbar:unit
                             scrollwidth:unit
                             init:unit
                             font:unit
                             selectmode:unit)}
                   )
         action
         list
         Window

      from Tk.button QTkClass

      meth dropdownlistbox(...)=M
         lock
            A B
         in
            QTkClass,{Record.adjoin M init}
            self.Return={CondFeat M return _}
            A#B={FilterButton M}
            Tk.button,{Record.adjoin B tkInit(parent:M.parent
                                              action:self#DropDown
                                              image:{Lib get(name:'mini-down.xbm' image:$)})}
            self.Window={QTk.build td(overrideredirect:true
                                      {Record.adjoin {Subtracts A [handle]}
                                       listbox(glue:nswe
                                               feature:list
                                               action:self#Execute)})}
            {self.Window bind(event:"<ButtonRelease-1>" action:self#Close)}
         end
      end

      meth DropDown
         lock
            proc{D}
               BX BY BW BH SW SH
               {self winfo(rootx:BX rooty:BY
                           width:BW height:BH
                           screenwidth:SW screenheight:SH)}
               WW WH
               {self.Window winfo(width:WW height:WH)}
               X1=BX+BW-WW
               X2=if X1<0 then 0 else X1 end
               WX=if X2+WW>SW then SW-WW else X2 end
               Y1=BY+BH
               WY=if Y1+WH>SH then SH-WH else Y1 end
            in
               {self.Window.list set(selection:nil)}
               {self.Window set(geometry:geometry(x:WX y:WY))}
               {self.Window show(modal:true)}
               {self.Window set(geometry:geometry(x:WX y:WY))}
               {self.Window 'raise'}
            end
         in
            {D}
            {D}
         end
      end

      meth Close
         try
            {self.Window releaseGrab}
            {self.Window hide}
         catch _ then skip end
      end

      meth destroy
         lock
            self.Return={self.toplevel getDestroyer($)}==self
         end
      end

      meth Execute
         lock
            {self Close}
            {self.action execute}
         end
      end

      meth set(...)=M
         lock
            A B C D
         in
            {Assert self.widgetType self.typeInfo M}
            A#B={FilterButton M}
            {SplitParams B [action tooltips] C D}
            QTkClass,D
            SetGet,C
            {self.Window.list A}
         end
      end

      meth get(...)=M
         lock
            A B C D
         in
            {Assert self.widgetType self.typeInfo M}
            A#B={FilterButton M}
            {SplitParams B [action tooltips] C D}
            QTkClass,D
            SetGet,C
            {self.Window.list A}
         end
      end

      meth otherwise(M)
         lock
            {self.Window.list M}
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:Feature
                     qTkDropdownlistbox:QTkDropdownlistbox)}

end
