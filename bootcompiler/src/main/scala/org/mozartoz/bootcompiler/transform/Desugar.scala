package org.mozartoz.bootcompiler
package transform

import ast._
import symtab._

object Desugar extends Transformer with TreeDSL {
  override def transformStat(statement: Statement) = statement match {
    case thread @ ThreadStatement(body) =>
      val proc = PROC("", Nil) {
        transformStat(body)
      }

      builtins.CreateThread call (proc)

    case _ =>
      super.transformStat(statement)
  }

  override def transformExpr(expression: Expression) = expression match {
    case fun @ FunExpression(name, args, body, flags) =>
      val result = Symbol.newSynthetic("<Result>", formal = true)

      val proc = PROC(name, args.args :+ Variable(result), flags) {
        result === body
      }

      transformExpr(proc)

    case thread @ ThreadExpression(body) =>
      expressionWithTemp { temp =>
        transformStat(THREAD (temp === body)) ~> temp
      }

    case _ =>
      super.transformExpr(expression)
  }
}
