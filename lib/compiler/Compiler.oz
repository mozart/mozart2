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

local
   %%
   %% Auxiliary classes
   %%

   class CompilerStateClass
      attr
         defines: nil
         switches: switches(%% global switches:
                            %%
                            compilerpasses: false
                            showinsert: false
                            showcompiletime: false
                            showcompilememory: false
                            echoqueries: false
                            watchdog: true
                            ozma: false

                            %% warnings:
                            %%
                            warnredecl: false
                            warnunused: false
                            warnforward: false

                            %% parsing and expanding:
                            %%
                            expression: false
                            system: true
                            catchall: false
                            selfallowedanywhere: false

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

                            %% debugger support:
                            %%
                            runwithdebugger: false
                            debuginfocontrol: false
                            debuginfovarnames: false)
         savedSwitches: nil
         maxNumberOfErrors: 17

      feat variables values

      meth init(Env)
         self.variables = {NewDictionary}
         self.values = {NewDictionary}
         CompilerStateClass, putEnv(Env)
      end

      meth macroDefine(X) A in
         A = {String.toAtom {VirtualString.toString X}}
         case {Member A @defines} then skip
         else defines <- A|@defines
         end
      end
      meth macroUndef(X) A in
         A = {String.toAtom {VirtualString.toString X}}
         defines <- {Filter @defines fun {$ B} A \= B end}
      end
      meth getDefines($)
         @defines
      end

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
            {@wrapper notify(switch(compilerpasses B))}
            {@wrapper notify(switch(showinsert B))}
         [] debuginfo then
            switches <- {Adjoin @switches switches(runwithdebugger: B
                                                   debuginfocontrol: B
                                                   debuginfovarnames: B)}
            {@wrapper notify(switch(runwithdebugger B))}
            {@wrapper notify(switch(debuginfocontrol B))}
            {@wrapper notify(switch(debuginfovarnames B))}
         elsecase {HasFeature @switches SwitchName} then
            switches <- {AdjoinAt @switches SwitchName B}
            {@wrapper notify(switch(SwitchName B))}
         else
            {@reporter warn(coord: C kind: 'compiler directive warning'
                            msg: 'unknown switch `'#SwitchName#'\'')}
         end
      end
      meth getSwitch(SwitchName $)
         @switches.SwitchName
      end
      meth getMultipleSwitches(Rec) Switches = @switches in
         {Record.forAllInd Rec fun {$ SwitchName} Switches.SwitchName end}
      end
      meth setMultipleSwitches(Rec)
         switches <- {Adjoin @switches Rec}
         {@wrapper notify(switches(@switches))}
      end
      meth showSwitches($)
         '%\n% Current values of switches:\n%\n'#
         {Record.foldRInd @switches
          fun {$ SwitchName B In}
             '\\switch '#case B then '+' else '-' end#SwitchName#'\n'#In
          end '%\n% Number of saved switch states: '#{Length @savedSwitches}#
          '\n%\n'}
      end
      meth pushSwitches()
         savedSwitches <- @switches|@savedSwitches
      end
      meth popSwitches()
         case @savedSwitches of Switches|Rest then
            switches <- Switches
            {@wrapper notify(switches(@switches))}
            savedSwitches <- Rest
         [] nil then skip
         end
      end

      meth setMaxNumberOfErrors(N)
         maxNumberOfErrors <- N
         {@wrapper notify(maxNumberOfErrors(N))}
      end
      meth getMaxNumberOfErrors($)
         @maxNumberOfErrors
      end

      meth enter(V X <= _ NameIt <= true)
         CompilerStateClass, Enter(V X NameIt)
         {@wrapper notify(env(self.values))}
      end
      meth enterMultiple(Vs)
         {ForAll Vs proc {$ V} CompilerStateClass, Enter(V _ true) end}
         {@wrapper notify(env(self.values))}
      end
      meth Enter(V X NameIt) PrintName in
         {V getPrintName(?PrintName)}
         {Dictionary.put self.variables PrintName V}
         {Dictionary.put self.values PrintName X}
         case {IsFree X} andthen NameIt then {NameVariable X PrintName}
         else skip
         end
         {V setUse(multiple)}
         {V setToplevel(true)}
      end
      meth putEnv(Env)
         {Dictionary.removeAll self.variables}
         {Dictionary.removeAll self.values}
         CompilerStateClass, MergeEnv(Env)
         {@wrapper notify(env(self.values))}
      end
      meth mergeEnv(Env)
         CompilerStateClass, MergeEnv(Env)
         {@wrapper notify(env(self.values))}
      end
      meth MergeEnv(Env)
         {Record.forAllInd Env
          proc {$ PrintName Value}
             case {IsPrintName PrintName} then V in
                V = {New Core.variable init(PrintName putEnv unit)}
                CompilerStateClass, Enter(V Value true)
             else
                {@reporter warn(kind: 'warning'
                                msg: ('tried to add variable with '#
                                      'illegal print name to environment'))}
             end
          end}
      end
      meth annotateEnv(Vs ?TheInterface)
         TheInterface = {List.toRecord interface
                         {Map Vs
                          fun {$ V} PrintName Value in
                             {V getPrintName(?PrintName)}
                             Value = {Dictionary.get self.values PrintName}
                             {V valToSubst(Value)}
                             PrintName#{Interface.ofValue Value}
                          end}}
      end
      meth getEnv(?Env)
         Env = {Dictionary.toRecord env self.values}
      end
      meth lookupVariableInEnv(PrintName $)
         {Dictionary.condGet self.variables PrintName undeclared}
      end
      meth lookupInEnv(PrintName $)
         {Dictionary.get self.values PrintName}
      end
      meth removeFromEnv(PrintName)
         {Dictionary.remove self.variables PrintName}
         {Dictionary.remove self.values PrintName}
         {@wrapper notify(env(self.values))}
      end
      meth getVars($)
         {Dictionary.items self.variables}
      end
   end

   class CompilerEngine from CompilerStateClass
      prop final
      attr wrapper reporter ExecutingThread InterruptLock
      meth init(WrapperObject)
         wrapper <- WrapperObject
         CompilerStateClass, init(env('`Builtin`': {`Builtin` 'builtin' 3}
                                      '`Compiler`': WrapperObject))
         reporter <- {New Reporter init(self WrapperObject)}
         ExecutingThread <- unit
         InterruptLock <- {NewLock}
      end
      meth getReporter($)
         @reporter
      end
      meth notifyOne(P)
         {Send P info('Mozart Compiler '#OZVERSION#' of '#DATE#
                      ' playing Oz 3\n\n')}
         {Send P switches(@switches)}
         {Send P maxNumberOfErrors(@maxNumberOfErrors)}
         {Send P env(self.values)}
      end

      meth ping(X)
         {@wrapper notify(pong())}
         X = unit
      end
      meth CatchResult(P)
         try
            {P}
            {@reporter logAccept()}
         catch tooManyErrors then
            {@reporter userInfo('%** Too many errors, aborting compilation\n')}
         [] rejected then
            {@reporter logReject()}
         [] aborted then
            {@reporter logAbort()}
         [] crashed then
            {@reporter logCrash()}
         [] interrupt then
            {@reporter logInterrupt()}
         end
      end

      meth feedFile(FileName Return <= return)
         CompilerEngine,
         CatchResult(proc {$}
                        CompilerEngine, FeedFileSub(FileName Return)
                     end)
      end
      meth FeedFileSub(FileName Return)
         {@reporter userInfo('%%% feeding file '#FileName#'\n')}
         CompilerEngine, Feed(ParseOzFile FileName Return)
      end
      meth feedVirtualString(VS Return <= return)
         CompilerEngine,
         CatchResult(proc {$}
                        case CompilerStateClass, getSwitch(echoqueries $) then
                           {@reporter userInfo(VS)}
                        else
                           {@reporter userInfo('%%% feeding virtual string\n')}
                        end
                        CompilerEngine, Feed(ParseOzVirtualString VS Return)
                     end)
      end
      meth FeedFileWithSwitches(FileName Switches) OldState in
         OldState = {Record.map Switches fun {$ _} _ end}
         CompilerStateClass, getMultipleSwitches(OldState)
         CompilerStateClass, setMultipleSwitches(Switches)
         CompilerEngine, Feed(ParseOzFile FileName return)
         CompilerStateClass, setMultipleSwitches(OldState)
      end
      meth Feed(ParseOz Data Return)
         ExecutingThread <- {Thread.this}
         {@reporter clearErrors()}
         try Queries0 Directives Queries1 Queries in
            {@reporter logPhase('parsing ...')}
            Queries0 = {ParseOz Data @reporter
                        CompilerStateClass, getSwitch(showinsert $)
                        CompilerStateClass, getSwitch(system $)
                        CompilerStateClass, getDefines($)}
            case {@reporter hasSeenError($)} then
               raise rejected end
            else skip
            end
            {GetDirectives Queries0 ?Directives ?Queries1}
            CompilerEngine, FeedSub(Directives return)
            Queries = case CompilerStateClass, getSwitch(ozma $) then
                         {JoinQueries Queries1 @reporter}
                      elsecase CompilerStateClass, getSwitch(expression $) then
                         case Queries1 of nil then Queries1
                         else V in
                            V = {New Core.variable
                                 init('`result`' putEnv unit)}
                            case {HasFeature Return result} then
                               CompilerStateClass, enter(V Return.result false)
                            else
                               CompilerStateClass, enter(V _ false)
                            end
                            {MakeExpressionQuery Queries1}
                         end
                      else
                         Queries1
                      end
            CompilerEngine, FeedSub(Queries Return)
         finally
            ExecutingThread <- unit
         end
      end
      meth FeedSub(Queries Return)
         T = {Thread.this}
      in
         CompilerEngine,
         ExecProtected(proc {$}
                          try
                             Is = {Map Queries
                                   fun {$ Query}
                                      CompilerEngine, CompileQuery(Query $)
                                   end}
                          in
                             case {HasFeature Return requiredInterfaces}
                             then Return.requiredInterfaces = Is
                             else skip
                             end
                          catch tooManyErrors then
                             {Thread.injectException T tooManyErrors}
                          [] rejected then
                             {Thread.injectException T rejected}
                          [] aborted then
                             {Thread.injectException T aborted}
                          [] crashed then
                             {Thread.injectException T crashed}
                          end
                       end true)
         case {@reporter hasSeenError($)} then
            raise rejected end
         else skip
         end
      end
      meth CompileQuery(Query ?RequiredInterface)
         case Query of dirHelp then
            {@reporter
             userInfo('\n'#
                      ' The following compiler directives are supported\n'#
                      ' (you may use abbreviations):\n'#
                      '\n'#
                      '     \\help                display this message\n'#
                      '     \\switch +<switch>    set <switch>\n'#
                      '     \\switch -<switch>    reset <switch>\n'#
                      '     \\showSwitches        show all switch values\n'#
                      '     \\feed <file>         process a file\n'#
                      '     \\core <file>         output in core syntax\n'#
                      '     \\machine <file>      output emulator code\n'#
                      '\n\n')}
         [] dirSwitch(Ss) then
            {ForAll Ss self}
         [] dirShowSwitches then
            {@reporter userInfo(CompilerStateClass, showSwitches($))}
         [] dirPushSwitches then
            CompilerStateClass, pushSwitches()
         [] dirPopSwitches then
            CompilerStateClass, popSwitches()
         [] dirFeed(FileName) then
            CompilerEngine, FeedFileSub(FileName return)
         [] dirThreadedFeed(FileName) then
            CompilerEngine,
            FeedFileWithSwitches(FileName
                                 state(threadedqueries: true))
         [] dirCore(FileName) then
            CompilerEngine,
            FeedFileWithSwitches(FileName
                                 state(core: true
                                       codegen: false))
         [] dirMachine(FileName) then
            CompilerEngine,
            FeedFileWithSwitches(FileName
                                 state(staticanalysis: true
                                       core: false
                                       codegen: true
                                       outputcode: true
                                       feedtoemulator: false))
         else TopLevelGVs GS FreeGVs in
            case Query of fDeclare(_ _ C) then
               {@reporter logDeclare(C)}
            else skip
            end
            {@reporter logPhase('transforming into graph representation ...')}
            {UnnestQuery self @reporter self Query
             ?TopLevelGVs ?GS ?FreeGVs}
            case CompilerStateClass, getSwitch(warnredecl $) then
               {ForAll TopLevelGVs
                proc {$ GV} PrintName = {GV getPrintName($)} in
                   case CompilerStateClass, lookupVariableInEnv(PrintName $)
                   of undeclared then skip
                   elseof PreviousGV then C in
                      {PreviousGV getCoord(?C)}
                      {@reporter
                       warn(kind: 'warning'
                            msg: ('redeclaring top-level variable '#
                                  pn(PrintName))
                            body: case C == unit then
                                     [line('previously declared via putEnv')
                                      {GV getCoord($)}]
                                  else
                                     [{GV getCoord($)} unit
                                      line('previous declaration was here') C]
                                  end)}
                   end
                end}
            else skip
            end
            case {@reporter hasSeenError($)} then
               raise rejected end
            else skip
            end
            case CompilerStateClass, getSwitch(staticanalysis $) then
               {@reporter logPhase('static analysis ...')}
               CompilerStateClass, annotateEnv(FreeGVs ?RequiredInterface)
               {@reporter logSubPhase('determining nonlocal variables ...')}
               {ForAll TopLevelGVs
                proc {$ V}
                   {V setUse(multiple)}
                   {V setToplevel(true)}
                end}
               {ForAll GS proc {$ GS} {GS annotateGlobalVars(nil _ _)} end}
               {@reporter logSubPhase('value propagation ...')}
               case GS of GS|GSr then
                  {GS staticAnalysis(@reporter self GSr)}
               end
            else
               RequiredInterface = {List.toRecord interface
                                    {Map FreeGVs
                                     fun {$ GV} {GV getPrintName($)}#top end}}
            end
            case {@reporter hasSeenError($)} then
               raise rejected end
            else skip
            end
            case CompilerStateClass, getSwitch(warnunused $) then
               {@reporter logPhase('classifying variable occurrences ...')}
               case CompilerStateClass, getSwitch(staticanalysis $) then skip
               else
                  {ForAll CompilerStateClass, getVars($)
                   proc {$ V} {V setUse(multiple)} end}
                  {ForAll TopLevelGVs
                   proc {$ V} {V setUse(multiple)} end}
                  {ForAll GS proc {$ GS} {GS annotateGlobalVars(nil _ _)} end}
               end
               {ForAll GS proc {$ GS} {GS markFirst(@reporter)} end}
            else skip
            end
            case CompilerStateClass, getSwitch(core $) then R1 R2 FS in
               {@reporter logPhase('writing core representation ...')}
               R1 = debug(realcore:
                             CompilerStateClass, getSwitch(realcore $)
                          debugValue:
                             CompilerStateClass, getSwitch(debugvalue $)
                          debugType:
                             CompilerStateClass, getSwitch(debugtype $))
               R2 = {AdjoinAt R1 realcore true}
               FS = case TopLevelGVs of nil then ""
                    else FSs in
                       FSs = {Map TopLevelGVs
                              fun {$ GV} {GV output(R2 $)} end}
                       'declare'#format(glue(" "))#
                       format(list(FSs format(glue(" "))))#format(glue(" "))#
                       'in'#format(break)
                    end#
                    format(list({Map GS fun {$ GS} {GS output(R1 $)} end}
                                format(break)))
               {@reporter displaySource('Oz Compiler: Core Output' '.ozc'
                                        {FormatStringToVirtualString FS}#'\n')}
            else skip
            end
            case CompilerStateClass, getSwitch(codegen $) then
               GPNs Code Assembler
            in
               {@reporter logPhase('generating code ...')}
               case CompilerStateClass, getSwitch(staticanalysis $) then skip
               else
                  {@reporter logSubPhase('determining nonlocal variables ...')}
                  {ForAll TopLevelGVs
                   proc {$ V}
                      {V setUse(multiple)}
                      {V setToplevel(true)}
                   end}
                  {ForAll GS proc {$ GS} {GS annotateGlobalVars(nil _ _)} end}
               end
               {GS.1 startCodeGen(GS self @reporter
                                  CompilerStateClass, getVars($) TopLevelGVs
                                  ?GPNs ?Code)}
               {@reporter logSubPhase('assembling ...')}
               Assembler = {Assemble CompilerStateClass, getSwitch(profile $)
                            Code}
               case CompilerStateClass, getSwitch(ozma $) then
                  case GPNs of nil then File VS in
                     {@reporter logSubPhase('displaying assembler code ...')}
                     {Assembler output(?VS)}
                     {@reporter
                      displaySource('Oz Compiler: Assembler Output' '.ozm' VS)}
                  else
                     {@reporter error(kind: 'Ozma error'
                                      msg: ('No free variables allowed '#
                                            'when compiling for Ozma'))}
                  end
               else
                  case CompilerStateClass, getSwitch(outputcode $) then VS in
                     {@reporter logSubPhase('displaying assembler code ...')}
                     VS = case GPNs of nil then '%% No Global Registers\n'
                          else
                             {List.foldLInd GPNs
                              fun {$ I In PrintName}
                                 In#'%%    g('#I - 1#') = '#
                                 {PrintNameToVirtualString PrintName}#'\n'
                              end '%% Assignment of Global Registers:\n'}
                          end#{Assembler output($)}
                     {@reporter
                      displaySource('Oz Compiler: Assembler Output' '.ozm' VS)}
                  else skip
                  end
                  case CompilerStateClass, getSwitch(feedtoemulator $) then
                     Globals Proc P
                  in
                     {@reporter logSubPhase('loading ...')}
                     proc {Proc}
                        case TopLevelGVs of nil then skip
                        else
                           CompilerStateClass, enterMultiple(TopLevelGVs)
                        end
                        Globals = {Map GPNs
                                   fun {$ PrintName}
                                      CompilerStateClass,
                                      lookupInEnv(PrintName $)
                                   end}
                        {Assembler load(Globals ?P)}
                     end
                     CompilerEngine, ExecuteUninterruptible(Proc)
                     case CompilerStateClass, getSwitch(threadedqueries $) then
                        {@reporter
                         logSubPhase('executing in an independent thread ...')}
                        case {{`Builtin` getOPICompiler 1}} == @wrapper then
                           % this helps Ozcar detect queries from the OPI:
                           {{`Builtin` 'Thread.setId' 2} {Thread.this} 1}
                        else skip
                        end
                        thread {P} end
                     else
                        {@reporter
                         logSubPhase('executing and waiting for '#
                                     'completion ...')}
                        CompilerEngine, ExecProtected(P false)
                     end
                  else skip
                  end
               end
            else skip
            end
         end
      end

      meth interrupt()
         case @ExecutingThread of unit then skip
         elseof T then
            lock @InterruptLock then
               {Thread.injectException T interrupt}
            end
         end
      end
      meth ExecuteUninterruptible(P)
         lock @InterruptLock then {P} end
      end
      meth ExecProtected(P IsCompilerThread)
         % This method executes {P} but protects the current thread
         % against exceptions raised by P.  Furthermore, it sets the
         % raiseOnBlock flag of the thread executing P if it is a
         % compiler thread.
         T Completed Exceptionless RaiseOnBlock
      in
         T = {Thread.this}
         thread
            ExecutingThread <- {Thread.this}
            case IsCompilerThread
               andthen CompilerStateClass, getSwitch(watchdog $)
            then
               {Thread.setRaiseOnBlock {Thread.this} true}
            else skip
            end
            case {{`Builtin` getOPICompiler 1}} == @wrapper then
               % this helps Ozcar detect queries from the OPI:
               {{`Builtin` 'Thread.setId' 2} {Thread.this} 1}
            else skip
            end
            try
               {P}
               Exceptionless = true
            catch interrupt then
               {Thread.injectException T interrupt}
            finally
               ExecutingThread <- T
               Completed = true
            end
         end
         RaiseOnBlock = {Thread.getRaiseOnBlock T}
         {Thread.setRaiseOnBlock T false}
         {Wait Completed}
         {Thread.setRaiseOnBlock T RaiseOnBlock}
         case {IsDet Exceptionless} then skip
         elsecase IsCompilerThread then
            raise crashed end
         else
            raise aborted end
         end
      end
   end
in
   class CompilerClass
      prop final
      attr Registered: nil CurrentQuery: unit QueriesHd QueriesTl NextId: 1
      feat RegistrationLock QueueLock Compiler
      meth init() X in
         self.RegistrationLock = {NewLock}
         self.QueueLock = {NewLock}
         QueriesHd <- X
         QueriesTl <- X
         self.Compiler = {New CompilerEngine init(self)}
         thread
            CompilerClass, RunQueue()
         end
      end

      %%
      %% Managing registration of interfaces
      %%
      %% An interface registers by providing a port onto which
      %% the following notification messages will be sent:
      %%
      %%    newQuery(Id M)
      %%    runQuery(Id M)
      %%    removeQuery(Id)
      %%
      %%    busy()
      %%    idle()
      %%
      %%    switch(SwitchName B)
      %%    switches(Rec)
      %%    maxNumberOfErrors(N)
      %%    env(Env)   %--** is a dictionary, should be a record
      %%
      %%    info(VS Coord <= unit)
      %%    displaySource(TitleVS ExtVS VS)
      %%    toTop()
      %%
      %%    pong()
      %%

      meth register(P)
         lock self.RegistrationLock then
            Registered <- P|@Registered
            {self.Compiler notifyOne(P)}
            lock self.QueueLock then
               case @CurrentQuery of unit then
                  {Send P idle()}
               elseof Id#M then
                  {Send P busy()}
                  {Send P runQuery(Id M)}
               end
               CompilerClass, NotifyQueue(@QueriesHd P)
            end
         end
      end
      meth NotifyQueue(Qs P)
         case {IsDet Qs} then Id#M|Qr = Qs in
            {Send P newQuery(Id M)}
            CompilerClass, NotifyQueue(Qr P)
         else skip
         end
      end
      meth unregister(P)
         lock self.RegistrationLock then
            Registered <- {Filter @Registered fun {$ P0} P0 \= P end}
         end
      end
      meth notify(M)
         lock self.RegistrationLock then
            {ForAll @Registered proc {$ P} {Send P M} end}
         end
      end

      %%
      %% Managing the query queue
      %%
      %% Each query is enqueued into the compilers query queue; the
      %% enqueueing operation immediately returns.  The output variables
      %% of information requesting queries become bound when the query
      %% is actually executed.  In answer to state change requests, a
      %% notification message is broadcast on all registered interface
      %% ports.  Exceptions are raised on the thread that enqueued the
      %% query.
      %%
      %% Each query is assigned a unique identification that is immediately
      %% unified with Id when enqueueing.  This Id may be used to remove a
      %% query from the queue.
      %%

      meth enqueue(M ?Id <= _)
         lock self.QueueLock then NewTl in
            case M of macroDefine(X) then skip
            [] macroUndef(X) then skip
            [] getDefines(?Xs) then skip
            [] getSwitch(SwitchName ?B) then skip
            [] setSwitch(SwitchName B) then skip
            [] pushSwitches() then skip
            [] popSwitches() then skip
            [] getMaxNumberOfErrors(?N) then skip
            [] setMaxNumberOfErrors(N) then skip
            [] addToEnv(PrintName Value) then skip
            [] lookupInEnv(PrintName ?Value) then skip
            [] removeFromEnv(PrintName) then skip
            [] putEnv(Env) then skip
            [] mergeEnv(Env) then skip
            [] getEnv(?Env) then skip
            [] feedVirtualString(VS) then skip
            [] feedVirtualString(VS Return) then skip
            [] feedFile(VS) then skip
            [] feedFile(VS Return) then skip
            [] ping(?HereIAm) then skip
            else
               raise compiler(invalidQuery M) end
            end
            Id = @NextId
            NextId <- Id + 1
            @QueriesTl = Id#M|NewTl
            QueriesTl <- NewTl
            CompilerClass, notify(newQuery(Id M))
         end
      end
      meth interrupt()
         {self.Compiler interrupt()}
      end
      meth dequeue(Id)
         lock self.QueueLock then
            QueriesHd <- CompilerClass, Dequeue(@QueriesHd Id $)
         end
      end
      meth clearQueue()
         lock self.QueueLock then
            CompilerClass, ClearQueue(@QueriesHd)
         end
      end
      meth ClearQueue(Qs)
         case {IsDet Qs} then Id#_|Qr = Qs in
            CompilerClass, notify(removeQuery(Id))
            CompilerClass, ClearQueue(Qr)
         else
            QueriesHd <- Qs
         end
      end
      meth Dequeue(Qs Id ?NewQs)
         case {IsDet Qs} then (Q=Id0#_)|Qr = Qs in
            case Id == Id0 then
               NewQs = Qr
               CompilerClass, notify(removeQuery(Id))
            else NewQr in
               NewQs = Q|NewQr
               CompilerClass, Dequeue(Qr Id ?NewQr)
            end
         else
            % make sure that no race conditions occur, since the
            % queue is processed concurrently
            NewQs = Qs
         end
      end

      meth RunQueue()
         case {IsFree @QueriesHd} then
            CompilerClass, notify(idle())
            {Wait @QueriesHd}
            CompilerClass, notify(busy())
         else skip
         end
         try
            lock self.QueueLock then Qs in
               Qs = @QueriesHd
               case {IsDet Qs} then Id#M|Qr = Qs in
                  QueriesHd <- Qr
                  raise query(Id M) end   % unlock the QueueLock
               else skip
               end
            end
         catch query(Id M) then
            lock self.QueueLock then
               CompilerClass, notify(runQuery(Id M))
               CurrentQuery <- Id#M
            end
            try
               {self.Compiler M}
            catch failure(...) then Reporter in
               {self.Compiler getReporter(?Reporter)}
               {Reporter error(kind: 'error'
                               msg: 'execution of query raised failure'
                               body: [hint(l: 'Query' m: oz(M))])}
               {Reporter logReject()}
            end
            lock self.QueueLock then
               CurrentQuery <- unit
               CompilerClass, notify(removeQuery(Id))
            end
         end
         CompilerClass, RunQueue()
      end
   end
end
