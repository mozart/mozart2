package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable.ListBuffer

import oz._
import ast._
import symtab._

object Namer extends Transformer with TransformUtils {
  type EnvValue = Symbol Either OzValue
  type Env = Map[String, EnvValue]

  private var env: Env = _

  override def apply(prog: Program) {
    val topLevelEnvironemnt: Env =
      prog.builtins.topLevelEnvironment.mapValues(v => Right(v))

    withEnvironment(topLevelEnvironemnt) {
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
    val newEnv = (decls map (decl => decl.name -> Left(decl.symbol)))
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

    case matchStat @ MatchStatement(value, clauses, elseStat) =>
      val decls = extractDecls(clauses)

      withEnvironmentFromDecls(decls) {
        val transformedStat = super.transformStat(matchStat)
        if (decls.isEmpty) transformedStat
        else treeCopy.LocalStatement(matchStat, decls, transformedStat)
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

    case matchExpr @ MatchExpression(value, clauses, elseExpr) =>
      val decls = extractDecls(clauses)

      withEnvironmentFromDecls(decls) {
        val transformedExpr = super.transformExpr(matchExpr)
        if (decls.isEmpty) transformedExpr
        else treeCopy.LocalExpression(matchExpr, decls, transformedExpr)
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
      env(name) match {
        case Left(symbol) => treeCopy.Variable(v, name) withSymbol symbol
        case Right(value) => treeCopy.Constant(v, value)
      }

    case EscapedVariable(v) =>
      transformExpr(v)

    case _ =>
      super.transformExpr(expression)
  }

  def extractDecls(
      declarations: List[Declaration]): (List[Variable], List[Statement]) = {
    val decls = new ListBuffer[Variable]
    val statements = new ListBuffer[Statement]

    def process(declarations: List[Declaration]) {
      for (declaration <- declarations) {
        declaration match {
          case variable:Variable =>
            decls += variable

          case stat @ BindStatement(left, right) =>
            decls ++= extractDeclsInExpression(left)
            statements += stat

          case stat @ LocalStatement(subDecls, subStat) =>
            val (declsInside, statsInside) = extractDecls(List(subStat))
            decls ++= declsInside
            statements += treeCopy.LocalStatement(stat, subDecls,
                statementsToStatement(statsInside))

          case stat @ CompoundStatement(subStatements) =>
            process(subStatements)

          case stat:Statement =>
            statements += stat
        }
      }
    }

    process(declarations)

    val namedDecls = nameDecls(decls.toList)

    (namedDecls, statements.toList)
  }

  def extractDecls(clauses: List[MatchClauseCommon]) = {
    // Extract the captures in all clauses
    val captures = clauses flatMap {
      clause => extractDeclsInExpression(clause.pattern)
    }

    // Name the captures
    nameDecls(captures, capture = true)
  }

  def extractDeclsInExpression(expr: Expression): List[Variable] = expr match {
    case variable:Variable =>
      List(variable)

    case Record(label, fields) =>
      for {
        RecordField(_, value) <- fields
        variable <- extractDeclsInExpression(value)
      } yield variable

    case _ =>
      Nil
  }

  def nameDecls(decls: List[Variable], capture: Boolean = false) = {
    for (v @ Variable(name) <- decls) yield {
      val symbol = new VariableSymbol(name, capture = capture)
      treeCopy.Variable(v, name) withSymbol symbol
    }
  }

  def nameFormals(args: List[FormalArg]) = {
    for (v @ Variable(name) <- args) yield {
      val symbol = new VariableSymbol(name, formal = true)
      treeCopy.Variable(v, name) withSymbol symbol
    }
  }
}
