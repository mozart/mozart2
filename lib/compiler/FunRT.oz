local
   \insert RunTime
in
   functor prop once
   import
      System.printName
      Core.{nameToken variable}
      RunTimeLibrary
   export
      Literals
      Tokens
      Procs
   body
      Literals = LiteralValues
      Tokens = {Record.mapInd TokenValues
                fun {$ X Value}
                   {New Core.nameToken
                    init({System.printName Value} Value true)}
                end}
      Procs = {Record.mapInd RunTimeLibrary
               proc {$ X Value ?V} PrintName in
                  PrintName = {VirtualString.toAtom '`'#X#'`'}
                  V = {New Core.variable init(PrintName runTimeLibrary unit)}
                  {V valToSubst(Value)}
                  {V setUse(multiple)}
                  {V reg(~1)}
               end}
   end
end
