package org.mozartoz.bootcompiler
package parser

import scala.util.parsing.input.CharArrayReader.EofCh
import scala.util.parsing.combinator._
import scala.util.parsing.combinator.lexical._
import collection.mutable.HashSet

class OzLexical extends Lexical with OzTokens with ImplicitConversions {
  // see `token' in `Scanners'
  def token: Parser[Token] = (
      identifier >> handleLabel
    | atomLiteral >> handleLabel
    | floatLiteral
    | integerLiteral
    | atomLiteral
    | stringLiteral
    | EofCh ^^^ EOF
    | delim
    | '?' ~> token
    | '\\' ~> preprocessorDirective
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

  def identifier = (
      stringOf1(upperCaseLetter, identChar) ^^ Identifier
    | quotedKeepQuotes('`') ^^ Identifier
  )

  def floatLiteral =
    stringOf1(digit) ~ stringOf1('.', digit) ^^ {
      case int ~ fract => FloatLit(int + fract)
    }

  def integerLiteral =
    stringOf1(digit) ^^ NumericLit

  def atomLiteral = (
      stringOf1(lowerCaseLetter, identChar) ^^ processKeyword
    | quoted('\'') ^^ AtomLit
  )

  def stringLiteral =
    quoted('\"') ^^ StringLit

  def quotedKeepQuotes(quoteChar: Char) =
    quoted(quoteChar) ^^ (quoteChar + _ + quoteChar)

  def quoted(quoteChar: Char) =
    quoteChar ~> stringOf(inQuoteChar(quoteChar)) <~ quoteChar

  def inQuoteChar(quoteChar: Char) = (
      '\\' ~> escapeChar
    | chrExcept('\\', '\n', quoteChar, EofCh)
  )

  def escapeChar = (
      elem('\'') | '"' | '\\'
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

  def preprocessorDirective = (
      "switch" ~> whitespace ~> switchArgs
    | ("showSwitches" | "pushSwitches" | "popSwitches" | "localSwitches" |
        "else" | "endif") ^^ PreprocessorDirective
    | ((("define" | "undef" | "ifdef" | "ifndef") <~ whitespace) ~
        preprocessorVar ^^ PreprocessorDirectiveWithArg)
    | (("insert" <~ whitespace) ~ preprocessorFileName
        ^^ PreprocessorDirectiveWithArg)
  )

  def switchArgs = (
      ((('+' ^^^ true) | ('-' ^^^ false)) <~ opt(whitespace)) ~
      stringOf1(lowerCaseLetter, identChar)
  ) ^^ { case value ~ switch => PreprocessorSwitch(switch, value) }

  def preprocessorVar =
    stringOf1(upperCaseLetter, identChar)

  def preprocessorFileName = (
      stringOf1(letter | digit | '/' | '_' | '~' | '.' | '-')
    | quoted('\'')
  )

  // utils

  def stringOf(p: => Parser[Char]): Parser[String] = rep(p) ^^ chars2string
  def stringOf1(p: => Parser[Char]): Parser[String] = rep1(p) ^^ chars2string
  def stringOf1(first: => Parser[Char], p: => Parser[Char]): Parser[String] =
    rep1(first, p) ^^ chars2string

  private def chars2string(chars: List[Char]) = chars mkString ""

  private implicit def verbatimString(str: String): Parser[String] =
    str.toList.foldRight[Parser[Any]](success("")) {
      (c, prev) => c ~ prev
    } ^^^ str

  // reserved words and delimiters

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
