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
NewOpen
NewPickle
NewCompiler
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

\insert 'op/Open.oz'
= NewOpen

\insert 'op/Pickle.oz'
= NewPickle

\insert 'Compiler.oz'
= NewCompiler


UrlDefaults = \insert '../url-defaults.oz'

{{`Builtin` 'save' 2}
 functor prop once body

    IMPORT


    'import'(%% Boot modules
             'Parser':        Parser
             'FDP':           FDP
             'FSP':           FSP

             %% Volatile modules
             'OS':            OS
             'Property':      Property

             %% Plain functors
             'System':        System
             'Foreign':       Foreign
             'Error':         Error
             'ErrorRegistry': ErrorRegistry
             'FD':            FD
             'Open':          Open
             'URL':           'export'(open:unit)
             'FS':            FS
             'Pickle':        Pickle
             'Search':        Search)
    =IMPORT

    BootManager = {`Builtin` 'BootManager'  2}

    {ForAll ['Parser'#   Parser
             'FDP'#      FDP
             'FSP'#      FSP
             'OS'#       OS
             'Property'# Property]
     proc {$ A#M}
        M={BootManager A}
     end}

    Compiler

    {ForAll [System        # NewSystem
             Foreign       # NewForeign
             ErrorRegistry # NewErrorRegistry
             Error         # NewError
             FD            # NewFD
             FS            # NewFS
             Search        # NewSearch
             Open          # NewOpen
             Pickle        # NewPickle
             Compiler      # NewCompiler]
     proc {$ V#F}
        thread {F.apply IMPORT}=V end
     end}

    \insert 'init/Module.oz'

    Module = {NewModule}

    {ForAll ['Parser'# Parser
             'FDP'#    FDP
             'FSP'#    FSP]
     proc {$ A#M}
        {Module.enter 'x-oz-boot:'#A M}
     end}

    {ForAll ['System'#       System
             'Foreign'#      Foreign
             'Property'#     Property
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
    {System.exit {BatchCompile {Map {Property.get argv} Atom.toString}}}
 end 'ozc'#UrlDefaults.pickle}

{{`Builtin` 'shutdown' 1} 0}
