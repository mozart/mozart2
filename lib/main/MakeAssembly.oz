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

\insert Standard

declare
NewSystem
NewForeign
NewError
NewFS
NewFD
NewSearch
NewOS
NewOpen
NewComponent
NewCompiler
NewLILO
in
\insert 'sp/System.oz'
= NewSystem

\insert 'sp/Foreign.oz'
= NewForeign

\insert 'sp/Error.oz'
= NewError

\insert 'cp/FD.oz'
= NewFD

\insert 'cp/FS.oz'
= NewFS

\insert 'cp/Search.oz'
= NewSearch

\insert 'op/OS.oz'
= NewOS

\insert 'op/Open.oz'
= NewOpen

\insert 'op/Component.oz'
= NewComponent

\insert 'Compiler.oz'
= NewCompiler

\insert 'lilo/LILO.oz'

{{`Builtin` 'save' 2}
 proc instantiate {$}

    System    = {NewSystem.'apply'
                 'import'}
    Foreign   = {NewForeign.'apply'
                 'import'('System':System)}
    Error     = {NewError.'apply'
                 'import'('System':System)}
    FD        = {NewFD.'apply'
                 'import'('Foreign':Foreign)}
    FS        = {NewFS.'apply'
                 'import'('Foreign':Foreign
                          'FD':     FD)}
    Search    = {NewSearch.'apply'
                 'import'}
    OS        = {NewOS.'apply'
                 'import'}
    Open      = {NewOpen.'apply'
                 'import'('OS':  OS
                          'URL': 'export'(open:unit))}
    Component = {NewComponent.'apply'
                 'import'}
    Compiler  = {NewCompiler.'apply'
                 'import'('System':  System
                          'Foreign': Foreign
                          'Error':   Error
                          'FS':      FS
                          'FD':      FD
                          'Search':  Search
                         )}
    LILO = {NewLILO}

       \insert BatchCompile
 in
    {System.exit {BatchCompile {Map {System.get argv} Atom.toString}}}
 end 'ozc.ozc'}

{{`Builtin` 'shutdown' 1} 0}

\else

\insert Standard

declare
NewSP NewCP NewOP NewAP NewCompiler
in
\insert SP
= NewSP
\insert CP
= NewCP
\insert OP
= NewOP
\insert AP
= NewAP
\insert Compiler
= NewCompiler

{{`Builtin` 'save' 2}
 proc instantiate {$}
    Env = m('SP':       \insert SP.env
            'CP':       \insert CP.env
            'OP':       \insert OP.env
            'AP':       \insert AP.env
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
    \insert Compiler.env
    = {NewCompiler Env}

    \insert BatchCompile
 in
    {Exit {BatchCompile {Map {System.get argv} Atom.toString}}}
 end 'ozbatch.ozc'}

{{`Builtin` 'shutdown' 1} 0}

\endif
