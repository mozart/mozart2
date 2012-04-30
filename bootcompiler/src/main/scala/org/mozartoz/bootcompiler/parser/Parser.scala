package org.mozartoz.bootcompiler
package parser

import scala.util.parsing.combinator._
import scala.util.parsing.combinator.syntactical._
import scala.util.parsing.input._

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
    | threadStatement
    | bindStatement
    | skipStatement
  )

  // Expressions

  lazy val expression: PackratParser[Expression] =
    expression0

  // Declarations

  lazy val inStatement: PackratParser[Statement] = (
      (declarations <~ "in") ~ statement ^^ LocalStatement
    | statement
  )

  lazy val inExpression: PackratParser[Expression] = (
      (declarations <~ "in") ~ statExpression ^^ LocalExpression
    | statExpression
  )

  lazy val statExpression: PackratParser[Expression] = (
      statement ~ expression ^^ StatAndExpression
    | expression
  )

  lazy val declarations: PackratParser[List[Declaration]] =
    declaration+

  lazy val declaration: PackratParser[Declaration] = (
      oneStatement
    | variable
  )

  // Procedure and function definition

  lazy val procStatement: PackratParser[Statement] =
    (("proc" ~> procFlags <~ "{") ~ expression ~ formalArgs <~ "}") ~ inStatement <~ "end" ^^ {
      case flags ~ left ~ args ~ body =>
        val name = left match {
          case Variable(name) => name
          case _ => ""
        }
        BindStatement(left, ProcExpression(name, args, body, flags))
    }

  lazy val funStatement: PackratParser[Statement] =
    (("fun" ~> procFlags <~ "{") ~ expression ~ formalArgs <~ "}") ~ inExpression <~ "end" ^^ {
      case flags ~ left ~ args ~ body =>
        val name = left match {
          case Variable(name) => name
          case _ => ""
        }
        BindStatement(left, FunExpression(name, args, body, flags))
    }

  lazy val procExpression: PackratParser[Expression] =
    (("proc" ~> procFlags <~ "{" ~ dollar) ~ formalArgs <~ "}") ~ inStatement <~ "end" ^^ {
      case flags ~ args ~ body => ProcExpression("", args, body, flags)
    }

  lazy val funExpression: PackratParser[Expression] =
    (("fun" ~> procFlags <~ "{" ~ dollar) ~ formalArgs <~ "}") ~ inExpression <~ "end" ^^ {
      case flags ~ args ~ body => FunExpression("", args, body, flags)
    }

  lazy val procFlags = rep(atom)

  lazy val formalArgs = rep(formalArg)

  lazy val formalArg = variable

  lazy val dollar = "$"

  // Call

  lazy val callStatement: PackratParser[Statement] =
    "{" ~> expression ~ actualArgs <~ "}" ^^ CallStatement

  lazy val callExpression: PackratParser[Expression] =
    "{" ~> expression ~ actualArgs <~ "}" ^^ CallExpression

  lazy val actualArgs = rep(expression)

  // If then else end

  lazy val ifStatement: PackratParser[Statement] =
    "if" ~> innerIfStatement <~ "end"

  lazy val innerIfStatement: PackratParser[Statement] =
    expression ~ ("then" ~> inStatement) ~ elseStatement ^^ IfStatement

  lazy val elseStatement: PackratParser[Statement] = (
      "else" ~> inStatement
    | "elseif" ~> innerIfStatement
    | success(SkipStatement())
  )

  lazy val ifExpression: PackratParser[Expression] =
    "if" ~> innerIfExpression <~ "end"

  lazy val innerIfExpression: PackratParser[Expression] =
    expression ~ ("then" ~> inExpression) ~ elseExpression ^^ IfExpression

  lazy val elseExpression: PackratParser[Expression] = (
      "else" ~> inExpression
    | "elseif" ~> innerIfExpression
  )

  // Thread

  lazy val threadStatement: PackratParser[Statement] =
    "thread" ~> inStatement <~ "end" ^^ ThreadStatement

  lazy val threadExpression: PackratParser[Expression] =
    "thread" ~> inExpression <~ "end" ^^ ThreadExpression

  // Bind

  lazy val bindStatement: PackratParser[Statement] =
    (expression1 <~ "=") ~ expression0 ^^ BindStatement

  // Skip

  lazy val skipStatement: PackratParser[Statement] =
    "skip" ^^^ SkipStatement()

  // Operations with precedence

  lazy val expression0: PackratParser[Expression] = (
      (expression1 <~ "=") ~ expression0 ^^ BindExpression
    | expression1
  )

  // X<-Y   X:=Y   X.Y:=Z   (right-associative)
  lazy val expression1: PackratParser[Expression] = expression2

  // X orelse Y   (right-associative)
  lazy val expression2: PackratParser[Expression] = (
      expression3 ~ "orelse" ~ expression2 ^^ ShortCircuitBinaryOp
    | expression3
  )

  // X andthen Y   (right-associative)
  lazy val expression3: PackratParser[Expression] = (
      expression4 ~ "andthen" ~ expression3 ^^ ShortCircuitBinaryOp
    | expression4
  )

  // X==Y   X\=Y     X<Y    X=<Y     X>Y    X>=Y   (non-associative)
  // X=:Y   X\=:Y    X<:Y   X=<:Y    X>:Y   X>=:Y
  lazy val expression4: PackratParser[Expression] = (
      expression5 ~ operator4 ~ expression5 ^^ BinaryOp
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

  private def cons(head: Expression, tail: Expression) =
    Record(Atom("|"), List(head, tail))

  // X#Y#...#Z   (mixin)
  lazy val expression7: PackratParser[Expression] = (
      expression8 ~ rep1("#" ~> expression8) ^^ sharp
    | expression8
  )

  private def sharp(first: Expression, rest: List[Expression]) =
    Record(Atom("#"), (first :: rest) map expr2recordField)

  // X+Y   X-Y   (left-associative)
  lazy val expression8: PackratParser[Expression] = (
      expression8 ~ ("+" | "-") ~ expression9 ^^ BinaryOp
    | expression9
  )

  // X*Y   X/Y    X div Y   X mod Y   (left-associative)
  lazy val expression9: PackratParser[Expression] = (
      expression9 ~ ("*" | "/" | "div" | "mod") ~ expression10 ^^ BinaryOp
    | expression10
  )

  // X,Y   (right-associative)
  lazy val expression10: PackratParser[Expression] = expression11

  // ~X   (prefix)
  lazy val expression11: PackratParser[Expression] = (
      "~" ~ expression11 ^^ UnaryOp
    | expression12
  )

  // X.Y   X^Y   (left-associative)
  lazy val expression12: PackratParser[Expression] = (
      expression12 ~ "." ~ expression13 ^^ BinaryOp
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
    | threadExpression
    | trivialExpression
    | recordExpression
    | listExpression
  )

  // Trivial expressions

  lazy val trivialExpression: PackratParser[Expression] = (
      variable
    | "!!" ~> variable ^^ EscapedVariable
    | unboundExpression
    | integerConst
    | floatConst
    | atomLike
  )

  lazy val unboundExpression: PackratParser[UnboundExpression] =
    "_" ^^^ UnboundExpression()

  lazy val integerConst: PackratParser[IntLiteral] =
    numericLit ^^ (chars => IntLiteral(chars.toInt))

  lazy val floatConst: PackratParser[FloatLiteral] =
    floatLit ^^ (chars => FloatLiteral(chars.toInt))

  lazy val atomLike: PackratParser[AtomLike] = (
      "true" ^^^ True()
    | "false" ^^^ False()
    | "unit" ^^^ UnitVal()
    | atom
  )

  lazy val atom: PackratParser[Atom] =
    atomLit ^^ (chars => Atom(chars))

  lazy val variable: PackratParser[Variable] =
    ident ^^ (chars => Variable(chars))

  // Record expressions

  lazy val recordExpression: PackratParser[Expression] =
    recordLabel ~ recordFields <~ ")" ^^ Record

  lazy val recordLabel: PackratParser[Expression] = (
      atomLitLabel ^^ Atom
    | identLabel ^^ Variable
  )

  lazy val recordFields: PackratParser[List[RecordField]] =
    rep(recordField)

  lazy val recordField: PackratParser[RecordField] = (
      expression ~ (":" ~> expression) ^^ RecordField
    | expression ^^ (expr => RecordField(AutoFeature(), expr))
  )

  // List expressions

  lazy val listExpression: PackratParser[Expression] =
    "[" ~> (expression+) <~ "]" ^^ exprListToListExpr

  def exprListToListExpr(elems: List[Expression]): Expression =
    if (elems.isEmpty) Atom("nil")
    else Record(Atom("|"), List(elems.head, exprListToListExpr(elems.tail)))
}
