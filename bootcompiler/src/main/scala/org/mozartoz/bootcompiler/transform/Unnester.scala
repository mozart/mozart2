package org.mozartoz.bootcompiler
package transform

import ast._
import symtab._

object Unnester extends Transformer with TreeDSL {
  override def transformStat(statement: Statement) = statement match {
    case bind @ ((v:Variable) === rhs) =>
      transformBindVarToExpression(bind, v, rhs)

    case bind @ (lhs === (v:Variable)) =>
      transformBindVarToExpression(bind, v, lhs)

    case lhs === rhs =>
      val tempSymbol = Symbol.newSynthetic()

      val bindLhs = tempSymbol === lhs
      val bindRhs = tempSymbol === rhs

      transformStat(bindLhs ~ bindRhs)

    case _ =>
      super.transformStat(statement)
  }

  def transformBindVarToExpression(bind: BindStatement,
      v: Variable, rhs: Expression) = rhs match {

    case _:Variable | _:Constant | _:ProcExpression =>
      v === transformExpr(rhs)

    case UnboundExpression() =>
      treeCopy.SkipStatement(v)

    case StatAndExpression(stat, expr) =>
      transformStat(stat ~ (v === expr))

    case LocalExpression(decls, expr) =>
      transformStat(treeCopy.LocalStatement(rhs, decls, v === expr))

    case CallExpression(callable, ActualArgs(args)) =>
      transformStat(treeCopy.CallStatement(
          rhs, callable, ActualArgs(args :+ v)))

    case IfExpression(cond, trueExpr, falseExpr) =>
      val statement = IF (cond) THEN (v === trueExpr) ELSE (v === falseExpr)
      transformStat(statement)

    case BindExpression(lhs2, rhs2) =>
      transformStat((v === lhs2) ~ (v === rhs2))

    case UnaryOp(op, v2:Variable) =>
      bind

    case UnaryOp(op, rhs2) =>
      val temp = Symbol.newSynthetic()
      transformStat((temp === rhs2) ~ (v === treeCopy.UnaryOp(rhs, op, temp)))

    case BinaryOp(v2:Variable, op, v3:Variable) =>
      bind

    case BinaryOp(v2:Variable, op, rhs3) =>
      val temp = Symbol.newSynthetic()
      transformStat(
          (temp === rhs3) ~ (v === treeCopy.BinaryOp(rhs, v2, op, temp)))

    case BinaryOp(lhs2, op, v3:Variable) =>
      val temp = Symbol.newSynthetic()
      transformStat(
          (temp === lhs2) ~ (v === treeCopy.BinaryOp(rhs, temp, op, v3)))

    case BinaryOp(lhs2, op, rhs3) =>
      val temp2 = Symbol.newSynthetic()
      val temp3 = Symbol.newSynthetic()

      val bindings = (temp2 === lhs2) ~ (temp3 === rhs3)
      transformStat(
          bindings ~ (v === treeCopy.BinaryOp(rhs, temp2, op, temp3)))

    case _:FunExpression | _:ThreadExpression | _:EscapedVariable =>
      throw new Exception(
          "illegal tree in Unnester.transformBindVarToExpression")
  }
}
