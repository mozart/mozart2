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

declare
local
   Load = {`Builtin` load 2}
in
   NewSP = {Load 'SP.ozc'}
   SP = {NewSP m}
   \insert 'SP.env'
   = SP

   NewOP = {Load 'OP.ozc'}
   OP = {NewOP m('SP': SP)}
   \insert 'OP.env'
   = OP
end

\ifdef NEWCOMPILER
\switch
\endif

{Application.exec
 'ozbatch'
 c('SP':       lazy
   'OP':       lazy
   'Compiler': eager)

 proc instantiate {$ IMPORT ?BatchCompile}
    \insert 'SP.env'
    = IMPORT.'SP'
    \insert 'OP.env'
    = IMPORT.'OP'
    \insert 'Compiler.env'
    = IMPORT.'Compiler'
 in
    \insert BatchCompile
 end

 plain}
