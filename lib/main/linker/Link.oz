%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
%%%
%%% Copyright:
%%%   Christian Schulte, 1998
%%%   Leif Kornstaedt, 2001
%%%
%%% Last change:
%%%   $Date$ by $Author$
%%%   $Revision$
%%%
%%% This file is part of Mozart, an implementation of Oz 3:
%%%    http://www.mozart-oz.org
%%%
%%% See the file "LICENSE" or
%%%    http://www.mozart-oz.org/LICENSE.html
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

      fun {NewUrlFilter Args RootUrl}
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
                {Debug '   '#{Label S}#' '#S.1}
             end}
         end
      in
         fun {$ Url}
            if {IsNativeUrl Url} then false
            else
               try Str={UrlToString Url} in
                  {Debug '   '#Str}
                  {ForAll AllSpecs
                   proc {$ S}
                      if {List.isPrefix S.1 Str}
                      then
                         {Debug '      matches '#{Label S}#'("'#S.1#'")'}
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
   %% Determine functors for both exclusion and inclusion
   %%
   %% Result: o(include: Include exclude: Exclude functors: Functors)
   %% where
   %%    Include:
   %%       is a record mapping the URL of every included functor
   %%       to a simplified representation of its import.
   %%       This import is represented as a record mapping every
   %%       imported module name to its resolved URL (as an atom key
   %%       suitable for accessing Include, Exclude, and Functors).
   %%    Exclude:
   %%       is a record mapping the URL of every excluded functor
   %%       to its expected type.
   %%    Functors:
   %%       is a record mapping the URL of every included functor
   %%       to the functor itself (with its import stripped of its types).
   %%

   local
      %%
      %% Type checking procedures
      %%

      CheckExpImp = {Property.condGet 'ozl.checkExpImp'
                     fun {$ ExpType ImpType _}
                        %% Must return either:
                        %%    no(TypeConflictDescription)
                        %%    ok
                        ok
                     end}

      CheckImpImp = {Property.condGet 'ozl.checkImpImp'
                     fun {$ ImpType1 ImpType2}
                        %% Must return either:
                        %%    no(TypeConflictDescription)
                        %%    ok(IntersectionType)
                        ok(ImpType1)
                     end}

      proc {DoFind Url Importer ImpType ToInclude InclMap ExclMap FuncMap}
         UrlKey = {UrlToAtom Url}
      in
         try
            if {Dictionary.member InclMap UrlKey} then ExpType in
               %% Typecheck what the module manager would normally do
               ExpType = {Dictionary.get FuncMap UrlKey}.'export'
               case {CheckExpImp ExpType ImpType o(url: UrlKey)}
               of ok then skip
               [] no(Conflict) then
                  raise ar(exportImport(Conflict UrlKey Importer)) end
               end
            elseif {Dictionary.member ExclMap UrlKey} then
               %% Check for import <-> import matches
               case {CheckImpImp ImpType {Dictionary.get ExclMap UrlKey}}
               of ok(IntersectionType) then
                  {Dictionary.put ExclMap UrlKey IntersectionType}
               [] no(Conflict) then
                  raise ar(importImport(Conflict UrlKey)) end
               end
            elseif {ToInclude Url} then Func Embed in
               %% Load the functor
               Func = try
                         {Pickle.load UrlKey}
                      catch _ then
                         raise ar(load(nil)) end
                      end
               case ImpType of top then skip
               elsecase {CheckExpImp Func.'export' ImpType o(url: UrlKey)}
               of ok then skip
               [] no(Conflict) then
                  raise ar(exportImport(Conflict UrlKey Importer)) end
               end
               {Dictionary.put FuncMap UrlKey
                case ImpType of top then Func
                else
                   %% Strip the functor of its import types
                   %% (to make them subject to garbage collection)
                   {Functor.new
                    {Record.map Func.'import'
                     fun {$ Info} {Record.subtract Info type} end}
                    Func.'export' Func.apply}
                end}
               %% Not using Record.map produces garbage early:
               {Dictionary.put InclMap UrlKey Embed}
               Embed = {List.toRecord 'import'
                        {Map {Record.toListInd Func.'import'}
                         fun {$ ModName#Info}
                            EmbedUrl = if {HasFeature Info 'from'} then
                                          {UrlMake Info.'from'}
                                       else
                                          {ModNameToUrl ModName}
                                       end
                            FullUrl  = {UrlResolve Url EmbedUrl}
                         in
                            {DoFind FullUrl UrlKey {CondSelect Info type nil}
                             ToInclude InclMap ExclMap FuncMap}
                            ModName#{UrlToAtom FullUrl}
                         end}}
            else
               {Dictionary.put ExclMap UrlKey
                case ImpType of top then nil else ImpType end}
            end
         catch ar(load(Urls)) then
            raise ar(load(UrlKey|Urls)) end
         end
      end
   in
      fun {Find RootUrl UrlFilter}
         {Debug 'Acquiring functors ...'}
         InclMap = {Dictionary.new}
         ExclMap = {Dictionary.new}
         FuncMap = {Dictionary.new}
         {DoFind RootUrl unit top UrlFilter InclMap ExclMap FuncMap}
         Include = {Dictionary.toRecord incl InclMap}
         Exclude = {Dictionary.toRecord excl ExclMap}
         Functors = {Dictionary.toRecord func FuncMap}
      in
         if {IsAtom Include} then
            raise ar(nothingToLink) end
         end
         o(include: Include exclude: Exclude functors: Functors)
      end
   end

   %%
   %% Schedule functors for application
   %%
   %% Result: either acyclic(Urls) or cyclic(Urls)
   %% where Urls is a list of URLs specifying functor evaluation order.
   %%
   %% The order of URLs has the following properties:
   %%    Exclude functors come first;
   %%    then the included functors;
   %%    root functor comes last.
   %%

   local
      fun {DepthFirst RootKey Map}
         CurrentId = {NewCell 0}
         Stack = {NewCell nil}
         Done = {NewDictionary}
         Sorted = {NewCell nil}
         fun {GetCycle Key1|Keys Key}
            if Key1 == Key then
               {Assign Stack Keys}
               [Key1]
            else Key1|{GetCycle Keys Key}
            end
         end
         proc {Visit Key ?MinId} Id in
            Id = {Access CurrentId}
            {Assign CurrentId Id + 1}
            {Dictionary.put Done Key Id}
            {Assign Stack Key|{Access Stack}}
            MinId = {Record.foldL Map.Key
                     fun {$ MinId Key2}
                        if {HasFeature Map Key2} then
                           {Min case {Dictionary.condGet Done Key2 unit}
                                of unit then {Visit Key2}
                                elseof Id then Id
                                end MinId}
                        else MinId
                        end
                     end Id}
            if MinId == Id then
               {Dictionary.put Done Key {Width Map}}
               {Assign Sorted {GetCycle {Access Stack} Key}|{Access Sorted}}
            end
         end
      in
         _ = {Visit RootKey}
         {Reverse {Access Sorted}}
      end
   in
      fun {Schedule RootUrl Info Args}
         {Debug 'Scheduling ...'}
         RootKey = {UrlToAtom RootUrl}
         Sorted = {DepthFirst RootKey Info.include}
         Lab = if {All Sorted fun {$ Urls} Urls.2 == nil end} then acyclic
               else cyclic
               end
         AllUrls = {Append {Arity Info.exclude}
                    {Append {List.subtract {Flatten Sorted} RootKey}
                     [RootKey]}}
      in
         if Args.sequential then
            if Lab == cyclic then
               {Trace
                'Executing functor bodies concurrently '#
                'due to cyclic dependencies.'}
               {ForAll Sorted
                proc {$ Urls}
                   case Urls of [_] then skip
                   else {Trace 'Cyclic dependency:\n'#{CommaList Urls}}
                   end
                end}
            else
               {Trace 'Executing functor bodies sequentially.'}
            end
         end
         Lab(AllUrls)
      end
   end

   %%
   %% Assemble new functor
   %%

   local

      fun {IntToVarName I}
         {StringToAtom &V|{IntToString I}}
      end

      %% rewrite URL prefixes

      fun {RewriteString S Rules}
         case Rules of From#To|Rest then
            if {List.isPrefix From S} then
               To#{List.drop S {Length From}}
            else {RewriteString S Rest}
            end
         [] nil then S
         end
      end

      proc {RewriteFrom Url Rules ?NewUrl}
         NewUrl = {VirtualString.toAtom
                   {RewriteString {VirtualString.toString Url} Rules}}
         {Debug Url#'\n\t=> '#NewUrl#'\n'}
      end

   in

      fun {Assemble RootUrl Args Info Order}
         {Debug 'Assembling ...'}
         RootUrlKey = {UrlToAtom RootUrl}
         Rewrite    = if Args.relative then
                         {Append Args.rewrite
                          [{VirtualString.toString
                            {UrlToVs {UrlResolve RootUrl nil}}}#""]}
                      else Args.rewrite
                      end
         UrlToInt   = {List.toRecord urlToInt
                       {List.mapInd Order.1 fun {$ I A} A#I end}}
         IsSeq      = Args.sequential andthen {Label Order}==acyclic
      in
         %% Assemble
         local
            IMPORT =
            {List.toRecord ''
             {Map {Arity Info.exclude}
              fun {$ UrlKey}
                 NewModName = {IntToVarName UrlToInt.UrlKey}
              in
                 NewModName # info(type: Info.exclude.UrlKey
                                   'from': {RewriteFrom UrlKey Rewrite})
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
                                 {Record.mapInd Spec
                                  fun {$ ModName EmbedKey}
                                     UrlToInt.EmbedKey
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

   fun {Link RootUrl Args}
      ToInclude = {NewUrlFilter Args RootUrl}
      Info      = {Find RootUrl ToInclude}
      Order     = {Schedule RootUrl Info Args}
   in
      {Trace 'Include:\n'#{CommaList {Filter Order.1
                                      fun {$ Url}
                                         {HasFeature Info.include Url}
                                      end}}}
      {Trace 'Import:\n'#{CommaList {Arity Info.exclude}}}
      {Assemble RootUrl Args Info Order}
   end

end
