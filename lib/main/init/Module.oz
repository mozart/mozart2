%%%
%%% Author:
%%%   Christian Schulte <schulte@dfki.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
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

%%%
%%% Interface specification
%%%
%%% {Module.load ModName}
%%%   loads and returns module created by functor
%%%
%%% {Module.link ModName Functor}
%%%   links functor and returns module
%%%
%%% {Module.enter ModName Module}
%%%   enters module and returns module
%%%
%%% {Module.system SystemName URLInfix}
%%%

local

   \insert 'RURL.oz'


   fun {ToUrl UorV}
      case {VirtualString.is UorV} then {RURL.vsToUrl UorV}
      else UorV
      end
   end

   local
      proc {Copy Fs Mod Adj}
         case Fs of nil then skip
         [] F|Fr then Adj.F=Mod^F {Copy Fr Mod Adj}
         end
      end
   in
      proc {AdjustImport Mod Fs ?Adj}
         %% Projects import to features Fs
         Adj={MakeRecord m Fs} {Copy Fs Mod Adj}
      end
   end

   fun {NewSyncDict}
      D = {Dictionary.new}
      L = {Lock.new}
   in
      dict(ensure: fun {$ Key ?Entry}
                      lock L then
                         case {Dictionary.member D Key} then
                            Entry={Dictionary.get D Key} true
                         else
                            Entry={Dictionary.put D Key} false
                         end
                      end
                   end
           member: fun {$ Key}
                      lock L then {Dictionary.member D Key} end
                   end
           put:    proc {$ Key X}
                      lock L then {Dictionary.put D Key X} end
                   end
           get:    fun {$ Key}
                      lock L then {Dictionary.get D Key} end
                   end)
   end


in

   fun {NewModule}

      Load  = {`Builtin` load 2}

      Trace = case {{`Builtin` 'OS.getEnv' 2} 'OZ_TRACE_MODULE'}==false then
                 proc {$ _} skip end
              else
                 {`Builtin` 'System.printInfo'  1}
              end

      fun {LoadFromUrl Url}
         %% Loads a functor from a given Url
         V={RURL.urlToKey Url}
      in
         {Trace '[Module] Load: '#V#'\n'}
         {Load V}
      end

      %% Mapping: URL -> e(top:      EXPORT that synchronizes on toplevel
      %%                   features: EXPORT that synchronizes on features
      %%                   load:     Unary procedure that loads)
      %%
      ModuleMap = {NewSyncDict}

      %%
      %% Url resolving
      %%
      SystemMap = {NewSyncDict}

      fun {ModNameToUrl ModName From BaseUrl}
         case {SystemMap.member ModName} then
            {SystemMap.get ModName}
         else
            RelUrl = {ToUrl case From==unit then ModName#'.ozf'
                            else From
                            end}
         in
            case BaseUrl==unit then RelUrl else
               {RURL.resolve BaseUrl RelUrl}
            end
         end
      end

      fun {LinkFunctor BaseUrl Func}
         IMPORT = {Record.mapInd Func.'import'
                   fun {$ ModName Info}
                      ImAddr = {ModNameToUrl ModName
                                {CondSelect Info 'from' unit}
                                BaseUrl}
                      Feats  = {Functor.getFeatures Func.'import'.ModName}
                   in
                      %% Shrink features to what has been imported
                      case Feats==nil then
                         {GetFunctor top ImAddr}
                      else
                         {AdjustImport {GetFunctor features ImAddr} Feats}
                      end
                   end}
      in
         {Func.'apply' IMPORT}
      end

      fun {MakeLoadProc TopExp FeatExp Url}
         %% Ensures that loading happens at most once
         proc {DoLoad}
            FeatExp={LinkFunctor Url {LoadFromUrl Url}}
            TopExp=FeatExp
         end
         proc {DoSkip}
            skip
         end
         C = {Cell.new DoLoad}
      in
         proc {$ _}
            {{Cell.exchange C $ DoSkip}}
         end
      end

      fun {GetFunctor Mode Url}
         UrlKey = {RURL.urlToKey Url}
         LoadInfo
      in
         case {ModuleMap.ensure UrlKey ?LoadInfo} then
            {Trace '[Module] Get:  ('#Mode#') '#UrlKey#'\n'}
         else
            TopExp FeatExp
            LoadProc = {MakeLoadProc TopExp FeatExp Url}
         in
            {Trace '[Module] Sync: '#UrlKey#'\n'}

            LoadInfo = info(top:      TopExp
                            features: FeatExp
                            load:     LoadProc)
            thread
               %% Synchronize on feature request
               {ForAll {Record.monitorArity FeatExp _}
                proc {$ A}
                   {Lazy.new LoadProc FeatExp.A}
                end}
            end

            {Lazy.new LoadProc TopExp}
         end

         case Mode
         of eager    then thread {LoadInfo.load _} end LoadInfo.top
         [] top      then LoadInfo.top
         [] features then LoadInfo.features
         end
      end

      Module = module(load:
                         fun {$ ModName From Feats}
                            Url={ModNameToUrl ModName From unit}
                         in
                            case Feats==nil then
                               {GetFunctor top Url}
                            else
                               {AdjustImport {GetFunctor features Url} Feats}
                            end
                         end
                      link:
                         fun {$ UrlV Func}
                            Url      = {RURL.vsToUrl UrlV}
                            LoadInfo = {ModuleMap.put {RURL.urlToKey Url}}
                            Export   = thread
                                          {LinkFunctor Url Func}
                                       end
                         in
                            LoadInfo = info(top:      Export
                                            features: Export
                                            load:     proc {$ _} skip end)
                               Export
                         end
                      enter:
                         proc {$ UrlV Module}
                            Url={RURL.vsToUrl UrlV}
                         in
                            {ModuleMap.put {RURL.urlToKey Url}
                             info(top:      Module
                                  features: Module
                                  load:     proc {$ _} skip end)}
                         end
                      system:
                         proc {$ ModName UrlV}
                            {SystemMap.put ModName {RURL.vsToUrl UrlV}}
                         end)

      %%
      %% Register System defaults
      %%
      local
         MozartUrl  = 'http://www.ps.uni-sb.de/ozhome/'
         FunExt     = '.ozf'
      in
         %% System library functors
         {ForAll ['Application'
                  'Search' 'FD' 'Schedule' 'FS'
                  'System' 'Error' 'Debug' 'Finalize' 'Foreign'
                  'Connection' 'Remote'
                  'OS' 'Open' 'Pickle'
                  'Tk' 'TkTools'
                  'Compiler'
                  'Misc'
                  'URL' 'Module'
                  'Applet' 'Syslet' 'Servlet'
                 ]
          proc {$ ModName}
             {Module.system ModName MozartUrl#'lib/'#ModName#FunExt}
          end}

         %% Tool functors
         {ForAll ['Panel' 'Browser' 'Explorer' 'CompilerPanel'
                  'Emacs' 'Ozcar' 'Profiler' 'Gump' 'GumpScanner'
                  'GumpParser']
          proc {$ ModName}
             {Module.system ModName MozartUrl#'tools/'#ModName#FunExt}
          end}

         %% Register some modules
         {Module.enter MozartUrl#'lib/Module.ozf' Module}
         {Module.enter MozartUrl#'lib/URL.ozf'
          {{`Builtin` 'CondGetProperty' 3} url unit}}

      end

   in

      Module

   end

end
