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
            tkInit:             TkInit
            assert:             Assert
            checkType:          CheckType
            condFeat:           CondFeat
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
   QTkListbox

define

   NoArgs={NewName}
   WidgetType=listbox
   Feature=scroll

   class QTkListbox

      feat
         widgetType:WidgetType
         action
         Return
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(1:listVs
                           init:listVs
                           return:free
                           reload:listVs
                           selection:listBoolean
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
                           scrollwidth:pixel)}
                    uninit:r(1:unit
                             reload:unit
                             reloadSelection:unit
                             firstselection:unit)
                    unset:{Record.adjoin GlobalUnsetType
                           r(lrscrollbar:unit
                             tdscrollbar:unit
                             scrollwidth:unit
                             init:unit
                             reload:unit
                             firstselection:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(lrscrollbar:unit
                             tdscrollbar:unit
                             scrollwidth:unit
                             init:unit
                             font:unit
                             selectmode:unit)}
                   )

      attr Content

      from Tk.listbox QTkClass

      meth listbox(...)=M
         lock
            A B
         in
            QTkClass,{Record.adjoin M init}
            {SplitParams M [lrscrollbar tdscrollbar scrollwidth init selection return] A B}
            Tk.listbox,{TkInit A}
            Content<-nil
            if {HasFeature B init} then {self set(B.init)} end
            if {HasFeature B selection} then {self set(selection:B.selection)} end
            {self tkBind(event:"<B1-ButtonRelease>" action:{self.action action($)})}
            {self tkBind(event:"<KeyRelease>" action:{self.action action($)})}
            self.Return={CondFeat B return _}
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [1 selection] A B}
            QTkClass,A
            if {HasFeature B 1} then
               ToSet={List.map B.1 VirtualString.toString}
               proc{Loop Left Right J}
                  case Left of X|Xs then
                     S E
                  in
                     {List.takeDropWhile Right
                      fun{$ Line} Line\=X end S E}
                     if E\=nil then % same element is found later
                        if S\=nil then % deletes unneeded elements
                           {self tk(delete J J+{Length S}-1)}
                        else skip end
                        {Loop Xs {List.drop E 1} J+1}
                     else
                        % insert the new element
                        {self tk(insert J X)}
                        {Loop Xs Right J+1}
                     end
                  else
                     % delete remaining element
                     if Right\=nil then
                        {self tk(delete J J+{Length Right}-1)}
                     else skip end
                  end
               end
            in
               {Loop ToSet @Content 0}
               Content<-ToSet
            end
            if {HasFeature B selection} then
               Max={self tkReturnInt(size $)}
               proc{Loop I L}
                  if I=<Max then
                     case L
                     of true|Xs then {self tk(selection set I-1 I-1)}
                        {Loop I+1 Xs}
                     [] false|Xs then {self tk(selection clear I-1 I-1)}
                        {Loop I+1 Xs}
                     else
                        {self tk(selection clear I-1 I-1)}
                        {Loop I+1 nil}
                     end
                  else skip end
               end
            in
               {Loop 1 B.selection}
            end
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M [1 selection reload firstselection] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            if {HasFeature B reload} then
               Content<-{self tkReturnList(get(0 'end') $)}
               {Wait @Content}
               B.reload=@Content
            end
            if {HasFeature B 1} then B.1=@Content end
            if {HasFeature B selection} then
               Max={self tkReturnInt(size $)}
            in
               if {Int.is Max}==false then
                  B.selection=nil
               else
                  Indices={self tkReturnListInt(curselection $)}
               in
                  B.selection={List.make Max}
                  {List.forAllInd B.selection
                   proc{$ I E}
                      E={List.member I-1 Indices}
                   end}
               end
            end
            if {HasFeature B firstselection} then
               L={self tkReturnListInt(curselection $)}
            in
               if {List.is L} andthen {Length L}>0 andthen {Int.is {List.nth L 1}} then
                  B.firstselection={List.nth L 1}+1
               else
                  B.firstselection=0
               end
            end
         end
      end

      meth activate(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth bbox(...)=M
         lock
            {ReturnTk self M listInt}
         end
      end

      meth delete(From ToI<=NoArgs)
         lock
            To=if ToI==NoArgs then From else ToI end
         in
            {ExecTk self delete(From To)}
            if {IsInt From} then
               if {IsInt To} andthen To>From then
                  Content<-{List.append
                            {List.take @Content From}
                            {List.drop @Content To+1}}
               elseif To=='end' then
                  Content<-{List.take @Content From}
               else
                  Content<-{self tkReturnList(get(0 'end') $)}
               end
            else
               Content<-{self tkReturnList(get(0 'end') $)}
               {Wait @Content}
            end
         end
      end

      meth index(...)=M
         lock
            {ReturnTk self M natural}
         end
      end

      meth insert(Where What)
         lock
            local
               Err={CheckType listVs What}
            in
               if Err==unit then skip else
                  {Exception.raiseError qtk(typeError 2 self.widgetType Err insert(Where What))}
               end
            end
            {ExecTk self insert(Where b(What))}
            if {IsInt Where} andthen Where>0 then
               Content<-{List.append
                         {List.take @Content Where}
                         {List.append
                          {List.map What VirtualString.toString}
                          {List.drop @Content Where}}}
            elseif Where=='end' then
               Content<-{List.append @Content {List.map What VirtualString.toString}}
            else
               Content<-{self tkReturnList(get(0 'end') $)}
            end
         end
      end

      meth nearest(...)=M
         lock
            {ReturnTk self M natural}
         end
      end

      meth scan(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth see(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth size(...)=M
         lock
            {ReturnTk self M natural}
         end
      end

      meth destroy
         lock
            self.Return=@Content
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:Feature
                     qTkListbox:QTkListbox)}

end
