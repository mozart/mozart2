local
   FunMisc      = {Pickle.load 'FunMisc.ozf'}
   FunBuiltins  = {Pickle.load 'FunBuiltins.ozf'}
   FunSA        = {Pickle.load 'FunSA.ozf'}
   FunCodeGen   = {Pickle.load 'FunCodeGen.ozf'}
   FunCore      = {Pickle.load 'FunCore.ozf'}
   FunRunTime   = {Pickle.load 'FunRunTime.ozf'}
   FunUnnest    = {Pickle.load 'FunUnnest.ozf'}
   FunAssembler = {Pickle.load 'FunAssembler.ozf'}
   FunCompiler  = {Pickle.load 'FunCompiler.ozf'}
in
   \insert FunMain
end
