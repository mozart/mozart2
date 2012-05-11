package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable.ListBuffer

import oz._
import ast._
import symtab._

object Namer extends Transformer with TransformUtils with TreeDSL {
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
      val declsBuilder = new ListBuffer[Variable]
      val newClauses = {
        for {
          clause @ MatchStatementClause(pattern, guard, body) <- clauses
          (patternDecls, newPattern) = processPattern(pattern)
        } yield {
          declsBuilder ++= patternDecls
          withEnvironmentFromDecls(patternDecls) {
            transformClauseStat(
                treeCopy.MatchStatementClause(clause, newPattern, guard, body))
          }
        }
      }
      val decls = declsBuilder.toList

      val newMatchStat = treeCopy.MatchStatement(
          matchStat, transformExpr(value), newClauses, transformStat(elseStat))

      if (decls.isEmpty) newMatchStat
      else treeCopy.LocalStatement(newMatchStat, decls, newMatchStat)

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
      val declsBuilder = new ListBuffer[Variable]
      val newClauses = {
        for {
          clause @ MatchExpressionClause(pattern, guard, body) <- clauses
          (patternDecls, newPattern) = processPattern(pattern)
        } yield {
          declsBuilder ++= patternDecls
          withEnvironmentFromDecls(patternDecls) {
            transformClauseExpr(
                treeCopy.MatchExpressionClause(clause, newPattern, guard, body))
          }
        }
      }
      val decls = declsBuilder.toList

      val newMatchExpr = treeCopy.MatchExpression(
          matchExpr, transformExpr(value), newClauses, transformExpr(elseExpr))

      if (decls.isEmpty) newMatchExpr
      else treeCopy.LocalExpression(newMatchExpr, decls, newMatchExpr)

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

    case functor: FunctorExpression =>
      transformFunctor(functor)

    case v @ Variable(name) =>
      env.get(name) match {
        case Some(Left(symbol)) => treeCopy.Variable(v, name) withSymbol symbol
        case Some(Right(value)) => treeCopy.Constant(v, value)

        case _ =>
          program.reportError("Undeclared variable "+name, v.pos)
          transformExpr(LOCAL (v) IN (v))
      }

    case EscapedVariable(v) =>
      transformExpr(v)

    case _ =>
      super.transformExpr(expression)
  }

  private def transformFunctor(functor: FunctorExpression): Expression = {
    val FunctorExpression(name,
        require, prepare,
        imports, define,
        exports) = functor

    val (requireDecls, newRequire) = transformFunctorImports(require)

    withEnvironmentFromDecls(requireDecls) {
      val (prepareDecls, newPrepare) = transformFunctorDefine(prepare)

      withEnvironmentFromDecls(prepareDecls) {
        val (importsDecls, newImports) = transformFunctorImports(imports)

        withEnvironmentFromDecls(importsDecls) {
          val (defineDecls, newDefine) = transformFunctorDefine(define)

          withEnvironmentFromDecls(defineDecls) {
            val newExports = transformFunctorExports(exports)

            treeCopy.FunctorExpression(functor, name, newRequire,
                newPrepare, newImports, newDefine, newExports)
          }
        }
      }
    }
  }

  def transformFunctorImports(imports: List[FunctorImport]) = {
    val decls = new ListBuffer[Variable]
    val newImports = new ListBuffer[FunctorImport]

    def nameDecl(variable: Variable) = {
      val symbol = new VariableSymbol(variable.name)
      val decl = treeCopy.Variable(variable, variable.name) withSymbol symbol
      decls += decl
      decl
    }

    for (imp @ FunctorImport(module, aliases, location) <- imports) {
      val newModule = nameDecl(module)

      val newAliases = {
        for (aliased @ AliasedFeature(feature, alias) <- aliases) yield {
          treeCopy.AliasedFeature(aliased, feature, alias map nameDecl)
        }
      }

      newImports += treeCopy.FunctorImport(imp, newModule,
          newAliases, location)
    }

    (decls.toList, newImports.toList)
  }

  def transformFunctorDefine(define: Option[LocalStatement]) = {
    if (define.isEmpty) (Nil, define)
    else transformFunctionDefineInner(define.get)
  }

  def transformFunctionDefineInner(define: LocalStatement) = {
    val LocalStatement(declarations, body) = define

    val (decls, stats) = extractDecls(declarations)
    val stat = statsAndStatToStat(stats, body)

    val newDefine = withEnvironmentFromDecls(decls) {
      treeCopy.LocalStatement(define, decls, transformStat(stat))
    }

    (decls, Some(newDefine))
  }

  def transformFunctorExports(exports: List[FunctorExport]) = {
    for (export @ FunctorExport(feature, value: Variable) <- exports) yield {
      val newFeature = feature match {
        case AutoFeature() =>
          val strFeature = value.name.head.toLower + value.name.tail
          treeCopy.Constant(feature, OzAtom(strFeature))
        case _ =>
          feature
      }

      val newValue = transformExpr(value)

      treeCopy.FunctorExport(export, newFeature, newValue)
    }
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

  def processPattern(pattern: Expression): (List[Variable], Expression) = {
    pattern match {
      case UnboundExpression() =>
        (Nil, treeCopy.Constant(pattern, OzPatMatWildcard()))

      case v @ Variable(name) =>
        val symbol = new VariableSymbol(name, capture = true)
        val variable = treeCopy.Variable(v, name) withSymbol symbol
        (List(variable), treeCopy.Constant(pattern, OzPatMatCapture(symbol)))

      case record @ Record(label, fields) =>
        val variables = new ListBuffer[Variable]
        val newFields = {
          for (field @ RecordField(feature, value) <- fields) yield {
            val (subVars, newValue) = processPattern(value)
            variables ++= subVars
            treeCopy.RecordField(field, feature, newValue)
          }
        }
        val newRecord = treeCopy.Record(record, label, newFields)
        (variables.toList, newRecord)

      case _ =>
        (Nil, pattern)
    }
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
