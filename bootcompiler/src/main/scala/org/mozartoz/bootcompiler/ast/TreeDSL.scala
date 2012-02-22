package org.mozartoz.bootcompiler
package ast

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

      case _ =>
        treeCopy.CompoundStatement(self, List(self, right))
    }
  }

  /** Operations on Expressions */
  implicit def expression2ops(self: Expression) = new {
    def === (rhs: Expression) =
      treeCopy.BindStatement(self, self, rhs)
  }

  /** Convert a Symbol into a Variable */
  implicit def symbol2variable(symbol: Symbol) =
    Variable(symbol)

  /** Apply operations on Expressions directly on Symbols */
  implicit def symbol2ops(symbol: Symbol) =
    expression2ops(symbol)

  /** Pattern matching for BindStatements */
  object === {
    def unapply(statement: BindStatement) =
      Some((statement.left, statement.right))
  }

  /** Construct IFStatements and IfExpressions */
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
}
