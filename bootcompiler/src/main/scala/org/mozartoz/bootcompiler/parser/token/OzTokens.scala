package org.mozartoz.bootcompiler.parser
package token

import scala.util.parsing.combinator.token._

trait OzTokens extends StdTokens {
  /** The class of atom literal tokens */
  case class AtomLit(chars: String) extends Token {
    override def toString() = "atom "+chars
  }

  /** A special token representing a token (identifier or atom literal)
   *  followed directly by a (
   */
  case class OpenRecord(label: Token) extends Token {
    override def chars = label.chars + "("
    override def toString() = label.toString() + "("
  }
}
