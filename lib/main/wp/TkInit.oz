%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Michael Mehl, 1997
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

% send event to Oz
%  id : index into table
%  args: a list of args
% output format:
%   p Id N
%   <Arg1>
%   ...
%   <ArgN>
'
proc ozp {id args} {
    set len [llength $args]
    puts stdout "p $id $len"
    for {set i 0} {$i < $len} {incr i} {
        puts stdout "[ozq [lindex $args $i]]"
    }
    flush stdout
}' #
%% Sending a request for a return value
'
proc ozr {v} {
    puts stdout "r [ozq $v]"
    flush stdout
}' #
%% quote arguments:
%% \\       -> \\\\
%% newline -> \\n
'
proc ozq {in} {
    regsub -all \\\\\\\\ $in \\\\\\\\\\\\\\\\ out
    regsub -all \\n $out \\\\n final
    return $final
}
' #
'
proc ozm {item menu} {
    return [expr $item + [$menu cget -tearoff]]
}
' #
'
proc bgerror err {
     puts stderr "w $err\\n."
}
   '
