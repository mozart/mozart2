functor prop once
import
   Debug            from 'x-oz://boot/Debug'
   Parser           from 'x-oz://boot/Parser'
   CompilerSupport  from 'x-oz://boot/CompilerSupport'
   Property
   System   %.{gcDo printName valueToVirtualString get property printError eq}
   Error   %.{formatExc formatPos formatLine formatGeneric format dispatch msg}
   ErrorRegistry   %.put
   FS   %.{include var subset value reflect isIn}
   FD   %.{int is less distinct distribute}
   Search   %.{SearchOne='SearchOne'}
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
body
   local
      ImAConstruction       = {NewName}
      ImAValueNode          = {NewName}
      ImAVariableOccurrence = {NewName}
      ImAToken              = {NewName}

      Misc      = {FunMisc.apply
                   c('CompilerSupport':       CompilerSupport)}
      Builtins  = {FunBuiltins.apply c}
      SA        = {FunSA.apply
                   c('FD':                    FD
                     'FS':                    FS
                     'Search':                Search
                     'System':                System
                     'Misc':                  Misc
                     'ImAConstruction':       ImAConstruction
                     'ImAValueNode':          ImAValueNode
                     'ImAVariableOccurrence': ImAVariableOccurrence
                     'ImAToken':              ImAToken
                     'Core':                  Core
                     'CompilerSupport':       CompilerSupport
                     'Builtins':              Builtins
                     'RunTime':               RT)}
      Code      = {FunCode.apply
                   c('System':                System
                     'Misc':                  Misc
                     'Builtins':              Builtins
                     'ImAVariableOccurrence': ImAVariableOccurrence
                     'Core':                  Core
                     'RunTime':               RT)}
      Core      = {FunCore.apply
                   c('System':                System
                     'Misc':                  Misc
                     'SA':                    SA
                     'CodeGen':               Code
                     'ImAConstruction':       ImAConstruction
                     'ImAValueNode':          ImAValueNode
                     'ImAVariableOccurrence': ImAVariableOccurrence
                     'ImAToken':              ImAToken)}
      RT        = {FunRT.apply
                   c('System':                System
                     'Core':                  Core
                     'RunTimeLibrary':        RunTimeLibrary)}
      Unnest    = {FunUnnest.apply
                   c('FD':                    FD
                     'Misc':                  Misc
                     'CompilerSupport':       CompilerSupport
                     'Core':                  Core
\ifndef OZM
                     'Gump':                  Gump
\endif
                     'RunTime':               RT)}
      Assembler = {FunAssembler.apply
                   c('System':                System
                     'CompilerSupport':       CompilerSupport
                     'Builtins':              Builtins
                     'RunTimeLibrary':        RunTimeLibrary)}
      CompilerF = {FunCompiler.apply
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
      Engine = CompilerF.compilerEngine
      ParseOzFile = CompilerF.parseOzFile
      ParseOzVirtualString = CompilerF.parseOzVirtualString
      GenericInterface = CompilerF.genericInterface
      QuietInterface = CompilerF.quietInterface
      EvalExpression = CompilerF.evalExpression
      VirtualStringToValue = CompilerF.virtualStringToValue
      Assemble = Assembler.doAssemble
   end
end
