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

oz('Panel':          ['SP' 'OP' 'WP']
   'Browser':        ['SP' 'WP' 'CP']
   'Explorer':       ['SP' 'WP' 'Browser'#lazy]
   'CompilerPanel':  ['SP' 'CP' 'OP' 'WP' 'Compiler'
                      'Browser'#lazy 'Emacs'#lazy]
   'Emacs':          ['OP' 'SP' 'Compiler']
   'Ozcar':          ['SP' 'CP'#lazy 'WP'
                      'Browser'#lazy 'Compiler'#lazy 'Emacs'#lazy]
   'Profiler':       ['SP' 'OP' 'WP' 'Browser'#lazy 'Emacs'#lazy]
   'Gump':           ['SP' 'OP']
   'GumpScanner':    ['SP']
   'GumpParser':     ['SP'])
