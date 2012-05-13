package org.mozartoz.bootcompiler
package transform

import oz._
import ast._
import symtab._

object ConstantFolding extends Transformer with TreeDSL {
  import Utils._

  override def transformExpr(expression0: Expression) = {
    val expression = super.transformExpr(expression0)

    expression match {
      case record:Record =>
        transformRecord(record)

      case Constant(record:OzRecord) dot Constant(feature:OzFeature) =>
        val value = record.select(feature)
        if (value.isDefined)
          Constant(value.get)
        else {
          program.reportError(
              "The constant record %s does not have feature %s".format(
                  record, feature), expression)
          expression
        }

      case (record @ Record(_, fields)) dot (feature @ Constant(_:OzFeature)) =>
        fields.find(_.feature == feature) match {
          case Some(RecordField(_, value)) => value
          case None => expression
        }

      case _ =>
        expression
    }
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

  private object Utils {
    abstract class UnaryOp(builtin: Builtin) extends
        (Expression => Expression) {
      private val ozBuiltin = OzBuiltin(builtin)

      def apply(operand: Expression): Expression =
        builtin callExpr(operand)

      def unapply(call: CallExpression): Option[Expression] = {
        call match {
          case CallExpression(Constant(ozBuiltin), List(operand)) =>
            Some(operand)

          case _ => None
        }
      }
    }

    abstract class BinaryOp(builtin: Builtin) extends
        ((Expression, Expression) => Expression) {
      private val ozBuiltin = OzBuiltin(builtin)

      def apply(left: Expression, right: Expression): Expression =
        builtin callExpr(left, right)

      def unapply(call: CallExpression): Option[(Expression, Expression)] = {
        call match {
          case CallExpression(Constant(ozBuiltin), List(left, right)) =>
            Some((left, right))

          case _ => None
        }
      }
    }

    object <+> extends BinaryOp(builtins.binaryOpToBuiltin("+"))
    object <-> extends BinaryOp(builtins.binaryOpToBuiltin("-"))

    object dot extends BinaryOp(builtins.binaryOpToBuiltin("."))
  }
}
