package org.mozartoz.bootcompiler
package ast

import oz._
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
    body: Statement, flags: List[String]) extends Expression
    with ProcFunExpression {
  protected val keyword = "proc"
}

case class FunExpression(name: String, args: List[FormalArg],
    body: Expression, flags: List[String]) extends Expression
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

case class Constant(value: OzValue) extends VarOrConst {
  def syntax(indent: String) = value.syntax()
}

case class AutoFeature() extends Expression {
  def syntax(indent: String) = ""
}

// Records

case class RecordField(feature: Expression, value: Expression) extends Node {
  def syntax(indent: String) = {
    val featSyntax = feature.syntax(indent)
    featSyntax + ":" + value.syntax(indent + " " + " "*featSyntax.length())
  }

  def hasAutoFeature =
    feature.isInstanceOf[AutoFeature]

  def hasConstantFeature =
    feature.isInstanceOf[Constant] || hasAutoFeature

  def isConstant =
    feature.isInstanceOf[Constant] && value.isInstanceOf[Constant]
}

case class Record(label: Expression,
    fields: List[RecordField]) extends Expression {
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

  lazy val hasConstantArity =
    label.isInstanceOf[Constant] && (fields forall (_.hasConstantFeature))

  lazy val getConstantArity: OzArity = {
    require(hasConstantArity)

    val Constant(ozLabel:OzLiteral) = label
    val ozFeatures =
      for (RecordField(Constant(feature:OzFeature), _) <- fields)
        yield feature

    OzArity(ozLabel, ozFeatures)
  }

  def isTuple = hasConstantArity && getConstantArity.isTupleArity
  def isCons = hasConstantArity && getConstantArity.isConsArity

  def isConstant =
    label.isInstanceOf[Constant] && (fields forall (_.isConstant))

  def getAsConstant: OzValue = {
    require(isConstant)

    val Constant(ozLabel:OzLiteral) = label
    val ozFields = {
      for (RecordField(Constant(feature:OzFeature),
          Constant(value)) <- fields)
        yield OzRecordField(feature, value)
    }

    OzRecord(ozLabel, ozFields)
  }
}

object Tuple extends ((Expression, List[Expression]) => Record) {
  def apply(label: Expression, fields: List[Expression]) = {
    val recordFields =
      for ((value, index) <- fields.zipWithIndex)
        yield RecordField(Constant(OzInt(index+1)), value)
    Record(label, recordFields)
  }

  def unapply(record: Record) = {
    if (record.isTuple) Some((record.label, record.fields map (_.value)))
    else None
  }
}

object Cons extends ((Expression, Expression) => Record) {
  def apply(head: Expression, tail: Expression) =
    Tuple(Constant(OzAtom("|")), List(head, tail))

  def unapply(record: Record) = {
    if (record.isCons) Some((record.fields(0).value, record.fields(1).value))
    else None
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
