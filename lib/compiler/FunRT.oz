local
   \insert RunTime
in
   functor prop once
   import
      System(printName)
      Core(nameToken variable)
      RunTimeLibrary
      Module(manager)
   export
      Literals
      Tokens
      Procs
   body
      fun {ApplyFunctor FileName F}
         ModMan = {New Module.manager init()}
      in
         {ModMan apply(url: FileName F $)}
      end

      Literals = LiteralValues
      Tokens = {Record.mapInd TokenValues
                fun {$ X Value}
                   {New Core.nameToken
                    init({System.printName Value} Value true)}
                end}
      Procs = {Record.mapInd
               {AdjoinAt RunTimeLibrary 'ApplyFunctor' ApplyFunctor}
               proc {$ X Value ?V} PrintName in
                  PrintName = {VirtualString.toAtom '`'#X#'`'}
                  V = {New Core.variable init(PrintName runTimeLibrary unit)}
                  {V valToSubst(Value)}
                  {V setUse(multiple)}
                  {V reg(~1)}
               end}
   end
end
