package org.mozartoz.bootcompiler
package transform

import scala.collection.mutable.ListBuffer

import oz._
import ast._
import symtab._

/** Namer phase
 *
 *  The Namer is the first compilation phase of Oz. Its purpose is to link
 *  variable uses to their declaration.
 *
 *  Basically this phase turns all
 *  [[org.mozartoz.bootcompiler.ast.RawLocalStatement]] (resp.
 *  [[org.mozartoz.bootcompiler..ast.RawLocalExpression]]) to
 *  [[org.mozartoz.bootcompiler.ast.LocalStatement]] (resp.
 *  [[org.mozartoz.bootcompiler.ast.LocalExpression]]),
 *  creating a new [[org.mozartoz.bootcompiler.symtab.Symbol]] for each
 *  variable that is introduced.
 *
 *  It also turns all [[org.mozartoz.bootcompiler.ast.RawVariable]] to
 *  [[org.mozartoz.bootcompiler.ast.Variable]], linking them to the appropriate
 *  [[org.mozartoz.bootcompiler.symtab.Symbol]].
 *
 *  Variables introduced as captures in pattern matching are also given a
 *  [[org.mozartoz.bootcompiler.symtab.Symbol]], and their occurrence in the
 *  pattern is replaced by a
 *  [[org.mozartoz.bootcompiler.oz.OzPatMatCapture]].
 */
object Namer extends Transformer with TransformUtils with TreeDSL {
  /** Type of an environment */
  type Env = Map[String, Symbol]

  /** Current environment */
  private var env: Env = Map.empty

  /** Computes a sub expression with a new given environment
   *
   *  @param newEnv environment to use
   *  @param f sub expression to compute with the given environment
   *  @return result of `f` evaluated with the given environment
   */
  private def withEnvironment[A](newEnv: Env)(f: => A) = {
    val savedEnv = env
    env = newEnv
    try f
    finally env = savedEnv
  }

  /** Computes a sub expression with an environment extracted from declarations
   *
   *  @param decls declarations to include in the new environment
   *  @param f sub expression to compute with the given environment
   *  @return result of `f` evaluated with the given environment
   */
  private def withEnvironmentFromDecls[A](
      decls: List[Variable])(f: => A) = {
    val newEnv = (decls map (decl => decl.symbol.name -> decl.symbol))
    withEnvironment(env ++ newEnv)(f)
  }

  override def transformStat(statement: Statement) = statement match {
    /* Input:
     *   local D in S end
     * Output:
     *   local x1 .. xn in D' S end
     * where
     *   {x1 .. xn} = PV(D) which have been named
     *   D' = D without singleton variables
     */
    case local @ RawLocalStatement(declarations, body) =>
      val (decls, stats) = extractDecls(declarations)
      val stat = statsAndStatToStat(stats, body)

      withEnvironmentFromDecls(decls) {
        if (decls.isEmpty) transformStat(stat)
        else treeCopy.LocalStatement(local, decls, transformStat(stat))
      }

    /* Input:
     *   case E of C1 [] ... [] Cn [else S] end
     * Output:
     *   local c1 ... cn in
     *      case E of C1' [] ... [] Cn' [else S] end
     *   end
     * where
     *   {c1 .. cn} are new named capture variables for every captures in Cx
     *   Ci' = Ci where all captures have been replace by the named one
     */
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

    /* Input:
     *   try S1 catch X then S2 end
     * Output:
     *   local x in
     *      try S1 catch x then S2 end
     *   end
     * where
     *   x is a new named capture variable
     */
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
    /* Input:
     *   local D in E end
     * Output:
     *   local x1 .. xn in D' E end
     * where
     *   {x1 .. xn} = PV(D) which have been named
     *   D' = D without singleton variables
     */
    case local @ RawLocalExpression(declarations, body) =>
      val (decls, stats) = extractDecls(declarations)
      val expr = statsAndExprToExpr(stats, body)

      withEnvironmentFromDecls(decls) {
        if (decls.isEmpty) transformExpr(expr)
        else treeCopy.LocalExpression(local, decls, transformExpr(expr))
      }

    /* Input:
     *   case E of C1 [] ... [] Cn [else E2] end
     * Output:
     *   local c1 ... cn in
     *      case E of C1' [] ... [] Cn' [else E2] end
     *   end
     * where
     *   {c1 .. cn} are new named capture variables for every captures in Cx
     *   Ci' = Ci where all captures have been replace by the named one
     */
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

    /* Input:
     *   try E1 catch X then E2 end
     * Output:
     *   local x in
     *      try E1 catch x then E2 end
     *   end
     * where
     *   x is a new named capture variable
     */
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

    /* Input:
     *   proc {$ X1 .. Xn} S end
     * Output:
     *   proc {$ x1 .. xn} S end
     * where
     *   xi are new named formal parameters
     */
    case proc @ ProcExpression(name, args, body, flags) =>
      val namedFormals = nameFormals(args)

      withEnvironmentFromDecls(namedFormals) {
        treeCopy.ProcExpression(proc,
            name,
            namedFormals,
            transformStat(body),
            flags)
      }

    /* Input:
     *   fun {$ X1 .. Xn} E end
     * Output:
     *   fun {$ x1 .. xn} E end
     * where
     *   xi are new named formal parameters
     */
    case fun @ FunExpression(name, args, body, flags) =>
      val namedFormals = nameFormals(args)

      withEnvironmentFromDecls(namedFormals) {
        treeCopy.FunExpression(fun,
            name,
            namedFormals,
            transformExpr(body),
            flags)
      }

    /* See transformFunctor() */
    case functor: FunctorExpression =>
      transformFunctor(functor)

    /* See transformClass() */
    case clazz: ClassExpression =>
      transformClass(clazz)

    /* Input:
     *   X
     * Output:
     *   x
     * where x is the symbol found in the environment for X
     */
    case v @ RawVariable(name) =>
      val symbol = env.get(name)

      if (symbol.isDefined) {
        treeCopy.Variable(v, symbol.get)
      } else if (!program.isBaseEnvironment &&
          ((program.baseDeclarations contains name) || (name == "Base"))) {
        atPos(v)(baseEnvironment(name))
      } else {
        program.reportError("Undeclared variable "+name, v)
        transformExpr(atPos(v)(RAWLOCAL (v) IN (v)))
      }

    /* Input:
     *   !X
     * Output:
     *   X
     */
    case EscapedVariable(v) =>
      transformExpr(v)

    case _ =>
      super.transformExpr(expression)
  }

  // Begin transformations applied to functors

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

    // In base environment mode, add the declarations to the base symbols
    if (program.isBaseEnvironment) {
      for (Variable(symbol) <- decls)
        if (!(program.baseSymbols.contains(symbol.name)))
          program.baseSymbols += symbol.name -> symbol
    }

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

  // End transformations applied to functors

  // Begin transformations applied to classes

  /** Transform a class */
  def transformClass(clazz: ClassExpression): Expression = {
    val decls = classDeclarations(clazz)
    val namedDecls = nameDecls(decls)

    withEnvironmentFromDecls(namedDecls) {
      if (namedDecls.isEmpty) super.transformExpr(clazz)
      else {
        val initNames = CompoundStatement(for {
          decl <- namedDecls
        } yield {
          decl === (builtins.newName.callExpr())
        })

        treeCopy.LocalExpression(clazz, namedDecls,
            initNames ~> super.transformExpr(clazz))
      }
    }
  }

  /** Returns the raw variables that are implicitly introduced in a class */
  def classDeclarations(clazz: ClassExpression): List[RawVariable] = {
    val result = new ListBuffer[RawVariable]

    for (FeatOrAttr(nameVar: RawVariable, _) <- clazz.features)
      result += nameVar

    for (FeatOrAttr(nameVar: RawVariable, _) <- clazz.attributes)
      result += nameVar

    for (MethodDef(MethodHeader(
        nameVar: RawVariable, _, _), _, _) <- clazz.methods)
      result += nameVar

    result.toList
  }

  override def transformMethodDef(method: MethodDef) = {
    val MethodDef(header @ MethodHeader(name, params, open),
        messageVar, body) = method

    val namedParams = new ListBuffer[Variable]

    val newName = transformExpr(name)

    val newParams = for {
      (param @ MethodParam(feature, name, default)) <- params
    } yield {
      val newName = name match {
        case paramVar:RawVariable =>
          val namedParamVar = nameDecl(paramVar)
          namedParams += namedParamVar
          namedParamVar

        case _ =>
          name
      }

      val newDefault = default map transformExpr

      treeCopy.MethodParam(param, transformExpr(feature), newName, newDefault)
    }

    val newMessageVar = messageVar map { v =>
      val named = nameDecl(v.asInstanceOf[RawVariable])
      namedParams += named
      named
    }

    val newBody = withEnvironmentFromDecls(namedParams.toList) {
      body match {
        case stat:Statement => transformStat(stat)
        case expr:Expression => transformExpr(expr)
      }
    }

    treeCopy.MethodDef(method,
        treeCopy.MethodHeader(header, newName, newParams, open),
        newMessageVar, newBody)
  }

  // End transformations applied to classes

  /** Returns (named(PV(D)), D without singleton vars) for a given D */
  def extractDecls(
      declarations: List[RawDeclaration]): (List[Variable], List[Statement]) = {
    val decls = patternVariables(declarations).toList
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
      declarations: List[RawDeclaration]): Set[RawVariable] = {
    declarations.foldLeft(Set.empty[RawVariable]) {
      (prev, declaration) => prev ++ patternVariables(declaration)
    }
  }

  /** Compute the PV set for a single declaration
   *
   *  <a href="http://www.mozart-oz.org/documentation/notation/node6.html">
   *    Definition of the PV set</a>
   */
  private def patternVariables(
      declaration: RawDeclaration): Set[RawVariable] = declaration match {
    case v: RawVariable =>
      Set(v)

    case CompoundStatement(statements) =>
      patternVariables(statements)

    case RawLocalStatement(decls, stat) =>
      patternVariables(stat) filterNot (patternVariables(decls) contains)

    case lhs === rhs =>
      patternVariables(lhs)

    case _ =>
      Set.empty
  }

  /** Compute the PV set for an expression
   *
   *  <a href="http://www.mozart-oz.org/documentation/notation/node6.html">
   *    Definition of the PV set</a>
   */
  private def patternVariables(
      expression: Expression): Set[RawVariable] = expression match {
    case v: RawVariable =>
      Set(v)

    case StatAndExpression(statement, expr) =>
      patternVariables(statement) ++ patternVariables(expr)

    case RawLocalExpression(decls, expr) =>
      patternVariables(expr) -- patternVariables(decls)

    case BindExpression(lhs, rhs) =>
      patternVariables(lhs) ++ patternVariables(rhs)

    case Record(_, fields) =>
      fields.foldLeft(Set.empty[RawVariable]) {
        case (prev, (RecordField(_, value))) => prev ++ patternVariables(value)
      }

    case _ =>
      Set.empty
  }

  /** Processes a pattern */
  def processPattern(pattern: Expression): (List[Variable], Expression) = {
    val variables = new ListBuffer[Variable]
    val newPattern = processPatternInner(pattern, variables)
    (variables.toList, newPattern)
  }

  /** Processes a pattern (inner) */
  private def processPatternInner(pattern: Expression,
      variables: ListBuffer[Variable]): Expression = {

    def processRecordFields(fields: List[RecordField]) = {
      for (field @ RecordField(feature, value) <- fields) yield {
        val newValue = processPatternInner(value, variables)
        treeCopy.RecordField(field, feature, newValue)
      }
    }

    pattern match {
      /* Wildcard */
      case UnboundExpression() =>
        treeCopy.Constant(pattern, OzPatMatWildcard())

      /* Capture */
      case v @ RawVariable(name) =>
        val symbol = new Symbol(name, capture = true)
        variables += treeCopy.Variable(v, symbol)
        treeCopy.Constant(pattern, OzPatMatCapture(symbol))

      /* Dive into records */
      case record @ Record(label, fields) =>
        treeCopy.Record(record, label, processRecordFields(fields))

      /* Dive into open record patterns */
      case pattern @ OpenRecordPattern(label, fields) =>
        treeCopy.OpenRecordPattern(pattern, label, processRecordFields(fields))

      /* Dive into pattern conjunctions */
      case conj @ PatternConjunction(parts) =>
        val newParts = parts map (processPatternInner(_, variables))
        treeCopy.PatternConjunction(conj, newParts)

      /* Escaped variable */
      case EscapedVariable(v) =>
        transformExpr(v)

      case _ =>
        pattern
    }
  }

  /** Names a list of raw variables */
  def nameDecls(decls: List[RawVariable], capture: Boolean = false) = {
    for (v <- decls) yield
      nameDecl(v, capture = capture)
  }

  /** Names one raw variable */
  def nameDecl(decl: RawVariable, capture: Boolean = false) = {
    val symbol = new Symbol(decl.name, capture = capture)
    treeCopy.Variable(decl, symbol)
  }

  /** Names a list of formal parameters */
  def nameFormals(args: List[VariableOrRaw]) = {
    for (v @ RawVariable(name) <- args) yield {
      val symbol = new Symbol(name, formal = true)
      treeCopy.Variable(v, symbol)
    }
  }
}
