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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

\insert Standard

declare
RunTimeLibrary = {Dictionary.toRecord 'export' `runTimeDict`}

declare
NewErrorRegistry
NewError
NewFS
NewFD
NewSearch
Search
NewOpen
NewType
NewCompiler
UrlDefaults
OuterBoot
NewModule
in

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

Search = {NewSearch.apply 'import'}

\insert 'op/Open.oz'
= NewOpen

\insert 'support/Type.oz'
= NewType

local
   URL = {\insert dp/URL.oz
          .apply 'import'}
in
   \insert 'init/Module.oz'
end

local
   FunMisc      = \insert compiler/FunMisc
   FunBuiltins  = \insert compiler/FunBuiltins
   FunSA        = \insert compiler/FunSA
   FunCode      = \insert compiler/FunCode
   FunCore      = \insert compiler/FunCore
   FunRT        = \insert compiler/FunRT
   FunUnnest    = \insert compiler/FunUnnest
   FunAssembler = \insert compiler/FunAssembler
   FunCompiler  = \insert compiler/FunCompiler
in
   NewCompiler  = \insert compiler/FunMain
end


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
             'CompilerSupport': CompilerSupport
             'Debug':         Debug

             %% Volatile modules
             'OS':            OS
             'Pickle':        Pickle
             'Property':      Property
             'System':        System
             'Module':        Module

             %% Constructed modules
             'RunTimeLibrary': !RunTimeLibrary

             %% Plain functors
             'Error':         Error
             'ErrorRegistry': ErrorRegistry
             'FD':            FD
             'Open':          Open
             'Resolve':       'export'(open:unit)
             'FS':            FS
             'Type':          Type)
    =IMPORT

    BootManager = {`Builtin` 'BootManager'  2}

    {ForAll ['Parser'#          Parser
             'FDB'#             FDB
             'FSB'#             FSB
             'FDP'#             FDP
             'FSP'#             FSP
             'OS'#              OS
             'Pickle'#          Pickle
             'System'#          System
             'Debug'#           Debug
             'CompilerSupport'# CompilerSupport
             'Property'#        Property]
     proc {$ A#M}
        M={BootManager A}
     end}

    Compiler

    {ForAll [ErrorRegistry # NewErrorRegistry
             Error         # NewError
             FD            # NewFD
             FS            # NewFS
             Open          # NewOpen
             Type          # NewType
             Compiler      # NewCompiler]
     proc {$ V#F}
        thread {F.apply IMPORT}=V end
     end}

    Module = {NewModule.apply 'import'('Pickle': Pickle
                                       'System': System
                                       'OS':     OS
                                       'Boot':   b(manager: BootManager))}

    {ForAll ['Parser'#          Parser
             'FDB'#             FDB
             'FSB'#             FSB
             'FDP'#             FDP
             'Debug'#           Debug
             'FSP'#             FSP
             'CompilerSupport'# CompilerSupport]
     proc {$ A#M}
        {Module.root enter(url:'x-oz://boot/'#A M)}
     end}

    {ForAll ['System'#       System
             'Property'#     Property
             'ErrorRegistry'#ErrorRegistry
             'Error'#        Error
             'FD'#           FD
             'FS'#           FS
             'OS'#           OS
             'Open'#         Open
             'Pickle'#       Pickle
             'Compiler'#     Compiler
             'Module'#       Module]
     proc {$ A#M}
        {Module.root enter(name:A M)}
     end}

    \insert BatchCompile
 in
    {System.exit {BatchCompile {Map {Property.get argv} Atom.toString}}}
 end 'ozc'#UrlDefaults.pickle}

{{OuterBoot 'System'}.exit 0}
