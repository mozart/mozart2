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
NewForeign
NewErrorRegistry
NewError
NewFS
NewFD
NewSearch
NewOpen
NewCompiler
UrlDefaults
OuterBoot
in
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

\insert 'Compiler.oz'
= NewCompiler


UrlDefaults = \insert '../url-defaults.oz'

OuterBoot = {`Builtin` 'BootManager' 2}

{{OuterBoot 'Pickle'}.save
 functor prop once body

    IMPORT


    'import'(%% Boot modules
             'Parser':        Parser
             'FDP':           FDP
             'FDB':           FDB
             'FSP':           FSP
             'FSB':           FSB
             'AssemblerSupport':       AssemblerSupport
             'CompilerSupport': CompilerSupport

             %% Volatile modules
             'OS':            OS
             'Pickle':        Pickle
             'Property':      Property
             'System':        System

             %% Plain functors
             'Foreign':       Foreign
             'Error':         Error
             'ErrorRegistry': ErrorRegistry
             'FD':            FD
             'Open':          Open
             'URL':           'export'(open:unit)
             'FS':            FS
             'Search':        Search)
    =IMPORT

    BootManager = {`Builtin` 'BootManager'  2}

    {ForAll ['Parser'#   Parser
             'FDB'#      FDB
             'FSB'#      FSB
             'FDP'#      FDP
             'FSP'#      FSP
             'OS'#       OS
             'Pickle'#   Pickle
             'System'#   System
             'AssemblerSupport'#     AssemblerSupport
             'CompilerSupport'#      CompilerSupport
             'Property'# Property]
     proc {$ A#M}
        M={BootManager A}
     end}

    Compiler

    {ForAll [Foreign       # NewForeign
             ErrorRegistry # NewErrorRegistry
             Error         # NewError
             FD            # NewFD
             FS            # NewFS
             Search        # NewSearch
             Open          # NewOpen
             Compiler      # NewCompiler]
     proc {$ V#F}
        thread {F.apply IMPORT}=V end
     end}

    \insert 'init/Module.oz'

    Module = {NewModule}

    {ForAll ['Parser'#   Parser
             'FDB'#      FDB
             'FSB'#      FSB
             'FDP'#      FDP
             'FSP'#      FSP
             'OS'#       OS
             'Pickle'#   Pickle
             'System'#   System
             'AssemblerSupport'# AssemblerSupport
             'CompilerSupport'#  CompilerSupport
             'Property'# Property]
     proc {$ A#M}
        {Module.enter 'x-oz-boot://'#A M}
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

{{OuterBoot 'System'}.exit 0}
