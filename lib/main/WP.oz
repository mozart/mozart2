%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Christian Schulte, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

fun instantiate {$ IMPORT}
   \insert 'OP.env'
       = IMPORT.'OP'
   \insert 'SP.env'
       = IMPORT.'SP'
   \insert WP/Tk
   Tk      = {NewTk}
   \insert WP/TkOptions
   \insert WP/TkTools
   TkTools = {NewTkTools Tk}
in
   \insert 'WP.env'
end
