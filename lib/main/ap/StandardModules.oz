%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%   Leif Kornstaedt (kornstae@ps.uni-sb.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 1997
%%%   Leif Kornstaedt, 1998
%%%   Christian Schulte, 1997, 1998
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

oz('SP':             nil
   'OP':             ['SP']
   'AP':             ['SP' 'OP']
   'CP':             ['SP']
   'WP':             ['SP' 'OP']
   'DP':             ['OP' 'AP']
   'Panel':          ['SP' 'OP' 'WP']
   'Browser':        ['SP' 'WP' 'CP']
   'Explorer':       ['SP' 'WP' 'Browser'#lazy]
   'Compiler':       ['SP' 'CP' 'Gump'#lazy]
   'CompilerPanel':  ['SP' 'CP' 'OP' 'WP' 'Compiler' 'Browser'#lazy]
   'Emacs':          ['OP' 'SP']
   'Ozcar':          ['SP' 'CP'#lazy 'WP' 'Browser'#lazy
                      'Compiler' 'Emacs'#lazy]
   'Profiler':       ['SP' 'OP' 'WP' 'Browser'#lazy 'Compiler' 'Emacs'#lazy]
   'Gump':           ['SP' 'OP']
   'GumpScanner':    ['SP']
   'GumpParser':     ['SP']
   'Misc':           nil)
