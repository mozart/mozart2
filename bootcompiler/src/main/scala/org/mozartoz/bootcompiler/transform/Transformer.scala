package org.mozartoz.bootcompiler
package transform

import ast._
import symtab._

/** Base class for transformation phases */
abstract class Transformer extends (Program => Unit) {
  /** Program that is being transformed */
  var program: Program = _

  /** Abstraction that is being transformed (only if `!program.isRawCode`) */
  var abstraction: Abstraction = _

  /** Builtin manager of the program */
  def builtins = program.builtins

  /** Tree copier */
  val treeCopy = new TreeCopier

  /** Applies the transformation phase to a program */
  def apply(program: Program) {
    this.program = program
    try {
      apply()
    } finally {
      this.program = null
    }
  }

  /** Applies the transformation phase to the current `program` */
  protected def apply() {
    if (program.isRawCode)
      program.rawCode = transformStat(program.rawCode)
    else {
      for (abs <- program.abstractions) {
        abstraction = abs
        try {
          applyToAbstraction()
        } finally {
          abstraction = null
        }
      }
    }
  }

  /** Applies the transformation phase to the current `abstraction` */
  protected def applyToAbstraction() {
    abstraction.body = transformStat(abstraction.body)
  }

  /** Transforms a Statement */
  def transformStat(statement: Statement): Statement = statement match {
    case CompoundStatement(stats) =>
      treeCopy.CompoundStatement(statement, stats map transformStat)

    case RawLocalStatement(declarations, statement) =>
      treeCopy.RawLocalStatement(statement, declarations map transformDecl,
          transformStat(statement))

    case LocalStatement(declarations, statement) =>
      treeCopy.LocalStatement(statement, declarations,
          transformStat(statement))

    case CallStatement(callable, args) =>
      treeCopy.CallStatement(statement, transformExpr(callable),
          args map transformExpr)

    case IfStatement(condition, trueStatement, falseStatement) =>
      treeCopy.IfStatement(statement, transformExpr(condition),
          transformStat(trueStatement), transformStat(falseStatement))

    case MatchStatement(value, clauses, elseStatement) =>
      treeCopy.MatchStatement(statement, transformExpr(value),
          clauses map transformClauseStat, transformStat(elseStatement))

    case ThreadStatement(statement) =>
      treeCopy.ThreadStatement(statement, transformStat(statement))

    case TryStatement(body, exceptionVar, catchBody) =>
      treeCopy.TryStatement(statement, transformStat(body),
          exceptionVar, transformStat(catchBody))

    case TryFinallyStatement(body, finallyBody) =>
      treeCopy.TryFinallyStatement(statement, transformStat(body),
          transformStat(finallyBody))

    case RaiseStatement(exception) =>
      treeCopy.RaiseStatement(statement, transformExpr(exception))

    case BindStatement(left, right) =>
      treeCopy.BindStatement(statement, transformExpr(left),
          transformExpr(right))

    case AssignStatement(left, right) =>
      treeCopy.AssignStatement(statement, transformExpr(left),
          transformExpr(right))

    case SkipStatement() =>
      treeCopy.SkipStatement(statement)
  }

  /** Transforms an expression */
  def transformExpr(expression: Expression): Expression = expression match {
    case StatAndExpression(statement, expression) =>
      treeCopy.StatAndExpression(statement, transformStat(statement),
          transformExpr(expression))

    case RawLocalExpression(declarations, expression) =>
      treeCopy.RawLocalExpression(expression, declarations map transformDecl,
          transformExpr(expression))

    case LocalExpression(declarations, expression) =>
      treeCopy.LocalExpression(expression, declarations,
          transformExpr(expression))

    // Complex expressions

    case ProcExpression(name, args, body, flags) =>
      treeCopy.ProcExpression(expression, name, args,
          transformStat(body), flags)

    case FunExpression(name, args, body, flags) =>
      treeCopy.FunExpression(expression, name, args,
          transformExpr(body), flags)

    case CallExpression(callable, args) =>
      treeCopy.CallExpression(expression, transformExpr(callable),
          args map transformExpr)

    case IfExpression(condition, trueExpression, falseExpression) =>
      treeCopy.IfExpression(expression, transformExpr(condition),
          transformExpr(trueExpression), transformExpr(falseExpression))

    case MatchExpression(value, clauses, elseExpression) =>
      treeCopy.MatchExpression(expression, transformExpr(value),
          clauses map transformClauseExpr, transformExpr(elseExpression))

    case ThreadExpression(expression) =>
      treeCopy.ThreadExpression(expression, transformExpr(expression))

    case TryExpression(body, exceptionVar, catchBody) =>
      treeCopy.TryExpression(expression, transformExpr(body),
          exceptionVar, transformExpr(catchBody))

    case TryFinallyExpression(body, finallyBody) =>
      treeCopy.TryFinallyExpression(expression, transformExpr(body),
          transformStat(finallyBody))

    case RaiseExpression(exception) =>
      treeCopy.RaiseExpression(expression, transformExpr(exception))

    case BindExpression(left, right) =>
      treeCopy.BindExpression(expression, transformExpr(left),
          transformExpr(right))

    case FunctorExpression(name, require, prepare, imports, define, exports) =>
      def transformDefine(stat: LocalStatementOrRaw) =
        transformStat(stat).asInstanceOf[LocalStatementOrRaw]

      treeCopy.FunctorExpression(expression, name,
          require, prepare map transformDefine,
          imports, define map transformDefine,
          exports)

    // Operations

    case UnaryOp(operator, operand) =>
      treeCopy.UnaryOp(expression, operator, transformExpr(operand))

    case BinaryOp(left, operator, right) =>
      treeCopy.BinaryOp(expression, transformExpr(left), operator,
          transformExpr(right))

    case ShortCircuitBinaryOp(left, operator, right) =>
      treeCopy.ShortCircuitBinaryOp(expression, transformExpr(left), operator,
          transformExpr(right))

    // Trivial expressions

    case RawVariable(name) => expression
    case Variable(symbol) => expression
    case EscapedVariable(variable) => expression
    case UnboundExpression() => expression
    case NestingMarker() => expression

    // Constants

    case Constant(value) => expression

    // Records

    case AutoFeature() => expression

    case Record(label, fields) =>
      def transformRecordField(field: RecordField): RecordField =
        treeCopy.RecordField(field,
            transformExpr(field.feature), transformExpr(field.value))

      treeCopy.Record(expression, transformExpr(label),
          fields map transformRecordField)

    // Synthetic-only

    case CreateAbstraction(arity, body, globals) =>
      treeCopy.CreateAbstraction(expression, transformExpr(arity),
          transformExpr(body), globals map transformExpr)
  }

  /** Transforms a declaration */
  def transformDecl(
      declaration: RawDeclaration): RawDeclaration = declaration match {
    case stat:Statement => transformStat(stat)
    case _ => declaration
  }

  /** Transforms a clause of a match statement */
  def transformClauseStat(clause: MatchStatementClause) =
    treeCopy.MatchStatementClause(clause, transformExpr(clause.pattern),
        clause.guard map transformExpr, transformStat(clause.body))

  /** Transforms a clause of a match expression */
  def transformClauseExpr(clause: MatchExpressionClause) =
    treeCopy.MatchExpressionClause(clause, transformExpr(clause.pattern),
        clause.guard map transformExpr, transformExpr(clause.body))
}
