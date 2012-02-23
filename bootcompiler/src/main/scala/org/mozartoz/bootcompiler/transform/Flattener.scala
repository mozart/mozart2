package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable.HashMap

import ast._
import symtab._

object Flattener extends Transformer {
  override def apply() {
    val rawCode = program.rawCode
    program.rawCode = null

    withAbstraction(program.topLevelAbstraction) {
      program.topLevelAbstraction.body = transformStat(rawCode)
    }
  }

  private def withAbstraction[A](newAbs: Abstraction)(f: => A) = {
    val savedAbs = abstraction
    abstraction = newAbs
    try f
    finally abstraction = savedAbs
  }

  override def transformStat(statement: Statement) = statement match {
    case LocalStatement(declarations, stat) =>
      for (v @ Variable(_) <- declarations)
        abstraction.acquire(v.symbol.asInstanceOf[VariableSymbol])

      transformStat(stat)

    case _ =>
      super.transformStat(statement)
  }

  override def transformExpr(expression: Expression) = expression match {
    case LocalExpression(declarations, expr) =>
      for (v @ Variable(_) <- declarations)
        abstraction.acquire(v.symbol.asInstanceOf[VariableSymbol])

      transformExpr(expr)

    case proc @ ProcExpression(name, args, body, flags) =>
      val abs = abstraction.newAbstraction(name)

      program.abstractions += abs

      for (v @ Variable(_) <- args)
        abs.acquire(v.symbol.asInstanceOf[VariableSymbol])

      abs.flags ++= flags map (_.value)

      abs.body = withAbstraction(abs) {
        transformStat(body)
      }

      treeCopy.ProcExpression(proc, name, args,
          treeCopy.SkipStatement(body), flags)

    case _ =>
      super.transformExpr(expression)
  }
}
