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

   class AboutDialog
      from TkTools.dialog
      prop final

      meth init(master:Master)
	 TkTools.dialog,tkInit(master:  Master
			       title:   TitleName#': About'
			       buttons: ['Okay'#tkClose]
			       focus:   1
			       default: 1)
	 Title = {New Tk.label tkInit(parent:     self
				      font:       AboutFont
				      text:       TitleName
				      foreground: AboutColor)}

	 Author = {New Tk.label tkInit(parent: self
				       text: ('Christian Schulte\n' #
					      '<schulte@ps.uni-sb.de>\n'))}
      in
	 {Tk.send pack(Title Author
		       side:top expand:1 padx:Pad pady:Pad)}
      end

   end

   class ShutdownDialog
      from TkTools.dialog
      prop final

      meth init(master:Master shut:Shut)
	 TkTools.dialog,tkInit(master:  Master
			       title:   TitleName#': Shutdown'
			       buttons: ['Okay'#tkClose(proc {$}
							   Shut = true
							end)
					 'Cancel'#tkClose(proc {$}
							     Shut = false
							  end)]
			       focus:   1
			       default: 1)
	 Bitmap  = {New Tk.label   tkInit(parent: self
					  bitmap: question)}
	 Message = {New Tk.message tkInit(parent: self
					  aspect: 250
					  text:   'Do you really want to shutdown?')}
      in
	 {Tk.send pack(Bitmap Message
		       side:left expand:1 padx:Pad pady:Pad)}
      end

   end



   local

      fun {FindPos TLs FT N}
	 T#_|TLr = TLs
      in
	 if T==FT then N else {FindPos TLr FT N+1} end
      end

      ScaleWidth  = 100

   in

      class UpdateDialog
	 from TkTools.dialog
	 prop final

	 meth init(master:Master  options:O)
	    TkTools.dialog,tkInit(master:  Master
				  title:   TitleName#': Update'
				  buttons:
		['Okay'   #
		 tkClose(proc {$}
			    {Dictionary.put O mouse
			     {MouseVar tkReturnInt($)}==1}
			    {Dictionary.put O time
			     {TimeScale get($)}}
			 end)
		 'Cancel' # tkClose]
				  focus:   1
				  default: 1)
	    TimeOuter = {New TkTools.textframe tkInit(parent: self
						      text:   'Update Time')}
	    TimeLabel = {New Tk.label tkInit(parent: TimeOuter.inner
					     text:   'Update Every: ')}
	    TimeScale = {New TkTools.scale init(parent: TimeOuter.inner
						width:  ScaleWidth
						values: UpdateTimes
						initpos: {FindPos UpdateTimes
							  {Dictionary.get O
							   time} 1})}
	    MouseOuter = {New TkTools.textframe tkInit(parent: self
						       text:   'Update Requirement')}
	    MouseVar   = {New Tk.variable tkInit({Dictionary.get O mouse})}
	    MouseButton = {New Tk.checkbutton
			   tkInit(parent:   MouseOuter.inner
				  variable: MouseVar
				  text:     'Require Mouse over Panel')}
	 in
	    {Tk.batch [pack(TimeLabel TimeScale side:left fill:x)
		       pack(MouseButton side:left fill:x)
		       pack(TimeOuter MouseOuter fill:x)]}
	 end

      end


      class HistoryDialog
	 from TkTools.dialog
	 prop final

	 meth init(master:Master options:O)
	    TkTools.dialog,tkInit(master:  Master
				  title:   TitleName#': History'
				  buttons: ['Okay'   #
					    tkClose(proc {$}
						     {Dictionary.put O history
						      {RangeScale get($)}}
						    end)
					    'Cancel' # tkClose]
				  focus:   1
				  default: 1)
	    RangeOuter = {New TkTools.textframe tkInit(parent: self
						       text:   'History Range')}
	    RangeLabel = {New Tk.label tkInit(parent: RangeOuter.inner
					     text:   'Range Covers: ')}
	    RangeScale = {New TkTools.scale init(parent:  RangeOuter.inner
						 width:   ScaleWidth
						 values:  HistoryRanges
						 initpos: {FindPos
							   HistoryRanges
							   {Dictionary.get O
							    history}
							   1})}
	 in
	    {Tk.batch [pack(RangeLabel RangeScale side:left fill:x)
		       pack(RangeOuter)]}
	 end

      end

   end

in

   class DialogClass

      meth about
	 {Wait {New AboutDialog init(master:self)}.tkClosed}
      end

      meth shutdown(?Shut)
	 {Wait {New ShutdownDialog init(master:self shut:?Shut)}.tkClosed}
      end

      meth update
	 {Wait {New UpdateDialog
		init(master:self options:self.options)}.tkClosed}
      end

      meth history
	 {Wait {New HistoryDialog
		init(master:self options:self.options)}.tkClosed}
      end

   end

end

