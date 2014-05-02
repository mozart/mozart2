%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Contributors:
%%%   Martin Mueller <mmueller@ps.uni-sb.de>
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

{Error.registerFormatter panel
 fun {$ E}
    T = 'error in Oz Panel'
 in
    case E
    of panel(option OM) then
       error(kind: T
	     msg: 'Illegal option specification'
	     items: [hint(l:'Message'
			  m:oz(OM))])
    else
       error(kind: T
	     items: [line(oz(E))])
    end
 end}
