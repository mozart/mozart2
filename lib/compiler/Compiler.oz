%%%  Programming Systems Lab, Universitaet des Saarlandes,
%%%  Postfach 15 11 50, D-66041 Saarbruecken, Phone (+49) 681 302-5609
%%%  Author: Leif Kornstaedt <kornstae@ps.uni-sb.de>

local
   %%
   %% Auxiliary classes
   %%

   class Switches
      prop final
      attr state: state(%% global switches:
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

      feat MyReporter
      meth init(Reporter)
         self.MyReporter = Reporter
      end
      meth on(S C) State = @state in
         case S of verbose then
            state <- {Adjoin State state(compilerpasses: true
                                         showinsert: true)}
         [] debuginfo then
            state <- {Adjoin State state(runwithdebugger: true
                                         debuginfocontrol: true
                                         debuginfovarnames: true)}
         elsecase {CondSelect State S unknown} \= unknown then
            state <- {AdjoinAt State S true}
         else
            {self.MyReporter warn(coord: C kind: 'compiler directive warning'
                                  msg: 'unknown switch `'#S#'\'')}
         end
      end
      meth off(S C) State = @state in
         case S of verbose then
            state <- {Adjoin State state(compilerpasses: false
                                         showinsert: false)}
         [] debuginfo then
            state <- {Adjoin State state(runwithdebugger: false
                                         debuginfocontrol: false
                                         debuginfovarnames: false)}
         elsecase {CondSelect State S unknown} \= unknown then
            state <- {AdjoinAt State S false}
         else
            {self.MyReporter warn(coord: C kind: 'compiler directive warning'
                                  msg: 'unknown switch `'#S#'\'')}
         end
      end
      meth get(S $)
         @state.S
      end
      meth getMultiple(Rec) State = @state in
         {Record.forAllInd Rec proc {$ Switch X} X = State.Switch end}
      end
      meth setMultiple(Rec)
         state <- {Adjoin @state Rec}
      end
      meth show($)
         '\n Current values of switches:\n\n'#
         {Record.foldRInd @state
          fun {$ Switch Value In}
             '     '#case Value then '+' else '-' end#Switch#'\n'#In
          end '\n\n'}
      end
   end

   class TopLevelClass
      prop final
      feat variables values
      meth init()
         self.variables = {NewDictionary}
         self.values = {NewDictionary}
      end
      meth putEnv(Env)
         {ForAll {Dictionary.keys self.variables}
          proc {$ PrintName}
             {Dictionary.remove self.variables PrintName}
             {Dictionary.remove self.values PrintName}
          end}
         TopLevelClass, mergeEnv(Env)
      end
      meth mergeEnv(Env)
         {Record.forAllInd Env
          proc {$ PrintName Value} V in
             case {IsPrintName PrintName} then
                V = {New Core.variable init(PrintName putEnv unit)}
                TopLevelClass, enter(V Value)
             else skip   %--** issue a warning about this?
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
      meth getEnv($)
         {List.toRecord env {Dictionary.entries self.values}}
      end
      meth enter(V X <= _) PrintName = {V getPrintName($)} in
         {Dictionary.put self.variables PrintName V}
         {Dictionary.put self.values PrintName X}
         case {IsDet X} then skip
         else {NameVariable X PrintName}
         end
         {V setUse(multiple)}
         {V setToplevel(true)}
      end
      meth lookup(PrintName $)
         {Dictionary.condGet self.variables PrintName undeclared}
      end
      meth getValueOf(PrintName $)
         {Dictionary.get self.values PrintName}
      end
      meth undeclare(PrintName)
         {Dictionary.remove self.variables PrintName}
         {Dictionary.remove self.values PrintName}
      end
      meth getVars($)
         {Dictionary.items self.variables}
      end
   end

   BaseEnv = env('`Builtin`': {`Builtin` 'builtin' 3})
in
   %%
   %% The CompilerClass does not do any locking.  This is due to the
   %% fact that it is intended to be driven by an interface frontend,
   %% which is supposed to ensure the necessary locking.
   %%

   class CompilerClass from Unnester
      prop final
      feat interface
      attr switches reporter TopLevel ExecutingThread InterruptLock
      meth init(Interface <= _)
         MyReporter N
         CompilerEnv = env('NewCompiler': NewCompiler
                           '`Compiler`': Interface)
      in
         self.interface = Interface
         switches <- {New Switches init(MyReporter)}
         MyReporter = {New Reporter init(@switches Interface)}
         reporter <- MyReporter
         TopLevel <- {New TopLevelClass init()}
         ExecutingThread <- unit
         InterruptLock <- {NewLock}
         {Interface ShowInfo('PS Oz Compiler '#OZVERSION#' of '#DATE#'\n\n')}
         CompilerClass, putEnv(BaseEnv)
         CompilerClass, mergeEnv(CompilerEnv)
         Unnester, init(@TopLevel)
         {Interface SetSwitches(@switches)}
         {@reporter getMaxNumberOfErrors(?N)}
         {Interface SetMaxNumberOfErrors(N)}
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
      meth setSwitch(S)
         {@switches S}
      end
      meth getSwitches($)
         @switches
      end
      meth setMaxNumberOfErrors(N)
         {@reporter setMaxNumberOfErrors(N)}
      end
      meth feedFile(FileName ?RequiredInterfaces)
         {@reporter userInfo('%%% feeding file '#FileName#'\n')}
         CompilerClass, Feed(ParseOzFile FileName ?RequiredInterfaces)
      end
      meth feedVirtualString(VS ?RequiredInterfaces)
         case {@switches get(echoqueries $)} then
            {@reporter userInfo(VS)}
         else
            {@reporter userInfo('%%% feeding virtual string\n')}
         end
         CompilerClass, Feed(ParseOzVirtualString VS ?RequiredInterfaces)
      end
      meth putEnv(Env)
         {@TopLevel putEnv(Env)}
         {self.interface DisplayEnv(@TopLevel.values)}
         {@reporter userInfo('%%% installed new environment\n')}
      end
      meth mergeEnv(Env)
         {@TopLevel mergeEnv(Env)}
         {self.interface DisplayEnv(@TopLevel.values)}
         {@reporter userInfo('%%% added new bindings to environment\n')}
      end
      meth getEnv($)
         {@TopLevel getEnv($)}
      end
      meth isDeclared(PrintName $)
         {@TopLevel lookup(PrintName $)} \= undeclared
      end
      meth undeclare(PrintName)
         {@TopLevel undeclare(PrintName)}
         {self.interface DisplayEnv(@TopLevel.values)}
         {@reporter userInfo('%%% removed binding from environment\n')}
      end

      meth Feed(ParseOz Data ?RequiredInterfaces)
         {@reporter clearErrors()}
         ExecutingThread <- {Thread.this}
         try Queries0 Queries T in
            {@reporter logPhase('parsing ...')}
            Queries0 = {ParseOz Data @reporter
                        {@switches get(showinsert $)}
                        {@switches get(system $)}}
            case {@reporter hasSeenError($)} then
               raise rejected end
            else skip
            end
            case {@switches get(ozma $)} then
               Unnester, joinQueries(Queries0 ?Queries)
            else
               Queries = Queries0
            end
            T = {Thread.this}
            CompilerClass,
            ExecProtected(proc {$}
                             try
                                {Map Queries
                                 fun {$ Query}
                                    CompilerClass, CompileQuery(Query $)
                                 end ?RequiredInterfaces}
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
         finally
            ExecutingThread <- unit
         end
      end
      meth CompileQuery(Query ?RequiredInterface)
         case Query of dirHalt then OPICompiler in
            OPICompiler = {{`Builtin` getOPICompiler 1}}
            case OPICompiler == self.interface then ShutDownV in
               {@reporter logHalt()}
               ShutDownV = {@TopLevel lookup('`ShutDown`' $)}
               case ShutDownV \= undeclared then ShutDown in
                  ShutDown = {@TopLevel getValueOf('`ShutDown`' $)}
                  case {IsDet ShutDown}
                     andthen ({IsProcedure ShutDown}
                              andthen {Procedure.arity ShutDown} == 1)
                     orelse {IsObject ShutDown}
                  then
                     {ShutDown exit()}
                  else
                     {Exit 0}
                  end
               else
                  {Exit 0}
               end
            elsecase {IsObject OPICompiler} then
               {OPICompiler feedVirtualString('\\halt')}
            else
               {Exit 0}
            end
         [] dirHelp then
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
            {ForAll Ss @switches}
            {self.interface SetSwitches(@switches)}
         [] dirShowSwitches then
            {@reporter userInfo({@switches show($)})}
         [] dirFeed(FileName) then
            CompilerClass, feedFile(FileName _)
         [] dirThreadedFeed(FileName) then
            CompilerClass, FeedFileWithSwitches(FileName
                                                state(threadedqueries: true))
         [] dirCore(FileName) then
            CompilerClass, FeedFileWithSwitches(FileName
                                                state(core: true
                                                      codegen: false))
         [] dirMachine(FileName) then
            CompilerClass, FeedFileWithSwitches(FileName
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
            Unnester, unnestQuery(Query ?TopLevelGVs ?GS ?FreeGVs)
            case {@switches get(warnredecl $)} then
               {ForAll TopLevelGVs
                proc {$ GV} PrintName = {GV getPrintName($)} in
                   case {@TopLevel lookup(PrintName $)} of undeclared then skip
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
            case {@switches get(staticanalysis $)} then
               {@reporter logPhase('static analysis ...')}
               {@TopLevel annotateEnv(FreeGVs ?RequiredInterface)}
               {@reporter logSubPhase('determining nonlocal variables ...')}
               {ForAll TopLevelGVs
                proc {$ V}
                   {V setUse(multiple)}
                   {V setToplevel(true)}
                end}
               {ForAll GS proc {$ GS} {GS annotateGlobalVars(nil _ _)} end}
               {@reporter logSubPhase('value propagation ...')}
               case GS of GS|GSr then
                  {GS staticAnalysis(@reporter @switches GSr)}
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
            case {@switches get(warnunused $)} then
               {@reporter logPhase('classifying variable occurrences ...')}
               case {@switches get(staticanalysis $)} then skip
               else
                  {ForAll {@TopLevel getVars($)}
                   proc {$ V} {V setUse(multiple)} end}
                  {ForAll TopLevelGVs
                   proc {$ V} {V setUse(multiple)} end}
                  {ForAll GS proc {$ GS} {GS annotateGlobalVars(nil _ _)} end}
               end
               {ForAll GS proc {$ GS} {GS markFirst(@reporter)} end}
            else skip
            end
            case {@switches get(core $)} then R1 R2 FS in
               {@reporter logPhase('writing core representation ...')}
               R1 = debug(realcore: {@switches get(realcore $)}
                          debugValue: {@switches get(debugvalue $)}
                          debugType: {@switches get(debugtype $)})
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
            case {@switches get(codegen $)} then GPNs Code Assembler in
               {@reporter logPhase('generating code ...')}
               case {@switches get(staticanalysis $)} then skip
               else
                  {@reporter logSubPhase('determining nonlocal variables ...')}
                  {ForAll TopLevelGVs
                   proc {$ V}
                      {V setUse(multiple)}
                      {V setToplevel(true)}
                   end}
                  {ForAll GS proc {$ GS} {GS annotateGlobalVars(nil _ _)} end}
               end
               {GS.1 startCodeGen(GS @switches @reporter
                                  {@TopLevel getVars($)} TopLevelGVs
                                  ?GPNs ?Code)}
               {@reporter logSubPhase('assembling ...')}
               Assembler = {Assemble {@switches get(profile $)} Code}
               case {@switches get(ozma $)} then
                  case GPNs of nil then File VS in
                     {@reporter logSubPhase('saving assembler code ...')}
                     {Assembler output(?VS)}
                     File = {New Open.file
                             init(name: '/tmp/output.ozm'
                                  flags: [write create truncate])}
                     {File write(vs: VS)}
                     {File close()}
                  else
                     {@reporter error(kind: 'Ozma error'
                                      msg: ('No free variables allowed '#
                                            'when compiling for Ozma'))}
                  end
               else
                  case {@switches get(outputcode $)} then VS in
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
                  case {@switches get(feedtoemulator $)} then Globals Proc P in
                     {@reporter logSubPhase('loading ...')}
                     proc {Proc}
                        case TopLevelGVs of nil then skip
                        else
                           {ForAll TopLevelGVs
                            proc {$ GV} {@TopLevel enter(GV)} end}
                           {self.interface DisplayEnv(@TopLevel.values)}
                        end
                        Globals = {Map GPNs
                                   fun {$ PrintName}
                                      {@TopLevel getValueOf(PrintName $)}
                                   end}
                        {Assembler load(Globals ?P)}
                     end
                     CompilerClass, ExecuteUninterruptible(Proc)
                     case {@switches get(threadedqueries $)} then
                        {@reporter
                         logSubPhase('executing in an independent thread ...')}
                        thread {P} end
                     else
                        {@reporter
                         logSubPhase('executing and waiting for '#
                                     'completion ...')}
                        CompilerClass, ExecProtected(P false)
                     end
                  else skip
                  end
               end
            else skip
            end
         end
      end
      meth FeedFileWithSwitches(FileName Switches) OldState in
         OldState = {Record.map Switches fun {$ _} _ end}
         {@switches getMultiple(OldState)}
         {@switches setMultiple(Switches)}
         CompilerClass, Feed(ParseOzFile FileName _)
         {@switches setMultiple(OldState)}
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
            case IsCompilerThread andthen {@switches get(watchdog $)} then
               {Thread.setRaiseOnBlock {Thread.this} true}
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
         elsecase {self.interface AskAbort($)} then
            raise aborted end
         else skip
         end
      end
   end
end
