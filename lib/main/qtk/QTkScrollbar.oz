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
   QTkDevel(tkInit:             TkInit
            qTkClass:           QTkClass
            execTk:             ExecTk
            returnTk:           ReturnTk
            splitParams:        SplitParams
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget)

export
   WidgetType
   Feature
   QTkScrollbar

define

   WidgetType=scrollbar
   Feature=false

   class QTkScrollbar

      feat
         widgetType:WidgetType
         action
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(1:float
                           2:float
                           activebackground:color
                           background:color bg:color
                           borderwidth:pixel
                           cursor:cursor
                           highlightbackground:color
                           highlightcolor:color
                           highlightthickness:pixel
                           jump:boolean
                           relief:relief
                           repeatdelay:natural
                           repeatinterval:natural
                           takefocus:boolean
                           troughcolor:color
                           activerelief:relief
                           action:action
                           elementborderwidth:pixel
                           width:pixel)}
                    uninit:r(1 2)
                    unset:GlobalUnsetType
                    unget:{Record.adjoin GlobalUngetType
                           r(2:unit)}
                   )

      from Tk.scrollbar QTkClass

      meth Scrollbar(M Orient)
         lock
            QTkClass,{Record.adjoin M init}
            Tk.scrollbar,{Record.adjoin {TkInit M}
                          tkInit(action:self.toplevel.port#r(self Execute)
                                 orient:Orient
                                )}
         end
      end

      meth tdscrollbar(...)=M
         lock
            {self Scrollbar(M vert)}
         end
      end

      meth lrscrollbar(...)=M
         lock
            {self Scrollbar(M horiz)}
         end
      end

      meth Execute(...)
         lock
            {self.action execute}
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [1 2] A B}
            QTkClass,A
            if {HasFeature B 1} andthen {HasFeature B 2} then
               {ExecTk self set(B.1 B.2)}
            end
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            QTkClass,A
            {Record.forAllInd B
             proc{$ I V}
                case I
                of 1 then
                   {ReturnTk self get(V) listFloat}
                end
             end}
         end
      end

      meth activate(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth delta(...)=M
         lock
            {ReturnTk self M float}
         end
      end

      meth fraction(...)=M
         lock
            {ReturnTk self M float}
         end
      end

      meth identify(...)=M
         lock
            {ReturnTk self M atom}
         end
      end

   end

   {RegisterWidget r(widgetType:tdscrollbar
                     feature:false
                     qTkTdscrollbar:QTkScrollbar)}

   {RegisterWidget r(widgetType:lrscrollbar
                     feature:false
                     qTkLrscrollbar:QTkScrollbar)}

end
