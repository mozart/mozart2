package org.mozartoz.bootcompiler
package transform

import ast._
import symtab._

object Desugar extends Transformer {
  override def transformStat(statement: Statement) = statement match {
    case thread @ ThreadStatement(body) =>
      val proc = treeCopy.ProcExpression(thread, "", FormalArgs(Nil),
          transformStat(body), Nil)

      treeCopy.CallStatement(thread,
          Variable(builtins.CreateThread),
          ActualArgs(List(proc)))

    case _ =>
      super.transformStat(statement)
  }

  override def transformExpr(expression: Expression) = expression match {
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

    case thread @ ThreadExpression(body) =>
      val resultSymbol = Symbol.newSynthetic()

      val threadStatement0 = treeCopy.ThreadStatement(thread,
          BindStatement(Variable(resultSymbol), body))

      val threadStatement = transformStat(threadStatement0)

      newSyntheticLocal(resultSymbol,
          StatAndExpression(threadStatement, Variable(resultSymbol)))

    case _ =>
      super.transformExpr(expression)
  }

  def newSyntheticLocal(symbol: Symbol, expr: Expression) =
    LocalExpression(List(Variable(symbol)), expr)
}
