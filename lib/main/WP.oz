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

\ifdef LILO

functor $

import
   OP.{Open    = 'Open'
       URL     = 'URL'
       OS      = 'OS'}
   SP.{System  = 'System'
       Foreign = 'Foreign'}

export
   'Tk':      Tk
   'TkTools': TkTools

body
   Tk      = \insert 'wp/Tk.oz'
   \insert 'wp/TkOptions.oz'
   TkTools = \insert 'wp/TkTools.oz'

end

\else

fun instantiate {$ IMPORT}
   \insert 'OP.env'
       = IMPORT.'OP'
   \insert 'SP.env'
       = IMPORT.'SP'

   Tk      = \insert 'wp/Tk.oz'

   \insert 'wp/TkOptions.oz'

   TkTools = \insert 'wp/TkTools.oz'

in
   \insert 'WP.env'
end

\endif
