%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

AllLoader = {Application.loader
             full('SP':eager 'OP':eager 'DP':eager
                  'AP':lazy 'CP':lazy 'WP':lazy
                  'Panel':lazy 'Browser':lazy 'Explorer':lazy
                  'Compiler':lazy 'CompilerPanel':lazy
                  'Emacs':lazy 'Ozcar':lazy 'Profiler':lazy
                  'Gump':lazy 'GumpScanner':lazy 'GumpParser':lazy
                  'Misc':lazy)}
