%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Christian Schulte
%%%  Email: schulte@dfki.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

%%%
%%% This file creates the Open Programming Functor
%%%

\insert 'OS.oz'

declare
fun
\ifdef NEWCOMPILER
   instantiate
\endif
   {NewOP IMPORT}
   \insert 'SP.env'
   = IMPORT.'SP'

   \insert 'Open.oz'
   \insert 'Component.oz'
   \insert 'Application.oz'

in
   \insert 'OP.env'
end
