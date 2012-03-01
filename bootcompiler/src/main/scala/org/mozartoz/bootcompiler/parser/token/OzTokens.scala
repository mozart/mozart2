package org.mozartoz.bootcompiler.parser
package token

import scala.util.parsing.combinator.token._

trait OzTokens extends StdTokens {
  /** The class of float literal tokens */
  case class FloatLit(chars: String) extends Token {
    override def toString() = chars
  }

  /** The class of atom literal tokens */
  case class AtomLit(chars: String) extends Token {
    override def toString() = "atom "+chars
  }

  /** A special token representing a label, i.e. an identifier or atom literal
   *  followed directly by a (
   */
  case class Label(label: Token) extends Token {
    override def chars = label.chars + "("
    override def toString() = label.toString() + "("
  }
}
