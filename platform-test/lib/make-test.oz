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
%%%    $MOZARTURL$
%%%
%%% See the file "LICENSE" or
%%%    $LICENSEURL$
%%% for information on usage and redistribution
%%% of this file, and for a DISCLAIMER OF ALL
%%% WARRANTIES.
%%%

local
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
   end

   fun {MakeTestEngine AllKeys AllTests}
      fun {$ IMPORT}
         \insert 'AP.env'
         = IMPORT.'AP'
         \insert 'OP.env'
         = IMPORT.'OP'
         \insert 'SP.env'
         = IMPORT.'SP'
         \insert 'CP.env'
         = IMPORT.'CP'

         fun {X2V X}
            {System.valueToVirtualString X 100 100}
         end

         \insert 'engine.oz'



      in

         fun {$ Argv}
            case Argv.usage orelse Argv.help then
               {System.printInfo \insert 'help-string.oz'
               }
               0
            else
               Keys =  case Argv.keys=="all" then AllKeys else
                          {Filter
                           {Map {String.tokens Argv.keys &,} String.toAtom}
                           fun {$ K}
                              {Member K AllKeys}
                           end}
                       end
               Tests = case Argv.tests=="all" then AllTests else
                          TestTests = {String.tokens Argv.tests &,}
                       in
                          {Filter AllTests
                           fun {$ T}
                              S1={Atom.toString {Label T}}
                           in
                              {Some TestTests
                               fun {$ S2}
                                  {IsIn S2 S1}
                               end}
                           end}
                       end
               RunTests = {Filter Tests
                           fun {$ T}
                              {Some T.keys fun {$ K1}
                                              {Member K1 Keys}
                                           end}
                           end}

               local
                  UrlDict  = {Dictionary.new}

                  fun {LoadTest URL}
                     case {Dictionary.member UrlDict URL} then skip
                     else {Dictionary.put UrlDict URL {{Load URL} IMPORT}}
                     end
                     {Dictionary.get UrlDict URL}
                  end

                  TestDict = {Dictionary.new}

                  fun {GetIt T|Tr I}
                     case {Label T}==I then T else {GetIt Tr I} end
                  end
                  fun {FindTest I|Is S}
                     {Label S}=I
                     case Is of nil then S
                     [] I|Ir then {FindTest Is {GetIt S.1 I}}
                     end
                  end
               in
                  fun {GetTest TD}
                     TL = {Label TD}
                     T  = {LoadTest TD.url}
                  in
                     case {Dictionary.member TestDict TL} then skip
                     else {Dictionary.put TestDict TL {FindTest TD.id T}}
                     end
                     {Dictionary.get TestDict TL}
                  end
               end

               ToRun = {Map RunTests
                        fun {$ T}
                           S={GetTest T}.1
                        in
                           {Adjoin
                            {Adjoin o(script: S
                                      repeat: 1)
                             {Debug.procedureCoord S.1}}
                            T}
                        end}

               proc {PV V}
                  case Argv.verbose then {System.printInfo V}
                  else skip end
               end


               proc {PT Ts}
                  case Argv.verbose then
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
                        Ys|case Zs==nil then nil else {ChunkUp Zs} end
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

               case Argv.do then
                  %% Start garbage collection thread, if requested
                  case Argv.gc > 0 then
                     proc {GcLoop}
                        {System.gcDo} {Wait Argv.gc} {GcLoop}
                     end
                  in
                     thread {GcLoop} end
                  else skip
                  end
                  %% Go for it

                  Results = {Map ToRun
                             fun {$ T}
                                {PV {Label T} # ': '}
                                Bs={Map {MakeList Argv.threads}
                                    fun {$ _}
                                       thread
                                          {ForThread 1 T.repeat 1
                                           fun {$ B _}
                                              B1={DoTest T.script}
                                           in
                                              {PV case B1 then '+' else '-' end}
                                              B1 andthen B
                                           end true}
                                       end
                                    end}
                                B={FoldL Bs And true}
                             in
                                {Wait B}
                                {PV '\n'}
                                {AdjoinAt T result B}
                             end}
                  Goofed = {Filter Results fun {$ T}
                                              {Not T.result}
                                           end}
               in

                  case Goofed==nil then
                     case Argv.verbose then
                        {System.showInfo \insert 'passed.oz'
                        }
                     else
                        {System.showInfo 'PASSED'}
                     end
                     0
                  else
                     case Argv.verbose then
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
   single(do(type:bool default:true)
          help(type:bool default:false)
          usage(type:bool default:false)
          verbose(type:bool default:false)
          gc(type:int optional:false default:0)
          keys(type:string optional:true default:"all")
          tests(type:string optional:true default:"all")
          threads(type:int optional:false default:1))

in
   {Application.exec
    './make-test'
    c('AP':eager 'OP':eager 'SP':eager 'CP':eager)
    fun {$ IMPORT}
       \insert 'AP.env'
       = IMPORT.'AP'
       \insert 'SP.env'
       = IMPORT.'SP'
       \insert 'OP.env'
       = IMPORT.'OP'

       fun {X2V X}
          {System.valueToVirtualString X 100 100}
       end

    in

       fun {$ Argv}
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
             else [L # {Append Ids [LL]} # {CondSelect S keys nil}]
             end
          end

          Tests = {AppendAll
                   {Map Argv.2 fun {$ C}
                                  S = {{Load C} IMPORT}
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
          case Argv.verbose then
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
             Engine =      {MakeTestEngine Keys Tests}
          in
             {Application.exec
              './oztest'
              c('AP':eager 'CP':eager 'SP':eager 'OP':eager)
              Engine
              TestOptions}

             {Component.save Engine './te.ozc' './te.ozc'}
          end

          0
       end

    end
    single(verbose(type:bool default:false))
   }

end
