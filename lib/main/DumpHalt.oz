%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Denys Duchier, Christian Schulte
%%%  Email: duchier@ps.uni-sb.de, schulte@dfki.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

\ifndef NOHALT

local
   Delay = {`Builtin` 'Delay' 1}
in
   {Delay 1000}
end

{{`Builtin` 'shutdown' 1} 0}

\endif
