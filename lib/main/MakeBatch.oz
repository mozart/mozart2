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

   NewAP = {Load 'AP.ozc'}
   AP = {NewAP m('SP':SP 'OP':OP)}
   \insert 'AP.env'
   = AP
end

\ifdef NEWCOMPILER
%% Inserting a bogus directive here splits this file into two directives.
%% This implied that after loading the above components, the environment
%% gets reannotated by the compiler, providing for more opportunities for
%% optimization.
\switch
\endif

{Application.exec
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
