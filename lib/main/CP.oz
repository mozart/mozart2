%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Christian Schulte
%%%  Email: schulte@dfki.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

\insert 'Search.oz'
\insert 'FD.oz'
\insert 'FSET.oz'

\ifdef SAVE
declare
   NewCP
in

local
   CP = cp('Search':       Search
           'SearchOne':    SearchOne
           'SearchAll':    SearchAll
           'SearchBest':   SearchBest
           'FD':           FD
           '`::`':         `::`
           '`:::`':        `:::`
           '`GenSum`':     `GenSum`
           '`GenSumC`':    `GenSumC`
           '`GenSumCN`':   `GenSumCN`
           '`PlusRel`':    `PlusRel`
           '`TimesRel`':   `TimesRel`
           '`Lec`':        `Lec`
           '`Gec`':        `Gec`
           '`Nec`':        `Nec`
           '`Lepc`':       `Lepc`
           '`Nepc`':       `Nepc`
           '`Neq`':        `Neq`
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
           'FS':           FS)
in

   fun {NewCP}
      CP
   end

end



\endif
