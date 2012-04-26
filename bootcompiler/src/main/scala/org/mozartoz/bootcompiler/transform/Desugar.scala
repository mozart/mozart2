package org.mozartoz.bootcompiler
package transform

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

    case BinaryOp(lhs, "+", IntLiteral(1)) =>
      transformExpr(builtins.plus1 callExpr (lhs))

    case BinaryOp(lhs, "-", IntLiteral(1)) =>
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

  private def transformRecord(record: Record): Record = {
    val fieldsNoAuto = fillAutoFeatures(record.fields)

    if (!record.hasConstantArity) {
      treeCopy.Record(record, record.label, fieldsNoAuto)
    } else {
      val sortedFields = fieldsNoAuto.sortWith { (leftField, rightField) =>
        val left = leftField.feature.asInstanceOf[Constant]
        val right = rightField.feature.asInstanceOf[Constant]
        featureLessThan(left, right)
      }

      treeCopy.Record(record, record.label, sortedFields)
    }
  }

  private def fillAutoFeatures(fields: List[RecordField]) = {
    if (fields forall (!_.hasAutoFeature)) {
      // Trivial case: all features are non-auto
      fields
    } else if (fields forall (_.hasAutoFeature)) {
      // Next-to-trivial case: all features are auto
      for ((field, index) <- fields.zipWithIndex)
        yield treeCopy.RecordField(field, IntLiteral(index+1), field.value)
    } else {
      // Complex case: mix of auto and non-auto features

      // Collect used integer features
      val usedFeatures = (for {
        RecordField(IntLiteral(feature), _) <- fields
      } yield feature).toSet

      // Actual filling
      var nextFeature: Long = 1

      for (field @ RecordField(feature, value) <- fields) yield {
        if (field.hasAutoFeature) {
          while (usedFeatures contains nextFeature)
            nextFeature += 1
          nextFeature += 1

          val newFeature = treeCopy.IntLiteral(feature, nextFeature-1)
          treeCopy.RecordField(field, newFeature, value)
        } else {
          field
        }
      }
    }
  }

  private def featureLessThan(left: Constant, right: Constant): Boolean = {
    (left, right) match {
      case (IntLiteral(l), IntLiteral(r)) => l < r
      case (Atom(l), Atom(r)) => l.compareTo(r) < 0
      case (l:BuiltinName, r:BuiltinName) => l.tag.compareTo(r.tag) < 0

      case _ => featureTypeRank(left) < featureTypeRank(right)
    }
  }

  private def featureTypeRank(feature: Constant): Int = {
    (feature: @unchecked) match {
      case _:IntLiteral => 1
      case _:Atom => 2
      case _:BuiltinName => 3
    }
  }
}
