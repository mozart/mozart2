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
            checkType:          CheckType
%           execTk:             ExecTk
            splitParams:        SplitParams
            assert:             Assert
            qTkClass:           QTkClass
            globalInitType:     GlobalInitType
            globalUnsetType:    GlobalUnsetType
            globalUngetType:    GlobalUngetType
            registerWidget:     RegisterWidget
            propagateLook:      PropagateLook)

export
   WidgetType
   Feature
   QTkRubberframe

define

   WidgetType=rubberframe
   Feature=true

   SepSize=6

   class QTkSep

      from Tk.canvas

      prop locking

      feat vert nu parent port

      attr ox

      meth sep(parent:Parent nu:Nu vert:Vert)
         lock
            self.parent=Parent
            self.nu=Nu
            self.vert=Vert
            Tk.canvas,tkInit(parent:Parent
                             width:if Vert then 1 else SepSize end
                             height:if Vert then SepSize else 1 end
                             relief:raised
                             borderwidth:1
                             cursor:if Vert then
                                       sb_h_double_arrow
                                    else
                                       sb_v_double_arrow
                                    end)
            local
               Out
               proc{Loop L}
                  case L
                  of motion(X Y)|Ls then
                     if {IsDet Ls} then
                        case Ls
                        of motion(_ _)|_ then
                           {Loop Ls} % forgets the first motion message
                        else
                           {self motion(X Y)}
                           {Loop Ls}
                        end
                     else
                        {self motion(X Y)}
                        {Loop Ls}
                     end
                  [] unit|_ then
                     skip
                  [] X|Xs then
                     {self X}
                     {Loop Xs}
                  else skip end
               end
            in
               self.port={NewPort Out}
               {self tkBind(event:"<1>"
                            args:[int(x) int(y)]
                            action:self.port#click)}
               {self tkBind(event:"<B1-Motion>"
                            args:[int(x) int(y)]
                            action:self.port#motion)}
               {self tkBind(event:"<B1-ButtonRelease>"
                            args:[int(x) int(y)]
                            action:self.port#release)}
               thread
                  {Loop Out}
               end
            end
         end
      end

      %%
      %% this version is not reliable as messages can be constructed
      %% (and not removed from the list) based on old coordinates...
      %%

%      meth click(X Y)
%        lock
%           {Tk.send 'raise'(self)}
%           if self.vert then
%              ox<-X %% ox stores where in this canvas the user has clicked
%           else
%              ox<-Y
%           end
%        end
%      end

%      meth motion(X1 Y1 only:Only<=self)
%        lock
%           X=if self.vert then X1 else Y1 end
%           DX=X-@ox
%           {self.parent chgSize(self.nu
%                                relative:true
%                                only:Only
%                                DX)}
%           {Tk.send update}
%        in skip end
%      end

%      meth release(X1 Y1)
%        lock
%           {self motion(X1 Y1 only:nil)}
%        end
%      end

      meth mouseCoord(R)
         R=if self.vert then
              {Tk.returnInt winfo(pointerx self)}-{Tk.returnInt winfo(rootx self)}
           else
              {Tk.returnInt winfo(pointery self)}-{Tk.returnInt winfo(rooty self)}
           end
      end

      meth click(_ _)
         lock
            {Tk.send 'raise'(self)}
            ox<-{self mouseCoord($)}
         end
      end

      meth motion(_ _ only:Only<=self)
         lock
            X={self mouseCoord($)}
            DX=X-@ox
            {self.parent chgSize(self.nu
                                 relative:true
                                 only:Only
                                 DX)}
            {Tk.send update}
         in skip end
      end

      meth release(X1 Y1)
         lock
            {self motion(X1 Y1 only:nil)}
         end
      end


      meth destroy
         lock
            {Send self.port unit}
         end
      end

   end

   class QTkRubberframe

      from Tk.frame QTkClass

      prop locking

      feat
         widgetType:WidgetType
         typeInfo:r(all:{Record.adjoin GlobalInitType
                         r(borderwidth:pixel
                           cursor:cursor
                           highlightbackground:color
                           highlightcolor:color
                           highlightthickness:pixel
                           relief:relief
                           takefocus:boolean
                           background:color bg:color
                           'class':atom
                           colormap:no
                           container:boolean
                           height:pixel
                           width:pixel
                           visual:no
                           continue:boolean)}
                    uninit:r
                    unset:{Record.adjoin GlobalUnsetType
                           r('class':unit
                             colormap:unit
                             container:unit
                             visual:unit)}
                    unget:{Record.adjoin GlobalUngetType
                           r(bitmap:bitmap
                             font:font)})
         Children
         Vert

      attr
         Sizes
         MinSize
         Continue

      meth init(M1)
         lock
            A B C
            M={PropagateLook M1}
         in
            MinSize<-10
            {Record.partitionInd {Record.adjoin M init}
             fun{$ I _} {Int.is I} end C A}
            B={Record.toList C}
            QTkClass,A
            Tk.frame,{TkInit {Record.subtract A continue}}
            Continue<-{CondSelect A continue false}
            %% B contains the structure of
            self.Vert={Label M}==lrrubberframe
            %% creates the children
            self.Children={List.make {Length B}+{Length B}-1}
            {List.forAllInd B
             proc{$ I Desc}
                Obj={MapLabelToObject {Record.adjoinAt Desc parent self}}
             in
                if {HasFeature Desc feature} andthen {IsFree self.(Desc.feature)} then
                   self.(Desc.feature)=Obj
                end
                if {HasFeature Desc handle} andthen {IsFree Desc.handle} then
                   Desc.handle=Obj
                end
                {List.nth self.Children (I-1)*2+1}=Obj
             end}
            {List.forAllInd self.Children
             proc{$ I O}
                if {Int.isEven I} then
                   O={New QTkSep sep(parent:self nu:((I+1) div 2)
                                     vert:self.Vert)}
                end
             end}
            %% calculate the sizes
            {Tk.send update}
            local
               {ForAll self.Children
                proc{$ O}
                   {Tk.send place(O x:0 y:0)}
                end}
               Sizes<-{List.map self.Children
                       fun{$ O}
                          T={Tk.returnInt winfo(if self.Vert then
                                                   width
                                                else
                                                   height
                                                end O) $}
                       in
                          if T==1 then %% probably tk isn't ready yet
%                            {ExecTk unit update}
%                            {Delay 500}
                             {Tk.returnInt winfo(if self.Vert then
                                                   reqwidth
                                                else
                                                   reqheight
                                                 end O) $}
                          else T
                          end
%                         {O tkReturnInt(cget(if self.Vert then
%                                                  "-width"
%                                               else
%                                                  "-height"
%                                               end ) $)}
                       end}
               W={List.foldL @Sizes Number.'+' 0}
               H={List.foldL self.Children
                  fun{$ Old O}
                     V={Tk.returnInt winfo(if self.Vert then
                                              height
                                           else
                                              width
                                           end
                                           O)}
                  in
                     if V>Old then V else Old end
                  end
                  0}
               %% display all information
            in
               {self Update}
               {self tk(configure
                        width:if self.Vert then W else H end
                        height:if self.Vert then H else W end
                       )}
            end
            {self tkBind(event:"<Configure>"
                         action:self#Resize)}
         end
      end

      meth Resize
         lock
            {self AssertSize}
            {self Update}
         end
      end

      meth Update(only:Only<=nil)
         lock
            %% place everything correctly
            {ForAll @Sizes Wait}
            proc{Loop L S Pad}
               case L of O|Os then
                  case S of X|Xs then
                     if @Continue orelse Only==nil orelse Only==O then
                        if self.Vert then
                           {Tk.send place(O
                                          y:0    relheight:1.0
                                          x:Pad  width:X)}
                        else
                           {Tk.send place(O
                                          x:0    relwidth:1.0
                                          y:Pad  height:X)}
                        end
                     end
                     {Loop Os Xs Pad+X}
                  end
               else skip end
            end
         in
            {Loop self.Children @Sizes 0}
         end
      end

      meth AssertSize
         %% transform an arbitrary Size attribute and transform it into a correct one
         %% depending on the width/height of the frame
         lock
            if @Sizes==nil then skip else
               W={Tk.returnInt winfo(if self.Vert then width else height end self)}
               Sizes<-{List.mapInd @Sizes
                       fun{$ I S}
                          if S<@MinSize andthen {Int.isOdd I} then @MinSize
                          else S end
                       end}
               S={List.foldL @Sizes Number.'+' 0}
            in
               if W>S then % more space available : all given to the last widget
                  Sizes<-{List.append
                          {List.take @Sizes {Length @Sizes}-1}
                          {List.nth @Sizes {Length @Sizes}}+W-S|nil}
               elseif W<S then % less space available
                  fun{Loop I S R}
                     case S of X|Xs then
                        if {Int.isOdd I} then
                           if X>R+@MinSize then % enough space available
                              X-R|Xs
                           else
                              @MinSize|{Loop I+1 Xs R-(X-@MinSize)}
                           end
                        else X|{Loop I+1 Xs R} end
                     else nil end
                  end
               in
                  Sizes<-{Reverse {Loop 1 {Reverse @Sizes} S-W}}
               end
            end
         end
      end

      meth chgSize(Nu Size only:Only<=nil relative:Rel<=false)=M
         lock
            N
            Error=proc{$}
                     {Exception.raiseError qtk(custom "Can't change size of frame" "Specified frame not found" M)}
                  end
            Err={CheckType integer Size}
            if Err==unit then skip
            else
               {Exception.raiseError qtk(typeError Size self.widgetType Err M)}
            end
         in
            if {Int.is Nu} then % then number was given
               N=(Nu-1)*2+1
            else
               {List.forAllInd self.Children
                proc{$ I C}
                   if C==Nu then N=I else skip end
                end}
               if {IsFree N} then {Error} end
            end
            if N<1 orelse N>{Length self.Children} then {Error} end
            Sizes<-{List.mapInd @Sizes
                    fun{$ I S}
                       if I\=N then S
                       else if Rel then Size+S else Size end
                       end
                    end}
            {self AssertSize}
            {self Update(only:Only)}
         end
      end

      meth set(...)=M
         lock
            A B
         in
            {SplitParams M [continue] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {Record.forAllInd B
             proc{$ I V}
                case I
                of continue then continue<-V
                end
             end}
         end
      end

      meth get(...)=M
         lock
            A B
         in
            {SplitParams M [continue] A B}
            QTkClass,A
            {Assert self.widgetType self.typeInfo B}
            {Record.forAllInd B
             proc{$ I V}
                case I
                of continue then V=@continue
                end
             end}
         end
      end

      meth destroy
         lock
            {ForAll self.Children
             proc{$ C} try {C destroy} catch _ then skip end end}
         end
      end

      meth tdrubberframe(...)=M
         lock
            {self init(M)}
         end
      end

      meth lrrubberframe(...)=M
         lock
            {self init(M)}
         end
      end

   end

   {RegisterWidget r(widgetType:tdrubberframe
                     feature:true
                     qTkTdrubberframe:QTkRubberframe)}

   {RegisterWidget r(widgetType:lrrubberframe
                     feature:true
                     qTkLrrubberframe:QTkRubberframe)}
end
