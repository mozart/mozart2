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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
   UsageError = 'command line option error'

   local
      fun {ConvertBooleanOpts OptSpecs}
         case OptSpecs of OptSpec|OptSpecr then C#S#Spec = OptSpec in
            case {CondSelect Spec type unit} of bool then
               C#S#{AdjoinAt Spec value true}|
               unit#(&n|&o|S)#{AdjoinAt Spec value false}|
               {ConvertBooleanOpts OptSpecr}
            else
               OptSpec|{ConvertBooleanOpts OptSpecr}
            end
         [] nil then
            nil
         end
      end
   in
      OptSpecs = {ConvertBooleanOpts
                  [&E#"core"#mode(value: core)
                   &S#"outputcode"#mode(value: outputcode)
                   &s#"ozma"#mode(value: ozma)
                   &e#"feedtoemulator"#mode(value: feedtoemulator)
                   &c#"dump"#mode(value: dump)
                   &h#"help"#help(value: unit) &?#unit#help(value: unit)
                   &D#"define"#define(type: atom)
                   &U#"undefine"#undef(type: atom)
                   &v#"verbose"#verbose(value: true)
                   &q#"quiet"#verbose(value: false)
                   &o#"outputfile"#outputfile(type: string)
                   &l#"environment"#environment(type: string)
                   &I#"incdir"#incdir(type: string)
                   unit#"include"#include(type: string)
                   unit#"maxerrors"#maxerrors(type: int)
                   unit#"compilerpasses"#compilerpasses(type: bool)
                   unit#"showinsert"#showinsert(type: bool)
                   unit#"showcompiletime"#showcompiletime(type: bool)
                   unit#"showcompilememory"#showcompilememory(type: bool)
                   unit#"echoqueries"#echoqueries(type: bool)
                   unit#"watchdog"#watchdog(type: bool)
                   unit#"warnredecl"#warnredecl(type: bool)
                   unit#"warnunused"#warnunused(type: bool)
                   unit#"warnunusedformals"#warnunused(type: bool)
                   unit#"warnforward"#warnforward(type: bool)
                   unit#"system"#system(type: bool)
                   unit#"gump"#gump(type: bool)
                   unit#"staticanalysis"#staticanalysis(type: bool)
                   unit#"realcore"#realcore(type: bool)
                   unit#"debugvalue"#debugvalue(type: bool)
                   unit#"debugtype"#debugtype(type: bool)
                   &p#"profile"#profile(type: bool)
                   unit#"runwithdebugger"#runwithdebugger(type: bool)
                   unit#"debuginfocontrol"#debuginfocontrol(type: bool)
                   unit#"debuginfovarnames"#debuginfovarnames(type: bool)
                   &g#"debuginfo"#debuginfo(type: bool)]}
   end

   Usage =
   'Usage: ozbatch [options] [file] ...\n'#
   'You have to choose one of the following modes of operation:\n'#
   '-E, --core                    Transform a statement into core language\n'#
   '                              (file extension: .ozi).\n'#
   '-S, --outputcode              Compile a statement to assembly code\n'#
   '                              (file extension: .ozm).\n'#
   '-s, --ozma                    Compile a statement to Ozma assembly code\n'#
   '                              (file extension: .ozm).\n'#
   '-e, --feedtoemulator          Compile and execute a statement.\n'#
   '                              This is the default mode.\n'#
   '-c, --dump                    Compile and evaluate an expression,\n'#
   '                              pickling the result\n'#
   '                              (file extension: .ozp).\n'#
   '\n'#
   'Additionally, you may specify the following options:\n'#
   '-h, -?, --help                Output usage information and exit.\n'#
   '-D NAME, --define=NAME        Define macro name NAME.\n'#
   '-U NAME, --undefine=NAME      Undefine macro name NAME.\n'#
   '-v, --verbose                 Display all compiler messages.\n'#
   '-q, --quiet                   Inhibit compiler messages\n'#
   '                              unless an error is encountered.\n'#
   '-o FILE, --outputfile=FILE    Write output to FILE (`-\' for stdout).\n'#
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
   '--(no)system                  Allow use of system variables.\n'#
   '--(no)gump                    Allow Gump definitions.\n'#
   '--(no)staticanalysis          Run static analysis.\n'#
   '--(no)realcore                Output the real non-fancy core syntax.\n'#
   '--(no)debugvalue              Annotate variable values in core output.\n'#
   '--(no)debugtype               Annotate variable types in core output.\n'#
   '-p, --(no)profile             Include profiling information.\n'#
   '--(no)runwithdebugger         Execute queries under debugger.\n'#
   '--(no)debuginfocontrol        Include control flow information.\n'#
   '--(no)debuginfovarnames       Include variable information.\n'#
   '-g, --(no)debuginfo           All three above.\n'

   local
      fun {SignConvert S}
         {Map S fun {$ C} case C == &- then &~ end end}
      end

      proc {ParseOptArg Spec Args ?Opt ?Rest} Value in
         case {HasFeature Spec value} then
            Value = Spec.value
            Rest = Args
         elsecase Args of Arg1|Argr then
            case Spec.type of string then
               Value = Arg1
            [] atom then
               Value = {String.toAtom Arg1}
            [] int then S = {SignConvert Arg1} in
               case {String.isInt S} then
                  Value = {String.toInt S}
               else
                  raise usage('integer argument expected') end
               end
            [] float then S = {SignConvert Arg1} in
               case {String.isFloat S} then
                  Value = {String.toFloat S}
               else
                  raise usage('float argument expected') end
               end
            end
            Rest = Argr
         [] nil then
            raise usage('missing argument') end
         end
         Opt = {Label Spec}#Value
      end

      fun {GetOptSpec OptSpecs OptChar}
         case OptSpecs of OptSpec|OptSpecr then C#_#Spec = OptSpec in
            case C == OptChar then Spec
            else {GetOptSpec OptSpecr OptChar}
            end
         [] nil then unit
         end
      end

      proc {ParseOpt OptChar Arg1r Args ?Opt ?Rest}
         case {GetOptSpec OptSpecs OptChar} of unit then
            raise usage('unknown option `-'#[OptChar]#'\'') end
         elseof Spec then
            case Arg1r of nil then
               {ParseOptArg Spec Args ?Opt ?Rest}
            elsecase {HasFeature Spec value} then
               Opt = {Label Spec}#Spec.value
               Rest = (&-|Arg1r)|Args
            else
               {ParseOptArg Spec Arg1r|Args ?Opt ?Rest}
            end
         end
      end

      fun {IsPrefix S1 S2 ?Exact ?Value}
         case S1 of nil then
            Exact = S2 == nil
            Value = unit
            true
         [] C1|Cr1 then
            case C1 of &= then
               Exact = S2 == nil
               Value = Cr1
               true
            elsecase S2 of nil then false
            [] C2|Cr2 then
               C1 == C2 andthen {IsPrefix Cr1 Cr2 ?Exact ?Value}
            end
         end
      end

      fun {GetLongOptSpec OptSpecs LongOpt ?Exact ?Value}
         case OptSpecs of OptSpec|OptSpecr then
            S Spec1 Exact1 Value1
         in
            _#S#Spec1 = OptSpec
            case S \= unit andthen {IsPrefix LongOpt S ?Exact1 ?Value1}
            then
               case Exact1 then
                  Exact = true
                  Value = Value1
                  Spec1
               else Spec2 Exact2 Value2 in
                  Spec2 = {GetLongOptSpec OptSpecr LongOpt ?Exact2 ?Value2}
                  case Spec2 == unit then
                     Exact = false
                     Value = Value1
                     Spec1
                  elsecase Exact2 then
                     Exact = true
                     Value = Value2
                     Spec2
                  else
                     raise
                        usage('ambiguous option prefix `'#LongOpt#'\'')
                     end
                  end
               end
            else
               {GetLongOptSpec OptSpecr LongOpt ?Exact ?Value}
            end
         [] nil then
            unit
         end
      end

      proc {ParseLongOpt LongOpt Args ?Opt ?Rest} Value in
         case {GetLongOptSpec OptSpecs LongOpt _ ?Value} of unit then
            raise usage('unknown option `--'#LongOpt#'\'') end
         elseof Spec then NewArgs in
            case Value of unit then
               case {HasFeature Spec value} then
                  NewArgs = Args
               else
                  raise
                     usage('option `--'#LongOpt#'\' expects an argument')
                  end
               end
            elsecase {HasFeature Spec value} then
               raise
                  usage('option `--'#LongOpt#
                        '\' does not expect an argument')
               end
            else
               NewArgs = Value|Args
            end
            {ParseOptArg Spec NewArgs ?Opt ?Rest}
         end
      end
   in
      proc {ParseArgs Args ?Opts ?Rest}
         case Args of Arg1|Argr then
            case Arg1 of &-|Opt then Opt1 Optr NewArgr in
               case Opt of &-|LongOpt then
                  {ParseLongOpt LongOpt Argr ?Opt1 ?NewArgr}
               elseof OptChar|Arg1r then
                  {ParseOpt OptChar Arg1r Argr ?Opt1 ?NewArgr}
               [] nil then
                  raise usage('bad option syntax `-\'') end
               end
               Opts = Opt1|Optr
               {ParseArgs NewArgr ?Optr ?Rest}
            else NewRest in
               Rest = Arg1|NewRest
               {ParseArgs Argr ?Opts ?NewRest}
            end
         [] nil then
            Opts = nil
            Rest = nil
         end
      end
   end

   fun {GetVerbose Args}
      case Args of verbose#B|Argr then
         case {GetVerbose Argr} of auto then B
         elseof NewB then NewB
         end
      elseof _|Argr then
         {GetVerbose Argr}
      [] nil then
         auto
      end
   end

   local
      fun {IsIDChar C}
         {Char.isAlNum C} orelse C == &_
      end

      fun {IsQuotedVariable S}
         case S of C1|Cr then
            case C1 == &` andthen Cr == nil then true
            elsecase C1 == 0 then false
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
   in
      proc {IncludeFunctors S Compiler}
         case S==nil then skip else
            Var VarAtom URL Rest Export
         in
            {String.token {String.token S &, $ ?Rest} &= ?Var ?URL}
            VarAtom = {String.toAtom Var}
            try
               Export={Module.load VarAtom case URL==nil then unit
                                           else URL
                                           end}
               {Wait Export}
            catch _ then
               {Report
                error(kind: UsageError
                      msg: 'unknown functor `'#Var#'='#URL#'\' requested'
                      items: [hint(l: 'Hint'
                                   m: ('Use --help to obtain '#
                                       'usage information'))])}
            end
            case {IsPrintName VarAtom} then
               {Compiler enqueue(mergeEnv(env(VarAtom:Export)))}
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
            {IncludeFunctors Rest Compiler}
         end
      end
   end

   fun {ChangeExtension X OldExt NewExt}
      case X == OldExt then NewExt
      elsecase X of C|Cr then
         C|{ChangeExtension Cr OldExt NewExt}
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
   proc {BatchCompile Argv ?Status}
      try
         Opts FileNames Verbose BatchCompiler UI Mode ModeGiven OutputFile
         IncDir
      in
         try
            {ParseArgs Argv ?Opts ?FileNames}
         catch usage(VS) then
            {Report error(kind: UsageError
                          msg: VS
                          items: [hint(l: 'Hint'
                                       m: ('Use --help to obtain '#
                                           'usage information'))])}
         end
         Verbose = {GetVerbose Opts}
         BatchCompiler = {New Compiler.engine init()}
         UI = {New Compiler.quietInterface init(BatchCompiler Verbose)}
         {BatchCompiler enqueue(setSwitch(showdeclares false))}
         {BatchCompiler enqueue(setSwitch(warnunused true))}
         {BatchCompiler enqueue(setSwitch(threadedqueries false))}
         Mode = {NewCell feedtoemulator}
         OutputFile = {NewCell unit}
         IncDir = {NewCell nil}
         {ForAll Opts
          proc {$ Opt#X}
             case Opt of help then
                {System.printInfo Usage}
                raise success end
             [] define then
                {BatchCompiler enqueue(macroDefine(X))}
             [] undef then
                {BatchCompiler enqueue(macroUndef(X))}
             [] maxerrors then
                {BatchCompiler enqueue(setMaxNumberOfErrors(X))}
             [] environment then
                {IncludeFunctors X BatchCompiler}
             [] incdir then
                {Assign IncDir X|{Access IncDir}}
             [] include then
                {BatchCompiler enqueue(pushSwitches())}
                {BatchCompiler enqueue(setSwitch(feedtoemulator true))}
                {BatchCompiler enqueue(feedFile(X return))}
                {BatchCompiler enqueue(popSwitches())}
                {Wait {BatchCompiler enqueue(ping($))}}
                case {UI hasBeenTopped($)} then
                   {System.printError {UI getVS($)}}
                   case {UI hasErrors($)} then
                      raise error end
                   else skip
                   end
                else skip
                end
             [] verbose then
                skip   % has already been set
             [] mode then
                case {IsDet ModeGiven} then
                   {Report error(kind: UsageError
                                 msg: 'mode specified multiply on command line'
                                 items: [hint(l: 'Hint'
                                              m: ('Use --help to obtain '#
                                                  'usage information'))])}
                else
                   {Assign Mode X}
                   ModeGiven = true
                end
             [] outputfile then
                {Assign OutputFile X}
             [] debuginfo then
                {BatchCompiler enqueue(setSwitch(runwithdebugger X))}
                {BatchCompiler enqueue(setSwitch(debuginfocontrol X))}
                {BatchCompiler enqueue(setSwitch(debuginfovarnames X))}
             elseof SwitchName then
                {BatchCompiler enqueue(setSwitch(SwitchName X))}
             end
          end}
         {OS.putEnv 'OZPATH'
          {FoldL {Access IncDir}
           fun {$ In S} {Append S &:|In} end
           case {OS.getEnv 'OZPATH'} of false then "."
           elseof S then S
           end}}
         case FileNames of nil then
            {Report error(kind: UsageError
                          msg: 'no input files given'
                          items: [hint(l: 'Hint'
                                       m: ('Use --help to obtain '#
                                           'usage information'))])}
         elsecase {Access OutputFile} \= "-"
            andthen {Access OutputFile} \= unit
            andthen {Length FileNames} > 1
         then
            {Report error(kind: UsageError
                          msg: ('only one input file allowed when '#
                                'an output file name is given'))}
         else
            {ForAll FileNames
             proc {$ Arg} OFN R in
                case {Access OutputFile} == unit then
                   case {Access Mode} of core then
                      OFN = {ChangeExtension Arg ".oz" ".ozi"}
                   [] outputcode then
                      OFN = {ChangeExtension Arg ".oz" ".ozm"}
                   [] ozma then
                      OFN = {ChangeExtension Arg ".oz" ".ozm"}
                   [] feedtoemulator then
                      OFN = unit
                   [] dump then
                      OFN = {ChangeExtension Arg ".oz" ".ozp"}
                   end
                elsecase {Access OutputFile} == "-" then
                   case {Access Mode} of dump then
                      {Report
                       error(kind: UsageError
                             msg: 'dumping to stdout is not possible')}
                   else
                      OFN = stdout
                   end
                elsecase {Access Mode} of feedtoemulator then
                   {Report
                    error(kind: UsageError
                          msg: ('no output file name must be '#
                                'specified for feedtoemulator'))}
                else
                   OFN = {Access OutputFile}
                end
                {BatchCompiler enqueue(pushSwitches())}
                case {Access Mode} of core then
                   {BatchCompiler enqueue(setSwitch(core true))}
                   {BatchCompiler enqueue(setSwitch(codegen false))}
                [] outputcode then
                   {BatchCompiler enqueue(setSwitch(outputcode true))}
                   {BatchCompiler
                    enqueue(setSwitch(feedtoemulator false))}
                [] ozma then
                   {BatchCompiler enqueue(setSwitch(ozma true))}
                [] feedtoemulator then
                   {BatchCompiler
                    enqueue(setSwitch(feedtoemulator true))}
                [] dump then
                   {BatchCompiler enqueue(setSwitch(expression true))}
                   {BatchCompiler
                    enqueue(setSwitch(feedtoemulator true))}
                end
                {BatchCompiler
                 enqueue(feedFile(Arg return(result: ?R)))}
                {BatchCompiler enqueue(popSwitches())}
                {Wait {BatchCompiler enqueue(ping($))}}
                case {UI hasBeenTopped($)} then
                   {System.printError {UI getVS($)}}
                   case {UI hasErrors($)} then
                      raise error end
                   else skip
                   end
                else skip
                end
                case {Access Mode} of dump then
                   try
                      {Pickle.save R OFN}
                   catch error(dp(save resources Filename Vs) ...) then
                      {Report
                       error(kind: UsageError
                             msg: 'saved value is not stateless'
                             items: [hint(l: 'Stateful values'
                                          m: oz(Vs))])}
                   end
                [] feedtoemulator then skip
                else File in
                   File = {New Open.file
                           init(name: OFN
                                flags: [write create truncate])}
                   {File write(vs: {UI getSource($)})}
                   {File close()}
                end
             end}
         end
         raise success end
      catch error then
         Status = 1
      [] success then
         Status = 0
      end
   end
end
