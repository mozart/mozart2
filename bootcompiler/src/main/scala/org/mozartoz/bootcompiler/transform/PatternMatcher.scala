package org.mozartoz.bootcompiler
package transform

import ast._
import symtab._

object PatternMatcher extends Transformer with TreeDSL {
  override def transformStat(statement: Statement) = statement match {
    case matchStat:MatchStatement =>
      transformMatchStatement(matchStat)

    case _ =>
      super.transformStat(statement)
  }

  private def transformMatchStatement(statement: MatchStatement): Statement = {
    // TODO
    super.transformStat(statement)
  }
}
