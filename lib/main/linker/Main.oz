%%%
%%% Authors:
%%%   Christian Schulte <schulte@ps.uni-sb.de>
%%%
%%% Contributor:
%%%   Leif Kornstaedt <kornstae@ps.uni-sb.de>
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

functor

require
   URL(make:                    UrlMake
       toVirtualStringExtended: UrlToVsExt
       resolve:                 UrlResolve)

   DefaultURL(nameToUrl: ModNameToUrl)

prepare

   fun {UrlToVs U}
      {UrlToVsExt U o(full:true)}
   end

   local
      V2A = VirtualString.toAtom
   in
      fun {UrlToAtom U}
         {V2A {UrlToVs U}}
      end
   end


   \insert 'Print.oz'

   fun {MakeExecHeader Path}
      '#!/bin/sh\nexec '#Path#' $0 "$@"\n'
   end
   DefaultExecPath = 'ozengine'
   DefaultExecHeader = {MakeExecHeader DefaultExecPath}

   proc {Swallow _}
      skip
   end


import
   Pickle(load saveWithHeader)
   Application(exit getArgs)
   System(printError showError)
   FD(record distinctD distribute sumC)
   Search(base)
   OS(system)
   Resolve(expand)

define

   IncludeSpecs = {NewCell nil}
   local
      fun {MakeInclude Key} include(Key) end
      fun {MakeExclude Key} exclude(Key) end
   in
      proc {AddInclude _ L} Old New in
         {Exchange IncludeSpecs Old New}
         {Append {Map L MakeInclude} Old New}
      end
      proc {AddExclude _ L} Old New in
         {Exchange IncludeSpecs Old New}
         {Append {Map L MakeExclude} Old New}
      end
   end
   ArgSpec = record(include(accumulate(AddInclude)
                            type: list(string) default: nil)
                    exclude(accumulate(AddExclude)
                            type: list(string) default: nil)
                    relative(rightmost type: bool default: true)

                    out(single char: &o type: string optional:true)

                    verbose(rightmost char: &v type: bool default: false)
                    quiet(char: &q alias: [verbose#false debug#false])
                    sequential(rightmost type: bool default: false)
                    executable(rightmost char: &x type: bool default: false)
                    execheader(single type: string
                               validate: alt(when(execpath false)))
                    execpath(single type: string
                             validate: alt(when(execheader false)))
                    compress(rightmost char: &z
                             type: int(min: 0 max: 9) default: 0)

                    debug(rightmost type:bool default:false)
                    usage(alias: help)
                    help(rightmost char: [&h &?] default: false))

   UrlExpand = Resolve.expand

   {Application.exit
    try
       Args = {Application.getArgs ArgSpec}

       if Args.help then
          {System.showError {Usage}}
          raise ar(exit) end
       end

       RootUrl = case Args.1 of [GetInFile] then
                   {UrlExpand {UrlResolve './' GetInFile}}
                 else
                    raise ar(inputFile) end
                 end

       Trace  = if Args.verbose then
                   System.showError
                else
                   Swallow
                end

       Debug  = if Args.debug then
                   System.showError
                else
                   Swallow
                end

       \insert 'Link.oz'

       OutFunctor = {Link RootUrl Args}

    in

       if {HasFeature Args out} then
          try
             {Pickle.saveWithHeader OutFunctor Args.out
              if Args.executable then
                 case {CondSelect Args execheader unit} of unit then
                    case {CondSelect Args execpath unit} of unit then
                       DefaultExecHeader
                    elseof S then {MakeExecHeader S}
                    end
                 elseof S then S
                 end
              else ''
              end
              Args.compress}
             if Args.executable then
                if {OS.system 'chmod +x '#Args.out}\=0 then
                   raise ar(saveExec) end
                end
             end
          catch _ then
             raise ar(save(Args.out)) end
          end
       end

       0

    catch ar(Ar) then
       case Ar
       of load(Us) then
          U|Ur={Reverse Us}
       in
          {System.showError
           'ERROR: Could not load functor: '#U#'.'}
          if Ur\=nil then
             {System.printError '       Included from: '}
             {ForAll Ur
              proc {$ A}
                 {System.printError A#'\n                      '}
              end}
          end
          1
       [] save(Url) then
          {System.showError
           'ERROR: Could not save functor to file: '#Url#'.'}
          1
       [] importImport(Conflict Url) then
          {System.showError
           'ERROR: Conflicting types for import modules.'}
          {Swallow Conflict} {Swallow Url}
          1
       [] importExport(Conflict EmbedUrl Url) then
          {System.showError
           'ERROR: Type mismatch between included modules.'}
          {Swallow Conflict} {Swallow Url} {Swallow EmbedUrl}
          1
       [] usage then
          {System.showError
           'ERROR: Illegal usage: see below\n'#{Usage}}
          1
       [] inputFile then
          {System.showError
           'No or multiple input file(s) given.\n'}
          0
       [] exit then
          0
       end
    [] error(ap(usage VS) ...) then
       {System.showError
        'Illegal usage: '#VS#'\n'#{Usage}}
       1
    end}

end


/*

{ForAll
 ['F'#functor
      import FD System G H
      export
         e:E
      define
         E=f(fd:FD system:System g:G h:H)
      end
  'G'#functor
      import FD System H
      export
         e:E
      define
         E=g(fd:FD system:System h:H)
      end
  'H'#functor
      import FD Property U at 'down/U.ozf'
      export E
      define
         E=h(fd:FD porperty:Property u:U)
      end
  'down/U'#functor
           import FD System V
           export E
           define
              E=u(fd:FD system:System v:V)
           end
  'down/V'#functor
           import System Tk U
           export E
           define
              E=v(tk:Tk system:System u:U)
           end
 ]
 proc {$ URL#F}
    {Pickle.save F URL#'.ozf'}
 end}

{ForAll
 ['A'#functor
      import FD B
      export
         e:E
      define
         E=a(fd:FD b:B)
      end
  'B'#functor
      import System C
      export
         e:E
      define
         E=b(system:System c:C)
      end
  'C'#functor
      import D
      export E
      define
         E=h(d:D)
      end
 ]
 proc {$ URL#F}
    {Pickle.save F URL#'.ozf'}
 end}


declare NF={Archive spec('in':     'F.ozf'
                         relative: true
                         exclude: )}

{Pickle.save NF 'NF.ozf'}

{Show NF}

*/
