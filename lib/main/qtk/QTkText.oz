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
            execTk:             ExecTk
            lastInt:            LastInt
            condFeat:           CondFeat
            subtracts:          Subtracts
            returnTk:           ReturnTk
            mapLabelToObject:   MapLabelToObject
            qTkClass:           QTkClass
            qTkAction:          QTkAction
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget)

export
   WidgetType
   Feature
   QTkText

define

   WidgetType=text
   Feature=scroll
   NoArgs={NewName}

   fun{Purge Rec}
      {Record.map Rec
       fun{$ J}
          if {IsDet J} andthen {IsRecord J} then
             case {Label J}
             of coord then J.1#"."#J.2-1
             [] pixel then "@"#J.1#","#J.2
             [] chars then v(if J.1<0 then "- "#~J.1 else "+ "#J.1 end#" chars")
             [] lines then v(if J.1<0 then "- "#~J.1 else "+ "#J.1 end#" lines")
             else J end
          else J end
       end}
   end

   proc{TExecTk Obj Msg}
      {ExecTk Obj {Purge Msg}}
   end

   fun{ToCoord S}
      X Y
   in
      {List.takeDropWhile S fun{$ C} C\=46 end X Y}
      coord({String.toInt X} {String.toInt {List.drop Y 1}}+1)
   end

   proc{TReturnTk Obj Msg Type}
      if Type==coord then
         Last={LastInt Msg}
         Ret=Msg.Last
         Temp
      in
         {ReturnTk Obj {Record.adjoinAt
                        {Purge {Record.subtract Msg Last}}
                        Last Temp} no}
         Ret=if Temp=="" then false else {ToCoord Temp} end
      else
         {ReturnTk Obj {Purge Msg} Type}
      end
   end

   class QTkText

      feat
         widgetType:WidgetType
         action
         Return
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(1:vs
                           init:vs
                           return:free
                           background:color bg:color
                           borderwidth:pixel
                           cursor:cursor
                           exportselection:boolean
                           font:font
                           foreground:color
                           highlightbackground:color
                           highlightcolor:color
                           highlightthickness:pixel
                           insertbackground:color
                           insertborderwidth:pixel
                           insertofftime:natural
                           insertontime:natural
                           insertwidth:pixel
                           ipadx:pixel
                           ipady:pixel
                           relief:relief
                           selectbackground:color
                           selectborderwidth:pixel
                           selectforeground:color
                           setgrid:boolean
                           takefocus:boolean
                           height:pixel
                           spacing1:pixel
                           spacing2:pixel
                           spacing3:pixel
                           state:[normal disabled]
                           tabs:no
                           width:pixel
                           wrap:[none char word]
                           action:action
                           lrscrollbar:boolean
                           tdscrollbar:boolean
                           scrollwidth:pixel)}
                    uninit:r(1:unit)
                    unset:{Record.adjoin GlobalUnsetType
                           r(lrscrollbar:unit
                             tdscrollbar:unit
                             scrollwidth:unit
                             init:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(lrscrollbar:unit
                             tdscrollbar:unit
                             scrollwidth:unit
                             init:unit
                             font:unit)}
                   )

      attr Windows:nil

      from Tk.text QTkClass

      meth text(...)=M
         lock
            A B
         in
            QTkClass,{Record.adjoin M init}
            {SplitParams M [lrscrollbar tdscrollbar scrollwidth init return ipadx ipady] A B}
            Tk.text,{Record.subtract
                     {Record.adjoin {TkInit A} tkInit(padx:{CondFeat B ipadx 0}
                                                      pady:{CondFeat B ipady 0})}
                     state}
            {self tkBind(event:"<KeyRelease>" action:{self.action action($)})}
            if {HasFeature B init} then {self set(B.init)} end
            {self tk(configure state:{CondSelect A state normal})}
            self.Return={CondFeat B return _}
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [1 ipadx ipady] A B}
            QTkClass,A
            {Record.forAllInd B
             proc{$ I V}
                case I
                of 1 then
                   {ExecTk self delete("1.0" "end")}
                   {ExecTk self insert("1.0" B.1)}
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
                of 1 then {self getText("1.0" "end" V)}
                [] ipadx then {ReturnTk self cget("-padx" V) natural}
                [] ipady then {ReturnTk self cget("-pady" V) natural}
                end
             end}
         end
      end

      meth bbox(...)=M
         lock
            {TReturnTk self M listInt}
         end
      end

      meth compare(...)=M
         lock
            {TReturnTk self M boolean}
         end
      end

      meth delete(...)=M
         lock
            {TExecTk self M}
         end
      end

      meth dlineinfo(...)=M
         lock
            {TReturnTk self M listInt}
         end
      end

      meth dump(...)=M
         lock
            {TReturnTk self M listAtom}
         end
      end

      meth getText(...)=M
         lock
            {TReturnTk self {Record.adjoin M get} no}
         end
      end

      meth newImage(...)=M
         lock
            Self=self
            Last={LastInt M}
            Img=M.Last
            class TextImage
               feat
                  widgetType:textimage
                  typeInfo:r(all:r(align:[top center bottom baseline]
                                   1:no
                                   image:image
                                   padx:pixel
                                   pady:pixel)
                             uninit:r
                             unset:r(image:unit
                                     1:unit)
                             unget:r(image:unit
                                    1:unit))
               from QTkClass
               meth init(...)=M
                  lock
                     self.parent=Self
                     self.toplevel=Self.toplevel
                     {Assert self.widgetType self.typeInfo M}
                     {TExecTk Self image(create M.1
                                         d({Subtracts M [1]}))}
                  end
               end
               meth set(...)=M
                  lock
                     {Assert self.widgetType self.typeInfo M}
                     {TExecTk Self image(configure self d(M))}
                  end
               end
               meth get(...)=M
                  lock
                     {Assert self.widgetType self.typeInfo M}
                     {Record.forAllInd M
                      proc{$ I V}
                         {TReturnTk Self image(cget self "-"#I V) self.typeInfo.all.I}
                      end}
                  end
               end
            end
         in
            Img={New TextImage {Record.adjoin {Record.subtract M Last} init}}
         end
      end

      meth index(...)=M
         lock
            {TReturnTk self M coord}
         end
      end

      meth insert(...)=M
         lock
            {TExecTk self M}
         end
      end

      meth newMark(Mark<=NoArgs insert:I<=NoArgs current:C<=NoArgs)=M
         lock
            Self=self
            class TextMark
               from QTkClass Tk.textMark
               feat widgetType:textmark
                  Mark
               meth init(...)=M
                  lock
                     self.parent=Self
                     self.toplevel=Self.toplevel
                     self.Mark=case M.type
                               of 1 then {New Tk.textMark tkInit(parent:self.parent)}
                               else M.type
                               end
                  end
               end
               meth gravity(D)
                  lock
                     {TExecTk Self mark(gravity self.Mark D)}
                  end
               end
               meth set(Index)
                  lock
                     {TExecTk Self mark(set self.Mark Index)}
                  end
               end
               meth unset
                  lock
                     {TExecTk Self mark(unset self.Mark)}
                  end
               end
            end
         in
            {Record.forAllInd M
             proc{$ I V}
                if {IsFree V} then
                   V={New TextMark init(parent:self type:I)}
                end
             end}
         end
      end

      meth scan(...)=M
         lock
            {TExecTk self M}
         end
      end

      meth search(...)=M
         lock
            {TReturnTk self M coord}
         end
      end

      meth see(...)=M
         lock
            {TExecTk self M}
         end
      end

      meth newTag(Tag)
         lock
            Self=self
            fun{TAdd M}
               {List.toRecord
                tag
                1#{Label M}|2#Tag|{List.map
                             {Record.toListInd M}
                             fun{$ R}
                                case R of I#V then if {IsInt I} then I+2#V else I#V end end
                             end}}
            end
            proc{RExecTk M}
               {TExecTk Self {TAdd M}}
            end
            proc{RReturnTk M Type}
               {TReturnTk Self {TAdd M} Type}
            end
            class TextTag
               from Tk.textTag QTkClass
               feat widgetType:texttag
                  typeInfo:r(all:r(parent:no
                                   background:color
                                   bgstipple:bitmap
                                   borderwidth:pixel
                                   fgstipple:bitmap
                                   font:font
                                   foreground:color
                                   justify:[left right center]
                                   lmargin1:pixel
                                   lmargin2:pixel
                                   offset:pixel
                                   overstrike:boolean
                                   relief:relief
                                   rmargin:pixel
                                   spacing1:pixel
                                   spacing2:pixel
                                   spacing3:pixel
                                   tabs:no
                                   underline:boolean
                                   wrap:[none char word])
                             uninit:r
                             unset:r(parent:unit)
                             unget:r(parent:unit
                                     font:unit
                                     bgstipple:unit
                                     fgstipple:unit
                                     tabs:unit))
                  first last

               meth init(...)=M
                  lock
                     self.parent=Self
                     self.toplevel=Self.toplevel
                     {Assert self.widgetType self.typeInfo M}
                     Tk.textTag,{Record.adjoin M tkInit}
                     self.first=self#".first"
                     self.last=self#".last"
                  end
               end
               meth set(...)=M
                  lock
                     {Assert self.widgetType self.typeInfo M}
                     {RExecTk {Record.adjoin M configure}}
                  end
               end
               meth get(...)=M
                  lock
                     {Assert self.widgetType self.typeInfo M}
                     {Record.forAllInd M
                      proc{$ I V}
                         {RReturnTk cget("-"#I V) self.typeInfo.all.I}
                      end}
                  end
               end
               meth add(...)=M
                  lock
                     {RExecTk M}
                  end
               end
               meth bind(action:A<=proc{$} skip end event:E args:G<=nil)
                  lock
                     Command={New Tk.action tkInit(parent:self
                                                   action:{{New QTkAction init(parent:self action:A)} action($)}
                                                   args:G)}
                  in
                     {RExecTk bind(E Command)}
                  end
               end
               meth delete=M
                  lock
                     {RExecTk M}
                  end
               end
               meth lower=M
                  lock
                     {RExecTk M}
                  end
               end
               meth Range(M)
                  lock
                     Last={LastInt M}
                     Ret=M.Last
                     Temp
                  in
                     {RReturnTk {Record.adjoinAt M Last Temp} list}
                     Ret={List.map Temp ToCoord}
                  end
               end
               meth nextrange(...)=M
                  {self Range(M)}
               end
               meth prevrange(...)=M
                  {self Range(M)}
               end
               meth 'raise'=M
                  lock
                     {RExecTk M}
                  end
               end
               meth ranges(...)=M
                  {self Range(M)}
               end
               meth remove(...)=M
                  lock
                     {RExecTk M}
                  end
               end
            end
         in
            Tag={New TextTag init(parent:self)}
         end
      end

      meth newWindow(...)=M
         lock
            Self=self
            Last={LastInt M}
            Win=M.Last
            class TextWindow
               feat
                  widgetType:textwindow
                  typeInfo:r(all:r(1:no
                                   2:no
                                   align:[top center bottom baseline]
                                   stretch:boolean
                                   padx:pixel
                                   pady:pixel
                                   handle:free)
                             uninit:r
                             unset:r(1:unit
                                     2:unit)
                             unget:r(1:unit
                                     2:unit))
                  Window

               from QTkClass
               meth init(...)=M
                  lock
                     self.parent=Self
                     self.toplevel=Self.toplevel
                     {Assert self.widgetType self.typeInfo M}
                     self.Window={MapLabelToObject {Record.adjoinAt M.2 parent Self}}
                  in
                     {TExecTk Self window(create M.1
                                          d({Record.adjoinAt
                                             {Subtracts M [1 2]}
                                             window self.Window}))}
                     {CondFeat M handle _}=self.Window
                  end
               end
               meth set(...)=M
                  lock
                     {Assert self.widgetType self.typeInfo M}
                     {TExecTk Self window(configure self d(M))}
                  end
               end
               meth get(...)=M
                  lock
                     {Assert self.widgetType self.typeInfo M}
                     {Record.forAllInd M
                      proc{$ I V}
                         {TReturnTk Self window(cget self "-"#I V) self.typeInfo.all.I}
                      end}
                  end
               end
               meth destroy
                  lock
                     {self.Window destroy}
                  end
               end
            end
         in
            Win={New TextWindow {Record.adjoin {Record.subtract M Last} init}}
            Windows<-Win|@Windows
         end
      end

      meth destroy
         lock
            self.Return={self get($)}
            {ForAll @Windows proc{$ W} {W destroy} end}
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:Feature
                     qTkText:QTkText)}

end
