package org.mozartoz.bootcompiler

import scala.util.parsing.input.{ Position, NoPosition, Positional }

package object ast {
  // Utils

  def escapePseudoChars(name: String, delim: Char) = {
    val result = new StringBuffer
    name foreach { c =>
      if (c == '\\' || c == delim)
        result append '\\'
      result append c
    }
    result.toString
  }

  implicit def pair2recordField(pair: (Expression, Expression)) =
    RecordField(pair._1, pair._2)

  implicit def expr2recordField(expr: Expression) =
    RecordField(AutoFeature(), expr)

  def atPos[A <: Node](pos: Position)(node: A): A = {
    node walkBreak { subNode =>
      if (subNode.pos ne NoPosition) false
      else {
        subNode.setPos(pos)
        true
      }
    }

    node
  }

  def atPos[A <: Node](positional: Positional)(node: A): A =
    atPos(positional.pos)(node)
}
