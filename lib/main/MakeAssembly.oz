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
NewSystem
NewForeign
NewErrorRegistry
NewError
NewFS
NewFD
NewSearch
NewOS
NewOpen
NewPickle
NewCompiler
NewModule
UrlDefaults
in
\insert 'sp/System.oz'
= NewSystem

\insert 'sp/Foreign.oz'
= NewForeign

\insert 'sp/Error.oz'
= NewError

\insert 'sp/ErrorRegistry.oz'
= NewErrorRegistry

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

\insert 'op/Pickle.oz'
= NewPickle

\insert 'Compiler.oz'
= NewCompiler

\insert 'init/Module.oz'

UrlDefaults = \insert '../url-defaults.oz'

{{`Builtin` 'save' 2}
 functor prop once body

    IMPORT

    'import'('System':        System
             'Foreign':       Foreign
             'Error':         Error
             'ErrorRegistry': ErrorRegistry
             'FD':            FD
             'OS':            OS
             'Open':          Open
             'URL':           'export'(open:unit)
             'FS':            FS
             'Pickle':        Pickle
             'Search':        Search)
    =IMPORT

    Compiler

    {ForAll [System        # NewSystem
             Foreign       # NewForeign
             ErrorRegistry # NewErrorRegistry
             Error         # NewError
             FD            # NewFD
             FS            # NewFS
             Search        # NewSearch
             OS            # NewOS
             Open          # NewOpen
             Pickle        # NewPickle
             Compiler      # NewCompiler]
     proc {$ V#F}
        thread {F.apply IMPORT}=V end
     end}

    Module = {NewModule}

    {ForAll ['System'#       System
             'Foreign'#      Foreign
             'ErrorRegistry'#ErrorRegistry
             'Error'#        Error
             'FD'#           FD
             'FS'#           FS
             'Search'#       Search
             'OS'#           OS
             'Open'#         Open
             'Pickle'#       Pickle
             'Compiler'#     Compiler]

     proc {$ A#M}
        {Module.enter UrlDefaults.home#'lib/'#A#UrlDefaults.'functor' M}
     end}

    \insert BatchCompile
 in
    {System.exit {BatchCompile {Map {System.get argv} Atom.toString}}}
 end 'ozc'#UrlDefaults.pickle}

{{`Builtin` 'shutdown' 1} 0}
