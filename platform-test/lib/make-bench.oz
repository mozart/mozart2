%%%
%%% Authors:
%%%   Michael Mehl (mehl@dfki.de)
%%%
%%% Contributors:
%%%   Christian Schulte (schulte@dfki.de)
%%%   Tobias Mueller (tmueller@ps.uni-sb.de)
%%%
%%% Copyright:
%%%   Michael Mehl, 1998
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
   TimeMap = [&t#total &r#run &g#gc &c#copy
              &p#propagate &l#load &s#system]

   fun {AppendAll Xss}
      case Xss of nil then nil
      [] Xs|Xss then
         {Append Xs {AppendAll Xss}}
      end
   end

   local
      fun {IsPrefix Is Js}
         %% Is is prefix of Js
         case Is of nil then true
         [] I|Ir then
            case Js of nil then false
            [] J|Jr then
               I==J andthen {IsPrefix Ir Jr}
            end
         end
      end
   in
      fun {IsIn Is Js}
         %% Is is contained in Js
         case Js of nil then false
         [] J|Jr then
            {IsPrefix Is Js} orelse {IsIn Is Jr}
         end
      end
      fun {IsNotIn Is Js}
         case {IsIn Is Js} then false else true end
      end
   end

   local
      fun {MakeInit As I}
         case As of nil then nil
         [] A|Ar then A#I|{MakeInit Ar I}
         end
      end
   in
      fun {MakeRecordInit L As I}
         {List.toRecord L {MakeInit As I}}
      end
   end

   % Vector Arithmetic
   fun {VectorOp V1 V2 Op}
      {Record.zip V1 V2 fun {$ I J} {Op I J} end}
   end
   fun {VectorAdd V1 V2} {VectorOp V1 V2 Number.'+'} end

   % format float as fixnum: I.ff
   fun {Truncate F}
      I={Float.toInt F}
   in
      if {Int.toFloat I}>F then I-1 else I end
   end

   fun {Average Result}
      N = {Width Result}
      NF = {Int.toFloat N}
      Sum = {ForThread 1 {Width Result} 1
             fun {$ Tmp I}
                {VectorAdd Result.I Tmp}
             end
             {MakeRecordInit time {Arity Result.1} 0.0}}
   in
      {Record.map Sum fun {$ I} I/NF end}
   end

   fun {Sqr X} X*X end

   %% The Variance of n measurements Xi is computed as
   %% square root of the sum of (Xi-Xav)^2 divided by (n-1)
   %% normalized to the average Xav
   fun {Variance Av Result}
      N = {Width Result}
      NF = {Int.toFloat N-1}
      Sum={ForThread 1 N 1
           fun {$ Tmp I}
              Delta={VectorOp Result.I Av
                     fun {$ I J} {Sqr I-J} end}
           in
              {VectorAdd Delta Tmp}
           end
           {MakeRecordInit time {Arity Av} 0.0}}
   in
      {Record.mapInd Sum fun {$ F I}
                            if Av.F > 1.0 then
                               {Sqrt I/NF}/Av.F
                            else
                               0.0
                            end
                         end}
   end

   % print float
   fun {PF F}
      I={Truncate F}
      Mat = {Truncate 100.0*(F-{Int.toFloat I})}
   in
      I#'.'#Mat
   end

   fun {MakeTestEngine AllKeys AllTests}

      functor

      import
         Property
         System
         Debug    from 'x-oz://boot/Debug'
                     Module

      export
         Run

      body
         \insert 'engine.oz'
         \insert 'compute-tests.oz'

         fun {RunUntil T0 TMin Test}
            {Test _}
            local
               T1={Property.get time}
            in
               if T1.total - T0.total < TMin then
                  1+{RunUntil T0 TMin Test}
               else
                  1
               end
            end
         end

         fun {Run Argv}
            case Argv.usage orelse Argv.help then
               {System.printInfo \insert 'help-bench.oz'
               }
               0
            else
               Repeat = if Argv.repeat > 1 then Argv.repeat else 2 end
               ToRun={ComputeTests Argv}
               proc {PI V}
                  {System.printInfo V}
               end
               proc {PV V}
                  if Argv.verbose then {PI V} end
               end
               fun {DiffTime T0 T1 N}
                  NF={Int.toFloat N}
               in
                  {ForAll TimeMap
                   proc {$ C#F}
                      {PV ' '#[C]#':'#(T1.F-T0.F) div N#'ms'}
                   end}
                  {PV '\n'}
                  {Record.zip T0 T1
                   fun {$ I J}
                      if {IsInt J} then {Int.toFloat J-I}/NF
                      else 0.0 end end}
               end
               %% Start garbage collection thread, if requested
               if Argv.gc > 0 then
                  proc {GcLoop}
                     {System.gcDo} {Wait Argv.gc} {GcLoop}
                  end
               in
                  thread {GcLoop} end
               end
               %% Go for it

               {Property.put 'time.detailed' true}

               % StartTime = {Property.get time}
            in
               {ForAll ToRun
                proc {$ T}
                   Result={MakeTuple time Repeat}
                   proc {Test _}
                      {For 1 T.repeat 1
                       proc {$ _}
                          {Wait {DoTest T.script}}
                       end}
                   end
                in
                   {PI {Label T} # ': '}
                   local
                      {System.gcDo}
                      T0 = {Property.get time}
                      N={RunUntil T0 Argv.mintime Test}
                      % results of first run discarded (lazy loading)
                      %T1 = {Property.get time}
                      %Result.1={DiffTime T0 T1 N}
                      {PV '(#'#N#')\n'}
                   in
                      {For 1 Repeat 1
                       proc {$ I}
                          {System.gcDo}
                          T0={Property.get time}
                          {For 1 N 1 Test}
                          T1={Property.get time}
                       in
                          Result.I={DiffTime T0 T1 N*T.repeat}
                       end}
                   end
                   {PV '-------------------------\n'}
                   local
                      Av = {Average Result}
%                     {System.show Av}
                      Var={Variance Av Result}
%                     {System.show Var}
                   in
                      {ForAll TimeMap
                       proc {$ C#F}
                          {PI ' '#[C]#':'#{PF Av.F}#'ms'}
                          if Var.F>0.1 then
                             {PI ' ('#{Truncate Var.F*100.0}#'%)'}
                          end
                       end}
                      {PI '\n'}
                      {PV '=========================\n'}
                   end
                end}
               0
            end
         end
      end
   end

   TestOptions =
   single(
      help(type:bool default:false)
      usage(type:bool default:false)
      gc(type:int optional:false default:0)
      ignores(type:string optional:true default:"none")
      keys(type:string optional:true default:"all")
      tests(type:string optional:true default:"all")
      repeat(type:int optional:false default:5)
      mintime(type:int optional:false default:2000)
      verbose(type:bool optional:false default:false)
      )

in
   functor $

   import
      Application
      System
      Syslet.{Argv=args Exit=exit spec}
      Module
      Pickle

   body
      Syslet.spec = single(verbose(type:bool default:false))

      fun {X2V X}
         {System.valueToVirtualString X 100 100}
      end

      fun {GetAll S Ids Ls}
         LL = {Label S}
         LS = {Atom.toString LL}
         L  = case Ls==nil then LS else {Append Ls &_|LS} end
      in
         case {Width S}==1 andthen {IsList S.1} then
            {AppendAll
             {Map S.1 fun {$ S}
                         {GetAll S {Append Ids [LL]} L}
                      end}}
         else
            if {HasFeature S bench} then
               [L # {Append Ids [LL]} # {CondSelect S keys nil} # S.bench]
            else nil
            end
         end
      end

      ModMan = {New Module.manager init}

      Tests = {AppendAll
               {Map Argv.2 fun {$ C}
                              S = {ModMan link(url:C $)}.return
                           in
                              {Map {GetAll S nil nil}
                               fun {$ T#Id#K#R}
                                  L={String.toAtom T}
                               in
                                  L(id:Id
                                    keys:K
                                    url:{String.toAtom C}
                                    repeat:R
                                   )
                               end}
                           end}}

      Keys = {Sort {FoldL Tests
                    fun {$ Ks T}
                       {FoldL T.keys
                        fun {$ Ks K}
                           case {Member K Ks} then Ks else K|Ks end
                        end Ks}
                    end nil}
              Value.'<'}

      fun {ChunkUp Xs}
         Ys Zs
      in
         {List.takeDrop Xs 6 ?Ys ?Zs}
         Ys|case Zs==nil then nil else {ChunkUp Zs} end
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
         {Application.save
          './ozbench'

          functor $ prop once
          import Module Syslet
          body

             ModMan = {New Module.manager init}

             Syslet.spec = TestOptions

             {Syslet.exit {{ModMan apply(url:'' Engine $)}.run Syslet.args}}
          end}

         {Pickle.save
          Engine
          './te.ozf'}
      end

      {Exit 0}

   end

end
