package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable.ListBuffer

import ast._
import symtab._

object Namer extends Transformer with TransformUtils {
  type Env = Map[String, Symbol]

  private var env: Env = _

  override def apply(prog: Program) {
    withEnvironment(prog.builtins.topLevelEnvironment) {
      super.apply(prog)
    }
  }

  private def withEnvironment[A](newEnv: Env)(f: => A) = {
    val savedEnv = env
    env = newEnv
    try f
    finally env = savedEnv
  }

  private def withEnvironmentFromDecls[A](
      decls: List[Variable])(f: => A) = {
    val newEnv = (decls map (decl => decl.name -> decl.symbol))
    withEnvironment(env ++ newEnv)(f)
  }

  override def transformStat(statement: Statement) = statement match {
    case local @ LocalStatement(declarations, body) =>
      val (decls, stats) = extractDecls(declarations)
      val stat = statsAndStatToStat(stats, body)

      withEnvironmentFromDecls(decls) {
        if (decls.isEmpty) transformStat(stat)
        else treeCopy.LocalStatement(local, decls, transformStat(stat))
      }

    case _ =>
      super.transformStat(statement)
  }

  override def transformExpr(expression: Expression) = expression match {
    case local @ LocalExpression(declarations, body) =>
      val (decls, stats) = extractDecls(declarations)
      val expr = statsAndExprToExpr(stats, body)

      withEnvironmentFromDecls(decls) {
        if (decls.isEmpty) transformExpr(expr)
        else treeCopy.LocalExpression(local, decls, transformExpr(expr))
      }

    case proc @ ProcExpression(name, args, body, flags) =>
      val namedFormals = nameFormals(args)

      withEnvironmentFromDecls(namedFormals) {
        treeCopy.ProcExpression(proc,
            name,
            namedFormals,
            transformStat(body),
            flags)
      }

    case fun @ FunExpression(name, args, body, flags) =>
      val namedFormals = nameFormals(args)

      withEnvironmentFromDecls(namedFormals) {
        treeCopy.FunExpression(fun,
            name,
            namedFormals,
            transformExpr(body),
            flags)
      }

    case v @ Variable(name) =>
      treeCopy.Variable(v, name) withSymbol env(name)

    case EscapedVariable(v) =>
      transformExpr(v)

    case _ =>
      super.transformExpr(expression)
  }

  def extractDecls(
      declarations: List[Declaration]): (List[Variable], List[Statement]) = {
    val decls = new ListBuffer[Variable]
    val statements = new ListBuffer[Statement]

    for (declaration <- declarations) {
      declaration match {
        case variable:Variable =>
          decls += variable

        case stat @ BindStatement(left, right) =>
          decls ++= extractDeclsInExpression(left)
          statements += stat

        case stat:Statement =>
          statements += stat
      }
    }

    val namedDecls = for (v@Variable(name) <- decls.toList)
      yield treeCopy.Variable(v, name) withSymbol new VariableSymbol(name)

    (namedDecls, statements.toList)
  }

  def extractDeclsInExpression(expr: Expression) = expr match {
    case variable:Variable =>
      List(variable)

    case _ =>
      Nil
  }

  def nameFormals(args: List[FormalArg]) = {
    for (v @ Variable(name) <- args) yield {
      val symbol = new VariableSymbol(name, formal = true)
      treeCopy.Variable(v, name) withSymbol symbol
    }
  }
}
