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
        keys:     ["fd"]   % nil for `all' or a non-empty list of strings: ["fs"]
        ignores:  nil %["misc1_41"]   % nil for `none' or a non-empty list of strings
%       tests:    ["prop_engine_lib_tasksOverlap_2"]
        tests:    nil
        'do':       true
        time:     ""
        gc:       0
        threads:  1) _}


{Property.put 'messages.idle' true}
