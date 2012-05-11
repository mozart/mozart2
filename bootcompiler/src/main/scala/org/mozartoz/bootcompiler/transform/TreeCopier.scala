package org.mozartoz.bootcompiler
package transform

import oz._
import ast._
import symtab._

class TreeCopier {
  // Statements

  def CompoundStatement(tree: Node, statements: List[Statement]) =
    new CompoundStatement(statements).copyAttrs(tree)

  def LocalStatement(tree: Node, declarations: List[Declaration],
      statement: Statement) =
    new LocalStatement(declarations, statement).copyAttrs(tree)

  def CallStatement(tree: Node, callable: Expression, args: List[Expression]) =
    new CallStatement(callable, args).copyAttrs(tree)

  def IfStatement(tree: Node, condition: Expression,
      trueStatement: Statement, falseStatement: Statement) =
    new IfStatement(condition, trueStatement, falseStatement).copyAttrs(tree)

  def MatchStatement(tree: Node, value: Expression,
      clauses: List[MatchStatementClause], elseStatement: Statement) =
    new MatchStatement(value, clauses, elseStatement).copyAttrs(tree)

  def ThreadStatement(tree: Node, statement: Statement) =
    new ThreadStatement(statement).copyAttrs(tree)

  def BindStatement(tree: Node, left: Expression, right: Expression) =
    new BindStatement(left, right).copyAttrs(tree)

  def AssignStatement(tree: Node, left: Expression, right: Expression) =
    new AssignStatement(left, right).copyAttrs(tree)

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

  def ProcExpression(tree: Node, name: String, args: List[FormalArg],
      body: Statement, flags: List[String]) =
    new ProcExpression(name, args, body, flags).copyAttrs(tree)

  def FunExpression(tree: Node, name: String, args: List[FormalArg],
      body: Expression, flags: List[String]) =
    new FunExpression(name, args, body, flags).copyAttrs(tree)

  def CallExpression(tree: Node, callable: Expression, args: List[Expression]) =
    new CallExpression(callable, args).copyAttrs(tree)

  def IfExpression(tree: Node, condition: Expression,
      trueExpression: Expression, falseExpression: Expression) =
    new IfExpression(condition, trueExpression, falseExpression).copyAttrs(tree)

  def MatchExpression(tree: Node, value: Expression,
      clauses: List[MatchExpressionClause], elseExpression: Expression) =
    new MatchExpression(value, clauses, elseExpression).copyAttrs(tree)

  def ThreadExpression(tree: Node, expression: Expression) =
    new ThreadExpression(expression).copyAttrs(tree)

  def BindExpression(tree: Node, left: Expression, right: Expression) =
    new BindExpression(left, right).copyAttrs(tree)

  // Functors

  def AliasedFeature(tree: Node, feature: Constant, alias: Option[Variable]) =
    new AliasedFeature(feature, alias).copyAttrs(tree)

  def FunctorImport(tree: Node, module: Variable, aliases: List[AliasedFeature],
      location: Option[String]) =
    new FunctorImport(module, aliases, location).copyAttrs(tree)

  def FunctorExport(tree: Node, feature: Expression, value: Expression) =
    new FunctorExport(feature, value).copyAttrs(tree)

  def FunctorExpression(tree: Node, name: String,
      require: List[FunctorImport], prepare: Option[LocalStatement],
      imports: List[FunctorImport], define: Option[LocalStatement],
      exports: List[FunctorExport]) = {
    new FunctorExpression(name, require, prepare, imports,
        define, exports).copyAttrs(tree)
  }

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

  def Constant(tree: Node, value: OzValue) =
    new Constant(value).copyAttrs(tree)

  // Records

  def RecordField(tree: Node, feature: Expression, value: Expression) =
    new RecordField(feature, value).copyAttrs(tree)

  def Record(tree: Node, label: Expression, fields: List[RecordField]) =
    new Record(label, fields).copyAttrs(tree)

  // Match clauses

  def MatchStatementClause(tree: Node, pattern: Expression,
      guard: Option[Expression], body: Statement) =
    new MatchStatementClause(pattern, guard, body).copyAttrs(tree)

  def MatchExpressionClause(tree: Node, pattern: Expression,
      guard: Option[Expression], body: Expression) =
    new MatchExpressionClause(pattern, guard, body).copyAttrs(tree)

  // Synthetic-only

  def CreateAbstraction(tree: Node, arity: Expression, body: Expression,
      globals: List[Expression]) =
    new CreateAbstraction(arity, body, globals).copyAttrs(tree)
}
