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
   CP
in

CP = cp('Search':     Search
        'SearchOne':  SearchOne
        'SearchAll':  SearchAll
        'SearchBest': SearchBest
        'FD':         FD
        `::`
        `:::`

        `GenSum`
        `GenSumC`
        `GenSumCN`
        `PlusRel`
        `TimesRel`
        `Lec`
        `Gec`
        `Nec`
        `Lepc`
        `Nepc`
        `Neq`
        `GenSumR`
        `GenSumCR`
        `GenSumCNR`
        `::R`
        `:::R`

        `CDHeader`
        `CDBody`
        `GenSumCD`
        `GenSumCCD`
        `GenSumCNCD`
        `::CD`
        `:::CD`
