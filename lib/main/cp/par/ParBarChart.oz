%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://mozart.ps.uni-sb.de/
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


functor

import
   Tk

export
   chart: BarChart

require
   ParFindLimit
   ParGetColor
   ParServer


prepare


   ChartHeight  = 90
   BarXGap      = 20
   BarYGap      = 10

   BarHeight    = 16
   BarBorder    = 2

   fun {ToFloat X}
      if {IsInt X} then {IntToFloat X} else X end
   end

   fun {Format X N}
      X
   end

define


   SmallFont   = {New Tk.font tkInit(family:helvetica size:10)}
   BalloonFont = {New Tk.font tkInit(family:helvetica size:12)}

   local
      BalloonDelay = 1500

      fun {MakeBalloon T X Y}
         W = {New Tk.toplevel tkInit(withdraw:true bg:black)}
         M = {New Tk.label
              tkInit(parent:W text:T bg:lightyellow font:BalloonFont)}
      in
         {Tk.batch [wm(overrideredirect W true)
                    wm(geometry W '+'#X#'+'#Y)
                    pack(M ipadx:3 padx:1 pady:1)
                    update(idletasks)
                    wm(deiconify W)]}
         W
      end
   in
      class Balloon
         attr cur
         feat top
         meth init(Top)
            self.top=Top
         end
         meth enter(GT)
            LeaveVar WaitVar
         in
            cur <- LeaveVar
            {Alarm BalloonDelay WaitVar}
            thread
               [X Y] = {Map [pointerx pointery]
                        fun {$ WI} {Tk.returnInt winfo(WI self.top)} end}
            in
               {WaitOr LeaveVar WaitVar}
               if {IsDet LeaveVar} then skip else
                  W={MakeBalloon {GT} X+10 Y+10}
               in
                  {Wait LeaveVar}
                  {W tkClose}
               end
            end
         end
         meth leave
            @cur = unit
         end
      end
   end

   class Bar
      from Tk.canvasTag
      attr
         value:  0.0
         suffix: ''
      feat
         y
         x
      meth init(parent:P y:Y x:X balloon:B color:C)
         Bar,tkInit(parent:P)
         self.y = Y
         self.x = X
         {P tk(create rectangle
               X Y+BarBorder
               X Y+BarHeight-BarBorder
               fill: C         tags: self)}
         {self tkBind(event:'<Enter>'
                      action: B # enter(fun {$}
                                           {Format @value 2}#' '#@suffix
                                        end))}
         {self tkBind(event:'<Leave>'
                      action: B # leave)}
      end
      meth set(V)
         value <- V
      end
      meth get($)
         @value
      end
      meth setSuffix(S)
         suffix <- S
      end
      meth redraw(Scale)
         W = {FloatToInt @value * Scale}
      in
         {self tk(coords
                  self.x   self.y+BarBorder
                  self.x+W self.y+BarHeight-BarBorder)}
         {self tk('raise')}
      end
   end

   class BarChart
      from Tk.frame

      feat
         canvas
         suffix
         scroll
         x0 x1
         y0 y1
         bars
         width
         ticks
         balloon

      attr
         scale: 1.0
         limit: 0.0

      meth init(parent:    P
                barwidth:  BW
                textwidth: TW <= 60
                legend:    L
                suffix:    S <= '')
         W = BW + TW + 3 * BarXGap
         IH = ({Width L} + 2)* BarHeight
         H = IH + 2 * BarYGap
      in
         self.x0      = TW + 2 * BarXGap
         self.x1      = self.x0 + BW
         self.y0      = BarYGap
         self.y1      = self.y0 + {Width L} * BarHeight
         self.width   = BW
         self.balloon = {Server.newPort Balloon init(P)}
         BarChart,tkInit(parent:P bd:2 relief:sunken bg:white)
         self.canvas = {New Tk.canvas
                        tkInit(parent: self
                               width:  W
                               height: ChartHeight + 2*BarYGap)}
         {self.canvas tk(conf
                         scrollregion: q(0 0 W
                                         {Max ChartHeight + 2*BarYGap H}))}
         self.scroll = {New Tk.scrollbar tkInit(parent:self width:12)}
         {Tk.addYScrollbar self.canvas self.scroll}
         %% Draw bar area
         {self.canvas tk(create rectangle
                         self.x0-1 self.y0-1
                         self.x1+1 self.y1+1
                         fill:    ivory
                         outline: gray40
                         width:   2)}
         {Record.forAllInd L
          proc {$ I T}
             {self text(self.canvas I T)}
          end}
         self.bars = {Record.mapInd L
                      fun {$ I _}
                         {New Bar init(parent:self.canvas
                                       x:self.x0
                                       y:self.y0+(I-1)*BarHeight
                                       color: {GetColor.get I}
                                       balloon:self.balloon)}
                      end}
         self.ticks  = {New Tk.canvasTag tkInit(parent:self.canvas)}
         self.suffix = {New Tk.canvasTag tkInit(parent:self.canvas)}
         {self.canvas tk(create text
                         self.x1 self.y1 + 2 * BarHeight
                         anchor: se
                         font:   SmallFont
                         text:   S
                         tags:   self.suffix)}
         {self setSuffix(S)}
      end

      meth text(P I T)
         Tag = {New Tk.canvasTag tkInit(parent:P)}
         S   = {VirtualString.toString T}
         SS  = {List.take S 10}
      in
         {self.canvas tk(create text
                         BarXGap
                         self.y0 + (I-1) * BarHeight +
                         BarHeight div 2
                         anchor: w
                         font:   SmallFont
                         text:   SS
                         tags:   Tag)}
         if SS\=S then
            {Tag tkBind(event:'<Enter>'
                        action: self.balloon#enter(fun {$} S end))}
            {Tag tkBind(event:'<Leave>'
                        action: self.balloon#leave)}
         end
      end

      meth setSuffix(S)
         {self.suffix tk(itemconfigure text:S)}
         {Record.forAll self.bars proc {$ B}
                                     {B setSuffix(S)}
                                  end}
      end

      meth pack
         {Tk.batch [grid(self.canvas row:0 column:0)
                    grid(self.scroll row:0 column:1 sticky:ns)]}
      end

      meth getMax($)
         {Record.foldL self.bars fun {$ M B}
                                    {Max M {B get($)}}
                                 end 0.0}
      end

      meth update(Limit NoTicks)
         scale <- {ToFloat self.width} / Limit
         {self.ticks tk(delete)}
         {For 1 2*NoTicks-1 1
          proc {$ I}
             X  = self.x0 + (self.width * I) div (2*NoTicks)
          in
             {self.canvas tk(create line
                             X self.y0
                             X self.y1
                             fill: gray20
                             tags: self.ticks)}
          end}
         {For 0 NoTicks 1
          proc {$ I}
             X = self.x0 + (self.width * I) div NoTicks
             V = (Limit / {IntToFloat NoTicks}) * {IntToFloat I}
          in
             if V=={Round V} then
                {self.canvas tk(create text
                                X self.y1 + BarHeight
                                anchor: s
                                font:   SmallFont
                                text:   {Format V 2}
                                tags:   self.ticks)}
             end
          end}
         {Record.forAll self.bars
          proc {$ B}
             {B redraw(@scale)}
          end}
      end

      meth display(I V)
         F = {ToFloat V}
         {self.bars.I set(F)}
         NM              = BarChart,getMax($)
         Limit # NoTicks = {FindLimit.find NM}
      in
         if Limit==@limit then
            {self.bars.I redraw(@scale)}
         else
            limit <- Limit
            {self update(Limit NoTicks)}
         end
      end

      meth displayAll(RV)
         {Record.forAllInd self.bars proc {$ I B}
                                        {B set({ToFloat RV.I})}
                                     end}
         NM              = BarChart,getMax($)
         Limit # NoTicks = {FindLimit.find NM}
      in
         if Limit==@limit then
            {Record.forAll self.bars proc {$ B}
                                        {B redraw(@scale)}
                                     end}
         else
            limit <- Limit
            {self update(Limit NoTicks)}
         end
      end

   end

end
