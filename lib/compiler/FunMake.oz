local
   FunMisc      = {Load 'FunMisc.ozc'}
   FunBuiltins  = {Load 'FunBuiltins.ozc'}
   FunSA        = {Load 'FunSA.ozc'}
   FunCode      = {Load 'FunCode.ozc'}
   FunCore      = {Load 'FunCore.ozc'}
   FunUnnest    = {Load 'FunUnnest.ozc'}
   FunAssembler = {Load 'FunAssembler.ozc'}
   FunCompiler  = {Load 'FunCompiler.ozc'}
in
   fun instantiate {$ IMPORT}
      \insert 'SP.env'
      = IMPORT.'SP'
      \insert 'CP.env'
      = IMPORT.'CP'
      \insert '../tools/Gump.env'
      = IMPORT.'Gump'
   in
      local
         ImAConstruction       = {NewName}
         ImAValueNode          = {NewName}
         ImAVariableOccurrence = {NewName}
         ImAToken              = {NewName}

         % for resolving cyclic dependencies:
         Core
         Core^core = _
         Core^flattenSequence = _

         Misc      = {FunMisc.apply c}
         Builtins  = {FunBuiltins.apply c}
         SA        = {FunSA.apply
                      c('SP':                    IMPORT.'SP'
                        'CP':                    IMPORT.'CP'
                        'Misc':                  Misc
                        'ImAConstruction':       ImAConstruction
                        'ImAValueNode':          ImAValueNode
                        'ImAVariableOccurrence': ImAVariableOccurrence
                        'ImAToken':              ImAToken
                        'Core':                  Core.core
                        'GetBuiltinInfo':        Builtins.getBuiltinInfo)}
         Code      = {FunCode.apply
                      c('SP':                    IMPORT.'SP'
                        'Misc':                  Misc
                        'ImAVariableOccurrence': ImAVariableOccurrence
                        'Core':                  Core.core
                        'GetBuiltinInfo':        Builtins.getBuiltinInfo)}
         Core      = {FunCore.apply
                      c('SP':                    IMPORT.'SP'
                        'Misc':                  Misc
                        'SA':                    SA.sA
                        'CodeGen':               Code.codeGen
                        'ImAConstruction':       ImAConstruction
                        'ImAValueNode':          ImAValueNode
                        'ImAVariableOccurrence': ImAVariableOccurrence
                        'ImAToken':              ImAToken)}
         Unnest    = {FunUnnest.apply
                      c('CP':                    IMPORT.'CP'
                        'Misc':                  Misc
                        'FlattenSequence':       Core.flattenSequence
                        'Core':                  Core.core
                        'Gump':                  Gump)}
         Assembler = {FunAssembler.apply
                      c('SP':                    IMPORT.'SP'
                        'GetBuiltinInfo':        Builtins.getBuiltinInfo)}
         CompilerF = {FunCompiler.apply
                      c('SP':                    IMPORT.'SP'
                        'Misc':                  Misc
                        'Core':                  Core.core
                        'JoinQueries':           Unnest.joinQueries
                        'MakeExpressionQuery':   Unnest.makeExpressionQuery
                        'UnnestQuery':           Unnest.unnestQuery
                        'Gump':                  Gump
                        'Assemble':              Assembler.assemble)}

         Compiler = compiler(compilerClass: CompilerF.compilerClass
                             genericInterface: CompilerF.genericInterface
                             quietInterface: CompilerF.quietInterface
                             evalExpression: CompilerF.evalExpression
                             virtualStringToValue:
                                CompilerF.virtualStringToValue)
      in
         \insert 'Compiler.env'
      end
   end
end
