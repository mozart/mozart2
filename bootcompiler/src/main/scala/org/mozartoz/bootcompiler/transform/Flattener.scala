package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable._

import ast._
import symtab._

object Flattener extends Transformer {
  private var globalToFreeVar: Map[VariableSymbol, VariableSymbol] = _

  override def apply() {
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

      treeCopy.CreateAbstraction(proc, abs, newGlobalArgs)

    case v @ FreeVar(name, sym) =>
      val global = abstraction.freeVarToGlobal(sym)
      globalToFreeVar += global -> sym
      treeCopy.Variable(v, name) withSymbol global

    case _ =>
      super.transformExpr(expression)
  }

  object FreeVar {
    def unapply(v: Variable) = {
      if (v.symbol.owner eq abstraction) None
      else (v.symbol match {
        case sym:VariableSymbol => Some((v.name, sym))
        case _ => None
      })
    }
  }
}
