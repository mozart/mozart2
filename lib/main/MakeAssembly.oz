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

\insert 'sp/ErrorRegistry.oz'
= NewErrorRegistry

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

\insert 'op/Pickle.oz'
= NewPickle

\insert 'Compiler.oz'
= NewCompiler

\insert 'init/Module.oz'

UrlDefaults = \insert '../url-defaults.oz'

{{`Builtin` 'save' 2}
 proc instantiate {$}

    System        = {NewSystem.apply
                     'import'()}
    ErrorRegistry = {NewErrorRegistry.apply
                     'import'('Error': Error)}
    Error         = {NewError.apply
                     'import'('System':        System
                              'ErrorRegistry': ErrorRegistry)}
    Foreign       = {NewForeign.apply
                     'import'('System':        System
                              'Error':         Error
                              'ErrorRegistry': ErrorRegistry)}

    FD            = {NewFD.apply
                     'import'('Foreign': Foreign
                              'Error':         Error
                              'ErrorRegistry': ErrorRegistry)}
    FS            = {NewFS.apply
                     'import'('Foreign': Foreign
                              'FD':      FD)}
    Search        = {NewSearch.apply
                     'import'('Error':         Error
                              'ErrorRegistry': ErrorRegistry)}
    OS            = {NewOS.apply
                     'import'()}
    Open          = {NewOpen.apply
                     'import'('OS':            OS
                              'Error':         Error
                              'ErrorRegistry': ErrorRegistry
                              'URL':           'export'(open: unit))}
    Pickle        = {NewPickle.apply
                     'import'()}
    Compiler      = {NewCompiler.apply
                     'import'('System':        System
                              'Foreign':       Foreign
                              'Error':         Error
                              'ErrorRegistry': ErrorRegistry
                              'FS':            FS
                              'FD':            FD
                              'Search':        Search)}
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
