package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable._

import oz._
import ast._
import symtab._

object Flattener extends Transformer with TreeDSL {
  private var globalToFreeVar: Map[Symbol, Symbol] = _

  override def apply(): Unit = {
    val rawCode = program.rawCode
    program.rawCode = null

    withAbstraction(program.topLevelAbstraction) {
      program.topLevelAbstraction.body = transformStat(rawCode)
    }
  }

  private def withAbstraction[A](newAbs: Abstraction)(f: => A) = {
    val savedAbs = abstraction
    val savedGlobalToFreeVar = globalToFreeVar

    try {
      abstraction = newAbs
      globalToFreeVar = Map.empty
      f
    } finally {
      abstraction = savedAbs
      globalToFreeVar = savedGlobalToFreeVar
    }
  }

  override def transformStat(statement: Statement) = statement match {
    case LocalStatement(declarations, stat) =>
      for (variable <- declarations)
        abstraction.acquire(variable.symbol)

      transformStat(stat)

    case _ =>
      super.transformStat(statement)
  }

  override def transformExpr(expression: Expression) = expression match {
    case LocalExpression(declarations, expr) =>
      for (variable <- declarations)
        abstraction.acquire(variable.symbol)

      transformExpr(expr)

    case proc @ ProcExpression(name, args, body, flags) =>
      val abs = abstraction.newAbstraction(name, proc.pos)

      program.abstractions += abs

      for (Variable(symbol) <- args)
        abs.acquire(symbol)

      abs.flags ++= flags

      val (newBody, globalArgs) = withAbstraction(abs) {
        val newBody = transformStat(body)

        val globalArgs =
          for (global <- abs.globals.toList)
            yield Variable(globalToFreeVar(global))

        (newBody, globalArgs)
      }

      abs.body = newBody

      val newGlobalArgs = globalArgs map {
        g => transformExpr(g).asInstanceOf[Variable]
      }

      treeCopy.CreateAbstraction(proc,
          OzCodeArea(abs.codeArea), newGlobalArgs)

    case v @ Variable(sym) if v.symbol.owner ne abstraction =>
      val global = abstraction.freeVarToGlobal(sym)
      globalToFreeVar += global -> sym
      treeCopy.Variable(v, global)

    case _ =>
      super.transformExpr(expression)
  }
}
