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

%%
%% -in



%% -out
%% -prefix
%% -threads
%% -verbose

declare

local
   UrlDefaults = \insert '../url-defaults.oz'
in
   FunExt     = UrlDefaults.'functor'
   MozartHome = UrlDefaults.'home'
end

SystemModules = local
                   Functors = \insert '../functor-defaults.oz'
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

fun {IsSystemUrl Url}
   {CondSelect Url scheme ""}=="x-oz"
end

fun {IsPath Url}
   {HasFeature Url path} andthen {Width Url}==1
end

fun {IsRelativePath Url}
   {IsPath Url} andthen {Label Url.path}\=abs
end

fun {IsAbsolutePath Url}
   {Not {IsRelativePath Url}}
end

fun {ToInclude Url}
   %% Returns true, iff functor at Url is to be included
   {Not {IsSystemUrl Url}}
end


%%
%% First Step: Determine functors for both exclusion and inclusion
%%

declare
%% Map URL-keys to import information and possibly functors
FuncMap   = {Dictionary.new}
InclMap   = {Dictionary.new}
ExclMap   = {Dictionary.new}

proc {FindIncl Url}
   UrlKey = {URL.toAtom Url}
   {Show find(UrlKey)}
in
   if {Dictionary.member InclMap UrlKey}
      orelse {Dictionary.member ExclMap UrlKey} then
      skip
   else
      if {ToInclude Url} then
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
                in
                   {FindIncl {URL.resolve Url EmbedUrl}}
                   o(url:EmbedUrl key:{URL.toAtom EmbedUrl})
                end}
      else
         {Dictionary.put ExclMap UrlKey Url}
      end
   end
end

{FindIncl {URL.fromVs 'F.ozf'}}

{Browse o(incl: {Dictionary.toRecord g InclMap})}
{Browse o(incl: {Dictionary.toRecord g InclMap})}


%%
%% Type checking
%%

declare
ExclTypes = {Dictionary.new}

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

   proc {CheckTypes}
      %%
      %% Check for export -> import matches
      %% Collect external import types
      %%
      {ForAll {Dictionary.entries InclMap}
       %% All modules that are included
       proc {$ UrlKey#Spec}
          {Record.forAllInd Spec.embed
           %% All imported modules
           proc {$ ModName Imp}
              EmbedKey = Imp.key
              ImpType  = {Dictionary.get FuncMap UrlKey}.'import'.ModName
           in
              if {Dictionary.member InclMap EmbedKey} then
                 {Show check(UrlKey EmbedKey)}
                 %% Typecheck what the module manager would normally do
                 ExpType = {Dictionary.get FuncMap EmbedKey}.'export'
              in
                 case {CheckExpImp ExpType ImpType} then
                 of ok then skip
                 [] no(Conflict) then
                    raise type(exportImport(Conflict)
                               EmbedKey UrlKey)
                    end
                 end
              else
                 %% Collect type
                 {Dictionary.put ExclTypes EmbedKey
                  ImpType|{Dictionary.condGet ExclTypes EmbedKey nil}}
              end
           end}
       end}
      %%
      %% Check for import <-> import matches
      %%
      {ForAll {Dictionary.entries ExclTypes}
       proc {$ UrlKey#(T|Tr)}
          if Tr==nil then T else
             {Dictionary.put ExclTypes UrlKey
              {FoldL Tr
               fun {$ CurType EmbedKey#Type}
                  case {CheckImpImp CurType Type}
                  of ok(Type)     then Type
                  [] no(Conflict) then
                    raise type(importImport(Conflict)
                               EmbedKey)
                    end
                  end
               end T}}
          end
       end}
   end

end

{CheckTypes}

{
local
   Ctr = {New class $
                  attr n:0
                  prop final
                  meth init
                     n <- 0
                  end
                  meth get($)
                     n <- @n+1
                  end
               end
          init}
   fun {GenVarName}
      {VirtualString.toAtom 'V'#{Ctr get($)}}
   end
in
   fun {MakeImport}
      {List.toRecord 'import'
end










/*

{ForAll
 ['F'#functor
      import FD System G H
      body skip
      end
  'G'#functor
      import FD System H
      body skip
      end
  'H'#functor
      import FD System U from 'down/U.ozf'
      body skip
      end
  'down/U'#functor
           import FD System V
           body skip
           end
  'down/V'#functor
           import FD System Tk U
           body skip
           end
 ]
 proc {$ URL#F}
    {Pickle.save F URL#'.ozf'}
 end}


*/
