package org.mozartoz.bootcompiler
package parser

import scala.util.parsing.combinator.syntactical._
import scala.util.parsing.input._

import syntactical._
import ast._

/**
 * The main Oz parser
 */
class OzParser extends OzTokenParsers {
  lexical.reserved ++= List(
      "true", "false", "unit"
  )

  lexical.delimiters ++= List(
      "{", "}", "(", ")", "[", "]", ":", ",",
      "+", "-", "*", "/", "~"
  )

  def parse(input: Reader[Char]) =
    phrase(root)(new lexical.Scanner(input))

  def parse(input: String) =
    phrase(root)(new lexical.Scanner(input))

  def root = statements
  def statements = statement+

  def statement: Parser[Statement] =
    elem("any token", _ != lexical.EOF) ^^ (token => TokenStatement(token))
}
