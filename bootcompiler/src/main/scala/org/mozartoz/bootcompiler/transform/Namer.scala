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
    val newEnv = (decls map (decl => decl.symbol.name -> Left(decl.symbol)))
    withEnvironment(env ++ newEnv)(f)
  }

  override def transformStat(statement: Statement) = statement match {
    case local @ RawLocalStatement(declarations, body) =>
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

    case tryStat @ TryStatement(body, exceptionVar:RawVariable, catchBody) =>
      val newBody = transformStat(body)
      val namedExcVar = nameDecl(exceptionVar, capture = true)

      val newCatchBody = withEnvironmentFromDecls(List(namedExcVar)) {
        transformStat(catchBody)
      }

      atPos(tryStat) {
        LOCAL (namedExcVar) IN {
          treeCopy.TryStatement(tryStat, newBody, namedExcVar, newCatchBody)
        }
      }

    case _ =>
      super.transformStat(statement)
  }

  override def transformExpr(expression: Expression) = expression match {
    case local @ RawLocalExpression(declarations, body) =>
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

    case tryExpr @ TryExpression(body, exceptionVar:RawVariable, catchBody) =>
      val newBody = transformExpr(body)
      val namedExcVar = nameDecl(exceptionVar, capture = true)

      val newCatchBody = withEnvironmentFromDecls(List(namedExcVar)) {
        transformExpr(catchBody)
      }

      atPos(tryExpr) {
        LOCAL (namedExcVar) IN {
          treeCopy.TryExpression(tryExpr, newBody, namedExcVar, newCatchBody)
        }
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

    case functor: FunctorExpression =>
      transformFunctor(functor)

    case v @ RawVariable(name) =>
      env.get(name) match {
        case Some(Left(symbol)) => treeCopy.Variable(v, symbol)
        case Some(Right(value)) => treeCopy.Constant(v, value)

        case _ =>
          program.reportError("Undeclared variable "+name, v.pos)
          transformExpr(RAWLOCAL (v) IN (v))
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

    def nameDecl(variable: VariableOrRaw) = {
      val symbol = new Symbol(variable.asInstanceOf[RawVariable].name)
      val decl = treeCopy.Variable(variable, symbol)
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

  def transformFunctorDefine(define: Option[LocalStatementOrRaw]) = {
    if (define.isEmpty) (Nil, define)
    else transformFunctionDefineInner(define.get)
  }

  def transformFunctionDefineInner(define: LocalStatementOrRaw) = {
    val RawLocalStatement(declarations, body) = define

    val (decls, stats) = extractDecls(declarations)
    val stat = statsAndStatToStat(stats, body)

    val newDefine = withEnvironmentFromDecls(decls) {
      treeCopy.LocalStatement(define, decls, transformStat(stat))
    }

    (decls, Some(newDefine))
  }

  def transformFunctorExports(exports: List[FunctorExport]) = {
    for (export @ FunctorExport(feature, value: RawVariable) <- exports) yield {
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
      declarations: List[RawDeclaration]): (List[Variable], List[Statement]) = {
    val decls = patternVariables(declarations)
    val namedDecls = nameDecls(decls)

    val statements = for {
      decl <- declarations
      if decl.isInstanceOf[Statement]
    } yield decl.asInstanceOf[Statement]

    (namedDecls, statements)
  }

  /** Compute the PV set for a list of declarations
   *
   *  <a href="http://www.mozart-oz.org/documentation/notation/node6.html">
   *    Definition of the PV set</a>
   */
  private def patternVariables(
      declarations: List[RawDeclaration]): List[RawVariable] = {
    declarations flatMap patternVariables
  }

  /** Compute the PV set for a single declaration
   *
   *  <a href="http://www.mozart-oz.org/documentation/notation/node6.html">
   *    Definition of the PV set</a>
   */
  private def patternVariables(
      declaration: RawDeclaration): List[RawVariable] = declaration match {
    case v: RawVariable =>
      List(v)

    case CompoundStatement(statements) =>
      patternVariables(statements)

    case RawLocalStatement(decls, stat) =>
      patternVariables(stat) filterNot (patternVariables(decls) contains)

    case lhs === rhs =>
      patternVariables(lhs)

    case _ =>
      Nil
  }

  /** Compute the PV set for an expression
   *
   *  <a href="http://www.mozart-oz.org/documentation/notation/node6.html">
   *    Definition of the PV set</a>
   */
  private def patternVariables(
      expression: Expression): List[RawVariable] = expression match {
    case v: RawVariable =>
      List(v)

    case StatAndExpression(statement, expr) =>
      patternVariables(statement) ++ patternVariables(expr)

    case RawLocalExpression(decls, expr) =>
      patternVariables(expr) filterNot (patternVariables(decls) contains)

    case BindExpression(lhs, rhs) =>
      patternVariables(lhs) ++ patternVariables(rhs)

    case Record(_, fields) =>
      for {
        RecordField(_, value) <- fields
        v <- patternVariables(value)
      } yield v

    case _ =>
      Nil
  }

  def processPattern(pattern: Expression): (List[Variable], Expression) = {
    pattern match {
      case UnboundExpression() =>
        (Nil, treeCopy.Constant(pattern, OzPatMatWildcard()))

      case v @ RawVariable(name) =>
        val symbol = new Symbol(name, capture = true)
        val variable = treeCopy.Variable(v, symbol)
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

  def nameDecls(decls: List[RawVariable], capture: Boolean = false) = {
    for (v <- decls) yield
      nameDecl(v)
  }

  def nameDecl(decl: RawVariable, capture: Boolean = false) = {
    val symbol = new Symbol(decl.name, capture = capture)
    treeCopy.Variable(decl, symbol)
  }

  def nameFormals(args: List[FormalArg]) = {
    for (v @ RawVariable(name) <- args) yield {
      val symbol = new Symbol(name, formal = true)
      treeCopy.Variable(v, symbol)
    }
  }
}
