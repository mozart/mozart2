%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Christian Schulte
%%%  Email: schulte@dfki.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

declare

fun {NewWP Standard Open}
   \insert 'Standard.env'
       = Standard
   \insert 'Tk.oz'
   Tk      = {NewTk Open}
   \insert 'TkTools.oz'
   TkTools = {NewTkTools Tk}
in
   \insert 'WP.env'
end
