%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Denys Duchier, Christian Schulte
%%%  Email: duchier@ps.uni-sb.de, schulte@dfki.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

\insert 'Base.oz'

local
   \insert 'LoadDump.oz'
in
   local
      BASE = \insert 'Base.env'
   in
      {Dump BASE 'Base'}
   end

   {Dump NewStandard 'Standard'}

end

\insert 'DumpHalt.oz'
