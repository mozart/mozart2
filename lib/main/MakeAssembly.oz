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

\insert Standard

declare
NewSP NewCP NewOP NewAP NewGump NewCompiler
in
\insert SP
= NewSP
\insert CP
= NewCP
\insert OP
= NewOP
\insert AP
= NewAP
\insert Gump
= NewGump
\insert Compiler
= NewCompiler

local
   Env = m('SP':       \insert SP.env
           'CP':       \insert CP.env
           'OP':       \insert OP.env
           'AP':       \insert AP.env
           'Gump':     \insert Gump.env
           'Compiler': \insert Compiler.env
          )
   \insert SP.env
   = {NewSP Env}
   \insert CP.env
   = {NewCP Env}
   \insert OP.env
   = {NewOP Env}
   \insert AP.env
   = {NewAP Env}
   \insert Gump.env
   = {NewGump Env}
   \insert Compiler.env
   = {NewCompiler Env}

   \insert BatchCompile
in
   {Exit {BatchCompile {Map {System.get argv} Atom.toString}}}
end
