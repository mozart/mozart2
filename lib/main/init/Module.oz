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

   fun {IsNative Url}
      {HasFeature {CondSelect Url info info} 'native'}
   end

   NONE = {NewName}

   fun {NameOrUrlToUrl ModName UrlV}
      if UrlV==NONE then {ModNameToUrl ModName}
      else {UrlMake UrlV}
      end
   end

   Link  = {NewName}
   Apply = {NewName}

   proc {TraceOFF _ _} skip end

   class UnsitedBaseManager
      prop locking
      feat ModuleMap

      meth init
         self.ModuleMap = {Dictionary.new}
      end

      meth !Link(Url ?Module)
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

      meth !Apply(Url Func $)
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
                UnsitedBaseManager,Link({UrlResolve Url EmbedUrl} $)
             end}
      in
         {Func.apply IM}
      end

      meth Enter(Url Module)
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

      %%
      %% Methods that are usable
      %%

      meth link(name: ModName <= NONE
                url:  UrlV    <= NONE
                ?Module       <= _) = Message
         Url = {NameOrUrlToUrl ModName UrlV}
      in
         Module = UnsitedBaseManager,Link(Url $)
         if {Not {HasFeature Message 1}} then
            thread {Wait Module} end
         end
      end

      meth enter(name: ModName <= NONE
                 url:  UrlV    <= NONE
                 Module)
         Url = {NameOrUrlToUrl ModName UrlV}
      in
         UnsitedBaseManager,Enter(Url Module)
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

      class BaseManager from UnsitedBaseManager
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
            Module = UnsitedBaseManager,Apply(Url Func $)
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
            {self Apply(Url Fun $)}
         end

         meth systemResolve(Auth Url $)
            try
               {UrlResolve
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
                                      Last#FunctorExt}#Bool)|Prefix} end
                   else raise badUrl end end
                in
                   {Adjoin Url url(scheme:unit authority:unit
                                   path:rel(L2))}
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

         meth system(Url $)
            {self trace('system method' Url)}
            case {StringToAtom {CondSelect Url authority ""}}
            of boot then
               {self trace('boot module' Url)}
               try
                  case {CondSelect Url path unit}
                  of abs([Name#false]) then
                     %% drop the extension of any
                     {Boot.obtain true {String.token Name &. $ _}}
                  else
                     raise badUrl end
                  end
               catch system(foreign(dlOpen _) ...) then
                  raise system(module(notFound system {UrlToAtom Url})) end
               [] badUrl then
                  raise error(module(urlSyntax {UrlToAtom Url})) end
               end
            [] system then
               {self trace('system module' Url)}
               {self systemApply(system Url $)}
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
            {RM Link(Url $)}
         end

      end

   end

end
