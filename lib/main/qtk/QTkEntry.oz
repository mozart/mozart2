%
% Authors:
%   Donatien Grolaux (2000)
%
% Copyright:
%   (c) 2000 Université catholique de Louvain
%
% Last change:
%   $Date$
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
   QTkEntry

define

   WidgetType=entry
   Feature=scroll

   class QTkEntry

      feat
         Return TkVar
         widgetType:WidgetType
         action
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(1:vs
                           init:vs
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
                           lrscrollbar:boolean
                           scrollwidth:pixel
                           selectionfrom:natural
                           selectionto:natural
                          )}
                    uninit:r(1:unit
                             selectionfrom:unit
                             selectionto:unit)
                    unset:{Record.adjoin GlobalUnsetType
                           r(init:unit
                             lrscrollbar:unit
                             scrollwidth:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(init:unit
                             font:unit
                             lrscrollbar:unit
                             scrollwidth:unit
                             selectionfrom:unit
                             selectionto:unit)}
                   )

      from Tk.entry QTkClass

      meth entry(...)=M
         lock
            A B
         in
            QTkClass,{Record.adjoin M init}
            self.Return={CondFeat M return _}
            {SplitParams M [init lrscrollbar scrollwidth] A B}
            self.TkVar={New Tk.variable tkInit("")}
            Tk.entry,{Record.adjoin {TkInit A} tkInit(textvariable:self.TkVar)}
            Tk.entry,tkBind(event:"<KeyRelease>" action:{self.action action($)})
            Tk.entry,tk(insert 0 {CondFeat B init ""})
            Tk.entry,tkBind(event:"<FocusIn>"
                            action:proc{$}
                                      {self tk(selection 'from' 0)}
                                      {self tk(selection 'to' 'end')}
                                   end)
            Tk.entry,tkBind(event:"<FocusOut>"
                            action:proc{$}
                                      {self tk(selection clear)}
                                   end)
         end
      end

      meth destroy
         lock
            self.Return={self.TkVar tkReturn($)}
            {Wait self.Return}
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [1 selectionfrom selectionto] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {Record.forAllInd B
             proc{$ I V}
                case I
                of 1 then {self.TkVar tkSet(V)}
                [] selectionfrom then {ExecTk self selection('from' V)}
                [] selectionto then {ExecTk self selection(to V)}
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
                of 1 then {self.TkVar tkReturn(V)}
                end
                {Wait V}
             end}
         end
      end

      meth icursor(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth index(...)=M
         lock
            {ReturnTk self M natural}
         end
      end

      meth scan(...)=M
         lock
            {ExecTk self M}
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:Feature
                     qTkEntry:QTkEntry)}

end
