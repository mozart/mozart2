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
            assert:             Assert
            qTkClass:           QTkClass
            subtracts:          Subtracts
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget)

export
   WidgetType
   Feature
   TbButtonArea

define

   WidgetType=toolbar
   Feature=false
   BAI=r(bitmap:unit
         image:unit
         highlightbitmap:unit
         highlightimage:unit
         selectedbitmap:unit
         selectedimage:unit
         disabledimage:unit
         disabledbitmap:unit)
   TbTypeInfo=r(all:{Record.adjoin GlobalInitType
                     r(foreground:color fg:color
                       background:color bg:color
                       bitmap:bitmap
                       image:image
                       relief:relief
                       borderwidth:pixel
                       highlightforeground:color
                       highlightbackground:color
                       highlightbitmap:bitmap
                       highlightimage:image
                       highlightrelief:relief
                       highlightborderwidth:pixel
                       selectedforeground:color
                       selectedbackground:color
                       selectedbitmap:bitmap
                       selectedimage:image
                       selectedrelief:relief
                       selectedborderwidth:pixel
                       disabledforeground:color
                       disabledbackground:color
                       disabledbitmap:bitmap
                       disabledimage:image
                       disabledrelief:relief
                       disabledborderwidth:pixel
                       state:[normal disabled]
                       text:vs
%                      anchor:[n ne e se s sw w nw center]
                       action:action
                      )}
                uninit:r
                unset:GlobalUnsetType
                unget:{Record.adjoin GlobalUngetType BAI}
               )

   TbTypeDefault=r(foreground:black fg:black
                   background:gray bg:gray
                   relief:flat
                   borderwidth:2
                   highlightforeground:black
                   highlightbackground:gray
                   highlightrelief:raised
                   highlightborderwidth:2
                   selectedforeground:black
                   selectedbackground:gray
                   selectedrelief:sunken
                   selectedborderwidth:2
                   disabledforeground:white
                   disabledbackground:gray
                   disabledrelief:flat
                   disabledborderwidth:2
                  )

   SetBorder={NewName}

   class TbButtonArea

      from Tk.canvas QTkClass

      feat
         widgetType:toolbar
         typeInfo:TbTypeInfo
         action
         IconTag
         TextTag

      attr
         state
         normal
         highlight
         select
         disabled
         icon
         iconType
         text

      meth init(...)=M
         lock
            QTkClass,M
            normal<-r
            highlight<-r
            select<-r
            disabled<-r
            state<-normal
            icon<-nil
            iconType<-bitmap
            text<-nil
            {self SetBorderRec(TbTypeDefault)}
            {self SetBorderRec(r(image:nil bitmap:nil
                                 highlightimage:nil highlightbitmap:nil
                                 disabledimage:nil disabledbitmap:nil
                                 selectedimage:nil selectedbitmap:nil))}
            Tk.canvas,tkInit(parent:M.parent
                             highlightthickness:0
                             takefocus:false
                             width:1
                             height:1)
            self.IconTag={New Tk.canvasTag tkInit(parent:self)}
            self.TextTag={New Tk.canvasTag tkInit(parent:self)}
            {self {Record.adjoin
%                  {Subtracts M [parent action]}
                   {Subtracts M {List.map {Record.toListInd self.typeInfo.unset}
                                 fun{$ R} X in R=X#_ X end}}
                   set}}
            {self tkBind(event:"<Enter>"
                         append:true
                         action:self#Enter)}
            {self tkBind(event:"<Leave>"
                         append:true
                         action:self#Leave)}
            {self tkBind(event:"<1>"
                         action:self#Click)}
            {self tkBind(event:"<B1-Motion>"
                         args:[int(x) int(y)]
                         action:self#Motion)}
            {self tkBind(event:"<B1-ButtonRelease>"
                         action:self#Release)}
         end
      end

      meth SetBorderRec(M)
         lock
            proc{Set Name Sub Value}
               Name<-{Record.adjoinAt @Name Sub Value}
            end
         in
            {Record.forAllInd M
             proc{$ I V}
                case I
                of foreground then {Set normal I V}
                [] fg then {Set normal foreground V}
                [] background then {Set normal I V}
                [] bg then {Set normal background V}
                [] relief then {Set normal I V}
                [] borderwidth then {Set normal I V}
                [] bitmap then {Set normal I V}
                [] image then {Set normal I V}
                [] highlightforeground then {Set highlight foreground V}
                [] highlightbackground then {Set highlight background V}
                [] highlightrelief then {Set highlight relief V}
                [] highlightborderwidth then {Set highlight borderwidth V}
                [] highlightbitmap then {Set highlight bitmap V}
                [] highlightimage then {Set highlight image V}
                [] selectedforeground then {Set select foreground V}
                [] selectedbackground then {Set select background V}
                [] selectedrelief then {Set select relief V}
                [] selectedborderwidth then {Set select borderwidth V}
                [] selectedbitmap then {Set select bitmap V}
                [] selectedimage then {Set select image V}
                [] disabledforeground then {Set disabled foreground V}
                [] disabledbackground then {Set disabled background V}
                [] disabledrelief then {Set disabled relief V}
                [] disabledborderwidth then {Set disabled borderwidth V}
                [] disabledbitmap then {Set disabled bitmap V}
                [] disabledimage then {Set disabled image V}
                else skip end
             end}
         end
      end

      meth !SetBorder
         lock
            R=@@state
         in
            {self tk(configure
                     bg:R.background
                     relief:R.relief
                     borderwidth:R.borderwidth)}
         end
      end

      meth Display(T)
         lock
            fun{FNN L I T}
               case L
               of X|Xs then if X\=nil then
                               T=if {IsOdd I} then image else bitmap end
                               X
                            else
                               {FNN Xs I+1 T}
                            end
               [] nil then
                  T=bitmap
                  nil
               end
            end
            TIconType
            TIcon={FNN [@@state.image @@state.bitmap
                        @normal.image @normal.bitmap] 1 TIconType}
            proc{Replace}
               X1 Y1 X2 Y2
               X3 Y3 X4 Y4
               IX IY TX TY
               W H
            in
               [X1 Y1 X2 Y2]=if @icon==nil then [0 0 0 0]
                             else {self tkReturnListInt(bbox(self.IconTag) $)} end
               [X3 Y3 X4 Y4]=if @text==nil then [0 0 0 0]
                             else {self tkReturnListInt(bbox(self.TextTag) $)} end
               W={Max X4-X3 X2-X1}+4
               H=(Y4-Y3)+(Y2-Y1)+6
               IX=((W-(X2-X1)) div 2)+2
               IY=2
               TX=((W-(X4-X3)) div 2)+2
               TY=(Y2-Y1)+4
               if @icon==nil then skip else {self tk(move self.IconTag
                                                     IX-X1 IY-Y1)} end
               if @text==nil then skip else {self tk(move self.TextTag
                                                     TX-X3 TY-Y3)} end
               {self tk(configure width:W height:H)}
            end
         in
            if TIcon\=@icon then
               % the display of icon changes
               proc{Create}
                  if TIconType==bitmap then
                     {self tk(crea bitmap 0 0 anchor:nw tags:self.IconTag
                              bitmap:TIcon
                              background:""
                              foreground:black)}
                  else
                     {self tk(crea image 0 0 anchor:nw tags:self.IconTag
                              image:TIcon)}
                  end
               end
               proc{Delete}
                  {self tk(delete self.IconTag)}
               end
            in
               if @icon==nil then
                  % ceates a new icon
                  {Create}
               elseif TIcon==nil then
                  % deletes the old icon
                  {Delete}
               else
                  % modifies the old icon into the new one
                  if TIconType==@iconType then
                     {self tk(itemconfigure self.IconTag TIconType:TIcon)}
                  else
                     {Delete}
                     {Create}
                  end
               end
               icon<-TIcon
               iconType<-TIconType
               {Replace}
            end
            if T\=@text then
               % dispays another text
               if @text==nil then
                  % creates a new text
                  {self tk(create text 0 0 anchor:nw tags:self.TextTag
                           text:T)}
               elseif T==nil then
                  % deletes the old text
                  {self tk(delete self.TextTag)}
               else
                  % modifies the old text into the new one
                  {self tk(itemconfigure self.TextTag text:T)}
               end
               if T\=nil then
                  {self tk(itemconfigure self.TextTag fill:@@state.foreground)}
               end
               text<-T
               {Replace}
            end
         end
      end

      meth Enter
         lock
            case @state
            of normal then
               state<-highlight
               {self SetBorder}
            else skip end
         end
      end

      meth Leave
         lock
            case @state
            of highlight then
               state<-normal
               {self SetBorder}
            else skip end
         end
      end

      meth Click
         lock
            case @state
            of highlight then
               {self tk(move all 2 2)}
               state<-select
               {self SetBorder}
            else skip end
         end
      end

      meth Motion(X Y)
         lock
            W={self tkReturnInt(cget("-width") $)}
            H={self tkReturnInt(cget("-height") $)}
         in
            case @state
            of select then
               if X=<W andthen Y=<H andthen X>=0 andthen Y>=0 then
                  skip
               else
                  {self tk(move all ~2 ~2)}
                  state<-normal
                  {self SetBorder}
               end
            [] highlight then
               {self tk(move all 2 2)}
               state<-select
               {self SetBorder}
            [] normal then
               if X=<W andthen Y=<H andthen X>=0 andthen Y>=0 then
                  {self tk(move all 2 2)}
                  state<-select
                  {self SetBorder}
               else
                  skip
               end
            else skip end
         end
      end

      meth Release
         lock
            case @state
            of normal then skip
            [] select then
               {self tk(move all ~2 ~2)}
               state<-highlight
               {self SetBorder}
               {self execute}
            else skip end
         end
      end

      meth execute
         skip
      end

      meth destroy
         lock
            skip
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [action tooltips] B A}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {self SetBorderRec(B)} % set initial state
            {self SetBorder}
            {self Display({CondFeat B text @text})}
            {self tkBind(event:"<Enter>"
                         append:true
                         action:self#Enter)}
            {self tkBind(event:"<Leave>"
                         append:true
                         action:self#Leave)}
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M [action tooltips] B A}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {Record.forAllInd B
             proc{$ I V}
                V=case I
                  of foreground then            @normal.I
                  [] fg then                    @normal.foreground
                  [] background then            @normal.I
                  [] bg then                    @normal.background
                  [] relief then                @normal.relief
                  [] borderwidth then           @normal.borderwidth
                  [] highlightforeground then   @highlight.foreground
                  [] highlightbackground then   @highlight.background
                  [] highlightrelief then       @highlight.relief
                  [] highlightborderwidth then  @highlight.borderwidth
                  [] selectedforeground then    @select.foreground
                  [] selectedbackground then    @select.background
                  [] selectedrelief then        @select.relief
                  [] selectedborderwidth then   @select.borderwidth
                  [] disabledforeground then    @disabled.foreground
                  [] disabledbackground then    @disabled.background
                  [] disabledrelief then        @disabled.relief
                  [] disabledborderwidth then   @disabled.borderwidth
                  [] state then if @state==disabled then disabled else normal end
                  [] text then {VirtualString.toString @text}
                  end
             end}
         end
      end

   end

   class QTkTbbutton

      from TbButtonArea

      feat
         widgetType:tbbutton
         typeInfo:r(all:{Record.adjoin TbTypeInfo.all
                         r(return:free
                           state:[normal disabled selected])}
                    uninit:TbTypeInfo.uninit
                    unset:{Record.adjoinAt TbTypeInfo.unset return unit}
                    unget:{Record.adjoinAt TbTypeInfo.unget return unit})
         Return
         State

      meth tbbutton(...)=M
         lock
            self.Return={CondFeat M return _}
            {Assert self.widgetType self.typeInfo init(return:self.Return)}
            TbButtonArea,{Record.adjoin {Subtracts M [return]} init}
         end
      end

      meth execute
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

   end

   class QTkTbcheckbutton

      from TbButtonArea

      feat
         widgetType:tbcheckbutton
         typeInfo:r(all:{Record.adjoin TbTypeInfo.all
                         r(return:free
                           init:boolean
                           1:boolean)}
                    uninit:{Record.adjoin TbTypeInfo.uninit
                            r(1:boolean)}
                    unset:{Record.adjoin TbTypeInfo.unset
                           r(return:unit
                             init:unit)}
                    unget:{Record.adjoin TbTypeInfo.unget
                           r(return:unit
                             init:unit)})
         Return
      attr sel

      meth tbcheckbutton(...)=M
         lock
            sel<-{CondFeat M init false}
            self.Return={CondFeat M return _}
            {Assert self.widgetType self.typeInfo init(return:self.Return
                                                       init:@sel)}
            TbButtonArea,{Record.adjoin {Subtracts M [init return]} init}
         end
      end

      meth execute
         lock
            sel<-@sel==false
            {self SetBorder}
            {self.action execute}
         end
      end

      meth destroy
         lock
            self.Return=@sel
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            {Assert self.widgetType self.typeInfo B}
            TbButtonArea,A
            if {HasFeature B 1} then sel<-B.1 {self SetBorder} end
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            {Assert self.widgetType self.typeInfo B}
            TbButtonArea,A
            if {HasFeature B 1} then B.1=@sel end
         end
      end

      meth !SetBorder
         lock
            R=if @state==normal andthen @sel then
                 @select else @@state end
         in
            {self tk(configure
                     bg:R.background
                     relief:R.relief
                     borderwidth:R.borderwidth)}
         end
      end

   end

   class QTkTbradiobutton

      from QTkTbcheckbutton

      feat
         widgetTYpe:tbradiobutton
         typeInfo:r(all:{Record.adjoin TbTypeInfo.all
                         r(return:free
                           init:boolean
                           group:atom
                           1:boolean)}
                    uninit:{Record.adjoin TbTypeInfo.uninit
                            r(1:boolean)}
                    unset:{Record.adjoin TbTypeInfo.unset
                           r(return:unit
                             init:unit
                             group:unit)}
                    unget:{Record.adjoin TbTypeInfo.unget
                           r(return:unit
                             init:unit
                             group:unit)})
         Return
         Name
         Value
         TkVar

      meth tbradiobutton(...)=M
         lock
            if {HasFeature M group}==false then
               {Exception.raiseError qtk(missingParameter group self.widgetType M)}
            end
            sel<-{CondFeat M init false}
            self.Return={CondFeat M return _}
            self.Name=M.group
            {Assert self.widgetType self.typeInfo init(return:self.Return
                                                       init:@sel
                                                       group:self.Name)}
            TbButtonArea,{Record.adjoin {Subtracts M [init return]} init}
            local
               R={self.toplevel getRadioDict(self.Name $)}
            in
               self.TkVar=R.1
               self.Value=R.2+1
            end
            {self.toplevel askNotifyRadioButton(self.Name self)}
            if @sel then
               {self.TkVar tkSet(self.Value)}
               {self.toplevel notifyRadioButton(self.Name)}
            elseif {self.TkVar tkReturnInt($)}==self.Value then
               sel<-true
               {self SetBorder}
            end
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [1] A B}
            {Assert self.widgetType self.typeInfo B}
            TbButtonArea,A
            if {HasFeature B 1} then
               if B.1==false then
                  if @sel==false then skip
                  else
                     {self.TkVar tkSet(0)}
                     {self.toplevel notifyRadioButton(self.Name)}
                  end
               elseif @sel==false then
                  {self.TkVar tkSet(self.Value)}
                  {self.toplevel notifyRadioButton(self.Name)}
               end
            end
         end
      end

      meth execute
         lock
            {self.TkVar tkSet(self.Value)}
            {self.toplevel notifyRadioButton(self.Name)}
            {self.action execute}
         end
      end

      meth notify
         lock
            sel<-{self.TkVar tkReturnInt($)}==self.Value
            {self SetBorder}
         end
      end

      meth destroy
         lock
            self.Return=@sel
         end
      end


   end

   {RegisterWidget r(widgetType:tbbutton
                     feature:false
                     qTkTbbutton:QTkTbbutton)}

   {RegisterWidget r(widgetType:tbradiobutton
                     feature:false
                     qTkTbradiobutton:QTkTbradiobutton)}

   {RegisterWidget r(widgetType:tbcheckbutton
                     feature:false
                     qTkTbcheckbutton:QTkTbcheckbutton)}

end
