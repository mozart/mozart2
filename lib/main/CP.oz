%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Christian Schulte
%%%  Email: schulte@dfki.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

\ifdef NEWSAVE
declare
fun {NewCP Standard}
\insert 'Standard.env'
   = Standard
in
   local
\insert 'Search.oz'
\insert 'FD.oz'
\insert 'FS.oz'
   in
      \insert 'CP.env'
   end
end
\else

\insert 'Search.oz'
\insert 'FD.oz'
\insert 'FS.oz'

\ifdef SAVE
declare
fun {NewCP}
\insert 'CP.env'
end
\endif
\endif
