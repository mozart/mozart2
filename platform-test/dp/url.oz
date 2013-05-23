%%%
%%% Authors:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Denys Duchier, 1998
%%%   Christian Schulte, 1998
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

%%% These tests check the resolving of relative uris.
%%% They are transcribed from those published by Roy Fielding
%%% <fielding@ics.uci.edu> at http://www.ics.uci.edu/~fielding/url/

functor $

import
   URL System

export
   Return

define
   Return =

   local
      fun {MkTest Test}
	 L    = {VirtualString.toAtom Test.title}
	 Base = {URL.make Test.base}
      in
	 L(fun {$}
	      {All Test.alist
	       fun {$ Relative#Wanted}
		  Resolved={VirtualString.toString
			    {URL.toVirtualStringExtended
			     {URL.resolve Base {URL.make Relative}}
			     o(full:true)}}
	       in
		  if Resolved\=Wanted then
		     {System.show {String.toAtom Resolved}#{String.toAtom Wanted}}
		  end
		  Resolved==Wanted
	       end}
	   end
	   keys:[url])
      end
   in

      url(
	 ascii(proc {$}
		  if {URL.toString "föo"}=="f%f6o" then skip
		  else raise url_ascii_failed end end
	       end
	       keys:[url])
	 
	 |{Map
	   [
	    test(title:"fielding1"
		 base :"http://a/b/c/d;p?q"
		 alist:
		    [
		     "gg:h"	#"gg:h"
		     "g"	#"http://a/b/c/g"
		     "./g"	#"http://a/b/c/g"
		     "g/"	#"http://a/b/c/g/"
		     "/g"	#"http://a/g"
		     "//g"	#"http://g"
		     "?y"	#"http://a/b/c/?y"
		     "g?y"	#"http://a/b/c/g?y"
		     %%"#s"	#"(current document)#s"
		     "g#s"	#"http://a/b/c/g#s"
		     "g?y#s"	#"http://a/b/c/g?y#s"
		     ";x"	#"http://a/b/c/;x"
		     "g;x"	#"http://a/b/c/g;x"
		     "g;x?y#s"	#"http://a/b/c/g;x?y#s"
		     "."	#"http://a/b/c/"
		     "./"	#"http://a/b/c/"
		     ".."	#"http://a/b/"
		     "../"	#"http://a/b/"
		     "../g"	#"http://a/b/g"
		     "../.."	#"http://a/"
		     "../../"	#"http://a/"
		     "../../g"	#"http://a/g"
		    ]
		)
	    test(title:"fielding1Abnormal"
		 base :"http://a/b/c/d;p?q"
		 alist:
		    [
		     "../../../g"	#"http://a/../g"
		     "../../../../g"	#"http://a/../../g"
		     "/./g"		#"http://a/./g"
		     "/../g"		#"http://a/../g"
		     "g."		#"http://a/b/c/g."
		     ".g"		#"http://a/b/c/.g"
		     "g.."		#"http://a/b/c/g.."
		     "..g"		#"http://a/b/c/..g"
		     "./../g"		#"http://a/b/g"
		     "./g/."		#"http://a/b/c/g/"
		     "g/./h"		#"http://a/b/c/g/h"
		     "g/../h"		#"http://a/b/c/h"
		     "g;x=1/./y"	#"http://a/b/c/g;x=1/y"
		     "g;x=1/../y"	#"http://a/b/c/y"
		     "g?y/./x"		#"http://a/b/c/g?y/./x"
		     "g?y/../x"		#"http://a/b/c/g?y/../x"
		     "g#s/./x"		#"http://a/b/c/g#s/./x"
		     "g#s/../x"		#"http://a/b/c/g#s/../x"
		     "http:g"		#"http:g"
		     "http:"		#"http:"
		    ]
		)
	    test(title:"fielding2"
		 base :"http://a/b/c/d;p?q=1/2"
		 alist:
		    [
		     "g"	#"http://a/b/c/g"
		     "./g"	#"http://a/b/c/g"
		     "g/"	#"http://a/b/c/g/"
		     "/g"	#"http://a/g"
		     "//g"	#"http://g"
		     "?y"	#"http://a/b/c/?y"
		     "g?y"	#"http://a/b/c/g?y"
		     "g?y/./x"	#"http://a/b/c/g?y/./x"
		     "g?y/../x"	#"http://a/b/c/g?y/../x"
		     "g#s"	#"http://a/b/c/g#s"
		     "g#s/./x"	#"http://a/b/c/g#s/./x"
		     "g#s/../x"	#"http://a/b/c/g#s/../x"
		     "./"	#"http://a/b/c/"
		     "../"	#"http://a/b/"
		     "../g"	#"http://a/b/g"
		     "../../"	#"http://a/"
		     "../../g"	#"http://a/g"
		    ]
		)
	    test(title:"fielding3"
		 base :"http://a/b/c/d;p=1/2?q"
		 alist:
		    [
		     "g"		#"http://a/b/c/d;p=1/g"
		     "./g"		#"http://a/b/c/d;p=1/g"
		     "g/"		#"http://a/b/c/d;p=1/g/"
		     "g?y"		#"http://a/b/c/d;p=1/g?y"
		     ";x"		#"http://a/b/c/d;p=1/;x"
		     "g;x"		#"http://a/b/c/d;p=1/g;x"
		     "g;x=1/./y"	#"http://a/b/c/d;p=1/g;x=1/y"
		     "g;x=1/../y"	#"http://a/b/c/d;p=1/y"
		     "./"		#"http://a/b/c/d;p=1/"
		     "../"		#"http://a/b/c/"
		     "../g"		#"http://a/b/c/g"
		     "../../"		#"http://a/b/"
		     "../../g"		#"http://a/b/g"
		    ]
		)
	    test(title:"fielding4"
		 base :"fred:///s//a/b/c"
		 alist:
		    [
		     "gg:h"		#"gg:h"
		     "g"		#"fred:///s//a/b/g"
		     "./g"		#"fred:///s//a/b/g"
		     "g/"		#"fred:///s//a/b/g/"
		     "/g"		#"fred:///g"
		     "//g"		#"fred://g"
		     "//g/x"		#"fred://g/x"
		     "///g"		#"fred:///g"
		     "./"		#"fred:///s//a/b/"
		     "../"		#"fred:///s//a/"
		     "../g"		#"fred:///s//a/g"
		     "../../"		#"fred:///s//"
		     "../../g"		#"fred:///s//g"
		     "../../../g"	#"fred:///s/g"
		     "../../../../g"	#"fred:///g"
		    ]
		)
	    test(title:"fielding5"
		 base :"http:///s//a/b/c"
		 alist:
		    [
		     "gg:h"		#"gg:h"
		     "g"		#"http:///s//a/b/g"
		     "./g"		#"http:///s//a/b/g"
		     "g/"		#"http:///s//a/b/g/"
		     "/g"		#"http:///g"
		     "//g"		#"http://g"
		     "//g/x"		#"http://g/x"
		     "///g"		#"http:///g"
		     "./"		#"http:///s//a/b/"
		     "../"		#"http:///s//a/"
		     "../g"		#"http:///s//a/g"
		     "../../"		#"http:///s//"
		     "../../g"		#"http:///s//g"
		     "../../../g"	#"http:///s/g"
		     "../../../../g"	#"http:///g"
		    ]
		)
	   ] MkTest})

   end
end



