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

\ifdef LILO

functor $

import
   SP.{Show    = 'Show'   % Should go away (FS.oz)
       Foreign = 'Foreign' }

export
   'Search':       Search
   'SearchOne':    SearchOne
   'SearchAll':    SearchAll
   'SearchBest':   SearchBest
   'FD':           FD
   '`::`':         `::`
   '`:::`':        `:::`
   '`GenSum`':     `GenSum`
   '`GenSumC`':    `GenSumC`
   '`GenSumCN`':   `GenSumCN`
   '`PlusRel`':    `PlusRel`   % NO
   '`TimesRel`':   `TimesRel`  % NO
   '`Lec`':        `Lec`       % NO
   '`Gec`':        `Gec`       % NO
   '`Nec`':        `Nec`       % NO
   '`Lepc`':       `Lepc`      % NO
   '`Nepc`':       `Nepc`      % NO
   '`Neq`':        `Neq`       % NO
   '`GenSumR`':    `GenSumR`
   '`GenSumCR`':   `GenSumCR`
   '`GenSumCNR`':  `GenSumCNR`
   '`::R`':        `::R`
   '`:::R`':       `:::R`
   '`CDHeader`':   `CDHeader`
   '`CDBody`':     `CDBody`
   '`GenSumCD`':   `GenSumCD`
   '`GenSumCCD`':  `GenSumCCD`
   '`GenSumCNCD`': `GenSumCNCD`
   '`::CD`':       `::CD`
   '`:::CD`':      `:::CD`
   'FS':           FS
body

   \insert 'cp/Search.oz'
   \insert 'cp/FD.oz'
   \insert 'cp/FS.oz'
end

\else

fun instantiate {$ IMPORT}
   \insert 'SP.env'
       = IMPORT.'SP'
in
   local
      \insert 'cp/Search.oz'
      \insert 'cp/FD.oz'
      \insert 'cp/FS.oz'
   in
      \insert 'CP.env'
   end
end

\endif
