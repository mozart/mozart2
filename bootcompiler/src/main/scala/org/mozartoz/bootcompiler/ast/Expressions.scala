package org.mozartoz.bootcompiler
package ast

import symtab._

sealed abstract class Expression extends StatOrExpr

// Compound expressions

case class StatAndExpression(statement: Statement,
    expression: Expression) extends Expression {
  def syntax(indent: String) = {
    statement.syntax(indent) + "\n" + indent + expression.syntax(indent)
  }
}

case class LocalExpression(declarations: List[Declaration],
    expression: Expression) extends Expression with LocalCommon {
  protected val body = expression
}

// Complex expressions

case class ProcExpression(name: String, args: List[FormalArg],
    body: Statement, flags: List[Atom]) extends Expression
    with ProcFunExpression {
  protected val keyword = "proc"
}

case class FunExpression(name: String, args: List[FormalArg],
    body: Expression, flags: List[Atom]) extends Expression
    with ProcFunExpression {
  protected val keyword = "fun"
}

case class CallExpression(callable: Expression,
    args: List[Expression]) extends Expression with CallCommon

case class IfExpression(condition: Expression,
    trueExpression: Expression,
    falseExpression: Expression) extends Expression with IfCommon {
  protected val truePart = trueExpression
  protected val falsePart = falseExpression
}

case class MatchExpression(value: Expression,
    clauses: List[MatchExpressionClause],
    elseExpression: Expression) extends Expression with MatchCommon {
  protected val elsePart = elseExpression
}

case class MatchExpressionClause(pattern: Expression, guard: Option[Expression],
    body: Expression) extends MatchClauseCommon {
}

case class ThreadExpression(
    expression: Expression) extends Expression with ThreadCommon {
  protected val body = expression
}

case class BindExpression(left: Expression,
    right: Expression) extends Expression with InfixSyntax {
  protected val opSyntax = " = "
}

// Operations

case class UnaryOp(operator: String, operand: Expression) extends Expression {
  def syntax(indent: String) =
    operator + operand.syntax(indent + " "*operator.length)
}

case class BinaryOp(left: Expression, operator: String,
    right: Expression) extends Expression with InfixSyntax {
  protected val opSyntax = " " + operator + " "
}

case class ShortCircuitBinaryOp(left: Expression, operator: String,
    right: Expression) extends Expression with InfixSyntax {
  protected val opSyntax = operator
}

// Trivial expressions

trait VarOrConst extends Expression

case class Variable(name: String) extends VarOrConst with SymbolNode
    with FormalArg with Declaration {
  def syntax(indent: String) = name
}

object Variable extends (String => Variable) {
  def apply(symbol: Symbol) =
    new Variable(symbol.name) withSymbol symbol
}

case class EscapedVariable(variable: Variable) extends Expression {
  def syntax(indent: String) = "!!" + variable.syntax(indent+"  ")
}

case class UnboundExpression() extends Expression {
  def syntax(indent: String) = "_"
}

sealed trait Constant extends VarOrConst

case class IntLiteral(value: Long) extends Constant {
  def syntax(indent: String) = value.toString()
}

case class FloatLiteral(value: Double) extends Constant {
  def syntax(indent: String) = value.toString()
}

trait AtomLike extends Constant

case class Atom(value: String) extends AtomLike {
  def syntax(indent: String) = "'" + escapePseudoChars(value, '\'') + "'"
}

abstract class BuiltinName(val tag: String) extends AtomLike {
  def syntax(indent: String) = tag
}

case class True() extends BuiltinName("true")
case class False() extends BuiltinName("false")
case class UnitVal() extends BuiltinName("unit")

case class AutoFeature() extends Constant {
  def syntax(indent: String) = ""
}

// Records

trait BaseRecordField extends Node {
  val feature: Expression
  val value: Expression

  def syntax(indent: String) = {
    val featSyntax = feature.syntax(indent)
    featSyntax + ":" + value.syntax(indent + " " + " "*featSyntax.length())
  }

  def hasAutoFeature =
    feature.isInstanceOf[AutoFeature]

  def hasConstantFeature =
    feature.isInstanceOf[Constant]
}

object BaseRecordField {
  def unapply(field: BaseRecordField) =
    Some((field.feature, field.value))
}

trait BaseRecord extends Expression {
  val label: Expression
  val fields: List[BaseRecordField]

  def syntax(indent: String) = fields.toList match {
    case Nil => label.syntax()

    case firstField :: otherFields => {
      val prefix = label.syntax() + "("
      val subIndent = indent + " " * prefix.length

      val firstLine = prefix + firstField.syntax(subIndent)

      otherFields.foldLeft(firstLine) {
        _ + "\n" + subIndent + _.syntax(subIndent)
      } + ")"
    }
  }

  def hasConstantArity =
    label.isInstanceOf[Constant] && (fields forall (_.hasConstantFeature))

  def isCons = {
    (label, fields) match {
      case (Atom("|"), List(
          BaseRecordField(IntLiteral(1), _),
          BaseRecordField(IntLiteral(2), _))) => true
      case _ => false;
    }
  }

  def isTuple = {
    fields.zipWithIndex.forall {
      case (BaseRecordField(IntLiteral(feat), _), index) if feat == index+1 =>
        true
      case _ => false
    }
  }
}

object BaseRecord {
  def unapply(record: BaseRecord) =
    Some((record.label, record.fields))
}

case class RecordField(feature: Expression,
    value: Expression) extends BaseRecordField {
}

case class Record(label: Expression,
    fields: List[RecordField]) extends BaseRecord {
}

object Tuple extends ((Expression, List[Expression]) => Record) {
  def apply(label: Expression, fields: List[Expression]) = {
    val recordFields =
      for ((value, index) <- fields.zipWithIndex)
        yield RecordField(IntLiteral(index+1), value)
    Record(label, recordFields)
  }

  def unapply(record: Record) = {
    if (record.isTuple) Some((record.label, record.fields map (_.value)))
    else None
  }
}

object Cons extends ((Expression, Expression) => Record) {
  def apply(head: Expression, tail: Expression) =
    Tuple(Atom("|"), List(head, tail))

  def unapply(record: Record) = record match {
    case Tuple(Atom("|"), List(head, tail)) => Some((head, tail))
    case _ => None
  }
}

case class ConstantRecordField(feature: Constant,
    value: Constant) extends BaseRecordField {
  override def hasConstantFeature = true
}

case class ConstantRecord(label: Constant,
    fields: List[ConstantRecordField]) extends BaseRecord with Constant {
  override def hasConstantArity = true
}

object ConstantTuple extends ((Constant, List[Constant]) => ConstantRecord) {
  def apply(label: Constant, fields: List[Constant]) = {
    val recordFields =
      for ((value, index) <- fields.zipWithIndex)
        yield ConstantRecordField(IntLiteral(index+1), value)
    ConstantRecord(label, recordFields)
  }

  def unapply(record: ConstantRecord) = {
    if (record.isTuple) Some((record.label, record.fields map (_.value)))
    else None
  }
}

object ConstantCons extends ((Constant, Constant) => ConstantRecord) {
  def apply(head: Constant, tail: Constant) =
    ConstantTuple(Atom("|"), List(head, tail))

  def unapply(record: ConstantRecord) = record match {
    case ConstantTuple(Atom("|"), List(head, tail)) => Some((head, tail))
    case _ => None
  }
}

object ConstantSharp extends (List[Constant] => ConstantRecord) {
  def apply(fields: List[Constant]) =
    ConstantTuple(Atom("#"), fields)

  def unapply(record: ConstantRecord) = record match {
    case ConstantTuple(Atom("#"), fields) => Some(fields)
    case _ => None
  }
}

/** Synthetic-only expressions */

case class CreateAbstraction(abstraction: Abstraction,
    globals: List[Variable]) extends Expression {
  def syntax(indent: String) = {
    "{CreateAbstraction '%s' [%s]}" format (abstraction.fullName,
        globals mkString " ")
  }
}
