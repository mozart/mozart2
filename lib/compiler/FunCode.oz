functor prop once
import
   System.printName
   Misc.isBuiltin
   Builtins.getInfo
   ImAVariableOccurrence
   Core
   RunTime.{procs literals}
export
   % mixin classes for the abstract syntax:
   statement: CodeGenStatement
   typeOf: CodeGenTypeOf
   stepPoint: CodeGenStepPoint
   declaration: CodeGenDeclaration
   skipNode: CodeGenSkipNode
   equation: CodeGenEquation
   construction: CodeGenConstruction
   definition: CodeGenDefinition
   functionDefinition: CodeGenFunctionDefinition
   clauseBody: CodeGenClauseBody
   application: CodeGenApplication
   boolCase: CodeGenBoolCase
   boolClause: CodeGenBoolClause
   patternCase: CodeGenPatternCase
   patternClause: CodeGenPatternClause
   recordPattern: CodeGenRecordPattern
   equationPattern: CodeGenEquationPattern
   abstractElse: CodeGenAbstractElse
   elseNode: CodeGenElseNode
   noElse: CodeGenNoElse
   threadNode: CodeGenThreadNode
   tryNode: CodeGenTryNode
   lockNode: CodeGenLockNode
   classNode: CodeGenClassNode
   method: CodeGenMethod
   methodWithDesignator: CodeGenMethodWithDesignator
   methFormal: CodeGenMethFormal
   methFormalOptional: CodeGenMethFormalOptional
   methFormalWithDefault: CodeGenMethFormalWithDefault
   objectLockNode: CodeGenObjectLockNode
   getSelf: CodeGenGetSelf
   failNode: CodeGenFailNode
   ifNode: CodeGenIfNode
   choicesAndDisjunctions: CodeGenChoicesAndDisjunctions
   orNode: CodeGenOrNode
   disNode: CodeGenDisNode
   choiceNode: CodeGenChoiceNode
   clause: CodeGenClause
   valueNode: CodeGenValueNode
   atomNode: CodeGenAtomNode
   intNode: CodeGenIntNode
   floatNode: CodeGenFloatNode
   variable: CodeGenVariable
   variableOccurrence: CodeGenVariableOccurrence
   patternVariableOccurrence: CodeGenPatternVariableOccurrence

   % mixin classes for token representations:
   token: CodeGenToken
   nameToken: CodeGenNameToken
   builtinToken: CodeGenBuiltinToken
   procedureToken: CodeGenProcedureToken
body
   local
      \insert CodeEmitter
      \insert CodeStore
   in
      \insert CodeGen
   end
end
