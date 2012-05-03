package org.mozartoz.bootcompiler
package transform

import oz._
import ast._
import symtab._

object Desugar extends Transformer with TreeDSL {
  override def transformStat(statement: Statement) = statement match {
    case thread @ ThreadStatement(body) =>
      val proc = PROC("", Nil) {
        transformStat(body)
      }

      builtins.createThread call (proc)

    case _ =>
      super.transformStat(statement)
  }

  override def transformExpr(expression: Expression) = expression match {
    case fun @ FunExpression(name, args, body, flags) =>
      val result = Symbol.newSynthetic("<Result>", formal = true)

      val proc = PROC(name, args :+ Variable(result), flags) {
        result === body
      }

      transformExpr(proc)

    case thread @ ThreadExpression(body) =>
      expressionWithTemp { temp =>
        transformStat(THREAD (temp === body)) ~> temp
      }

    case BinaryOp(lhs, "+", Constant(OzInt(1))) =>
      transformExpr(builtins.plus1 callExpr (lhs))

    case BinaryOp(lhs, "-", Constant(OzInt(1))) =>
      transformExpr(builtins.minus1 callExpr (lhs))

    case UnaryOp(op, arg) =>
      transformExpr(builtins.unaryOpToBuiltin(op) callExpr (arg))

    case BinaryOp(lhs, op, rhs) =>
      transformExpr(builtins.binaryOpToBuiltin(op) callExpr (lhs, rhs))

    case ShortCircuitBinaryOp(lhs, "andthen", rhs) =>
      transformExpr(IF (lhs) THEN (rhs) ELSE (False()))

    case ShortCircuitBinaryOp(lhs, "orelse", rhs) =>
      transformExpr(IF (lhs) THEN (True()) ELSE (rhs))

    case record:Record =>
      transformRecord(super.transformExpr(record).asInstanceOf[Record])

    case _ =>
      super.transformExpr(expression)
  }

  private def transformRecord(record: Record): Expression = {
    val fieldsNoAuto = fillAutoFeatures(record.fields)

    if (!record.hasConstantArity) {
      makeDynamicRecord(record, record.label, fieldsNoAuto)
    } else if (fieldsNoAuto.isEmpty) {
      record.label
    } else {
      val sortedFields = fieldsNoAuto.sortWith { (leftField, rightField) =>
        val Constant(left:OzFeature) = leftField.feature
        val Constant(right:OzFeature) = rightField.feature
        left feature_< right
      }

      val newRecord = treeCopy.Record(record, record.label, sortedFields)

      if (newRecord.isConstant) newRecord.getAsConstant
      else newRecord
    }
  }

  private def fillAutoFeatures(fields: List[RecordField]) = {
    if (fields forall (!_.hasAutoFeature)) {
      // Trivial case: all features are non-auto
      fields
    } else if (fields forall (_.hasAutoFeature)) {
      // Next-to-trivial case: all features are auto
      for ((field, index) <- fields.zipWithIndex)
        yield treeCopy.RecordField(field, OzInt(index+1), field.value)
    } else {
      // Complex case: mix of auto and non-auto features

      // Collect used integer features
      val usedFeatures = (for {
        RecordField(Constant(OzInt(feature)), _) <- fields
      } yield feature).toSet

      // Actual filling
      var nextFeature: Long = 1

      for (field @ RecordField(feature, value) <- fields) yield {
        if (field.hasAutoFeature) {
          while (usedFeatures contains nextFeature)
            nextFeature += 1
          nextFeature += 1

          val newFeature = treeCopy.Constant(feature, OzInt(nextFeature-1))
          treeCopy.RecordField(field, newFeature, value)
        } else {
          field
        }
      }
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
