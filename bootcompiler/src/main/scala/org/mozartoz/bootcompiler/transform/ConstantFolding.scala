package org.mozartoz.bootcompiler
package transform

import oz._
import ast._
import symtab._

object ConstantFolding extends Transformer with TreeDSL {
  override def transformExpr(expression: Expression) = expression match {
    case _:Record =>
      transformRecord(super.transformExpr(expression).asInstanceOf[Record])

    case _ =>
      super.transformExpr(expression)
  }

  private def transformRecord(record: Record): Expression = {
    val Record(label, fields) = record

    if (!record.hasConstantArity) {
      makeDynamicRecord(record, label, fields)
    } else if (fields.isEmpty) {
      label
    } else {
      val sortedFields = fields.sortWith { (leftField, rightField) =>
        val Constant(left:OzFeature) = leftField.feature
        val Constant(right:OzFeature) = rightField.feature
        left feature_< right
      }

      val newRecord = treeCopy.Record(record, label, sortedFields)

      if (newRecord.isConstant) newRecord.getAsConstant
      else newRecord
    }
  }

  private def makeDynamicRecord(record: Record, label: Expression,
      fields: List[RecordField]): Expression = {
    val elementsOfTheTuple = for {
      RecordField(feature, value) <- fields
      elem <- List(feature, value)
    } yield elem

    val fieldsOfTheTuple =
      for ((elem, index) <- elementsOfTheTuple.zipWithIndex)
        yield treeCopy.RecordField(elem, OzInt(index+1), elem)

    val tupleWithFields = treeCopy.Record(record, OzAtom("#"), fieldsOfTheTuple)

    builtins.makeRecordDynamic callExpr (label, tupleWithFields)
  }
}
