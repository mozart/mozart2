%%%
%%% Authors:
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Denys Duchier, 1997
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation
%%% of Oz 3
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%
%%% ==================================================================
%%% This file generalizes Christian Schulte's `application builder'
%%% idea which unfortunately was limited to system modules because all
%%% the data was wired in.  Also that code did not allow instantiating
%%% a functor in more than one way.
%%%
%%% Instead, I propose to register module construction descriptions.
%%% Thus, the application building facility can be arbitrarily extended
%%% with new modules.  Also the name of the module and the feature on
%%% which it is put in an IMPORT record are no longer required to be
%%% identical.
%%%
%%% Among the other extensions is the possibility to register
%%% submodules, which saves the programmer the headache of having to
%%% remember in which component module M has been stashed away.  It
%%% also makes application building more robust, because nothing
%%% changes if a registered submodule has been moved from one
%%% component to another: the registry keeps track of this, not the
%%% application.
%%% ------------------------------------------------------------------
%%% {Application.registry.new ?R}
%%%
%%% Returns a new registry initialized with entries for all system
%%% modules and useful submodules.
%%% ------------------------------------------------------------------
%%% {Application.registry.register R NAME x(src:SRC args:ARGS type:TYPE<=unit)}
%%%
%%% adds an entry for NAME to the registry.
%%%
%%% * SRC describes where the functor may be obtained, valid values
%%%   are:
%%%             url(URL)
%%%             value(FUN)
%%%             path(PATH)
%%%             system(BASENAME)
%%%
%%%   value(FUN) is for the case when the functor is not in a component
%%%   but is given explicitly as a procedure value. path(PATH) is for
%%%   the case that the module is to be looked up in an argument to the
%%%   functor: this facilitates creating entries for submodules.
%%%   system(BASENAME) is used for system components in Oz/lib; these
%%%   are not registered as url so as to permit local testing of
%%%   components via the environment variable OZCOMPONENTS.  The url
%%%   is then computed dynamically.
%%%
%%% * ARGS is a record of FEATURE:MODULE_NAME mappings.  It describes
%%%   the shape of the functor's IMPORT record and indicates which
%%%   module should be plugged into each feature.
%%%
%%% * TYPE describes the interface exported by a module.  This makes
%%%   it possible to create a `lazy' interface that makes available
%%%   all values exported by the module without actually loading the
%%%   the module.  Only when one of these values is touched/requested
%%%   is the module actually loaded, and, as a side-effect, all the
%%%   lazy exports are then instantiated with their actual values.
%%%   valid values are:
%%%
%%%             LABEL#ARITY
%%%             file(FILE)
%%%             load(URL)       system(NAME)
%%%             unit
%%%
%%%   LABEL#ARITY describes an export record.  file(FILE) indicates
%%%   that FILE is a `*.env' kind of file from which LABEL#ARITY can
%%%   be computed. unit indicates that no interface is available.
%%%   load(URL) indicates that LABEL#ARITY can be obtained by loading
%%%   the component available at URL.  system(NAME) is essentially
%%%   equivalent to load(COMPS#NAME#'.tyc') where COMPS is either the
%%%   value of environment variable OZCOMPONENTS or the default:
%%%   'http://www.ps.uni-sb.de/ozhome/lib/'.
%%% ------------------------------------------------------------------
%%% {Application.registry.plan R SPEC ?PLAN}
%%%
%%% SPEC describes the IMPORT record for a functor that implements a
%%% `stand-alone' application.  This is slightly more complicated than
%%% the ARGS record for a module because, in addition, we want to
%%% specify how the arguments should be loaded: either lazily, eagerly,
%%% or by including it directly in application component to be created.
%%% SPEC contains FEATURE:MODULE#MODE mappings where MODE is one of
%%% {lazy,lazyTop,eager,include}. lazyTop indicates lazyness, but will
%%% not cause the creation of a lazy interface; only the module itself
%%% will be lazy.
%%% ------------------------------------------------------------------
%%% {Application.registry.exec R FILE SPEC FUNCTOR ARGSPEC}
%%%
%%% creates an executable component in FILE whose imports are specified
%%% by SPEC.  FUNCTOR applied to the IMPORTS creates a function SCRIPT.
%%% SCRIPT applied to a value summarizing the command-line arguments
%%% supplied to the executable returns an integer status: 0 as usual,
%%% means that everything went ok.  The value summarizing the command
%%% line arguments is computed according to ARGSPEC whose syntax is as
%%% defined by Christian Schulte, with the addition of ARGSPEC=unit to
%%% mean that we are not interested in the arguments.
%%% ------------------------------------------------------------------
%%% {Application.registry.cgi R FILE SPEC FUNCTOR CGISPEC}
%%%
%%% creates an executable component that serves as a CGI script.  The
%%% only difference with the above is that there are no command-line
%%% arguments; instead, most of the data comes from the environment
%%% variable QUERY_STRING as usual.  Other than that, I don't know
%%% what the syntax for CGISPEC is supposed to be.
%%% ------------------------------------------------------------------
%%% There is a default registry for convenience and for backward
%%% compatibility with Christian's interface.
%%% {Application.register NAME x(src:SRC args:ARGS type:TYPE<=unit)}
%%% {Application.plan SPEC ?PLAN}
%%% {Application.exec FILE SPEC FUNCTOR ARGSPEC}
%%% {Application.cgi  FILE SPEC FUNCTOR CGISPEC}
%%% ==================================================================
\ifdef FOOBAR
declare
\endif
local
   proc {NameNotFound Name}
      raise error(registry(nameNotFound Name) debug:debug)
      with debug end
   end
   proc {BadRegistration Name Desc Which}
      raise error(registry(badRegistration Name Desc Which) debug:debug)
      with debug end
   end
   proc {BadDescriptor Name Desc}
      raise error(registry(badDescriptor Name Desc) debug:debug)
      with debug end
   end
   proc {CircularDependency Name}
      raise error(registry(circularDependency Name) debug:debug)
      with  debug end
   end
   fun {RegistryFormatter Exc}
      case Exc.1
      of registry(nameNotFound Name) then
         {Adjoin
          {Error.formatter.generic 'module name not found: '#oz(Name) Exc}
          error(body:unit kind:'Registry Error')}
      elseof registry(badRegistration Name Desc Which) then
         {Adjoin
          {Error.formatter.generic 'Bad Registration Attempt' Exc}
          error(body:[line('for module : '#oz(Name))
                      line('at argument: '#oz(Which))
                      line('in         : '#oz(Desc))]
                kind:'Registry Error')}
      elseof registry(circularDependency Name) then
         {Adjoin
          {Error.formatter.generic
           'circular dependency for module: '#oz(Name) Exc}
          error(body:unit kind:'Registry Error')}
      else
         {Adjoin
          {Error.formatter.generic 'unrecognized exception' Exc}
          error(kind:'Registry Error')}
      end
   end
   %%
   %% {Registry.new ?R}
   %%
   fun {NewEmptyRegistry}
      registry({Dictionary.new})
   end
   %%
   fun {RegistryGetPlan R Spec}
      ArgsMap = {Dictionary.new} ArgsLst ArgsLstSorted
      DepsMap = {Dictionary.new}
      ModeMap = {Dictionary.new}
   in
      % find all necessary modules and record them in ArgsMap
      %
      {Record.forAll Spec
       proc {$ Name#Mode} {RegistryGetAllDeps R Name ArgsMap} end}
      ArgsLst = {Dictionary.keys ArgsMap}
      %
      % for each one, compute the set of modules it recursively
      % depends on and record them in DepsMap
      %
      {ForAll ArgsLst
       proc {$ Name}
          {Dictionary.put DepsMap Name {RegistryDependsOn R Name}}
       end}
      %
      % sort according to dependencies: a modules should appear
      % after the argument modules it depends on.
      %         [it is possible to improve the complexity here
      %          but I don't think it is worth the bother]
      ArgsLstSorted =
      {Sort ArgsLst
       fun {$ M1 M2} {Member M1 {Dictionary.get DepsMap M2}} end}
      %
      % Now we compute the modes for all the required modules.
      % Each module Name in Spec is associated with a Mode.
      % For each recursive dependency X of Name (which we have already
      % computed in DepsMap) we update X's mode with Mode.  This
      % update is effected by combination where the strongest mode
      % wins: include > eager > lazy > lazyTop
      %
      {Record.forAll Spec
       proc {$ Name#Mode}
          {Dictionary.put ModeMap Name
           {ModeCombine Mode
            % if Name appeared in the dependency of an earlier
            % module of Spec, it would already have a
            % recorded mode: we need to look it up
            {Dictionary.condGet ModeMap Name 'lazyTop'}}}
          {ForAll {Dictionary.get DepsMap Name}
           proc {$ Arg}
              {Dictionary.put ModeMap Arg
               {ModeCombine Mode
                {Dictionary.condGet ModeMap Arg 'lazyTop'}}}
           end}
       end}
      %
      % The plan consists of the sorted list of all required
      % modules, each paired with its mode
      %
      {Map ArgsLstSorted
       fun {$ Name} Name#{Dictionary.get ModeMap Name} end}
   end
   %%
   %% {RegistryGetAllDeps R Name ArgsMap}
   %%   records in ArgsMap all the modules that Name depends on
   %%   (including Name itself).
   %%
   proc {RegistryGetAllDeps R Name ArgsMap}
      %% either Name itself is already recorded in ArgsMap, which
      %% means we have already processed it, in which case we
      %% return immediately
      case {Dictionary.condGet ArgsMap Name false} then skip else
         % ...or we record Name in ArgsMap and start exploring
         % its dependencies.
         {Dictionary.put ArgsMap Name true}
         {Record.forAll {RegistryGetArgs R Name}
          proc {$ Arg} {RegistryGetAllDeps R Arg ArgsMap} end}
      end
   end
   %%
   %% {RegistryGet R Name $}
   %%   returns the descriptor for Name or raises an error
   %%
   fun {RegistryGet R Name}
      E={Dictionary.condGet {RegistryGetMap R} Name unit}
   in
      case E==unit then {NameNotFound Name} _ else E end
   end
   fun {RegistryGetMap R} R.1 end
   %%
   %% {RegistryGetArgs R Name $}
   %%   returns a record of FEATURE:MODULE mappings
   %%
   fun {RegistryGetArgs R Name}
      {RegistryGet R Name}.args
   end
   %%
   %% {RegistryDependsOn R Name $}
   %%   compute the transitive closure of the modules Name depends on
   %%
   fun {RegistryDependsOn R Name}
      Deps={Dictionary.new}
   in
      {Record.forAll {RegistryGetArgs R Name}
       proc {$ Arg} {RegistryPropagate R Arg Deps Name} end}
      {Dictionary.keys Deps}
   end
   %%
   %% {RegistryPropagate R Name Deps Except}
   %%   record Name as well as all its recursive dependencies in Deps
   %%   if Name==Except we have found a circularity: we are back at
   %%   the Name that initiated the Propagation from DependsOn.  The
   %%   reason it is enough to watch out for loops that reenter at
   %%   the initiating node, is that we are going to do this for all
   %%   modules involved anyway: if there is a loop, we will eventually
   %%   find it.
   %%
   proc {RegistryPropagate R Name Deps Except}
      % check for circularity
      case Name==Except then {CircularDependency Name}
         % skip, if we have already explored Name
      elsecase {Dictionary.condGet Deps Name false} then skip
         % otherwise, record Name and explore its dependencies
      else
         {Dictionary.put Deps Name true}
         {Record.forAll {RegistryGetArgs R Name}
          proc {$ Arg} {RegistryPropagate R Arg Deps Except} end}
      end
   end
   %%
   %% register(NAME src:SRC args:ARGS type:TYPE)
   %%
   proc {RegistryRegister R NAME Desc}
      SRC  = Desc.src
      ARGS = Desc.args
      TYPE = case {HasFeature Desc type} then Desc.type else unit end
   in
      %% check arguments
      case SRC
      of    url(_) then skip
      []  value(_) then skip
      []   path(_) then skip
      [] system(_) then skip
      else {BadRegistration NAME Desc src} end
      case {Record.is ARGS} andthen {Record.all ARGS Atom.is}
      then skip else {BadRegistration NAME Desc args} end
      case TYPE
      of unit      then skip
      [] _#_       then skip
      [] file(_)   then skip
      [] load(_)   then skip
      [] system(_) then skip
      else {BadRegistration NAME Desc type} end
      {Dictionary.put {RegistryGetMap R} NAME
       module(name:NAME src:SRC args:ARGS type:TYPE)}
   end
   %%
   %% The Loader code is adapted from code originally written
   %% by Christian Schulte, and extended with new functionality
   %%
   %% A loader is a function that applies a functor to arguments
   %% there are 3 versions that differ e.g. in when the functor is
   %% loaded from its url and when it is actually applied to its
   %% arguments.
   %%
   fun {ComputeSystemURL BASENAME}
      {SystemURL}#BASENAME#'.ozc'
   end
   fun {SystemURL}
      case {OS.getEnv 'OZCOMPONENTS'} of false then
         'http://www.ps.uni-sb.de/ozhome/lib/'
      elseof URL then
         case {List.last {VirtualString.toString URL}}==&/ then URL
         else URL#'/'
         end
      end
   end
   %%
   %% MakeEagerLoader creates a loader that, when applied, retrieves
   %% the functor and immediately applies it to its arguments.
   %%
   fun {RegistryMakeEagerLoader R Name}
      case {RegistryGetSrc R Name}
      of url(URL) then
         fun {$ IMPORT} {{Load URL} IMPORT} end
      [] value(FUN) then FUN
      [] path(PATH) then
         fun {$ IMPORT} {LookupPath IMPORT PATH} end
      [] system(BASENAME) then
         fun {$ IMPORT} {{Load {ComputeSystemURL BASENAME}} IMPORT} end
      end
   end
   %%
   fun {RegistryGetSrc R Name}
      {RegistryGet R Name}.src
   end
   %%
   %% MakeLazyLoader creates a loader that, when applied, creates
   %% the `shape' of the exported interface of the module, but
   %% where the values are not yet instantiated.  Instead they are
   %% lazy variables, which, when touched, will cause the functor
   %% to be retrieved and applied to its arguments, thus causing
   %% the values to become instantiated with the module's contents.
   %%
   %% Why do we do it this way instead of making just the module
   %% lazy?  Because typically the programmer wants to open the
   %% interface to the module without causing the module to load.
   %% The programmer will use code like:
   %%
   %%   \insert Foo.env
   %%   = IMPORT.'Foo'
   %%
   %% and this will cause all the variables in the interface to be
   %% lazy: as soon as one is touched, module Foo actually gets loaded.
   %%
   fun {RegistryMakeLazyLoader R Name}
      Entry = {RegistryGet R Name}
      TYPE  = Entry.type
   in
      case TYPE==unit then
            % if the module doesn't have a declared interface, we can
            % only make the module itself lazy, we can't create a lazy
            % interface
         {RegistryMakeLazyTopLoader R Name}
      else
         SRC = Entry.src
         LABEL#ARITY = case TYPE of file(FILE) then {GetType FILE}
                       elseof       load(URL ) then {Load URL}
                       elseof     system(NAME) then
                          {Load {SystemURL}#NAME#'.tyc'}
                       else TYPE end
      in
         proc {$ IMPORT EXPORT}
               % R is the variable controling loading
               % When a lazy variable is touched it will call ForwardRequest
               % and becomes a free variable again.
            R proc {ForwardRequest _} R=unit end
         in
            EXPORT = {Record.make LABEL ARITY}
            {Record.forAllInd EXPORT
             proc {$ F V}
                {Lazy.new ForwardRequest V}
             end}
            thread
                  % wait until loading is requested, then do it
               {Wait R}
               EXPORT=
               case SRC of url(URL) then {{Load URL} IMPORT}
               []        value(FUN) then {FUN IMPORT}
               []        path(PATH) then {LookupPath IMPORT PATH}
               []  system(BASENAME) then {{Load {ComputeSystemURL BASENAME}}
                                          IMPORT}
               end
            end
         end
      end
   end
   %%
   %% MakeLazyTopLoader(Name $)
   %%   creates a loader that, when applied to its imports
   %% creates a lazy variable that waits until it is requested
   %% before it actually applies the real functor.
   %%
   fun {RegistryMakeLazyTopLoader R Name}
      case {RegistryGetSrc R Name}
      of url(URL) then
         fun {$ IMPORT}
            {Lazy.new fun {$} {{Load URL} IMPORT} end}
         end
      [] value(FUN) then
         fun {$ IMPORT}
            {Lazy.new fun {$} {FUN IMPORT} end}
         end
      [] path(PATH) then
         fun {$ IMPORT}
            {Lazy.new fun {$} {LookupPath IMPORT PATH} end}
         end
      [] system(BASENAME) then
         fun {$ IMPORT}
            {Lazy.new fun {$} {{Load {ComputeSystemURL BASENAME}} IMPORT} end}
         end
      end
   end
   %%
   %% MakeIncludeLoader immediately retrieves the functor, which
   %% will cause it to be included in the saved component (because
   %% we simply include everything - i.e. we abandon the idea of
   %% support)
   %%
   fun {RegistryMakeIncludeLoader R Name}
      case {RegistryGetSrc R Name}
      of url(URL) then {Load URL}
      [] value(FUN) then FUN
      [] path(PATH) then
         fun {$ IMPORT} {LookupPath IMPORT PATH} end
      [] system(BASENAME) then {Load {ComputeSystemURL BASENAME}}
      end
   end
   %%
   %% An application is characterized by a set of modules and
   %% the modes in which they are to be loaded. getLoader is given
   %% Spec which is a record of FEATURE:MODULE#MODE mappings and returns
   %% a function, which returns a record of FEATURE:VALUE mappings
   %% where VALUE is the value of the module (which could be a lazy
   %% variable if MODULE's MODE was lazyTop).
   %%
   fun {NormalizeSpec Feat What}
      case What
      of _#_ then What
      else Feat#What end
   end
   fun {RegistryGetLoader R Spec}
      NSpec    = {Record.mapInd Spec NormalizeSpec}
      Plan     = {RegistryGetPlan R NSpec}
      LoadPlan = {Map Plan
                  fun {$ Name#Mode}
                     % Name # Loader # Args
                     Name #
                     case Mode
                     of eager   then {RegistryMakeEagerLoader   R Name}
                     [] lazy    then {RegistryMakeLazyLoader    R Name}
                     [] lazyTop then {RegistryMakeLazyTopLoader R Name}
                     [] include then {RegistryMakeIncludeLoader R Name}
                     end  #
                     {RegistryGetArgs R Name}
                  end}
      Modules  = {Map Plan fun {$ Name#_} Name end}
      Args     = {Record.arity Spec}
      %
      % If SP is part of the required Modules, then we can install
      % the better error handler, otherwise not.
      %
      InstallErrorHandler =
      case {Member 'SP' Modules} then FixErrorHandler else Dummy end
   in
      fun {$}
         MODULES = {Record.make 'import' Modules}
         ARGS    = {Record.make 'import' Args   }
      in
         {InstallErrorHandler MODULES}
         {ForAll Args proc {$ A} ARGS.A = MODULES.(NSpec.A.1) end}
         {ForAll LoadPlan
          % for each required module
          proc {$ Name#Loader#Args}
             % construct its import interface
             IMPORT = {Record.make 'import' {Record.arity Args}}
          in
             % fill in the interface
             {Record.forAllInd IMPORT
              fun {$ Name} MODULES.(Args.Name) end}
             % obtain module's value using its loader
             MODULES.Name = {Loader IMPORT}
          end}
         % return application's argument modules
         ARGS
      end
   end
   %%
   %% Creation of an executable component
   %%
   fun {RegistryMakeExecProc R CompSpec ArgSpec Functor}
      Loader  = {RegistryGetLoader R CompSpec}
      ArgProc = {MakeArgParser ArgSpec}
   in
      proc {$}
         try {Exit {{Functor {Loader}} {ArgProc}}}
               % provide some error message
         catch E then
            {{{`Builtin` getDefaultExceptionHandler 1}} E}
         finally {Exit 1} end
      end
   end
   %%
   fun  {RegistryMakeCgiProc R CompSpec InterSpec Functor}
      Loader  = {RegistryGetLoader R CompSpec}
      ArgProc = {MakeCgiParser InterSpec}
   in
      proc {$}
         try {Exit {{Functor {Loader}} {ArgProc}}}
               % provide some error message
         catch E then
            {{{`Builtin` getDefaultExceptionHandler 1}} E}
         finally {Exit 1} end
      end
   end
   %%
   proc {RegistryMakeExec R File CompSpec Functor ArgSpec}
      {MakeExec File
       {RegistryMakeExecProc R CompSpec ArgSpec Functor}}
   end
   %%
   proc {RegistryMakeCgi R File CompSpec Functor InterSpec}
      {MakeExec File
       {RegistryMakeCgiProc R CompSpec InterSpec Functor}}
   end
   %%
   %% Return the value that can be obtained by following the
   %% access path L (list of features) into record R
   %%
   fun {LookupPath R L}
      case L of H|T then {LookupPath R.H T}
      [] nil then R end
   end
   %%
   %% Combine two loading modes: simply return the strongest one
   %%   include > eager > lazy > lazyTop
   %%
   ModePriority = x('lazyTop':0 'lazy':1 'eager':2 'include':3)
   fun {ModeCombine Mode1 Mode2}
      case ModePriority.Mode1 < ModePriority.Mode2
      then Mode2 else Mode1 end
   end
   %%
   %% Righteous hack to read a value from a file
   %%
   %% This indicates that Application shouldn't be in OP: it ought
   %% to be instantiated with the Compiler module as import.
   %%
   GetOPICompiler = {`Builtin` 'getOPICompiler' 1}
   fun {ReadFromFile File}
      CC = {GetOPICompiler}
      VS = 'local \\insert '#File#'\n=Registry__Return__Value__ in skip end'
   in
      {CC enqueue(mergeEnv(x('Registry__Return__Value__':_)))}
      {CC enqueue(feedVirtualString(VS))}
      {CC enqueue(getEnv($))}.'Registry__Return__Value__'
   end
   %%
   %% Given the path to file Foo.env, return the LABEL#ARITY of the
   %% interface record written in it
   %%
   fun {GetType EnvFile}
      Env = {ReadFromFile EnvFile}
   in
      {Label Env}#{Arity Env}
   end
   %%
   %% The table of all Oz standard modules.  For simplicity, if M is listed
   %% as a dependency, it is also expected on import feature M.
   %%
   StandardModules =
   oz('SP':             nil
      'OP':             ['SP']
      'AP':             ['SP' 'OP']
      'CP':             ['SP']
      'WP':             ['SP' 'OP']
      'DP':             ['SP' 'OP' 'AP' 'WP']
      'Panel':          ['SP' 'OP' 'WP']
      'Browser':        ['SP' 'WP' 'CP']
      'Explorer':       ['SP' 'WP' 'Browser']
      'Compiler':       ['SP' 'CP']
      'CompilerPanel':  ['SP' 'OP' 'WP' 'Compiler' 'Browser']
      'Emacs':          ['OP' 'SP']
      'Ozcar':          ['SP' 'WP' 'Browser' 'Compiler' 'Emacs']
      'Profiler':       ['SP' 'OP' 'WP' 'Browser' 'Compiler' 'Emacs'])
   %%
   %% we also want to export a useful collection of submodules
   %%
   StandardSubModules =
   oz('SP':             ['System' 'Exit' 'Print' 'Show' 'Foreign'
                         'Debug' 'Error' 'Finalize']
      'OP':             ['OS' 'Open' 'Component' 'Load' 'Save']
      'AP':             ['Application']
      'CP':             ['Search' 'SearchOne' 'SearchAll' 'SearchBest'
                         'FD' 'FS']
      'WP':             ['Tk' 'NewTk' 'TkTools' 'NewTkTools']
      'DP':             ['Site' 'Server' 'NewServer' 'NewAgenda'
                         'LinkToNetscape' 'RunApplets' 'Gate']
      'Panel':          nil
      'Browser':        ['Browse']
      'Explorer':       ['ExploreOne' 'ExploreAll' 'ExploreBest']
      'Compiler':       nil
      'CompilerPanel':  nil
      'Emacs':          nil
      'Ozcar':          nil
      'Profiler':       nil)
   %%
   %% Create a new registry and record in it all the standard modules
   %% and submodules
   %%
   proc {StandardRegistry R}
      {NewEmptyRegistry R}
      {Record.forAllInd StandardModules
       proc {$ Name Args}
          {RegistryRegister R Name
           module(src:system(Name)
                  args:{List.toRecord x
                        {Map Args fun {$ A} A#A end}}
                  type:system(Name))}
       end}
      {Record.forAllInd StandardSubModules
       proc {$ Mod SubMods}
          {ForAll SubMods
           proc {$ SubMod}
              {RegistryRegister R SubMod
               submodule(src:path([1 SubMod]) args:x(Mod))}
           end}
       end}
   end
   fun {MakeDefaultRegistry}
      {StandardRegistry}
   end
   %%
   %% There is a default registry to make things easier and corresponding
   %% default interfaces.
   %%
   DefaultRegistry = {Lazy.new MakeDefaultRegistry}
   proc {DefaultRegister Name Desc}
      {RegistryRegister DefaultRegister Name Desc}
   end
   fun  {DefaultGetPlan   Spec} {RegistryGetPlan   DefaultRegistry Spec} end
   fun  {DefaultGetLoader Spec} {RegistryGetLoader DefaultRegistry Spec} end
   proc {DefaultMakeExec File C F A}
      {RegistryMakeExec DefaultRegistry File C F A}
   end
   proc {DefaultMakeCgi File C F I}
      {RegistryMakeCgi DefaultRegistry File C F I}
   end
   %%
   %% Since the Error module needs to be loaded before it can
   %% provide nice formatting for escaping exceptions, we install
   %% a default exception handler that loads the Error module and
   %% then reinvokes the new improved handler that it provide and
   %% which was installed as a side effect of loading the module.
   %%
   %% Here is the procedure that installs this interim default handler
   %%
   proc {FixErrorHandler EXPORT}
      %% This very smart idea has been taken over from Denys Duchier
      %%        [I am stealing it back! -- Denys]
      {{`Builtin` setDefaultExceptionHandler 1}
       proc {$ E}
          %% cause Error to be instantiated, which installs
          %% a new error handler as a side effect
          {Wait EXPORT.'SP'.'Error'}
          %% invoke this new error handler
          {{{`Builtin` getDefaultExceptionHandler 1}} E}
          %% this whole procedure is invoked at most once
          %% since instantiating base causes the handler
          %% to be replaced with a better one.
       end}
   end
   %%
   proc {Dummy _} skip end
   %%
   %% ArgParser
   %%
   \insert ArgParser.oz
   %%
   %% CgiParser
   %%
   \insert CgiParser.oz
   %%
   proc {MakeExec File ExecProc}
      TmpFile = {OS.tmpnam}
      Script  = {New Open.file
                 init(name:File flags:[create write truncate])}
   in
      try
         {Script write(vs:'#!/bin/sh\n')}
         {Script write(vs:': ${OZHOME='#{System.get home}#'}\n')}
         {Script write(vs:'exec $OZHOME/bin/ozcs $0 "$@"\n')}
         {Script close}
         {Save ExecProc TmpFile o(components: unit
                                  include:    unit
                                  resources:  nil)}
         {OS.system 'cat '#TmpFile#' >> '#File#'; chmod +x '#File _}
      finally
         {OS.unlink TmpFile}
      end
   end
in
   {Error.formatter.put registry RegistryFormatter}
   Application = application(
                             register   :DefaultRegister
                             loader     :DefaultGetLoader
                             plan       :DefaultGetPlan
                             exec       :DefaultMakeExec
                             cgi        :DefaultMakeCgi
                             registry   :registry(new     :MakeDefaultRegistry
                                                  register:RegistryRegister
                                                  loader  :RegistryGetLoader
                                                  plan    :RegistryGetPlan
                                                  exec    :RegistryMakeExec
                                                  cgi     :RegistryMakeCgi)
                            )
end
