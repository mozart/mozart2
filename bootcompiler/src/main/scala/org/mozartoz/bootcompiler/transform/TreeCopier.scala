package org.mozartoz.bootcompiler
package transform

import ast._

class TreeCopier {
  // Statements

  def CompoundStatement(tree: Node, statements: List[Statement]) =
    new CompoundStatement(statements).copyAttrs(tree)

  def LocalStatement(tree: Node, declarations: List[Declaration],
      statement: Statement) =
    new LocalStatement(declarations, statement).copyAttrs(tree)

  def CallStatement(tree: Node, callable: Expression, args: ActualArgs) =
    new CallStatement(callable, args).copyAttrs(tree)

  def IfStatement(tree: Node, condition: Expression,
      trueStatement: Statement, falseStatement: Statement) =
    new IfStatement(condition, trueStatement, falseStatement).copyAttrs(tree)

  def ThreadStatement(tree: Node, statement: Statement) =
    new ThreadStatement(statement).copyAttrs(tree)

  def BindStatement(tree: Node, left: Expression, right: Expression) =
    new BindStatement(left, right).copyAttrs(tree)

  def SkipStatement(tree: Node) =
    new SkipStatement().copyAttrs(tree)

  // Expressions

  def StatAndExpression(tree: Node, statement: Statement,
      expression: Expression) =
    new StatAndExpression(statement, expression).copyAttrs(tree)

  def LocalExpression(tree: Node, declarations: List[Declaration],
      expression: Expression) =
    new LocalExpression(declarations, expression).copyAttrs(tree)

  // Complex expressions

  def ProcExpression(tree: Node, name: String, args: FormalArgs,
      body: Statement, flags: List[Atom]) =
    new ProcExpression(name, args, body, flags).copyAttrs(tree)

  def FunExpression(tree: Node, name: String, args: FormalArgs,
      body: Expression, flags: List[Atom]) =
    new FunExpression(name, args, body, flags).copyAttrs(tree)

  def CallExpression(tree: Node, callable: Expression, args: ActualArgs) =
    new CallExpression(callable, args).copyAttrs(tree)

  def IfExpression(tree: Node, condition: Expression,
      trueExpression: Expression, falseExpression: Expression) =
    new IfExpression(condition, trueExpression, falseExpression).copyAttrs(tree)

  def ThreadExpression(tree: Node, expression: Expression) =
    new ThreadExpression(expression).copyAttrs(tree)

  def BindExpression(tree: Node, left: Expression, right: Expression) =
    new BindExpression(left, right).copyAttrs(tree)

  // Operations

  def UnaryOp(tree: Node, operator: String, operand: Expression) =
    new UnaryOp(operator, operand).copyAttrs(tree)

  def BinaryOp(tree: Node, left: Expression, operator: String,
      right: Expression) =
    new BinaryOp(left, operator, right).copyAttrs(tree)

  def ShortCircuitBinaryOp(tree: Node, left: Expression, operator: String,
      right: Expression) =
    new ShortCircuitBinaryOp(left, operator, right).copyAttrs(tree)

  // Trivial expressions

  def Variable(tree: Node, name: String) =
    new Variable(name).copyAttrs(tree)

  def EscapedVariable(tree: Node, variable: Variable) =
    new EscapedVariable(variable).copyAttrs(tree)

  def UnboundExpression(tree: Node) =
    new UnboundExpression().copyAttrs(tree)

  def IntLiteral(tree: Node, value: Long) =
    new IntLiteral(value).copyAttrs(tree)

  def Atom(tree: Node, value: String) =
    new Atom(value).copyAttrs(tree)

  def True(tree: Node) =
    new True().copyAttrs(tree)

  def False(tree: Node) =
    new False().copyAttrs(tree)

  def UnitVal(tree: Node) =
    new UnitVal().copyAttrs(tree)

  // Other

  def FormalArgs(tree: Node, args: List[FormalArg]) =
    new FormalArgs(args).copyAttrs(tree)

  def ActualArgs(tree: Node, args: List[Expression]) =
    new ActualArgs(args).copyAttrs(tree)
}
