%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%



declare
T={Module.load '' {OS.getEnv 'HOME'}#'/mozart/share/test/te.ozf' nil}.run

{T argv(verbose:  true
        usage:    false
        help:     false
        keys:     "all"
        ignores:  "none"
        tests:    "all"
        do:       true
        time:     ""
        gc:       0
        threads:  1) _}

{System.set messages(idle:true)}
