%%%  Programming Systems Lab, DFKI Saarbruecken,
%%%  Stuhlsatzenhausweg 3, D-66123 Saarbruecken, Phone (+49) 681 302-5312
%%%  Author: Christian Schulte
%%%  Email: schulte@dfki.de
%%%  Last modified: $Date$ by $Author$
%%%  Version: $Revision$

\ifdef NEWSAVE
declare
fun {NewWP Standard Open}
\insert 'Standard.env'
   = Standard
in
   local
\insert 'Tk.oz'
\insert 'TkTools.oz'
   in
      local
         Tk = {NewTk Open}
         TkTools = {NewTkTools Tk}
      in
\insert 'WP.env'
      end
   end
end
\else

\insert 'Tk.oz'
\insert 'TkTools.oz'

\ifdef SAVE
declare
fun {NewWP Open}
   Tk      = {NewTk Open}
   TkTools = {NewTkTools Tk}
in
   \insert 'WP.env'
end
\endif
\endif
