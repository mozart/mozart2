proc
   %instantiate
   {$ IMPORTS}
   RegSet
   Emitter
   Continuations
   CodeStore
   \insert SP.env
   = IMPORTS.'SP'
   \insert Common.env
   = IMPORTS.'Common'
in
   \insert RegSet
   \insert CodeEmitter
   \insert CodeStore
   \insert CodeGen
end
