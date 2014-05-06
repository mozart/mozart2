%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%


local
   Border       = 2
   LargeBorder  = 5
   LabelWidth   = 10
   SquareSize   = 8
   ButtonWidth  = 6

   class Square
      from Tk.canvas
      prop final
      meth init(parent:P color:C stipple:S)
	 Square,tkInit(parent:             P
		       width:              SquareSize
		       height:             SquareSize
		       bd:                 Border
		       relief:             groove
		       highlightthickness: 0)
	 Square,tk(crea rectangle ~2 ~2 SquareSize+2 SquareSize+2
		   fill:C stipple:S)
      end
   end

   class PrintNumber
      from Tk.label
      prop final
      attr Saved:0 Clear:0
      meth init(parent:P)
	 PrintNumber,tkInit(parent:P text:0 anchor:e width:LabelWidth
			    font:MediumFont)
      end
      meth set(N)
	 if N\=@Saved then
	    Saved <- N
	    PrintNumber,tk(conf text:(N-@Clear))
	 end
      end
      meth clear
	 Clear <- @Saved
	 Saved <- 0
	 PrintNumber,tk(conf text:0)
      end
   end

   class PrintTime
      from Tk.label
      prop final
      attr Saved:0 Clear:0
      meth init(parent:P)
	 PrintTime,tkInit(parent:P text:'0.00' anchor:e font:MediumFont
			  width:LabelWidth)
      end
      meth set(N)
	 if @Saved\=N then
	    C    = (N - @Clear) * 100 div 1000
	    Head = C div 100
	    Tail = C mod 100
	 in
	    PrintTime,tk(conf text:Head#'.'#if Tail<10 then '0'#Tail
					    else Tail
					    end)
	    Saved <- N
	 end
      end
      meth clear
	 PrintTime,tk(conf text:'0.00')
	 Clear <- @Saved
	 Saved <- 0
      end
   end

   class Checkbutton
      from Tk.checkbutton
      prop final
      feat Var Action
      attr Saved:false
      meth init(parent:P text:T action:A state:S)
	 V = {New Tk.variable tkInit(S)}
      in
	 Tk.checkbutton,tkInit(parent:             P
			       highlightthickness: 0
			       text:               T
			       anchor:             w
			       var:                V
			       font:               MediumFont
			       action:             self # invoke)
	 self.Var    = V
	 self.Action = A
	 Saved <- S
      end
      meth invoke
	 Saved <- {Not @Saved}
	 {self.Action @Saved}
      end
      meth set(N)
	 if N\=@Saved then
	    Saved <- N
	    {self.Var tkSet(N)}
	 end
      end
   end

   class Button
      from Tk.button
      prop final

      meth init(parent:P text:T action:A)
	 Tk.button,tkInit(parent:             P
			  highlightthickness: 0
			  text:               T
			  anchor:             w
			  action:             A
			  font:               BoldFont
			  width:              ButtonWidth)
      end
   end

   class NumberEntry
      from TkTools.numberentry
      prop final
      attr SetMode:true

      meth tkInit(...) = M
	 TkTools.numberentry,M
	 NumberEntry,tkBind(event:  '<FocusIn>'
			    action: self#setMode(false))
	 NumberEntry,tkBind(event:  '<FocusOut>'
			    action: self#setMode(true))
      end
      meth setMode(M)
	 SetMode <- M
      end
      meth set(V)
	 if @SetMode then
	    TkTools.numberentry,tkSet(V)
	 end
      end
      meth get($)
	 TkTools.numberentry,tkGet($)
      end
   end

   fun {MakeSide Ls N P R TclT}
      case Ls of nil then TclT
      [] L|Lr then TclR TclS in
	 TclS =
	 case {Label L}
	 of entry then
	    RO#CO = case {CondSelect L side left}
		    of left then 0#0 else ~1#3 end
	    L1 = {New Tk.label tkInit(parent: P
				      text:   L.text
				      font:   MediumFont
				      anchor: w)}
	    S1 = {New NumberEntry tkInit(parent: P
					 min:    {CondSelect L min  1}
					 val:    {CondSelect L init 1}
					 max:    {CondSelect L max  unit}
					 action: L.action)}
	    L2 = {New Tk.label tkInit(parent: P
				      anchor: w
				      font:   MediumFont
				      text:   {CondSelect L dim ''}#'   ')}
	 in
	    R.(L.feature)=S1
	    grid(L1 sticky:w column:0+CO row:N+RO) |
	    grid(S1 sticky:e column:1+CO row:N+RO) |
	    grid(L2 sticky:w column:2+CO row:N+RO) | TclR
	 [] number    then
	    L1 = {New Tk.label tkInit(parent: P
				      text:   L.text
				      font:   MediumFont
				      anchor: w)}
	    L2 = {New PrintNumber init(parent:P)}
	    L3 = if {HasFeature L color} orelse {HasFeature L stipple} then
		    C = {CondSelect L color black}
		    S = {CondSelect L stipple ''}
		 in {New Square init(parent:P color:C stipple:S)}
		 else {New Tk.frame tkInit(parent:P)}
		 end
	 in
	    R.(L.feature)=L2
	    grid(L1 sticky:w column:0 row:N) |
	    grid(L2 sticky:e column:1 row:N) |
	    grid(L3 padx:Pad sticky:e column:2 row:N) | TclR
	 [] size then
	    L1 = {New Tk.label tkInit(parent: P
				      text:   L.text
				      font:   MediumFont
				      anchor: w)}
	    L2 = {New PrintNumber init(parent:P)}
	    L3 = {New Tk.label tkInit(parent: P
				      anchor: e
				      font:   MediumFont
				      text:   {CondSelect L dim 'KB'})}
	    L4 = if {HasFeature L color} orelse {HasFeature L stipple} then
		    C = {CondSelect L color black}
		    S = {CondSelect L stipple ''}
		 in {New Square init(parent:P color:C stipple:S)}
		 else {New Tk.frame tkInit(parent:P)}
		 end
	 in
	    R.(L.feature)=L2
	    grid(L1 sticky:w column:0 row:N) |
	    grid(L2 sticky:e column:1 row:N) |
	    grid(L3 sticky:e column:2 row:N) |
	    grid(L4 padx:Pad sticky:e column:3 row:N) | TclR
	 [] time then
	    L1 = {New Tk.label tkInit(parent: P
				      text:   L.text
				      font:   MediumFont
				      anchor: w)}
	    L3 = {New Tk.label  tkInit(parent:P
				       text:s anchor:e
				       font:MediumFont)}
	    L2 = {New PrintTime init(parent:P)}
	    L4 = if {HasFeature L color} orelse {HasFeature L stipple} then
		    C = {CondSelect L color black}
		    S = {CondSelect L stipple ''}
		 in {New Square init(parent:P color:C stipple:S)}
		 else {New Tk.frame tkInit(parent:P)}
		 end
	 in
	    R.(L.feature)=L2
	    grid(L1 sticky:w column:0 row:N) |
	    grid(L2 sticky:e column:1 row:N) |
	    grid(L3 sticky:w column:2 row:N) |
	    grid(L4 padx:Pad sticky:e column:3 row:N) | TclR
	 [] button  then
	    B = {New Button init(parent: P
				 text:   L.text
				 action: {CondSelect L action
					  proc {$} skip end})}
	 in
	    R.(L.feature)=B
	    grid(B sticky:w column:0 row:N) | TclR
	 [] checkbutton  then
	    B = {New Checkbutton init(parent: P
				      state:  L.state
				      text:   L.text
				      action: L.action)}
	 in
	    R.(L.feature)=B
	    grid(B sticky:w column:0 row:N) | TclR
	 [] timebar then
	    F  = {New Tk.frame tkInit(parent:            P
				      highlightthickness:0)}
	    L1 = {New RuntimeBar init(parent: F)}
	 in
	    R.(L.feature)=L1
	    grid(F sticky:ens column:0 row:N) |
	    pack(L1 side:top) | TclR
	 [] load then
	    L1 = {New Load init(parent:  P
				colors:  L.colors
				stipple: L.stipple
				miny:    {CondSelect L miny 5.0}
				maxy:    {CondSelect L maxy 5.0}
				dim:     {CondSelect L dim ''})}
	 in
	    R.(L.feature)=L1
	    grid(L1 sticky:e column:0 row:N) | TclR
	 end
	 TclR={MakeSide Lr N+1 P R TclT}
	 TclS
      end
   end

   fun {GetFeature X} X.feature end

   fun {MakeFrames Fs P R TclT}
      case Fs
      of nil then pack({New Tk.frame tkInit(parent:P
					    highlightthickness: 0
					    height:             3)}
		       fill:x side:top)|TclT
      [] F|Fr then
	 Border = {New TkTools.textframe tkInit(parent: P
						text:   F.text
						font:   BoldFont)}
	 Left   = {New Tk.frame tkInit(parent:            Border.inner
				       highlightthickness: 0)}
	 Right  = {New Tk.frame tkInit(parent:            Border.inner
				       border:            LargeBorder
				       highlightthickness: 0)}
	 FR     = {MakeRecord a frame|{Append {Map F.left GetFeature}
				       {Map F.right GetFeature}}}
      in
	 FR.frame = Border
	 R.(F.feature)=FR
	 {MakeSide F.left 0 Left FR
	  {MakeSide F.right 0 Right FR
	   pack(Left   side:left  anchor:nw) |
	   pack(Right  side:right anchor:se) |
	   if {CondSelect F pack true} then
	      pack(Border fill:x side:top padx:3) | {MakeFrames Fr P R TclT}
	   else {MakeFrames Fr P R TclT}
	   end}}
     end
   end

in

   fun {MakePage Class Mark Book Top Add PageSpec}
      R    = {MakeRecord a {Map PageSpec GetFeature}}
      Page = {New Class init(parent:Book top:Top options:R text:' '#Mark#' ')}
   in
      {Tk.batch {MakeFrames PageSpec Page R nil}}
      if Add then
	 {Book add(Page)}
      end
      Page
   end

end
