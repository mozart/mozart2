package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable.ListBuffer

import ast._
import oz._
import symtab._

object PatternMatcher extends Transformer with TreeDSL {
  override def transformStat(statement: Statement) = statement match {
    case matchStat @ MatchStatement(value, clauses, elseStat)
    if clauses exists (clause => containsVariable(clause.pattern)) =>
      val newCaptures = new ListBuffer[Variable]

      val newClauses = for {
        clause @ MatchStatementClause(pattern, guard, body) <- clauses
      } yield {
        val (newPattern, newGuard) = processVariablesInPattern(
            pattern, guard, newCaptures)
        treeCopy.MatchStatementClause(clause, newPattern, newGuard, body)
      }

      transformStat {
        LOCAL (newCaptures.toSeq:_*) IN {
          treeCopy.MatchStatement(matchStat, value, newClauses, elseStat)
        }
      }

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
    case matchStat @ MatchExpression(value, clauses, elseExpr)
    if clauses exists (clause => containsVariable(clause.pattern)) =>
      val newCaptures = new ListBuffer[Variable]

      val newClauses = for {
        clause @ MatchExpressionClause(pattern, guard, body) <- clauses
      } yield {
        val (newPattern, newGuard) = processVariablesInPattern(
            pattern, guard, newCaptures)
        treeCopy.MatchExpressionClause(clause, newPattern, newGuard, body)
      }

      transformExpr {
        LOCAL (newCaptures.toSeq:_*) IN {
          treeCopy.MatchExpression(matchStat, value, newClauses, elseExpr)
        }
      }

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

  private def containsVariable(pattern: Expression): Boolean = {
    pattern walk {
      case Variable(_) => return true
      case _ => ()
    }
    return false
  }

  private def processVariablesInPattern(pattern: Expression,
      guard: Option[Expression],
      captures: ListBuffer[Variable]): (Expression, Option[Expression]) = {
    if (!containsVariable(pattern)) {
      (pattern, guard)
    } else {
      val guardsBuffer = new ListBuffer[Expression]
      val newPattern = processVariablesInPatternInner(pattern,
          captures, guardsBuffer)
      guardsBuffer ++= guard

      val guards = guardsBuffer.toList
      assert(!guards.isEmpty)

      val newGuard = guards.tail.foldLeft(guards.head) {
        (lhs, rhs) => IF (lhs) THEN (rhs) ELSE (False())
      }

      (newPattern, Some(newGuard))
    }
  }

  /** Processes the variables in a pattern (inner) */
  private def processVariablesInPatternInner(pattern: Expression,
      captures: ListBuffer[Variable],
      guards: ListBuffer[Expression]): Expression = {

    def processRecordFields(fields: List[RecordField]) = {
      for (field @ RecordField(feature, value) <- fields) yield {
        val newValue = processVariablesInPatternInner(value, captures, guards)
        treeCopy.RecordField(field, feature, newValue)
      }
    }

    pattern match {
      /* Variable, what we're here for */
      case v @ Variable(symbol) =>
        val capture = new Symbol(symbol.name + "$", capture = true)
        captures += capture
        guards += builtins.binaryOpToBuiltin("==") callExpr (capture, v)
        treeCopy.Constant(pattern, OzPatMatCapture(capture))

      /* Dive into records */
      case record @ Record(label, fields) =>
        treeCopy.Record(record, label, processRecordFields(fields))

      /* Dive into open record patterns */
      case pattern @ OpenRecordPattern(label, fields) =>
        treeCopy.OpenRecordPattern(pattern, label, processRecordFields(fields))

      /* Dive into pattern conjunctions */
      case conj @ PatternConjunction(parts) =>
        val newParts = parts map {
          part => processVariablesInPatternInner(part, captures, guards)
        }
        treeCopy.PatternConjunction(conj, newParts)

      case _ =>
        pattern
    }
  }

  private def eliminateGuardsStat(original: MatchStatement, value: VarOrConst,
      clauses: List[MatchStatementClause],
      elseStat: Statement): Statement = {

    if (clauses.isEmpty) {
      elseStat match {
        case NoElseStatement() =>
          atPos(original) {
            MatchStatement(value, Nil, elseStat)
          }

        case _ =>
          elseStat
      }
    } else {
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

    if (clauses.isEmpty) {
      elseExpr match {
        case NoElseExpression() =>
          atPos(original) {
            MatchExpression(value, Nil, elseExpr)
          }

        case _ =>
          elseExpr
      }
    } else {
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
