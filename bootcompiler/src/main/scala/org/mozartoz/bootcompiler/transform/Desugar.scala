package org.mozartoz.bootcompiler
package transform

import oz._
import ast._
import symtab._

object Desugar extends Transformer with TreeDSL {
  override def transformStat(statement: Statement) = statement match {
    case assign @ AssignStatement(lhs, rhs) =>
      builtins.cellAssign call (transformExpr(lhs), transformExpr(rhs))

    case DotAssignStatement(left, center, right) =>
      builtins.arrayPut call (transformExpr(left), transformExpr(center),
          transformExpr(right))

    case thread @ ThreadStatement(body) =>
      val proc = PROC("", Nil) {
        transformStat(body)
      }

      builtins.createThread call (proc)

    case TryFinallyStatement(body, finallyBody) =>
      transformStat {
        atPos(statement) {
          statementWithTemp { tempX =>
            val tempY = Variable.newSynthetic(capture = true)

            (LOCAL (tempY) IN {
              (tempX === TryExpression(body ~> UnitVal(),
                  tempY, Tuple(OzAtom("ex"), List(tempY))))
            }) ~
            finallyBody ~
            (IF (tempX =?= UnitVal()) THEN {
              SkipStatement()
            } ELSE {
              RaiseStatement(tempX dot OzInt(1))
            })
          }
        }
      }

    case _ =>
      super.transformStat(statement)
  }

  override def transformExpr(expression: Expression) = expression match {
    case fun @ FunExpression(name, args, body, flags) =>
      val result = Variable.newSynthetic("<Result>", formal = true)

      val proc = PROC(name, args :+ result, flags) {
        result === body
      }

      transformExpr(proc)

    case thread @ ThreadExpression(body) =>
      expressionWithTemp { temp =>
        transformStat(THREAD (temp === body)) ~> temp
      }

    case TryFinallyExpression(body, finallyBody) =>
      transformExpr {
        atPos(expression) {
          expressionWithTemp { tempX =>
            val tempY = Variable.newSynthetic(capture = true)

            (LOCAL (tempY) IN {
              (tempX === TryExpression(
                  Tuple(OzAtom("ok"), List(body)),
                  tempY, Tuple(OzAtom("ex"), List(tempY))))
            }) ~
            finallyBody ~>
            (IF ((builtins.label callExpr (tempX)) =?= OzAtom("ok")) THEN {
              tempX dot OzInt(1)
            } ELSE {
              RaiseExpression(tempX dot OzInt(1))
            })
          }
        }
      }

    case DotAssignExpression(left, center, right) =>
      transformExpr(builtins.arrayExchange callExpr (left, center, right))

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

    case Record(label, fields) =>
      val fieldsNoAuto = fillAutoFeatures(fields)
      val newRecord = treeCopy.Record(expression, label, fieldsNoAuto)
      super.transformExpr(newRecord)

    case _ =>
      super.transformExpr(expression)
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
}
