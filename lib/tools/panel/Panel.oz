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

functor

import
   Property(get
	    put)

   System(gcDo)

   Application(exit)

   Error(registerFormatter)

   Open(file)

   Tk

   TkTools(error
	   dialog
	   note
	   notebook
	   scale
	   textframe
	   numberentry
	   menubar)

export
   'class':  PanelClass
   'object': Panel

   'open':   OpenPanel
   'close':  ClosePanel

require
   DefaultURL(homeUrl)
   URL(make resolve toAtom)

prepare
   BitmapUrl = {URL.toAtom {URL.resolve DefaultURL.homeUrl
			    {URL.make 'images/'}}}
   
define
   \insert 'panel/errors.oz'
   \insert 'panel/main.oz'

   Panel = {New PanelClass init}

   proc {OpenPanel}
      {Panel open}
   end

   proc {ClosePanel}
      {Panel close}
   end

end
