%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
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

local

   %%
   %% Filtering of URLs
   %%

   local

      fun {IsNativeUrl Url}
         {HasFeature {CondSelect Url info no} native}
      end

      fun {UrlToString Url}
         {VirtualString.toString {UrlToVs Url}}
      end

   in

      fun {NewUrlFilter Spec RootUrl}
         {Debug 'Root: '#{UrlToVs RootUrl}}
         BaseUrl = {UrlToString {UrlResolve RootUrl nil}}
         {Debug 'Base: '#{UrlToVs BaseUrl}}
         AllSpecs= {Map {Append {Access IncludeSpecs}
                         if Args.relative then
                            [include(BaseUrl) exclude("x-oz://")]
                         else
                            [exclude("x-oz://")]
                         end}
                    fun {$ Spec}
                       Lab = {Label Spec}
                       Str = Spec.1
                    in
                       Lab({UrlToString {UrlExpand {UrlMake Str}}})
                    end}
         if Args.debug then
            {Debug 'Include/Exclude Specs:'}
            {ForAll AllSpecs
             proc {$ S}
                {Debug '\t'#{Label S}#' '#S.1}
             end}
         end
      in
         fun {$ Url}
            if {IsNativeUrl Url} then false
            else
               try Str={UrlToString Url} in
                  {Debug 'IMPORT '#Str}
                  {ForAll AllSpecs
                   proc {$ S}
                      if {List.isPrefix S.1 Str}
                      then
                         {Debug 'MATCH '#{Label S}#' '#S.1}
                         raise {Label S} end
                      end
                   end}
                  false
               catch include then true
               []    exclude then false
               end
            end
         end
      end

   end




   %%
   %% First Step: Determine functors for both exclusion and inclusion
   %%

   local
      proc {DoFind Url ToInclude InclMap ExclMap FuncMap}
         UrlKey = {UrlToAtom Url}
      in
         try
            if {Dictionary.member InclMap UrlKey}
               orelse {Dictionary.member ExclMap UrlKey} then
               skip
            else
               if {ToInclude Url} then
                  %% Load the functor
                  Func Embed
               in
                  try
                     Func = {Pickle.load UrlKey}
                  catch _ then
                     raise ar(load(nil)) end
                  end
                  {Dictionary.put FuncMap UrlKey Func}
                  {Dictionary.put InclMap UrlKey incl(embed:Embed url:Url)}
                  Embed={Record.mapInd Func.'import'
                         fun {$ ModName Info}
                            EmbedUrl = if {HasFeature Info 'from'} then
                                          {UrlMake Info.'from'}
                                       else
                                          {ModNameToUrl ModName}
                                       end
                            FullUrl  = {UrlResolve Url EmbedUrl}
                         in
                            {DoFind FullUrl ToInclude InclMap ExclMap FuncMap}
                            o(url:FullUrl key:{UrlToAtom FullUrl})
                         end}
               else
                  {Dictionary.put ExclMap UrlKey Url}
               end
            end
         catch ar(load(Urls)) then
            raise ar(load(UrlKey|Urls)) end
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
                 EmbedKey = {UrlToAtom Imp.url} % Imp.key
                 ImpType  = FuncMap.UrlKey.'import'.ModName
              in
                 if {HasFeature InclMap EmbedKey} then
                    %% Typecheck what the module manager would normally do
                    ExpType = FuncMap.EmbedKey.'export'
                 in
                    case {CheckExpImp ExpType ImpType}
                    of ok then skip
                    [] no(Conflict) then
                       raise ar(exportImport(Conflict
                                             EmbedKey UrlKey))
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
                        raise ar(importImport(Conflict
                                              EmbedKey))
                        end
                     end
                  end T.2}
              end}
          end}
         {Dictionary.toRecord types ExclTypes}
      end

   end

   %%
   %% Schedule functors for application
   %%

   fun {Schedule RootUrl Info}
      %% Map URLs to integers
      %% Assumptions: Exclude functors come first.
      %%              Then included.
      %%              Root is last.
      RootKey = {UrlToAtom RootUrl}
      NoUrls  = {Width Info.exclude} + {Width Info.include}
      AllUrls = {Append {Arity Info.exclude} {Arity Info.include}}

      proc {Script UrlToInt}
         UrlToInt = {FD.record urlToInt AllUrls 1#NoUrls}
         %% Excluded functors go first
         {List.forAllInd {Arity Info.exclude}
          proc {$ I U}
             UrlToInt.U = I
          end}
         %% Root functor goes last
         UrlToInt.RootKey = NoUrls
         %% Now the real stuff comes
         {FD.distinct UrlToInt}
         {Record.forAllInd Info.include
          %% All modules that are included
          proc {$ UrlKey Spec}
             {Record.forAll Spec.embed
              %% All imported modules
              proc {$ Imp}
                 EmbedKey={UrlToAtom Imp.url}
              in
                 if {HasFeature Info.include EmbedKey} then
                    UrlToInt.EmbedKey <: UrlToInt.UrlKey
                 end
              end}
          end}
         {FD.distribute naive UrlToInt}
      end

   in

      case {Search.base.one Script}
      of nil then
         %% Naive fallback
         {Trace 'Scheduling: Due to cyclic dependencies using naive fallback'}
         cyclic({List.toRecord urllToInt
                 {List.mapInd {Append {List.subtract AllUrls RootKey}
                               [RootKey]}
                  fun {$ I A}
                     A#I
                  end}})
      [] [IntToUrl] then
         {Trace 'Scheduling:\n'#
          ({CommaList
            {Record.toList
             {List.toRecord ''
              {Map {Filter {Record.toListInd IntToUrl}
                    fun {$ UrlKey#_} {HasFeature Info.include UrlKey} end}
               fun {$ UrlKey#I}
                  I#UrlKey
               end}}}})}
         acyclic(IntToUrl)
      end

   end

   %%
   %% Assemble new functor
   %%

   local

      fun {IntToVarName I}
         {StringToAtom &V|{IntToString I}}
      end

      %% remove relative prefix

      NoRootPrefix =
      if Args.relative then
         fun {$ RootPrefix Key}
            Str = {Atom.toString Key}
         in
            if {List.isPrefix RootPrefix Str}
            then
               {String.toAtom {Append RootPrefix $ Str}}
            else
               Key
            end
         end
      else
         fun {$ _ Key} Key end
      end

   in

      fun {Assemble RootUrl BodiesSeq Info Types UrlToIntSpec}
         RootUrlKey = {UrlToAtom RootUrl}
         RootPrefix = {VirtualString.toString
                       {UrlToVs {UrlResolve RootUrl nil}}}
         UrlToInt   = UrlToIntSpec.1
         IsSeq      = BodiesSeq andthen {Label UrlToIntSpec}==acyclic
      in
         %% Assemble
         local
            IMPORT =
            {List.toRecord ''
             {Map {Arity Info.exclude}
              fun {$ UrlKey}
                 NewModName = {IntToVarName UrlToInt.UrlKey}
              in
                 NewModName # {AdjoinAt Types.UrlKey 'from'
                               {NoRootPrefix RootPrefix UrlKey}}
              end}}

            EXPORT =
            Info.functors.RootUrlKey.'export'

            local
               NoExcl     = {Width Info.exclude}
               NoIncl     = {Width Info.include}
               NoExclIncl = NoIncl + NoExcl

               InclTab    = {List.toRecord ''
                             {Map {Record.toListInd Info.include}
                              fun {$ UrlKey#Spec}
                                 (UrlToInt.UrlKey) #
                                 {Record.mapInd Spec.embed
                                  fun {$ ModName Imp}
                                     UrlToInt.{UrlToAtom Imp.url}
                                  end}
                              end}}

               FuncTab    = {List.toRecord ''
                             {Map {Record.toListInd Info.functors}
                              fun {$ UrlKey#Func}
                                 (UrlToInt.UrlKey) # Func.'apply'
                              end}}

               proc {FOR I J P}
                  if I>J then skip else {P I} {FOR I+1 J P} end
               end

               MAP = Record.map

               fun {MKAPPLY ModMap I}
                  ImpMap = {MAP InclTab.I fun {$ J} ModMap.J end}
               in
                  proc {$}
                     ModMap.I = {FuncTab.I ImpMap}
                  end
               end

               MAINAPPLY =
               if IsSeq then
                  {Trace 'Executing bodies sequentially.'}
                  proc {$ ModMap}
                     {FOR NoExcl+1 NoExclIncl-1
                      proc {$ I}
                         {{MKAPPLY ModMap I}}
                      end}
                  end
               else
                  proc {$ ModMap}
                     {FOR NoExcl+1 NoExclIncl-1
                      proc {$ I}
                         APPLY={MKAPPLY ModMap I}
                      in
                         thread {APPLY} end
                      end}
                  end
               end

            in
               fun {BODY IMPORT}
                  ModMap = {MakeTuple modmap NoExclIncl}
               in
                  %% Enter excluded modules
                  {FOR 1 NoExcl
                   proc {$ I}
                      ModMap.I=IMPORT.{IntToVarName I}
                   end}

                  %% Enter included modules
                  {MAINAPPLY ModMap}

                  %% Fix export
                  {{MKAPPLY ModMap NoExclIncl}}
                  ModMap.NoExclIncl
               end
            end
         in
            {Functor.new IMPORT EXPORT BODY}
         end


      end
   end

in


   fun {Link RootUrl Spec}
      ToInclude = {NewUrlFilter Spec RootUrl}
      Info      = {Find RootUrl ToInclude}

      {Trace 'Include:\n'#{CommaList {Arity Info.include}}}
      {Trace 'Import:\n'#{CommaList {Arity Info.exclude}}}

      Types     = {TypeCheck Info}
      UrlToInt  = {Schedule RootUrl Info}
   in

      {Assemble RootUrl Spec.sequential Info Types UrlToInt}

   end

end
