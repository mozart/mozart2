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
   BarChart at 'ParBarChart.ozf'
   Tk TkTools

export
   dialog: Statistics

prepare

   fun {ToText Mode}
      '['# case Mode
           of total then 'Total'
           [] avg   then 'Average'
           end # ' Nodes]'
   end

define

   SmallFont = {New Tk.font tkInit(family:helvetica size:10)}
   TextFont  = {New Tk.font tkInit(family:helvetica size:12)}

   class SearchChart
      from TkTools.textframe

      prop
         locking

      attr
         mode: total
         data

      feat
         bars
         what

      meth init(parent:P text:T legend:L what:W)
         lock
            SearchChart,tkInit(parent: P
                               text:   T
                               font:   TextFont)
            Bars = {New BarChart.chart init(parent:    self.inner
                                            barwidth:  400
                                            suffix:    {ToText @mode}
                                            legend:    L)}

            ModeVar = {New Tk.variable    tkInit(@mode)}
            ModeFr  = {New Tk.frame tkInit(parent:self.inner)}
            Total   = {New Tk.radiobutton tkInit(parent: ModeFr
                                                 font:   SmallFont
                                                 var:    ModeVar
                                                 val:    total
                                                 action: self # setMode(total)
                                                 width:  10
                                                 text:   'Total')}
            Avg     = {New Tk.radiobutton tkInit(parent: ModeFr
                                                 font:   SmallFont
                                                 var:    ModeVar
                                                 val:    avg
                                                 action: self # setMode(avg)
                                                 width:  10
                                                 text:   'Average')}
         in
            {Bars pack}
            {Tk.batch [grid(Bars      padx:3 pady:2 row:0 columnspan:2)
                       grid(Total Avg sticky:w)
                       grid(ModeFr    sticky:w      row:1)
                      ]}
            self.bars = Bars
            self.what = W
         end
      end

      meth reset(Data)
         lock
            data <- Data
            {self UpdateAll}
         end
      end

      meth update(WID)
         lock
            What = self.what
         in
            {self.bars display(WID {@data What(WID @mode $)})}
         end
      end

      meth UpdateAll
         Data = @data
         What = self.what
         M    = {Data getWorkers($)}
         D    = {MakeTuple '#' M}
      in
         {For 1 M 1
          proc {$ WID}
             D.WID = {Data What(WID @mode $)}
          end}
         {self.bars displayAll(D)}
      end

      meth setMode(Mode)
         lock
            mode <- Mode
            {self.bars setSuffix({ToText Mode})}
            {self UpdateAll}
         end
      end

   end

   class Statistics
      from Tk.toplevel

      feat
         explored overhead

      meth init(worker: W)
         Statistics,tkInit(title:    'Statistics'
                           withdraw: true)
         Explored = {New SearchChart init(parent: self
                                          text:   'Explored'
                                          legend: W
                                          what:   getNodes)}
         Overhead = {New SearchChart init(parent: self
                                          text:   'Overhead'
                                          legend: W
                                          what:   getOverhead)}
      in
         {Tk.batch [grid(Explored)
                    grid(Overhead)
                    update(idletasks)
                    wm(deiconify self)]}
         self.explored = Explored
         self.overhead = Overhead
      end

      meth reset(Data)
         {self.explored reset(Data)}
         {self.overhead reset(Data)}
      end

      meth update(WID)
         {self.explored update(WID)}
         {self.overhead update(WID)}
      end

   end
end
