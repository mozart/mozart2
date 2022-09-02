package org.mozartoz.bootcompiler
package transform

import oz._
import ast._
import symtab._

object ConstantFolding extends Transformer with TreeDSL {
  import Utils._

  override protected def apply(): Unit = {
    program.rawCode = transformRoot(program.rawCode)
  }

  private def transformRoot(statement: Statement): Statement = {
    /* The top-level local statements define the base environment.
     * A lot of variables in the base environment are trivially bound to a
     * constant builtin. This treatment allows to replace uses of such
     * variables by the builtin, directly.
     * Later, the codegen will take huge advantage of this knowledge to
     * produce OpCallBuiltin opcodes instead of OpCall's.
     */
    statement match {
      case compound @ CompoundStatement(stats) =>
        treeCopy.CompoundStatement(compound, stats map transformRoot)

      case local @ LocalStatement(decls, stat0) =>
        val stat = transformRoot(stat0)

        processConstAssignments(decls, stat) match {
          case None =>
            treeCopy.LocalStatement(local, decls, stat)

          case Some((newDecls, newStat)) =>
            transformRoot {
              treeCopy.LocalStatement(local, newDecls, newStat)
            }
        }

      case _ =>
        transformStat(statement)
    }
  }

  override def transformExpr(expression0: Expression) = {
    val expression = super.transformExpr(expression0)

    expression match {
      case Variable(symbol) if symbol.isConstant =>
        treeCopy.Constant(expression, symbol.constant.get)

      case record:Record =>
        transformRecord(record)

      case record:OpenRecordPattern =>
        transformOpenRecordPattern(record)

      case conj @ PatternConjunction(parts)
      if parts.forall(_.isInstanceOf[Constant]) =>
        val constantParts = parts map { _.asInstanceOf[Constant].value }
        treeCopy.Constant(conj, OzPatMatConjunction(constantParts))

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
      record
    } else if (fields.isEmpty) {
      label
    } else {
      val newRecord = treeCopy.Record(record, label, sortRecordFields(fields))

      if (newRecord.isConstant) newRecord.getAsConstant
      else newRecord
    }
  }

  private def transformOpenRecordPattern(
      record: OpenRecordPattern): Expression = {
    val OpenRecordPattern(label, fields) = record

    if (!record.hasConstantArity) {
      record
    } else {
      val newRecord = treeCopy.OpenRecordPattern(record,
          label, sortRecordFields(fields))

      if (newRecord.isConstant) newRecord.getAsConstant
      else newRecord
    }
  }

  /** Sort the fields of a record according to their features */
  private def sortRecordFields(fields: List[RecordField]) = {
    fields.sortWith { (leftField, rightField) =>
      val Constant(left:OzFeature) = leftField.feature
      val Constant(right:OzFeature) = rightField.feature
      left feature_< right
    }
  }

  private def processConstAssignments(decls: List[Variable],
      statement: Statement): Option[(List[Variable], Statement)] = {
    var touched: Boolean = false

    def inner(statement: Statement): Statement = {
      val statements = foldCompoundStatements(statement)

      val newStatements = statements flatMap { stat => stat match {
        case (lhs @ Variable(symbol)) === Constant(rhs) if decls contains lhs =>
          symbol.constant match {
            case Some(const) if const == rhs =>
              ()

            case Some(const) =>
              program.reportError("Duplicate constant assignment", lhs)

            case None =>
              symbol.setConstant(rhs)
          }

          touched = true
          None

        case local @ LocalStatement(subDecls, subStat) =>
          Some(treeCopy.LocalStatement(local, subDecls, inner(subStat)))

        case _ =>
          Some(stat)
      }}

      treeCopy.CompoundStatement(statement, newStatements)
    }

    val newStatement = inner(statement)

    if (touched) {
      val newDecls = decls filterNot (_.symbol.isConstant)
      Some((newDecls, newStatement))
    } else {
      None
    }
  }

  private def foldCompoundStatements(statement: Statement): List[Statement] = {
    statement match {
      case CompoundStatement(stats) =>
        stats flatMap foldCompoundStatements

      case SkipStatement() =>
        Nil

      case _ =>
        List(statement)
    }
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
