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

    case call @ CallStatement(callable, args) =>
      val argsAndTheirTemps =
        for (arg <- callable :: args) yield arg match {
          case v:Variable => v -> v
          case _ => arg -> Variable(Symbol.newSynthetic())
        }

      val argsNeedingTempsAndTheirTemps =
        argsAndTheirTemps filter (x => x._1 ne x._2)

      val tempArgs = argsNeedingTempsAndTheirTemps map (_._2)

      if (tempArgs.isEmpty) super.transformStat(call)
      else {
        LOCAL (tempArgs:_*) IN {
          val computeTemps =
            for ((arg, temp) <- argsNeedingTempsAndTheirTemps)
              yield transformStat(temp === arg)

          val temps = argsAndTheirTemps map (_._2)
          val newCall = treeCopy.CallStatement(call, temps.head, temps.tail)

          CompoundStatement(computeTemps) ~ newCall
        }
      }

    case test @ IfStatement(cond, trueStat, falseStat) =>
      val newTrueStat = transformStat(trueStat)
      val newFalseStat = transformStat(falseStat)

      cond match {
        case v:Variable =>
          IF (v) THEN (newTrueStat) ELSE (newFalseStat)

        case _ =>
          statementWithTemp { temp =>
            transformStat(temp === cond) ~ {
              IF (temp) THEN (newTrueStat) ELSE (newFalseStat)
            }
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

    case CallExpression(callable, args) =>
      transformStat(treeCopy.CallStatement(
          rhs, callable, args :+ v))

    case IfExpression(cond, trueExpr, falseExpr) =>
      val statement = IF (cond) THEN (v === trueExpr) ELSE (v === falseExpr)
      transformStat(statement)

    case BindExpression(lhs2, rhs2) =>
      transformStat((v === lhs2) ~ (v === rhs2))

    case _:FunExpression | _:ThreadExpression | _:EscapedVariable |
        _:UnaryOp | _:BinaryOp | _:ShortCircuitBinaryOp |
        _:CreateAbstraction =>
      throw new Exception(
          "illegal tree in Unnester.transformBindVarToExpression")
  }
}
