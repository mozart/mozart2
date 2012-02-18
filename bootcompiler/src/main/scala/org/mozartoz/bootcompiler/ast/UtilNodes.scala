package org.mozartoz.bootcompiler
package ast

case class FormalArgs(args: List[FormalArg]) {
  def syntax(indent: String) = args mkString " "
}

trait FormalArg extends Node

case class ActualArgs(args: List[Expression]) {
  def syntax(indent: String) = args mkString " "
}

trait Declaration extends Node

trait InfixSyntax extends Node {
  val left: Node
  val right: Node
  protected val opSyntax: String

  def syntax(indent: String) = {
    val untilOp = left.syntax(indent) + opSyntax
    val rightIndent = indent + " "*untilOp.length
    untilOp + right.syntax(rightIndent)
  }
}
