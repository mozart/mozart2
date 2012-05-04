package org.mozartoz.bootcompiler
package transform

import ast._
import symtab._

object PatternMatcher extends Transformer with TreeDSL {
  override def transformStat(statement: Statement) = statement match {
    case matchStat @ MatchStatement(value, clauses, elseStat)
    if clauses exists (_.hasGuard) =>
      transformStat {
        statementWithValIn[VarOrConst](value) { onceValue =>
          eliminateGuardsStat(matchStat, onceValue, clauses, elseStat)
        }
      }

    case _ =>
      super.transformStat(statement)
  }

  override def transformExpr(expression: Expression) = expression match {
    case matchExpr @ MatchExpression(value, clauses, elseExpr)
    if clauses exists (_.hasGuard) =>
      transformExpr {
        expressionWithValIn[VarOrConst](value) { onceValue =>
          eliminateGuardsExpr(matchExpr, onceValue, clauses, elseExpr)
        }
      }

    case _ =>
      super.transformExpr(expression)
  }

  private def eliminateGuardsStat(original: MatchStatement, value: VarOrConst,
      clauses: List[MatchStatementClause],
      elseStat: Statement): Statement = {

    if (clauses.isEmpty) elseStat
    else {
      val (clausesNoGuard, clausesGuard) = clauses.span(!_.hasGuard)

      if (clausesGuard.isEmpty) {
        treeCopy.MatchStatement(original, value, clausesNoGuard, elseStat)
      } else {
        val newElseStat = {
          eliminateGuardsStat(original, value, clausesGuard.tail, elseStat)
        }

        val firstClause = clausesGuard.head
        val MatchStatementClause(pattern, Some(guard), body) = firstClause

        val newClause = treeCopy.MatchStatementClause(firstClause,
            pattern, None, IF (guard) THEN (body) ELSE (newElseStat))

        treeCopy.MatchStatement(original, value,
            clausesNoGuard :+ newClause, newElseStat)
      }
    }
  }

  private def eliminateGuardsExpr(original: MatchExpression, value: VarOrConst,
      clauses: List[MatchExpressionClause],
      elseExpr: Expression): Expression = {

    if (clauses.isEmpty) elseExpr
    else {
      val (clausesNoGuard, clausesGuard) = clauses.span(!_.hasGuard)

      if (clausesGuard.isEmpty) {
        treeCopy.MatchExpression(original, value, clausesNoGuard, elseExpr)
      } else {
        val newElseExpr = {
          eliminateGuardsExpr(original, value, clausesGuard.tail, elseExpr)
        }

        val firstClause = clausesGuard.head
        val MatchExpressionClause(pattern, Some(guard), body) = firstClause

        val newClause = treeCopy.MatchExpressionClause(firstClause,
            pattern, None, IF (guard) THEN (body) ELSE (newElseExpr))

        treeCopy.MatchExpression(original, value,
            clausesNoGuard :+ newClause, newElseExpr)
      }
    }
  }
}
