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
            condFeat:           CondFeat
            subtracts:          Subtracts
            returnTk:           ReturnTk
            checkType:          CheckType
            makeClass:          MakeClass
            qTkClass:           QTkClass
            qTkAction:          QTkAction
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget)

export
   WidgetType
   Feature
   QTkMenubutton
   QTkMenu
   NewMenu

define

   WidgetType=menubutton
   Feature=menu

   fun{MakeMenu Def}
      if {Object.is Def} andthen {HasFeature Def widgetType} andthen Def.widgetType==menu then
         Def % Def is itself a correct menu (maybe created by NewMenu
      elseif {Record.is Def} andthen {Label Def}==menu then
         Def1={Subtracts Def [handle feature]}
         Obj={New {MakeClass QTkMenu Def1} Def1} % Def is a declaration of a menu : menu(...)
      in
         {CondFeat Def handle _}=Obj
         if {HasFeature Def feature} then
            (Def.parent).(Def.feature)=Obj
         end
         Obj
      else
         {Exception.raiseError qtk(typeError menu menu "A record declaring a menu or a menu object" Def)}
         nil
      end
   end

   class QTkMenubutton

      feat
         widgetType:menubutton
         action
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(activebackground:color
                           activeforeground:color
                           anchor:anchor
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
                           justify:[left center right]
                           ipadx:pixel
                           ipady:pixel
                           relief:relief
                           takefocus:boolean
                           text:vs
                           underline:natural
                           wraplength:pixel
                           direction:[above below left right flush]
                           height:pixel
                           indicatoron:boolean
                           menu:no
                           state:[normal active disabled]
                           width:pixel
                           action:action)}
                    uninit:r
                    unset:GlobalUnsetType
                    unget:{Record.adjoin GlobalUngetType
                           r(font:unit
                             image:unit)
                          }
                          )
         Act

      attr Menu

      from Tk.menubutton QTkClass

      meth menubutton(...)=M
         lock
            A B
         in
            QTkClass,{Record.adjoin M init}
            {SplitParams M [menu action ipadx ipady] A B}
            Tk.menubutton,{Record.adjoin {TkInit {Record.subtract A menu}}
                           tkInit(padx:{CondFeat B ipadx 2}
                                  pady:{CondFeat B ipady 2})}
            if {HasFeature B menu} then
               Menu<-{MakeMenu {Record.adjoinAt B.menu parent self}}
               Tk.menubutton,tk(configure menu:@Menu)
            else
               Menu<-nil
            end
            self.Act={New Tk.action tkInit(parent:self
                                           action:{{New QTkAction init(parent:self
                                                                       action:{CondFeat B action proc{$} skip end}
                                                                      )} action($)})}
            if @Menu\=nil then
               {@Menu tk(configure postcommand:self.Act)}
            end
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [menu ipadx ipady] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {Record.forAllInd B
             proc{$ I V}
                case I
                of menu then
                   if B.menu==nil then
                      Menu<-nil
                   else
                      Menu<-{New QTkMenu B.menu}
                      {@Menu tk(configure postcommand:self.Act)}
                   end
                   {ExecTk self configure(menu:@Menu)}
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
            {SplitParams M [menu ipadx ipady] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {Record.forAllInd B
             proc{$ I V}
                case I
                of menu then V=@Menu
                [] ipadx then {ReturnTk self cget("-padx" V) natural}
                [] ipady then {ReturnTk self cget("-pady" V) natural}
                end
             end}
         end
      end

      meth destroy
         lock
            if @Menu\=nil then
               {@Menu destroy}
            end
         end
      end

   end

   fun{MakeAccel Obj Rec}
      Binder=Rec.parent.toplevel
      fun {DoMakeEvent R}
         case R
         of ctrl(S) then 'Control-'#{DoMakeEvent S}
         [] alt(S) then 'Alt-'#{DoMakeEvent S}
         [] meta(S) then 'Meta-'#{DoMakeEvent S}
         else R
         end
      end
      fun {DoMakeKey R}
         case R
         of ctrl(S) then "C-"#{DoMakeKey S}
         [] alt(S) then "A-"#{DoMakeKey S}
         [] meta(S) then "M-"#{DoMakeKey S}
         else R
         end
      end
   in
      if {HasFeature Rec accelerator} then
         {Binder tkBind(event:"<"#{DoMakeEvent Rec.accelerator}#">"
                        action:Binder.port#r(Obj invoke))}
         {VirtualString.toString {DoMakeKey Rec.accelerator}}
      else '' end
   end

   class MenuEntry % like QTkClass but for menuentries only

      prop locking

      feat
         widgetType:menuentry
         tooltipsAvailable:false
         toplevel
         parent
         Private

      attr nu

      meth init(...)=M
         lock
            self.parent=M.parent
            self.toplevel=M.parent.toplevel
            {Assert self.widgetType self.typeInfo M}
            nu<-M.nu
            if {HasFeature self action} then % action widget
               self.action={New QTkAction init(parent:self action:{CondFeat M action proc{$} skip end})}
            end
            self.Private=M.private
         end
      end

      meth set(...)=M
         lock
            Pad={self.parent tkReturnInt(cget("-tearoff") $)}
         in
            {Assert self.widgetType self.typeInfo M}
            if {HasFeature self action} andthen {HasFeature M action} then
               {self.action set(M.action)}
            end
            {Record.forAllInd {Subtracts M [action]}
             proc{$ I V}
                if I==text then
                   {ExecTk self.parent entryconfigure(@nu+Pad-1 label:V)}
                else
                   {ExecTk self.parent entryconfigure(@nu+Pad-1 I:V)}
                end
             end}
         end
      end

      meth get(...)=M
         lock
            Pad={self.parent tkReturnInt(cget("-tearoff") $)}
         in
            {Assert self.widgetType self.typeInfo M}
            if {HasFeature self action} andthen {HasFeature M action} then
               {self.action get(M.action)}
            end
            {Record.forAllInd {Subtracts M [action]}
             proc{$ I R}
                if I==text then
                   {ReturnTk self.parent entrycget(@nu+Pad-1 "-"#label R) self.typeInfo.all.I}
                else
                   {ReturnTk self.parent entrycget(@nu+Pad-1 "-"#I R) self.typeInfo.all.I}
                end
             end}
         end
      end

      meth invoke
         lock
            Pad={self.parent tkReturnInt(cget("-tearoff") $)}
         in
            {ExecTk self.parent invoke(@nu+Pad-1)}
         end
      end

      meth delete
         lock
            Pad={self.parent tkReturnInt(cget("-tearoff") $)}
         in
            {ExecTk self.parent delete(@nu+Pad-1)}
            {self.parent {Record.adjoin r(@nu) (self.Private).delete}}
         end
      end

      meth yposition(P)
         lock
            Pad={self.parent tkReturnInt(cget("-tearoff") $)}
         in
            {ReturnTk self.parent yposition(@nu+Pad-1 P) natural}
         end
      end

      meth chgNu(Val)
         lock
            nu<-Val
         end
      end

      meth destroy
         lock
            skip
         end
      end
   end

   class MenuCommand

      from Tk.menuentry.command MenuEntry

      feat
         widgetType:menuentrycommand
         typeInfo:r(all:r(parent:no
                          nu:natural
                          private:no
                          activebackground:color
                          activeforeground:color
                          background:color
                          bitmap:bitmap
                          columnbreak:boolean
                          font:font
                          foreground:color
                          hidemargin:boolean
                          image:image
                          state:[normal active disabled]
                          underline:natural
                          text:vs
                          action:action
                          accelerator:no
                          return:free)
                    uninit:r
                    unset:r(nu:unit private:unit)
                    unget:r(nu:unit private:unit))
         action
         Return


      meth command(...)=M
         lock
            MenuEntry,{Record.adjoin M init}
            Tk.menuentry.command,{Record.adjoin {Subtracts M [return text nu private]}
                                  tkInit(action:self.toplevel.port#r(self Execute)
                                         accelerator:{MakeAccel self M}
                                         label:{CondFeat M text ""})}
            self.Return={CondFeat M return _}
         end
      end

      meth Execute
         lock
            {self.toplevel setDestroyer(self)}
            {self.action execute}
         end
      end

      meth destroy
         lock
            self.Return={self.toplevel getDestroyer($)}==self
         end
      end

      meth type(T)
         lock
            T=command
         end
      end

   end

   class MenuSeparator

      from Tk.menuentry.separator MenuEntry

      feat
         widgetType:menuentryseparator
         typeInfo:r(all:r(parent:no
                          nu:natural
                          private:no
                          columnbreak:boolean
                          hidemargin:boolean)
                    uninit:r
                    unset:r(nu:unit private:unit)
                    unget:r(nu:unit private:unit))

      meth separator(...)=M
         lock
            MenuEntry,{Record.adjoin M init}
            Tk.menuentry.command,{Record.adjoin {Subtracts M [nu private]}
                                  tkInit}
         end
      end

      meth type(T)
         lock
            T=separator
         end
      end

   end

   class MenuCheckbutton

      from Tk.menuentry.checkbutton MenuEntry

      feat
         widgetType:menuentrycheckbutton
         typeInfo:r(all:r(parent:no
                          1:boolean
                          init:boolean
                          nu:natural
                          private:no
                          activebackground:color
                          activeforeground:color
                          background:color
                          bitmap:bitmap
                          columnbreak:boolean
                          font:font
                          foreground:color
                          hidemargin:boolean
                          image:image
                          indicatoron:boolean
                          selectcolor:color
                          selectimage:image
                          state:[normal active disabled]
                          underline:natural
                          text:vs
                          action:action
                          accelerator:vs
                          return:free)
                    uninit:r(1:unit)
                    unset:r(init:unit
                            nu:unit
                            accelerator:unit
                            private:unit)
                    unget:r(init:unit
                            nu:unit
                            accelerator:unit
                            private:unit))
         action
         Return
         TkVar


      meth checkbutton(...)=M
         lock
            MenuEntry,{Record.adjoin M init}
            self.TkVar={New Tk.variable tkInit({CondFeat M init false})}
            Tk.menuentry.checkbutton,{Record.adjoin {Subtracts M [text return nu private init]}
                                      tkInit(variable:self.TkVar
                                             offvalue:false
                                             onvalue:true
                                             action:{self.action action($)}
                                             accelerator:{MakeAccel self M}
                                             label:{CondFeat M text ""})}
            self.Return={CondFeat M return _}
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            MenuEntry,A
            if {HasFeature B 1} then
               Err={CheckType boolean B.1}
            in
               if Err==unit then skip else
                  {Exception.raiseError qtk(typeError 1 self.widgetType Err M)}
               end
               {self.TkVar tkSet(B.1)}
            end
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            MenuEntry,A
            if {HasFeature B 1} then
               Err={CheckType free B.1}
            in
               if Err==unit then skip else
                  {Exception.raiseError qtk(typeError 1 self.widgetType Err M)}
               end
               B.1={self.TkVar tkReturn($)}=="1"
            end
         end
      end

      meth type(T)
         lock
            T=checkbutton
         end
      end

      meth destroy
         lock
            self.Return={self.TkVar tkReturn($)}=="1"
         end
      end

   end

   class MenuRadiobutton

      from Tk.menuentry.radiobutton MenuEntry

      feat
         widgetType:menuentryradiobutton
         typeInfo:r(all:r(parent:no
                          1:boolean
                          init:boolean
                          nu:natural
                          private:no
                          group:atom
                          activebackground:color
                          activeforeground:color
                          background:color
                          bitmap:bitmap
                          columnbreak:boolean
                          font:font
                          foreground:color
                          hidemargin:boolean
                          image:image
                          indicatoron:boolean
                          selectcolor:color
                          selectimage:image
                          state:[normal active disabled]
                          underline:natural
                          text:vs
                          action:action
                          accelerator:vs
                          return:free)
                    uninit:r(1:unit)
                    unset:r(init:unit
                            nu:unit
                            accelerator:unit
                            private:unit
                            group:unit
                            return:unit)
                    unget:r(init:unit
                            nu:unit
                            accelerator:unit
                            private:unit
                            group:unit
                            return:unit))
         action
         Return
         Name
         TkVar
         Value

      meth radiobutton(...)=M
         lock
            A
         in
            MenuEntry,{Record.adjoin M init}
            if {HasFeature M group}==false then
               {Exception.raiseError qtk(missingParameter group self.widgetType M)}
            end
            self.Return={CondFeat M return _}
            {SplitParams M [init nu private label return] A _}
            self.Name=A.group
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
            Tk.menuentry.radiobutton,{Record.adjoin {Subtracts M [text return nu private group init]}
                                      tkInit(variable:self.TkVar
                                             value:self.Value
                                             action:self.toplevel.port#r(self Execute)
                                             accelerator:{MakeAccel self M}
                                             label:{CondFeat M text ""})}
         end
      end

      meth Execute
         lock
            {self.toplevel notifyRadioButton(self.Name)}
            {self.action execute}
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            MenuEntry,A
            if {HasFeature B 1} then
               Err={CheckType boolean B.1}
            in
               if Err==unit then skip else
                  {Exception.raiseError qtk(typeError 1 self.widgetType Err M)}
               end
               if B.1 then
                  {self.TkVar tkSet(self.Value)}
                  {self.toplevel notifyRadioButton(self.Name)}
               else
                  if {self.TkVar tkReturnInt($)}==self.Value then
                     {self.TkVar tkSet(0)}
                     {self.toplevel notifyRadioButton(self.Name)}
                  end
               end
            end
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            MenuEntry,A
            if {HasFeature B 1} then
               Err={CheckType free B.1}
            in
               if Err==unit then skip else
                  {Exception.raiseError qtk(typeError 1 self.widgetType Err M)}
               end
               B.1={self.TkVar tkReturnInt($)}==self.Value
            end
         end
      end

      meth type(T)
         lock
            T=radiobutton
         end
      end

      meth destroy
         lock
            self.Return={self.TkVar tkReturn($)}==self.Value
         end
      end

   end

   class MenuCascade

      from Tk.menuentry.cascade MenuEntry

      feat
         widgetType:menuentrycascade
         typeInfo:r(all:r(parent:no
                          nu:natural
                          private:no
                          activebackground:color
                          activeforeground:color
                          background:color
                          bitmap:bitmap
                          columnbreak:boolean
                          font:font
                          foreground:color
                          hidemargin:boolean
                          image:image
                          state:[normal active disabled]
                          underline:natural
                          text:vs
                          action:action
                          accelerator:no
                          menu:no)
                    uninit:r
                    unset:r(nu:unit private:unit)
                    unget:r(nu:unit private:unit))
         action
      attr
         Menu

      meth cascade(...)=M
         lock
            A B Pad
         in
            MenuEntry,{Record.adjoin M init}
            {SplitParams M [menu action text nu private] A B}
            Tk.menuentry.cascade,{Record.adjoin A
                                  tkInit(action:{self.action action($)}
                                         accelerator:{MakeAccel self M}
                                         label:{CondFeat M text ""})}
            Menu<-{MakeMenu {Record.adjoinAt B.menu parent self.parent}}
            Pad={self.parent tkReturnInt(cget("-tearoff") $)}
            {self.parent tk(entryconfigure B.nu+Pad-1 menu:@Menu)}
         end
      end

      meth type(T)
         lock
            T=cascade
         end
      end

   end

   MenuObj=r(command:MenuCommand
             separator:MenuSeparator
             checkbutton:MenuCheckbutton
             radiobutton:MenuRadiobutton)

   class QTkMenu

      feat
         widgetType:menu
         action
         typeInfo:r(all:r(parent:no
                          activebackground:color
                          activeborderwidth:pixel
                          activeforeground:color
                          background:color bg:color
                          borderwidth:pixel
                          cursor:cursor
                          disabledforeground:color
                          font:font
                          foreground:color fg:color
                          relief:relief
                          takefocus:boolean
                          selectcolor:color
                          tearoff:boolean
                          title:vs
                          type:[menubar tearoff normal]
                          action:action)
                    uninit:r
                    unset:r
                    imget:r)
         BuildChild

      attr Children

      from Tk.menu QTkClass

      meth menu(...)=M
         lock
            A B C
         in
            {Record.partitionInd M
             fun{$ I V}
                I\=action andthen {Not {Int.is I}}
             end
             A B}
            local
               Err={CheckType action {CondFeat B action proc{$} skip end}}
            in
               if Err==unit then skip else
                  {Exception.raiseError qtk(typeError action self.widgetType Err M)}
               end
            end
            QTkClass,{Record.adjoin A init}
            Tk.menu,{Record.adjoin A tkInit}
            C={Record.toList {Record.subtract B action}}
            self.BuildChild=fun{$ I Def}
                               Lab={Label Def}
                               R={Subtracts {Record.adjoin Def Lab(parent:self
                                                                   nu:I
                                                                   private:r(delete:Delete))} [handle feature]}
                               Obj=case Lab
                                   of cascade then {New {MakeClass MenuCascade Def} R}
                                   else {New MenuObj.{Label Def} R} end
                               if {HasFeature Def handle} then Def.handle=Obj end
                               if {HasFeature Def feature} then self.(Def.feature)=Obj end
                            in
                               Obj
                            end
            Children<-{List.mapInd C self.BuildChild}
         end
      end

      meth Delete(N)
         lock
            Children<-{List.filterInd @Children
                       fun{$ I C}
                          if I<N then
                             true
                          elseif I>N then
                             {C chgNu(I-1)}
                             true
                          else false end
                       end}
         end
      end

%      meth clone(...)=M
%        lock
%           {ExecTk self M}
%        end
%      end

      meth insert(Where What)=Rec
         lock
            Pad={self.parent tkReturnInt(cget("-tearoff") $)}
            Err={CheckType natural Where}
            if Err==unit then skip else
               {Exception.raiseError qtk(typeError 1 self.widgetType Err Rec)}
            end
            C={self.BuildChild Where+Pad-1 What}
         in
            Children<-{List.append {List.take @Children Where-1}
                       C|{List.drop @Children Where+1}}
            {List.forAllInd @Children proc{$ I C} {C chgNu(I)} end}
         end
      end

      meth index(Where O)
         lock
            N
            Pad={self.parent tkReturnInt(cget("-tearoff") $)}
         in
            try
               {ReturnTk self index(Where N) natural}
               O={List.nth @Children N+Pad-1}
            catch _ then O=none end
         end
      end

      meth post(...)=M
         lock
            {ExecTk self M}
         end
      end

      meth destroy
         lock
            {ForAll @Children
             proc{$ C}
                {C destroy}
             end}
         end
      end

   end

   {RegisterWidget r(widgetType:WidgetType
                     feature:Feature
                     qTkMenubutton:QTkMenubutton)}

   fun{NewMenu M}
      {New QTkMenu M}
   end

end
