%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Christian Schulte
%%%  Email: schulte@dfki.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

%%%
%%% This file creates the System Programming Functor
%%%

declare
fun {NewSP IMPORT}
   \insert 'Standard.env'
   = IMPORT.'Standard'

   \insert 'Foreign.oz'
   \insert 'System.oz'
   \insert 'Debug.oz'
   \insert 'Error.oz'

   Foreign = {NewForeign}
   Error   = {NewError}
in
   \insert 'SP.env'
end
