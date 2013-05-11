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
    | charLiteral
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
      case int ~ fract => FloatLit((int+fract).toDouble)
    }

  def integerLiteral = (
      integerLiteralBase ^^ IntLit
    | '~' ~> integerLiteralBase ^^ (x => IntLit(-x))
  )

  def integerLiteralBase = (
      ('0' ~ (elem('x') | 'X')) ~> rep1(hexDigit) ^^ {
        digits => digits.foldLeft(0L)(_ * 16 + _)
      }
    | ('0' ~ (elem('b') | 'B')) ~> rep1(binDigit) ^^ {
        digits => digits.foldLeft(0L)(_ * 2 + _)
      }
    | '0' ~> rep1(octalDigit) ^^ {
        digits => digits.foldLeft(0L)(_ * 8 + _)
      }
    | stringOf1(digit) ^^ (chars => chars.toLong)
  )

  def atomLiteral = (
      stringOf1(lowerCaseLetter, identChar) ^^ processKeyword
    | quoted('\'') ^^ AtomLit
  )

  def charLiteral =
    '&' ~> (chrExcept('\\', EofCh) | pseudoChar) ^^ CharLit

  def stringLiteral =
    quoted('\"') ^^ StringLit

  def quotedKeepQuotes(quoteChar: Char) =
    quoted(quoteChar) ^^ (quoteChar + _ + quoteChar)

  def quoted(quoteChar: Char) =
    quoteChar ~> stringOf(inQuoteChar(quoteChar)) <~ quoteChar

  def inQuoteChar(quoteChar: Char) =
    chrExcept('\\', quoteChar, EofCh) | pseudoChar

  def pseudoChar = '\\' ~> (
      octalDigit ~ octalDigit ~ octalDigit ^^ {
        case sixtyFour ~ eight ~ one => latin1char(64*sixtyFour + 8*eight + one)
      }
    | (elem('x') | 'X') ~> hexDigit ~ hexDigit ^^ {
        case sixteen ~ one => latin1char(16*sixteen + one)
      }
    | escapeChar
  )

  def binDigit =
    elem("binary digit", c => c == '0' || c == '1') ^^ (_ - '0')

  def octalDigit =
    elem("octal digit", c => '0' <= c && c <= '7') ^^ (_ - '0')

  def hexDigit = accept("hex digit", {
    case c @ ('0'|'1'|'2'|'3'|'4'|'5'|'6'|'7'|'8'|'9') => (c - '0')
    case c @ ('A'|'B'|'C'|'D'|'E'|'F') => (c - 'A' + 10)
    case c @ ('a'|'b'|'c'|'d'|'e'|'f') => (c - 'a' + 10)
  })

  def latin1char(code: Int) = code.toChar

  def escapeChar = (
      elem('\'') | '"' | '`' | '\\' | '&'
    | 'a' ^^^ '\u0007'
    | 'b' ^^^ '\u0008'
    | 't' ^^^ '\u0009'
    | 'n' ^^^ '\u000A'
    | 'v' ^^^ '\u000B'
    | 'f' ^^^ '\u000C'
    | 'r' ^^^ '\u000D'
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
    | '/' ~ '*' ~ rep(not('*' ~ '/') ~> chrExcept(EofCh)) ~ '*' ~ '/'
    | '%' ~ rep( chrExcept(EofCh, '\n') )
    | '/' ~ '*' ~ failure("unclosed comment")
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
