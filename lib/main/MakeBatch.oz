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

\feed DumpIntro

declare
local
   Load = {`Builtin` load 2}
in
   NewSP = {Load 'SP.ozc'}
   SP = {NewSP m}
   \insert 'SP.env'
   = SP

   NewOP = {Load 'OP.ozc'}
   OP = {NewOP m('SP': SP)}
   \insert 'OP.env'
   = OP
end

\ifdef NEWCOMPILER
\switch
\endif

local
   Env = \insert Standard.env
in
   {Application.exec
    'ozbatch'
    c('SP':       lazy
      'OP':       lazy
      'Compiler': eager)

    fun instantiate {$ IMPORT}
       \insert 'SP.env'
       = IMPORT.'SP'
       \insert 'OP.env'
       = IMPORT.'OP'
       \insert 'Compiler.env'
       = IMPORT.'Compiler'

       fun {GetVerbose Args}
          case Args of verbose#B|Argr then
             case {GetVerbose Argr} of unspecified then B
             elseof NewB then NewB
             end
          elseof _|Argr then
             {GetVerbose Argr}
          [] nil then
             unspecified
          end
       end
    in
       proc {$ Argv ?Status}
          thread
             Verbose = case {GetVerbose Argv} of unspecified then false
                       elseof B then B
                       end
             BatchCompiler = {New Compiler.compilerClass init()}
             UI = {New Compiler.quietInterface init(BatchCompiler Verbose)}
             Dump = {NewCell false}
             OutputFileName = {NewCell unit}
          in
             {BatchCompiler enqueue(mergeEnv(Env))}
             {BatchCompiler enqueue(setSwitch(threadedqueries false))}
             {BatchCompiler enqueue(setSwitch(feedtoemulator false))}
             try
                {ForAll Argv
                 proc {$ Arg}
                    case Arg of define#X then
                       {BatchCompiler enqueue(macroDefine(X))}
                    elseof undef#X then
                       {BatchCompiler enqueue(macroUndef(X))}
                    elseof maxerrors#N then
                       {BatchCompiler enqueue(setMaxNumberOfErrors(N))}
                    elseof verbose#B then
                       skip   % has already been set
                    elseof dump#B then
                       {Assign Dump B}
                    elseof o#FileName then
                       {Assign OutputFileName FileName}
                    elseof SwitchName#Value then
                       {BatchCompiler enqueue(setSwitch(SwitchName Value))}
                    else R Core Code Ozma Feed in
                       {BatchCompiler enqueue(getSwitch(core ?Core))}
                       {BatchCompiler enqueue(getSwitch(outputcode ?Code))}
                       {BatchCompiler enqueue(getSwitch(ozma ?Ozma))}
                       {BatchCompiler enqueue(getSwitch(feedtoemulator ?Feed))}
                       case (case Core then 1 else 0 end) +
                          (case Code then 1 else 0 end) +
                          (case Ozma then 1 else 0 end) +
                          (case Feed then 1 else 0 end) +
                          (case {Access Dump} then 1 else 0 end) \= 1
                       then
                          {Error.msg
                           proc {$ X}
                              {System.printError {Error.formatLine X}}
                           end
                           error(kind: 'compiler directive error'
                                 msg: ('exactly one of '#
                                       'core, outputcode, ozma, '#
                                       'feedtoemulator or dump '#
                                       'must be set')
                                 body: [hint(l: 'core' m: oz(Core))
                                        hint(l: 'outputcode' m: oz(Code))
                                        hint(l: 'ozma' m: oz(Ozma))
                                        hint(l: 'feedtoemulator' m: oz(Feed))
                                        hint(l: 'dump' m: oz({Access Dump}))])}
                          raise error end
                       elsecase {Access OutputFileName} == unit
                          andthen {Not Feed}
                       then
                          {Error.msg
                           proc {$ X}
                              {System.printError {Error.formatLine X}}
                           end
                           error(kind: 'compiler directive error'
                                 msg: ('an output file name must be '#
                                       'specified'))}
                          raise error end
                       elsecase {Access OutputFileName} \= unit andthen Feed
                       then
                          {Error.msg
                           proc {$ X}
                              {System.printError {Error.formatLine X}}
                           end
                           error(kind: 'compiler directive error'
                                 msg: ('no output file name must be '#
                                       'specified for feedtoemulator'))}
                          raise error end
                       else skip
                       end
                       case {Access Dump} then
                          {BatchCompiler
                           enqueue(pushSwitches())}
                          {BatchCompiler
                           enqueue(setSwitch(expression true))}
                          {BatchCompiler
                           enqueue(setSwitch(feedtoemulator true))}
                          {BatchCompiler
                           enqueue(feedFile(Arg return(result: ?R)))}
                          {BatchCompiler
                           enqueue(popSwitches())}
                       else
                          {BatchCompiler
                           enqueue(feedFile(Arg return))}
                       end
                       {Wait {BatchCompiler enqueue(ping($))}}
                       case {UI hasErrors($)} then
                          {System.printError {UI getVS($)}}
                          raise error end
                       else skip
                       end
                       case {Access Dump} then
                          case {Component.smartSave R {Access OutputFileName}}
                          of nil then skip
                          elseof Vs then
                             {Error.msg
                              proc {$ X}
                                 {System.printError {Error.formatLine X}}
                              end
                              error(kind: 'dump error'
                                    msg: 'saved value is not stateless'
                                    body: [hint(l: 'Stateful values'
                                                m: oz(Vs))])}
                             {OS.unlink {Access OutputFileName}}
                             raise error end
                          end
                       elsecase Feed then skip
                       else File in
                          File = {New Open.file
                                  init(name: {Access OutputFileName}
                                       flags: [write create truncate])}
                          {File write(vs: {UI getSource($)})}
                          {File close()}
                       end
                    end
                 end}
                Status = 0
             catch error then
                Status = 1
             end
          end
       end
    end

    list(%% macro directives:
         define(type: string)
         undef(type: string)

         %% misc:
         maxerrors(type: int)
         verbose(type: bool)
         dump(type: bool)
         o(type: string)

         %% compiler switches:
         compilerpasses(type: bool)
         showinsert(type: bool)
         showcompiletime(type: bool)
         showcompilememory(type: bool)
         echoqueries(type: bool)
         watchdog(type: bool)
         ozma(type: bool)
         warnredecl(type: bool)
         warnunused(type: bool)
         warnforward(type: bool)
%        expression(type: bool)
         system(type: bool)
         catchall(type: bool)
%        selfallowedanywhere(type: bool)
         staticanalysis(type: bool)
         core(type: bool)
         realcore(type: bool)
         debugvalue(type: bool)
         debugtype(type: bool)
         codegen(type: bool)
         outputcode(type: bool)
         feedtoemulator(type: bool)
%        threadedqueries(type: bool)
         profile(type: bool)
         runwithdebugger(type: bool)
         debuginfocontrol(type: bool)
         debuginfovarnames(type: bool))}
end
