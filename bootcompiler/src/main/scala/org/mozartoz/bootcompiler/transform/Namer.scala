package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable.HashMap

import ast._
import symtab._

object Namer extends Transformer {
  type Env = Map[String, Symbol]

  private var program: Program = _
  private var env: Env = _

  override def apply(prog: Program) {
    program = prog
    try {
      val rawCode = prog.rawCode
      program.rawCode = null

      withAbstraction(prog.topLevelAbstraction) {
        withEnvironment(prog.builtins.topLevelEnvironment) {
          prog.topLevelAbstraction.body = transformStat(rawCode)
        }
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

  private def withEnvironment[A](newEnv: Env)(f: => A) = {
    val savedEnv = env
    env = newEnv
    try f
    finally env = savedEnv
  }

  private def withEnvironmentFromDecls[A](
      declarations: List[Declaration])(f: => A) = {
    val newEnv = new HashMap[String, Symbol]

    for (RawVariable(name) <- declarations) {
      newEnv += name -> abstraction.newLocal(name)
    }

    withEnvironment(env ++ newEnv)(f)
  }

  override def transformStat(stat: Statement) = stat match {
    case LocalStatement(declarations, statement) =>
      withEnvironmentFromDecls(declarations) {
        transformStat(statement)
      }

    case _ => super.transformStat(stat)
  }

  override def transformExpr(expr: Expression) = expr match {
    case LocalExpression(declarations, expression) =>
      withEnvironmentFromDecls(declarations) {
        transformExpr(expression)
      }

    case RawVariable(name) =>
      Variable(env(name))

    case EscapedVariable(RawVariable(name)) =>
      Variable(env(name))

    case ProcExpression(name, args, body, flags) =>
      makeAbstractionValue(name, args, flags) { abs => body }

    case FunExpression(name, args, body, flags) =>
      makeAbstractionValue(name, args, flags) { abs =>
        val resultVar = abs.newFormal("<Result>")
        BindStatement(Variable(resultVar), body)
      }

    case _ => super.transformExpr(expr)
  }

  private def makeAbstractionValue(name: String, args: FormalArgs,
      flags: List[Atom])(absToBody: Abstraction => Statement) = {
    val abs = abstraction.newAbstraction(name)

    program.abstractions += abs

    var innerEnv = new HashMap[String, Symbol]
    for (RawVariable(arg) <- args.args)
      innerEnv += arg -> abs.newFormal(arg)

    abs.flags ++= flags map (_.value)

    abs.body = withAbstraction(abs) {
        withEnvironment(env ++ innerEnv) {
          transformStat(absToBody(abs))
        }
      }

    AbstractionValue(abs)
  }
}
