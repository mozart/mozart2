package org.mozartoz.bootcompiler
package ast

import symtab._

trait RawDeclarationOrVar extends Node
trait RawDeclaration extends RawDeclarationOrVar

trait InfixSyntax extends Node {
  protected val left: Node
  protected val right: Node
  protected val opSyntax: String

  def syntax(indent: String) = {
    val untilOp = left.syntax(indent) + opSyntax
    val rightIndent = indent + " "*untilOp.length
    untilOp + right.syntax(rightIndent)
  }
}

trait MultiInfixSyntax extends Node {
  protected val operands: Seq[Node]
  protected val operators: Seq[String]

  def syntax(indent: String) = {
    val first = operands.head.syntax(indent)
    (operators zip operands.tail).foldLeft(first) {
      case (prev, (op, operand)) =>
        val untilOp = prev + op
        untilOp + operand.syntax(indent + " "*untilOp.length)
    }
  }
}
