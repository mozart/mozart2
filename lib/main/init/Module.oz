%%%
%%% Author:
%%%   Christian Schulte <schulte@dfki.de>
%%%
%%% Contributor:
%%%   Denys Duchier <duchier@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Denys Duchier, 1998
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

local

   BootUrl    = {URL.make "x-oz://boot/DUMMY"}
   SystemUrl  = {URL.make "x-oz://system/DUMMY"}
   ContribUrl = {URL.make "x-oz://contrib/DUMMY"}
   OzScheme  = BootUrl.scheme = SystemUrl.scheme

   local
      UrlDefaults = \insert '../../url-defaults.oz'
   in
      FunExt     = UrlDefaults.'functor'
      MozartHome = UrlDefaults.'home'
      ContribHome= UrlDefaults.'contrib'
      SystemHomeUrl  = {URL.toBase MozartHome}
      ContribHomeUrl = {URL.toBase ContribHome}
   end

   proc {Swallow _}
      skip
   end

   %%
   %% Register System names
   %%

   SystemModules = local
                      Functors = \insert '../../functor-defaults.oz'
                   in
                      {List.toRecord map
                       {Map {Append Functors.volatile
                             {Append Functors.lib Functors.tools}}
                        fun {$ ModName}
                           ModName #
                           {URL.resolve SystemUrl
                            {URL.make ModName}}
                        end}}
                   end

   fun {ModNameToUrl ModName}
      ModKey = {VirtualString.toAtom ModName}
   in
      if {HasFeature SystemModules ModKey} then
         SystemModules.ModKey
      else
         {URL.make ModKey#FunExt}
      end
   end

   fun {IsNative Url}
      {HasFeature {CondSelect Url info info} 'native'}
   end

   NONE = {NewName}

   fun {NameOrUrlToUrl ModName UrlV}
      if UrlV==NONE then {ModNameToUrl ModName}
      else {URL.make UrlV}
      end
   end

   Link  = {NewName}
   Apply = {NewName}

   proc {TraceOFF _ _} skip end

   class BaseManager
      prop locking
      feat ModuleMap

      meth init
         self.ModuleMap = {Dictionary.new}
      end

      meth !Link(Url ?Module)
         {self trace('link' Url)}
         %% Return module from "Url"
         lock Key={URL.toAtom Url} ModMap=self.ModuleMap in
            case {Dictionary.member ModMap Key} then
               {Dictionary.get ModMap Key Module}
            else
               TryModule
               = {ByNeed
                  fun {$}
                     if {CondSelect Url scheme unit}==OzScheme
                     then {self system(Url $)}
                     else {self load(  Url $)} end
                  end}
            in
               {Dictionary.put ModMap Key TryModule}
               Module = TryModule
            end
         end
      end

      meth !Apply(Url Func $)
         {self trace('apply' Url)}
         %% Applies a functor and returns a module
         IM={Record.mapInd Func.'import'
             fun {$ ModName Info}
                EmbedUrl = if {HasFeature Info 'from'} then
                              {URL.make Info.'from'}
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
         {self trace('enter' Url)}
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
      Pickle System OS Boot Foreign Property

   export
      root:    RM
      manager: Manager
      trace:   ApiTrace

   body

      proc {TraceON X1 X2}
         {System.printError 'Module manager: '#X1#' '#{URL.toVs X2}}
      end

      Trace = {NewCell
               case {OS.getEnv 'OZ_TRACE_MODULE'}==false
               then TraceOFF else TraceON end}
      ApiTrace =
      trace(set:proc {$ B}
                   {Assign Trace if B then TraceON else TraceOFF end}
                end
            get:fun {$ B} {Access Trace}==TraceON end)

      PLATFORM = case {Property.get 'platform'} of Name#Cpu
                 then Name#'-'#Cpu else 'unknown' end

      class RootManager from BaseManager

         meth trace(M1 M2)
            {{Access Trace} M1 M2}
         end

         meth load(Url $)
            %% Takes a URL and returns a module
            %% check if URL is annotated as denoting a `native functor'
            if {IsNative Url}
               %% if yes, use the Foreign loader
            then {self native(Url $)}
            else {self Apply(Url {Pickle.load {URL.toVs Url}} $)} end
         end

         meth native(Url $)
            {self trace('native module' Url)}
            {Foreign.load {URL.toVs Url}#'-'#PLATFORM}
         end

         meth systemResolve(Auth Url $)
            {URL.resolve
             case Auth
             of system  then SystemHomeUrl
             [] contrib then ContribHomeUrl
             else raise badUrl end end
             case {CondSelect Url path unit}
             of abs(L) then
                L1 = {Reverse L}
                L2 =
                case L1 of (Last#Bool)|Prefix then
                   if {Member &. Last} then L
                   else {Reverse ({VirtualString.toString
                                   Last#FunExt}#Bool)|Prefix} end
                else raise badUrl end end
             in
                {Adjoin Url url(scheme:unit authority:unit
                                path:rel(L2))}
             else raise badUrl end end}
         end

         meth systemApply(Auth Url $)
            U = {self systemResolve(Auth Url $)}
         in
            if {IsNative U}
            then {self native(U $)}
            else {self Apply(Url {Pickle.load U} $)} end
         end

         meth system(Url $)
            {self trace('system method' Url)}
            try
               case {StringToAtom {CondSelect Url authority ""}}
               of boot then
                  {self trace('boot module' Url)}
                  case {CondSelect Url path unit}
                  of abs([Name#false]) then
                     %% drop the extension of any
                     {Boot.manager {String.token Name &. $ _}}
                  else raise badUrl end end
               [] system then
                  {self trace('system module' Url)}
                  {self systemApply(system Url $)}
               [] contrib then
                  {self trace('contrib module' Url)}
                  {self systemApply(contrib Url $)}
               else raise badUrl end end
            catch error(url(load _) ...) then
               raise module(systemNotFound {URL.toAtom Url}) end
            [] error(system(unknownBootModule _) ...) then
               raise module(bootNotFound {URL.toAtom Url}) end
            [] badUrl then
               raise module(urlSyntax {URL.toAtom Url}) end
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
