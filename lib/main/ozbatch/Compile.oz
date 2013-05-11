%%%
%%% Author:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Leif Kornstaedt, 1998-2001
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

functor
import
   Module
   Property(get put)
   System(printInfo printError)
   Error(messageToVirtualString)
   OS(putEnv getEnv system)
   Open(file)
   Pickle(saveWithHeader)
   Compiler(engine interface)
   Application(getArgs exit)
prepare
   UsageError = 'command line option error'
   BatchCompilationError = 'batch compilation error'

   OptSpecs = record(%% mode in which to run
                     mode(single
                          type: atom(help core scode ecode execute
                                     dump executable)
                          default: execute)
                     help(char: [&h &?] alias: mode#help)
                     core(char: &E alias: mode#core)
                     scode(char: &S alias: mode#scode)
                     ecode(char: &s alias: mode#ecode)
                     execute(char: &e alias: mode#execute)
                     dump(char: &c alias: mode#dump)
                     executable(char: &x alias: mode#executable)

                     %% options valid in all modes
                     verbose(rightmost char: &v type: bool default: auto)
                     quiet(rightmost char: &q alias: verbose#false)
                     makedepend(rightmost char: &M default: false)

                     %% options for individual modes
                     outputfile(single char: &o type: string default: unit)
                     target(rightmost type: atom(unix windows) default: unit)
                     unix(alias: target#unix)
                     windows(alias: target#windows)
                     execheader(single type: string
                                validate:
                                   alt(when(disj(execpath execfile execwrapper)
                                            false)))
                     execpath(single type: string
                              validate:
                                 alt(when(disj(execheader execfile execwrapper)
                                          false)))
                     execfile(single type: string
                              validate:
                                 alt(when(disj(execheader execpath execwrapper)
                                          false)))
                     execwrapper(single type: string
                                 validate:
                                    alt(when(disj(execheader execpath execfile)
                                             false)))
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
                     compilerpasses(type: bool)
                     showinsert(type: bool)
                     echoqueries(type: bool)
                     showdeclares(type: bool)
                     watchdog(type: bool)
                     warnredecl(type: bool)
                     warnshadow(type: bool)
                     warnunused(type: bool)
                     warnunusedformals(type: bool)
                     warnforward(type: bool)
                     warnopt(type: bool)
                     expression(type: bool)
                     allowdeprecated(type: bool)
                     gump(type: bool)
                     gumpscannerbestfit(type: bool)
                     gumpscannercaseless(type: bool)
                     gumpscannernowarn(type: bool)
                     gumpscannerbackup(type: bool)
                     gumpscannerperfreport(type: bool)
                     gumpscannerstatistics(type: bool)
                     gumpparseroutputsimplified(type: bool)
                     gumpparserverbose(type: bool)
                     staticanalysis(type: bool)
                     realcore(type: bool)
                     debugvalue(type: bool)
                     debugtype(type: bool)
                     recordhoist(type: bool)
                     profile(char: &p type: bool)
                     controlflowinfo(type: bool)
                     staticvarnames(type: bool)
                     debuginfo(char: &g
                               alias: [controlflowinfo#true
                                       staticvarnames#true])
                     dynamicvarnames(type: bool)

                     %% compiler options
                     maxerrors(type: int)
                     baseurl(char: &b type: string)
                     gumpdirectory(single type: string default: unit))

   Usage =
   'You have to choose one of the following modes of operation:\n'#
   '-h, -?, --help                Output usage information and exit.\n'#
   '-e, --execute, --mode=execute Compile and execute a statement.\n'#
   '                              This is the default mode.\n'#
   '-c, --dump, --mode=dump       Compile and evaluate an expression,\n'#
   '                              pickling the result\n'#
   '                              (file extension: .ozf).\n'#
   '-x, --executable, --mode=executable\n'#
   '                              Compile and evaluate an expression,\n'#
   '                              making result executable\n'#
   '                              (file extension: none).\n'#
   '-E, --core, --mode=core       Compile a statement to core language\n'#
   '                              (file extension: .ozi).\n'#
   '-S, --scode, --mode=scode     Compile a statement to assembly code\n'#
   '                              (file extension: .ozm).\n'#
   '-s, --ecode, --mode=ecode     Compile an expression to assembly code\n'#
   '                              (file extension: .ozm).\n'#
   '\n'#
   'Additionally, you may specify the following options:\n'#
   '-v, --verbose                 Display all compiler messages.\n'#
   '-q, --quiet                   Inhibit compiler messages\n'#
   '                              unless an error is encountered.\n'#
   '-M, --makedepend              Instead of executing, write a list\n'#
   '                              of dependencies to stdout.\n'#
   '-o FILE, --outputfile=FILE    Write output to FILE (`-\' for stdout).\n'#
   '--execheader=STR              Use header STR for executables\n'#
   '                              (Unix default:\n'#
   '                               "#!/bin/sh\\nexec ozengine $0 "$@"\\n").\n'#
   '--execpath=STR                Use above header, with ozengine\n'#
   '                              replaced by STR.\n'#
   '--execfile=FILE               Use contents of FILE as header\n'#
   '                              (Windows default:\n'#
   '                               <ozhome>/bin/ozwrapper.bin).\n'#
   '--execwrapper=FILE            Use above header, with ozwrapper.bin\n'#
   '                              replaced by STR.\n'#
   '--target=(unix|windows)       when creating an executable functor, do\n'#
   '                              it for this platform (default current).\n'#
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
   '--(no)compilerpasses          Show compiler passes.\n'#
   '--(no)warnredecl              Warn about top-level redeclarations.\n'#
   '--(no)warnshadow              Warn about all redeclarations.\n'#
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
   '--(no)controlflowinfo         Include control flow information.\n'#
   '--(no)staticvarnames          Include static variable name information.\n'#
   '-g, --(no)debuginfo           The two switches above.\n'#
   '--(no)dynamicvarnames         Dynamically assign variable names.\n'#
   '\n'#
   'The following compiler options can be set:\n'#
   '--maxerrors=N                 Limit the number of errors reported to N.\n'#
   '--baseurl=STRING              Set the base URL to resolve imports of\n'#
   '                              computed functors to STRING.\n'#
   '--gumpdirectory=STRING        Set the directory where Gump will create\n'#
   '                              its output files to STRING.\n'
define
   Platform = {Property.get 'platform.os'}

   fun {MakeExecHeader Path}
      '#!/bin/sh\nexec '#Path#' "$0" "$@"\n'
   end
   fun {MakeExecFile File}
      {Property.get 'oz.home'}#'/bin/'#File
   end

   DefaultExecWindows = file({MakeExecFile 'ozwrapper.bin'})
   DefaultExecUnix = string({MakeExecHeader 'ozengine'})

   DefaultExec = case Platform of win32 then DefaultExecWindows
                 else DefaultExecUnix
                 end

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

   local
      fun {NotIsDirSep C}
         C \= &/ andthen (Platform \= win32 orelse C \= &\\)
      end

      fun {ChangeExtensionSub S NewExt}
         case S of ".oz" then NewExt
         elseof ".ozg" then NewExt
         elseof C|Cr then
            C|{ChangeExtensionSub Cr NewExt}
         [] nil then NewExt
         end
      end
   in
      fun {ChangeExtension S NewExt}
         {ChangeExtensionSub
          {Reverse {List.takeWhile {Reverse S} NotIsDirSep}} NewExt}
      end

      fun {Dirname S}
         case S of stdout then unit
         else {Reverse {List.dropWhile {Reverse S} NotIsDirSep}}
         end
      end
   end

   proc {ReadFile File ?VS} F in
      F = {New Open.file init(name: File flags: [read])}
      {F read(list: ?VS size: all)}
      {F close()}
   end

   proc {Report E}
      {System.printError {Error.messageToVirtualString E}}
      raise error end
   end
in
   try OptRec BatchCompiler UI IncDir FileNames in
      try
         OptRec = {Application.getArgs OptSpecs}
      catch error(ap(usage VS) ...) then
         {Report error(kind: UsageError
                       msg: VS
                       items: [hint(l: 'Hint'
                                    m: ('Use --help to obtain '#
                                        'usage information'))])}
      end
      case OptRec.mode of help then X in
         X = {Property.get 'application.url'}
         {System.printInfo 'Usage: '#X#' { [option] | [file] }\n'#Usage}
         raise success end
      else skip
      end
      BatchCompiler = {New Compiler.engine init()}
      UI = {New Compiler.interface init(BatchCompiler OptRec.verbose)}
      {BatchCompiler enqueue(setSwitch(showdeclares false))}
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
             [] include then
                {BatchCompiler enqueue(pushSwitches())}
                {BatchCompiler enqueue(setSwitch(feedtoemulator true))}
                {BatchCompiler enqueue(feedFile(X return))}
                {BatchCompiler enqueue(popSwitches())}
                {UI sync()}
                if {UI hasErrors($)} then
                   raise error end
                end
             [] maxerrors then
                {BatchCompiler enqueue(setMaxNumberOfErrors(X))}
             [] baseurl then
                {BatchCompiler enqueue(setBaseURL(X))}
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
        fun {$ In S}
           {Append S case Platform of win32 then &; else &: end|In}
        end
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
          proc {$ Arg} OFN GumpDir R in
             {UI reset()}
             case OptRec.outputfile of unit then
                case OptRec.mode of core then
                   OFN = {ChangeExtension Arg ".ozi"}
                [] scode then
                   OFN = {ChangeExtension Arg ".ozm"}
                [] ecode then
                   OFN = {ChangeExtension Arg ".ozm"}
                [] execute then
                   if OptRec.makedepend then
                      {Report
                       error(kind: UsageError
                             msg: ('--makedepend with --execute '#
                                   'needs an --outputfile'))}
                   end
                   OFN = unit
                [] dump then
                   OFN = {ChangeExtension Arg ".ozf"}
                [] executable then ExeExt in
                   ExeExt = case OptRec.target of unix then ""
                            [] windows then ".exe"
                            elsecase Platform of win32 then ".exe"
                            else ""
                            end
                   OFN = {ChangeExtension Arg ExeExt}
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
             else
                if OptRec.mode == execute andthen {Not OptRec.makedepend} then
                   {Report
                    error(kind: UsageError
                          msg: ('no output file name must be '#
                                'specified for --execute'))}
                else
                   OFN = OptRec.outputfile
                end
             end
             GumpDir = case OptRec.gumpdirectory of unit then
                          case OFN of unit then unit
                          elsecase {Dirname OFN} of "" then unit
                          elseof Dir then Dir
                          end
                       elseof Dir then Dir
                       end
             {BatchCompiler enqueue(setGumpDirectory(GumpDir))}
             {BatchCompiler enqueue(pushSwitches())}
             if OptRec.makedepend then
                {BatchCompiler enqueue(setSwitch(unnest false))}
             end
             case OptRec.mode of core then
                {BatchCompiler enqueue(setSwitch(core true))}
                {BatchCompiler enqueue(setSwitch(codegen false))}
             [] scode then
                {BatchCompiler enqueue(setSwitch(outputcode true))}
                {BatchCompiler
                 enqueue(setSwitch(feedtoemulator false))}
             [] ecode then
                {BatchCompiler enqueue(setSwitch(outputcode true))}
                {BatchCompiler enqueue(setSwitch(expression true))}
                {BatchCompiler
                 enqueue(setSwitch(feedtoemulator false))}
             [] execute then
                {BatchCompiler
                 enqueue(setSwitch(feedtoemulator true))}
             else   % dump, executable
                {BatchCompiler enqueue(setSwitch(expression true))}
                {BatchCompiler
                 enqueue(setSwitch(feedtoemulator true))}
             end
             {BatchCompiler enqueue(feedFile(Arg return(result: ?R)))}
             {BatchCompiler enqueue(popSwitches())}
             {UI sync()}
             if {UI hasErrors($)} then
                raise error end
             end
             if OptRec.makedepend then File VS in
                File = {New Open.file init(name: stdout flags: [write])}
                VS = (OFN#':'#
                      case {UI getInsertedFiles($)} of Ns=_|_ then
                         {FoldL Ns fun {$ In X} In#' \\\n\t'#X end ""}
                      [] nil then ""
                      end#'\n')
                {File write(vs: VS)}
                {File close()}
             else
                case OptRec.mode of dump then
                   {Pickle.saveWithHeader R OFN '' OptRec.compress}
                [] executable then Exec Exec2 in
                   if {Functor.is R} then skip
                   else
                      {Report
                       error(kind: BatchCompilationError
                             msg: 'only functors can be made executable'
                             items: [hint(l: 'Value found'
                                          m: oz(R))])}
                   end
                   Exec = case {CondSelect OptRec execheader unit}
                          of unit then
                             case {CondSelect OptRec execpath unit}
                             of unit then
                                case {CondSelect OptRec execfile unit}
                                of unit then
                                   case {CondSelect OptRec execwrapper unit}
                                   of unit then
                                      case OptRec.target
                                      of unix then DefaultExecUnix
                                      [] windows then DefaultExecWindows
                                      else DefaultExec end
                                   elseof S then file({MakeExecFile S})
                                   end
                                elseof S then file(S)
                                end
                             elseof S then string({MakeExecHeader S})
                             end
                          elseof S then string(S)
                          end
                   Exec2 = case Exec of file(S) then {ReadFile S}
                           [] string(S) then S
                           end
                   {Pickle.saveWithHeader R OFN Exec2 OptRec.compress}
                   case Platform of win32 then skip
                   elsecase {OS.system 'chmod +x '#OFN} of 0 then skip
                   elseof N then
                      {Report
                       error(kind: BatchCompilationError
                             msg: 'failed to make output file executable'
                             items: [hint(l: 'Error code' m: N)])}
                   end
                [] execute then skip
                else File in   % core, scode, ecode
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
