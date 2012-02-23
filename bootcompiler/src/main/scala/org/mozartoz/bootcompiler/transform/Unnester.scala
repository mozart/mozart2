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
      statementWithTemp { temp =>
        transformStat {
          (temp === lhs) ~ (temp === rhs)
        }
      }

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

    case _:FunExpression | _:ThreadExpression | _:EscapedVariable |
        _:UnaryOp | _:BinaryOp | _:ShortCircuitBinaryOp =>
      throw new Exception(
          "illegal tree in Unnester.transformBindVarToExpression")
  }
}
