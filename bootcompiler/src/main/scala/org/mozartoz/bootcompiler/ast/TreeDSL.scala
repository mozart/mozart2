package org.mozartoz.bootcompiler
package ast

import oz._
import symtab._
import transform._

trait TreeDSL {
  /** User-provided tree copier */
  val treeCopy: TreeCopier

  /** Operations on Statements */
  implicit def statement2ops(self: Statement) = new {
    def ~ (right: Statement) = self match {
      case CompoundStatement(selfStats) =>
        treeCopy.CompoundStatement(self, selfStats :+ right)

      case SkipStatement() =>
        right

      case _ =>
        treeCopy.CompoundStatement(self, List(self, right))
    }

    def ~> (right: Expression) = self match {
      case SkipStatement() =>
        right

      case _ =>
        treeCopy.StatAndExpression(self, self, right)
    }
  }

  /** Operations on Expressions */
  implicit def expression2ops(self: Expression) = new {
    def === (rhs: Expression) =
      treeCopy.BindStatement(self, self, rhs)

    def call(args: Expression*) =
      treeCopy.CallStatement(self, self, args.toList)

    def callExpr(args: Expression*) =
      treeCopy.CallExpression(self, self, args.toList)

    def dot(rhs: Expression) =
      treeCopy.BinaryOp(self, self, ".", rhs)
  }

  /** Wrap an Oz value inside a Constant */
  implicit def value2constant(value: OzValue) =
    Constant(value)

  /** Convert a Symbol into a Variable */
  implicit def symbol2variable(symbol: Symbol) =
    Variable(symbol)

  /** Operations on Builtins */
  implicit def builtin2ops(builtin: Builtin) =
    expression2ops(OzBuiltin(builtin))

  /** Apply operations on Expressions directly on Symbols */
  implicit def symbol2ops(symbol: Symbol) =
    expression2ops(symbol)

  /** Pattern matching for BindStatements */
  object === {
    def unapply(statement: BindStatement) =
      Some((statement.left, statement.right))
  }

  /** Construct IfStatements and IfExpressions */
  def IF(cond: Expression) = new {
    // Statement
    def THEN(trueStat: Statement) = new {
      def ELSE(falseStat: Statement) =
        treeCopy.IfStatement(cond, cond, trueStat, falseStat)
    }

    // Expression
    def THEN(trueExpr: Expression) = new {
      def ELSE(falseExpr: Expression) =
        treeCopy.IfExpression(cond, cond, trueExpr, falseExpr)
    }
  }

  /** Construct ProcExpressions */
  def PROC(name: String, args: List[FormalArg],
      flags: List[String] = Nil)(body: Statement) = {
    treeCopy.ProcExpression(body, name, args, body, flags)
  }

  /** Construct FunExpressions */
  def FUN(name: String, args: List[FormalArg],
      flags: List[String] = Nil)(body: Expression) = {
    treeCopy.FunExpression(body, name, args, body, flags)
  }

  /** Construct ThreadStatements */
  def THREAD(body: Statement) =
    treeCopy.ThreadStatement(body, body)

  /** Construct LocalStatements and LocalExpressions */
  def LOCAL(decls: Declaration*) = new {
    def IN(body: Statement) =
      treeCopy.LocalStatement(body, decls.toList, body)

    def IN(body: Expression) =
      treeCopy.LocalExpression(body, decls.toList, body)
  }

  def statementWithTemp(statement: Symbol => Statement) = {
    val temp = Symbol.newSynthetic()
    LOCAL (temp) IN statement(temp)
  }

  def statementWithTemps(statement: (Symbol, Symbol) => Statement) = {
    val temp1 = Symbol.newSynthetic()
    val temp2 = Symbol.newSynthetic()
    LOCAL (temp1, temp2) IN statement(temp1, temp2)
  }

  def expressionWithTemp(expression: Symbol => Expression) = {
    val temp = Symbol.newSynthetic()
    LOCAL (temp) IN expression(temp)
  }

  def statementWithValIn[A >: Variable <: Expression](value: Expression)(
      statement: A => Statement)(implicit m: Manifest[A]) = {
    if (m.erasure.isInstance(value)) {
      statement(value.asInstanceOf[A])
    } else {
      statementWithTemp { temp =>
        (temp === value) ~ statement(temp)
      }
    }
  }

  def expressionWithValIn[A >: Variable <: Expression](value: Expression)(
      expression: A => Expression)(implicit m: Manifest[A]) = {
    if (m.erasure.isInstance(value)) {
      expression(value.asInstanceOf[A])
    } else {
      expressionWithTemp { temp =>
        (temp === value) ~> expression(temp)
      }
    }
  }
}
