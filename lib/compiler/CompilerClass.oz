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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   %%
   %% Auxiliary classes
   %%

   fun {EnumerateVersionNumbers S Prefix} S1 Rest S2 in
      {List.takeDropWhile S fun {$ C} C \= &_ end ?S1 ?Rest}
      S2 = {Append Prefix S1}
      {String.toAtom S2}|
      case Rest of _|R then {EnumerateVersionNumbers R {Append S2 "_"}}
      [] nil then nil
      end
   end

   DefaultDefines = {EnumerateVersionNumbers
                     {Map {Atom.toString {Property.get 'oz.version'}}
                      fun {$ C}
                         case C of &. then &_ else C end
                      end} "Mozart_"}

   DefaultSwitches = switches(%% global switches:
                              %%
                              compilerpasses: false
                              showinsert: false
                              echoqueries: true
                              showdeclares: true
                              watchdog: true
                              recordhoist: true

                              %% warnings:
                              %%
                              warnredecl: false
                              warnshadow: false
                              warnunused: true
                              warnunusedformals: false
                              warnforward: false
                              warnopt: false

                              %% parsing and expanding:
                              %%
                              unnest: true
                              expression: false
                              allowdeprecated: true

                              %% gump:
                              gump: false
                              gumpscannerbestfit: false
                              gumpscannercaseless: false
                              gumpscannernowarn: false
                              gumpscannerbackup: false
                              gumpscannerperfreport: false
                              gumpscannerstatistics: false
                              gumpparseroutputsimplified: false
                              gumpparserverbose: false

                              %% static analysis:
                              %%
                              staticanalysis: true

                              %% outputting code in core syntax:
                              %%
                              core: false
                              realcore: false
                              debugvalue: false
                              debugtype: false

                              %% code generation:
                              %%
                              codegen: true
                              outputcode: false

                              %% feeding to the emulator:
                              %%
                              feedtoemulator: true
                              threadedqueries: true
                              profile: false

                              %% debugging support:
                              %%
                              runwithdebugger: false
                              controlflowinfo: false
                              staticvarnames: false
                              dynamicvarnames: false)

   DefaultOptions = options(maxNumberOfErrors: 17
                            baseURL: unit
                            gumpDirectory: unit)

   InterruptException = {NewName}

   fun {NormalizeCoord Coord}
      case Coord of unit then Coord
      else pos(Coord.1 Coord.2 Coord.3)
      end
   end

   class CompilerStateClass
      prop final
      attr
         defines: unit
         switches: DefaultSwitches
         options: DefaultOptions
         savedSwitches: nil
         localSwitches: unit
         productionTemplates: unit

         ParseFile: ParseOzFile
         ParseVirtualString: ParseOzVirtualString

         ExecutingThread: unit InterruptLock

         narrator reporter

      feat variables values

      meth init(NarratorObject ReporterObject)
         defines <- {NewDictionary}
         {ForAll DefaultDefines
          proc {$ D} {Dictionary.put @defines D true} end}
         InterruptLock <- {NewLock}
         narrator <- NarratorObject
         reporter <- ReporterObject
         self.variables = {NewDictionary}
         self.values = {NewDictionary}
         CompilerStateClass, putEnv({Record.subtract Base 'OoExtensions'})
      end

      %%
      %% Defines
      %%

      meth macroDefine(X)
         {Dictionary.put @defines {VirtualString.toAtom X} true}
      end
      meth macroUndef(X)
         {Dictionary.remove @defines {VirtualString.toAtom X}}
      end
      meth getDefines($)
         {Dictionary.keys @defines}
      end

      %%
      %% Switches
      %%

      meth on(SwitchName C)
         CompilerStateClass, setSwitch(SwitchName true C)
      end
      meth off(SwitchName C)
         CompilerStateClass, setSwitch(SwitchName false C)
      end
      meth setSwitch(SwitchName B C <= unit)
         case SwitchName of verbose then
            switches <- {Adjoin @switches switches(compilerpasses: B
                                                   showinsert: B)}
            {@narrator tell(switch(compilerpasses B))}
            {@reporter setLogPhases(B)}
            {@narrator tell(switch(showinsert B))}
         [] debuginfo then
            switches <- {Adjoin @switches switches(runwithdebugger: B
                                                   controlflowinfo: B
                                                   staticvarnames: B)}
            {@narrator tell(switch(runwithdebugger B))}
            {@narrator tell(switch(controlflowinfo B))}
            {@narrator tell(switch(staticvarnames B))}
         else
            if {HasFeature @switches SwitchName} then
               switches <- {AdjoinAt @switches SwitchName B}
               {@narrator tell(switch(SwitchName B))}
               if SwitchName == compilerpasses then
                  {@reporter setLogPhases(B)}
               end
            elseif C == unit then
               {@reporter error(coord: C kind: 'compiler engine error'
                                msg: 'unknown switch `'#SwitchName#'\''
                                items: [hint(l: 'Query'
                                             m: oz(setSwitch(SwitchName B)))])}
               {@reporter endBatch(rejected)}
            else
               {@reporter error(coord: C kind: 'compiler directive error'
                                msg: 'unknown switch `'#SwitchName#'\'')}
            end
         end
      end
      meth getSwitch(SwitchName $)
         @switches.SwitchName
      end
      meth localSwitches()
         case @localSwitches of unit then
            localSwitches <- @switches|@savedSwitches
         else skip
         end
      end
      meth unlocalSwitches()
         case @localSwitches of unit then skip
         [] X|Xr then
            switches <- X
            savedSwitches <- Xr
            localSwitches <- unit
         end
      end
      meth pushSwitches()
         savedSwitches <- @switches|@savedSwitches
      end
      meth popSwitches()
         case @savedSwitches of Switches|Rest then
            switches <- Switches
            {@narrator tell(switches(@switches))}
            savedSwitches <- Rest
         [] nil then skip
         end
      end

      %%
      %% Options
      %%

      meth setMaxNumberOfErrors(N)
         options <- {AdjoinAt @options maxNumberOfErrors N}
         {@narrator tell(maxNumberOfErrors(N))}
         {@reporter setMaxNumberOfErrors(N)}
      end
      meth getMaxNumberOfErrors($)
         @options.maxNumberOfErrors
      end
      meth setBaseURL(X) A in
         A = case X of unit then X
             else {VirtualString.toAtom X}
             end
         options <- {AdjoinAt @options baseURL A}
         {@narrator tell(baseURL(A))}
      end
      meth getBaseURL($)
         @options.baseURL
      end
      meth setGumpDirectory(X)
         options <- {AdjoinAt @options gumpDirectory X}
         {@narrator tell(gumpDirectory(X))}
      end
      meth getGumpDirectory($)
         @options.gumpDirectory
      end

      %%
      %% Environment
      %%

      meth enter(V X <= _ NameIt <= true)
         CompilerStateClass, Enter(V X NameIt)
         {@narrator tell(env({Dictionary.toRecord env self.values}))}
      end
      meth enterMultiple(Vs)
         {ForAll Vs proc {$ V} CompilerStateClass, Enter(V _ true) end}
         {@narrator tell(env({Dictionary.toRecord env self.values}))}
      end
      meth Enter(V X NameIt) PrintName in
         {V getPrintName(?PrintName)}
         {Dictionary.put self.variables PrintName V}
         {Dictionary.put self.values PrintName X}
         if {Not {IsDet X}} andthen NameIt then
            {CompilerSupport.nameVariable X PrintName}
         end
         {V setUse(multiple)}
         {V setToplevel(true)}
      end
      meth putEnv(Env)
         {Dictionary.removeAll self.variables}
         {Dictionary.removeAll self.values}
         CompilerStateClass, MergeEnv(Env)
         {@narrator tell(env({Dictionary.toRecord env self.values}))}
      end
      meth mergeEnv(Env)
         CompilerStateClass, MergeEnv(Env)
         {@narrator tell(env({Dictionary.toRecord env self.values}))}
      end
      meth MergeEnv(Env)
         {Record.forAllInd Env
          proc {$ PrintName Value} V in
             V = {New Core.userVariable init(PrintName unit)}
             CompilerStateClass, Enter(V Value true)
          end}
      end
      meth annotateEnv(Vs)
         {ForAll Vs
          proc {$ V} PrintName Value in
             {V getPrintName(?PrintName)}
             Value = {Dictionary.get self.values PrintName}
             {V valToSubst(Value)}
          end}
      end
      meth getEnv(?Env)
         Env = {Dictionary.toRecord env self.values}
      end
      meth lookupVariableInEnv(PrintName $)
         {Dictionary.condGet self.variables PrintName undeclared}
      end
      meth lookupInEnv(PrintName ?X)=M
         if {Dictionary.member self.values PrintName} then
            X = {Dictionary.get self.values PrintName}
         else
            {@reporter error(kind: 'compiler engine error'
                             msg: 'undeclared variable '#pn(PrintName)
                             items: [hint(l: 'Query' m: oz(M))])}
         end
      end
      meth removeFromEnv(PrintName)
         if {Dictionary.member self.variables PrintName} then
            {Dictionary.remove self.variables PrintName}
            {Dictionary.remove self.values PrintName}
            {@narrator tell(env({Dictionary.toRecord env self.values}))}
         else
            {@reporter error(kind: 'compiler engine error'
                             msg: 'undeclared variable '#pn(PrintName))}
         end
      end
      meth getVars($)
         {Dictionary.items self.variables}
      end

\ifndef NO_GUMP
      meth addProductionTemplates(Ps)
         CompilerStateClass, InitProductionTemplates()
         {@productionTemplates add(Ps @reporter)}
      end
      meth getProductionTemplates($)
         CompilerStateClass, InitProductionTemplates()
         {@productionTemplates get($)}
      end
      meth InitProductionTemplates()
         case @productionTemplates of unit then
            productionTemplates <- {Gump.makeProductionTemplates}
            {@productionTemplates add(ProductionTemplates.default @reporter)}
         else skip
         end
      end
\endif

      %%
      %% Queries
      %%

      meth getReporter($)
         @reporter
      end
      meth newListener(P)
         OZVERSION = {Property.get 'oz.version'}
         OZDATE    = {Property.get 'oz.date'}
      in
         {Send P info('Mozart Compiler '#OZVERSION#' ('#OZDATE#')'#
                      ' playing Oz 3\n\n')}
         {Send P switches(@switches)}
         {Send P maxNumberOfErrors(@options.maxNumberOfErrors)}
         {Send P baseURL(@options.baseURL)}
         {Send P gumpDirectory(@options.gumpDirectory)}
         {Send P env({Dictionary.toRecord env self.values})}
      end

      meth ping(X Y <= unit)
         {@narrator tell(pong(Y))}
         X = unit
      end

      meth setFrontEnd(PF PVS)
         ParseFile <- PF
         ParseVirtualString <- PVS
      end
      meth feedFile(FileName Return <= return)
         CompilerStateClass,
         CatchResult(proc {$}
                        {@reporter
                         tell(info('%%% feeding file '#FileName#'\n'))}
                        CompilerStateClass, Feed(@ParseFile FileName Return)
                     end)
      end
      meth feedVirtualString(VS Return <= return)
         CompilerStateClass,
         CatchResult(proc {$}
                        if CompilerStateClass, getSwitch(echoqueries $) then
                           {@reporter tell(info(VS))}
                        else
                           {@reporter
                            tell(info('%%% feeding virtual string\n'))}
                        end
                        CompilerStateClass, Feed(@ParseVirtualString VS Return)
                     end)
      end
      meth CatchResult(P)
         try
            {P}
            {@reporter endBatch(accepted)}
         catch tooManyErrors then
            {@reporter
             tell(info('%** Too many errors, aborting compilation\n'))}
            {@reporter endBatch(rejected)}
         [] rejected then
            {@reporter endBatch(rejected)}
         [] aborted then
            {@reporter endBatch(aborted)}
         [] crashed then
            {@reporter endBatch(crashed)}
         [] !InterruptException then
            {@reporter endBatch(interrupted)}
         end
      end
      meth Feed(ParseProc Data Return)
         ExecutingThread <- {Thread.this}
         {@reporter startBatch()}
         try DoParse Queries in
            proc {DoParse}
               Queries = {ParseProc Data @reporter
                          fun {$ S} CompilerStateClass, getSwitch(S $) end
                          @defines}
            end
            if ParseProc == ParseOzFile
               orelse ParseProc == ParseOzVirtualString
            then
               {@reporter startPhase('parsing')}
               {DoParse}
            else
               {@reporter startPhase('acquiring syntax tree')}
               CompilerStateClass, ExecProtected(DoParse false)
               {@reporter startSubPhase('checking syntax tree for validity')}
               CompilerStateClass,
               ExecProtected(proc {$} {CheckTupleSyntax Queries} end true)
            end
            if {@reporter hasSeenError($)} orelse Queries == parseError then
               raise rejected end
            end
            if CompilerStateClass, getSwitch(unnest $) then
               if CompilerStateClass, getSwitch(expression $) then
                  case Queries of nil then
                     {@reporter error(kind: 'compiler directive error'
                                      msg: 'file contains no expression')}
                     raise rejected end
                  else V in
                     V = {New Core.userVariable
                          init('`result`' unit)}
                     CompilerStateClass,
                     enter(V {CondSelect Return result _} false)
                     case {Unnester.makeExpressionQuery Queries}
                     of _#false then
                        {@reporter error(kind: 'compiler directive error'
                                         msg: 'file contains no expression')}
                        raise rejected end
                     elseof NewQueries#_ then
                        CompilerStateClass, FeedSub(NewQueries Return)
                     end
                  end
               else
                  CompilerStateClass, FeedSub(Queries Return)
               end
            end
         finally
            ExecutingThread <- unit
         end
      end
      meth FeedSub(Queries Return)
         T = {Thread.this}
      in
         CompilerStateClass,
         ExecProtected(proc {$}
                          try
                             {ForAll Queries
                              proc {$ Query}
                                 CompilerStateClass, CompileQuery(Query)
                              end}
                          catch tooManyErrors then
                             {Thread.injectException T tooManyErrors}
                          [] rejected then
                             {Thread.injectException T rejected}
                          [] aborted then
                             {Thread.injectException T aborted}
                          [] crashed then
                             {Thread.injectException T crashed}
                          finally
                             CompilerStateClass, unlocalSwitches()
                          end
                       end true)
         if {@reporter hasSeenError($)} then
            raise rejected end
         end
      end
      meth CompileQuery(Query)
         case Query of dirSwitch(Ss) then
            {ForAll Ss self}
         [] dirLocalSwitches then
            CompilerStateClass, localSwitches()
         [] dirPushSwitches then
            CompilerStateClass, pushSwitches()
         [] dirPopSwitches then
            CompilerStateClass, popSwitches()
         [] fSynTopLevelProductionTemplates(Ps) then
\ifdef NO_GUMP
            {@reporter error(kind: 'compiler restriction'
                             msg: 'Gump definitions not supported')}
\else
            CompilerStateClass, addProductionTemplates(Ps)
\endif
         else DeclaredGVs GS FreeGVs AnnotateGlobalVars in
            case Query of fDeclare(_ _ C) then
               if CompilerStateClass, getSwitch(compilerpasses $) then
                  NewCoord = {NormalizeCoord C}
               in
                  case NewCoord of pos(_ _ _) then VS in
                     VS = {Error.extendedVSToVS NewCoord}
                     {@reporter tell(info('%%% processing query in '#
                                          VS#' ...\n' NewCoord))}
                  else
                     {@reporter tell(info('%%% processing query ...\n'))}
                  end
               end
            else skip
            end
            {@reporter startPhase('transforming into graph representation')}
            {Unnester.unnestQuery self @reporter self Query
             ?DeclaredGVs ?GS ?FreeGVs}
            local Done in
               proc {AnnotateGlobalVars}
                  if {IsFree Done} then
                     {@reporter
                      startSubPhase('determining nonlocal variables')}
                     {ForAll GS
                      proc {$ GS} {GS annotateGlobalVars(nil _ _)} end}
                     Done = unit
                  end
               end
            end
            if {@reporter hasSeenError($)} then
               raise rejected end
            end
            if CompilerStateClass, getSwitch(staticanalysis $) then
               {@reporter startPhase('static analysis')}
               CompilerStateClass, annotateEnv(FreeGVs)
               {AnnotateGlobalVars}
               {@reporter startSubPhase('value propagation')}
               case GS of GS|GSr then
                  {GS staticAnalysis(@reporter self GSr)}
               end
            end
            if {@reporter hasSeenError($)} then
               raise rejected end
            end
            if CompilerStateClass, getSwitch(warnunused $) then W in
               {@reporter startPhase('classifying variable occurrences')}
               {AnnotateGlobalVars}
               CompilerStateClass, getSwitch(warnunusedformals ?W)
               {ForAll GS proc {$ GS} {GS markFirst(W @reporter)} end}
            end
            if CompilerStateClass, getSwitch(showdeclares $)
               andthen DeclaredGVs \= nil
            then
               {@reporter tell(info('Declared variables:\n'))}
               {ForAll {Sort DeclaredGVs
                        fun {$ V W}
                           {V getPrintName($)} < {W getPrintName($)}
                        end}
                proc {$ V}
                   {@reporter tell(info('  '#{FormatStringToVirtualString
                                              pn({V getPrintName($)})}#': '#
                                        {V outputDebugType($)}#'\n'))}
                end}
            end
            if CompilerStateClass, getSwitch(core $) then FS in
               {@reporter startPhase('writing core representation')}
               FS = {Core.output DeclaredGVs GS self}
               {@reporter
                tell(displaySource('Oz Compiler: Core Output' '.ozi'
                                   {FormatStringToVirtualString FS}#'\n'))}
            end
            if CompilerStateClass, getSwitch(codegen $) then
               GPNs Code MyAssembler
            in
               {@reporter startPhase('generating code')}
               {AnnotateGlobalVars}
               {GS.1 startCodeGen(GS self @reporter
                                  CompilerStateClass, getVars($) DeclaredGVs
                                  ?GPNs ?Code)}
               {@reporter startSubPhase('assembling')}
               MyAssembler = {Assembler.internalAssemble Code
                              switches(profile:
                                          (CompilerStateClass,
                                           getSwitch(profile $))
                                       controlflowinfo:
                                          (CompilerStateClass,
                                           getSwitch(controlflowinfo $))
                                       verify: false
                                       peephole: true)}
               if CompilerStateClass, getSwitch(outputcode $) then VS in
                  {@reporter startSubPhase('displaying assembler code')}
                  VS = case GPNs of nil then '%% No Global Registers\n'
                       else
                          {List.foldLInd GPNs
                           fun {$ I In PrintName}
                              In#'%%    g('#I - 1#') = '#
                              {FormatStringToVirtualString pn(PrintName)}#'\n'
                           end '%% Assignment of Global Registers:\n'}
                       end#{MyAssembler output($)}
                  {@reporter
                   tell(displaySource('Oz Compiler: Assembler Output'
                                      '.ozm' VS))}
               end
               if CompilerStateClass, getSwitch(feedtoemulator $) then
                  Globals Proc P0 P
               in
                  {@reporter startSubPhase('loading')}
                  proc {Proc}
                     case DeclaredGVs of nil then skip
                     else
                        CompilerStateClass, enterMultiple(DeclaredGVs)
                     end
                     Globals = {Map GPNs
                                fun {$ PrintName}
                                   CompilerStateClass,
                                   lookupInEnv(PrintName $)
                                end}
                     {MyAssembler load(Globals ?P0)}
                  end
                  CompilerStateClass, ExecuteUninterruptible(Proc)
                  if CompilerStateClass, getSwitch(runwithdebugger $) then
                     proc {P} {Debug.breakpoint} {P0} end
                  else
                     P = P0
                  end
                  local
                     OPI = {Property.condGet 'opi.compiler' false}
                  in
                     if OPI \= false
                        andthen {OPI getNarrator($)} == @narrator
                     then
                        %% this helps Ozcar detect queries from the OPI:
                        {Debug.setId {Thread.this} 1}
                     end
                  end
                  if CompilerStateClass, getSwitch(threadedqueries $) then
                     {@reporter
                      startSubPhase('executing in an independent thread')}
                     thread {P} end
                  else
                     {@reporter
                      startSubPhase('executing and waiting for completion')}
                     CompilerStateClass, ExecProtected(P false)
                  end
               end
            end
         end
      end

      meth interrupt()
         case @ExecutingThread of unit then skip
         elseof T then
            lock @InterruptLock then
               {Thread.injectException T InterruptException}
            end
         end
      end
      meth ExecuteUninterruptible(P)
         lock @InterruptLock then {P} end
      end
      meth ExecProtected(P IsCompilerThread)
         %% This method executes {P} but protects the current thread
         %% against exceptions raised by P.  Furthermore, it sets the
         %% raiseOnBlock flag of the thread executing P if it is a
         %% compiler thread.
         T Completed Exceptionless RaiseOnBlock
      in
         T = {Thread.this}
         thread
            ExecutingThread <- {Thread.this}
            if IsCompilerThread
               andthen CompilerStateClass, getSwitch(watchdog $)
            then
               {Debug.setRaiseOnBlock {Thread.this} true}
            end
            try
               {P}
               Exceptionless = true
            catch !InterruptException then
               {Thread.injectException T InterruptException}
            [] E then
               {Error.printException E}
               raise E end
            finally
               ExecutingThread <- T
               Completed = true
            end
         end
         RaiseOnBlock = {Debug.getRaiseOnBlock T}
         {Debug.setRaiseOnBlock T false}
         {Wait Completed}
         {Debug.setRaiseOnBlock T RaiseOnBlock}
         if {IsFree Exceptionless} then
            raise if IsCompilerThread then crashed else aborted end end
         end
      end
   end

   proc {TypeCheck P M I A}
      if {P M.I} then skip
      else {Exception.raiseError compiler(invalidQuery M I A)}
      end
   end

   fun {IsVirtualStringOrUnit X}
      {IsUnit X} orelse {IsVirtualString X}
   end

   fun {IsEnv X}
      {IsRecord X} andthen {All {Arity X} PrintName.is}
   end

   fun {IsProcedure5 X}
      {IsProcedure X} andthen {Procedure.arity X} == 5
   end
in
   class Engine from Narrator.'class'
      prop final
      attr Registered: nil CurrentQuery: unit QueriesHd QueriesTl NextId: 1
      feat QueueLock Compiler
      meth init() PrivateNarrator X in
         Narrator.'class', init(?PrivateNarrator)
         self.QueueLock = {NewLock}
         QueriesHd <- X
         QueriesTl <- X
         self.Compiler = {New CompilerStateClass init(self PrivateNarrator)}
         thread
            Engine, RunQueue()
         end
      end

      %%
      %% Managing registration of interfaces
      %%

      meth newListener(P)
         {self.Compiler newListener(P)}
         lock self.QueueLock then
            case @CurrentQuery of unit then
               {Send P idle()}
            elseof Id#M then
               {Send P busy()}
               {Send P runQuery(Id M)}
            end
            Engine, TellQueue(@QueriesHd P)
         end
      end
      meth TellQueue(Qs P)
         if {IsDet Qs} then Id#M|Qr = Qs in
            {Send P newQuery(Id M)}
            Engine, TellQueue(Qr P)
         end
      end

      %%
      %% Managing the query queue
      %%

      meth enqueue(Ms ?Ids <= _)
         case Ms of _|Mr then
            if {IsList Mr} then skip
            else {Exception.raiseError compiler(invalidQuery Ms)}
            end
            lock self.QueueLock then
               Ids = {Map Ms fun {$ M} Engine, Enqueue(M $) end}
            end
         [] nil then
            Ids = nil
         else
            Engine, Enqueue(Ms ?Ids)
         end
      end
      meth Enqueue(M ?Id)
         lock self.QueueLock then NewTl in
            case M of macroDefine(_) then
               {TypeCheck IsVirtualString M 1 'virtual string'}
            [] macroUndef(_) then
               {TypeCheck IsVirtualString M 1 'virtual string'}
            [] getDefines(_) then skip
            [] getSwitch(_ _) then
               {TypeCheck IsAtom M 1 'atom'}
            [] setSwitch(_ _) then
               {TypeCheck IsAtom M 1 'atom'}
               {TypeCheck IsBool M 2 'bool'}
            [] pushSwitches() then skip
            [] popSwitches() then skip
            [] setMaxNumberOfErrors(_) then
               {TypeCheck IsInt M 1 'int'}
            [] getMaxNumberOfErrors(_) then skip
            [] setBaseURL(_) then
               {TypeCheck IsVirtualStringOrUnit M 1 'virtual string or unit'}
            [] getBaseURL(_) then skip
            [] setGumpDirectory(_) then
               {TypeCheck IsVirtualStringOrUnit M 1 'virtual string or unit'}
            [] getGumpDirectory(_) then skip
            [] addToEnv(_ _) then
               {TypeCheck PrintName.is M 1 'print name'}
            [] lookupInEnv(_ _) then
               {TypeCheck PrintName.is M 1 'print name'}
            [] removeFromEnv(_) then
               {TypeCheck PrintName.is M 1 'print name'}
            [] putEnv(_) then
               {TypeCheck IsEnv M 1 'environment'}
            [] mergeEnv(_) then
               {TypeCheck IsEnv M 1 'environment'}
            [] getEnv(_) then skip
            [] setFrontEnd(_ _) then
               {TypeCheck IsProcedure5 M 1 'procedure/5'}
               {TypeCheck IsProcedure5 M 2 'procedure/5'}
            [] feedVirtualString(_) then
               {TypeCheck IsVirtualString M 1 'virtual string'}
            [] feedVirtualString(_ _) then
               {TypeCheck IsVirtualString M 1 'virtual string'}
               {TypeCheck IsRecord M 2 'record'}
            [] feedFile(_) then
               {TypeCheck IsVirtualString M 1 'virtual string'}
            [] feedFile(_ _) then
               {TypeCheck IsVirtualString M 1 'virtual string'}
               {TypeCheck IsRecord M 2 'record'}
            [] ping(_) then skip
            [] ping(_ _) then skip
            else
               {Exception.raiseError compiler(invalidQuery M)}
            end
            Id = @NextId
            NextId <- Id + 1
            @QueriesTl = Id#M|NewTl
            QueriesTl <- NewTl
            Narrator.'class', tell(newQuery(Id M))
         end
      end
      meth interrupt()
         {self.Compiler interrupt()}
      end
      meth dequeue(Id)
         lock self.QueueLock then
            QueriesHd <- Engine, Dequeue(@QueriesHd Id $)
         end
      end
      meth clearQueue()
         lock self.QueueLock then
            Engine, ClearQueue(@QueriesHd)
         end
      end
      meth ClearQueue(Qs)
         if {IsDet Qs} then Id#_|Qr = Qs in
            Narrator.'class', tell(removeQuery(Id))
            Engine, ClearQueue(Qr)
         else
            QueriesHd <- Qs
         end
      end
      meth Dequeue(Qs Id ?NewQs)
         if {IsDet Qs} then (Q=Id0#_)|Qr = Qs in
            if Id == Id0 then
               NewQs = Qr
               Narrator.'class', tell(removeQuery(Id))
            else NewQr in
               NewQs = Q|NewQr
               Engine, Dequeue(Qr Id ?NewQr)
            end
         else
            %% make sure that no race conditions occur, since the
            %% queue is processed concurrently
            NewQs = Qs
         end
      end

      meth RunQueue()
         if {IsFree @QueriesHd} then
            Narrator.'class', tell(idle())
            {Wait @QueriesHd}
            Narrator.'class', tell(busy())
         end
         try
            lock self.QueueLock then Qs in
               Qs = @QueriesHd
               if {IsDet Qs} then Id#M|Qr = Qs in
                  QueriesHd <- Qr
                  raise query(Id M) end   % unlock the QueueLock
               end
            end
         catch query(Id M) then
            lock self.QueueLock then
               Narrator.'class', tell(runQuery(Id M))
               CurrentQuery <- Id#M
            end
            try
               {self.Compiler M}
            catch E then Reporter in
               {self.Compiler getReporter(?Reporter)}
               {Reporter error(kind: 'compiler engine error'
                               msg: ('execution of query raised an exception '#
                                     '-- description follows')
                               items: [hint(l: 'Query' m: oz(M))])}
               Narrator.'class', tell(message({AdjoinAt
                                               {Error.exceptionToMessage E}
                                               footer false} unit))
               {Reporter endBatch(rejected)}
            end
            lock self.QueueLock then
               CurrentQuery <- unit
               Narrator.'class', tell(removeQuery(Id))
            end
         end
         Engine, RunQueue()
      end
   end
end
