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
end




















\insert 'init/RURL.oz'

declare
local
   Check = String.isPrefix
in
   fun {IsPrefix V1 V2}
      {Check {VirtualString.toString V1} {VirtualString.toString V2}}
   end
end

declare
%% Maps URLs to import
QualImpMap = {NewDictionary}
UnquImpMap = {NewDictionary}
FunctorMap = {NewDictionary}

proc {ProcessURLs URLs}
   case URLs of nil then skip
   [] URL|URLr then
      Key = {RURL.urlToKey URL}
      Fun = {Pickle.load Key}
      ArURLs NoArURLs
   in
      %% Store functor
      {Dictionary.put FunctorMap Key Fun}
      %% Compute and store URLs for import
      ImportURLs =
      {Record.mapInd Fun.'import'
       fun {$ ModName Info}
          {Module.getUrl ModName {CondSelect Info 'from' unit}}
       end}
      %% Resolve URLs
      ResImportURLs =
      {Record.map ImportUrl
       fun {$ IUrl}
          {RURL.resolve Url IUrl}
       end}
      {Dictionary.put ImportUrlMap Key ImportUrls}
      %% Partition imports
      {Record.partitionInd Fun.'import'
       fun {$ ModName _}
          {RURL.isAbsUrl ImportUrls.ModName}
       end
       ?ArUrls ?NoArUrls}

          AURL={RURL.resolve URL IURL}
       in

      {ProcessURLs
       {Record.foldLInd Fun.'import'
           case {RURL.isAbsUrl IURL} then URLs else
              Key={RURL.urlToKey AURL}
           in
              %% Functor for inclusion found
              case {Dictionary.member FunctorMap Key} then
                 URLs
              else
                 AURL|URLs
              end
           end
        end URLr}}
   end
end

{ProcessURLs [{RURL.vsToUrl './F.ozf'}]}

{Browse {Dictionary.toRecord map FunctorMap}}

{Application.syslet
 'ozar'
 functor $ prop once

 import
    Syslet.{args exit}
    Pickle.{load}
    Module.{link
            expand}

 body
    Args = Syslet.args

    {ProcessImports [{RURL.vsToUrl Args.'in'}]}

    try
       RunRet # CtrlRet = {Connection.take Syslet.args.ticket}
       RunStr CtrlStr
    in
       {Port.send RunRet  {Port.new RunStr}}
       {Port.send CtrlRet {Port.new CtrlStr}}

       %% The server for running procedures and functors
       thread
          {ForAll RunStr
           proc {$ What}
              {Port.send RunRet
               try
                  X = case {Procedure.is What} then {What}
                      elsecase {Functor.is What} then
                         {Module.link '' What}
                      end
               in
                  okay(X)
               catch E then
                  exception(E)
               end}
              end}
       end

       %% The server for control messages
       thread
          {ForAll CtrlStr
           proc {$ C}
              {Port.send CtrlRet
               okay(case C
                    of ping  then unit
                    [] close then {Syslet.exit 0} unit
                    end)}
           end}
       end

    catch _ then
       {Syslet.exit 1}
    end
 end

 single(verbose(type:bool default:false)
        threads(type:bool default:true)
        'in'(type:string)
        'out'(type:string)
        'prefix'(type:string default:""))
}


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
           import FD System Tk
           body skip
           end
 ]
 proc {$ URL#F}
    {Pickle.save F URL#'.ozf'}
 end}

*/
