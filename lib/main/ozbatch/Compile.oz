%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998
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

local
   UsageError = 'command line option error'
   BatchCompilationError = 'batch compilation error'

   DefaultExecHeader = '#!/bin/sh\nexec ozengine $0 "$@"\n'

   OptSpecs = record(%% mode in which to run
                     mode(single
                          type: atom(help core outputcode
                                     feedtoemulator dump executable)
                          default: feedtoemulator)
                     help(char: [&h &?] alias: mode#help)
                     core(char: &E alias: mode#core)
                     outputcode(char: &S alias: mode#outputcode)
                     feedtoemulator(char: &e alias: mode#feedtoemulator)
                     dump(char: &c alias: mode#dump)
                     executable(char: &x alias: mode#executable)

                     %% options valid in all modes
                     verbose(rightmost char: &v type: bool default: auto)
                     quiet(rightmost char: &q alias: verbose#false)
                     makedepend(rightmost char: &M default: false)

                     %% options for individual modes
                     outputfile(single char: &o type: string default: unit)
                     execheader(single type: string default: DefaultExecHeader)
                     compress(rightmost char: &z
                              type: int(min: 0 max: 9) default: 0)

                     %%
                     %% between all of the following, order is important
                     %%

                     %% preparing the compiler state
                     'define'(char: &D type: list(atom))
                     undefine(char: &U type: list(atom))
                     environment(char: &l type: list(string))
                     incdir(char: &I type: string)
                     include(type: string)

                     %% compiler switches
                     maxerrors(type: int)
                     compilerpasses(type: bool)
                     showinsert(type: bool)
                     echoqueries(type: bool)
                     showdeclares(type: bool)
                     showcompiletime(type: bool)
                     showcompilememory(type: bool)
                     watchdog(type: bool)
                     warnredecl(type: bool)
                     warnunused(type: bool)
                     warnforward(type: bool)
                     warnopt(type: bool)
                     expression(type: bool)
                     allowdeprecated(type: bool)
                     gump(type: bool)
                     staticanalysis(type: bool)
                     realcore(type: bool)
                     debugvalue(type: bool)
                     debugtype(type: bool)
                     profile(char: &p type: bool)
                     debuginfocontrol(type: bool)
                     debuginfovarnames(type: bool)
                     debuginfo(char: &g
                               alias: [debuginfocontrol#true
                                       debuginfovarnames#true]))

   Usage =
   'You have to choose one of the following modes of operation:\n'#
   '-h, -?, --help                Output usage information and exit.\n'#
   '-E, --core                    Transform a statement into core language\n'#
   '                              (file extension: .ozi).\n'#
   '-S, --outputcode              Compile a statement to assembly code\n'#
   '                              (file extension: .ozm).\n'#
   '-e, --feedtoemulator          Compile and execute a statement.\n'#
   '                              This is the default mode.\n'#
   '-c, --dump                    Compile and evaluate an expression,\n'#
   '                              pickling the result\n'#
   '                              (file extension: .ozf).\n'#
   '-x, --executable              Compile and evaluate an expression,\n'#
   '                              making result executable\n'#
   '                              (file extension: none).\n'#
   '\n'#
   'Additionally, you may specify the following options:\n'#
   '-v, --verbose                 Display all compiler messages.\n'#
   '-q, --quiet                   Inhibit compiler messages\n'#
   '                              unless an error is encountered.\n'#
   '-M, --makedepend              Instead of executing, write a list\n'#
   '                              of dependencies to stdout.\n'#
   '-o FILE, --outputfile=FILE    Write output to FILE (`-\' for stdout).\n'#
   '--execheader=STR              Use header STR for executables (default:\n'#
   '                              "#!/bin/sh\\nexec ozengine $0 "$@"\\n").\n'#
   '-z N, --compress=N            Use compression level N for pickles.\n'#
   '-D NAME, --define=NAME        Define macro name NAME.\n'#
   '-U NAME, --undefine=NAME      Undefine macro name NAME.\n'#
   '-l FNCS, --environment=FNCS   Make functors FNCS (a comma-separated\n'#
   '                              pair list VAR=URL) available in the\n'#
   '                              environment.\n'#
   '-I DIR, --incdir=DIR          Add DIR to the head of OZPATH.\n'#
   '--include=FILE                Compile and execute the statement in FILE\n'#
   '                              before processing the remaining options.\n'#
   '\n'#
   'The following compiler switches have the described effects when set:\n'#
   %% Note that the remaining options are not documented here on purpose.
   '--maxerrors=N                 Limit the number of errors reported to N.\n'#
   '--(no)compilerpasses          Show compiler passes.\n'#
   '--(no)warnredecl              Warn about top-level redeclarations.\n'#
   '--(no)warnunused              Warn about unused variables.\n'#
   '--(no)warnunusedformals       Warn about unused variables and formals.\n'#
   '--(no)warnforward             Warn about oo forward declarations.\n'#
   '--(no)warnopt                 Warn about missed optimizations.\n'#
   '--(no)expression              Expect expressions, not statements.\n'#
   '--(no)allowdeprecated         Allow use of deprecated syntax.\n'#
   '--(no)gump                    Allow Gump definitions.\n'#
   '--(no)staticanalysis          Run static analysis.\n'#
   '--(no)realcore                Output the real non-fancy core syntax.\n'#
   '--(no)debugvalue              Annotate variable values in core output.\n'#
   '--(no)debugtype               Annotate variable types in core output.\n'#
   '-p, --(no)profile             Include profiling information.\n'#
   '--(no)debuginfocontrol        Include control flow information.\n'#
   '--(no)debuginfovarnames       Include variable information.\n'#
   '-g, --(no)debuginfo           Both of the above.\n'
in
   functor
   import
      Module
      Property(get)
      System(printInfo printError)
      Error(msg formatLine printExc)
      OS(putEnv getEnv system)
      Open(file)
      Pickle(saveWithHeader)
      Compiler(engine quietInterface)
      Application(getCmdArgs exit)
   define
      local
         fun {IsIDChar C}
            {Char.isAlNum C} orelse C == &_
         end

         fun {IsQuotedVariable S}
            case S of C1|Cr then
               if C1 == &` andthen Cr == nil then true
               elseif C1 == 0 then false
               else {IsQuotedVariable Cr}
               end
            [] nil then false
            end
         end

         fun {IsPrintName X}
            {IsAtom X} andthen
            local
               S = {Atom.toString X}
            in
               case S of C|Cr then
                  case C of &` then
                     {IsQuotedVariable Cr}
                  else
                     {Char.isUpper C} andthen {All Cr IsIDChar}
                  end
               [] nil then false
               end
            end
         end

         ModMan = {New Module.manager init()}
      in
         proc {IncludeFunctor S Compiler} Var URL VarAtom Export in
            {String.token S &= ?Var ?URL}
            VarAtom = {String.toAtom Var}
            Export = case URL of nil then {ModMan link(name: Var $)}
                     else {ModMan link(url: URL $)}
                     end
            if {IsPrintName VarAtom} then
               {Compiler enqueue(mergeEnv(env(VarAtom: Export)))}
            else
               {Report
                error(kind: UsageError
                      msg: 'illegal variable identifier `'#Var#'\' specified'
                      items: [hint(l: 'Hint'
                                   m: ('Use --help to obtain '#
                                       'usage information'))])}
            end
            {Compiler enqueue(mergeEnv({Record.filterInd Export
                                        fun {$ P _} {IsPrintName P} end}))}
         end
      end

      fun {ChangeExtension X NewExt}
         case X of ".oz" then NewExt
         elsecase X of C|Cr then
            C|{ChangeExtension Cr NewExt}
         [] nil then NewExt
         end
      end

      proc {Report E}
         {Error.msg
          proc {$ X}
             {System.printError {Error.formatLine X}}
          end E}
         raise error end
      end
   in
      try OptRec BatchCompiler UI IncDir FileNames in
         try
            OptRec = {Application.getCmdArgs OptSpecs}
         catch error(ap(usage VS) ...) then
            {Report error(kind: UsageError
                          msg: VS
                          items: [hint(l: 'Hint'
                                       m: ('Use --help to obtain '#
                                           'usage information'))])}
         end
         case OptRec.mode of help then X in
            X = {Property.get 'root.url'}
            {System.printInfo 'Usage: '#X#' { [option] | [file] }\n'#Usage}
            raise success end
         else skip
         end
         BatchCompiler = {New Compiler.engine init()}
         UI = {New Compiler.quietInterface init(BatchCompiler OptRec.verbose)}
         {BatchCompiler enqueue(setSwitch(showdeclares false))}
         {BatchCompiler enqueue(setSwitch(warnunused true))}
         {BatchCompiler enqueue(setSwitch(threadedqueries false))}
         IncDir = {NewCell nil}
         FileNames =
         {Filter OptRec.1
          fun {$ Y}
             case Y of Opt#X then
                case Opt of 'define' then
                   {ForAll X
                    proc {$ D} {BatchCompiler enqueue(macroDefine(D))} end}
                [] undefine then
                   {ForAll X
                    proc {$ D} {BatchCompiler enqueue(macroUndef(D))} end}
                [] environment then
                   {ForAll X proc {$ S} {IncludeFunctor S BatchCompiler} end}
                [] incdir then
                   {Assign IncDir X|{Access IncDir}}
                [] include then Id in
                   {BatchCompiler enqueue(pushSwitches())}
                   {BatchCompiler enqueue(setSwitch(feedtoemulator true))}
                   {BatchCompiler enqueue(feedFile(X return) ?Id)}
                   {BatchCompiler enqueue(popSwitches())}
                   {UI wait(Id)}
                   if {UI hasErrors($)} then
                      raise error end
                   end
                [] maxerrors then
                   {BatchCompiler enqueue(setMaxNumberOfErrors(X))}
                elseof SwitchName then
                   {BatchCompiler enqueue(setSwitch(SwitchName X))}
                end
                false
             else
                true
             end
          end}
         {OS.putEnv 'OZPATH'
          {FoldL {Access IncDir}
           fun {$ In S} {Append S &:|In} end
           case {OS.getEnv 'OZPATH'} of false then "."
           elseof S then S
           end}}
         if FileNames == nil then
            {Report error(kind: UsageError
                          msg: 'no input files given'
                          items: [hint(l: 'Hint'
                                       m: ('Use --help to obtain '#
                                           'usage information'))])}
         elseif OptRec.outputfile \= "-"
            andthen OptRec.outputfile \= unit
            andthen {Length FileNames} > 1
         then
            {Report error(kind: UsageError
                          msg: ('only one input file allowed when '#
                                'an output file name is given'))}
         else
            {ForAll FileNames
             proc {$ Arg} OFN R Id in
                {UI reset()}
                case OptRec.outputfile of unit then
                   case OptRec.mode of core then
                      OFN = {ChangeExtension Arg ".ozi"}
                   [] outputcode then
                      OFN = {ChangeExtension Arg ".ozm"}
                   [] feedtoemulator then
                      if OptRec.makedepend then
                         {Report
                          error(kind: UsageError
                                msg: ('--makedepend with --feedtoemulator '#
                                      'needs an --outputfile'))}
                      end
                      OFN = unit
                   [] dump then
                      OFN = {ChangeExtension Arg ".ozf"}
                   [] executable then
                      OFN = {ChangeExtension Arg ""}
                   end
                elseof "-" then
                   if OptRec.mode == dump orelse OptRec.mode == executable
                   then
                      {Report
                       error(kind: UsageError
                             msg: 'dumping to stdout is not possible')}
                   else
                      OFN = stdout
                   end
                elseif OptRec.mode == feedtoemulator
                   andthen {Not OptRec.makedepend}
                then
                   {Report
                    error(kind: UsageError
                          msg: ('no output file name must be '#
                                'specified for --feedtoemulator'))}
                else
                   OFN = OptRec.outputfile
                end
                {BatchCompiler enqueue(pushSwitches())}
                if OptRec.makedepend then
                   {BatchCompiler enqueue(setSwitch(unnest false))}
                end
                case OptRec.mode of core then
                   {BatchCompiler enqueue(setSwitch(core true))}
                   {BatchCompiler enqueue(setSwitch(codegen false))}
                [] outputcode then
                   {BatchCompiler enqueue(setSwitch(outputcode true))}
                   {BatchCompiler
                    enqueue(setSwitch(feedtoemulator false))}
                [] feedtoemulator then
                   {BatchCompiler
                    enqueue(setSwitch(feedtoemulator true))}
                else   % dump, executable
                   {BatchCompiler enqueue(setSwitch(expression true))}
                   {BatchCompiler
                    enqueue(setSwitch(feedtoemulator true))}
                end
                {BatchCompiler
                 enqueue(feedFile(Arg return(result: ?R)) ?Id)}
                {BatchCompiler enqueue(popSwitches())}
                {UI wait(Id)}
                if {UI hasErrors($)} then
                   raise error end
                end
                if OptRec.makedepend then File VS in
                   File = {New Open.file init(name: stdout flags: [write])}
                   VS = (OFN#':'#
                         case {UI getInsertedFiles($)} of Ns=_|_ then
                            {FoldL {UI getInsertedFiles($)}
                             fun {$ In X} In#' \\\n\t'#X end ""}
                         [] nil then ""
                         end#'\n')
                   {File write(vs: VS)}
                   {File close()}
                else
                   case OptRec.mode of dump then
                      try
                         {Pickle.saveWithHeader R OFN '' OptRec.compress}
                      catch E then
                         {Error.printExc E}
                         raise error end
                      end
                   [] executable then
                      if {Functor.is R} then skip
                      else
                         {Report
                          error(kind: BatchCompilationError
                                msg: 'only functors can be made executable'
                                items: [hint(l: 'Value found'
                                             m: oz(R))])}
                      end
                      try
                         {Pickle.saveWithHeader
                          R % Value
                          OFN % Filename
                          OptRec.execheader % Header
                          OptRec.compress % Compression level
                         }
                         case {OS.system 'chmod +x '#OFN}
                         of 0 then skip elseof N then
                            {Report
                             error(kind: BatchCompilationError
                                   msg: 'writing executable functor failed'
                                   items: [hint(l: 'Error code' m: N)])}
                         end
                      catch E then
                         {Error.printExc E}
                         raise error end
                      end
                   [] feedtoemulator then skip
                   else File in   % core, outputcode
                      File = {New Open.file
                              init(name: OFN
                                   flags: [write create truncate])}
                      {File write(vs: {UI getSource($)})}
                      {File close()}
                   end
                end
             end}
         end
         raise success end
      catch error then
         {Application.exit 1}
      [] success then
         {Application.exit 0}
      end
   end
end
