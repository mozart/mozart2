local
   FunMisc      = {Pickle.load 'FunMisc.ozf'}
   FunBuiltins  = {Pickle.load 'FunBuiltins.ozf'}
   FunSA        = {Pickle.load 'FunSA.ozf'}
   FunCode      = {Pickle.load 'FunCode.ozf'}
   FunCore      = {Pickle.load 'FunCore.ozf'}
   FunUnnest    = {Pickle.load 'FunUnnest.ozf'}
   FunAssembler = {Pickle.load 'FunAssembler.ozf'}
   FunCompiler  = {Pickle.load 'FunCompiler.ozf'}
in
   functor prop once
   import
      Property
      System   %.{gcDo printName valueToVirtualString get property
               %  printError eq}
      Foreign   %.{pointer staticLoad}
      Error   %.{formatExc formatPos formatLine formatGeneric format
              %  dispatch msg}
      ErrorRegistry   %.put
      FS   %.{include var subset value reflect isIn}
      FD   %.{int is less distinct distribute}
      Search   %.{SearchOne='SearchOne'}
\ifndef OZM
      Gump
\endif
   export
      Engine
      CompilerClass   %--** deprecated
      ParseOzFile
      ParseOzVirtualString
      GenericInterface
      QuietInterface
      EvalExpression
      VirtualStringToValue
      Assemble
   body
      local
         ImAConstruction       = {NewName}
         ImAValueNode          = {NewName}
         ImAVariableOccurrence = {NewName}
         ImAToken              = {NewName}

         % for resolving cyclic dependencies:
         Core
         Core^core = _
         Core^flattenSequence = _
         Core^trueToken = _
         Core^falseToken = _

         Misc      = {FunMisc.apply c}
         Builtins  = {FunBuiltins.apply c}
         SA        = {FunSA.apply
                      c('FD':                    FD
                        'FS':                    FS
                        'Search':                Search
                        'Foreign':               Foreign
                        'System':                System
                        'Misc':                  Misc
                        'ImAConstruction':       ImAConstruction
                        'ImAValueNode':          ImAValueNode
                        'ImAVariableOccurrence': ImAVariableOccurrence
                        'ImAToken':              ImAToken
                        'Core':                  Core.core
                        'TrueToken':             Core.trueToken
                        'FalseToken':            Core.falseToken
                        'GetBuiltinInfo':        Builtins.getBuiltinInfo)}
         Code      = {FunCode.apply
                      c('Foreign':               Foreign
                        'System':                System
                        'Misc':                  Misc
                        'ImAVariableOccurrence': ImAVariableOccurrence
                        'Core':                  Core.core
                        'GetBuiltinInfo':        Builtins.getBuiltinInfo)}
         Core      = {FunCore.apply
                      c('System':                System
                        'Misc':                  Misc
                        'SA':                    SA.sA
                        'CodeGen':               Code.codeGen
                        'ImAConstruction':       ImAConstruction
                        'ImAValueNode':          ImAValueNode
                        'ImAVariableOccurrence': ImAVariableOccurrence
                        'ImAToken':              ImAToken)}
         Unnest    = {FunUnnest.apply
                      c('FD':                    FD
                        'Misc':                  Misc
                        'FlattenSequence':       Core.flattenSequence
                        'Core':                  Core.core
                        'Gump':                  Gump)}
         Assembler = {FunAssembler.apply
                      c('System':                System
                        'Foreign':               Foreign
                        'GetBuiltinInfo':        Builtins.getBuiltinInfo)}
         CompilerF = {FunCompiler.apply
                      c('System':                System
                        'Property':              Property
                        'Error':                 Error
                        'ErrorRegistry':         ErrorRegistry
                        'Foreign':               Foreign
                        'Misc':                  Misc
                        'Core':                  Core.core
                        'JoinQueries':           Unnest.joinQueries
                        'MakeExpressionQuery':   Unnest.makeExpressionQuery
                        'UnnestQuery':           Unnest.unnestQuery
                        'Gump':                  Gump
                        'Assemble':              Assembler.assemble)}
      in
         Engine = CompilerF.compilerEngine
         CompilerClass = CompilerF.compilerEngine   %--** deprecated
         ParseOzFile = CompilerF.parseOzFile
         ParseOzVirtualString = CompilerF.parseOzVirtualString
         GenericInterface = CompilerF.genericInterface
         QuietInterface = CompilerF.quietInterface
         EvalExpression = CompilerF.evalExpression
         VirtualStringToValue = CompilerF.virtualStringToValue
         Assemble = Assembler.doAssemble
      end
   end
end
