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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

declare DIR={OS.getEnv 'HOME'}#'/mozart.build/share/test'
{OS.chDir DIR}

declare
T={{New Module.manager init}
   link(url:DIR#'/te.ozf' $)}.run

{T argv(verbose:  true
	usage:    false
	help:     false
	keys:     nil % nil for `all' or a non-empty list of strings: ["fs"]
	ignores:  nil % nil for `none' or a non-empty list of strings
	tests:    nil % nil for `all' or a non-empty list of strings: ["fs"]
	'do':     true
	time:     "" % "rgscplt"
	memory:   "" % "vhacfn"
	gc:       0
        threads:  1
	repeat:   1
	delay:    0) _}


{Property.put 'messages.idle' true}
