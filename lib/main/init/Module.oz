%%%
%%% Author:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local

   fun {IsNative Url}
      {HasFeature {CondSelect Url info info} 'native'}
   end

   NONE  = {NewName}
   LINK  = {NewName}
   APPLY = {NewName}
   ENTER = {NewName}

   proc {TraceOFF _ _}
      skip
   end

   class UnsitedBaseManager
      prop locking
      feat ModuleMap

      meth init
         self.ModuleMap = {Dictionary.new}
      end

      meth !LINK(Url ?Module)
         %% Return module from "Url"
         lock Key={UrlToAtom Url} ModMap=self.ModuleMap in
            if {Dictionary.member ModMap Key} then
               {self trace('link [found]' Url)}
               {Dictionary.get ModMap Key Module}
            else
               {self trace('link [lazy]' Url)}
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

      meth !APPLY(Url Func $)
         {self trace('apply' Url)}
         %% Applies a functor and returns a module
         IM={Record.mapInd Func.'import'
             fun {$ ModName Info}
                EmbedUrl = if {HasFeature Info 'from'} then
                              {UrlMake Info.'from'}
                           else
                              {ModNameToUrl ModName}
                           end
             in
                UnsitedBaseManager,LINK({UrlResolve Url EmbedUrl} $)
             end}
      in
         {Func.apply IM}
      end

      meth !ENTER(Url Module)
         {self trace('enter' Url)}
         %% Stores "Module" under "Url"
         lock Key={UrlToAtom Url} in
            if {Dictionary.member self.ModuleMap Key} then
               raise system(module(alreadyInstalled Key)) end
            else
               {Dictionary.put self.ModuleMap Key Module}
            end
         end
      end

   end

in

   functor NewModule

   import
      System OS Boot Property Resolve

   export
      root:    RM
      manager: Manager
      trace:   ApiTrace

   define

      fun {NameOrUrlToUrl ModName UrlV}
         {Resolve.expand
          if UrlV==NONE then {ModNameToUrl ModName}
          else {UrlMake UrlV}
          end}
      end

      class BaseManager
         from UnsitedBaseManager

         meth link(name: ModName <= NONE
                   url:  UrlV    <= NONE
                   ?Module       <= _) = Message
            Url = {NameOrUrlToUrl ModName UrlV}
         in
            Module = UnsitedBaseManager,LINK(Url $)
            if {Not {HasFeature Message 1}} then
               thread {Wait Module} end
            end
         end

         meth enter(name: ModName <= NONE
                    url:  UrlV    <= NONE
                    Module)
            Url = {NameOrUrlToUrl ModName UrlV}
         in
            UnsitedBaseManager,ENTER(Url Module)
         end

         meth apply(name: ModName <= NONE
                    url:  UrlV    <= NONE
                    Func
                    ?Module       <= _) = Message
            Url = if ModName==NONE andthen UrlV==NONE then
                     {UrlMake {OS.getCWD}#'/'}
                  else
                     {NameOrUrlToUrl ModName UrlV}
                  end
         in
            Module = UnsitedBaseManager,APPLY(Url Func $)
            if {Not {HasFeature Message 2}} then
               thread {Wait Module} end
            end
         end

      end

      proc {TraceON X1 X2}
         {System.printError 'Module manager: '#X1#' '#{UrlToVs X2}#'\n'}
      end

      Trace = {NewCell
               if {OS.getEnv 'OZ_TRACE_MODULE'}==false
               then TraceOFF else TraceON end}
      ApiTrace =
      trace(set:proc {$ B}
                   {Assign Trace if B then TraceON else TraceOFF end}
                end
            get:fun {$ B} {Access Trace}==TraceON end)

      PLATFORM = {Property.get 'platform.name'}

      class RootManager from BaseManager

         meth trace(M1 M2)
            {{Access Trace} M1 M2}
         end

         meth load(Url $)
            %% Takes a URL and returns a module
            %% check if URL is annotated as denoting a `native functor'
            if {IsNative Url} then
               %% if yes, use the Foreign loader
               {self Native(Url $)}
            else
               {self Pickle(Url Url $)}
            end
         end

         meth Native(Url $)
            {self trace('native module' Url)}
            %% note that this method will not attempt to
            %% localize. A derived class could redefine it
            %% to attempt localization.
            try
               {Resolve.native.native {UrlToVs Url}#'-'#PLATFORM}
            catch system(foreign(dlOpen _) ...) then
               raise system(module(notFound native {UrlToAtom Url})) end
            [] error(url(_ _) ...) then
               raise system(module(notFound native {UrlToAtom Url})) end
            end
         end

         meth Pickle(Url ResUrl $)
            Fun
         in
            try
               Fun={Resolve.pickle.load ResUrl}
            catch error(url(O _) ...) then
               raise system(module(notFound O {UrlToAtom Url})) end
            end
            {self APPLY(Url Fun $)}
         end

         meth systemResolve(Auth Url $)
            try
               {UrlResolve
                case Auth
                of system  then SystemHomeUrl
                [] contrib then ContribHomeUrl
                else raise badUrl end end
                case {CondSelect Url path nil}
                of (_|_)=L then
                   L1 = {Reverse L}
                   L2 =
                   case L1 of H|T then
                      if {Member &. H} then L
                      else {Reverse {VirtualString.toString
                                     H#FunctorExt}|T} end
                   else raise badUrl end end
                in
                   {Adjoin Url url(scheme    : unit
                                   authority : unit
                                   device    : unit
                                   absolute  : false
                                   path      : L2)}
                else raise badUrl end end}
            catch badUrl then
               raise error(module(urlSyntax {UrlToAtom Url})) end
            end
         end

         meth systemApply(Auth Url $)
            U = {self systemResolve(Auth Url $)}
         in
            if {IsNative U} then
               {self Native(U $)}
            else
               {self Pickle(Url U $)}
            end
         end

         meth GetSystemName(Url $)
            case {CondSelect Url path unit}
            of [Name] then
               %% drop the extension of any
               {String.token Name &. $ _}
            else
               raise error(module(urlSyntax {UrlToAtom Url})) end
            end
         end

         meth GetSystemBoot(Name $)
            {self trace('boot module' Name)}
            try
               {Boot.obtain true Name}
            catch system(foreign(dlOpen _) ...) then
               raise system(module(notFound system {UrlToAtom Name})) end
            end
         end

         meth system(Url $)
            {self trace('system method' Url)}
            case {StringToAtom {CondSelect Url authority ""}}
            of boot then
               {self GetSystemBoot({self GetSystemName(Url $)} $)}
            [] system then Name={self GetSystemName(Url $)} in
               {self trace('system module' Url)}
               if {IsNatSystemName Name} then
                  {self GetSystemBoot(Name $)}
               else
                  {self systemApply(system Url $)}
               end
            [] contrib then
               {self trace('contrib module' Url)}
               {self systemApply(contrib Url $)}
            else
               raise error(module(urlSyntax {UrlToAtom Url})) end
            end
         end

      end

      RM = {New RootManager init}

      class Manager
         from RootManager
         prop sited

         meth system(Url $)
            {RM LINK(Url $)}
         end

      end

   end

end
