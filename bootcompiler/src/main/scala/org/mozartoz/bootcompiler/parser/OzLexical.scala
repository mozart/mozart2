package org.mozartoz.bootcompiler
package parser

import scala.util.parsing.input.CharArrayReader.EofCh
import scala.util.parsing.combinator.lexical._
import collection.mutable.HashSet

class OzLexical extends Lexical with OzTokens {
  // see `token' in `Scanners'
  def token: Parser[Token] = (
      identifier >> handleLabel
    | atomLiteral >> handleLabel
    | floatLiteral
    | integerLiteral
    | atomLiteral
    | EofCh ^^^ EOF
    | delim
    | failure("illegal character")
  )

  private val unitTrueFalse = Set("unit", "true", "false")

  def handleLabel(prev: Token) = prev match {
    case kw @ Keyword(chars) if (!(unitTrueFalse contains chars)) => success(kw)
    case _ => (
        '(' ^^^ Label(prev)
      | success(prev)
    )
  }

  def identifier =
    upperCaseLetter ~ rep(identChar) ^^ {
      case first ~ rest => Identifier(first :: rest mkString "")
    }

  def floatLiteral =
    (digit ~ rep(digit) <~ '.') ~ rep(digit) ^^ {
      case first ~ rest ~ fract =>
        FloatLit(first :: rest mkString "" + "." + fract mkString "")
    }

  def integerLiteral =
    digit ~ rep(digit) ^^ {
      case first ~ rest => NumericLit(first :: rest mkString "")
    }

  def atomLiteral = (
      lowerCaseLetter ~ rep(identChar) ^^ {
        case first ~ rest => processKeyword(first :: rest mkString "")
      }

    | '\'' ~> rep( chrExcept('\'', '\n', EofCh) ) <~ '\'' ^^ {
        chars => AtomLit(chars mkString "")
      }
  )

  /** A character-parser that matches a lowercase letter (and returns it)*/
  def lowerCaseLetter = elem("letter", _.isLower)

  /** A character-parser that matches a uppercase letter (and returns it)*/
  def upperCaseLetter = elem("letter", _.isUpper)

  // legal identifier chars
  def identChar = letter | digit | elem('_')

  // see `whitespace in `Scanners'
  def whitespace: Parser[Any] = rep(
      whitespaceChar
    | '/' ~ '*' ~ comment
    | '%' ~ rep( chrExcept(EofCh, '\n') )
    | '/' ~ '*' ~ failure("unclosed comment")
  )

  protected def comment: Parser[Any] = (
      '*' ~ '/'  ^^ { case _ => ' ' }
    | chrExcept(EofCh) ~ comment
  )

  /** The set of reserved identifiers: these will be returned as `Keyword's */
  val reserved = new HashSet[String]

  /** The set of delimiters (ordering does not matter) */
  val delimiters = new HashSet[String]

  protected def processKeyword(name: String) =
    if (reserved contains name) Keyword(name) else AtomLit(name)

  private lazy val _delim: Parser[Token] = {
    /* construct parser for delimiters by |'ing together the parsers for the
     * individual delimiters, starting with the longest one -- otherwise a
     * delimiter D will never be matched if there is another delimiter that is
     * a prefix of D
     */
    def parseDelim(s: String): Parser[Token] =
      accept(s.toList) ^^ { x => Keyword(s) }

    val d = new Array[String](delimiters.size)
    delimiters.copyToArray(d, 0)
    scala.util.Sorting.quickSort(d)
    (d.toList map parseDelim).foldRight(
        failure("no matching delimiter"): Parser[Token])((x, y) => y | x)
  }

  protected def delim: Parser[Token] = _delim
}
