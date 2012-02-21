package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable.HashMap

import ast._
import symtab._

object Flattener extends Transformer {
  private var program: Program = _

  override def apply(prog: Program) {
    program = prog
    try {
      val rawCode = prog.rawCode
      program.rawCode = null

      withAbstraction(prog.topLevelAbstraction) {
        prog.topLevelAbstraction.body = transformStat(rawCode)
      }
    } finally {
      program = null
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
        v.symbol.setOwner(abstraction)

      super.transformStat(statement)

    case _ =>
      super.transformStat(statement)
  }

  override def transformExpr(expression: Expression) = expression match {
    case LocalExpression(declarations, expr) =>
      for (v @ Variable(_) <- declarations)
        v.symbol.setOwner(abstraction)

      super.transformExpr(expression)

    case proc @ ProcExpression(name, args, body, flags) =>
      val abs = abstraction.newAbstraction(name)

      program.abstractions += abs

      abs.flags ++= flags map (_.value)

      abs.body = withAbstraction(abs) {
        transformStat(body)
      }

      treeCopy.ProcExpression(proc, name, args,
          treeCopy.SkipStatement(body), flags)

    case fun @ FunExpression(name, args, body, flags) =>
      val resultVarSym = new VariableSymbol("<Result>",
          formal = true, synthetic = true)
      val resultVar = treeCopy.Variable(args,
          resultVarSym.name) withSymbol resultVarSym

      val newArgs = treeCopy.FormalArgs(args, args.args :+ resultVar)

      val newBody = treeCopy.BindStatement(body,
          treeCopy.Variable(resultVar, resultVar.name),
          body)

      val proc = treeCopy.ProcExpression(fun, name, newArgs, newBody, flags)
      transformExpr(proc)

    case _ =>
      super.transformExpr(expression)
  }
}
