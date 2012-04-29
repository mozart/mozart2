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

object Variable {
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

case class RecordField(feature: Expression, value: Expression) extends Node {
  def syntax(indent: String) = {
    val featSyntax = feature.syntax(indent)
    featSyntax + ":" + value.syntax(indent + " " + " "*featSyntax.length())
  }

  def hasAutoFeature =
    feature.isInstanceOf[AutoFeature]

  def hasConstantFeature =
    feature.isInstanceOf[Constant]
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

  def hasConstantArity =
    label.isInstanceOf[Constant] && (fields forall (_.hasConstantFeature))

  def isCons = {
    (label, fields) match {
      case (Atom("|"), List(
          RecordField(IntLiteral(1), _),
          RecordField(IntLiteral(2), _))) => true
      case _ => false;
    }
  }

  def isTuple = {
    fields.zipWithIndex.forall {
      case (RecordField(IntLiteral(feat), _), index) if feat == index+1 => true
      case _ => false
    }
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
