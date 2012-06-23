package org.mozartoz.bootcompiler
package parser

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

  /** Preprocessor switch */
  case class PreprocessorSwitch(switch: String, value: Boolean) extends Token {
    override def chars = "\\switch " + (if (value) "+" else "-") + switch
    override def toString() = chars
  }

  /** Preprocessor directive */
  case class PreprocessorDirective(directive: String) extends Token {
    override def chars = "\\" + directive
    override def toString() = chars
  }

  /** Preprocessor directive with argument */
  case class PreprocessorDirectiveWithArg(directive: String,
      arg: String) extends Token {
    override def chars = "\\" + directive + " " + arg
    override def toString() = chars
  }
}
