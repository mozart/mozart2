%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Christian Schulte
%%%  Email: schulte@dfki.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

\insert 'Site.oz'

\ifdef SAVE
declare NewDP in

fun {NewDP}
   dp('Site':           Site
      'Load':           Load
      'SmartSave':      SmartSave
      'Save':           Save
      'NewGate':        NewGate
      'Server':         Server
      'NewServer':      NewServer
      'NewAgenda':      NewAgenda
      'ComputeServer':  ComputeServer
      'LinkToNetscape': LinkToNetscape
      'RunApplets':     RunApplets)
end
\endif
