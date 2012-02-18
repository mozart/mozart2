package org.mozartoz.bootcompiler
package transform

import ast._

trait TransformUtils {
  def statementsToStatement(statements: List[Statement]) = statements match {
    case Nil => SkipStatement()
    case stat :: Nil => stat
    case _ => CompoundStatement(statements)
  }

  def statsAndStatToStat(statements: List[Statement], statement: Statement) =
    if (statements.isEmpty) statement
    else CompoundStatement(statements :+ statement)

  def statsAndExprToExpr(statements: List[Statement], expression: Expression) =
    if (statements.isEmpty) expression
    else StatAndExpression(statementsToStatement(statements), expression)
}
