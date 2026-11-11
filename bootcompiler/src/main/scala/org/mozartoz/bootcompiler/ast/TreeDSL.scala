package org.mozartoz.bootcompiler
package ast

import scala.reflect.ClassTag

import oz._
import symtab._
import transform._

/** Mixin trait that provides a DSL to synthesize Oz ASTs */
trait TreeDSL {
  /** User-provided tree copier */
  val treeCopy: TreeCopier

  /* The DSL wrappers below are named classes rather than anonymous ones, so
   * that calling their methods does not require reflection.
   */

  /** Operations on Statements */
  class StatementOps(self: Statement) {
    /** `self ~ right` sequentially composes `self` and `right` */
    def ~ (right: Statement): Statement = self match {
      case CompoundStatement(selfStats) =>
        treeCopy.CompoundStatement(self, selfStats :+ right)

      case SkipStatement() =>
        right

      case _ =>
        treeCopy.CompoundStatement(self, List(self, right))
    }

    /** `self ~> right` sequentially composes `self` and `right` */
    def ~> (right: Expression): Expression = self match {
      case SkipStatement() =>
        right

      case _ =>
        treeCopy.StatAndExpression(self, self, right)
    }
  }

  implicit def statement2ops(self: Statement): StatementOps =
    new StatementOps(self)

  /** Operations on Expressions */
  class ExpressionOps(self: Expression) {
    /** `self === rhs` binds `self` to `rhs` */
    def === (rhs: Expression) =
      treeCopy.BindStatement(self, self, rhs)

    /** Call `self` with arguments `args` as a statement */
    def call(args: Expression*) =
      treeCopy.CallStatement(self, self, args.toList)

    /** Call `self` with arguments `args` as an expression */
    def callExpr(args: Expression*) =
      treeCopy.CallExpression(self, self, args.toList)

    /** `==` operator */
    def =?= (rhs: Expression) =
      treeCopy.BinaryOp(self, self, "==", rhs)

    /** `.` operator */
    def dot(rhs: Expression) =
      treeCopy.BinaryOp(self, self, ".", rhs)
  }

  implicit def expression2ops(self: Expression): ExpressionOps =
    new ExpressionOps(self)

  /** Wrap an Oz value inside a Constant */
  implicit def value2constant(value: OzValue): Constant =
    Constant(value)

  /** Convert a Symbol into a Variable */
  implicit def symbol2variable(symbol: Symbol): Variable =
    Variable(symbol)

  /** Operations on Builtins */
  implicit def builtin2ops(builtin: Builtin): ExpressionOps =
    expression2ops(OzBuiltin(builtin))

  /** Apply operations on Expressions directly on Symbols */
  implicit def symbol2ops(symbol: Symbol): ExpressionOps =
    expression2ops(symbol)

  /** Pattern matching for BindStatements
   *
   *  Usage:
   *  {{{
   *  someStatement match {
   *    case lhs === rhs =>
   *      ...
   *  }
   *  }}}
   */
  object === {
    def unapply(statement: BindStatement) =
      Some((statement.left, statement.right))
  }

  /** Construct IfStatements and IfExpressions
   *
   *  Usage:
   *  {{{
   *  IF (<condition>) THEN {
   *    <thenPart>
   *  } ELSE {
   *    <elsePart>
   *  }
   *  }}}
   */
  def IF(cond: Expression) = new IfBuilder(cond)

  class IfBuilder(cond: Expression) {
    // Statement
    def THEN(trueStat: Statement) = new IfStatementBuilder(cond, trueStat)

    // Expression
    def THEN(trueExpr: Expression) = new IfExpressionBuilder(cond, trueExpr)
  }

  class IfStatementBuilder(cond: Expression, trueStat: Statement) {
    def ELSE(falseStat: Statement) =
      treeCopy.IfStatement(cond, cond, trueStat, falseStat)
  }

  class IfExpressionBuilder(cond: Expression, trueExpr: Expression) {
    def ELSE(falseExpr: Expression) =
      treeCopy.IfExpression(cond, cond, trueExpr, falseExpr)
  }

  /** Construct ProcExpressions
   *
   *  Usage:
   *  {{{
   *  PROC (<name>, List(<args>...) [, <flags>]) {
   *    <body>
   *  }
   *  }}}
   */
  def PROC(name: String, args: List[VariableOrRaw],
      flags: List[String] = Nil)(body: Statement) = {
    treeCopy.ProcExpression(body, name, args, body, flags)
  }

  /** Construct FunExpressions
   *
   *  Usage:
   *  {{{
   *  FUN (<name>, List(<args>...) [, <flags>]) {
   *    <body>
   *  }
   *  }}}
   */
  def FUN(name: String, args: List[VariableOrRaw],
      flags: List[String] = Nil)(body: Expression) = {
    treeCopy.FunExpression(body, name, args, body, flags)
  }

  /** Construct ThreadStatements
   *
   *  Usage:
   *  {{{
   *  THREAD {
   *    <body>
   *  }
   *  }}}
   */
  def THREAD(body: Statement) =
    treeCopy.ThreadStatement(body, body)

  /** Construct RawLocalStatements and RawLocalExpressions
   *
   *  Usage:
   *  {{{
   *  RAWLOCAL (<decls>...) IN {
   *    <body>
   *  }
   *  }}}
   */
  def RAWLOCAL(decls: RawDeclaration*) = new RawLocalBuilder(decls)

  class RawLocalBuilder(decls: Seq[RawDeclaration]) {
    def IN(body: Statement) =
      treeCopy.RawLocalStatement(body, decls.toList, body)

    def IN(body: Expression) =
      treeCopy.RawLocalExpression(body, decls.toList, body)
  }

  /** Construct LocalStatements and LocalExpressions
   *
   *  Usage:
   *  {{{
   *  LOCAL (<decls>...) IN {
   *    <body>
   *  }
   *  }}}
   */
  def LOCAL(decls: Variable*) = new LocalBuilder(decls)

  class LocalBuilder(decls: Seq[Variable]) {
    def IN(body: Statement) =
      treeCopy.LocalStatement(body, decls.toList, body)

    def IN(body: Expression) =
      treeCopy.LocalExpression(body, decls.toList, body)
  }

  /** Declare a synthetic temporary variable in a statement
   *
   *  Usage:
   *  {{{
   *  statementWithTemp { temp =>
   *    <body>
   *  }
   *  }}}
   *
   *  In `body` you can use `temp` as a temporary variable.
   */
  def statementWithTemp(statement: Variable => Statement) = {
    val temp = Variable.newSynthetic()
    LOCAL (temp) IN statement(temp)
  }

  /** Declare two synthetic temporary variables in a statement
   *
   *  Usage:
   *  {{{
   *  statementWithTemps { (temp1, temp2) =>
   *    <body>
   *  }
   *  }}}
   *
   *  In `body` you can use `temp1` and `temp2` as a temporary variables.
   */
  def statementWithTemps(statement: (Variable, Variable) => Statement) = {
    val temp1 = Variable.newSynthetic()
    val temp2 = Variable.newSynthetic()
    LOCAL (temp1, temp2) IN statement(temp1, temp2)
  }

  /** Declare a synthetic temporary variable in an expression
   *
   *  Usage:
   *  {{{
   *  expressionWithTemp { temp =>
   *    <body>
   *  }
   *  }}}
   *
   *  In `body` you can use `temp` as a temporary variable.
   */
  def expressionWithTemp(expression: Variable => Expression) = {
    val temp = Variable.newSynthetic()
    LOCAL (temp) IN expression(temp)
  }

  def statementWithValIn[A >: Variable <: Expression : ClassTag](value: Expression)(
      statement: A => Statement) = {
    value match {
      case value: A =>
        statement(value)
      case _ =>
        statementWithTemp { temp =>
          (temp === value) ~ statement(temp)
        }
    }
  }

  def expressionWithValIn[A >: Variable <: Expression : ClassTag](value: Expression)(
      expression: A => Expression) = {
    value match {
      case value: A =>
        expression(value)
      case _ =>
        expressionWithTemp { temp =>
          (temp === value) ~> expression(temp)
        }
    }
  }
}
