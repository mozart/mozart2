fun
\ifdef NEWCOMPILER
   instantiate
\endif
   {$ IMPORT}
   \insert 'SP.env'
   = IMPORT.'SP'
   \insert 'Common.env'
   = _
in
   ImAConstruction       = {NewName}
   ImAValueNode          = {NewName}
   ImAVariableOccurrence = {NewName}
   ImAToken              = {NewName}
   \insert Misc
   \insert Builtins
   \insert Annotate
   local
      IMPORTS = {AdjoinAt IMPORT 'Common' \insert 'Common.env'
                }
   in
      {FunStat IMPORTS}
      {FunCode IMPORTS}
      {FunCore IMPORTS}
      {FunMisc IMPORTS}
      {FunEnd  IMPORTS}
   end
   local

      GetOPICompiler = {`Builtin` 'getOPICompiler' 1}

      Compiler = compiler(compilerClass: CompilerClass
                          genericInterface: CompilerInterfaceGeneric
                          quietInterface: CompilerInterfaceQuiet
                          getOPICompiler: GetOPICompiler)
   in
      \insert 'Compiler.env'
   end
end
