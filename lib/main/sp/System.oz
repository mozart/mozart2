%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Michael Mehl (mehl@dfki.de)
%%%   Ralf Scheidhauer (scheidhr@dfki.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
%%%   Michael Mehl, 1997
%%%   Ralf Scheidhauer, 1997
%%%   Christian Schulte, 1997
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


%%
%% Global
%%
Show       = {`Builtin` 'Show'  1}
Print      = {`Builtin` 'Print' 1}
Exit       = {`Builtin` shutdown 1}
SystemRegistry = {{`Builtin` 'SystemRegistry' 1}}

proc {RegistryGet     P   V} {Dictionary.get     SystemRegistry P   V} end
proc {RegistryPut     P   V} {Dictionary.put     SystemRegistry P   V} end
proc {RegistryCondGet P D V} {Dictionary.condGet SystemRegistry P D V} end

%%
%% Module
%%
local

   %%
   %% Printing
   %%
   PrintInfo  = {`Builtin` 'System.printInfo'  1}
   proc {ShowInfo V}
      {PrintInfo V # '\n'}
   end
   PrintError = {`Builtin` 'System.printError' 1}
   proc {ShowError V}
      {PrintError V # '\n'}
   end

   %%
   %% StringToValue and vice versa
   %%
   local
      fun {Trans X}
         case X of fAtom(A _) then A
         [] fVar(PrintName _) then
            case PrintName of '`true`' then true
            [] '`false`' then false
            [] '`unit`' then unit
            else raise notAValue end
            end
         [] fEscape(V _) then
            {Trans V}
         [] fWildcard(_) then _
         [] fInt(I _) then I
         [] fFloat(F _) then F
         [] fRecord(Label Args) then ArgCounter in
            ArgCounter = {NewCell 1}
            {List.toRecord {Trans Label}
             {Map Args
              fun {$ Arg}
                 case Arg of fColon(F T) then
                    {Trans F}#{Trans T}
                 else N NewN in
                    {Exchange ArgCounter ?N NewN}
                    NewN = N + 1
                    N#{Trans Arg}
                 end
              end}}
         [] fOpenRecord(Label Args) then ArgCounter Res in
            ArgCounter = {NewCell 1}
            Res = {Record.tell {Trans Label}}
            {ForAll Args
             proc {$ Arg}
                case Arg of fColon(F T) then
                   Res^{Trans F} = {Trans T}
                else N NewN in
                   {Exchange ArgCounter ?N NewN}
                   NewN = N + 1
                   Res^N = {Trans Arg}
                end
             end}
            Res
         else
            raise notAValue end
         end
      end

      ParseVirtualString = {`Builtin` ozparser_parseVirtualString 3}
   in
      fun {SystemVirtualStringToValue VS}
         case {ParseVirtualString VS defaults} of [ParseTree] then
            try
               {Trans ParseTree}
            catch notAValue then
               {`RaiseError` system(virtualStringToValue VS)} unit
            end
         else
            {`RaiseError` system(virtualStringToValue VS)} unit
         end
      end
   end

   local
      SetThreads    = {`Builtin` 'SystemSetThreads'    1}
      SetTime       = {`Builtin` 'SystemSetTime'       1}
      SetPriorities = {`Builtin` 'SystemSetPriorities' 1}
      SetGC         = {`Builtin` 'SystemSetGC'         1}
      SetPrint      = {`Builtin` 'SystemSetPrint'      1}
      SetErrors     = {`Builtin` 'SystemSetErrors'     1}
      SetMessages   = {`Builtin` 'SystemSetMessages'   1}
      SetInternal   = {`Builtin` 'SystemSetInternal'   1}
      SetFD         = {`Builtin` 'SystemSetFD'         1}
   in
      proc {SystemSet W}
         case {Label W}
         of threads    then {SetThreads W}
         [] time       then {SetTime W}
         [] priorities then {SetPriorities W}
         [] gc         then {SetGC W}
         [] print      then {SetPrint W}
         [] errors     then {SetErrors W}
         [] messages   then {SetMessages W}
         [] internal   then {SetInternal W}
         [] fd         then {SetFD W}
         end
      end
   end

   local
      GetThreads    = {`Builtin` 'SystemGetThreads'    1}
      GetPriorities = {`Builtin` 'SystemGetPriorities' 1}
      GetTime       = {`Builtin` 'SystemGetTime'       1}
      GetGC         = {`Builtin` 'SystemGetGC'         1}
      GetPrint      = {`Builtin` 'SystemGetPrint'      1}
      GetFD         = {`Builtin` 'SystemGetFD'         1}
      GetSpaces     = {`Builtin` 'SystemGetSpaces'     1}
      GetErrors     = {`Builtin` 'SystemGetErrors'     1}
      GetMessages   = {`Builtin` 'SystemGetMessages'   1}
      GetMemory     = {`Builtin` 'SystemGetMemory'     1}
      GetLimits     = {`Builtin` 'SystemGetLimits'     1}
      GetArgv       = {`Builtin` 'SystemGetArgv'       1}
      GetStandalone = {`Builtin` 'SystemGetStandalone' 1}
      GetHome       = {`Builtin` 'SystemGetHome'       1}
      GetPlatform   = {`Builtin` 'SystemGetPlatform'   1}
   in
      fun {SystemGet C}
         case C
         of threads    then
            R = threads(created:_ runnable:_ min:_ max:_)
         in
            {GetThreads R} R
         [] priorities then
            R = priorities(high:_ medium:_)
         in
            {GetPriorities R} R
         [] time       then
            R = time(copy:_ gc:_ load:_ propagate:_ run:_
                     system:_ user:_ total:_ detailed:_)
         in
            {GetTime R} R
         [] gc         then
            R = gc(min:_ max:_ free:_ tolerance:_ on:_
                   threshold:_ size:_ active:_)
         in
            {GetGC R} R
         [] print      then
            R = print(depth:_ width:_)
         in
            {GetPrint R} R
         [] fd         then
            R = fd(variables:_ propagators:_ invoked:_ threshold:_)
         in
            {GetFD R} R
         [] spaces     then
            R = spaces(committed:_ cloned:_ created:_ failed:_ succeeded:_)
         in
            {GetSpaces R} R
         [] errors     then
            R = errors('thread':_ location:_ hints:_ depth:_ width:_ debug:_)
         in
            {GetErrors R} R
         [] messages   then
            R = messages(gc:_ idle:_ feed:_ foreign:_ load:_ cache:_)
         in
            {GetMessages R} R
         [] memory     then
            R = memory(atoms:_ names:_ builtins:_ freelist:_ code:_ heap:_)
         in
            {GetMemory R} R
         [] limits     then
            R = limits(int:_)
         in
            {GetLimits R} R
         [] argv       then {GetArgv}
         [] standalone then {GetStandalone}
         [] home       then {GetHome}
         [] platform   then {GetPlatform}
         end
      end
   end

in

   System = system(%% Querying and configuring system parameters
                   get:        SystemGet
                   set:        SystemSet
                   %% printing and showing of virtual strings
                   printError: PrintError
                   printInfo:  PrintInfo
                   showError:  ShowError
                   showInfo:   ShowInfo
                   %% printing and showing of trees
                   print:      Print
                   show:       Show
                   %% test for pointer equality
                   eq:         {`Builtin` 'System.eq' 3}
                   %% system related inquiry functions
                   nbSusps:    {`Builtin` 'System.nbSusps' 2}
                   printName:  {`Builtin` 'System.printName' 2}
                   %% system control functionality
                   gcDo:       {`Builtin` 'System.gcDo' 0}
                   %% misc functionality
                   apply:                {`Builtin` 'System.apply' 2}
                   tellRecordSize:       `tellRecordSize`
                   virtualStringToValue: SystemVirtualStringToValue
                   valueToVirtualString:
                      {`Builtin` 'System.valueToVirtualString' 4}
                   exit: Exit
                   %% interface to system registry
                   registry:
                      registry(get:RegistryGet
                               put:RegistryPut
                               condGet:RegistryCondGet)
                  )
end
