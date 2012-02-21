package org.mozartoz.bootcompiler
package transform

import ast._
import symtab._

abstract class Transformer extends (Program => Unit) {
  var abstraction: Abstraction = _

  val treeCopy = new TreeCopier

  def apply(program: Program) {
    if (program.isRawCode)
      program.rawCode = transformStat(program.rawCode)
    else {
      for (abs <- program.abstractions) {
        abstraction = abs
        try {
          abs.body = transformStat(abs.body)
        } finally {
          abstraction = null
        }
      }
    }
  }

  def transformStat(statement: Statement): Statement = statement match {
    case CompoundStatement(stats) =>
      treeCopy.CompoundStatement(statement, stats map transformStat)

    case LocalStatement(declarations, statement) =>
      treeCopy.LocalStatement(statement, declarations map transformDecl,
          transformStat(statement))

    case CallStatement(callable, args) =>
      treeCopy.CallStatement(statement, transformExpr(callable),
          transformActualArgs(args))

    case IfStatement(condition, trueStatement, falseStatement) =>
      treeCopy.IfStatement(statement, transformExpr(condition),
          transformStat(trueStatement), transformStat(falseStatement))

    case ThreadStatement(statement) =>
      treeCopy.ThreadStatement(statement, transformStat(statement))

    case BindStatement(left, right) =>
      treeCopy.BindStatement(statement, transformExpr(left),
          transformExpr(right))

    case SkipStatement() =>
      treeCopy.SkipStatement(statement)
  }

  def transformExpr(expression: Expression): Expression = expression match {
    case StatAndExpression(statement, expression) =>
      treeCopy.StatAndExpression(statement, transformStat(statement),
          transformExpr(expression))

    case LocalExpression(declarations, expression) =>
      treeCopy.LocalExpression(expression, declarations map transformDecl,
          transformExpr(expression))

    // Complex expressions

    case ProcExpression(name, args, body, flags) =>
      treeCopy.ProcExpression(expression, name, transformFormalArgs(args),
          transformStat(body), flags)

    case FunExpression(name, args, body, flags) =>
      treeCopy.FunExpression(expression, name, transformFormalArgs(args),
          transformExpr(body), flags)

    case CallExpression(callable, args) =>
      treeCopy.CallExpression(expression, transformExpr(callable),
          transformActualArgs(args))

    case IfExpression(condition, trueExpression, falseExpression) =>
      treeCopy.IfExpression(expression, transformExpr(condition),
          transformExpr(trueExpression), transformExpr(falseExpression))

    case ThreadExpression(expression) =>
      treeCopy.ThreadExpression(expression, transformExpr(expression))

    case BindExpression(left, right) =>
      treeCopy.BindExpression(expression, transformExpr(left),
          transformExpr(right))

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

    case Variable(name) => expression
    case EscapedVariable(variable) => expression
    case UnboundExpression() => expression
    case IntLiteral(value) => expression
    case Atom(value) => expression
    case True() => expression
    case False() => expression
    case UnitVal() => expression
  }

  def transformDecl(declaration: Declaration): Declaration = declaration match {
    case stat:Statement => transformStat(stat)
    case _ => declaration
  }

  def transformFormalArgs(args: FormalArgs): FormalArgs =
    FormalArgs(args.args map transformFormalArg)

  def transformFormalArg(arg: FormalArg) = arg

  def transformActualArgs(args: ActualArgs): ActualArgs =
    ActualArgs(args.args map transformExpr)
}
