package org.mozartoz.bootcompiler
package transform

import ast._
import oz._
import symtab._

/** Base class for transformation phases */
abstract class Transformer extends (Program => Unit) {
  /** Program that is being transformed */
  var program: Program = _

  /** Abstraction that is being transformed (only if `!program.isRawCode`) */
  var abstraction: Abstraction = _

  /** Builtin manager of the program */
  def builtins = program.builtins

  protected def baseEnvironment(name: String): Expression = {
    if (program.isBaseEnvironment) {
      Variable(program.baseSymbols(name))
    } else if (name == "Base") {
      Variable(program.baseEnvSymbol)
    } else {
      CallExpression(Constant(OzBuiltin(builtins.binaryOpToBuiltin("."))),
          List(Variable(program.baseEnvSymbol), Constant(OzAtom(name))))
    }
  }

  /** Tree copier */
  val treeCopy = new TreeCopier

  /** Applies the transformation phase to a program */
  def apply(program: Program): Unit = {
    this.program = program
    try {
      apply()
    } finally {
      this.program = null
    }
  }

  /** Applies the transformation phase to the current `program` */
  protected def apply(): Unit = {
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
  protected def applyToAbstraction(): Unit = {
    abstraction.body = transformStat(abstraction.body)
  }

  /** Transforms a Statement */
  def transformStat(statement: Statement): Statement = (statement: @unchecked) match {
    case CompoundStatement(stats) =>
      treeCopy.CompoundStatement(statement, stats map transformStat)

    case RawLocalStatement(declarations, body) =>
      treeCopy.RawLocalStatement(statement, declarations map transformDecl,
          transformStat(body))

    case LocalStatement(declarations, body) =>
      treeCopy.LocalStatement(statement, declarations,
          transformStat(body))

    case CallStatement(callable, args) =>
      treeCopy.CallStatement(statement, transformExpr(callable),
          args map transformExpr)

    case IfStatement(condition, trueStatement, falseStatement) =>
      treeCopy.IfStatement(statement, transformExpr(condition),
          transformStat(trueStatement), transformStat(falseStatement))

    case MatchStatement(value, clauses, elseStatement) =>
      treeCopy.MatchStatement(statement, transformExpr(value),
          clauses map transformClauseStat, transformStat(elseStatement))

    case NoElseStatement() =>
      statement

    case ThreadStatement(body) =>
      treeCopy.ThreadStatement(statement, transformStat(body))

    case LockStatement(lock, body) =>
      treeCopy.LockStatement(statement, transformExpr(lock),
          transformStat(body))

    case LockObjectStatement(body) =>
      treeCopy.LockObjectStatement(statement, transformStat(body))

    case TryStatement(body, exceptionVar, catchBody) =>
      treeCopy.TryStatement(statement, transformStat(body),
          exceptionVar, transformStat(catchBody))

    case TryFinallyStatement(body, finallyBody) =>
      treeCopy.TryFinallyStatement(statement, transformStat(body),
          transformStat(finallyBody))

    case RaiseStatement(body) =>
      treeCopy.RaiseStatement(statement, transformExpr(body))

    case FailStatement() =>
      statement

    case BindStatement(left, right) =>
      treeCopy.BindStatement(statement, transformExpr(left),
          transformExpr(right))

    case BinaryOpStatement(left, operator, right) =>
      treeCopy.BinaryOpStatement(statement, transformExpr(left),
          operator, transformExpr(right))

    case DotAssignStatement(left, center, right) =>
      treeCopy.DotAssignStatement(statement, transformExpr(left),
          transformExpr(center), transformExpr(right))

    case SkipStatement() =>
      treeCopy.SkipStatement(statement)
  }

  /** Transforms an expression */
  def transformExpr(expression: Expression): Expression = (expression: @unchecked) match {
    case StatAndExpression(statement, expr) =>
      treeCopy.StatAndExpression(expression, transformStat(statement),
          transformExpr(expr))

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

    case NoElseExpression() =>
      expression

    case ThreadExpression(body) =>
      treeCopy.ThreadExpression(expression, transformExpr(body))

    case LockExpression(lock, body) =>
      treeCopy.LockExpression(expression, transformExpr(lock),
          transformExpr(body))

    case LockObjectExpression(body) =>
      treeCopy.LockObjectExpression(expression, transformExpr(body))

    case TryExpression(body, exceptionVar, catchBody) =>
      treeCopy.TryExpression(expression, transformExpr(body),
          exceptionVar, transformExpr(catchBody))

    case TryFinallyExpression(body, finallyBody) =>
      treeCopy.TryFinallyExpression(expression, transformExpr(body),
          transformStat(finallyBody))

    case RaiseExpression(body) =>
      treeCopy.RaiseExpression(expression, transformExpr(body))

    case BindExpression(left, right) =>
      treeCopy.BindExpression(expression, transformExpr(left),
          transformExpr(right))

    case DotAssignExpression(left, center, right) =>
      treeCopy.DotAssignExpression(expression, transformExpr(left),
          transformExpr(center), transformExpr(right))

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
    case Self() => expression

    // Constants

    case Constant(value) => expression

    // Records

    case AutoFeature() => expression

    case Record(label, fields) =>
      treeCopy.Record(expression, transformExpr(label),
          fields map transformRecordField)

    case OpenRecordPattern(label, fields) =>
      treeCopy.OpenRecordPattern(expression, transformExpr(label),
          fields map transformRecordField)

    case PatternConjunction(parts) =>
      treeCopy.PatternConjunction(expression, parts map transformExpr)

    // Classes

    case ClassExpression(name, parents, features, attributes,
        properties, methods) =>
      treeCopy.ClassExpression(expression, name, parents map transformExpr,
          features map transformFeatOrAttr, attributes map transformFeatOrAttr,
          properties map transformExpr, methods map transformMethodDef)

    // Synthetic-only

    case CreateAbstraction(body, globals) =>
      treeCopy.CreateAbstraction(expression, transformExpr(body),
          globals map transformExpr)
  }

  /** Transforms a declaration */
  def transformDecl(
      declaration: RawDeclaration): RawDeclaration = declaration match {
    case stat:Statement => transformStat(stat)
    case _ => declaration
  }

  /** Transforms a record field */
  private def transformRecordField(field: RecordField): RecordField =
    treeCopy.RecordField(field,
        transformExpr(field.feature), transformExpr(field.value))

  /** Transforms a clause of a match statement */
  def transformClauseStat(clause: MatchStatementClause) =
    treeCopy.MatchStatementClause(clause, transformExpr(clause.pattern),
        clause.guard map transformExpr, transformStat(clause.body))

  /** Transforms a clause of a match expression */
  def transformClauseExpr(clause: MatchExpressionClause) =
    treeCopy.MatchExpressionClause(clause, transformExpr(clause.pattern),
        clause.guard map transformExpr, transformExpr(clause.body))

  /** Transforms a feature or an attribute of a class */
  def transformFeatOrAttr(featOrAttr: FeatOrAttr) =
    treeCopy.FeatOrAttr(featOrAttr, transformExpr(featOrAttr.name),
        featOrAttr.value map transformExpr)

  /** Transforms a method definition */
  def transformMethodDef(method: MethodDef) = {
    val body = method.body match {
      case stat:Statement => transformStat(stat)
      case expr:Expression => transformExpr(expr)
    }

    treeCopy.MethodDef(method, method.header, method.messageVar, body)
  }
}
