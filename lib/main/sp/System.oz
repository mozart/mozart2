%%%
%%% Authors:
%%%   Martin Henz (henz@iscs.nus.edu.sg)
%%%   Michael Mehl (mehl@dfki.de)
%%%   Ralf Scheidhauer (scheidhr@dfki.de)
%%%   Christian Schulte (schulte@dfki.de)
%%%   Denys Duchier (duchier@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Martin Henz, 1997
%%%   Michael Mehl, 1997
%%%   Ralf Scheidhauer, 1997
%%%   Christian Schulte, 1997
%%%   Denys Duchier, 1998
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
Show            = {`Builtin` 'Show'            1}
Print           = {`Builtin` 'Print'           1}
Exit            = {`Builtin` shutdown          1}
GetProperty     = {`Builtin` 'GetProperty'     2}
PutProperty     = {`Builtin` 'PutProperty'     2}
CondGetProperty = {`Builtin` 'CondGetProperty' 3}

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

   proc {SystemSet W}
      {PutProperty {Label W} W}
   end

   fun {SystemGet C}
      case C
      of     standalone then {GetProperty 'oz.standalone'}
      elseof home       then {GetProperty 'oz.home'      }
      else                   {GetProperty C              }
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
                   %% interface to system properties
                   property:
                      property(get:GetProperty
                               put:PutProperty
                               condGet:CondGetProperty)
                  )
end
