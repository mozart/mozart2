functor prop once
import
   Debug           at 'x-oz://boot/Debug'
   Parser          at 'x-oz://boot/Parser'
   CompilerSupport at 'x-oz://boot/CompilerSupport'
   Property
   System
   Error
   ErrorRegistry
   FS
   FD
   Module
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
      PrintName      = {FunPrintName.apply c}
      Builtins       = {FunBuiltins.apply c}
      StaticAnalysis = {FunStaticAnalysis.apply
                        c('CompilerSupport':       CompilerSupport
                          'FD':                    FD
                          'FS':                    FS
                          'System':                System
                          'Type':                  Type
                          'Core':                  Core
                          'Builtins':              Builtins
                          'RunTime':               RunTime)}
      CodeGen        = {FunCodeGen.apply
                        c('CompilerSupport':       CompilerSupport
                          'System':                System
                          'Builtins':              Builtins
                          'Core':                  Core
                          'RunTime':               RunTime)}
      Core           = {FunCore.apply
                        c('System':                System
                          'StaticAnalysis':        StaticAnalysis
                          'CodeGen':               CodeGen)}
      RunTime        = {FunRunTime.apply
                        c('Module':                Module
                          'RunTimeLibrary':        RunTimeLibrary
                          'Core':                  Core)}
      Unnester       = {FunUnnester.apply
                        c('CompilerSupport':       CompilerSupport
                          'FD':                    FD
\ifndef OZM
                          'Debug':                 Debug
                          'Gump':                  Gump
\endif
                          'PrintName':             PrintName
                          'Core':                  Core
                          'RunTime':               RunTime)}
      Assembler      = {FunAssembler.apply
                        c('System':                System
                          'CompilerSupport':       CompilerSupport
                          'Builtins':              Builtins
                          'RunTimeLibrary':        RunTimeLibrary)}
      Main           = {FunMain.apply
                        c('Debug':                 Debug
                          'Parser':                Parser
                          'CompilerSupport':       CompilerSupport
                          'Property':              Property
                          'System':                System
                          'Error':                 Error
                          'ErrorRegistry':         ErrorRegistry
                          'Type':                  Type
                          'PrintName':             PrintName
                          'Builtins':              Builtins
                          'Unnester':              Unnester
                          'Core':                  Core
                          'Assembler':             Assembler
                          'RunTime':               RunTime
\ifndef OZM
                          'Gump':                  Gump
                          'ProductionTemplates':   ProductionTemplates
\endif
                         )}
   in
      Engine = Main.engine
      ParseOzFile = Main.parseOzFile
      ParseOzVirtualString = Main.parseOzVirtualString
      GenericInterface = Main.genericInterface
      QuietInterface = Main.quietInterface
      EvalExpression = Main.evalExpression
      VirtualStringToValue = Main.virtualStringToValue
      Assemble = Main.assemble
   end
end
