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

   local
      UrlDefaults = \insert '../../url-defaults.oz'
   in
      FunExt    = UrlDefaults.'functor'
      MozartUrl = UrlDefaults.'home'
   end

%%%\ifndef OZM
%%%   local
%%%      Load = {`Builtin` load 2}
%%%   in
%%%      Peanuts = {Map \insert '../module-Peanuts.oz'
%%%              fun {$ M}
%%%                 Fun = {Load M#FunExt}
%%%              in
%%%                 case {Width Fun.'import'}==0
%%%                 then M # Fun.apply
%%%                 else
%%%                    raise error('No import for peanuts allowed') end
%%%                 end
%%%              end}
%%%   end
%%%\endif

   \insert 'RURL.oz'


   fun {ToUrl UorV}
      case {VirtualString.is UorV} then {RURL.vsToUrl UorV}
      else UorV
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

      fun {LoadFromUrl UrlV}
         {Trace '[Module] Load: '#UrlV#'\n'}
         {Load UrlV}
      end

      %% Mapping: URL -> Module
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
                   in
                      {GetFunctor ImAddr}
                   end}
      in
         {Func.'apply' IMPORT}
      end


      proc {GetFunctor Url ?Mod}
         UrlKey = {RURL.urlToKey Url}
      in
         case {ModuleMap.ensure UrlKey ?Mod} then
            {Trace '[Module] Get:  '#UrlKey#'\n'}
         else
            {Trace '[Module] Sync: '#UrlKey#'\n'}
            Mod={ByNeed fun {$}
                           {LinkFunctor Url {LoadFromUrl UrlKey}}
                        end}
         end
      end


      Module = module(load:
                         fun {$ ModName From}
                            Url={ModNameToUrl ModName From unit}
                         in
                            {GetFunctor Url}
                         end
                      link:
                         proc {$ UrlV Func ?Mod}
                            Url = {RURL.vsToUrl UrlV}
                         in
                            {ModuleMap.put {RURL.urlToKey Url} Mod}
                            thread
                               Mod={LinkFunctor Url Func}
                            end
                         end
                      enter:
                         proc {$ UrlV Mod}
                            {Trace '[Module] Enter: '#UrlV#'\n'}
                            Url={RURL.vsToUrl UrlV}
                         in
                            {ModuleMap.put {RURL.urlToKey Url} Mod}
                         end
                      system:
                         proc {$ ModName UrlV}
                            {Trace '[Module] System Map: '#ModName#':='#UrlV#'\n'}
                            {SystemMap.put ModName {RURL.vsToUrl UrlV}}
                         end
                      resolve: ModNameToUrl
                      getUrl:
                         fun {$ ModName From}
                            case {SystemMap.member ModName} then
                               {SystemMap.get ModName}
                            else
                               {ToUrl case From==unit then ModName#'.ozf'
                                      else From
                                      end}
                            end
                         end)

      %%
      %% Register System defaults
      %%

      local
         Functors = \insert '../functor-defaults.oz'
      in
         %% System library functors
         {ForAll Functors.dirs
          proc {$ Kind}
             {ForAll Functors.Kind
              proc {$ ModName}
                 {Module.system ModName MozartUrl#Kind#'/'#ModName#FunExt}
              end}
          end}
         {ForAll Functors.volatile
          proc {$ ModName}
             {Module.system ModName MozartUrl#'lib/'#ModName#FunExt}
          end}
      end

      %% Register some virtual modules
      %% Hmm, still not independent: CS

      {Module.enter MozartUrl#'lib/Module'#FunExt Module}
      {Module.enter MozartUrl#'lib/URL'#FunExt
       {{`Builtin` 'CondGetProperty' 3} url unit}}

      %% Register peanuts
%%%\ifndef OZM
%%%      {ForAll Peanuts
%%%       proc {$ M#P}
%%%       {Module.enter MozartUrl#'lib/'#M#FunExt {P 'import'}}
%%%       end}
%%%\endif

   in

      Module

   end

end
