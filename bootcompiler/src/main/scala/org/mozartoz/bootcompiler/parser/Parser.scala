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

  lazy val expression: PackratParser[Expression] = (
      "local" ~> inExpression <~ "end"
    | "(" ~> inExpression <~ ")"
    | procExpression
    | funExpression
    | callExpression
    | ifExpression
    | threadExpression
    | operationExpression
  )

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
      case flags ~ name ~ args ~ body => ProcStatement(name, args, body, flags)
    }

  lazy val funStatement: PackratParser[Statement] =
    (("fun" ~> procFlags <~ "{") ~ expression ~ formalArgs <~ "}") ~ inExpression <~ "end" ^^ {
      case flags ~ name ~ args ~ body => FunStatement(name, args, body, flags)
    }

  lazy val procExpression: PackratParser[Expression] =
    (("proc" ~> procFlags <~ "{" ~ dollar) ~ formalArgs <~ "}") ~ inStatement <~ "end" ^^ {
      case flags ~ args ~ body => ProcExpression(args, body, flags)
    }

  lazy val funExpression: PackratParser[Expression] =
    (("fun" ~> procFlags <~ "{" ~ dollar) ~ formalArgs <~ "}") ~ inExpression <~ "end" ^^ {
      case flags ~ args ~ body => FunExpression(args, body, flags)
    }

  lazy val procFlags = rep(atom)

  lazy val formalArgs = rep(formalArg) ^^ FormalArgs

  lazy val formalArg = variable

  lazy val dollar = "$"

  // Call

  lazy val callStatement: PackratParser[Statement] =
    "{" ~> expression ~ actualArgs <~ "}" ^^ CallStatement

  lazy val callExpression: PackratParser[Expression] =
    "{" ~> expression ~ actualArgs <~ "}" ^^ CallExpression

  lazy val actualArgs = rep(expression) ^^ ActualArgs

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
    (expression1 <~ "=") ~ expression ^^ BindStatement

  lazy val bindExpression: PackratParser[Expression] =
    (expression1 <~ "=") ~ expression ^^ BindExpression

  // Skip

  lazy val skipStatement: PackratParser[Statement] =
    "skip" ^^^ SkipStatement()

  // Operations with precedence

  lazy val operationExpression: PackratParser[Expression] = (
      bindExpression
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
  lazy val expression6: PackratParser[Expression] = expression7

  // X#Y#...#Z   (mixin)
  lazy val expression7: PackratParser[Expression] = expression8

  // X+Y   X-Y   (left-associative)
  lazy val expression8: PackratParser[Expression] =
    expression9 ~ rep(("+" | "-") ~ expression9) ^^ {
      case x ~ ys => ys.foldLeft(x) {
        case (prev, op ~ right) => BinaryOp(prev, op, right)
      }
    }

  // X*Y   X/Y    X div Y   X mod Y   (left-associative)
  lazy val expression9: PackratParser[Expression] =
    expression10 ~ rep(("*" | "/" | "div" | "mod") ~ expression10) ^^ {
      case x ~ ys => ys.foldLeft(x) {
        case (prev, op ~ right) => BinaryOp(prev, op, right)
      }
    }

  // X,Y   (right-associative)
  lazy val expression10: PackratParser[Expression] = expression11

  // ~X   (prefix)
  lazy val expression11: PackratParser[Expression] = (
      "~" ~ expression11 ^^ UnaryOp
    | expression12
  )

  // X.Y   X^Y   (left-associative)
  lazy val expression12: PackratParser[Expression] = expression13

  // @X   !!X   (prefix)
  lazy val expression13: PackratParser[Expression] = expression14

  // trivial
  lazy val expression14: PackratParser[Expression] = trivialExpression

  // Trivial expressions

  lazy val trivialExpression: PackratParser[Expression] = (
      variable
    | "!!" ~> variable ^^ EscapedVariable
    | unboundExpression
    | integerConst
    | atomLike
  )

  lazy val unboundExpression: PackratParser[UnboundExpression] =
    "_" ^^^ UnboundExpression()

  lazy val integerConst: PackratParser[IntLiteral] =
    numericLit ^^ (chars => IntLiteral(chars.toInt))

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
}
