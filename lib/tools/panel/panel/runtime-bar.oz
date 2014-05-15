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
   BackColor = white
   Width     = 240
   Height    = 20
   Gap       = 2
   Border    = 2
   Y0        = Gap + 1
   Y1        = Height
   Home      = ~10
in

   class RuntimeBar
      from Tk.canvas
      prop final

      feat
	 RunTag
	 GcTag
	 CopyTag
	 PropTag
      attr
	 Saved: ZeroTime
	 Clear: ZeroTime

      meth init(parent:P)
	 RuntimeBar,tkInit(parent:             P
			   width:              Width
			   relief:             groove
			   highlightthickness: 0
			   bd:                 Border
			   bg:                 BackColor
			   height:             Height)
	 ThisRunTag  = {New Tk.canvasTag tkInit(parent:self)}
	 ThisGcTag   = {New Tk.canvasTag tkInit(parent:self)}
	 ThisCopyTag = {New Tk.canvasTag tkInit(parent:self)}
	 ThisPropTag = {New Tk.canvasTag tkInit(parent:self)}
      in
	 self.RunTag  = ThisRunTag
	 self.GcTag   = ThisGcTag
	 self.CopyTag = ThisCopyTag
	 self.PropTag = ThisPropTag
	 RuntimeBar,tk(crea rectangle Home Y0 Home Y1
		       fill:    TimeColors.run
		       stipple: TimeStipple.run
		       tags:    ThisRunTag)
	 RuntimeBar,tk(crea rectangle Home Y0 Home Y1
		       fill:    TimeColors.gc
		       stipple: TimeStipple.gc
		       tags:    ThisGcTag)
	 RuntimeBar,tk(crea rectangle Home Y0 Home Y1
		       fill:    TimeColors.copy
		       stipple: TimeStipple.copy
		       tags:    ThisCopyTag)
	 RuntimeBar,tk(crea rectangle Home Y0 Home Y1
		       fill:    TimeColors.'prop'
		       stipple: TimeStipple.'prop'
		       tags:    ThisPropTag)
      end

      meth clear
	 Clear <- @Saved
	 Saved <- ZeroTime
	 RuntimeBar, displayZero
      end

      meth displayZero
	 RuntimeBar,tk(coords self.RunTag  Home Y0 Home Y1)
	 RuntimeBar,tk(coords self.GcTag   Home Y0 Home Y1)
	 RuntimeBar,tk(coords self.CopyTag Home Y0 Home Y1)
	 RuntimeBar,tk(coords self.PropTag Home Y0 Home Y1)
      end

      meth display(T)
	 if T\=@Saved then
	    C           = @Clear
	    GcTime      = T.gc   - C.gc
	    CopyTime    = T.copy - C.copy
	    PropTime    = T.propagate - C.propagate
	    RunTime     = T.user - C.user
	 in
	    if RunTime==0 then
	       RuntimeBar,displayZero
	    else
	       GcZero    = if GcTime==0   then 0 else 1 end
	       CopyZero  = if CopyTime==0 then 0 else 1 end
	       PropZero  = if PropTime==0 then 0 else 1 end
	       HalfTime  = RunTime div 2
	       ThisWidth = Width -
			   (GcZero + CopyZero + PropZero + 1) * Gap
	       GcWidth   = (GcTime   * ThisWidth + HalfTime) div RunTime
	       CopyWidth = (CopyTime * ThisWidth + HalfTime) div RunTime
	       PropWidth = (PropTime * ThisWidth + HalfTime) div RunTime
	       PropEnd   = Width
	       PropStart = PropEnd - PropWidth
	       CopyEnd   = PropStart - PropZero * Gap
	       CopyStart = CopyEnd - CopyWidth
	       GcEnd     = CopyStart - CopyZero * Gap
	       GcStart   = GcEnd   - GcWidth
	       RunEnd    = GcStart   - GcZero * Gap
	       RunStart  = Gap + 1
	    in
	       Saved <- T
	       RuntimeBar,tk(coords self.RunTag  RunStart  Y0 RunEnd  Y1)
	       if GcTime==0 then
		  RuntimeBar,tk(coords self.GcTag  Home Y0 Home Y1)
	       else
		  RuntimeBar,tk(coords self.GcTag   GcStart   Y0 GcEnd   Y1)
	       end
	       if CopyTime==0 then
		  RuntimeBar,tk(coords self.CopyTag Home Y0 Home Y1)
	       else
		  RuntimeBar,tk(coords self.CopyTag CopyStart Y0 CopyEnd Y1)
	       end
	       if PropTime==0 then
		  RuntimeBar,tk(coords self.PropTag Home Y0 Home Y1)
	       else
		  RuntimeBar,tk(coords self.PropTag PropStart Y0 PropEnd Y1)
	       end
	    end
	 end
      end
   end

end
