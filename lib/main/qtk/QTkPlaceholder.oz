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
            mapLabelToObject:   MapLabelToObject
%           subtracts:          Subtracts
            execTk:             ExecTk
            condFeat:           CondFeat
            assert:             Assert
            qTkClass:           QTkClass
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget
            splitParams:        SplitParams)

export
   WidgetType
   Feature
   QTkPlaceholder

define

   WidgetType=placeholder
   Feature=true

   class QTkPlaceholder

      from Tk.frame QTkClass

      prop locking

      feat
         widgetType:WidgetType
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(1:no
                           borderwidth:pixel
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
                           visual:no)}
                    uninit:r
                    unset:{Record.adjoin GlobalUnsetType
                           r('class':unit
                             colormap:unit
                             container:unit
                             visual:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(bitmap:unit
                             font:unit)})
      attr Child Pack

      meth placeholder(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            QTkClass,{Record.adjoin A init}
            Tk.frame,{TkInit A}
            %% B contains the structure of
            %% creates the children
            Child<-empty
            Pack<-nil
            {Tk.batch [grid(rowconfigure self 0 weight:1)
                       grid(columnconfigure self 0 weight:1)]}
            if {HasFeature B 1} andthen B.1\=empty then
               {self set(B.1)}
            end
         end
      end

      meth set(...)=M
         lock
            A C
         in
            {SplitParams M [1] A C}
            QTkClass,A
            if {HasFeature C 1} then
               NC P B=C.1
            in
               if {Object.is B} andthen {HasFeature B parent} then
                  NC=B
               elseif {Label B}==empty then
                  NC=empty
               else
                  NC={MapLabelToObject {Record.adjoinAt B parent self}}
%                 if {HasFeature B feature} then
%                    try
%                       self.(B.feature)=NC
%                    catch _ then
%                       {Exception.raiseError qtk(badParameter feature {Label B} M)}
%                    end
%                 end
%                 if {HasFeature B handle} andthen {IsFree B.handle} then
%                    B.handle=NC
%                 end
                  Pack<-r(obj:NC
                          sticky:{CondFeat B glue ""}
                          padx:{CondFeat B padx 0}
                          pady:{CondFeat B pady 0})|@Pack
               end
               if {IsFree NC} then {Exception.raiseError qtk(badParameter 1 self.widgetType M)} end
               {ForAll @Pack proc{$ R} if R.obj==NC then P=R end end}
               if @Child\=empty then {Tk.send grid(forget @Child)} end
               if NC\=empty then
                  if {IsFree P} then {Exception.raiseError qtk(badParameter 1 self.widgetType M)} end
                  {ExecTk unit grid(NC row:0 column:0
                                    sticky:P.sticky
                                    padx:P.padx
                                    pady:P.pady)}
               end
               Child<-NC
            end
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {CondFeat B 1 _}=@Child
         end
      end

      meth destroy
         lock
            if @Child==empty then skip else
               try {@Child destroy} catch _ then skip end
            end
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:Feature
                     qTkPlaceholder:QTkPlaceholder)}

end
