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
NewSP NewOP NewCP NewCompiler
in
\insert SP
= NewSP
\insert OP
= NewOP
\insert CP
= NewCP
\insert Compiler
= NewCompiler

local
   Env = m('SP':       \insert SP.env
           'CP':       \insert CP.env
           'OP':       \insert OP.env
           'Compiler': \insert Compiler.env
          )
   \insert SP.env
   = {NewSP Env}
   \insert CP.env
   = {NewCP Env}
   \insert OP.env
   = {NewOP Env}
   \insert Compiler.env
   = {NewCompiler Env}

   \insert StartOPI
in
   {StartOPI
    {Record.foldL Env Adjoin
     {Adjoin
      \insert Base.env
      \insert Standard.env
     }}}
end
