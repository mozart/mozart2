fun {ComputeTests Argv}
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
   Tests1 = case Argv.ignores=="none" then Tests else
               TestTests = {String.tokens Argv.ignores &,}
            in
               {Filter Tests
                fun {$ T}
                   S1={Atom.toString {Label T}}
                in
                   {All TestTests
                    fun {$ S2}
                       {IsNotIn S2 S1}
                    end}
                end}
            end
   RunTests = {Filter Tests1
               fun {$ T}
                  {Some T.keys fun {$ K1}
                                  {Member K1 Keys}
                               end}
               end}
   local
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

      ModMan = {New Module.manager init}

   in
      fun {GetTest TD}
         TL = {Label TD}
         T  = {ModMan link(url:TD.url $)}.return
      in
         case {Dictionary.member TestDict TL} then skip
         else {Dictionary.put TestDict TL {FindTest TD.id T}}
         end
         {Dictionary.get TestDict TL}
      end
   end
in
   {Map RunTests
    fun {$ T}
       S={GetTest T}.1
    in
       {Adjoin
        {Adjoin o(script: S
                  repeat: 1
                 )
         {Debug.procedureCoord
          case {IsProcedure S} then S else S.1 end}}
        T}
    end}
end
