package org.mozartoz.bootcompiler
package transform

import oz._
import ast._
import symtab._

class TreeCopier {
  // Statements

  def CompoundStatement(tree: Node, statements: List[Statement]) =
    new CompoundStatement(statements).copyAttrs(tree)

  def RawLocalStatement(tree: Node, declarations: List[RawDeclaration],
      statement: Statement) =
    new RawLocalStatement(declarations, statement).copyAttrs(tree)

  def LocalStatement(tree: Node, declarations: List[Variable],
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

  def NoElseStatement(tree: Node) =
    new NoElseStatement().copyAttrs(tree)

  def ThreadStatement(tree: Node, statement: Statement) =
    new ThreadStatement(statement).copyAttrs(tree)

  def LockStatement(tree: Node, lock: Expression, statement: Statement) =
    new LockStatement(lock, statement).copyAttrs(tree)

  def LockObjectStatement(tree: Node, statement: Statement) =
    new LockObjectStatement(statement).copyAttrs(tree)

  def TryStatement(tree: Node, body: Statement, exceptionVar: VariableOrRaw,
      catchBody: Statement) =
    new TryStatement(body, exceptionVar, catchBody).copyAttrs(tree)

  def TryFinallyStatement(tree: Node, body: Statement,
      finallyBody: Statement) =
    new TryFinallyStatement(body, finallyBody).copyAttrs(tree)

  def RaiseStatement(tree: Node, exception: Expression) =
    new RaiseStatement(exception).copyAttrs(tree)

  def FailStatement(tree: Node) =
    new FailStatement().copyAttrs(tree)

  def BindStatement(tree: Node, left: Expression, right: Expression) =
    new BindStatement(left, right).copyAttrs(tree)

  def BinaryOpStatement(tree: Node, left: Expression, operator: String,
      right: Expression) =
    new BinaryOpStatement(left, operator, right).copyAttrs(tree)

  def DotAssignStatement(tree: Node, left: Expression, center: Expression,
      right: Expression) =
    new DotAssignStatement(left, center, right).copyAttrs(tree)

  def SkipStatement(tree: Node) =
    new SkipStatement().copyAttrs(tree)

  // Expressions

  def StatAndExpression(tree: Node, statement: Statement,
      expression: Expression) =
    new StatAndExpression(statement, expression).copyAttrs(tree)

  def RawLocalExpression(tree: Node, declarations: List[RawDeclaration],
      expression: Expression) =
    new RawLocalExpression(declarations, expression).copyAttrs(tree)

  def LocalExpression(tree: Node, declarations: List[Variable],
      expression: Expression) =
    new LocalExpression(declarations, expression).copyAttrs(tree)

  // Complex expressions

  def ProcExpression(tree: Node, name: String, args: List[VariableOrRaw],
      body: Statement, flags: List[String]) =
    new ProcExpression(name, args, body, flags).copyAttrs(tree)

  def FunExpression(tree: Node, name: String, args: List[VariableOrRaw],
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

  def NoElseExpression(tree: Node) =
    new NoElseExpression().copyAttrs(tree)

  def ThreadExpression(tree: Node, expression: Expression) =
    new ThreadExpression(expression).copyAttrs(tree)

  def LockExpression(tree: Node, lock: Expression, expression: Expression) =
    new LockExpression(lock, expression).copyAttrs(tree)

  def LockObjectExpression(tree: Node, expression: Expression) =
    new LockObjectExpression(expression).copyAttrs(tree)

  def TryExpression(tree: Node, body: Expression, exceptionVar: VariableOrRaw,
      catchBody: Expression) =
    new TryExpression(body, exceptionVar, catchBody).copyAttrs(tree)

  def TryFinallyExpression(tree: Node, body: Expression,
      finallyBody: Statement) =
    new TryFinallyExpression(body, finallyBody).copyAttrs(tree)

  def RaiseExpression(tree: Node, exception: Expression) =
    new RaiseExpression(exception).copyAttrs(tree)

  def BindExpression(tree: Node, left: Expression, right: Expression) =
    new BindExpression(left, right).copyAttrs(tree)

  def DotAssignExpression(tree: Node, left: Expression, center: Expression,
      right: Expression) =
    new DotAssignExpression(left, center, right).copyAttrs(tree)

  // Functors

  def AliasedFeature(tree: Node, feature: Constant,
      alias: Option[VariableOrRaw]) =
    new AliasedFeature(feature, alias).copyAttrs(tree)

  def FunctorImport(tree: Node, module: VariableOrRaw,
      aliases: List[AliasedFeature], location: Option[String]) =
    new FunctorImport(module, aliases, location).copyAttrs(tree)

  def FunctorExport(tree: Node, feature: Expression, value: Expression) =
    new FunctorExport(feature, value).copyAttrs(tree)

  def FunctorExpression(tree: Node, name: String,
      require: List[FunctorImport], prepare: Option[LocalStatementOrRaw],
      imports: List[FunctorImport], define: Option[LocalStatementOrRaw],
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

  def RawVariable(tree: Node, name: String) =
    new RawVariable(name).copyAttrs(tree)

  def Variable(tree: Node, symbol: Symbol) =
    new Variable(symbol).copyAttrs(tree)

  def EscapedVariable(tree: Node, variable: RawVariable) =
    new EscapedVariable(variable).copyAttrs(tree)

  def UnboundExpression(tree: Node) =
    new UnboundExpression().copyAttrs(tree)

  def Self(tree: Node) =
    new Self().copyAttrs(tree)

  def Constant(tree: Node, value: OzValue) =
    new Constant(value).copyAttrs(tree)

  // Records

  def RecordField(tree: Node, feature: Expression, value: Expression) =
    new RecordField(feature, value).copyAttrs(tree)

  def Record(tree: Node, label: Expression, fields: List[RecordField]) =
    new Record(label, fields).copyAttrs(tree)

  def OpenRecordPattern(tree: Node, label: Expression,
      fields: List[RecordField]) =
    new OpenRecordPattern(label, fields).copyAttrs(tree)

  def PatternConjunction(tree: Node, parts: List[Expression]) =
    new PatternConjunction(parts).copyAttrs(tree)

  // Match clauses

  def MatchStatementClause(tree: Node, pattern: Expression,
      guard: Option[Expression], body: Statement) =
    new MatchStatementClause(pattern, guard, body).copyAttrs(tree)

  def MatchExpressionClause(tree: Node, pattern: Expression,
      guard: Option[Expression], body: Expression) =
    new MatchExpressionClause(pattern, guard, body).copyAttrs(tree)

  // Classes

  def FeatOrAttr(tree: Node, name: Expression, value: Option[Expression]) =
    new FeatOrAttr(name, value).copyAttrs(tree)

  def MethodParam(tree: Node, feature: Expression, name: Expression,
      default: Option[Expression]) =
    new MethodParam(feature, name, default).copyAttrs(tree)

  def MethodHeader(tree: Node, name: Expression, params: List[MethodParam],
      open: Boolean) =
    new MethodHeader(name, params, open).copyAttrs(tree)

  def MethodDef(tree: Node, header: MethodHeader,
      messageVar: Option[VariableOrRaw], body: StatOrExpr) =
    new MethodDef(header, messageVar, body).copyAttrs(tree)

  def ClassExpression(tree: Node, name: String, parents: List[Expression],
      features: List[FeatOrAttr], attributes: List[FeatOrAttr],
      properties: List[Expression], methods: List[MethodDef]) =
    new ClassExpression(name, parents, features, attributes,
        properties, methods).copyAttrs(tree)

  // Synthetic-only

  def CreateAbstraction(tree: Node, body: Expression,
      globals: List[Expression]) =
    new CreateAbstraction(body, globals).copyAttrs(tree)
}
