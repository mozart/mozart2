functor prop once
import
   Debug           at 'x-oz://boot/Debug'
   Parser          at 'x-oz://boot/Parser'
   CompilerSupport at 'x-oz://boot/CompilerSupport'
   Property
   System   %(gcDo printName valueToVirtualString get property printError eq)
   Error   %(formatExc formatPos formatLine formatGeneric format dispatch msg)
   ErrorRegistry   %(put)
   FS   %(include var subset value reflect isIn)
   FD   %(int is less distinct distribute)
   Module   %(manager)
   Type
\ifndef OZM
   Gump
   ProductionTemplates
\endif
   RunTimeLibrary
export
   Engine
   ParseOzFile
   ParseOzVirtualString
   GenericInterface
   QuietInterface
   EvalExpression
   VirtualStringToValue
   Assemble
define
   local
      Misc      = {FunMisc.apply
                   c('CompilerSupport':       CompilerSupport)}
      Builtins  = {FunBuiltins.apply c}
      SA        = {FunSA.apply
                   c('FD':                    FD
                     'FS':                    FS
                     'System':                System
                     'Type':                  Type
                     'Misc':                  Misc
                     'Core':                  Core
                     'CompilerSupport':       CompilerSupport
                     'Builtins':              Builtins
                     'RunTime':               RunTime)}
      CodeGen   = {FunCodeGen.apply
                   c('System':                System
                     'Misc':                  Misc
                     'Builtins':              Builtins
                     'Core':                  Core
                     'RunTime':               RunTime)}
      Core      = {FunCore.apply
                   c('System':                System
                     'Misc':                  Misc
                     'SA':                    SA
                     'CodeGen':               CodeGen)}
      RunTime   = {FunRunTime.apply
                   c('System':                System
                     'Core':                  Core
                     'RunTimeLibrary':        RunTimeLibrary
                     'Module':                Module)}
      Unnest    = {FunUnnest.apply
                   c('FD':                    FD
                     'Misc':                  Misc
                     'CompilerSupport':       CompilerSupport
                     'Core':                  Core
                     'Debug':                 Debug
\ifndef OZM
                     'Gump':                  Gump
\endif
                     'RunTime':               RunTime)}
      Assembler = {FunAssembler.apply
                   c('System':                System
                     'CompilerSupport':       CompilerSupport
                     'Builtins':              Builtins
                     'RunTimeLibrary':        RunTimeLibrary)}
      Compiler  = {FunCompiler.apply
                   c('System':                System
                     'Property':              Property
                     'Error':                 Error
                     'ErrorRegistry':         ErrorRegistry
                     'Debug':                 Debug
                     'Parser':                Parser
                     'Misc':                  Misc
                     'Core':                  Core
                     'Unnest':                Unnest
\ifndef OZM
                     'Gump':                  Gump
                     'ProductionTemplates':   ProductionTemplates
\endif
                     'Assembler':             Assembler)}
   in
      Engine = Compiler.compilerEngine
      ParseOzFile = Compiler.parseOzFile
      ParseOzVirtualString = Compiler.parseOzVirtualString
      GenericInterface = Compiler.genericInterface
      QuietInterface = Compiler.quietInterface
      EvalExpression = Compiler.evalExpression
      VirtualStringToValue = Compiler.virtualStringToValue
      Assemble = Compiler.assemble
   end
end
