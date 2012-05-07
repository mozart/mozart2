package org.mozartoz.bootcompiler
package parser

import scala.util.parsing.combinator._
import scala.util.parsing.combinator.syntactical._
import scala.util.parsing.input._

import oz._
import syntactical._
import ast._

/**
 * The main Oz parser
 */
class OzParser extends OzTokenParsers with PackratParsers
    with ImplicitConversions {

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

  def parse(input: Reader[Char]) =
    phrase(root)(new lexical.Scanner(input))

  def parse(input: String) =
    phrase(root)(new lexical.Scanner(input))

  lazy val root = statement

  // Statements

  lazy val statement: PackratParser[Statement] =
    rep1(oneStatement) ^^ CompoundStatement

  lazy val oneStatement: PackratParser[Statement] = (
      "local" ~> inStatement <~ "end"
    | "(" ~> inStatement <~ ")"
    | procStatement
    | funStatement
    | callStatement
    | ifStatement
    | caseStatement
    | threadStatement
    | bindStatement
    | skipStatement
  )

  // Expressions

  lazy val expression: PackratParser[Expression] =
    expression0

  // Declarations

  lazy val inStatement: PackratParser[Statement] = (
      positioned((declarations <~ "in") ~ statement ^^ LocalStatement)
    | statement
  )

  lazy val inExpression: PackratParser[Expression] = (
      positioned((declarations <~ "in") ~ statExpression ^^ LocalExpression)
    | statExpression
  )

  lazy val statExpression: PackratParser[Expression] = (
      positioned(statement ~ expression ^^ StatAndExpression)
    | expression
  )

  lazy val declarations: PackratParser[List[Declaration]] =
    declaration+

  lazy val declaration: PackratParser[Declaration] = (
      oneStatement
    | variable
  )

  // Procedure and function definition

  lazy val procStatement: PackratParser[Statement] = positioned {
    (("proc" ~> procFlags <~ "{") ~ expression ~ formalArgs <~ "}") ~ inStatement <~ "end" ^^ {
      case flags ~ left ~ args ~ body =>
        val name = left match {
          case Variable(name) => name
          case _ => ""
        }
        BindStatement(left, ProcExpression(name, args, body, flags))
    }
  }

  lazy val funStatement: PackratParser[Statement] = positioned {
    (("fun" ~> procFlags <~ "{") ~ expression ~ formalArgs <~ "}") ~ inExpression <~ "end" ^^ {
      case flags ~ left ~ args ~ body =>
        val name = left match {
          case Variable(name) => name
          case _ => ""
        }
        BindStatement(left, FunExpression(name, args, body, flags))
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

  lazy val procFlags = rep(atom ^^ (_.value))

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
          expression ~ opt("if" ~> expression) ~ ("then" ~> inStatement)
              ^^ MatchStatementClause)
  )

  lazy val caseExpressionClauses: PackratParser[List[MatchExpressionClause]] =
    rep1(caseExpressionClause, "[]" ~> caseExpressionClause)

  lazy val caseExpressionClause: PackratParser[MatchExpressionClause] = (
      positioned(
          expression ~ opt("if" ~> expression) ~ ("then" ~> inExpression)
              ^^ MatchExpressionClause)
  )

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

  // Bind

  lazy val bindStatement: PackratParser[Statement] = positioned {
    (expression1 <~ "=") ~ expression0 ^^ BindStatement
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
  lazy val expression1: PackratParser[Expression] = expression2

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
      positioned((expression7 <~ "|") ~ expression6 ^^ cons)
    | expression7
  )

  private def cons(head: Expression, tail: Expression) =
    Record(Constant(OzAtom("|")), List(head, tail))

  // X#Y#...#Z   (mixin)
  lazy val expression7: PackratParser[Expression] = (
      positioned(expression8 ~ rep1("#" ~> expression8) ^^ sharp)
    | expression8
  )

  private def sharp(first: Expression, rest: List[Expression]) =
    Record(Constant(OzAtom("#")), (first :: rest) map expr2recordField)

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
  lazy val expression10: PackratParser[Expression] = expression11

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

  // @X   !!X   (prefix)
  lazy val expression13: PackratParser[Expression] = expression14

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
    | trivialExpression
    | recordExpression
    | listExpression
  )

  // Trivial expressions

  lazy val trivialExpression: PackratParser[Expression] = (
      variable
    | positioned("!!" ~> variable ^^ EscapedVariable)
    | unboundExpression
    | positioned(integerConst ^^ Constant)
    | positioned(floatConst ^^ Constant)
    | positioned(atomLike ^^ Constant)
  )

  lazy val unboundExpression: PackratParser[UnboundExpression] =
    positioned("_" ^^^ UnboundExpression())

  lazy val integerConst: PackratParser[OzInt] =
    numericLit ^^ (chars => OzInt(chars.toInt))

  lazy val floatConst: PackratParser[OzFloat] =
    floatLit ^^ (chars => OzFloat(chars.toInt))

  lazy val atomLike: PackratParser[OzLiteral] = (
      "true" ^^^ True()
    | "false" ^^^ False()
    | "unit" ^^^ UnitVal()
    | atom
  )

  lazy val atom: PackratParser[OzAtom] =
    atomLit ^^ (chars => OzAtom(chars))

  lazy val variable: PackratParser[Variable] =
    positioned(ident ^^ (chars => Variable(chars)))

  // Record expressions

  lazy val recordExpression: PackratParser[Expression] =
    positioned(recordLabel ~ recordFields <~ ")" ^^ Record)

  lazy val recordLabel: PackratParser[Expression] = (
      positioned(atomLitLabel ^^ (chars => Constant(OzAtom(chars))))
    | positioned(identLabel ^^ Variable)
  )

  lazy val recordFields: PackratParser[List[RecordField]] =
    rep(recordField)

  lazy val recordField: PackratParser[RecordField] = (
      positioned(expression ~ (":" ~> expression) ^^ RecordField)
    | positioned(expression ^^ (expr => RecordField(AutoFeature(), expr)))
  )

  // List expressions

  lazy val listExpression: PackratParser[Expression] =
    positioned("[" ~> (expression+) <~ "]" ^^ exprListToListExpr)

  def exprListToListExpr(elems: List[Expression]): Expression =
    if (elems.isEmpty) Constant(OzAtom("nil"))
    else {
      Record(Constant(OzAtom("|")),
          List(elems.head, exprListToListExpr(elems.tail)))
    }
}
