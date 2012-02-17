package org.mozartoz.bootcompiler.parser
package syntactical

import scala.util.parsing.combinator.syntactical._
import scala.util.parsing.combinator.token._

import collection.mutable.HashMap

import token._
import lexical._

trait OzTokenParsers extends StdTokenParsers {
  type Tokens = OzTokens
  val lexical = new OzLexical

  import lexical.{Keyword, NumericLit, StringLit, AtomLit, Identifier}

  /** A parser which matches an atom literal */
  def atomLit: Parser[String] =
    elem("atom literal", _.isInstanceOf[AtomLit]) ^^ (_.chars)

  /* an implicit keyword function that gives a warning when a given word is
   * not in the reserved/delimiters list
   */
  override implicit def keyword(chars : String): Parser[String] =
    if (lexical.reserved.contains(chars) || lexical.delimiters.contains(chars))
      super.keyword(chars)
    else {
      failure("You are trying to parse \""+chars+"\", but it is neither "+
          "contained in the delimiters list, nor in the reserved keyword list "+
          "of your lexical object")
    }
}
