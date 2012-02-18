package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable.ListBuffer

import ast._

object DeclarationExtractor extends Transformer with TransformUtils {
  override def transformStat(stat: Statement) = super.transformStat(stat) match {
    case LocalStatement(declarations, body) =>
      val (decls, stats) = extractDecls(declarations)
      val stat = statsAndStatToStat(stats, body)

      if (decls.isEmpty) stat
      else LocalStatement(decls, stat)

    case anythingElse => anythingElse
  }

  override def transformExpr(expr: Expression) = super.transformExpr(expr) match {
    case LocalExpression(declarations, body) =>
      val (decls, stats) = extractDecls(declarations)
      val expr = statsAndExprToExpr(stats, body)

      if (decls.isEmpty) expr
      else LocalExpression(decls, expr)

    case anythingElse => anythingElse
  }

  def extractDecls(
      declarations: List[Declaration]): (List[RawVariable], List[Statement]) = {
    val decls = new ListBuffer[RawVariable]
    val statements = new ListBuffer[Statement]

    for (declaration <- declarations) {
      declaration match {
        case variable:RawVariable =>
          decls += variable

        case stat @ BindStatement(left, right) =>
          decls ++= extractDeclsInExpression(left)
          statements += stat

        case stat:Statement =>
          statements += stat
      }
    }

    (decls.toList, statements.toList)
  }

  def extractDeclsInExpression(expr: Expression) = expr match {
    case variable:RawVariable =>
      List(variable)

    case _ =>
      Nil
  }
}
