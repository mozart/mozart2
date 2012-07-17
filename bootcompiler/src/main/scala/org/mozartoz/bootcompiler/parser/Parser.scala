package org.mozartoz.bootcompiler
package parser

import java.io.File

import scala.util.parsing.combinator._
import scala.util.parsing.combinator.syntactical._
import scala.util.parsing.input._

import oz._
import ast._

object OzParser {
  private val generatedIdentCounter = new util.Counter

  private def generateExcIdent() =
    "<exc$" + generatedIdentCounter.next() + ">"
}

/**
 * The main Oz parser
 */
class OzParser extends OzTokenParsers with PackratParsers
    with ImplicitConversions {

  import OzParser.generateExcIdent

  lexical.reserved ++= List(
      "andthen", "at", "attr", "case", "catch", "choice",
      "class", "cond", "declare", "define", "dis",
      "div", "else", "elsecase", "elseif", "end",
      "export", "fail", "false", "feat", "finally", "from",
      "fun", "functor", "if", "import", "in", "local",
      "lock", "meth", "mod", "not", "of", "or", "orelse",
      "prepare", "proc", "prop", "raise", "require",
      "self", "skip", "then", "thread", "true", "try",
      "unit"
  )

  lexical.delimiters ++= List(
      "(", ")", "[", "]", "{", "}",
      "|", "#", ":", "...", "=", ".", ":=", "^", "[]", "$",
      "!", "_", "~", "+", "-", "*", "/", "@", "<-",
      ",", "!!", "<=", "==", "\\=", "<", "=<", ">",
      ">=", "=:", "\\=:", "<:", "=<:", ">:", ">=:", "::", ":::"
  )

  def parseStatement(input: Reader[Char], file: File) =
    phrase(statement)(makePreprocessor(input, file))

  def parseExpression(input: Reader[Char], file: File) =
    phrase(expression)(makePreprocessor(input, file))

  private def makePreprocessor(input: Reader[Char], file: File) =
    new Preprocessor(new lexical.Scanner(input), file)

  // Statements

  lazy val statement: PackratParser[Statement] =
    rep1(oneStatement) ^^ CompoundStatement

  lazy val oneStatement: PackratParser[Statement] = (
      operatorStatement
    | "local" ~> inStatement <~ "end"
    | "(" ~> inStatement <~ ")"
    | procStatement
    | funStatement
    | callStatement
    | ifStatement
    | caseStatement
    | threadStatement
    | lockStatement
    | tryStatement
    | raiseStatement
    | functorStatement
    | classStatement
    | skipStatement
  )

  // Expressions

  lazy val expression: PackratParser[Expression] =
    expression0

  // Declarations

  lazy val inStatement: PackratParser[Statement] = (
      positioned((declarations <~ "in") ~ statement ^^ RawLocalStatement)
    | statement
  )

  lazy val inExpression: PackratParser[Expression] = (
      positioned((declarations <~ "in") ~ statExpression ^^ RawLocalExpression)
    | statExpression
  )

  lazy val statExpression: PackratParser[Expression] = positioned(
      expression
  ||| positioned(oneStatement ~ statExpression ^^ StatAndExpression)
  )

  lazy val declarations: PackratParser[List[RawDeclaration]] =
    declaration+

  lazy val declaration: PackratParser[RawDeclaration] = (
      oneStatement
    | variable
  )

  // Procedure and function definition

  lazy val procStatement: PackratParser[Statement] = positioned {
    (("proc" ~> procFlags <~ "{") ~ expression ~ formalArgs <~ "}") ~ inStatement <~ "end" ^^ {
      case flags ~ left ~ args ~ body =>
        BindStatement(left, ProcExpression(nameOf(left), args, body, flags))
    }
  }

  lazy val funStatement: PackratParser[Statement] = positioned {
    (("fun" ~> procFlags <~ "{") ~ expression ~ formalArgs <~ "}") ~ inExpression <~ "end" ^^ {
      case flags ~ left ~ args ~ body =>
        BindStatement(left, FunExpression(nameOf(left), args, body, flags))
    }
  }

  lazy val procExpression: PackratParser[Expression] = positioned {
    (("proc" ~> procFlags <~ "{" ~ "$") ~ formalArgs <~ "}") ~ inStatement <~ "end" ^^ {
      case flags ~ args ~ body => ProcExpression("", args, body, flags)
    }
  }

  lazy val funExpression: PackratParser[Expression] = positioned {
    (("fun" ~> procFlags <~ "{" ~ "$") ~ formalArgs <~ "}") ~ inExpression <~ "end" ^^ {
      case flags ~ args ~ body => FunExpression("", args, body, flags)
    }
  }

  lazy val procFlags = rep(atomConst ^^ (_.value))

  lazy val formalArgs = rep(formalArg)

  lazy val formalArg = variable

  // Call

  lazy val callStatement: PackratParser[Statement] = positioned {
    "{" ~> expression ~ actualArgs <~ "}" ^^ CallStatement
  }

  lazy val callExpression: PackratParser[Expression] = positioned {
    "{" ~> expression ~ actualArgs <~ "}" ^^ CallExpression
  }

  lazy val actualArgs = rep(expression)

  // If then else end

  lazy val ifStatement: PackratParser[Statement] = positioned {
    "if" ~> innerIfStatement <~ "end"
  }

  lazy val ifExpression: PackratParser[Expression] = positioned {
    "if" ~> innerIfExpression <~ "end"
  }

  lazy val innerIfStatement: PackratParser[Statement] = // !positioned
    expression ~ ("then" ~> inStatement) ~ elseStatement ^^ IfStatement

  lazy val innerIfExpression: PackratParser[Expression] = // !positioned
    expression ~ ("then" ~> inExpression) ~ elseExpression ^^ IfExpression

  // case of

  lazy val caseStatement: PackratParser[Statement] = positioned {
    "case" ~> innerCaseStatement <~ "end"
  }

  lazy val caseExpression: PackratParser[Expression] = positioned {
    "case" ~> innerCaseExpression <~ "end"
  }

  lazy val innerCaseStatement: PackratParser[Statement] = ( // !positioned
      expression ~ ("of" ~> caseStatementClauses) ~ elseStatement
          ^^ MatchStatement
  )

  lazy val innerCaseExpression: PackratParser[Expression] = ( // !positioned
      expression ~ ("of" ~> caseExpressionClauses) ~ elseExpressionCase
          ^^ MatchExpression
  )

  lazy val caseStatementClauses: PackratParser[List[MatchStatementClause]] =
    rep1(caseStatementClause, "[]" ~> caseStatementClause)

  lazy val caseStatementClause: PackratParser[MatchStatementClause] = (
      positioned(
          pattern ~ opt("andthen" ~> expression) ~ ("then" ~> inStatement)
              ^^ MatchStatementClause)
  )

  lazy val caseExpressionClauses: PackratParser[List[MatchExpressionClause]] =
    rep1(caseExpressionClause, "[]" ~> caseExpressionClause)

  lazy val caseExpressionClause: PackratParser[MatchExpressionClause] = (
      positioned(
          pattern ~ opt("andthen" ~> expression) ~ ("then" ~> inExpression)
              ^^ MatchExpressionClause)
  )

  lazy val pattern: PackratParser[Expression] = (
      positioned((pattern1 <~ "|") ~ pattern ^^ cons)
    | pattern1
  )

  lazy val pattern1: PackratParser[Expression] = (
      pattern2 ~ rep1("#" ~> pattern2) ^^ { case f ~ r => sharp(f :: r) }
    | pattern2
  )

  lazy val pattern2: PackratParser[Expression] = (
      // TODO escaped variable (and <pattern> = <pattern> ?)
      positioned {
        literalLabelExpr ~ rep(patternRecordField) ~ opt("...") <~ ")" ^^ {
          case label ~ fields ~ openMarker =>
            if (openMarker.isEmpty) Record(label, fields)
            else OpenRecordPattern(label, fields)
        }
      }
    | positioned("[" ~> rep1(pattern) <~ "]" ^^ exprListToListExpr)
    | integerConstExpr | floatConstExpr | literalConstExpr
    | variable
    | wildcardExpr
    | "(" ~> pattern <~ ")"
  )

  lazy val patternRecordField: PackratParser[RecordField] =
    positioned(optFeatureNoVar ~ pattern ^^ RecordField)

  lazy val optFeatureNoVar: PackratParser[Expression] =
    positioned(opt(featureNoVar <~ ":") ^^ (_.getOrElse(AutoFeature())))

  // else clauses of if and case

  lazy val elseStatement: PackratParser[Statement] = (
      "else" ~> inStatement
    | positioned("elseif" ~> innerIfStatement)
    | positioned("elsecase" ~> innerCaseStatement)
    | positioned(success(SkipStatement()))
  )

  lazy val elseExpression: PackratParser[Expression] = (
      "else" ~> inExpression
    | positioned("elseif" ~> innerIfExpression)
    | positioned("elsecase" ~> innerCaseExpression)
  )

  lazy val elseExpressionCase: PackratParser[Expression] = (
      elseExpression
    | positioned(success(Constant(OzAtom("matchError"))))
  )

  // Thread

  lazy val threadStatement: PackratParser[Statement] = positioned {
    "thread" ~> inStatement <~ "end" ^^ ThreadStatement
  }

  lazy val threadExpression: PackratParser[Expression] = positioned {
    "thread" ~> inExpression <~ "end" ^^ ThreadExpression
  }

  // Lock

  lazy val lockStatement: PackratParser[Statement] = positioned {
    "lock" ~> opt(expression <~ "then") ~ inStatement <~ "end" ^^ {
      case Some(lock) ~ body => LockStatement(lock, body)
      case None ~ body => LockObjectStatement(body)
    }
  }

  lazy val lockExpression: PackratParser[Expression] = positioned {
    "lock" ~> opt(expression <~ "then") ~ inExpression <~ "end" ^^ {
      case Some(lock) ~ body => LockExpression(lock, body)
      case None ~ body => LockObjectExpression(body)
    }
  }

  // Try

  lazy val tryStatement: PackratParser[Statement] = positioned {
    ("try" ~> inStatement) ~ opt("catch" ~> caseStatementClauses) ~
      opt("finally" ~> inStatement) <~ "end" ^^ {

      case body ~ optCatchClauses ~ optFinallyBody =>
        val tryCatch = optCatchClauses match {
          case None => body
          case Some(catchClauses) =>
            val excVar = RawVariable(generateExcIdent())

            TryStatement(body, excVar,
              MatchStatement(excVar, catchClauses, RaiseStatement(excVar)))
        }

        optFinallyBody match {
          case None => tryCatch
          case Some(finallyBody) => TryFinallyStatement(tryCatch, finallyBody)
        }
    }
  }

  lazy val tryExpression: PackratParser[Expression] = positioned {
    ("try" ~> inExpression) ~ opt("catch" ~> caseExpressionClauses) ~
      opt("finally" ~> inStatement) <~ "end" ^^ {

      case body ~ optCatchClauses ~ optFinallyBody =>
        val tryCatch = optCatchClauses match {
          case None => body
          case Some(catchClauses) =>
            val excVar = RawVariable(generateExcIdent())

            TryExpression(body, excVar,
              MatchExpression(excVar, catchClauses, RaiseExpression(excVar)))
        }

        optFinallyBody match {
          case None => tryCatch
          case Some(finallyBody) => TryFinallyExpression(tryCatch, finallyBody)
        }
    }
  }

  // Raise

  lazy val raiseStatement: PackratParser[Statement] = positioned {
    "raise" ~> inExpression <~ "end" ^^ RaiseStatement
  }

  lazy val raiseExpression: PackratParser[Expression] = positioned {
    "raise" ~> inExpression <~ "end" ^^ RaiseExpression
  }

  // Operator statement

  lazy val operatorStatement: PackratParser[Statement] = positioned(
      (expression1 <~ "=") ~ expression0 ^^ BindStatement
    | expression12andDot ~ (expression13 <~ ":=") ~ expression1 ^^ DotAssignStatement
    | expression2 ~ ("<-" | ":=") ~ expression1 ^^ BinaryOpStatement
    | expression11 ~ "," ~ expression10 ^^ BinaryOpStatement
  )

  // Functor

  lazy val functorStatement: PackratParser[Statement] = positioned {
    "functor" ~> expression ~ innerFunctor <~ "end" ^^ {
      case lhs ~ functor =>
        BindStatement(lhs, functor.copy(name = nameOf(lhs)))
    }
  }

  lazy val functorExpression: PackratParser[Expression] =
    "functor" ~> opt("$") ~> innerFunctor <~ "end"

  lazy val innerFunctor: PackratParser[FunctorExpression] = positioned {
    require ~ prepare ~ imports ~ exports ~ define ^^ {
      case r ~ p ~ i ~ e ~ d => FunctorExpression("", r, p, i, d, e)
    }
  }

  lazy val require: PackratParser[List[FunctorImport]] =
    opt("require" ~> rep(importElem)) ^^ (_.getOrElse(Nil))

  lazy val prepare: PackratParser[Option[RawLocalStatement]] =
    opt("prepare" ~> defineBody)

  lazy val imports: PackratParser[List[FunctorImport]] =
    opt("import" ~> rep(importElem)) ^^ (_.getOrElse(Nil))

  lazy val exports: PackratParser[List[FunctorExport]] =
    opt("export" ~> rep(exportElem)) ^^ (_.getOrElse(Nil))

  lazy val define: PackratParser[Option[RawLocalStatement]] =
    opt("define" ~> defineBody)

  lazy val importElem: PackratParser[FunctorImport] = positioned(
      variable ~ success(Nil) ~ opt(importLocation) ^^ FunctorImport
    | variableLabel ~ (rep(importAlias) <~ ")") ~ opt(importLocation) ^^ FunctorImport
  )

  lazy val variableLabel: PackratParser[RawVariable] = positioned {
    identLabel ^^ RawVariable
  }

  lazy val importAlias: PackratParser[AliasedFeature] = positioned {
    featureNoVar ~ opt(":" ~> variable) ^^ AliasedFeature
  }

  lazy val importLocation: PackratParser[String] =
    "at" ~> atomConst ^^ (_.value)

  lazy val exportElem: PackratParser[FunctorExport] = positioned {
    exportFeature ~ variable ^^ FunctorExport
  }

  lazy val exportFeature: PackratParser[Expression] = positioned {
    opt(featureNoVar <~ ":") ^^ (_ getOrElse AutoFeature())
  }

  lazy val defineBody: PackratParser[RawLocalStatement] = positioned {
    declarations ~ opt("in" ~> statement) ^^ {
      case decls ~ optStat =>
        RawLocalStatement(decls, optStat getOrElse SkipStatement())
    }
  }

  lazy val featureNoVar = positioned(featureConst ^^ Constant)

  // Class

  lazy val classStatement: PackratParser[Statement] = positioned {
    "class" ~> expression ~ positioned(classContents) <~ "end" ^^ {
      case lhs ~ clazz =>
        BindStatement(lhs, clazz.copy(name = nameOf(lhs)))
    }
  }

  lazy val classExpression: PackratParser[Expression] = positioned {
    "class" ~> opt("$") ~> classContents <~ "end"
  }

  lazy val classContents = {
    rep(classContentsItem) ^^ {
      _.foldLeft(partialClass())(mergePartialClasses)
    }
  }

  lazy val classContentsItem: PackratParser[ClassExpression] = (
      "from" ~> rep(expression) ^^ (p => partialClass(parents = p))
    | "feat" ~> rep(classFeatOrAttr) ^^ (f => partialClass(features = f))
    | "attr" ~> rep(classFeatOrAttr) ^^ (a => partialClass(attributes = a))
    | "prop" ~> rep(expression) ^^ (p => partialClass(properties = p))
    | classMethod ^^ (m => partialClass(methods = List(m)))
  )

  lazy val classFeatOrAttr: PackratParser[FeatOrAttr] = positioned {
    attrOrFeat ~ opt(":" ~> expression) ^^ FeatOrAttr
  }

  lazy val classMethod: PackratParser[MethodDef] = positioned {
    "meth" ~> methodHeader >> { header =>
      opt("=" ~> variable) ~ methodBody(header) <~ "end" ^^ {
        case messageVar ~ body => MethodDef(header, messageVar, body)
      }
    }
  }

  lazy val methodHeader: PackratParser[MethodHeader] = positioned(
      methodHeaderWithoutArgs ^^ (label => MethodHeader(label, Nil, false))
    | methodHeaderLabel ~ rep(methodParam) ~ opt("...") <~ ")" ^^ {
        case label ~ params ~ open =>
          MethodHeader(label, params, open.isDefined)
      }
  )

  lazy val methodHeaderWithoutArgs: PackratParser[Expression] =
    variable | escapedVariable | literalConstExpr

  lazy val methodHeaderLabel: PackratParser[Expression] = (
      literalLabelExpr
    | identLabelExpr
    | positioned("!" ~> identLabelExpr ^^ EscapedVariable)
  )

  lazy val methodParam: PackratParser[MethodParam] = positioned {
    methodParamFeat ~ methodParamName ~ opt("<=" ~> expression) ^^ MethodParam
  }

  lazy val methodParamFeat: PackratParser[Expression] = positioned {
    opt(featureNoVar <~ ":") ^^ (x => x.getOrElse(AutoFeature()))
  }

  lazy val methodParamName: PackratParser[Expression] =
    variable | wildcardExpr | nestingMarker

  def methodBody(header: MethodHeader) = {
    if (header.params exists (_.name.isInstanceOf[NestingMarker]))
      inExpression
    else
      inStatement
  }

  def partialClass(name: String = "", parents: List[Expression] = Nil,
      features: List[FeatOrAttr] = Nil, attributes: List[FeatOrAttr] = Nil,
      properties: List[Expression] = Nil, methods: List[MethodDef] = Nil) =
    ClassExpression(name, parents, features, attributes, properties, methods)

  def mergePartialClasses(lhs: ClassExpression, rhs: ClassExpression) = {
    val ClassExpression(lhsName, lhsParents, lhsFeatures, lhsAttributes,
        lhsProperties, lhsMethods) = lhs

    val ClassExpression(rhsName, rhsParents, rhsFeatures, rhsAttributes,
        rhsProperties, rhsMethods) = rhs

    ClassExpression(if (lhsName.isEmpty) rhsName else lhsName,
        lhsParents ::: rhsParents, lhsFeatures ::: rhsFeatures,
        lhsAttributes ::: rhsAttributes, lhsProperties ::: rhsProperties,
        lhsMethods ::: rhsMethods)
  }

  // Skip

  lazy val skipStatement: PackratParser[Statement] = positioned {
    "skip" ^^^ SkipStatement()
  }

  // Operations with precedence

  lazy val expression0: PackratParser[Expression] = (
      positioned((expression1 <~ "=") ~ expression0 ^^ BindExpression)
    | expression1
  )

  // X<-Y   X:=Y   X.Y:=Z   (right-associative)
  lazy val expression1: PackratParser[Expression] = (
      positioned(expression12andDot ~ (expression13 <~ ":=") ~ expression1
          ^^ DotAssignExpression)
    | positioned(expression2 ~ ("<-" | ":=") ~ expression1 ^^ BinaryOp)
    | expression2
  )

  // X orelse Y   (right-associative)
  lazy val expression2: PackratParser[Expression] = (
      positioned(expression3 ~ "orelse" ~ expression2 ^^ ShortCircuitBinaryOp)
    | expression3
  )

  // X andthen Y   (right-associative)
  lazy val expression3: PackratParser[Expression] = (
      positioned(expression4 ~ "andthen" ~ expression3 ^^ ShortCircuitBinaryOp)
    | expression4
  )

  // X==Y   X\=Y     X<Y    X=<Y     X>Y    X>=Y   (non-associative)
  // X=:Y   X\=:Y    X<:Y   X=<:Y    X>:Y   X>=:Y
  lazy val expression4: PackratParser[Expression] = (
      positioned(expression5 ~ operator4 ~ expression5 ^^ BinaryOp)
    | expression5
  )

  lazy val operator4 = "==" | "\\=" | "<" | "=<" | ">" | ">="

  // X::Y   X:::Y   (non-associative)
  lazy val expression5: PackratParser[Expression] = expression6

  // X|Y   (right-associative)
  lazy val expression6: PackratParser[Expression] = (
      (expression7 <~ "|") ~ expression6 ^^ cons
    | expression7
  )

  // X#Y#...#Z   (mixin)
  lazy val expression7: PackratParser[Expression] = (
      expression8 ~ rep1("#" ~> expression8) ^^ { case f ~ r => sharp(f :: r) }
    | expression8
  )

  // X+Y   X-Y   (left-associative)
  lazy val expression8: PackratParser[Expression] = (
      positioned(expression8 ~ ("+" | "-") ~ expression9 ^^ BinaryOp)
    | expression9
  )

  // X*Y   X/Y    X div Y   X mod Y   (left-associative)
  lazy val expression9: PackratParser[Expression] = (
      positioned(expression9 ~ operator9 ~ expression10 ^^ BinaryOp)
    | expression10
  )

  lazy val operator9 = "*" | "/" | "div" | "mod"

  // X,Y   (right-associative)
  lazy val expression10: PackratParser[Expression] = (
      positioned(expression11 ~ "," ~ expression10 ^^ BinaryOp)
    | expression11
  )

  // ~X   (prefix)
  lazy val expression11: PackratParser[Expression] = (
      positioned("~" ~ expression11 ^^ UnaryOp)
    | expression12
  )

  // X.Y   X^Y   (left-associative)
  lazy val expression12: PackratParser[Expression] = (
      positioned(expression12 ~ "." ~ expression13 ^^ BinaryOp)
    | expression13
  )

  // same as above but followed by a '.'
  lazy val expression12andDot: PackratParser[Expression] = (
      positioned(expression12andDot ~ expression13 <~ "." ^^ {
        case left ~ right => BinaryOp(left, ".", right)
      })
    | expression13 <~ "."
  )

  // @X   !!X   (prefix)
  lazy val expression13: PackratParser[Expression] = (
      positioned(("@" | "!!") ~ expression13 ^^ UnaryOp)
    | expression14
  )

  // elementary
  lazy val expression14: PackratParser[Expression] = (
      "local" ~> inExpression <~ "end"
    | "(" ~> inExpression <~ ")"
    | procExpression
    | funExpression
    | callExpression
    | ifExpression
    | caseExpression
    | threadExpression
    | lockExpression
    | tryExpression
    | raiseExpression
    | functorExpression
    | trivialExpression
    | stringConstExpr
    | recordExpression
    | listExpression
    | classExpression
  )

  // Trivial expressions

  lazy val trivialExpression: PackratParser[Expression] =
    attrOrFeat | wildcardExpr | nestingMarker | floatConstExpr | selfExpr

  lazy val attrOrFeat: PackratParser[Expression] =
    variable | escapedVariable | integerConstExpr | literalConstExpr

  lazy val variable: PackratParser[RawVariable] =
    positioned(ident ^^ (chars => RawVariable(chars)))

  lazy val escapedVariable: PackratParser[EscapedVariable] =
    positioned("!" ~> variable ^^ EscapedVariable)

  lazy val wildcardExpr: PackratParser[UnboundExpression] =
    positioned("_" ^^^ UnboundExpression())

  lazy val nestingMarker: PackratParser[NestingMarker] =
    positioned("$" ^^^ NestingMarker())

  lazy val integerConstExpr: PackratParser[Constant] =
    positioned(integerConst ^^ Constant)

  lazy val floatConstExpr: PackratParser[Constant] =
    positioned(floatConst ^^ Constant)

  lazy val literalConstExpr: PackratParser[Constant] =
    positioned(literalConst ^^ Constant)

  lazy val stringConstExpr: PackratParser[Constant] =
    positioned(stringConst ^^ Constant)

  lazy val selfExpr: PackratParser[Self] =
    positioned("self" ^^^ Self())

  // Constants

  lazy val integerConst: PackratParser[OzInt] = (
      intLit ^^ (value => OzInt(value))
    | charLit ^^ (char => OzInt(char.toLong))
  )

  lazy val floatConst: PackratParser[OzFloat] =
    floatLit ^^ (value => OzFloat(value))

  lazy val literalConst: PackratParser[OzLiteral] = (
      "true" ^^^ True()
    | "false" ^^^ False()
    | "unit" ^^^ UnitVal()
    | atomConst
  )

  lazy val atomConst: PackratParser[OzAtom] =
    atomLit ^^ (chars => OzAtom(chars))

  lazy val featureConst: PackratParser[OzFeature] =
    integerConst | literalConst

  lazy val stringConst: PackratParser[OzValue] =
    stringLit ^^ (chars => OzList(chars.toList map (c => OzInt(c.toInt))))

  // Record expressions

  lazy val recordExpression: PackratParser[Expression] =
    positioned(recordLabel ~ rep(recordField) <~ ")" ^^ Record)

  lazy val recordLabel: PackratParser[Expression] =
    literalLabelExpr | identLabelExpr

  lazy val literalLabelExpr: PackratParser[Constant] =
    positioned(atomLitLabel ^^ (chars => Constant(OzAtom(chars))))

  lazy val identLabelExpr: PackratParser[RawVariable] =
    positioned(identLabel ^^ RawVariable)

  lazy val recordField: PackratParser[RecordField] = positioned {
    optFeature ~ expression ^^ RecordField
  }

  lazy val optFeature: PackratParser[Expression] = positioned {
    opt(feature <~ ":") ^^ (_.getOrElse(AutoFeature()))
  }

  lazy val feature: PackratParser[Expression] = (
      featureNoVar
    | variable
  )

  // List expressions

  lazy val listExpression: PackratParser[Expression] =
    positioned("[" ~> rep1(expression) <~ "]" ^^ exprListToListExpr)

  // Helpers

  /** Extracts the name of a RawVariable, or "" if it is not */
  private def nameOf(expression: Expression) = expression match {
    case RawVariable(name) => name
    case _ => ""
  }
}
