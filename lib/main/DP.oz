%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Christian Schulte
%%%  Email: schulte@dfki.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

\ifdef NEWSAVE
declare
fun {NewDP Standard NewTk}
\insert 'Standard.env'
   = Standard
in
   local
      \insert 'Site.oz'
   in
      \insert 'DP.env'
   end
end
\else

\insert 'Site.oz'

\ifdef SAVE
declare
fun {NewDP}
   \insert 'DP.env'
end
\endif
\endif
