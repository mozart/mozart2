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
      withSimplifiedHeaderAndArgs(callable, args) { (newCallable, newArgs) =>
        treeCopy.CallStatement(call, newCallable, newArgs)
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

    case matchStat @ MatchStatement(value, clauses, elseStat) =>
      val newClauses = transformClausesStat(clauses)
      val newElseStat = transformStat(elseStat)

      value match {
        case v:Variable =>
          treeCopy.MatchStatement(matchStat, v, newClauses, newElseStat)

        case _ =>
          statementWithTemp { temp =>
            transformStat(temp === value) ~ {
              treeCopy.MatchStatement(matchStat, temp, newClauses, newElseStat)
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

    case MatchExpression(value, clauses, elseExpr) =>
      val newClauses = {
        for (clause @ MatchExpressionClause(pattern, guard, body) <- clauses)
          yield treeCopy.MatchStatementClause(
              clause, pattern, guard, v === body)
      }

      val newElse = (v === elseExpr)

      transformStat(treeCopy.MatchStatement(rhs, value, newClauses, newElse))

    case BindExpression(lhs2, rhs2) =>
      transformStat((v === lhs2) ~ (v === rhs2))

    case record @ Record(label, fields) =>
      val args = fields.map(_.feature) ::: fields.map(_.value)

      withSimplifiedHeaderAndArgs(label, args) { (newLabel, newArgs) =>
        val (newFeatures, newValues) = newArgs.splitAt(fields.size)

        val newFields = for ((feature, value) <- newFeatures zip newValues)
          yield treeCopy.RecordField(value, feature, value)

        v === treeCopy.Record(record, newLabel, newFields)
      }

    case _:FunExpression | _:ThreadExpression | _:FunctorExpression |
        _:EscapedVariable | _:UnaryOp | _:BinaryOp | _:ShortCircuitBinaryOp |
        _:AutoFeature | _:CreateAbstraction =>
      throw new Exception(
          "illegal tree in Unnester.transformBindVarToExpression")
  }

  private def withSimplifiedHeaderAndArgs(header: Expression,
      args: List[Expression])(
      makeStatement: (Expression, List[Expression]) => Statement) = {

    withSimplifiedArgs(header :: args) { simplified =>
      makeStatement(simplified.head, simplified.tail)
    }
  }

  private def withSimplifiedArgs(args: List[Expression])(
      makeStatement: List[Expression] => Statement) = {
    val argsAndTheirTemps =
      for (arg <- args) yield arg match {
        case v:VarOrConst => v -> v
        case _ => arg -> Variable(Symbol.newSynthetic())
      }

    val argsNeedingTempsAndTheirTemps = for {
      argAndTemp @ (arg, temp) <- argsAndTheirTemps
      if arg ne temp
    } yield {
      (arg, temp.asInstanceOf[Variable])
    }

    val tempArgs = argsNeedingTempsAndTheirTemps map (_._2)

    if (tempArgs.isEmpty) makeStatement(args)
    else {
      LOCAL (tempArgs:_*) IN {
        val computeTemps =
          for ((arg, temp) <- argsNeedingTempsAndTheirTemps)
            yield transformStat(temp === arg)

        val temps = argsAndTheirTemps map (_._2)
        val newStatement = makeStatement(temps)

        CompoundStatement(computeTemps) ~ newStatement
      }
    }
  }
}
