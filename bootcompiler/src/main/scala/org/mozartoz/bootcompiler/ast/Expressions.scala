package org.mozartoz.bootcompiler
package ast

trait Expression extends StatOrExpr

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

case class ProcExpression(args: FormalArgs,
    body: Statement, flags: List[Atom]) extends Expression
    with ProcCommon with ProcFunExpression

case class FunExpression(args: FormalArgs,
    body: Expression, flags: List[Atom]) extends Expression
    with FunCommon with ProcFunExpression

case class CallExpression(callable: Expression,
    args: ActualArgs) extends Expression with CallCommon

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

case class Variable(name: String) extends Expression
    with FormalArg with Declaration {
  def syntax(indent: String) = name
}

case class EscapedVariable(variable: Variable) extends Expression {
  def syntax(indent: String) = "!!" + variable.syntax(indent+"  ")
}

case class UnboundExpression() extends Expression {
  def syntax(indent: String) = "_"
}

trait Constant extends Expression

case class IntLiteral(value: Long) extends Constant {
  def syntax(indent: String) = value.toString()
}

trait AtomLike extends Constant

case class Atom(value: String) extends AtomLike {
  def syntax(indent: String) = "'" + escapePseudoChars(value, '\'') + "'"
}

abstract class BuiltinName(tag: String) extends AtomLike {
  def syntax(indent: String) = tag
}

case class True() extends BuiltinName("true")
case class False() extends BuiltinName("false")
case class UnitVal() extends BuiltinName("unit")
