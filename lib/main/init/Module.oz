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
%%%    http://mozart.ps.uni-sb.de
%%%
%%% See the file "LICENSE" or
%%%    http://mozart.ps.uni-sb.de/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

\ifdef NEWMODULE

local

   local
      BootUrl   = {URL.fromVs "x-oz://boot/DUMMY"}
      SystemUrl = {URL.fromVs "x-oz://system/DUMMY"}
   in
      OzScheme  = BootUrl.scheme = SystemUrl.scheme
      %% BootLoc   = BootUrl.netloc
      %% SystemLoc = SystemUrl.netloc
   end

  local
      UrlDefaults = \insert '../../url-defaults.oz'
   in
      FunExt     = UrlDefaults.'functor'
      MozartHome = UrlDefaults.'home'
   end

   proc {Swallow _}
      skip
   end

   %%
   %% Register System names
   %%

   SystemModules = local
                      Functors = \insert '../../functor-defaults.oz'
                      BaseUrl  = {URL.fromVs "x-oz://system/DUMMY"}
                   in
                      {List.toRecord map
                       {Map {Append Functors.volatile
                             {Append Functors.lib Functors.tools}}
                        fun {$ ModName}
                           ModName #
                           {URL.resolve BaseUrl
                            {URL.fromVs ModName}}
                        end}}
                   end

   fun {ModNameToUrl ModName}
      ModKey = {VirtualString.toAtom ModName}
   in
      if {HasFeature SystemModules ModKey} then
         SystemModules.ModKey
      else
         {URL.fromVs ModKey#FunExt}
      end
   end

   NONE = {NewName}

   fun {NameOrUrlToUrl ModName UrlV}
      if UrlV==NONE then {ModNameToUrl ModName}
      else {URL.fromVs UrlV}
      end
   end

   Link  = {NewName}
   Apply = {NewName}

   class BaseManager
      prop locking
      feat ModuleMap

      meth init
         self.ModuleMap = {Dictionary.new}
      end

      meth !Link(Url ?Module)
         {self trace(intLink({URL.toAtom Url}))}
         %% Return module from "Url"
         lock Key={URL.toAtom Url} ModMap=self.ModuleMap in
            case {Dictionary.member ModMap Key} then
               {Dictionary.get ModMap Key Module}
            else
               TryModule = {ByNeed
                            fun {$}
                               if {CondSelect Url scheme unit}==OzScheme then
                                  {self system(Url $)}
                               else
                                  {self load(Url $)}
                               end
                            end}
            in
               {Dictionary.put ModMap Key TryModule}
               Module = TryModule
            end
         end
      end

      meth !Apply(Url Func $)
         {self trace(intApply({URL.toAtom Url}))}
         %% Applies a functor and returns a module
         IM={Record.mapInd Func.'import'
             fun {$ ModName Info}
                EmbedUrl = if {HasFeature Info 'from'} then
                              {URL.fromVs Info.'from'}
                           else
                              {ModNameToUrl ModName}
                           end
             in
                BaseManager,Link({URL.resolve Url EmbedUrl} $)
             end}
      in
         {Func.apply IM}
      end

      meth Enter(Url Module)
         {self trace(intEnter({URL.toAtom Url}))}
         %% Stores "Module" under "Url"
         lock Key={URL.toAtom Url} in
            if {Dictionary.member self.ModuleMap Key} then
               raise module(alreadyInstalled Key) end
            else
               {Dictionary.put self.ModuleMap Key Module}
            end
         end
      end

      %%
      %% Methods that are usable
      %%

      meth link(name: ModName <= NONE
                url:  UrlV    <= NONE
                ?Module       <= _) = Message
         Url = {NameOrUrlToUrl ModName UrlV}
      in
         Module = BaseManager,Link(Url $)
         if {Not {HasFeature Message 1}} then {Wait Module} end
      end

      meth apply(name: ModName <= NONE
                 url:  UrlV    <= NONE
                 Func
                 ?Module       <= _) = Message
         Url = {NameOrUrlToUrl ModName UrlV}
      in
         Module = BaseManager,Apply(Url Func $)
         if {Not {HasFeature Message 2}} then {Wait Module} end
      end

      meth enter(name: ModName <= NONE
                 url:  UrlV    <= NONE
                 Module)
         Url = {NameOrUrlToUrl ModName UrlV}
      in
         BaseManager,Enter(Url Module)
      end

   end

in

   functor NewModule prop once

   import
      Pickle System OS Boot

   export
      root:    RM
      manager: Manager

   body

      Trace = case {OS.getEnv 'OZ_TRACE_MODULE'}==false then Swallow
              else
                 System.show
              end

      class RootManager from BaseManager

         meth trace(What)
            {Trace What}
         end

         meth load(Url $)
            %% Takes a URL and returns a module
            {self Apply(Url {Pickle.load {URL.toVs Url}} $)}
         end

         meth system(Url $)
            {self trace(systemOrBoot({URL.toAtom Url}))}
            %% Gets system or boot module
            try
               Netloc  = {StringToAtom Url.netloc}
               ModName = {String.token Url.path.1.1 &. $ _}
            in
               case Netloc
               of boot   then
                  {self trace(boot({URL.toAtom Url}))}
                  {Boot.manager ModName}
               [] system then
                  {self trace(system(ModName {URL.toAtom Url}))}
                  {self Apply(Url {Pickle.load
                                   MozartHome#ModName#FunExt} $)}
               end
            catch _ then
               raise module(systemNotFound {URL.toAtom Url}) end
            end
         end

      end

      RM = {New RootManager init}

      class Manager
         from RootManager

         meth system(Url $)
            {RM Link(Url $)}
         end

      end

   end

end

\else

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
      BootUrl   = {URL.fromVs "x-oz://boot//DUMMY"}
      SystemUrl = {URL.fromVs "x-oz://system//DUMMY"}
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
      case {VirtualString.is UorV} then {URL.fromVs UorV}
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
                  BaseUrl  = {URL.fromVs MozartUrl#"DUMMY"}
               in
                  {List.toRecord map
                   {Map {Append Functors.volatile
                         {Append Functors.lib Functors.tools}}
                    fun {$ ModName}
                       ModName #
                       {URL.resolve BaseUrl
                        {URL.fromVs ModName#FunExt}}
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
         elsecase From==unit andthen {HasFeature SystemMap ModName} then
            SystemMap.ModName
         else
            RelUrl = {ToUrl case From==unit then ModName#'.ozf'
                            else From
                            end}
         in
            case BaseUrl==unit then RelUrl else
               {URL.resolve BaseUrl RelUrl}
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
            UrlKey = {URL.toAtom Url}
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
            Url = {URL.fromVs UrlV}
         in
            lock GetLock then
               {Dictionary.put ModuleMap {URL.toAtom Url} Mod}
            end
            thread
               Mod={LinkFunctor Url Func}
            end
         end

         proc {ModuleEnter UrlV Mod}
            {Trace '[Module] Enter: '#UrlV}
            Url={URL.fromVs UrlV}
         in
            lock GetLock then
               {Dictionary.put ModuleMap {URL.toAtom Url} Mod}
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


\endif
