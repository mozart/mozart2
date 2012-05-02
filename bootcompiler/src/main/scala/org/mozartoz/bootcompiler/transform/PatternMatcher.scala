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

  override def transformExpr(expression: Expression) = expression match {
    case record @ Record(label, fields) =>
      val newLabel = transformExpr(label)
      val newFields = fields map transformRecordField

      if (newLabel.isInstanceOf[Constant] &&
          (newFields forall isConstantField)) {
        val constantLabel = newLabel.asInstanceOf[Constant]
        val constantFields = newFields map asConstantField
        treeCopy.ConstantRecord(record, constantLabel, constantFields)
      } else {
        treeCopy.Record(record, newLabel, newFields)
      }

    case _ =>
      super.transformExpr(expression)
  }

  private def isConstantField(field: RecordField) =
    field.feature.isInstanceOf[Constant] && field.value.isInstanceOf[Constant]

  private def asConstantField(field: RecordField) = {
    val newFeature = field.feature.asInstanceOf[Constant]
    val newValue = field.value.asInstanceOf[Constant]
    treeCopy.ConstantRecordField(field, newFeature, newValue)
  }
}
