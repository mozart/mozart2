package org.mozartoz.bootcompiler
package ast

trait Statement extends StatOrExpr with Declaration

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

case class ProcStatement(name: Expression, args: FormalArgs,
    body: Statement, flags: List[Atom]) extends Statement
    with ProcCommon with ProcFunStatement

case class FunStatement(name: Expression, args: FormalArgs,
    body: Expression, flags: List[Atom]) extends Statement
    with FunCommon with ProcFunStatement

case class CallStatement(callable: Expression,
    args: ActualArgs) extends Statement with CallCommon

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
