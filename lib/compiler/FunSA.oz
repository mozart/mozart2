functor prop once
import
   CompilerSupport(newNamedName newCopyableName isCopyableName
                   newPredicateRef newCopyablePredicateRef)
   FD(int is less distinct distribute)
   FS(include var subset value reflect isIn)
   System(eq valueToVirtualString printName)
   Type(is)
   Misc(isBuiltin nameVariable
        imAConstruction: ImAConstruction
        imAValueNode: ImAValueNode
        imAVariableOccurrence: ImAVariableOccurrence
        imAToken: ImAToken)
   Core
   Builtins(getInfo)
   RunTime(tokens)
export
   statement: SAStatement
   typeOf: SATypeOf
   stepPoint: SAStepPoint
   declaration: SADeclaration
   equation: SAEquation
   construction: SAConstruction
   definition: SADefinition
   application: SAApplication
   boolCase: SABoolCase
   boolClause: SABoolClause
   patternCase: SAPatternCase
   patternClause: SAPatternClause
   recordPattern: SARecordPattern
   equationPattern: SAEquationPattern
   elseNode: SAElseNode
   noElse: SANoElse
   threadNode: SAThreadNode
   tryNode: SATryNode
   lockNode: SALockNode
   classNode: SAClassNode
   method: SAMethod
   methodWithDesignator: SAMethodWithDesignator
   methFormal: SAMethFormal
   methFormalOptional: SAMethFormalOptional
   methFormalWithDefault: SAMethFormalWithDefault
   objectLockNode: SAObjectLockNode
   getSelf: SAGetSelf
   ifNode: SAIfNode
   choicesAndDisjunctions: SAChoicesAndDisjunctions
   clause: SAClause
   valueNode: SAValueNode
   variable: SAVariable
   variableOccurrence: SAVariableOccurrence
   token: SAToken
   nameToken: SANameToken
define
   local
      \insert POTypes
   in
      \insert StaticAnalysis
   end
end
