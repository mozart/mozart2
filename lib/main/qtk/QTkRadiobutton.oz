%
% Authors:
%   Donatien Grolaux (2000)
%
% Copyright:
%   (c) 2000 Université catholique de Louvain
%
% Last change:
%   $Date$ by $Author$
%   $Revision$
%
% This file is part of Mozart, an implementation
% of Oz 3:
%   http://www.mozart-oz.org
%
% See the file "LICENSE" or
%   http://www.mozart-oz.org/LICENSE.html
% for information on usage and redistribution
% of this file, and for a DISCLAIMER OF ALL
% WARRANTIES.
%
%  The development of QTk is supported by the PIRATES project at
%  the Université catholique de Louvain.


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
   QTkRadiobutton

define

   WidgetType=radiobutton
   Feature=false

   class QTkRadiobutton

      feat
         Return Name Value
         TkVar
         widgetType:WidgetType
         action
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(1:boolean
                           init:boolean
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
                           height:pixel
                           indicatoron:boolean
                           selectcolor:color
                           selectimage:image
                           state:[normal disabled active]
                           width:pixel
                           ipadx:pixel
                           ipady:pixel
                           action:action
                           group:atom)}
                    uninit:r(1:unit)
                    unset:{Record.adjoin GlobalUnsetType
                           r(init:unit
                             group:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(init:unit
                             bitmap:unit
                             image:unit
                             selectimage:unit
                             font:unit
                             key:unit
                             group:unit)}
                   )

      from Tk.radiobutton QTkClass

      meth radiobutton(...)=M
         lock
            A B
         in
            QTkClass,{Record.adjoin M init}
            if {HasFeature M group}==false then
               {Exception.raiseError qtk(missingParameter group self.widgetType M)}
            end
            self.Return={CondFeat M return _}
            {SplitParams M [ipadx ipady init group] A B}
            self.Name=B.group
            local
               R={self.toplevel getRadioDict(self.Name $)}
            in
               self.TkVar=R.1
               self.Value=R.2+1
            end
            if {CondFeat M init false} then
               {self.TkVar tkSet(self.Value)}
               {self.toplevel notifyRadioButton(self.Name)}
            end
            Tk.radiobutton,{Record.adjoin {TkInit A} tkInit(padx:{CondFeat B ipadx 2}
                                                            pady:{CondFeat B ipady 2}
                                                            action:self.toplevel.port#r(self Execute)
                                                            variable:self.TkVar
                                                            value:self.Value
                                                           )}
         end
      end

      meth Execute
         lock
            {self.toplevel notifyRadioButton(self.Name)}
            {self.action execute}
         end
      end

      meth destroy
         lock
            self.Return={self.TkVar tkReturnInt($)}==self.Value
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
                of 1 then if V then {self.TkVar tkSet(self.Value)}
                                    {self.toplevel notifyRadioButton(self.Name)}
                          else
                             if {self.TkVar tkReturnInt($)}==self.Value then
                                {self.TkVar tkSet(0)}
                                {self.toplevel notifyRadioButton(self.Name)}
                             end
                          end
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
                of 1 then  V={self.TkVar tkReturnInt($)}==self.Value
                [] ipadx then {ReturnTk self cget("-padx" V) natural}
                [] ipady then {ReturnTk self cget("-pady" V) natural}
                end
             end}
         end
      end

      meth flash
         lock
            Tk.radiobutton,tk(flash)
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:false
                     qTkRadiobutton:QTkRadiobutton)}

end
