%%%
%%% Authors:
%%%   Christian Schulte (schulte@dfki.de)
%%%
%%% Contributors:
%%%   Tobias Mueller (tmueller@ps.uni-sb.de)
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
   fun {AppendAll Xss}
      {FoldR Xss Append nil}
   end

   fun {IsIn Is Js}
      %% Is is contained in Js
      case Js of nil then false
      [] J|Jr then
         {List.isPrefix Is Js} orelse {IsIn Is Jr}
      end
   end

   fun {IsNotIn Is Js}
      {Not {IsIn Is Js}}
   end

   fun {MakeTestEngine AllKeys AllTests}

      functor

      import
         Property
         System
         Debug at 'x-oz://boot/Debug'
         Module

      export
         Run

      define
         fun {X2V X}
            {Value.toVirtualString X 100 100}
         end


         \insert 'engine.oz'
         \insert 'compute-tests.oz'

         fun {Run Argv}
            if Argv.help then
               {System.printInfo \insert 'help-string.oz'
               }
               0
            else
               ToRun={ComputeTests Argv}
               proc {PV V}
                  if Argv.verbose then {System.printInfo V}
                  else skip end
               end


               proc {PT Ts}
                  if Argv.verbose then
                     {ForAll Ts
                      proc {$ T}
                         {System.printInfo
                          ({X2V {Label T}} # ':\n     file: ' #
                           {X2V T.file} # ':' #
                           {X2V T.line} # ')\n')}
                      end}
                  else
                     fun {ChunkUp Xs}
                        Ys Zs
                     in
                        {List.takeDrop Xs 3 ?Ys ?Zs}
                        Ys|if Zs==nil then nil else {ChunkUp Zs} end
                     end
                  in
                     {ForAll {ChunkUp Ts}
                      proc {$ Ts}
                         {System.printInfo '   '}
                         {ForAll Ts
                          proc {$ T}
                             {System.printInfo {X2V {Label T}} # ', '}
                          end}
                         {System.showInfo ''}
                      end}
                  end
               end

            in

               if Argv.do then
                  %% Start garbage collection thread, if requested
                  if Argv.gc > 0 then
                     proc {GcLoop}
                        {System.gcDo} {Delay Argv.gc} {GcLoop}
                     end
                  in
                     thread {GcLoop} end
                  else skip
                  end
                  %% Go for it

                  if Argv.time \= nil then
                     {Property.put 'time.detailed' true}
                  else skip
                  end

                  StartTime = {Property.get time}
                  Results = {Map ToRun
                             fun {$ T}
                                T0={Property.get time}
                                {PV {Label T} # ': '}
                                Bs={Map {MakeList Argv.threads}
                                    fun {$ _}
                                       thread
                                          {ForThread 1 T.repeat 1
                                           fun {$ B _}
                                              B1={DoTest T.script}
                                           in
                                              {PV if B1 then '+' else '-' end}
                                              B1 andthen B
                                           end true}
                                       end
                                    end}
                                B={FoldL Bs And true}
                             in
                                {Wait B}
                                if Argv.time \= nil then
                                   T1={Property.get time}
                                   proc {PT C#F}
                                      if {Member C Argv.time} then
                                         {PV ' '#[C]#':'#T1.F-T0.F#' ms'}
                                      else skip
                                      end
                                   end
                                in
                                   {PV ' ('}
                                   {ForAll
                                    [&r#run &g#gc &s#system &c#copy
                                     &p#propagate &l#load &t#total]
                                    PT}
                                   {PV ' )'}
                                else skip
                                end
                                {PV '\n'}
                                {AdjoinAt T result B}
                             end}
                  Goofed = {Filter Results fun {$ T}
                                              {Not T.result}
                                           end}
               in
                  {Wait Goofed}
                  if Argv.time \= nil then
                     T1={Property.get time}
                     proc {PT C#F}
                        if {Member C Argv.time} then
                           {PV ' '#[C]#':'#T1.F-StartTime.F#' ms'}
                        else skip
                        end
                     end
                  in
                     {PV 'Total time: '}
                     {ForAll
                      [&r#run &g#gc &s#system &c#copy
                       &p#propagate &l#load &t#total]
                      PT}
                     {PV '\n'}
                  else skip
                  end

                  if Goofed==nil then
                     if Argv.verbose then
                        {System.showInfo \insert 'passed.oz'
                        }
                     else
                        {System.showInfo 'PASSED'}
                     end
                     0
                  else
                     if Argv.verbose then
                        {System.showInfo \insert 'failed.oz'
                        }
                     else
                        {System.showInfo 'FAILED'}
                     end
                     {System.showInfo ''}
                     {System.showInfo 'The following test failed:'}
                     {PT Goofed}
                     1
                  end
               else
                  %% Only print tests to be performed
                  {System.showInfo 'TESTS FOUND:'}
                  {PT ToRun}
                  {System.showInfo ''}
                  0
               end
            end
         end

      end
   end

   TestOptions =
   record(do(rightmost type: bool default: true)
          help(rightmost char: [&h &?] type: bool default: false)
          usage(alias: help)
          verbose(rightmost char: &v type: bool default: false)
          quiet(char: &q alias: verbose#false)
          gc(rightmost type: int(min: 0) default: 0)
          ignores(multiple type: list(string) default: nil)
          keys(multiple type: list(string) default: nil)
          tests(multiple type: list(string) default: nil)
          time(single type: string default: "")
          threads(rightmost type: int(min: 1) default: 1))

in
   functor

   import
      System
      Application
      Module
      Pickle

   define

      Argv = {Application.getCmdArgs
              record(verbose(rightmost type: bool default: false))}

      fun {X2V X}
         {Value.toVirtualString X 100 100}
      end

      fun {GetAll S Ids Ls}
         LL = {Label S}
         LS = {Atom.toString LL}
         L  = if Ls==nil then LS else {Append Ls &_|LS} end
      in
         if {Width S}==1 andthen {IsList S.1} then
            {AppendAll
             {Map S.1 fun {$ S}
                         {GetAll S {Append Ids [LL]} L}
                      end}}
         else [L # {Append Ids [LL]} # {CondSelect S keys nil}]
         end
      end

      ModMan = {New Module.manager init}

      Tests = {AppendAll
               {Map Argv.1 fun {$ C}
                              S = {ModMan link(url:C $)}.return
                           in
                              {Map {GetAll S nil nil}
                               fun {$ T#Id#K}
                                  L={String.toAtom T}
                               in
                                  L(id:Id keys:K url:{String.toAtom C})
                               end}
                           end}}

      Keys = {Sort {FoldL Tests
                    fun {$ Ks T}
                       {FoldL T.keys
                        fun {$ Ks K}
                           if {Member K Ks} then Ks else K|Ks end
                        end Ks}
                    end nil}
              Value.'<'}

      fun {ChunkUp Xs}
         Ys Zs
      in
         {List.takeDrop Xs 6 ?Ys ?Zs}
         Ys|if Zs==nil then nil else {ChunkUp Zs} end
      end

   in
      if Argv.verbose then
         {System.showInfo 'TESTS FOUND:'}
         {ForAll Tests proc {$ T}
                          {System.showInfo
                           ({X2V {Label T}} # ':\n' #
                            '   keys:  ' # {X2V T.keys} # '\n')}
                       end}
         {System.showInfo '\n\nKEYS FOUND:'}
         {ForAll {ChunkUp Keys}
          proc {$ Ks}
             {System.printInfo '   '}
             {ForAll Ks
              proc {$ K}
                 {System.printInfo {X2V K} # ', '}
              end}
             {System.showInfo ''}
          end}
      end

      local
         Engine = {MakeTestEngine Keys Tests}
      in
         {Pickle.saveWithHeader
          functor
          import Module Application
          define

             ModMan = {New Module.manager init}

             Args = {Application.getCmdArgs TestOptions}

             {Application.exit {{ModMan apply(url:'' Engine $)}.run
                                Args}}
          end
          './oztest'

          '#!/bin/sh\nexec ozengine $0 "$@"\n'
          9}

         {Pickle.save
          Engine
          './te.ozf'}
      end

      {Application.exit 0}

   end

end
