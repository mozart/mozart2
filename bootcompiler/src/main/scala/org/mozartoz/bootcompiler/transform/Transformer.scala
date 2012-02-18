package org.mozartoz.bootcompiler
package transform

import ast._
import symtab._

abstract class Transformer extends (Program => Unit) {
  var abstraction: Abstraction = _

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
      CompoundStatement(stats map transformStat)

    case LocalStatement(declarations, statement) =>
      LocalStatement(declarations map transformDecl, transformStat(statement))

    case CallStatement(callable, args) =>
      CallStatement(transformExpr(callable), transformActualArgs(args))

    case IfStatement(condition, trueStatement, falseStatement) =>
      IfStatement(transformExpr(condition), transformStat(trueStatement),
          transformStat(falseStatement))

    case ThreadStatement(statement) =>
      ThreadStatement(transformStat(statement))

    case BindStatement(left, right) =>
      BindStatement(transformExpr(left), transformExpr(right))

    case SkipStatement() =>
      SkipStatement()
  }

  def transformExpr(expression: Expression): Expression = expression match {
    case StatAndExpression(statement, expression) =>
      StatAndExpression(transformStat(statement), transformExpr(expression))

    case LocalExpression(declarations, expression) =>
      LocalExpression(declarations map transformDecl, transformExpr(expression))

    // Complex expressions

    case ProcExpression(name, args, body, flags) =>
      ProcExpression(name, transformFormalArgs(args),
          transformStat(body), flags)

    case FunExpression(name, args, body, flags) =>
      FunExpression(name, transformFormalArgs(args),
          transformExpr(body), flags)

    case CallExpression(callable, args) =>
      CallExpression(transformExpr(callable), transformActualArgs(args))

    case IfExpression(condition, trueExpression, falseExpression) =>
      IfExpression(transformExpr(condition), transformExpr(trueExpression),
          transformExpr(falseExpression))

    case ThreadExpression(expression) =>
      ThreadExpression(transformExpr(expression))

    case BindExpression(left, right) =>
      BindExpression(transformExpr(left), transformExpr(right))

    // Operations

    case UnaryOp(operator, operand) =>
      UnaryOp(operator, transformExpr(operand))

    case BinaryOp(left, operator, right) =>
      BinaryOp(transformExpr(left), operator, transformExpr(right))

    case ShortCircuitBinaryOp(left, operator, right) =>
      ShortCircuitBinaryOp(transformExpr(left), operator, transformExpr(right))

    // Trivial expressions

    case RawVariable(name) => expression
    case EscapedVariable(variable) => expression
    case UnboundExpression() => expression
    case IntLiteral(value) => expression
    case Atom(value) => expression
    case True() => expression
    case False() => expression
    case UnitVal() => expression

    // Synthetic expressions

    case AbstractionValue(abs) => expression
    case Variable(sym) => expression
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
