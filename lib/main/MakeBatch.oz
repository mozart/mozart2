%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

\ifdef LILO

{Application.syslet
 'ozbatch'
 functor
 import
    LILO.load
    SP.{System='System' Error='Error'}
    OP.{OS='OS' Open='Open' Component='Component'}
    Compiler.{X='Compiler'}
 export
    BatchCompile
 body
    Compiler = X
 in
    \insert BatchCompile
 end
 plain}

\else

{Application.syslet
 'ozbatch'
 c('SP':       eager
   'OP':       lazy
   'AP':       lazy
   'Compiler': eager)
 proc instantiate {$ IMPORT ?BatchCompile}
    \insert 'SP.env'
    = IMPORT.'SP'
    \insert 'OP.env'
    = IMPORT.'OP'
    \insert 'AP.env'
    = IMPORT.'AP'
    \insert 'Compiler.env'
    = IMPORT.'Compiler'
 in
    \insert BatchCompile
 end
 plain}

\endif
