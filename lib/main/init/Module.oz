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

   local
      BootUrl   = {RURL.vsToUrl "x-oz://boot//DUMMY"}
      SystemUrl = {RURL.vsToUrl "x-oz://system//DUMMY"}
   in
      OzScheme  = BootUrl.scheme = SystemUrl.scheme
      %% BootLoc   = BootUrl.netloc
      %% SystemLoc = SystemUrl.netloc
   end

  local
      UrlDefaults = \insert '../../url-defaults.oz'
   in
      FunExt    = UrlDefaults.'functor'
      MozartUrl = UrlDefaults.'home'
   end

   fun {ToUrl UorV}
      case {VirtualString.is UorV} then {RURL.vsToUrl UorV}
      else UorV
      end
   end

   proc {Swallow _}
      skip
   end

   %%
   %% Register System names
   %%

   SystemMap = local
                  Functors = \insert '../../functor-defaults.oz'
                  BaseUrl  = {RURL.vsToUrl MozartUrl#"DUMMY"}
               in
                  {List.toRecord map
                   {Map {Append Functors.volatile
                         {Append Functors.lib Functors.tools}}
                    fun {$ ModName}
                       ModName #
                       {RURL.resolve BaseUrl
                        {RURL.vsToUrl ModName#FunExt}}
                    end}}
               end

in

   functor NewModule prop once

   import
      Pickle System OS Boot
   export
      load:   ModuleLoad
      link:   ModuleLink
      enter:  ModuleEnter

   body

      Trace = case {OS.getEnv 'OZ_TRACE_MODULE'}==false then Swallow
              else System.showInfo
              end

      fun {LoadFromUrl UrlV}
         {Trace '[Module] Load:  '#UrlV}
         {Pickle.load UrlV}
      end

      %%
      %% Mapping: URL -> Module
      %%
      ModuleMap = {Dictionary.new}

      fun {ModNameToUrl ModName From BaseUrl}
         FromUrl = {ToUrl case From==unit then
                             ModName#'.ozf'
                          else From
                          end}
      in
         case {CondSelect FromUrl scheme ""}==OzScheme then
            %% Reserved scheme for boot and system modules
            FromUrl
         elsecase {HasFeature SystemMap ModName} then
            SystemMap.ModName
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

      local
         GetLock = {NewLock}
      in
         fun {GetFunctor Url}
            UrlKey = {RURL.urlToKey Url}
         in
            lock GetLock then
               case {Dictionary.member ModuleMap UrlKey} then skip else
                  {Dictionary.put ModuleMap UrlKey
                   case {CondSelect Url scheme ""}==OzScheme then
                      {Trace '[Module] Boot:  '#UrlKey}
                      {Boot.manager Url.path.1.1}
                   else
                      {Trace '[Module] Sync:  '#UrlKey}
                      {ByNeed fun {$}
                                 {LinkFunctor Url {LoadFromUrl UrlKey}}
                              end}
                   end}
               end
               {Dictionary.get ModuleMap UrlKey}
            end
         end

         proc {ModuleLink UrlV Func ?Mod}
            {Trace '[Module] Link:  '#UrlV}
            Url = {RURL.vsToUrl UrlV}
         in
            lock GetLock then
               {Dictionary.put ModuleMap {RURL.urlToKey Url} Mod}
            end
            thread
               Mod={LinkFunctor Url Func}
            end
         end

         proc {ModuleEnter UrlV Mod}
            {Trace '[Module] Enter: '#UrlV}
            Url={RURL.vsToUrl UrlV}
         in
            lock GetLock then
               {Dictionary.put ModuleMap {RURL.urlToKey Url} Mod}
            end
         end
      end

      fun {ModuleLoad ModName From}
         Url={ModNameToUrl ModName From unit}
      in
         {GetFunctor Url}
      end

   end

end
