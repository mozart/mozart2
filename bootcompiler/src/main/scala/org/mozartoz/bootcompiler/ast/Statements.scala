package org.mozartoz.bootcompiler
package ast

sealed abstract class Statement extends StatOrExpr with Declaration

case class CompoundStatement(statements: List[Statement]) extends Statement {
  def syntax(indent: String) = {
    val head :: tail = statements.toList
    tail.foldLeft(head.syntax(indent)) {
      _ + "\n" + indent + _.syntax(indent)
    }
  }
}

case class LocalStatement(declarations: List[Declaration],
    statement: Statement) extends Statement with LocalCommon {
  protected val body = statement
}

case class CallStatement(callable: Expression,
    args: List[Expression]) extends Statement with CallCommon

case class IfStatement(condition: Expression,
    trueStatement: Statement,
    falseStatement: Statement) extends Statement with IfCommon {
  protected val truePart = trueStatement
  protected val falsePart = falseStatement
}

case class ThreadStatement(
    statement: Statement) extends Statement with ThreadCommon {
  protected val body = statement
}

case class BindStatement(left: Expression,
    right: Expression) extends Statement with InfixSyntax {
  protected val opSyntax = " = "
}

case class SkipStatement() extends Statement {
  def syntax(indent: String) = "skip"
}
