%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
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

declare

local

   %%
   %% Mapping module names to URLs
   %%
   local
      local
         UrlDefaults = \insert '../url-defaults.oz'
      in
         FunExt     = UrlDefaults.'functor'
      end

      local
         Functors = \insert '../functor-defaults.oz'
         BaseUrl  = {URL.fromVs "x-oz://system/DUMMY"}
      in
         SystemModules = {List.toRecord map
                          {Map {Append Functors.volatile
                                {Append Functors.lib Functors.tools}}
                           fun {$ ModName}
                              ModName #
                              {URL.resolve BaseUrl
                               {URL.fromVs ModName}}
                           end}}
      end
   in

      fun {ModNameToUrl ModName}
         %% Maps module name to URL
         ModKey = {VirtualString.toAtom ModName}
      in
         if {HasFeature SystemModules ModKey} then
            SystemModules.ModKey
         else
            {URL.fromVs ModKey#FunExt}
         end
      end

   end

   %%
   %% Filtering of URLs
   %%

   local
      fun {AlwaysFalse Url}
         false
      end

      local
         fun {IsPath Url}
            {HasFeature Url path} andthen {Width Url}==1
         end
      in
         fun {IsRelativePath Url}
            {IsPath Url} andthen {Label Url.path}\=abs
         end
      end

      fun {IsSystemUrl Url}
         {CondSelect Url scheme ""}=="x-oz"
      end

      local
         fun {UrlToString Url}
            {VirtualString.toString {URL.toVs Url}}
         end
      in
         fun {NewPrefixFilter RawUrls}
            if RawUrls==nil then
               AlwaysFalse
            else
               Urls = {Map RawUrls
                       fun {$ Url}
                          {UrlToString {URL.fromVs Url}}
                       end}
            in
               fun {$ Url}
                  {Some Urls fun {$ UrlPre}
                                {List.isPrefix UrlPre {UrlToString Url}}
                             end}
               end
            end
         end
      end

   in

      fun {NewUrlFilter Spec}
         IsRel  = if {CondSelect Spec relative false} then
                     IsRelativePath
                  else
                     AlwaysFalse
                  end
         ToExcl = {NewPrefixFilter {CondSelect Spec exclude nil}}
         ToIncl = {NewPrefixFilter {CondSelect Spec include nil}}
      in
         fun {$ Url}
            {Show check({URL.toAtom Url} {IsRel Url})}
            if {IsSystemUrl Url} orelse {ToExcl Url} then false
            elseif {IsRel Url} orelse {ToIncl Url} then true
            else false
            end
         end
      end

   end




   %%
   %% First Step: Determine functors for both exclusion and inclusion
   %%

   local
      proc {DoFind Url ToInclude InclMap ExclMap FuncMap}
         {System.showInfo 'Finding: '#{URL.toAtom Url}}
         UrlKey = {URL.toAtom Url}
      in
         if {Dictionary.member InclMap UrlKey}
            orelse {Dictionary.member ExclMap UrlKey} then
            skip
         else
            if {ToInclude Url} then
               {System.showInfo 'Including: '#{URL.toAtom Url}}
               %% Load the functor
               Func  = {Pickle.load UrlKey}
               Embed
            in
               {Dictionary.put FuncMap UrlKey Func}
               {Dictionary.put InclMap UrlKey incl(embed:Embed url:Url)}
               Embed={Record.mapInd Func.'import'
                      fun {$ ModName Info}
                         EmbedUrl = if {HasFeature Info 'from'} then
                                       {URL.fromVs Info.'from'}
                                    else
                                       {ModNameToUrl ModName}
                                    end
                         FullUrl  = {URL.resolve Url EmbedUrl}
                         {Show o(embed:{URL.toAtom EmbedUrl}
                                 url:{URL.toAtom Url}
                                 full:{URL.toAtom FullUrl})}
                      in
                         {DoFind FullUrl ToInclude InclMap ExclMap FuncMap}
                         o(url:FullUrl key:{URL.toAtom FullUrl})
                      end}
            else
               {Dictionary.put ExclMap UrlKey Url}
            end
         end
      end

   in

      fun {Find RootUrl UrlFilter}
         InclMap = {Dictionary.new}
         ExclMap = {Dictionary.new}
         FuncMap = {Dictionary.new}
      in
         {DoFind RootUrl UrlFilter InclMap ExclMap FuncMap}

         o(include:  {Dictionary.toRecord incl InclMap}
           exclude:  {Dictionary.toRecord excl ExclMap}
           functors: {Dictionary.toRecord func FuncMap})
      end

   end


   %%
   %% Type checking
   %%

   local

      fun {CheckExpImp ExpType ImpType}
         %% no(TypeConflictDescription)
         ok
      end

      fun {CheckImpImp ImpType1 ImpType2}
         %% no(TypeConflictDescription)
         %% ok(CommonTyp)
         ok(ImpType1)
      end

   in

      fun {TypeCheck Info}
         %%
         %% Check for export -> import matches
         %% Collect external import types
         %%
         ExclTypes = {Dictionary.new}
         InclMap   = Info.include
         FuncMap   = Info.functors
      in
         {Record.forAllInd InclMap
          %% All modules that are included
          proc {$ UrlKey Spec}
             {Record.forAllInd Spec.embed
              %% All imported modules
              proc {$ ModName Imp}
                 EmbedKey = {URL.toAtom Imp.url} % Imp.key
                 ImpType  = FuncMap.UrlKey.'import'.ModName
              in
                 if {HasFeature InclMap EmbedKey} then
                    %% Typecheck what the module manager would normally do
                    ExpType = FuncMap.EmbedKey.'export'
                 in
                    case {CheckExpImp ExpType ImpType}
                    of ok then skip
                    [] no(Conflict) then
                       raise type(exportImport(Conflict)
                                  EmbedKey UrlKey)
                       end
                    end
                 else
                    %% Collect type
                    {Dictionary.put ExclTypes EmbedKey
                     (EmbedKey#ImpType)|
                     {Dictionary.condGet ExclTypes EmbedKey nil}}
                 end
              end}
          end}
         %%
         %% Check for import <-> import matches
         %%
         {ForAll {Dictionary.entries ExclTypes}
          proc {$ UrlKey#(T|Tr)}
             {Dictionary.put ExclTypes UrlKey
              if Tr==nil then
                 T.2
              else
                 {FoldL Tr
                  fun {$ CurType EmbedKey#Type}
                     case {CheckImpImp CurType Type}
                     of ok(Type)     then Type
                     [] no(Conflict) then
                        raise type(importImport(Conflict)
                                   EmbedKey)
                        end
                     end
                  end T.2}
              end}
          end}
         {Dictionary.toRecord types ExclTypes}
      end

   end


   %%
   %% Assemble new functor
   %%

   local

      fun {IntToVarName I}
         {VirtualString.toAtom 'V'#I}
      end

   in

      fun {Assemble RootUrl Info Types}
         %% Map URLs to integers
         local
            AllUrls   = {Append {Arity Info.exclude} {Arity Info.include}}
         in
            UrlToInt  = {List.toRecord urlToInt
                         {List.mapInd AllUrls fun {$ I U} U#I end}}
         end
         RootUrlKey = {URL.toAtom RootUrl}
      in
         %% Assemble
         local
            IMPORT =
            {List.toRecord ''
             {Map {Arity Info.exclude}
              fun {$ UrlKey}
                 NewModName = {IntToVarName UrlToInt.UrlKey}
              in
                 NewModName # {AdjoinAt Types.UrlKey 'from' UrlKey}
              end}}

            EXPORT =
            Info.functors.RootUrlKey.'export'

            BODY =
            local
               NoExcl     = {Width Info.exclude}
               NoIncl     = {Width Info.include}
               NoExclIncl = NoIncl + NoExcl

               RootNo     = UrlToInt.RootUrlKey

               InclTab = {List.toRecord ''
                          {Map {Record.toListInd Info.include}
                           fun {$ UrlKey#Spec}
                              (UrlToInt.UrlKey) #
                              {Record.mapInd Spec.embed
                               fun {$ ModName Imp}
                                  UrlToInt.{URL.toAtom Imp.url}
                               end}
                           end}}

               FuncTab = {List.toRecord ''
                          {Map {Record.toListInd Info.functors}
                           fun {$ UrlKey#Func}
                              (UrlToInt.UrlKey) # Func.'apply'
                           end}}
            in
               fun {$ IMPORT}
                  ModMap = {MakeTuple modmap NoExclIncl}
               in
                  %% Enter excluded modules
                  {For 1 NoExcl 1
                   proc {$ I}
                      ModMap.I=IMPORT.{IntToVarName I}
                   end}

                  %% Enter included modules
                  {For NoExcl+1 NoExclIncl 1
                   proc {$ I}
                      ModMap.I={ByNeed fun {$}
                                          {FuncTab.I
                                           {Record.map InclTab.I
                                            fun {$ I}
                                               ModMap.I
                                            end}}
                                       end}
                   end}
                  %% Fix export
                  ModMap.RootNo
               end
            end
         in
            {Functor.new IMPORT EXPORT BODY}
         end


      end
   end

in


   fun {Archive Spec}
      ToInclude = {NewUrlFilter Spec}
      RootUrl   = {URL.fromVs Spec.'in'}
      Info      = {Find RootUrl ToInclude}
      Types     = {TypeCheck Info}
   in
      {Assemble RootUrl Info Types}
   end

end


/*

{ForAll
 ['F'#functor
      import FD System G H
      export
         e:E
      body
         E=f(fd:FD system:System g:G h:H)
      end
  'G'#functor
      import FD System H
      export
         e:E
      body
         E=g(fd:FD system:System h:H)
      end
  'H'#functor
      import FD Property U from 'down/U.ozf'
      export E
      body
         E=h(fd:FD porperty:Property u:U)
      end
  'down/U'#functor
           import FD System V
           export E
           body
              E=u(fd:FD system:System v:V)
           end
  'down/V'#functor
           import System Tk U
           export E
           body
              E=v(tk:Tk system:System u:U)
           end
 ]
 proc {$ URL#F}
    {Pickle.save F URL#'.ozf'}
 end}

declare NF={Archive spec('in':     'F.ozf'
                         relative: true)}

{Pickle.save NF 'NF.ozf'}

{Show NF}

*/
