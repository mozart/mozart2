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
            execTk:             ExecTk
            returnTk:           ReturnTk
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget)

export
   WidgetType
   Feature
   QTkButton

define

   WidgetType=button
   Feature=false

   class QTkButton

      feat
         Return
         widgetType:WidgetType
         action
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(1:vs
                           init:vs
                           return:free
                           activebackground:color
                           activeforeground:color
                           anchor:[n ne e se s sw w nw center]
                           background:color bg:color
                           bitmap:bitmap
                           borderwidth:pixel
                           cursor:cursor
                           disabledforeground:color
                           font:font
                           foreground:color fg:color
                           highlightbackground:color
                           highlightcolor:color
                           highlightthickness:pixel
                           image:image
                           justify:[left right center]
                           relief:relief
                           takefocus:boolean
                           text:vs
                           underline:natural
                           wraplength:pixel
                           ipadx:pixel
                           ipady:pixel
                           action:action
                           default:[normal disabled active]
                           height:pixel
                           state:[normal disabled active]
                           width:pixel
                           key:vs
                          )}
                    uninit:r(1:unit)
                    unset:{Record.adjoin GlobalUnsetType
                           r(init:unit
                             return:unit
                             key:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(init:unit
                             bitmap:bitmap
                             image:image
                             font:font
                             return:unit
                             key:unit)}
                   )

      from Tk.button QTkClass

      meth button(...)=M
         lock
            A B
         in
            QTkClass,{Record.adjoin M init}
            self.Return={CondFeat M return _}
            {SplitParams M [ipadx ipady init key] A B}
            Tk.button,{Record.adjoin {TkInit A} tkInit(padx:{CondFeat B ipadx 2}
                                                       pady:{CondFeat B ipady 2}
                                                       text:{CondFeat B init {CondFeat A text ""}}
                                                       action:self.toplevel.port#r(self Execute)
                                                      )}
            if {HasFeature B key} then
               if {Tk.returnInt 'catch'(v("{") bind self.toplevel "<"#M.key#">" v("{info library}") v("}"))}==0 then
                  {self.toplevel tkBind(event:"<"#M.key#">" action:self.toplevel.port#r(self Execute))}
               else
                  {Exception.raiseError qtk(typeError key button "A virtual string representing a valid key" M)}
               end
            end
         end
      end

      meth destroy
         lock
            self.Return={self.toplevel getDestroyer($)}==self
         end
      end

      meth Execute
         lock
            {self.toplevel setDestroyer(self)}
            {self.action execute}
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [1 ipadx ipady] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {Record.forAllInd B
             proc{$ I V}
                case I
                of 1 then QTkClass,set(text:V)
                [] ipadx then {ExecTk self configure(padx:V)}
                [] ipady then {ExecTk self configure(pady:V)}
                end
             end}
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M [1 ipadx ipady] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {Record.forAllInd B
             proc{$ I V}
                case I
                of 1 then QTkClass,get(text:V)
                [] ipadx then {ReturnTk self cget("-padx" V) natural}
                [] ipady then {ReturnTk self cget("-pady" V) natural}
                end
             end}
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:false
                     qTkButton:QTkButton)}

end
