functor prop once
import
   FD.{int is less distinct distribute}
   FS.{include var subset value reflect isIn}
   Search.{SearchOne='SearchOne'}
   System.{eq valueToVirtualString printName}
   Misc.{isBuiltin nameVariable}
   ImAConstruction
   ImAValueNode
   ImAVariableOccurrence
   ImAToken
   Core
   Builtins.getInfo
   CompilerSupport
export
   statement: SAStatement
   stepPoint: SAStepPoint
   declaration: SADeclaration
   skipNode: SASkipNode
   equation: SAEquation
   construction: SAConstruction
   definition: SADefinition
   functionDefinition: SAFunctionDefinition
   clauseBody: SAClauseBody
   application: SAApplication
   boolCase: SABoolCase
   boolClause: SABoolClause
   patternCase: SAPatternCase
   patternClause: SAPatternClause
   recordPattern: SARecordPattern
   equationPattern: SAEquationPattern
   abstractElse: SAAbstractElse
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
   failNode: SAFailNode
   ifNode: SAIfNode
   choicesAndDisjunctions: SAChoicesAndDisjunctions
   orNode: SAOrNode
   disNode: SADisNode
   choiceNode: SAChoiceNode
   clause: SAClause
   valueNode: SAValueNode
   atomNode: SAAtomNode
   intNode: SAIntNode
   floatNode: SAFloatNode
   variable: SAVariable
   variableOccurrence: SAVariableOccurrence
   token: SAToken
body
   local
      \insert POTypes
   in
      \insert StaticAnalysis
   end
end
